import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ResultsScreen extends StatefulWidget {
  final String extractedText;
  const ResultsScreen({super.key, required this.extractedText});

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Future<Map<String, dynamic>>? analysisResult;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    analysisResult = _getAnalysis();
  }

  Future<Map<String, dynamic>> _getAnalysis() async {
    // This line is updated to specify the region correctly.
    final HttpsCallable callable =
        FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('analyzeReport');
    try {
      final result = await callable.call<Map<String, dynamic>>(
        {'text': widget.extractedText},
      );
      return result.data;
    } catch (e) {
      print("Error calling cloud function: $e");
      return {'error': 'Failed to get analysis.'};
    }
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Report Analysis"),
        actions: [
          IconButton(
            icon: Icon(Icons.volume_up),
            onPressed: () async {
              final data = await analysisResult;
               if (data != null && data['summary'] != null) {
                 _speak(data['summary'].toString());
               }
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: analysisResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              (snapshot.hasData && snapshot.data!.containsKey('error'))) {
            return Center(child: Text("Error: ${snapshot.data?['error'] ?? snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return Center(child: Text("No analysis available."));
          }

          final data = snapshot.data!;
          // These lines are updated for type safety.
          final summary = data['summary']?.toString() ?? 'No summary available.';
          final recommendations = data['recommendations']?.toString() ?? 'No recommendations available.';
          final doctorQuestions = data['doctorQuestions'] as List? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection("Summary", summary),
                _buildSection("Recommendations", recommendations),
                _buildSection("Questions for your Doctor", doctorQuestions.join('\n')),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(content, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
