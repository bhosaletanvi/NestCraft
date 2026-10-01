import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

final List<String> roomImages = [
  'assets/images/hall.jpg',
  'assets/images/kitchen.jpg',
  'assets/images/gallery.jpg',
  'assets/images/bedroom.jpg',
];
Timer? _imageTimer;
final PageController _pageController = PageController();
int _currentImage = 0;

@override
void initState() {
  super.initState();

  _imageTimer = Timer.periodic(
    const Duration(seconds: 2),
    (timer) {
      if (!_pageController.hasClients) return;

      _currentImage++;

      if (_currentImage >= roomImages.length) {
        _currentImage = 0;
      }

      _pageController.animateToPage(
        _currentImage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    },
  );
}

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ============================================================
  // LOGIN
  // ============================================================

 Future<void> loginUser() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Login successful!"),
        backgroundColor: Color(0xFF514E25),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // NO NAVIGATOR HERE
    // AuthWrapper handles navigation automatically.
  }

  // ============================================================
  // FIREBASE ERROR HANDLING
  // ============================================================

  on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String message;

    switch (e.code) {
      case 'user-not-found':
        message = "No account found with this email.";
        break;

      case 'wrong-password':
      case 'invalid-credential':
        message = "Incorrect email or password.";
        break;

      case 'invalid-email':
        message = "Please enter a valid email address.";
        break;

      case 'user-disabled':
        message = "This account has been disabled.";
        break;

      case 'too-many-requests':
        message = "Too many attempts. Please try again later.";
        break;

      case 'network-request-failed':
        message =
            "Network error. Please check your internet connection.";
        break;

      default:
        message =
            e.message ?? "Login failed. Please try again.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================================
  // GENERAL ERROR
  // ============================================================

  catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Something went wrong. Please try again.",
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
  @override
  void dispose() {
     _imageTimer?.cancel();
  _pageController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  bool _showMobileNav = false;

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF2F2922);
    const Color brown = Color(0xFF6B4528);
    const Color olive = Color(0xFF514E25);
    const Color cream = Color(0xFFF5F0E8);
    const Color fieldColor = Color(0xFFF8F6F2);

    return Scaffold(
      backgroundColor: cream,

      body: LayoutBuilder(
        builder: (context, constraints) {
      
          // ======================================================
          // MOBILE
          // ======================================================
      
          if (constraints.maxWidth < 700) {
            return _mobileLogin(
              context,
              darkBrown,
              brown,
              olive,
              cream,
              fieldColor,
            );
          }
      
          // ======================================================
          // DESKTOP
          // ======================================================
      
          return _desktopLogin(
            context,
            darkBrown,
            brown,
            olive,
            cream,
            fieldColor,
          );
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP LOGIN
  // ============================================================

  Widget _desktopLogin(
    BuildContext context,
    Color darkBrown,
    Color brown,
    Color olive,
    Color cream,
    Color fieldColor,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
      
          // ==================================================
          // NAVBAR
          // ==================================================
      Row(
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
      
          // ==================================================
          // MAIN CONTENT
          // ==================================================
      
          SizedBox(
            height: 750,
      
            child: Row(
              children: [
      
                // =================================================
                // LEFT IMAGE / INTRO
                // =================================================
      
                Expanded(
                  flex: 6,
      
                  child: Stack(
                    children: [
      
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.only(
                          bottomLeft:
                              Radius.circular(18),
                        ),
      
                        child: SizedBox.expand(
                       child: PageView.builder(
  controller: _pageController,
  itemCount: roomImages.length,
  physics: const NeverScrollableScrollPhysics(),

  itemBuilder: (context, index) {
    return Image.asset(
      roomImages[index],
      fit: BoxFit.cover,
    );
  },
),
                        ),
                      ),
      
                      // DARK GRADIENT
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin:
                                  Alignment.topCenter,
                              end:
                                  Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black
                                    .withOpacity(0.15),
                              ],
                            ),
                          ),
                        ),
                      ),
      
                      // TEXT
                      Positioned(
                        left: 65,
                        top: 75,
      
                        child: SizedBox(
                          width: 390,
      
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
      
                            children: [
      
                              Row(
                                children: [
                                  const Text(
                                    "WELCOME BACK",
                                    style: TextStyle(
                                      color:
                                          Color(0xFF6B4528),
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
      
                                  const SizedBox(
                                      width: 15),
      
                                  Container(
                                    height: 1,
                                    width: 75,
                                    color:
                                        const Color(
                                      0xFF6B4528,
                                    ),
                                  ),
                                ],
                              ),
      
                              const SizedBox(height: 18),
      
                              const Text(
                                "Turn Spaces\nInto Stories",
                                style: TextStyle(
                                  fontSize: 45,
                                  height: 1.0,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      Color(0xFF17130F),
                                ),
                              ),
      
                              const SizedBox(height: 15),
      
                              const Text(
                                "Login to continue designing beautiful\n"
                                "interiors, save your ideas and explore\n"
                                "new inspirations.",
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color:
                                      Color(0xFF3D352D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
      
                      // BOTTOM MESSAGE
                      Positioned(
                        left: 45,
                        bottom: 35,
      
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
      
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEE3)
                                .withOpacity(0.94),
      
                            borderRadius:
                                BorderRadius.circular(18),
                          ),
      
                          child: const Row(
                            children: [
      
                              Icon(
                                Icons
                                    .spa_outlined,
                                color:
                                    Color(0xFF6B4528),
                                size: 28,
                              ),
      
                              SizedBox(width: 12),
      
                              Text(
                                "Beautiful spaces\n"
                                "happier lives.",
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color:
                                      Color(0xFF3D352D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      
                // =================================================
                // RIGHT LOGIN
                // =================================================
      
                Expanded(
                  flex: 4,
      
                  child: Container(
                    padding: const EdgeInsets.all(35),
      
                    child: _loginForm(
                      context,
                      darkBrown,
                      brown,
                      olive,
                      fieldColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  // ============================================================
  // MOBILE LOGIN
  // ============================================================

  Widget _mobileLogin(
    BuildContext context,
    Color darkBrown,
    Color brown,
    Color olive,
    Color cream,
    Color fieldColor,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [

          // navbar
         _mobileNavbar(brown),

          // ROOM IMAGE
          SizedBox(
            height: 350,
            width: double.infinity,

           child: SizedBox.expand(
                       child: PageView.builder(
  controller: _pageController,
  itemCount: roomImages.length,
  physics: const NeverScrollableScrollPhysics(),

  itemBuilder: (context, index) {
    return Image.asset(
      roomImages[index],
      fit: BoxFit.cover,
    );
  },
),
                        ),
          ),

          // LOGIN AREA
          Container(
            padding: const EdgeInsets.fromLTRB(
              24,
              30,
              24,
              30,
            ),

            decoration: const BoxDecoration(
              color: Color(0xFFF8F4EC),

              borderRadius: BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),

            child: _loginForm(
              context,
              darkBrown,
              brown,
              olive,
              fieldColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN FORM
  // ============================================================

  Widget _loginForm(
    BuildContext context,
    Color darkBrown,
    Color brown,
    Color olive,
    Color fieldColor,
  ) {
    return Form(
      key: _formKey,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // TITLE
          const Text(
            "Login",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17130F),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            "Welcome back! Please login to your account.",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF514A42),
            ),
          ),

          const SizedBox(height: 28),

          // NAME
          _fieldLabel("NAME"),

          const SizedBox(height: 7),

          TextFormField(
            controller: nameController,

            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return "Please enter your name";
              }

              return null;
            },

            decoration: _inputDecoration(
              hint: "Name",
              icon: Icons.person_outline_rounded,
              fieldColor: fieldColor,
            ),
          ),

          const SizedBox(height: 13),

          // EMAIL
          _fieldLabel("EMAIL"),

          const SizedBox(height: 7),

          TextFormField(
            controller: emailController,

            keyboardType:
                TextInputType.emailAddress,

            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return "Please enter your email";
              }

              if (!value.contains("@")) {
                return "Please enter a valid email";
              }

              return null;
            },

            decoration: _inputDecoration(
              hint: "Email",
              icon: Icons.mail_outline_rounded,
              fieldColor: fieldColor,
            ),
          ),

          const SizedBox(height: 13),

          // PASSWORD
          _fieldLabel("PASSWORD"),

          const SizedBox(height: 7),

          TextFormField(
            controller: passwordController,

            obscureText: _obscurePassword,

            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return "Please enter your password";
              }

              return null;
            },

            decoration: _inputDecoration(
              hint: "Password",
              icon: Icons.lock_outline_rounded,
              fieldColor: fieldColor,
            ).copyWith(

              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },

                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,

                  size: 18,
                  color: const Color(0xFF665C51),
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          // REMEMBER / FORGOT
          Row(
            children: [

              SizedBox(
                height: 20,
                width: 20,

                child: Checkbox(
                  value: false,
                  onChanged: (value) {},
                  activeColor: olive,
                  side: const BorderSide(
                    color: Color(0xFF8A806F),
                  ),
                ),
              ),

              const SizedBox(width: 5),

              const Text(
                "Remember me",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF554A3E),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: () {
                  // Forgot password
                },

                child: const Text(
                  "Forgot password?",
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF654522),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // LOGIN BUTTON
          SizedBox(
            width: double.infinity,
            height: 51,

            child: ElevatedButton(
              onPressed:
                  _isLoading ? null : loginUser,

              style: ElevatedButton.styleFrom(
                backgroundColor: olive,
                foregroundColor: Colors.white,
                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(28),
                ),
              ),

              child: _isLoading
                  ? const SizedBox(
                      height: 21,
                      width: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        SizedBox(width: 9),

                        Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 18),

          // OR
          Row(
            children: [

              Expanded(
                child: Divider(
                  color: Colors.grey
                      .withOpacity(0.25),
                ),
              ),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 12,
                ),

                child: Text(
                  "OR",
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF81776B),
                  ),
                ),
              ),

              Expanded(
                child: Divider(
                  color: Colors.grey
                      .withOpacity(0.25),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          // GOOGLE
          SizedBox(
            width: double.infinity,
            height: 47,

            child: OutlinedButton(
              onPressed: () {
                // Google Sign-In
              },

              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.grey
                      .withOpacity(0.35),
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(25),
                ),
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [

                  const Text(
                    "G",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Text(
                    "Continue with Google",
                    style: TextStyle(
                      color: Color(0xFF2F2922),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // REGISTER
          Center(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF62584D),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegisterPage(),
                      ),
                    );
                  },

                  child: const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF654522),
                      fontWeight: FontWeight.bold,
                    ),
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
  // LOGO
  // ============================================================

  Widget _logo({
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,

      child: Image.asset(
        'assets/images/nestcraft.png',
        fit: BoxFit.contain,

        errorBuilder:
            (context, error, stack) {
          return const Row(
            children: [

              Icon(
                Icons.home_outlined,
                color: Color(0xFF654522),
                size: 30,
              ),

              SizedBox(width: 7),

              Text(
                "DesignNest",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F2922),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // FIELD LABEL
  // ============================================================

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: Color(0xFF51483D),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color fieldColor,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF8B8277),
      ),

      prefixIcon: Icon(
        icon,
        size: 19,
        color: const Color(0xFF51483D),
      ),

      filled: true,
      fillColor: fieldColor,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFF6B4528),
          width: 1.4,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
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

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: const Center(
        child: Text('Register Page'),
      ),
    );
  }
}

