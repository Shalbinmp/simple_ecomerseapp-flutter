import 'package:hive/hive.dart';

// part 'cart_model.g.dart';

@HiveType(typeId: 0)
class CartItem extends HiveObject {
  @HiveField(0)
  final String productId;

  @HiveField(1)
  int quantity;

  CartItem({required this.productId, required this.quantity});
}
