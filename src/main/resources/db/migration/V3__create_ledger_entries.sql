CREATE TYPE entry_type_enum AS ENUM('FEE', 'PRINCIPAL');

CREATE TABLE ledger_entries (
                                id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                                account_id BIGINT NOT NULL REFERENCES accounts(id),
                                transfer_id BIGINT NOT NULL REFERENCES transfers(id),
                                amount NUMERIC(19, 2) NOT NULL,
                                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                                entry_type entry_type_enum NOT NULL,

                                CONSTRAINT entries_amount_nonzero CHECK(amount <> 0)

);