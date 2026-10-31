import 'package:nest_craft/shopping_page.dart';

import 'LandingPage.dart';
import 'LoginPage.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'package:supabase_flutter/supabase_flutter.dart'
    hide MultipartFile;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


const String laptopIp = '10.42.229.130';


String get apiBaseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://$laptopIp:8000';
  }

  return 'http://127.0.0.1:8000';
}

const Color darkBrown = Color(0xFF2F2922);
const Color brown = Color(0xFF6B4528);
const Color cream = Color(0xFFF5F0E8);
const Color cardColor = Color(0xFFFCF8F1);
const Color olive = Color(0xFF514E25);


class ModifyRoomPage extends StatefulWidget {
  const ModifyRoomPage({super.key});

  @override
  State<ModifyRoomPage> createState() =>
      _ModifyRoomPageState();
}

class _ModifyRoomPageState extends State<ModifyRoomPage> {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  XFile? selectedRoomImage;
  Uint8List? editedRoomImageBytes;

  bool isReplacingFurniture = false;
  bool isPickingImage = false;
  bool isDetecting = false;
  bool isSavingDesign = false;

  String? uploadedRoomImagePath;
  String? savedDesignPath;

  int selectedObject = -1;
  int selectedAlternative = 0;

  double detectedImageWidth = 0;
  double detectedImageHeight = 0;

  List<Map<String, dynamic>> detectedFurniture = [];

  final Map<int, String> furnitureNames = {};
  final Map<int, String> originalFurnitureNames = {};
  final Map<int, String> appliedFurnitureImages = {};
  final Map<int, String> appliedFurnitureNames = {};

  final Map<int, Offset> furniturePositions = {};
  final Map<int, Offset> originalFurniturePositions = {};

  bool showObjectTools = false;
bool _showMobileNav = false;

final GlobalKey _howItWorksKey = GlobalKey();
final GlobalKey _aboutKey = GlobalKey();
  List<Map<String, dynamic>> alternatives = [];

  bool isLoadingAlternatives = true;
  String? alternativesError;

  final List<Map<String, dynamic>> roomItems = [
    {'name': 'Sofa', 'price': 30000, 'icon': Icons.weekend_rounded},
    {'name': 'Center Table', 'price': 12000, 'icon': Icons.table_restaurant},
    {'name': 'Rug', 'price': 8500, 'icon': Icons.grid_on_rounded},
    {'name': 'Plant', 'price': 4500, 'icon': Icons.eco_rounded},
    {'name': 'Lighting', 'price': 30000, 'icon': Icons.light_rounded},
  ];

  int get totalCost => roomItems.fold<int>(
        0,
        (sum, item) => sum + (item['price'] as int),
      );

String getAlternativeImageUrl(Map<String, dynamic> item) {
  const imageKeys = [
    'imageUrl',
    'image_url',
    'signedUrl',
    'signed_url',
    'image',
    'url',
  ];

  for (final key in imageKeys) {
    final value = item[key];

    if (value is String &&
        value.trim().startsWith('http')) {
      return value.trim();
    }
  }

  return '';
}

  @override
  void initState() {
    super.initState();

    _dbg(
      'A',
      'ModifyRoomPage.dart:initState',
      'ModifyRoomPage opened',
      {
        'kIsWeb': kIsWeb,
        'platform': defaultTargetPlatform.name,
      },
    );

    _loadAlternatives();
  }


Future<void> _loadAlternatives() async {
  try {
    debugPrint('Loading furniture alternatives...');

    final supabase = Supabase.instance.client;

    debugPrint('SUPABASE URL: ${supabase.rest.url}');
    debugPrint('BUCKET: furniture-images');

    final snapshot = await FirebaseFirestore.instance
        .collection('furniture_catalog')
        .where('active', isEqualTo: true)
        .get();

    final loadedItems = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        final imagePath = (
          data['imagePath'] ?? data['imageUrl'] ?? ''
        ).toString().trim();

        String finalImageUrl = '';

        debugPrint('Furniture ID: ${doc.id}');
        debugPrint('Image path: $imagePath');

        if (imagePath.startsWith('https://') ||
            imagePath.startsWith('http://')) {
          finalImageUrl = imagePath;
        } else if (imagePath.isNotEmpty) {
          finalImageUrl = supabase.storage
              .from('furniture-images')
              .getPublicUrl(imagePath);

          debugPrint('IMAGE URL: $finalImageUrl');
        } else {
          debugPrint(
            'WARNING: Image path is empty for ${doc.id}',
          );
        }

        final categoryValue =
            (data['category'] ?? '').toString().trim();

        final id = doc.id.toLowerCase();

        String inferredCategory = categoryValue;

        if (inferredCategory.isEmpty) {
          if (id.contains('sofa')) {
            inferredCategory = 'sofa';
          } else if (id.contains('chair')) {
            inferredCategory = 'chair';
          } else if (id.contains('plant')) {
            inferredCategory = 'plant';
          } else if (id.contains('table')) {
            inferredCategory = 'table';
          } else if (id.contains('bed')) {
            inferredCategory = 'bed';
          } else if (id.contains('tv')) {
            inferredCategory = 'tv';
          } else if (id.contains('vase')) {
            inferredCategory = 'vase';
          } else if (id.contains('bowl')) {
            inferredCategory = 'bowl';
          } else if (id.contains('clock')) {
            inferredCategory = 'clock';
          } else {
            inferredCategory = 'other';
          }
        }

        loadedItems.add({
          'id': doc.id,
          'name': data['name'] ?? doc.id,
          'category': inferredCategory,
          'price': (data['price'] as num?)?.toInt() ?? 0,
          'imageUrl': finalImageUrl,
          'imagePath': imagePath,
        });
      } catch (e) {
        debugPrint(
          'ERROR loading furniture ${doc.id}: $e',
        );
      }
    }

    if (!mounted) return;

    setState(() {
      alternatives = loadedItems;
      isLoadingAlternatives = false;
      alternativesError = loadedItems.isEmpty
          ? 'No active furniture items found.'
          : null;
    });

    debugPrint('Loaded furniture: ${loadedItems.length}');

    debugPrint(
      'Furniture image URLs prepared: '
      '${loadedItems.where(
        (item) =>
            (item['imageUrl'] as String).isNotEmpty,
      ).length}',
    );
  } catch (e, stackTrace) {
    debugPrint('FURNITURE LOADING ERROR: $e');
    debugPrint('$stackTrace');

    if (!mounted) return;

    setState(() {
      isLoadingAlternatives = false;
      alternativesError = e.toString();
    });
  }
}


  void _dbg(
    String hypothesisId,
    String location,
    String message, [
    Map<String, dynamic>? data,
  ]) {
    debugPrint(
      '[$hypothesisId] $location: $message ${data ?? {}}',
    );
  }

