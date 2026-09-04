# ``RobinJobs``

Run typed, durable background jobs with explicit tenant ownership.

## Overview

``JobClient`` encodes `Codable & Sendable` jobs into a ``JobQueue``.
``SQLiteJobQueue`` provides the durable single-node v1 implementation with
scheduled execution, expiring claims, idempotency, bounded retries, and
dead-letter state. ``JobWorker`` supplies typed handlers and graceful task
cancellation. Distributed queue providers are a post-v1 extension.

## Topics

### Jobs

- ``Job``
- ``JobClient``
- ``JobOptions``
- ``JobRetryPolicy``
- ``JobContext``

### Queue and workers

- ``JobQueue``
- ``SQLiteJobQueue``
- ``QueuedJob``
- ``JobClaim``
- ``JobFailureDisposition``
- ``JobWorker``
- ``AnyJobHandler``
- ``JobWorkerEvent``
- ``JobWorkerError``
- ``JobQueueError``
