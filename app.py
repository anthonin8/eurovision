from flask import Flask, jsonify, request
from flask_cors import CORS
import requests
import json
import re
import os

app = Flask(__name__)
CORS(app)

# Nom du fichier pour stocker les derniers participants trouvés (cache)
SAVE_FILE = "eurovision_cache.json"

# ==========================================================
# LOGIQUE DE RECHERCHE IA (AVEC CLÉS DYNAMIQUES)
# ==========================================================

def logic_ia_recherche(mistral_key, serpapi_key):
    try:
        print("\n--- APPEL IA + GOOGLE (CONSOMMATION DE CLÉS DE L'UTILISATEUR) ---")
        
        # 1. RECHERCHE GOOGLE VIA SERPAPI
        params = {
            "q": "(site:eurovisionworld.com OR site:eurovision.tv) Eurovision 2026 participants songs",
            "api_key": serpapi_key,
            "engine": "google",
            "num": 10
        }
        
        search_res = requests.get("https://serpapi.com/search", params=params, timeout=15).json()
        
        # Vérification si SerpApi renvoie une erreur (clé invalide, quota dépassé...)
        if "error" in search_res:
            print(f"⚠️ Erreur SerpApi : {search_res['error']}")
            return None

        results = search_res.get("organic_results", [])
        context = " ".join([res.get("snippet", "") for res in results])

        if not context:
            print("⚠️ Aucun résultat trouvé sur Google.")
            return None

        # 2. GÉNÉRATION VIA MISTRAL AI
        mistral_url = "https://api.mistral.ai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {mistral_key}", 
            "Content-Type": "application/json"
        }
        
        prompt = (
            f"CONTEXTE : {context}\n\n"
            "Tu es un expert Eurovision. Analyse les infos des sites officiels.\n"
            "MISSION : Extraire la liste des participants 2026.\n"
            "RÈGLES :\n"
            "- Ignore les pays bannis (Russie, Biélorussie).\n"
            "- Pour chaque pays, trouve l'ARTISTE et la CHANSON.\n"
            "- Si une info manque, écris 'À confirmer'.\n"
            "- Supprime les mentions comme '(Big-5)' ou '(Host)'.\n"
            "- Traduis les noms des pays en Français.\n\n"
            "FORMAT JSON STRICT : [{'country': '...', 'countryCode': '...', 'participant': '...', 'song': '...'}]"
        )

        payload = {
            "model": "mistral-tiny", 
            "messages": [{"role": "user", "content": prompt}], 
            "temperature": 0.1
        }
        
        res = requests.post(mistral_url, json=payload, headers=headers, timeout=25)
        res_data = res.json()
        
        # Vérification si Mistral renvoie une erreur
        if 'choices' not in res_data:
            print(f"❌ Erreur Mistral : {res_data.get('error', 'Inconnue')}")
            return None

        raw_text = res_data['choices'][0]['message']['content']
        
        # Extraction du JSON dans la réponse de l'IA
        json_match = re.search(r'\[\s*\{.*\}\s*\]', raw_text, re.DOTALL)
        if json_match:
            data = json.loads(json_match.group())
            # On sauvegarde pour éviter de repayer une requête au prochain lancement
            with open(SAVE_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=4, ensure_ascii=False)
            print(f"✅ Succès : {len(data)} pays trouvés.")
            return data
        else:
            print("❌ Mistral n'a pas renvoyé un JSON valide.")
            return None

    except Exception as e:
        print(f"🔥 Erreur critique IA : {e}")
        return None

# ==========================================================
# ROUTES API
# ==========================================================

@app.route('/api/participants', methods=['GET'])
def get_participants():
    # Si on a déjà une sauvegarde locale, on la donne direct (c'est gratuit)
    if os.path.exists(SAVE_FILE):
        print("📁 Chargement de la sauvegarde locale (Gratuit)")
        with open(SAVE_FILE, "r", encoding="utf-8") as f:
            return jsonify(json.load(f))
    
    # Sinon, on tente de rafraîchir (nécessite les headers)
    return refresh_data()

@app.route('/api/refresh', methods=['GET'])
def refresh_data():
    # On récupère les clés envoyées par Flutter dans les Headers
    mistral_key = request.headers.get('X-Mistral-Key')
    serpapi_key = request.headers.get('X-SerpApi-Key')

    if not mistral_key or not serpapi_key:
        print("❌ Requête refusée : Clés API manquantes dans les headers.")
        return jsonify({"error": "Veuillez configurer vos clés API dans les réglages de l'application."}), 401

    data = logic_ia_recherche(mistral_key, serpapi_key)
    if data:
        return jsonify(data)
    
    return jsonify({"error": "Erreur lors de la récupération des données Eurovision."}), 500

# --- ARCHIVES & HISTORIQUE ---

@app.route('/api/eurovision/<int:year>', methods=['GET'])
def get_eurovision_year(year):
    try:
        url = f"https://eurovisionapi.runasp.net/api/senior/contests/{year}"
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            contestants_map = {c['id']: {
                "country": c.get("country"),
                "artist": c.get("artist"),
                "song": c.get("song")
            } for c in data.get('contestants', [])}

            final_round = next((r for r in data.get('rounds', []) if r['name'] == 'final'), None)
            participants_finaux = []

            if final_round:
                for p in final_round.get('performances', []):
                    c_id = p.get('contestantId')
                    info = contestants_map.get(c_id, {})
                    total_points = 0
                    if p.get('scores'):
                        score_obj = next((s for s in p['scores'] if s['name'] == 'total'), p['scores'][0])
                        total_points = score_obj.get('points', 0)

                    participants_finaux.append({
                        "rank": p.get("place"),
                        "country": info.get("country", "??"),
                        "artist": info.get("artist", "Inconnu"),
                        "song": info.get("song", "N/A"),
                        "points": total_points
                    })
            else:
                for c_id, info in contestants_map.items():
                    participants_finaux.append({
                        "rank": None, "country": info["country"], "artist": info["artist"],
                        "song": info["song"], "points": 0
                    })

            participants_finaux.sort(key=lambda x: (x['rank'] is None, x['rank'] or 999, -x['points']))

            return jsonify({
                "year": data.get("year"),
                "city": data.get("city"),
                "country_host": data.get("country"),
                "logo_url": data.get("logoUrl"),
                "winner": participants_finaux[0] if participants_finaux else {},
                "all_participants": participants_finaux
            })
            
        return jsonify({"error": "Année introuvable"}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)