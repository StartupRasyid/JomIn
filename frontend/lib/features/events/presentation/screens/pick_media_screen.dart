import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../data/media_picker_service.dart';

class PickMediaScreen extends StatefulWidget {
  const PickMediaScreen({super.key});

  @override
  State<PickMediaScreen> createState() => _PickMediaScreenState();
}

class _PickMediaScreenState extends State<PickMediaScreen> {
  final MediaPickerService _mediaService = MediaPickerService();
  PickedMediaResult? _selectedMedia;
  bool _isPicking = false;

  Future<void> _handlePick(PickedMediaType type) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final result = type == PickedMediaType.image
          ? await _mediaService.pickImageFromGallery()
          : await _mediaService.pickVideoFromGallery();

      if (!mounted) return;
      if (result != null) {
        setState(() => _selectedMedia = result);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open gallery: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _clearSelection() {
    setState(() => _selectedMedia = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create Event Post',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select an event poster or promo video from your gallery.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),

          // Preview Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedMedia == null
                  ? _buildEmptyPlaceholder(colorScheme)
                  : _buildMediaPreview(_selectedMedia!, colorScheme),
            ),
          ),
          const SizedBox(height: 20),

          // Gallery Picker Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPicking
                      ? null
                      : () => _handlePick(PickedMediaType.image),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Pick Poster'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isPicking
                      ? null
                      : () => _handlePick(PickedMediaType.video),
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Pick Video'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Next Step Button (hands off to SS-84 Event Form)
          FilledButton.icon(
            onPressed: _selectedMedia == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected: ${_selectedMedia!.file.name} (${_selectedMedia!.type.name})',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue to Event Details'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 56,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No media selected yet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Supports JPG, PNG posters or MP4 videos',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(
      PickedMediaResult media, ColorScheme colorScheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (media.type == PickedMediaType.image)
          kIsWeb
              ? Image.network(media.file.path, fit: BoxFit.contain)
              : Image.file(File(media.file.path), fit: BoxFit.contain)
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.video_file_outlined,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    media.file.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Video ready for upload',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton.filledTonal(
            onPressed: _clearSelection,
            icon: const Icon(Icons.close),
            tooltip: 'Remove selected media',
          ),
        ),
      ],
    );
  }
}