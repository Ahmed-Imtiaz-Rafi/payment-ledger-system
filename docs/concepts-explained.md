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

## Adding beans to the Spring context

**1. `@Bean` method.** The instance's class has no annotation. A `@Configuration` class declares a `@Bean` method that returns the object.
- Old: I create the context in plain code and pass the config class to it.
- Modern: `SpringApplication.run(...)` creates the context, and component scanning finds the config class (it is a `@Component`).

**2. Stereotype annotation.** The class itself is annotated with `@Component` (or `@Service`, `@Repository`, `@RestController`, which are all `@Component` underneath).
- Old: a separate `@Configuration` class carries `@ComponentScan` with the base package, and I pass it to the context.
- Modern: `@SpringBootApplication` already includes `@ComponentScan`, which scans the main class's package and all subpackages. No extra config class is needed.

**3. Programmatic registration.** The class has no annotation. I call `registerBean` on the context, passing the class and a supplier that creates the instance.
- Old: create the context with an empty config class, then call `registerBean`.
- Modern: still possible, but rare. In practice Boot code uses ways 1 and 2.

**In practice:** stereotypes for classes I write, `@Bean` for third-party classes I can't annotate.

**Related, not a way to add beans:** `@PostConstruct` runs once after Spring creates the instance and injects its dependencies. Auto-configuration (`@EnableAutoConfiguration`) is a separate feature that creates beans such as the `DataSource` from the classpath.