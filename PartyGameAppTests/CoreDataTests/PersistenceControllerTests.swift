import XCTest
import CoreData
@testable import PartyGameApp

class PersistenceControllerTests: XCTestCase {
    var persistenceController: PersistenceController!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        persistenceController = PersistenceController(inMemory: true)
    }
    
    override func tearDownWithError() throws {
        persistenceController = nil
        try super.tearDownWithError()
    }
    
    func testPersistenceControllerInitialization() throws {
        // Given/When
        let controller = PersistenceController(inMemory: true)
        
        // Then
        XCTAssertNotNil(controller.container)
        XCTAssertNotNil(controller.container.viewContext)
    }
    
    func testCreateDeckEntity() throws {
        // Given
        let context = persistenceController.container.viewContext
        
        // When
        let deckEntity = DeckEntity(context: context)
        deckEntity.id = UUID()
        deckEntity.name = "Test Deck"
        deckEntity.deckDescription = "A test deck"
        deckEntity.isDefault = false
        deckEntity.isPublic = false
        deckEntity.downloadCount = 0
        deckEntity.rating = 0.0
        deckEntity.createdDate = Date()
        deckEntity.lastModified = Date()
        
        // Then
        XCTAssertNotNil(deckEntity.id)
        XCTAssertEqual(deckEntity.name, "Test Deck")
        XCTAssertEqual(deckEntity.deckDescription, "A test deck")
        XCTAssertFalse(deckEntity.isDefault)
        XCTAssertFalse(deckEntity.isPublic)
    }
    
    func testCreateQuestionEntity() throws {
        // Given
        let context = persistenceController.container.viewContext
        
        // When
        let questionEntity = QuestionEntity(context: context)
        questionEntity.id = UUID()
        questionEntity.text = "Test question?"
        questionEntity.category = "custom"
        questionEntity.difficulty = "easy"
        
        // Then
        XCTAssertNotNil(questionEntity.id)
        XCTAssertEqual(questionEntity.text, "Test question?")
        XCTAssertEqual(questionEntity.category, "custom")
        XCTAssertEqual(questionEntity.difficulty, "easy")
    }
    
    func testSaveContext() throws {
        // Given
        let context = persistenceController.container.viewContext
        let deckEntity = DeckEntity(context: context)
        deckEntity.id = UUID()
        deckEntity.name = "Test Deck"
        deckEntity.deckDescription = "A test deck"
        deckEntity.isDefault = false
        deckEntity.isPublic = false
        deckEntity.downloadCount = 0
        deckEntity.rating = 0.0
        deckEntity.createdDate = Date()
        deckEntity.lastModified = Date()
        
        // When
        XCTAssertNoThrow(try context.save())
        
        // Then
        let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Test Deck")
    }
    
    func testDeckEntityToQuestionDeckConversion() throws {
        // Given
        let context = persistenceController.container.viewContext
        let deckEntity = DeckEntity(context: context)
        deckEntity.id = UUID()
        deckEntity.name = "Test Deck"
        deckEntity.deckDescription = "A test deck"
        deckEntity.isDefault = false
        deckEntity.isPublic = false
        deckEntity.downloadCount = 5
        deckEntity.rating = 4.5
        deckEntity.createdDate = Date()
        deckEntity.lastModified = Date()
        
        // When
        let questionDeck = deckEntity.toQuestionDeck()
        
        // Then
        XCTAssertNotNil(questionDeck)
        XCTAssertEqual(questionDeck?.name, "Test Deck")
        XCTAssertEqual(questionDeck?.description, "A test deck")
        XCTAssertFalse(questionDeck?.isDefault ?? true)
        XCTAssertFalse(questionDeck?.isPublic ?? true)
        XCTAssertEqual(questionDeck?.downloadCount, 5)
        XCTAssertEqual(questionDeck?.rating, 4.5)
    }
    
    func testQuestionEntityToQuestionConversion() throws {
        // Given
        let context = persistenceController.container.viewContext
        let questionEntity = QuestionEntity(context: context)
        questionEntity.id = UUID()
        questionEntity.text = "Test question?"
        questionEntity.category = "truthOrDare"
        questionEntity.difficulty = "medium"
        
        // When
        let question = questionEntity.toQuestion()
        
        // Then
        XCTAssertNotNil(question)
        XCTAssertEqual(question?.text, "Test question?")
        XCTAssertEqual(question?.category, .truthOrDare)
        XCTAssertEqual(question?.difficulty, .medium)
    }
}