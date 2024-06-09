import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';

class StreamThumbnail extends GetView<Logic> {
  const StreamThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
            color: const Color.fromARGB(83, 37, 37, 37),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.5), width: 1),
            boxShadow: [
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
          child: Obx(() {
            return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: () {
                  if (controller.fetchingData.value == true) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.foundVideo.isFalse) {
                    return const Center(
                        child: Text(
                      "No Video ",
                      style: TextStyle(fontSize: 20),
                    ));
                  }

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
                }());
          }),
        ),
      ),
    );
  }
}
