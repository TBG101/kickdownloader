import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              FilteringTextInputFormatter.digitsOnly
            ],
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              var time = int.tryParse(value);
              if (time == null) return;
              if (text == "S" || text == "M") {
                if (time < 0 && time > 60) {
                  value = "0";
                }
              }
            },
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
