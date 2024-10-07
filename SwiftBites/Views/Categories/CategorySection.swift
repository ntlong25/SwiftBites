import SwiftUI

struct CategorySection: View {
  let category: Category

  // MARK: - Body

  var body: some View {
    Section(
      content: {
        if category.recipes.isEmpty {
          empty
        } else {
          list
        }
      },
      header: {
        HStack(alignment: .center) {
          Text(category.name)
            .font(.title)
            .bold()
          Spacer()
          NavigationLink("Edit", value: CategoryForm.Mode.edit(category))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
      }
    )
  }

  // MARK: - Views

  var list: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 0) {
        ForEach(category.recipes, id: \.name) { recipe in
          RecipeCell(recipe: recipe)
            .containerRelativeFrame(.horizontal, count: 12, span: 11, spacing: 0)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.viewAligned)
    .scrollIndicators(.hidden)
  }

  var empty: some View {
    ContentUnavailableView(
      label: {
        Label("No Recipes", systemImage: "list.clipboard")
      },
      description: {
        Text("Recipes you add will appear here.")
      },
      actions: {
        NavigationLink("Add Recipe", value: RecipeForm.Mode.add)
          .buttonBorderShape(.roundedRectangle)
          .buttonStyle(.bordered)
      }
    )
  }
}

//#Preview {
//  let margherita = Recipe(
//    name: "Classic Margherita Pizza",
//    summary: "A simple yet delicious pizza with tomato, mozzarella, basil, and olive oil.",
//    category: Category(name: "Italian"),
//    serving: 4,
//    time: 50,
//    ingredients: [
//      RecipeIngredient(ingredient: Ingredient(name: "Pizza Dough"), quantity: "1 ball"),
//      RecipeIngredient(ingredient: Ingredient(name: "Tomato Sauce"), quantity: "1/2 cup"),
//    ],
//    instructions: "Preheat oven, roll out dough, apply sauce, add cheese and basil, bake for 20 minutes.",
//    imageData: UIImage(named: "margherita")?.pngData()
//  )
//  CategorySection(category: Category(name: "Italian", recipes: [margherita]))
//}
