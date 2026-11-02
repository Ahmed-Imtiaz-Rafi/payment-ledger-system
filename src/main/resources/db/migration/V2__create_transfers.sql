CREATE TYPE transfer_status_enum AS ENUM ('PENDING', 'COMPLETED', 'FAILED');
CREATE TYPE transfer_type_enum AS ENUM ('CASH_IN', 'CASH_OUT', 'PAYMENT', 'SEND_MONEY');

CREATE TABLE transfers (
                           id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                           transfer_type   transfer_type_enum   NOT NULL,
                           amount     NUMERIC(19, 2)       NOT NULL,
                           transfer_status transfer_status_enum NOT NULL,
                           transfer_time   TIMESTAMPTZ          NOT NULL DEFAULT now(),
                           idempotency_key UUID not null unique,

                           CONSTRAINT amount_positive CHECK (amount > 0)
);