"""Rotas relacionadas a mensagens (core do chat)."""
from fastapi import APIRouter, Depends, HTTPException

from db.repositories.conversation_repo import (
    ConversationRepository,
)
from db.repositories.message_repo import MessageRepository
from bot.responder import BotResponder
from api.deps import (
    get_conversation_repo,
    get_message_repo,
    get_bot,
)
from api.schemas import (
    SendMessageRequest,
    SendMessageResponse,
    MessageResponse,
    MessageListResponse,
    ConversationResponse,
)


router = APIRouter(prefix="/conversations/{conversation_id}/messages", tags=["messages"])


def _msg_to_response(msg) -> MessageResponse:
    return MessageResponse(
        id=msg.id,
        conversation_id=msg.conversation_id,
        role=msg.role,
        content=msg.content,
        created_at=msg.created_at,
    )


@router.get("", response_model=MessageListResponse)
async def list_messages(
    conversation_id: int,
    repo: MessageRepository = Depends(get_message_repo),
) -> MessageListResponse:
    """Historico completo da conversa, em ordem cronologica."""
    msgs = await repo.list_for_conversation(conversation_id)
    return MessageListResponse(messages=[_msg_to_response(m) for m in msgs])


@router.post("", response_model=SendMessageResponse)
async def send_message(
    conversation_id: int,
    payload: SendMessageRequest,
    bot: BotResponder = Depends(get_bot),
    msg_repo: MessageRepository = Depends(get_message_repo),
    conv_repo: ConversationRepository = Depends(get_conversation_repo),
) -> SendMessageResponse:
    """Endpoint principal do chat.

    O usuario envia uma mensagem; o backend:
      1. Garante que a conversa existe
      2. Salva a mensagem do usuario, chama o bot e salva a resposta
         (toda essa orquestracao acontece dentro de BotResponder)
      3. Devolve as duas mensagens + estado atualizado da conversa
    """
    conv = await conv_repo.get_by_id(conversation_id)
    if conv is None:
        raise HTTPException(status_code=404, detail="Conversa nao encontrada")

    if conv.status == "opted_out":
        raise HTTPException(
            status_code=403,
            detail="Esta conversa esta com opt-out e nao aceita mensagens.",
        )

    # Bot processa: salva user msg + chama Claude + salva bot msg
    await bot.handle_user_message(
        conversation_id=conversation_id,
        user_text=payload.content,
    )

    # Le de volta as duas ultimas mensagens (user + assistant) e a conv atualizada
    recent = await msg_repo.list_recent(conversation_id=conversation_id, limit=2)
    if len(recent) < 2:
        raise HTTPException(status_code=500, detail="Erro ao recuperar mensagens")

    user_msg, bot_msg = recent[0], recent[1]
    updated_conv = await conv_repo.get_by_id(conversation_id)

    return SendMessageResponse(
        user_message=_msg_to_response(user_msg),
        bot_message=_msg_to_response(bot_msg),
        conversation=ConversationResponse(
            id=updated_conv.id,
            user_id=updated_conv.user_id,
            status=updated_conv.status,
            lead_score=updated_conv.lead_score,
            seller_id=updated_conv.seller_id,
            model_id=updated_conv.model_id,
            started_at=updated_conv.started_at,
            last_message_at=updated_conv.last_message_at,
        ),
    )
