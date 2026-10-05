import secrets

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import settings

bearer_scheme = HTTPBearer(auto_error=False)


def require_auth(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> None:
    """Exige o header `Authorization: Bearer <API_TOKEN>`.

    Autenticação provisória por token fixo; substituir por login/JWT quando houver usuários.
    """
    if (
        not settings.api_token
        or credentials is None
        or not secrets.compare_digest(credentials.credentials, settings.api_token)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Não autenticado",
            headers={"WWW-Authenticate": "Bearer"},
        )
