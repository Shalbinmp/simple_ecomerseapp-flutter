

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CustomerDetailsForm extends StatefulWidget {
  final double totalAmount;
  final Razorpay razorpay;

  const CustomerDetailsForm({Key? key, required this.totalAmount, required this.razorpay}) : super(key: key);

  @override
  _CustomerDetailsFormState createState() => _CustomerDetailsFormState();
}

class _CustomerDetailsFormState extends State<CustomerDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _phone, _email;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }




  Future<void> _fetchAndSetLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        Placemark placemark = placemarks.first;
        setState(() {
          _addressController.text = '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.postalCode ?? ''}, ${placemark.country ?? ''}';
        });
      } catch (e) {
        print('Error fetching location: $e');
      }
    } else {
      print('Location permission denied');
    }
  }

  void _openRazorpayCheckout(double amount, String name, String address, String email, String phone) {
    var options = {
      'key': 'rzp_test_E6AcSJXP948Z0Z', // Replace with your Razorpay API key
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Semov pvt',
      'description': 'Payment for your order',
      'prefill': {
        'contact': phone,
        'email': email,
      },
      'notes': {
        'address': address,
      },
      'theme': {
        'color': '#000000',
      },
      'external' : {
        'wallets' : ['paytm','phonepe','gpay']
      },
    };

    try {
      widget.razorpay.open(options);
    } catch (e) {
      print('Error opening Razorpay checkout: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Customer Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  _buildTextFormField(
                    label: 'Name',
                    onSaved: (value) => _name = value!,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.location_on),
                        onPressed: _fetchAndSetLocation,
                      ),
                    ),
                    onSaved: (value) => _addressController.text = value!,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'Phone',
                    keyboardType: TextInputType.phone,
                    onSaved: (value) => _phone = value!,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  _buildTextFormField(
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => _email = value!,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _openRazorpayCheckout(widget.totalAmount, _name, _addressController.text, _email, _phone);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      child: Text('Proceed to Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: suffixIcon,
      ),
      onSaved: onSaved,
      validator: validator,
      keyboardType: keyboardType,
      readOnly: readOnly,
    );
  }
}
