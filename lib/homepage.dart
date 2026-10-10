import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nest_craft/uploadimg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color darkBrown = Color(0xFF2F2922);
  static const Color brown = Color(0xFF6B4528);
  static const Color olive = Color(0xFF514E25);
  static const Color cream = Color(0xFFF5F0E8);

  // ============================================================
  // SCROLL
  // ============================================================

  final ScrollController _scrollController = ScrollController();

  bool _showMobileNav = false;

final GlobalKey _howItWorksKey = GlobalKey();
final GlobalKey _aboutKey = GlobalKey();

  // ============================================================
  // MY DESIGNS
  // ============================================================

  // Empty for now.
  // Later we can load the user's designs from Firebase.

  final List<Map<String, String>> myDesigns = [];

  // ============================================================
  // EXPLORE INSPIRATIONS
  // ============================================================
void _scrollToSection(GlobalKey key) {
  final context = key.currentContext;

  if (context != null) {
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }
}
 final List<Map<String, String>> inspirations = [
  
  {
    'title': 'Luxury Living',
    'image':
        'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Cozy Bedroom',
    'image':
        'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Modern Kitchen',
    'image':
        'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Elegant Dining',
    'image':
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Scandinavian Interior',
    'image':
        'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Contemporary Room',
    'image':
        'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Minimal Bedroom',
    'image':
        'https://images.unsplash.com/photo-1617104678098-de229db51175?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Luxury Bedroom',
    'image':
        'https://images.unsplash.com/photo-1615529162924-f8605388461d?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Natural Living',
    'image':
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
  },
  {
    'title': 'Classic Interior',
    'image':
        'https://images.unsplash.com/photo-1600607688969-a5bfcd646154?auto=format&fit=crop&w=1200&q=80',
  },
];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SCROLL HOME
  // ============================================================

  void _scrollToHome() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

 Widget _logo({
  double width = 200,
  double height = 70,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: Image.asset(
      'assets/images/nestcraft.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.home_work_rounded,
          size: 40,
          color: olive,
        );
      },
    ),
  );
}
  // ============================================================
  // DESKTOP NAVBAR
  // ============================================================
Widget _navbar() {
  return Container(
    height: 78,
    color: cream,
    padding: const EdgeInsets.symmetric(horizontal: 35),
    child: Row(
      children: [
        GestureDetector(
          onTap: _scrollToHome,
          child: _logo(
            width: 200,
            height: 70,
          ),
        ),

        const Spacer(),

        _navText("Home", olive),
        const SizedBox(width: 35),

        _navText("How It Works", olive),
        const SizedBox(width: 35),

        _navText("About", olive),
        const SizedBox(width: 35),

         _profileMenu(),
                const SizedBox(width: 25),
      ],
    ),
  );
}
  // ============================================================
  // MOBILE NAVBAR
  // ============================================================
Widget _profileMenu() {
  return FutureBuilder<String>(
    future: _getUserName(),
    builder: (context, snapshot) {
      final userName = snapshot.data ?? "Profile";

      return PopupMenuButton<String>(
        tooltip: "User Profile",
        onSelected: (value) async {
          if (value == 'profile') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Logged in as $userName"),
              ),
            );
          } else if (value == 'logout') {
            await FirebaseAuth.instance.signOut();
          }
        },
        offset: const Offset(0, 50),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: olive,
                ),
                const SizedBox(width: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: darkBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 10),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: olive,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                snapshot.connectionState == ConnectionState.waiting
                    ? "Loading..."
                    : userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String> _getUserName() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return "Guest Profile";
  }

  try {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();

      print("Document ID: ${query.docs.first.id}");
      print("User name: ${data['name']}");

      return data['name'] ?? "Profile";
    }

    print("No user document found for UID: ${user.uid}");
    return "Profile";
  } catch (e) {
    print("Error fetching user name: $e");
    return "Profile";
  }
}
 
 
Widget _mobileNavbar() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 7,
        ),
        child: Row(
          children: [
            // LOGO
            GestureDetector(
              onTap: _scrollToHome,
              child: _logo(
                width: 160,
                height: 65,
              ),
            ),

            const Spacer(),

            // MENU BUTTON
            IconButton(
              onPressed: () {
                setState(() {
                  _showMobileNav = !_showMobileNav;
                });
              },
              icon: Icon(
                _showMobileNav
                    ? Icons.close_rounded
                    : Icons.more_vert_rounded,
                size: 27,
                color: darkBrown,
              ),
            ),
          ],
        ),
      ),

      // MOBILE MENU
      if (_showMobileNav)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            15,
            0,
            15,
            12,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
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
              _mobileNavItem("Home"),
              _mobileNavItem("How It Works"),
              _mobileNavItem("About"),

              const SizedBox(height: 8),

                _profileMenu(),
                const SizedBox(width: 25),
            ],
          ),
        ),
    ],
  );
}

  // ============================================================
  // MOBILE NAV ITEM
  // ============================================================

 Widget _mobileNavItem(String title) {
  return InkWell(
    onTap: () {
      setState(() {
        _showMobileNav = false;
      });

      if (title == "Home") {
        _scrollToHome();
      }

      if (title == "How It Works") {
        _scrollToSection(_howItWorksKey);
      }

      if (title == "About") {
        _scrollToSection(_aboutKey);
      }
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
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
  // ============================================================
  // NAV TEXT
  // ============================================================

 Widget _navText(
  String text,
  Color color,
) {
  return InkWell(
    onTap: () {
      if (text == "Home") {
        _scrollToHome();
      }

      if (text == "How It Works") {
        _scrollToSection(_howItWorksKey);
      }

      if (text == "About") {
        _scrollToSection(_aboutKey);
      }
    },
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 8,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 800;

          return SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // NAVBAR
                  if (isMobile)
                    _mobileNavbar()
                  else
                    _navbar(),

                  // HERO
_buildHeroSection(),

// MY DESIGNS
_buildMyDesigns(),

// INSPIRATIONS
_buildInspirations(),


                    // HOW IT WORKS
                    _howItWorksSection(),

                    // ABOUT
                    _aboutSection(),

                ],
              ),
            ),
          );
        },
      ),
    );
  }

    // ============================================================
  // HOW IT WORKS
  // ============================================================

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

  // ============================================================
  // DESKTOP HOW IT WORKS STEP
  // ============================================================

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

  Widget _buildHeroSection() {
    return Container(
      height: 430,
      width: double.infinity,
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(25),
        image: const DecorationImage(
          image: NetworkImage(
           'https://images.unsplash.com/photo-1630699144035-c0f6311ec482?auto=format&fit=crop&w=1600&q=80',
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
                  'Your Space,\nYour Story.',
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

  // ============================================================
  // MY DESIGNS
  // ============================================================

  Widget _buildMyDesigns() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        35,
        35,
        35,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'My Designs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 12),

              Container(
                width: 55,
                height: 1,
                color: Colors.black54,
              ),

              const Spacer(),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All →',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildDesignList(),
        ],
      ),
    );
  }

  // ============================================================
  // DESIGN LIST
  // ============================================================

