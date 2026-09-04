# ``RobinPostgres``

Run RobinData repositories on a pooled PostgreSQL database.

## Overview

``PostgresDatabase`` owns a `PostgresNIO` connection pool and implements the same database, transaction, migration, typed-query, health, and durable key-value contracts as SQLite.

The common value surface maps integers, floating-point values, text, bytes, Booleans, and nulls. PostgreSQL-specific types and SQL remain available only inside this adapter; portable repositories should use the common surface. SQLite serializes work through one connection, while PostgreSQL leases concurrent pooled connections. `TestDatabase.postgres(configuration:)` creates and later drops an isolated database, so its user needs `CREATE DATABASE` and `DROP DATABASE` privileges.

## Topics

### Start here

- <doc:Configure-PostgreSQL>

### PostgreSQL

- ``PostgresConfiguration``
- ``PostgresDatabase``
