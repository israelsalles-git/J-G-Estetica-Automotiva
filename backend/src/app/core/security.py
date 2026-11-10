from datetime import datetime, timedelta, timezone

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pwdlib import PasswordHash
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.models.usuarios import Usuario
from app.repositories import usuarios as usuarios_repository
from app.services.exceptions import ConfiguracaoError

ALGORITMO_JWT = "HS256"

password_hash = PasswordHash.recommended()  # argon2
bearer_scheme = HTTPBearer(auto_error=False)


def gerar_hash_senha(senha: str) -> str:
    return password_hash.hash(senha)


def verificar_senha(senha: str, senha_hash: str) -> bool:
    return password_hash.verify(senha, senha_hash)


def criar_token(usuario_id: int) -> str:
    """Gera o JWT de acesso, válido por JWT_EXPIRA_MIN minutos."""
    if not settings.jwt_secret:
        raise ConfiguracaoError("Login indisponível: o servidor está sem Token configurado")
    expira = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expira_min)
    return jwt.encode(
        {"sub": str(usuario_id), "exp": expira}, settings.jwt_secret, algorithm=ALGORITMO_JWT
    )


def require_auth(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    """
    Exige o header `Authorization: Bearer <JWT>` e devolve o usuário logado.

    Token ausente, inválido, expirado ou de usuário inativo/removido -> 401.
    """
    nao_autenticado = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não autenticado",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not settings.jwt_secret or credentials is None:
        raise nao_autenticado

    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.jwt_secret,
            algorithms=[ALGORITMO_JWT],
            options={"require": ["exp", "sub"]},
        )
        usuario_id = int(payload["sub"])
    except (jwt.InvalidTokenError, ValueError):
        raise nao_autenticado

    usuario = usuarios_repository.obter(db, usuario_id)
    if usuario is None or not usuario.ativo:
        raise nao_autenticado
    return usuario
