import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}
class _DiscoverScreenState extends State<DiscoverScreen> {
  String _userLevel = "Yeni";

  @override
  void initState() {
    super.initState();
    _fetchUserLevel();
  }

  void _fetchUserLevel() async {
    var userData = await AuthService().getUserData();
    if (userData != null) {
      setState(() {
        String rawLevel = userData['experience'] ?? "Yeni";
        if (rawLevel.isNotEmpty) {
          _userLevel = rawLevel[0].toUpperCase() + rawLevel.substring(1).toLowerCase();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Keşfet",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("$_userLevel Seviyesi İçin Özel"),
              const SizedBox(height: 16),

              // 1. BÖLÜM: STRATEJİ KARTLARI
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('strategies')
                    .where('level', isEqualTo: _userLevel)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var docs = snapshot.data!.docs;

                  return SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        return _buildImageStrategyCard(context, data);
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 35),
              _buildSectionTitle("Canlı Piyasa Takibi"),
              const SizedBox(height: 16),

              // 2. BÖLÜM: CANLI PİYASA LİSTESİ (Haberler yerine geldi)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('market').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  var coins = snapshot.data!.docs;

                  if (coins.isEmpty) {
                    return const Center(
                      child: Text("Piyasa verisi yükleniyor...", style: TextStyle(color: Colors.white38)),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222D), // Koyu uzman tema rengi
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: coins.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withOpacity(0.05),
                        indent: 20,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        var data = coins[index].data() as Map<String, dynamic>;

                        // isUp değerine göre renk belirleme
                        bool isUp = data['isUp'] ?? true;
                        Color statusColor = isUp ? Colors.greenAccent : Colors.redAccent;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                data['coin']?[0] ?? "C",
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          title: Text(
                            data['coin'] ?? "",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text("24s Değişim", style: TextStyle(color: Colors.white38, fontSize: 12)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                data['price'] ?? "0.00 \$",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                  Text(
                                    data['change'] ?? "%0.00",
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Yardımcı Widgetlar ---

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildImageStrategyCard(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => StrategyDetailScreen(
          title: data['title'] ?? "",
          description: data['content'] ?? "",
          image: data['image'],
        )));
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  data['image'] ?? "https://via.placeholder.com/300",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.3), Colors.transparent],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? "",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)]),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(data['subtitle'] ?? "",
                    style: const TextStyle(color: Colors.white70, fontSize: 13,
                        shadows: [Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2)]),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Strateji Detay Ekranı (Daire Geri Butonlu)
class StrategyDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String? image;

  const StrategyDetailScreen({super.key, required this.title, required this.description, this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            leading: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kBackgroundColor.withOpacity(0.5),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_double_arrow_left_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: image != null ? Image.network(image!, fit: BoxFit.cover) : Container(color: Colors.grey),
            ),
            backgroundColor: kBackgroundColor,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(description, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}