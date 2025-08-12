import XCTest
@testable import PartyGameApp

final class PlayerTests: XCTestCase {
    
    func testPlayerInitialization() {
        // Test basic initialization
        let player = Player(name: "Alice")
        
        XCTAssertEqual(player.name, "Alice")
        XCTAssertTrue(player.isActive)
        XCTAssertNotNil(player.id)
    }
    
    func testPlayerInitializationWithAllParameters() {
        // Test initialization with all parameters
        let id = UUID()
        let player = Player(id: id, name: "Bob", isActive: false)
        
        XCTAssertEqual(player.id, id)
        XCTAssertEqual(player.name, "Bob")
        XCTAssertFalse(player.isActive)
    }
    
    func testPlayerValidation() {
        // Test valid player
        let validPlayer = Player(name: "Charlie")
        XCTAssertTrue(validPlayer.isValid())
        
        // Test invalid player with empty name
        let invalidPlayer = Player(name: "")
        XCTAssertFalse(invalidPlayer.isValid())
        
        // Test invalid player with whitespace-only name
        let whitespacePlayer = Player(name: "   ")
        XCTAssertFalse(whitespacePlayer.isValid())
    }
    
    func testPlayerNameSanitization() {
        // Test name with leading/trailing whitespace
        let player = Player(name: "  Diana  ")
        XCTAssertEqual(player.sanitizedName(), "Diana")
        
        // Test name with tabs and newlines
        let messyPlayer = Player(name: "\t\nEve\n\t")
        XCTAssertEqual(messyPlayer.sanitizedName(), "Eve")
    }
    
    func testPlayerEquality() {
        // Test equality based on ID
        let id = UUID()
        let player1 = Player(id: id, name: "Frank")
        let player2 = Player(id: id, name: "Franklin") // Different name, same ID
        
        XCTAssertEqual(player1, player2)
        
        // Test inequality with different IDs
        let player3 = Player(name: "Frank")
        let player4 = Player(name: "Frank")
        
        XCTAssertNotEqual(player3, player4)
    }
    
    func testPlayerHashable() {
        // Test that players with same ID have same hash
        let id = UUID()
        let player1 = Player(id: id, name: "Grace")
        let player2 = Player(id: id, name: "Gracie")
        
        XCTAssertEqual(player1.hashValue, player2.hashValue)
        
        // Test that players with different IDs have different hashes (usually)
        let player3 = Player(name: "Grace")
        let player4 = Player(name: "Grace")
        
        XCTAssertNotEqual(player3.hashValue, player4.hashValue)
    }
    
    func testPlayerCodable() throws {
        // Test encoding and decoding
        let originalPlayer = Player(name: "Henry")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPlayer)
        
        let decoder = JSONDecoder()
        let decodedPlayer = try decoder.decode(Player.self, from: data)
        
        XCTAssertEqual(originalPlayer.id, decodedPlayer.id)
        XCTAssertEqual(originalPlayer.name, decodedPlayer.name)
        XCTAssertEqual(originalPlayer.isActive, decodedPlayer.isActive)
    }
    
    func testSamplePlayerCreation() {
        // Test sample player creation
        let samplePlayer = Player.sample
        XCTAssertEqual(samplePlayer.name, "Sample Player")
        XCTAssertTrue(samplePlayer.isActive)
        XCTAssertTrue(samplePlayer.isValid())
    }
    
    func testSamplePlayersCreation() {
        // Test creating multiple sample players
        let players = Player.samplePlayers(count: 3)
        
        XCTAssertEqual(players.count, 3)
        XCTAssertEqual(players[0].name, "Alice")
        XCTAssertEqual(players[1].name, "Bob")
        XCTAssertEqual(players[2].name, "Charlie")
        
        // Test all players are valid and unique
        for player in players {
            XCTAssertTrue(player.isValid())
            XCTAssertTrue(player.isActive)
        }
        
        // Test all players have unique IDs
        let uniqueIds = Set(players.map { $0.id })
        XCTAssertEqual(uniqueIds.count, players.count)
    }
    
    func testSamplePlayersWithLargeCount() {
        // Test creating more players than available names
        let players = Player.samplePlayers(count: 10)
        
        // Should only create as many as there are names available
        XCTAssertEqual(players.count, 8) // Based on the names array in Player.swift
    }
    
    func testSamplePlayersWithZeroCount() {
        // Test creating zero players
        let players = Player.samplePlayers(count: 0)
        XCTAssertEqual(players.count, 0)
    }
}