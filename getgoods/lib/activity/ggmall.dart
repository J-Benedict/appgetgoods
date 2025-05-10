import 'package:flutter/material.dart';

import 'categorypage.dart';
import 'profile.dart'; 
import 'cart.dart';
import 'mobilebody.dart';
import 'notifications.dart';

class Ggmall extends StatefulWidget {
  const Ggmall({super.key});

  @override
  State<Ggmall> createState() => _GgmallState();
}

class _GgmallState extends State<Ggmall> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyMobileBody()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Categorypage()),
        );
        break;
        case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Ggmall()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Notifications()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profilepage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.white),
            SizedBox(width: 8),
            Text("GG Mall"),
            Spacer(),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric( horizontal: 10 ),
                height: 38,
                child: TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    hintText: "Search",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),

          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("DEALS", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            _buildProductCard("Nike Air 270 React", "₱1,999", "nike.jpg"),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("RECOMMENDED", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            _buildProductGrid(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // <-- Handle tap
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Categories"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "GG Mall"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  


  Widget _buildProductCard(String title, String price, String imagePath) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        children: [
          Image.asset(imagePath, height: 120, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(price, style: TextStyle(color: Colors.purple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    List<Map<String, String>> products = [
      {"title": "Nike Air 270 React", "price": "₱1,999", "image": "nike.jpg"},
      {"title": "NVIDIA RTX 5090 16GB VRAM", "price": "₱155,690", "image": "rtx.jpg"},
      {"title": "Boeing 777X", "price": "₱500,000,000", "image": "plano.jpg"},
      {"title": "Xavier Electric Wheelchair", "price": "₱50,000", "image": "xavier.jpg"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(
          products[index]["title"]!,
          products[index]["price"]!,
          products[index]["image"]!,
        );
      },
    );
  }
}
