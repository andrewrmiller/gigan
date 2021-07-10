import 'package:flutter/material.dart';

class WaitSpinner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Center(
        child: SizedBox(
      child: CircularProgressIndicator(),
      width: 60,
      height: 60,
    ));
  }
}
