import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

// img showing variables
String? uploadedImageUrl;
bool isUploading = false;
String? projectId;

  // ============================================================
  // VARIABLES
  // ============================================================

  int selectedRoom = 0;
  int selectedBudget = 0;
  String selectedProjectType = "";
  int maxbudget = 0;
  Uint8List? uploadedImageBytes;
  bool _showMobileNav = false;
  final ImagePicker imagePicker = ImagePicker();
  final TextEditingController projectNameController = TextEditingController();
  // ============================================================
  // SCROLL
  // ============================================================

  final ScrollController _scrollController =
      ScrollController();

  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

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
  {
    "name": "Bathroom",
    "icon": Icons.bathtub_outlined,
  },
  {
    "name": "Kids' Room",
    "icon": Icons.toys_outlined,
  },
  {
    "name": "Guest Room",
    "icon": Icons.single_bed_outlined,
  },
  {
    "name": "Study Room",
    "icon": Icons.menu_book_outlined,
  },
  {
    "name": "Balcony",
    "icon": Icons.balcony_outlined,
  },
  {
    "name": "Laundry Room",
    "icon": Icons.local_laundry_service_outlined,
  },
  {
    "name": "Garage",
    "icon": Icons.garage_outlined,
  },
  {
    "name": "Hallway",
    "icon": Icons.door_sliding_outlined,
  },
  {
    "name": "Dressing Room",
    "icon": Icons.checkroom_outlined,
  },
  {
    "name": "Pantry",
    "icon": Icons.inventory_2_outlined,
  },
  {
    "name": "Outdoor Space",
    "icon": Icons.deck_outlined,
  },
  {
    "name": "Home Theater",
    "icon": Icons.theaters_outlined,
  },
  {
    "name": "Gym",
    "icon": Icons.fitness_center_outlined,
  },
];

  // ============================================================
  // BUDGET
  // ============================================================
final budgets = [
      "Below ₹10,000",
      "₹10,000 - ₹30,000",
      "₹30,000 - ₹50,000",
      "₹50,000 - ₹1,00,000",
      "₹1,00,000 - ₹1,50,000",
      "₹1,60,000 - ₹2,00,000",
      "₹2,00,000 - ₹5,00,000",
      "Above ₹5,00,000",
    ];
    @override
void dispose() {
  projectNameController.dispose();
  super.dispose();
}
//----------max budget selection fun
int getMaxBudget(String budget) {
  if (budget.startsWith("Below")) {
    return 10000;
  }

  if (budget.startsWith("Above")) {
    return 500000; // Minimum amount for Above ₹5,00,000
  }

  // Get the amount after the hyphen
  final parts = budget.split('-');
  final maxAmount = parts.last
      .replaceAll('₹', '')
      .replaceAll(',', '')
      .trim();

  return int.parse(maxAmount);
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
  //ulpad seletced img to supabase
 Future<String?> uploadToSupabase() async {
    print("user : ${FirebaseAuth.instance.currentUser?.uid}");
    if (selectedImg == null) {
      print("No image selected");
      return null;
    }

    try {
      print("selected img : ${selectedImg!.path}");
      final Uint8List bytes = await selectedImg!.readAsBytes();
      print("${bytes}");
      final String fileName =
          '${DateTime.now().microsecondsSinceEpoch}_${selectedImg!.name}';
      print("${fileName}");
      await Supabase.instance.client.storage
          .from("uploaded_images")
          .uploadBinary(
            fileName,
            bytes,
          );

      print("Image added to Supabase Storage");

      final String url = Supabase.instance.client.storage
          .from("uploaded_images")
          .getPublicUrl(fileName);

      print("Image URL: $url");

      return url;
   } on StorageException catch (e) {
  print("StorageException");
  print("Message: ${e.message}");
  print("Status code: ${e.statusCode}");
  print("Error: ${e.error}");
  return null;
} catch (e) {
  print("Other error: $e");
  return null;
}
  }

  // Add course to Firestore
Future<void> addimage() async {
  if (selectedImg == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select an image first"),
      ),
    );
    return;
  }

 final projectName = projectNameController.text.trim();
final user = FirebaseAuth.instance.currentUser;

if (projectName.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please enter a project name"),
    ),
  );
  return;
}

if (user == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Please log in first"),
    ),
  );
  return;
}

