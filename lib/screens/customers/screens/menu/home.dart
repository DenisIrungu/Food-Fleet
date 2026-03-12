// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:foodfleet/models/menu_item_model.dart';
// import 'package:foodfleet/models/restaurant_model.dart';

// class HomePage extends StatefulWidget {
//   final RestaurantModel restaurant;

//   const HomePage({super.key, required this.restaurant});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   final TextEditingController _searchController = TextEditingController();

//   /// Streams stored in state — created once, never recreated on rebuild
//   Stream<List<MenuItemModel>>? _chefsSpecialStream;
//   Stream<List<MenuItemModel>>? _topOfWeekStream;

//   @override
//   void initState() {
//     super.initState();
//     _initStreams();
//   }

//   Future<void> _initStreams() async {
//     final chefsId = await _getCategoryId("Chef's Special");
//     final topId = await _getCategoryId('Top of the Week');

//     if (!mounted) return;

//     setState(() {
//       if (chefsId != null) {
//         _chefsSpecialStream = _buildItemsStream(chefsId, limit: 1);
//       }
//       if (topId != null) {
//         _topOfWeekStream = _buildItemsStream(topId);
//       }
//     });
//   }

//   /// Fetch category ID by name — runs once
//   Future<String?> _getCategoryId(String categoryName) async {
//     final snap = await FirebaseFirestore.instance
//         .collection('restaurants')
//         .doc(widget.restaurant.id)
//         .collection('categories')
//         .where('name', isEqualTo: categoryName)
//         .limit(1)
//         .get();

//     print('🔍 Category: $categoryName → docs: ${snap.docs.length}');
//     if (snap.docs.isNotEmpty) {
//       print('✅ ID: ${snap.docs.first.id}');
//     }

//     if (snap.docs.isEmpty) return null;
//     return snap.docs.first.id;
//   }

//   /// Build a stream for menu items — only called once per category
//   Stream<List<MenuItemModel>> _buildItemsStream(String categoryId,
//       {int? limit}) {
//     print('🎯 Building stream for categoryId: $categoryId');

//     var query = FirebaseFirestore.instance
//         .collection('restaurants')
//         .doc(widget.restaurant.id)
//         .collection('categories')
//         .doc(categoryId)
//         .collection('menu_items')
//         .orderBy('position');

//     if (limit != null) query = query.limit(limit);

//     return query.snapshots().map((snap) {
//       print('📥 Items for $categoryId: ${snap.docs.length}');
//       final items = snap.docs
//           .map((d) => MenuItemModel.fromFirestore(d))
//           .where((item) => item.isAvailable) 
//           .toList();
//       print('✅ Available items: ${items.length}');
//       return items;
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,

//       /// ================= APP BAR =================
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//         backgroundColor: Colors.white,
//         title: Text(
//           "Home",
//           style: TextStyle(
//             color: Theme.of(context).colorScheme.secondary,
//             fontWeight: FontWeight.bold,
//             fontSize: 22,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.notifications_outlined,
//                 size: 30, color: Theme.of(context).colorScheme.secondary),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: Icon(Icons.shopping_cart_outlined,
//                 size: 30, color: Theme.of(context).colorScheme.secondary),
//             onPressed: () {},
//           ),
//         ],
//       ),

//       /// ================= BODY =================
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               /// ── SEARCH BAR ──
//               TextField(
//                 controller: _searchController,
//                 decoration: InputDecoration(
//                   hintText: "Search food...",
//                   prefixIcon: const Icon(Icons.search),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(14),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               /// ── RESTAURANT HEADER ──
//               _RestaurantHeader(restaurant: widget.restaurant),

//               const SizedBox(height: 20),

//               /// ── CHEF'S SPECIAL ──
//               _chefsSpecialStream == null
//                   ? const _ChefsSpecialSkeleton()
//                   : StreamBuilder<List<MenuItemModel>>(
//                       stream: _chefsSpecialStream,
//                       builder: (context, snapshot) {
//                         print(
//                             '🍽️ ChefsSpecial: state=${snapshot.connectionState}, items=${snapshot.data?.length}, error=${snapshot.error}');
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const _ChefsSpecialSkeleton();
//                         }
//                         final items = snapshot.data ?? [];
//                         if (items.isEmpty) {
//                           return const _ChefsSpecialSkeleton();
//                         }
//                         return _ChefsSpecialCard(item: items.first);
//                       },
//                     ),

//               const SizedBox(height: 25),

//               /// ── TOP OF THE WEEK TITLE ──
//               const Text(
//                 "Top of the Week",
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),

//               const SizedBox(height: 15),

//               /// ── TOP OF THE WEEK ──
//               _topOfWeekStream == null
//                   ? const _TopOfWeekSkeleton()
//                   : StreamBuilder<List<MenuItemModel>>(
//                       stream: _topOfWeekStream,
//                       builder: (context, snapshot) {
//                         print(
//                             '🏆 TopOfWeek: state=${snapshot.connectionState}, items=${snapshot.data?.length}, error=${snapshot.error}');
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const _TopOfWeekSkeleton();
//                         }
//                         final items = snapshot.data ?? [];
//                         if (items.isEmpty) {
//                           return const _TopOfWeekSkeleton();
//                         }
//                         return SizedBox(
//                           height: 210,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: items.length,
//                             itemBuilder: (context, index) {
//                               return _TopFoodCard(item: items[index]);
//                             },
//                           ),
//                         );
//                       },
//                     ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ================= RESTAURANT HEADER =================
// class _RestaurantHeader extends StatelessWidget {
//   final RestaurantModel restaurant;

