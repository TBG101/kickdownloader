import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kickdownloader/myColors.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final bool enabled;

  final String text;

  const MyButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        gradient: enabled ? MyColors.gradient : MyColors.gradientDisabled,
      ),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5))),
          onPressed: enabled ? onTap : null,
          child: Text(
            text,
            style: TextStyle(
                color: enabled ? MyColors.white : MyColors.textDisbaled,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          )),
    );
  }
}