bool isCompatibleAlternative(int targetId, int alternativeIndex) {
  if (targetId < 0 ||
      targetId >= detectedFurniture.length ||
      alternativeIndex < 0 ||
      alternativeIndex >= alternatives.length) {
    return false;
  }

  final originalName =
      (originalFurnitureNames[targetId] ??
              detectedFurniture[targetId]['name'] ??
              '')
          .toString();

  final alternative = alternatives[alternativeIndex];

  final alternativeCategory =
      (alternative['category'] ?? '').toString().trim();

  final originalCategory = _getFurnitureCategory(originalName);

  final alternativeCategoryNormalized =
      _getFurnitureCategory(
        alternativeCategory.isNotEmpty
            ? alternativeCategory
            : (alternative['name'] ?? '').toString(),
      );

  if (originalCategory == null ||
      alternativeCategoryNormalized == null) {
    return false;
  }

  return originalCategory.toLowerCase() ==
      alternativeCategoryNormalized.toLowerCase();
}

  String money(int amount) {
    return '₹${amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: brown,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

Future<void> pickRoomImage() async {
  try {
    setState(() => isPickingImage = true);

    final image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (!mounted || image == null) return;

    setState(() {
      selectedRoomImage = image;
      editedRoomImageBytes = null;
isReplacingFurniture = false;
      uploadedRoomImagePath = null;
      savedDesignPath = null;

      // Clear previous furniture detection.
      detectedFurniture = [];

      furnitureNames.clear();
      originalFurnitureNames.clear();

      // Clear previous furniture positions.
      furniturePositions.clear();
      originalFurniturePositions.clear();

      // Clear previously applied alternative images and names.
      appliedFurnitureImages.clear();
      appliedFurnitureNames.clear();

      selectedObject = -1;
      selectedAlternative = 0;
      showObjectTools = false;

      detectedImageWidth = 0;
      detectedImageHeight = 0;
    });

    // Upload the newly selected room image.
    await uploadRoomImage(image);
    if (!mounted) return;

    // Detect furniture in the new image.
    await detectRoomFurniture(image);
  } catch (e) {
    showMessage('Image selection failed: $e');
  } finally {
    if (mounted) {
      setState(() => isPickingImage = false);
    }
  }
}

  Future<void> uploadRoomImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: image.name,
        ),
      });

      final response = await _dio.post(
        '$apiBaseUrl/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map) {
          uploadedRoomImagePath =
              responseData['storage_path']?.toString() ??
              responseData['image_path']?.toString() ??
              responseData['path']?.toString() ??
              responseData['image_url']?.toString() ??
              responseData['url']?.toString();
        }

        debugPrint('Room image uploaded: $responseData');
        showMessage('Room image uploaded successfully!');
      } else {
        showMessage('Room image upload failed.');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      showMessage('Upload failed: $e');
    }
  }

final Map<String, Map<String, String>> roomObjectLabels = {
  'Bedroom': {
    'bed': 'Bed',
    'chair': 'Chair',
    'couch': 'Sofa',
    'dining table': 'Bedside Table',
    'potted plant': 'Plant',
  },
  'Hall': {
    'couch': 'Sofa',
    'chair': 'Chair',
    'dining table': 'Center Table',
    'tv': 'TV',
    'potted plant': 'Plant',
  },
  'Kitchen': {
  'refrigerator': 'Refrigerator',
  'microwave': 'Microwave',
  'oven': 'Oven',
  'sink': 'Sink',
  'dining table': 'Dining Table',
  },
  'Study Room': {
    'chair': 'Chair',
    'dining table': 'Study Desk',
    'laptop': 'Laptop',
    'tv': 'TV',
    'potted plant': 'Plant',
  },
};

String? normalizeFurnitureName(String label) {
  final normalized = label.toLowerCase().trim();

  const labels = <String, String>{
    'couch': 'Sofa',
    'sofa': 'Sofa',
    'chair': 'Chair',
    'dining table': 'Table',
    'table': 'Table',
    'bed': 'Bed',
    'potted plant': 'Plant',
    'plant': 'Plant',
    'tv': 'TV',
    'vase': 'Vase',
    'bowl': 'Bowl',
    'clock': 'Clock',
    'book': 'Book',

    // Existing household classes
    'refrigerator': 'Refrigerator',
    'microwave': 'Microwave',
    'oven': 'Oven',
    'sink': 'Sink',
    'laptop': 'Laptop',
  };

  return labels[normalized];
}


String? _getFurnitureCategory(String name) {
  final value = name.toLowerCase().trim();

  switch (value) {
    case 'sofa':
    case 'couch':
      return 'Sofa';

    case 'chair':
      return 'Chair';

    case 'table':
    case 'dining table':
    case 'center table':
    case 'study desk':
    case 'study table':
      return 'Table';

    case 'bed':
      return 'Bed';

    case 'plant':
    case 'potted plant':
      return 'Plant';

    case 'tv':
    case 'television':
      return 'TV';

    case 'vase':
      return 'Vase';

    case 'bowl':
      return 'Bowl';

    case 'clock':
      return 'Clock';

    case 'book':
      return 'Book';

    default:
      return null;
  }
}

