import 'package:flutter/material.dart';
import 'package:getgoods/activity/categorypage.dart';
import 'package:getgoods/activity/mobilebody.dart';
import 'package:getgoods/activity/responsivelayout.dart';
import 'package:getgoods/activity/tabletbody.dart';

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
        category: Categorypage(),
      ),
    );
  }
}