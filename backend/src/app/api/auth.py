from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.rate_limit import LIMITE_LOGIN, LIMITE_LOGIN_GOOGLE, limiter
from app.core.security import require_auth
from app.models.usuarios import Usuario
from app.schemas.auth import LoginGoogleRequest, LoginRequest, TokenResponse, UsuarioRead
from app.services import auth as auth_service

#Não há cadastro público: o primeiro admin é criado pelo script app.scripts.criar_admin
router = APIRouter(prefix="/auth", tags=["auth"])


# Os limites contam todas as tentativas (certas e erradas) por IP: freiam a força bruta.
@router.post("/login", response_model=TokenResponse)
@limiter.limit(LIMITE_LOGIN)
def login(request: Request, dados: LoginRequest, db: Session = Depends(get_db)):
    """Troca e-mail e senha pelo token de acesso (JWT)"""
    return auth_service.login(db, dados)


@router.post("/google", response_model=TokenResponse)
@limiter.limit(LIMITE_LOGIN_GOOGLE)
def login_google(request: Request, dados: LoginGoogleRequest, db: Session = Depends(get_db)):
    """Troca o id_token do Google por um token de acesso, só para e-mails da lista fixa"""
    return auth_service.login_google(db, dados.id_token)


@router.get("/me", response_model=UsuarioRead)
def usuario_logado(usuario: Usuario = Depends(require_auth)):
    """Retorna o usuário dono do token"""
    return usuario
