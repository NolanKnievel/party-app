import Foundation

/// Represents a player in the party game
struct Player: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var isActive: Bool
    
    /// Creates a new player with the given name
    /// - Parameter name: The player's display name
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isActive = true
    }
    
    /// Creates a player with all properties specified (useful for testing)
    /// - Parameters:
    ///   - id: Unique identifier for the player
    ///   - name: The player's display name
    ///   - isActive: Whether the player is currently active in the game
    init(id: UUID = UUID(), name: String, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.isActive = isActive
    }
    
    // MARK: - Validation
    
    /// Validates that the player has a valid name
    /// - Returns: True if the player name is valid, false otherwise
    func isValid() -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns a sanitized version of the player name
    /// - Returns: Player name with leading/trailing whitespace removed
    func sanitizedName() -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Player Extensions

extension Player {
    /// Creates a sample player for testing and previews
    static var sample: Player {
        Player(name: "Sample Player")
    }
    
    /// Creates multiple sample players for testing
    /// - Parameter count: Number of sample players to create
    /// - Returns: Array of sample players
    static func samplePlayers(count: Int = 4) -> [Player] {
        let names = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
        return Array(names.prefix(count)).map { Player(name: $0) }
    }
}