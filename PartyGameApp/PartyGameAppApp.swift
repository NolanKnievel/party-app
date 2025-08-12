import SwiftUI
import CoreData

@main
struct PartyGameAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// MARK: - Core Data Stack
class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleDeck = DeckEntity(context: viewContext)
        sampleDeck.id = UUID()
        sampleDeck.name = "Truth or Dare"
        sampleDeck.description = "Classic party game questions"
        sampleDeck.isDefault = true
        sampleDeck.isPublic = false
        sampleDeck.createdDate = Date()
        
        let sampleQuestion = QuestionEntity(context: viewContext)
        sampleQuestion.id = UUID()
        sampleQuestion.text = "What's your most embarrassing moment?"
        sampleQuestion.category = "Truth"
        sampleQuestion.difficulty = "medium"
        sampleQuestion.deck = sampleDeck
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable CloudKit integration
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
// MAR
K: - Core Data Entities

@objc(DeckEntity)
public class DeckEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var deckDescription: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var isPublic: Bool
    @NSManaged public var downloadCount: Int32
    @NSManaged public var rating: Double
    @NSManaged public var createdDate: Date?
    @NSManaged public var lastModified: Date?
    @NSManaged public var questions: NSSet?
}

// MARK: Generated accessors for questions
extension DeckEntity {
    @objc(addQuestionsObject:)
    @NSManaged public func addToQuestions(_ value: QuestionEntity)

    @objc(removeQuestionsObject:)
    @NSManaged public func removeFromQuestions(_ value: QuestionEntity)

    @objc(addQuestions:)
    @NSManaged public func addToQuestions(_ values: NSSet)

    @objc(removeQuestions:)
    @NSManaged public func removeFromQuestions(_ values: NSSet)
}

extension DeckEntity: Identifiable {
    /// Converts Core Data entity to domain model
    func toQuestionDeck() -> QuestionDeck? {
        guard let id = id,
              let name = name,
              let description = deckDescription,
              let createdDate = createdDate,
              let lastModified = lastModified else {
            return nil
        }
        
        let questionEntities = questions?.allObjects as? [QuestionEntity] ?? []
        let questions = questionEntities.compactMap { $0.toQuestion() }
        
        return QuestionDeck(
            id: id,
            name: name,
            description: description,
            questions: questions,
            isDefault: isDefault,
            isPublic: isPublic,
            createdBy: nil,
            downloadCount: Int(downloadCount),
            rating: rating,
            createdDate: createdDate,
            lastModified: lastModified
        )
    }
    
    /// Updates entity from domain model
    func update(from deck: QuestionDeck, context: NSManagedObjectContext) {
        self.id = deck.id
        self.name = deck.name
        self.deckDescription = deck.description
        self.isDefault = deck.isDefault
        self.isPublic = deck.isPublic
        self.downloadCount = Int32(deck.downloadCount)
        self.rating = deck.rating
        self.createdDate = deck.createdDate
        self.lastModified = deck.lastModified
        
        // Update questions
        if let existingQuestions = questions {
            removeFromQuestions(existingQuestions)
        }
        
        for question in deck.questions {
            let questionEntity = QuestionEntity(context: context)
            questionEntity.update(from: question)
            addToQuestions(questionEntity)
        }
    }
}

@objc(QuestionEntity)
public class QuestionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var category: String?
    @NSManaged public var difficulty: String?
    @NSManaged public var deck: DeckEntity?
}

extension QuestionEntity: Identifiable {
    /// Converts Core Data entity to domain model
    func toQuestion() -> Question? {
        guard let id = id,
              let text = text,
              let categoryString = category,
              let difficultyString = difficulty,
              let questionCategory = Question.QuestionCategory(rawValue: categoryString),
              let questionDifficulty = Question.DifficultyLevel(rawValue: difficultyString) else {
            return nil
        }
        
        return Question(
            id: id,
            text: text,
            category: questionCategory,
            difficulty: questionDifficulty
        )
    }
    
    /// Updates entity from domain model
    func update(from question: Question) {
        self.id = question.id
        self.text = question.text
        self.category = question.category.rawValue
        self.difficulty = question.difficulty.rawValue
    }
}