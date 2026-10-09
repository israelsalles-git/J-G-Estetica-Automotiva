from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, Integer, Numeric, String, true
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

    ativo: Mapped[bool] = mapped_column(
        Boolean, 
        nullable=False, 
        default=True, 
        server_default=true()
    )
