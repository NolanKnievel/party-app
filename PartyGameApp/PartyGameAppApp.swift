import SwiftUI
import CoreData
import CloudKit

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
class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleDeck = DeckEntity(context: viewContext)
        sampleDeck.id = UUID()
        sampleDeck.name = "Truth or Dare"
        sampleDeck.deckDescription = "Classic party game questions"
        sampleDeck.isDefault = true
        sampleDeck.isPublic = false
        sampleDeck.createdDate = Date()
        sampleDeck.lastModified = Date()
        
        let sampleQuestion = QuestionEntity(context: viewContext)
        sampleQuestion.id = UUID()
        sampleQuestion.text = "What's your most embarrassing moment?"
        sampleQuestion.category = "truthOrDare"
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

    let container: NSPersistentCloudKitContainer
    
    @Published var cloudKitStatus: CloudKitStatus = .notStarted
    
    enum CloudKitStatus {
        case notStarted
        case inProgress
        case succeeded
        case failed(Error)
    }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "DataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure CloudKit integration
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("Failed to retrieve a persistent store description.")
            }
            
            // Enable CloudKit
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Configure CloudKit container - remove this line for now as it's not needed for basic CloudKit setup
        }
        
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                print("Core Data failed to load: \(error.localizedDescription)")
                self?.cloudKitStatus = .failed(error)
            } else {
                print("Core Data loaded successfully")
                self?.cloudKitStatus = .succeeded
            }
        }
        
        // Configure the view context
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Watch for CloudKit sync notifications
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Saves the view context if there are changes
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
    
    /// Creates a background context for performing operations off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
// MARK: - Core Data Entities

@objc(DeckEntity)
public class DeckEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var deckDescription: String
    @NSManaged public var isDefault: Bool
    @NSManaged public var isPublic: Bool
    @NSManaged public var downloadCount: Int32
    @NSManaged public var rating: Double
    @NSManaged public var createdDate: Date
    @NSManaged public var lastModified: Date
    @NSManaged public var questions: NSSet?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeckEntity> {
        return NSFetchRequest<DeckEntity>(entityName: "DeckEntity")
    }
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
        let questionEntities = questions?.allObjects as? [QuestionEntity] ?? []
        let questions = questionEntities.compactMap { $0.toQuestion() }
        
        return QuestionDeck(
            id: id,
            name: name,
            description: deckDescription,
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
    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var category: String
    @NSManaged public var difficulty: String
    @NSManaged public var deck: DeckEntity?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuestionEntity> {
        return NSFetchRequest<QuestionEntity>(entityName: "QuestionEntity")
    }
}

extension QuestionEntity: Identifiable {
    /// Converts Core Data entity to domain model
    func toQuestion() -> Question? {
        guard let questionCategory = Question.QuestionCategory(rawValue: category),
              let questionDifficulty = Question.DifficultyLevel(rawValue: difficulty) else {
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