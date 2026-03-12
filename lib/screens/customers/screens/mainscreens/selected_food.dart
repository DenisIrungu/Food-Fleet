import 'package:flutter/material.dart';

class SelectFoodPage extends StatefulWidget {
  final Map<String, dynamic> food;

  const SelectFoodPage({
    super.key,
    required this.food,
  });

  @override
  State<SelectFoodPage> createState() => _SelectFoodPageState();
}

class _SelectFoodPageState extends State<SelectFoodPage> {
  int quantity = 1;

  /// STATIC ADDONS (UI ONLY)
  final Map<String, double> addons = {
    "Extra Cheese": 1.5,
    "Spicy Sauce": 1.0,
    "Double Patty": 3.0,
  };

  final Map<String, bool> selectedAddons = {};

  @override
  void initState() {
    super.initState();
    for (var addon in addons.keys) {
      selectedAddons[addon] = false;
    }
  }

  /// ================= TOTAL PRICE =================
  double get totalPrice {
    double base = double.parse(widget.food["price"].replaceAll("\$", ""));

    double addonTotal = 0;

    selectedAddons.forEach((key, value) {
      if (value) addonTotal += addons[key]!;
    });

    return (base + addonTotal) * quantity;
  }

  /// ================= ADD TO CART =================
  Future<void> _addToCart() async {
    /// UI ONLY — cart logic comes later

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.food["title"]} added to cart ✅"),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    /// allow user to see confirmation
    await Future.delayed(const Duration(milliseconds: 900));

    /// go back to HOME (MainScreen root)
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    /// ================= RESPONSIVE BREAKPOINT =================
    final bool isLargeScreen = width > 700;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: isLargeScreen ? _desktopLayout() : _mobileLayout(),
                ),
              ),
            ),
          ),

          /// BACK BUTTON
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ============================================================
  // 📱 MOBILE LAYOUT
  // ============================================================

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _foodImage(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: _foodDetails(),
        ),
      ],
    );
  }

  // ============================================================
  // 💻 TABLET / DESKTOP LAYOUT
  // ============================================================

  Widget _desktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _foodImage()),
          const SizedBox(width: 40),
          Expanded(child: _foodDetails()),
        ],
      ),
    );
  }

  // ============================================================
  // FOOD IMAGE
  // ============================================================

  Widget _foodImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        widget.food["image"],
        height: 320,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  // ============================================================
  // DETAILS SECTION
  // ============================================================

  Widget _foodDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.food["title"],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.food["price"],
          style: const TextStyle(
            fontSize: 20,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 25),
        _quantitySelector(),
        const SizedBox(height: 25),
        const Text(
          "Add-ons",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _addonsList(),
        const SizedBox(height: 25),
        _totalPriceCard(),
        const SizedBox(height: 20),
        _addToCartButton(),
      ],
    );
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  Widget _quantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Quantity",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (quantity > 1) {
                  setState(() => quantity--);
                }
              },
            ),
            Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() => quantity++);
              },
            ),
          ],
        )
      ],
    );
  }

  // ============================================================
  // ADDONS
  // ============================================================

  Widget _addonsList() {
    return Column(
      children: addons.keys.map((addon) {
        return CheckboxListTile(
          value: selectedAddons[addon],
          title: Text(addon),
          subtitle: Text("\$${addons[addon]!.toStringAsFixed(2)}"),
          onChanged: (value) {
            setState(() {
              selectedAddons[addon] = value!;
            });
          },
        );
      }).toList(),
    );
  }

  // ============================================================
  // TOTAL PRICE
  // ============================================================

  Widget _totalPriceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            "\$${totalPrice.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 20,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _addToCartButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F2A12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "Add to Cart",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
