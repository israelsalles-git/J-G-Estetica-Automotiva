from sqlalchemy import Boolean, Integer, String, true
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


#Modelo Usuários (quem acessa o painel admin)
class Usuario(Base):

    __tablename__ = "cadusu"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True
    )

    nome: Mapped[str] = mapped_column(
        String(120),
        nullable=False
    )

    #Guardado sempre em minúsculas
    email: Mapped[str] = mapped_column(
        String(254),
        nullable=False,
        unique=True
    )

    #Hash argon2 da senha; a senha em texto nunca é salva
    senha_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    ativo: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
        server_default=true()
    )
