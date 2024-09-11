import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:lottie/lottie.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shimmer/shimmer.dart';


import 'Customer_form.dart';
import 'confirmed_orders.dart';


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
  List<Map<String, dynamic>> products = [];
  double totalAmount = 0;
  bool isLoading = true;
  Razorpay _razorpay = Razorpay();

  @override
  void initState() {
    super.initState();
    _getUserId();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      await _fetchCartData();
    } else {
      print('User is not signed in.');
    }
  }

  Future<void> _fetchCartData() async {
    try {
      final cartDoc = cartCollection.doc(userId);
      final cartSnapshot = await cartDoc.get();
      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>;
        setState(() {
          cartItems = List<Map<String, dynamic>>.from(cartData['products'] ?? []);
        });
        await _fetchProductDetails();
      }
    } catch (e) {
      print('Error fetching cart data: $e');
    }
  }

  Future<void> _fetchProductDetails() async {
    final productIds = cartItems.map((item) => item['productId']).toList();
    final List<Future<Response>> futures = productIds.map((id) => dio.get('https://fakestoreapi.com/products/$id')).toList();

    try {
      final responses = await Future.wait(futures);
      setState(() {
        products = responses.where((response) => response.statusCode == 200)
            .map((response) => response.data as Map<String, dynamic>)
            .toList();
        totalAmount = _calculateTotal(cartItems, products);
        isLoading = false; // Set loading to false after fetching data
      });
    } catch (e) {
      print('Error fetching product details: $e');
    }
  }



  Future<void> _deleteAllItems() async {
    try {
      final cartDoc = cartCollection.doc(userId);
      await cartDoc.update({
        'products': [], // Clear all items by setting 'products' to an empty list
      });
      setState(() {
        cartItems = []; // Clear local cartItems list
        totalAmount = 0; // Reset total amount
      });
    } catch (e) {
      print('Error deleting all items: $e');
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
          await _fetchCartData(); // Refresh cart data after update
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
        await _fetchCartData(); // Refresh cart data after removal
      }
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cart'),
        actions: [
          IconButton(onPressed: (){
            _deleteAllItems();
          }, icon: Icon(Icons.clear_all_outlined))],
      ),
      body: isLoading
          ? _buildShimmerEffect()
          : cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
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

                // Ensure product and quantity are not null
                final price = product['price'] ?? 0.0;
                final quantity = item['quantity'] ?? 0;

                return Container(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image and quantity controls
                        SizedBox(
                          width: MediaQuery.of(context).size.width *0.3,
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
                                      final newQuantity = quantity - 1;
                                      if (newQuantity > 0) {
                                        _updateItemQuantity(item['productId'], newQuantity);
                                      }
                                    },
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      final newQuantity = quantity + 1;
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
                                '\$${price * quantity}',
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CustomerDetailsForm(totalAmount: totalAmount, razorpay: _razorpay)),
                  );
                },
                color: Colors.blueAccent,
                child: Text('Checkout (\$$totalAmount)'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 5, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder for product image
                  Expanded(
                    flex: 2,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Placeholder for product details
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: Colors.white,
                          height: 16,
                          width: double.infinity,
                        ),
                        SizedBox(height: 8),
                        Container(
                          color: Colors.white,
                          height: 16,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _succefullPaymentAction() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not signed in.');
        return;
      }

      final cartDoc = FirebaseFirestore.instance.collection('Carts').doc(user.uid);
      final orderDoc = FirebaseFirestore.instance.collection('Orders').doc(user.uid);

      // Show Lottie animation
      showDialog(
        context: context,
        builder: (context) => Center(
          child: Container(
            width: 200,
            height: 200,
            child: Lottie.asset('assets/animation/success.json'),
          ),
        ),
        barrierDismissible: false,
      );

      // Delay for the duration of the animation
      await Future.delayed(Duration(milliseconds: 1400));

      // Close the dialog
      Navigator.of(context).pop();

      // Create order data
      final orderData = {
        'userId': user.uid,
        'orderId': orderDoc.id,  // This will be the user's ID
        'products': cartItems,
        'totalAmount': totalAmount,
        'orderDate': FieldValue.serverTimestamp(),
      };

      // Save order data to Firestore with user ID as the document ID
      await orderDoc.set(orderData);

      // Clear the cart data
      await cartDoc.update({
        'products': [],
      });

      setState(() {
        cartItems = [];
        totalAmount = 0;
      });

      // Navigate to Confirmed_Order screen and pass cart items
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Confirmed_Order(
            cartItems: cartItems,
          ),
        ),
      );
    } catch (e) {
      print('Error in successful payment action: $e');
    }
  }




  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('pay sucess 123 _handlePaymentSuccess');
    _succefullPaymentAction();
    Fluttertoast.showToast(
      timeInSecForIosWeb: 12,
      msg: "Payment Success: ${response.data}",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    print('pay success 123 _handlePaymentError');

    // Show Lottie animation
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 200,
          height: 200,
          child: Lottie.asset('assets/animation/Animation - 1722842971499.json'),
        ),
      ),
      barrierDismissible: false,
    );
    Fluttertoast.showToast(
      msg: "Payment Failed",
      toastLength: Toast.LENGTH_SHORT,
    );

    // Delay for the duration of the animation
    await Future.delayed(Duration(seconds: 2));

    // Close the Lottie animation dialog
    Navigator.of(context).pop();

  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _succefullPaymentAction();
    print('pay sucess 123 _handleExternalWallet');
    Fluttertoast.showToast(
        msg: "Payment Success with:  ${response.walletName}",
        toastLength: Toast.LENGTH_SHORT
    );
  }

  double _calculateTotal(List<Map<String, dynamic>> cartItems, List<Map<String, dynamic>> products) {
    double total = 0.0;
    for (final item in cartItems) {
      final product = products.firstWhere(
            (p) => p['id'] == item['productId'],
        orElse: () => {},
      );
      final price = product['price'] ?? 0.0;
      final quantity = item['quantity'] ?? 0;
      total += price * quantity;
    }
    return total;
  }
}
