from psycopg_pool import AsyncConnectionPool
from trabalho_final_poo.backend.config import settings


pool = AsyncConnectionPool(
    settings.postgres_dsn,
    min_size=2,
    max_size=10,
    open=False
)

async def open_pool() -> None:
    await pool.open()
    await pool.wait()

async def close_pool() -> None:
    await pool.close()


