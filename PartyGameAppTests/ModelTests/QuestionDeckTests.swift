import XCTest
@testable import PartyGameApp

final class QuestionDeckTests: XCTestCase {
    
    func testQuestionDeckInitialization() {
        // Test basic initialization
        let deck = QuestionDeck(
            name: "Test Deck",
            description: "A test deck"
        )
        
        XCTAssertEqual(deck.name, "Test Deck")
        XCTAssertEqual(deck.description, "A test deck")
        XCTAssertEqual(deck.questions.count, 0)
        XCTAssertFalse(deck.isDefault)
        XCTAssertFalse(deck.isPublic)
        XCTAssertNil(deck.createdBy)
        XCTAssertEqual(deck.downloadCount, 0)
        XCTAssertEqual(deck.rating, 0.0)
        XCTAssertNotNil(deck.id)
        XCTAssertNotNil(deck.createdDate)
        XCTAssertNotNil(deck.lastModified)
    }
    
    func testQuestionDeckInitializationWithQuestions() {
        // Test initialization with questions
        let questions = Question.sampleQuestions
        let deck = QuestionDeck(
            name: "Sample Deck",
            description: "A deck with sample questions",
            questions: questions,
            isDefault: true,
            isPublic: true,
            createdBy: "TestUser"
        )
        
        XCTAssertEqual(deck.name, "Sample Deck")
        XCTAssertEqual(deck.description, "A deck with sample questions")
        XCTAssertEqual(deck.questions.count, questions.count)
        XCTAssertTrue(deck.isDefault)
        XCTAssertTrue(deck.isPublic)
        XCTAssertEqual(deck.createdBy, "TestUser")
        XCTAssertEqual(deck.questionCount, questions.count)
    }
    
    func testQuestionDeckValidation() {
        // Test valid deck
        let validDeck = QuestionDeck(
            name: "Valid Deck",
            description: "A valid deck",
            questions: [Question.sample]
        )
        XCTAssertTrue(validDeck.isValid())
        
        // Test invalid deck with empty name
        let invalidNameDeck = QuestionDeck(
            name: "",
            description: "Valid description",
            questions: [Question.sample]
        )
        XCTAssertFalse(invalidNameDeck.isValid())
        
        // Test invalid deck with empty description
        let invalidDescriptionDeck = QuestionDeck(
            name: "Valid Name",
            description: "",
            questions: [Question.sample]
        )
        XCTAssertFalse(invalidDescriptionDeck.isValid())
        
        // Test invalid deck with no questions
        let noQuestionsDeck = QuestionDeck(
            name: "Valid Name",
            description: "Valid description",
            questions: []
        )
        XCTAssertFalse(noQuestionsDeck.isValid())
        
        // Test invalid deck with invalid questions
        let invalidQuestion = Question(text: "")
        let invalidQuestionsDeck = QuestionDeck(
            name: "Valid Name",
            description: "Valid description",
            questions: [invalidQuestion]
        )
        XCTAssertFalse(invalidQuestionsDeck.isValid())
    }
    
    func testQuestionDeckSanitization() {
        // Test name and description sanitization
        let deck = QuestionDeck(
            name: "  Test Deck  ",
            description: "  Test Description  "
        )
        
        XCTAssertEqual(deck.sanitizedName(), "Test Deck")
        XCTAssertEqual(deck.sanitizedDescription(), "Test Description")
    }
    
    func testQuestionDeckAppropriatenessCheck() {
        // Test deck with appropriate content
        let appropriateDeck = QuestionDeck(
            name: "Good Deck",
            description: "A good deck",
            questions: [Question(text: "What's your favorite color?")]
        )
        XCTAssertTrue(appropriateDeck.hasAppropriateContent())
        
        // Test deck with inappropriate content
        let inappropriateDeck = QuestionDeck(
            name: "Bad Deck",
            description: "A bad deck",
            questions: [Question(text: "This is inappropriate content")]
        )
        XCTAssertFalse(inappropriateDeck.hasAppropriateContent())
    }
    
    func testQuestionDeckEquality() {
        // Test equality based on ID
        let id = UUID()
        let deck1 = QuestionDeck(
            id: id,
            name: "Deck 1",
            description: "Description 1"
        )
        let deck2 = QuestionDeck(
            id: id,
            name: "Deck 2",
            description: "Description 2"
        )
        
        XCTAssertEqual(deck1, deck2)
        
        // Test inequality with different IDs
        let deck3 = QuestionDeck(name: "Same Name", description: "Same Description")
        let deck4 = QuestionDeck(name: "Same Name", description: "Same Description")
        
        XCTAssertNotEqual(deck3, deck4)
    }
    
    func testQuestionDeckHashable() {
        // Test that decks with same ID have same hash
        let id = UUID()
        let deck1 = QuestionDeck(id: id, name: "Deck A", description: "Description A")
        let deck2 = QuestionDeck(id: id, name: "Deck B", description: "Description B")
        
        XCTAssertEqual(deck1.hashValue, deck2.hashValue)
    }
    
    func testQuestionDeckCodable() throws {
        // Test encoding and decoding
        let originalDeck = QuestionDeck(
            name: "Codable Deck",
            description: "A deck for testing codable",
            questions: Question.sampleQuestions,
            isDefault: true,
            isPublic: false,
            createdBy: "TestUser"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalDeck)
        
        let decoder = JSONDecoder()
        let decodedDeck = try decoder.decode(QuestionDeck.self, from: data)
        
        XCTAssertEqual(originalDeck.id, decodedDeck.id)
        XCTAssertEqual(originalDeck.name, decodedDeck.name)
        XCTAssertEqual(originalDeck.description, decodedDeck.description)
        XCTAssertEqual(originalDeck.questions.count, decodedDeck.questions.count)
        XCTAssertEqual(originalDeck.isDefault, decodedDeck.isDefault)
        XCTAssertEqual(originalDeck.isPublic, decodedDeck.isPublic)
        XCTAssertEqual(originalDeck.createdBy, decodedDeck.createdBy)
    }
    
