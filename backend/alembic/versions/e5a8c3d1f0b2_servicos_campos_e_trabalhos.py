"""campos do site em servicos (categoria, descricao, destaque) e tabela trabalhos

Revision ID: e5a8c3d1f0b2
Revises: b7e2c94a1f3d
Create Date: 2026-11-02 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e5a8c3d1f0b2'
down_revision: Union[str, Sequence[str], None] = 'b7e2c94a1f3d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Colunas novas com valor padrão, para os serviços já cadastrados continuarem válidos.
    op.add_column('cadser', sa.Column('categoria', sa.String(length=30), server_default='Outros', nullable=False))
    op.add_column('cadser', sa.Column('descricao', sa.String(length=500), nullable=True))
    op.add_column('cadser', sa.Column('destaque', sa.Boolean(), server_default=sa.false(), nullable=False))
    op.create_index(op.f('ix_cadser_categoria'), 'cadser', ['categoria'], unique=False)

    op.create_table('trabalhos',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('titulo', sa.String(length=120), nullable=True),
    sa.Column('descricao', sa.String(length=500), nullable=True),
    sa.Column('categoria', sa.String(length=60), nullable=True),
    sa.Column('data', sa.Date(), nullable=True),
    sa.Column('arquivo', sa.String(length=255), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('trabalhos')
    op.drop_index(op.f('ix_cadser_categoria'), table_name='cadser')
    op.drop_column('cadser', 'destaque')
    op.drop_column('cadser', 'descricao')
    op.drop_column('cadser', 'categoria')
