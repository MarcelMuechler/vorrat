import time

import httpx

from app.config import settings

# In-memory lookup cache, keyed by barcode -> (expiry_monotonic, result).
# Deliberately per-process and unbounded-by-persistence: it resets on
# restart, which is fine for a cache of network lookups on a single-process
# app. lookup_off is a plain `async def` awaited on the FastAPI event loop
# (not dispatched to the threadpool, which is only for sync endpoints), so
# there's no real concurrent mutation of _CACHE across OS threads and no
# lock is needed here.
_CACHE: dict[str, tuple[float, dict | None]] = {}
_TTL_FOUND_SECONDS = 24 * 60 * 60
_TTL_NOT_FOUND_SECONDS = 60 * 60
_MAX_ENTRIES = 1000


def _cache_get(barcode: str) -> tuple[bool, dict | None]:
    """Returns (hit, result). A stale entry counts as a miss and is dropped."""
    entry = _CACHE.get(barcode)
    if entry is None:
        return False, None
    expiry, result = entry
    if time.monotonic() >= expiry:
        del _CACHE[barcode]
        return False, None
    return True, result


def _cache_set(barcode: str, result: dict | None) -> None:
    ttl = _TTL_FOUND_SECONDS if result is not None else _TTL_NOT_FOUND_SECONDS
    _CACHE[barcode] = (time.monotonic() + ttl, result)
    if len(_CACHE) > _MAX_ENTRIES:
        _evict()


def _evict() -> None:
    """Drop expired entries first, then the oldest-expiring ones until back at the cap."""
    now = time.monotonic()
    for key in [k for k, (expiry, _) in _CACHE.items() if expiry <= now]:
        del _CACHE[key]
    overflow = len(_CACHE) - _MAX_ENTRIES
    if overflow > 0:
        oldest = sorted(_CACHE.items(), key=lambda kv: kv[1][0])[:overflow]
        for key, _ in oldest:
            del _CACHE[key]


async def lookup_off(barcode: str) -> dict | None:
    """Look up a barcode on Open Food Facts. Returns a Product-shaped dict or None.

    Never raises: any network error, timeout, or "not found" response from OFF
    is treated the same way as a genuine miss. Results are cached in-process
    for a while (see _TTL_*_SECONDS) so repeated scans of the same barcode
    don't hit the network every time.
    """
    hit, cached = _cache_get(barcode)
    if hit:
        return cached

    result = await _fetch_off(barcode)
    _cache_set(barcode, result)
    return result


async def _fetch_off(barcode: str) -> dict | None:
    url = f"{settings.off_base_url}/api/v2/product/{barcode}.json"
    headers = {"User-Agent": settings.off_user_agent}
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(url, headers=headers)
            response.raise_for_status()
            data = response.json()
    except (httpx.HTTPError, ValueError):
        # ValueError covers response.json() raising JSONDecodeError, e.g. OFF
        # returning a 200 with an HTML rate-limit/maintenance page instead of
        # JSON — should be treated as a miss too, not an unhandled 500.
        return None

    if data.get("status") != 1:
        return None

    off_product = data.get("product", {})
    name = off_product.get("product_name") or off_product.get("product_name_en")
    if not name:
        return None

    category = (off_product.get("categories") or "").split(",")[0].strip() or None
    image_url = off_product.get("image_front_small_url") or off_product.get("image_url")

    # OFF already normalizes the free-text "quantity" field (e.g. "33 cl")
    # into a numeric product_quantity + unit when its data is populated --
    # no need to parse the free-text version ourselves. Both are frequently
    # missing/empty for a given product, hence the permissive fallback to
    # omitting them entirely rather than guessing.
    amount = off_product.get("product_quantity")
    quantity_unit = off_product.get("product_quantity_unit") or None

    return {
        "barcode": barcode,
        "name": name,
        "category": category,
        "image_url": image_url,
        "amount": float(amount) if amount else None,
        "quantity_unit": quantity_unit,
    }


if __name__ == "__main__":
    # Offline self-check of the cache logic (no network involved).
    _cache_set("111", {"name": "Test"})
    assert _cache_get("111") == (True, {"name": "Test"})

    _CACHE["111"] = (time.monotonic() - 1, {"name": "Test"})  # force expiry
    assert _cache_get("111") == (False, None)
    assert "111" not in _CACHE

    _cache_set("222", None)  # not-found results are cached too, shorter TTL
    assert _CACHE["222"][1] is None

    _CACHE.clear()
    for i in range(_MAX_ENTRIES + 5):
        _CACHE[str(i)] = (time.monotonic() + 1000, {"i": i})
    _evict()
    assert len(_CACHE) <= _MAX_ENTRIES

    print("off_client self-check OK")
