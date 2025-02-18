import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FullScreenImage extends StatelessWidget {
  final String imagePath;
  const FullScreenImage({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center( // Keep the rounded corners
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
          ),
      ),
    );
  }
}