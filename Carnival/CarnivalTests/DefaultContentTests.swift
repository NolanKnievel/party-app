import XCTest
import CoreData
@testable import Carnival

final class DefaultContentTests: XCTestCase {
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        persistenceController = nil
        context = nil
        super.tearDown()
    }
    
    func testDefaultDecksCreation() {
        // Create default decks using the same logic as the app
        createDefaultDecks(context: context)
        
        // Fetch default decks
        let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let decks = try context.fetch(request)
            
            // Verify we have 2 default decks
            XCTAssertEqual(decks.count, 2, "Should have 2 default decks")
            
            let deckNames = decks.compactMap { $0.name }.sorted()
            XCTAssertEqual(deckNames, ["Truth or Dare", "Would You Rather"], "Should have correct deck names")
            
            // Verify Truth or Dare deck
            if let truthOrDareDeck = decks.first(where: { $0.name == "Truth or Dare" }) {
                XCTAssertEqual(truthOrDareDeck.deckDescription, "Classic party game with truth questions and fun dares")
                XCTAssertTrue(truthOrDareDeck.isDefault)
                XCTAssertFalse(truthOrDareDeck.isPublic)
                XCTAssertEqual(truthOrDareDeck.questions?.count, 20, "Truth or Dare deck should have 20 questions")
            } else {
                XCTFail("Truth or Dare deck not found")
            }
            
            // Verify Would You Rather deck
            if let wouldYouRatherDeck = decks.first(where: { $0.name == "Would You Rather" }) {
                XCTAssertEqual(wouldYouRatherDeck.deckDescription, "Thought-provoking choices that spark great conversations")
                XCTAssertTrue(wouldYouRatherDeck.isDefault)
                XCTAssertFalse(wouldYouRatherDeck.isPublic)
                XCTAssertEqual(wouldYouRatherDeck.questions?.count, 20, "Would You Rather deck should have 20 questions")
            } else {
                XCTFail("Would You Rather deck not found")
            }
            
        } catch {
            XCTFail("Failed to fetch default decks: \(error)")
        }
    }
    
    func testDefaultQuestionsContent() {
        // Create default decks
        createDefaultDecks(context: context)
        
        // Fetch all questions
        let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
        
        do {
            let questions = try context.fetch(request)
            
            // Verify we have 40 questions total (20 per deck)
            XCTAssertEqual(questions.count, 40, "Should have 40 questions total")
            
            // Verify Truth or Dare questions
            let truthOrDareQuestions = questions.filter { $0.category == "truthOrDare" }
            XCTAssertEqual(truthOrDareQuestions.count, 20, "Should have 20 Truth or Dare questions")
            
            // Verify Would You Rather questions
            let wouldYouRatherQuestions = questions.filter { $0.category == "wouldYouRather" }
            XCTAssertEqual(wouldYouRatherQuestions.count, 20, "Should have 20 Would You Rather questions")
            
            // Verify all questions have valid content
            for question in questions {
                XCTAssertFalse(question.text?.isEmpty ?? true, "Question text should not be empty")
                XCTAssertFalse(question.category?.isEmpty ?? true, "Question category should not be empty")
                XCTAssertFalse(question.difficulty?.isEmpty ?? true, "Question difficulty should not be empty")
                XCTAssertNotNil(question.deck, "Question should be associated with a deck")
            }
            
            // Verify difficulty levels are valid
            let validDifficulties = ["easy", "medium", "hard"]
            for question in questions {
                if let difficulty = question.difficulty {
                    XCTAssertTrue(validDifficulties.contains(difficulty), 
                                 "Question difficulty '\(difficulty)' should be valid")
                }
            }
            
        } catch {
            XCTFail("Failed to fetch questions: \(error)")
        }
    }
    
    // Helper method - same as in the main app
    private func createDefaultDecks(context: NSManagedObjectContext) {
        // Create Truth or Dare deck
        let truthOrDareDeck = DeckEntity(context: context)
        truthOrDareDeck.id = UUID()
        truthOrDareDeck.name = "Truth or Dare"
        truthOrDareDeck.deckDescription = "Classic party game with truth questions and fun dares"
        truthOrDareDeck.isDefault = true
        truthOrDareDeck.isPublic = false
        truthOrDareDeck.downloadCount = 0
        truthOrDareDeck.rating = 0.0
        truthOrDareDeck.createdDate = Date()
        truthOrDareDeck.lastModified = Date()
        
        // Add Truth or Dare questions
        let truthOrDareQuestions = [
            // Truth Questions
            ("What's your most embarrassing moment?", "truthOrDare", "medium"),
            ("What's the weirdest thing you've ever eaten?", "truthOrDare", "easy"),
            ("What's your biggest fear?", "truthOrDare", "medium"),
            ("What's the most trouble you've ever been in?", "truthOrDare", "hard"),
            ("What's your most unusual talent?", "truthOrDare", "easy"),
            ("What's the worst lie you've ever told?", "truthOrDare", "hard"),
            ("What's your biggest secret?", "truthOrDare", "hard"),
            ("Who was your first crush?", "truthOrDare", "medium"),
            ("What's the most childish thing you still do?", "truthOrDare", "easy"),
            ("What's your guilty pleasure?", "truthOrDare", "medium"),
            
            // Dare Questions
            ("Sing your favorite song out loud", "truthOrDare", "easy"),
            ("Do your best impression of someone in the room", "truthOrDare", "medium"),
            ("Dance for 30 seconds without music", "truthOrDare", "easy"),
            ("Tell a joke that makes everyone laugh", "truthOrDare", "medium"),
            ("Act out your favorite movie scene", "truthOrDare", "medium"),
            ("Do 10 push-ups", "truthOrDare", "easy"),
            ("Speak in an accent for the next 3 rounds", "truthOrDare", "medium"),
            ("Let someone else style your hair", "truthOrDare", "hard"),
            ("Call a random contact and sing Happy Birthday", "truthOrDare", "hard"),
            ("Do your best runway walk across the room", "truthOrDare", "easy")
        ]
        
        for (text, category, difficulty) in truthOrDareQuestions {
            let question = QuestionEntity(context: context)
            question.id = UUID()
            question.text = text
            question.category = category
            question.difficulty = difficulty
            question.deck = truthOrDareDeck
        }
        
        // Create Would You Rather deck
        let wouldYouRatherDeck = DeckEntity(context: context)
        wouldYouRatherDeck.id = UUID()
        wouldYouRatherDeck.name = "Would You Rather"
        wouldYouRatherDeck.deckDescription = "Thought-provoking choices that spark great conversations"
        wouldYouRatherDeck.isDefault = true
        wouldYouRatherDeck.isPublic = false
        wouldYouRatherDeck.downloadCount = 0
        wouldYouRatherDeck.rating = 0.0
        wouldYouRatherDeck.createdDate = Date()
        wouldYouRatherDeck.lastModified = Date()
        
        // Add Would You Rather questions
        let wouldYouRatherQuestions = [
            ("Would you rather have the ability to fly or be invisible?", "wouldYouRather", "easy"),
            ("Would you rather live in the past or the future?", "wouldYouRather", "medium"),
            ("Would you rather be able to read minds or predict the future?", "wouldYouRather", "medium"),
            ("Would you rather have unlimited money or unlimited time?", "wouldYouRather", "hard"),
            ("Would you rather be famous or anonymous?", "wouldYouRather", "medium"),
            ("Would you rather live underwater or in space?", "wouldYouRather", "easy"),
            ("Would you rather have super strength or super speed?", "wouldYouRather", "easy"),
            ("Would you rather never have to sleep or never have to eat?", "wouldYouRather", "medium"),
            ("Would you rather be able to speak all languages or play all instruments?", "wouldYouRather", "medium"),
            ("Would you rather have the power to heal others or bring back the dead?", "wouldYouRather", "hard"),
            ("Would you rather always be 10 minutes late or 20 minutes early?", "wouldYouRather", "easy"),
            ("Would you rather have a rewind button or a pause button for your life?", "wouldYouRather", "hard"),
            ("Would you rather be able to teleport anywhere or be able to time travel?", "wouldYouRather", "medium"),
            ("Would you rather have perfect memory or perfect intuition?", "wouldYouRather", "hard"),
            ("Would you rather be the smartest person in the world or the most attractive?", "wouldYouRather", "medium"),
            ("Would you rather live without music or without movies?", "wouldYouRather", "easy"),
            ("Would you rather have a personal chef or a personal trainer?", "wouldYouRather", "easy"),
            ("Would you rather be able to control fire or water?", "wouldYouRather", "easy"),
            ("Would you rather know when you're going to die or how you're going to die?", "wouldYouRather", "hard"),
            ("Would you rather have a photographic memory or be able to forget anything you want?", "wouldYouRather", "medium")
        ]
        
        for (text, category, difficulty) in wouldYouRatherQuestions {
            let question = QuestionEntity(context: context)
            question.id = UUID()
            question.text = text
            question.category = category
            question.difficulty = difficulty
            question.deck = wouldYouRatherDeck
        }
        
        // Save the context
        do {
            try context.save()
        } catch {
            print("Failed to save default decks: \(error)")
        }
    }
}