import 'package:flutter/material.dart';
import 'package:unicamp/core/models/spot_model.dart';
import 'package:unicamp/core/services/supabase_service.dart';
import 'package:latlong2/latlong.dart';

class SpotProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  Map<String, int> _popularityData = {};

  List<CampusSpot> _spots = [];
  bool _isLoading = true;
  String _errorMessage = '';

  List<CampusSpot> get spots => _spots;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // ✅ UPDATE: Load Spots + Sync Favorites (Gabungkan data tempat & data like)
  Future<void> loadSpots() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final allSpots = await _supabaseService.getAllCampusSpots();

      // Ambil daftar kunci unik favorit (contoh: ["gedung_1", "kantin_2"])
      final favoriteKeys = await _supabaseService.getUserFavoriteIds();

      _popularityData = await _supabaseService.getSpotPopularity();

      for (var spot in allSpots) {
        // Buat kunci unik untuk spot ini
        final uniqueKey = "${spot.tableName}_${spot.id}";

        // Cek apakah kunci unik ini ada di daftar favorit
        if (favoriteKeys.contains(uniqueKey)) {
          spot.isFavorite = true;
        } else {
          spot.isFavorite = false;
        }
      }
      _spots = allSpots;
    } catch (e) {
      _errorMessage = 'Gagal memuat data: $e';
      debugPrint('Error loading spots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// ✅ UPDATE: Toggle Favorite Menerima ID & TableName
  Future<void> toggleFavorite(String spotId, String tableName) async {
    // 1. Cari spot spesifik berdasarkan ID DAN TableName (Biar ga salah orang)
    final index =
        _spots.indexWhere((s) => s.id == spotId && s.tableName == tableName);

    if (index == -1) return; // Kalau ga ketemu, stop

    final oldStatus = _spots[index].isFavorite;

    // Optimistic UI Update
    _spots[index].isFavorite = !oldStatus;
    notifyListeners();

    try {
      // Kirim ke database
      final isLikedServer =
          await _supabaseService.toggleFavorite(spotId, tableName);
      _spots[index].isFavorite = isLikedServer;
    } catch (e) {
      // Rollback jika error
      _spots[index].isFavorite = oldStatus;
      debugPrint("Gagal update favorite: $e");
    }

    notifyListeners();
  }

  // Helper: Ambil list yang dilike saja (untuk Profile Page)
  List<CampusSpot> getFavoriteSpots() {
    return _spots.where((spot) => spot.isFavorite).toList();
  }

  // Helper: Filter Kategori
  List<CampusSpot> getSpotsByCategory(SpotCategory category) {
    if (category == SpotCategory.all) return _spots;
    return _spots.where((spot) => spot.category == category).toList();
  }

  List<CampusSpot> getPopularSpots() {
    // Clone list biar list asli ga berantakan
    List<CampusSpot> sortedSpots = List.from(_spots);

    sortedSpots.sort((a, b) {
      final keyA = "${a.tableName}_${a.id}";
      final keyB = "${b.tableName}_${b.id}";

      final likesA = _popularityData[keyA] ?? 0;
      final likesB = _popularityData[keyB] ?? 0;

      return likesB.compareTo(likesA); // Sort dari besar ke kecil
    });

    return sortedSpots; // Kembalikan 10 teratas misalnya (opsional)
  }

  // Helper: Search Lokal
  List<CampusSpot> searchSpots(String query) {
    if (query.isEmpty) return _spots;

    final lowerQuery = query.toLowerCase();
    return _spots
        .where((spot) =>
            spot.name.toLowerCase().contains(lowerQuery) ||
            spot.description.toLowerCase().contains(lowerQuery) ||
            spot.category.name.toLowerCase().contains(lowerQuery) ||
            spot.address.toLowerCase().contains(lowerQuery))
        .toList();
  }

  List<CampusSpot> getNearbySpots() {
    // Koordinat Dummy (Misal User lagi di Gerbang Depan UIN)
    // Nanti ganti pakai Geolocator.getCurrentPosition()
    const userLat = -6.9311;
    const userLng = 107.7175;
    const Distance distance = Distance();

    List<CampusSpot> sortedSpots = List.from(_spots);

    sortedSpots.sort((a, b) {
      final distA =
          distance.as(LengthUnit.Meter, LatLng(userLat, userLng), a.position);
      final distB =
          distance.as(LengthUnit.Meter, LatLng(userLat, userLng), b.position);
      return distA.compareTo(distB); // Sort dari yang terdekat
    });

    return sortedSpots;
  }
}
