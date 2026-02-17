import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/body_metrics.dart';
import '../services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final StorageService _storage;

  UserProfile? _profile;
  List<BodyMetrics> _bodyMetrics = [];

  ProfileProvider(this._storage) {
    _loadData();
  }

  // --- Getters ---
  UserProfile? get profile {
    if (_profile == null) return null;
    if (_bodyMetrics.isEmpty) return _profile;
    // Always return profile with the weight from the latest metrics log
    return _profile!.copyWith(weight: _bodyMetrics.last.weight);
  }

  List<BodyMetrics> get bodyMetrics => _bodyMetrics;
  BodyMetrics? get latestMetrics =>
      _bodyMetrics.isNotEmpty ? _bodyMetrics.last : null;
  bool get hasProfile => _profile != null;

  void _loadData() {
    _profile = _storage.getProfile();
    _bodyMetrics = _storage.getAllBodyMetrics();
    notifyListeners();
  }

  // --- Profile ---
  Future<void> saveProfile(UserProfile profile) async {
    await _storage.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    double? height,
    double? weight,
    String? gender,
    int? weeklyGoal,
    String? weightUnit,
    DateTime? birthDate,
  }) async {
    final current =
        _profile ??
        UserProfile(
          name: '',
          age: 0,
          height: 0,
          weight: 0,
          gender: '',
          weightUnit: weightUnit ?? 'kg',
        );
    final updated = current.copyWith(
      name: name,
      age: age,
      height: height,
      weight: weight,
      gender: gender,
      weeklyGoal: weeklyGoal,
      weightUnit: weightUnit,
      birthDate: birthDate,
    );
    await saveProfile(updated);
  }

  // --- Body Metrics ---
  Future<void> addBodyMetrics({
    required double weight,
    double bodyFatPercentage = 0,
    double bmi = 0,
    double bodyFatMass = 0,
    double totalBodyWater = 0,
    double protein = 0,
    double minerals = 0,
    double visceralFatLevel = 0,
    double basalMetabolicRate = 0,
    double waistHipRatio = 0,
    double recommendedCalorieIntake = 0,
    DateTime? date,
  }) async {
    final metrics = BodyMetrics(
      id: _uuid.v4(),
      date: date ?? DateTime.now(),
      weight: weight,
      bodyFatPercentage: bodyFatPercentage,
      bmi: bmi,
      bodyFatMass: bodyFatMass,
      totalBodyWater: totalBodyWater,
      protein: protein,
      minerals: minerals,
      visceralFatLevel: visceralFatLevel,
      basalMetabolicRate: basalMetabolicRate,
      waistHipRatio: waistHipRatio,
      recommendedCalorieIntake: recommendedCalorieIntake,
    );
    await _storage.saveBodyMetrics(metrics);
    _bodyMetrics = _storage.getAllBodyMetrics();

    notifyListeners();
  }

  Future<void> updateBodyMetrics(BodyMetrics metrics) async {
    await _storage.saveBodyMetrics(metrics);
    _bodyMetrics = _storage.getAllBodyMetrics();
    notifyListeners();
  }

  Future<void> deleteBodyMetrics(String id) async {
    await _storage.deleteBodyMetrics(id);
    _bodyMetrics = _storage.getAllBodyMetrics();

    notifyListeners();
  }
}
