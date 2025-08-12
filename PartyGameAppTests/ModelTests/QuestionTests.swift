import XCTest
@testable import PartyGameApp

final class QuestionTests: XCTestCase {
    
    func testQuestionInitialization() {
        // Test basic initialization
        let question = Question(text: "What's your favorite color?")
        
        XCTAssertEqual(question.text, "What's your favorite color?")
        XCTAssertEqual(question.category, .custom)
        XCTAssertEqual(question.difficulty, .medium)
        XCTAssertNotNil(question.id)
    }
    
    func testQuestionInitializationWithAllParameters() {
        // Test initialization with all parameters
        let id = UUID()
        let question = Question(
            id: id,
            text: "Truth or dare?",
            category: .truthOrDare,
            difficulty: .easy
        )
        
        XCTAssertEqual(question.id, id)
        XCTAssertEqual(question.text, "Truth or dare?")
        XCTAssertEqual(question.category, .truthOrDare)
        XCTAssertEqual(question.difficulty, .easy)
    }
    
    func testQuestionValidation() {
        // Test valid question
        let validQuestion = Question(text: "What's your dream job?")
        XCTAssertTrue(validQuestion.isValid())
        
        // Test invalid question with empty text
        let invalidQuestion = Question(text: "")
        XCTAssertFalse(invalidQuestion.isValid())
        
        // Test invalid question with whitespace-only text
        let whitespaceQuestion = Question(text: "   ")
        XCTAssertFalse(whitespaceQuestion.isValid())
    }
    
    func testQuestionTextSanitization() {
        // Test text with leading/trailing whitespace
        let question = Question(text: "  What's your hobby?  ")
        XCTAssertEqual(question.sanitizedText(), "What's your hobby?")
        
        // Test text with tabs and newlines
        let messyQuestion = Question(text: "\t\nWhat's your name?\n\t")
        XCTAssertEqual(messyQuestion.sanitizedText(), "What's your name?")
    }
    
    func testQuestionAppropriatenessCheck() {
        // Test appropriate question
        let appropriateQuestion = Question(text: "What's your favorite movie?")
        XCTAssertTrue(appropriateQuestion.isAppropriate())
        
        // Test inappropriate question (based on simple keyword matching)
        let inappropriateQuestion = Question(text: "This is inappropriate content")
        XCTAssertFalse(inappropriateQuestion.isAppropriate())
        
        let offensiveQuestion = Question(text: "This is offensive material")
        XCTAssertFalse(offensiveQuestion.isAppropriate())
    }
    
    func testQuestionEquality() {
        // Test equality based on ID
        let id = UUID()
        let question1 = Question(id: id, text: "Question 1", category: .custom, difficulty: .easy)
        let question2 = Question(id: id, text: "Question 2", category: .truthOrDare, difficulty: .hard)
        
        XCTAssertEqual(question1, question2)
        
        // Test inequality with different IDs
        let question3 = Question(text: "Same text")
        let question4 = Question(text: "Same text")
        
        XCTAssertNotEqual(question3, question4)
    }
    
    func testQuestionHashable() {
        // Test that questions with same ID have same hash
        let id = UUID()
        let question1 = Question(id: id, text: "Question A", category: .custom, difficulty: .easy)
        let question2 = Question(id: id, text: "Question B", category: .truthOrDare, difficulty: .hard)
        
        XCTAssertEqual(question1.hashValue, question2.hashValue)
        
        // Test that questions with different IDs have different hashes (usually)
        let question3 = Question(text: "Question")
        let question4 = Question(text: "Question")
        
        XCTAssertNotEqual(question3.hashValue, question4.hashValue)
    }
    
    func testQuestionCodable() throws {
        // Test encoding and decoding
        let originalQuestion = Question(
            text: "What's your biggest fear?",
            category: .truthOrDare,
            difficulty: .hard
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalQuestion)
        
        let decoder = JSONDecoder()
        let decodedQuestion = try decoder.decode(Question.self, from: data)
        
        XCTAssertEqual(originalQuestion.id, decodedQuestion.id)
        XCTAssertEqual(originalQuestion.text, decodedQuestion.text)
        XCTAssertEqual(originalQuestion.category, decodedQuestion.category)
        XCTAssertEqual(originalQuestion.difficulty, decodedQuestion.difficulty)
    }
    
