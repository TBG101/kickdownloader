import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';

class VideoTimeWidget extends StatelessWidget {
  const VideoTimeWidget({
    super.key,
    required this.text,
    this.padLeft = 0,
    required this.enable,
    this.controller,
  });
  final TextEditingController? controller;
  final bool enable;
  final String text;
  final double padLeft;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: ((MediaQuery.of(context).size.width * 0.7) / 3),
        child: Padding(
          padding: EdgeInsets.only(left: padLeft),
          child: TextField(
            enableSuggestions: false,
            autocorrect: false,
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              if (text == "S" || text == "M")
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isNotEmpty) {
                    final int? newValueAsInt = int.tryParse(newValue.text);
                    if (newValueAsInt == null) return oldValue;
                    if (newValueAsInt > 60) {
                      // Value exceeds maximum, limit it to maxValue
                      if (!Get.isSnackbarOpen) {
                        Get.snackbar("Notifier", "Value can't go over 60",
                            backgroundColor: MyColors.background,
                            isDismissible: true,
                            barBlur: 0,
                            overlayBlur: 0,
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 10),
                            snackPosition: SnackPosition.TOP);
                      }
                      return oldValue;
                    }
                  }
                  return newValue;
                })
            ],
            textInputAction: TextInputAction.next,
            enabled: enable,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              disabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: MyColors.disabledBorder)),
              hintText: text,
              border: const OutlineInputBorder(),
            ),
          ),
        ));
  }
}
