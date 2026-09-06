# Enhance form submissions

Update a server-rendered region after submitting a form, without navigating away.

Add an identifier to the region containing your forms, and register a
``FormSubmissionClientModule`` asset when starting the application:

```swift
Section(id: "notes") {
  // Ordinary Robin forms and server-rendered notes.
}

try FormSubmissionClientModule(
  regionID: "notes", actionPrefix: "/api/v1/notes"
).asset()
```

The module enhances URL-encoded POST forms inside that region whose same-origin
action matches the prefix or a child path. Other forms, uploads, and buttons with
submission overrides retain native behaviour. Use disjoint regions when enabling
multiple modules. Assets have stable, configuration-specific identities.

## Endpoint contract

For requests accepting `application/json`, return a successful status after saving,
without redirecting. For validation failures, return a non-success status with an
`errors` array of messages. Keep redirects and HTML validation responses for ordinary
browser submissions, so forms continue to work without JavaScript.

After a successful mutation, Robin fetches the current page and replaces the matching
region. Authentication cookies and hidden form fields travel with the request;
server authorization, validation, and CSRF checks remain required.

## User interaction

Robin prevents overlapping enhanced submissions within a region, marks it busy,
and announces success or errors. Give editable controls stable, unique identifiers
to preserve drafts in other forms and changes typed while saving. Hidden fields
come from the fresh server response. Focus stays outside the region if the user
has moved away; otherwise it returns to a surviving control or the region.

The response's generated inline Robin styles are applied through a constructed
stylesheet. The document, URL, and surrounding regions remain in place. Replacement
does not rerun scripts or preserve arbitrary component-owned browser state.

Each request times out after 30 seconds. Robin never automatically retries a
mutation: a lost response can leave its result uncertain. If saving succeeds but
refreshing fails, the page explains that the change was saved and asks the user to
reload. Validation errors leave their input intact.

## Verify changes

Run the Swift tests with `mise run test`. In the dashboard template, verify that
creating, editing, and deleting notes updates the region without navigation; drafts
in other forms survive; and disabling JavaScript restores normal form submission.
