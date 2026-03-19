import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // Import pour les liens

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _mistralController = TextEditingController();
  final TextEditingController _serpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  // Fonction pour ouvrir les liens web
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir $url');
    }
  }

  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mistralController.text = prefs.getString('mistral_api_key') ?? "";
      _serpController.text = prefs.getString('serp_api_key') ?? "";
    });
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mistral_api_key', _mistralController.text.trim());
    await prefs.setString('serp_api_key', _serpController.text.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Clés API sauvegardées avec succès !")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05001E),
      appBar: AppBar(
        title: const Text("CONFIGURATION API", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION MISTRAL ---
            _buildHeader("Mistral AI", "Utilisé pour la génération des textes."),
            _buildTextField(_mistralController, "Clé Mistral API..."),
            _buildLinkButton("Créer une clé Mistral gratuite ↗", "https://console.mistral.ai/api-keys/"),
            
            const SizedBox(height: 30),
            
            // --- SECTION SERPAPI ---
            _buildHeader("SerpApi", "Utilisé pour les recherches web Google."),
            _buildTextField(_serpController, "Clé SerpApi..."),
            _buildLinkButton("Obtenir une clé SerpApi ↗", "https://serpapi.com/dashboard"),

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF00FF),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _saveKeys,
                child: const Text("ENREGISTRER MES CLÉS", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Petit bouton de lien discret
  Widget _buildLinkButton(String label, String url) {
    return TextButton(
      onPressed: () => _launchURL(url),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: Text(
        label,
        style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, decoration: TextDecoration.underline),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}