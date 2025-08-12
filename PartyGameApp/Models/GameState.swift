import Foundation

/// Represents the current state of a party game session
struct GameState: Codable, Equatable {
    var players: [Player]
    var currentDeck: QuestionDeck
    var currentPlayer: Player?
    var usedQuestions: Set<UUID>
    var gamePhase: GamePhase
    var sessionId: UUID
    var startTime: Date?
    var lastActivityTime: Date
    
    /// The different phases of the game
    enum GamePhase: String, Codable, CaseIterable {
        case setup = "setup"
        case spinning = "spinning"
        case questioning = "questioning"
        case paused = "paused"
        case ended = "ended"
        
        var displayName: String {
            switch self {
            case .setup: return "Setup"
            case .spinning: return "Spinning"
            case .questioning: return "Question"
            case .paused: return "Paused"
            case .ended: return "Ended"
            }
        }
        
        var isActive: Bool {
            return self != .ended && self != .paused
        }
    }
    
    /// Creates a new game state
    /// - Parameters:
    ///   - players: Array of players in the game
    ///   - deck: The question deck to use
    ///   - phase: Initial game phase (defaults to setup)
    init(players: [Player], deck: QuestionDeck, phase: GamePhase = .setup) {
        self.players = players
        self.currentDeck = deck
        self.currentPlayer = nil
        self.usedQuestions = Set<UUID>()
        self.gamePhase = phase
        self.sessionId = UUID()
        self.startTime = nil
        self.lastActivityTime = Date()
    }
    
    /// Creates a game state with all properties specified (useful for testing)
    /// - Parameters:
    ///   - players: Array of players in the game
    ///   - currentDeck: The question deck to use
    ///   - currentPlayer: The currently selected player
    ///   - usedQuestions: Set of question IDs that have been used
    ///   - gamePhase: Current phase of the game
    ///   - sessionId: Unique identifier for this game session
    ///   - startTime: When the game started
    ///   - lastActivityTime: Last time there was activity in the game
    init(
        players: [Player],
        currentDeck: QuestionDeck,
        currentPlayer: Player? = nil,
        usedQuestions: Set<UUID> = Set<UUID>(),
        gamePhase: GamePhase = .setup,
        sessionId: UUID = UUID(),
        startTime: Date? = nil,
        lastActivityTime: Date = Date()
    ) {
        self.players = players
        self.currentDeck = currentDeck
        self.currentPlayer = currentPlayer
        self.usedQuestions = usedQuestions
        self.gamePhase = gamePhase
        self.sessionId = sessionId
        self.startTime = startTime
        self.lastActivityTime = lastActivityTime
    }
    
    // MARK: - Validation
    
    /// Validates that the game state is valid
    /// - Returns: True if the game state is valid, false otherwise
    func isValid() -> Bool {
        return players.count >= 2 &&
               players.allSatisfy { $0.isValid() } &&
               currentDeck.isValid() &&
               (currentPlayer == nil || players.contains(currentPlayer!))
    }
    
    /// Checks if the game can be started
    /// - Returns: True if the game can be started, false otherwise
    func canStart() -> Bool {
        return players.count >= 2 && 
               !currentDeck.questions.isEmpty &&
               gamePhase == .setup
    }
    
    /// Checks if there are unused questions available
    /// - Returns: True if there are unused questions, false otherwise
    func hasUnusedQuestions() -> Bool {
        return usedQuestions.count < currentDeck.questions.count
    }
    
    // MARK: - Game Management
    
