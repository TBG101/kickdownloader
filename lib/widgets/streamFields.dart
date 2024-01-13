import 'package:flutter/material.dart';
import 'package:kickdownloader/myColors.dart';

class StreamFields extends StatelessWidget {
  const StreamFields({super.key, required this.field, required this.text});
  final String text;
  final String field;
  @override
  Widget build(BuildContext context) {
    return RichText(
      softWrap: true,
      text: TextSpan(
          text: '$field:  ',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          children: <TextSpan>[
            TextSpan(
              text: text,
              style: TextStyle(
                color: myColors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ]),
    );
  }
}
