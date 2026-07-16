from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import Product, ProductBarcode
from app.off_client import lookup_off
from app.schemas import ProductRead
from app.utils import normalize_barcode

router = APIRouter(prefix="/api/barcode", tags=["barcode"])


@router.get("/{code}")
async def lookup_barcode(code: str, db: Session = Depends(get_db)):
    code = normalize_barcode(code) or code
    product = db.query(Product).filter(Product.barcode == code).first()
    if not product:
        # Fall back to a product's alternate/extra codes (#208) -- e.g. a
        # different pack size or a regional/reprinted barcode for the same
        # item -- before treating this as a genuine miss and hitting OFF.
        extra = db.query(ProductBarcode).filter(ProductBarcode.code == code).first()
        if extra:
            product = db.get(Product, extra.product_id)
    if product:
        return {"source": "local", "product": ProductRead.model_validate(product)}

    off_product = await lookup_off(code)
    if off_product:
        return {"source": "off", "product": off_product}

    raise HTTPException(404, {"source": "none"})
