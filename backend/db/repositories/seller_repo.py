from typing import List, Optional
from psycopg.rows import dict_row
from db.pool import pool
from db.models import Seller
from db.repositories.base import BaseRepository


class SellerRepository(BaseRepository[Seller]):

    @property
    def table_name(self) -> str:
        return "sellers"

    @property
    def model(self) -> type[Seller]:
        return Seller

    async def create(self, nome: str, email: str, telefone: Optional[str] = None) -> Seller:
        sql = """
            INSERT INTO sellers (nome, email, telefone)
            VALUES (%s, %s, %s)
            RETURNING *
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (nome, email, telefone))
                row = await cur.fetchone()
                return Seller(**row)

    async def list_active(self) -> List[Seller]:
        sql = "SELECT * FROM sellers WHERE ativo = TRUE ORDER BY nome"
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql)
                rows = await cur.fetchall()
                return [Seller(**row) for row in rows]

    async def get_least_busy(self) -> Optional[Seller]:
        sql = """
            SELECT s.* FROM sellers s
            LEFT JOIN conversations c
                ON c.seller_id = s.id
                AND c.status IN ('qualified', 'handoff')
            WHERE s.ativo = TRUE
            GROUP BY s.id
            ORDER BY COUNT(c.id) ASC, s.id ASC
            LIMIT 1
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql)
                row = await cur.fetchone()
                return Seller(**row) if row else None
