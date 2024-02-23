import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';
import 'package:kickdownloader/utilities/logic.dart';

class DownloadVodBtn extends GetView<Logic> {
  const DownloadVodBtn({super.key});

  @override
  Widget build(BuildContext context) {
    var condition =
        controller.foundVideo.value && controller.lastVideoLink.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 10),
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          gradient: MyColors.gradient,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0x00000000),
              disabledBackgroundColor: const Color(0x00000000),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5))),
          onPressed: condition ? controller.downloadVodDataBtn : null,
          child: Text(
            "Download VOD",
            style: TextStyle(
                color: condition ? MyColors.white : MyColors.textDisbaled,
                fontSize: 18,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}
