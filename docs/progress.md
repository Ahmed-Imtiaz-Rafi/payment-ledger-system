# Progress

## Done
- Chose scope: mobile money wallet ledger (decision 001)
- Chose PostgreSQL over MySQL (decision 002)
- Repo created (public, MIT) with README, docs/invariants.md, docs/decisions.md
- Spring Boot project generated (Maven, Java 25, Boot 4.1.2) and pushed
- compose.yaml edited: postgres:17, db/user "ledger", port 5432:5432
- App starts and Spring launches the Postgres container
- DBeaver connected (localhost:5432, db ledger)
- Schema built as four Flyway migrations, all applied:
    - V1 accounts (account_type enum, balance CHECK by type)
    - V2 transfers (type and status enums, amount_positive, unique idempotency_key)
    - V3 ledger_entries (FKs to accounts and transfers, signed amount, nonzero CHECK, entry_type enum)
    - V4 phone_number on accounts (unique, required for PERSONAL and AGENT, forbidden for FUNDING and FEE)
- Wrote docs/invariant-checks.sql: constraint tests and invariant checks, run with psql from the terminal. Output matched every comment.
- docs/invariants.md has 9 invariants, each with its type, a check, and the expected healthy result
- docs/concepts-explained.md covers Flyway, Testcontainers, Docker Compose
- docs/decisions.md has entries 001 to 011 (011: phone number rule)
- Decided: a transfer's amount is the principal only, and the fee is a separate FEE entry (invariant 9 depends on this)
- Decided: PENDING transfers have no entries until they resolve, and FAILED transfers have none either

## Next
1. Read Spring Start Here: the container, beans, and dependency injection chapters. Write a recap in my own words in concepts-explained.md.
2. Write the entities for accounts, transfers, and ledger_entries, and confirm they map to the migrations (PostgreSQL enums and BigDecimal need explicit mapping).
3. Write the repositories and test them with Testcontainers.
4. Write the transfer service with @Transactional (the balance update and both entries in one transaction).
5. DTOs and controllers.

## Reading plan (only when the step needs it)
- Now: Spring Start Here (container, beans, dependency injection), then its Spring Data chapter
- Docs before entities: Spring Data JPA "Repositories" and "Query methods", Hibernate entity mapping basics
- Before the service step: the transactions chapter (@Transactional)
- Before concurrency: Postgres docs 13.1 and 13.2, then DDIA first edition chapter 7 (selected sections)
- On hold until I'm told: everything on the concurrency list above. Light reading of DDIA chapter 1 only.

## Parked
- Decision entries still owed, in my own words: authentication (PIN) deferred, transfer amount is principal only
- Reread decisions 005 to 010 and rewrite any line in my own words
- Prove invariant 9 by breaking the data on purpose and confirming it is flagged
- Seed the FUNDING and FEE accounts in a later migration
- A separate table for failed attempts, so a failed transfer still records who was involved
- Authentication and PIN (later, optional, after the failure harness)
- Whether idempotency key uniqueness should be per sender instead of global
- NUMERIC(19,2) versus integer poisha for money
- Whether to keep one platform account or the FUNDING/FEE split (currently split)
- Open question: why Flyway migrations instead of Hibernate auto-creating tables?
- JUnit and Testcontainers tests to replace reading the psql output by eye

## Invariants status
- Enforced by constraints: 2 (balance by type), 6 (unique key), 7 (amount_positive)
- Checked by query: 1, 3, 4, 5, 8, 9
- Invariant 3 returns rows until the service updates balance and writes entries in one transaction. That is expected for now.

## Common Problems
- IntelliJ Maven fix: if "ArtifactHandlerManager was bound" appears, set Settings > Maven > Maven home path to Bundled (Maven 3).
- Editing a migration that already ran makes Flyway fail on checksum. In dev, `docker compose down -v` resets the database. Once shared, write a new migration instead.
- Flyway only finds migrations in `src/main/resources/db/migration/` (nested folders, not one folder named `db.migration`). File names need a capital `V`, a version, and two underscores.
- DBeaver and psql test inserts: always list the columns, and enum values are case-sensitive (`'PERSONAL'`, not `'Personal'`).
- Run the check script on a fresh database: `docker compose down -v`, start the app, then from the repo root:
  `docker compose exec -T postgres psql -a -U ledger -d ledger < docs/invariant-checks.sql`
  The `-a` flag prints each statement above its result.
- A failed insert still uses up an id from the counter, so ids can have gaps. That is normal.