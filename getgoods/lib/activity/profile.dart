import 'package:flutter/material.dart';
import 'mobilebody.dart';
import 'categorypage.dart';
import 'cart.dart';
import 'ggmall.dart';
import 'notifications.dart';
import 'settings.dart';
import 'login.dart';
import 'signup.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _AccountPageState();
}

class _AccountPageState extends State<Profilepage> {
  final Color primaryColor = Color(0xFF7B1FA2); // Purple
  int _selectedIndex = 4; // Account is the fifth item (index 4)

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
      // case 2 and 3 are placeholders
      case 2:
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Ggmall()),
        );

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Notifications()),
        );
        break;
      case 4:
        // Already on Profile page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section
            Container(
              color: primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: primaryColor),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    child: const Text("Login"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Signup()),
                      );
                    },
                    child: Text("Sign Up"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),

                  SizedBox(width: 10),
                  
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Settings()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Sections
            buildSection(
              title: "My Purchases",
              rightText: "View Purchase History",
              icons: [
                Icons.payment,
                Icons.local_shipping,
                Icons.move_to_inbox,
                Icons.star_rate,
              ],
              labels: ["To Pay", "To Ship", "To Receive", "To Rate"],
            ),
            buildSection(
              title: "My Wallet",
              icons: [
                Icons.account_balance_wallet,
                Icons.monetization_on,
                Icons.schedule,
                Icons.card_giftcard,
              ],
              labels: ["GG Pay", "GG Coins", "GG PayLater", "Vouchers"],
            ),
            SizedBox(height: 40),
            Text(
              "COMING SOON!!!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'GG Mail'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  
  Widget buildSection({
    required String title,
    String? rightText,
    required List<IconData> icons,
    required List<String> labels,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              Spacer(),
              if (rightText != null)
                Text(rightText, style: TextStyle(color: Colors.grey)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(icons.length, (index) {
              return Column(
                children: [
                  Icon(icons[index], color: primaryColor),
                  SizedBox(height: 5),
                  Text(labels[index], style: TextStyle(fontSize: 12)),
                ],
              );
            }),
          )
        ],
      ),
    );
  }
}
