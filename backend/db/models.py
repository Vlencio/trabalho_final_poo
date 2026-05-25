from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class User(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    wa_id: str
    nome: Optional[str] = None
    telefone: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class Seller(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    email: str
    telefone: Optional[str] = None
    ativo: bool
    created_at: datetime


class MotorcycleModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    categoria: str
    preco_base: float
    disponivel: bool


class Conversation(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    seller_id: Optional[int] = None
    model_id: Optional[int] = None
    status: str
    lead_score: Optional[int] = None
    started_at: datetime
    last_message_at: datetime
    ended_at: Optional[datetime] = None


class Message(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    conversation_id: int
    role: str
    content: str
    created_at: datetime


class QualificationSlot(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    conversation_id: int
    slot_name: str
    slot_value: str
    captured_at: datetime


class HandoffEvent(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    conversation_id: int
    seller_id: Optional[int] = None
    motivo: str
    occurred_at: datetime


class LeadScoreHistory(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    conversation_id: int
    score_anterior: Optional[int] = None
    score_novo: int
    changed_at: datetime
