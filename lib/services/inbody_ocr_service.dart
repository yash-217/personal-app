import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Extracted body metrics from an InBody result sheet (tested on InBody 270)
class InBodyResult {
  final double? weight;
  final double? bodyFatPercentage;
  final double? bmi;
  final double? bodyFatMass;
  final double? totalBodyWater;
  final double? protein;
  final double? minerals;
  final double? visceralFatLevel;
  final double? basalMetabolicRate;
  final double? waistHipRatio;
  final double? recommendedCalorieIntake;
  final DateTime? testDate;

  InBodyResult({
    this.weight,
    this.bodyFatPercentage,
    this.bmi,
    this.bodyFatMass,
    this.totalBodyWater,
    this.protein,
    this.minerals,
    this.visceralFatLevel,
    this.basalMetabolicRate,
    this.waistHipRatio,
    this.recommendedCalorieIntake,
    this.testDate,
  });

  bool get hasAnyData =>
      weight != null || bodyFatPercentage != null || bmi != null;

  @override
  String toString() =>
      'InBodyResult(date: $testDate, weight: $weight, bf%: $bodyFatPercentage, '
      'bmi: $bmi, bfMass: $bodyFatMass, tbw: $totalBodyWater, '
      'protein: $protein, minerals: $minerals, visceral: $visceralFatLevel, '
      'bmr: $basalMetabolicRate, whr: $waistHipRatio, kcal: $recommendedCalorieIntake)';
}

