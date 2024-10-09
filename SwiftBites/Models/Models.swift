//
//  Models.swift
//  SwiftBites
//
//  Created by Nguyen Thanh Long on 25/7/24.
//

import Foundation
import RealmSwift


// Category Model
class Category: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var name: String
    @Persisted var recipes: List<Recipe> // Liệt kê các Recipe thuộc Category
    
    override class func primaryKey() -> String? {
        "id"
    }
}

// Recipe Model
class Recipe: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var name: String
    @Persisted var summary: String
    @Persisted var category: Category?
    @Persisted var serving: Int
    @Persisted var time: Int
    @Persisted var ingredients: List<RecipeIngredient> // Danh sách RecipeIngredient
    @Persisted var instructions: String
    @Persisted var imageData: Data?
    
    override class func primaryKey() -> String? {
        "id"
    }
}

// RecipeIngredient Model
class RecipeIngredient: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var quantity: String
    @Persisted var ingredient: Ingredient? // Mối quan hệ với Ingredient
    @Persisted var recipe: Recipe? // Mối quan hệ với Recipe
    
    override class func primaryKey() -> String? {
        "id"
    }
}

// Ingredient Model
class Ingredient: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var name: String
    @Persisted var recipeIngredients: List<RecipeIngredient> // Liên kết nhiều-nhiều
    
    override class func primaryKey() -> String? {
        "id"
    }
}
