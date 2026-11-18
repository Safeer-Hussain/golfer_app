import '../../core/storage/database_helper.dart';
import '../models/club_model.dart';

class ClubBagRepository {
  final DatabaseHelper _db;

  ClubBagRepository(this._db);

  Future<List<ClubModel>> getClubs() async {
    try {
      return await _db.getClubBag();
    } catch (_) {
      return ClubModel.default14Clubs;
    }
  }

  Future<void> updateClub(ClubModel club) async {
    await _db.updateClub(club);
  }

  Future<void> recordShot(String clubId, int distance) async {
    await _db.recordClubShot(clubId, distance);
  }
}
