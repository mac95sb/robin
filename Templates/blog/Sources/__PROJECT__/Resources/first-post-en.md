---
title: A quieter way to build for the web
summary: Start with words. Add a little structure. Let the browser do what it does best.
slug: a-quieter-web
locale: en
date: 2026-09-06T00:00:00Z
tags: [Engineering, Design]
---
The best tools leave room for the work. A page should feel considered before it feels complicated: a clear title, a comfortable measure, and a reason to keep reading.

This journal starts with **Markdown**, not a collection of hard-coded paragraphs. The words live in a file; Swift supplies the layout, the theme, and the route.

## Start with the content

Writing in plain text keeps the distance between an idea and a published page small. You can review a sentence in a diff, move a section without touching a view, and keep the story alongside the code.

- Use headings to give the piece a clear structure.
- Add emphasis when a phrase deserves attention.
- Keep links descriptive and useful.

> Good defaults should make the ordinary things feel effortless.

## A small, typed foundation

Robin turns the document into semantic components. A heading remains a heading; a list remains a list. The application chooses how the page looks.

```swift
Heading { "Hello, world!" }
Text { "A little less machinery." }
```

The title, summary, language, and publication date come from the front matter at the top of this file. The same information can inform the page metadata.

## Make it your own

Edit this post, adjust the tokens in `Theme.swift`, and rebuild. There is no separate stylesheet to keep in sync with the component tree.

You can learn more about the project on the [About page](/en/about).