Widget _buildDesignList() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Center(
      child: Text("Please log in to view your designs"),
    );
  }

  return SizedBox(
    height: 230,
    child: StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Unable to load projects"),
          );
        }

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final projects = snapshot.data?.docs ?? [];

        if (projects.isEmpty) {
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildLetsDesignCard(),
            ],
          );
        }

        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            ...projects.map((doc) {
              final data = doc.data();

              return _buildDesignCard({
                'id': doc.id,
                'image': data['uploadedimg_url'] ?? '',
                'title': data['projectName'] ?? 'Untitled Project',
                'date': data['projectType'] ?? 'Room Design',
              });
            }),
            _buildLetsDesignCard(),
          ],
        );
      },
    ),
  );
}

  // ============================================================
  // USER DESIGN CARD
  // ============================================================

  Widget _buildDesignCard(Map<String, String> design) {
  return GestureDetector(
    onTap: () {
      final imageUrl = design['image'] ?? '';

      if (imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No image URL found for this project"),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectImagePage(
            imageUrl: imageUrl,
            projectName: design['title'] ?? 'My Design',
          ),
        ),
      );
    },
    child: Container(
      width: 250,
      margin: const EdgeInsets.only(right: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(15),
            ),
            child: Image.network(
              design['image'] ?? '',
              height: 145,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 145,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  design['title'] ?? 'Untitled Project',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  design['date'] ?? 'Room Design',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  // ============================================================
  // LET'S DESIGN NEW
  // ============================================================

  Widget _buildLetsDesignCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UplodeImg(),
          ),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(
          right: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EADF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFD7C8B4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                color: Color(0xFF654321),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Let's Design New",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                'Upload your room and bring it to life.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EXPLORE INSPIRATIONS
  // ============================================================

  Widget _buildInspirations() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        35,
        20,
        35,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'See Inspirations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 12),

              Container(
                width: 55,
                height: 1,
                color: Colors.black54,
              ),

              const Spacer(),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'See More →',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: inspirations.length,
              itemBuilder: (context, index) {
                final item = inspirations[index];

                return Container(
                  width: 320,
                  margin: const EdgeInsets.only(
                    right: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // IMAGE
                        Image.network(
                          item['image']!,
                          fit: BoxFit.cover,
                          loadingBuilder: (
                            context,
                            child,
                            loadingProgress,
                          ) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),

                        // DARK GRADIENT
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black87,
                                ],
                              ),
                            ),
                            child: Text(
                              item['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI DESIGN PAGE
// ============================================================












class ProjectImagePage extends StatelessWidget {
  final String imageUrl;
  final String projectName;

  const ProjectImagePage({
    super.key,
    required this.imageUrl,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const CircularProgressIndicator();
          },
          errorBuilder: (context, error, stackTrace) {
            return const Text("Unable to load image");
          },
        ),
      ),
    );
  }
}