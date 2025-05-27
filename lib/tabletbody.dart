import 'package:flutter/material.dart';

class MyTabletBody extends StatelessWidget {
  const MyTabletBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(100, 59, 159, 100),
      //App Bar start
      appBar: AppBar(
        title: Text('GetGoods',
        style: TextStyle(
          color: const Color.fromARGB(255, 0, 0, 0),
          fontSize: 20,
          fontWeight: FontWeight.bold
        ),
      ),
      backgroundColor: Color.fromRGBO(100, 59, 159, 10)
      ),
      //App Bar End
      body: Column(
        
      ),
    );
  }
}