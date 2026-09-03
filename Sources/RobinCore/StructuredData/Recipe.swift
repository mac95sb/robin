extension StructuredData {
  /// Schema-specific recipe facts.
  public struct Recipe: Equatable, Sendable {
    /// Ingredient descriptions in visible recipe order.
    public let ingredients: [String]
    /// Instruction steps in visible recipe order.
    public let instructions: [String]
    /// The ISO 8601 preparation duration, when shown.
    public let preparationTime: String?
    /// The ISO 8601 cooking duration, when shown.
    public let cookingTime: String?
    /// The visible recipe yield, such as `4 servings`.
    public let yield: String?
    /// The visible aggregate rating, when available.
    public let aggregateRating: AggregateRating?

    /// Creates recipe facts.
    public init(
      ingredients: [String],
      instructions: [String],
      preparationTime: String? = nil,
      cookingTime: String? = nil,
      yield: String? = nil,
      aggregateRating: AggregateRating? = nil
    ) {
      precondition(!ingredients.isEmpty && !instructions.isEmpty)
      self.ingredients = ingredients
      self.instructions = instructions
      self.preparationTime = preparationTime
      self.cookingTime = cookingTime
      self.yield = yield
      self.aggregateRating = aggregateRating
    }
  }
}
