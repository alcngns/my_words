import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:my_words/models/word.dart';
import 'package:my_words/screens/add_update_word.dart';
import 'package:my_words/screens/word_list.dart';
import 'package:my_words/services/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isarService = IsarService();
  try {
    await isarService.init();
  } catch (e) {
    debugPrint("Main dartda isar service başlatılamadı $e");
  }

  runApp(MyApp(
    isarService: isarService,
  ));
}

class MyApp extends StatelessWidget {
  final IsarService isarService;

  const MyApp({super.key, required this.isarService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Words',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'My Words',
        isarService: isarService,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final IsarService isarService;

  const MyHomePage({super.key, required this.title, required this.isarService});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedScreen = 0;
  Word? _wordToEdit;

  void _editWord(Word updatedWord) {
    setState(() {
      _selectedScreen = 1;
      _wordToEdit = updatedWord;
    });
  }

  List<Widget> getScreens() {
    return [
      WordList(
        isarService: widget.isarService,
        onEditWord: _editWord,
      ),
      AddUpdateWord(
          isarService: widget.isarService,
          wordToEdit: _wordToEdit,
          onSave: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Word saved"),
              ),
            );
            setState(() {
              _selectedScreen = 0;
              _wordToEdit = null;
            });
          }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: getScreens()[_selectedScreen],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedScreen,
        destinations: [
          NavigationDestination(icon: Icon(Icons.list_alt), label: "Words"),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline_outlined),
              label: _wordToEdit == null ? "Add" : "Update"),
        ],
        onDestinationSelected: (value) {
          setState(() {
            _selectedScreen = value;
            _wordToEdit = null;
          });
        },
      ),
    );
  }
}
