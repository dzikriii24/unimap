import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicamp/core/models/spot_model.dart';
import 'package:unicamp/core/providers/spot_provider.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/features/auth/presentation/pages/login_screen.dart';
import 'package:unicamp/presentation/pages/spot_detail_screen.dart';
import 'package:unicamp/features/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoadingProfile = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpotProvider>(context, listen: false).loadSpots();
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data =
          await _supabase.from('users_001').select().eq('id', userId).single();

      if (mounted) {
        setState(() {
          _userData = data;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotProvider = Provider.of<SpotProvider>(context);
    final favoriteSpots =
        spotProvider.spots.where((s) => s.isFavorite).toList();

    if (_isLoadingProfile) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text(
                'Memuat profil...',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String name = _userData?['username'] ?? 'User';
    String joinYear = '2025';
    if (_userData?['created_at'] != null) {
      try {
        joinYear = DateTime.parse(_userData!['created_at'].toString()).year.toString();
      } catch (_) {}
    }

    final String jurusan = _userData?['jurusan'] ?? '-';
    final String email = _userData?['email'] ?? '-';
    final String photoUrl = _userData?['foto_profile'] ??
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde';

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: Colors.grey.shade300),
            ),
          ),

          // Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(name, jurusan, photoUrl),

                      SizedBox(height: 30),

                      // Stats Cards
                      _buildStatsCards(favoriteSpots.length, joinYear),

                      SizedBox(height: 30),

                      // Action Buttons
                      _buildActionButtons(),

                      SizedBox(height: 30),

                      // Favorites Section
                      _buildFavoritesSection(spotProvider, favoriteSpots),

                      SizedBox(height: 30),

                      // Contact Info
                      _buildContactInfo(email),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String jurusan, String photoUrl) {
    return Column(
      children: [
        // Profile Picture
        Container(
          width: 100,
          height: 100,
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),

        // Name
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 8),

        // Jurusan Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school_rounded,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 6),
              Text(
                jurusan,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(int favoriteCount, String joinYear) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            icon: Icons.favorite_rounded,
            value: favoriteCount.toString(),
            label: 'Favorit',
            color: Colors.red,
          ),
          _buildStatCard(
            icon: Icons.event_available_rounded,
            value: 'Aktif',
            label: 'Status',
            color: Colors.green,
          ),
          _buildStatCard(
            icon: Icons.calendar_today_rounded,
            value: joinYear,
            label: 'Bergabung',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_userData != null) {
                final bool? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(userData: _userData!),
                  ),
                );
                if (result == true) {
                  _fetchUserData();
                }
              }
            },
            icon: Icon(Icons.edit_rounded, size: 20),
            label: Text(
              'Edit Profil',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded, size: 20),
            label: Text(
              'Keluar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection(
      SpotProvider spotProvider, List<CampusSpot> favoriteSpots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tempat Favorit",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (favoriteSpots.isNotEmpty)
              Text(
                '${favoriteSpots.length} item',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        if (spotProvider.isLoading)
          Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        else if (favoriteSpots.isEmpty)
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 12),
                Text(
                  "Belum ada favorit",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Simpan tempat yang Anda suka",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          ...favoriteSpots.map((spot) => _buildFavoriteItem(spot)).toList(),
      ],
    );
  }

  Widget _buildFavoriteItem(CampusSpot spot) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SpotDetailScreen(spot: spot)),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Spot Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: spot.photoUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.location_on, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 12),

                // Spot Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: spot.category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spot.category.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: spot.category.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 12, color: Colors.grey.shade500),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              spot.address,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite Button
                IconButton(
                  icon: Icon(
                    Icons.favorite_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () {
                    Provider.of<SpotProvider>(context, listen: false)
                        .toggleFavorite(spot.id, spot.tableName);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(String email) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.email_rounded, color: Colors.blue, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Kontak",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension SpotCategoryColor on SpotCategory {
  Color get color {
    switch (this) {
      case SpotCategory.building:
        return const Color(0xFF4FC3F7);
      case SpotCategory.wifi:
        return const Color(0xFF7986CB);
      case SpotCategory.canteen:
        return const Color(0xFFFF8A65);
      case SpotCategory.mosque:
        return const Color(0xFF81C784);
      case SpotCategory.minimarket:
        return const Color(0xFFF06292);
      case SpotCategory.photocopy:
        return const Color(0xFF90A4AE);
      case SpotCategory.parking:
        return const Color(0xFF4DB6AC);
      case SpotCategory.sports:
        return const Color(0xFFFF9800);
      case SpotCategory.library:
        return const Color(0xFFBA68C8);
      case SpotCategory.atm:
        return const Color(0xFFE57373);
      default:
        return AppTheme.primaryColor;
    }
  }
}
