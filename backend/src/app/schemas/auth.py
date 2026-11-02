from typing import Annotated, Literal

from pydantic import AfterValidator, BaseModel, ConfigDict, EmailStr, Field


def _normalizar_email(valor: str) -> str:
    """E-mail é comparado sem diferenciar maiúsculas: guarda e busca sempre em minúsculas."""
    return valor.strip().lower()


SENHA_MIN = 8
SENHA_MAX = 128

Nome = Annotated[str, Field(min_length=1, max_length=120)]
Email = Annotated[str, Field(min_length=1, max_length=254), AfterValidator(_normalizar_email)]


class LoginRequest(BaseModel):
    email: Email
    senha: str = Field(min_length=1, max_length=SENHA_MAX)


#Usado só pelo script de cadastro do admin (não há cadastro público)
class UsuarioCreate(BaseModel):
    nome: Nome
    email: Annotated[EmailStr, AfterValidator(_normalizar_email)]
    senha: str = Field(min_length=SENHA_MIN, max_length=SENHA_MAX)


class UsuarioRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    email: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    usuario: UsuarioRead
