import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tts_pro_arch/features/tts_home/controller/tts_controller.dart';

class TtsHomeScreen extends StatefulWidget {
  const TtsHomeScreen({super.key});

  @override
  State<TtsHomeScreen> createState() => _TtsHomeScreenState();
}

class _TtsHomeScreenState extends State<TtsHomeScreen> {
  late final TextEditingController _textController;
  late final ScrollController _chunksScrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'Xin chào! Đây là ví dụ văn bản để bạn thử nghiệm Text-to-Speech trong ứng dụng TTS Pro.',
    );
    _chunksScrollController = ScrollController();
    
    // Lắng nghe thay đổi currentChunk để scroll đến chunk đang đọc
    final controller = context.read<TtsController>();
    controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final controller = context.read<TtsController>();
    if (controller.chunks.isNotEmpty && _chunksScrollController.hasClients) {
      final currentIndex = controller.currentChunk;
      // Scroll đến chunk đang đọc sau một frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _chunksScrollController.hasClients) {
          _scrollToChunk(currentIndex);
        }
      });
    }
  }

  void _scrollToChunk(int index) {
    if (!_chunksScrollController.hasClients) return;
    
    // Tính toán vị trí scroll dựa trên index
    // Giả sử mỗi chunk có chiều cao khoảng 100-150px
    final estimatedHeight = 120.0;
    final targetOffset = (index * estimatedHeight).clamp(
      0.0,
      _chunksScrollController.position.maxScrollExtent,
    );
    
    _chunksScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    final controller = context.read<TtsController>();
    controller.removeListener(_onControllerChanged);
    _textController.dispose();
    _chunksScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 768;
        final isDesktop = constraints.maxWidth >= 1200;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('TTS Pro'),
            centerTitle: true,
            elevation: 0,
          ),
          // Giữ resizeToAvoidBottomInset = true nhưng tối ưu bằng RepaintBoundary
          resizeToAvoidBottomInset: true,
          body: isDesktop
              ? _DesktopLayout(
                  textController: _textController,
                  chunksScrollController: _chunksScrollController,
                )
              : isTablet
                  ? _TabletLayout(
                      textController: _textController,
                      chunksScrollController: _chunksScrollController,
                    )
                  : _MobileLayout(
                      textController: _textController,
                      chunksScrollController: _chunksScrollController,
                    ),
        );
      },
    );
  }
}

// Mobile Layout - Single Column
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.textController,
    required this.chunksScrollController,
  });

  final TextEditingController textController;
  final ScrollController chunksScrollController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Scroll khi keyboard xuất hiện, tự động dismiss khi drag
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tách TextInputSection với RepaintBoundary để tránh rebuild các phần khác
          // RepaintBoundary giúp tách riêng repaint, giảm lag khi keyboard xuất hiện
          RepaintBoundary(
            child: _TextInputSection(controller: textController),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: _PlaybackControlsSection(),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: _ProgressSection(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300, // Chiều cao cố định cho chunks section trên mobile
            child: RepaintBoundary(
              child: _ChunksSection(scrollController: chunksScrollController),
            ),
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            child: _SettingsSection(),
          ),
        ],
      ),
    );
  }
}

// Tablet Layout - 2 Columns
class _TabletLayout extends StatelessWidget {
  const _TabletLayout({
    required this.textController,
    required this.chunksScrollController,
  });

