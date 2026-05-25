import asyncio
from pathlib import Path
from db.pool import pool, open_pool, close_pool


SQL_DIR = Path(__file__).parent / "sql"

# functions precisam existir antes dos triggers que as chamam
SQL_FILES = [
    "01_schema.sql",
    "02_views.sql",
    "04_functions.sql",
    "03_triggers.sql",
]


async def reset_schema() -> None:
    async with pool.connection() as conn:
        async with conn.cursor() as cur:
            await cur.execute("DROP SCHEMA IF EXISTS public CASCADE")
            await cur.execute("CREATE SCHEMA public")
    print("schema public resetado")


async def run_sql_files() -> None:
    async with pool.connection() as conn:
        for filename in SQL_FILES:
            path = SQL_DIR / filename
            sql = path.read_text(encoding="utf-8")
            async with conn.cursor() as cur:
                await cur.execute(sql)
            print(f"executado: {filename}")


async def seed_basic_data() -> None:
    async with pool.connection() as conn:
        async with conn.cursor() as cur:
            await cur.execute("""
                INSERT INTO sellers (nome, email, telefone) VALUES
                ('Carlos Silva',   'carlos@shineray.com', '34999990001'),
                ('Ana Oliveira',   'ana@shineray.com',    '34999990002'),
                ('Bruno Martins',  'bruno@shineray.com',  '34999990003')
            """)

            await cur.execute("""
                INSERT INTO motorcycle_models (nome, categoria, preco_base) VALUES
                ('Shineray XY 150',      'street',   12500.00),
                ('Shineray XY 250',      'naked',    18900.00),
                ('Shineray Worker 125',  'cargo',    10500.00),
                ('Shineray Phoenix 50',  'scooter',   8900.00),
                ('Shineray Trail 200',   'trail',    16200.00),
                ('Shineray Jet 50',      'scooter',   7800.00)
            """)
    print("dados de seed inseridos")


async def main() -> None:
    await open_pool()
    try:
        await reset_schema()
        await run_sql_files()
        await seed_basic_data()
        print("banco inicializado com sucesso")
    finally:
        await close_pool()


if __name__ == "__main__":
    asyncio.run(main())
