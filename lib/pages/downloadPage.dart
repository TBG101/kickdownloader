import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';

class DownloadPage extends GetView<Logic> {
  const DownloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
          itemCount: controller.queeVideoDownload.length,
          itemBuilder: (context, index) {
            return Text(
                "name : ${(controller.queeVideoDownload[index]["downloading"] as bool) ? controller.videoDownloadPercentage.value : " waiting"}");
          },
        ));
  }
}