Future<void> saveDesign() async {
  if (isSavingDesign) return;

  if (selectedRoomImage == null) {
    showMessage('Please upload a room photo first.');
    return;
  }

  try {
    setState(() {
      isSavingDesign = true;
    });

    // Edited image available असल्यास ती save करायची.
    // अन्यथा original room image save करायची.
    final Uint8List imageBytes =
        editedRoomImageBytes ??
        await selectedRoomImage!.readAsBytes();

    if (imageBytes.isEmpty) {
      showMessage('The selected image is empty.');
      return;
    }

    // Firebase login तपासणे.
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Firebase UID: ${user?.uid}');
debugPrint('Firebase Email: ${user?.email}');

    if (user == null) {
      showMessage('Please log in before saving your design.');
      return;
    }

    // Firebase ID token मिळवणे.
    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      showMessage('Unable to verify your login. Please try again.');
      return;
    }

    // Image extension आणि content type ठरवणे.
    final originalName = selectedRoomImage!.name.toLowerCase();

    String extension;
    String contentType;

    if (originalName.endsWith('.png')) {
      extension = 'png';
      contentType = 'image/png';
    } else if (originalName.endsWith('.webp')) {
      extension = 'webp';
      contentType = 'image/webp';
    } else {
      extension = 'jpg';
      contentType = 'image/jpeg';
    }

    // Existing backend port 8000 आहे.
    // Save Design API port 8001 वर चालते.
    final saveApiUrl =
        apiBaseUrl.replaceFirst(':8000', ':8001');

    debugPrint('Saving design through authenticated API...');
    debugPrint('API URL: $saveApiUrl/save-design');

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: 'room.$extension',
        contentType: DioMediaType.parse(contentType),
      ),
    });

    // Image आणि Firebase token नवीन API ला पाठवणे.
    final response = await Dio().post(
      '$saveApiUrl/save-design',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $idToken',
        },
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    final responseData = response.data;

    if (response.statusCode == 200 &&
        responseData is Map &&
        responseData['path'] != null) {
      final storagePath = responseData['path'].toString();

      if (!mounted) return;

      setState(() {
        savedDesignPath = storagePath;
      });

      debugPrint('Design saved successfully: $storagePath');

      showMessage('Design saved successfully to Supabase!');
    } else {
      throw Exception('Unexpected response from Save Design API.');
    }
  } on DioException catch (e) {
    debugPrint('Save Design API error: ${e.message}');
    debugPrint('API response: ${e.response?.data}');

    if (mounted) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['detail']?.toString()
          : null;

      showMessage(
        message ?? 'Unable to save design. Please try again.',
      );
    }
  } catch (e) {
    debugPrint('Save design error: $e');

    if (mounted) {
      showMessage('Unable to save design: $e');
    }
  } finally {
    if (mounted) {
      setState(() {
        isSavingDesign = false;
      });
    }
  }
}

Future<void> detectRoomFurniture(XFile image) async {
    debugPrint('DEBUG: detectRoomFurniture function called');

  if (!mounted) return;

  setState(() => isDetecting = true);

  try {
    final bytes = await image.readAsBytes();

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: image.name,
      ),
    });

    final response = await _dio.post(
      '$apiBaseUrl/detect',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    if (response.statusCode != 200) {
      showMessage('Furniture detection failed.');
      return;
    }

    final result = Map<String, dynamic>.from(response.data);
    final rawList = result['detections'] as List;

    final List<Map<String, dynamic>> detections = [];

    for (final raw in rawList) {
      final item = Map<String, dynamic>.from(raw);

      final name = normalizeFurnitureName(
        item['label']?.toString() ?? '',
      );

      if (name == null) continue;

      detections.add({
        'name': name,
        'class_id': (item['class_id'] as num?)?.toInt() ?? -1,
        'confidence': ((item['confidence'] ?? 0) as num).toDouble(),
        'x1': ((item['x1'] ?? 0) as num).toDouble(),
        'y1': ((item['y1'] ?? 0) as num).toDouble(),
        'x2': ((item['x2'] ?? 0) as num).toDouble(),
        'y2': ((item['y2'] ?? 0) as num).toDouble(),
      });
    }

    if (!mounted) return;

    setState(() {
      detectedImageWidth =
          ((result['image_width'] ?? 0) as num).toDouble();

      detectedImageHeight =
          ((result['image_height'] ?? 0) as num).toDouble();

      detectedFurniture = detections;

      furnitureNames.clear();
      originalFurnitureNames.clear();
      furniturePositions.clear();
      originalFurniturePositions.clear();

      for (int i = 0; i < detections.length; i++) {
        originalFurnitureNames[i] =
            detections[i]['name'] as String;
      }

      // Debug logs to verify detected furniture
      debugPrint('DETECTED FURNITURE: $detectedFurniture');
      debugPrint('ORIGINAL FURNITURE NAMES: $originalFurnitureNames');

      selectedObject = detections.isEmpty ? -1 : 0;
      showObjectTools = false;
    });
    debugPrint('DETECTION FUNCTION COMPLETED');
debugPrint('DETECTED FURNITURE: $detectedFurniture');
debugPrint('ORIGINAL FURNITURE NAMES: $originalFurnitureNames');

    _dbg(
      'A',
      'ModifyRoomPage.dart:detectRoomFurniture',
      'Detection stored',
      {
        'detectionCount': detections.length,
        'appliedOverlayCount': furnitureNames.length,
        'originalLabels': originalFurnitureNames.values.toList(),
      },
    );

    showMessage('Detected ${detections.length} furniture objects.');
  } catch (e) {
    debugPrint('Detection error: $e');

    _dbg(
      'A',
      'ModifyRoomPage.dart:detectRoomFurniture',
      'Detection failed',
      {'error': e.toString()},
    );

    showMessage('Detection failed: $e');
  } finally {
    if (mounted) {
      setState(() => isDetecting = false);
    }
  }
}
Future<void> replaceFurniture(
  int targetId,
  int alternativeIndex,
) async {
  if (isReplacingFurniture) return;

  if (selectedRoomImage == null) {
    showMessage('Please upload a room photo first.');
    return;
  }

  if (targetId < 0 ||
      targetId >= detectedFurniture.length ||
      alternativeIndex < 0 ||
      alternativeIndex >= alternatives.length) {
    return;
  }

  if (!isCompatibleAlternative(targetId, alternativeIndex)) {
    showMessage('Choose a matching furniture alternative.');
    return;
  }

  final item = alternatives[alternativeIndex];
  final furnitureName = (item['name'] ?? 'Furniture').toString();
  final furnitureUrl = getAlternativeImageUrl(item);
  final detected = detectedFurniture[targetId];

  if (furnitureUrl.isEmpty) {
    showMessage('Furniture image URL is not available.');
    return;
  }

  try {
    setState(() {
      isReplacingFurniture = true;
    });

    // 1. Read the original room image.
    final roomBytes = await selectedRoomImage!.readAsBytes();

    // 2. Download the selected furniture image.
    final furnitureResponse = await _dio.get<List<int>>(
      furnitureUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    final furnitureBytes = furnitureResponse.data;

    if (furnitureBytes == null || furnitureBytes.isEmpty) {
      throw Exception('Could not download furniture image.');
    }

    // 3. Prepare coordinates detected by YOLO.
    final x1 = (detected['x1'] as num).round();
    final y1 = (detected['y1'] as num).round();
    final x2 = (detected['x2'] as num).round();
    final y2 = (detected['y2'] as num).round();

    final classId =
        (detected['class_id'] as num?)?.toInt() ?? -1;

    debugPrint('Replacing: $furnitureName');
    debugPrint('Coordinates: $x1, $y1, $x2, $y2');
    debugPrint('YOLO class ID: $classId');

    // 4. Send both images and coordinates to FastAPI.
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        roomBytes,
        filename: selectedRoomImage!.name,
      ),
      'furniture_image': MultipartFile.fromBytes(
        furnitureBytes,
        filename: 'replacement.png',
      ),
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
      'class_id': classId,
    });

    final response = await _dio.post<List<int>>(
      '$apiBaseUrl/replace-furniture',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        responseType: ResponseType.bytes,
      ),
    );

    final resultBytes = response.data;

    if (response.statusCode == 200 &&
        resultBytes != null &&
        resultBytes.isNotEmpty) {
      if (!mounted) return;

      // 5. Display the edited room photo.
      setState(() {
        editedRoomImageBytes = Uint8List.fromList(resultBytes);

        appliedFurnitureNames[targetId] = furnitureName;
        appliedFurnitureImages[targetId] = furnitureUrl;
        furnitureNames[targetId] = furnitureName;

        selectedObject = targetId;
        selectedAlternative = alternativeIndex;
        showObjectTools = true;
      });

      showMessage('$furnitureName replacement completed!');
    } else {
      showMessage('Replacement failed. Please try again.');
    }
  } on DioException catch (e) {
    debugPrint('Replace API error: ${e.message}');
    debugPrint('API response: ${e.response?.data}');

    if (mounted) {
      showMessage(
        'Replacement API failed: ${e.response?.statusCode ?? "Network error"}',
      );
    }
  } catch (e) {
    debugPrint('Furniture replacement error: $e');

    if (mounted) {
      showMessage('Replacement failed: $e');
    }
  } finally {
    if (mounted) {
      setState(() {
        isReplacingFurniture = false;
      });
    }
  }
}
void restoreOriginalFurniture() {
  setState(() {
    furnitureNames.clear();
    appliedFurnitureImages.clear();
    appliedFurnitureNames.clear();
    editedRoomImageBytes = null;

    furniturePositions
      ..clear()
      ..addAll(originalFurniturePositions);

    selectedObject = detectedFurniture.isEmpty ? -1 : 0;
    selectedAlternative = 0;
    showObjectTools = false;
  });

  showMessage('Original furniture restored.');
}

  IconData iconForFurniture(String name) {
    switch (name) {
      case 'Sofa':
        return Icons.weekend_rounded;
      case 'Table':
        return Icons.table_restaurant;
      case 'Lamp':
        return Icons.lightbulb_outline;
      case 'Chair':
        return Icons.chair_alt;
      case 'Bed':
        return Icons.bed;
      case 'Plant':
        return Icons.eco_rounded;
      default:
        return Icons.chair_alt;
    }
  }

  String? assetForFurniture(String name) {
    switch (name) {
      case 'Sofa':
        return 'assets/images/furniture/sofa.png';
      case 'Table':
        return 'assets/images/furniture/table.png';
      case 'Lamp':
        return 'assets/images/furniture/lamp.png';
      case 'Chair':
        return 'assets/images/furniture/chair.png';
      case 'Bed':
        return 'assets/images/furniture/bed.png';
      default:
        return null;
    }
  }


