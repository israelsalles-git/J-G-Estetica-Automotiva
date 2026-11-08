import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy.exc import IntegrityError

import app.models  # noqa: F401  (registra todos os models antes de configurar os relacionamentos)
from app.api import agendamentos, auth, clientes, health, servicos, trabalhos
from app.core.config import settings
from app.services.exceptions import (
    ArquivoInvalidoError,
    ConfiguracaoError,
    ConflitoError,
    CredenciaisInvalidasError,
    IntegracaoError,
    NaoEncontradoError,
)

logger = logging.getLogger(__name__)

TAMANHO_MIN_JWT_SECRET = 32  # abaixo disso o PyJWT avisa que a chave HS256 é fraca


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Confere a configuração na subida. Em produção, sem JWT_SECRET a API não sobe."""
    if not settings.jwt_secret:
        if settings.environment.strip().lower() == "production":
            raise RuntimeError("JWT_SECRET é obrigatório em produção")
        logger.warning("JWT_SECRET vazio: login e rotas protegidas ficam indisponíveis")
    elif len(settings.jwt_secret) < TAMANHO_MIN_JWT_SECRET:
        logger.warning(
            "JWT_SECRET com menos de %d caracteres: use um segredo mais longo",
            TAMANHO_MIN_JWT_SECRET,
        )
    yield


# As tabelas são criadas/alteradas pelas migrations (alembic upgrade head), não na subida da API.
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    debug=settings.debug,
    lifespan=lifespan,
)

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


@app.exception_handler(ConfiguracaoError)
async def configuracao_handler(_: Request, exc: ConfiguracaoError):
    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content={"detail": str(exc)}
    )


# Rede de segurança: o banco recusou a gravação (UNIQUE, CHECK, FK) mesmo depois das validações
# do service, por exemplo dois cadastros com o mesmo CPF ao mesmo tempo. O rollback já foi feito
# pelo commit() de core/database.py. A mensagem é neutra porque nem todo caso é duplicidade.
@app.exception_handler(IntegrityError)
async def integridade_handler(_: Request, exc: IntegrityError):
    logger.warning("Banco recusou a operação: %s", exc.orig)
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={
            "detail": "Os dados conflitam com um registro já existente (ex.: CPF/CNPJ duplicado)"
        },
    )
