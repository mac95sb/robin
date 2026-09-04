# Metadata and Structured Data

Declare shared document facts once and let Robin project them into each supported format.

## Provide common metadata

Application metadata supplies defaults. A page replaces only the values it declares:

```swift
var metadata: Metadata {
  Metadata(
    title: "Download",
    site: "Robin",
    description: "Build Swift-native web applications.",
    canonicalURL: "https://example.com/download",
    image: Metadata.Image(
      url: "https://example.com/robin.png",
      alternativeText: "The Robin logo",
      width: 1200,
      height: 630,
      mediaType: "image/png"
    ),
    structuredData: [
      .softwareApplication(
        StructuredData.SoftwareApplication(
          operatingSystem: "Linux and macOS",
          category: "DeveloperApplication"
        )
      )
    ]
  )
}
```

Robin emits `Download | Robin` as the document, Open Graph, and X card title. The description,
canonical URL, and image flow into their corresponding standard and social metadata. The software
application entry adds only schema-specific facts; Robin supplies its common name, description, URL,
and image when encoding JSON-LD.

Structured data must describe content visible on the page. Robin rejects duplicate declarations of
the same schema for one page rather than choosing one silently. Feed metadata will reuse the same
common fields when a typed feed surface is available; Robin does not emit a feed declaration without
one.

Use the matching typed value for each page:

- ``StructuredData/Article`` selects the applicable article kind; authorship and dates come from
  ``Metadata``.
- ``StructuredData/BreadcrumbList`` adds an ordered trail of ``StructuredData/Breadcrumb`` values.
- ``StructuredData/Event`` adds its schedule, physical or online venue, and ticket offer.
- ``StructuredData/Product`` adds its SKU, brand, offers, and ``StructuredData/AggregateRating``.
- ``StructuredData/Recipe`` adds ingredients, instructions, durations, yield, and rating.
- ``StructuredData/SoftwareApplication`` adds platform, category, offer, and rating details.

Do not copy a page's title, description, canonical URL, or image into these values. Robin always takes
those shared facts from ``Metadata``. Robin intentionally has no raw Schema.org or JSON escape hatch;
add a focused typed schema value when another content type is required.

## Topics

- ``Metadata``
- ``StructuredData``
- ``StructuredData/Article``
- ``StructuredData/BreadcrumbList``
- ``StructuredData/Event``
- ``StructuredData/Product``
- ``StructuredData/Recipe``
- ``StructuredData/SoftwareApplication``
- ``StructuredData/Offer``
- ``StructuredData/AggregateRating``
