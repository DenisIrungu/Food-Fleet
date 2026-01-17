import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/addon_group_model.dart';
import '../models/menu_item_model.dart';

class AddonService {
  final FirebaseFirestore _firestore;
  final String restaurantId;

  AddonService({
    FirebaseFirestore? firestore,
    required this.restaurantId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /* ----------------------------------------------------
     Firestore references (LOCKED PATHS)
  ---------------------------------------------------- */

  CollectionReference<Map<String, dynamic>> get _addonGroupsRef => _firestore
      .collection('restaurants')
      .doc(restaurantId)
      .collection('addon_groups');

  CollectionReference<Map<String, dynamic>> get _menuItemsRef => _firestore
      .collection('restaurants')
      .doc(restaurantId)
      .collection('menu_items');

  /* ----------------------------------------------------
     ADDON GROUPS (ADMIN ONLY)
  ---------------------------------------------------- */

  /// ADMIN ONLY: Get all addon groups ordered by position
  Future<List<AddonGroupModel>> getAddonGroupsForAdmin() async {
    final snapshot = await _addonGroupsRef.orderBy('position').get();

    return snapshot.docs
        .map((doc) => AddonGroupModel.fromFirestore(doc))
        .toList();
  }

  /// ADMIN ONLY: Get addon groups by IDs
  Future<List<AddonGroupModel>> getAddonGroupsByIdsForAdmin(
    List<String> addonGroupIds,
  ) async {
    if (addonGroupIds.isEmpty) return [];

    final List<AddonGroupModel> results = [];

    // Firestore whereIn limit = 10
    for (int i = 0; i < addonGroupIds.length; i += 10) {
      final batchIds = addonGroupIds.skip(i).take(10).toList();

      final snapshot = await _addonGroupsRef
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      results.addAll(
        snapshot.docs.map((doc) => AddonGroupModel.fromFirestore(doc)),
      );
    }

    // Ensure correct ordering after batching
    return results..sort((a, b) => a.position.compareTo(b.position));
  }

  /// ADMIN ONLY: Create addon group
  Future<void> createAddonGroup(AddonGroupModel group) async {
    await _addonGroupsRef.add(group.toMap());
  }

  /// ADMIN ONLY: Update addon group
  Future<void> updateAddonGroup(AddonGroupModel group) async {
    await _addonGroupsRef.doc(group.id).update(group.toMap());
  }

  /// ADMIN ONLY: Delete addon group (hard delete)
  Future<void> deleteAddonGroup(String addonGroupId) async {
    await _addonGroupsRef.doc(addonGroupId).delete();
  }

  /* ----------------------------------------------------
     ADDON ITEMS
     (Menu items where isAddon == true)
  ---------------------------------------------------- */

  /// Get addon items by IDs (used when rendering menu items)
  Future<List<MenuItemModel>> getAddonItemsByIds(
    List<String> addonItemIds,
  ) async {
    if (addonItemIds.isEmpty) return [];

    final List<MenuItemModel> results = [];

    // Firestore whereIn limit = 10
    for (int i = 0; i < addonItemIds.length; i += 10) {
      final batchIds = addonItemIds.skip(i).take(10).toList();

      final snapshot = await _menuItemsRef
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      results.addAll(
        snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)),
      );
    }

    return results..sort((a, b) => a.position.compareTo(b.position));
  }

  /// ADMIN ONLY: Get all addon items
  Future<List<MenuItemModel>> getAllAddonItemsForAdmin() async {
    final snapshot = await _menuItemsRef
        .where('isAddon', isEqualTo: true)
        .orderBy('position')
        .get();

    return snapshot.docs
        .map((doc) => MenuItemModel.fromFirestore(doc))
        .toList();
  }

  /* ----------------------------------------------------
     UTILITIES (ADMIN ONLY)
  ---------------------------------------------------- */

  /// Update addon group positions (drag & drop ordering)
  Future<void> updateAddonGroupPositions(
    Map<String, int> positions,
  ) async {
    final batch = _firestore.batch();

    positions.forEach((addonGroupId, position) {
      batch.update(
        _addonGroupsRef.doc(addonGroupId),
        {
          'position': position,
          'updatedAt': Timestamp.now(),
        },
      );
    });

    await batch.commit();
  }

  /// Attach addon groups to a menu item
  Future<void> attachAddonGroupsToMenuItem({
    required String menuItemId,
    required List<String> addonGroupIds,
  }) async {
    await _menuItemsRef.doc(menuItemId).update({
      'addonGroupIds': addonGroupIds,
      'updatedAt': Timestamp.now(),
    });
  }
}
