import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenHeight = constraints.maxHeight;
          double screenWidth = constraints.maxWidth;
          double avatarRadius = screenHeight * 0.1;
          double padding = screenHeight * 0.02;
          double gridHeight = screenHeight * 0.4;
          double headerspace = screenHeight * 0.15;

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: headerspace),
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.network(
                      'https://static.vecteezy.com/system/resources/previews/029/711/176/non_2x/developer-with-ai-generated-free-png.png',
                      fit: BoxFit.cover,
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                    ),
                  ),
                ),
                SizedBox(height: padding),
                Text(
                  'Muhammed Shalbin M P',
                  style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: padding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Flutter Developer | Daily',
                      style: TextStyle(fontSize: screenWidth * 0.04),
                    ),
                    Icon(
                      Icons.developer_mode_rounded,
                      color: Colors.blue,
                      size: screenWidth * 0.05,
                    )
                  ],
                ),
                SizedBox(height: padding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BuildSocialCard(Icons.facebook, Colors.blue.withOpacity(0.2)),
                    BuildSocialCard(Icons.whatshot, Colors.pink.withOpacity(0.2)),
                    BuildSocialCard(Icons.apple_rounded, Colors.black87.withOpacity(0.2)),
                    BuildSocialCard(Icons.sunny, Colors.red.withOpacity(0.2)),
                  ],
                ),
                SizedBox(height: padding),
                Container(
                  height: gridHeight,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    child: BuildGridView(),
                  ),
                ),
                SizedBox(height: padding),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget BuildGridView() {
    final List<String> imageUrls = [
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9m2_vhNVneYcC1E0n0loGAWh3mqBbaCGSXQ&s',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQyu2q3IQb0nNT8uCxtrrgMb7vBMDjVaKVxeg&s',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQqJOh7xO7_OBYnmy26ppdEBy_yH1Oe5aBvzg&s',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS1cn7MyWTcEcSKucawe_OYLDeNqOYkb6PfAQ&s',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTnIhxXOI8H7zsLt3HWB165LEL9hC8THf1zMw&s',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRKn3_PwG92uFGelKLlrR14aI3K90fXd3Vofg&s',
      // Add more image URLs here
    ];

    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Number of columns in the grid
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15), // Adjust the radius as needed
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget BuildSocialCard(IconData icon, Color selectedColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selectedColor,
      ),
      padding: EdgeInsets.all(10),
      child: Icon(icon),
    );
  }
}
