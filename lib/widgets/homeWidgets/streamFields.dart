import 'package:flutter/material.dart';

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
              color: Color.fromARGB(255, 255, 255, 255),
              fontFamily: "SpaceGrotesk"),
          children: <TextSpan>[
            TextSpan(
              text: text,
              style: const TextStyle(
                  color: Color.fromARGB(255, 235, 235, 235),
                  overflow: TextOverflow.ellipsis,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: "SpaceGrotesk"),
            ),
          ]),
    );
  }
}
