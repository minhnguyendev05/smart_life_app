import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('Error recognizing text: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