    /// Starts the game
    /// - Returns: A new game state with the game started
    func startingGame() -> GameState {
        guard canStart() else { return self }
        
        var updatedState = self
        updatedState.gamePhase = .spinning
        updatedState.startTime = Date()
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Pauses the game
    /// - Returns: A new game state with the game paused
    func pausingGame() -> GameState {
        guard gamePhase.isActive else { return self }
        
        var updatedState = self
        updatedState.gamePhase = .paused
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Resumes the game from pause
    /// - Returns: A new game state with the game resumed
    func resumingGame() -> GameState {
        guard gamePhase == .paused else { return self }
        
        var updatedState = self
        updatedState.gamePhase = currentPlayer != nil ? .questioning : .spinning
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Ends the game
    /// - Returns: A new game state with the game ended
    func endingGame() -> GameState {
        var updatedState = self
        updatedState.gamePhase = .ended
        updatedState.currentPlayer = nil
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Selects a player for the current turn
    /// - Parameter player: The player to select
    /// - Returns: A new game state with the player selected
    func selectingPlayer(_ player: Player) -> GameState {
        guard players.contains(player) && gamePhase == .spinning else { return self }
        
        var updatedState = self
        updatedState.currentPlayer = player
        updatedState.gamePhase = .questioning
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Marks a question as used
    /// - Parameter questionId: The ID of the question to mark as used
    /// - Returns: A new game state with the question marked as used
    func markingQuestionAsUsed(_ questionId: UUID) -> GameState {
        var updatedState = self
        updatedState.usedQuestions.insert(questionId)
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Advances to the next turn (back to spinning)
    /// - Returns: A new game state ready for the next turn
    func advancingToNextTurn() -> GameState {
        guard gamePhase == .questioning else { return self }
        
        var updatedState = self
        updatedState.currentPlayer = nil
        updatedState.gamePhase = .spinning
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Resets used questions (when deck is exhausted)
    /// - Returns: A new game state with questions reset
    func resettingQuestions() -> GameState {
        var updatedState = self
        updatedState.usedQuestions.removeAll()
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Adds a player to the game
    /// - Parameter player: The player to add
    /// - Returns: A new game state with the player added
    func addingPlayer(_ player: Player) -> GameState {
        guard !players.contains(player) else { return self }
        
        var updatedState = self
        updatedState.players.append(player)
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    /// Removes a player from the game
    /// - Parameter playerId: The ID of the player to remove
    /// - Returns: A new game state with the player removed
    func removingPlayer(withId playerId: UUID) -> GameState {
        var updatedState = self
        updatedState.players.removeAll { $0.id == playerId }
        
        // If we removed the current player, clear the selection
        if updatedState.currentPlayer?.id == playerId {
            updatedState.currentPlayer = nil
            if updatedState.gamePhase == .questioning {
                updatedState.gamePhase = .spinning
            }
        }
        
        updatedState.lastActivityTime = Date()
        return updatedState
    }
    
    // MARK: - Question Management
    
    /// Gets the next available question
    /// - Returns: An unused question from the deck, or nil if all are used
    func nextAvailableQuestion() -> Question? {
        let availableQuestions = currentDeck.questions.filter { !usedQuestions.contains($0.id) }
        return availableQuestions.randomElement()
    }
    
    /// Gets all unused questions
    /// - Returns: Array of unused questions
    func unusedQuestions() -> [Question] {
        return currentDeck.questions.filter { !usedQuestions.contains($0.id) }
    }
    
    /// Gets the percentage of questions used
    /// - Returns: Percentage of questions used (0.0 to 1.0)
    func questionsUsedPercentage() -> Double {
        guard !currentDeck.questions.isEmpty else { return 0.0 }
        return Double(usedQuestions.count) / Double(currentDeck.questions.count)
    }
    
    // MARK: - Statistics
    
    /// Gets the duration of the current game session
    /// - Returns: Time interval since the game started, or nil if not started
    func gameDuration() -> TimeInterval? {
        guard let startTime = startTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Gets the time since last activity
    /// - Returns: Time interval since last activity
    func timeSinceLastActivity() -> TimeInterval {
        return Date().timeIntervalSince(lastActivityTime)
    }
    
    /// Checks if the game session is stale (no activity for a while)
    /// - Parameter threshold: Time threshold in seconds (default: 30 minutes)
    /// - Returns: True if the session is stale, false otherwise
    func isStale(threshold: TimeInterval = 1800) -> Bool {
        return timeSinceLastActivity() > threshold
    }
}

// MARK: - GameState Extensions

extension GameState {
    /// Creates a sample game state for testing and previews
    static var sample: GameState {
        GameState(
            players: Player.samplePlayers(count: 4),
            deck: QuestionDeck.sample,
            phase: .setup
        )
    }
    
    /// Creates a sample active game state
    static var sampleActive: GameState {
        let players = Player.samplePlayers(count: 4)
        var gameState = GameState(
            players: players,
            deck: QuestionDeck.sample,
            phase: .questioning
        )
        gameState.currentPlayer = players.first
        gameState.startTime = Date().addingTimeInterval(-300) // Started 5 minutes ago
        return gameState
    }
    
    /// Creates a sample ended game state
    static var sampleEnded: GameState {
        let players = Player.samplePlayers(count: 4)
        var gameState = GameState(
            players: players,
            deck: QuestionDeck.sample,
            phase: .ended
        )
        gameState.startTime = Date().addingTimeInterval(-1800) // Started 30 minutes ago
        gameState.usedQuestions = Set(QuestionDeck.sample.questions.map { $0.id })
        return gameState
    }
}