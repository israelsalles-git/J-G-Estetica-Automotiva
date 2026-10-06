from sqlalchemy import CheckConstraint, Integer, String, Boolean, true
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Cliente(Base):
    """Cliente da estética."""

    __tablename__ = "cadcli"
    __table_args__ = (
        CheckConstraint("char_length(cpf_cnpj) IN (11, 14)", name="ck_cadcli_cpf_cnpj_tamanho"),
    )

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True
    )

    nome: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
        index=True
    )

    cpf_cnpj: Mapped[str | None] = mapped_column(
        String(14),
        nullable=True,
        unique=True
    )

    ativo: Mapped[bool] = mapped_column(
        Boolean, 
        nullable=False, 
        default=True, 
        server_default=true()
    )