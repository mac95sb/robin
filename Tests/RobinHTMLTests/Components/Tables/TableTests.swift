import RobinHTML
import Testing

@Suite("Table")
struct TableTests {
  @Test func tableComposesRowsAndCells() throws {
    let table = try HTMLRenderer.render(
      Table(id: "pricing") {
        TableRow {
          TableHeaderCell { "Plan" }
          TableHeaderCell { "Price" }
        }
        TableRow {
          TableCell { "Basic" }
          TableCell { "$10" }
        }
      }
    )

    #expect(
      table
        == #"<table id="pricing"><tr><th>Plan</th><th>Price</th></tr><tr><td>Basic</td><td>$10</td></tr></table>"#
    )
  }
}