@override

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: cream,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 800;

          return Column(
            children: [
              desktop ? _navbar() : _mobileNavbar(),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: desktop ? 30 : 14,
                    vertical: 18,
                  ),
                  child: Column(
                    children: [
                      _buildPageTitle(desktop),
                      const SizedBox(height: 22),

                      if (desktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _buildRoomPreview(),
                                  const SizedBox(height: 14),
                                  _buildAlternatives(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildQuickActions(),
                                  const SizedBox(height: 14),
                                  _buildRoomDesignTips(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildRoomPreview(),
                            const SizedBox(height: 14),
                            _buildAlternatives(),
                            const SizedBox(height: 14),
                            _buildQuickActions(),
                            const SizedBox(height: 14),
                            _buildRoomDesignTips(),
                          ],
                        ),

                      const SizedBox(height: 35),

                      _buildHowItWorksSection(),

                      const SizedBox(height: 35),

                      _aboutSection(),

                      const SizedBox(height: 35),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// HOW IT WORKS SECTION
Widget _buildHowItWorksSection() {
  final steps = [
    {
      'icon': Icons.add_photo_alternate_outlined,
      'number': '01',
      'title': 'Upload Your Space',
      'description':
          'Start by uploading a photo of your room. It can be your living room, bedroom, kitchen, or any space you want to redesign.',
    },
    {
      'icon': Icons.auto_awesome,
      'number': '02',
      'title': 'Get Design Ideas',
      'description':
          'NestCraft analyzes your room and provides creative interior ideas that match your space and preferences.',
    },
    {
      'icon': Icons.tune,
      'number': '03',
      'title': 'Personalize Everything',
      'description':
          'Change furniture, colors and decorations. Move objects around and experiment until the room feels right.',
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'number': '04',
      'title': 'Explore Alternatives',
      'description':
          'Discover alternative furniture and decor options with prices so you can find choices that fit your style and budget.',
    },
    {
      'icon': Icons.home_outlined,
      'number': '05',
      'title': 'Transform Your Space',
      'description':
          "Save your final design and turn your vision into a beautiful, personalized space you'll love.",
    },
  ];

  return Container(
    key: _howItWorksKey,
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal:  desktopPadding(context),
      vertical: 55,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFF8F5EF),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Column(
          children: [
            const Text(
              'H O W   I T   W O R K S',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: Color(0xFF514E25),
              ),
            ),

            const SizedBox(height: 20),
Text(
  'From Empty Space\nTo Your Dream Space',
  textAlign: TextAlign.center,
  style: TextStyle(
    fontSize: isDesktop ? 48 : 34,
    height: 1.12,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF514E25),
  ),
),

            const SizedBox(height: 24),

            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 800,
              ),
              child: const Text(
                'A simple design journey that helps you imagine, '
                'customize and create a space that feels uniquely yours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.6,
                  color: Color(0xFF514E25),
                ),
              ),
            ),

            const SizedBox(height: 75),

            if (isDesktop)
              _buildDesktopHowItWorks(steps)
            else
              _buildMobileHowItWorks(steps),
          ],
        );
      },
    ),
  );
}

// Responsive horizontal timeline for desktop

