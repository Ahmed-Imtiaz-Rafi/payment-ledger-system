# Progress

## Done
- Chose scope: mobile money wallet ledger (decision 001)
- Chose PostgreSQL over MySQL (decision 002)
- Repo created (public, MIT) with README, docs/invariants.md, docs/decisions.md
- Spring Boot project generated (Maven, Java 25, Boot 4.1.2) and pushed
- compose.yaml edited: postgres:17, db/user "ledger", port 5432:5432
- App starts and Spring launches the Postgres container
- DBeaver connected (localhost:5432, db ledger)

## Next
- Schema design: accounts and ledger_entries, written as Flyway migrations
- Open question: why Flyway migrations instead of Hibernate auto-creating tables?

## Parked
- Invariants list is incomplete. Still needs a rule for duplicate requests.
- Fill in checks for invariants 2 and 3 once the schema exists.

## Common Problems
- IntelliJ Maven fix: if "ArtifactHandlerManager was bound" appears, set Settings > Maven > Maven home path to Bundled (Maven 3).