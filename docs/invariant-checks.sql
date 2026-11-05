-- Constraint tests and invariant checks.
-- Run on a FRESH database (docker compose down -v, then start the app).
-- Expected failures are intentional: read each error and confirm it is the rule named in the comment.

-- ===== accounts: FUNDING =====
-- must FAIL: account_type cannot be NULL
INSERT INTO accounts (balance, phone_number)
VALUES (50000.99, '+8801734600716');

-- must FAIL: account_type is not one of the four allowed values
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('INVESTMENT', 50000.99, '+8801734600716');

-- must FAIL: a FUNDING account must not have a phone number
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('FUNDING', 0.00, '+8801734600716');

-- must FAIL: a FUNDING balance cannot be positive
INSERT INTO accounts (account_type, balance)
VALUES ('FUNDING', 50000.00);

-- must SUCCEED (also proves created_at fills itself in)
INSERT INTO accounts (account_type, balance)
VALUES ('FUNDING', 0.00);

-- ===== accounts: FEE =====
-- must FAIL: a FEE account must not have a phone number
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('FEE', 50000.00, '+8801734600716');

-- must FAIL: a FEE balance cannot be negative
INSERT INTO accounts (account_type, balance)
VALUES ('FEE', -50000.00);

-- must SUCCEED
INSERT INTO accounts (account_type, balance)
VALUES ('FEE', 0.00);

-- ===== accounts: PERSONAL =====
-- must FAIL: a PERSONAL account must have a phone number
INSERT INTO accounts (account_type, balance)
VALUES ('PERSONAL', 5000.00);

-- must FAIL: a PERSONAL balance cannot be negative
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('PERSONAL', -5000.00, '+8801734600716');

-- must SUCCEED
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('PERSONAL', 5000.00, '+8801734600716');

-- expect 5000.00
SELECT COALESCE(SUM(balance), 0) FROM accounts;

-- must SUCCEED: the funding account mirrors the issued money
INSERT INTO accounts (account_type, balance)
VALUES ('FUNDING', -5000.00);

-- expect 0.00
SELECT COALESCE(SUM(balance), 0) FROM accounts;

-- must FAIL: two accounts cannot share a phone number
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('PERSONAL', 50000.00, '+8801734600716');

-- must FAIL: updating a PERSONAL balance below zero
UPDATE accounts
SET balance = -50000.00
WHERE phone_number = '+8801734600716';

-- ===== accounts: AGENT =====
-- must FAIL: an AGENT account must have a phone number
INSERT INTO accounts (account_type, balance)
VALUES ('AGENT', 5000.00);

-- must FAIL: an AGENT balance cannot be negative
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('AGENT', -5000.00, '+8801734600816');

-- must SUCCEED
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('AGENT', 6000.00, '+8801734600816');

-- must FAIL: two accounts cannot share a phone number
INSERT INTO accounts (account_type, balance, phone_number)
VALUES ('AGENT', 50000.00, '+8801734600716');

-- expect 6000.00
SELECT COALESCE(SUM(balance), 0) FROM accounts;

-- must SUCCEED
INSERT INTO accounts (account_type, balance)
VALUES ('FUNDING', -6000.00);

-- expect 0.00
SELECT COALESCE(SUM(balance), 0) FROM accounts;


-- ===== transfers =====
-- must FAIL: transfer_type cannot be NULL
INSERT INTO transfers (amount, transfer_status, idempotency_key)
VALUES (500.00, 'PENDING', '00000000-0000-0000-0000-000000000001');

-- must FAIL: transfer_type is not one of the allowed values
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('PAY_BILL', 500.00, 'PENDING', '00000000-0000-0000-0000-000000000001');

-- must FAIL: amount cannot be NULL
INSERT INTO transfers (transfer_type, transfer_status, idempotency_key)
VALUES ('SEND_MONEY', 'PENDING', '00000000-0000-0000-0000-000000000001');

-- must FAIL: amount must be positive
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('SEND_MONEY', 0, 'PENDING', '00000000-0000-0000-0000-000000000001');

-- must FAIL: transfer_status cannot be NULL
INSERT INTO transfers (transfer_type, amount, idempotency_key)
VALUES ('CASH_OUT', 500.00, '00000000-0000-0000-0000-000000000001');

-- must FAIL: transfer_status is not one of the allowed values
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('CASH_OUT', 500.00, 'DELAYED', '00000000-0000-0000-0000-000000000001');

-- must FAIL: idempotency_key cannot be NULL
INSERT INTO transfers (transfer_type, amount, transfer_status)
VALUES ('SEND_MONEY', 500.00, 'PENDING');

-- must SUCCEED: a PENDING transfer, so no entries (also proves transfer_time fills itself in)
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('SEND_MONEY', 500.00, 'PENDING', '00000000-0000-0000-0000-000000000001');

-- must FAIL: duplicate idempotency_key (the same key as the row above)
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('SEND_MONEY', 500.00, 'PENDING', '00000000-0000-0000-0000-000000000001');

-- expect 0.00: transfers never touch account balances
SELECT COALESCE(SUM(balance), 0) FROM accounts;

-- must SUCCEED: completed transfer 1 (key ...0002)
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('SEND_MONEY', 500.00, 'COMPLETED', '00000000-0000-0000-0000-000000000002');

