import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UplodeImg extends StatefulWidget {
  const UplodeImg({super.key});

  @override
  State<UplodeImg> createState() => _UplodeImgState();
}

class _UplodeImgState extends State<UplodeImg> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color cream = Color(0xFFF7F1E8);
  static const Color lightCream = Color(0xFFF8F5EF);
  static const Color olive = Color(0xFF6F7654);
  static const Color brown = Color(0xFF6B4325);
  static const Color darkBrown = Color(0xFF3E2C1E);
  static const Color lightBrown = Color(0xFF9A795A);

  // ============================================================
  // VARIABLES
  // ============================================================

  int selectedRoom = 0;
  int selectedBudget = 0;

  Uint8List? uploadedImageBytes;

  final ImagePicker imagePicker = ImagePicker();

  // ============================================================
  // ROOM TYPES
  // ============================================================

  final List<Map<String, dynamic>> roomTypes = [
    {
      "name": "Living Room",
      "icon": Icons.weekend_outlined,
    },
    {
      "name": "Bedroom",
      "icon": Icons.bed_outlined,
    },
    {
      "name": "Kitchen",
      "icon": Icons.kitchen_outlined,
    },
    {
      "name": "Dining Room",
      "icon": Icons.restaurant_outlined,
    },
    {
      "name": "Office",
      "icon": Icons.desk_outlined,
    },
  ];

  // ============================================================
  // BUDGET
  // ============================================================

  final List<String> budgets = [
    "Under ₹50,000",
    "₹50,000 - ₹1 Lakh",
    "₹1 Lakh - ₹2 Lakh",
    "Above ₹2 Lakh",
  ];

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> pickImage() async {
    try {
      final XFile? pickedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedImage == null) {
        return;
      }

      final Uint8List bytes = await pickedImage.readAsBytes();

      setState(() {
        uploadedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to select image: $e"),
        ),
      );
    }
  }

  // ============================================================
  // NAVBAR
  // Same navbar as Login Page
  // ============================================================

  Widget _navbar() {
    return Container(
      height: 78,
      color: cream,
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Row(
        children: [
          // ------------------------------------------------------
          // LOGO
          // ------------------------------------------------------

          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: _logo(
              width: 200,
              height: 70,
            ),
          ),

          const Spacer(),

          // ------------------------------------------------------
          // NAVIGATION
          // ------------------------------------------------------

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

              // ------------------------------------------------
              // PROFILE BUTTON
              // ------------------------------------------------

              GestureDetector(
                onTap: () {},
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
                        "profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(width: 8),

                      Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
        'assets/images/nestcraft.png',
        fit: BoxFit.contain,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
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
  // NAV TEXT
  // ============================================================

  Widget _navText(
    String text,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        if (text == "Home") {
          Navigator.pop(context);
        }
      },
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // ROOM TYPE CARD
  // ============================================================

  Widget _roomCard(
    int index,
    String title,
    IconData icon,
  ) {
    final bool selected = selectedRoom == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRoom = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 145,
        height: 120,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? brown : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? brown
                : lightBrown.withOpacity(0.25),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: selected ? Colors.white : olive,
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : darkBrown,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUDGET CARD
  // ============================================================

  Widget _budgetCard(
    int index,
    String title,
  ) {
    final bool selected = selectedBudget == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBudget = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: selected ? brown : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? brown
                : lightBrown.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 20,
              color: selected
                  ? Colors.white
                  : olive,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : darkBrown,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPLOAD IMAGE BOX
  // ============================================================

  Widget _uploadImageBox() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        width: double.infinity,
        height: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: olive.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: uploadedImageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: cream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: olive,
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "Upload Room Image",
                    style: TextStyle(
                      color: darkBrown,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Click here to choose an image",
                    style: TextStyle(
                      color: lightBrown,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "JPG, PNG or JPEG",
                    style: TextStyle(
                      color: lightBrown,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        uploadedImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            uploadedImageBytes = null;
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 15,
                      left: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),

                            SizedBox(width: 8),

                            Text(
                              "Image uploaded successfully",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
  // MODIFY DESIGN BUTTON
  // ============================================================

  Widget _modifyDesignButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: uploadedImageBytes == null
            ? null
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Design customization will be available here.",
                    ),
                  ),
                );
              },
        icon: const Icon(
          Icons.auto_awesome,
          size: 19,
        ),
        label: const Text(
          "Modify Design",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              lightBrown.withOpacity(0.25),
          disabledForegroundColor:
              Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXISTING ELEMENTS
  // ============================================================

  Widget _existingElements() {
    final List<Map<String, dynamic>> elements = [
      {
        "name": "Sofa",
        "icon": Icons.weekend_outlined,
      },
      {
        "name": "Table",
        "icon": Icons.table_restaurant_outlined,
      },
      {
        "name": "Lamp",
        "icon": Icons.light_outlined,
      },
      {
        "name": "Chair",
        "icon": Icons.chair_outlined,
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: lightBrown.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Existing Elements",
            style: TextStyle(
              color: darkBrown,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 15),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: elements.map((element) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      element["icon"],
                      color: olive,
                      size: 18,
                    ),

                    const SizedBox(width: 7),

                    Text(
                      element["name"],
                      style: const TextStyle(
                        color: darkBrown,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _mainContent() {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 45,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                const Text(
                  "Create Your Dream Space",
                  style: TextStyle(
                    color: darkBrown,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Upload your room image and tell us what kind of space you want to create.",
                  style: TextStyle(
                    color: lightBrown,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                // ------------------------------------------------
                // TWO COLUMN LAYOUT
                // ------------------------------------------------

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // LEFT SIDE
                    // ============================================

                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "1. Upload Your Room",
                            style: TextStyle(
                              color: darkBrown,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 15),

                          _uploadImageBox(),

                          const SizedBox(height: 25),

                          _existingElements(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 35),

                    // ============================================
                    // RIGHT SIDE
                    // ============================================

                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "2. Select Room Type",
                            style: TextStyle(
                              color: darkBrown,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(
                              roomTypes.length,
                              (index) {
                                return _roomCard(
                                  index,
                                  roomTypes[index]["name"],
                                  roomTypes[index]["icon"],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 30),

                          const Text(
                            "3. Select Your Budget",
                            style: TextStyle(
                              color: darkBrown,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Column(
                            children: List.generate(
                              budgets.length,
                              (index) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 10,
                                  ),
                                  child: _budgetCard(
                                    index,
                                    budgets[index],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          _modifyDesignButton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CONTENT
  // ============================================================

  Widget _mobileContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              "Create Your Dream Space",
              style: TextStyle(
                color: darkBrown,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Upload your room image and customize your space.",
              style: TextStyle(
                color: lightBrown,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "1. Upload Your Room",
              style: TextStyle(
                color: darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 15),

            _uploadImageBox(),

            const SizedBox(height: 25),

            const Text(
              "2. Select Room Type",
              style: TextStyle(
                color: darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: roomTypes.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 12);
                },
                itemBuilder: (context, index) {
                  return _roomCard(
                    index,
                    roomTypes[index]["name"],
                    roomTypes[index]["icon"],
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "3. Select Your Budget",
              style: TextStyle(
                color: darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 15),

            Column(
              children: List.generate(
                budgets.length,
                (index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: _budgetCard(
                      index,
                      budgets[index],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            _modifyDesignButton(),

            const SizedBox(height: 25),

            _existingElements(),

            const SizedBox(height: 30),
          ],
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
          final bool isMobile =
              constraints.maxWidth < 800;

          if (isMobile) {
            return SafeArea(
              child: Column(
                children: [
                  // Same login navbar
                  _navbar(),

                  Expanded(
                    child: _mobileContent(),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Same login navbar
                _navbar(),

                Expanded(
                  child: _mainContent(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}