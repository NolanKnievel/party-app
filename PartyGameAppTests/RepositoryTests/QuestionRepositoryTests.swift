import XCTest
import CoreData
import Combine
@testable import PartyGameApp

class QuestionRepositoryTests: XCTestCase {
    var questionRepository: CoreDataQuestionRepository!
    var deckRepository: CoreDataDeckRepository!
    var persistenceController: PersistenceController!
    var cancellables: Set<AnyCancellable>!
    var testDeck: QuestionDeck!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        questionRepository = CoreDataQuestionRepository(persistenceController: persistenceController)
        deckRepository = CoreDataDeckRepository(persistenceController: persistenceController)
        cancellables = Set<AnyCancellable>()
        
        // Create a test deck for questions
        testDeck = QuestionDeck(
            name: "Test Deck",
            description: "A deck for testing questions",
            questions: []
        )
        
        // Save the test deck
        let expectation = XCTestExpectation(description: "Save test deck")
        deckRepository.saveDeck(testDeck)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDownWithError() throws {
        testDeck = nil
        cancellables = nil
        questionRepository = nil
        deckRepository = nil
        persistenceController = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Save Question Tests
    
    func testSaveQuestion_ValidQuestion_Success() throws {
        // Given
        let question = Question(
            text: "What's your favorite color?",
            category: .custom,
            difficulty: .easy
        )
        
        let expectation = XCTestExpectation(description: "Save question")
        var savedQuestion: Question?
        var saveError: Error?
        
        // When
        questionRepository.saveQuestion(question, to: testDeck.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        saveError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { question in
                    savedQuestion = question
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(saveError)
        XCTAssertNotNil(savedQuestion)
        XCTAssertEqual(savedQuestion?.text, "What's your favorite color?")
        XCTAssertEqual(savedQuestion?.category, .custom)
        XCTAssertEqual(savedQuestion?.difficulty, .easy)
    }
    
    func testSaveQuestion_NonExistentDeck_ReturnsError() throws {
        // Given
        let question = Question(
            text: "Test question?",
            category: .custom,
            difficulty: .easy
        )
        let nonExistentDeckId = UUID()
        
        let expectation = XCTestExpectation(description: "Save question to non-existent deck")
        var saveError: Error?
        
        // When
        questionRepository.saveQuestion(question, to: nonExistentDeckId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        saveError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(saveError)
        XCTAssertTrue(saveError is RepositoryError)
    }
    
    // MARK: - Get Question Tests
    
    func testGetQuestion_ExistingId_ReturnsCorrectQuestion() throws {
        // Given
        let question = Question(
            text: "What's your favorite food?",
            category: .truthOrDare,
            difficulty: .medium
        )
        
        let saveExpectation = XCTestExpectation(description: "Save question")
        let getExpectation = XCTestExpectation(description: "Get question")
        
        // Save question first
        questionRepository.saveQuestion(question, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When
        var retrievedQuestion: Question?
        questionRepository.getQuestion(by: question.id)
            .sink(
                receiveCompletion: { _ in getExpectation.fulfill() },
                receiveValue: { question in retrievedQuestion = question }
            )
            .store(in: &cancellables)
        
        wait(for: [getExpectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(retrievedQuestion)
        XCTAssertEqual(retrievedQuestion?.id, question.id)
        XCTAssertEqual(retrievedQuestion?.text, "What's your favorite food?")
        XCTAssertEqual(retrievedQuestion?.category, .truthOrDare)
        XCTAssertEqual(retrievedQuestion?.difficulty, .medium)
    }
    
    func testGetQuestion_NonExistentId_ReturnsNil() throws {
        // Given
        let nonExistentId = UUID()
        let expectation = XCTestExpectation(description: "Get non-existent question")
        
        // When
        var retrievedQuestion: Question?
        questionRepository.getQuestion(by: nonExistentId)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { question in retrievedQuestion = question }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(retrievedQuestion)
    }
    
    // MARK: - Get Questions for Deck Tests
    
    func testGetQuestionsForDeck_WithQuestions_ReturnsAllQuestions() throws {
        // Given
        let question1 = Question(text: "Question 1?", category: .custom, difficulty: .easy)
        let question2 = Question(text: "Question 2?", category: .custom, difficulty: .medium)
        
        let saveExpectation1 = XCTestExpectation(description: "Save question 1")
        let saveExpectation2 = XCTestExpectation(description: "Save question 2")
        let getExpectation = XCTestExpectation(description: "Get questions for deck")
        
        // Save questions
        questionRepository.saveQuestion(question1, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation1.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        questionRepository.saveQuestion(question2, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation2.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation1, saveExpectation2], timeout: 1.0)
        
        // When
        var deckQuestions: [Question] = []
        questionRepository.getQuestions(for: testDeck.id)
            .sink(
                receiveCompletion: { _ in getExpectation.fulfill() },
                receiveValue: { questions in deckQuestions = questions }
            )
            .store(in: &cancellables)
        
        wait(for: [getExpectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(deckQuestions.count, 2)
        XCTAssertTrue(deckQuestions.contains { $0.text == "Question 1?" })
        XCTAssertTrue(deckQuestions.contains { $0.text == "Question 2?" })
    }
    
    func testGetQuestionsForDeck_EmptyDeck_ReturnsEmptyArray() throws {
        // Given
        let expectation = XCTestExpectation(description: "Get questions for empty deck")
        
        // When
        var deckQuestions: [Question] = []
        questionRepository.getQuestions(for: testDeck.id)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { questions in deckQuestions = questions }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(deckQuestions.isEmpty)
    }
    
    // MARK: - Update Question Tests
    
    func testUpdateQuestion_ExistingQuestion_Success() throws {
        // Given
        let originalQuestion = Question(
            text: "Original question?",
            category: .custom,
            difficulty: .easy
        )
        
        let saveExpectation = XCTestExpectation(description: "Save original question")
        let updateExpectation = XCTestExpectation(description: "Update question")
        
        // Save original question
        questionRepository.saveQuestion(originalQuestion, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When - Update question
        let updatedQuestion = Question(
            id: originalQuestion.id,
            text: "Updated question?",
            category: .truthOrDare,
            difficulty: .hard
        )
        
        var finalQuestion: Question?
        questionRepository.updateQuestion(updatedQuestion)
            .sink(
                receiveCompletion: { _ in updateExpectation.fulfill() },
                receiveValue: { question in finalQuestion = question }
            )
            .store(in: &cancellables)
        
        wait(for: [updateExpectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(finalQuestion)
        XCTAssertEqual(finalQuestion?.text, "Updated question?")
        XCTAssertEqual(finalQuestion?.category, .truthOrDare)
        XCTAssertEqual(finalQuestion?.difficulty, .hard)
    }
    
    func testUpdateQuestion_NonExistentQuestion_ReturnsError() throws {
        // Given
        let nonExistentQuestion = Question(
            text: "Non-existent question?",
            category: .custom,
            difficulty: .easy
        )
        
        let expectation = XCTestExpectation(description: "Update non-existent question")
        var updateError: Error?
        
        // When
        questionRepository.updateQuestion(nonExistentQuestion)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        updateError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(updateError)
        XCTAssertTrue(updateError is RepositoryError)
    }
    
    // MARK: - Delete Question Tests
    
    func testDeleteQuestion_ExistingQuestion_Success() throws {
        // Given
        let question = Question(
            text: "Question to delete?",
            category: .custom,
            difficulty: .easy
        )
        
        let saveExpectation = XCTestExpectation(description: "Save question")
        let deleteExpectation = XCTestExpectation(description: "Delete question")
        let verifyExpectation = XCTestExpectation(description: "Verify deletion")
        
        // Save question first
        questionRepository.saveQuestion(question, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When - Delete question
        var deleteError: Error?
        questionRepository.deleteQuestion(by: question.id)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        deleteError = error
                    }
                    deleteExpectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [deleteExpectation], timeout: 1.0)
        
        // Then - Verify question is deleted
        var retrievedQuestion: Question?
        questionRepository.getQuestion(by: question.id)
            .sink(
                receiveCompletion: { _ in verifyExpectation.fulfill() },
                receiveValue: { question in retrievedQuestion = question }
            )
            .store(in: &cancellables)
        
        wait(for: [verifyExpectation], timeout: 1.0)
        
        XCTAssertNil(deleteError)
        XCTAssertNil(retrievedQuestion)
    }
    
    // MARK: - Filter Questions Tests
    
    func testGetQuestionsByCategory_WithMatchingQuestions_ReturnsFilteredQuestions() throws {
        // Given
        let truthQuestion = Question(text: "Truth question?", category: .truthOrDare, difficulty: .easy)
        let customQuestion = Question(text: "Custom question?", category: .custom, difficulty: .easy)
        
        let saveExpectation1 = XCTestExpectation(description: "Save truth question")
        let saveExpectation2 = XCTestExpectation(description: "Save custom question")
        let filterExpectation = XCTestExpectation(description: "Filter questions by category")
        
        // Save questions
        questionRepository.saveQuestion(truthQuestion, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation1.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        questionRepository.saveQuestion(customQuestion, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation2.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation1, saveExpectation2], timeout: 1.0)
        
        // When
        var filteredQuestions: [Question] = []
        questionRepository.getQuestions(by: .truthOrDare, in: testDeck.id)
            .sink(
                receiveCompletion: { _ in filterExpectation.fulfill() },
                receiveValue: { questions in filteredQuestions = questions }
            )
            .store(in: &cancellables)
        
        wait(for: [filterExpectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(filteredQuestions.count, 1)
        XCTAssertEqual(filteredQuestions.first?.text, "Truth question?")
        XCTAssertEqual(filteredQuestions.first?.category, .truthOrDare)
    }
    
    func testGetQuestionsByDifficulty_WithMatchingQuestions_ReturnsFilteredQuestions() throws {
        // Given
        let easyQuestion = Question(text: "Easy question?", category: .custom, difficulty: .easy)
        let hardQuestion = Question(text: "Hard question?", category: .custom, difficulty: .hard)
        
        let saveExpectation1 = XCTestExpectation(description: "Save easy question")
        let saveExpectation2 = XCTestExpectation(description: "Save hard question")
        let filterExpectation = XCTestExpectation(description: "Filter questions by difficulty")
        
        // Save questions
        questionRepository.saveQuestion(easyQuestion, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation1.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        questionRepository.saveQuestion(hardQuestion, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation2.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation1, saveExpectation2], timeout: 1.0)
        
        // When
        var filteredQuestions: [Question] = []
        questionRepository.getQuestions(by: .hard, in: testDeck.id)
            .sink(
                receiveCompletion: { _ in filterExpectation.fulfill() },
                receiveValue: { questions in filteredQuestions = questions }
            )
            .store(in: &cancellables)
        
        wait(for: [filterExpectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(filteredQuestions.count, 1)
        XCTAssertEqual(filteredQuestions.first?.text, "Hard question?")
        XCTAssertEqual(filteredQuestions.first?.difficulty, .hard)
    }
    
    // MARK: - Question Exists Tests
    
    func testQuestionExists_ExistingQuestion_ReturnsTrue() throws {
        // Given
        let question = Question(text: "Test question?", category: .custom, difficulty: .easy)
        
        let saveExpectation = XCTestExpectation(description: "Save question")
        let existsExpectation = XCTestExpectation(description: "Check question exists")
        
        // Save question first
        questionRepository.saveQuestion(question, to: testDeck.id)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When
        var questionExists = false
        questionRepository.questionExists(with: question.id)
            .sink(
                receiveCompletion: { _ in existsExpectation.fulfill() },
                receiveValue: { exists in questionExists = exists }
            )
            .store(in: &cancellables)
        
        wait(for: [existsExpectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(questionExists)
    }
    
    func testQuestionExists_NonExistentQuestion_ReturnsFalse() throws {
        // Given
        let nonExistentId = UUID()
        let expectation = XCTestExpectation(description: "Check non-existent question")
        
        // When
        var questionExists = true
        questionRepository.questionExists(with: nonExistentId)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { exists in questionExists = exists }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertFalse(questionExists)
    }
}