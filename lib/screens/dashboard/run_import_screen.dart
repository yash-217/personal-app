import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../models/run_log.dart';
import '../../providers/workout_provider.dart';
import '../../services/strava_ocr_service.dart';

class RunImportScreen extends StatefulWidget {
  final File? sharedImage;

  const RunImportScreen({super.key, this.sharedImage});

  @override
  State<RunImportScreen> createState() => _RunImportScreenState();
}

class _RunImportScreenState extends State<RunImportScreen> {
  final _distanceController = TextEditingController();
  final _durationMinController = TextEditingController();
  final _durationSecController = TextEditingController();
  final _elevationController = TextEditingController();
  final _notesController = TextEditingController();
  final _ocrService = StravaOcrService();

  File? _selectedImage;
  bool _isProcessing = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.sharedImage != null) {
      _selectedImage = widget.sharedImage;
      _processImage(widget.sharedImage!);
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _durationMinController.dispose();
    _durationSecController.dispose();
    _elevationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      await _processImage(File(picked.path));
    }
  }

  Future<void> _processImage(File file) async {
    setState(() => _isProcessing = true);
    final result = await _ocrService.processStravaScreenshot(file);
    if (result != null && mounted) {
      setState(() {
        _distanceController.text = result.distanceKm.toStringAsFixed(2);
        final totalMin = result.durationSeconds ~/ 60;
        final secs = result.durationSeconds % 60;
        _durationMinController.text = '$totalMin';
        _durationSecController.text = secs.toString().padLeft(2, '0');
        if (result.elevationGain != null) {
          _elevationController.text = result.elevationGain!.toStringAsFixed(0);
        }
      });
    }
    setState(() => _isProcessing = false);
  }

  Future<void> _saveRun() async {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final minutes = int.tryParse(_durationMinController.text) ?? 0;
    final seconds = int.tryParse(_durationSecController.text) ?? 0;
    final elevation = double.tryParse(_elevationController.text);

    if (distance <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a distance')));
      return;
    }

    final runLog = RunLog(
      id: const Uuid().v4(),
      date: _selectedDate,
      distanceKm: distance,
      durationSeconds: minutes * 60 + seconds,
      elevationGain: elevation,
      source: _selectedImage != null ? 'strava' : 'manual',
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    await context.read<WorkoutProvider>().addRunLog(runLog);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a Run'),
        actions: [
          TextButton.icon(
            onPressed: _saveRun,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Import from screenshot
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Import from screenshot'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            if (_isProcessing) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Text(
                'Processing screenshot...',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),
            Text('Run Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),

            const SizedBox(height: 16),

            // Distance
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Distance (km)',
                prefixIcon: Icon(Icons.straighten),
              ),
            ),

            const SizedBox(height: 16),

            // Duration
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      prefixIcon: Icon(Icons.timer),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durationSecController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Seconds'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Elevation
            TextField(
              controller: _elevationController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Elevation Gain (m) — optional',
                prefixIcon: Icon(Icons.terrain),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes — optional',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
