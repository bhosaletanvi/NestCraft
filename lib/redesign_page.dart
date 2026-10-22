
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RedesignPage extends StatefulWidget {
  final Uint8List originalImageBytes;

  const RedesignPage({
    super.key,
    required this.originalImageBytes,
  });

  @override
  State<RedesignPage> createState() => _RedesignPageState();
}

class _RedesignPageState extends State<RedesignPage> {
  static const Color darkBrown = Color(0xFF2F2922);
  static const Color brown = Color(0xFF6B4528);
  static const Color olive = Color(0xFF514E25);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color fieldColor = Color(0xFFF8F6F2);
  static const Color mutedText = Color(0xFF81776B);

  static const String baseUrl =
      'https://backward-banknote-backlog.ngrok-free.dev';

  Uint8List? redesignedImageBytes;

  bool isGenerating = false;
  bool showComparison = false;
  String errorMessage = '';

  String selectedStyle = 'Modern';
  String selectedRoom = 'Living Room';

  final List<Map<String, dynamic>> styles = [
    {
      'name': 'Modern',
      'description': 'Clean and elegant',
      'icon': Icons.weekend_outlined,
    },
    {
      'name': 'Minimalist',
      'description': 'Simple and calm',
      'icon': Icons.chair_outlined,
    },
    {
      'name': 'Luxury',
      'description': 'Rich and refined',
      'icon': Icons.diamond_outlined,
    },
    {
      'name': 'Traditional',
      'description': 'Classic and timeless',
      'icon': Icons.home_outlined,
    },
    {
      'name': 'Scandinavian',
      'description': 'Natural and cozy',
      'icon': Icons.spa_outlined,
    },
    {
      'name': 'Contemporary',
      'description': 'Fresh and stylish',
      'icon': Icons.architecture_outlined,
    },
  ];

  final List<String> roomTypes = [
    'Living Room',
    'Bedroom',
    'Kitchen',
    'Dining Room',
    'Office',
  ];

