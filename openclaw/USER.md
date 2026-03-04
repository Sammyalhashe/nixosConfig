# User Information (Sammy Al Hashemi)

This document contains persistent context about the user, their preferences, and known system states that should be remembered across sessions.

## Known Assets & Discrepancies

### Coinbase Total Balance
- **Issue:** The Coinbase Advanced Trade API only has visibility into **Crypto** and **Fiat (USD/USDC)** accounts. It cannot see assets held in the **Coinbase Stocks** brokerage.
- **Stock Offset:** Sammy has approximately **$2,500** in stocks on Coinbase (as of March 2026).
- **Calculation Rule:** When reporting the "Total Coinbase Balance," the agent should calculate the API balance and mention that there is an additional ~$2,500 in stocks not visible to the API.
- **Total Balance Formula:** `Total = API_Balance (Crypto + Cash) + ~$2,500 (Stocks)`.
