# ``RobinCache``

Cache typed application values without crossing user or tenant boundaries.

## Overview

Create a ``CacheContext`` with explicit visibility and tenant scope, then use a
``CacheKey`` with ``Cache``. ``MemoryCacheStore`` is the bounded single-node v1
provider. The ``CacheStore`` contract leaves distributed providers as a post-v1
extension without changing application keys or policies.

## Topics

### Keys and policy

- ``CacheKey``
- ``CacheContext``
- ``CacheVisibility``
- ``CachePolicy``
- ``CacheLifetime``
- ``CacheTag``

### Storage

- ``Cache``
- ``CacheStore``
- ``MemoryCacheStore``
- ``CacheRecord``
- ``CachedValue``
- ``CacheFreshness``
- ``CacheValidators``
- ``CacheEvent``
- ``CacheKeyError``
