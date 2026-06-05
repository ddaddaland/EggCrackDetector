import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_widgets/label/label.dart';
import 'package:fire_egg_detector/model/inference_option.dart';
import 'package:fire_egg_detector/model/model.dart';
import 'package:fire_egg_detector/processor/processor.dart';
import 'package:fire_egg_detector_gui/processor/widget/window.dart';
import 'package:flutter/material.dart';

class InferenceScreen extends StatefulWidget {
  final List<AbstractYoloModel> models;

  const InferenceScreen({
    super.key,
    required this.models,
  });

  @override
  State<InferenceScreen> createState() => _InferenceScreenState();
}

class _InferenceScreenState extends State<InferenceScreen> {
  late final models = widget.models;

  late AbstractYoloModel selectedModel = models.first;
  final List<File> selectedImages = [];

  void pickImages() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: '이미지 선택 (복수)',
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result == null) return;

    setState(() {
      selectedImages.addAll(result.paths.map((path) => File(path!)));
    });
  }

  void runInference() async {
    final processor = InferenceProcessor(
      model: selectedModel,
      imageFiles: selectedImages,
      option: InferenceOption(),
    );
    await Navigator.push(context, MaterialPageRoute(builder: (context) => InferenceProcessorWindow(processor)));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // run
        Opacity(
          opacity: selectedImages.isEmpty ? 0.5 : 1,
          child: LightBox(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Icon(Icons.play_arrow),
                  Text('추론 ( ${selectedModel.name} / ${selectedImages.length} 이미지) '),
                ],
              ),
            ),
            onTap: selectedImages.isEmpty ? null : runInference,
          ),
        ),

        // models
        Expanded(
          child: LightBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Label(Icons.memory, '모델 선택 (${models.length})'),
                Expanded(
                  child: ListView.separated(
                    itemCount: models.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final model = models[index];
                      final selected = model == selectedModel;
                      return LightBox(
                        onTap: () {
                          setState(() {
                            selectedModel = model;
                          });
                        },
                        child: Column(
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                Icon(Icons.memory),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      spacing: 5,
                                      children: [
                                        Text(
                                          model.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (selected)
                                          Icon(
                                            Icons.check,
                                            color: Colors.amberAccent,
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '${model.parentModel}, ${model.description}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Divider(height: 15),
                            Row(
                              spacing: 10,
                              children: [
                                ...model.classes.indexed.map((pair) {
                                  final index = pair.$1;
                                  final cls = pair.$2;
                                  return LightBox(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      spacing: 10,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text('$index'),
                                        Text('${cls.label}'),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // images
        Expanded(
          child: LightBox(
            child: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Label(Icons.image, '추론'),
                Expanded(
                  child: LightBox(
                    child: Builder(
                      builder: (context) {
                        if (selectedImages.isEmpty) {
                          return Center(
                            child: Text('이미지를 선택해주세요'),
                          );
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 5,
                            childAspectRatio: 1,
                          ),
                          itemCount: selectedImages.length,
                          itemBuilder: (context, index) {
                            final image = selectedImages[index];
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(image, fit: BoxFit.cover),
                                Positioned(
                                  right: 5,
                                  bottom: 5,
                                  child: Container(
                                    color: Colors.black54,
                                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    child: Text('${(image.lengthSync() / (1024 * 1024)).toStringAsFixed(2)}MB'),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: Row(
                    spacing: 5,
                    children: [
                      LightBox(
                        width: 150,
                        child: Center(child: Text('초기화')),
                        onTap: selectedImages.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  selectedImages.clear();
                                });
                              },
                      ),
                      Expanded(
                        child: LightBox(
                          child: Center(child: Text('이미지 선택')),
                          onTap: pickImages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