Widget _buildDesktopHowItWorks(List<Map<String, Object>> steps) {
  return SizedBox(
    width: double.infinity,
    child: Stack(
      children: [
        Positioned(
          top: 39,
          left: 45,
          right: 45,
          child: Container(
            height: 1,
            color: const Color(0xFFD8D3C5),
          ),
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.map((step) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF514E25),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x1F514E25),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),

                    const SizedBox(height: 27),

                    Text(
                      step['number'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFAA8F78),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      step['title'] as String,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF514E25),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      step['description'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF514E25),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// Mobile layout

Widget _buildMobileHowItWorks(List<Map<String, Object>> steps) {
  return Column(
    children: steps.map((step) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF514E25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step['icon'] as IconData,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['number'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFAA8F78),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    step['title'] as String,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF514E25),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    step['description'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF514E25),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

// Horizontal padding based on screen width

double desktopPadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 1200) {
    return 10;
  } else if (width >= 800) {
    return 20;
  }

  return 4;
}

// ABOUT SECTION
// =========================================================
// ABOUT SECTION
// ============================================================

Widget _aboutSection() {
  return Container(
    key: _aboutKey,
    width: double.infinity,
    color: cream,
    padding: const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 80,
    ),
    child: Column(
      children: [
        // ABOUT HEADING
        const Text(
          "ABOUT NESTCRAFT",
          style: TextStyle(
            color: olive,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 12),

        // MAIN TITLE
        const Text(
          "Imagine. Change. Live.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: olive,
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 18),

        // DESCRIPTION
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800,
          ),
          child: const Text(
            "NestCraft is an interior design platform that helps "
            "you reimagine your living space. Upload your room, "
            "explore creative design ideas, customize furniture "
            "and decor, and discover alternatives that match "
            "your style and budget.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: olive,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ),

        const SizedBox(height: 40),

        // FEATURES
        Wrap(
          spacing: 25,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _aboutItem(
              Icons.design_services_outlined,
              "Personalized Design",
            ),
            _aboutItem(
              Icons.auto_awesome_outlined,
              "Smart Suggestions",
            ),
            _aboutItem(
              Icons.account_balance_wallet_outlined,
              "Budget Friendly",
            ),
          ],
        ),

        const SizedBox(height: 45),

        // BOTTOM INFORMATION CARD
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 850,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 30,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F5EF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: olive.withOpacity(0.12),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.home_work_outlined,
                color: olive,
                size: 34,
              ),

              const SizedBox(height: 15),

              const Text(
                "Your Space. Your Style. Your Story.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: olive,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "NestCraft brings creativity, personalization "
                "and practical choices together to make interior "
                "design simple and enjoyable.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: olive.withOpacity(0.85),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ============================================================
// ABOUT ITEM
// ============================================================

Widget _aboutItem(
  IconData icon,
  String title,
) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 22,
      vertical: 15,
    ),
    decoration: BoxDecoration(
      border: Border.all(
        color: olive.withOpacity(0.2),
      ),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: olive,
          size: 20,
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: const TextStyle(
            color: olive,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// NAVIGATION

void _navigateToLanding() {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const LandingPage(),
    ),
  );
}

void _handleNavigation(String title) {
  if (title == 'Home') {
    _navigateToLanding();
  } else if (title == 'How It Works') {
    _scrollToSection(_howItWorksKey);
  } else if (title == 'About') {
    _scrollToSection(_aboutKey);
  }
}

void _scrollToSection(GlobalKey key) {
  final targetContext = key.currentContext;

  if (targetContext != null) {
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }
}

// LOGO

Widget _logo() {
  return InkWell(
    onTap: _navigateToLanding,
    child: Image.asset(
      'assets/images/nestcraft.png',
      width: 160,
      height: 60,
      fit: BoxFit.contain,
    ),
  );
}

// DESKTOP NAVBAR

Widget _navbar() {
  return Container(
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 30),
    decoration: const BoxDecoration(
      color: Color(0xFFF1E7D9),
      border: Border(
        bottom: BorderSide(
          color: Color(0xFFE6D8C6),
        ),
      ),
    ),
    child: Row(
      children: [
        _logo(),
        const Spacer(),
        _navText('Home'),
        _navText('How It Works'),
        _navText('About'),
        const SizedBox(width: 15),
        _profileMenu(),
      ],
    ),
  );
}

Widget _navText(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: InkWell(
      onTap: () => _handleNavigation(title),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 4,
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF655443),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

// MOBILE NAVBAR

Widget _mobileNavbar() {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFF1E7D9),
      border: Border(
        bottom: BorderSide(
          color: Color(0xFFE6D8C6),
        ),
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            _logo(),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _showMobileNav = !_showMobileNav;
                });
              },
              icon: Icon(
                _showMobileNav
                    ? Icons.close_rounded
                    : Icons.menu_rounded,
                color: darkBrown,
                size: 28,
              ),
            ),
          ],
        ),

        if (_showMobileNav) ...[
          const Divider(
            color: Color(0xFFE6D8C6),
          ),
          _mobileNavItem('Home'),
          _mobileNavItem('How It Works'),
          _mobileNavItem('About'),
          Align(
            alignment: Alignment.centerLeft,
            child: _profileMenu(),
          ),
        ],
      ],
    ),
  );
}

Widget _mobileNavItem(String title) {
  return ListTile(
    dense: true,
    title: Text(
      title,
      style: const TextStyle(
        color: darkBrown,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: () {
      setState(() {
        _showMobileNav = false;
      });

      _handleNavigation(title);
    },
  );
}

// GET USER NAME
Future<String> _getUserName() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return 'Guest';

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      return (doc.data()?['name'] ?? user.email ?? 'User')
          .toString();
    }
  } catch (e) {
    debugPrint('Profile name error: $e');
  }

  return user.email ?? 'User';
}

// PROFILE MENU
Widget _profileMenu() {
  return PopupMenuButton<String>(
    tooltip: 'Profile',
    onSelected: (value) async {
      if (value == 'profile') {
        final user = FirebaseAuth.instance.currentUser;
        showMessage(user?.email ?? 'No user logged in');
      } else if (value == 'logout') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    },
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: 'profile',
        child: Row(
          children: [
            Icon(Icons.person_outline, color: darkBrown),
            SizedBox(width: 10),
            Text('Profile'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
      ),
    ],
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 15,
            backgroundColor: brown,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          FutureBuilder<String>(
            future: _getUserName(),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'User',
                style: const TextStyle(
                  color: darkBrown,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.keyboard_arrow_down,
            color: darkBrown,
          ),
        ],
      ),
    ),
  );
}


  Widget _buildPageTitle(bool desktop) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      'Modify Your Room',
      style: TextStyle(
        color: const Color(0xFF171512),
        fontSize: desktop ? 32 : 21,
        fontWeight: FontWeight.bold,
        fontFamily: 'Georgia',
      ),
    ),
  );
}

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: darkBrown,
        backgroundColor: const Color(0xFFEFE5D8),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }


