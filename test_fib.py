import pytest
from fib import fib

def test_fib_0():
    assert fib(0) == 0

def test_fib_1():
    assert fib(1) == 1

def test_fib_10():
    assert fib(10) == 55

def test_fib_negative():
    with pytest.raises(ValueError):
        fib(-1)
