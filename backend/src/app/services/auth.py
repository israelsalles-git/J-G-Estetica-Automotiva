from sqlalchemy.orm import Session

from app.core.security import criar_token, gerar_hash_senha, verificar_senha
from app.models.usuarios import Usuario
from app.repositories import usuarios as usuarios_repository
from app.schemas.auth import LoginRequest, TokenResponse, UsuarioCreate, UsuarioRead
from app.services.exceptions import ConflitoError, CredenciaisInvalidasError

# Mesma mensagem para e-mail inexistente, senha errada e usuário inativo:
# a resposta não revela quais e-mails estão cadastrados.
MENSAGEM_CREDENCIAIS_INVALIDAS = "E-mail ou senha incorretos"

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


def cadastrar(db: Session, dados: UsuarioCreate) -> Usuario:
    """Cria um usuário com a senha já em hash. Usado pelo script criar_admin."""
    if usuarios_repository.obter_por_email(db, dados.email) is not None:
        raise ConflitoError("Já existe um usuário com este e-mail")
    usuario = Usuario(nome=dados.nome, email=dados.email, senha_hash=gerar_hash_senha(dados.senha))
    return usuarios_repository.salvar(db, usuario)
