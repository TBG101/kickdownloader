import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';

class DownloadPage extends GetView<Logic> {
  const DownloadPage({super.key});

  String textSelector(int index) {
    if ((controller.queeVideoDownload[index]["downloading"] as bool)) {
      return "name : ${controller.videoDownloadPercentage.value.toStringAsFixed(0)}";
    } else if (controller.videoDownloadPercentage.value >= 100) {
      return "name : ${controller.videoDownloadPercentage.value.toStringAsFixed(0)}";
    } else {
      return "name: waiting for quee";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
          itemCount: controller.queeVideoDownload.length,
          itemBuilder: (context, index) {
            return Obx(() {
              return Text(textSelector(index));
            });
          },
        ));
  }
}