-- must SUCCEED: completed transfer 2 (key ...0003)
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('CASH_OUT', 5000.00, 'COMPLETED', '00000000-0000-0000-0000-000000000003');

-- must SUCCEED: a FAILED transfer, so no entries (key ...0004)
INSERT INTO transfers (transfer_type, amount, transfer_status, idempotency_key)
VALUES ('PAYMENT', 5000.00, 'FAILED', '00000000-0000-0000-0000-000000000004');


-- ===== ledger_entries =====
-- must FAIL: account_id does not exist
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES (999999,
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        500.00, 'PRINCIPAL');

-- must FAIL: transfer_id does not exist
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        999999,
        500.00, 'PRINCIPAL');

-- must FAIL: account_id cannot be NULL
INSERT INTO ledger_entries (transfer_id, amount, entry_type)
VALUES ((SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        500.00, 'PRINCIPAL');

-- must FAIL: transfer_id cannot be NULL
INSERT INTO ledger_entries (account_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        500.00, 'PRINCIPAL');

-- must FAIL: amount cannot be NULL
INSERT INTO ledger_entries (account_id, transfer_id, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        'PRINCIPAL');

-- must FAIL: entry_type cannot be NULL
INSERT INTO ledger_entries (account_id, transfer_id, amount)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        500.00);

-- must FAIL: an entry amount cannot be zero
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        0.00, 'PRINCIPAL');

-- must FAIL: entry_type is not one of the allowed values
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        500.00, 'FUND');

-- ----- transfer 1 (key ...0002): send 500 with a 10 fee -----
-- must SUCCEED: personal pays the principal (also proves created_at fills itself in)
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        -500.00, 'PRINCIPAL');

-- must SUCCEED: personal pays the fee
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        -10.00, 'FEE');

-- must SUCCEED: agent receives the principal
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600816'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        500.00, 'PRINCIPAL');

-- must SUCCEED: the fee account receives the fee
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE account_type = 'FEE'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002'),
        10.00, 'FEE');

-- expect 0.00: transfer 1 sums to zero
SELECT SUM(amount) FROM ledger_entries
WHERE transfer_id = (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000002');

-- ----- transfer 2 (key ...0003): cash-out of 5000 -----
-- expect ONE row: transfer 2 is COMPLETED but has no entries yet
SELECT t.id
FROM transfers t
         LEFT JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status = 'COMPLETED'
  AND le.id IS NULL;

-- must SUCCEED: half of transfer 2 (the debit)
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600716'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000003'),
        -5000.00, 'PRINCIPAL');

-- expect an EMPTY result: transfer 2 now has an entry
SELECT t.id
FROM transfers t
         LEFT JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status = 'COMPLETED'
  AND le.id IS NULL;

-- expect ONE row: transfer 2 with total -5000.00, because the credit is missing
SELECT t.id, SUM(le.amount) AS total
FROM transfers t
         JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status = 'COMPLETED'
GROUP BY t.id
HAVING SUM(le.amount) <> 0;

-- must SUCCEED: the other half of transfer 2 (the credit)
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600816'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000003'),
        5000.00, 'PRINCIPAL');

-- expect an EMPTY result: every COMPLETED transfer now sums to zero
SELECT t.id, SUM(le.amount) AS total
FROM transfers t
         JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status = 'COMPLETED'
GROUP BY t.id
HAVING SUM(le.amount) <> 0;

-- must FAIL: an account that entries point to cannot be deleted
DELETE FROM accounts
WHERE phone_number = '+8801734600716';

-- must FAIL: a transfer that entries point to cannot be deleted
DELETE FROM transfers
WHERE idempotency_key = '00000000-0000-0000-0000-000000000002';

-- ----- PENDING and FAILED transfers must have no entries -----
-- Violation on purpose: an entry on the PENDING transfer (key ...0001). The database accepts it.
INSERT INTO ledger_entries (account_id, transfer_id, amount, entry_type)
VALUES ((SELECT id FROM accounts WHERE phone_number = '+8801734600816'),
        (SELECT id FROM transfers WHERE idempotency_key = '00000000-0000-0000-0000-000000000001'),
        5000.00, 'PRINCIPAL');

-- expect ONE row: the check catches the violation
SELECT t.id, t.transfer_status
FROM transfers t
         JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status IN ('FAILED', 'PENDING');

-- remove the violation
DELETE FROM ledger_entries
WHERE transfer_id IN (
    SELECT id FROM transfers
    WHERE transfer_status IN ('PENDING', 'FAILED')
);

-- expect an EMPTY result: FAILED and PENDING transfers have no entries
SELECT t.id, t.transfer_status
FROM transfers t
         JOIN ledger_entries le ON le.transfer_id = t.id
WHERE t.transfer_status IN ('FAILED', 'PENDING');

-- ----- invariant 4: all entries in the system sum to zero -----
-- expect 0.00
SELECT COALESCE(SUM(amount), 0) FROM ledger_entries;

-- Invariant 3: expect an EMPTY result
SELECT a.id, a.balance, COALESCE(SUM(le.amount), 0) AS entries_sum
FROM accounts a
         LEFT JOIN ledger_entries le ON le.account_id = a.id
GROUP BY a.id
HAVING a.balance <> COALESCE(SUM(le.amount), 0);

-- Invariant 9: expect an EMPTY result
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
