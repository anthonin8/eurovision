import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class AnecdotesPage extends StatefulWidget {
  const AnecdotesPage({super.key});

  @override
  State<AnecdotesPage> createState() => _AnecdotesPageState();
}

class _AnecdotesPageState extends State<AnecdotesPage> {
  int score = 0;
  final Map<int, bool> questionsRepondues = {};
  final Map<int, bool> resultatsUtilisateur = {};
  
  List<Map<String, dynamic>> toutesLesAnecdotes = [];
  List<Map<String, dynamic>> questionsRestantes = []; // Le stock de questions non jouées
  List<Map<String, dynamic>> sessionQuestions = [];
  bool isLoading = true;
  bool afficheResultatFinal = false;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      final String response = await rootBundle.loadString('anecdotes.json');
      final data = await json.decode(response);
      setState(() {
        toutesLesAnecdotes = List<Map<String, dynamic>>.from(data);
        // On initialise la pioche avec toutes les anecdotes mélangées
        questionsRestantes = List.from(toutesLesAnecdotes);
        questionsRestantes.shuffle();
        
        _initialiserPartie();
        isLoading = false;
      });
    } catch (e) {
      print("Erreur de chargement JSON: $e");
    }
  }

  void _initialiserPartie() {
    setState(() {
      score = 0;
      questionsRepondues.clear();
      resultatsUtilisateur.clear();
      afficheResultatFinal = false;

      // Si la pioche est vide ou presque (moins de 10), on la recharge
      if (questionsRestantes.length < 10) {
        questionsRestantes = List.from(toutesLesAnecdotes);
        questionsRestantes.shuffle();
      }

      // On prend les 10 premières questions de la pioche
      sessionQuestions = questionsRestantes.take(10).toList();
      
      // On les retire de la pioche pour ne plus retomber dessus
      questionsRestantes.removeRange(0, 10);
    });
  }

  void _validerReponse(int index, bool choixUtilisateur) {
    if (questionsRepondues[index] == true) return;

    setState(() {
      questionsRepondues[index] = true;
      bool bonneReponse = sessionQuestions[index]['estVrai'] == choixUtilisateur;
      resultatsUtilisateur[index] = bonneReponse;
      if (bonneReponse) score += 10;
    });

    // Si c'est la dernière question (index 9), on lance le chrono avant l'écran de fin
    if (questionsRepondues.length == sessionQuestions.length) {
      Future.delayed(const Duration(milliseconds: 5000), () {
        if (mounted) {
          setState(() {
            afficheResultatFinal = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF05001E),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF05001E),
      body: Stack(
        children: [
          afficheResultatFinal 
            ? _buildEcranFin()
            : ScrollConfiguration(
                behavior: MyCustomScrollBehavior(),
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: sessionQuestions.length,
                  itemBuilder: (context, index) {
                    return TinderSwipeCard(
                      item: sessionQuestions[index],
                      index: index,
                      total: sessionQuestions.length,
                      dejaRepondu: questionsRepondues[index] ?? false,
                      aGagne: resultatsUtilisateur[index] ?? false,
                      onSwipeComplete: (isRight) => _validerReponse(index, isRight),
                    );
                  },
                ),
              ),
          
          if (!afficheResultatFinal) ...[
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amberAccent, width: 2),
                ),
                child: Text(
                  "SCORE: $score", 
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEcranFin() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 100),
          const SizedBox(height: 20),
          Text(
            "PARTIE TERMINÉE !", 
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          Text(
            "SCORE FINAL : $score / ${sessionQuestions.length * 10}", 
            style: GoogleFonts.montserrat(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w500)
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF00FF),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _initialiserPartie,
            child: Text(
              "REJOUER (10 NOUVELLES)", 
              style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "QUITTER", 
              style: GoogleFonts.montserrat(color: Colors.white54)
            ),
          )
        ],
      ),
    );
  }
}

class TinderSwipeCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final int total;
  final bool dejaRepondu;
  final bool aGagne;
  final Function(bool) onSwipeComplete;

  const TinderSwipeCard({
    super.key, 
    required this.item, 
    required this.index, 
    required this.total, 
    required this.dejaRepondu, 
    required this.aGagne, 
    required this.onSwipeComplete
  });

  @override
  State<TinderSwipeCard> createState() => _TinderSwipeCardState();
}

class _TinderSwipeCardState extends State<TinderSwipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _position = Offset.zero;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _angle = widget.dejaRepondu ? 0 : (_position.dx / screenWidth) * (math.pi / 12);
    double opaciteVerte = _position.dx > 0 ? (_position.dx / 100).clamp(0.0, 0.6) : 0.0;
    double opaciteRouge = _position.dx < 0 ? (_position.dx.abs() / 100).clamp(0.0, 0.6) : 0.0;

    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(opaciteRouge), 
                  Colors.transparent, 
                  Colors.greenAccent.withOpacity(opaciteVerte)
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onPanUpdate: (details) { if (!widget.dejaRepondu) setState(() => _position += details.delta); },
            onPanEnd: (details) {
              if (widget.dejaRepondu) return;
              if (_position.dx.abs() > 100) {
                final isRight = _position.dx > 0;
                final animation = Tween<Offset>(begin: _position, end: Offset.zero).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeOut)
                );
                animation.addListener(() { setState(() { _position = animation.value; _angle = 0; }); });
                _controller.forward(from: 0).then((_) => widget.onSwipeComplete(isRight));
              } else {
                final animation = Tween<Offset>(begin: _position, end: Offset.zero).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.elasticOut)
                );
                animation.addListener(() { setState(() { _position = animation.value; _angle = 0; }); });
                _controller.forward(from: 0);
              }
            },
            child: Transform.translate(
              offset: _position,
              child: Transform.rotate(
                angle: _angle,
                child: SizedBox(
                  width: screenWidth * 0.85,
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: Stack(
                    children: [
                      _buildCardContent(),
                      if (!widget.dejaRepondu) ...[
                        _buildStamp("VRAI", Colors.greenAccent, opaciteVerte, false),
                        _buildStamp("FAUX", Colors.redAccent, opaciteRouge, true),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 60,
          child: Column(
            children: [
              const Icon(Icons.bolt, color: Colors.cyanAccent, size: 30),
              const SizedBox(height: 5),
              Text(
                "${widget.index + 1}/${widget.total}", 
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStamp(String text, Color color, double opacite, bool aGauche) {
    if (opacite < 0.1) return const SizedBox.shrink();
    return Positioned(
      top: 40,
      left: aGauche ? 20 : null,
      right: aGauche ? null : 20,
      child: Transform.rotate(
        angle: aGauche ? -0.2 : 0.2,
        child: Opacity(
          opacity: opacite,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 4), 
              borderRadius: BorderRadius.circular(15)
            ),
            child: Text(
              text, 
              style: GoogleFonts.montserrat(color: color, fontSize: 32, fontWeight: FontWeight.w900)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    Color borderColor = !widget.dejaRepondu ? const Color(0xFFFF00FF) : (widget.aGagne ? Colors.greenAccent : Colors.redAccent);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(widget.dejaRepondu),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1440),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: borderColor, width: 4),
          boxShadow: [BoxShadow(color: borderColor.withOpacity(0.3), blurRadius: 20)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.item['titre']!, 
              style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Center(
                child: Text(
                  widget.dejaRepondu ? widget.item['reponse']! : widget.item['texte']!, 
                  textAlign: TextAlign.center, 
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                )
              )
            ),
            if (widget.dejaRepondu) Icon(widget.aGagne ? Icons.check_circle : Icons.cancel, color: borderColor, size: 60),
            const SizedBox(height: 20),
            Text(
              widget.dejaRepondu ? "SUIVANT ⬆️" : "⬅️ FAUX | VRAI ➡️", 
              style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 10, letterSpacing: 1.2)
            ),
          ],
        ),
      ),
    );
  }
}