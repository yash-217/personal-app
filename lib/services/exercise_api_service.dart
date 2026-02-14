import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/exercise.dart';
import 'storage_service.dart';

class ExerciseApiService {
  // ExerciseDB v1 — fully open-source, NO API key required
  static const String _baseUrl = 'https://exercisedb.dev';
  static const int _pageSize = 100;

  final StorageService _storage;

  ExerciseApiService(this._storage);

  /// Get exercises — cache first, then seed asset, then API
  Future<List<Exercise>> getExercises() async {
    // 1. Return from Hive cache if available and has difficulty data
    if (_storage.hasExercisesCache) {
      final cached = _storage.getAllExercises();
      // If any exercise has a non-default difficulty, the cache has proper data
      final hasDifficultyData = cached.any((e) => e.difficulty != 'Regular');
      if (cached.isNotEmpty && hasDifficultyData) {
        return cached;
      }
      // Old cache without difficulty data — fall through to reload from seed
    }

    // 2. Try loading from bundled seed JSON (instant, no network)
    try {
      final exercises = await _loadFromSeedAsset();
      if (exercises.isNotEmpty) {
        await _storage.cacheExercises(exercises);
        return exercises;
      }
    } catch (_) {
      // Seed asset missing or corrupt, fall through to API
    }

    // 3. Last resort — fetch from API
    return fetchAndCacheExercises();
  }

  /// Load exercises from the bundled JSON asset
  Future<List<Exercise>> _loadFromSeedAsset() async {
    final jsonStr = await rootBundle.loadString('assets/exercises_seed.json');
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
    return data.map((e) => _parseExercise(e as Map<String, dynamic>)).toList();
  }

  /// Fetch ALL exercises from the API (paginated, with rate-limit handling)
  Future<List<Exercise>> fetchAndCacheExercises() async {
    try {
      final List<Exercise> allExercises = [];
      int offset = 0;
      bool hasMore = true;

      while (hasMore) {
        final response = await _getWithRetry(
          '$_baseUrl/api/v1/exercises?offset=$offset&limit=$_pageSize',
        );

        if (response.statusCode == 200) {
          final body = json.decode(response.body) as Map<String, dynamic>;
          final success = body['success'] as bool? ?? false;
          if (!success) {
            throw Exception('API returned success=false');
          }

          final data = body['data'] as List<dynamic>? ?? [];
          if (data.isEmpty) {
            hasMore = false;
          } else {
            allExercises.addAll(
              data.map((e) => _parseExercise(e as Map<String, dynamic>)),
            );
            offset += _pageSize;

            if (data.length < _pageSize) {
              hasMore = false;
            }

            // Throttle between pages to avoid rate limiting
            if (hasMore) {
              await Future.delayed(const Duration(seconds: 5));
            }
          }
        } else {
          throw Exception('Failed to fetch exercises: ${response.statusCode}');
        }
      }

      await _storage.cacheExercises(allExercises);
      return allExercises;
    } catch (e) {
      if (_storage.hasExercisesCache) {
        return _storage.getAllExercises();
      }
      rethrow;
    }
  }

  /// HTTP GET with exponential backoff retry for 429 rate-limit errors
  Future<http.Response> _getWithRetry(String url, {int maxRetries = 3}) async {
    int attempt = 0;
    while (true) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 429 && attempt < maxRetries) {
        attempt++;
        final delay = Duration(seconds: attempt * 5); // 5s, 10s, 15s
        await Future.delayed(delay);
        continue;
      }
      return response;
    }
  }

  /// Parse v1 API response into our Exercise model.
  Exercise _parseExercise(Map<String, dynamic> json) {
    return Exercise(
      id: json['exerciseId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bodyPart: _firstFromList(json['bodyParts']),
      targetMuscle: _firstFromList(json['targetMuscles']),
      equipment: _firstFromList(json['equipments']),
      gifUrl: json['gifUrl']?.toString() ?? '',
      secondaryMuscles: _stringList(json['secondaryMuscles']),
      instructions: _stringList(json['instructions']),
      difficulty: json['difficulty']?.toString() ?? 'Regular',
    );
  }

  String _firstFromList(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    if (value is String) return value;
    return '';
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  // --- Local filter helpers (operate on cached data) ---

  List<Exercise> filterByBodyPart(List<Exercise> exercises, String bodyPart) {
    return exercises
        .where((e) => e.bodyPart.toLowerCase() == bodyPart.toLowerCase())
        .toList();
  }

  List<Exercise> filterByTargetMuscle(
    List<Exercise> exercises,
    String targetMuscle,
  ) {
    return exercises
        .where(
          (e) => e.targetMuscle.toLowerCase() == targetMuscle.toLowerCase(),
        )
        .toList();
  }

  List<Exercise> filterByEquipment(List<Exercise> exercises, String equipment) {
    return exercises
        .where((e) => e.equipment.toLowerCase() == equipment.toLowerCase())
        .toList();
  }

  List<Exercise> searchByName(List<Exercise> exercises, String query) {
    final lowerQuery = query.toLowerCase();
    return exercises
        .where((e) => e.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  List<String> getBodyParts(List<Exercise> exercises) {
    return exercises.map((e) => e.bodyPart).toSet().toList()..sort();
  }

  List<String> getTargetMuscles(List<Exercise> exercises) {
    return exercises.map((e) => e.targetMuscle).toSet().toList()..sort();
  }

  List<String> getEquipmentTypes(List<Exercise> exercises) {
    return exercises.map((e) => e.equipment).toSet().toList()..sort();
  }
}
