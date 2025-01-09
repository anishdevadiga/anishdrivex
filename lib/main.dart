import 'dart:html';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drive X',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: const DocumentUploadPage(),
    );
  }
}

class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({Key? key}) : super(key: key);

  @override
  _DocumentUploadPageState createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  File? uploadedFile;
  String? fileName;
  List<List<dynamic>>? extractedContent;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _fileLinkController = TextEditingController();
  String? answer;
  bool _isProcessing = false;

  String selectedOption = 'Upload File';

  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: "AIzaSyAKq7w0HBOHhPtdKd07lfoEIJOLg278QbA",
  );

  void _uploadFile(File file) {
    setState(() {
      uploadedFile = file;
      fileName = file.name;
      extractedContent = null;
    });

    final reader = FileReader();
    reader.onLoadEnd.listen((event) {
      final bytes = reader.result as Uint8List;
      final excel = Excel.decodeBytes(bytes);
      List<List<dynamic>> content = [];

      for (var table in excel.tables.keys) {
        for (var row in excel.tables[table]!.rows) {
          content.add(row.map((cell) => cell?.value ?? '').toList());
        }
      }

      setState(() {
        extractedContent = content;
      });
    });

    reader.readAsArrayBuffer(file);
  }

  void _removeFile() {
    setState(() {
      uploadedFile = null;
      fileName = null;
      extractedContent = null;
    });
  }

  Future<void> _fetchFileFromLink(String fileLink) async {
    try {
      final regex = RegExp(r'\/d\/(.+?)\/');
      final match = regex.firstMatch(fileLink);

      if (match == null) {
        throw 'Invalid Google Drive link. Please ensure it contains a valid file ID.';
      }

      final fileId = match.group(1);
      final downloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId';

      final request = HttpRequest();
      request.open('GET', downloadUrl);
      request.responseType = 'arraybuffer';
      request.send();

      await request.onLoadEnd.first;

      if (request.status == 200) {
        final bytes = request.response as ByteBuffer;
        final excel = Excel.decodeBytes(Uint8List.view(bytes));
        List<List<dynamic>> content = [];

        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows) {
            content.add(row.map((cell) => cell?.value ?? '').toList());
          }
        }

        setState(() {
          extractedContent = content;
          fileName = 'Fetched File';
        });
      } else {
        throw 'Failed to fetch the file from the provided link. Status: ${request.status}';
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _askQuestion() async {
    if (extractedContent == null || _questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a file or provide a valid link and ask a question.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      answer = null;
    });

    try {
      final contentString = extractedContent!.map((row) => row.join(', ')).join('\n');
      final content = [
        Content.text(
            'Using the following data from the uploaded file:\n\n$contentString\n\nQuestion: ${_questionController.text}\nAnswer:'),
      ];
      final response = await model.generateContent(content);
      setState(() {
        answer = response?.text ?? 'No answer generated.';
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive X',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Select Input Method:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: selectedOption,
                    items: <String>['Upload File', 'Paste Google Link']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedOption = newValue!;
                        uploadedFile = null;
                        fileName = null;
                        extractedContent = null;
                        _fileLinkController.clear();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (selectedOption == 'Upload File') ...[
                if (uploadedFile == null) ...[
                  ElevatedButton(
                    onPressed: () {
                      FileUploadInputElement uploadInput = FileUploadInputElement();
                      uploadInput.accept = '.xlsx';
                      uploadInput.click();
                      uploadInput.onChange.listen((event) {
                        final file = uploadInput.files!.first;
                        _uploadFile(file);
                      });
                    },
                    child: const Text('Upload Excel File'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('File: $fileName', style: const TextStyle(fontSize: 16)),
                          IconButton(
                            onPressed: _removeFile,
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (extractedContent != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'File Content:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columns: List.generate(
                                extractedContent!.isNotEmpty
                                    ? extractedContent![0].length
                                    : 0,
                                    (index) => DataColumn(
                                  label: Text('Column ${index + 1}'),
                                ),
                              ),
                              rows: extractedContent!
                                  .map(
                                    (row) {
                                  while (row.length < extractedContent![0].length) {
                                    row.add('');
                                  }
                                  return DataRow(
                                    cells: row
                                        .map(
                                          (cell) => DataCell(Text(cell.toString())),
                                    )
                                        .toList(),
                                  );
                                },
                              )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ] else if (selectedOption == 'Paste Google Link') ...[
                TextField(
                  controller: _fileLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Google Drive Link',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _fetchFileFromLink(_fileLinkController.text),
                  child: const Text('Fetch File from Link'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Ask a Question',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : _askQuestion,
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : const Text('Get Answer'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (answer != null)
                Text(
                  'Answer: $answer',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


