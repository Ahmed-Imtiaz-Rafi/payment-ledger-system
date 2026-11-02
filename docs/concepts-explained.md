# Concepts Explained

## Flyway

Flyway stores every schema change as a versioned SQL file, one file per change. This gives a full history of how the database changed over time. When the app starts, Flyway runs only the migrations the database hasn't seen yet, so the database always ends up at the latest version.

- **Undoing a change:** automatic undo migrations are a paid feature. Without it, I write a new migration that reverses the earlier change.
- **Stopping at an older version:** the `spring.flyway.target` setting makes Flyway migrate only up to a given version.
- **Seeing an old schema:** check out an old Git commit and start a fresh database. Flyway builds the schema as it was at that commit.

## Flyway and Testcontainers in tests

During tests, Testcontainers starts a separate, throwaway PostgreSQL container, and Flyway runs the same migration files against it. The test schema is therefore identical to the real one. Test data stays in that container and never touches my dev database.

## Docker Compose support

Spring Boot reads the project's `compose.yaml` at startup and starts every service listed there, each in its own container. It also passes the connection details to the app, and stops the containers when the app stops.