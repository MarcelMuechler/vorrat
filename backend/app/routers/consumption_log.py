from datetime import date

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, contains_eager

from app.db import get_db
from app.models import ConsumptionLog, Product
from app.schemas import ConsumptionLogItem, ConsumptionLogRead

router = APIRouter(prefix="/api/consumption-log", tags=["consumption-log"])


@router.get("", response_model=list[ConsumptionLogItem])
def list_consumption_log(
    since: date | None = None,
    until: date | None = None,
    reason: str | None = None,
    db: Session = Depends(get_db),
):
    query = (
        db.query(ConsumptionLog)
        .join(Product)
        .options(contains_eager(ConsumptionLog.product))
    )
    if since is not None:
        query = query.filter(ConsumptionLog.created_at >= since)
    if until is not None:
        query = query.filter(ConsumptionLog.created_at <= until)
    if reason is not None:
        query = query.filter(ConsumptionLog.reason == reason)
    return [
        ConsumptionLogItem(
            **ConsumptionLogRead.model_validate(entry).model_dump(),
            product_name=entry.product.name,
        )
        for entry in query.order_by(ConsumptionLog.created_at.desc()).all()
    ]
