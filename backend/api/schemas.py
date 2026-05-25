"""Schemas de request e response da API HTTP.

Separados dos modelos de banco (db/models.py) porque a API expoe um
contrato proprio para o frontend, que pode (e deve) ser diferente da
forma como os dados sao armazenados.
"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


# ----- Users -----

class CreateUserRequest(BaseModel):
    wa_id: str = Field(..., min_length=1, max_length=50)
    nome: Optional[str] = Field(None, max_length=100)


class UserResponse(BaseModel):
    id: int
    wa_id: str
    nome: Optional[str]


# ----- Conversations -----

class ConversationResponse(BaseModel):
    id: int
    user_id: int
    status: str
    lead_score: Optional[int]
    seller_id: Optional[int]
    model_id: Optional[int]
    started_at: datetime
    last_message_at: datetime


class ConversationMetricsResponse(BaseModel):
    total_mensagens: int
    msgs_cliente: int
    msgs_bot: int
    score_final: Optional[int]
    status_final: str


# ----- Messages -----

class SendMessageRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)


class MessageResponse(BaseModel):
    id: int
    conversation_id: int
    role: str
    content: str
    created_at: datetime


class SendMessageResponse(BaseModel):
    """Resposta enviada ao Flutter apos uma mensagem do usuario.
    Contem a propria mensagem do usuario, a resposta do bot e o
    estado atualizado da conversa.
    """
    user_message: MessageResponse
    bot_message: MessageResponse
    conversation: ConversationResponse


class MessageListResponse(BaseModel):
    messages: List[MessageResponse]
