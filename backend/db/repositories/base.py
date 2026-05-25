from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Optional, List
from pydantic import BaseModel
from psycopg.rows import dict_row
from db.pool import pool


T = TypeVar("T", bound=BaseModel)


class BaseRepository(ABC, Generic[T]):

    @property
    @abstractmethod
    def table_name(self) -> str: ...

    @property
    @abstractmethod
    def model(self) -> type[T]: ...

    @abstractmethod
    async def create(self, *args, **kwargs) -> T: ...

    async def get_by_id(self, id: int) -> Optional[T]:
        sql = f"SELECT * FROM {self.table_name} WHERE id = %s"
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (id,))
                row = await cur.fetchone()
                return self.model(**row) if row else None

    async def list_all(self, limit: int = 100) -> List[T]:
        sql = f"SELECT * FROM {self.table_name} ORDER BY id DESC LIMIT %s"
        async with pool.connection() as conn:
            async with conn.cursor(row_factory=dict_row) as cur:
                await cur.execute(sql, (limit,))
                rows = await cur.fetchall()
                return [self.model(**row) for row in rows]

    async def delete(self, id: int) -> bool:
        sql = f"DELETE FROM {self.table_name} WHERE id = %s"
        async with pool.connection() as conn:
            async with conn.cursor() as cur:
                await cur.execute(sql, (id,))
                return cur.rowcount > 0
