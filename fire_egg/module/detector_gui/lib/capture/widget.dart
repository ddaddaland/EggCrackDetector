// import 'package:fire_egg_common/detection/object_class.dart';
// import 'package:fire_egg_widgets/detection/overlay.dart';
// import 'package:flutter/material.dart';
//
// class CaptureWidget extends StatefulWidget {
//   final Capture capture;
//   final List<YoloObjectClass> classes;
//   final int imageSize;
//
//   const CaptureWidget({
//     super.key,
//     required this.capture,
//     required this.classes,
//     required this.imageSize,
//   });
//
//   @override
//   State<CaptureWidget> createState() => _CaptureWidgetState();
// }
//
// class _CaptureWidgetState extends State<CaptureWidget> {
//   late final cap = widget.capture;
//   late final classes = widget.classes;
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: cap.stateStream,
//       builder: (context, _) {
//         final process = cap.process;
//         final result = process?.result;
//         return GridView(
//           gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//             maxCrossAxisExtent: 300,
//             mainAxisSpacing: 5,
//             crossAxisSpacing: 5,
//           ),
//           children: [
//             ...cap.images.map((image) {
//               final detections = result?.detectionsByImage[image.index];
//
//               return Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   Image.memory(
//                     image.bytes,
//                   ),
//                   if (detections != null)
//                     DetectionOverlay(
//                       detections: detections,
//                       classes: classes,
//                       sourceImageSize: Size.square(widget.imageSize.toDouble()),
//                     ),
//                 ],
//               );
//             }),
//           ],
//         );
//       },
//     );
//   }
// }
