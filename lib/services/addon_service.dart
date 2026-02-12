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

  /* ====================================================
     ADDON GROUPS (ADMIN)
  ==================================================== */

  /// Get all addon groups (Future)
  Future<List<AddonGroupModel>> getAddonGroupsForAdmin() async {
    final snapshot = await _addonGroupsRef.orderBy('position').get();

    return snapshot.docs
        .map((doc) => AddonGroupModel.fromFirestore(doc))
        .toList();
  }

  /// Stream all addon groups (LIVE)
  Stream<List<AddonGroupModel>> streamAddonGroupsForAdmin() {
    return _addonGroupsRef.orderBy('position').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AddonGroupModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get addon groups by IDs (Future - batched safe)
  Future<List<AddonGroupModel>> getAddonGroupsByIdsForAdmin(
    List<String> addonGroupIds,
  ) async {
    if (addonGroupIds.isEmpty) return [];

    final List<AddonGroupModel> results = [];

    for (int i = 0; i < addonGroupIds.length; i += 10) {
      final batchIds = addonGroupIds.skip(i).take(10).toList();

      final snapshot = await _addonGroupsRef
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      results.addAll(
        snapshot.docs.map((doc) => AddonGroupModel.fromFirestore(doc)),
      );
    }

    return results..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Create addon group
  Future<void> createAddonGroup(AddonGroupModel group) async {
    await _addonGroupsRef.add(group.toMap());
  }

  /// Update addon group
  Future<void> updateAddonGroup(AddonGroupModel group) async {
    await _addonGroupsRef.doc(group.id).update(group.toMap());
  }

  /// Delete addon group
  Future<void> deleteAddonGroup(String addonGroupId) async {
    await _addonGroupsRef.doc(addonGroupId).delete();
  }

  /// Update addon group positions (drag & drop groups)
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

  /// Update addon item order inside a group (drag inside group)
  Future<void> updateAddonGroupItemOrder({
    required String groupId,
    required List<String> newOrder,
  }) async {
    await _addonGroupsRef.doc(groupId).update({
      'addonItemIds': newOrder,
      'updatedAt': Timestamp.now(),
    });
  }

  /* ====================================================
     ADDON ITEMS (Menu items where isAddon == true)
  ==================================================== */

  /// Get addon items by IDs (Future - batched safe)
  Future<List<MenuItemModel>> getAddonItemsByIds(
    List<String> addonItemIds,
  ) async {
    if (addonItemIds.isEmpty) return [];

    final List<MenuItemModel> results = [];

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

  /// Stream addon items by IDs (LIVE)
  Stream<List<MenuItemModel>> streamAddonItemsByIds(
    List<String> addonItemIds,
  ) {
    if (addonItemIds.isEmpty) {
      return Stream.value([]);
    }

    return _menuItemsRef
        .where(FieldPath.documentId, whereIn: addonItemIds)
        .snapshots()
        .map((snapshot) {
      final items =
          snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();

      // Maintain group order
      items.sort((a, b) => addonItemIds.indexOf(a.id).compareTo(
            addonItemIds.indexOf(b.id),
          ));

      return items;
    });
  }

  /// Get all addon items (ADMIN)
  Future<List<MenuItemModel>> getAllAddonItemsForAdmin() async {
    final snapshot =
        await _menuItemsRef.where('isAddon', isEqualTo: true).get();

    final items =
        snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();

    items.sort((a, b) => a.position.compareTo(b.position));

    return items;
  }

  /// Stream all addon items (ADMIN LIVE)
  Stream<List<MenuItemModel>> streamAllAddonItemsForAdmin() {
    return _menuItemsRef
        .where('isAddon', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final items =
          snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();

      items.sort((a, b) => a.position.compareTo(b.position));

      return items;
    });
  }

  /// Delete addon item
  Future<void> deleteAddonItem(String addonItemId) async {
    await _menuItemsRef.doc(addonItemId).delete();
  }

  /// Toggle availability (Quick Admin Action)
  Future<void> toggleAddonAvailability({
    required String addonItemId,
    required bool isAvailable,
  }) async {
    await _menuItemsRef.doc(addonItemId).update({
      'isAvailable': isAvailable,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Increment usage analytics (future checkout integration)
  Future<void> incrementAddonUsage(String addonItemId) async {
    await _menuItemsRef.doc(addonItemId).update({
      'usageCount': FieldValue.increment(1),
    });
  }

  /* ====================================================
     UTILITIES
  ==================================================== */

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
