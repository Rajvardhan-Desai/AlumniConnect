import 'package:alumniconnect/Widgets/snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/dom.dart' as dom; // Importing dom for Element
import '../providers/user_provider.dart';

class FirebaseService {
  final DatabaseReference _newsRef =
      FirebaseDatabase.instance.ref().child('news');

  Stream<List<Map<String, dynamic>>> getNewsStream() {
    return _newsRef.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.isNotEmpty) {
        return data.entries.map((e) {
          return {
            'id': e.key,
            'title': e.value['title'] ?? 'No title',
            'subtitle': e.value['subtitle'] ?? '',
            'body': e.value['body'] ?? '',
            'date': e.value['date'] ?? '',
            'image': e.value['image'] ?? '',
            'createdOn': e.value['createdOn'] ?? '',
          };
        }).toList();
      } else {
        return [];
      }
    });
  }

  Future<void> postNews(Map<String, dynamic> newNews) async {
    await _newsRef.push().set(newNews);
  }

  Future<void> updateNews(
      String newsId, Map<String, dynamic> updatedNews) async {
    await _newsRef.child(newsId).set(updatedNews);
  }

  Future<void> deleteNews(String newsId) async {
    await _newsRef.child(newsId).remove();
  }
}

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  NewsPageState createState() => NewsPageState();
}

class NewsPageState extends ConsumerState<NewsPage> {
  final DatabaseReference _newsRef =
      FirebaseDatabase.instance.ref().child('news');
  List<Map<String, dynamic>> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  void _fetchNews() {
    try {
      _newsRef.onValue.listen((event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null && data.isNotEmpty) {
          setState(() {
            _newsList = data.entries.map((e) {
              return {
                'id': e.key,
                'title': e.value['title'] ?? 'No title',
                'subtitle': e.value['subtitle'] ?? '',
                'body': e.value['body'] ?? '',
                'date': e.value['date'] ?? '',
                'image': e.value['image'] ?? '',
                'createdOn': e.value['createdOn'] ??
                    '', // Make sure to include this field
              };
            }).toList();

            // Sort by createdOn in descending order
            _newsList.sort((a, b) {
              DateTime dateA =
                  DateTime.tryParse(a['createdOn']) ?? DateTime.now();
              DateTime dateB =
                  DateTime.tryParse(b['createdOn']) ?? DateTime.now();
              return dateB.compareTo(dateA); // Newest first
            });

            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _newsList = [];
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching news: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.read(userProvider);
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _newsList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.newspaper,
                        size: 100,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No News Available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Stay tuned for updates!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _fetchNews();
                  },
                  child: ListView.builder(
                    itemCount: _newsList.length,
                    itemBuilder: (context, index) {
                      final news = _newsList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: news['image'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    news['image'],
                                    width: 70,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    width: 70,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.newspaper,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                          title: Text(news['title']),
                          subtitle: news['subtitle'].isNotEmpty
                              ? Text(
                                  '${news['subtitle']}\n${_formatDate(news['date'])}')
                              : Text(_formatDate(news['date'])),
                          isThreeLine: news['subtitle'].isNotEmpty,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NewsDetailPage(news: news),
                              ),
                            );
                            if (result == true) {
                              _fetchNews();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: userState.role == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewsPostForm(),
                  ),
                );
                if (result == true) {
                  _fetchNews();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yMMMd').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class NewsPostForm extends StatefulWidget {
  final Map<String, dynamic>? news;
  final bool isEditing;

  const NewsPostForm({super.key, this.news, this.isEditing = false});

  @override
  NewsPostFormState createState() => NewsPostFormState();
}

class NewsPostFormState extends State<NewsPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final HtmlEditorController _bodyController = HtmlEditorController();
  DateTime _date = DateTime.now();
  String? _image;
  bool _isUploading = false;
  bool _isPosting = false;
  final DatabaseReference _newsRef =
      FirebaseDatabase.instance.ref().child('news');

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.news != null) {
      _populateFields();
    } else {
      _titleController.text = '';
      _subtitleController.text = '';
      _image = null;
      _date = DateTime.now();
    }

    // Inject JavaScript to change Enter key behavior after a short delay
    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        await _bodyController.editorController?.evaluateJavascript(
          source: '''
          document.addEventListener('DOMContentLoaded', function() {
            document.querySelector('.note-editable').addEventListener('keydown', function(event) {
              if (event.key === 'Enter') {
                event.preventDefault();
                document.execCommand('insertHTML', false, '<br><br>');
              }
            });
          });
        ''',
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to customize Enter key behavior: $e');
        }
      }
    });
  }



  void _populateFields() {
    if (widget.news != null) {
      _titleController.text = widget.news!['title'] ?? '';
      _subtitleController.text = widget.news!['subtitle'] ?? '';
      _date = widget.news!['date'] != null
          ? DateTime.parse(widget.news!['date'])
          : DateTime.now();
      _image = widget.news!['image'];

      Future.delayed(const Duration(milliseconds: 300), () async {
        try {
          await _bodyController.editorController?.evaluateJavascript(
            source: "document.readyState == 'complete';",
          );
          _bodyController.setText(widget.news!['body'] ?? '');
        } catch (e) {
          if (kDebugMode) {
            print('Editor is not ready yet. Please wait: $e');
          }
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });
        final file = File(pickedFile.path);
        final fileName = '${const Uuid().v4()}.png';
        final storageRef =
            FirebaseStorage.instance.ref().child('news/$fileName');

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();
        setState(() {
          _image = downloadUrl;
        });
      }
    } catch (e) {
      showSnackBar(
          scaffoldMessenger, "Failed to upload image: $e", Colors.redAccent);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  void _postNews() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isPosting = true;
      });

