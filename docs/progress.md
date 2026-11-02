# Progress

## Done
- Chose scope: mobile money wallet ledger (decision 001)
- Chose PostgreSQL over MySQL (decision 002)
- Repo created (public, MIT) with README, docs/invariants.md, docs/decisions.md
- Spring Boot project generated (Maven, Java 25, Boot 4.1.2) and pushed
- compose.yaml edited: postgres:17, db/user "ledger", port 5432:5432
- App starts and Spring launches the Postgres container
- DBeaver connected (localhost:5432, db ledger)
- Designed the schema on paper: accounts, transfers, ledger_entries (entries hold signed amounts, one transfer has many entries)
- Wrote V1__create_accounts.sql (account_type enum, balance CHECK by type) and V2__create_transfers.sql (status and type enums, amount_positive, unique idempotency_key). Not yet run or tested.
- Expanded docs/invariants.md to 9 invariants, each tagged constraint-enforced or query-verified
- Added docs/concepts-explained.md (Flyway, Testcontainers, Docker Compose)

## Next
- Run `docker compose down -v` if V1 ran before the enum edit, then start the app so Flyway applies V1 and V2
- Test the constraints in DBeaver:
    - PERSONAL with balance -5 must fail on accounts_balance_by_type
    - FUNDING with balance -5 must succeed
    - transfer with amount 0 must fail on amount_positive
    - two transfers with the same idempotency_key: the second must fail
- Write V3__create_ledger_entries.sql: own id, FKs to transfers and accounts, signed amount (CHECK not zero), a column for the reason (principal, fee)
- Then fill in the invariant checks that wait on ledger_entries: 1, 3, 4, 8, 9
- Decide what "agrees" means for invariant 9 (does the transfer amount include the fee?)
- Seed the system accounts (FUNDING, FEE) in a later migration

## Parked
- Whether to keep one platform account or the FUNDING/FEE split (currently split)
- Whether idempotency key uniqueness should be per sender instead of global
- NUMERIC(19,2) versus integer poisha for money
- Add decisions.md entries in my own words: FUNDING/FEE split, ledger starts at zero, enums over CHECK lists, client-generated idempotency key
- Open question: why Flyway migrations instead of Hibernate auto-creating tables?

## Invariants status
- Enforced by constraints now: 2 (balance by type), 6 (unique key), 7 (amount_positive)
- Checkable now by query: 5 (SUM of account balances is 0)
- Waiting on ledger_entries: 1, 3, 4, 8, 9

## Common Problems
- IntelliJ Maven fix: if "ArtifactHandlerManager was bound" appears, set Settings > Maven > Maven home path to Bundled (Maven 3).
- Editing a migration that already ran makes Flyway fail on checksum. In dev, `docker compose down -v` resets the database. Once shared, write a new migration instead.