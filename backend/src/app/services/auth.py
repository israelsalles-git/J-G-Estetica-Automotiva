from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import criar_token, gerar_hash_senha, verificar_senha
from app.models.usuarios import Usuario
from app.repositories import usuarios as usuarios_repository
from app.schemas.auth import LoginRequest, TokenResponse, UsuarioCreate, UsuarioRead
from app.services.exceptions import ConflitoError, CredenciaisInvalidasError, IntegracaoError

# Mesma mensagem para e-mail inexistente, senha errada e usuário inativo:
# a resposta não revela quais e-mails estão cadastrados.
MENSAGEM_CREDENCIAIS_INVALIDAS = "E-mail ou senha incorretos"
MENSAGEM_CONTA_GOOGLE_INVALIDA = "Conta Google não autorizada"

# Usado quando o e-mail não existe, para o login levar o mesmo tempo que uma senha errada.
_HASH_FICTICIO = gerar_hash_senha("senha-ficticia-so-para-igualar-o-tempo")


def autenticar(db: Session, email: str, senha: str) -> Usuario:
    usuario = usuarios_repository.obter_por_email(db, email)
    if usuario is None:
        verificar_senha(senha, _HASH_FICTICIO)
        raise CredenciaisInvalidasError(MENSAGEM_CREDENCIAIS_INVALIDAS)
    if not verificar_senha(senha, usuario.senha_hash) or not usuario.ativo:
        raise CredenciaisInvalidasError(MENSAGEM_CREDENCIAIS_INVALIDAS)
    return usuario


def login(db: Session, dados: LoginRequest) -> TokenResponse:
    """Confere e-mail e senha e devolve o token de acesso com os dados do usuário."""
    usuario = autenticar(db, dados.email, dados.senha)
    return TokenResponse(
        access_token=criar_token(usuario.id), usuario=UsuarioRead.model_validate(usuario)
    )


def login_google(db: Session, id_token_str: str) -> TokenResponse:
    """Confere o id_token do Google. Só entra quem está na lista fixa e tem usuário ativo."""
    info = _verificar_id_token(id_token_str)
    email = str(info.get("email", "")).strip().lower()
    if not info.get("email_verified") or email not in settings.google_admin_emails:
        raise CredenciaisInvalidasError(MENSAGEM_CONTA_GOOGLE_INVALIDA)
    usuario = usuarios_repository.obter_por_email(db, email)
    if usuario is None or not usuario.ativo:
        raise CredenciaisInvalidasError(MENSAGEM_CONTA_GOOGLE_INVALIDA)
    return TokenResponse(
        access_token=criar_token(usuario.id), usuario=UsuarioRead.model_validate(usuario)
    )


def _verificar_id_token(id_token_str: str) -> dict:
    if not settings.google_client_id:
        raise CredenciaisInvalidasError("Login com Google não está configurado")
    # Import tardio: o módulo sobe mesmo sem as bibliotecas; a falta vira erro claro (não 500).
    try:
        from google.auth.exceptions import TransportError
        from google.auth.transport import requests as google_requests
        from google.oauth2 import id_token
    except ImportError as exc:
        raise IntegracaoError("Login com Google indisponível: dependência não instalada") from exc

    try:
        return id_token.verify_oauth2_token(
            id_token_str, google_requests.Request(), settings.google_client_id
        )
    except ValueError as exc:
        # Token inválido, expirado ou emitido para outro Client ID.
        raise CredenciaisInvalidasError(MENSAGEM_CONTA_GOOGLE_INVALIDA) from exc
    except TransportError as exc:
        raise IntegracaoError("Não foi possível confirmar a conta Google") from exc


def cadastrar(db: Session, dados: UsuarioCreate) -> Usuario:
    """Cria um usuário com a senha já em hash. Usado pelo script criar_admin."""
    if usuarios_repository.obter_por_email(db, dados.email) is not None:
        raise ConflitoError("Já existe um usuário com este e-mail")
    usuario = Usuario(nome=dados.nome, email=dados.email, senha_hash=gerar_hash_senha(dados.senha))
    return usuarios_repository.salvar(db, usuario)
