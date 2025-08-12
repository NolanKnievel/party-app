import Foundation
import Combine

/// Service for managing question decks with business logic
class DeckService: ObservableObject {
    private let deckRepository: DeckRepositoryProtocol
    private let questionRepository: QuestionRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    @Published var decks: [QuestionDeck] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    init(
        deckRepository: DeckRepositoryProtocol = CoreDataDeckRepository(),
        questionRepository: QuestionRepositoryProtocol = CoreDataQuestionRepository()
    ) {
        self.deckRepository = deckRepository
        self.questionRepository = questionRepository
        loadDecks()
    }
    
    // MARK: - Public Methods
    
    /// Loads all decks from the repository
    func loadDecks() {
        isLoading = true
        error = nil
        
        deckRepository.getAllDecks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] decks in
                    self?.decks = decks
                }
            )
            .store(in: &cancellables)
    }
    
    /// Creates a new custom deck
    /// - Parameter deck: The deck to create
    func createDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error> {
        guard deck.isValid() else {
            return Fail(error: DeckServiceError.invalidDeck)
                .eraseToAnyPublisher()
        }
        
        return deckRepository.saveDeck(deck)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadDecks()
            })
            .eraseToAnyPublisher()
    }
    
    /// Updates an existing deck
    /// - Parameter deck: The deck to update
    func updateDeck(_ deck: QuestionDeck) -> AnyPublisher<QuestionDeck, Error> {
        guard deck.isValid() else {
            return Fail(error: DeckServiceError.invalidDeck)
                .eraseToAnyPublisher()
        }
        
        return deckRepository.updateDeck(deck)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadDecks()
            })
            .eraseToAnyPublisher()
    }
    
    /// Deletes a deck
    /// - Parameter deckId: The ID of the deck to delete
    func deleteDeck(id deckId: UUID) -> AnyPublisher<Void, Error> {
        return deckRepository.deleteDeck(by: deckId)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadDecks()
            })
            .eraseToAnyPublisher()
    }
    
    /// Gets a specific deck by ID
    /// - Parameter id: The deck ID
    /// - Returns: Publisher with the deck or nil if not found
    func getDeck(by id: UUID) -> AnyPublisher<QuestionDeck?, Error> {
        return deckRepository.getDeck(by: id)
    }
    
    /// Gets all default decks
    /// - Returns: Publisher with array of default decks
    func getDefaultDecks() -> AnyPublisher<[QuestionDeck], Error> {
        return deckRepository.getDefaultDecks()
    }
    
    /// Gets all custom decks
    /// - Returns: Publisher with array of custom decks
    func getCustomDecks() -> AnyPublisher<[QuestionDeck], Error> {
        return deckRepository.getCustomDecks()
    }
    
    /// Adds a question to a deck
    /// - Parameters:
    ///   - question: The question to add
    ///   - deckId: The ID of the deck to add the question to
    func addQuestion(_ question: Question, to deckId: UUID) -> AnyPublisher<Question, Error> {
        guard question.isValid() else {
            return Fail(error: DeckServiceError.invalidQuestion)
                .eraseToAnyPublisher()
        }
        
        return questionRepository.saveQuestion(question, to: deckId)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadDecks()
            })
            .eraseToAnyPublisher()
    }
    
    /// Updates a question in a deck
    /// - Parameter question: The question to update
    func updateQuestion(_ question: Question) -> AnyPublisher<Question, Error> {
        guard question.isValid() else {
            return Fail(error: DeckServiceError.invalidQuestion)
                .eraseToAnyPublisher()
        }
        
        return questionRepository.updateQuestion(question)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadDecks()
            })
            .eraseToAnyPublisher()
    }
    
    /// Removes a question from a deck
    /// - Parameter questionId: The ID of the question to remove
    func removeQuestion(id questionId: UUID) -> AnyPublisher<Void, Error> {
        return questionRepository.deleteQuestion(by: questionId)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadDecks()
            })
            .eraseToAnyPublisher()
    }
    
    /// Seeds the database with default decks if they don't exist
    func seedDefaultDecksIfNeeded() -> AnyPublisher<Void, Error> {
        return deckRepository.getDefaultDecks()
            .flatMap { [weak self] existingDecks -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: DeckServiceError.serviceUnavailable)
                        .eraseToAnyPublisher()
                }
                
                if existingDecks.isEmpty {
                    return self.seedDefaultDecks()
                } else {
                    return Just(())
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func seedDefaultDecks() -> AnyPublisher<Void, Error> {
        let defaultDecks = QuestionDeck.defaultDecks
        
        let publishers = defaultDecks.map { deck in
            deckRepository.saveDeck(deck)
                .map { _ in () }
                .eraseToAnyPublisher()
        }
        
        return Publishers.MergeMany(publishers)
            .collect()
            .map { _ in () }
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.loadDecks()
            })
            .eraseToAnyPublisher()
    }
}

// MARK: - Deck Service Errors

enum DeckServiceError: LocalizedError {
    case invalidDeck
    case invalidQuestion
    case serviceUnavailable
    case deckNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidDeck:
            return "The deck data is invalid"
        case .invalidQuestion:
            return "The question data is invalid"
        case .serviceUnavailable:
            return "The deck service is currently unavailable"
        case .deckNotFound:
            return "The requested deck was not found"
        }
    }
}