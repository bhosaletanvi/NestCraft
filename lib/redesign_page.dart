
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nest_craft/ModifyRoomPage.dart';
import 'package:nest_craft/services/redesign_service.dart';
import 'package:nest_craft/shopping_page.dart';
import 'package:file_saver/file_saver.dart';

class RedesignPage extends StatefulWidget {
  final Uint8List originalImageBytes;
  final String projectId;

  const RedesignPage({
    super.key,
    required this.originalImageBytes,
    required this.projectId,
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

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  bool _showMobileNav = false;
  bool hasDownloadedImage = false;
  void _scrollToHome() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSection(GlobalKey key) {
    // Wait until the current frame finishes (important when the mobile
    // navigation menu is being closed) before looking up the target section.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetContext = key.currentContext;
      if (targetContext == null) {
        debugPrint('Navigation target is not attached to the widget tree.');
        return;
      }

      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        alignment: 0.04,
      );
    });
  }
Future<void> _saveRedesignedImage() async {
  final imageBytes = redesignedImageBytes;

  if (imageBytes == null || imageBytes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please generate a redesign first.'),
      ),
    );
    return;
  }

  try {
    await FileSaver.instance.saveFile(
      name: 'nestcraft_redesign',
      bytes: imageBytes,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );

    if (!mounted) return;
    setState(() {
  hasDownloadedImage = true;
});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your redesigned image is ready to save.'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to save image: $e'),
      ),
    );
  }
}
  Widget _logo({required double width, required double height}) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        'assets/images/nestcraft.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.home_work_rounded,
          size: 40,
          color: olive,
        ),
      ),
    );
  }

  Widget _mobileNavbar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          child: Row(
            children: [
              GestureDetector(
                onTap: _scrollToHome,
                child: _logo(width: 160, height: 65),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showMobileNav = !_showMobileNav),
                icon: Icon(
                  _showMobileNav ? Icons.close_rounded : Icons.more_vert_rounded,
                  size: 27,
                  color: darkBrown,
                ),
              ),
            ],
          ),
        ),
        if (_showMobileNav)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(15, 0, 15, 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5EF),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _mobileNavItem('Home'),
                _mobileNavItem('How It Works'),
                _mobileNavItem('About'),
                const SizedBox(height: 8),
                _profileMenu(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _mobileNavItem(String title) {
    return InkWell(
      onTap: () {
        setState(() => _showMobileNav = false);
        if (title == 'Home') _scrollToHome();
        if (title == 'How It Works') _scrollToSection(_howItWorksKey);
        if (title == 'About') _scrollToSection(_aboutKey);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: darkBrown,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _navbar() {
    return Container(
      height: 78,
      color: cream,
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Row(
        children: [
          GestureDetector(
            onTap: _scrollToHome,
            child: _logo(width: 200, height: 70),
          ),
          const Spacer(),
          _navText('Home', olive),
          const SizedBox(width: 35),
          _navText('How It Works', olive),
          const SizedBox(width: 35),
          _navText('About', olive),
          const SizedBox(width: 35),
          _profileMenu(),
          const SizedBox(width: 25),
        ],
      ),
    );
  }

  Widget _profileMenu() {
    return FutureBuilder<String>(
      future: _getUserName(),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'Profile';
        return PopupMenuButton<String>(
          tooltip: 'User Profile',
          onSelected: (value) async {
            if (value == 'profile') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logged in as $userName')),
              );
            } else if (value == 'logout') {
              await FirebaseAuth.instance.signOut();
            }
          },
          offset: const Offset(0, 50),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: olive),
                  const SizedBox(width: 10),
                  Text(userName, style: const TextStyle(color: darkBrown, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: olive, borderRadius: BorderRadius.circular(25)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : userName,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.person_outline, color: Colors.white, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Guest Profile';
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return query.docs.first.data()['name'] ?? 'Profile';
      return 'Profile';
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      return 'Profile';
    }
  }

  Widget _navText(String title, Color color) {
    return InkWell(
      onTap: () {
        if (title == 'Home') _scrollToHome();
        if (title == 'How It Works') _scrollToSection(_howItWorksKey);
        if (title == 'About') _scrollToSection(_aboutKey);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(title, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _navInfoSection({required Key sectionKey, required String title, required String description}) {
    return Container(
      key: sectionKey,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: darkBrown)),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 14, height: 1.6, color: mutedText)),
        ],
      ),
    );
  }

  static const String baseUrl =
      'https://backward-banknote-backlog.ngrok-free.dev';

  Uint8List? redesignedImageBytes;

  bool isGenerating = false;
  bool showComparison = false;
  String errorMessage = '';

  String selectedStyle = 'Modern';
  String selectedRoom = 'Living Room';
Future<String> _fetchExistingObjects() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('existingObject')
      .where('projectID', isEqualTo: widget.projectId)
      .get();

  final List<Map<String, dynamic>> objects = [];

  for (final document in snapshot.docs) {
    final data = document.data();

    final object = <String, dynamic>{
      'objectID': document.id,
      'type': data['type'] ?? 'object',
      'x': data['x'] ?? 0,
      'y': data['y'] ?? 0,
      'width': data['width'] ?? 0,
      'height': data['height'] ?? 0,
      'polygons': <Map<String, dynamic>>[],
    };

    final rawPolygons = data['polygons'];

    // YOLO records store points as a flat list of {x, y}.
    if (rawPolygons is List) {
      final points = <Map<String, dynamic>>[];

      for (final item in rawPolygons) {
        if (item is Map) {
          // Handle the manual-selection format: {points: [...]}
          if (item['points'] is List) {
            for (final point in item['points'] as List) {
              if (point is Map &&
                  point['x'] != null &&
                  point['y'] != null) {
                points.add({
                  'x': point['x'],
                  'y': point['y'],
                });
              }
            }
          } else if (item['x'] != null && item['y'] != null) {
            points.add({
              'x': item['x'],
              'y': item['y'],
            });
          }
        } else if (item is List && item.length >= 2) {
          points.add({
            'x': item[0],
            'y': item[1],
          });
        }
      }

      object['polygons'] = points;
    }

    objects.add(object);
  }

  debugPrint(
    'Existing objects loaded for project '
    '${widget.projectId}: ${objects.length}',
  );

  return jsonEncode(objects);
}
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
        hasDownloadedImage = false;

    });

    try {
      final existingObjectsJson = await _fetchExistingObjects();

final prompt =
    'Add new furniture and decor to the existing $selectedRoom '
    'in a $selectedStyle interior design style. '
    'Keep all existing furniture in exactly the same position '
    'and preserve its appearance. '
    'Preserve the original walls, windows, doors, floor, ceiling, '
    'room dimensions, and camera perspective. '
    'Do not replace, remove, move, or duplicate existing furniture. '
    'Add suitable new items only in available empty areas.';

final resultBytes = await RedesignService.redesignRoom(
  imageBytes: widget.originalImageBytes,
  fileName: 'room.png',
  roomType: selectedRoom,
  prompt: prompt,
  existingObjects: existingObjectsJson,
);
      if (!mounted) return;

      setState(() {
        redesignedImageBytes = resultBytes;
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
        crossAxisCount: isMobile ? 2 : 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 112,
      ),
      itemBuilder: (context, index) => _styleTile(styles[index]),
    );
  }
  
  Widget _howItWorksDesktopStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
    required bool isLast,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: olive,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        olive.withOpacity(
                      0.18,
                    ),
                    blurRadius: 15,
                    offset:
                        const Offset(0, 7),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 27,
              ),
            ),

            if (!isLast)
              Expanded(
                child: Container(
                  height: 1,
                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  color:
                      olive.withOpacity(
                    0.25,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        Align(
          alignment:
              Alignment.centerLeft,
          child: Text(
            number,
            style: TextStyle(
              color:
                  brown.withOpacity(
                0.6,
              ),
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),

        const SizedBox(height: 7),

        Align(
          alignment:
              Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: olive,
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Align(
          alignment:
              Alignment.centerLeft,
          child: Padding(
            padding:
                const EdgeInsets.only(
              right: 20,
            ),
            child: Text(
              description,
              style: const TextStyle(
                color: olive,
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ABOUT SECTION
  // ============================================================

  Widget _aboutSection() {
    return Container(
      key: _aboutKey,
      width: double.infinity,
      color: cream,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 80,
      ),
      child: Column(
        children: [
          const Text(
            "ABOUT NESTCRAFT",
            style: TextStyle(
              color: olive,
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Imagine. Change. Live.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: olive,
              fontSize: 34,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 800,
            ),
            child: const Text(
              "NestCraft is an interior design platform that helps you reimagine your living space. Upload your room, explore creative design ideas, customize furniture and decor, and discover alternatives that match your style and budget.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: olive,
                fontSize: 15,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(height: 40),

          Wrap(
            spacing: 25,
            runSpacing: 20,
            alignment:
                WrapAlignment.center,
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

          Container(
            width: double.infinity,
            constraints:
                const BoxConstraints(
              maxWidth: 850,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 30,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF8F5EF),
              borderRadius:
                  BorderRadius.circular(24),
              border: Border.all(
                color:
                    olive.withOpacity(
                  0.12,
                ),
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
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: olive,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "NestCraft brings creativity, personalization and practical choices together to make interior design simple and enjoyable.",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        olive.withOpacity(
                      0.85,
                    ),
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color:
              olive.withOpacity(0.2),
        ),
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
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
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  
  // ============================================================
  // MOBILE HOW IT WORKS STEP
  // ============================================================

  Widget _howItWorksVerticalStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: olive,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        olive.withOpacity(
                      0.18,
                    ),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),

            if (!isLast)
              Container(
                width: 1,
                height: 75,
                color:
                    olive.withOpacity(
                  0.25,
                ),
              ),
          ],
        ),

        const SizedBox(width: 18),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    color:
                        brown.withOpacity(
                      0.65,
                    ),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  title,
                  style:
                      const TextStyle(
                    color: olive,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  description,
                  style:
                      const TextStyle(
                    color: olive,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

Widget _howItWorksSection() {
    final steps = [
      {
        "number": "01",
        "icon":
            Icons.add_photo_alternate_outlined,
        "title": "Upload Your Space",
        "description":
            "Start by uploading a photo of your room. It can be your living room, bedroom, kitchen, or any space you want to redesign.",
      },
      {
        "number": "02",
        "icon":
            Icons.auto_awesome_outlined,
        "title": "Get Design Ideas",
        "description":
            "NestCraft analyzes your room and provides creative interior ideas that match the space and your preferences.",
      },
      {
        "number": "03",
        "icon": Icons.tune_outlined,
        "title": "Personalize Everything",
        "description":
            "Change furniture, colors and decorations. Move objects around and experiment until the room feels right.",
      },
      {
        "number": "04",
        "icon": Icons.shopping_bag_outlined,
        "title": "Explore Alternatives",
        "description":
            "Discover alternative furniture and decor options with prices so you can find choices that fit your style and budget.",
      },
      {
        "number": "05",
        "icon": Icons.home_outlined,
        "title": "Transform Your Space",
        "description":
            "Save your final design and turn your vision into a beautiful, personalized space you'll love.",
      },
    ];

    return Container(
      key: _howItWorksKey,
      width: double.infinity,
      color: const Color(0xFFF8F5EF),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 85,
      ),
      child: Column(
        children: [
          const Text(
            "HOW IT WORKS",
            style: TextStyle(
              color: olive,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            "From Empty Space\nTo Your Dream Space",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: olive,
              fontSize: 38,
              fontWeight:
                  FontWeight.w700,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 18),

          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 650,
            ),
            child: const Text(
              "A simple design journey that helps you imagine, customize and create a space that feels uniquely yours.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: olive,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 60),

          LayoutBuilder(
            builder:
                (context, constraints) {
              final bool smallScreen =
                  constraints.maxWidth <
                      850;

              if (smallScreen) {
                return Column(
                  children: [
                    for (int i = 0;
                        i < steps.length;
                        i++)
                      _howItWorksVerticalStep(
                        number:
                            steps[i]["number"]
                                as String,
                        icon:
                            steps[i]["icon"]
                                as IconData,
                        title:
                            steps[i]["title"]
                                as String,
                        description:
                            steps[i]["description"]
                                as String,
                        isLast:
                            i ==
                                steps.length -
                                    1,
                      ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  for (int i = 0;
                      i < steps.length;
                      i++)
                    Expanded(
                      child:
                          _howItWorksDesktopStep(
                        number:
                            steps[i]["number"]
                                as String,
                        icon:
                            steps[i]["icon"]
                                as IconData,
                        title:
                            steps[i]["title"]
                                as String,
                        description:
                            steps[i]["description"]
                                as String,
                        isLast:
                            i ==
                                steps.length -
                                    1,
                      ),
                    ),
                ],
              );
            },
          ),

          
        ],
      ),
    );
  }

 
Widget _buildGenerateButton() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isGenerating ? null : generateRedesign,
      style: ElevatedButton.styleFrom(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            brown.withValues(alpha: 0.55),
        elevation: 0,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGenerating)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            const Icon(
              Icons.auto_awesome,
              size: 19,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isGenerating
                  ? 'Creating Your Design...'
                  : redesignedImageBytes == null
                      ? 'Generate Redesign'
                      : 'Generate New Design',
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
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
            showComparison ? 'Show Redesign' : 'Compare With Original',
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
        if (redesignedImageBytes != null) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: 
OutlinedButton.icon(
  onPressed: hasDownloadedImage
      ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ModifyRoomPage(),
            ),
          );
        }
      : null,
  icon: Icon(
    hasDownloadedImage
        ? Icons.shopping_bag_outlined
        : Icons.lock_outline,
  ),
  label: Text(
    hasDownloadedImage
        ? 'Find Alternatives'
        : 'Save Image to Unlock Alternatives',
  ),
  style: OutlinedButton.styleFrom(
    foregroundColor: brown,
    disabledForegroundColor: mutedText,
    side: BorderSide(
      color: hasDownloadedImage
          ? brown
          : mutedText,
    ),
    padding: const EdgeInsets.symmetric(
      vertical: 14,
    ),
  ),
),

  ),
],
if (redesignedImageBytes != null) ...[
  const SizedBox(height: 16),
  SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: _saveRedesignedImage,
      icon: const Icon(Icons.download_rounded),
      label: const Text('Save Image'),
      style: ElevatedButton.styleFrom(
        backgroundColor: brown,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
]
      ],
    );
  }

  Widget _buildEditorControls(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DED2)),
        boxShadow: [
          BoxShadow(
            color: darkBrown.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          SizedBox(height: 20,),
          const Text(
            'Design settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Choose the look for your room.',
            style: TextStyle(fontSize: 12, color: mutedText, height: 1.4),
          ),
         
          const SizedBox(height: 22),
          const Text(
            'INTERIOR STYLE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: mutedText,
            ),
          ),
          const SizedBox(height: 10),
          _buildStyles(isMobile),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: olive, size: 19),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use a clear room photo for better results. AI results may vary.',
                    style: TextStyle(fontSize: 11, height: 1.45, color: darkBrown),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildGenerateButton(),
          _buildError(),
         
          if (redesignedImageBytes != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: isGenerating ? null : generateRedesign,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Another Design'),
              style: OutlinedButton.styleFrom(
                
                foregroundColor: brown,
                side: const BorderSide(color: brown),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomPreview() {
    final showingResult = redesignedImageBytes != null && !showComparison;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your room preview',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: darkBrown),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Your original space and generated design appear here.',
                    style: TextStyle(fontSize: 13, color: mutedText),
                  ),
                ],
              ),
            ),
            if (showingResult)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: olive.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'REDESIGNED',
                  style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: olive),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _imageCard(
          title: redesignedImageBytes == null
              ? 'Original Room'
              : (showComparison ? 'Original Room' : 'Redesigned Room'),
          subtitle: redesignedImageBytes == null
              ? 'Your starting point'
              : (showComparison ? 'Before redesign' : '$selectedStyle interior · $selectedRoom'),
          imageBytes: showingResult ? redesignedImageBytes! : widget.originalImageBytes,
          isResult: showingResult,
        ),
        if (redesignedImageBytes != null) ...[
          const SizedBox(height: 12),
          _buildResultActions(),
        ],
        const SizedBox(height: 12),
        const Text(
          'NESTCRAFT  ·  Design your space, your way.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedText, fontSize: 11, letterSpacing: 0.5),
        ),
      ],
    );
  }
Widget _buildHeroSection() {
    return Container(
      height: 430,
      width: double.infinity,
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(25),
        image: const DecorationImage(
          image: NetworkImage(
           'https://images.livspace-cdn.com/w:2048/plain/https://d3gq2merok8n5r.cloudfront.net/reno-lp-1662986043-otDV1/banner-1662986054-mF7RH/web-1440x730-1662986090-D7W4o.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(45),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
         
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 430,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR DESIGN JOURNEY',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'You Think,\nWe Redesign.',
                  style: TextStyle(
                    fontSize: 48,
                    color: Color.fromARGB(255, 14, 13, 13),
                    height: 1.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Design, visualize and transform your '
                  'spaces with AI-powered ideas.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Color.fromARGB(255, 14, 13, 13),
                  ),
                ),

                const SizedBox(height: 25),

               
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 760;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  isMobile ? _mobileNavbar() : _navbar(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(isMobile ? 14 : 28, 22, isMobile ? 14 : 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 22),
                        if (isMobile) ...[
                          _buildEditorControls(true),
                          const SizedBox(height: 22),
                          _buildRoomPreview(),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildRoomPreview(),
                              ),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 1,
                                child: _buildEditorControls(false),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 28),
                    child: Column(
                      children: [
                        _howItWorksSection(),
                        _aboutSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
