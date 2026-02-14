import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/weight_entry.dart';
import '../services/exercise_api_service.dart';
import '../services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ExerciseProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final ExerciseApiService _apiService;
  final StorageService _storage;

  List<Exercise> _exercises = [];
  List<Exercise> _filteredExercises = [];
  String? _selectedBodyPart;
  String? _selectedDifficulty;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  static const List<String> difficultyLevels = [
    'Rookie',
    'Regular',
    'Gym Bro',
    'Lifter',
    'Veteran',
  ];

  ExerciseProvider(this._apiService, this._storage) {
    loadExercises();
  }

  // --- Getters ---
  List<Exercise> get exercises => _filteredExercises;
  List<Exercise> get allExercises => _exercises;
  String? get selectedBodyPart => _selectedBodyPart;
  String? get selectedDifficulty => _selectedDifficulty;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _exercises.isNotEmpty;

  List<String> get bodyParts => _apiService.getBodyParts(_exercises);
  List<String> get targetMuscles => _apiService.getTargetMuscles(_exercises);
  List<String> get equipmentTypes => _apiService.getEquipmentTypes(_exercises);

  // --- Load & Filter ---
  Future<void> loadExercises() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _apiService.getExercises();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshExercises() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _apiService.fetchAndCacheExercises();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setBodyPartFilter(String? bodyPart) {
    _selectedBodyPart = bodyPart;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setDifficultyFilter(String? difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedBodyPart = null;
    _selectedDifficulty = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = List<Exercise>.from(_exercises);

    if (_selectedBodyPart != null && _selectedBodyPart!.isNotEmpty) {
      filtered = _apiService.filterByBodyPart(filtered, _selectedBodyPart!);
    }

    if (_selectedDifficulty != null && _selectedDifficulty!.isNotEmpty) {
      filtered = filtered
          .where((e) => e.difficulty == _selectedDifficulty)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = _apiService.searchByName(filtered, _searchQuery);
    }

    _sortExercises(filtered);
    _filteredExercises = filtered;
  }

  /// Get exercises filtered by muscle groups (for workout session builder)
  List<Exercise> getExercisesForMuscleGroups(List<String> muscleGroups) {
    if (muscleGroups.isEmpty) {
      var all = List<Exercise>.from(_exercises);
      _sortExercises(all);
      return all;
    }

    var filtered = _exercises.where((e) {
      final bodyPartMatch = muscleGroups.any(
        (m) => e.bodyPart.toLowerCase() == m.toLowerCase(),
      );
      final targetMatch = muscleGroups.any(
        (m) => e.targetMuscle.toLowerCase() == m.toLowerCase(),
      );
      return bodyPartMatch || targetMatch;
    }).toList();

    _sortExercises(filtered);
    return filtered;
  }

  void _sortExercises(List<Exercise> list) {
    list.sort((a, b) {
      // 1. Difficulty
      final rankA = _getDifficultyRank(a.difficulty);
      final rankB = _getDifficultyRank(b.difficulty);
      if (rankA != rankB) return rankA.compareTo(rankB);

      // 2. Equipment Type
      final eqComparison = a.equipment.compareTo(b.equipment);
      if (eqComparison != 0) return eqComparison;

      // 3. Name
      return a.name.compareTo(b.name);
    });
  }

  static int _getDifficultyRank(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'rookie':
        return 0;
      case 'regular':
        return 1;
      case 'gym bro':
        return 2;
      case 'lifter':
        return 3;
      case 'veteran':
        return 4;
      default:
        return 5;
    }
  }

  Exercise? getExerciseById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Weight Entries ---
  List<WeightEntry> getWeightEntries(String exerciseId) {
    return _storage.getWeightEntriesForExercise(exerciseId);
  }

  Future<void> addWeightEntry({
    required String exerciseId,
    required double weight,
    int? reps,
    int? sets,
    String? notes,
    DateTime? date,
  }) async {
    final entry = WeightEntry(
      id: _uuid.v4(),
      exerciseId: exerciseId,
      date: date ?? DateTime.now(),
      weight: weight,
      reps: reps,
      sets: sets,
      notes: notes,
    );
    await _storage.saveWeightEntry(entry);
    notifyListeners();
  }

  Future<void> deleteWeightEntry(String id) async {
    await _storage.deleteWeightEntry(id);
    notifyListeners();
  }
}
