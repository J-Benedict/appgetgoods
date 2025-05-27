import 'package:flutter/material.dart';




class Messages extends StatefulWidget {
  const Messages({super.key});

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Color(0xFF6C45F3),
        title: Row(
          children: [
            Icon(Icons.shopping_bag, color: Colors.white),
            SizedBox(width: 8),
            Text('Get Goods', style: TextStyle(color: Colors.white)),
           

          ],
        ),
      ),
      body: Column(
        children: [
          Text('Messages will appear here', style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)))
        ],
      ),
      
      
      
    );
  }
}