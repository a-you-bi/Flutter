// import 'package:flutter/material.dart';
// import 'package:tflite_flutter/tflite_flutter.dart'; // For running the AI model
// import 'package:flutter_sound/flutter_sound.dart'; // For recording audio
// import 'dart:typed_data';
// import 'dart:async';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late Interpreter _interpreter;
//   FlutterSoundRecorder _recorder = FlutterSoundRecorder();
//   bool _isRecording = false;
//   String _result = "Press Record to classify sound";
//   List<String> _labels = ["Dog Bark", "Cat Meow", "Human Speech"]; // Update with your labels

//   @override
//   void initState() {
//     super.initState();
//     loadModel();
//     initRecorder();
//   }

//   /// Load TFLite model
//   Future<void> loadModel() async {
//     _interpreter = await Interpreter.fromAsset('assets/sound_model.tflite');
//     print("✅ Model Loaded Successfully");
//   }

//   /// Initialize Recorder
//   Future<void> initRecorder() async {
//     await _recorder.openRecorder();
//     print("🎙️ Recorder Initialized");
//   }

//   /// Start/Stop Recording
//   Future<void> toggleRecording() async {
//     if (_isRecording) {
//       await _recorder.stopRecorder();
//       classifyAudio();
//     } else {
//       await _recorder.startRecorder(toFile: 'audio.wav');
//     }
//     setState(() {
//       _isRecording = !_isRecording;
//     });
//   }

//   /// Process and classify the recorded audio
//   void classifyAudio() async {
//     Uint8List audioData = await _recorder.readRecorder();
    
//     // Convert audio data into required model format
//     var inputBuffer = List.generate(1, (_) => List.filled(16000, 0.0)); // Assuming 1s, 16KHz
//     for (int i = 0; i < audioData.length && i < 16000; i++) {
//       inputBuffer[0][i] = audioData[i] / 255.0; // Normalize
//     }

//     var output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

//     _interpreter.run(inputBuffer, output);

//     int predictedIndex = output[0].indexWhere((val) => val == output[0].reduce((a, b) => a > b ? a : b));

//     setState(() {
//       _result = "Classified as: ${_labels[predictedIndex]}";
//     });

//     print("🔍 Classification Output: ${output[0]}");
//   }

//   @override
//   void dispose() {
//     _recorder.closeRecorder();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text("AI Voice Classifier")),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(_result, style: TextStyle(fontSize: 18)),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: toggleRecording,
//                 child: Text(_isRecording ? "Stop Recording" : "Record Sound"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
