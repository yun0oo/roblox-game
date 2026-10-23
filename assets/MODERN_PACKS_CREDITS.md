# Packs de décor Kenney — carte modernisée

Auteur : **Kenney** (https://kenney.nl). Licence : **CC0 1.0**.
La déclaration CC0 et le README du miroir sont conservés dans `source/Kenney.LICENSE.txt` et `source/Kenney.README.md`. Le README du miroir confirme la licence CC0 de la bibliothèque graphique. Les fichiers originaux et textures sont conservés sans modifier leurs octets ; SHA-256 dans `assets/manifest.json`.

Source de distribution figée :
https://github.com/shorepine/kenney/tree/3694c6879e487c108f55677be7dd2ca75b07cc3b/3d

| Pack officiel | Modèles utilisés |
| --- | --- |
| [Nature Kit](https://kenney.nl/assets/nature-kit) | `cliff_cave_rock`, `cliff_large_rock`, `rock_largeC`, `rock_tallB` |
| [Pirate Kit](https://kenney.nl/assets/pirate-kit) | `ship-wreck`, `barrel`, `cannon`, texture `Textures/colormap.png` |
| [Castle Kit](https://kenney.nl/assets/castle-kit) | `wall-doorway`, `wall-pillar`, `stairs-stone`, texture `Textures/colormap.png` |
| [Space Kit](https://kenney.nl/assets/space-kit) | `rock_crystalsLargeA`, `rock_crystalsLargeB` |

Modifications : normalisation des dimensions, soudure des sommets coïncidents, simplification en trois niveaux de détail, palette bleue des roches et cristaux cyan/violet sur roche sombre, conversion des couleurs des textures en couleurs de faces et placement adapté aux biomes sous-marins. Les palettes propres à chaque pack sont résolues séparément à l’import. Les attributs de matériau du jeu sont adaptés aux roches, pierres, bois et métal.

Régénération : `blender -b -t 2 --python tools/build_modern_art.py`. Les modèles sont intégrés comme données numériques dans le fichier Studio ; aucun script du miroir ni script de modèle n’est téléchargé ou exécuté par le jeu. Aucun achat ni import manuel de modèle n’est nécessaire.

Les supports de stations O₂, conduites, parcours, fonds continus et effets de particules sont originaux. Les sculptures de corail et anciennes pièces de décor conservées gardent les attributions Poly Pizza / WebGL Aquarium dans `MARINE_SCENERY_CREDITS.md`. Les images de référence du joueur ne sont pas redistribuées.

Les aperçus Blender sont des rendus hors Roblox ; ils ne prouvent pas le rendu ou les performances natifs.
