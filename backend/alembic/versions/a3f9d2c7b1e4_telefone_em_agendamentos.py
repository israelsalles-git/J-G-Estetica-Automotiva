"""telefone do cliente em agendamentos

Revision ID: a3f9d2c7b1e4
Revises: e5a8c3d1f0b2
Create Date: 2026-11-10 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3f9d2c7b1e4'
down_revision: Union[str, Sequence[str], None] = 'e5a8c3d1f0b2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Anulável: os agendamentos feitos antes desta versão não têm telefone.
    op.add_column('cadage', sa.Column('telefone', sa.String(length=11), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('cadage', 'telefone')
