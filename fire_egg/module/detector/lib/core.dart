import 'dart:async';

import 'package:fire_egg_detector/config/image_size.dart';
import 'package:fire_egg_common/detection/object_class.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_detector/detector/detector.dart';
import 'package:fire_egg_detector/model/cloud.dart';

class DetectorCore {
  const DetectorCore._();

  //
  static final logger = Logger('core', 25);
  static final _stateStreamController = StreamController<void>.broadcast();
  static late final stateStream = _stateStreamController.stream;

  // state
  static late final DetectorInstance detector;
  static bool _started = false, _busy = false;

  // static String? _error;

  // state getters
  static bool get started => _started;

  static bool get busy => _busy;

  // init
  static Future<void> start({
    required DetectorInstance detectorInstance,
    required void Function(String) onError,
  }) async {
    if (_busy) {
      return;
    }

    // mark
    _busy = true;
    _stateStreamController.add(null);

    // set
    await Future.delayed(Duration(seconds: 2));
    detector = detectorInstance;

    // unmark
    _started = true;
    _busy = false;
    _stateStreamController.add(null);
  }

  // models
  static final _ultralytics_api_key = 'ul_9d6de775f04c880518782876dcb6bf6f0c10e25c';
  static List<CloudYoloModel> cloudModels({
    int imageSize = DetectorImageSize.defaultSize,
  }) => [
    // common
    CloudYoloModel(
      imageSize: imageSize,
      name: 'EGG v1000 (best)',
      parentModel: 'YOLO v8 M',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFF69F0AE),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      url: 'https://predict-69ddbdc0d6cc04557d82-dproatj77a-du.a.run.app',
      apiKey: _ultralytics_api_key,
    ),
    CloudYoloModel(
      imageSize: imageSize,
      name: 'EGG v1003',
      parentModel: 'YOLO v26 L',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFF69F0AE),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      url: 'https://predict-69df730516fffa8ff269-dproatj77a-du.a.run.app',
      apiKey: _ultralytics_api_key,
    ),
  ];
}
