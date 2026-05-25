from typing import Optional
from psycopg.rows import dict_row
from db.pool import pool
from db.models import User
from db.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):

    @property
    def table_name(self) -> str:
        return "users"

    @property
    def model(self) -> type[User]:
        return User

    async def create(
        self,
        wa_id: str,
        nome: Optional[str] = None,
        telefone: Optional[str] = None,
    ) -> User:
        sql = """
            INSERT INTO users (wa_id, nome, telefone)
            VALUES (%s, %s, %s)
            RETURNING *
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (wa_id, nome, telefone))
                row = await cur.fetchone()
                return User(**row)

    async def get_by_wa_id(self, wa_id: str) -> Optional[User]:
        sql = "SELECT * FROM users WHERE wa_id = %s"
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (wa_id,))
                row = await cur.fetchone()
                return User(**row) if row else None

    async def get_or_create(self, wa_id: str, nome: Optional[str] = None) -> User:
        existing = await self.get_by_wa_id(wa_id)
        if existing:
            return existing
        return await self.create(wa_id=wa_id, nome=nome)
