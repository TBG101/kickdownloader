import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/utilities/logic.dart';
import 'package:kickdownloader/widgets/videoTimeWidget.dart';

class TimeSelectorRowEnd extends GetView<Logic> {
  const TimeSelectorRowEnd({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.24,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "End",
                          style: TextStyle(fontSize: 17),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: controller.endValue.value,
                            onChanged: (s) {
                              if (controller.foundVideo.value == false) return;
                              controller.endValue.value =
                                  !controller.endValue.value;

                              if (controller.endValue.value == true) {
                                controller.endHour.value.text =
                                    controller.streamLength.value.split(":")[0];
                                controller.endMinute.value.text =
                                    controller.streamLength.value.split(":")[1];
                                controller.endSecond.value.text =
                                    controller.streamLength.value.split(":")[2];
                              } else {
                                controller.endHour.value.text = "";
                                controller.endMinute.value.text = "";
                                controller.endSecond.value.text = "";
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
                            controller.endValue.value,
                        controller: controller.endHour.value,
                      ),
                      VideoTimeWidget(
                        text: "S",
                        padLeft: 9,
                        enable: controller.foundVideo.value &&
                            controller.endValue.value,
                        controller: controller.endMinute.value,
                      ),
                      VideoTimeWidget(
                        text: "M",
                        padLeft: 9,
                        enable: controller.foundVideo.value &&
                            controller.endValue.value,
                        controller: controller.endSecond.value,
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
