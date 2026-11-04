from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

import app.models  # noqa: F401  (registra todos os models antes de configurar os relacionamentos)
from app.api import agendamentos, auth, clientes, health, servicos, trabalhos
from app.core.config import settings
from app.services.exceptions import (
    ArquivoInvalidoError,
    ConflitoError,
    CredenciaisInvalidasError,
    IntegracaoError,
    NaoEncontradoError,
)

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
app.include_router(auth.router)
app.include_router(servicos.router)
app.include_router(clientes.router)
# Rotas públicas antes das do painel: evita que "/ocupados" seja lido como "/{agendamento_id}".
app.include_router(agendamentos.router_publico)
app.include_router(agendamentos.router)
app.include_router(trabalhos.router_publico)
app.include_router(trabalhos.router)

# Fotos da galeria. check_dir=False: a pasta pode ainda não existir (é criada no primeiro envio).
app.mount(
    "/arquivos",
    StaticFiles(directory=settings.upload_dir, check_dir=False),
    name="arquivos",
)


# Converte os erros de negócio (services/) em respostas HTTP.
@app.exception_handler(NaoEncontradoError)
async def nao_encontrado_handler(_: Request, exc: NaoEncontradoError):
    return JSONResponse(status_code=status.HTTP_404_NOT_FOUND, content={"detail": str(exc)})


@app.exception_handler(ConflitoError)
async def conflito_handler(_: Request, exc: ConflitoError):
    return JSONResponse(status_code=status.HTTP_409_CONFLICT, content={"detail": str(exc)})


@app.exception_handler(ArquivoInvalidoError)
async def arquivo_invalido_handler(_: Request, exc: ArquivoInvalidoError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, content={"detail": str(exc)}
    )


@app.exception_handler(CredenciaisInvalidasError)
async def credenciais_invalidas_handler(_: Request, exc: CredenciaisInvalidasError):
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": str(exc)},
        headers={"WWW-Authenticate": "Bearer"},
    )


@app.exception_handler(IntegracaoError)
async def integracao_handler(_: Request, exc: IntegracaoError):
    return JSONResponse(status_code=status.HTTP_502_BAD_GATEWAY, content={"detail": str(exc)})
