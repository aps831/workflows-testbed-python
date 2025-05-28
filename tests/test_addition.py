import pytest
from main import add_one

@pytest.mark.fast
def test_answer():
    assert add_one(3) == 4
