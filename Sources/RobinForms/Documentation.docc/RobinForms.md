# ``RobinForms``

Describe transport-stable form fields and uploaded files with typed Swift values.

## Overview

Declare fields once with `@FormModel` and `@Field`. Names, required values, text-length constraints,
and custom validation are shared by native HTML and JSON submission handling. Projected fields
render labels, native controls, and associated inline errors without JavaScript.

```swift
@FormModel
struct ProfileForm {
  @Field("name", label: "Your name", required: true, maximumLength: 80)
  var name = ""
}
```

Use `RobinHTML.Form` for the submission container and `$name` for its control. This module's
``Form`` protocol describes the submitted-value model. Public models must provide a public
zero-argument initializer.

```swift
RobinHTML.Form(action: "/profile") {
  profile.$name
  Button(.submit) { "Save" }
}
```

In a RobinServer route, call `request.form(ProfileForm.self)` after security middleware checks
origin/CSRF policy. Call `validated()` before mutating state. On validation failure, redisplay the
returned model and ``FormErrorSummary`` using a typed HTML response with status 400. Invalid text
is retained in the projected field; the wrapped value changes only after validation succeeds.
Custom validation runs on the server and needs no client runtime.

URL-encoded forms, multipart uploads, and JSON objects use the same model. Set `uploads: true` on
`RobinHTML.Form` for ``FileField`` controls. Validate file size, media type, and content in a custom
validator before storing a file; filenames and media types are untrusted. Browsers require users
to select files again after an error.

For several forms on one page, use `field.input(id:)` to give controls distinct identifiers.
``FormErrorSummary`` links to default field-name identifiers; use corresponding typed links when
choosing custom identifiers.

## Topics

### Start here

- <doc:Model-a-Form>

### Fields

- ``Form``
- ``FormModel()``
- ``FormValues``
- ``FormErrorSummary``
- ``Field``
- ``FileField``
- ``FieldValidationError``
- ``generatedFieldName(_:)``
