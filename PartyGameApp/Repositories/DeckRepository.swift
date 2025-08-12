import Foundation
import CoreData
import Combine

/// Protocol defining deck repository operations
protocol DeckRepositoryProtocol {
    func getAllDecks() -> AnyPublisher<[QuestionDeck], Error>
    func getDeck(by id: UUID) -> AnyPublisher<QuestionDeck?, Error>
    func getDefaultDecks() -> AnyPublisher<[QuestionDeck], Error>
    func getCustomDecks() -> AnyPublisher<[QuestionDeck], Error>
    func saveDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error>
    func updateDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error>
    func deleteDeck(by id: UUID) -> AnyPublisher<Void, Error>
    func deckExists(with id: UUID) -> AnyPublisher<Bool, Error>
}

/// Core Data implementation of deck repository
class CoreDataDeckRepository: DeckRepositoryProtocol {
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
    }
    
    func getAllDecks() -> AnyPublisher<[QuestionDeck], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \DeckEntity.isDefault, ascending: false),
                NSSortDescriptor(keyPath: \DeckEntity.name, ascending: true)
            ]
            
            do {
                let entities = try self.context.fetch(request)
                let decks = entities.compactMap { $0.toQuestionDeck() }
                promise(.success(decks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getDeck(by id: UUID) -> AnyPublisher<QuestionDeck?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let entities = try self.context.fetch(request)
                let deck = entities.first?.toQuestionDeck()
                promise(.success(deck))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getDefaultDecks() -> AnyPublisher<[QuestionDeck], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isDefault == YES")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \DeckEntity.name, ascending: true)]
            
            do {
                let entities = try self.context.fetch(request)
                let decks = entities.compactMap { $0.toQuestionDeck() }
                promise(.success(decks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCustomDecks() -> AnyPublisher<[QuestionDeck], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isDefault == NO")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \DeckEntity.lastModified, ascending: false)]
            
            do {
                let entities = try self.context.fetch(request)
                let decks = entities.compactMap { $0.toQuestionDeck() }
                promise(.success(decks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            // Check if deck already exists
            let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", deck.id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let existingEntities = try self.context.fetch(request)
                
                if let existingEntity = existingEntities.first {
                    // Update existing deck
                    existingEntity.update(from: deck, context: self.context)
                } else {
                    // Create new deck
                    let entity = DeckEntity(context: self.context)
                    entity.update(from: deck, context: self.context)
                }
                
                try self.context.save()
                promise(.success(deck))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error> {
        return saveDeck(deck) // Same implementation for Core Data
    }
    
    func deleteDeck(by id: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let entities = try self.context.fetch(request)
                
                if let entity = entities.first {
                    self.context.delete(entity)
                    try self.context.save()
                    promise(.success(()))
                } else {
                    promise(.failure(RepositoryError.entityNotFound))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deckExists(with id: UUID) -> AnyPublisher<Bool, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let count = try self.context.count(for: request)
                promise(.success(count > 0))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

/// Repository errors
enum RepositoryError: LocalizedError {
    case contextUnavailable
    case entityNotFound
    case invalidData
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .contextUnavailable:
            return "Database context is unavailable"
        case .entityNotFound:
            return "The requested entity was not found"
        case .invalidData:
            return "The provided data is invalid"
        case .saveFailed:
            return "Failed to save data to the database"
        }
    }
}