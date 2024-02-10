import 'package:cached_network_image/cached_network_image.dart';
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
          child: Obx(() {
            return CachedNetworkImage(
              imageUrl: controller.link.value,
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) {
                return const Icon(Icons.error);
              },
            );
          }),
        ),
      ),
    );
  }
}
