import RobinBuild
import Testing

@Test func formSubmissionScopesHaveDistinctValidatedAssets() throws {
  for path in ["", "/", "//host", "/notes/", "/notes/../other", "/notes?query", "/notes#fragment"] {
    #expect(throws: BuildError.self) {
      try FormSubmissionClientModule(regionID: "notes", actionPrefix: path)
    }
  }
  #expect(throws: BuildError.self) {
    try FormSubmissionClientModule(regionID: "two words", actionPrefix: "/notes")
  }
  let notes = try FormSubmissionClientModule(regionID: "notes", actionPrefix: "/notes").asset()
  let tasks = try FormSubmissionClientModule(regionID: "tasks", actionPrefix: "/tasks").asset()
  #expect(notes.reference != tasks.reference)
  #expect(
    notes.scriptOrigin
      == .robinDirectCapability(.navigation, selectedBy: "FormSubmissionClientModule"))
  #expect(
    notes.bytes
      == (try FormSubmissionClientModule(regionID: "notes", actionPrefix: "/notes").asset().bytes))
}
