class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String difficulty;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    required this.difficulty,
  });

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  String get totalTimeDisplay {
    final hours = totalTimeMinutes ~/ 60;
    final minutes = totalTimeMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  String get prepTimeDisplay {
    final hours = prepTimeMinutes ~/ 60;
    final minutes = prepTimeMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  String get cookTimeDisplay {
    final hours = cookTimeMinutes ~/ 60;
    final minutes = cookTimeMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}