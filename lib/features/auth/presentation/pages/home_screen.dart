import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicamp/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomePage(),
    PlaceholderWidget(title: 'Maps'),
    PlaceholderWidget(title: 'Favorites'),
    PlaceholderWidget(title: 'Notifications'),
    PlaceholderWidget(title: 'Profile'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Student!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              'University of Indonesia',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for spots, rooms, facilities...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // Quick Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('24', 'Open Spots'),
                  _buildStat('156', 'Total Spots'),
                  _buildStat('3', 'Events'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Categories
            Text(
              'Categories',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                final categories = [
                  {'icon': Icons.school, 'label': 'Class', 'color': Color(0xFF4CAF50)},
                  {'icon': Icons.restaurant, 'label': 'Food', 'color': Color(0xFFF44336)},
                  {'icon': Icons.wifi, 'label': 'WiFi', 'color': Color(0xFF2196F3)},
                  {'icon': Icons.sports_basketball, 'label': 'Sports', 'color': Color(0xFFFF9800)},
                  {'icon': Icons.local_library, 'label': 'Library', 'color': Color(0xFF9C27B0)},
                  {'icon': Icons.science, 'label': 'Lab', 'color': Color(0xFF009688)},
                  {'icon': Icons.local_parking, 'label': 'Parking', 'color': Color(0xFF795548)},
                  {'icon': Icons.more_horiz, 'label': 'More', 'color': Color(0xFF9E9E9E)},
                ];
                
                final category = categories[index];
                return Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: category['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category['icon'] as IconData,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Popular Spots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Spots',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See All',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Main Library',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Open until 21:00 • 2.4km',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.8',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.wifi, size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Icon(Icons.ac_unit, size: 16, color: Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
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
}

class PlaceholderWidget extends StatelessWidget {
  final String title;

  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '$title Page\nComing Soon',
            style: GoogleFonts.inter(
              fontSize: 20,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}