class InBodyOcrService {
  Future<InBodyResult?> processImage(File imageFile) async {
    final textRecognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await textRecognizer.processImage(inputImage);

      debugPrint('=== InBody OCR Raw Text ===');
      debugPrint(recognizedText.text);
      debugPrint('=== End OCR Text ===');

      final result = _parse(recognizedText.text);
      debugPrint('=== Parsed: $result ===');

      if (!result.hasAnyData) {
        debugPrint('InBody OCR: No data extracted');
        return null;
      }
      return result;
    } catch (e, stack) {
      debugPrint('InBody OCR error: $e\n$stack');
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  InBodyResult _parse(String fullText) {
    final lines = fullText.split('\n').map((l) => l.trim()).toList();

    // ─── 1. TEST DATE ───────────────────────────────────
    // "11.12.2025. 07:58"
    final testDate = _extractDate(lines);

    // ─── 2. BODY COMPOSITION TABLE (values with ranges) ─
    // ML Kit outputs these as separate lines:
    //   "38.6 ( 40.0~49.0"   → TBW
    //   "10.5 ( 10.7~13.1 )" → Protein
    //   "3.84 ( 3.71~4.53 )" → Minerals
    //   "25.8 ( 8.6~17.1"    → Body Fat Mass
    //   "78.7 ( 60.6~82.0"   → Weight
    // They always appear in this fixed order on InBody sheets.
    final rangePattern = RegExp(r'^(\d+\.?\d*)\s*\(\s*\d+\.?\d*[~\-]');
    final rangeValues = <double>[];
    for (final line in lines) {
      final m = rangePattern.firstMatch(line);
      if (m != null) {
        final v = double.tryParse(m.group(1)!);
        if (v != null) {
          rangeValues.add(v);
          debugPrint('  Range value: $v from "$line"');
        }
      }
    }

    double? tableTbw;
    double? tableProtein;
    double? tableMinerals;
    double? tableBfm;
    double? tableWeight;

    // Assign positionally:  TBW, Protein, Minerals, BFM, Weight
    if (rangeValues.length >= 5) {
      tableTbw = rangeValues[0];
      tableProtein = rangeValues[1];
      tableMinerals = rangeValues[2];
      tableBfm = rangeValues[3];
      tableWeight = rangeValues[4];
      debugPrint(
        '  Table: TBW=$tableTbw Protein=$tableProtein '
        'Minerals=$tableMinerals BFM=$tableBfm Weight=$tableWeight',
      );
    } else if (rangeValues.isNotEmpty) {
      // Partial match — try to identify by value range
      for (final v in rangeValues) {
        if (v >= 25 && v <= 60 && tableTbw == null) {
          tableTbw = v;
        } else if (v >= 5 && v <= 20 && tableProtein == null) {
          tableProtein = v;
        } else if (v >= 1 && v <= 8 && tableMinerals == null) {
          tableMinerals = v;
        } else if (v >= 30 && v <= 200 && tableWeight == null) {
          tableWeight = v;
        }
      }
      debugPrint(
        '  Partial table: TBW=$tableTbw Protein=$tableProtein '
        'Minerals=$tableMinerals Weight=$tableWeight',
      );
    }

    // ─── 3. EXTRACT HEIGHT (for BMI calculation) ──────────
    // OCR: "180cm" or "Height 180cm" or "180 cm"
    double? heightCm;
    for (final line in lines) {
      final m = RegExp(
        r'(\d{2,3})\s*cm',
        caseSensitive: false,
      ).firstMatch(line);
      if (m != null) {
        final v = double.tryParse(m.group(1)!);
        if (v != null && v >= 100 && v <= 250) {
          heightCm = v;
          debugPrint('  Height: ${v}cm from "$line"');
          break;
        }
      }
    }

    // ─── 4. CALCULATE BMI & PBF from Body Composition ───
    // PBF = Body Fat Mass / Weight × 100
    // BMI = Weight / (Height in meters)²
    // These are much more reliable than trying to parse chart text

    double? calcPbf;
    if (tableWeight != null && tableBfm != null && tableWeight > 0) {
      calcPbf = (tableBfm / tableWeight) * 100;
      debugPrint('  Calculated PBF: ${calcPbf.toStringAsFixed(1)}%');
    }

    double? calcBmi;
    if (tableWeight != null && heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100;
      calcBmi = tableWeight / (heightM * heightM);
      debugPrint('  Calculated BMI: ${calcBmi.toStringAsFixed(1)}');
    }

    // ─── 5. BMI & PBF (FALLBACK: OCR proximity) ─────────
    final bmi = _findNearLabel(lines, ['bmi', 'body mass index'], 10, 50);
    final pbf = _findNearLabel(lines, ['pbf', 'percent body fat'], 3, 60);

    // ─── 6. WEIGHT FROM "(kg)78.7" PATTERN ──────────────
    double? chartWeight;
    for (final line in lines) {
      final m = RegExp(r'\(kg\)\s*(\d+\.?\d*)').firstMatch(line);
      if (m != null) {
        final v = double.tryParse(m.group(1)!);
        if (v != null && v >= 30 && v <= 200) {
          chartWeight = v;
          debugPrint('  Chart weight: $v from "$line"');
          break;
        }
      }
    }

    // ─── 7. WAIST-HIP RATIO ─────────────────────────────
    // "0.95" appears near "Waist-Hip Ratio".
    // Look for 0.XX standalone number near the label.
    double? whr;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('waist') &&
          lines[i].toLowerCase().contains('hip')) {
        // Search ±5 lines for 0.XX
        for (
          int j = (i - 5).clamp(0, lines.length);
          j < (i + 5).clamp(0, lines.length);
          j++
        ) {
          final m = RegExp(r'^(\d\.\d{1,2})$').firstMatch(lines[j].trim());
          if (m != null) {
            final v = double.tryParse(m.group(1)!);
            if (v != null && v >= 0.5 && v <= 1.5) {
              whr = v;
              debugPrint('  WHR: $v from "${lines[j]}"');
              break;
            }
          }
        }
        break;
      }
    }

    // ─── 6. VISCERAL FAT LEVEL ──────────────────────────
    // "Level 11"
    double? visceral;
    for (final line in lines) {
      final m = RegExp(
        r'Level\s+(\d{1,2})',
        caseSensitive: false,
      ).firstMatch(line);
      if (m != null) {
        final v = double.tryParse(m.group(1)!);
        if (v != null && v >= 1 && v <= 30) {
          visceral = v;
          debugPrint('  Visceral: $v from "$line"');
          break;
        }
      }
    }

    // ─── 7. BMR ─────────────────────────────────────────
    // "Basal Metabolic Rate 1514 kcal"
    double? bmr;
    for (final line in lines) {
      if (line.toLowerCase().contains('basal metabolic')) {
        final m = RegExp(r'(\d{3,4})\s*kcal').firstMatch(line);
        if (m != null) {
          bmr = double.tryParse(m.group(1)!);
          debugPrint('  BMR: $bmr from "$line"');
          break;
        }
      }
    }

