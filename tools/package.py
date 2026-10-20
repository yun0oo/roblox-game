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
instructions = '''UNDERWATER EGG — NÉRÉIDE · RÉCIFS, CUVE & MODÈLES MARINS

1. Extraire ce ZIP dans un nouveau dossier.
2. Ouvrir le fichier UnderwaterEgg.rbxl avec Roblox Studio sur Windows/macOS.
3. Appuyer sur F5 (Play) pour jouer avec son personnage Roblox.
4. Attendre le chargement : votre galerie est sur le navire NÉRÉIDE.
   Retrouvez votre portrait et votre pseudo au-dessus de votre aquarium.
5. Rejoindre le bassin central : tous les joueurs plongent et remontent ici.
   Utiliser les échelles pour revenir sur le pont.
6. Explorer vers le bas : un boss géant surveille chaque palier.
   E près d’un œuf l’ajoute à votre inventaire NON SÉCURISÉ.
   Aucun œuf n’est attaché au personnage : sa rareté colore le plongeur.
   Un harpon peut faire tomber cet œuf pour permettre son vol.
7. Rejoindre sa propre galerie sécurise définitivement l’œuf.
   Déposer ensuite l’œuf de l’inventaire au terminal devant
   la cuve vitrée avec E, ou utiliser Collection > Déposer.
   Les œufs incubent dans leur cuve ; les animaux rejoignent le grand aquarium.
8. Attendre l'éclosion : l'animal nage dans l'aquarium et produit des gold.
   Dépenser ces gold chez les 7 marchands spécialisés sur le pont.
   E à un stand ouvre sa boutique : prix et effets avant achat.
   E à votre ordinateur ouvre les destinations : choisissez un marchand
   pour être téléporté devant son stand. Le transfert est gratuit.
9. F à la pancarte dorée de sa galerie améliore la base et l’aquarium.
   Cette pancarte est séparée du dépôt des œufs.

Toutes les profondeurs sont ouvertes, même sans le niveau conseillé. Attention :
les monstres mythologiques sont géants et de plus en plus rapides en profondeur.
Ils gagnent encore en vitesse et dégâts si votre combinaison est insuffisante.

Incubation : Common 15 s, Rare 40 s, Epic 90 s, Legendary 3 min,
Mythic 6 min, Secret 12 min. La couleur de l'aura indique la rareté de l'œuf.
Avec une vraie sauvegarde, une reconnexion ne remet pas le délai à zéro.

Aucune case API à cocher pour cette partie de test. Une session locale non
publiée est temporaire : sa progression ne sera pas sauvegardée.

Commandes : commandes Roblox / WASD pour nager, Espace pour monter,
Ctrl pour descendre, Maj pour accélérer, clic gauche pour tirer,
M pour bloquer/libérer la caméra (viseur centré).
E près d’un œuf pour le mettre dans l’inventaire, au terminal pour le déposer,
ou chez un marchand pour sa boutique. F à la pancarte améliore la base.

Pour conserver la progression : publier une expérience privée, puis autoriser
l'accès Studio aux services API dans les paramètres de l'expérience.

Nouveautés : fonds sableux continus dans les six profondeurs (récif à 325 m),
passages centraux ouverts, parois entièrement habillées, herbiers denses,
éponges bleues creuses et plateaux de corail rose. Plus de 60 jardins par zone.
Marchands en armures à gemmes et or, coiffures et accessoires propres à chacun.
Interface bleu/cyan : cartes hexagonales, onglets Animaux/Œufs/Bestiaire,
grand aperçu détaillé et pagination. M = caméra, Maj = boost.
15 modèles marins Quaternius CC0 intégrés, nouveaux boss,
coraux ramifiés/gorgones/plateaux, récif sans carré flottant,
cuve à œufs séparée, ordinateur de téléportation et nage R6/R15 retravaillée.
7 marchands, boutique avec aperçu 3D et comparaison des niveaux,
pancarte de base séparée, équipements visibles sur le personnage, style Roblox
plus coloré, aquariums lumineux, œufs géants et un seul boss par profondeur.
Le harpon vole les œufs NON SÉCURISÉS : le tir les fait tomber, puis E les
récupère. Les œufs arrivés dans leur propre base restent protégés à jamais.
Un viseur suit la souris en mode libre et reste centré en mode caméra M.
Les bases ont cinq niveaux : achat près de la pancarte avec vos gold.
Les modèles sont intégrés : aucun import manuel n'est requis.

Correction incluse : démarrage sans DataStore dans un fichier non publié,
suppression d'une écriture réservée à Studio qui arrêtait la carte, apparition
et réapparition automatiques des avatars, message de chargement et d'erreur.

Les sources et tests sont sur https://github.com/yun0oo/roblox-game/tree/codex/underwater-egg
Les contrôles automatisés ne remplacent pas un essai natif dans Roblox Studio.
'''
with zipfile.ZipFile(downloads / 'UnderwaterEgg.zip', 'w', zipfile.ZIP_DEFLATED) as package:
    package.write(source, source.name)
    package.writestr('LIRE-MOI.txt', instructions.encode('utf-8'))
    package.write(ROOT / 'assets/CREDITS.md', 'CREDITS-MODELES.md')
with zipfile.ZipFile(downloads / 'UnderwaterEgg.zip') as package:
    assert package.testzip() is None
    assert package.read(source.name) == source.read_bytes()
print('Packaged downloads/UnderwaterEgg.zip and downloads/UnderwaterEgg.rbxl')
