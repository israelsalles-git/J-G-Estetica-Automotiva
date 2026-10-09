from decimal import Decimal
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field

Nome = Annotated[str, Field(min_length=1, max_length=120)]
DuracaoMin = Annotated[int, Field(gt=0, description="Duração em minutos")]
Preco = Annotated[Decimal, Field(ge=0, max_digits=10, decimal_places=2)]


class ServicoCreate(BaseModel):
    nome: Nome
    duracao_min: DuracaoMin
    preco: Preco


#Todos os campos opcionais: só o que for enviado é alterado
class ServicoUpdate(BaseModel):

    nome: Nome | None = None
    duracao_min: DuracaoMin | None = None
    preco: Preco | None = None
    ativo: bool | None = None


class ServicoRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    duracao_min: int
    preco: Decimal
    ativo: bool
