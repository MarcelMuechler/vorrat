import pytest

from app.utils import escape_csv_formula_injection, unescape_csv_formula_injection


@pytest.mark.parametrize(
    "value",
    ["=SUM(A1:A10)", "+1+1", "-2", "@SUM(A1:A10)", "'Nduja", "plain name", "", None],
)
def test_csv_formula_injection_escape_unescape_round_trips(value):
    assert unescape_csv_formula_injection(escape_csv_formula_injection(value)) == value


def test_escape_csv_formula_injection_prefixes_a_leading_apostrophe_too():
    # A name that's already apostrophe-prefixed must itself be escaped (by
    # doubling the apostrophe) -- otherwise unescape, which always strips
    # exactly one leading apostrophe, would corrupt it back to "Nduja".
    assert escape_csv_formula_injection("'Nduja") == "''Nduja"
