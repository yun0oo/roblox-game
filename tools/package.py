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
instructions = '''UNDERWATER EGG — NÉRÉIDE · CARTE MODERNISÉE ET ŒUFS D’ÉVÉNEMENT

JOUER SUR WINDOWS / MACOS

1. Extraire ce ZIP dans un NOUVEAU dossier.
2. Ouvrir UnderwaterEgg.rbxl dans Roblox Studio.
3. Appuyer sur F5 / Play et attendre le chargement.
   Le personnage Roblox apparaît sur le navire, devant sa galerie.

PREMIÈRE EXPÉDITION

- Rejoindre le bassin central et plonger. Les deux filets servent à remonter.
- Explorer le récif : douze œufs apparaissent parmi quarante nids au sol.
  Un seul grand boss surveille chaque profondeur. E ramasse un œuf.
- L’œuf est dans l’inventaire, sans modèle derrière le personnage.
  La surbrillance du plongeur montre sa rareté. Un harpon peut le faire tomber.
- Revenir dans sa propre galerie sécurise définitivement l’œuf.
- E devant la cuve à œufs le met en incubation ; l’animal obtenu rejoint
  l’aquarium principal, sans coraux, et produit des gold.
- Acheter l’équipement avec E chez les sept marchands. L’ordinateur de sa
  galerie permet de choisir un marchand et de s’y téléporter gratuitement.
- F à la pancarte dorée améliore la base. Le socle reste sur le pont.

COMMANDES

Commandes Roblox / WASD : déplacement ; Espace : monter ; Ctrl : descendre.
Maj : boost. M : verrouiller/libérer la caméra. Clic gauche : harpon.
B ou ☰ : ouvrir/fermer les menus, y compris lorsque M est sélectionné.
E : interaction avec œuf, cuve, ordinateur ou marchand. F : améliorer la base.

NOUVEAUTÉS

Six panoramas réaménagés avec douze modèles de packs Kenney supplémentaires :
grottes de récif, épave avec canons et tonneaux, cité à arches et colonnes,
forêt de kelp, cavernes à cristaux bleu/violet et sanctuaire interdit.
Les sols sont continus, les passages ouverts, les nids posés sur le sable.
L’éclairage évolue en douceur et laisse les zones lisibles en profondeur.
Les modèles sont intégrés : aucun import manuel ou achat de skin requis.

Douze œufs sauvages par palier, soit soixante-douze pour toute la carte.
Les œufs ramassés et tombés ne consomment pas les douze emplacements sauvages.

ÉVÉNEMENTS ET REVENUS

Toutes les 5 minutes : petit événement et meilleures probabilités ordinaires.
Toutes les 15 minutes : événement majeur avec œufs TEMPÊTE.
Toutes les 40 minutes : tempête légendaire avec œufs TEMPÊTE et CÉLESTES.

Tempête : l’animal rapporte exactement dix fois le meilleur animal ordinaire
éclosable du même palier. Céleste : exactement dix fois l’animal Tempête.
Exemple au récif : Raie 100 gold/min → Raie des cyclones 1 000 →
Raie constellation 10 000, avant les mêmes bonus de base/fusion/prestige.
Le filtre ÉVÉNEMENT de la collection présente ces douze nouvelles créatures.

Un événement majeur garantit au moins un Tempête par palier ; la tempête
légendaire garantit aussi un Céleste. Ces raretés ne spawnent pas au calme.
Les œufs exclusifs sauvages non récupérés disparaissent avec l’événement ;
les œufs déjà ramassés restent transportables/volables, puis conservés une
fois sécurisés, même après l’événement ou une reconnexion sauvegardée.

Incubation : Common 15 s, Rare 40 s, Epic 90 s, Legendary 3 min,
Mythic 6 min, Secret 12 min, Tempête 15 min, Céleste 20 min.

Les six profondeurs restent accessibles sans le niveau conseillé, mais les
boss sont beaucoup plus rapides et dangereux avec une combinaison insuffisante.
Un bon équipement réduit la vitesse de poursuite ; toucher le boss au harpon
l’étourdit brièvement et interrompt sa capacité spéciale en préparation.

SAUVEGARDE ET VALIDATION

Un fichier Studio non publié démarre sans case API à cocher, en session
TEMPORAIRE explicitement marquée NON SAUVEGARDÉE. Pour conserver la progression,
publier une expérience privée et autoriser l’accès Studio aux services API.

Les tests automatisés du code, des services, des événements, des sauvegardes
simulées et de la construction réussissent. Le cloud Linux ne lance pas
Roblox Studio : rendu, collisions, test à huit joueurs et DataStore connecté
restent à valider dans Studio avant publication publique.

APERCU-CARTE-HORS-ROBLOX.png montre les géométries du jeu avec Blender.
C’est un rendu hors Roblox, pas une capture du jeu ni un test de performances.
Sources, modifications et licences : fichiers CREDITS et dossier LICENCES.

Sources : https://github.com/yun0oo/roblox-game/tree/codex/underwater-egg
Procédure de test Studio : docs/STUDIO_TESTS.md dans le dépôt.
'''
with zipfile.ZipFile(downloads / 'UnderwaterEgg.zip', 'w', zipfile.ZIP_DEFLATED) as package:
    package.write(source, source.name)
    package.writestr('LIRE-MOI.txt', instructions.encode('utf-8'))
    package.write(ROOT / 'assets/CREDITS.md', 'CREDITS-MODELES.md')
    package.write(ROOT / 'assets/MARINE_SCENERY_CREDITS.md', 'CREDITS-DECORS.md')
    package.write(ROOT / 'assets/MODERN_PACKS_CREDITS.md', 'CREDITS-PACKS-MODERNES.md')
    package.write(ROOT / 'docs/previews/map.png', 'APERCU-CARTE-HORS-ROBLOX.png')
    package.write(ROOT / 'assets/source/Aquarium.LICENSE.md', 'LICENCES/Aquarium-BSD-3-Clause.txt')
    package.write(ROOT / 'assets/source/PolyPizza.CC-BY-3.0.txt', 'LICENCES/PolyPizza-CC-BY-3.0.txt')
    package.write(ROOT / 'assets/source/PolyPizza.ATTRIBUTION.md', 'LICENCES/PolyPizza-Attribution.md')
    package.write(ROOT / 'assets/source/Kenney.LICENSE.txt', 'LICENCES/Kenney-CC0.txt')
    package.write(ROOT / 'assets/source/Kenney.README.md', 'LICENCES/Kenney-Provenance.md')
with zipfile.ZipFile(downloads / 'UnderwaterEgg.zip') as package:
    assert package.testzip() is None
    assert package.read(source.name) == source.read_bytes()
print('Packaged downloads/UnderwaterEgg.zip and downloads/UnderwaterEgg.rbxl')