    func testQuestionCategoryDisplayNames() {
        // Test category display names
        XCTAssertEqual(Question.QuestionCategory.truthOrDare.displayName, "Truth or Dare")
        XCTAssertEqual(Question.QuestionCategory.wouldYouRather.displayName, "Would You Rather")
        XCTAssertEqual(Question.QuestionCategory.custom.displayName, "Custom")
    }
    
    func testDifficultyLevelDisplayNames() {
        // Test difficulty display names
        XCTAssertEqual(Question.DifficultyLevel.easy.displayName, "Easy")
        XCTAssertEqual(Question.DifficultyLevel.medium.displayName, "Medium")
        XCTAssertEqual(Question.DifficultyLevel.hard.displayName, "Hard")
    }
    
    func testDifficultyLevelSortOrder() {
        // Test difficulty sort order
        XCTAssertEqual(Question.DifficultyLevel.easy.sortOrder, 1)
        XCTAssertEqual(Question.DifficultyLevel.medium.sortOrder, 2)
        XCTAssertEqual(Question.DifficultyLevel.hard.sortOrder, 3)
    }
    
    func testSampleQuestionCreation() {
        // Test sample question creation
        let sampleQuestion = Question.sample
        XCTAssertEqual(sampleQuestion.text, "What's your most embarrassing moment?")
        XCTAssertEqual(sampleQuestion.category, .truthOrDare)
        XCTAssertEqual(sampleQuestion.difficulty, .medium)
        XCTAssertTrue(sampleQuestion.isValid())
    }
    
    func testSampleQuestionsCreation() {
        // Test creating sample questions
        let questions = Question.sampleQuestions
        
        XCTAssertEqual(questions.count, 4)
        
        // Test all questions are valid
        for question in questions {
            XCTAssertTrue(question.isValid())
            XCTAssertTrue(question.isAppropriate())
        }
        
        // Test all questions have unique IDs
        let uniqueIds = Set(questions.map { $0.id })
        XCTAssertEqual(uniqueIds.count, questions.count)
    }
    
    func testDefaultTruthOrDareQuestions() {
        // Test default Truth or Dare questions
        let questions = Question.defaultTruthOrDareQuestions
        
        XCTAssertEqual(questions.count, 10)
        
        // Test all questions are Truth or Dare category
        for question in questions {
            XCTAssertEqual(question.category, .truthOrDare)
            XCTAssertTrue(question.isValid())
            XCTAssertTrue(question.isAppropriate())
        }
        
        // Test difficulty distribution
        let mediumQuestions = questions.filter { $0.difficulty == .medium }
        let easyQuestions = questions.filter { $0.difficulty == .easy }
        
        XCTAssertEqual(mediumQuestions.count, 5)
        XCTAssertEqual(easyQuestions.count, 5)
    }
    
    func testDefaultWouldYouRatherQuestions() {
        // Test default Would You Rather questions
        let questions = Question.defaultWouldYouRatherQuestions
        
        XCTAssertEqual(questions.count, 10)
        
        // Test all questions are Would You Rather category
        for question in questions {
            XCTAssertEqual(question.category, .wouldYouRather)
            XCTAssertTrue(question.isValid())
            XCTAssertTrue(question.isAppropriate())
        }
        
        // Test difficulty distribution
        let easyQuestions = questions.filter { $0.difficulty == .easy }
        let mediumQuestions = questions.filter { $0.difficulty == .medium }
        let hardQuestions = questions.filter { $0.difficulty == .hard }
        
        XCTAssertEqual(easyQuestions.count, 3)
        XCTAssertEqual(mediumQuestions.count, 4)
        XCTAssertEqual(hardQuestions.count, 3)
    }
}