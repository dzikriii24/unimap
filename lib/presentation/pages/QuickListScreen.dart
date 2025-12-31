import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:unicamp/core/models/spot_model.dart';
import 'package:unicamp/core/providers/spot_provider.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/presentation/pages/spot_detail_screen.dart';

enum QuickListType { favorite, nearby, popular }

class QuickListScreen extends StatelessWidget {
  final QuickListType type;

  const QuickListScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SpotProvider>(context);
    
    String title;
    List<CampusSpot> dataList;
    IconData icon;
    Color color;

    // Tentukan Data & Judul berdasarkan Tipe
    switch (type) {
      case QuickListType.favorite:
        title = "Tempat Favorit";
        dataList = provider.getFavoriteSpots();
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      case QuickListType.popular:
        title = "Paling Populer";
        dataList = provider.getPopularSpots();
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case QuickListType.nearby:
        title = "Terdekat Dari Saya";
        dataList = provider.getNearbySpots();
        icon = Icons.near_me;
        color = Colors.blue;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: dataList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Belum ada data tempat.", style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                final spot = dataList[index];
                return _buildSpotCard(context, spot, type, index);
              },
            ),
    );
  }

  Widget _buildSpotCard(BuildContext context, CampusSpot spot, QuickListType type, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot)),
            );
          },
          child: Row(
            children: [
              // Gambar
              Hero(
                tag: 'quick_img_${spot.id}_${spot.tableName}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: spot.photoUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
                  ),
                ),
              ),
              
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Rank (Khusus Populer)
                      if (type == QuickListType.popular && index < 3)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "Top ${index + 1}",
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),

                      Text(
                        spot.name,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        spot.category.name,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              spot.address,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Icon Action (Khusus Favorit ada delete)
              if (type == QuickListType.favorite)
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    Provider.of<SpotProvider>(context, listen: false)
                        .toggleFavorite(spot.id, spot.tableName);
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}