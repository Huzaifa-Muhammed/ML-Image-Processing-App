import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Classification',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyImageClassificationScreen(),
    );
  }
}

class MyImageClassificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Classification'),
      ),
      body: Center(
        child: TfliteModel(), // Add the TfliteModel widget here
      ),
    );
  }
}

class TfliteModel extends StatefulWidget {
  const TfliteModel({Key? key}) : super(key: key);

  @override
  _TfliteModelState createState() => _TfliteModelState();
}

class _TfliteModelState extends State<TfliteModel> {
  final Map<int, String> classMapping = {
    0: 'Brown rust',
    1: 'Healthy',
    2: 'Leaf_Rust',
    3: 'Yellow_rust'
  };

  late File _image;
  late List _results;
  bool imageSelect = false;
  bool imageClassified = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> imageClassification(File image) async {
    try {
      final input = image.readAsBytesSync();
      final interpreterOptions = InterpreterOptions()..threads = 2;
      final interpreter = await Interpreter.fromAsset(
          'assets/trained_model.tflite',
          options: interpreterOptions);

      // Perform inferences
      final output =
          List.filled(interpreter.getOutputTensors()[0].shape[0], 0.0).toList();
      interpreter.run(input, output);

      _results = [];

      final maxIndex = output
          .indexOf(output.reduce((curr, next) => curr > next ? curr : next));
      final maxConfidence = output[maxIndex];
      final maxLabel = classMapping[maxIndex] ?? 'Unknown';

      _results.add({"label": maxLabel, "confidence": maxConfidence});

      setState(() {
        imageClassified = true;
      });
    } catch (e) {
      print("Failed to classify image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Classification"),
        centerTitle: true,
        backgroundColor: Colors.purpleAccent.shade100,
      ),
      body: Stack(
        children: [
          _buildSelectedImage(),
          if (imageClassified) _buildClassificationResults(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showOptionsDialog();
        },
        tooltip: "Select Image",
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSelectedImage() {
    return Center(
      child: imageSelect
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Image.file(
                    _image,
                    height: MediaQuery.of(context).size.width - 50,
                    width: MediaQuery.of(context).size.width - 50,
                  ),
                ),
                if (!imageClassified)
                  ElevatedButton(
                    onPressed: () {
                      imageClassification(_image);
                    },
                    child: const Text('Classify Image'),
                  ),
              ],
            )
          : const Text("No image selected"),
    );
  }

  Widget _buildClassificationResults() {
    return Positioned(
      left: 10,
      bottom: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        color: Colors.black.withOpacity(0.5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _results.map((result) {
              return Text(
                "${result['label']} - ${result['confidence'].toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        imageSelect = true;
        imageClassified = false;
      });
    }
  }

  void showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Capture from Camera'),
                onTap: () {
                  pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
