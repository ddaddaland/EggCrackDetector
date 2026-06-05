import 'package:fire_egg_detector/processor/processor.dart';
import 'package:fire_egg_detector_gui/processor/widget/window.dart';
import 'package:flutter/material.dart';

class InferenceHistoryScreen extends StatefulWidget {
  const InferenceHistoryScreen({super.key});

  @override
  State<InferenceHistoryScreen> createState() => _InferenceHistoryScreenState();
}

class _InferenceHistoryScreenState extends State<InferenceHistoryScreen> {
  late final instances = InferenceProcessor.instances;

  @override
  Widget build(BuildContext context) {
    if (instances.isEmpty) {
      return Center(
        child: Text('추론 기록이 없습니다.'),
      );
    }

    return ListView.separated(
      itemCount: instances.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final proc = instances[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InferenceProcessorWindow(proc),
              ),
            );
          },
          title: Text('추론 #${proc.id.toString().padLeft(3, '0')} / ${proc.model.name} / ${proc.imageFilesCount} 이미지'),
          subtitle: StreamBuilder(
            stream: proc.stateStream,
            builder: (context, asyncSnapshot) {
              if (!proc.processing) {
                return Text('idle');
              }
              return Text('추론 중 (${proc.currentImageIndex}/${proc.imageFilesCount})');
            },
          ),
        );
      },
    );
  }
}
