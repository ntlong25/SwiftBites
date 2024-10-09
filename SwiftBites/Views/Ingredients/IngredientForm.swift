import SwiftUI
import RealmSwift

struct IngredientForm: View {
    enum Mode: Hashable {
        case add
        case edit(Ingredient)
    }

    var mode: Mode

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _name = .init(initialValue: "")
            title = "Add Ingredient"
        case .edit(let ingredient):
            _name = .init(initialValue: ingredient.name)
            title = "Edit \(ingredient.name)"
        }
    }

    private let title: String
    @State private var name: String
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .focused($isNameFocused)
            }
            if case .edit(let ingredient) = mode {
                Button(
                    role: .destructive,
                    action: {
                        delete(ingredient: ingredient)
                    },
                    label: {
                        Text("Delete Ingredient")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                )
            }
        }
        .onAppear {
            isNameFocused = true
        }
        .onSubmit {
            save()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: save)
                    .disabled(name.isEmpty)
            }
        }
    }

    // MARK: - Data

    private func delete(ingredient: Ingredient) {
        guard let realm = ingredient.realm else { return }
        do {
            try realm.write {
                realm.delete(ingredient)
            }
        } catch {
            print("Error deleting ingredient: \(error)")
        }
        
        
        dismiss()
    }

    private func save() {
        switch mode {
        case .add:
            let ingredient = Ingredient()
            ingredient.name = name
            
            do {
                let realm = try Realm()
                try realm.write {
                    realm.add(ingredient)
                }
            } catch {
                print("Error add ingredient: \(error)")
            }
        case .edit(let ingredient):
            do {
                guard let realm = ingredient.realm else { return }
                
                try realm.write {
                    ingredient.name = name
                }
            } catch {
                print("Error edit ingredient: \(error)")
            }
        }
        
        dismiss()
    }
}

//#Preview {
//    IngredientForm(mode: .add)
//}