// Check whether the project name already exists for this user.
final existingProject = await FirebaseFirestore.instance
    .collection('projects')
    .where('userId', isEqualTo: user.uid)
    .where('projectName', isEqualTo: projectName)
    .limit(1)
    .get();

if (existingProject.docs.isNotEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Project name already exists. Please choose another name.",
      ),
    ),
  );
  return;
}

// Continue with your image upload and Firestore save here.

  if (selectedProjectType.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a project type"),
      ),
    );
    return;
  }

  setState(() {
    isUploading = true;
  });

  try {
    // 1. Upload image to Supabase Storage
    final String? imgUrl = await uploadToSupabase();

    if (imgUrl == null) {
      throw Exception("Image upload failed");
    }

    // 2. Save image URL and project details in Firestore
    await FirebaseFirestore.instance.collection("projects").add({
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "uploadedimg_url": imgUrl,
      "projectName": projectNameController.text.trim(),
      "projectType": selectedProjectType,
      "maxBudget": maxbudget,
    });

    if (!mounted) return;

    // 3. Update UI after successful upload
    setState(() {
      uploadedImageUrl = imgUrl;
      isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Image uploaded successfully"),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload failed: $e")),
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
  // IMAGE PICKER
  // ============================================================

XFile? selectedImg;
  // Pick image
  Future<void> pickImage() async {
  try {
    final XFile? image = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    final Uint8List bytes = await image.readAsBytes();

    if (!mounted) return;

    setState(() {
      selectedImg = image;
      uploadedImageBytes = bytes;
    });

    debugPrint("Image selected: ${image.name}");
    debugPrint("Image bytes: ${bytes.length}");
  } catch (e) {
    debugPrint("Error picking image: $e");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Unable to select image: $e")),
    );
  }
}


  // ============================================================
  // NAVBAR
  // Same navbar as Login Page
  // ============================================================

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
        selectedProjectType=roomTypes[selectedRoom]["name"] ;

      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 150,
      height: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? brown : const Color.fromARGB(26, 107, 67, 37),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? brown
              : const Color.fromARGB(255, 65, 33, 4).withOpacity(0.3),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? brown.withOpacity(0.18)
                : const Color.fromARGB(255, 98, 53, 53).withOpacity(0.04),
            blurRadius: selected ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with a soft background
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.15)
                  : lightBrown.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 28,
              color: selected ? Colors.white : olive,
            ),
          ),

          const SizedBox(height: 10),

          // Room name and selection indicator
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : darkBrown,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 5),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selected
                ? Row(
                    key: const ValueKey('selected'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(
                    key: ValueKey('unselected'),
                    height: 12,
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

  Widget _budgetCard(int index, String title) {
  final bool selected = selectedBudget == index;

  return GestureDetector(
    onTap: () {
      setState(() {
        selectedBudget = index;
        maxbudget = getMaxBudget(budgets[selectedBudget]);

      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected
            ? const Color.fromARGB(255, 84, 88, 66)
            :  const Color.fromARGB(91, 210, 218, 177),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? olive
              :  Color.fromARGB(124, 108, 132, 103),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? brown.withOpacity(0.18)
                : Colors.black.withOpacity(0.04),
            blurRadius: selected ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.15)
                      : lightBrown.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 21,
                  color: selected ? Colors.white : olive,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : lightBrown.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 15,
                        color: brown,
                      )
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title.replaceAll('\n', ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : darkBrown,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            selected ? 'Selected budget' : 'Choose budget',
            style: TextStyle(
              color: selected
                  ? Colors.white70
                  : olive.withOpacity(0.75),
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
  return LayoutBuilder(
    builder: (context, constraints) {
      final bool isMobile = constraints.maxWidth < 650;

      Widget uploadArea = GestureDetector(
        onTap: pickImage,
        child: Container(
          width: double.infinity,
          height: isMobile ? 300 : 600,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: olive.withOpacity(0.4),
              width: 1.4,
            ),
          ),
          child: uploadedImageBytes != null
    ? Image.memory(
        uploadedImageBytes!,
        fit: BoxFit.contain,
      )
    : uploadedImageUrl != null
        ? Image.network(
            uploadedImageUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text("Unable to load uploaded image"),
              );
            },
          )
        :  Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 55,
        height: 55,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: olive,
          size: 28,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        "Upload Room Image",
        style: TextStyle(
          color: darkBrown,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        "Choose an image from your device",
        style: TextStyle(
          color: lightBrown,
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        "JPG, PNG or JPEG",
        style: TextStyle(
          color: lightBrown,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 13),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: olive,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          "Choose Image",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
)
        ),
      );

      Widget actionButtons = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
TextFormField(
  controller: projectNameController,
  textCapitalization: TextCapitalization.words,
  keyboardType: TextInputType.text,
  textInputAction: TextInputAction.next,
  style: const TextStyle(
    color: darkBrown,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  ),
  decoration: InputDecoration(
    labelText: "Project Name",
    hintText: "e.g. My Dream Living Room",
    prefixIcon: const Icon(
      Icons.drive_file_rename_outline_rounded,
      color: olive,
      size: 22,
    ),
    filled: true,
    fillColor: cream,
    labelStyle: const TextStyle(
      color: lightBrown,
      fontSize: 13,
    ),
    hintStyle: TextStyle(
      color: lightBrown.withOpacity(0.65),
      fontSize: 12,
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 18,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: olive.withOpacity(0.25),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: olive.withOpacity(0.3),
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: olive,
        width: 1.8,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Colors.redAccent,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: Colors.redAccent,
        width: 1.5,
      ),
    ),
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter a project name";
    }
    return null;
  },
),
                      const SizedBox(height: 12),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: uploadedImageBytes == null
                  ? null
                  : () => addimage(),
              icon: const Icon(
                Icons.download_done_rounded,
                size: 18,
              ),
              label: const Text("upload Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 58, 22, 22),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color.fromARGB(255, 89, 105, 24).withOpacity(0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
                    const SizedBox(height: 12),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: uploadedImageBytes == null
                  ? null
                  : () => _analyzeimgButton(),
              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
              ),
              label: const Text("Analyze Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: olive,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    olive.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: uploadedImageBytes == null
                  ? null
                  : () => _modifyDesignButton(),
              icon: const Icon(
                Icons.auto_awesome,
                size: 18,
              ),
              label: const Text("Modify Design"),
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    brown.withOpacity(0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );

      return Container(
        width: double.infinity,
         constraints: BoxConstraints(
    minHeight: isMobile ? 500 : 620,
  ),
        padding: EdgeInsets.all(isMobile ? 14 : 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: olive.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Room",
              style: TextStyle(
                color: darkBrown,
                fontSize: isMobile ? 18 : 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Upload your room image to start creating your dream space.",
              style: TextStyle(
                color: lightBrown,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
            const SizedBox(height: 20),

            if (isMobile) ...[
              uploadArea,
              const SizedBox(height: 14),
              actionButtons,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: uploadArea,
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 190,
                    child: actionButtons,
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}
// Small action button displayed over the image.
Widget _imageActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
 Widget _analyzeimgButton() {
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
          Icons.remove_red_eye_outlined,
          size: 19,
        ),
        label: const Text(
          "analyze Image",
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
  Widget _uploadtosupabase() {
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
          Icons.remove_red_eye_outlined,
          size: 19,
        ),
        label: const Text(
          "analyze Image",
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
      //"image": "assets/images/sofa.png",
      "icon": Icons.weekend_outlined,
    },
    {
      "name": "Table",
      // "image": "assets/images/table.png",
      "icon": Icons.table_restaurant_outlined,
    },
    {
      "name": "Plant",
      "image": "assets/images/plant.png",
      "icon": Icons.yard_outlined,
    },
    {
      "name": "Lamp",
      "image": "assets/images/lamp.png",
      "icon": Icons.light_outlined,
    },
    {
      "name": "Rug",
      "image": "assets/images/rug.png",
      "icon": Icons.texture_outlined,
    },
    {
      "name": "Wall Art",
      "image": "assets/images/wall_art.png",
      "icon": Icons.image_outlined,
    },
  ];

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: lightBrown.withOpacity(0.16),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        const Text(
          "Existing Elements",
          style: TextStyle(
            color: darkBrown,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          "These elements are detected from your room image.",
          style: TextStyle(
            color: lightBrown,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 18),

        // RESPONSIVE ELEMENT CARDS
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth =
                constraints.maxWidth;

            final int columns =
                availableWidth >= 650
                    ? 6
                    : availableWidth >= 400
                        ? 3
                        : 2;

            const double spacing = 10;

            final double cardWidth =
                (availableWidth -
                    (spacing * (columns - 1))) /
                columns;

            return Wrap(
              spacing: spacing,
              runSpacing: 12,
              children: elements.map((element) {
                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F0),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: lightBrown.withOpacity(0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: darkBrown.withOpacity(0.025),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // IMAGE THUMBNAIL
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 1.25,
                            // child: Image.asset(
                            //   element["image"] as String,
                            //   width: double.infinity,
                            //   fit: BoxFit.cover,
                            //   errorBuilder:
                            //       (context, error, stackTrace) {
                            //     return Container(
                            //       color: const Color(0xFFEDE2D3),
                            //       alignment: Alignment.center,
                            //       child: Icon(
                            //         element["icon"] as IconData,
                            //         size: 32,
                            //         color: brown,
                            //       ),
                            //     );
                            //   },
                            // ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        // ELEMENT NAME
                        Text(
                          element["name"] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: darkBrown,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
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
              "2. Select Room Type",
              style: TextStyle(
                color: darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
  height: 150,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: roomTypes.length,
    separatorBuilder: (context, index) =>
        const SizedBox(width: 12),
    itemBuilder: (context, index) {
      return _roomCard(
        index,
        roomTypes[index]["name"] as String,
        roomTypes[index]["icon"] as IconData,
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

           SizedBox(
  height: 135,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    itemCount: budgets.length,
    separatorBuilder: (context, index) =>
        const SizedBox(width: 12),
    itemBuilder: (context, index) {
      return SizedBox(
        width: 175,
        child: _budgetCard(
          index,
          budgets[index],
        ),
      );
    },
  ),
),
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

            const SizedBox(height: 30),
          ],
        ),
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
  // MAIN CONTENT
  // ============================================================
Widget _mainContent() {
  return Container(
    color: const Color(0xFFF7F1E8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HERO BANNER
       _buildHeroSection(),

        // MAIN FORM
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 22, 25, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ROOM TYPE
              _sectionTitle("1. Room Type"),
              const SizedBox(height: 12),

              SizedBox(
  height: 150,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: roomTypes.length,
    separatorBuilder: (context, index) =>
        const SizedBox(width: 10),
    itemBuilder: (context, index) {
      return _roomCard(
        index,
        roomTypes[index]["name"] as String,
        roomTypes[index]["icon"] as IconData,
      );
    },
  ),
),

              const SizedBox(height: 24),

              // BUDGET
              _sectionTitle("2. Budget"),
              const SizedBox(height: 12),

              Builder(
  builder: (context) {
    final budgetOptions = [
      "Below ₹10,000",
      "₹10,000 - ₹30,000",
      "₹30,000 - ₹50,000",
      "₹50,000 - ₹1,00,000",
      "₹1,00,000 - ₹1,50,000",
      "₹1,60,000 - ₹2,00,000",
      "₹2,00,000 - ₹5,00,000",
      "Above ₹5,00,000",
    ];

    return SizedBox(
  height: 135,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: budgetOptions.length,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.only(
          right: 12,
          bottom: 5,
        ),
        child: SizedBox(
          width: 175,
          child: _budgetCard(
            index,
            budgetOptions[index],
          ),
        ),
      );
    },
  ),
);
  },
),
              const SizedBox(height: 24),

              // UPLOAD + PREVIEW
              _sectionTitle("3. Upload Room Image"),
              const SizedBox(height: 12),

            Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // LEFT: Upload Image
    Expanded(
      child: Column(
        children: [
          _uploadImageBox(),
           SizedBox(
            height: 20,
          ),
         
        ],
      ),
    ),

    const SizedBox(width: 18),

     ],
),
              
              // EXISTING ELEMENTS
              _existingElements(),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _sectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      color: Color(0xFF3E2C1E),
      fontSize: 17,
      fontWeight: FontWeight.w700,
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
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Same  navbar
                    _mobileNavbar(),
                
                    _mobileContent(),
                    // HOW IT WORKS
                    _howItWorksSection(),

                    // ABOUT
                    _aboutSection(),
                  ],
                ),
              ),
            );
          }
          
          return SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // Same login navbar
                  _navbar(),
              
                  _mainContent(),
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