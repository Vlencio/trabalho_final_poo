from typing import List
from psycopg.rows import dict_row
from db.pool import pool
from db.models import LeadScoreHistory
from db.repositories.base import BaseRepository


class LeadScoreHistoryRepository(BaseRepository[LeadScoreHistory]):

    @property
    def table_name(self) -> str:
        return "lead_score_history"

    @property
    def model(self) -> type[LeadScoreHistory]:
        return LeadScoreHistory

    async def create(self, *args, **kwargs):
        # populada pelo trigger trg_audit_lead_score; use ConversationRepository.update_score()
        raise NotImplementedError

    async def list_for_conversation(self, conversation_id: int) -> List[LeadScoreHistory]:
        sql = """
            SELECT * FROM lead_score_history
            WHERE conversation_id = %s
            ORDER BY changed_at ASC
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (conversation_id,))
                rows = await cur.fetchall()
                return [LeadScoreHistory(**row) for row in rows]
