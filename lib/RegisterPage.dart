import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color darkBrown = Color(0xFF2F2922);
  static const Color brown = Color(0xFF6B4528);
  static const Color olive = Color(0xFF514E25);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color fieldColor = Color(0xFFF8F6F2);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // ============================================================
  // SCROLL
  // ============================================================

  final ScrollController _scrollController =
      ScrollController();

  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  // ============================================================
  // VARIABLES
  // ============================================================

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;
  bool _showMobileNav = false;

  int currentImage = 0;
  Timer? imageTimer;

  // ============================================================
  // ROOM IMAGES
  // ============================================================

  final List<String> roomImages = [
    'assets/images/hall.jpg',
    'assets/images/kitchen.jpg',
    'assets/images/gallery.jpg',
    'assets/images/bedroom.jpg',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    imageTimer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (!mounted) return;

        setState(() {
          currentImage =
              (currentImage + 1) % roomImages.length;
        });
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    imageTimer?.cancel();

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // SCROLL TO SECTION
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
  // REGISTER USER
  // ============================================================

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword =
        confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Please fill all fields.');
      return;
    }

    if (!email.contains('@')) {
      showMessage('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password must be at least 6 characters.',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      showMessage(
        'Account created successfully!',
        success: true,
      );

      await Future.delayed(
        const Duration(milliseconds: 800),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'This email is already registered.';
          break;

        case 'invalid-email':
          message =
              'The email address is invalid.';
          break;

        case 'weak-password':
          message = 'Password is too weak.';
          break;

        case 'network-request-failed':
          message =
              'Please check your internet connection.';
          break;

        default:
          message =
              e.message ?? 'Registration failed.';
      }

      showMessage(message);
    } catch (e) {
      showMessage(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? olive : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
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
        'assets/nestcraft.png',
        fit: BoxFit.contain,
        errorBuilder:
            (context, error, stackTrace) {
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
      padding:
          const EdgeInsets.symmetric(horizontal: 35),
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

          _navText("Home"),
          const SizedBox(width: 35),

          _navText("How It Works"),
          const SizedBox(width: 35),

          _navText("About"),
          const SizedBox(width: 35),

          GestureDetector(
            onTap: _scrollToHome,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 23,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: brown,
                borderRadius:
                    BorderRadius.circular(30),
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

          const SizedBox(width: 25),
        ],
      ),
    );
  }

  // ============================================================
  // NAV TEXT
  // ============================================================

  Widget _navText(String text) {
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
        padding:
            const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: olive,
            fontWeight: FontWeight.w500,
          ),
        ),
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
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 7,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _scrollToHome,
                child: _logo(
                  width: 160,
                  height: 65,
                ),
              ),

              const Spacer(),

              IconButton(
                onPressed: () {
                  setState(() {
                    _showMobileNav =
                        !_showMobileNav;
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

        if (_showMobileNav)
          Container(
            width: double.infinity,
            margin:
                const EdgeInsets.fromLTRB(
              15,
              0,
              15,
              12,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF8F5EF),
              borderRadius:
                  BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.08),
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
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          25,
                        ),
                      ),
                    ),
                    child: const Text(
                      "Get Started",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
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

        if (title == "How It Works") {
          _scrollToSection(
            _howItWorksKey,
          );
        }

        if (title == "About") {
          _scrollToSection(_aboutKey);
        }
      },
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
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
  // ROOM IMAGE
  // ============================================================

  Widget _roomImage() {
    return AnimatedSwitcher(
      duration:
          const Duration(milliseconds: 900),
      child: Image.asset(
        roomImages[currentImage],
        key: ValueKey(currentImage),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            color: cream,
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 60,
                color: olive,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP IMAGE SECTION
  // ============================================================

  Widget _imageSection() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: _roomImage(),
            ),

            Positioned.fill(
              child: Container(
                color:
                    Colors.black.withOpacity(0.18),
              ),
            ),

            Positioned(
              left: 35,
              top: 45,
              right: 30,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CREATE YOUR SPACE',
                    style: TextStyle(
                      color: olive,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Turn Spaces\nInto Stories',
                    style: TextStyle(
                      color: olive,
                      fontSize: 42,
                      fontWeight:
                          FontWeight.w700,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Transform your room into a space that truly feels like you.',
                    style: TextStyle(
                      color: olive,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Positioned(
              left: 35,
              bottom: 30,
              child: Text(
                'Beautiful spaces\nhappier lives.',
                style: TextStyle(
                  color: olive,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onSuffixPressed,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: darkBrown,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,

        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),

        // FIXED:
        // Now it uses the icon passed to the function.
        prefixIcon: Icon(
          icon,
          color: olive,
          size: 20,
        ),

        suffixIcon:
            onSuffixPressed != null
                ? IconButton(
                    onPressed:
                        onSuffixPressed,
                    icon: Icon(
                      obscureText
                          ? Icons
                              .visibility_off_outlined
                          : Icons
                              .visibility_outlined,
                      color: olive,
                      size: 20,
                    ),
                  )
                : null,

        filled: true,
        fillColor: fieldColor,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color: olive,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REGISTER FORM
  // ============================================================

  Widget _registerForm() {
    return Container(
      color: cream,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 35,
        vertical: 25,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                color: olive,
                fontSize: 30,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create your account and start transforming your space.',
              style: TextStyle(
                color: olive,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            // NAME
            _textField(
              controller: nameController,
              hint: 'Full Name',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            // EMAIL
            _textField(
              controller: emailController,
              hint: 'Email Address',
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 14),

            // PASSWORD
            _textField(
              controller: passwordController,
              hint: 'Password',
              icon: Icons.lock_outline,
              obscureText:
                  obscurePassword,
              onSuffixPressed: () {
                setState(() {
                  obscurePassword =
                      !obscurePassword;
                });
              },
            ),

            const SizedBox(height: 14),

            // CONFIRM PASSWORD
            _textField(
              controller:
                  confirmPasswordController,
              hint: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText:
                  obscureConfirmPassword,
              onSuffixPressed: () {
                setState(() {
                  obscureConfirmPassword =
                      !obscureConfirmPassword;
                });
              },
            ),

            const SizedBox(height: 25),

            // REGISTER BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : registerUser,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: olive,
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      olive.withOpacity(0.6),
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 22),

            // OR
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color:
                        olive.withOpacity(
                      0.3,
                    ),
                  ),
                ),

                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: olive,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Expanded(
                  child: Divider(
                    color:
                        olive.withOpacity(
                      0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // GOOGLE
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  showMessage(
                    'Google Sign-In coming soon.',
                  );
                },
                icon: const Icon(
                  Icons.g_mobiledata,
                  color: olive,
                  size: 27,
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: olive,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
                  side:
                      const BorderSide(
                    color: olive,
                    width: 1.2,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LOGIN
            Center(
              child: Wrap(
                alignment:
                    WrapAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: olive,
                      fontSize: 13,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: olive,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE IMAGE
  // ============================================================

  Widget _mobileImage() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 330,
        width: double.infinity,
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: _roomImage(),
              ),

              Positioned.fill(
                child: Container(
                  color:
                      Colors.black.withOpacity(
                    0.18,
                  ),
                ),
              ),

              Positioned(
                left: 25,
                top: 35,
                right: 20,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CREATE YOUR SPACE',
                      style: TextStyle(
                        color: olive,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Turn Spaces\nInto Stories',
                      style: TextStyle(
                        color: olive,
                        fontSize: 31,
                        fontWeight:
                            FontWeight.w700,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Transform your room into a space that truly feels like you.',
                      style: TextStyle(
                        color: olive,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const Positioned(
                left: 25,
                bottom: 25,
                child: Text(
                  'Beautiful spaces\nhappier lives.',
                  style: TextStyle(
                    color: olive,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
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

          const SizedBox(height: 60),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: brown,
              borderRadius:
                  BorderRadius.circular(40),
            ),
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  "Ready to reimagine your space?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                SizedBox(width: 15),

                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ],
            ),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: LayoutBuilder(
        builder:
            (context, constraints) {
          final bool isMobile =
              constraints.maxWidth < 800;

          // ==================================================
          // MOBILE
          // ==================================================

          if (isMobile) {
            return SafeArea(
              child:
                  SingleChildScrollView(
                controller:
                    _scrollController,
                child: Column(
                  children: [
                    // NAVBAR
                    _mobileNavbar(),

                    // HOME
                    _mobileImage(),

                    // REGISTER FORM
                    _registerForm(),

                    // HOW IT WORKS
                    _howItWorksSection(),

                    // ABOUT
                    _aboutSection(),
                  ],
                ),
              ),
            );
          }

          // ==================================================
          // DESKTOP
          // ==================================================

          final double mainHeight =
              constraints.maxHeight > 78
                  ? constraints.maxHeight - 78
                  : 650;

          return SafeArea(
            child:
                SingleChildScrollView(
              controller:
                  _scrollController,
              child: Column(
                children: [
                  // NAVBAR
                  _navbar(),

                  // ==================================================
                  // HOME / REGISTER SECTION
                  // ==================================================

                  SizedBox(
                    height: mainHeight,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child:
                              _imageSection(),
                        ),

                        Expanded(
                          flex: 4,
                          child:
                              _registerForm(),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // HOW IT WORKS
                  // ==================================================

                  _howItWorksSection(),

                  // ==================================================
                  // ABOUT
                  // ==================================================

                  _aboutSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}