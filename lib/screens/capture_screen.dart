import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/scan_repository.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

/// Guides the user to capture one or more photos of a rock from different
/// angles, then hands them to the AI service for analysis.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _picker = ImagePicker();
  final List<String> _paths = [];

  /// Angle prompts to nudge better coverage of the sample.
  static const _angles = [
    ('Whole sample', Icons.photo_camera, 'Fill the frame with the rock.'),
    ('Close-up', Icons.zoom_in, 'Zoom into any veins, crystals or staining.'),
    ('Fresh break', Icons.change_history,
        'Break the rock and shoot the fresh, unweathered surface.'),
  ];

  Future<void> _capture(ImageSource source) async {
    try {
      final XFile? shot = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (shot != null) {
        setState(() => _paths.add(shot.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera: $e')),
        );
      }
    }
  }

  Future<void> _analyze() async {
    final repo = context.read<ScanRepository>();
    final result = await repo.analyzePhotos(List.of(_paths));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultsScreen(scan: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyzing = context.watch<ScanRepository>().analyzing;

    return Scaffold(
      appBar: AppBar(title: const Text('Capture sample')),
      body: analyzing
          ? _AnalyzingView()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Photograph the rock',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text(
                        'More angles = a better read. Aim for these shots:',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      ..._angles.asMap().entries.map((e) {
                        final done = _paths.length > e.key;
                        final (title, icon, hint) = e.value;
                        return Card(
                          child: ListTile(
                            leading: Icon(icon,
                                color: done
                                    ? AppColors.success
                                    : AppColors.slateLight),
                            title: Text(title),
                            subtitle: Text(hint),
                            trailing: done
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.success)
                                : null,
                          ),
                        );
                      }),
                      if (_paths.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Captured photos',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        _Thumbs(
                          paths: _paths,
                          onRemove: (i) =>
                              setState(() => _paths.removeAt(i)),
                        ),
                      ],
                    ],
                  ),
                ),
                _CaptureBar(
                  count: _paths.length,
                  onCamera: () => _capture(ImageSource.camera),
                  onGallery: () => _capture(ImageSource.gallery),
                  onAnalyze: _paths.isEmpty ? null : _analyze,
                ),
              ],
            ),
    );
  }
}

class _Thumbs extends StatelessWidget {
  final List<String> paths;
  final void Function(int) onRemove;
  const _Thumbs({required this.paths, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(paths[i]),
                    width: 92, height: 92, fit: BoxFit.cover),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: const CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CaptureBar extends StatelessWidget {
  final int count;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onAnalyze;

  const _CaptureBar({
    required this.count,
    required this.onCamera,
    required this.onGallery,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: 'Pick from gallery',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.camera_alt),
                label: Text(count == 0 ? 'Take photo' : 'Add angle'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAnalyze,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Analyze'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text('Analysing sample…',
              style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Identifying rock type and mineral potential',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
