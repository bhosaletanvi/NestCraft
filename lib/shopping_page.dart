import 'package:flutter/material.dart';
import 'package:nest_craft/services/shopping_service.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  static const Color darkBrown = Color(0xFF2F2922);
  static const Color brown = Color(0xFF6B4528);
  static const Color cream = Color(0xFFF5F0E8);
  static const Color mutedText = Color(0xFF81776B);

  final List<String> objectTypes = [
    'Sofa',
    'Bed',
    'Table',
    'Chair',
    'Wardrobe',
    'Lamp',
    'Coffee Table',
    'Curtains',
    'Bookshelf',
    'Dining Table',
  ];

  final List<int> budgets = [
    1000,
    3000,
    5000,
    10000,
    20000,
    50000,
  ];

  String selectedObject = 'Sofa';
  String selectedColor = '';
  int selectedBudget = 10000;

  final TextEditingController colorController =
      TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  List<Map<String, dynamic>> products = [];

  @override
  void dispose() {
    colorController.dispose();
    super.dispose();
  }

  Future<void> findProducts() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      errorMessage = null;
      products = [];
    });

    try {
      final result = await ShoppingService.recommendProducts(
        objectType: selectedObject,
        color: colorController.text.trim(),
        budget: selectedBudget,
      );

      if (!mounted) return;

      setState(() {
        products = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String productValue(
    Map<String, dynamic> product,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = product[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  Widget buildProductCard(Map<String, dynamic> product) {
    final name = productValue(
      product,
      ['name', 'title', 'product_name'],
      fallback: 'Furniture Product',
    );

    final price = productValue(
      product,
      ['price', 'displayed_price', 'selling_price'],
      fallback: 'Price unavailable',
    );

    final imageUrl = productValue(
      product,
      ['image_url', 'image', 'thumbnail', 'imageUrl'],
    );

    final productUrl = productValue(
      product,
      ['product_url', 'url', 'link', 'product_link'],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: cream,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(
                        Icons.chair_outlined,
                        size: 55,
                        color: brown,
                      ),
                    )
                  : const Icon(
                      Icons.chair_outlined,
                      size: 55,
                      color: brown,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkBrown,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: brown,
                  ),
                ),
                if (productUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Product link integration can be added next.',
                            ),
                          ),
                        );
                      },
                      child: const Text('View Product'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: darkBrown,
        elevation: 0,
        title: const Text(
          'Find Furniture',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: darkBrown,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFE8D8C5),
                      size: 32,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Find Your Perfect Furniture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Discover furniture that matches your style and budget.',
                      style: TextStyle(
                        color: Color(0xFFD6CFC6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'What are you looking for?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: darkBrown,
                ),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedObject,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Furniture type',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                items: objectTypes.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => selectedObject = value);
                        }
                      },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: colorController,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: 'Preferred colour (optional)',
                  hintText: 'e.g. Beige, brown, white',
                  prefixIcon: const Icon(
                    Icons.palette_outlined,
                    color: brown,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: selectedBudget,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Maximum budget (₹)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                items: budgets.map((budget) {
                  return DropdownMenuItem(
                    value: budget,
                    child: Text('Up to ₹$budget'),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => selectedBudget = value);
                        }
                      },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : findProducts,
                  icon: isLoading
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    isLoading ? 'Finding Products...' : 'Find Products',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Unable to load products.\n$errorMessage',
                    style: const TextStyle(color: Color(0xFF9B3024)),
                  ),
                ),
              ],

              if (!isLoading &&
                  errorMessage == null &&
                  products.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  '${products.length} Recommended Products',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: darkBrown,
                  ),
                ),
                const SizedBox(height: 15),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 310,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) =>
                      buildProductCard(products[index]),
                ),
              ],

              if (!isLoading &&
                  errorMessage == null &&
                  products.isEmpty) ...[
                const SizedBox(height: 28),
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 45,
                        color: mutedText,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No products found yet.',
                        style: TextStyle(color: mutedText),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose your preferences and try again.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
