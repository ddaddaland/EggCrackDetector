// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/services.dart';
// import 'package:onnxruntime/onnxruntime.dart';
// import 'package:image/image.dart' as img;
//
// class FireEggDetectorApp extends StatefulWidget {
//   const FireEggDetectorApp({super.key});
//
//   @override
//   State<FireEggDetectorApp> createState() => _FireEggDetectorAppState();
// }
//
// class _FireEggDetectorAppState extends State<FireEggDetectorApp> {
//   OrtSession? _session;
//   final List<String> _labels = ['egg', 'crack'];
//   File? _imageFile;
//   Size? _imgSize;
//   List<Detection> _detections = <Detection>[];
//   bool _busy = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initYolo();
//   }
//
//   Future<void> _initYolo() async {
//     OrtEnv.instance.init();
//     final options = OrtSessionOptions();
//     final file = await rootBundle.load('asset/checkpoint/dain_00.onnx');
//     final bytes = file.buffer.asUint8List();
//     _session = OrtSession.fromBuffer(bytes, options);
//   }
//
//   Future<void> _runInference() async {
//     if (_session == null || _busy) return;
//
//     final result = await FilePicker.pickFiles(type: FileType.image);
//     if (result == null) return;
//     if (result.files.single.path == null) return;
//
//     setState(() {
//       _busy = true;
//       _imageFile = File(result.files.single.path!);
//       _detections = <Detection>[];
//     });
//
//     OrtValueTensor? inputTensor;
//     try {
//       // A. 이미지 전처리
//       final bytes = await _imageFile!.readAsBytes();
//       final originalImage = img.decodeImage(bytes);
//       if (originalImage == null) {
//         throw Exception('이미지를 디코딩할 수 없습니다.');
//       }
//
//       // YOLOv8 기본 입력 사이즈 640x640
//       final resized = img.copyResize(originalImage, width: 640, height: 640);
//       final input = Float32List(3 * 640 * 640);
//       for (int y = 0; y < 640; y++) {
//         for (int x = 0; x < 640; x++) {
//           final p = resized.getPixel(x, y);
//           input[y * 640 + x] = p.r / 255.0;
//           input[640 * 640 + y * 640 + x] = p.g / 255.0;
//           input[2 * 640 * 640 + y * 640 + x] = p.b / 255.0;
//         }
//       }
//
//       // B. 추론 실행
//       inputTensor = OrtValueTensor.createTensorWithDataList(input, [
//         1,
//         3,
//         640,
//         640,
//       ]);
//       final outputs = await _session!.run(OrtRunOptions(), {
//         'images': inputTensor,
//       });
//       final rawOutput =
//           outputs[0]?.value as List<List<List<double>>>; // [1][84][8400]
//
//       // C. 후처리 (YOLOv8 Output Parsing)
//       final detections = _parseYoloV8(
//         rawOutput[0],
//         originalImage.width,
//         originalImage.height,
//       );
//       final finalDetections = _deduplicateDetections(detections);
//
//       for (final output in outputs) {
//         output?.release();
//       }
//
//       if (!mounted) return;
//       setState(() {
//         _imgSize = Size(
//           originalImage.width.toDouble(),
//           originalImage.height.toDouble(),
//         );
//         _detections = finalDetections;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('추론 실패: $e')));
//     } finally {
//       inputTensor?.release();
//       if (mounted) {
//         setState(() {
//           _busy = false;
//         });
//       }
//     }
//   }
//
//   List<Detection> _deduplicateDetections(List<Detection> detections) {
//     final sorted = List<Detection>.from(detections)
//       ..sort((a, b) => b.score.compareTo(a.score));
//     final unique = <Detection>[];
//     for (final d in sorted) {
//       final overlaps = unique.any(
//         (u) => u.label == d.label && u.rect.overlaps(d.rect),
//       );
//       if (!overlaps) {
//         unique.add(d);
//       }
//     }
//     return unique;
//   }
//
//   List<Detection> _parseYoloV8(List<List<double>> data, int imgW, int imgH) {
//     final results = <Detection>[];
//     // YOLOv8 출력: [box_x, box_y, box_w, box_h, class0_score, class1_score, ...]
//     final numClasses = data.length - 4;
//     final numPredictions = data[0].length;
//
//     for (int i = 0; i < numPredictions; i++) {
//       double maxScore = 0.0;
//       int classId = -1;
//
//       for (int c = 0; c < numClasses; c++) {
//         if (data[c + 4][i] > maxScore) {
//           maxScore = data[c + 4][i];
//           classId = c;
//         }
//       }
//
//       if (maxScore > 0.45) {
//         // 임계값
//         final cx = data[0][i];
//         final cy = data[1][i];
//         final w = data[2][i];
//         final h = data[3][i];
//
//         // 640 기준 좌표를 원본 이미지 좌표로 복구
//         final x = (cx - w / 2) * (imgW / 640);
//         final y = (cy - h / 2) * (imgH / 640);
//         final width = w * (imgW / 640);
//         final height = h * (imgH / 640);
//
//         results.add(
//           Detection(
//             Rect.fromLTWH(x, y, width, height),
//             _labels.length > classId ? _labels[classId] : 'ID: $classId',
//             maxScore,
//           ),
//         );
//       }
//     }
//     // 간단하게 상위 20개만 표시 (실제로는 NMS 알고리즘 추가 권장)
//     results.sort((a, b) => b.score.compareTo(a.score));
//     return results.take(20).toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         elevation: 0,
//         title: const Text(
//           'Windows YOLO Analyzer',
//           style: TextStyle(fontWeight: FontWeight.w700),
//         ),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF101820), Color(0xFF0B2E3F)],
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Color(0xFF0B0F17), Color(0xFF121E2C), Color(0xFF0A1B24)],
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final isWide = constraints.maxWidth >= 980;
//               if (isWide) {
//                 return Row(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     SizedBox(width: 340, child: _buildControlPanel()),
//                     const SizedBox(width: 20),
//                     Expanded(child: _buildImageDisplay()),
//                   ],
//                 );
//               }
//
//               return Column(
//                 children: [
//                   _buildControlPanel(),
//                   const SizedBox(height: 16),
//                   Expanded(child: _buildImageDisplay()),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildControlPanel() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.06),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             '분석 컨트롤',
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             _busy ? '모델이 이미지를 분석 중입니다...' : '이미지를 선택하면 객체 탐지를 시작합니다.',
//             style: TextStyle(
//               color: Colors.white.withValues(alpha: 0.78),
//               height: 1.35,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: [
//               _buildStatusChip('Model', _session != null ? 'Ready' : 'Loading'),
//               _buildStatusChip('State', _busy ? 'Running' : 'Idle'),
//               _buildStatusChip('Detections', '${_detections.length}'),
//             ],
//           ),
//           const SizedBox(height: 20),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: _busy ? null : _runInference,
//               icon: _busy
//                   ? const SizedBox(
//                       width: 18,
//                       height: 18,
//                       child: CircularProgressIndicator(strokeWidth: 2),
//                     )
//                   : const Icon(Icons.upload_file_rounded),
//               label: Text(_busy ? 'Processing...' : '이미지 불러오기'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF00A8E8),
//                 foregroundColor: Colors.black,
//                 fixedSize: const Size(double.infinity, 52),
//                 textStyle: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _imageFile == null
//                 ? '선택된 이미지 없음'
//                 : '선택 파일: ${_imageFile!.path.split(Platform.pathSeparator).last}',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             '탐지 결과',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 10),
//           Expanded(
//             child: _detections.isEmpty
//                 ? Center(
//                     child: Text(
//                       '아직 결과가 없습니다.',
//                       style: TextStyle(
//                         color: Colors.white.withValues(alpha: 0.55),
//                       ),
//                     ),
//                   )
//                 : ListView.separated(
//                     itemCount: _detections.length > 8 ? 8 : _detections.length,
//                     separatorBuilder: (_, _) => const SizedBox(height: 8),
//                     itemBuilder: (context, index) {
//                       final d = _detections[index];
//                       final color = YoloPainter.colorForLabel(d.label);
//                       return Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 9,
//                         ),
//                         decoration: BoxDecoration(
//                           color: color.withValues(alpha: 0.15),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: color.withValues(alpha: 0.35),
//                           ),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 8,
//                               height: 8,
//                               decoration: BoxDecoration(
//                                 color: color,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 d.label,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                             Text('${(d.score * 100).toStringAsFixed(1)}%'),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusChip(String title, String value) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(999),
//       ),
//       child: Text(
//         '$title: $value',
//         style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
//       ),
//     );
//   }
//
//   Widget _buildImageDisplay() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.05),
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
//       ),
//       child: Center(
//         child: (_imageFile == null || _imgSize == null)
//             ? _buildPlaceholder()
//             : AspectRatio(
//                 aspectRatio: _imgSize!.width / _imgSize!.height,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(18),
//                   child: Stack(
//                     fit: StackFit.expand,
//                     children: [
//                       Image.file(_imageFile!, fit: BoxFit.contain),
//                       CustomPaint(
//                         size: Size.infinite,
//                         painter: YoloPainter(_detections, _imgSize!),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }
//
//   Widget _buildPlaceholder() {
//     return Container(
//       constraints: const BoxConstraints(maxWidth: 520, maxHeight: 300),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFF17212E), Color(0xFF121A23)],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
//       child: const Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.image_search_rounded, size: 56, color: Color(0xFF7ED8FF)),
//           SizedBox(height: 12),
//           Text(
//             '분석할 이미지를 선택해 주세요',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Text(
//             '추론이 완료되면 바운딩 박스와 신뢰도가 표시됩니다.',
//             textAlign: TextAlign.center,
//             style: TextStyle(color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class YoloPainter extends CustomPainter {
//   final List<Detection> detections;
//   final Size originalSize;
//
//   YoloPainter(this.detections, this.originalSize);
//
//   static Color colorForLabel(String label) {
//     if (label == 'egg') return const Color(0xFF4DFFB1);
//     if (label == 'crack') return const Color(0xFFFF8A65);
//     return const Color(0xFF80D8FF);
//   }
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final double scaleX = size.width / originalSize.width;
//     final double scaleY = size.height / originalSize.height;
//
//     for (var d in detections) {
//       final color = colorForLabel(d.label);
//       final paint = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2.5
//         ..color = color;
//       final rect = Rect.fromLTWH(
//         d.rect.left * scaleX,
//         d.rect.top * scaleY,
//         d.rect.width * scaleX,
//         d.rect.height * scaleY,
//       );
//       canvas.drawRect(rect, paint);
//
//       final tp = TextPainter(
//         text: TextSpan(
//           text: '${d.label} ${(d.score * 100).toStringAsFixed(1)}%',
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//             fontSize: 12,
//           ),
//         ),
//         textDirection: TextDirection.ltr,
//       )..layout();
//
//       final labelTop = (rect.top - tp.height - 6).clamp(
//         0.0,
//         size.height - tp.height - 4,
//       );
//       final labelLeft = rect.left.clamp(0.0, size.width - tp.width - 8);
//       final labelRect = RRect.fromRectAndRadius(
//         Rect.fromLTWH(labelLeft, labelTop, tp.width + 8, tp.height + 4),
//         const Radius.circular(6),
//       );
//
//       canvas.drawRRect(
//         labelRect,
//         Paint()..color = color.withValues(alpha: 0.9),
//       );
//       tp.paint(canvas, Offset(labelLeft + 4, labelTop + 2));
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return oldDelegate is! YoloPainter ||
//         oldDelegate.detections != detections ||
//         oldDelegate.originalSize != originalSize;
//   }
// }
