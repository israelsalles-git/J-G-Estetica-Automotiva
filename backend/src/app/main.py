from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse

import app.models  # noqa: F401  (registra os models no Base.metadata)
from app.api import clientes, health, servicos
from app.core.config import settings
from app.core.database import Base, engine
from app.services.exceptions import ConflitoError, NaoEncontradoError


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
app.include_router(clientes.router)


# Converte os erros de negócio (services/) em respostas HTTP.
@app.exception_handler(NaoEncontradoError)
async def nao_encontrado_handler(_: Request, exc: NaoEncontradoError):
    return JSONResponse(status_code=status.HTTP_404_NOT_FOUND, content={"detail": str(exc)})


@app.exception_handler(ConflitoError)
async def conflito_handler(_: Request, exc: ConflitoError):
    return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": str(exc)})
