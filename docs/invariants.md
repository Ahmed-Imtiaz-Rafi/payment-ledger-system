# Invariants

Rules that must be true at every moment, even under crashes, retries, and load.
Each has a check I can run. Checks are either **constraint-enforced** (the
database refuses violations itself) or **query-verified** (I run a query after
tests or load to confirm).

Queries that list broken rows should return an **empty result** when the ledger
is healthy. Queries that return a single number say which value to expect.

## 1. Every transfer's entries sum to zero
- Type: query-verified
- Check: expect an empty result.

```sql
SELECT t.id, COALESCE(SUM(le.amount), 0) AS total
FROM transfers t
         LEFT JOIN ledger_entries le ON le.transfer_id = t.id
GROUP BY t.id
HAVING COALESCE(SUM(le.amount), 0) <> 0;
```

## 2. Every account except the funding account stays at or above zero; the funding account stays at or below zero
- Type: constraint-enforced
- Check: the `accounts_balance_by_type` constraint.

```sql
CHECK (
    (account_type = 'FUNDING' AND balance <= 0)
    OR
    (account_type <> 'FUNDING' AND balance >= 0)
)
```

## 3. A stored balance equals the sum of that account's entries
- Type: query-verified
- Check: expect an empty result.
- Note: this returns rows until the service updates `accounts.balance` and writes the entries in the same transaction. Until then, rows here are expected and are not a bug.

```sql
SELECT a.id, a.balance, COALESCE(SUM(le.amount), 0) AS entries_sum
FROM accounts a
         LEFT JOIN ledger_entries le ON le.account_id = a.id
GROUP BY a.id
HAVING a.balance <> COALESCE(SUM(le.amount), 0);
```

## 4. The sum of all entries in the system is zero
- Type: query-verified
- Check: expect exactly 0.00.

```sql
SELECT COALESCE(SUM(amount), 0) FROM ledger_entries;
```

## 5. The sum of all account balances, funding account included, is zero
- Type: query-verified
- Check: expect exactly 0.00.

```sql
SELECT COALESCE(SUM(balance), 0) FROM accounts;
```

## 6. No two transfers share an idempotency key
- Type: constraint-enforced
- Check: the `UNIQUE` constraint on `transfers.idempotency_key`.

## 7. Every transfer amount is positive
- Type: constraint-enforced
- Check: the `amount_positive` constraint.

## 8. A COMPLETED transfer has entries that sum to zero; PENDING and FAILED transfers have no entries
- Type: query-verified
- Checks: three queries, each expecting an empty result.

COMPLETED transfers that have no entries at all:

```sql
SELECT t.id
FROM transfers t
         LEFT JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status = 'COMPLETED'
  AND le.id IS NULL;
```

COMPLETED transfers whose entries do not sum to zero:

```sql
SELECT t.id, SUM(le.amount) AS total
FROM transfers t
         JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status = 'COMPLETED'
GROUP BY t.id
HAVING SUM(le.amount) <> 0;
```

PENDING or FAILED transfers that have entries:

```sql
SELECT t.id, t.transfer_status
FROM transfers t
         JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status IN ('FAILED', 'PENDING');
```

## 9. A transfer's amount agrees with its entries
- Type: query-verified
- Check: expect an empty result.
- Note: a transfer's `amount` is the principal only. The fee lives in separate `FEE` entries and is not part of the amount. The check sums the positive and negative `PRINCIPAL` entries separately, so it still holds if a transfer's principal is ever split across several entries.

```sql
SELECT t.id, t.amount,
       SUM(le.amount) FILTER (WHERE le.amount > 0) AS credits,
       SUM(le.amount) FILTER (WHERE le.amount < 0) AS debits
FROM transfers t
         JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status = 'COMPLETED'
  AND le.entry_type = 'PRINCIPAL'
GROUP BY t.id
HAVING COALESCE(SUM(le.amount) FILTER (WHERE le.amount > 0), 0) <> t.amount
    OR COALESCE(SUM(le.amount) FILTER (WHERE le.amount < 0), 0) <> -t.amount;
```