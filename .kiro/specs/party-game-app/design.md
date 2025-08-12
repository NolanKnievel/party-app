# Design Document

## Overview

The Party Game App is an iOS application built using SwiftUI and following MVVM architecture patterns. The app provides a seamless pass-the-phone gaming experience with a spinning wheel player selector, customizable question decks, and community-driven content sharing. The design emphasizes smooth animations, intuitive navigation, and offline-first functionality with optional cloud sync.

## Architecture

### High-Level Architecture

The app follows a modular MVVM (Model-View-ViewModel) architecture with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Views       │    │   ViewModels    │    │     Models      │
│   (SwiftUI)     │◄──►│   (ObservableObject)│◄──►│   (Structs)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │    Services     │
                       │ (Data & Network)│
                       └─────────────────┘
```

### Core Components

1. **Game Engine**: Manages game state, player turns, and question flow
2. **Deck Manager**: Handles local and remote question deck operations
3. **Spinner Engine**: Controls wheel animation and player selection logic
4. **Data Layer**: Core Data for local storage, CloudKit for sync
5. **Network Layer**: API communication for community content
6. **UI Components**: Reusable SwiftUI views and animations

## Components and Interfaces

### 1. Game Flow Manager

**Purpose**: Orchestrates the overall game experience and state transitions

**Key Responsibilities**:

- Manages game session lifecycle
- Coordinates between spinner, questions, and player management
- Handles game state persistence

**Interface**:

```swift
protocol GameFlowManagerProtocol {
    func startGame(with deck: QuestionDeck, players: [Player])
    func pauseGame()
    func endGame()
    func nextTurn()
    var currentGameState: GameState { get }
}
```

### 2. Spinner Engine

**Purpose**: Handles the spinning wheel animation and player selection

**Key Responsibilities**:

- Animates wheel spinning with realistic physics
- Ensures fair random selection
- Provides smooth visual feedback

**Interface**:

```swift
protocol SpinnerEngineProtocol {
    func spin(players: [Player]) -> AnyPublisher<Player, Never>
    func configureAnimation(duration: TimeInterval, easing: AnimationCurve)
    var isSpinning: Bool { get }
}
```

### 3. Deck Service

**Purpose**: Manages question decks (local and remote)

**Key Responsibilities**:

- CRUD operations for custom decks
- Downloads and caches community decks
- Provides default deck content

**Interface**:

```swift
protocol DeckServiceProtocol {
    func getAvailableDecks() -> AnyPublisher<[QuestionDeck], Error>
    func createDeck(_ deck: QuestionDeck) -> AnyPublisher<Void, Error>
    func downloadCommunityDeck(id: String) -> AnyPublisher<QuestionDeck, Error>
    func searchCommunityDecks(query: String) -> AnyPublisher<[QuestionDeck], Error>
}
```

### 4. Question Provider

**Purpose**: Delivers questions from active deck with smart ordering

**Key Responsibilities**:

- Tracks used questions to avoid repetition
- Shuffles questions for variety
- Handles deck completion scenarios

**Interface**:

```swift
protocol QuestionProviderProtocol {
    func nextQuestion() -> Question?
    func skipQuestion() -> Question?
    func resetDeck()
    var remainingQuestions: Int { get }
}
```

## Data Models

### Core Models

```swift
struct Player: Identifiable, Codable {
    let id: UUID
    var name: String
    var isActive: Bool

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isActive = true
    }
}

struct Question: Identifiable, Codable {
    let id: UUID
    var text: String
    var category: QuestionCategory
    var difficulty: DifficultyLevel

    enum QuestionCategory: String, CaseIterable, Codable {
        case truthOrDare = "Truth or Dare"
        case wouldYouRather = "Would You Rather"
        case custom = "Custom"
    }

    enum DifficultyLevel: String, CaseIterable, Codable {
        case easy, medium, hard
    }
}

struct QuestionDeck: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var questions: [Question]
    var isDefault: Bool
    var isPublic: Bool
    var createdBy: String?
    var downloadCount: Int
    var rating: Double

    var questionCount: Int {
        questions.count
    }
}

struct GameState: Codable {
    var players: [Player]
    var currentDeck: QuestionDeck
    var currentPlayer: Player?
    var usedQuestions: Set<UUID>
    var gamePhase: GamePhase

    enum GamePhase: String, Codable {
        case setup, spinning, questioning, paused, ended
    }
}
```

### Data Persistence Models

```swift
// Core Data entities for local storage
@Model
class DeckEntity {
    var id: UUID
    var name: String
    var description: String
    var isDefault: Bool
    var isPublic: Bool
    var createdDate: Date
    var questions: [QuestionEntity]
}

