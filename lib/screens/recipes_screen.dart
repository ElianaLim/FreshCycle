import 'package:flutter/material.dart';
import '../data/sample_recipes.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';
import 'recipe_detail_screen.dart';
import '../data/db.dart';
import '../models/pantry_item.dart';
import '../services/ai_recipe_service.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _selectedTag = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGenerating = false;

  List<String> get _allTags {
    final tags = <String>{'All'};
    for (final recipe in sampleRecipes) {
      tags.addAll(recipe.tags);
    }
    return tags.toList();
  }

  List<Recipe> get _filteredRecipes {
    var recipes = sampleRecipes;

    // Filter by tag
    if (_selectedTag != 'All') {
      recipes = recipes.where((r) => r.tags.contains(_selectedTag)).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      recipes = recipes.where((r) {
        return r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return recipes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe({required bool expiringOnly}) async {
    setState(() => _isGenerating = true);

    try {
      // 1. Fetch Pantry Items using DB exactly like the Pantry tab does
      final deviceId = await DB.getDeviceId();
      final authUser = DB.getCurrentUser();
      List<Map<String, dynamic>> rows;

      if (authUser != null) {
        rows = await DB.client
            .from('pantry_items')
            .select()
            .eq('user_id', authUser['id'])
            .eq('is_consumed', false)
            .order('expiry_date', ascending: true);
      } else {
        rows = await DB.client
            .from('pantry_items')
            .select()
            .eq('device_id', deviceId)
            .isFilter('user_id', null)
            .eq('is_consumed', false)
            .order('expiry_date', ascending: true);
      }

      List<PantryItem> items = rows.map((r) => PantryItem.fromMap(r)).toList();

      // 2. Filter if the user chose "Expiring Soon" (<= 3 days left)
      if (expiringOnly) {
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        items = items.where((i) {
          final e = DateTime(
            i.computedExpiryDate.year,
            i.computedExpiryDate.month,
            i.computedExpiryDate.day,
          );
          final d = e.difference(today).inDays;
          return d <= 3;
        }).toList();
      }

      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                expiringOnly
                    ? 'No items are expiring soon! Great job.'
                    : 'Your pantry is empty! Add items first.',
              ),
              backgroundColor: FreshCycleTheme.urgencySoon,
            ),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      // 3. Call the Live LLM Service
      final generatedRecipe = await AiRecipeService.generateRecipeFromPantry(
        items,
      );

      if (!mounted) return;

      // 4. Navigate to the detail screen with the real AI recipe
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(recipe: generatedRecipe),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Chef encountered an error: $e'),
            backgroundColor: FreshCycleTheme.urgencyCritical,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }


//       // 3. Simulate an AI network call (Replace this with actual OpenAI/Gemini call later)
//       await Future.delayed(const Duration(seconds: 2));

//       // 4. Create the dynamically generated recipe
//       final itemNames = items.take(4).map((e) => e.name).toList();
//       final mainIngredient = itemNames.first;
//       final title = 'AI Special: $mainIngredient Surprise';

//       final generatedRecipe = Recipe(
//         id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
//         title: title,
//         description: 'An AI-generated recipe to help you save food!\n\n'
//             'Note: This recipe assumes you have basic cooking necessities '
//             '(like cooking oil, sugar, garlic, salt, etc.). If you are missing any of '
//             'these basics, you can easily make a request for them in the Marketplace tab!',
//         imageUrl:
//             'https://img.freepik.com/free-photo/healthy-vegetables-wooden-table_1150-38014.jpg',
//         prepTimeMinutes: 10,
//         cookTimeMinutes: 20,
//         servings: 2,
//         ingredients: [
//           ...items.map((e) => 'From your pantry: ${e.name}'),
//           'Basic necessities (cooking oil, garlic, salt, pepper, sugar to taste)',
//         ],
//         instructions: [
//           'Gather your pantry items: ${itemNames.join(', ')}.',
//           'Prepare the ingredients by washing, peeling, and chopping as necessary.',
//           'Heat a pan over medium heat with a splash of cooking oil and sauté your garlic until fragrant.',
//           'Add your pantry items into the pan. Stir-fry them together until thoroughly cooked.',
//           'Season everything with salt, pepper, and a pinch of sugar to balance the flavors.',
//           'Serve hot and enjoy a delicious meal that prevented food waste!',
//         ],
//         tags: ['AI Generated', 'Zero Waste', 'Quick'],
//         difficulty: 'Easy',
//       );

//       if (!mounted) return;

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => RecipeDetailScreen(recipe: generatedRecipe),
//         ),
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to generate recipe: $e'),
//             backgroundColor: FreshCycleTheme.urgencyCritical,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isGenerating = false);
//       }
//     }
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FreshCycleTheme.surfaceGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Recipes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: FreshCycleTheme.textPrimary,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search recipes...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: FreshCycleTheme.textHint,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: FreshCycleTheme.surfaceGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tags
                    SizedBox(
                      height: 28,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allTags.length,
                        itemBuilder: (context, index) {
                          final tag = _allTags[index];
                          final isSelected = _selectedTag == tag;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTag = tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? FreshCycleTheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? FreshCycleTheme.primary
                                        : FreshCycleTheme.borderColor,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : FreshCycleTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // AI Recipe Generator Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FreshCycleTheme.primaryLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: FreshCycleTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: FreshCycleTheme.primaryDark),
                        SizedBox(width: 8),
                        Text(
                          'AI Chef',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: FreshCycleTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Turn your pantry items into a delicious meal! We assume you have basic necessities like oil, sugar, and garlic. If you\'re missing something, easily make a request in the Marketplace!',
                      style: TextStyle(
                        fontSize: 13,
                        color: FreshCycleTheme.primaryDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _isGenerating
                        ? const Center(
                            child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                                color: FreshCycleTheme.primary),
                          ))
                        : Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _generateRecipe(
                                      expiringOnly: true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: FreshCycleTheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Use Expiring Soon',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _generateRecipe(
                                      expiringOnly: false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: FreshCycleTheme.primary,
                                    side: const BorderSide(
                                        color: FreshCycleTheme.primary),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Use All Items',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),

          if (_filteredRecipes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.restaurant_menu_outlined,
                      size: 64,
                      color: FreshCycleTheme.textHint,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No recipes found',
                      style: TextStyle(
                        fontSize: 16,
                        color: FreshCycleTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedTag = 'All';
                        _searchQuery = '';
                        _searchController.clear();
                      }),
                      child: const Text(
                        'Clear filters',
                        style: TextStyle(color: FreshCycleTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = _filteredRecipes[index];
                    return _RecipeCard(
                      recipe: recipe,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeDetailScreen(
                              recipe: recipe,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _filteredRecipes.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FreshCycleTheme.borderColor,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Container(
                height: 160,
                width: double.infinity,
                color: FreshCycleTheme.primaryLight,
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.restaurant_menu_rounded,
                        size: 48,
                        color: FreshCycleTheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    // Difficulty badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(recipe.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: FreshCycleTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: FreshCycleTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Info row
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: recipe.totalTimeDisplay,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.people_outline_rounded,
                        label: '${recipe.servings} servings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FreshCycleTheme.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: FreshCycleTheme.primaryDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return FreshCycleTheme.urgencySafe;
      case 'Medium':
        return FreshCycleTheme.urgencySoon;
      case 'Hard':
        return FreshCycleTheme.urgencyCritical;
      default:
        return FreshCycleTheme.textSecondary;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: FreshCycleTheme.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: FreshCycleTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}