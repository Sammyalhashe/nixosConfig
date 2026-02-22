```python
#!/usr/bin/env python3
"""
circle_area_calculator.py

A simple command-line utility to calculate the area of a circle from user input.
"""

import math
import sys
import argparse
from typing import Optional

# Constants
PI = math.pi
DEFAULT_PRECISION = 2
MIN_RADIUS = 0.0


def circle_area(radius: float) -> float:
    """
    Calculate the area of a circle given its radius.

    Args:
        radius (float): The radius of the circle (must be non-negative).

    Returns:
        float: The area of the circle.

    Raises:
        ValueError: If radius is negative.
    """
    if radius < MIN_RADIUS:
        raise ValueError("Radius must be non-negative.")
    return PI * radius ** 2


def format_area(area: float, precision: int = DEFAULT_PRECISION) -> str:
    """
    Format the area to a specified number of decimal places.

    Args:
        area (float): The area to format.
        precision (int): Number of decimal places (default: 2).

    Returns:
        str: Formatted area as a string.

    Raises:
        ValueError: If precision is negative.
    """
    if precision < 0:
        raise ValueError("Precision must be non-negative.")
    return f"{area:.{precision}f}"


def is_number(value: str) -> bool:
    """
    Check if a string can be converted to a float.

    Args:
        value (str): The string to check.

    Returns:
        bool: True if the string represents a valid number, False otherwise.
    """
    try:
        float(value)
        return True
    except ValueError:
        return False


def parse_positive_float(value: str) -> float:
    """
    Parse a string to a positive float.

    Args:
        value (str): The string to parse.

    Returns:
        float: The parsed positive float.

    Raises:
        ValueError: If the string is not a valid number or is negative.
    """
    if not value.strip():
        raise ValueError("Input cannot be empty.")
    
    if not is_number(value):
        raise ValueError("Invalid input: must be a number.")
    
    radius = float(value)
    if radius < MIN_RADIUS:
        raise ValueError("Radius must be non-negative.")
    
    return radius


def prompt_radius(prompt: str = "Enter radius: ") -> float:
    """
    Prompt the user for a valid radius until one is provided.

    Args:
        prompt (str): The prompt message to display.

    Returns:
        float: A valid non-negative radius.
    """
    while True:
        user_input = input(prompt).strip()
        try:
            return parse_positive_float(user_input)
        except ValueError as e:
            print(e)


def main() -> int:
    """
    Main entry point for the script.

    Returns:
        int: Exit status code (0 for success, non-zero for error).
    """
    parser = argparse.ArgumentParser(
        description="Calculate the area of a circle from a given radius."
    )
    parser.add_argument(
        "-r", "--radius",
        type=str,
        help="Radius of the circle (if not provided, will prompt user)."
    )
    parser.add_argument(
        "-p", "--precision",
        type=int,
        default=DEFAULT_PRECISION,
        help=f"Number of decimal places (default: {DEFAULT_PRECISION})."
    )
    
    try:
        args = parser.parse_args()
        
        # Handle radius input
        if args.radius is not None:
            try:
                radius = parse_positive_float(args.radius)
            except ValueError as e:
                print(f"Error: {e}", file=sys.stderr)
                return 1
        else:
            radius = prompt_radius()
        
        # Calculate and format area
        area = circle_area(radius)
        area_str = format_area(area, args.precision)
        
        # Output result
        print(f"The area of a circle with radius {radius} is {area_str}.")
        return 0
        
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.", file=sys.stderr)
        return 130
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
```