  final TextEditingController textController;
  final ScrollController chunksScrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Input & Controls
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RepaintBoundary(
                        child: _TextInputSection(controller: textController),
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: _PlaybackControlsSection(),
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: _ProgressSection(),
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        child: _SettingsSection(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Right Column - Chunks
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: constraints.maxHeight > 0
                      ? constraints.maxHeight - 48
                      : MediaQuery.of(context).size.height - 120,
                  child: RepaintBoundary(
                    child: _ChunksSection(scrollController: chunksScrollController),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Desktop Layout - 3 Columns
class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.textController,
    required this.chunksScrollController,
  });

  final TextEditingController textController;
  final ScrollController chunksScrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column - Input & Settings
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RepaintBoundary(
                            child: _TextInputSection(controller: textController),
                          ),
                          const SizedBox(height: 24),
                          RepaintBoundary(
                            child: _SettingsSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Middle Column - Controls & Progress
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RepaintBoundary(
                            child: _PlaybackControlsSection(),
                          ),
                          const SizedBox(height: 24),
                          RepaintBoundary(
                            child: _ProgressSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Column - Chunks
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: constraints.maxHeight > 0
                          ? constraints.maxHeight - 64
                          : MediaQuery.of(context).size.height - 120,
                      child: RepaintBoundary(
                        child: _ChunksSection(scrollController: chunksScrollController),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Text Input Section
class _TextInputSection extends StatefulWidget {
  const _TextInputSection({required this.controller});

  final TextEditingController controller;

  @override
  State<_TextInputSection> createState() => _TextInputSectionState();
}

class _TextInputSectionState extends State<_TextInputSection> {
  // Focus node để quản lý keyboard
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Nhập nội dung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: 6,
              minLines: 4,
              // Tối ưu keyboard behavior
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                // Ẩn keyboard khi nhấn done
                _focusNode.unfocus();
              },
              decoration: InputDecoration(
                hintText: 'Nhập văn bản bạn muốn chuyển thành giọng nói...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  // Ẩn keyboard trước khi xử lý
                  _focusNode.unfocus();
                  _handleSpeak(context);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu đọc'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSpeak(BuildContext context) {
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung cần đọc')),
      );
      return;
    }
    final ttsController = context.read<TtsController>();
    ttsController.speak(text);
  }
}

// Playback Controls Section
class _PlaybackControlsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TtsController, ({
      TtsState state,
      bool hasChunks,
      int currentChunk,
      int totalChunks,
    })>(
      selector: (_, controller) => (
        state: controller.ttsState,
        hasChunks: controller.chunks.isNotEmpty,
        currentChunk: controller.currentChunk,
        totalChunks: controller.chunks.length,
      ),
      builder: (context, data, _) {
        final controller = context.read<TtsController>();
        final isPlaying = data.state == TtsState.playing;
        final isPaused = data.state == TtsState.paused;
        final canGoPrev = data.hasChunks && data.currentChunk > 0;
        final canGoNext = data.hasChunks && data.currentChunk < data.totalChunks - 1;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.control_camera, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Điều khiển phát',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: canGoPrev ? controller.jumpToPreviousChunk : null,
                      icon: const Icon(Icons.skip_previous_rounded),
                      tooltip: 'Đoạn trước',
                    ),
                    IconButton.filled(
                      onPressed: isPlaying ? controller.pause : null,
                      icon: const Icon(Icons.pause_rounded),
                      tooltip: 'Tạm dừng',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton.filled(
                      onPressed: isPaused ? controller.resume : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      tooltip: 'Tiếp tục',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: data.hasChunks ? controller.stop : null,
                      icon: const Icon(Icons.stop_rounded),
                      tooltip: 'Dừng',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: canGoNext ? controller.jumpToNextChunk : null,
                      icon: const Icon(Icons.skip_next_rounded),
                      tooltip: 'Đoạn tiếp',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Progress Section
class _ProgressSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TtsController, ({
      int currentChunk,
      int totalChunks,
      String? currentChunkText,
    })>(
      selector: (_, controller) => (
        currentChunk: controller.currentChunk,
        totalChunks: controller.chunks.length,
        currentChunkText: controller.chunks.isNotEmpty
            ? controller.chunks[controller.currentChunk]
            : null,
      ),
      builder: (context, data, _) {
        if (data.totalChunks == 0) {
          return const SizedBox.shrink();
        }

        final progress = (data.currentChunk + 1) / data.totalChunks;

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Tiến trình đọc',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text('${data.currentChunk + 1} / ${data.totalChunks}'),
                      avatar: const Icon(Icons.bookmark, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                if (data.currentChunkText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      data.currentChunkText!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// Chunks Section
class _ChunksSection extends StatelessWidget {
  const _ChunksSection({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Selector<TtsController, ({
          List<String> chunks,
          int currentChunk,
        })>(
          selector: (_, controller) => (
            chunks: controller.chunks,
            currentChunk: controller.currentChunk,
          ),
          builder: (context, data, _) {
            if (data.chunks.isEmpty) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.text_snippet_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có nội dung',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập văn bản và nhấn "Bắt đầu đọc" để xem các đoạn văn bản',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Tính chiều cao tối đa cho ListView
            final maxHeight = constraints.maxHeight > 0
                ? constraints.maxHeight - 80 // Trừ đi header và padding
                : 400.0; // Fallback height

            return Card(
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.list, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Các đoạn văn bản',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text('${data.chunks.length} đoạn'),
                          avatar: const Icon(Icons.numbers, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxHeight,
                      minHeight: 200,
                    ),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: data.chunks.length,
                      itemBuilder: (context, index) {
                        final isActive = index == data.currentChunk;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ChunkItem(
                            text: data.chunks[index],
                            index: index,
                            isActive: isActive,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Chunk Item
class _ChunkItem extends StatelessWidget {
  const _ChunkItem({
    required this.text,
    required this.index,
    required this.isActive,
  });

  final String text;
  final int index;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    height: 1.5,
                  ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.volume_up,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
}

// Settings Section
class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TtsController, ({
      List<Map<String, dynamic>> voices,
      Map<String, dynamic>? selectedVoice,
      double speechRate,
      double pitch,
    })>(
      selector: (_, controller) => (
        voices: controller.voices,
        selectedVoice: controller.selectedVoice,
        speechRate: controller.speechRate,
        pitch: controller.pitch,
      ),
      builder: (context, data, _) {
        final controller = context.read<TtsController>();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Thiết lập giọng đọc',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: data.selectedVoice != null &&
                          data.voices.contains(data.selectedVoice)
                      ? data.selectedVoice
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Giọng đọc',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  items: data.voices
                      .map(
                        (voice) => DropdownMenuItem(
                          value: voice,
                          child: Text(
                            '${voice['name']} (${voice['locale']})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: data.voices.isEmpty
                      ? null
                      : (voice) => controller.setVoice(voice),
                ),
                if (data.voices.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Không tìm thấy giọng đọc. Vui lòng kiểm tra lại cấu hình thiết bị.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
                const SizedBox(height: 24),
                _SliderRow(
                  label: 'Tốc độ đọc',
                  value: data.speechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 18,
                  icon: Icons.speed,
                  onChanged: controller.setSpeechRate,
                ),
                const SizedBox(height: 20),
                _SliderRow(
                  label: 'Độ cao giọng',
                  value: data.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  icon: Icons.tune,
                  onChanged: controller.setPitch,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Slider Row
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final IconData icon;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
