import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api_client.dart';
import '../../../../core/token_storage.dart';
import '../../data/event_template.dart';
import '../../data/media_picker_service.dart';

class EventInfoFormScreen extends StatefulWidget {
  final PickedMediaResult? selectedMedia;

  const EventInfoFormScreen({
    super.key,
    this.selectedMedia,
  });

  @override
  State<EventInfoFormScreen> createState() => _EventInfoFormScreenState();
}

class _EventInfoFormScreenState extends State<EventInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const List<String> _categories = [
    'Hackathon',
    'Technical Workshop',
    'Fun Run',
    'Talk / Seminar',
    'Cultural Exhibition',
    'Sports Competition',
  ];

  EventTemplate? _selectedTemplate;
  String _selectedCategory = _categories.first;
  DateTime _startTime = DateTime.now().add(const Duration(days: 7, hours: 9));
  DateTime _endTime = DateTime.now().add(const Duration(days: 7, hours: 17));
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _applyTemplate(kEventTemplates.first, overwriteText: false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyTemplate(EventTemplate template, {bool overwriteText = true}) {
    setState(() {
      _selectedTemplate = template;
      if (_categories.contains(template.defaultCategory)) {
        _selectedCategory = template.defaultCategory;
      }
      if (overwriteText || _nameController.text.trim().isEmpty) {
        _nameController.text = template.sampleTitle;
      }
      if (overwriteText || _venueController.text.trim().isEmpty) {
        _venueController.text = template.sampleVenue;
      }
      if (overwriteText || _descriptionController.text.trim().isEmpty) {
        _descriptionController.text = template.sampleDescription;
      }
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = combined;
        if (!_endTime.isAfter(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 2));
        }
      } else {
        _endTime = combined;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} • $hour:$min';
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await TokenStorage.read();
      final authHeader =
          token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null;

      // 1. If teammate's /events/upload & /events endpoints exist, upload & create post
      String mediaUrl = 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d';
      String mediaType = widget.selectedMedia?.type.name ?? 'image';

      if (widget.selectedMedia != null) {
        final bytes = await widget.selectedMedia!.file.readAsBytes();
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: widget.selectedMedia!.file.name,
          ),
        });
        final uploadRes = await dio.post(
          '/events/upload',
          data: formData,
          options: authHeader,
        );
        mediaUrl = uploadRes.data['mediaUrl'] ?? mediaUrl;
        mediaType = uploadRes.data['mediaType'] ?? mediaType;
      }

      await dio.post(
        '/events',
        data: {
          'title': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _venueController.text.trim(),
          'templateId': _selectedTemplate?.id,
          'category': _selectedCategory,
          'mediaUrl': mediaUrl,
          'mediaType': mediaType,
          'startTime': _startTime.toUtc().toIso8601String(),
          'endTime': _endTime.toUtc().toIso8601String(),
        },
        options: authHeader,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event published successfully!')),
      );
      context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      // Graceful preview fallback if teammate's /events backend endpoints aren't merged yet
      if (e.response?.statusCode == 404) {
        _showFormSummaryDialog();
      } else {
        final msg = e.response == null
            ? 'Cannot reach the server. Check your connection.'
            : 'Failed to publish event (${e.response?.statusCode}).';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showFormSummaryDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Event Details Ready'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Template: ${_selectedTemplate?.label ?? 'Custom'}'),
              const SizedBox(height: 6),
              Text('Name: ${_nameController.text.trim()}'),
              const SizedBox(height: 6),
              Text('Category: $_selectedCategory'),
              const SizedBox(height: 6),
              Text('Venue: ${_venueController.text.trim()}'),
              const SizedBox(height: 6),
              Text('Start: ${_formatDateTime(_startTime)}'),
              Text('End: ${_formatDateTime(_endTime)}'),
              const SizedBox(height: 6),
              Text('Description: ${_descriptionController.text.trim()}'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/home');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Selected Media Banner Preview (if passed from PickMediaScreen)
              if (widget.selectedMedia != null) ...[
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: colorScheme.surfaceContainerHighest,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.selectedMedia!.type == PickedMediaType.image)
                        kIsWeb
                            ? Image.network(
                                widget.selectedMedia!.file.path,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(widget.selectedMedia!.file.path),
                                fit: BoxFit.cover,
                              )
                      else
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(widget.selectedMedia!.file.name),
                            ],
                          ),
                        ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Chip(
                          label: Text(
                            _selectedTemplate?.label ?? 'Template',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 1. Pre-Curated Templates
              Text(
                'Choose a Template',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a template to pre-fill structure and category.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kEventTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final tpl = kEventTemplates[index];
                    final isSelected = _selectedTemplate?.id == tpl.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _applyTemplate(tpl, overwriteText: true),
                      child: Container(
                        width: 130,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isSelected
                              ? tpl.accentColor.withValues(alpha: 0.14)
                              : colorScheme.surfaceContainerLow,
                          border: Border.all(
                            color: isSelected
                                ? tpl.accentColor
                                : colorScheme.outlineVariant,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(tpl.icon, color: tpl.accentColor, size: 26),
                            const SizedBox(height: 8),
                            Text(
                              tpl.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected ? tpl.accentColor : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 2. Event Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  hintText: 'e.g., UTM AI Hackathon 2026',
                  prefixIcon: Icon(Icons.event_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter an event name'
                    : null,
              ),
              const SizedBox(height: 16),

              // 3. Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // 4. Venue
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  hintText: 'e.g., Dewan Sultan Mizan, UTM JB',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter the event venue'
                    : null,
              ),
              const SizedBox(height: 16),

              // 5. Start & End Time Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isStart: true),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time', style: TextStyle(fontSize: 11)),
                          Text(
                            _formatDateTime(_startTime),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(isStart: false),
                      icon: const Icon(Icons.event_available, size: 18),
                      label: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time', style: TextStyle(fontSize: 11)),
                          Text(
                            _formatDateTime(_endTime),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the programme, prizes, or merit points...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter an event description'
                    : null,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Publish Event',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}