import 'package:flutter/material.dart';
import 'package:getgoods/mobilebody.dart';
import 'package:getgoods/responsivelayout.dart';
import 'package:getgoods/tabletbody.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: MyMobileBody(),
        tabletBody: MyTabletBody(),
      ),
    );
  }
}