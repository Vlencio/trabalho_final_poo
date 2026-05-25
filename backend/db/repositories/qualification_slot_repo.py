from typing import List
from psycopg.rows import dict_row
from db.pool import pool
from db.models import QualificationSlot


class QualificationSlotRepository:

    async def upsert(self, conversation_id: int, slot_name: str, slot_value: str) -> QualificationSlot:
        # ON CONFLICT atualiza o valor caso o cliente corrija um dado já enviado
        sql = """
            INSERT INTO qualification_slots (conversation_id, slot_name, slot_value)
            VALUES (%s, %s, %s)
            ON CONFLICT (conversation_id, slot_name)
            DO UPDATE SET slot_value  = EXCLUDED.slot_value,
                          captured_at = CURRENT_TIMESTAMP
            RETURNING *
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id, slot_name, slot_value))
                row = await cur.fetchone()
                return QualificationSlot(**row)

    async def list_for_conversation(self, conversation_id: int) -> List[QualificationSlot]:
        sql = """
            SELECT * FROM qualification_slots
            WHERE conversation_id = %s
            ORDER BY captured_at ASC
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id,))
                rows = await cur.fetchall()
                return [QualificationSlot(**row) for row in rows]

    async def count_for_conversation(self, conversation_id: int) -> int:
        sql = """
            SELECT COUNT(*) AS total
            FROM qualification_slots
            WHERE conversation_id = %s
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id,))
                row = await cur.fetchone()
                return row["total"]
