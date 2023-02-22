import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sample/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  // It makes no difference if the main app initializes Firebase or not.
  await FirestoreService().init();

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> uploadToStorage(String filePath) async {
  print('running in isolate');
  // Makes no difference if this is called or not.
  // WidgetsFlutterBinding.ensureInitialized();

  await FirestoreService().init();

  final z = DateTime.now().millisecondsSinceEpoch;
  final imageBucket = FirebaseStorage.instanceFor(app: FirestoreService().app);
  await imageBucket.ref('test-$z.jpg').putFile(File(filePath));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: upload,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// This method loads a file from assets and uploads to Firebase Storage.
  Future<void> upload() async {
    setState(() => _counter++);

    // Load a file to upload
    final tmp = await getTemporaryDirectory();
    final data = await rootBundle.load('assets/dell.jpg');
    final buffer = data.buffer;
    final file = await File('${tmp.path}/test.jpg').writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));

    // Upload the file.
    print('[UPLOAD STARTED]');

    await flutterCompute<void, String>(
      uploadToStorage,
      file.path,
    );

    // When an isolate has been triggered prior to upload, you'll
    // never get to this point. If you comment out the isolate, you'll need
    // to kill the app and restart it to get it working again.
    print('[UPLOAD DONE]');
  }
}

/// A small service to initialize a Firebase app instance.
class FirestoreService {
  factory FirestoreService() => _instance;

  FirestoreService._();

  static final FirestoreService _instance = FirestoreService._();

  late final FirebaseApp app;

  Future<void> init() async {
    app = await Firebase.initializeApp(
      name: 'testing-isolate-issue',
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
