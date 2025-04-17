import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminAdsPage extends StatefulWidget {
  @override
  _AdminAdsPageState createState() => _AdminAdsPageState();
}

class _AdminAdsPageState extends State<AdminAdsPage> {
  List<String> _existingImageUrls = [];
  String? _existingVideoUrl;
  List<File> _selectedImages = [];
  File? _selectedVideo;
  double _petrolPrice = 0.0;
  double _dieselPrice = 0.0;
  double _lubricantPrice = 0.0;
  bool _isLoading = false;
  final _priceControllers = {
    'petrolPrice': TextEditingController(),
    'dieselPrice': TextEditingController(),
    'lubricantPrice': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final doc =
        await FirebaseFirestore.instance.collection('ads').doc('current').get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        _existingImageUrls = List<String>.from(data?['sliderUrls'] ?? []);
        _existingVideoUrl = data?['videoUrl'];
        _petrolPrice = data?['petrolPrice'] ?? 0.0;
        _dieselPrice = data?['dieselPrice'] ?? 0.0;
        _lubricantPrice = data?['lubricantPrice'] ?? 0.0;
        _priceControllers['petrolPrice']?.text = _petrolPrice.toString();
        _priceControllers['dieselPrice']?.text = _dieselPrice.toString();
        _priceControllers['lubricantPrice']?.text = _lubricantPrice.toString();
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveAdsData() async {
    setState(() => _isLoading = true);
    List<String> imageUrls = [];

    // Upload images
    for (var image in _selectedImages) {
      Reference storageRef =
          FirebaseStorage.instance.ref().child('ads/${DateTime.now()}.jpg');
      await storageRef.putFile(image);
      String downloadUrl = await storageRef.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    // Use existing images if no new ones are selected
    if (imageUrls.isEmpty) {
      imageUrls = _existingImageUrls;
    }

    // Upload video
    String? videoUrl = _existingVideoUrl;
    if (_selectedVideo != null) {
      Reference storageRef =
          FirebaseStorage.instance.ref().child('ads/${DateTime.now()}.mp4');
      await storageRef.putFile(_selectedVideo!);
      videoUrl = await storageRef.getDownloadURL();
    }

    // Save data to Firestore
    await FirebaseFirestore.instance.collection('ads').doc('current').set({
      'sliderUrls': imageUrls,
      'videoUrl': videoUrl,
      'petrolPrice':
          double.tryParse(_priceControllers['petrolPrice']?.text ?? '0') ?? 0.0,
      'dieselPrice':
          double.tryParse(_priceControllers['dieselPrice']?.text ?? '0') ?? 0.0,
      'lubricantPrice':
          double.tryParse(_priceControllers['lubricantPrice']?.text ?? '0') ??
              0.0,
    });

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ads updated successfully!')),
    );
  }

  Future<void> _deleteAllAdsData() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Ads Data'),
        content: const Text('Are you sure you want to delete all ads data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      // Delete images
      for (var url in _existingImageUrls) {
        final ref = FirebaseStorage.instance.refFromURL(url);
        await ref.delete();
      }

      // Delete video
      if (_existingVideoUrl != null) {
        final ref = FirebaseStorage.instance.refFromURL(_existingVideoUrl!);
        await ref.delete();
      }

      // Reset Firestore data
      await FirebaseFirestore.instance.collection('ads').doc('current').set({
        'sliderUrls': [],
        'videoUrl': null,
        'petrolPrice': 0.0,
        'dieselPrice': 0.0,
        'lubricantPrice': 0.0,
      });

      setState(() {
        _existingImageUrls = [];
        _existingVideoUrl = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All ads data deleted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Update Ads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteAllAdsData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _pickImages,
                child: const Text('Select Images for Slider'),
              ),
              Wrap(
                spacing: 10,
                children: _existingImageUrls
                    .map((url) => Image.network(url, width: 100, height: 100))
                    .toList(),
              ),
              ElevatedButton(
                onPressed: _pickVideo,
                child: const Text('Select Video'),
              ),
              if (_existingVideoUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('Existing Video: $_existingVideoUrl'),
                ),
              for (var field in _priceControllers.keys)
                TextField(
                  controller: _priceControllers[field],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: field),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAdsData,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Ads Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
