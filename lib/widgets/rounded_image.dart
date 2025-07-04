import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RoundedImageFile extends StatelessWidget {
  final PlatformFile image;
  final double size;

  const RoundedImageFile({Key? key, required this.image, required this.size})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    DecorationImage? decorationImage;
    if (kIsWeb && image.bytes != null) {
      decorationImage = DecorationImage(
        fit: BoxFit.cover,
        image: MemoryImage(image.bytes!),
      );
    } else if (image.path != null) {
      decorationImage = DecorationImage(
        fit: BoxFit.cover,
        image: FileImage(File(image.path!)),
      );
    }
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        image: decorationImage,
        shape: BoxShape.circle,
        color: Colors.black,
      ),
      child: decorationImage == null
          ? const Icon(Icons.image, color: Colors.white54)
          : null,
    );
  }
}

class RoundedImageNetwork extends StatelessWidget {
  final String imagePath;
  final double size;

  const RoundedImageNetwork({
    Key? key,
    required this.imagePath,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(imagePath),
        ),
        shape: BoxShape.circle,
        color: Colors.black,
      ),
    );
  }
}

class RoundedImageNetworkWithStatusIndicator extends StatelessWidget {
  final String imagePath;
  final double size;
  final bool isActive;

  const RoundedImageNetworkWithStatusIndicator({
    Key? key,
    required this.imagePath,
    required this.size,
    required this.isActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double indicatorSize = size * 0.32;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        RoundedImageNetwork(imagePath: imagePath, size: size),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            height: indicatorSize,
            width: indicatorSize,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
