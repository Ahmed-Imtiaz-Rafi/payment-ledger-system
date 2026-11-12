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

## Wiring beans together (dependency injection)

A bean can use another bean in three ways, and all of them are dependency injection:
1. **Direct call:** one `@Bean` method calls another, and Spring returns the existing instance.
2. **Method parameter:** a `@Bean` method declares a parameter, and Spring injects the matching bean from the context.
3. **`@Autowired`:** on a field, a constructor, or a setter.

**Constructor injection is the one to prefer.** The field can be `final`, so the object can't exist half-built, and a test can pass in its own dependency without Spring. Field injection can't be `final`, and a plain test has no way to supply the dependency without reflection or a Spring context. Setter injection can't be `final` either, so I keep it for optional dependencies.

When a class has only one constructor, `@Autowired` can be omitted. Spring applies it implicitly (since Spring 4.3). That is the form I use.

## Writing queries in Spring Data JPA

There are various ways to create a query using Spring Data JPA. When the app starts, Spring creates a proxy for each repository interface and works out a query for every method on it, so a wrong query or a property name that doesn't exist fails the startup. That is useful because I find the mistake immediately. If a method has a query declared with `@Query`, that one takes precedence over a named query, and a named query is used instead of deriving a query from the method name. Deriving from the method name is the fallback when nothing else is declared.

The first way is to derive the query from the method name with keywords such as `And` and `Or`, like `findByPhoneNumber`. It is the most trivial, and derived methods are predominant for simple queries. The `distinct` keyword is the exception. It can be tricky and can give a different result than I expect. For example, `select distinct u` includes the id, so nothing is duplicated and I get the whole table, while `select distinct u.lastname` gives the unique last names as a list of strings. In that case it is better to write the query by hand.

The second way is `@Query` on top of the repository method, which is written in JPQL by default. I use it for methods that are non-trivial and not handled gracefully by a derived method name. It is more common than `@NamedQuery` because it keeps the entity free of query text and puts the query right next to the method that runs it.

Parameters in `@Query` can be bound in two ways. One is by position, `?1` and `?2`, which is the default and refers to the parameter's position in the method. The other is by name, `:name` with `@Param("name")` on the method parameter. The docs say positional binding is a little error-prone, because if I refactor and the parameters shuffle their positions, the values quietly go to the wrong place. Named binding doesn't have that problem, so I use it. From Spring Data JPA 4, `@Param` can be left out if the project is compiled with the `-parameters` flag. I haven't confirmed that my project has it on, and the test is to write a query without `@Param` and see if the app starts.

```java
@Query("select a from Account a where a.phoneNumber = :phone")
Optional<Account> findByPhone(@Param("phone") String phone);
```

The third way is `@NamedQuery` on top of the entity class. It has two attributes. `name` is the entity class name, a dot, and the method name, for example `User.findByEmailAddress`, and `query` holds the JPQL. The advantage is that I don't need a separate configuration file like `orm.xml`, and the cost is that I have to recompile the entity for every new query.

The fourth way is native SQL, for queries JPQL can't express. I can use `@NativeQuery` on the method, which is a shortcut for `@Query(nativeQuery = true)` with some extra attributes, or `@NamedNativeQuery` on the entity. The docs say native queries lose database platform independence, so they are tied to one database, which for me is PostgreSQL.

## Updating with `@Modifying`

There are two ways to update. The usual one is in the service. I load the entity, change its fields, and Hibernate writes the `UPDATE` at commit. The controller maps a full update to `@PutMapping`, a partial update to `@PatchMapping`, and deletion to `@DeleteMapping`, and each of them delegates to a service method.

The other way is `@Modifying` with `@Query` in the repository. It sends one `UPDATE` or `DELETE` statement straight to the database without loading the entity first, and it returns the number of rows affected. It suits bulk changes, or a change that has to be a single atomic statement, like a conditional balance update. For everyday updates, the service approach stays the default.

```java
@Modifying
@Query("update Account a set a.balance = a.balance - :amount " +
       "where a.id = :id and a.balance >= :amount")
int debit(@Param("id") long id, @Param("amount") BigDecimal amount);
```

The catch is that a `@Modifying` query changes the database but not the entities already loaded in the persistence context. Say I select an account with balance 1000 and then run the update for 500. The database now says 500, but the entity I loaded still says 1000. Even a second `findById` returns that same stale object, because Hibernate already holds it in memory for the transaction and doesn't re-read the row.

```java
@Transactional
public void withdrawWrong(long id, BigDecimal amount) {
    Account before = accountRepository.findById(id).orElseThrow(); // 1000, held in memory
    accountRepository.debit(id, amount);                           // database says 500
    accountRepository.findById(id).orElseThrow().getBalance();     // still 1000
}
```

So I run the update first and select afterwards. Nothing was loaded before the update, so the first load reads the fresh row.

```java
@Transactional
public BigDecimal withdraw(long id, BigDecimal amount) {
    int updated = accountRepository.debit(id, amount);
    if (updated == 0) {
        throw new IllegalStateException("No such account, or insufficient funds");
    }
    return accountRepository.findById(id).orElseThrow().getBalance(); // first load, 500
}
```

I don't have to avoid selecting first, I only have to avoid using an entity loaded before the update. If I must select first, `clearAutomatically = true` on `@Modifying` clears the persistence context after the update, and I reload. The catch is that clearing drops any changes that haven't been flushed yet, which is why it is off by default. I can also refresh one entity by hand with `entityManager.refresh(account)`. Another option is a scalar query such as `select a.balance from Account a where a.id = :id`, which asks for the column and not the entity, so it always returns what the database says right now. It returns null for an id that doesn't exist, so I declare it as `Optional<BigDecimal>` if the account might be missing. Working out the balance in Java with a plus or minus also works, but it repeats the logic outside the database, so re-reading is more trustworthy.

The ordering has a second benefit, which is where the "enough money" check happens. If I select first, I'm tempted to check in Java, `if (balance >= amount)`, and then call the update. The problem is that another request can change the balance between the check and the update. With 1000 in the account and two withdrawals of 800 arriving at the same moment, both read 1000, both checks pass, the first debit makes it 200 and the second makes it minus 600. That breaks my invariant that no balance goes below zero. The check and the change were two separate steps, and the other request fit between them. If I put the check inside the statement, with `where a.balance >= :amount`, the check and the change are one step, and PostgreSQL won't run two such statements on the same row at the same instant. The first request makes the balance 200 and returns 1. The second finds 200 is not enough, changes nothing and returns 0, so the service knows the withdrawal failed and rejects it. That is why `debit` returns the row count, and 0 means the account doesn't exist or the funds were insufficient. This is the simple version of the idea. It is one of the approaches I will compare in the concurrency step against the entity approach with locking, and I'll look at what PostgreSQL does when two requests hit the same row and at the isolation levels then. Ledger entries are append-only, so they never use updates or deletes at all.