Widget _buildRoomPreview() {
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 320),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: brown.withOpacity(0.18),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: selectedRoomImage == null
        ? SizedBox(
            height: 360,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 60,
                      color: brown.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Upload Your Room Photo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload a room image to detect furniture '
                      'and customize your design.',
                      style: TextStyle(
                        fontSize: 14,
                        color: darkBrown.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed:
                          isPickingImage || isDetecting
                              ? null
                              : pickRoomImage,
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Upload Room Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : FutureBuilder<Uint8List>(
            future: selectedRoomImage!.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SizedBox(
                  height: 320,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const SizedBox(
                  height: 320,
                  child: Center(
                    child: Text('Unable to load room image.'),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final previewWidth = constraints.maxWidth;

                  // Match the image aspect ratio so the photo
                  // is not stretched or cropped unexpectedly.
                  final imageAspectRatio =
                      detectedImageWidth > 0 &&
                              detectedImageHeight > 0
                          ? detectedImageWidth /
                              detectedImageHeight
                          : 4 / 3;

                  final previewHeight =
                      previewWidth / imageAspectRatio;

                  return SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Room image
                        Image.memory(
  editedRoomImageBytes ?? snapshot.data!,
  width: previewWidth,
  height: previewHeight,
  fit: BoxFit.fill,
),
                        // Reset furniture positions and names
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Tooltip(
                            message: 'Restore original furniture',
                            child: _smallIconButton(
                              Icons.restore_rounded,
                              restoreOriginalFurniture,
                            ),
                          ),
                        ),

                        // Upload another room photo
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Tooltip(
                            message: 'Upload another room photo',
                            child: _smallIconButton(
                              Icons.add_photo_alternate_outlined,
                              isPickingImage || isDetecting
                                  ? () {}
                                  : pickRoomImage,
                            ),
                          ),
                        ),

                        // Furniture markers
                        if (!isDetecting &&
                            detectedFurniture.isNotEmpty)
                          ...List.generate(
                            detectedFurniture.length,
                            (index) => _buildDetectedMarker(
                              index,
                              previewWidth,
                              previewHeight,
                            ),
                          ),

                        // Selected furniture tools
                        if (showObjectTools &&
                            selectedObject >= 0 &&
                            selectedObject <
                                detectedFurniture.length)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.96),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      furnitureNames[selectedObject] ??
                                          originalFurnitureNames[
                                              selectedObject] ??
                                          detectedFurniture[
                                                  selectedObject]
                                              ['name']
                                              ?.toString() ??
                                          'Furniture',
                                      style: const TextStyle(
                                        color: darkBrown,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      
                                    setState(() {
                                      furnitureNames.remove(selectedObject);
                                      appliedFurnitureNames.remove(selectedObject);
                                      appliedFurnitureImages.remove(selectedObject);
                                            showObjectTools = false;
                                    });

                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    label: const Text('Remove'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Close',
                                    onPressed: () {
                                      setState(() {
                                        showObjectTools = false;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: darkBrown,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Loading overlay
                        if (isPickingImage || isDetecting || isReplacingFurniture)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.25),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        // Detection result message
                        if (!isDetecting &&
                            detectedFurniture.isEmpty)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.94),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'No furniture detected. Try another room photo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: darkBrown,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
  );
}

Widget _buildDetectedMarker(
  int id,
  double parentWidth,
  double parentHeight,
) {
  if (id < 0 ||
      id >= detectedFurniture.length ||
      detectedImageWidth <= 0 ||
      detectedImageHeight <= 0 ||
      parentWidth <= 0 ||
      parentHeight <= 0) {
    return const SizedBox.shrink();
  }

  final item = detectedFurniture[id];

  final x1 = (item['x1'] as num?)?.toDouble() ?? 0.0;
  final y1 = (item['y1'] as num?)?.toDouble() ?? 0.0;
  final x2 = (item['x2'] as num?)?.toDouble() ?? 0.0;
  final y2 = (item['y2'] as num?)?.toDouble() ?? 0.0;

  // Room image uses BoxFit.fill.
  final scaleX = parentWidth / detectedImageWidth;
  final scaleY = parentHeight / detectedImageHeight;

  final rawLeft = x1 * scaleX;
  final rawTop = y1 * scaleY;
  final rawRight = x2 * scaleX;
  final rawBottom = y2 * scaleY;

  final left =
      rawLeft.clamp(0.0, parentWidth).toDouble();
  final top =
      rawTop.clamp(0.0, parentHeight).toDouble();
  final right =
      rawRight.clamp(left, parentWidth).toDouble();
  final bottom =
      rawBottom.clamp(top, parentHeight).toDouble();

  final width =
      (right - left).clamp(1.0, parentWidth).toDouble();
  final height =
      (bottom - top).clamp(1.0, parentHeight).toDouble();

  final initialPosition = Offset(
    (left / parentWidth).clamp(0.0, 1.0),
    (top / parentHeight).clamp(0.0, 1.0),
  );

  originalFurniturePositions.putIfAbsent(
    id,
    () => initialPosition,
  );

  final position =
      furniturePositions[id] ?? initialPosition;

  final originalName =
      originalFurnitureNames[id] ??
      item['name']?.toString() ??
      'Furniture';

  // Applied alternative name and Supabase image.
  final appliedName =
      appliedFurnitureNames[id] ?? furnitureNames[id];

  final appliedImageUrl = appliedFurnitureImages[id];

  final hasAppliedImage =
      appliedImageUrl != null &&
      appliedImageUrl.trim().startsWith('http');

  final asset = hasAppliedImage || appliedName == null
      ? null
      : assetForFurniture(appliedName);

  final selected = selectedObject == id;

  final maxLeft =
      (parentWidth - width).clamp(0.0, parentWidth);
  final maxTop =
      (parentHeight - height).clamp(0.0, parentHeight);

  return Positioned(
    left: (position.dx * parentWidth)
        .clamp(0.0, maxLeft)
        .toDouble(),
    top: (position.dy * parentHeight)
        .clamp(0.0, maxTop)
        .toDouble(),
    width: width,
    height: height,
    child: DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        return isCompatibleAlternative(id, details.data);
      },
      onAcceptWithDetails: (details) {
        replaceFurniture(id, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          onTap: () {
            setState(() {
              selectedObject = id;
              showObjectTools = true;
            });
          },

          // Move the marker without changing its size.
          onPanUpdate: (details) {
            setState(() {
              final current =
                  furniturePositions[id] ?? initialPosition;

              final maxX =
                  ((parentWidth - width) / parentWidth)
                      .clamp(0.0, 1.0);

              final maxY =
                  ((parentHeight - height) / parentHeight)
                      .clamp(0.0, 1.0);

              furniturePositions[id] = Offset(
                (current.dx +
                        details.delta.dx / parentWidth)
                    .clamp(0.0, maxX)
                    .toDouble(),
                (current.dy +
                        details.delta.dy / parentHeight)
                    .clamp(0.0, maxY)
                    .toDouble(),
              );

              selectedObject = id;
              showObjectTools = true;
            });
          },

          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.green
                    : selected
                        ? const Color(0xFF7197FF)
                        : Colors.white.withValues(alpha: 0.85),
                width: selected || candidateData.isNotEmpty
                    ? 3
                    : 1.5,
              ),
              borderRadius: BorderRadius.circular(5),
              color: candidateData.isNotEmpty
                  ? Colors.green.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),

            child: Stack(
              fit: StackFit.expand,
              children: [
                // Show the selected alternative's Supabase image.
                if (hasAppliedImage)
                  Image.network(
                    appliedImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        iconForFurniture(
                          appliedName ?? originalName,
                        ),
                        color: brown,
                        size: 35,
                      );
                    },
                  )
                else if (asset != null)
                  Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Icon(
                        iconForFurniture(
                          appliedName ?? originalName,
                        ),
                        color: brown,
                        size: 35,
                      );
                    },
                  )
                else
                  Icon(
                    iconForFurniture(
                      appliedName ?? originalName,
                    ),
                    color: brown,
                    size: 35,
                  ),

                // Show replacement name after applying an alternative.
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? brown : Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      appliedName ?? originalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _smallIconButton(
  IconData icon,
  VoidCallback onTap,
) {
  return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.all(9),
        child: Icon(
          icon,
          color: brown,
          size: 20,
        ),
      ),
    ),
  );
}


  Widget _buildBudgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: brown,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Budget & Details',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE9DFD2)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: brown,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Estimated Cost'),
                    const SizedBox(height: 5),
                    Text(
                      money(totalCost),
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF171512),
                      ),
                    ),
                    const Text(
                      'of ₹ 1,50,000 budget',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (totalCost / 150000).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: const Color(0xFFE8DDCF),
              valueColor: const AlwaysStoppedAnimation<Color>(brown),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(totalCost / 150000 * 100).round()}% used',
              style: const TextStyle(fontSize: 12, color: darkBrown),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE9DFD2)),
          const SizedBox(height: 14),
          const Text(
            'Selected Items',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 8),
          ...roomItems.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2E9DC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: olive,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['name'] as String,
                      style: const TextStyle(fontSize: 14, color: darkBrown),
                    ),
                  ),
                  Text(
                    money(item['price'] as int),
                    style: const TextStyle(
                      fontSize: 14,
                      color: darkBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

Widget _buildAlternatives() {
  final selectedName =
      selectedObject >= 0 &&
              selectedObject < detectedFurniture.length
          ? (originalFurnitureNames[selectedObject] ??
                  detectedFurniture[selectedObject]['name'] ??
                  'Furniture')
              .toString()
          : 'Furniture';

  // Show ALL loaded furniture alternatives.
  // Do not filter by detected room categories.
  final List<MapEntry<int, Map<String, dynamic>>> visibleItems = [];

  for (int i = 0; i < alternatives.length; i++) {
    visibleItems.add(MapEntry(i, alternatives[i]));
  }

  debugPrint('DETECTED FURNITURE: $detectedFurniture');
  debugPrint('TOTAL ALTERNATIVES: ${alternatives.length}');
  debugPrint('VISIBLE ALTERNATIVES: ${visibleItems.length}');
  debugPrint('ALTERNATIVES ERROR: $alternativesError');
  debugPrint('LOADING ALTERNATIVES: $isLoadingAlternatives');

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.brown.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Furniture Alternatives',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: darkBrown,
            fontFamily: 'Georgia',
          ),
        ),

        const SizedBox(height: 6),

        Text(
          selectedObject >= 0
              ? 'Furniture selected: $selectedName'
              : 'Choose furniture from the room, then select an alternative.',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 14),

        if (isLoadingAlternatives && alternatives.isEmpty)
          const SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(color: brown),
            ),
          )
        else if (visibleItems.isEmpty)
          SizedBox(
            height: 190,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image_not_supported_outlined,
                    size: 35,
                    color: brown,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alternativesError != null
                        ? 'Unable to load images. Please retry.'
                        : 'No furniture images available.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isLoadingAlternatives
                        ? null
                        : _loadAlternatives,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleItems.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final entry = visibleItems[index];
                final originalIndex = entry.key;
                final item = entry.value;

                final isSelected =
                    selectedAlternative == originalIndex;

                return SizedBox(
                  width: 145,
                  child: Draggable<int>(
                    data: originalIndex,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 145,
                        height: 190,
                        child: _alternativeCard(item, true),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.45,
                      child: _alternativeCard(item, isSelected),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (selectedObject < 0 ||
                            selectedObject >=
                                detectedFurniture.length) {
                          showMessage(
                            'Select a furniture object in the room first.',
                          );
                          return;
                        }

                        setState(() {
                          selectedAlternative = originalIndex;
                        });

                        showMessage(
                          'Selected ${item['name']}. Drag it onto the selected furniture to apply.',
                        );
                      },
                      child: _alternativeCard(item, isSelected),
                    ),
                  ),
                );
              },
            ),
          ),

        if (alternativesError != null &&
            alternatives.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: isLoadingAlternatives
                  ? null
                  : _loadAlternatives,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh furniture images'),
            ),
          ),
      ],
    ),
  );
}

