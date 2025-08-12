import Foundation

/// Represents a collection of questions for the party game
struct QuestionDeck: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var questions: [Question]
    var isDefault: Bool
    var isPublic: Bool
    var createdBy: String?
    var downloadCount: Int
    var rating: Double
    var createdDate: Date
    var lastModified: Date
    
    /// The number of questions in this deck
    var questionCount: Int {
        return questions.count
    }
    
    /// Creates a new question deck
    /// - Parameters:
    ///   - name: The deck name
    ///   - description: Description of the deck
    ///   - questions: Array of questions in the deck
    ///   - isDefault: Whether this is a default system deck
    ///   - isPublic: Whether this deck can be shared publicly
    ///   - createdBy: Username of the creator (for community decks)
    init(
        name: String,
        description: String,
        questions: [Question] = [],
        isDefault: Bool = false,
        isPublic: Bool = false,
        createdBy: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.questions = questions
        self.isDefault = isDefault
        self.isPublic = isPublic
        self.createdBy = createdBy
        self.downloadCount = 0
        self.rating = 0.0
        self.createdDate = Date()
        self.lastModified = Date()
    }
    
    /// Creates a deck with all properties specified (useful for testing)
    /// - Parameters:
    ///   - id: Unique identifier for the deck
    ///   - name: The deck name
    ///   - description: Description of the deck
    ///   - questions: Array of questions in the deck
    ///   - isDefault: Whether this is a default system deck
    ///   - isPublic: Whether this deck can be shared publicly
    ///   - createdBy: Username of the creator
    ///   - downloadCount: Number of times downloaded
    ///   - rating: Average rating (0.0 to 5.0)
    ///   - createdDate: When the deck was created
    ///   - lastModified: When the deck was last modified
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        questions: [Question] = [],
        isDefault: Bool = false,
        isPublic: Bool = false,
        createdBy: String? = nil,
        downloadCount: Int = 0,
        rating: Double = 0.0,
        createdDate: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.questions = questions
        self.isDefault = isDefault
        self.isPublic = isPublic
        self.createdBy = createdBy
        self.downloadCount = downloadCount
        self.rating = rating
        self.createdDate = createdDate
        self.lastModified = lastModified
    }
    
    // MARK: - Validation
    
    /// Validates that the deck has valid content
    /// - Returns: True if the deck is valid, false otherwise
    func isValid() -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !questions.isEmpty &&
               questions.allSatisfy { $0.isValid() }
    }
    
    /// Returns a sanitized version of the deck name
    /// - Returns: Deck name with leading/trailing whitespace removed
    func sanitizedName() -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns a sanitized version of the deck description
    /// - Returns: Deck description with leading/trailing whitespace removed
    func sanitizedDescription() -> String {
        return description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if all questions in the deck are appropriate
    /// - Returns: True if all questions are appropriate, false otherwise
    func hasAppropriateContent() -> Bool {
        return questions.allSatisfy { $0.isAppropriate() }
    }
    
    // MARK: - Question Management
    
    /// Adds a question to the deck
    /// - Parameter question: The question to add
    /// - Returns: A new deck with the question added
    func addingQuestion(_ question: Question) -> QuestionDeck {
        var updatedDeck = self
        updatedDeck.questions.append(question)
        updatedDeck.lastModified = Date()
        return updatedDeck
    }
    
    /// Removes a question from the deck
    /// - Parameter questionId: The ID of the question to remove
    /// - Returns: A new deck with the question removed
    func removingQuestion(withId questionId: UUID) -> QuestionDeck {
        var updatedDeck = self
        updatedDeck.questions.removeAll { $0.id == questionId }
        updatedDeck.lastModified = Date()
        return updatedDeck
    }
    
    /// Updates a question in the deck
    /// - Parameter question: The updated question
    /// - Returns: A new deck with the question updated
    func updatingQuestion(_ question: Question) -> QuestionDeck {
        var updatedDeck = self
        if let index = updatedDeck.questions.firstIndex(where: { $0.id == question.id }) {
            updatedDeck.questions[index] = question
            updatedDeck.lastModified = Date()
        }
        return updatedDeck
    }
    
    /// Shuffles the questions in the deck
    /// - Returns: A new deck with shuffled questions
    func shuffled() -> QuestionDeck {
        var updatedDeck = self
        updatedDeck.questions.shuffle()
        return updatedDeck
    }
    
    /// Filters questions by category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of questions matching the category
    func questions(in category: Question.QuestionCategory) -> [Question] {
        return questions.filter { $0.category == category }
    }
    
    /// Filters questions by difficulty
    /// - Parameter difficulty: The difficulty level to filter by
    /// - Returns: Array of questions matching the difficulty
    func questions(withDifficulty difficulty: Question.DifficultyLevel) -> [Question] {
        return questions.filter { $0.difficulty == difficulty }
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: QuestionDeck, rhs: QuestionDeck) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - QuestionDeck Extensions

extension QuestionDeck {
    /// Creates a sample deck for testing and previews
    static var sample: QuestionDeck {
        QuestionDeck(
            name: "Sample Deck",
            description: "A sample deck for testing",
            questions: Question.sampleQuestions,
            isDefault: false,
            isPublic: false
        )
    }
    
    /// Creates the default Truth or Dare deck
    /// - Returns: Default Truth or Dare deck
    static var defaultTruthOrDareDeck: QuestionDeck {
        QuestionDeck(
            name: "Truth or Dare",
            description: "Classic party game with truth questions and fun dares",
            questions: Question.defaultTruthOrDareQuestions,
            isDefault: true,
            isPublic: false
        )
    }
    
    /// Creates the default Would You Rather deck
    /// - Returns: Default Would You Rather deck
    static var defaultWouldYouRatherDeck: QuestionDeck {
        QuestionDeck(
            name: "Would You Rather",
            description: "Thought-provoking choices that spark great conversations",
            questions: Question.defaultWouldYouRatherQuestions,
            isDefault: true,
            isPublic: false
        )
    }
    
    /// Creates all default decks
    /// - Returns: Array of all default decks
    static var defaultDecks: [QuestionDeck] {
        return [
            defaultTruthOrDareDeck,
            defaultWouldYouRatherDeck
        ]
    }
    
    /// Creates sample community decks for testing
    /// - Returns: Array of sample community decks
    static var sampleCommunityDecks: [QuestionDeck] {
        return [
            QuestionDeck(
                name: "Icebreakers",
                description: "Perfect questions to get to know new people",
                questions: [
                    Question(text: "What's your favorite childhood memory?", category: .custom, difficulty: .easy),
                    Question(text: "If you could have dinner with anyone, who would it be?", category: .custom, difficulty: .medium)
                ],
                isDefault: false,
                isPublic: true,
                createdBy: "PartyMaster"
            ),
            QuestionDeck(
                name: "Deep Thoughts",
                description: "Questions that make you think",
                questions: [
                    Question(text: "What's the meaning of life to you?", category: .custom, difficulty: .hard),
                    Question(text: "What would you do if you knew you couldn't fail?", category: .custom, difficulty: .medium)
                ],
                isDefault: false,
                isPublic: true,
                createdBy: "Philosopher"
            )
        ]
    }
}