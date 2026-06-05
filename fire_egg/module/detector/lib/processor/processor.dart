import 'dart:async';
import 'dart:io';

import 'package:fire_egg_common/detection/detection.dart';
import 'package:fire_egg_detector/model/inference_option.dart';
import 'package:fire_egg_detector/model/model.dart';

class InferenceProcessor {
  static int _counter = 0;
  static final List<InferenceProcessor> instances = [];

  final int id = _counter++;
  final List<File> imageFiles;
  late final imageFilesCount = imageFiles.length;
  final AbstractYoloModel model;
  final InferenceOption option;

  final _stateStreamController = StreamController<int?>.broadcast();
  late final stateStream = _stateStreamController.stream;

  bool _processing = false;
  bool get processing => _processing;
  int? currentImageIndex;
  final Map<int, List<Detection>?> results = {};

  InferenceProcessor({
    required this.model,
    required this.imageFiles,
    required this.option,
  }) {
    instances.add(this);
  }

  void start() async {
    if (_processing) return;

    // mark
    _processing = true;
    results.clear();
    _stateStreamController.add(null);

    for (int i = 0; i < imageFilesCount; i++) {
      // mark
      currentImageIndex = i;
      _stateStreamController.add(null);

      // process
      final imageFile = imageFiles[i];
      final imageBytes = await imageFile.readAsBytes();
      final detections = await model.detect(imageBytes, option);

      // save
      results[i] = detections;
      currentImageIndex = null;
      _stateStreamController.add(i);
    }

    // mark
    _processing = false;
    _stateStreamController.add(null);
  }
}