Future<String?> _refreshFurnitureImageUrl(
  String imagePath,
) async {
  try {
    if (imagePath.isEmpty ||
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return null;
    }
final newUrl = Supabase.instance.client.storage
    .from('furniture-images')
    .getPublicUrl(imagePath);
    return newUrl;
  } catch (e) {
    debugPrint('Signed URL refresh failed: $e');
    return null;
  }
}

Widget _alternativeCard(
  Map<String, dynamic> item,
  bool selected,
) {
  final name = (item['name'] ?? 'Furniture').toString();

  final imageUrl =
      (item['imageUrl'] ?? item['asset'] ?? '').toString();

  final imagePath =
      (item['imagePath'] ?? '').toString();

  return _FurnitureAlternativeImage(
    key: ValueKey('${item['id'] ?? name}-$selected'),
    imageUrl: imageUrl,
    imagePath: imagePath,
    name: name,
    selected: selected,
    refreshUrl: _refreshFurnitureImageUrl,
  );
}


Widget _buildQuickActions() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: brown.withValues(alpha: 0.15),
      ),
      boxShadow: [
        BoxShadow(
          color: darkBrown.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modify Your Room',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: darkBrown,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Save your room design or discover more furniture.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: darkBrown.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 20),

        // Save Design button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isSavingDesign ? null : saveDesign,
            icon: isSavingDesign
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.bookmark_added_outlined,
                  ),
            label: Text(
              isSavingDesign
                  ? 'Saving Design...'
                  : 'Save Design',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkBrown,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(
                vertical: 17,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Search on Web button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_)=>ShoppingPage()));
            },
            icon: const Icon(Icons.travel_explore),
            label: const Text(
              'Search on Web',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: brown,
              backgroundColor: cream,
              side: BorderSide(
                color: brown.withValues(alpha: 0.35),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


Widget _buildRoomDesignTips() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: brown.withValues(alpha: 0.15),
      ),
      boxShadow: [
        BoxShadow(
          color: darkBrown.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: brown,
              size: 25,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Room Design Tips',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkBrown,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Simple ideas to make your room look better.',
          style: TextStyle(
            fontSize: 13,
            color: darkBrown.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 20),

        _buildDesignTip(
          Icons.wb_sunny_outlined,
          'Natural Lighting',
          'Use natural light to make your room bright and welcoming.',
        ),
        const SizedBox(height: 16),

        _buildDesignTip(
          Icons.chair_outlined,
          'Smart Furniture Placement',
          'Keep enough space between furniture for easy movement.',
        ),
        const SizedBox(height: 16),

        _buildDesignTip(
          Icons.eco_outlined,
          'Add Greenery',
          'Indoor plants can give your room a fresh, natural feel.',
        ),
        const SizedBox(height: 16),

        _buildDesignTip(
          Icons.palette_outlined,
          'Match Your Colors',
          'Choose colors that complement your furniture and decor.',
        ),
      ],
    ),
  );
}

