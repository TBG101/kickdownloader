import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/myColors.dart';

class DropdownSelector extends GetView<Logic> {
  const DropdownSelector({super.key});

  List<DropdownMenuItem<String>> listitemButton() {
    if (controller.resolutions.isEmpty) return [];
    List<DropdownMenuItem<String>> e = [];
    for (var element in controller.resolutions) {
      e.add(DropdownMenuItem(
        value: element,
        child: Text(element),
      ));
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: controller.foundVideo.value
                  ? MyColors.gradient
                  : MyColors.gradientDisabled,
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButton<String>(
              elevation: 2,
              disabledHint: const Text("Video Quality"),
              value: controller.qualitySelector.value,
              iconEnabledColor: Colors.white,
              isExpanded: true, //make true to take width of parent widget
              underline: const SizedBox.shrink(), //empty line
              padding: const EdgeInsets.symmetric(horizontal: 20),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: "SpaceGrotesk",
                  fontWeight: FontWeight.w600),
              items: listitemButton(),
              onChanged: (Object? value) {
                controller.qualitySelector.value = value as String;
              },
            ),
          ),
        )));
  }
}
