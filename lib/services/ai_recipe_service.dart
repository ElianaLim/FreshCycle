import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recipe.dart';
import '../models/pantry_item.dart';

class AiRecipeService {
  static Future<Recipe> generateRecipeFromPantry(List<PantryItem> items) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API key not found in .env file');
    }

    // We use gemini-1.5-flash as it is fast and perfect for text generation
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      // Force the model to return JSON so we can parse it easily
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final itemNames = items.map((e) => e.name).join(', ');

    final prompt = '''
      You are an expert chef. Create a delicious recipe using some or all of these ingredients: $itemNames.
      You can assume the user has basic cooking necessities like oil, salt, pepper, sugar, garlic, and water if they do not have so, recommend for them to make a request in the Marketplace tap in the app.
      
      Respond strictly in the following JSON format, do not italicize or bold any text:
      {
        "title": "Recipe Name",
        "description": "A short, appetizing description. Mention that missing basic ingredients can be requested in the Marketplace.",
        "prepTimeMinutes": 10,
        "cookTimeMinutes": 20,
        "servings": 2,
        "ingredients": ["1 cup ingredient name", "Basic necessities (oil, salt)"],
        "instructions": ["Step 1", "Step 2"],
        "tags": ["Quick", "Zero Waste"],
        "difficulty": "Easy" // Must be "Easy", "Medium", or "Hard"
      }
    ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final String responseText = response.text ?? '{}';
      
      final Map<String, dynamic> jsonMap = jsonDecode(responseText);

      return Recipe(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        title: jsonMap['title'] ?? 'AI Surprise',
        description: jsonMap['description'] ?? 'A delicious AI-generated meal.',
        // Use a placeholder image or a generic food image URL
        imageUrl: 'https://images.unsplash.com/photo-1495521821757-a1efb6729352?q=80&w=800&auto=format&fit=crop',
        prepTimeMinutes: jsonMap['prepTimeMinutes'] ?? 10,
        cookTimeMinutes: jsonMap['cookTimeMinutes'] ?? 20,
        servings: jsonMap['servings'] ?? 2,
        ingredients: List<String>.from(jsonMap['ingredients'] ?? []),
        instructions: List<String>.from(jsonMap['instructions'] ?? []),
        tags: List<String>.from(jsonMap['tags'] ?? ['AI Generated']),
        difficulty: jsonMap['difficulty'] ?? 'Medium',
      );
    } catch (e) {
      throw Exception('Failed to communicate with AI Chef: $e');
    }
  }
}