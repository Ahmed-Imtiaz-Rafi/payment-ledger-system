# Progress

## Done
- Chose scope: mobile money wallet ledger (decision 001)
- Chose PostgreSQL over MySQL (decision 002)
- Repo created (public, MIT) with README, docs/invariants.md, docs/decisions.md
- Spring Boot project generated (Maven, Java 25, Boot 4.1.2) and pushed
- Maven loads and builds in IntelliJ

## Next
- Edit compose.yaml: pin postgres:17, rename database and user to fit the project
- Run the app and confirm Spring starts the Postgres container
- Open question: why use Flyway migrations instead of Hibernate auto-creating tables?

## Parked
- Invariants list is incomplete. Still needs a rule for duplicate requests.