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