# Invariants

Rules that must be true at every moment, even under crashes, retries, and load.
Each has a check I can run. Checks are either **constraint-enforced** (the
database refuses violations itself) or **query-verified** (I run a query after
tests or load to confirm).

## 1. Every transfer's entries sum to zero
Type: query-verified
Check: (to be written once ledger_entries exists)

## 2. Every account except the funding account stays at or above zero; the funding account stays at or below zero
Type: constraint-enforced
Check: `accounts_balance_by_type`

```sql
CHECK (
    (account_type = 'FUNDING' AND balance <= 0)
    OR
    (account_type <> 'FUNDING' AND balance >= 0)
)
```

## 3. A stored balance equals the sum of that account's entries
Type: query-verified
Check: (to be written once ledger_entries exists)

## 4. The sum of all entries in the system is zero
Type: query-verified
Check: (to be written once ledger_entries exists)

## 5. The sum of all account balances, funding account included, is zero
Type: query-verified
Check:

```sql
SELECT COALESCE(SUM(balance), 0) FROM accounts;
```

The result must be exactly 0.

## 6. No two transfers share an idempotency key
Type: constraint-enforced
Check: the `UNIQUE` constraint on `transfers.idempotency_key`

## 7. Every transfer amount is positive
Type: constraint-enforced
Check: `amount_positive`

## 8. A COMPLETED transfer has entries that sum to zero, and a FAILED transfer has no entries
Type: query-verified
Check: (to be written once ledger_entries exists)

## 9. A transfer's amount agrees with its entries
Type: query-verified
Check: (to be written once ledger_entries exists)