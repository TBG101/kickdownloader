import 'package:flutter/material.dart';

class VideoTimeWidget extends StatelessWidget {
  const VideoTimeWidget(
      {super.key, required this.text, this.padLeft = 0, required this.enable});
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
            enabled: enable,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: text,
              border: const OutlineInputBorder(),
            ),
          ),
        ));
  }
}
