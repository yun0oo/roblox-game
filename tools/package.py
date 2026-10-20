#!/usr/bin/env python3
"""Publish the locally verified Studio build into the tracked download folder."""
from pathlib import Path
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / 'build/UnderwaterEgg.rbxl'
if not source.is_file() or not source.read_bytes().startswith(b'<roblox!'):
    raise SystemExit('Run python3 tools/check.py successfully before packaging.')
downloads = ROOT / 'downloads'
downloads.mkdir(exist_ok=True)
shutil.copyfile(source, downloads / source.name)
instructions = '''UNDERWATER EGG — ÎLES, AQUARIUMS ET GARDIENS MYTHOLOGIQUES

1. Extraire ce ZIP dans un nouveau dossier.
2. Ouvrir le fichier UnderwaterEgg.rbxl avec Roblox Studio sur Windows/macOS.
3. Appuyer sur F5 (Play) pour jouer avec son personnage Roblox.
4. Attendre le message de chargement. Le plongeur apparaît sur son île avec son
   harpon et son aquarium géant. Marcher jusqu'à la rampe pour plonger.
5. Explorer vers le bas et récupérer un œuf lumineux gardé par un monstre.
6. Remonter sur son île : l'œuf est sécurisé. Le déposer au terminal devant
   l'aquarium avec E, ou utiliser Collection > Déposer.
7. Attendre l'éclosion : l'animal nage dans l'aquarium et produit des gold.
   Dépenser ces gold dans l'atelier pour améliorer son équipement.

Toutes les profondeurs sont ouvertes, même sans le niveau conseillé. Attention :
les monstres mythologiques sont géants et de plus en plus rapides en profondeur.
Ils gagnent encore en vitesse et dégâts si votre combinaison est insuffisante.

Incubation : Common 15 s, Rare 40 s, Epic 90 s, Legendary 3 min,
Mythic 6 min, Secret 12 min. La couleur de l'aura indique la rareté de l'œuf.
Avec une vraie sauvegarde, une reconnexion ne remet pas le délai à zéro.

Aucune case API à cocher pour cette partie de test. Une session locale non
publiée est temporaire : sa progression ne sera pas sauvegardée.

Commandes : commandes Roblox / WASD pour nager, Espace pour monter,
Ctrl pour descendre, Shift pour accélérer, clic gauche pour tirer,
E près d'un œuf pour le transporter et au terminal de son île pour le déposer.

Pour conserver la progression : publier une expérience privée, puis autoriser
l'accès Studio aux services API dans les paramètres de l'expérience.

Correction incluse : démarrage sans DataStore dans un fichier non publié,
suppression d'une écriture réservée à Studio qui arrêtait la carte, apparition
et réapparition automatiques des avatars, message de chargement et d'erreur.

Les sources et tests sont sur https://github.com/yun0oo/roblox-game/tree/codex/underwater-egg
Les contrôles automatisés ne remplacent pas un essai natif dans Roblox Studio.
'''
with zipfile.ZipFile(downloads / 'UnderwaterEgg.zip', 'w', zipfile.ZIP_DEFLATED) as package:
    package.write(source, source.name)
    package.writestr('LIRE-MOI.txt', instructions.encode('utf-8'))
with zipfile.ZipFile(downloads / 'UnderwaterEgg.zip') as package:
    assert package.testzip() is None
    assert package.read(source.name) == source.read_bytes()
print('Packaged downloads/UnderwaterEgg.zip and downloads/UnderwaterEgg.rbxl')
