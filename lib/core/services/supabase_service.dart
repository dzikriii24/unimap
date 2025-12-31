import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/spot_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseService._internal();

  // URL dan Key (Pastikan ini sesuai dengan project Supabase kamu)
  static const String supabaseUrl = 'https://rbjfkmpuouzbtbmgsqlg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJiamZrbXB1b3V6YnRibWdzcWxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1NDYzNTcsImV4cCI6MjA4MTEyMjM1N30.yPJovU4J6gs2eRzv94VGq7epWbL1Vw0eLF3QcpY9aeQ';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
  bool get isLoggedIn => client.auth.currentUser != null;
  User? get currentUser => client.auth.currentUser;

  // ✅ METHOD REGISTER UTAMA (FIXED)
  Future<AuthResponse> registerUser({
    required String email,
    required String password,
    required String username,
    required String jurusan,
    required String fotoProfile,
  }) async {
    try {
      // 1. Daftar ke Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Jika Auth berhasil, masukkan data detail ke tabel 'users_001'
      if (response.user != null) {
        await _client.from('users_001').insert({
          'id':
              response.user!.id, // Menggunakan ID dari Auth sebagai Primary Key
          'username': username,
          'email': email,
          'jurusan': jurusan,
          'foto_profile': fotoProfile,
          // 'created_at' akan otomatis diisi oleh default value di database
        });
      }

      return response;
    } catch (e) {
      // Jika insert ke tabel gagal, opsi: hapus user auth agar tidak nyangkut (opsional)
      rethrow;
    }
  }

  // ✅ METHOD: Get User Profile (FIXED: baca dari users_001)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users_001') // Arahkan ke tabel yang benar
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return response as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // ✅ METHOD: Login
  Future<void> loginAfterVerification(String email, String password) async {
    try {
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error login: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRoomsBySpot(String spotName) async {
    try {
      final response = await client
          .from('ruang')
          .select('*')
          .eq('detail_tempat', spotName) // Asumsi relasi via nama tempat
          .order('lantai', ascending: true)
          .order('nama_ruang', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error get rooms: $e');
      return [];
    }
  }

  // ✅ GET COMMENTS (Join dengan users_001 untuk ambil nama & foto)
  Future<List<Map<String, dynamic>>> getComments(String spotId) async {
    try {
      // Supabase join syntax sederhana
      final response = await client
          .from('comments')
          .select('*, users_001(username, foto_profile)')
          .eq('spot_id', spotId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error get comments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRoomsByBuilding(
      String buildingName) async {
    try {
      // Kita cari yang kolom 'nama_gedung'-nya sama dengan nama gedung yang diklik
      final response = await client
          .from('ruang')
          .select('*')
          .ilike('nama_gedung',
              '%$buildingName%') // Pakai ilike biar tidak case sensitive
          .order('lantai', ascending: true)
          .order('nama_ruang', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error get rooms: $e');
      return [];
    }
  }

  // ✅ SEARCH ROOMS (Untuk Pencarian di Home)
  Future<List<Map<String, dynamic>>> searchRooms(String query) async {
    try {
      final response = await client
          .from('ruang')
          .select('*')
          .ilike('nama_ruang', '%$query%') // Cari berdasarkan nama ruang
          .limit(10); // Batasi hasil biar tidak kebanyakan

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error search rooms: $e');
      return [];
    }
  }

// ... kode sebelumnya ...

  // ✅ [BARU] AMBIL LIST ID FAVORIT USER
  Future<List<String>> getUserFavoriteIds() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];

      // Ambil spot_id DAN spot_type
      final response = await client
          .from('favorites')
          .select('spot_id, spot_type')
          .eq('user_id', userId);

      // Kita gabungkan jadi String unik: "gedung_1", "kantin_1", dll.
      return (response as List).map((e) {
        return "${e['spot_type']}_${e['spot_id']}";
      }).toList();
    } catch (e) {
      print('Error fetch favorites: $e');
      return [];
    }
  }

  // ✅ [BARU] TOGGLE FAVORITE (LIKE / UNLIKE)
  Future<bool> toggleFavorite(String spotId, String tableName) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // 1. Cek apakah sudah ada (Cek ID + TIPE)
      final existing = await client
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('spot_id', spotId)
          .eq('spot_type', tableName) // Cek tipenya juga!
          .maybeSingle();

      if (existing != null) {
        // DELETE (Unlike)
        await client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('spot_id', spotId)
            .eq('spot_type', tableName);
        return false;
      } else {
        // INSERT (Like)
        await client.from('favorites').insert({
          'user_id': userId,
          'spot_id': spotId,
          'spot_type': tableName, // Simpan tipenya!
        });
        return true;
      }
    } catch (e) {
      print('Error toggle favorite: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getSpotPopularity() async {
    try {
      final response = await client.from('spot_stats').select();

      // Convert ke Map biar gampang dicari: "gedung_1" -> 50 likes
      final Map<String, int> popularityMap = {};

      for (var item in response) {
        final key = "${item['spot_type']}_${item['spot_id']}";
        popularityMap[key] = (item['total_likes'] as int);
      }

      return popularityMap;
    } catch (e) {
      print('Error fetch popularity: $e');
      return {};
    }
  }

  // ✅ ADD COMMENT
  Future<void> addComment(String spotId, String content) async {
    final user = client.auth.currentUser;
    if (user == null) throw 'User belum login';

    await client.from('comments').insert({
      'spot_id': spotId,
      'user_id': user.id,
      'content': content,
    });
  }

  // ✅ DELETE COMMENT
  Future<void> deleteComment(int commentId) async {
    await client.from('comments').delete().eq('id', commentId);
  }

  // ========== METHODS UNTUK DATA KAMPUS (TIDAK PERLU DIUBAH) ==========

  Future<List<Map<String, dynamic>>> getAllAtms() async {
    final response = await client.from('atm').select('*').order('nama_bank');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllFotokopi() async {
    final response =
        await client.from('fotokopi').select('*').order('nama_tempat');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllGedung() async {
    final response =
        await client.from('gedung').select('*').order('nama_gedung');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllKantin() async {
    final response =
        await client.from('kantin').select('*').order('nama_kantin');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllLapangan() async {
    final response =
        await client.from('lapangan').select('*').order('nama_lapangan');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllMasjid() async {
    final response =
        await client.from('masjid').select('*').order('nama_masjid');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllMinimarket() async {
    final response =
        await client.from('minimarket').select('*').order('nama_minimarket');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllParkiran() async {
    final response =
        await client.from('parkiran').select('*').order('nama_parkiran');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllWifi() async {
    final response = await client.from('wifi').select('*').order('nama_wifi');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllRuang() async {
    final response = await client.from('ruang').select('*').order('nama_ruang');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllPerpustakaan() async {
    final response = await client
        .from('perpustakaan')
        .select('*')
        .order('nama_perpustakaan');
    return List<Map<String, dynamic>>.from(response);
  }

  // Method untuk mendapatkan semua spot dalam satu list
  Future<List<CampusSpot>> getAllCampusSpots() async {
    final allSpots = <CampusSpot>[];

    try {
      // Ambil data dari semua tabel
      final atms = await getAllAtms();
      final fotokopi = await getAllFotokopi();
      final gedung = await getAllGedung();
      final kantin = await getAllKantin();
      final lapangan = await getAllLapangan();
      final masjid = await getAllMasjid();
      final minimarket = await getAllMinimarket();
      final parkiran = await getAllParkiran();
      final wifi = await getAllWifi();
      final perpustakaan = await getAllPerpustakaan();

      // Konversi ATM ke CampusSpot
      for (var atm in atms) {
        allSpots.add(CampusSpot.fromDatabase(
          data: atm,
          category: SpotCategory.atm,
          tableName: 'atm',
        ));
      }

      // Konversi Fotokopi
      for (var fp in fotokopi) {
        allSpots.add(CampusSpot.fromDatabase(
          data: fp,
          category: SpotCategory.photocopy,
          tableName: 'fotokopi',
        ));
      }

      // Konversi Gedung
      for (var gdg in gedung) {
        allSpots.add(CampusSpot.fromDatabase(
          data: gdg,
          category: SpotCategory.building,
          tableName: 'gedung',
        ));
      }

      // Konversi Kantin
      for (var ktn in kantin) {
        allSpots.add(CampusSpot.fromDatabase(
          data: ktn,
          category: SpotCategory.canteen,
          tableName: 'kantin',
        ));
      }

      // Konversi Lapangan
      for (var lap in lapangan) {
        allSpots.add(CampusSpot.fromDatabase(
          data: lap,
          category: SpotCategory.sports,
          tableName: 'lapangan',
        ));
      }

      // Konversi Masjid
      for (var msj in masjid) {
        allSpots.add(CampusSpot.fromDatabase(
          data: msj,
          category: SpotCategory.mosque,
          tableName: 'masjid',
        ));
      }

      // Konversi Minimarket
      for (var mm in minimarket) {
        allSpots.add(CampusSpot.fromDatabase(
          data: mm,
          category: SpotCategory.minimarket,
          tableName: 'minimarket',
        ));
      }

      // Konversi Parkiran
      for (var prk in parkiran) {
        allSpots.add(CampusSpot.fromDatabase(
          data: prk,
          category: SpotCategory.parking,
          tableName: 'parkiran',
        ));
      }

      // Konversi WiFi
      for (var wf in wifi) {
        allSpots.add(CampusSpot.fromDatabase(
          data: wf,
          category: SpotCategory.wifi,
          tableName: 'wifi',
        ));
      }

      // Konversi Perpustakaan
      for (var perpus in perpustakaan) {
        allSpots.add(CampusSpot.fromDatabase(
          data: perpus,
          category: SpotCategory.library,
          tableName: 'perpustakaan',
        ));
      }

      return allSpots;
    } catch (e) {
      print('Error fetching campus spots: $e');
      return allSpots;
    }
  }
}
