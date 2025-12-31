import 'package:latlong2/latlong.dart';

// ========== ENUM KATEGORI ==========
enum SpotCategory {
  all('Semua'),
  atm('ATM'),
  building('Gedung'),
  parking('Parkir'),
  wifi('WiFi'),
  minimarket('Mini Market'),
  canteen('Kantin'),
  mosque('Masjid'),
  photocopy('Fotokopi'),
  library('Perpustakaan'),
  sports('Olahraga'),
  facility('Fasilitas');

  final String name;
  const SpotCategory(this.name);
}

// ========== MODEL CAMPUS SPOT ==========
class CampusSpot {
  final String id;
  final String name;
  final LatLng position;
  final SpotCategory category;
  final String description;
  final String operatingHours;
  final String address;
  final String photoUrl;
  final List<String> facilities;
  final String linkMaps;
  final String tableName; // Nama tabel sumber data
  bool isFavorite;

  CampusSpot({
    required this.id,
    required this.name,
    required this.position,
    required this.category,
    required this.description,
    required this.operatingHours,
    required this.address,
    required this.photoUrl,
    required this.facilities,
    required this.linkMaps,
    required this.tableName,
    this.isFavorite = false,
  });

  factory CampusSpot.fromDatabase({
    required Map<String, dynamic> data,
    required SpotCategory category,
    required String tableName,
  }) {
    // 1. Ekstrak Nama (Penting untuk Debugging)
    String name = '';
    if (tableName == 'atm') {
      name = data['nama_bank']?.toString() ?? 'ATM';
    } else if (tableName == 'fotokopi') {
      name = data['nama_tempat']?.toString() ?? 'Fotokopi';
    } else if (tableName == 'gedung') {
      name = data['nama_gedung']?.toString() ?? 'Gedung';
    } else if (tableName == 'kantin') {
      name = data['nama_kantin']?.toString() ?? 'Kantin';
    } else if (tableName == 'lapangan') {
      name = data['nama_lapangan']?.toString() ?? 'Lapangan';
    } else if (tableName == 'masjid') {
      name = data['nama_masjid']?.toString() ?? 'Masjid';
    } else if (tableName == 'minimarket') {
      name = data['nama_minimarket']?.toString() ?? 'Minimarket';
    } else if (tableName == 'parkiran') {
      name = data['nama_parkiran']?.toString() ?? 'Parkiran';
    } else if (tableName == 'wifi') {
      name = data['nama_wifi']?.toString() ?? 'WiFi';
    } else if (tableName == 'perpustakaan') {
      name = data['nama_perpustakaan']?.toString() ?? 'Perpustakaan';
    } else if (tableName == 'ruang') {
      name = data['nama_ruang']?.toString() ?? 'Ruang';
    } else {
      name = data['nama']?.toString() ?? 'Unknown';
    }

    // 2. Ekstrak Koordinat
    double lat;
    double lng;
    if (data['koordinat_lat'] != null && data['koordinat_lng'] != null) {
      lat = (data['koordinat_lat'] is num)
          ? (data['koordinat_lat'] as num).toDouble()
          : double.tryParse(data['koordinat_lat'].toString()) ?? -6.9311;

      lng = (data['koordinat_lng'] is num)
          ? (data['koordinat_lng'] as num).toDouble()
          : double.tryParse(data['koordinat_lng'].toString()) ?? 107.7175;
    } else {
      lat = -6.9311;
      lng = 107.7175;
    }

    // 3. 🔥 LOGIKA FOTO (YANG DIPERBAIKI) 🔥
    String rawPhoto = data['foto']?.toString() ?? '';

    if (rawPhoto.isEmpty || !rawPhoto.startsWith('http')) {
      rawPhoto =
          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=1000&auto=format&fit=crop';
    }
    if (rawPhoto.contains('pinimg.com')) {
      // Bungkus URL asli dengan proxy
      rawPhoto = 'https://wsrv.nl/?url=${Uri.encodeComponent(rawPhoto)}';
    } 
    String finalPhotoUrl;

    // Cek apakah link valid (tidak kosong & ada http)
    if (rawPhoto.isNotEmpty && rawPhoto.startsWith('http')) {
      finalPhotoUrl = rawPhoto;
    } else {
      // Fallback Image (Gambar Default Aesthetic)
      finalPhotoUrl =
          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=1000&auto=format&fit=crop';
    }

    // UNCOMMENT INI UNTUK CEK APAKAH DATABASE MENGIRIM LINK
    // print("📸 DEBUG FOTO [$name]: $rawPhoto");

    return CampusSpot(
      id: data['id']?.toString() ?? '0',
      name: name,
      position: LatLng(lat, lng),
      category: category,
      description: data['deskripsi']?.toString() ?? 'Tidak ada deskripsi',
      operatingHours: _extractOperatingHours(data),
      address: 'UIN Sunan Gunung Djati Bandung',
      photoUrl: finalPhotoUrl, // ✅ Pakai URL hasil validasi
      facilities: _extractFacilities(data),
      linkMaps: data['link_maps']?.toString() ?? '',
      tableName: tableName,
    );
  }

  static String _extractOperatingHours(Map<String, dynamic> data) {
    if (data['jam_buka'] != null && data['jam_tutup'] != null) {
      return '${data['jam_buka']} - ${data['jam_tutup']}';
    } else if (data['operasional'] != null) {
      return data['operasional'].toString();
    } else if (data['jam_operasional'] != null) {
      return data['jam_operasional'].toString();
    }
    return '24 Jam';
  }

  static List<String> _extractFacilities(Map<String, dynamic> data) {
    final facilities = <String>[];

    // Cek kolom spesifik berdasarkan kategori
    if (data['path'] != null && data['path'].toString().isNotEmpty) {
      facilities.add('Ikon SVG');
    }

    if (data['password_wifi'] != null &&
        data['password_wifi'].toString().isNotEmpty) {
      facilities.add('Password: ${data['password_wifi']}');
    }

    if (data['jenis'] != null && data['jenis'].toString().isNotEmpty) {
      facilities.add(data['jenis'].toString());
    }

    if (data['jumlah_lantai'] != null) {
      facilities.add('${data['jumlah_lantai']} Lantai');
    }

    // Default facilities jika kosong
    if (facilities.isEmpty) {
      facilities.addAll(['Akses Publik', 'Area Kampus']);
    }

    return facilities;
  }
}
