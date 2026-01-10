def fib(n: int) -> int:
    """
    Calculate the n-th Fibonacci number.
    
    Args:
        n (int): The position in the Fibonacci sequence (must be non-negative).
    
    Returns:
        int: The n-th Fibonacci number.
    
    Raises:
        ValueError: If n is negative.
    """
    if n < 0:
        raise ValueError("Input must be a non-negative integer")
    if n == 0:
        return 0
    if n == 1:
        return 1
    
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b
