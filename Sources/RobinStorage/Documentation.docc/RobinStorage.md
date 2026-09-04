# ``RobinStorage``

Store validated blobs outside relational persistence.

## Overview

``ScopedObjectKey`` requires an explicit tenant boundary. ``LocalStorage``
streams bodies through isolated, checksum-addressed object directories and
publishes validated writes atomically. ``Storage`` and ``StorageIntentSigner``
also define the operations used by S3-compatible providers.

## Topics

### Objects

- ``ObjectKey``
- ``ScopedObjectKey``
- ``StorageBody``
- ``StorageWrite``
- ``StoragePolicy``
- ``StorageMetadata``
- ``StoredObject``

### Providers

- ``Storage``
- ``LocalStorage``
- ``TestStorage``
- ``StorageIntentSigner``
- ``SignedStorageIntent``
- ``StorageIntentOperation``
- ``S3CompatibleStorage``
- ``S3Configuration``
- ``StorageError``