    func testQuestionManagement() {
        // Test adding questions
        let deck = QuestionDeck(name: "Test", description: "Test")
        let question = Question.sample
        let updatedDeck = deck.addingQuestion(question)
        
        XCTAssertEqual(updatedDeck.questions.count, 1)
        XCTAssertTrue(updatedDeck.questions.contains(question))
        XCTAssertNotEqual(deck.lastModified, updatedDeck.lastModified)
        
        // Test removing questions
        let removedDeck = updatedDeck.removingQuestion(withId: question.id)
        XCTAssertEqual(removedDeck.questions.count, 0)
        XCTAssertFalse(removedDeck.questions.contains(question))
        
        // Test updating questions
        var modifiedQuestion = question
        modifiedQuestion.text = "Modified question text"
        let modifiedDeck = updatedDeck.updatingQuestion(modifiedQuestion)
        
        XCTAssertEqual(modifiedDeck.questions.count, 1)
        XCTAssertEqual(modifiedDeck.questions.first?.text, "Modified question text")
    }
    
    func testQuestionDeckShuffling() {
        // Create deck with multiple questions
        let questions = Question.sampleQuestions
        let deck = QuestionDeck(
            name: "Shuffle Test",
            description: "Test shuffling",
            questions: questions
        )
        
        let shuffledDeck = deck.shuffled()
        
        // Should have same questions, potentially different order
        XCTAssertEqual(shuffledDeck.questions.count, deck.questions.count)
        
        // All original questions should still be present
        for question in deck.questions {
            XCTAssertTrue(shuffledDeck.questions.contains(question))
        }
    }
    
    func testQuestionFiltering() {
        // Create deck with mixed questions
        let truthQuestion = Question(text: "Truth question", category: .truthOrDare, difficulty: .easy)
        let wouldYouRatherQuestion = Question(text: "Would you rather question", category: .wouldYouRather, difficulty: .hard)
        let customQuestion = Question(text: "Custom question", category: .custom, difficulty: .medium)
        
        let deck = QuestionDeck(
            name: "Mixed Deck",
            description: "Mixed questions",
            questions: [truthQuestion, wouldYouRatherQuestion, customQuestion]
        )
        
        // Test filtering by category
        let truthQuestions = deck.questions(in: .truthOrDare)
        XCTAssertEqual(truthQuestions.count, 1)
        XCTAssertEqual(truthQuestions.first?.id, truthQuestion.id)
        
        let wouldYouRatherQuestions = deck.questions(in: .wouldYouRather)
        XCTAssertEqual(wouldYouRatherQuestions.count, 1)
        XCTAssertEqual(wouldYouRatherQuestions.first?.id, wouldYouRatherQuestion.id)
        
        // Test filtering by difficulty
        let easyQuestions = deck.questions(withDifficulty: .easy)
        XCTAssertEqual(easyQuestions.count, 1)
        XCTAssertEqual(easyQuestions.first?.id, truthQuestion.id)
        
        let hardQuestions = deck.questions(withDifficulty: .hard)
        XCTAssertEqual(hardQuestions.count, 1)
        XCTAssertEqual(hardQuestions.first?.id, wouldYouRatherQuestion.id)
    }
    
    func testDefaultDecks() {
        // Test default Truth or Dare deck
        let truthOrDareDeck = QuestionDeck.defaultTruthOrDareDeck
        XCTAssertEqual(truthOrDareDeck.name, "Truth or Dare")
        XCTAssertTrue(truthOrDareDeck.isDefault)
        XCTAssertFalse(truthOrDareDeck.isPublic)
        XCTAssertEqual(truthOrDareDeck.questions.count, 10)
        XCTAssertTrue(truthOrDareDeck.isValid())
        
        // Test default Would You Rather deck
        let wouldYouRatherDeck = QuestionDeck.defaultWouldYouRatherDeck
        XCTAssertEqual(wouldYouRatherDeck.name, "Would You Rather")
        XCTAssertTrue(wouldYouRatherDeck.isDefault)
        XCTAssertFalse(wouldYouRatherDeck.isPublic)
        XCTAssertEqual(wouldYouRatherDeck.questions.count, 10)
        XCTAssertTrue(wouldYouRatherDeck.isValid())
        
        // Test all default decks
        let defaultDecks = QuestionDeck.defaultDecks
        XCTAssertEqual(defaultDecks.count, 2)
        XCTAssertTrue(defaultDecks.allSatisfy { $0.isDefault })
        XCTAssertTrue(defaultDecks.allSatisfy { $0.isValid() })
    }
    
    func testSampleDecks() {
        // Test sample deck
        let sampleDeck = QuestionDeck.sample
        XCTAssertTrue(sampleDeck.isValid())
        XCTAssertFalse(sampleDeck.isDefault)
        XCTAssertFalse(sampleDeck.isPublic)
        
        // Test sample community decks
        let communityDecks = QuestionDeck.sampleCommunityDecks
        XCTAssertEqual(communityDecks.count, 2)
        XCTAssertTrue(communityDecks.allSatisfy { $0.isPublic })
        XCTAssertTrue(communityDecks.allSatisfy { !$0.isDefault })
        XCTAssertTrue(communityDecks.allSatisfy { $0.createdBy != nil })
        XCTAssertTrue(communityDecks.allSatisfy { $0.isValid() })
    }
}