@Model
class QuestionEntity {
    var id: UUID
    var text: String
    var category: String
    var difficulty: String
    var deck: DeckEntity?
}
```

## User Interface Design

### Navigation Structure

```
Main Menu
├── Play Game
│   ├── Select Deck
│   ├── Add Players
│   └── Game Session
│       ├── Spinner View
│       └── Question View
├── My Decks
│   ├── Create New Deck
│   └── Edit Existing Deck
└── Browse Community
    ├── Popular Decks
    ├── Search Results
    └── Deck Details
```

### Key UI Components

#### 1. Spinning Wheel View

- Circular wheel with player name segments
- Smooth rotation animation with deceleration
- Clear winner indication with haptic feedback
- Customizable colors and fonts

#### 2. Question Display View

- Large, readable text optimized for group viewing
- Minimal UI to focus attention on content
- Tap-anywhere-to-continue interaction
- Skip question option (swipe gesture)

#### 3. Deck Browser

- Grid layout for deck thumbnails
- Search bar with real-time filtering
- Sort options (popularity, rating, newest)
- Download progress indicators

#### 4. Deck Editor

- Add/edit/delete questions interface
- Drag-to-reorder functionality
- Category and difficulty selection
- Preview mode for testing

### Design System

**Color Palette**:

- Primary: Vibrant blue (#007AFF)
- Secondary: Warm orange (#FF9500)
- Success: Green (#34C759)
- Warning: Yellow (#FFCC00)
- Error: Red (#FF3B30)
- Background: System background colors
- Text: System label colors

**Typography**:

- Headlines: SF Pro Display (Bold)
- Body: SF Pro Text (Regular)
- Questions: SF Pro Display (Medium, larger size)
- UI Elements: SF Pro Text (Medium)

**Animation Principles**:

- Smooth, physics-based animations
- Consistent timing (0.3s for most transitions)
- Meaningful motion that guides user attention
- Reduced motion support for accessibility

## Error Handling

### Error Categories and Responses

1. **Network Errors**

   - Graceful degradation to offline mode
   - Retry mechanisms with exponential backoff
   - Clear user messaging about connectivity issues

2. **Data Corruption**

   - Automatic data validation on app launch
   - Recovery from backup/default data
   - User notification with recovery options

3. **Storage Errors**

   - Disk space monitoring
   - Cleanup of temporary files
   - Alternative storage strategies

4. **Game State Errors**
   - State validation before critical operations
   - Automatic recovery to last known good state
   - Option to restart game session

### Error Recovery Strategies

```swift
enum AppError: LocalizedError {
    case networkUnavailable
    case dataCorrupted
    case insufficientStorage
    case gameStateInvalid

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Unable to connect. Using offline content."
        case .dataCorrupted:
            return "Data issue detected. Restoring from backup."
        case .insufficientStorage:
            return "Storage full. Please free up space."
        case .gameStateInvalid:
            return "Game state error. Restarting session."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .dataCorrupted:
            return "Your custom content will be restored automatically."
        case .insufficientStorage:
            return "Delete unused apps or files to continue."
        case .gameStateInvalid:
            return "Your progress will be saved and the game restarted."
        }
    }
}
```

## Testing Strategy

### Unit Testing

- **Models**: Data validation, business logic
- **ViewModels**: State management, user interactions
- **Services**: API calls, data persistence
- **Utilities**: Helper functions, extensions

### Integration Testing

- **Game Flow**: Complete game session scenarios
- **Data Sync**: Local and cloud data consistency
- **Network Layer**: API integration and error handling

### UI Testing

- **Critical Paths**: Game setup to completion
- **Accessibility**: VoiceOver, Dynamic Type support
- **Performance**: Animation smoothness, memory usage

### Testing Tools and Frameworks

- XCTest for unit and integration tests
- XCUITest for UI automation
- Quick/Nimble for BDD-style testing
- SwiftUI Preview testing for rapid iteration

### Test Coverage Goals

- Minimum 80% code coverage
- 100% coverage for critical game logic
- All error scenarios tested
- Accessibility compliance verified

## Performance Considerations

### Memory Management

- Lazy loading of question content
- Image caching for community deck thumbnails
- Proper cleanup of game session data

### Animation Performance

- Use of CADisplayLink for smooth wheel animation
- GPU-accelerated Core Animation layers
- Reduced animation complexity on older devices

### Data Efficiency

- Incremental loading of community content
- Compression for question deck storage
- Background sync to minimize user wait times

### Battery Optimization

- Minimal background processing
- Efficient network usage patterns
- Screen dimming prevention during active gameplay
