import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'Qj0H4lrFRXi8LpDBN9MPeNu3vR9RodugYoUXHoyY';
  const keyClientKey = 'it9xjF7nRPmGiKF6tgDExHjQvcCQLhLwkgF29iaC';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(
    keyApplicationId,
    keyParseServerUrl,
    clientKey: keyClientKey,
    autoSendSessionId: true,
    debug: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home:LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final user = ParseUser(username, password, null);
    final response = await user.login();

    setState(() => _loading = false);

    if (response.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RecipeHome()),
      );
    } else {
      setState(() {
        _errorMessage = response.error?.message ?? 'Login failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar title here, as requested
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
            ),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
                      SizedBox(height: 20),
                      Text(
                        'Recipe App',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Login',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      SizedBox(height: 12),
                      if (_errorMessage != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_loading,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Enter username' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_loading,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Enter password' : null,
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Login', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class Recipe {
  String id;
  String title;
  String description;
  List<String> steps;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
  });

  factory Recipe.fromParse(ParseObject obj) {
    return Recipe(
      id: obj.objectId ?? '',
      title: obj.get<String>('title') ?? '',
      description: obj.get<String>('description') ?? '',
      steps: List<String>.from(obj.get<List<dynamic>>('steps') ?? []),
    );
  }

  ParseObject toParseObject() {
    final obj = ParseObject('Recipe');
    if (id.isNotEmpty) obj.objectId = id;
    obj.set<String>('title', title);
    obj.set<String>('description', description);
    obj.set<List<String>>('steps', steps);
    return obj;
  }
}

class RecipeHome extends StatefulWidget {
  @override
  _RecipeHomeState createState() => _RecipeHomeState();
}

class _RecipeHomeState extends State<RecipeHome> {
  List<Recipe> recipes = [];

  @override
  void initState() {
    super.initState();
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    final query = QueryBuilder(ParseObject('Recipe'));
    final response = await query.query();

    if (response.success && response.results != null) {
      setState(() {
        recipes = response.results!.map((obj) => Recipe.fromParse(obj)).toList();
      });
    } else {
      print('Failed to load recipes: ${response.error?.message}');
    }
  }

  Future<void> _deleteRecipe(String id) async {
    setState(() {
      recipes.removeWhere((r) => r.id == id);
    });

    final obj = ParseObject('Recipe')..objectId = id;
    final response = await obj.delete();

    if (!response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recipe: ${response.error?.message}')),
      );
      await loadRecipes();
    }
  }

  void _showRecipeDialog({Recipe? recipe}) {
    final titleController = TextEditingController(text: recipe?.title ?? '');
    final descController = TextEditingController(text: recipe?.description ?? '');
    final stepsController = TextEditingController(
      text: recipe != null ? recipe.steps.join('\n') : '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(recipe == null ? 'Add Recipe' : 'Edit Recipe'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
              TextField(
                controller: stepsController,
                decoration: InputDecoration(labelText: 'Steps (one per line)'),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            child: Text(recipe == null ? 'Add' : 'Update'),
            onPressed: () async {
              final newRecipe = Recipe(
                id: recipe?.id ?? '',
                title: titleController.text.trim(),
                description: descController.text.trim(),
                steps: stepsController.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
              );
              final parseObj = newRecipe.toParseObject();
              await parseObj.save();

              Navigator.pop(context);
              await loadRecipes();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user != null) {
      await user.logout();
      // Return to login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: recipes.isEmpty
          ? Center(child: Text('No recipes. Tap + to add one.'))
          : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (_, index) {
                final recipe = recipes[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(recipe.title),
                    subtitle: Text(recipe.description),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: recipe.steps
                              .asMap()
                              .entries
                              .map((e) => Text('${e.key + 1}. ${e.value}'))
                              .toList(),
                        ),
                      ),
                      ButtonBar(
                        children: [
                          TextButton(onPressed: () => _showRecipeDialog(recipe: recipe), child: Text('Edit')),
                          TextButton(onPressed: () => _deleteRecipe(recipe.id), child: Text('Delete')),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showRecipeDialog(),
      ),
    );
  }
}
