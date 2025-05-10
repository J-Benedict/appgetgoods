import 'package:flutter/material.dart';

import 'dimensions.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget tabletBody;
  final Widget category;

  const ResponsiveLayout({super.key, required this.mobileBody, required this.tabletBody, required this.category});
  


  @override
  Widget build(BuildContext context){
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < mobileWidth){
            return mobileBody;
          } 
          else {
            return tabletBody;
          }
        }
      );
  }
}