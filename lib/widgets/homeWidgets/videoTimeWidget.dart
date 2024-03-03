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
