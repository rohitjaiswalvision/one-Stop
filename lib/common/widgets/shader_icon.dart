import 'package:flutter/material.dart';

class ShaderIcon extends StatelessWidget {
  final IconData  icon;
  const ShaderIcon({super.key,required this.icon});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [
        Color(0xFF1565C0),
      Color(0xFFFF9800),
    ]).createShader(bounds),child: Icon(icon,color: Colors.white,),);
  }
}