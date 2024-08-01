//
//  Models.swift
//  SwiftBites
//
//  Created by Nguyen Thanh Long on 25/7/24.
//

import Foundation
import SwiftData

@Model final class Category {
  @Attribute(.unique) 
  var id = UUID()
  @Attribute(.unique)
  var name: String
  @Relationship(deleteRule: .nullify, inverse: \Recipe.category)
  var recipes: [Recipe]
  
  init(name: String = "", recipes: [Recipe] = []) {
    self.name = name
    self.recipes = recipes
  }
}

@Model final class Ingredient {
  @Attribute(.unique) 
  var id = UUID()
  @Attribute(.unique)
  var name: String
  @Relationship(deleteRule: .nullify)
  var recipeIngredients: [RecipeIngredient]?
  
  init(name: String) {
    self.name = name
  }
}

@Model final class RecipeIngredient {
  @Attribute(.unique) 
  var id = UUID()
  @Relationship(inverse: \Ingredient.recipeIngredients)
  var ingredient: Ingredient
  var quantity: String
  @Relationship(inverse: \Recipe.ingredients)
  var recipe: Recipe?
  
  init(ingredient: Ingredient, quantity: String) {
    self.ingredient = ingredient
    self.quantity = quantity
  }
}

@Model final class Recipe {
  @Attribute(.unique) 
  var id = UUID()
  @Attribute(.unique)
  var name: String
  var summary: String
  @Relationship
  var category: Category?
  var serving: Int
  var time: Int
  @Relationship(deleteRule: .cascade)
  var ingredients: [RecipeIngredient]
  var instructions: String
  @Attribute(.externalStorage) 
  var imageData: Data?
  
  init(
    name: String = "",
    summary: String = "",
    category: Category? = nil,
    serving: Int = 1,
    time: Int = 5,
    ingredients: [RecipeIngredient] = [],
    instructions: String = "",
    imageData: Data? = nil
  ) {
    self.name = name
    self.summary = summary
    self.category = category
    self.serving = serving
    self.time = time
    self.ingredients = ingredients
    self.instructions = instructions
    self.imageData = imageData
  }
}
