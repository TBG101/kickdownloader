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
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: "SpaceGrotesk"),
          children: <TextSpan>[
            TextSpan(
              text: text,
              style: const TextStyle(
                  color: MyColors.white,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 15,
                  fontFamily: "SpaceGrotesk"),
            ),
          ]),
    );
  }
}