    // ─── 8. RECOMMENDED CALORIE INTAKE ──────────────────
    // "Recommended caloie intake 2392 kcal" (note typo in OCR)
    double? kcal;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if ((lower.contains('recommended') && lower.contains('intake')) ||
          (lower.contains('calo') && lower.contains('intake'))) {
        final m = RegExp(r'(\d{3,5})\s*kcal').firstMatch(line);
        if (m != null) {
          kcal = double.tryParse(m.group(1)!);
          debugPrint('  Recommended Kcal: $kcal from "$line"');
          break;
        }
      }
    }

    // ─── MERGE ──────────────────────────────────────────
    final weight = tableWeight ?? chartWeight;
    final finalBmi = calcBmi ?? bmi;
    final finalPbf = calcPbf ?? pbf;

    debugPrint(
      'Final: weight=$weight pbf=${finalPbf?.toStringAsFixed(1)} '
      'bmi=${finalBmi?.toStringAsFixed(1)} bfm=$tableBfm tbw=$tableTbw '
      'protein=$tableProtein minerals=$tableMinerals '
      'visceral=$visceral bmr=$bmr whr=$whr height=$heightCm kcal=$kcal',
    );

    return InBodyResult(
      weight: weight,
      bodyFatPercentage: finalPbf != null
          ? double.parse(finalPbf.toStringAsFixed(1))
          : null,
      bmi: finalBmi != null ? double.parse(finalBmi.toStringAsFixed(1)) : null,
      bodyFatMass: tableBfm,
      totalBodyWater: tableTbw,
      protein: tableProtein,
      minerals: tableMinerals,
      visceralFatLevel: visceral,
      basalMetabolicRate: bmr,
      waistHipRatio: whr,
      recommendedCalorieIntake: kcal,
      testDate: testDate,
    );
  }

  // ─── Helpers ──────────────────────────────────────────

  /// Find a standalone number near a label line.
  /// Searches ±[radius] lines from each label occurrence.
  double? _findNearLabel(
    List<String> lines,
    List<String> labels,
    double min,
    double max, {
    int radius = 10,
    List<String> excludeLabels = const [],
  }) {
    // Find all line indices where a label appears
    final labelIndices = <int>[];
    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      for (final label in labels) {
        if (lower.contains(label)) {
          labelIndices.add(i);
          break;
        }
      }
    }

    // For each label occurrence, search nearby lines for a standalone number
    for (final labelIdx in labelIndices) {
      // Search AFTER the label first, then before
      for (int offset = 1; offset <= radius; offset++) {
        for (final idx in [labelIdx + offset, labelIdx - offset]) {
          if (idx < 0 || idx >= lines.length) continue;
          final line = lines[idx].trim();
          // Skip lines that are themselves labels
          final lower = line.toLowerCase();
          if (labels.any((l) => lower == l) ||
              excludeLabels.any((l) => lower == l)) {
            continue;
          }
          // Look for a standalone number (just a number on its own line)
          final m = RegExp(r'^(\d+\.?\d*)$').firstMatch(line);
          if (m != null) {
            final v = double.tryParse(m.group(1)!);
            if (v != null && v >= min && v <= max) {
              debugPrint('  Near "${labels.first}": $v at line $idx ("$line")');
              return v;
            }
          }
        }
      }
    }
    return null;
  }

  /// Extract test date from "DD.MM.YYYY. HH:MM"
  DateTime? _extractDate(List<String> lines) {
    for (final line in lines) {
      final m = RegExp(
        r'(\d{1,2})\.(\d{1,2})\.(\d{4})\.?\s*(\d{1,2}):(\d{2})',
      ).firstMatch(line);
      if (m != null) {
        try {
          return DateTime(
            int.parse(m.group(3)!),
            int.parse(m.group(2)!),
            int.parse(m.group(1)!),
            int.parse(m.group(4)!),
            int.parse(m.group(5)!),
          );
        } catch (_) {}
      }
    }
    return null;
  }
}
