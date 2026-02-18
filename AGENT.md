# Project: Sun Position Calculator

This project aims to create a program that calculates the position of the sun.

## Requirements

*   **Language:** Roc
*   **Methodology:** Test-Driven Development (TDD)
*   **Core Task:** Calculate the sun's position.

# Testing in Roc

### Key Mechanisms
* **`expect` keyword**: Used for assertions. A test passes if the expression evaluates to `Bool.true`.
* **`roc test` command**: Executes all tests in the project and reports any `expect` that returns `false`.

### Test Types
1.  **Top-level Expects**: Defined outside of functions. Used for unit testing logic and APIs.
2.  **Inline Expects**: Placed inside function bodies to verify invariants during execution.

### Behavior by Command
| Command | Top-level Expects | Inline Expects |
| :--- | :--- | :--- |
| **`roc test`** | Executed | Executed (if reached) |
| **`roc dev`** | Ignored | Reported if encountered |
| **`roc build`** | Discarded | Discarded (for performance) |

### Constraints
* **No "Diff" View**: Currently, `roc test` doesn't show the actual vs. expected value.
* **Workaround**: Assign the result to a variable within the `expect` block to see it in failure logs:
    ```roc
    expect
        result = pluralize "cactus" "cacti" 1
        result == "2 cactus"
    ```
* **Non-halting**: Inline expects do not stop program execution; they only log failures.

### Best Practices
* Use `expect` for **logic verification**.
* Use `Result` for **recoverable errors**.
* Use `crash` only for **unreachable states** or unrecoverable system failures.
