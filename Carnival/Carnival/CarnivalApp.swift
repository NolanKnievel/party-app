import SwiftUI
import CoreData
import CloudKit
import Combine

@main
struct CarnivalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    seedDefaultDataIfNeeded()
                }
        }
    }
    
    private func seedDefaultDataIfNeeded() {
        let context = persistenceController.container.viewContext
        
        // Check if default decks already exist
        let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let existingDecks = try context.fetch(request)
            if existingDecks.isEmpty {
                createDefaultDecks(context: context)
            }
        } catch {
            print("Failed to check for existing default decks: \(error)")
        }
    }
    
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
            print("Default decks created successfully")
        } catch {
            print("Failed to save default decks: \(error)")
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
        container = NSPersistentCloudKitContainer(name: "Carnival")
        
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

// Core Data entities are automatically generated from the .xcdatamodeld file