# ``RobinPolar``

Connect Robin applications to Polar checkout, subscriptions, and webhooks.

## Overview

``PolarClient`` calls Polar's production or sandbox API without exposing its access token. A
``PolarPlugin`` contributes the client as a typed service and a ``PolarWebhookRoute`` that verifies
signed delivery headers before durably enqueueing ``PolarWebhookJob``.

## Topics

### Client

- ``PolarClient``
- ``PolarEnvironment``
- ``PolarCheckoutRequest``
- ``PolarCheckout``
- ``PolarSubscription``
- ``PolarError``

### Plugin

- ``PolarPlugin``
- ``PolarClientKey``
- ``PolarWebhookRoute``
- ``PolarWebhookJob``
