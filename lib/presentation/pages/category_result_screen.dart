import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unicamp/core/models/spot_model.dart';
import 'package:unicamp/core/providers/spot_provider.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/presentation/pages/spot_detail_screen.dart';
import 'package:unicamp/core/services/supabase_service.dart';
import 'package:unicamp/presentation/pages/building_rooms_screen.dart';

class CategoryResultScreen extends StatefulWidget {
  final SpotCategory? category;
  final String? initialSearchQuery;

  const CategoryResultScreen({
    super.key,
    this.category,
    this.initialSearchQuery,
  });

  @override
  State<CategoryResultScreen> createState() => _CategoryResultScreenState();
}

class _CategoryResultScreenState extends State<CategoryResultScreen> {
  late TextEditingController _searchController;
  String _currentQuery = '';
  final _supabaseService = SupabaseService();

  List<Map<String, dynamic>> _roomResults = [];
  bool _isSearchingRooms = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery ?? '');
    _currentQuery = widget.initialSearchQuery ?? '';

    if (_currentQuery.isNotEmpty) {
      _performRoomSearch(_currentQuery);
    }
  }

  Future<void> _performRoomSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _roomResults = []);
      return;
    }
    setState(() => _isSearchingRooms = true);
    final rooms = await _supabaseService.searchRooms(query);
    if (mounted) {
      setState(() {
        _roomResults = rooms;
        _isSearchingRooms = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CampusSpot> _getFilteredSpots(List<CampusSpot> allSpots) {
    return allSpots.where((spot) {
      if (widget.category != null && widget.category != SpotCategory.all) {
        if (spot.category != widget.category) return false;
      }
      if (_currentQuery.isNotEmpty) {
        final query = _currentQuery.toLowerCase();
        return spot.name.toLowerCase().contains(query) ||
            spot.description.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer agar UI terupdate saat Like ditekan
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Abu-abu sangat muda
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.category != null ? widget.category!.name : 'Pencarian',
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _currentQuery = value);
                  _performRoomSearch(value);
                },
                decoration: InputDecoration(
                  hintText: 'Cari gedung, kantin, atau ruangan...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: _currentQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _currentQuery = '';
                              _roomResults = [];
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // --- CONTENT LIST ---
          Expanded(
            child: Consumer<SpotProvider>(
              builder: (context, provider, child) {
                final filteredSpots = _getFilteredSpots(provider.spots);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HASIL PENCARIAN RUANGAN
                      if (_currentQuery.isNotEmpty) ...[
                        _buildSectionHeader("Ruangan Ditemukan (${_roomResults.length})"),
                        const SizedBox(height: 12),
                        if (_isSearchingRooms)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_roomResults.isEmpty && filteredSpots.isEmpty)
                          const SizedBox()
                        else
                          ..._roomResults.map((room) => _buildRoomResultCard(room)).toList(),
                        const SizedBox(height: 24),
                      ],

                      // 2. HASIL TEMPAT (Spot)
                      _buildSectionHeader("Tempat & Fasilitas (${filteredSpots.length})"),
                      const SizedBox(height: 12),

                      if (filteredSpots.isEmpty && _roomResults.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredSpots.map((spot) => _buildSpotCard(context, spot, provider)).toList(),
                      
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  // Card Ruangan (Premium)
  Widget _buildRoomResultCard(Map<String, dynamic> room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BuildingRoomsScreen(
                  spotName: room['nama_gedung'],
                  highlightRoomName: room['nama_ruang'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.meeting_room_rounded, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room['nama_ruang'],
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.apartment_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            room['nama_gedung'],
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 10, color: Colors.grey.shade300),
                          const SizedBox(width: 8),
                          Text(
                            "Lantai ${room['lantai']}",
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card Spot Premium (Dengan Gambar, Info, Like)
  Widget _buildSpotCard(BuildContext context, CampusSpot spot, SpotProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot)));
          },
          child: Column(
            children: [
              // 1. Gambar & Badge Kategori
              Stack(
                children: [
                  Hero(
                    tag: 'category_img_${spot.id}_${spot.tableName}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: CachedNetworkImage(
                        imageUrl: spot.photoUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey.shade100),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        spot.category.name,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  // Tombol Like
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: () {
                        provider.toggleFavorite(spot.id, spot.tableName);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          spot.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                          color: spot.isFavorite ? Colors.red : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Informasi Detail
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            spot.name,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Rating (Dummy atau Real)
                        if (spot.facilities.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  "${spot.facilities.length}",
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Alamat
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            spot.address.isEmpty ? 'UIN Bandung' : spot.address,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Jam
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          spot.operatingHours.isNotEmpty ? spot.operatingHours : "24 Jam",
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("Tidak ditemukan data", style: GoogleFonts.inter(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}