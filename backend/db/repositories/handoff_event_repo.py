from typing import List, Optional
from psycopg.rows import dict_row
from db.pool import pool
from db.models import HandoffEvent
from db.repositories.base import BaseRepository


class HandoffEventRepository(BaseRepository[HandoffEvent]):

    @property
    def table_name(self) -> str:
        return "handoff_events"

    @property
    def model(self) -> type[HandoffEvent]:
        return HandoffEvent

    async def create(
        self,
        conversation_id: int,
        motivo: str,
        seller_id: Optional[int] = None,
    ) -> HandoffEvent:
        sql = """
            INSERT INTO handoff_events (conversation_id, seller_id, motivo)
            VALUES (%s, %s, %s)
            RETURNING *
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id, seller_id, motivo))
                row = await cur.fetchone()
                return HandoffEvent(**row)

    async def list_for_conversation(self, conversation_id: int) -> List[HandoffEvent]:
        sql = """
            SELECT * FROM handoff_events
            WHERE conversation_id = %s
            ORDER BY occurred_at ASC
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id,))
                rows = await cur.fetchall()
                return [HandoffEvent(**row) for row in rows]