//   const _RestaurantHeader({required this.restaurant});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: 180,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: const Color(0xFF0F2A12),
//       ),
//       clipBehavior: Clip.hardEdge,
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           if (restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty)
//             Image.network(
//               restaurant.imageUrl!,
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) => const SizedBox.shrink(),
//             ),
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   const Color(0xFF0F2A12).withOpacity(0.85),
//                   const Color(0xFF1B3A1F).withOpacity(0.6),
//                 ],
//                 begin: Alignment.bottomLeft,
//                 end: Alignment.topRight,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Text(
//                   restaurant.name,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Row(
//                   children: [
//                     const Icon(Icons.location_on_outlined,
//                         color: Colors.white70, size: 16),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         restaurant.address,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                             color: Colors.white70, fontSize: 13),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.restaurant_menu_outlined,
//                         color: Colors.white70, size: 16),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         restaurant.cuisineTypes.isNotEmpty
//                             ? restaurant.cuisineTypes.join(", ")
//                             : "Various cuisines",
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                             color: Colors.white70, fontSize: 13),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ================= CHEF'S SPECIAL CARD =================
// class _ChefsSpecialCard extends StatelessWidget {
//   final MenuItemModel item;

//   const _ChefsSpecialCard({required this.item});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE9F5F1),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Stack(
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(right: 130),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: const [
//                     Icon(Icons.restaurant, size: 14, color: Color(0xFF0F2A12)),
//                     SizedBox(width: 5),
//                     Text(
//                       "Chef's Recommendation",
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF0F2A12),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 Text(
//                   item.name,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     color: Color(0xFF0F2A12),
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Ksh ${item.price.toStringAsFixed(2)}",
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                     color: Color(0xFF0F2A12),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     // TODO: Add to cart
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF0F2A12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 20, vertical: 10),
//                   ),
//                   child: const Text(
//                     "Order Now",
//                     style: TextStyle(color: Colors.white, fontSize: 13),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             right: 0,
//             top: 0,
//             child: SizedBox(
//               height: 120,
//               width: 120,
//               child: ClipOval(
//                 child: item.imageUrl.isNotEmpty
//                     ? Image.network(
//                         item.imageUrl,
//                         fit: BoxFit.cover,
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return Container(color: Colors.grey.shade200);
//                         },
//                         errorBuilder: (_, __, ___) => _imageFallback(),
//                       )
//                     : _imageFallback(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _imageFallback() {
//     return Container(
//       color: Colors.grey.shade300,
//       child: const Center(
//         child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
//       ),
//     );
//   }
// }

// // ================= CHEF'S SPECIAL SKELETON =================
// class _ChefsSpecialSkeleton extends StatelessWidget {
//   const _ChefsSpecialSkeleton();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE9F5F1),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Stack(
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(right: 130),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _shimmerBox(width: 140, height: 12),
//                 const SizedBox(height: 14),
//                 _shimmerBox(width: double.infinity, height: 20),
//                 const SizedBox(height: 8),
//                 _shimmerBox(width: 120, height: 20),
//                 const SizedBox(height: 10),
//                 _shimmerBox(width: 80, height: 16),
//                 const SizedBox(height: 20),
//                 _shimmerBox(width: 110, height: 38, radius: 20),
//               ],
//             ),
//           ),
//           Positioned(
//             right: 0,
//             top: 0,
//             child: Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _shimmerBox(
//       {required double width, required double height, double radius = 8}) {
//     return Container(
//       width: width,
//       height: height,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade300,
//         borderRadius: BorderRadius.circular(radius),
//       ),
//     );
//   }
// }

// // ================= TOP FOOD CARD =================
// class _TopFoodCard extends StatelessWidget {
//   final MenuItemModel item;

//   const _TopFoodCard({required this.item});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: item.imageUrl.isNotEmpty
//                 ? Image.network(
//                     item.imageUrl,
//                     width: 140,
//                     height: 120,
//                     fit: BoxFit.cover,
//                     loadingBuilder: (context, child, loadingProgress) {
//                       if (loadingProgress == null) return child;
//                       return _placeholder();
//                     },
//                     errorBuilder: (_, __, ___) => _placeholder(),
//                   )
//                 : _placeholder(),
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             width: 140,
//             child: Text(
//               item.name,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Text(
//             "Ksh ${item.price.toStringAsFixed(2)}",
//             style: const TextStyle(color: Colors.green),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _placeholder() {
//     return Container(
//       width: 140,
//       height: 120,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Center(
//         child: Icon(Icons.fastfood, size: 36, color: Colors.grey),
//       ),
//     );
//   }
// }

// // ================= TOP OF THE WEEK SKELETON =================
// class _TopOfWeekSkeleton extends StatelessWidget {
//   const _TopOfWeekSkeleton();

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 210,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: 4,
//         physics: const NeverScrollableScrollPhysics(),
//         itemBuilder: (context, index) {
//           return Padding(
//             padding: const EdgeInsets.only(right: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 140,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   width: 100,
//                   height: 14,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(
//                   width: 60,
//                   height: 12,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
