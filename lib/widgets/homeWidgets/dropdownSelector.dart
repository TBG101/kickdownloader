import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/myColors.dart';

class DropdownSelector extends GetView<Logic> {
  const DropdownSelector({super.key});

  List<DropdownMenuItem<String>> listitemButton() {
    if (controller.resolutions.isEmpty) return [];
    List<DropdownMenuItem<String>> e = [];
    controller.resolutions.forEach((element) {
      e.add(DropdownMenuItem(
        value: element,
        child: Text(element),
      ));
    });
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
              color: myColors.btnPrimary,
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButton<String>(
              elevation: 2,
              disabledHint: const Text("Video Quality"),
              value: controller.valueSelected.value,
              iconEnabledColor: myColors.white,
              isExpanded: true, //make true to take width of parent widget
              underline: Container(), //empty line
              padding: const EdgeInsets.symmetric(horizontal: 20),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
              items: listitemButton(),
              onChanged: (Object? value) {
                controller.valueSelected.value = value as String;
              },
            ),
          ),
        )));
  }
}
