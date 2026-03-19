import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'classement_page.dart'; 

class SauvegardesPage extends StatelessWidget {
  const SauvegardesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('mes_classements');

    return Scaffold(
      backgroundColor: const Color(0xFF05001E),
      appBar: AppBar(
        title: const Text("Mes Archives"),
        backgroundColor: const Color(0xFF1A1440),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          if (b.isEmpty) {
            return const Center(
              child: Text("Aucune sauvegarde pour le moment", 
              style: TextStyle(color: Colors.white54))
            );
          }

          return ListView.builder(
            itemCount: b.length,
            itemBuilder: (context, index) {
              String nomCle = b.keyAt(index);
              return Card(
                color: const Color(0xFF1A1440),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFFFE0191)),
                  title: Text(nomCle, style: const TextStyle(color: Colors.white)),
                  subtitle: const Text("Cliquez pour recharger", style: TextStyle(color: Colors.white38)),
                  
                  onTap: () {
                    List rawData = b.get(nomCle);
                    
                    // On reconstruit les objets avec les bonnes clés JSON
                    List<Participant> listeChargee = rawData.map((item) {
                      return Participant(
                        country: item['country'] ?? 'Inconnu',
                        countryCode: item['countryCode'] ?? 'EU', // 'countryCode' et pas 'code'
                        artist: item['participant'] ?? 'À confirmer',
                        song: item['song'] ?? 'TBA',
                        points: item['points'] ?? 0,
                      );
                    }).toList();

                    Navigator.pop(context, listeChargee);
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => b.deleteAt(index),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}