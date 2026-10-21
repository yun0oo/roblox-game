# Modèles et licences

Les modèles sont fournis dans le dépôt et convertis en données numériques pour le jeu. Aucun script provenant d'un modèle téléchargé n'est exécuté.

| Source | Auteur | Licence | Utilisation |
| --- | --- | --- | --- |
| [Barramundi Fish](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/BarramundiFish) | Microsoft | CC0 1.0 | Poisson d'aquarium ; anatomie de base modifiée pour requin, Léviathan et dragon marin |
| [Blaster Kit, blaster-e](https://github.com/shorepine/kenney/blob/3694c6879e487c108f55677be7dd2ca75b07cc3b/3d/blaster/blaster-e.glb) | Kenney | CC0 1.0 | Corps fin du fusil-harpon, palette marine ; rail, flèche, ardillons et moulinet originaux |
| [Blaster Kit, crate-medium](https://github.com/shorepine/kenney/blob/3694c6879e487c108f55677be7dd2ca75b07cc3b/3d/blaster/crate-medium.glb) | Kenney | CC0 1.0 | Caisses de matériel dans les galeries du navire |

| [Animated Cute Fish Pack](https://quaternius.com/packs/cutefish.html) | Quaternius | CC0 1.0 | Poisson-clown, papillon, globe, lune, espadon, requin, requin gobelin, baudroie, piranha, mérou, chirurgien et poisson-lion |
| [Animated Fish Pack](https://quaternius.com/packs/animatedfish.html) | Quaternius | CC0 1.0 | Raie manta, baleine et dauphin |

Les déclarations de licence des distributeurs sont conservées dans `source/`. Le fichier `Kenney.LICENSE.txt` est la licence racine de la bibliothèque miroir ; son README conservé dans `source/Kenney.README.md` confirme que toute la bibliothèque graphique, dont Blaster Kit, est CC0. Les empreintes des modèles originaux sont dans `manifest.json`.

L'œuf ovoïde, les silhouettes animales procédurales, les tentacules, les cornes, les nageoires, le bateau, les aquariums et leurs décors sont créés pour Underwater Egg. Le Kraken, Scylla et Charybde sont des modèles originaux ; les sources externes ne sont pas présentées comme des monstres prêts à l'emploi.

`blender -b -t 2 --python tools/build_art.py` régénère les maillages, les couleurs et une version légère. Le jeu utilise le rendu natif EditableMesh lorsqu'il est disponible, et un rendu géométrique local de secours sinon. Aucun téléversement de modèle ni activation d'API n'est nécessaire pour ce secours. Les détails sont créés côté client, dans un rayon de 420 studs pour les boss, 270 pour les autres modèles, pour limiter la réplication et le nombre d'objets affichés.

La refonte colorée ajoute des yeux expressifs, des crocs, des couleurs plus franches et un maillage de secours plus détaillé. Les marchands, stands rayés et accessoires de plongée sont originaux. Les marchands portent désormais des armures originales à gemmes et bordures dorées, avec coiffures et visages assemblés en primitives Roblox, inspirées de la direction artistique des images fournies par le joueur.

## Nouveaux modèles marins

Quinze fichiers Quaternius préexistants sont intégrés depuis le miroir [quaternius-showcase au commit 722c39e](https://github.com/trebeljahr/quaternius-showcase/tree/722c39e964360beff2728a8ee4d103e2d11d457c/public/glb). La déclaration de licence par pack et sa provenance sont conservées dans [source/Quaternius.LICENSES.md](source/Quaternius.LICENSES.md). La licence MIT du visualiseur ne sert pas de licence aux modèles : les packs sélectionnés sont déclarés CC0. Les modèles restent crédités à Quaternius.

Les palettes sont adaptées au style Roblox, les yeux et dents sont préservés et les objets techniques sans matériau sont retirés à l'import. L'orientation de chaque modèle est normalisée pour regarder vers -Z dans Roblox. Les sculptures importées servent directement à la collection et aux boss ; le Léviathan primordial dérive du requin gobelin, avec nageoires et cornes originales. Aucun fichier d'un jeu propriétaire ni script de modèle n'est utilisé.

L’incubateur vitré, le bureau d’ordinateur et le poste d’amélioration sont originaux. Les anciens coraux et algues en primitives ont été remplacés par les sculptures préexistantes créditées ci-dessous. Les poses de nage R6/R15 sont procédurales et affichées sur chaque client pour tous les plongeurs ; aucun téléchargement d'animation n'est requis.

Les armures des marchands et cartes hexagonales de l’interface sont originales et intégrées au code. Les récifs utilisent désormais les modèles marins préexistants décrits ci-dessous. Les images de référence n’ont pas été extraites d’un autre jeu ni redistribuées dans le fichier Studio.


# Décors marins préexistants — crédits et modifications

Les modèles de récif sont importés de collections existantes. Les coraux/algues
assemblés avec des cylindres et ellipsoïdes dans les versions précédentes sont
remplacés par ces sculptures. Aucun script provenant d’un autre jeu n’est exécuté.

## Poly Pizza — Creative Commons Attribution 3.0

Modèles originaux, via Poly Pizza ; miroir de distribution :
https://github.com/Vivtorsing/Aquarium/tree/f0df5b244a836f60f4014cca5194fb137d67766d/src/models
Les crédits d’origine du miroir sont conservés dans PolyPizza.ATTRIBUTION.md.
Licence de ces modèles : https://creativecommons.org/licenses/by/3.0/
Texte complet : PolyPizza.CC-BY-3.0.txt.

- « Coral », Poly by Google : https://poly.pizza/m/80uVAty6wZ2
  Les éponges tubulaires sont extraites de cette sculpture ; palette turquoise.
- « underwater_enviro_coral », God Appeasers : https://poly.pizza/m/0CrDBiCnI5e
  Corail rose ramifié. Reconstruction du volume des branches pour la simplification.
- « Orange Coral », Device Lab : https://poly.pizza/m/3HEc6LvqCJd
- « Seaweed », Laney XR Labs : https://poly.pizza/m/461xlaa6SZW
- « Seaweed 3 », Laney XR Labs : https://poly.pizza/m/f_gXhnf06Oc
- « Anemone », Poly by Google : https://poly.pizza/m/eUZruaSm-9X
- « Sea anemone », Poly by Google : https://poly.pizza/m/5mWGVL6VgMd

Modifications communes : normalisation, sommets coïncidents soudés, versions
allégées, couleurs intégrées dans les surfaces, placement et dimensions adaptés
aux récifs et aux aquariums Roblox. Les créateurs originaux ne cautionnent pas
Underwater Egg. Les modèles modifiés restent attribués aux auteurs ci-dessus.

## WebGL Aquarium — BSD 3-Clause

Scène Aquarium par Greggman / Human Engines, dépôt WebGLSamples.
Copyright 2009 Google Inc. Sauf indication propre à un fichier, les contenus du
dépôt sont distribués sous BSD 3-Clause. Texte intégral : Aquarium.LICENSE.md.
Source figée :
https://github.com/WebGLSamples/WebGLSamples.github.io/tree/4c87dfea3cff6bf9f351c5ed4a191f86ceed8bbc/aquarium/assets

Modèles utilisés : CoralStoneA, CoralStoneB, RockB, Arch, RuinColumn,
SunknShip, TreasureChest ; textures diffuses correspondantes.
Modifications : géométrie normalisée, niveaux de détails et couleurs des textures
intégrées aux faces ; les rochers sont recolorés en bleu. Les créateurs et Google
ne cautionnent pas Underwater Egg.

Les empreintes de chaque modèle et texture ainsi que leurs sources précises
sont conservées dans assets/manifest.json. Les autres modèles marins, notamment
ceux de Quaternius, gardent les crédits détaillés dans CREDITS-MODELES.md.


## Navire, filets et harpon

Les caisses de matériel et le nouveau corps de harpon sont des modèles Kenney CC0 préexistants, figés au commit du tableau. Les géométries sont soudées et simplifiées avec `blender -b -t 2 --python tools/build_ship_art.py`, puis intégrées au catalogue numérique local. `tools/build_art.py` exécute aussi cette passe. Les textures de palette sont converties en couleurs de faces ; le fusil est recoloré en bleu marin. Aucun appel au catalogue Roblox ni achat de modèle n’est nécessaire.

Terrasses en teck, garde-corps vitrés, cloisons, cuves, ventilation, filets de corde, rail du harpon, sandows, moulinet et flèche sont originaux. Les coraux et rochers décoratifs sont retirés des aquariums à tous les niveaux ; les décors d’exploration conservent les sculptures marines créditées ci-dessus.
