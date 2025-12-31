import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unicamp/core/models/spot_model.dart';
import 'package:unicamp/core/providers/spot_provider.dart';
import 'package:unicamp/core/services/supabase_service.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/presentation/pages/building_rooms_screen.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ UNTUK BUKA MAPS

class SpotDetailScreen extends StatefulWidget {
  final CampusSpot spot;

  const SpotDetailScreen({super.key, required this.spot});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  final _supabaseService = SupabaseService();
  final _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoadingComments = true;
  List<Map<String, dynamic>> _comments = [];
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _supabaseService.getComments(widget.spot.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching comments: $e");
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _handlePostComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      await _supabaseService.addComment(
          widget.spot.id, _commentController.text.trim());
      _commentController.clear();
      FocusManager.instance.primaryFocus?.unfocus();

      await _fetchComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Komentar berhasil dikirim!'),
              backgroundColor: Colors.green),
        );
        // Scroll ke komentar terbaru
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  Future<void> _handleDeleteComment(int commentId) async {
    try {
      await _supabaseService.deleteComment(commentId);
      setState(() {
        _comments.removeWhere((c) => c['id'] == commentId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar dihapus')),
        );
      }
    } catch (e) {
      debugPrint("Gagal hapus: $e");
    }
  }

  // ✅ FUNGSI BUKA GOOGLE MAPS
  Future<void> _openGoogleMaps(String? url) async {
    if (url == null || url.isEmpty) {
      // Fallback: Buka pakai koordinat jika link kosong
      final lat = widget.spot.position.latitude;
      final lng = widget.spot.position.longitude;
      final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
      
      if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal membuka Maps")));
        }
      }
      return;
    }

    // Buka link dari database
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link tidak valid")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spotProvider = Provider.of<SpotProvider>(context);
    
    // Cari spot terbaru untuk status like yang sinkron
    final currentSpot = spotProvider.spots.firstWhere(
        (s) => s.id == widget.spot.id && s.tableName == widget.spot.tableName,
        orElse: () => widget.spot);

    final isBuilding = currentSpot.category == SpotCategory.building;
    
    // Gambar Default jika null/kosong
    final displayPhoto = currentSpot.photoUrl.isNotEmpty 
        ? currentSpot.photoUrl 
        : 'https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=1000&auto=format&fit=crop';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 1. HEADER IMAGE MEWAH
          SliverAppBar(
            expandedHeight: 320.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3), // Glass effect gelap
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'spot_img_detail_${currentSpot.id}_${currentSpot.tableName}',
                    child: CachedNetworkImage(
                      imageUrl: displayPhoto,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                  // Judul di atas gambar (Opsional, tapi bagus)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentSpot.category.name.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentSpot.name,
                          style: GoogleFonts.inter(
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. KONTEN DETAIL
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOMBOL AKSI UTAMA ---
                    Row(
                      children: [
                        // Tombol Like Besar
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              spotProvider.toggleFavorite(currentSpot.id, currentSpot.tableName);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: currentSpot.isFavorite ? Colors.red.shade50 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: currentSpot.isFavorite ? Colors.red.shade200 : Colors.grey.shade300
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    currentSpot.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: currentSpot.isFavorite ? Colors.red : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentSpot.isFavorite ? "Disukai" : "Suka",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: currentSpot.isFavorite ? Colors.red : Colors.grey.shade700
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tombol Maps Besar
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Gunakan linkMaps dari database jika ada, atau koordinat
                              // Disini saya asumsikan di model CampusSpot ada field `linkMaps` (String?)
                              // Jika belum ada di model, gunakan logika koordinat fallback
                              // (Karena di provider/model kamu belum ada field linkMaps, saya pakai koordinat)
                              
                              // TODO: Update model CampusSpot untuk tampung linkMaps jika mau ambil dari DB
                              _openGoogleMaps(null); 
                            },
                            icon: const Icon(Icons.map, color: Colors.white, size: 20),
                            label: const Text("Rute"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- TOMBOL LIHAT RUANGAN (KHUSUS GEDUNG) ---
                    if (isBuilding) ...[
                      Material(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuildingRoomsScreen(spotName: currentSpot.name),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.meeting_room_outlined, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Daftar Ruangan",
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                      Text(
                                        "Lihat denah lantai & ruang",
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- INFO PENTING ---
                    _buildInfoSection("Informasi", [
                      _buildInfoRow(Icons.access_time, "Jam Operasional", 
                          currentSpot.operatingHours.isNotEmpty ? currentSpot.operatingHours : "24 Jam"),
                      _buildInfoRow(Icons.location_on, "Alamat", currentSpot.address),
                    ]),

                    const SizedBox(height: 24),

                    // --- DESKRIPSI ---
                    Text("Tentang Tempat Ini", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      currentSpot.description,
                      style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: Colors.grey.shade700),
                    ),

                    const SizedBox(height: 24),

                    // --- FASILITAS ---
                    if (currentSpot.facilities.isNotEmpty) ...[
                      Text("Fasilitas Tersedia", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: currentSpot.facilities.map((f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          side: BorderSide.none,
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const Divider(thickness: 1, height: 40),

                    // --- KOMENTAR SECTION ---
                    Row(
                      children: [
                        Text("Ulasan (${_comments.length})", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        // Bisa tambah tombol filter/sort disini
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Input Komentar Modern
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: "Bagikan pendapatmu...",
                                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                border: InputBorder.none,
                              ),
                              minLines: 1,
                              maxLines: 3,
                            ),
                          ),
                          IconButton(
                            onPressed: _isPostingComment ? null : _handlePostComment,
                            icon: _isPostingComment
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // List Komentar
                    if (_isLoadingComments)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text("Belum ada ulasan.", style: GoogleFonts.inter(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildCommentItem(_comments[index]);
                        },
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Item Komentar yang Cantik
  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['users_001'] ?? {};
    final username = user['username'] ?? 'Pengguna';
    final photoUrl = user['foto_profile'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde';
    final content = comment['content'] ?? '';
    final createdAt = DateTime.tryParse(comment['created_at'].toString()) ?? DateTime.now();
    final isMyComment = _supabaseService.currentUser?.id == comment['user_id'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(photoUrl),
          backgroundColor: Colors.grey.shade200,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(username, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    "${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}",
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                content, 
                style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: Colors.grey.shade800),
              ),
              if (isMyComment)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _handleDeleteComment(comment['id']),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text("Hapus", style: GoogleFonts.inter(fontSize: 12, color: Colors.red)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}