import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:infinity_scrolling_project/consts.dart';
import 'package:intl/intl.dart';
import '../Models/FakeApi.dart';
import 'cart_hive_model.dart';

class ScrollingPage extends StatefulWidget {
  const ScrollingPage({super.key});

  @override
  State<ScrollingPage> createState() => _ScrollingPageState();
}

class _ScrollingPageState extends State<ScrollingPage> with AutomaticKeepAliveClientMixin {
  final Dio dio = Dio();
  PageController controller = PageController(initialPage: 0);
  List<StoreApi> storedata = [];
  bool isLoadingMore = false;
  bool _showScrollToTopButton = false;
  int currentApiIndex = 0;
  final Random _random = Random();
  bool isReversed = false;
  int cartCount = 0;
  var userId;
  CollectionReference cartCollection = FirebaseFirestore.instance.collection('Carts');

  final List<String> apiUrls = [
    'https://fakestoreapi.com/products'
  ];

  @override
  void initState() {
    super.initState();
    _initHive();
    _getStoreData();
    controller.addListener(() {
      if (controller.position.pixels >= controller.position.maxScrollExtent * 0.9) {
        _fetchMoreData();
      }
      if (controller.offset >= 400) {
        if (!_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = true;
          });
        }
      } else {
        if (_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = false;
          });
        }
      }
    });
  }

  Future<void> _initHive() async {
    await Hive.openBox<CartItem>('cartBox');
    // other initialization
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      body: Stack(
        children: [
          _buildUI(size, isPortrait),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: Text(
                      'Products',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: isPortrait ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: cartCollection.doc(userId).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/cart'),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/cart'),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }

                      final cartData = snapshot.data!.data() as Map<String, dynamic>;
                      final products = List<Map<String, dynamic>>.from(cartData['products'] ?? []);
                      final cartCount = products.length;
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/cart'),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 5),
                              Text(
                                cartCount != 0 ? '$cartCount' : '',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: isPortrait ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUI(Size size, bool isPortrait) {
    return storedata.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _refresh,
      child: PageView.builder(
        controller: controller,
        scrollDirection: Axis.vertical,
        itemCount: storedata.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == storedata.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final storeone = storedata[index];
          return Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(storeone.imageUrl ?? PLACEHOLDER_IMAGE_LINK),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 10),
                _showScrollToTopButton
                    ? IconButton(
                  onPressed: () {
                    _scrollToTop();
                  },
                  style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white),
                  icon: Icon(Icons.arrow_upward_outlined),
                )
                    : const SizedBox(height: 10),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              storeone.title ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isPortrait ? 24 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final product = {'productId': storeone.id, 'quantity': 1};
                              // addCartItem(userId, [product]);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.cyan.withOpacity(0.5),
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                                size: isPortrait ? 24 : 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '\$${storeone.price.toString()}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isPortrait ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchMoreData() async {
    if (!isLoadingMore) {
      setState(() {
        isLoadingMore = true;
      });
      await _getStoreData(page: (storedata.length ~/ 10) + 1);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      storedata.clear();
      isLoadingMore = false;
    });
    currentApiIndex = returnRandom();
    await _getStoreData();

    setState(() {
      // Toggle the reversed state
      isReversed = !isReversed;

      // Reverse the list if isReversed is true
      if (isReversed) {
        storedata = storedata.reversed.toList();
      }
    });
  }

  int returnRandom() {
    var length = apiUrls.length;
    var randomNum = _random.nextInt(length);
    return randomNum;
  }

  Future<void> _getStoreData({int page = 1}) async {
    final response = await dio.get(
      '${apiUrls[returnRandom()]}',
    );
    final storeApiJson = response.data as List;
    setState(() {
      List<StoreApi> newsStoreApi = storeApiJson.map((a) => StoreApi.fromJson(a)).toList();
      newsStoreApi = newsStoreApi.where((a) => a.title != "[Removed]").toList();

      if (page == 1) {
        storedata = newsStoreApi;
      } else {
        storedata.addAll(newsStoreApi);
      }

      isLoadingMore = false;
    });
  }




  void _scrollToTop() {
    controller.animateTo(
      0,
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }
}
