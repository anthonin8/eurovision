import 'package:flutter/material.dart';
import 'annees_page.dart';

class HistoriquePage extends StatelessWidget {
  const HistoriquePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> decennies = [
      {"label": "LES ANNÉES 2020", "start": 2020, "end": 2026, "color": const Color(0xFFFE0191)},
      {"label": "LES ANNÉES 2010", "start": 2010, "end": 2019, "color": Colors.cyanAccent},
      {"label": "LES ANNÉES 2000", "start": 2000, "end": 2009, "color": Colors.amberAccent},
      {"label": "LES ANNÉES 90", "start": 1990, "end": 1999, "color": Colors.purpleAccent},
      {"label": "LES ANNÉES 80", "start": 1980, "end": 1989, "color": Colors.orangeAccent},
      {"label": "LES ANNÉES 70", "start": 1970, "end": 1979, "color": Colors.greenAccent},
      {"label": "LES ANNÉES 60", "start": 1960, "end": 1969, "color": Colors.blueAccent},
      {"label": "LES ANNÉES 50", "start": 1956, "end": 1959, "color": Colors.redAccent},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF05001E),
      appBar: AppBar(
        title: const Text("ARCHIVES EUROVISION", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1440),
        elevation: 10,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "DÉCOUVREZ L'HISTOIRE DU CONCOURS",
              style: TextStyle(color: Colors.white70, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: decennies.length,
                itemBuilder: (context, index) {
                  final d = decennies[index];
                  return _buildDecadeCard(
                    context,
                    label: d['label'],
                    range: "${d['start']} - ${d['end']}",
                    color: d['color'],
                    debut: d['start'], // Nouvel argument
                    fin: d['end'],     // Nouvel argument
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecadeCard(BuildContext context, {
    required String label, 
    required String range, 
    required Color color,
    required int debut, // Ajouté
    required int fin,   // Ajouté
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnneesPage(
                debut: debut,
                fin: fin,
                couleur: color,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A1440), const Color(0xFF05001E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label, 
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)
                  ),
                  Text(
                    range, 
                    style: TextStyle(color: color.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              Icon(Icons.auto_stories_rounded, color: color, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}