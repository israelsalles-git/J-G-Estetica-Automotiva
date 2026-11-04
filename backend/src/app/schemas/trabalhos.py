from datetime import date
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field

Titulo = Annotated[str | None, Field(max_length=120)]
Descricao = Annotated[str | None, Field(max_length=500)]
Categoria = Annotated[str | None, Field(max_length=60)]


class TrabalhoUpdate(BaseModel):
    """Campos de texto. A foto não é trocada aqui: para outra foto, cadastre um trabalho novo."""

    titulo: Titulo = None
    descricao: Descricao = None
    categoria: Categoria = None
    data: date | None = None


class TrabalhoRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    titulo: str | None
    descricao: str | None
    categoria: str | None
    data: date | None
    # Caminho público da foto (ex.: "/arquivos/trabalhos/3f2a...jpg"), servido pela própria API
    imagem_url: str
