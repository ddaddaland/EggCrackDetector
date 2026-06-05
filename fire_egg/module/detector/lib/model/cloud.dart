import 'dart:convert';

import 'package:fire_egg_common/core/rect.dart';
import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_detector/config/image_size.dart';
import 'package:fire_egg_detector/model/inference_option.dart';
import 'package:fire_egg_detector/model/model.dart';
import 'package:http/http.dart' as http;

class CloudYoloModel extends AbstractYoloModel {
  final logger = Logger('ultralytics', 33);
  final String url, apiKey;

  CloudYoloModel({
    super.imageSize = DetectorImageSize.defaultSize,
    required super.name,
    required super.parentModel,
    required super.classes,
    required this.url,
    required this.apiKey,
  }) : super(
         description: 'Ultralytics Cloud YOLO Model',
       );

  @override
  bool get isCloud => true;

  @override
  bool get isLoaded => true;

  @override
  Future<bool> load() async {
    logger.info('cloud model does not require loading');
    return true;
  }

  @override
  Future<void> unLoad() async {
    logger.info('cloud model does not require unloading');
  }

  @override
  Future<List<Detection>> detect(List<int> imageBytes, InferenceOption option) async {
    logger.info('sending image to cloud model ...');
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'));
    request.fields['conf'] = option.confidenceThreshold.toString();
    // request.fields['iou'] = '0.7';
    // request.fields['imgsz'] = '640';

    final responseStreamed = await request.send();
    final response = await http.Response.fromStream(responseStreamed);
    logger.info('response status: ${response.statusCode}');
    if (response.statusCode != 200) {
      logger.warning('cloud model inference failed: ${response.body}');
      throw Exception('Cloud model inference failed with status code ${response.statusCode}');
    }

    final imageJson = jsonDecode(response.body)['images'][0];
    final resultsJson = imageJson['results'] as List;
    final detections = resultsJson.map((result) {
      final cls = result['class'] as int;
      final conf = (result['confidence'] as num).toDouble();
      final box = result['box'];

      // final h = imageJson['shape'][0] as double;
      // final w = imageJson['shape'][1] as double;

      /*

                "box": {
            "x1": 0.56049,
            "y1": 0.66939,
            "x2": 0.56082,
            "y2": 0.35386,
            "x3": 0.33329,
            "y3": 0.35363,
            "x4": 0.33297,
            "y4": 0.66916
          }

       */

      final Rect rect;
      final x1 = (box['x1'] as num).toDouble();
      final y1 = (box['y1'] as num).toDouble();
      final x2 = (box['x2'] as num).toDouble();
      final y2 = (box['y2'] as num).toDouble();
      final x3 = box['x3'] as double?;
      if (x3 == null) {
        final left = x1 < x2 ? x1 : x2;
        final right = x1 < x2 ? x2 : x1;
        final top = y1 < y2 ? y1 : y2;
        final bottom = y1 < y2 ? y2 : y1;
        rect = Rect.fromLTRB(left, top, right, bottom);
      } else {
        // convert obb to aabb
        final y3 = box['y3'] as double;
        final x4 = box['x4'] as double;
        final y4 = box['y4'] as double;

        final left = [x1, x2, x3, x4].reduce((a, b) => a < b ? a : b);
        final right = [x1, x2, x3, x4].reduce((a, b) => a > b ? a : b);
        final top = [y1, y2, y3, y4].reduce((a, b) => a < b ? a : b);
        final bottom = [y1, y2, y3, y4].reduce((a, b) => a > b ? a : b);
        rect = Rect.fromLTRB(left, top, right, bottom);
      }

      return Detection(
        classIndex: cls,
        confidence: conf,
        absoluteRect: rect,
      );
    }).toList();
    return detections;
  }
}
