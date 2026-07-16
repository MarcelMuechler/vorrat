"""add category_id to shopping_list_items

Revision ID: c1969f63762b
Revises: 7fe0e9f090c1
Create Date: 2026-07-16 08:59:44.675642

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c1969f63762b'
down_revision: Union[str, Sequence[str], None] = '7fe0e9f090c1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # SQLite can't ALTER a constraint onto an existing table -- batch mode
    # does the copy-and-recreate dance for us (matches
    # c92c18306a9a_category_as_a_real_entity.py).
    with op.batch_alter_table('shopping_list_items') as batch_op:
        batch_op.add_column(sa.Column('category_id', sa.Integer(), nullable=True))
        batch_op.create_foreign_key(
            'fk_shopping_list_items_category_id_categories', 'categories', ['category_id'], ['id']
        )


def downgrade() -> None:
    """Downgrade schema."""
    with op.batch_alter_table('shopping_list_items') as batch_op:
        batch_op.drop_constraint(
            'fk_shopping_list_items_category_id_categories', type_='foreignkey'
        )
        batch_op.drop_column('category_id')
