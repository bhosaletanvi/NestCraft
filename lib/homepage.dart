import 'package:flutter/material.dart';

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

  // ============================================================
  // MY DESIGNS
  // ============================================================

  // Empty for now.
  // Later we can load the user's designs from Firebase.

  final List<Map<String, String>> myDesigns = [];

  // ============================================================
  // EXPLORE INSPIRATIONS
  // ============================================================

  final List<Map<String, String>> inspirations = [
    {
      'title': 'Modern Living',
      'image':
          'https://i.pinimg.com/736x/16/0b/7d/160b7db69aeaf05160336567487956c7.jpg',
    },
    {
      'title': 'Warm Bedroom',
      'image':
          'https://i.pinimg.com/1200x/9c/63/73/9c6373da660106e1ef5a3db929180e3b.jpg',
    },
    {
      'title': 'Minimal Kitchen',
      'image':
          'https://i.pinimg.com/736x/cd/97/7b/cd977b027e14aa3e12841ef7b08ad01e.jpg',
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
          // LOGO
          GestureDetector(
            onTap: _scrollToHome,
            child: _logo(
              width: 200,
              height: 70,
            ),
          ),

          const Spacer(),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navText(
                "Home",
                darkBrown,
              ),

              const SizedBox(width: 35),

              _navText(
                "How It Works",
                darkBrown,
              ),

              const SizedBox(width: 35),

              _navText(
                "About",
                darkBrown,
              ),

              const SizedBox(width: 35),

              // GET STARTED
              GestureDetector(
                onTap: _scrollToHome,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 23,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: brown,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Get Started",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(width: 8),

                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 25),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE NAVBAR
  // ============================================================

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

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showMobileNav = false;
                      });

                      _scrollToHome();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Get Started",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HERO SECTION
  // ============================================================

  Widget _buildHeroSection() {
    return Container(
      height: 430,
      width: double.infinity,
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        image: const DecorationImage(
          image: AssetImage(
            'assets/images/hero_room.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(45),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.white.withOpacity(0.35),
              Colors.transparent,
            ],
          ),
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
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Your Space,\nYour Story.',
                  style: TextStyle(
                    fontSize: 48,
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
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search),

                      SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          'Search designs, rooms or styles...',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      Icon(Icons.tune),
                    ],
                  ),
                ),
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
    return SizedBox(
      height: 230,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...myDesigns.map(
            (design) => _buildDesignCard(design),
          ),

          // LET'S DESIGN CARD
          _buildLetsDesignCard(),
        ],
      ),
    );
  }

  // ============================================================
  // USER DESIGN CARD
  // ============================================================

  Widget _buildDesignCard(
    Map<String, String> design,
  ) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(
        right: 18,
      ),
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
              design['image']!,
              height: 145,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  height: 145,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                    ),
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
                  design['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  design['date']!,
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
            builder: (context) => const AIDesignPage(),
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
                'Explore Inspirations',
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

class AIDesignPage extends StatelessWidget {
  const AIDesignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0E8),
        elevation: 0,
        title: const Text(
          'Create Your Design',
          style: TextStyle(
            color: Color(0xFF2F2922),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF2F2922),
        ),
      ),
      body: const Center(
        child: Text(
          'AI Interior Designer\n\n'
          'We will build this screen next.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            color: Color(0xFF2F2922),
          ),
        ),
      ),
    );
  }
}

