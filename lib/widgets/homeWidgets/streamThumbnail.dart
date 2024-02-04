import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';

class StreamThumbnail extends GetView<Logic> {
  const StreamThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(
          color: const Color(0x00000000)
              .withOpacity(controller.gradientOpacity.value),
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 1,
        )
      ]),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            controller.link.value,
            fit: BoxFit.fitWidth,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                controller.gradientOpacity.value = 0.4;
                return child;
              }
              controller.gradientOpacity.value = 0;
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}
