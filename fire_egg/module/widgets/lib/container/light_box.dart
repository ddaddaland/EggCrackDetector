import 'package:fire_egg_widgets/label/label.dart';
import 'package:flutter/material.dart';

class LightBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool withBorder;
  final double? width, height;
  final void Function()? onTap;

  const LightBox({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.withBorder = true,
    this.onTap,
  });

  LightBox.label({
    super.key,
    required String label,
    required IconData icon,
    required Widget child,
    Widget? trailing,
    this.padding,
    this.withBorder = true,
    this.width,
    this.height,
    this.onTap,
  }) : child = Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         spacing: 5,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             spacing: 10,
             children: [
               Label(icon, label),

               if (trailing != null) ...[
                 trailing,
               ],
             ],
           ),
           child,
         ],
       );

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(5);
    final body = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x09FFFFFF),
        borderRadius: borderRadius,
        border: withBorder ? Border.all(color: Colors.white10) : null,
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: child,
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: borderRadius, child: body);
    } else {
      return body;
    }
  }
}
