import 'package:flutter/material.dart';
import 'package:app/constants/colors.dart';

class Head1 extends StatelessWidget {
  final String text;
  final double weight;
  final Color? color;
  final TextAlign textAlign;
  final double? lineHeight; // <-- New parameter

  const Head1(
    this.text, {
    this.weight = 700,
    this.color,
    this.textAlign = TextAlign.start,
    this.lineHeight = 1.5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 35,
        height: lineHeight, // <-- Apply here
        fontVariations: [
          FontVariation('wght', weight),
        ],
        color: color ?? AppColors.karry[100],
      ),
    );
  }
}

class Head2 extends StatelessWidget {
  final String text;
  final double weight;
  final Color? color;
  final TextAlign textAlign;
  final double? lineHeight; // <-- New parameter

  const Head2(
    this.text, {
    this.weight = 700,
    this.color,
    this.textAlign = TextAlign.start,
    this.lineHeight = 1.5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 22,
        height: lineHeight, // <-- Apply here
        fontVariations: [
          FontVariation('wght', weight),
        ],
        color: color ?? AppColors.karry[100],
      ),
    );
  }
}
