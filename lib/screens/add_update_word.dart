import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_words/models/word.dart';
import 'package:my_words/services/isar_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AddUpdateWord extends StatefulWidget {
  final IsarService isarService;
  final VoidCallback onSave;
  final Word? wordToEdit;

  const AddUpdateWord(
      {super.key,
      required this.isarService,
      required this.onSave,
      this.wordToEdit});

  @override
  State<AddUpdateWord> createState() => _AddUpdateWordState();
}

class _AddUpdateWordState extends State<AddUpdateWord> {
  final _formKey = GlobalKey<FormState>();
  final _englishController = TextEditingController();
  final _turkishController = TextEditingController();
  final _storyController = TextEditingController();
  String _selectedWordType = "Noun";
  bool _isLearned = false;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  List<String> wordTypes = [
    "Noun",
    "Adjective",
    "Verb",
    "Adverb",
    "Phrasal Verb",
    "Idiom"
  ];

  @override
  void initState() {
    if (widget.wordToEdit != null) {
      var updatedWord = widget.wordToEdit;
      _englishController.text = updatedWord!.englishWord;
      _turkishController.text = updatedWord.turkishWord;
      _storyController.text = updatedWord.story!;
      _selectedWordType = updatedWord.wordType;
      _isLearned = updatedWord.isLearned;
    }
    super.initState();
  }

  @override
  void dispose() {
    _englishController.dispose();
    _turkishController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      var _englisWord = _englishController.text;
      var _turkishWord = _turkishController.text;
      var _story = _storyController.text;
      var word = Word(
          englishWord: _englisWord,
          turkishWord: _turkishWord,
          wordType: _selectedWordType,
          story: _story,
          isLearned: _isLearned,
      );
      if (widget.wordToEdit == null) {
        word.imageBytes = _imageFile != null ? await _imageFile!.readAsBytes() : null;
        await widget.isarService.saveWord(word);
      } else {
        word.id = widget.wordToEdit!.id;
        word.imageBytes = _imageFile != null ? await _imageFile!.readAsBytes() : widget.wordToEdit?.imageBytes;
        await widget.isarService.updateWord(word);
      }

      widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter English Word";
                  }
                  return null;
                },
                controller: _englishController,
                decoration: InputDecoration(
                  labelText: "English Word",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter Turkish Word";
                  }
                  return null;
                },
                controller: _turkishController,
                decoration: InputDecoration(
                  labelText: "Turkish Word",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Word Type",
                ),
                value: _selectedWordType,
                items: wordTypes.map(
                  (e) {
                    return DropdownMenuItem(
                      child: Text(e),
                      value: e,
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWordType = value!;
                  });
                },
              ),
              SizedBox(
                height: 20,
              ),
              TextFormField(
                controller: _storyController,
                decoration: InputDecoration(
                  labelText: "Story of Word",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(
                height: 17,
              ),
              Row(
                children: [
                  Text(
                    "Learned",
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: _isLearned,
                    onChanged: (value) {
                      setState(() {
                        _isLearned = !_isLearned;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 17,
              ),
              ElevatedButton.icon(
                onPressed: _selectImage,
                label: Text(
                  "Add Image",
                  style: TextStyle(fontSize: 16),
                ),
                icon: Icon(Icons.image),
              ),
              SizedBox(
                height: 8,
              ),
              if (_imageFile != null ||
                  widget.wordToEdit?.imageBytes != null) ...[
                if (_imageFile != null)
                  Image.file(
                    _imageFile!,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                else if (widget.wordToEdit?.imageBytes != null)
                  Image.memory(
                    Uint8List.fromList(widget.wordToEdit!.imageBytes!),
                    height: 150,
                    fit: BoxFit.cover,
                  ),
              ],
              SizedBox(
                height: 8,
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: _saveWord,
                  child: widget.wordToEdit == null
                      ? const Text(
                          "Save Word",
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        )
                      : Text(
                          "Update Word",
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        )),
            ],
          )),
    );
  }
}
