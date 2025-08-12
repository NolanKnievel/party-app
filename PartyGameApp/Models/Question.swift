import Foundation

/// Represents a question in the party game
struct Question: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var text: String
    var category: QuestionCategory
    var difficulty: DifficultyLevel
    
    /// Categories of questions available in the game
    enum QuestionCategory: String, CaseIterable, Codable {
        case truthOrDare = "Truth or Dare"
        case wouldYouRather = "Would You Rather"
        case custom = "Custom"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    /// Difficulty levels for questions
    enum DifficultyLevel: String, CaseIterable, Codable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        
        var displayName: String {
            return self.rawValue.capitalized
        }
        
        var sortOrder: Int {
            switch self {
            case .easy: return 1
            case .medium: return 2
            case .hard: return 3
            }
        }
    }
    
    /// Creates a new question
    /// - Parameters:
    ///   - text: The question text
    ///   - category: The question category
    ///   - difficulty: The difficulty level
    init(text: String, category: QuestionCategory = .custom, difficulty: DifficultyLevel = .medium) {
        self.id = UUID()
        self.text = text
        self.category = category
        self.difficulty = difficulty
    }
    
    /// Creates a question with all properties specified (useful for testing)
    /// - Parameters:
    ///   - id: Unique identifier for the question
    ///   - text: The question text
    ///   - category: The question category
    ///   - difficulty: The difficulty level
    init(id: UUID = UUID(), text: String, category: QuestionCategory, difficulty: DifficultyLevel) {
        self.id = id
        self.text = text
        self.category = category
        self.difficulty = difficulty
    }
    
    // MARK: - Validation
    
    /// Validates that the question has valid content
    /// - Returns: True if the question is valid, false otherwise
    func isValid() -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns a sanitized version of the question text
    /// - Returns: Question text with leading/trailing whitespace removed
    func sanitizedText() -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if the question text contains inappropriate content
    /// - Returns: True if the question appears to be appropriate, false otherwise
    func isAppropriate() -> Bool {
        let inappropriateWords = ["inappropriate", "offensive"] // This would be expanded in a real app
        let lowercaseText = text.lowercased()
        return !inappropriateWords.contains { lowercaseText.contains($0) }
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Question Extensions

extension Question {
    /// Creates a sample question for testing and previews
    static var sample: Question {
        Question(
            text: "What's your most embarrassing moment?",
            category: .truthOrDare,
            difficulty: .medium
        )
    }
    
    /// Creates sample questions for testing
    /// - Returns: Array of sample questions
    static var sampleQuestions: [Question] {
        return [
            Question(
                text: "What's your most embarrassing moment?",
                category: .truthOrDare,
                difficulty: .medium
            ),
            Question(
                text: "Would you rather have the ability to fly or be invisible?",
                category: .wouldYouRather,
                difficulty: .easy
            ),
            Question(
                text: "Tell us about a time you broke the rules",
                category: .truthOrDare,
                difficulty: .hard
            ),
            Question(
                text: "Would you rather live in the past or the future?",
                category: .wouldYouRather,
                difficulty: .medium
            )
        ]
    }
    
    /// Creates default Truth or Dare questions
    /// - Returns: Array of default Truth or Dare questions
    static var defaultTruthOrDareQuestions: [Question] {
        let questions = [
            "What's your most embarrassing moment?",
            "What's the weirdest thing you've ever eaten?",
            "What's your biggest fear?",
            "What's the most trouble you've ever been in?",
            "What's your most unusual talent?",
            "Sing your favorite song out loud",
            "Do your best impression of someone in the room",
            "Dance for 30 seconds without music",
            "Tell a joke that makes everyone laugh",
            "Act out your favorite movie scene"
        ]
        
        return questions.enumerated().map { index, text in
            Question(
                text: text,
                category: .truthOrDare,
                difficulty: index < 5 ? .medium : .easy
            )
        }
    }
    
    /// Creates default Would You Rather questions
    /// - Returns: Array of default Would You Rather questions
    static var defaultWouldYouRatherQuestions: [Question] {
        let questions = [
            "Would you rather have the ability to fly or be invisible?",
            "Would you rather live in the past or the future?",
            "Would you rather be able to read minds or predict the future?",
            "Would you rather have unlimited money or unlimited time?",
            "Would you rather be famous or anonymous?",
            "Would you rather live underwater or in space?",
            "Would you rather have super strength or super speed?",
            "Would you rather never have to sleep or never have to eat?",
            "Would you rather be able to speak all languages or play all instruments?",
            "Would you rather have the power to heal others or bring back the dead?"
        ]
        
        return questions.enumerated().map { index, text in
            Question(
                text: text,
                category: .wouldYouRather,
                difficulty: index < 3 ? .easy : (index < 7 ? .medium : .hard)
            )
        }
    }
}