import XCTest
@testable import PartyGameApp

final class GameStateTests: XCTestCase {
    
    var samplePlayers: [Player]!
    var sampleDeck: QuestionDeck!
    
    override func setUp() {
        super.setUp()
        samplePlayers = Player.samplePlayers(count: 4)
        sampleDeck = QuestionDeck.sample
    }
    
    override func tearDown() {
        samplePlayers = nil
        sampleDeck = nil
        super.tearDown()
    }
    
    func testGameStateInitialization() {
        // Test basic initialization
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        
        XCTAssertEqual(gameState.players.count, 4)
        XCTAssertEqual(gameState.currentDeck.id, sampleDeck.id)
        XCTAssertNil(gameState.currentPlayer)
        XCTAssertTrue(gameState.usedQuestions.isEmpty)
        XCTAssertEqual(gameState.gamePhase, .setup)
        XCTAssertNotNil(gameState.sessionId)
        XCTAssertNil(gameState.startTime)
        XCTAssertNotNil(gameState.lastActivityTime)
    }
    
    func testGameStateInitializationWithAllParameters() {
        // Test initialization with all parameters
        let sessionId = UUID()
        let startTime = Date()
        let lastActivity = Date()
        let usedQuestions: Set<UUID> = [UUID(), UUID()]
        
        let gameState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            currentPlayer: samplePlayers.first,
            usedQuestions: usedQuestions,
            gamePhase: .questioning,
            sessionId: sessionId,
            startTime: startTime,
            lastActivityTime: lastActivity
        )
        
