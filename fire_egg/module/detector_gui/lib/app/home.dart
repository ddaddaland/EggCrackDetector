import 'dart:async';
import 'dart:io';

import 'package:fire_egg_common/detection/object_class.dart';
import 'package:fire_egg_detector/config/image_size.dart';
import 'package:fire_egg_detector/core.dart';
import 'package:fire_egg_detector/camera/sample.dart';
import 'package:fire_egg_detector/detector/detector.dart';
import 'package:fire_egg_detector/detector/option/option.dart';
import 'package:fire_egg_detector/model/model.dart';
import 'package:fire_egg_detector/model/onnx.dart';
import 'package:fire_egg_detector_gui/detector/option_builder.dart';
import 'package:fire_egg_detector_gui/detector/widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FireEggDetectorGuiHome extends StatefulWidget {
  const FireEggDetectorGuiHome({super.key});

  @override
  State<FireEggDetectorGuiHome> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<FireEggDetectorGuiHome> {
  int selectedImageSize = DetectorImageSize.defaultSize;
  late List<AbstractYoloModel> selectableModels = _buildModels(selectedImageSize);

  late final option = DetectorInstanceOption()
    ..id = 'DET-000'
    ..appVersion = '${Platform.localHostname} (${Platform.operatingSystem}, ${Platform.operatingSystemVersion})'
    ..model = selectableModels.firstOrNull;

  late final optionSteamController = StreamController<void>.broadcast();
  late final optionStream = optionSteamController.stream;

  void onOptionChanged() {
    optionSteamController.add(null);
  }

  void onImageSizeChanged(int? value) {
    if (value == null || value == selectedImageSize || !DetectorImageSize.isSupported(value)) {
      return;
    }

    final selectedModelName = option.model?.name;
    setState(() {
      selectedImageSize = value;
      selectableModels = _buildModels(selectedImageSize);
      option.model = selectableModels.where((m) => m.name == selectedModelName).firstOrNull ?? selectableModels.firstOrNull;
      // Keep manually attached cameras as-is, but remove sample cameras tied to old fixed-size assets.
      option.cameras.removeWhere((camera) => camera is SampleCamera);
    });
    onOptionChanged();
  }

  void start() {
    option.ensureValid();
    DetectorCore.start(
      detectorInstance: DetectorInstance(
        id: option.id!,
        appVersion: option.appVersion!,
        model: option.model!,
        lift: option.lift!,
        serverOption: option.serverOption!,
        cameras: option.cameras,
      ),
      onError: (e) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: Text('오류'),
            content: Text('$e'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DetectorCore.stateStream,
      builder: (context, _) {
        if (!DetectorCore.busy && DetectorCore.started) {
          return DetectorWidget(
            detector: DetectorCore.detector,
          );
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Row(
              spacing: 5,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings),
                Text('검출기 시작 설정'),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10),
            child: Builder(
              builder: (context) {
                if (DetectorCore.busy) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return Column(
                  spacing: 5,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: DetectorInstanceOptionBuilder(
                          option: option,
                          imageSize: selectedImageSize,
                          models: selectableModels,
                          onChanged: onOptionChanged,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: selectedImageSize,
                      decoration: const InputDecoration(
                        labelText: '이미지 크기',
                        border: OutlineInputBorder(),
                      ),
                      items: DetectorImageSize.supported
                          .map(
                            (size) => DropdownMenuItem<int>(
                              value: size,
                              child: Text('${size}x$size'),
                            ),
                          )
                          .toList(),
                      onChanged: DetectorCore.busy ? null : onImageSizeChanged,
                    ),
                    StreamBuilder(
                      stream: optionStream,
                      builder: (context, _) {
                        String? error;

                        try {
                          option.ensureValid();
                        } on ArgumentError catch (e) {
                          error = e.message;
                        } catch (e) {
                          error = '알 수 없는 오류: $e';
                        }

                        return ElevatedButton(
                          onPressed: error != null ? null : start,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${error ?? '시작'}',
                                  style: TextStyle(
                                    color: error != null ? Colors.red : null,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  //

  static List<AbstractYoloModel> _buildModels(int imageSize) => [
    ...localModels(imageSize),
    ...DetectorCore.cloudModels(imageSize: imageSize),
  ];

  static List<OnnxYoloModel> localModels(int imageSize) => [

    // 1100
    OnnxYoloModel(
      imageSize: imageSize,
      name: 'EGG Single 1102',
      parentModel: 'YOLO v26m ',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/1102.onnx').then((bd) => bd.buffer.asUint8List()),
    ),

    OnnxYoloModel(
      imageSize: imageSize,
      name: 'EGG Single 1101',
      parentModel: 'YOLO v26m ',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/1101.onnx').then((bd) => bd.buffer.asUint8List()),
    ),


    OnnxYoloModel(
      imageSize: imageSize,
      name: 'EGG Single 1100 (OPSET 11, FP32)',
      parentModel: 'YOLO v8 s',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/1100.onnx').then((bd) => bd.buffer.asUint8List()),
    ),


    // v1006
    OnnxYoloModel(
      name: 'EGG Single v1006 (FF)',
      parentModel: 'YOLO v26 m',
      classes: [
        YoloObjectClass(label: 'white_egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'yellow_egg', color: 0xFFEBCB6B),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1006_ff.onnx').then((bd) => bd.buffer.asUint8List()),
    ),
    OnnxYoloModel(
      name: 'EGG Single v1006 1',
      parentModel: 'YOLO v26 m',
      classes: [
        YoloObjectClass(label: 'white_egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'yellow_egg', color: 0xFFEBCB6B),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1006_1.onnx').then((bd) => bd.buffer.asUint8List()),
    ),
    OnnxYoloModel(
      name: 'EGG Single v1006 (FT)',
      parentModel: 'YOLO v26 m',
      classes: [
        YoloObjectClass(label: 'white_egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'yellow_egg', color: 0xFFEBCB6B),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1006_ft.onnx').then((bd) => bd.buffer.asUint8List()),
    ),
    OnnxYoloModel(
      name: 'EGG Single v1006 (TF)',
      parentModel: 'YOLO v26 m',
      classes: [
        YoloObjectClass(label: 'white_egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'yellow_egg', color: 0xFFEBCB6B),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1006_tf.onnx').then((bd) => bd.buffer.asUint8List()),
    ),

    // v1004
    OnnxYoloModel(
      imageSize: imageSize,
      name: 'EGG Single v1004 (OPSET 11, FP32)',
      parentModel: 'YOLO v8 s',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1004_o11_fp32.onnx').then((bd) => bd.buffer.asUint8List()),
    ),

    // v1003
    OnnxYoloModel(
      imageSize: imageSize,
      name: 'EGG Single v1003 (OPSET 11, FP32)',
      parentModel: 'YOLO v26 m',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1003_o11_fp32.onnx').then((bd) => bd.buffer.asUint8List()),
    ),
    OnnxYoloModel(
      imageSize: imageSize,
      name: 'EGG Single v1003 (OPSET 11, FP16)',
      parentModel: 'YOLO v26 m',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1003_o11_fp16.onnx').then((bd) => bd.buffer.asUint8List()),
    ),
    OnnxYoloModel(
      imageSize: imageSize,
      name: 'EGG Single v1003 (FP16)',
      parentModel: 'YOLO v26 m',
      classes: [
        YoloObjectClass(label: 'egg', color: 0xFFFFFFFF),
        YoloObjectClass(label: 'crack', color: 0xFFFF5252),
      ],
      description: 'local onnx model',
      modelLoader: () => rootBundle.load('asset/model/v1003.onnx').then((bd) => bd.buffer.asUint8List()),
    ),
  ];
}
