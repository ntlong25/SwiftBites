import SwiftUI
import PhotosUI
import Foundation
import RealmSwift

struct RecipeForm: View {
    enum Mode: Hashable {
        case add
        case edit(Recipe)
    }
  
    var mode: Mode
  
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            title = "Add Recipe"
            _name = .init(initialValue: "")
            _summary = .init(initialValue: "")
            _serving = .init(initialValue: 1)
            _time = .init(initialValue: 5)
            _instructions = .init(initialValue: "")
            _recipeIngredients = .init(initialValue: [])
        case .edit(let recipe):
            title = "Edit \(recipe.name)"
            _name = .init(initialValue: recipe.name)
            _summary = .init(initialValue: recipe.summary)
            _category = .init(initialValue: recipe.category ?? Category())
            _serving = .init(initialValue: recipe.serving)
            _time = .init(initialValue: recipe.time)
            _instructions = .init(initialValue: recipe.instructions)
            _recipeIngredients = .init(initialValue: Array(recipe.ingredients) )
            _imageData = .init(initialValue: recipe.imageData)
      
        }
    }
  
    private let title: String
    @State private var name: String
    @State private var summary: String
    @State private var serving: Int
    @State private var time: Int
    @State private var instructions: String
    @State private var category: Category?
    @State private var recipeIngredients: [RecipeIngredient]
    @State private var imageItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isIngredientsPickerPresented =  false
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
  
    @State private var categories: Results<Category>?
  
    // MARK: - Body
  
    var body: some View {
        GeometryReader { geometry in
            Form {
                imageSection(width: geometry.size.width)
                nameSection
                summarySection
                categorySection
                servingAndTimeSection
                ingredientsSection
                instructionsSection
                deleteButton
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(error: $error)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: save)
                    .disabled(name.isEmpty || instructions.isEmpty)
            }
        }
        .onChange(of: imageItem) { _, _ in
            Task {
                self.imageData = try? await imageItem?
                    .loadTransferable(type: Data.self)
            }
        }
        .sheet(
            isPresented: $isIngredientsPickerPresented,
            content: ingredientPicker
        )
        .onAppear(perform: loadCategory)
    }
  
    // MARK: - Views
  
    private func ingredientPicker() -> some View {
        IngredientsView { selectedIngredient in
            let recipeIngredient = RecipeIngredient()
            recipeIngredient.id = UUID()
            recipeIngredient.ingredient = selectedIngredient
            recipeIngredient.quantity = ""
            
            recipeIngredients.append(recipeIngredient)
        }
    }
  
    @ViewBuilder
    private func imageSection(width: CGFloat) -> some View {
        Section {
            imagePicker(width: width)
            removeImage
        }
    }
  
    @ViewBuilder
    private func imagePicker(width: CGFloat) -> some View {
        PhotosPicker(selection: $imageItem, matching: .images) {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width)
                    .clipped()
                    .listRowInsets(EdgeInsets())
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 200,
                        idealHeight: 200,
                        maxHeight: 200,
                        alignment: .center
                    )
            } else {
                Label("Select Image", systemImage: "photo")
            }
        }
    }
  
    @ViewBuilder
    private var removeImage: some View {
        if imageData != nil {
            Button(
                role: .destructive,
                action: {
                    imageData = nil
                },
                label: {
                    Text("Remove Image")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            )
        }
    }
  
    @ViewBuilder
    private var nameSection: some View {
        Section("Name") {
            TextField("Margherita Pizza", text: $name)
        }
    }
  
    @ViewBuilder
    private var summarySection: some View {
        Section("Summary") {
            TextField(
                "Delicious blend of fresh basil, mozzarella, and tomato on a crispy crust.",
                text: $summary,
                axis: .vertical
            )
            .lineLimit(3...5)
        }
    }
  
    @ViewBuilder
    private var categorySection: some View {
        Section {
            Picker("Category", selection: $category) {
                Text("None").tag(Category())
                if let categories = categories {
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
        }
    }
  
    @ViewBuilder
    private var servingAndTimeSection: some View {
        Section {
            Stepper("Servings: \(serving)p", value: $serving, in: 1...100)
            Stepper("Time: \(time)m", value: $time, in: 5...300, step: 5)
        }
        .monospacedDigit()
    }
  
    @ViewBuilder
    private var ingredientsSection: some View {
        Section("Ingredients") {
            if recipeIngredients.isEmpty {
                ContentUnavailableView(
                    label: {
                        Label("No Ingredients", systemImage: "list.clipboard")
                    },
                    description: {
                        Text("Recipe ingredients will appear here.")
                    },
                    actions: {
                        Button("Add Ingredient") {
                            isIngredientsPickerPresented = true
                        }
                    }
                )
            } else {
                ForEach(recipeIngredients) { recipeIngredient in
                    HStack(alignment: .center) {
                        if let ingredient = recipeIngredient.ingredient {
                            Text(ingredient.name)
                                .bold()
                                .layoutPriority(2)
                        }
                        Spacer()
                        TextField(
                            "Quantity",
                            text: .init(
                                get: {
                                    recipeIngredient.quantity
                                },
                                set: { quantity in
                                    if let index = recipeIngredients.firstIndex(
                                        where: { $0.id == recipeIngredient.id
                                        }) {
                                        recipeIngredients[index].quantity = quantity
                                    }
                                }
                            )
                        )
                        .layoutPriority(1)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(
                            "Delete",
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            deleteRecipeIngredient(recipeIngredient: recipeIngredient)
                        }
                    }
                }
        
                Button("Add Ingredient") {
                    isIngredientsPickerPresented = true
                }
            }
        }
    }
  
    @ViewBuilder
    private var instructionsSection: some View {
        Section("Instructions") {
            TextField(
        """
        1. Preheat the oven to 475°F (245°C).
        2. Roll out the dough on a floured surface.
        3. ...
        """,
        text: $instructions,
        axis: .vertical
            )
            .lineLimit(8...12)
        }
    }
  
    @ViewBuilder
    private var deleteButton: some View {
        if case .edit(let recipe) = mode {
            Button(
                role: .destructive,
                action: {
                    delete(recipe: recipe)
                },
                label: {
                    Text("Delete Recipe")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            )
        }
    }
  
    // MARK: - Data
    
    private func deleteRecipeIngredient(recipeIngredient: RecipeIngredient) {
        let ingredientId = recipeIngredient.id
        withAnimation {
            recipeIngredients.removeAll(where: { $0.id == ingredientId })
        }
    }
    
    private func delete(recipe: Recipe) {
        guard case .edit(let recipe) = mode else {
            fatalError("Delete unavailable in add mode")
        }
        // Remove all ingredients from recipe object
        recipeIngredients.removeAll()
        do {
            let realm = try Realm()
            
            realm.beginWrite()
            
            // Xóa tất cả RecipeIngredient liên quan đến Recipe
            let recipeIngredientsToDelete = recipe.ingredients
            realm.delete(recipeIngredientsToDelete)
            
            // Xóa Recipe khỏi Category (nếu Recipe thuộc một Category)
            if let category = recipe.category {
                if let index = category.recipes.index(of: recipe) {
                    category.recipes.remove(at: index)
                }
            }
            
            // Xóa Recipe
            realm.delete(recipe)
            
            realm.cancelWrite()
            
        } catch {
            print("Error deleting recipe: \(error.localizedDescription)")
        }
        dismiss()
    }
    
    private func save() {
        do {
            let realm = try Realm()
            
            // Lấy category hiện tại dựa trên danh sách categories
            guard let categories = categories else {
                fatalError("No categories")
            }
            let category = categories.first(where: { $0 == self.category })
            
            try realm.write {
                switch mode {
                case .add:
                    let recipe = Recipe()
                    recipe.id = UUID()  // Tạo ID mới cho recipe
                    recipe.name = name
                    recipe.summary = summary
                    recipe.category = category
                    recipe.serving = serving
                    recipe.time = time
                    recipe.instructions = instructions
                    recipe.imageData = imageData

                    // Thêm ingredients mới vào Recipe
                    for recipeIngredient in recipeIngredients {
                        recipeIngredient.recipe = recipe
                        
                        realm.add(recipeIngredient)
                        recipe.ingredients.append(recipeIngredient)
                        
                        if let ingredient = recipeIngredient.ingredient {
                            ingredient.recipeIngredients.append(recipeIngredient)
                        }
                    }

                    if let category = category {
                        category.recipes.append(recipe)
                    }
                    
                    realm.add(recipe)  // Thêm recipe mới vào Realm
                    

                case .edit(let recipe):
                    // Nếu Category thay đổi, di chuyển Recipe giữa các Category
                    if let oldCategory = recipe.category, let category = category {
                        if oldCategory != category {
                            if let index = oldCategory.recipes.index(of: recipe) {
                                oldCategory.recipes.remove(at: index)
                            }
                            category.recipes.append(recipe)
                        }
                    }
                    
                    // Cập nhật thông tin Recipe
                    recipe.name = name
                    recipe.summary = summary
                    recipe.category = category
                    recipe.serving = serving
                    recipe.time = time
                    recipe.instructions = instructions
                    recipe.imageData = imageData

                    // Xử lý ingredients
                    let currentIngredientIds = Set(recipe.ingredients.map { $0.id })
                    let newIngredientIds = Set(recipeIngredients.map { $0.id })
                    
                    // Xóa các RecipeIngredient không còn tồn tại
                    for recipeIngredient in recipe.ingredients {
                        if !newIngredientIds.contains(recipeIngredient.id) {
                            realm.delete(recipeIngredient)
                        }
                    }
                    
                    // Thêm và cập nhật ingredients
                    for recipeIngredient in recipeIngredients {
                        if !currentIngredientIds.contains(recipeIngredient.id) {
                            // Thêm ingredient mới
                            recipeIngredient.recipe = recipe
                            realm.add(recipeIngredient)
                            recipe.ingredients.append(recipeIngredient)
                        }
                    }
                }
            }
            
            dismiss()
            
        } catch {
            print("Error saving recipe: \(error.localizedDescription)")
        }
    }

//    private func save() {
//        do {
//            let realm = try Realm()
//            
//            // Lấy category hiện tại dựa trên danh sách categories
//            guard let categories = categories else {
//                fatalError("No categories")
//            }
//            let category = categories.first(where: { $0 == self.category })
//            
//            try realm.write {
//                switch mode {
//                case .add:
//                    let recipe = Recipe()
//                    recipe.id = UUID()  // Tạo ID mới cho recipe
//                    recipe.name = name
//                    recipe.summary = summary
//                    recipe.category = category
//                    recipe.serving = serving
//                    recipe.time = time
//                    recipe.instructions = instructions
//                    recipe.imageData = imageData
//                    
//                    // Thêm ingredients mới vào Recipe
//                    for recipeIngredient in recipeIngredients {
//                        // Tạo một RecipeIngredient mới để đảm bảo nó là unmanaged
//                        let newRecipeIngredient = RecipeIngredient()
//                        newRecipeIngredient.id = UUID()
//                        newRecipeIngredient.quantity = recipeIngredient.quantity
//                        newRecipeIngredient.recipe = recipe
//                        
//                        // Liên kết với Ingredient hiện tại
//                        if let ingredient = recipeIngredient.ingredient {
//                            newRecipeIngredient.ingredient = ingredient
//                            ingredient.recipeIngredients.append(newRecipeIngredient)
//                        }
//                        
//                        // Thêm vào Recipe và Realm
//                        recipe.ingredients.append(newRecipeIngredient)
//                        realm.add(newRecipeIngredient)
//                    }
//                    
//                    if let category = category {
//                        category.recipes.append(recipe)
//                    }
//                    
//                    realm.add(recipe)  // Thêm recipe mới vào Realm
//                    
//                case .edit(let recipe):
//                    // Nếu Category thay đổi, di chuyển Recipe giữa các Category
//                    if let oldCategory = recipe.category, let newCategory = category {
//                        if oldCategory != newCategory {
//                            if let index = oldCategory.recipes.index(of: recipe) {
//                                oldCategory.recipes.remove(at: index)
//                            }
//                            newCategory.recipes.append(recipe)
//                        }
//                    }
//                    
//                    // Cập nhật thông tin Recipe
//                    recipe.name = name
//                    recipe.summary = summary
//                    recipe.category = category
//                    recipe.serving = serving
//                    recipe.time = time
//                    recipe.instructions = instructions
//                    recipe.imageData = imageData
//                    
//                    // Xử lý ingredients
//                    let currentIngredientIds = Set(recipe.ingredients.map { $0.id })
//                    let newIngredientIds = Set(recipeIngredients.map { $0.id })
//                    
//                    // Xóa các RecipeIngredient không còn tồn tại
//                    for recipeIngredient in recipe.ingredients {
//                        if !newIngredientIds.contains(recipeIngredient.id) {
//                            // Xóa từ Realm
//                            realm.delete(recipeIngredient)
//                            
////                            // Cập nhật Ingredient liên quan
////                            if let ingredient = recipeIngredient.ingredient {
////                                ingredient.recipeIngredients.removeAll(where: { $0.id == recipeIngredient.id })
////                            }
//                        }
//                    }
//                    
//                    // Thêm và cập nhật ingredients
//                    for recipeIngredient in recipeIngredients {
//                        if !currentIngredientIds.contains(recipeIngredient.id) {
//                            // Thêm ingredient mới
//                            let newRecipeIngredient = RecipeIngredient()
//                            newRecipeIngredient.id = UUID()
//                            newRecipeIngredient.quantity = recipeIngredient.quantity
//                            newRecipeIngredient.recipe = recipe
//                            
//                            if let ingredient = recipeIngredient.ingredient {
//                                newRecipeIngredient.ingredient = ingredient
//                                ingredient.recipeIngredients.append(newRecipeIngredient)
//                            }
//                            
//                            recipe.ingredients.append(newRecipeIngredient)
//                            realm.add(newRecipeIngredient)
//                        } else {
//                            // Cập nhật thông tin RecipeIngredient hiện có
//                            if let existingRecipeIngredient = recipe.ingredients.first(where: { $0.id == recipeIngredient.id }) {
//                                existingRecipeIngredient.quantity = recipeIngredient.quantity
//                                // Nếu cần cập nhật Ingredient liên quan, thêm logic ở đây
//                            }
//                        }
//                    }
//                    
//                    // Không cần thiết phải gán lại recipe.ingredients nếu đã thêm/xóa các RecipeIngredient trên
//                }
//            }
//            
//        } catch {
//            print("Error saving recipe: \(error.localizedDescription)")
//        }
//    }


    
    private func loadCategory() {
        do {
            let realm = try Realm()
            categories = realm
                .objects(Category.self)
                .sorted(byKeyPath: "name", ascending: true)
        } catch {
            print("Error loading categories: \(error.localizedDescription)")
        }
    }
}

//#Preview {
//  RecipeForm(mode: .add)
//}
