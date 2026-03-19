import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // AJOUTÉ

class Participant {
  final String country;
  final String countryCode;
  final String artist;
  final String song;
  int points;

  Participant({
    required this.country, 
    required this.countryCode, 
    required this.artist, 
    required this.song, 
    this.points = 0
  });
}

class ClassementPage extends StatefulWidget {
  final List<Participant>? donneesInitiales;
  const ClassementPage({super.key, this.donneesInitiales});

  @override
  State<ClassementPage> createState() => _ClassementPageState();
}

class _ClassementPageState extends State<ClassementPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  List<Participant> participants = [];
  bool isLoading = true;
  final List<int> pointsEurovision = [12, 10, 8, 7, 6, 5, 4, 3, 2, 1, 0];

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  // --- COULEURS DU PODIUM ---
  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // OR
    if (index == 1) return const Color(0xFFC0C0C0); // ARGENT
    if (index == 2) return const Color(0xFFCD7F32); // BRONZE
    return Colors.white38; 
  }

  // --- STYLE NEON CYAN (Pour les chansons) ---
  TextStyle _neonCyanStyle({double fontSize = 10}) {
    return TextStyle(
      color: Colors.cyanAccent,
      fontSize: fontSize,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w600,
      shadows: [
        Shadow(color: Colors.cyanAccent.withOpacity(0.7), blurRadius: 6),
      ],
    );
  }

  // --- STYLE NEON ROSE (Pour les artistes) ---
  TextStyle _neonPinkStyle({double fontSize = 10, bool isGray = false}) {
    if (isGray) return TextStyle(color: Colors.white24, fontSize: fontSize, letterSpacing: 0.5);
    
    return TextStyle(
      color: const Color(0xFFFE0191),
      fontSize: fontSize,
      letterSpacing: 0.7,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: const Color(0xFFFE0191).withOpacity(0.7), blurRadius: 6),
      ],
    );
  }

  Future<void> _chargerDonnees() async {
    if (widget.donneesInitiales != null) {
      setState(() {
        participants = List.from(widget.donneesInitiales!);
        isLoading = false;
      });
      return;
    }
    _fetchFromServer('participants');
  }

  Future<void> _trierAvecAnimation() async {
    bool swapped = true;
    while (swapped) {
      swapped = false;
      for (int i = 0; i < participants.length - 1; i++) {
        if (participants[i].points < participants[i + 1].points) {
          setState(() {
            final temp = participants[i];
            participants[i] = participants[i + 1];
            participants[i + 1] = temp;
          });
          swapped = true;
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }
    }
  }

  Future<void> _partagerTop10() async {
    try {
      List<Participant> sortedList = List.from(participants);
      sortedList.sort((a, b) => b.points.compareTo(a.points));
      final top10 = sortedList.take(10).toList();

      final widgetAPartager = Container(
        padding: const EdgeInsets.all(25),
        width: 380,
        color: const Color(0xFF05001E),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "MON TOP 10 - EUROVISION 2026",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(height: 20),
            ...top10.asMap().entries.map((entry) {
              int index = entry.key;
              Participant p = entry.value;
              Color rankColor = _getRankColor(index);
              bool notConfirmed = p.artist.toLowerCase().contains("confirmer") || p.artist.toLowerCase().contains("inconnu");

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1440),
                  borderRadius: BorderRadius.circular(8),
                  border: index < 3 ? Border.all(color: rankColor, width: 1.5) : null,
                ),
                child: Row(
                  children: [
                    Text("#${index + 1}", style: TextStyle(color: rankColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 15),
                    CountryFlag.fromCountryCode(p.countryCode, height: 15, width: 25),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.country, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(p.artist.toUpperCase(), style: _neonPinkStyle(fontSize: 8, isGray: notConfirmed)),
                          Row(
                            children: [
                              const Icon(Icons.music_note, color: Colors.cyanAccent, size: 9),
                              const SizedBox(width: 4),
                              Expanded(child: Text(p.song, style: _neonCyanStyle(fontSize: 9), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text("${p.points} pts", style: TextStyle(color: index < 3 ? rankColor : Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );

      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        Material(child: widgetAPartager), 
        delay: const Duration(milliseconds: 50)
      );

      if (imageBytes != null) {
        final XFile xFile = XFile.fromData(imageBytes, mimeType: 'image/png', name: 'mon_top10.png');
        await Share.shareXFiles([xFile], text: 'Voici mon Top 10 Eurovision 2026 ! #Eurovision #EuroVote');
      }
    } catch (e) {
      debugPrint("Erreur lors du partage : $e");
    }
  }

  // --- MODIFICATION ICI : ENVOI DES CLÉS API ---
  Future<void> _fetchFromServer(String route) async {
    setState(() => isLoading = true);
    try {
      // On récupère les clés enregistrées dans les SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final mistralKey = prefs.getString('mistral_api_key') ?? "";
      final serpKey = prefs.getString('serp_api_key') ?? "";

      // Remplace bien l'IP par celle de ton serveur Flask
      final url = Uri.parse('http://192.168.1.2:5000/api/$route');
      
      final response = await http.get(
        url,
        headers: {
          "X-Mistral-Key": mistralKey,
          "X-SerpApi-Key": serpKey,
        },
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        _decoderJson(response.body);
      } else {
        _chargerSecours();
        // Optionnel : Afficher l'erreur exacte du serveur (ex: clés manquantes)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Serveur : ${response.body}"))
        );
      }
    } catch (e) {
      _chargerSecours();
    }
  }

  void _decoderJson(String rawJson) {
    final List<dynamic> data = json.decode(rawJson);
    Map<String, int> pointsExistants = {for (var p in participants) p.countryCode: p.points};

    setState(() {
      participants = data.map((item) {
        String code = item['countryCode'] ?? 'EU';
        return Participant(
          country: item['country'] ?? '?',
          countryCode: code,
          artist: item['participant'] ?? 'À confirmer',
          song: item['song'] ?? 'Titre à confirmer',
          points: pointsExistants[code] ?? 0,
        );
      }).toList();

      participants.sort((a, b) => a.country.compareTo(b.country));
      isLoading = false;
    });
  }

  void _chargerSecours() {
    setState(() {
      participants = [Participant(country: "Erreur Serveur", countryCode: "FR", artist: "À confirmer", song: "Pas de connexion")];
      isLoading = false;
    });
  }

  void _sauvegarderMonTop() {
    var box = Hive.box('mes_classements');
    List<Map<String, dynamic>> toSave = participants.map((p) => {
      'country': p.country,
      'countryCode': p.countryCode,
      'participant': p.artist,
      'song': p.song,
      'points': p.points,
    }).toList();
    
    String nomSauvegarde = "Top_${DateTime.now().day}_${DateTime.now().hour}h${DateTime.now().minute}";
    box.put(nomSauvegarde, toSave);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: const Color(0xFFFE0191), content: Text("Top sauvegardé : $nomSauvegarde"))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05001E),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("EUROVISION 2026", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1440),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.cyanAccent), onPressed: _partagerTop10),
          IconButton(icon: const Icon(Icons.leaderboard, color: Colors.amberAccent), onPressed: _trierAvecAnimation),
          IconButton(icon: const Icon(Icons.cloud_sync, color: Colors.cyanAccent), onPressed: () => _fetchFromServer('refresh')),
          IconButton(icon: const Icon(Icons.save, color: Color(0xFFFE0191)), onPressed: _sauvegarderMonTop),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFE0191)))
        : ReorderableListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            itemCount: participants.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = participants.removeAt(oldIndex);
                participants.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final p = participants[index];
              final rankColor = _getRankColor(index);
              final isTop3 = index < 3;
              bool isNotConfirmed = p.artist.toLowerCase().contains("confirmer") || p.artist.toLowerCase().contains("inconnu");
              
              return AnimatedContainer(
                key: ValueKey(p.countryCode),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutBack,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Card(
                  color: const Color(0xFF1A1440),
                  elevation: isTop3 ? 12 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isTop3 ? BorderSide(color: rankColor, width: 2) : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: SizedBox(
                      width: 55,
                      child: Row(
                        children: [
                          Text(
                            "${index + 1}",
                            style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CountryFlag.fromCountryCode(p.countryCode, height: 20, width: 30),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      p.country,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.artist.toUpperCase(),
                          style: _neonPinkStyle(isGray: isNotConfirmed),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.cyanAccent, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.song,
                                style: _neonCyanStyle(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF05001E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isTop3 ? rankColor.withOpacity(0.5) : Colors.white10),
                      ),
                      child: DropdownButton<int>(
                        value: p.points,
                        underline: const SizedBox(),
                        dropdownColor: const Color(0xFF1A1440),
                        icon: Icon(Icons.arrow_drop_down, color: isTop3 ? rankColor : const Color(0xFFFE0191), size: 20),
                        items: pointsEurovision.map((v) => DropdownMenuItem(
                          value: v, 
                          child: Text(
                            "$v pts", 
                            style: TextStyle(
                              color: v == 12 ? Colors.amberAccent : Colors.white,
                              fontSize: 13,
                              fontWeight: v == 12 ? FontWeight.bold : FontWeight.normal,
                            ),
                          )
                        )).toList(),
                        onChanged: (val) {
                          setState(() => p.points = val!);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}