  Future<void> generateRedesign() async {
    if (isGenerating) return;

    setState(() {
      isGenerating = true;
      errorMessage = '';
      showComparison = false;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/redesign'),
      );

      request.fields['prompt'] =
          'Redesign the entire $selectedRoom in a $selectedStyle '
          'interior design style. Create a photorealistic, professionally '
          'designed room with coordinated furniture, tasteful decor, '
          'harmonious colors, beautiful lighting, and suitable materials. '
          'Preserve the original room architecture, windows, doors, '
          'walls, and camera perspective. Make the result look realistic '
          'and cohesive. Return the generated image.';

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          widget.originalImageBytes,
          filename: 'room.png',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}. '
          '${response.body}',
        );
      }

      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();

      if (!contentType.contains('image/')) {
        throw Exception(
          'The server did not return an image. '
          'Received: $contentType',
        );
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('The generated image is empty.');
      }

      if (!mounted) return;

      setState(() {
        redesignedImageBytes = response.bodyBytes;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: darkBrown,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: mutedText,
          ),
        ),
      ],
    );
  }

  Widget _imageCard({
    required String title,
    required String subtitle,
    required Uint8List imageBytes,
    bool isResult = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9E1D6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isResult ? olive.withValues(alpha: 0.10) : cream,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isResult
                        ? Icons.auto_awesome
                        : Icons.photo_outlined,
                    color: isResult ? olive : brown,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: darkBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: fieldColor,
            constraints: const BoxConstraints(minHeight: 180),
            child: Image.memory(
              imageBytes,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Unable to display this image.'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleTile(Map<String, dynamic> style) {
    final name = style['name'] as String;
    final selected = selectedStyle == name;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: isGenerating
          ? null
          : () {
              setState(() {
                selectedStyle = name;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? brown.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? brown : const Color(0xFFE7DED2),
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  style['icon'] as IconData,
                  color: selected ? brown : mutedText,
                  size: 23,
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: brown,
                    size: 19,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: selected ? brown : darkBrown,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              style['description'] as String,
              style: const TextStyle(
                color: mutedText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyles(bool isMobile) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: styles.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) => _styleTile(styles[index]),
    );
  }

  Widget _buildRoomSelector() {
    return DropdownButtonFormField<String>(
      value: selectedRoom,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE7DED2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE7DED2)),
        ),
      ),
      items: roomTypes.map((room) {
        return DropdownMenuItem(
          value: room,
          child: Text(room),
        );
      }).toList(),
      onChanged: isGenerating
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  selectedRoom = value;
                });
              }
            },
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isGenerating ? null : generateRedesign,
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brown.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGenerating)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.auto_awesome, size: 20),
            const SizedBox(width: 10),
            Text(
              isGenerating
                  ? 'Creating Your Design...'
                  : redesignedImageBytes == null
                      ? 'Generate Redesign'
                      : 'Generate New Design',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    if (errorMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEBC5BD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unable to generate your design',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9B3024),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            errorMessage,
            style: const TextStyle(
              color: Color(0xFF79372F),
              fontSize: 12,
            ),
          ),
          TextButton.icon(
            onPressed: isGenerating ? null : generateRedesign,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.chair_alt_outlined, color: brown, size: 38),
          SizedBox(height: 13),
          Text(
            'Reimagining your space',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: darkBrown,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Your AI designer is working on your new interior. '
            'This may take a few minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: mutedText,
              height: 1.5,
            ),
          ),
          SizedBox(height: 18),
          LinearProgressIndicator(
            color: brown,
            backgroundColor: cream,
          ),
        ],
      ),
    );
  }

  Widget _buildResultActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              showComparison = !showComparison;
            });
          },
          icon: Icon(
            showComparison
                ? Icons.visibility_off_outlined
                : Icons.compare_outlined,
          ),
          label: Text(
            showComparison ? 'Hide Original' : 'Compare With Original',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: brown,
            side: const BorderSide(color: brown),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
        if (showComparison) ...[
          const SizedBox(height: 14),
          _imageCard(
            title: 'Original Room',
            subtitle: 'Before redesign',
            imageBytes: widget.originalImageBytes,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 650;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: darkBrown,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'NestCraft',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7DED2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: brown, size: 15),
                SizedBox(width: 5),
                Text(
                  'AI Studio',
                  style: TextStyle(
                    color: brown,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 30,
            vertical: 12,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 20 : 28),
                    decoration: BoxDecoration(
                      color: darkBrown,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'YOUR SPACE, REIMAGINED',
                            style: TextStyle(
                              color: Color(0xFFE8D8C5),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Create a space\nthat feels like you.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 29 : 37,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Choose your style and let NestCraft '
                          'reimagine your room.',
                          style: TextStyle(
                            color: Color(0xFFD6CFC6),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  _sectionTitle(
                    'Your uploaded room',
                    'This is the image your design will be based on.',
                  ),
                  const SizedBox(height: 13),

                  _imageCard(
                    title: 'Original Room',
                    subtitle: 'Your starting point',
                    imageBytes: widget.originalImageBytes,
                  ),

                  const SizedBox(height: 27),

                  _sectionTitle(
                    'Room type',
                    'Select the space you want to redesign.',
                  ),
                  const SizedBox(height: 13),
                  _buildRoomSelector(),

                  const SizedBox(height: 27),

                  _sectionTitle(
                    'Choose your aesthetic',
                    'Select a style that matches your vision.',
                  ),
                  const SizedBox(height: 13),
                  _buildStyles(isMobile),

                  const SizedBox(height: 26),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE6D9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: olive,
                          size: 22,
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'For the best result, use a clear photo '
                            'of your room. AI results may vary, and '
                            'some room details can change.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: darkBrown,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  _buildGenerateButton(),
                  _buildError(),

                  if (isGenerating) _buildLoadingPanel(),

                  if (redesignedImageBytes != null) ...[
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: olive.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: olive,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your new space',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: darkBrown,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your AI-generated design is ready.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    _imageCard(
                      title: 'Redesigned Room',
                      subtitle: '$selectedStyle interior · $selectedRoom',
                      imageBytes: redesignedImageBytes!,
                      isResult: true,
                    ),

                    const SizedBox(height: 13),
                    _buildResultActions(),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed:
                          isGenerating ? null : generateRedesign,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Another Design'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: brown,
                        side: const BorderSide(color: brown),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Divider(color: Color(0xFFE0D7CA)),
                  const SizedBox(height: 10),
                  const Text(
                    'NESTCRAFT  ·  Design your space, your way.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
