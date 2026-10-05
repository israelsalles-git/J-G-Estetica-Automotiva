from contextlib import asynccontextmanager

from fastapi import FastAPI

import app.models  # noqa: F401  (registra os models no Base.metadata)
from app.api import health, servicos
from app.core.config import settings
from app.core.database import Base, engine


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Cria as tabelas que ainda não existem. Trocar por migrations (Alembic) quando o schema evoluir.
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title=settings.app_name, version=settings.app_version, debug=settings.debug, lifespan=lifespan
)

app.include_router(health.router)
app.include_router(servicos.router)


@app.get("/")
def home():
    return {"mensagem": "Minha primeira API"}
