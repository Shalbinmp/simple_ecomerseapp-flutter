import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  late String userId;
  final CollectionReference cartCollection = FirebaseFirestore.instance.collection('Carts');
  final Dio dio = Dio();
  List<Map<String, dynamic>> cartItems = [];
  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    } else {
      print('User is not signed in.');
    }
  }

  Future<void> _updateItemQuantity(int productId, int quantity) async {
    try {
      final cartDoc = cartCollection.doc(userId);
      final cartSnapshot = await cartDoc.get();
      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>;
        final products = List<Map<String, dynamic>>.from(cartData['products'] ?? []);
        final itemIndex = products.indexWhere((item) => item['productId'] == productId);
        if (itemIndex != -1) {
          products[itemIndex]['quantity'] = quantity;
          await cartDoc.update({'products': products});
        }
      }
    } catch (e) {
      print('Error updating item quantity: $e');
    }
  }

  Future<void> _removeItem(int productId) async {
    try {
      final cartDoc = cartCollection.doc(userId);
      final cartSnapshot = await cartDoc.get();
      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>;
        final products = List<Map<String, dynamic>>.from(cartData['products'] ?? []);
        final updatedProducts = products.where((item) => item['productId'] != productId).toList();
        await cartDoc.update({'products': updatedProducts});
      }
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[150],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cart'),
      ),
      body: userId == null
          ? const Center(child: Text('User is not signed in'))
          : StreamBuilder<DocumentSnapshot>(
        stream: cartCollection.doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Your cart is empty'));
          }

          final cartData = snapshot.data!.data() as Map<String, dynamic>;
          cartItems = List<Map<String, dynamic>>.from(cartData['products'] ?? []);

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchProductDetails(cartItems),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (futureSnapshot.hasError) {
                return Center(child: Text('Error: ${futureSnapshot.error}'));
              }

              final products = futureSnapshot.data ?? [];

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final product = products.firstWhere(
                              (p) => p['id'] == item['productId'],
                          orElse: () => {},
                        );
                        totalAmount = totalAmount + product['price'];

                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          // elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image and quantity controls
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child: Image.network(
                                          product['image'] ?? '',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              final newQuantity = (item['quantity'] ?? 1) - 1;
                                              if (newQuantity > 0) {
                                                _updateItemQuantity(item['productId'], newQuantity);
                                              }
                                            },
                                          ),
                                          Text('${item['quantity']}'),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              final newQuantity = (item['quantity'] ?? 1) + 1;
                                              _updateItemQuantity(item['productId'], newQuantity);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Product details
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['title'] ?? 'Product ID: ${item['productId']}',
                                        style: Theme.of(context).textTheme.subtitle1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '\$${product['price'] * item['quantity'] ?? '0.00'}',
                                        style: Theme.of(context).textTheme.subtitle2,
                                      ),
                                    ],
                                  ),
                                ),
                                // Remove button
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeItem(item['productId']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (cartItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: MaterialButton(
                        onPressed: () {
                          // Handle checkout or other actions
                        },
                        color: Colors.blueAccent,
                        child: Text('Checkout (\$$totalAmount})'),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProductDetails(List<Map<String, dynamic>> cartItems) async {
    final List<Map<String, dynamic>> products = [];

    for (var item in cartItems) {
      final productId = item['productId'];
      try {
        final response = await dio.get('https://fakestoreapi.com/products/$productId');
        if (response.statusCode == 200) {
          final productData = response.data as Map<String, dynamic>;
          products.add(productData);
        } else {
          print('Failed to load product details for $productId. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching product details for $productId: $e');
      }
    }

    return products;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(
      0.0,
          (total, item) => total + (item['price'] ?? 0) * (item['quantity'] ?? 0),
    );
  }
}
