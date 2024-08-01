import SwiftUI
import SwiftData

@main
struct SwiftBitesApp: App {
    let container: ModelContainer
    
    init() {
        let schema = Schema([
            Recipe.self,
            Category.self,
            Ingredient.self,
            RecipeIngredient.self
        ])
        
        do {
            let config = ModelConfiguration()
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
