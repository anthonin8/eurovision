import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/classement_page.dart';
import 'pages/sauvegardes_page.dart';
import 'pages/historique_page.dart';
import 'pages/anecdotes_page.dart';
import 'pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('mes_classements');
  runApp(const EurovisionApp());
}

class EurovisionApp extends StatelessWidget {
  const EurovisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eurovision Ranker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05001E),
        primaryColor: const Color(0xFFFE0191),
      ),
      home: const MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Le Stack permet de superposer le bouton Settings par-dessus le menu
      body: Stack(
        children: [
          // --- FOND ET MENU PRINCIPAL ---
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF05001E), Color(0xFF1A1440)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- LOGO ANIMÉ ---
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFE0191)
                                .withOpacity(0.4 * _animation.value),
                            blurRadius: 40 + (20 * _animation.value),
                            spreadRadius: 5 * _animation.value,
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity: 0.8 + (0.2 * _animation.value),
                        child: Image.asset(
                          'logo_coeur.webp',
                          width: 140,
                          height: 130,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.favorite,
                                color: Color(0xFFFE0191), size: 100);
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                const Text(
                  "EUROVISION",
                  style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white),
                ),
                Text(
                  "2026 EDITION",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: Colors.cyanAccent,
                    shadows: [
                      Shadow(
                          color: Colors.cyanAccent.withOpacity(0.8),
                          blurRadius: 10)
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // --- BOUTONS DU MENU ---
                _buildMenuButton(
                  context,
                  "COMMENCER LE CLASSEMENT",
                  Icons.play_arrow_rounded,
                  const Color(0xFFFE0191),
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ClassementPage())),
                ),

                const SizedBox(height: 20),

                _buildMenuButton(
                  context,
                  "MES SAUVEGARDES",
                  Icons.history_rounded,
                  Colors.cyanAccent,
                  () async {
                    final List<Participant>? resultat = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SauvegardesPage()));
                    if (resultat != null && context.mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ClassementPage(donneesInitiales: resultat)));
                    }
                  },
                ),

                const SizedBox(height: 20),

                _buildMenuButton(
                  context,
                  "HISTORIQUE DU CONCOURS",
                  Icons.emoji_events_rounded,
                  Colors.amberAccent,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoriquePage())),
                ),

                const SizedBox(height: 20),

                _buildMenuButton(
                  context,
                  "LE SAVIEZ-VOUS ?",
                  Icons.lightbulb_rounded,
                  const Color(0xFFBC13FE),
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AnecdotesPage())),
                ),
              ],
            ),
          ),

          // --- BOUTON PARAMÈTRES (SETTINGS) ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.cyanAccent,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget de bouton néon réutilisable
  Widget _buildMenuButton(BuildContext context, String text, IconData icon,
      Color color, VoidCallback onPressed) {
    return Container(
      width: 300,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1440),
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(text,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}