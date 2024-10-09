import SwiftUI
import RealmSwift

struct CategoryForm: View {
    enum Mode: Hashable {
        case add
        case edit(Category)
    }

    var mode: Mode

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _name = .init(initialValue: "")
            title = "Add Category"
        case .edit(let category):
            _name = .init(initialValue: category.name)
            title = "Edit \(category.name)"
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
            if case .edit(let category) = mode {
                Button(
                    role: .destructive,
                    action: {
                        delete(category: category)
                    },
                    label: {
                        Text("Delete Category")
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
        .alert(error: $error)
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

    private func delete(category: Category) {
        guard let realm = category.realm else { return }
        
        do {
            try realm.write {
                realm.delete(category)
            }
        } catch {
            print("Error deleting category: \(error.localizedDescription)")
        }
        
        dismiss()
    }

    private func save() {
        switch mode {
        case .add:
            
            let category = Category()
            category.name = name
            do {
                let realm = try Realm()
                try realm.write {
                    realm.add(category)
                }
            } catch {
                print("Error adding category: \(error)")
            }
        
        case .edit(let category):
            do {
                guard let realm = category.realm else { return }
                try realm.write {
                    category.name = name
                }
            } catch {
                print("Error edit category: \(error)")
            }
        }
  
        dismiss()
    }
}

//#Preview {
//    CategoryForm(mode: .add)
//}
