import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_words/models/word.dart';
import 'package:my_words/services/isar_service.dart';

class WordList extends StatefulWidget {
  final IsarService isarService;
  final Function(Word) onEditWord;

  const WordList({super.key, required this.isarService, required this.onEditWord});

  @override
  State<WordList> createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late Future<List<Word>> _getAllWords;
  List<Word> _kelimeler = [];
  List<Word> _filtrelenmisKelimeler = [];
  List<String> wordTypes = [
    "All",
    "Noun",
    "Adjective",
    "Verb",
    "Adverb",
    "Phrasal Verb",
    "Idiom"
  ];
  String _selectedWordType = "All";
  bool _isLearned = false;

  _applyFilter() {
    _filtrelenmisKelimeler = List.from(_kelimeler);

    if (_selectedWordType != "All") {
      _filtrelenmisKelimeler = _filtrelenmisKelimeler
          .where((element) =>
              element.wordType.toLowerCase() == _selectedWordType.toLowerCase())
          .toList();
    }
    if (_isLearned) {
      _filtrelenmisKelimeler = _filtrelenmisKelimeler
          .where(
            (element) => element.isLearned != _isLearned,
          )
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _getAllWords = _getWordFromDB();
  }

  Widget _buildFilterCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt_rounded),
                SizedBox(
                  width: 8,
                ),
                Text(
                  "Filter",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  width: 12,
                ),
                Expanded(
                    child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Word Type",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedWordType,
                  items: wordTypes
                      .map(
                        (e) => DropdownMenuItem(
                          child: Text(e),
                          value: e,
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWordType = value!;
                      _applyFilter();
                    });
                  },
                )),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Hide what I learned"),
                Switch(
                  value: _isLearned,
                  onChanged: (value) {
                    setState(() {
                      _isLearned = !_isLearned;
                      _applyFilter();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Word>> _getWordFromDB() async {
    var wordFromDB = await widget.isarService.getAllWords();
    _kelimeler = wordFromDB;
    return wordFromDB;
  }

  void _refreshWords() {
    setState(() {
      _getAllWords = _getWordFromDB();
    });
  }

  void _toggleUpdateWord(Word nowKelime) async {
    await widget.isarService.toggleWordLearned(nowKelime.id);
    final index =
        _kelimeler.indexWhere((_element) => _element.id == nowKelime.id);
    var degistirilecekKelime = _kelimeler[index];
    degistirilecekKelime.isLearned = !degistirilecekKelime.isLearned;
    _kelimeler[index] = degistirilecekKelime;
    setState(() {});
  }

  void _deleteWord(Word deletedWord) async {
    await widget.isarService.deleteWord(deletedWord.id);
    _kelimeler.removeWhere(
      (element) => element.id == deletedWord.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterCard(),
        Expanded(
            child: FutureBuilder<List<Word>>(
          future: _getAllWords,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Hata var ${snapshot.error.toString()}"),
              );
            }
            if (snapshot.hasData) {
              return snapshot.data?.length == 0
                  ? Center(
                      child: Text("Please add words", style: TextStyle(fontSize: 17),),
                    )
                  : _buildListView(snapshot.data!);
            } else {
              return SizedBox();
            }
          },
        ))
      ],
    );
  }

  _buildListView(List<Word> data) {
    _applyFilter();
    return ListView.builder(
      itemBuilder: (context, index) {
        var nowKelime = _filtrelenmisKelimeler[index];
        return Dismissible(
          key: UniqueKey(),
          background: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => _deleteWord(nowKelime),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Delete Word"),
                  content: Text("Are you sure you want to delete the word?"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text("No")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: Text("Yes")),
                  ],
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: () => widget.onEditWord(nowKelime),
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(nowKelime.englishWord),
                        subtitle: Text(nowKelime.turkishWord),
                        leading: Chip(label: Text(nowKelime.wordType)),
                        trailing: Switch(
                          value: nowKelime.isLearned,
                          onChanged: (value) => _toggleUpdateWord(nowKelime),
                        ),
                      ),
                      if (nowKelime.story != null && nowKelime.story!.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    "Reminder Note",
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 6,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  nowKelime.story ?? "",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (nowKelime.imageBytes != null)
                        Image.memory(
                          Uint8List.fromList(nowKelime.imageBytes!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      itemCount: _filtrelenmisKelimeler.length,
    );
  }
}
