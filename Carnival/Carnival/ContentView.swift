import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DeckEntity.name, ascending: true)],
        animation: .default)
    private var decks: FetchedResults<DeckEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(decks) { deck in
                    VStack(alignment: .leading) {
                        Text(deck.name ?? "Unknown Deck")
                            .font(.headline)
                        Text(deck.deckDescription ?? "No description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(deck.questions?.count ?? 0) questions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Party Game")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Deck") {
                        // TODO: Add deck creation functionality
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}