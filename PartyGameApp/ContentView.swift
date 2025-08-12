import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "party.popper.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Party Game App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome to the ultimate party game!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            .navigationTitle("Party Game")
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}