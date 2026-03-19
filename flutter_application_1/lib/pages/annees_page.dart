import 'package:flutter/material.dart';
import 'fiche_annee_page.dart';

class AnneesPage extends StatelessWidget {
  final int debut;
  final int fin;
  final Color couleur;

  const AnneesPage({super.key, required this.debut, required this.fin, required this.couleur});

  @override
  Widget build(BuildContext context) {
    // Génère la liste des années (ex: de 2026 à 2020 pour l'ordre décroissant)
    List<int> annees = List.generate(fin - debut + 1, (index) => fin - index);

    return Scaffold(
      backgroundColor: const Color(0xFF05001E),
      appBar: AppBar(
        title: Text(
          "ÉDITIONS $debut - $fin",
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: const Color(0xFF1A1440),
        elevation: 0, // AppBar plate pour plus de modernité
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: annees.length,
        itemBuilder: (context, index) {
          int annee = annees[index];
          return _buildAnneeListItem(context, annee, couleur);
        },
      ),
    );
  }

  Widget _buildAnneeListItem(BuildContext context, int annee, Color couleur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15), // Espacement entre les années
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FicheAnneePage(annee: annee, couleur: couleur),
            )
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 70, // Hauteur fixe pour l'item
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1440),
            borderRadius: BorderRadius.circular(15),
            // Effet de bordure néon discret
            border: Border.all(color: couleur.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: couleur.withOpacity(0.03), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Année en gros
              Text(
                "$annee",
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 26, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              // Icône d'ouverture
              Icon(Icons.arrow_forward_ios_rounded, color: couleur.withOpacity(0.7), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}