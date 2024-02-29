import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/widgets/homeWidgets/videoTimeWidget.dart';

class TimeSelectorRowStart extends GetView<Logic> {
  const TimeSelectorRowStart({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: size.width * 0.24,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Start",
                          style: TextStyle(fontSize: 17),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: controller.startValue.value,
                            onChanged: (s) {
                              if (controller.foundVideo.value == false) return;
                              controller.startValue.value =
                                  !controller.startValue.value;
                              if (controller.startValue.value == true) {
                                controller.startHour.value.text = "0";
                                controller.startMinute.value.text = "0";
                                controller.startSecond.value.text = "0";
                              } else {
                                controller.startHour.value.text = "";
                                controller.startMinute.value.text = "";
                                controller.startSecond.value.text = "";
                              }
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                      ]),
                ),
                SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VideoTimeWidget(
                        text: "H",
                        enable: controller.foundVideo.value &&
                            controller.startValue.value,
                        controller: controller.startHour.value,
                      ),
                      VideoTimeWidget(
                        text: "S",
                        padLeft: 9,
                        enable: controller.foundVideo.value &&
                            controller.startValue.value,
                        controller: controller.startMinute.value,
                      ),
                      VideoTimeWidget(
                        text: "M",
                        padLeft: 9,
                        enable: controller.foundVideo.value &&
                            controller.startValue.value,
                        controller: controller.startSecond.value,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
