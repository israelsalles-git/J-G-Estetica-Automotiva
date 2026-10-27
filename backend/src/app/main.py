from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

import app.models  # noqa: F401  (registra todos os models antes de configurar os relacionamentos)
from app.api import agendamentos, clientes, health, servicos
from app.core.config import settings
from app.services.exceptions import ConflitoError, IntegracaoError, NaoEncontradoError

# As tabelas são criadas/alteradas pelas migrations (alembic upgrade head), não na subida da API.
app = FastAPI(title=settings.app_name, version=settings.app_version, debug=settings.debug)

# Libera o site (Flutter Web, outra origem) a chamar a API pelo navegador.
# Sem allow_credentials: a autenticação é pelo header Authorization, não por cookie.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_origin_regex=settings.cors_origin_regex,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(servicos.router)
app.include_router(clientes.router)
app.include_router(agendamentos.router)


# Converte os erros de negócio (services/) em respostas HTTP.
@app.exception_handler(NaoEncontradoError)
async def nao_encontrado_handler(_: Request, exc: NaoEncontradoError):
    return JSONResponse(status_code=status.HTTP_404_NOT_FOUND, content={"detail": str(exc)})


@app.exception_handler(ConflitoError)
async def conflito_handler(_: Request, exc: ConflitoError):
    return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": str(exc)})


@app.exception_handler(IntegracaoError)
async def integracao_handler(_: Request, exc: IntegracaoError):
    return JSONResponse(status_code=status.HTTP_502_BAD_GATEWAY, content={"detail": str(exc)})
