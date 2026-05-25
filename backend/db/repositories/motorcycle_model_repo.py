from typing import List, Optional
from psycopg.rows import dict_row
from db.pool import pool
from db.models import MotorcycleModel
from db.repositories.base import BaseRepository


class MotorcycleModelRepository(BaseRepository[MotorcycleModel]):

    @property
    def table_name(self) -> str:
        return "motorcycle_models"

    @property
    def model(self) -> type[MotorcycleModel]:
        return MotorcycleModel

    async def create(self, nome: str, categoria: str, preco_base: float) -> MotorcycleModel:
        sql = """
            INSERT INTO motorcycle_models (nome, categoria, preco_base)
            VALUES (%s, %s, %s)
            RETURNING *
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (nome, categoria, preco_base))
                row = await cur.fetchone()
                return MotorcycleModel(**row)

    async def list_available(self) -> List[MotorcycleModel]:
        sql = """
            SELECT * FROM motorcycle_models
            WHERE disponivel = TRUE
            ORDER BY preco_base
        """
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql)
                rows = await cur.fetchall()
                return [MotorcycleModel(**row) for row in rows]

    async def get_by_name(self, nome: str) -> Optional[MotorcycleModel]:
        sql = "SELECT * FROM motorcycle_models WHERE LOWER(nome) = LOWER(%s)"
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (nome,))
                row = await cur.fetchone()
                return MotorcycleModel(**row) if row else None
