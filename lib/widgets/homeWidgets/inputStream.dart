import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';

class InputStreamUrl extends GetView<Logic> {
  const InputStreamUrl({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextField(
          controller: controller.url.value,
          autocorrect: false,
          decoration: const InputDecoration(
              hintText: "Stream URL", border: OutlineInputBorder()),
        ));
  }
}
