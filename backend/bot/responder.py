from anthropic import AsyncAnthropic

from config import settings
from db.repositories.message_repo import MessageRepository
from db.repositories.qualification_slot_repo import QualificationSlotRepository
from db.repositories.conversation_repo import ConversationRepository
from db.repositories.handoff_event_repo import HandoffEventRepository
from db.repositories.seller_repo import SellerRepository
from db.repositories.motorcycle_model_repo import MotorcycleModelRepository


SLOT_POINTS = 15
QUALIFIED_THRESHOLD = 70

VALID_SLOTS = [
    "modelo",
    "cidade",
    "forma_pagamento",
    "prazo_compra",
    "tem_cnh",
    "faixa_renda",
]

SAVE_SLOT_TOOL = {
    "name": "save_qualification_slot",
    "description": (
        "Salva um dado de qualificacao do cliente quando ele for mencionado "
        "na conversa. Use sempre que o cliente fornecer uma informacao que "
        "se encaixa em um dos slots disponiveis."
    ),
    "input_schema": {
        "type": "object",
        "properties": {
            "slot_name": {
                "type": "string",
                "enum": VALID_SLOTS,
                "description": "Nome do slot a ser salvo.",
            },
            "slot_value": {
                "type": "string",
                "description": "Valor exato informado pelo cliente.",
            },
        },
        "required": ["slot_name", "slot_value"],
    },
}

SYSTEM_PROMPT = """Voce e Maria, atendente virtual da Shineray Uberlandia, uma concessionaria de motocicletas.
Seu objetivo e atender clientes interessados em comprar uma moto de forma amigavel e
profissional, coletando informacoes para qualificar o lead.

Voce precisa descobrir (de forma natural, ao longo da conversa):
- modelo de moto de interesse
- cidade onde mora
- forma de pagamento (avista, financiamento, consorcio)
- prazo de compra (imediato, 30 dias, 90 dias, sem pressa)
- se tem CNH categoria A
- faixa de renda mensal aproximada

Quando o cliente mencionar qualquer uma dessas informacoes, use a tool
save_qualification_slot para registrar.

Regras:
- Seja breve e direta. Mensagens curtas, estilo WhatsApp.
- Faca UMA pergunta por vez.
- Nunca invente promocoes, precos ou condicoes.
- Se o cliente pedir para falar com um humano, diga que vai transferir.
"""


class BotResponder:

    def __init__(
        self,
        client: AsyncAnthropic,
        message_repo: MessageRepository,
        slot_repo: QualificationSlotRepository,
        conv_repo: ConversationRepository,
        handoff_repo: HandoffEventRepository,
        seller_repo: SellerRepository,
        model_repo: MotorcycleModelRepository,
    ):
        self.client = client
        self.message_repo = message_repo
        self.slot_repo = slot_repo
        self.conv_repo = conv_repo
        self.handoff_repo = handoff_repo
        self.seller_repo = seller_repo
        self.model_repo = model_repo

    async def handle_user_message(self, conversation_id: int, user_text: str) -> str:
        await self.message_repo.create(
            conversation_id=conversation_id,
            role="user",
            content=user_text,
        )

        history = await self.message_repo.list_recent(
            conversation_id=conversation_id,
            limit=settings.history_max_messages,
        )
        anthropic_messages = [
            {"role": msg.role, "content": msg.content}
            for msg in history
            if msg.role in ("user", "assistant")
        ]

        system = await self._build_system_prompt(conversation_id)
        response_text = await self._chat_loop(
            conversation_id=conversation_id,
            system=system,
            messages=anthropic_messages,
        )

        await self.message_repo.create(
            conversation_id=conversation_id,
            role="assistant",
            content=response_text,
        )

        await self._update_score_and_status(conversation_id)
        return response_text

    async def _build_system_prompt(self, conversation_id: int) -> str:
        slots = await self.slot_repo.list_for_conversation(conversation_id)
        if not slots:
            return SYSTEM_PROMPT
        slots_str = "\n".join(f"- {s.slot_name}: {s.slot_value}" for s in slots)
        return SYSTEM_PROMPT + f"\n\nDados ja coletados nesta conversa:\n{slots_str}"

    async def _chat_loop(self, conversation_id: int, system: str, messages: list) -> str:
        while True:
            response = await self.client.messages.create(
                model="claude-haiku-4-5-20251001",
                max_tokens=1024,
                system=system,
                tools=[SAVE_SLOT_TOOL],
                messages=messages,
            )

            if response.stop_reason != "tool_use":
                text_blocks = [b.text for b in response.content if b.type == "text"]
                return "\n".join(text_blocks).strip() or "..."

            messages.append({"role": "assistant", "content": response.content})

            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    result = await self._handle_tool_call(
                        conversation_id=conversation_id,
                        tool_name=block.name,
                        tool_input=block.input,
                    )
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": result,
                    })

            messages.append({"role": "user", "content": tool_results})

    async def _handle_tool_call(self, conversation_id: int, tool_name: str, tool_input: dict) -> str:
        if tool_name != "save_qualification_slot":
            return f"erro: tool '{tool_name}' desconhecida"

        slot_name = tool_input.get("slot_name", "")
        slot_value = (tool_input.get("slot_value") or "").strip()

        if slot_name not in VALID_SLOTS:
            return f"erro: slot_name '{slot_name}' invalido"
        if not slot_value:
            return "erro: slot_value vazio"

        await self.slot_repo.upsert(
            conversation_id=conversation_id,
            slot_name=slot_name,
            slot_value=slot_value,
        )

        if slot_name == "modelo":
            model = await self.model_repo.get_by_name(slot_value)
            if model:
                await self.conv_repo.set_model(conversation_id, model.id)

        return f"slot '{slot_name}' salvo: {slot_value}"

    async def _update_score_and_status(self, conversation_id: int) -> None:
        count = await self.slot_repo.count_for_conversation(conversation_id)
        new_score = min(count * SLOT_POINTS, 100)

        await self.conv_repo.update_score(conversation_id, new_score)

        if new_score < QUALIFIED_THRESHOLD:
            return

        conv = await self.conv_repo.get_by_id(conversation_id)
        if conv is None or conv.status != "active":
            return

        await self.conv_repo.update_status(conversation_id, "qualified")

        seller = await self.seller_repo.get_least_busy()
        if seller is not None:
            await self.conv_repo.assign_seller(conversation_id, seller.id)

        await self.handoff_repo.create(
            conversation_id=conversation_id,
            motivo="lead_qualificado",
            seller_id=seller.id if seller else None,
        )
