import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ================= COLORS =================

  static const Color darkBrown = Color(0xFF2F2922);
  static const Color brown = Color(0xFF6B4528);
  static const Color olive = Color(0xFF514E25);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color fieldColor = Color(0xFFF8F6F2);

  // ================= CONTROLLERS =================

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // ================= VARIABLES =================

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;
  bool _showMobileNav = false;

  int currentImage = 0;
  Timer? imageTimer;

  // ================= ROOM IMAGES =================

  final List<String> roomImages = [
  'assets/images/hall.jpg',
  'assets/images/kitchen.jpg',
  'assets/images/gallery.jpg',
  'assets/images/bedroom.jpg',
  ];

  // ================= INIT =================

  @override
  void initState() {
    super.initState();

    imageTimer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (!mounted) return;

        setState(() {
          currentImage = (currentImage + 1) % roomImages.length;
        });
      },
    );
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    imageTimer?.cancel();

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ================= REGISTER =================

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

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
      showMessage('Password must be at least 6 characters.');
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
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      print("added to authentication");

        await FirebaseFirestore.instance.collection("users").add({
          "username": nameController.text.trim(),
          "email": emailController.text.trim(),
          "user_id": FirebaseAuth.instance.currentUser!.uid,
        });

        print("added to firestore");
      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'invalid-email':
          message = 'The email address is invalid.';
          break;

        case 'weak-password':
          message = 'Password is too weak.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection.';
          break;

        default:
          message = e.message ?? 'Registration failed.';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ================= MESSAGE =================

  void showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? olive : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================= LOGO =================

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

  // ================= DESKTOP NAVBAR =================

  Widget _navbar() {
    return Container(
      height: 78,
      color: cream,
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child:  Row(
  children: [

    // =========================
    // LOGO - LEFT
    // =========================
    _logo(
      width: 200,
      height: 70,
    ),

    const Spacer(),

    // =========================
    // NAVBAR - RIGHT
    // =========================
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        _navText(
          "Home",
          const Color(0xFF2F2922),
        ),
        
        const SizedBox(width: 35),
        
        _navText(
          "How It Works",
          const Color(0xFF2F2922),
        ),
        
        const SizedBox(width: 35),
        
        _navText(
          "About",
          const Color(0xFF2F2922),
        ),
        
        const SizedBox(width: 35),
        
        // GET STARTED
        Container(
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
      ],
    ),

    const SizedBox(width: 25),
  ],
),
    );
  }

  // ================= MOBILE NAVBAR =================
Widget _mobileNavbar(Color brown) {
  return Column(
    children: [
      // TOP BAR
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 7,
        ),
        child: Row(
          children: [
            _logo(
              width: 160,
              height: 65,
            ),

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
                    : Icons.more_vert_rounded,
                size: 27,
                color: const Color(0xFF2F2922),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------- MOBILE NAVBAR 

      // DROPDOWN NAVIGATION
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
              _mobileNavItem("Features"),
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
Widget _mobileNavItem(String title) {
  return InkWell(
    onTap: () {
      setState(() {
        _showMobileNav = false;
      });
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
          color: Color(0xFF2F2922),
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

  // ================= ROOM IMAGE =================

  Widget _roomImage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      child: Image.asset(
        roomImages[currentImage],
        key: ValueKey(currentImage),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
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

  // ================= DESKTOP IMAGE SECTION =================

  Widget _imageSection() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: _roomImage(),
            ),

            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.18),
              ),
            ),

            // MAIN TEXT
            Positioned(
              left: 35,
              top: 45,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CREATE YOUR SPACE',
                    style: TextStyle(
                      color: olive,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Turn Spaces\nInto Stories',
                    style: TextStyle(
                      color: olive,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
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

            // BOTTOM TEXT
            const Positioned(
              left: 35,
              bottom: 30,
              child: Text(
                'Beautiful spaces\nhappier lives.',
                style: TextStyle(
                  color: olive,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TEXT FIELD =================

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
        prefixIcon: const Icon(
          Icons.person_outline,
          color: olive,
          size: 20,
        ),
        suffixIcon: onSuffixPressed != null
            ? IconButton(
                onPressed: onSuffixPressed,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: olive,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: olive,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  // ================= REGISTER FORM =================

  Widget _registerForm() {
    return Container(
      color: cream,
      padding: const EdgeInsets.symmetric(
        horizontal: 35,
        vertical: 25,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                color: olive,
                fontSize: 30,
                fontWeight: FontWeight.w700,
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

            _textField(
              controller: nameController,
              hint: 'Full Name',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 14),

            _textField(
              controller: emailController,
              hint: 'Email Address',
              icon: Icons.email_outlined,
            ),

            const SizedBox(height: 14),

            _textField(
              controller: passwordController,
              hint: 'Password',
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              onSuffixPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),

            const SizedBox(height: 14),

            _textField(
              controller: confirmPasswordController,
              hint: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: obscureConfirmPassword,
              onSuffixPressed: () {
                setState(() {
                  obscureConfirmPassword =
                      !obscureConfirmPassword;
                });
              },
            ),

            const SizedBox(height: 24),

            // CREATE ACCOUNT BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: olive,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      olive.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
                    color: olive.withOpacity(0.3),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: olive,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                Expanded(
                  child: Divider(
                    color: olive.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // GOOGLE BUTTON
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: olive,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // LOGIN
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: olive,
                      fontSize: 13,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: olive,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  // ================= MOBILE IMAGE =================

  Widget _mobileImage() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        height: 330,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: _roomImage(),
              ),

              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.18),
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
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Turn Spaces\nInto Stories',
                      style: TextStyle(
                        color: olive,
                        fontSize: 31,
                        fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MOBILE FORM =================

  Widget _mobileForm() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        22,
        28,
        22,
        25,
      ),
      child: _registerForm(),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile =
              constraints.maxWidth < 800;

          // ================= MOBILE =================

          if (isMobile) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _mobileNavbar(brown),
                    _mobileImage(),
                    _mobileForm(),
                  ],
                ),
              ),
            );
          }

          // ================= DESKTOP =================

          return SafeArea(
            child: Column(
              children: [
                _navbar(),

                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _imageSection(),
                      ),

                      Expanded(
                        flex: 4,
                        child: _registerForm(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _navText(
    String text,
    Color color,
  ) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}