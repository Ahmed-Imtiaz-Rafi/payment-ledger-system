# Decision Log

One entry per significant choice: what, what else I considered, why.

## 001: Mobile money wallet as the project scope
- Considered: commercial bank core ledger, a combined system.
- Chose the wallet because it keeps the focus on concurrency, idempotency, and
  failure handling instead of banking rules. Combined scope risks never finishing.

## 002: PostgreSQL over MySQL
- Considered: MySQL, which I already know.
- Chose PostgreSQL for stricter constraints, clearer EXPLAIN ANALYZE output, and
  because it is the modern default.

## 003: MIT license
- Simplest permissive license for a public portfolio project.

## 004: Pin PostgreSQL to version 17 and fix the host port to 5432
- Considered: `postgres:latest` with a random host port, which is what Initializr generated.
- Chose to pin `postgres:17` so the database version can't change under me and
  results stay reproducible, especially for concurrency and load tests.
- Chose the fixed mapping `5432:5432` so DBeaver always connects to the same
  port instead of me looking up a new one on every run.
- Trade-off: if something else on my machine already uses port 5432, the app
  won't start until I change the left-hand number.