CREATE TYPE account_type_enum AS ENUM ('PERSONAL', 'AGENT', 'FEE', 'FUNDING');

CREATE TABLE accounts (
                          id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                          account_type account_type_enum NOT NULL,
                          balance      NUMERIC(19,2)     NOT NULL DEFAULT 0,
                          created_at   TIMESTAMPTZ       NOT NULL DEFAULT now(),

                          CONSTRAINT accounts_balance_by_type
                              CHECK (
                                  (account_type = 'FUNDING' AND balance <= 0)
                                      OR
                                  (account_type <> 'FUNDING' AND balance >= 0)
                                  )
);

