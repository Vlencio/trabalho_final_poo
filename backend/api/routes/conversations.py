"""Rotas relacionadas a conversas."""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from psycopg.rows import dict_row

from db.pool import pool
from db.repositories.conversation_repo import (
    ConversationRepository,
)
from api.deps import get_conversation_repo
from api.schemas import (
    ConversationResponse,
    ConversationMetricsResponse,
)


router = APIRouter(prefix="/conversations", tags=["conversations"])


def _to_response(conv) -> ConversationResponse:
    return ConversationResponse(
        id=conv.id,
        user_id=conv.user_id,
        status=conv.status,
        lead_score=conv.lead_score,
        seller_id=conv.seller_id,
        model_id=conv.model_id,
        started_at=conv.started_at,
        last_message_at=conv.last_message_at,
    )


@router.get("", response_model=List[ConversationResponse])
async def list_conversations(
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> List[ConversationResponse]:
    """Lista as conversas mais recentes (usado pela tela do vendedor)."""
    convs = await repo.list_all(limit=50)
    return [_to_response(c) for c in convs]


@router.get("/{conversation_id}", response_model=ConversationResponse)
async def get_conversation(
    conversation_id: int,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> ConversationResponse:
    conv = await repo.get_by_id(conversation_id)
    if conv is None:
        raise HTTPException(status_code=404, detail="Conversa nao encontrada")
    return _to_response(conv)


@router.post("/by-user/{user_id}", response_model=ConversationResponse)
async def get_or_create_active(
    user_id: int,
    repo: ConversationRepository = Depends(get_conversation_repo),
) -> ConversationResponse:
    """Retorna a conversa ativa do usuario, criando uma nova se nao existir.
    Chamado pelo Flutter quando o chat e aberto.
    """
    conv = await repo.get_or_create_active(user_id=user_id)
    return _to_response(conv)


@router.get("/{conversation_id}/metrics", response_model=ConversationMetricsResponse)
async def get_metrics(conversation_id: int) -> ConversationMetricsResponse:
    """Metricas da conversa (chama a function fn_conversation_metrics)."""
    sql = "SELECT * FROM fn_conversation_metrics(%s)"
    async with pool.connection() as conn:
        async with conn.cursor(row_factory=dict_row) as cur:
            await cur.execute(sql, (conversation_id,))
            row = await cur.fetchone()

    if row is None:
        raise HTTPException(status_code=404, detail="Conversa sem dados")

    return ConversationMetricsResponse(
        total_mensagens=row["total_mensagens"] or 0,
        msgs_cliente=row["msgs_cliente"] or 0,
        msgs_bot=row["msgs_bot"] or 0,
        score_final=row["score_final"],
        status_final=row["status_final"],
    )
