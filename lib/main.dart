import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'models/mudra_detector.dart';

void main() {
  runApp(const MudraApp());
}

class MudraApp extends StatelessWidget {
  const MudraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mudra Recognition Pro',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MudraDetector _detector = MudraDetector();
  final ImagePicker _picker = ImagePicker();

  String _currentMudra = 'Ready to detect';
  double _confidence = 0.0;
  bool _isLoading = false;
  File? _selectedImage;
  List<Map<String, dynamic>> _allPredictions = [];
  Map<String, String>? _currentMudraInfo;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  Future<void> _initializeDetector() async {
    setState(() => _isLoading = true);
    await _detector.loadModel();
    setState(() => _isLoading = false);
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _processImage(File(pickedFile.path));
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _isLoading = true;
      _currentMudra = 'Analyzing...';
      _confidence = 0.0;
      _allPredictions = [];
    });

    try {
      // ADD AWAIT HERE - This was missing!
      final result = await _detector.predictFromImage(imageFile);

      if (result.containsKey('error')) {
        _showError(result['error']);
        return;
      }

      if (result['predictions'] != null) {
        final predictions =
            List<Map<String, dynamic>>.from(result['predictions']);
        setState(() {
          _allPredictions = predictions;
          if (predictions.isNotEmpty) {
            _currentMudra = predictions[0]['mudra'];
            _confidence = predictions[0]['confidence'];
            _currentMudraInfo = _detector.getMudraDescription(_currentMudra);
          }
        });
      }
    } catch (e) {
      _showError('Analysis failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    setState(() => _isLoading = false);
  }

  void _showMudraDetails() {
    if (_currentMudraInfo == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MudraDetailSheet(mudraInfo: _currentMudraInfo!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '🎭 Mudra AI Pro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange,
      ),
      body: _isLoading && _selectedImage == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header Card
                  _buildHeaderCard(),
                  const SizedBox(height: 24),

                  // Image Preview
                  if (_selectedImage != null) _buildImagePreview(),
                  if (_selectedImage != null) const SizedBox(height: 24),

                  // Results Section
                  _buildResultsSection(),
                  const SizedBox(height: 24),

                  // All Predictions
                  if (_allPredictions.isNotEmpty) _buildAllPredictions(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickImageFromGallery,
        icon: const Icon(Icons.photo_library),
        label: const Text('Analyze Image'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 50,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bharatanatyam Mudra Recognition',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered detection of 50+ classical hand gestures',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'DETECTION RESULT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'AI is analyzing the hand gesture...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                )
              : Column(
                  children: [
                    GestureDetector(
                      onTap: _showMudraDetails,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _currentMudra.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _confidence,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _confidence > 0.8
                                    ? Colors.green
                                    : _confidence > 0.6
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Confidence',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${(_confidence * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: _confidence > 0.8
                                        ? Colors.green
                                        : _confidence > 0.6
                                            ? Colors.orange
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_currentMudraInfo != null)
                      TextButton.icon(
                        onPressed: _showMudraDetails,
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('View Mudra Details'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildAllPredictions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOP PREDICTIONS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._allPredictions
              .map((prediction) => _buildPredictionRow(prediction)),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(Map<String, dynamic> prediction) {
    final confidence = prediction['confidence'];
    final mudra = prediction['mudra'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              mudra,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getConfidenceColor(confidence).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: _getConfidenceColor(confidence),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }
}

class MudraDetailSheet extends StatelessWidget {
  final Map<String, String> mudraInfo;

  const MudraDetailSheet({super.key, required this.mudraInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            mudraInfo['name']!.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mudraInfo['category']!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            mudraInfo['description']!,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
