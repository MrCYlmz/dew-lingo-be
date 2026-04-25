CREATE TABLE app_user (
    id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    username      VARCHAR(50)  NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    level         VARCHAR(2)   NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_app_user PRIMARY KEY (id),
    CONSTRAINT ck_app_user_level CHECK (level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
    CONSTRAINT ck_app_user_username_length CHECK (char_length(username) >= 3)
);

CREATE UNIQUE INDEX ux_app_user_username_lower ON app_user (LOWER(username));
