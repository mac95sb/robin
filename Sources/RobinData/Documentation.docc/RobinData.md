# ``RobinData``

Persist plain Swift models through database-neutral repositories, migrations, transactions, and durable key-value storage.

## Overview

RobinData keeps application models as ordinary `Codable & Sendable` values. Repositories receive a request-scoped ``RepositoryContext`` and issue typed ``SQLStatement`` and ``DatabaseQuery`` values through ``Database`` rather than depending on a database driver.

``SQLiteDatabase`` is the zero-configuration default. It supports in-memory test databases and persistent files through one serialized connection. The separate `RobinPostgres` module supplies production connection pooling while conforming to the same contracts.

``DatabaseKeyValueStore`` stores durable namespaced bytes in either adapter. Expiration checks use an explicit date or injected clock, conditional writes are atomic, and cleanup is bounded.

## Topics

### Start here

- <doc:Persist-Application-Data>

### Database contracts

- ``Database``
- ``DatabaseConnection``
- ``DatabaseValue``
- ``DatabaseRow``
- ``SQLStatement``
- ``SQLIdentifier``
- ``SQLDialect``
- ``DatabaseQuery``

### Repositories and schema

- ``Repository``
- ``RepositoryContext``
- ``Migration``
- ``Migrator``
- ``TestDatabase``

### SQLite and durable values

- ``SQLiteDatabase``
- ``DatabaseKeyValueStore``
- ``KeyValueStore``
- ``KeyValueWriteCondition``
- ``KeyValueStoreError``
