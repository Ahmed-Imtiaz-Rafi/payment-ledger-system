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
- Wrote and applied V1__create_accounts.sql (account_type enum, balance CHECK by type) and V2__create_transfers.sql (status and type enums, amount_positive, unique idempotency_key)
- Tested the constraints in DBeaver: PERSONAL with -5 fails on accounts_balance_by_type, FUNDING with -5 succeeds, amount 0 fails on amount_positive, duplicate idempotency_key fails
- Expanded docs/invariants.md to 9 invariants, each tagged constraint-enforced or query-verified
- Added docs/concepts-explained.md (Flyway, Testcontainers, Docker Compose)
- Added decisions 005 to 010 (transfers vs entries, ledger starts at zero, FUNDING/FEE split, enums, idempotency key, fees as entries)

## Next
- Write V3__create_ledger_entries.sql: own id, FKs to transfers and accounts, signed amount (CHECK not zero), a column for the reason (principal, fee)
- Fill in the invariant checks that wait on ledger_entries: 1, 3, 4, 8, 9
- Decide what "agrees" means for invariant 9 (does the transfer amount include the fee?)
- Change invariant 5's check to `SELECT COALESCE(SUM(balance), 0) FROM accounts;` so an empty table returns 0 instead of NULL
- Seed the system accounts (FUNDING, FEE) in a later migration
- Reread decisions 005 to 010 and rewrite any line in my own words

## Parked
- Whether to keep one platform account or the FUNDING/FEE split (currently split)
- Whether idempotency key uniqueness should be per sender instead of global
- NUMERIC(19,2) versus integer poisha for money
- Open question: why Flyway migrations instead of Hibernate auto-creating tables?

## Invariants status
- Enforced by constraints now: 2 (balance by type), 6 (unique key), 7 (amount_positive)
- Checkable now by query: 5 (SUM of account balances is 0)
- Waiting on ledger_entries: 1, 3, 4, 8, 9

## Common Problems
- IntelliJ Maven fix: if "ArtifactHandlerManager was bound" appears, set Settings > Maven > Maven home path to Bundled (Maven 3).
- Editing a migration that already ran makes Flyway fail on checksum. In dev, `docker compose down -v` resets the database. Once shared, write a new migration instead.
- Flyway only finds migrations in `src/main/resources/db/migration/` (nested folders, not one folder named `db.migration`). File names need a capital `V`, a version, and two underscores.
- DBeaver test inserts: always list the columns, and enum values are case-sensitive (`'PERSONAL'`, not `'Personal'`).