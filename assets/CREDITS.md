# Modèles et licences

Les modèles sont fournis dans le dépôt et convertis en données numériques pour le jeu. Aucun script provenant d'un modèle téléchargé n'est exécuté.

| Source | Auteur | Licence | Utilisation |
| --- | --- | --- | --- |
| [Barramundi Fish](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/BarramundiFish) | Microsoft | CC0 1.0 | Poisson d'aquarium ; anatomie de base modifiée pour requin, Léviathan et dragon marin |
| [Blaster Kit, blaster-b](https://github.com/shorepine/kenney/blob/3694c6879e487c108f55677be7dd2ca75b07cc3b/3d/blaster/blaster-b.glb) | Kenney | CC0 1.0 | Corps du harpon, complété par une flèche, des ardillons et un moulinet originaux |

| [Animated Cute Fish Pack](https://quaternius.com/packs/cutefish.html) | Quaternius | CC0 1.0 | Poisson-clown, papillon, globe, lune, espadon, requin, requin gobelin, baudroie, piranha, mérou, chirurgien et poisson-lion |
| [Animated Fish Pack](https://quaternius.com/packs/animatedfish.html) | Quaternius | CC0 1.0 | Raie manta, baleine et dauphin |

Les déclarations de licence des distributeurs sont conservées dans `source/`. Le fichier `Kenney.LICENSE.txt` est la licence racine de la bibliothèque miroir ; son README confirme que toute la bibliothèque graphique, dont Blaster Kit, est CC0. Les empreintes des modèles originaux sont dans `manifest.json`.

L'œuf ovoïde, les silhouettes animales procédurales, les tentacules, les cornes, les nageoires, le bateau, les aquariums et leurs décors sont créés pour Underwater Egg. Le Kraken, Scylla et Charybde sont des modèles originaux ; les sources externes ne sont pas présentées comme des monstres prêts à l'emploi.

`blender -b -t 2 --python tools/build_art.py` régénère les maillages, les couleurs et une version légère. Le jeu utilise le rendu natif EditableMesh lorsqu'il est disponible, et un rendu géométrique local de secours sinon. Aucun téléversement de modèle ni activation d'API n'est nécessaire pour ce secours. Les détails sont créés côté client, dans un rayon de 420 studs pour les boss, 270 pour les autres modèles, pour limiter la réplication et le nombre d'objets affichés.

La refonte colorée ajoute des yeux expressifs, des crocs, des couleurs plus franches et un maillage de secours plus détaillé. Les marchands, stands rayés et accessoires de plongée sont originaux. La forme du visage souriant des marchands utilise la texture intégrée à Roblox `rbxasset://textures/face.png`.

## Nouveaux modèles marins

Quinze fichiers Quaternius préexistants sont intégrés depuis le miroir [quaternius-showcase au commit 722c39e](https://github.com/trebeljahr/quaternius-showcase/tree/722c39e964360beff2728a8ee4d103e2d11d457c/public/glb). La déclaration de licence par pack et sa provenance sont conservées dans [source/Quaternius.LICENSES.md](source/Quaternius.LICENSES.md). La licence MIT du visualiseur ne sert pas de licence aux modèles : les packs sélectionnés sont déclarés CC0. Les modèles restent crédités à Quaternius.

Les palettes sont adaptées au style Roblox, les yeux et dents sont préservés et les objets techniques sans matériau sont retirés à l'import. L'orientation de chaque modèle est normalisée pour regarder vers -Z dans Roblox. Les sculptures importées servent directement à la collection et aux boss ; le Léviathan primordial dérive du requin gobelin, avec nageoires et cornes originales. Aucun fichier d'un jeu propriétaire ni script de modèle n'est utilisé.

Le récif ramifié, les gorgones, les coraux en plateaux, l'incubateur vitré, le bureau d'ordinateur et le poste d'amélioration sont originaux. Les poses de nage R6/R15 sont procédurales et affichées sur chaque client pour tous les plongeurs ; aucun téléchargement d'animation n'est requis.
