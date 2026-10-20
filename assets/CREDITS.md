# Modèles et licences

Les modèles sont fournis dans le dépôt et convertis en données numériques pour le jeu. Aucun script provenant d'un modèle téléchargé n'est exécuté.

| Source | Auteur | Licence | Utilisation |
| --- | --- | --- | --- |
| [Barramundi Fish](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/BarramundiFish) | Microsoft | CC0 1.0 | Poisson d'aquarium ; anatomie de base modifiée pour requin, Léviathan et dragon marin |
| [Blaster Kit, blaster-b](https://github.com/shorepine/kenney/blob/3694c6879e487c108f55677be7dd2ca75b07cc3b/3d/blaster/blaster-b.glb) | Kenney | CC0 1.0 | Corps du harpon, complété par une flèche, des ardillons et un moulinet originaux |

Les déclarations de licence des distributeurs sont conservées dans `source/`. Le fichier `Kenney.LICENSE.txt` est la licence racine de la bibliothèque miroir ; son README confirme que toute la bibliothèque graphique, dont Blaster Kit, est CC0. Les empreintes des deux modèles originaux sont dans `manifest.json`.

L'œuf ovoïde, les autres silhouettes animales, les tentacules, les cornes, les nageoires, le bateau, les aquariums et leurs décors sont créés pour Underwater Egg. Le Kraken, Scylla et Charybde sont des modèles originaux ; les sources externes ne sont pas présentées comme des monstres prêts à l'emploi.

`blender -b -t 2 --python tools/build_art.py` régénère les maillages, les couleurs et une version légère. Le jeu utilise le rendu natif EditableMesh lorsqu'il est disponible, et un rendu géométrique local de secours sinon. Aucun téléversement de modèle ni activation d'API n'est nécessaire pour ce secours. Les détails sont créés côté client, dans un rayon de 270 studs, pour limiter la réplication et le nombre d'objets affichés.
