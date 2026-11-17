import 'package:flutter/foundation.dart';

import '../../data/models/club_model.dart';
import '../../data/repositories/club_bag_repository.dart';
import '../../domain/entities/club_gapping_entity.dart';
import '../../domain/usecases/club_gapping_usecase.dart';

class ClubGappingController extends ChangeNotifier {
  final ClubGappingUseCase useCase;
  final ClubBagRepository? bagRepository;

  List<ClubModel> _clubs = List<ClubModel>.from(ClubModel.default14Clubs);
  bool _usesCarryDistance = true;
  String? _selectedClubId = 'driver';
  ClubGappingReport? _report;

  ClubGappingController({required this.useCase, this.bagRepository}) {
    _recalculate();
    loadClubs();
  }

  List<ClubModel> get clubs => _clubs;
  bool get usesCarryDistance => _usesCarryDistance;
  String? get selectedClubId => _selectedClubId;
  bool get isLoading => false;
  ClubGappingReport? get report => _report;

  ClubModel? get selectedClub {
    if (_selectedClubId == null || _clubs.isEmpty) {
      return _report?.sortedClubs.isNotEmpty == true
          ? _report!.sortedClubs.first
          : null;
    }
    try {
      return _clubs.firstWhere((c) => c.id == _selectedClubId);
    } catch (_) {
      return _clubs.first;
    }
  }

  ClubDispersionProfile? get selectedClubDispersion {
    final club = selectedClub;
    if (club == null || _report == null) return null;
    return _report!.dispersionProfiles[club.id];
  }

  Future<void> loadClubs() async {
    try {
      if (bagRepository != null) {
        final bag = await bagRepository!.getClubs();
        if (bag.isNotEmpty) {
          _clubs = List<ClubModel>.from(bag);
          if (!_clubs.any((c) => c.id == _selectedClubId)) {
            _selectedClubId = _clubs.first.id;
          }
          _recalculate();
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep seeded default 14 clubs
    }
  }

  void toggleDistanceMetric() {
    _usesCarryDistance = !_usesCarryDistance;
    _recalculate();
    notifyListeners();
  }

  void setUsesCarryDistance(bool value) {
    if (_usesCarryDistance == value) return;
    _usesCarryDistance = value;
    _recalculate();
    notifyListeners();
  }

  void selectClub(String clubId) {
    _selectedClubId = clubId;
    notifyListeners();
  }

  Future<void> updateClubYardages(
    String clubId,
    int carryYards,
    int totalYards,
  ) async {
    final index = _clubs.indexWhere((c) => c.id == clubId);
    if (index == -1) return;

    final updated = _clubs[index].copyWith(
      carryYards: carryYards,
      totalYards: totalYards,
    );

    _clubs[index] = updated;

    if (bagRepository != null) {
      try {
        await bagRepository!.updateClub(updated);
      } catch (_) {
        // Fallback gracefully
      }
    }

    _recalculate();
    notifyListeners();
  }

  void resetToDefaults() {
    _clubs = List<ClubModel>.from(ClubModel.default14Clubs);
    if (_selectedClubId == null ||
        !_clubs.any((c) => c.id == _selectedClubId)) {
      _selectedClubId = _clubs.first.id;
    }
    _recalculate();
    notifyListeners();
  }

  void _recalculate() {
    _report = useCase.analyzeGapping(
      _clubs,
      usesCarryDistance: _usesCarryDistance,
    );
  }
}
