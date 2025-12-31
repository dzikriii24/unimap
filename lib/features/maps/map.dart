import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:unicamp/core/theme/app_theme.dart'; // Pastikan path ini sesuai
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unicamp/core/providers/spot_provider.dart'; // Pastikan path ini sesuai
import 'package:unicamp/core/models/spot_model.dart'; // Pastikan path ini sesuai
import 'package:unicamp/presentation/pages/spot_detail_screen.dart';
// import 'package:url_launcher/url_launcher.dart'; // Uncomment jika sudah install package url_launcher

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final LatLng _campusCenter = const LatLng(-6.9311, 107.7175);
  final double _initialZoom = 17.5;
  final MapController _mapController = MapController();

  final TextEditingController _searchController = TextEditingController();
  SpotCategory _selectedCategory = SpotCategory.all;
  CampusSpot? _selectedSpot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SpotProvider>(context, listen: false);
      if (provider.spots.isEmpty) {
        provider.loadSpots();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- LOGIC ---
  List<CampusSpot> _getFilteredSpots(SpotProvider provider) {
    List<CampusSpot> spots = provider.spots;

    if (_selectedCategory != SpotCategory.all) {
      spots =
          spots.where((spot) => spot.category == _selectedCategory).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      spots = spots
          .where((spot) =>
              spot.name.toLowerCase().contains(query) ||
              spot.category.name.toLowerCase().contains(query))
          .toList();
    }

    return spots;
  }

  void _moveToLocation(LatLng destLocation) {
    _mapController.move(destLocation, 18.5);
  }

  Future<void> _openGoogleMaps(CampusSpot spot) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${spot.position.latitude},${spot.position.longitude}');
    debugPrint('Opening Maps: $url');
    // Implementasi url_launcher:
    // if (await canLaunchUrl(url)) {
    //   await launchUrl(url, mode: LaunchMode.externalApplication);
    // }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final spotProvider = Provider.of<SpotProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: spotProvider.isLoading
          ? _buildLoadingState()
          : spotProvider.errorMessage.isNotEmpty
              ? _buildErrorState(spotProvider)
              : _buildMainContent(spotProvider),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Memuat peta kampus...',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SpotProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Gagal memuat data', style: GoogleFonts.inter(fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => provider.loadSpots(),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white),
            child: const Text('Coba Lagi'),
          )
        ],
      ),
    );
  }

  Widget _buildMainContent(SpotProvider provider) {
    final filteredSpots = _getFilteredSpots(provider);

    return CustomScrollView(
      slivers: [
        // 1. App Bar Floating
        _buildSliverAppBar(),

        // 2. Kategori Filter (Sticky)
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverCategoryDelegate(
            categories: SpotCategory.values,
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory =
                    _selectedCategory == category ? SpotCategory.all : category;
                _selectedSpot = null; // Reset selection
              });
            },
          ),
        ),

        // 3. Peta Kampus
        SliverToBoxAdapter(
          child: _buildMapSection(filteredSpots, provider),
        ),

        // 4. Judul List
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Lokasi',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${filteredSpots.length} ditemukan',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 5. Grid List Lokasi
        filteredSpots.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyState())
            : SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // Aspect ratio card
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildSpotGridCard(filteredSpots[index], provider);
                    },
                    childCount: filteredSpots.length,
                  ),
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari gedung, kantin...',
                        hintStyle:
                            GoogleFonts.inter(color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search,
                            color: AppTheme.primaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.grey.shade400),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(List<CampusSpot> spots, SpotProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _campusCenter,
                  initialZoom: _initialZoom,
                  onTap: (_, __) => setState(() => _selectedSpot = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),
                  MarkerLayer(
                    markers: spots.map((spot) {
                      final isSelected = _selectedSpot?.id == spot.id;
                      return Marker(
                        point: spot.position,
                        width: isSelected ? 50 : 35,
                        height: isSelected ? 50 : 35,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedSpot = spot);
                            _moveToLocation(spot.position);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : _getCategoryColor(spot.category),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getCategoryIcon(spot.category),
                              color: Colors.white,
                              size: isSelected ? 24 : 18,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Kartu Detail Floating di atas Peta
              if (_selectedSpot != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: _buildFloatingMapCard(_selectedSpot!, provider),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Kartu yang muncul di atas peta (Compact & Elegant)
// Kartu yang muncul di atas peta (Compact & Elegant)
  Widget _buildFloatingMapCard(CampusSpot spot, SpotProvider provider) {
    const defaultPhotoUrl =
        'https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=1000&auto=format&fit=crop';
    final displayPhoto =
        spot.photoUrl.isNotEmpty ? spot.photoUrl : defaultPhotoUrl;
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gambar Kecil
              Hero(
                tag:
                    'spot_img_float_${spot.id}', // Tag unik biar ga clash sama grid
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: displayPhoto,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      spot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.category.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getCategoryColor(spot.category),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Indikator "Klik untuk detail"
                    Row(
                      children: [
                        Text(
                          "Lihat Detail",
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_ios,
                            size: 10, color: AppTheme.primaryColor),
                      ],
                    ),
                  ],
                ),
              ),

              // Tombol Like (Berfungsi)
              IconButton(
                icon: Icon(
                  spot.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: spot.isFavorite ? Colors.red : Colors.grey.shade400,
                  size: 24,
                ),
                onPressed: () {
                  // PENTING: Kirim spot.id DAN spot.tableName
                  provider.toggleFavorite(spot.id, spot.tableName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSpotGridCard(CampusSpot spot, SpotProvider provider) {
    const defaultPhotoUrl =
        'https://i.pinimg.com/736x/63/e7/8c/63e78cbab74c995bae4f4015b8161a25.jpg';

    final displayPhoto =
        spot.photoUrl.isNotEmpty ? spot.photoUrl : defaultPhotoUrl;

    IconData getCategoryIcon(SpotCategory category) {
      switch (category) {
        case SpotCategory.building: return Icons.apartment;
        case SpotCategory.wifi: return Icons.wifi;
        case SpotCategory.canteen: return Icons.restaurant;
        case SpotCategory.mosque: return Icons.mosque;
        case SpotCategory.minimarket: return Icons.local_convenience_store;
        case SpotCategory.photocopy: return Icons.print;
        case SpotCategory.parking: return Icons.local_parking;
        case SpotCategory.sports: return Icons.sports_basketball;
        default: return Icons.location_on;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER IMAGE (Fixed Height) ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Hero(
                      tag: 'spot_img_grid_${spot.id}_${spot.tableName}',
                      child: CachedNetworkImage(
                        imageUrl: displayPhoto,
                        height: 120, // Sedikit dikurangi biar text muat
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey.shade100),
                        errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  // Badge Kategori
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            getCategoryIcon(spot.category),
                            size: 12,
                            color: _getCategoryColor(spot.category),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            spot.category.name,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _getCategoryColor(spot.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Tombol Like
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        provider.toggleFavorite(spot.id, spot.tableName);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          spot.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          size: 18,
                          color: spot.isFavorite ? Colors.red : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- CONTENT AREA (Pake Expanded biar ga overflow) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12), // Padding diperkecil (16 -> 12)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Sebar konten vertikal
                    children: [
                      // 1. Nama & Alamat
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spot.name,
                            maxLines: 1, // Batasi 1 baris
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  spot.address.isNotEmpty
                                      ? spot.address
                                      : 'UIN Sunan Gunung Djati',
                                  maxLines: 1, // Batasi 1 baris
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 2. Info Bawah (Jam & Fasilitas)
                      // Spacer() akan mendorong ini ke paling bawah container
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (spot.operatingHours.isNotEmpty)
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 12, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      spot.operatingHours,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Badge Fasilitas (Opsional, tampil jika muat)
                          if (spot.facilities.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 10, color: AppTheme.primaryColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    "${spot.facilities.length}",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("Lokasi tidak ditemukan",
                style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  IconData _getCategoryIcon(SpotCategory category) {
    switch (category) {
      case SpotCategory.atm:
        return Icons.atm;
      case SpotCategory.building:
        return Icons.business;
      case SpotCategory.parking:
        return Icons.local_parking;
      case SpotCategory.wifi:
        return Icons.wifi;
      case SpotCategory.minimarket:
        return Icons.store;
      case SpotCategory.canteen:
        return Icons.restaurant;
      case SpotCategory.mosque:
        return Icons.mosque;
      case SpotCategory.photocopy:
        return Icons.print;
      case SpotCategory.library:
        return Icons.library_books;
      case SpotCategory.sports:
        return Icons.sports_basketball;
      case SpotCategory.facility:
        return Icons.health_and_safety;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(SpotCategory category) {
    switch (category) {
      case SpotCategory.atm:
        return Colors.green;
      case SpotCategory.building:
        return Colors.blue;
      case SpotCategory.parking:
        return Colors.blueGrey;
      case SpotCategory.wifi:
        return Colors.indigo;
      case SpotCategory.minimarket:
        return Colors.pink;
      case SpotCategory.canteen:
        return Colors.orange;
      case SpotCategory.mosque:
        return Colors.teal;
      case SpotCategory.photocopy:
        return Colors.brown;
      case SpotCategory.library:
        return Colors.deepPurple;
      case SpotCategory.sports:
        return Colors.deepOrange;
      default:
        return AppTheme.primaryColor;
    }
  }
}

// --- Delegate untuk Sticky Header ---
class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final List<SpotCategory> categories;
  final SpotCategory selectedCategory;
  final Function(SpotCategory) onCategorySelected;

  _SliverCategoryDelegate({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 60,
      color: Colors.grey.shade50, // Match background
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onCategorySelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    cat.name,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(covariant _SliverCategoryDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory;
  }
}
