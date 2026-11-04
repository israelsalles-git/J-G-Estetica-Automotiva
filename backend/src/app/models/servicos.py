from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, Integer, Numeric, String, false, true
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base

#Modelo Serviços 
class Servico(Base):

    __tablename__ = "cadser"
    
    #validações
    __table_args__ = (
        CheckConstraint("duracao_min > 0", name="ck_cadser_duracao_positiva"),
        CheckConstraint("preco >= 0", name="ck_cadser_preco_nao_negativo"),
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

    duracao_min: Mapped[int] = mapped_column(
        Integer, 
        nullable=False
    )

    preco: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), 
        nullable=False
    )

    # Categoria do catálogo do site (ex.: Carro, Moto); o site agrupa os serviços por ela
    categoria: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default="Outros",
        server_default="Outros",
        index=True
    )

    descricao: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    # Serviço em destaque no site (aparece com selo)
    destaque: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
        server_default=false()
    )

    ativo: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
        server_default=true()
    )
