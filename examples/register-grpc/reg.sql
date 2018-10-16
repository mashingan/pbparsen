CREATE TABLE IF NOT EXISTS users (
    name varchar(20) UNIQUE
);

CREATE TABLE IF NOT EXISTS emails(
    username varchar(20) REFERENCES users(name),
    email varchar(20)
);
