import Foundation
import CoreData
import Combine

/// Protocol defining question repository operations
protocol QuestionRepositoryProtocol {
    func getQuestions(for deckId: UUID) -> AnyPublisher<[Question], Error>
    func getQuestion(by id: UUID) -> AnyPublisher<Question?, Error>
    func saveQuestion(_ question: Question, to deckId: UUID) -> AnyPublisher<Question, Error>
    func updateQuestion(_ question: Question) -> AnyPublisher<Question, Error>
    func deleteQuestion(by id: UUID) -> AnyPublisher<Void, Error>
    func getQuestions(by category: Question.QuestionCategory, in deckId: UUID) -> AnyPublisher<[Question], Error>
    func getQuestions(by difficulty: Question.DifficultyLevel, in deckId: UUID) -> AnyPublisher<[Question], Error>
    func questionExists(with id: UUID) -> AnyPublisher<Bool, Error>
}

/// Core Data implementation of question repository
class CoreDataQuestionRepository: QuestionRepositoryProtocol {
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
    }
    
    func getQuestions(for deckId: UUID) -> AnyPublisher<[Question], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "deck.id == %@", deckId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \QuestionEntity.text, ascending: true)]
            
            do {
                let entities = try self.context.fetch(request)
                let questions = entities.compactMap { $0.toQuestion() }
                promise(.success(questions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getQuestion(by id: UUID) -> AnyPublisher<Question?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let entities = try self.context.fetch(request)
                let question = entities.first?.toQuestion()
                promise(.success(question))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveQuestion(_ question: Question, to deckId: UUID) -> AnyPublisher<Question, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            // First, find the deck
            let deckRequest: NSFetchRequest<DeckEntity> = DeckEntity.fetchRequest()
            deckRequest.predicate = NSPredicate(format: "id == %@", deckId as CVarArg)
            deckRequest.fetchLimit = 1
            
            do {
                let deckEntities = try self.context.fetch(deckRequest)
                guard let deckEntity = deckEntities.first else {
                    promise(.failure(RepositoryError.entityNotFound))
                    return
                }
                
                // Check if question already exists
                let questionRequest: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
                questionRequest.predicate = NSPredicate(format: "id == %@", question.id as CVarArg)
                questionRequest.fetchLimit = 1
                
                let existingQuestions = try self.context.fetch(questionRequest)
                
                let questionEntity: QuestionEntity
                if let existingEntity = existingQuestions.first {
                    questionEntity = existingEntity
                } else {
                    questionEntity = QuestionEntity(context: self.context)
                }
                
                questionEntity.update(from: question)
                questionEntity.deck = deckEntity
                
                // Update deck's last modified date
                deckEntity.lastModified = Date()
                
                try self.context.save()
                promise(.success(question))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateQuestion(_ question: Question) -> AnyPublisher<Question, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", question.id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let entities = try self.context.fetch(request)
                
                if let entity = entities.first {
                    entity.update(from: question)
                    
                    // Update deck's last modified date
                    entity.deck?.lastModified = Date()
                    
                    try self.context.save()
                    promise(.success(question))
                } else {
                    promise(.failure(RepositoryError.entityNotFound))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteQuestion(by id: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let entities = try self.context.fetch(request)
                
                if let entity = entities.first {
                    // Update deck's last modified date before deleting question
                    entity.deck?.lastModified = Date()
                    
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
    
    func getQuestions(by category: Question.QuestionCategory, in deckId: UUID) -> AnyPublisher<[Question], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "deck.id == %@ AND category == %@",
                deckId as CVarArg,
                category.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \QuestionEntity.text, ascending: true)]
            
            do {
                let entities = try self.context.fetch(request)
                let questions = entities.compactMap { $0.toQuestion() }
                promise(.success(questions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getQuestions(by difficulty: Question.DifficultyLevel, in deckId: UUID) -> AnyPublisher<[Question], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "deck.id == %@ AND difficulty == %@",
                deckId as CVarArg,
                difficulty.rawValue
            )
            request.sortDescriptors = [NSSortDescriptor(keyPath: \QuestionEntity.text, ascending: true)]
            
            do {
                let entities = try self.context.fetch(request)
                let questions = entities.compactMap { $0.toQuestion() }
                promise(.success(questions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func questionExists(with id: UUID) -> AnyPublisher<Bool, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<QuestionEntity> = QuestionEntity.fetchRequest()
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