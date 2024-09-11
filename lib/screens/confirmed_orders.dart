import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Confirmed_Order extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const Confirmed_Order({Key? key, required this.cartItems}) : super(key: key);

  @override
  State<Confirmed_Order> createState() => _Confirmed_OrderState();
}

class _Confirmed_OrderState extends State<Confirmed_Order> {
  List<Map<String, dynamic>> confirmedOrders = [];
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    // Add passed cart items to confirmed orders
    confirmedOrders.addAll(widget.cartItems);
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Orders').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmed Orders'),
      ),
      body: Column(
        children: [
          if (userData != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: ListTile(
                  title: Text(userData?['name'] ?? 'Unknown User'),
                  subtitle: Text('Email: ${userData?['email'] ?? 'Not Available'}\nPhone: ${userData?['phone'] ?? 'Not Available'}'),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: confirmedOrders.length,
              itemBuilder: (context, index) {
                final order = confirmedOrders[index];
                final price = (order['price'] ?? 0.0) * (order['quantity'] ?? 0);

                return ListTile(
                  title: Text(order['title'] ?? 'Unknown Product'),
                  subtitle: Text('Quantity: ${order['quantity']}'),
                  trailing: Text('\$${price.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