        XCTAssertEqual(gameState.players.count, 4)
        XCTAssertEqual(gameState.currentDeck.id, sampleDeck.id)
        XCTAssertEqual(gameState.currentPlayer?.id, samplePlayers.first?.id)
        XCTAssertEqual(gameState.usedQuestions, usedQuestions)
        XCTAssertEqual(gameState.gamePhase, .questioning)
        XCTAssertEqual(gameState.sessionId, sessionId)
        XCTAssertEqual(gameState.startTime, startTime)
        XCTAssertEqual(gameState.lastActivityTime, lastActivity)
    }
    
    func testGameStateValidation() {
        // Test valid game state
        let validGameState = GameState(players: samplePlayers, deck: sampleDeck)
        XCTAssertTrue(validGameState.isValid())
        
        // Test invalid game state with too few players
        let tooFewPlayers = [Player(name: "Solo")]
        let invalidGameState = GameState(players: tooFewPlayers, deck: sampleDeck)
        XCTAssertFalse(invalidGameState.isValid())
        
        // Test invalid game state with invalid players
        let invalidPlayers = [Player(name: "Valid"), Player(name: "")]
        let invalidPlayersGameState = GameState(players: invalidPlayers, deck: sampleDeck)
        XCTAssertFalse(invalidPlayersGameState.isValid())
        
        // Test invalid game state with invalid deck
        let invalidDeck = QuestionDeck(name: "", description: "Invalid")
        let invalidDeckGameState = GameState(players: samplePlayers, deck: invalidDeck)
        XCTAssertFalse(invalidDeckGameState.isValid())
        
        // Test invalid game state with current player not in players list
        let outsidePlayer = Player(name: "Outsider")
        let invalidCurrentPlayerGameState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            currentPlayer: outsidePlayer
        )
        XCTAssertFalse(invalidCurrentPlayerGameState.isValid())
    }
    
    func testGameStateCanStart() {
        // Test can start with valid setup
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        XCTAssertTrue(gameState.canStart())
        
        // Test cannot start with too few players
        let tooFewPlayers = [Player(name: "Solo")]
        let tooFewPlayersState = GameState(players: tooFewPlayers, deck: sampleDeck)
        XCTAssertFalse(tooFewPlayersState.canStart())
        
        // Test cannot start with empty deck
        let emptyDeck = QuestionDeck(name: "Empty", description: "No questions")
        let emptyDeckState = GameState(players: samplePlayers, deck: emptyDeck)
        XCTAssertFalse(emptyDeckState.canStart())
        
        // Test cannot start if not in setup phase
        let activeState = GameState(players: samplePlayers, deck: sampleDeck, gamePhase: .spinning)
        XCTAssertFalse(activeState.canStart())
    }
    
    func testGameStateHasUnusedQuestions() {
        // Test with no used questions
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        XCTAssertTrue(gameState.hasUnusedQuestions())
        
        // Test with some used questions
        let someUsedQuestions = Set([sampleDeck.questions.first!.id])
        let someUsedState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            usedQuestions: someUsedQuestions
        )
        XCTAssertTrue(someUsedState.hasUnusedQuestions())
        
        // Test with all questions used
        let allUsedQuestions = Set(sampleDeck.questions.map { $0.id })
        let allUsedState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            usedQuestions: allUsedQuestions
        )
        XCTAssertFalse(allUsedState.hasUnusedQuestions())
    }
    
    func testGameStateStarting() {
        // Test starting a valid game
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        let startedState = gameState.startingGame()
        
        XCTAssertEqual(startedState.gamePhase, .spinning)
        XCTAssertNotNil(startedState.startTime)
        XCTAssertNotEqual(gameState.lastActivityTime, startedState.lastActivityTime)
        
        // Test starting an invalid game (should return unchanged)
        let invalidState = GameState(players: [Player(name: "Solo")], deck: sampleDeck)
        let unchangedState = invalidState.startingGame()
        XCTAssertEqual(unchangedState.gamePhase, .setup)
        XCTAssertNil(unchangedState.startTime)
    }
    
    func testGameStatePausingAndResuming() {
        // Test pausing an active game
        let activeState = GameState(players: samplePlayers, deck: sampleDeck, gamePhase: .spinning)
        let pausedState = activeState.pausingGame()
        
        XCTAssertEqual(pausedState.gamePhase, .paused)
        XCTAssertNotEqual(activeState.lastActivityTime, pausedState.lastActivityTime)
        
        // Test pausing an inactive game (should return unchanged)
        let endedState = GameState(players: samplePlayers, deck: sampleDeck, gamePhase: .ended)
        let unchangedState = endedState.pausingGame()
        XCTAssertEqual(unchangedState.gamePhase, .ended)
        
        // Test resuming from pause without current player
        let resumedSpinningState = pausedState.resumingGame()
        XCTAssertEqual(resumedSpinningState.gamePhase, .spinning)
        
        // Test resuming from pause with current player
        let pausedWithPlayerState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            currentPlayer: samplePlayers.first,
            gamePhase: .paused
        )
        let resumedQuestioningState = pausedWithPlayerState.resumingGame()
        XCTAssertEqual(resumedQuestioningState.gamePhase, .questioning)
        
        // Test resuming non-paused game (should return unchanged)
        let nonPausedState = GameState(players: samplePlayers, deck: sampleDeck, gamePhase: .setup)
        let unchangedResumeState = nonPausedState.resumingGame()
        XCTAssertEqual(unchangedResumeState.gamePhase, .setup)
    }
    
    func testGameStateEnding() {
        // Test ending a game
        let activeState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            currentPlayer: samplePlayers.first,
            gamePhase: .questioning
        )
        let endedState = activeState.endingGame()
        
        XCTAssertEqual(endedState.gamePhase, .ended)
        XCTAssertNil(endedState.currentPlayer)
        XCTAssertNotEqual(activeState.lastActivityTime, endedState.lastActivityTime)
    }
    
    func testGameStatePlayerSelection() {
        // Test selecting a valid player
        let gameState = GameState(players: samplePlayers, deck: sampleDeck, gamePhase: .spinning)
        let selectedState = gameState.selectingPlayer(samplePlayers.first!)
        
        XCTAssertEqual(selectedState.currentPlayer?.id, samplePlayers.first?.id)
        XCTAssertEqual(selectedState.gamePhase, .questioning)
        XCTAssertNotEqual(gameState.lastActivityTime, selectedState.lastActivityTime)
        
        // Test selecting invalid player (not in game)
        let outsidePlayer = Player(name: "Outsider")
        let unchangedState = gameState.selectingPlayer(outsidePlayer)
        XCTAssertNil(unchangedState.currentPlayer)
        XCTAssertEqual(unchangedState.gamePhase, .spinning)
        
        // Test selecting player in wrong phase
        let setupState = GameState(players: samplePlayers, deck: sampleDeck, gamePhase: .setup)
        let wrongPhaseState = setupState.selectingPlayer(samplePlayers.first!)
        XCTAssertNil(wrongPhaseState.currentPlayer)
        XCTAssertEqual(wrongPhaseState.gamePhase, .setup)
    }
    
    func testGameStateQuestionManagement() {
        // Test marking question as used
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        let questionId = sampleDeck.questions.first!.id
        let updatedState = gameState.markingQuestionAsUsed(questionId)
        
        XCTAssertTrue(updatedState.usedQuestions.contains(questionId))
        XCTAssertNotEqual(gameState.lastActivityTime, updatedState.lastActivityTime)
        
        // Test advancing to next turn
        let questioningState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            currentPlayer: samplePlayers.first,
            gamePhase: .questioning
        )
        let nextTurnState = questioningState.advancingToNextTurn()
        
        XCTAssertNil(nextTurnState.currentPlayer)
        XCTAssertEqual(nextTurnState.gamePhase, .spinning)
        XCTAssertNotEqual(questioningState.lastActivityTime, nextTurnState.lastActivityTime)
        
        // Test resetting questions
        let usedQuestions = Set(sampleDeck.questions.map { $0.id })
        let allUsedState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            usedQuestions: usedQuestions
        )
        let resetState = allUsedState.resettingQuestions()
        
        XCTAssertTrue(resetState.usedQuestions.isEmpty)
        XCTAssertNotEqual(allUsedState.lastActivityTime, resetState.lastActivityTime)
    }
    
    func testGameStatePlayerManagement() {
        // Test adding player
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        let newPlayer = Player(name: "NewPlayer")
        let updatedState = gameState.addingPlayer(newPlayer)
        
        XCTAssertEqual(updatedState.players.count, 5)
        XCTAssertTrue(updatedState.players.contains(newPlayer))
        XCTAssertNotEqual(gameState.lastActivityTime, updatedState.lastActivityTime)
        
        // Test adding duplicate player (should return unchanged)
        let duplicateState = updatedState.addingPlayer(newPlayer)
        XCTAssertEqual(duplicateState.players.count, 5)
        
        // Test removing player
        let removedState = updatedState.removingPlayer(withId: newPlayer.id)
        XCTAssertEqual(removedState.players.count, 4)
        XCTAssertFalse(removedState.players.contains(newPlayer))
        
        // Test removing current player
        let currentPlayerState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            currentPlayer: samplePlayers.first,
            gamePhase: .questioning
        )
        let removedCurrentState = currentPlayerState.removingPlayer(withId: samplePlayers.first!.id)
        
        XCTAssertNil(removedCurrentState.currentPlayer)
        XCTAssertEqual(removedCurrentState.gamePhase, .spinning)
        XCTAssertEqual(removedCurrentState.players.count, 3)
    }
    
    func testGameStateQuestionRetrieval() {
        // Test getting next available question
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        let nextQuestion = gameState.nextAvailableQuestion()
        
        XCTAssertNotNil(nextQuestion)
        XCTAssertTrue(sampleDeck.questions.contains(nextQuestion!))
        
        // Test getting unused questions
        let unusedQuestions = gameState.unusedQuestions()
        XCTAssertEqual(unusedQuestions.count, sampleDeck.questions.count)
        
        // Test with some used questions
        let usedQuestionId = sampleDeck.questions.first!.id
        let someUsedState = gameState.markingQuestionAsUsed(usedQuestionId)
        let remainingQuestions = someUsedState.unusedQuestions()
        
        XCTAssertEqual(remainingQuestions.count, sampleDeck.questions.count - 1)
        XCTAssertFalse(remainingQuestions.contains { $0.id == usedQuestionId })
        
        // Test questions used percentage
        let percentage = someUsedState.questionsUsedPercentage()
        let expectedPercentage = 1.0 / Double(sampleDeck.questions.count)
        XCTAssertEqual(percentage, expectedPercentage, accuracy: 0.001)
    }
    
    func testGameStateStatistics() {
        // Test game duration with no start time
        let gameState = GameState(players: samplePlayers, deck: sampleDeck)
        XCTAssertNil(gameState.gameDuration())
        
        // Test game duration with start time
        let startTime = Date().addingTimeInterval(-300) // 5 minutes ago
        let startedState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            startTime: startTime
        )
        let duration = startedState.gameDuration()
        XCTAssertNotNil(duration)
        XCTAssertGreaterThan(duration!, 290) // Should be around 300 seconds
        XCTAssertLessThan(duration!, 310)
        
        // Test time since last activity
        let lastActivity = Date().addingTimeInterval(-60) // 1 minute ago
        let activityState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            lastActivityTime: lastActivity
        )
        let timeSinceActivity = activityState.timeSinceLastActivity()
        XCTAssertGreaterThan(timeSinceActivity, 55) // Should be around 60 seconds
        XCTAssertLessThan(timeSinceActivity, 65)
        
        // Test stale session detection
        let staleActivity = Date().addingTimeInterval(-2000) // Over 30 minutes ago
        let staleState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            lastActivityTime: staleActivity
        )
        XCTAssertTrue(staleState.isStale())
        XCTAssertFalse(gameState.isStale()) // Fresh state should not be stale
    }
    
    func testGameStateCodable() throws {
        // Test encoding and decoding
        let originalState = GameState(
            players: samplePlayers,
            currentDeck: sampleDeck,
            currentPlayer: samplePlayers.first,
            usedQuestions: Set([sampleDeck.questions.first!.id]),
            gamePhase: .questioning
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalState)
        
        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(GameState.self, from: data)
        
        XCTAssertEqual(originalState.players.count, decodedState.players.count)
        XCTAssertEqual(originalState.currentDeck.id, decodedState.currentDeck.id)
        XCTAssertEqual(originalState.currentPlayer?.id, decodedState.currentPlayer?.id)
        XCTAssertEqual(originalState.usedQuestions, decodedState.usedQuestions)
        XCTAssertEqual(originalState.gamePhase, decodedState.gamePhase)
        XCTAssertEqual(originalState.sessionId, decodedState.sessionId)
    }
    
    func testSampleGameStates() {
        // Test sample game state
        let sampleState = GameState.sample
        XCTAssertTrue(sampleState.isValid())
        XCTAssertEqual(sampleState.gamePhase, .setup)
        XCTAssertEqual(sampleState.players.count, 4)
        
        // Test sample active game state
        let activeState = GameState.sampleActive
        XCTAssertTrue(activeState.isValid())
        XCTAssertEqual(activeState.gamePhase, .questioning)
        XCTAssertNotNil(activeState.currentPlayer)
        XCTAssertNotNil(activeState.startTime)
        
        // Test sample ended game state
        let endedState = GameState.sampleEnded
        XCTAssertTrue(endedState.isValid())
        XCTAssertEqual(endedState.gamePhase, .ended)
        XCTAssertNotNil(endedState.startTime)
        XCTAssertFalse(endedState.hasUnusedQuestions())
    }
}