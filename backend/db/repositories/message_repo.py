from typing import List
from psycopg.rows import dict_row
from db.pool import pool
from db.models import Message
from db.repositories.base import BaseRepository


class MessageRepository(BaseRepository[Message]):

    @property
    def table_name(self) -> str:
        return "messages"

    @property
    def model(self) -> type[Message]:
        return Message

    async def create(self, conversation_id: int, role: str, content: str) -> Message:
        sql = """
            INSERT INTO messages (conversation_id, role, content)
            VALUES (%s, %s, %s)
            RETURNING *
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id, role, content))
                row = await cur.fetchone()
                return Message(**row)

    async def list_recent(self, conversation_id: int, limit: int = 15) -> List[Message]:
        # subconsulta pega as N mais recentes; ORDER BY ASC externo restaura a ordem cronológica
        sql = """
            SELECT * FROM (
                SELECT * FROM messages
                WHERE conversation_id = %s
                ORDER BY created_at DESC
                LIMIT %s
            ) recent
            ORDER BY created_at ASC
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id, limit))
                rows = await cur.fetchall()
                return [Message(**row) for row in rows]

    async def list_for_conversation(self, conversation_id: int) -> List[Message]:
        sql = """
            SELECT * FROM messages
            WHERE conversation_id = %s
            ORDER BY created_at ASC
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id,))
                rows = await cur.fetchall()
                return [Message(**row) for row in rows]
