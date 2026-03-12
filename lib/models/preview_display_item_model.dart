import 'menu_item_model.dart';

abstract class PreviewDisplayItemModel {}

class PreviewCategoryHeaderModel extends PreviewDisplayItemModel {
  final String title;

  PreviewCategoryHeaderModel(this.title);
}

class PreviewMenuItemDisplayModel extends PreviewDisplayItemModel {
  final MenuItemModel item;

  PreviewMenuItemDisplayModel(this.item);
}
