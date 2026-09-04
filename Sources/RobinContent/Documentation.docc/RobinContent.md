# ``RobinContent``

Convert Markdown documents into typed content nodes without raw HTML escape hatches.

## Overview

RobinContent parses supported Markdown structures, returns typed nodes in source order, and reports rejected or unsupported input as diagnostics.

## Topics

### Start here

- <doc:Parse-Markdown-Content>

### Parsing

- ``MarkdownContentParser``
- ``ParsedContent``
- ``ContentDiagnostic``
- ``ContentFrontMatter``
- ``ContentDocument``
- ``ContentCollection``
- ``ContentPage``
- ``Pagination``
- ``ContentCollectionError``

### Typed content

- ``ContentNode``
- ``ContentInline``
- ``TableOfContentsEntry``
- ``AdmonitionNode``
- ``AdmonitionKind``

### Localization

- ``LocalizedPages``
- ``t(_:)``
- ``localizedPath(_:)``
- ``LocalizedStringKey``
- ``LocalizedMessage``
- ``LocalizationCatalog``
- ``LocalizationDiagnostic``
- ``LocalePreference``
- ``LocaleNegotiator``
- ``LocalizationFormatter``
- ``TextDirection``
- ``LocalizedRouteSet``
- ``TranslationProvider``

### Publication

- ``ContentFeed``
- ``FeedItem``
- ``Sitemap``
- ``SitemapEntry``
