import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/core/services/supabase_service.dart';

class BuildingRoomsScreen extends StatefulWidget {
  final String spotName;
  final String? highlightRoomName;

  const BuildingRoomsScreen({
    super.key,
    required this.spotName,
    this.highlightRoomName,
  });

  @override
  State<BuildingRoomsScreen> createState() => _BuildingRoomsScreenState();
}

class _BuildingRoomsScreenState extends State<BuildingRoomsScreen> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    // Memanggil fungsi getRoomsByBuilding yang sudah kita buat sebelumnya
    // Pastikan di SupabaseService sudah ada method getRoomsByBuilding
    final rooms = await _supabaseService.getRoomsByBuilding(widget.spotName);
    if (mounted) {
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Grouping ruangan per lantai
    final Map<int, List<Map<String, dynamic>>> roomsByFloor = {};
    for (var room in _rooms) {
      final lantai = room['lantai'] as int? ?? 1;
      if (!roomsByFloor.containsKey(lantai)) {
        roomsByFloor[lantai] = [];
      }
      roomsByFloor[lantai]!.add(room);
    }
    final sortedFloors = roomsByFloor.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Daftar Ruangan - ${widget.spotName}',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.meeting_room_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada data ruangan.",
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedFloors.length,
                  itemBuilder: (context, index) {
                    final lantai = sortedFloors[index];
                    final roomsOnFloor = roomsByFloor[lantai]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Lantai
                        Container(
                          margin: EdgeInsets.only(
                              bottom: 12, top: index == 0 ? 0 : 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Lantai $lantai",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        // List Ruangan
                        ...roomsOnFloor
                            .map((room) => _buildRoomCard(room))
                            .toList(),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final isHighlighted = widget.highlightRoomName != null &&
        room['nama_ruang'].toString().toLowerCase() ==
            widget.highlightRoomName!.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Ubah warna background jika di-highlight
        color: isHighlighted
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: AppTheme.primaryColor, width: 2) // Border tebal
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.meeting_room, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['nama_ruang'] ?? 'Tanpa Nama',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (room['deskripsi'] != null &&
                    room['deskripsi'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      room['deskripsi'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