Widget _buildDesignTip(
  IconData icon,
  String title,
  String description,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: brown,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                color: darkBrown.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

}

class _FurnitureAlternativeImage extends StatefulWidget {
  final String imageUrl;
  final String imagePath;
  final String name;
  final bool selected;
  final Future<String?> Function(String) refreshUrl;

  const _FurnitureAlternativeImage({
    super.key,
    required this.imageUrl,
    required this.imagePath,
    required this.name,
    required this.selected,
    required this.refreshUrl,
  });

  @override
  State<_FurnitureAlternativeImage> createState() =>
      _FurnitureAlternativeImageState();
}


class _FurnitureAlternativeImageState
    extends State<_FurnitureAlternativeImage> {
  late String currentUrl;
  int retryCount = 0;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    currentUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(
    covariant _FurnitureAlternativeImage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl) {
      currentUrl = widget.imageUrl;
      retryCount = 0;
      refreshing = false;
    }
  }

  Future<void> refreshImage() async {
    if (refreshing || retryCount >= 1) return;
    if (widget.imagePath.isEmpty) return;

    setState(() {
      refreshing = true;
      retryCount++;
    });

    try {
      final newUrl = await widget.refreshUrl(widget.imagePath);

      if (!mounted) return;

      setState(() {
        if (newUrl != null && newUrl.isNotEmpty) {
          currentUrl = newUrl;
          debugPrint('Furniture image URL refreshed.');
        } else {
          debugPrint('Furniture image URL refresh returned empty.');
        }

        refreshing = false;
      });
    } catch (e) {
      debugPrint('Furniture image refresh failed: $e');

      if (!mounted) return;

      setState(() {
        refreshing = false;
      });
    }
  }

  IconData _iconForFurniture(String name) {
    final furniture = name.toLowerCase();

    if (furniture.contains('sofa') ||
        furniture.contains('couch')) {
      return Icons.weekend_rounded;
    } else if (furniture.contains('chair')) {
      return Icons.chair_alt;
    } else if (furniture.contains('bed')) {
      return Icons.bed;
    } else if (furniture.contains('table')) {
      return Icons.table_restaurant;
    } else if (furniture.contains('plant')) {
      return Icons.eco_rounded;
    } else if (furniture.contains('tv')) {
      return Icons.tv;
    }

    return Icons.chair_alt;
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (currentUrl.startsWith('http://') ||
        currentUrl.startsWith('https://')) {
      image = Image.network(
        currentUrl,
        key: ValueKey(currentUrl),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('FURNITURE IMAGE ERROR: $error');
          debugPrint('FAILED IMAGE URL: $currentUrl');
          debugPrint('FURNITURE IMAGE PATH: ${widget.imagePath}');

          if (retryCount == 0 && !refreshing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && retryCount == 0) {
                refreshImage();
              }
            });
          }

          return Center(
            child: refreshing
                ? const CircularProgressIndicator(
                    color: brown,
                  )
                : IconButton(
                    tooltip: 'Retry image',
                    onPressed: retryCount == 0
                        ? refreshImage
                        : null,
                    icon: Icon(
                      _iconForFurniture(widget.name),
                      color: brown,
                      size: 45,
                    ),
                  ),
          );
        },
      );
    } else if (currentUrl.isNotEmpty) {
      image = Image.asset(
        currentUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('FURNITURE ASSET ERROR: $error');
          debugPrint('FAILED ASSET PATH: $currentUrl');

          return Icon(
            _iconForFurniture(widget.name),
            color: brown,
            size: 45,
          );
        },
      );
    } else {
      debugPrint(
        'EMPTY IMAGE URL for furniture: ${widget.name}',
      );

      image = Icon(
        _iconForFurniture(widget.name),
        color: brown,
        size: 45,
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.selected
              ? brown
              : const Color(0xFFE6DCCF),
          width: widget.selected ? 1.8 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: image,
          ),
        ),
      ),
    );
  }
}

