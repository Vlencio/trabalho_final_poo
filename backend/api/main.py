from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from db.pool import open_pool, close_pool
from api.deps import init_dependencies
from api.routes import users, conversations, messages


@asynccontextmanager
async def lifespan(app: FastAPI):
    await open_pool()
    init_dependencies()
    yield
    await close_pool()


app = FastAPI(
    title="Atendente Shineray - API",
    description="Backend para o chat de atendimento via WhatsApp",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["health"])
async def health() -> dict:
    return {"status": "ok"}


app.include_router(users.router)
app.include_router(conversations.router)
app.include_router(messages.router)
