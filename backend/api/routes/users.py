"""Rotas relacionadas a usuarios."""
from fastapi import APIRouter, Depends

from db.repositories.user_repo import UserRepository
from api.deps import get_user_repo
from api.schemas import (
    CreateUserRequest,
    UserResponse,
)


router = APIRouter(prefix="/users", tags=["users"])


@router.post("", response_model=UserResponse)
async def create_or_get_user(
    payload: CreateUserRequest,
    repo: UserRepository = Depends(get_user_repo),
) -> UserResponse:
    """Identifica ou cria um usuario pelo wa_id.

    Usado no inicio do fluxo: quando o cliente abre o chat no Flutter,
    o app envia o wa_id (numero de telefone simulado) e recebe o user_id
    que usara nas requisicoes seguintes.
    """
    user = await repo.get_or_create(wa_id=payload.wa_id, nome=payload.nome)
    return UserResponse(id=user.id, wa_id=user.wa_id, nome=user.nome)
