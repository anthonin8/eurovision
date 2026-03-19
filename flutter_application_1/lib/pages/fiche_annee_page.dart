import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // <--- L'import indispensable

class FicheAnneePage extends StatefulWidget {
  final int annee;
  final Color couleur;

  const FicheAnneePage({super.key, required this.annee, required this.couleur});

  @override
  State<FicheAnneePage> createState() => _FicheAnneePageState(); // <--- Corrigé ici
}

class _FicheAnneePageState extends State<FicheAnneePage> { // <--- Corrigé ici (un seul _)
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchYearData();
  }

  // --- FONCTION POUR OUVRIR YOUTUBE ---
  Future<void> _ouvrirYouTube(String artiste, String chanson) async {
    final String query = Uri.encodeComponent("Eurovision ${widget.annee} $artiste $chanson");
    final Uri url = Uri.parse("https://www.youtube.com/results?search_query=$query");
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Impossible de lancer $url');
      }
    } catch (e) {
      debugPrint("Erreur YouTube: $e");
    }
  }

  Future<void> _fetchYearData() async {
    try {
      // Note: localhost pour Chrome, 10.0.2.2 pour Émulateur Android
      final response = await http.get(Uri.parse('http://localhost:5000/api/eurovision/${widget.annee}'));
      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; data = null; });
    }
  }

  // --- FONCTION MAGIQUE POUR LES DRAPEAUX ---
  // Transforme un code pays (ex: 'FR') en émoji drapeau (ex: 🇫🇷)
  String _getCountryFlag(String countryCode) {
    if (countryCode == "??") return "🏳️"; // Drapeau blanc si inconnu
    if (countryCode.length != 2) return "🏳️"; // Sécurité si le code est mal formé

    String base = countryCode.toUpperCase();
    int firstChar = base.codeUnitAt(0) - 0x41 + 0x1F1E6;
    int secondChar = base.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
  }

  Color _getBorderColor(int position) {
    if (position == 1) return const Color(0xFFFFD700); // OR
    if (position == 2) return const Color(0xFFC0C0C0); // ARGENT
    if (position == 3) return const Color(0xFFCD7F32); // BRONZE
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05001E),
      appBar: AppBar(
        title: Text("ÉDITION ${widget.annee}", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1440),
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : data == null 
          ? const Center(child: Text("Erreur de chargement", style: TextStyle(color: Colors.white)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // LOGO
                  if (data!['logo_url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Image.network(data!['logo_url'], height: 100, fit: BoxFit.contain),
                    ),

                  // LA GRANDE CARTE NÉON OR (Rendue cliquable)
                  GestureDetector(
                    onTap: () => _ouvrirYouTube(data!['winner']['artist'], data!['winner']['song']),
                    child: _buildGrandeCarteGagnantNeon(),
                  ),

                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("CLASSEMENT COMPLET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 15),

                  // LISTE DES PARTICIPANTS AVEC DRAPEAUX
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data!['all_participants'].length,
                    itemBuilder: (context, index) {
                      final p = data!['all_participants'][index];
                      final position = index + 1;
                      final borderColor = _getBorderColor(position);
                      // On récupère le code pays de l'API (ex: 'FR')
                      final countryCode = p['country'] ?? "??";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _ouvrirYouTube(p['artist'], p['song']),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1440),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: borderColor != Colors.transparent ? borderColor : Colors.white10, width: borderColor != Colors.transparent ? 2 : 0.5),
                            ),
                            child: Row(
                              children: [
                                // Position et Numéro
                                Text("$position.", style: TextStyle(color: borderColor != Colors.transparent ? borderColor : Colors.white24, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 15),
                                
                                // --- AJOUT DU DRAPEAU ---
                                Text(
                                  _getCountryFlag(countryCode),
                                  style: const TextStyle(fontSize: 26), // Drapeau assez grand pour être lisible
                                ),
                                const SizedBox(width: 15),

                                // Infos Pays / Artiste / Chanson
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Pays en blanc simple
                                      Text(
                                        countryCode, // On affiche le code pays pour le moment
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      // ARTISTE EN ROSE NÉON
                                      Text(
                                        p['artist'] ?? "N/A",
                                        style: const TextStyle(
                                          color: Color(0xFFFF00FF), 
                                          fontSize: 14, 
                                          shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 8)],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // CHANSON EN CYAN NÉON AVEC ICÔNE
                                      Row(
                                        children: [
                                          const Icon(Icons.music_note, color: Colors.cyanAccent, size: 14),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              p['song'] ?? "N/A",
                                              style: const TextStyle(
                                                color: Colors.cyanAccent, 
                                                fontSize: 13, 
                                                fontStyle: FontStyle.italic,
                                                shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Points
                                Text("${p['points']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Fonction spécifique pour dessiner la carte Or Néon
  Widget _buildGrandeCarteGagnantNeon() {
    final winner = data!['winner'];
    final Color colorOr = const Color(0xFFFFD700); // OR
    final String winnerCountryCode = winner['country'] ?? "??";
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        // Le dégradé
        gradient: LinearGradient(
          colors: [
            colorOr.withOpacity(0.35), // Haut gauche
            const Color(0xFF05001E),    // Bas droite
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        // La bordure
        border: Border.all(color: colorOr, width: 2.5),
        // L'effet de lueur
        boxShadow: [
          BoxShadow(
            color: colorOr.withOpacity(0.4), 
            blurRadius: 20, 
            spreadRadius: 2
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre Or avec petite lueur
          Text(
            "🏆 GAGNANT ÉDITION ${data!['year']}", 
            style: TextStyle(
              color: colorOr, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 2,
              shadows: [Shadow(color: colorOr, blurRadius: 5)],
            ),
          ),
          const SizedBox(height: 15),
          // Artiste Rose Néon
          Text(
            winner['artist'] ?? "", 
            textAlign: TextAlign.center, 
            style: const TextStyle(
              color: Color(0xFFFF00FF), 
              fontSize: 26, 
              fontWeight: FontWeight.w900, 
              shadows: [Shadow(color: Color(0xFFFF00FF), blurRadius: 12)],
            ),
          ),
          const SizedBox(height: 5),
          // Chanson Cyan Néon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, color: Colors.cyanAccent, size: 20),
              Text(
                " « ${winner['song']} »", 
                style: const TextStyle(
                  color: Colors.cyanAccent, 
                  fontSize: 18, 
                  fontStyle: FontStyle.italic, 
                  shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Infos blanches et dorées AVEC LE DRAPEAU
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getCountryFlag(winnerCountryCode),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Text(
                "$winnerCountryCode • ${winner['points']} POINTS", 
                style: const TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 16
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}