import 'package:fire_egg_detector/model/model.dart';
import 'package:fire_egg_detector_gui/model/widget/inspector.dart';
import 'package:flutter/material.dart';

class ModelsScreen extends StatefulWidget {
  final List<AbstractYoloModel> models;

  const ModelsScreen({
    super.key,
    required this.models,
  });

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  void showModelInspector(AbstractYoloModel model) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              spacing: 10,
              children: [
                Icon(Icons.memory),
                Row(
                  spacing: 5,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(model.name),
                    Text(
                      model.description,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8),
            child: ModelInspector(model: model),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.models.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final model = widget.models[index];
        return ListTile(
          leading: Icon(Icons.memory),
          title: Text(model.name),
          subtitle: Text(model.description),
          onTap: () => showModelInspector(model),
        );
      },
    );
  }
}
