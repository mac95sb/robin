import RobinContent
import RobinTesting
import Testing

@testable import __PROJECT__

@Test func journalPagesUseAppropriateStructuredData() {
  #expect(Site().metadata.structuredData.isEmpty)
  #expect(HomePage().metadata.structuredData == [.blog])
  #expect(PostPage().metadata.structuredData == [.article(.init(kind: .blogPosting))])
  #expect(AboutPage().metadata.structuredData.isEmpty)
}

@Test func bundledMarkdownPostsHaveMetadataAndStructuredContent() {
  for post in [Post.english, Post.french] {
    #expect(post.diagnostics.isEmpty)
    #expect(post.frontMatter.title != nil)
    #expect(post.frontMatter.publishedAt != nil)
    #expect(post.tableOfContents.count == 3)
    #expect(post.nodes.contains { if case .code = $0 { true } else { false } })
    #expect(post.nodes.contains { if case .list = $0 { true } else { false } })
  }
  #expect(AccessibilityAudit.audit(PostPage()).isEmpty)
}
