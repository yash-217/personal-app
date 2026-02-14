import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/run_log.dart';
import 'package:uuid/uuid.dart';

class StravaOcrService {
  static const _uuid = Uuid();

  /// Process a Strava screenshot and extract run data
  Future<RunLog?> processStravaScreenshot(File imageFile) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _parseStravaText(recognizedText.text);
    } catch (e) {
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  /// Parse extracted text from Strava screenshot
  RunLog? _parseStravaText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();

    double? distance;
    int? durationSeconds;
    double? elevation;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      // Parse distance (e.g., "5.02" followed by "km" or "5.02 km")
      if (distance == null) {
        final distanceMatch = RegExp(
          r'(\d+[.,]\d+)\s*km',
          caseSensitive: false,
        ).firstMatch(line);
        if (distanceMatch != null) {
          distance = double.tryParse(
            distanceMatch.group(1)!.replaceAll(',', '.'),
          );
        } else {
          // Try standalone number near "km" or "distance"
          final numMatch = RegExp(r'^(\d+[.,]\d+)$').firstMatch(line);
          if (numMatch != null && i + 1 < lines.length) {
            final nextLine = lines[i + 1].toLowerCase();
            if (nextLine.contains('km') || nextLine.contains('distance')) {
              distance = double.tryParse(
                numMatch.group(1)!.replaceAll(',', '.'),
              );
            }
          }
        }
      }

      // Parse duration (e.g., "28:34" or "1:02:15")
      if (durationSeconds == null) {
        final durationMatch = RegExp(
          r'(\d{1,2}):(\d{2}):(\d{2})',
        ).firstMatch(line);
        if (durationMatch != null) {
          durationSeconds =
              int.parse(durationMatch.group(1)!) * 3600 +
              int.parse(durationMatch.group(2)!) * 60 +
              int.parse(durationMatch.group(3)!);
        } else {
          final shortDuration = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(line);
          if (shortDuration != null &&
              !lowerLine.contains('pace') &&
              !lowerLine.contains('/km')) {
            // Check if it's a time context
            if (lowerLine.contains('time') ||
                lowerLine.contains('duration') ||
                lowerLine.contains('elapsed') ||
                (i > 0 && lines[i - 1].toLowerCase().contains('time'))) {
              durationSeconds =
                  int.parse(shortDuration.group(1)!) * 60 +
                  int.parse(shortDuration.group(2)!);
            }
          }
        }
      }

      // Parse elevation (e.g., "125 m" near elevation context)
      if (elevation == null &&
          (lowerLine.contains('elev') || lowerLine.contains('gain'))) {
        final elevMatch = RegExp(r'(\d+)\s*m').firstMatch(line);
        if (elevMatch != null) {
          elevation = double.tryParse(elevMatch.group(1)!);
        }
      }
    }

    // Need at least distance to create a log
    if (distance == null) return null;

    return RunLog(
      id: _uuid.v4(),
      date: DateTime.now(),
      distanceKm: distance,
      durationSeconds: durationSeconds ?? 0,
      elevationGain: elevation,
      source: 'strava',
    );
  }
}
