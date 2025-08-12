import XCTest
import Combine
@testable import PartyGameApp

class DeckServiceTests: XCTestCase {
    var deckService: DeckService!
    var mockDeckRepository: MockDeckRepository!
    var mockQuestionRepository: MockQuestionRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockDeckRepository = MockDeckRepository()
        mockQuestionRepository = MockQuestionRepository()
        deckService = DeckService(
            deckRepository: mockDeckRepository,
            questionRepository: mockQuestionRepository
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        deckService = nil
        mockQuestionRepository = nil
        mockDeckRepository = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Create Deck Tests
    
    func testCreateDeck_ValidDeck_Success() throws {
        // Given
        let deck = QuestionDeck(
            name: "Test Deck",
            description: "A test deck",
            questions: [
                Question(text: "Test question?", category: .custom, difficulty: .easy)
            ]
        )
        
        mockDeckRepository.saveResult = .success(deck)
        
        let expectation = XCTestExpectation(description: "Create deck")
        var createdDeck: QuestionDeck?
        var createError: Error?
        
        // When
        deckService.createDeck(deck)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        createError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { deck in
                    createdDeck = deck
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(createError)
        XCTAssertNotNil(createdDeck)
        XCTAssertEqual(createdDeck?.name, "Test Deck")
        XCTAssertTrue(mockDeckRepository.saveWasCalled)
    }
    
    func testCreateDeck_InvalidDeck_ReturnsError() throws {
        // Given
        let invalidDeck = QuestionDeck(
            name: "",  // Invalid: empty name
            description: "A test deck",
            questions: []
        )
        
        let expectation = XCTestExpectation(description: "Create invalid deck")
        var createError: Error?
        
        // When
        deckService.createDeck(invalidDeck)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        createError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(createError)
        XCTAssertTrue(createError is DeckServiceError)
        XCTAssertFalse(mockDeckRepository.saveWasCalled)
    }
    
    // MARK: - Update Deck Tests
    
    func testUpdateDeck_ValidDeck_Success() throws {
        // Given
        let deck = QuestionDeck(
            name: "Updated Deck",
            description: "An updated deck",
            questions: [
                Question(text: "Updated question?", category: .custom, difficulty: .medium)
            ]
        )
        
        mockDeckRepository.updateResult = .success(deck)
        
        let expectation = XCTestExpectation(description: "Update deck")
        var updatedDeck: QuestionDeck?
        var updateError: Error?
        
        // When
        deckService.updateDeck(deck)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        updateError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { deck in
                    updatedDeck = deck
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(updateError)
        XCTAssertNotNil(updatedDeck)
        XCTAssertEqual(updatedDeck?.name, "Updated Deck")
        XCTAssertTrue(mockDeckRepository.updateWasCalled)
    }
    
    // MARK: - Delete Deck Tests
    
    func testDeleteDeck_ExistingDeck_Success() throws {
        // Given
        let deckId = UUID()
        mockDeckRepository.deleteResult = .success(())
        
        let expectation = XCTestExpectation(description: "Delete deck")
        var deleteError: Error?
        
        // When
        deckService.deleteDeck(id: deckId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        deleteError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(deleteError)
        XCTAssertTrue(mockDeckRepository.deleteWasCalled)
        XCTAssertEqual(mockDeckRepository.deletedDeckId, deckId)
    }
    
    // MARK: - Add Question Tests
    
    func testAddQuestion_ValidQuestion_Success() throws {
        // Given
        let question = Question(
            text: "New question?",
            category: .custom,
            difficulty: .easy
        )
        let deckId = UUID()
        
        mockQuestionRepository.saveResult = .success(question)
        
        let expectation = XCTestExpectation(description: "Add question")
        var addedQuestion: Question?
        var addError: Error?
        
        // When
        deckService.addQuestion(question, to: deckId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        addError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { question in
                    addedQuestion = question
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(addError)
        XCTAssertNotNil(addedQuestion)
        XCTAssertEqual(addedQuestion?.text, "New question?")
        XCTAssertTrue(mockQuestionRepository.saveWasCalled)
    }
    
    func testAddQuestion_InvalidQuestion_ReturnsError() throws {
        // Given
        let invalidQuestion = Question(
            text: "",  // Invalid: empty text
            category: .custom,
            difficulty: .easy
        )
        let deckId = UUID()
        
        let expectation = XCTestExpectation(description: "Add invalid question")
        var addError: Error?
        
        // When
        deckService.addQuestion(invalidQuestion, to: deckId)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        addError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(addError)
        XCTAssertTrue(addError is DeckServiceError)
        XCTAssertFalse(mockQuestionRepository.saveWasCalled)
    }
    
    // MARK: - Seed Default Decks Tests
    
    func testSeedDefaultDecksIfNeeded_NoExistingDecks_SeedsDefaults() throws {
        // Given
        mockDeckRepository.getDefaultDecksResult = .success([])  // No existing default decks
        mockDeckRepository.saveResult = .success(QuestionDeck.defaultTruthOrDareDeck)
        
        let expectation = XCTestExpectation(description: "Seed default decks")
        var seedError: Error?
        
        // When
        deckService.seedDefaultDecksIfNeeded()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        seedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        // Then
        XCTAssertNil(seedError)
        XCTAssertTrue(mockDeckRepository.getDefaultDecksWasCalled)
        XCTAssertTrue(mockDeckRepository.saveWasCalled)
    }
    
    func testSeedDefaultDecksIfNeeded_ExistingDecks_DoesNotSeed() throws {
        // Given
        let existingDeck = QuestionDeck.defaultTruthOrDareDeck
        mockDeckRepository.getDefaultDecksResult = .success([existingDeck])
        
        let expectation = XCTestExpectation(description: "Check existing default decks")
        var seedError: Error?
        
        // When
        deckService.seedDefaultDecksIfNeeded()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        seedError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(seedError)
        XCTAssertTrue(mockDeckRepository.getDefaultDecksWasCalled)
        XCTAssertFalse(mockDeckRepository.saveWasCalled)  // Should not save if decks already exist
    }
}

// MARK: - Mock Repositories

class MockDeckRepository: DeckRepositoryProtocol {
    var getAllDecksResult: Result<[QuestionDeck], Error> = .success([])
    var getDeckResult: Result<QuestionDeck?, Error> = .success(nil)
    var getDefaultDecksResult: Result<[QuestionDeck], Error> = .success([])
    var getCustomDecksResult: Result<[QuestionDeck], Error> = .success([])
    var saveResult: Result<QuestionDeck, Error> = .success(QuestionDeck.sample)
    var updateResult: Result<QuestionDeck, Error> = .success(QuestionDeck.sample)
    var deleteResult: Result<Void, Error> = .success(())
    var deckExistsResult: Result<Bool, Error> = .success(false)
    
    var getAllDecksWasCalled = false
    var getDeckWasCalled = false
    var getDefaultDecksWasCalled = false
    var getCustomDecksWasCalled = false
    var saveWasCalled = false
    var updateWasCalled = false
    var deleteWasCalled = false
    var deckExistsWasCalled = false
    
    var savedDeck: QuestionDeck?
    var updatedDeck: QuestionDeck?
    var deletedDeckId: UUID?
    var queriedDeckId: UUID?
    
    func getAllDecks() -> AnyPublisher<[QuestionDeck], Error> {
        getAllDecksWasCalled = true
        return getAllDecksResult.publisher.eraseToAnyPublisher()
    }
    
    func getDeck(by id: UUID) -> AnyPublisher<QuestionDeck?, Error> {
        getDeckWasCalled = true
        queriedDeckId = id
        return getDeckResult.publisher.eraseToAnyPublisher()
    }
    
    func getDefaultDecks() -> AnyPublisher<[QuestionDeck], Error> {
        getDefaultDecksWasCalled = true
        return getDefaultDecksResult.publisher.eraseToAnyPublisher()
    }
    
    func getCustomDecks() -> AnyPublisher<[QuestionDeck], Error> {
        getCustomDecksWasCalled = true
        return getCustomDecksResult.publisher.eraseToAnyPublisher()
    }
    
    func saveDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error> {
        saveWasCalled = true
        savedDeck = deck
        return saveResult.publisher.eraseToAnyPublisher()
    }
    
    func updateDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error> {
        updateWasCalled = true
        updatedDeck = deck
        return updateResult.publisher.eraseToAnyPublisher()
    }
    
    func deleteDeck(by id: UUID) -> AnyPublisher<Void, Error> {
        deleteWasCalled = true
        deletedDeckId = id
        return deleteResult.publisher.eraseToAnyPublisher()
    }
    
    func deckExists(with id: UUID) -> AnyPublisher<Bool, Error> {
        deckExistsWasCalled = true
        queriedDeckId = id
        return deckExistsResult.publisher.eraseToAnyPublisher()
    }
}

class MockQuestionRepository: QuestionRepositoryProtocol {
    var getQuestionsResult: Result<[Question], Error> = .success([])
    var getQuestionResult: Result<Question?, Error> = .success(nil)
    var saveResult: Result<Question, Error> = .success(Question.sample)
    var updateResult: Result<Question, Error> = .success(Question.sample)
    var deleteResult: Result<Void, Error> = .success(())
    var questionExistsResult: Result<Bool, Error> = .success(false)
    
    var getQuestionsWasCalled = false
    var getQuestionWasCalled = false
    var saveWasCalled = false
    var updateWasCalled = false
    var deleteWasCalled = false
    var questionExistsWasCalled = false
    
    var savedQuestion: Question?
    var savedToDeckId: UUID?
    var updatedQuestion: Question?
    var deletedQuestionId: UUID?
    
    func getQuestions(for deckId: UUID) -> AnyPublisher<[Question], Error> {
        getQuestionsWasCalled = true
        return getQuestionsResult.publisher.eraseToAnyPublisher()
    }
    
    func getQuestion(by id: UUID) -> AnyPublisher<Question?, Error> {
        getQuestionWasCalled = true
        return getQuestionResult.publisher.eraseToAnyPublisher()
    }
    
    func saveQuestion(_ question: Question, to deckId: UUID) -> AnyPublisher<Question, Error> {
        saveWasCalled = true
        savedQuestion = question
        savedToDeckId = deckId
        return saveResult.publisher.eraseToAnyPublisher()
    }
    
    func updateQuestion(_ question: Question) -> AnyPublisher<Question, Error> {
        updateWasCalled = true
        updatedQuestion = question
        return updateResult.publisher.eraseToAnyPublisher()
    }
    
    func deleteQuestion(by id: UUID) -> AnyPublisher<Void, Error> {
        deleteWasCalled = true
        deletedQuestionId = id
        return deleteResult.publisher.eraseToAnyPublisher()
    }
    
    func getQuestions(by category: Question.QuestionCategory, in deckId: UUID) -> AnyPublisher<[Question], Error> {
        return getQuestionsResult.publisher.eraseToAnyPublisher()
    }
    
    func getQuestions(by difficulty: Question.DifficultyLevel, in deckId: UUID) -> AnyPublisher<[Question], Error> {
        return getQuestionsResult.publisher.eraseToAnyPublisher()
    }
    
    func questionExists(with id: UUID) -> AnyPublisher<Bool, Error> {
        questionExistsWasCalled = true
        return questionExistsResult.publisher.eraseToAnyPublisher()
    }
}

extension Result {
    var publisher: AnyPublisher<Success, Failure> {
        switch self {
        case .success(let value):
            return Just(value)
                .setFailureType(to: Failure.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}