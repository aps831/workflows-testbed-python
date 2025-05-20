import pytest
from main import multiply_by_three


@pytest.mark.slow
def test_answer():
    assert multiply_by_three(3) == 9
