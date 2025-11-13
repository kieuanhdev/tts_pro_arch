import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/tts_controller.dart';

class TtsHomeScreen extends StatefulWidget {
  const TtsHomeScreen({super.key});

  @override
  _TtsHomeScreenState createState() => _TtsHomeScreenState();
}

class _TtsHomeScreenState extends State<TtsHomeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ttsController = context.watch<TtsController>();
    final ttsRead = context.read<TtsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Pro - Ngày 3'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Nhập văn bản của bạn ở đây...',
                border: OutlineInputBorder(),
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  iconSize: 50,
                  color: Colors.green,
                  onPressed: (ttsController.ttsState == TtsState.stopped)
                      ? () => ttsRead.speak(_textController.text)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.stop_rounded),
                  iconSize: 50,
                  color: Colors.red,
                  onPressed: (ttsController.ttsState == TtsState.playing)
                      ? () => ttsRead.stop()
                      : null,
                ),
              ],
            ),

            const Divider(height: 32, thickness: 1),

            _buildSettings(ttsController, ttsRead),
          ],
        ),
      ),
    );
  }

  // UI phần cài đặt
  Widget _buildSettings(TtsController ttsController, TtsController ttsRead) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt Giọng nói',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Dropdown giọng nói
        (ttsController.voices.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<Map<String, dynamic>>(
          value: ttsController.selectedVoice,
          decoration: const InputDecoration(
            labelText: 'Giọng đọc',
            border: OutlineInputBorder(),
          ),
          items: ttsController.voices.map((voice) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: voice,
              child: Text(
                "${voice['name']} (${voice['locale']})",
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            ttsRead.setVoice(value);
          },
          isExpanded: true,
        ),

        const SizedBox(height: 20),

        // Speed slider
        Text('Tốc độ nói: ${ttsController.speechRate.toStringAsFixed(1)}'),
        Slider(
          value: ttsController.speechRate,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: ttsController.speechRate.toStringAsFixed(1),
          onChanged: (value) => ttsRead.setSpeechRate(value),
        ),

        // Pitch slider
        Text('Cao độ giọng: ${ttsController.pitch.toStringAsFixed(1)}'),
        Slider(
          value: ttsController.pitch,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          label: ttsController.pitch.toStringAsFixed(1),
          onChanged: (value) => ttsRead.setPitch(value),
        ),
      ],
    );
  }
}
