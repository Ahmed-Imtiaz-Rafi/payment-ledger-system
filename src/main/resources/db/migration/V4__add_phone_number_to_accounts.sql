ALTER TABLE accounts
    ADD COLUMN phone_number VARCHAR(14) UNIQUE;

ALTER TABLE accounts
    ADD CONSTRAINT accounts_phone_by_type
        CHECK (
            (account_type IN ('PERSONAL', 'AGENT') AND phone_number IS NOT NULL)
                OR
            (account_type IN ('FEE', 'FUNDING') AND phone_number IS NULL)
            );