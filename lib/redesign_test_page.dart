
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/redesign_service.dart';

class RedesignTestPage extends StatefulWidget {
  const RedesignTestPage({super.key});

  @override
  State<RedesignTestPage> createState() => _RedesignTestPageState();
}

class _RedesignTestPageState extends State<RedesignTestPage> {
  Uint8List? originalBytes;
  Uint8List? redesignedBytes;
  bool isLoading = false;
  String? errorMessage;

  Future<void> pickRoomImage() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (file == null || !mounted) return;

    setState(() {
      originalBytes = null;
      redesignedBytes = null;
      errorMessage = null;
    });

    final bytes = await file.readAsBytes();

    if (!mounted) return;

    setState(() {
      originalBytes = bytes;
    });
  }

  Future<void> redesignRoom() async {
    if (originalBytes == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      redesignedBytes = null;
    });

    try {
      final result = await RedesignService.redesignRoom(
        imageBytes: originalBytes!,
        fileName: 'room.jpg',
        prompt:
            'Modern interior design, elegant coffee table, '
            'cream rug, tasteful wall art, photorealistic room',
      );

      if (!mounted) return;

      setState(() {
        redesignedBytes = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NestCraft Redesign Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: isLoading ? null : pickRoomImage,
            child: const Text('Choose Room Image'),
          ),
          if (originalBytes != null) ...[
            const SizedBox(height: 16),
            const Text('Original Room'),
            Image.memory(originalBytes!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : redesignRoom,
              child: const Text('Redesign Room'),
            ),
          ],
          if (isLoading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
            const Center(child: Text('Redesigning your room...')),
          ],
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            SelectableText(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          if (redesignedBytes != null) ...[
            const SizedBox(height: 20),
            const Text('Redesigned Room'),
            Image.memory(redesignedBytes!),
          ],
        ],
      ),
    );
  }
}
