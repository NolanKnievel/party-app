import XCTest
import CoreData
import Combine
@testable import PartyGameApp

class DeckRepositoryTests: XCTestCase {
    var repository: CoreDataDeckRepository!
    var persistenceController: PersistenceController!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        repository = CoreDataDeckRepository(persistenceController: persistenceController)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        repository = nil
        persistenceController = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Save Deck Tests
    
    func testSaveDeck_ValidDeck_Success() throws {
        // Given
        let deck = QuestionDeck(
            name: "Test Deck",
            description: "A test deck",
            questions: [
                Question(text: "Test question?", category: .custom, difficulty: .easy)
            ]
        )
        
        let expectation = XCTestExpectation(description: "Save deck")
        var savedDeck: QuestionDeck?
        var saveError: Error?
        
        // When
        repository.saveDeck(deck)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        saveError = error
                    }
                    expectation.fulfill()
                },
                receiveValue: { deck in
                    savedDeck = deck
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(saveError)
        XCTAssertNotNil(savedDeck)
        XCTAssertEqual(savedDeck?.name, "Test Deck")
        XCTAssertEqual(savedDeck?.description, "A test deck")
        XCTAssertEqual(savedDeck?.questions.count, 1)
    }
    
    func testSaveDeck_DuplicateId_UpdatesExisting() throws {
        // Given
        let originalDeck = QuestionDeck(
            name: "Original Deck",
            description: "Original description",
            questions: []
        )
        
        let updatedDeck = QuestionDeck(
            id: originalDeck.id,
            name: "Updated Deck",
            description: "Updated description",
            questions: []
        )
        
        let saveExpectation = XCTestExpectation(description: "Save original deck")
        let updateExpectation = XCTestExpectation(description: "Update deck")
        
        // When - Save original deck
        repository.saveDeck(originalDeck)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When - Update deck with same ID
        var finalDeck: QuestionDeck?
        repository.saveDeck(updatedDeck)
            .sink(
                receiveCompletion: { _ in updateExpectation.fulfill() },
                receiveValue: { deck in finalDeck = deck }
            )
            .store(in: &cancellables)
        
        wait(for: [updateExpectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(finalDeck)
        XCTAssertEqual(finalDeck?.name, "Updated Deck")
        XCTAssertEqual(finalDeck?.description, "Updated description")
    }
    
    // MARK: - Get Deck Tests
    
    func testGetDeck_ExistingId_ReturnsCorrectDeck() throws {
        // Given
        let deck = QuestionDeck(
            name: "Test Deck",
            description: "A test deck",
            questions: []
        )
        
        let saveExpectation = XCTestExpectation(description: "Save deck")
        let getExpectation = XCTestExpectation(description: "Get deck")
        
        // Save deck first
        repository.saveDeck(deck)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When
        var retrievedDeck: QuestionDeck?
        repository.getDeck(by: deck.id)
            .sink(
                receiveCompletion: { _ in getExpectation.fulfill() },
                receiveValue: { deck in retrievedDeck = deck }
            )
            .store(in: &cancellables)
        
        wait(for: [getExpectation], timeout: 1.0)
        
        // Then
        XCTAssertNotNil(retrievedDeck)
        XCTAssertEqual(retrievedDeck?.id, deck.id)
        XCTAssertEqual(retrievedDeck?.name, "Test Deck")
    }
    
    func testGetDeck_NonExistentId_ReturnsNil() throws {
        // Given
        let nonExistentId = UUID()
        let expectation = XCTestExpectation(description: "Get non-existent deck")
        
        // When
        var retrievedDeck: QuestionDeck?
        repository.getDeck(by: nonExistentId)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { deck in retrievedDeck = deck }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertNil(retrievedDeck)
    }
    
    // MARK: - Get All Decks Tests
    
    func testGetAllDecks_EmptyDatabase_ReturnsEmptyArray() throws {
        // Given
        let expectation = XCTestExpectation(description: "Get all decks")
        
        // When
        var allDecks: [QuestionDeck] = []
        repository.getAllDecks()
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { decks in allDecks = decks }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(allDecks.isEmpty)
    }
    
    func testGetAllDecks_WithDecks_ReturnsAllDecks() throws {
        // Given
        let deck1 = QuestionDeck(name: "Deck 1", description: "First deck", questions: [])
        let deck2 = QuestionDeck(name: "Deck 2", description: "Second deck", questions: [])
        
        let saveExpectation1 = XCTestExpectation(description: "Save deck 1")
        let saveExpectation2 = XCTestExpectation(description: "Save deck 2")
        let getAllExpectation = XCTestExpectation(description: "Get all decks")
        
        // Save decks
        repository.saveDeck(deck1)
            .sink(
                receiveCompletion: { _ in saveExpectation1.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        repository.saveDeck(deck2)
            .sink(
                receiveCompletion: { _ in saveExpectation2.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation1, saveExpectation2], timeout: 1.0)
        
        // When
        var allDecks: [QuestionDeck] = []
        repository.getAllDecks()
            .sink(
                receiveCompletion: { _ in getAllExpectation.fulfill() },
                receiveValue: { decks in allDecks = decks }
            )
            .store(in: &cancellables)
        
        wait(for: [getAllExpectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(allDecks.count, 2)
        XCTAssertTrue(allDecks.contains { $0.name == "Deck 1" })
        XCTAssertTrue(allDecks.contains { $0.name == "Deck 2" })
    }
    
    // MARK: - Delete Deck Tests
    
    func testDeleteDeck_ExistingDeck_Success() throws {
        // Given
        let deck = QuestionDeck(name: "Test Deck", description: "A test deck", questions: [])
        
        let saveExpectation = XCTestExpectation(description: "Save deck")
        let deleteExpectation = XCTestExpectation(description: "Delete deck")
        let verifyExpectation = XCTestExpectation(description: "Verify deletion")
        
        // Save deck first
        repository.saveDeck(deck)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When - Delete deck
        var deleteError: Error?
        repository.deleteDeck(by: deck.id)
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
        
        // Then - Verify deck is deleted
        var retrievedDeck: QuestionDeck?
        repository.getDeck(by: deck.id)
            .sink(
                receiveCompletion: { _ in verifyExpectation.fulfill() },
                receiveValue: { deck in retrievedDeck = deck }
            )
            .store(in: &cancellables)
        
        wait(for: [verifyExpectation], timeout: 1.0)
        
        XCTAssertNil(deleteError)
        XCTAssertNil(retrievedDeck)
    }
    
    func testDeleteDeck_NonExistentDeck_ReturnsError() throws {
        // Given
        let nonExistentId = UUID()
        let expectation = XCTestExpectation(description: "Delete non-existent deck")
        
        // When
        var deleteError: Error?
        repository.deleteDeck(by: nonExistentId)
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
        XCTAssertNotNil(deleteError)
        XCTAssertTrue(deleteError is RepositoryError)
    }
    
    // MARK: - Default Decks Tests
    
    func testGetDefaultDecks_WithDefaultDecks_ReturnsOnlyDefaults() throws {
        // Given
        let defaultDeck = QuestionDeck(
            name: "Default Deck",
            description: "A default deck",
            questions: [],
            isDefault: true
        )
        
        let customDeck = QuestionDeck(
            name: "Custom Deck",
            description: "A custom deck",
            questions: [],
            isDefault: false
        )
        
        let saveExpectation1 = XCTestExpectation(description: "Save default deck")
        let saveExpectation2 = XCTestExpectation(description: "Save custom deck")
        let getDefaultsExpectation = XCTestExpectation(description: "Get default decks")
        
        // Save both decks
        repository.saveDeck(defaultDeck)
            .sink(
                receiveCompletion: { _ in saveExpectation1.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        repository.saveDeck(customDeck)
            .sink(
                receiveCompletion: { _ in saveExpectation2.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation1, saveExpectation2], timeout: 1.0)
        
        // When
        var defaultDecks: [QuestionDeck] = []
        repository.getDefaultDecks()
            .sink(
                receiveCompletion: { _ in getDefaultsExpectation.fulfill() },
                receiveValue: { decks in defaultDecks = decks }
            )
            .store(in: &cancellables)
        
        wait(for: [getDefaultsExpectation], timeout: 1.0)
        
        // Then
        XCTAssertEqual(defaultDecks.count, 1)
        XCTAssertEqual(defaultDecks.first?.name, "Default Deck")
        XCTAssertTrue(defaultDecks.first?.isDefault == true)
    }
    
    // MARK: - Deck Exists Tests
    
    func testDeckExists_ExistingDeck_ReturnsTrue() throws {
        // Given
        let deck = QuestionDeck(name: "Test Deck", description: "A test deck", questions: [])
        
        let saveExpectation = XCTestExpectation(description: "Save deck")
        let existsExpectation = XCTestExpectation(description: "Check deck exists")
        
        // Save deck first
        repository.saveDeck(deck)
            .sink(
                receiveCompletion: { _ in saveExpectation.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        wait(for: [saveExpectation], timeout: 1.0)
        
        // When
        var deckExists = false
        repository.deckExists(with: deck.id)
            .sink(
                receiveCompletion: { _ in existsExpectation.fulfill() },
                receiveValue: { exists in deckExists = exists }
            )
            .store(in: &cancellables)
        
        wait(for: [existsExpectation], timeout: 1.0)
        
        // Then
        XCTAssertTrue(deckExists)
    }
    
    func testDeckExists_NonExistentDeck_ReturnsFalse() throws {
        // Given
        let nonExistentId = UUID()
        let expectation = XCTestExpectation(description: "Check non-existent deck")
        
        // When
        var deckExists = true
        repository.deckExists(with: nonExistentId)
            .sink(
                receiveCompletion: { _ in expectation.fulfill() },
                receiveValue: { exists in deckExists = exists }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        XCTAssertFalse(deckExists)
    }
}