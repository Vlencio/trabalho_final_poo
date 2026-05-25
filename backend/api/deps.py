from anthropic import AsyncAnthropic

from config import settings
from db.repositories.user_repo import UserRepository
from db.repositories.conversation_repo import ConversationRepository
from db.repositories.message_repo import MessageRepository
from db.repositories.seller_repo import SellerRepository
from db.repositories.motorcycle_model_repo import MotorcycleModelRepository
from db.repositories.handoff_event_repo import HandoffEventRepository
from db.repositories.qualification_slot_repo import QualificationSlotRepository
from bot.responder import BotResponder


_user_repo: UserRepository | None = None
_conversation_repo: ConversationRepository | None = None
_message_repo: MessageRepository | None = None
_seller_repo: SellerRepository | None = None
_model_repo: MotorcycleModelRepository | None = None
_handoff_repo: HandoffEventRepository | None = None
_slot_repo: QualificationSlotRepository | None = None
_bot: BotResponder | None = None
_anthropic_client: AsyncAnthropic | None = None


def init_dependencies() -> None:
    global _user_repo, _conversation_repo, _message_repo
    global _seller_repo, _model_repo, _handoff_repo, _slot_repo
    global _bot, _anthropic_client

    _user_repo = UserRepository()
    _conversation_repo = ConversationRepository()
    _message_repo = MessageRepository()
    _seller_repo = SellerRepository()
    _model_repo = MotorcycleModelRepository()
    _handoff_repo = HandoffEventRepository()
    _slot_repo = QualificationSlotRepository()

    _anthropic_client = AsyncAnthropic(api_key=settings.anthropic_api_key)

    _bot = BotResponder(
        client=_anthropic_client,
        message_repo=_message_repo,
        slot_repo=_slot_repo,
        conv_repo=_conversation_repo,
        handoff_repo=_handoff_repo,
        seller_repo=_seller_repo,
        model_repo=_model_repo,
    )


def get_user_repo() -> UserRepository:
    assert _user_repo is not None, "Dependencias nao inicializadas"
    return _user_repo


def get_conversation_repo() -> ConversationRepository:
    assert _conversation_repo is not None, "Dependencias nao inicializadas"
    return _conversation_repo


def get_message_repo() -> MessageRepository:
    assert _message_repo is not None, "Dependencias nao inicializadas"
    return _message_repo


def get_bot() -> BotResponder:
    assert _bot is not None, "Dependencias nao inicializadas"
    return _bot
