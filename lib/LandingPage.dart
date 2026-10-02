import 'dart:async';

import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // ------------------------------------------------------------
  // INTERIOR IMAGES
  // ------------------------------------------------------------

  final List<String> interiorImages = [
  'assets/images/hall.jpg',
  'assets/images/kitchen.jpg',
  'assets/images/gallery.jpg',
  'assets/images/bedroom.jpg',
];

  int currentImageIndex = 0;

  Timer? slideshowTimer;

  @override
  void initState() {
    super.initState();

    // Change background image every 4 seconds
    slideshowTimer = Timer.periodic(
      const Duration(seconds: 4),
      (timer) {
        if (!mounted) return;

        setState(() {
          currentImageIndex =
              (currentImageIndex + 1) % interiorImages.length;
        });
      },
    );
  }

  @override
  void dispose() {
    slideshowTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ======================================================
          // FULL SCREEN BACKGROUND IMAGE
          // ======================================================

          Positioned.fill(
            child: Image.asset(
              interiorImages[currentImageIndex],
              key: ValueKey(currentImageIndex),
              fit: BoxFit.cover,
            ),
          ),

          // ======================================================
          // DARK OVERLAY
          // ======================================================

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [
                    0.0,
                    0.45,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // SAFE AREA
          // ======================================================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                18,
                22,
                24,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ==================================================
                  // TOP BAR
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      // BRAND LOGO ICON + NAME
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/nestcraft.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          
                        ],
                      ),

                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // MAIN CONTENT
                  // ==================================================

                  const Spacer(),

                  // --------------------------------------------------
                  // SMALL LABEL
                  // --------------------------------------------------

                  Row(
                    children: [

                      Container(
                        width: 28,
                        height: 1,
                        color: Colors.white,
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        'INTERIOR DESIGN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // --------------------------------------------------
                  // MAIN HEADING
                  // --------------------------------------------------

                  const Text(
                    'Design Your\nDream Space.',
                    style: TextStyle(
                      fontSize: 39,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // --------------------------------------------------
                  // SMALLER SLOGAN
                  // --------------------------------------------------

                  const Text(
                    'Create spaces that reflect your style.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // DESCRIPTION CARD
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),

                    // decoration: BoxDecoration(
                    //   color: Colors.white.withOpacity(0.18),
                    //   borderRadius:
                    //       BorderRadius.circular(20),
                    //   border: Border.all(
                    //     color: Colors.white.withOpacity(0.25),
                    //   ),
                    // ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Container(
                          width: 38,
                          height: 38,

                          // decoration: BoxDecoration(
                          //   color: Colors.white.withOpacity(0.20),
                          //   borderRadius:
                          //       BorderRadius.circular(12),
                          // ),

                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 19,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Container(
                          child: Column(
                            
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                          
                            children: [
                          
                              Text(
                                'Beautiful spaces, your way.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                          
                              SizedBox(height: 4),
                          
                              Text(
                                'Explore inspiring interiors and '
                                'bring your dream home to life.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // SLIDESHOW INDICATORS
                  // ==================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: List.generate(
                      interiorImages.length,
                      (index) {

                        final bool isSelected =
                            index == currentImageIndex;

                        return AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 250),

                          margin:
                              const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),

                          width: isSelected ? 22 : 6,
                          height: 6,

                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.45),

                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ==================================================
                  // SMALLER START DESIGNING BUTTON
                  // ==================================================

                  Center(
                    child: SizedBox(
                      width: 230,
                      height: 48,

                      child: ElevatedButton(
                        onPressed: () {
                          // TODO:
                          // Navigate to next page here.
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color(0xFF292720),

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),

                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [

                            Text(
                              'START DESIGNING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w700,
                                letterSpacing: 1.3,
                              ),
                            ),

                            SizedBox(width: 9),

                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}