      String? bodyText = await _bodyController.getText();
      if (bodyText.isEmpty) {
        showSnackBar(
            scaffoldMessenger, "Please enter the news body", Colors.redAccent);
        setState(() {
          _isPosting = false;
        });
        return;
      }

      final newNews = {
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'body': bodyText,
        'date': DateFormat('y-MM-dd').format(_date),
        'image': _image ?? '',
        'createdOn': DateTime.now().toString(),
      };

      try {
        if (widget.isEditing && widget.news != null) {
          await _newsRef.child(widget.news!['id']).set(newNews);
          showSnackBar(
              scaffoldMessenger, "News updated successfully", Colors.green);
        } else {
          await _newsRef.push().set(newNews);
          showSnackBar(
              scaffoldMessenger, "News posted successfully", Colors.green);
        }

        // Pop the screen and pass `true` to indicate success
        if (mounted) Navigator.pop(context, true);
      } catch (error) {
        showSnackBar(
            scaffoldMessenger, "Failed to post news: $error", Colors.redAccent);
      } finally {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit News' : 'Post News',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Date: ${DateFormat('yMMMd').format(_date)}'),
                leading: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Subtitle (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    if (_isUploading)
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      )
                    else if (_image != null &&
                        _image!.isNotEmpty) // Add this check
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          _image!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Tap to add an image (optional)',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    if (_image != null && _image!.isNotEmpty) // Add this check
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300, // You can adjust this height as needed
                child: HtmlEditor(
                  controller: _bodyController,
                  htmlEditorOptions: HtmlEditorOptions(
                    hint: 'Enter news content here...',
                    initialText:
                        widget.news != null ? widget.news!['body'] ?? '' : '',
                  ),
                  htmlToolbarOptions: const HtmlToolbarOptions(
                    toolbarType: ToolbarType.nativeExpandable,
                    toolbarPosition: ToolbarPosition.aboveEditor,
                    defaultToolbarButtons: [
                      FontButtons(
                        bold: true,
                        italic: true,
                        underline: true,
                        clearAll: false,
                        strikethrough: false,
                        superscript: false,
                        subscript: false,
                      ),
                      InsertButtons(
                        link: true,
                        picture: false,
                        audio: false,
                        video: false,
                        otherFile: false,
                        table: true,
                        hr: true,
                      ),
                      FontSettingButtons(
                        fontName: false,
                        fontSize: false,
                        fontSizeUnit: false,
                      ),
                      ListButtons(
                        ul: true,
                        ol: true,
                        listStyles: false,
                      ),
                      ParagraphButtons(
                        alignLeft: true,
                        alignCenter: true,
                        alignRight: true,
                        alignJustify: true,
                        increaseIndent: true,
                        decreaseIndent: true,
                        textDirection: false,
                        lineHeight: true,
                        caseConverter: false,
                      ),
                      ColorButtons(
                        foregroundColor: true,
                        highlightColor: true,
                      ),
                      OtherButtons(
                        fullscreen: true,
                        codeview: true,
                        undo: true,
                        redo: true,
                        help: false,
                        copy: true,
                        paste: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isPosting ? null : _postNews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffa57eff),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isPosting
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        widget.isEditing ? 'Update News' : 'Post News',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsDetailPage extends ConsumerWidget {
  final Map<String, dynamic> news;

  const NewsDetailPage({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState =
        ref.watch(userProvider); // Access user state from provider
    final navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          news['title'],
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis),
        ),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Show edit and delete buttons only if the user is an admin
          if (userState.role == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NewsPostForm(news: news, isEditing: true),
                  ),
                );
                if (result == true) {
                  navigator.pop();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _deleteNews(context);
              },
            ),
          ]
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news['image'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 200.0,
                    child: Image.network(
                      news['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                news['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (news['subtitle'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  news['subtitle'],
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                DateFormat('yMMMd').format(DateTime.parse(news['date'])),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Html(
                data: news['body'],
                style: {
                  "body": Style(fontSize: FontSize(16.0),lineHeight:const LineHeight(0)),
                },
                onLinkTap: (String? url, Map<String, String> attributes,
                    dom.Element? element) {
                  _launchUrl(context, url);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNews(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final DatabaseReference newsRef =
        FirebaseDatabase.instance.ref().child('news').child(news['id']);

    try {
      await newsRef.remove();
      showSnackBar(
          scaffoldMessenger, "News deleted successfully", Colors.green);
      navigator.pop(); // Use navigator here
    } catch (error) {
      showSnackBar(
          scaffoldMessenger, "Failed to delete news: $error", Colors.redAccent);
    }
  }

  Future<void> _launchUrl(BuildContext context, String? url) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (url == null || url.isEmpty) {
      _showError(scaffoldMessenger, 'The link is not available.');
      return;
    }

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError(scaffoldMessenger, 'No application can handle this link.');
      }
    } catch (error) {
      _showError(scaffoldMessenger,
          'Could not launch the link. Please check your settings.');
    }
  }

  void _showError(ScaffoldMessengerState context, String message) {
    showSnackBar(context, message, Colors.redAccent);
  }
}
