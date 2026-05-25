from typing import Optional
from psycopg.rows import dict_row
from db.pool import pool
from db.models import Conversation
from db.repositories.base import BaseRepository


class ConversationRepository(BaseRepository[Conversation]):

    @property
    def table_name(self) -> str:
        return "conversations"

    @property
    def model(self) -> type[Conversation]:
        return Conversation

    async def create(self, user_id: int) -> Conversation:
        sql = """
            INSERT INTO conversations (user_id)
            VALUES (%s)
            RETURNING *
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (user_id,))
                row = await cur.fetchone()
                return Conversation(**row)

    async def get_active_for_user(self, user_id: int) -> Optional[Conversation]:
        sql = """
            SELECT * FROM conversations
            WHERE user_id = %s AND status = 'active'
            ORDER BY last_message_at DESC
            LIMIT 1
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (user_id,))
                row = await cur.fetchone()
                return Conversation(**row) if row else None

    async def get_or_create_active(self, user_id: int) -> Conversation:
        existing = await self.get_active_for_user(user_id)
        if existing:
            return existing
        return await self.create(user_id=user_id)

    async def update_score(self, id: int, new_score: int) -> None:
        sql = "UPDATE conversations SET lead_score = %s WHERE id = %s"
        async with pool.connection() as conn:
            async with conn.cursor() as cur:
                await cur.execute(sql, (new_score, id))

    async def update_status(self, id: int, new_status: str) -> None:
        sql = "UPDATE conversations SET status = %s WHERE id = %s"
        async with pool.connection() as conn:
            async with conn.cursor() as cur:
                await cur.execute(sql, (new_status, id))

    async def assign_seller(self, id: int, seller_id: int) -> None:
        sql = "UPDATE conversations SET seller_id = %s WHERE id = %s"
        async with pool.connection() as conn:
            async with conn.cursor() as cur:
                await cur.execute(sql, (seller_id, id))

    async def set_model(self, id: int, model_id: int) -> None:
        sql = "UPDATE conversations SET model_id = %s WHERE id = %s"
        async with pool.connection() as conn:
            async with conn.cursor() as cur:
                await cur.execute(sql, (model_id, id))
