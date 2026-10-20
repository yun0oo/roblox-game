# Underwater Egg

Jeu Roblox multijoueur sous-marin en Luau, construit avec Rojo. La carte, les animaux, les gardiens et les interfaces sont générés par le projet : aucun modèle payant ni pack externe n'est nécessaire.

**Explorer → prendre un œuf gardé → échapper aux harpons → sécuriser à sa base → faire éclore → gagner → améliorer → descendre.**

## Télécharger sur GitHub

Les fichiers prêts à ouvrir sont dans [`downloads/`](downloads/) :

- [`UnderwaterEgg.zip`](downloads/UnderwaterEgg.zip) : jeu et instructions pour Windows/macOS ;
- [`UnderwaterEgg.rbxl`](downloads/UnderwaterEgg.rbxl) : fichier Roblox Studio directement.

Sur la page du fichier GitHub, cliquer sur **Download raw file** (icône de téléchargement). Extraire le ZIP, puis ouvrir `UnderwaterEgg.rbxl` dans Roblox Studio et cliquer sur **Play**.

## Ouvrir le jeu

1. Ouvrir `build/UnderwaterEgg.rbxl` ou `build/UnderwaterEgg.rbxlx` dans Roblox Studio sur Windows ou macOS.
2. Lancer **Play**. La carte apparaît au démarrage du serveur, pas en mode édition.
3. Pour tester les poursuites, utiliser l'onglet **Test**, un serveur local et **2 joueurs**.
4. Pour tester les vraies sauvegardes, publier une expérience privée et activer **Game Settings → Security → Enable Studio Access to API Services**. Studio utilise un magasin distinct : `UnderwaterEgg_v1_Studio`.

Sans accès DataStore, Studio autorise une session temporaire explicitement marquée **NON SAUVEGARDÉ**. Dans une expérience publiée, une erreur de chargement bloque la connexion pour éviter d'écraser la progression avec un profil neuf.

Configurer la capacité de l'expérience à **8 joueurs**, correspondant aux huit habitats.

L'archive `build/UnderwaterEgg-project.zip` regroupe les sources, les tests, la documentation et les deux fichiers Roblox.

## Ce qui est implémenté

| Système | Contenu |
| --- | --- |
| Océan | Six paliers verticaux, récif, épave, ruines, forêt bioluminescente, squelette de titan et fosse interdite ; puits central et stations O₂ |
| Exploration | Nage 3D, oxygène, pression, lampe, propulseur, ralentissement selon l'œuf |
| Œufs | 24 noms d'œufs, 16 nids par palier, choix aléatoire des nids et raretés, expiration ; jusqu'à 36 œufs actifs |
| Gardiens | Un gardien par apparition, patrouille, poursuite, retour au nid, PV, attaque, dégâts et vitesse selon profondeur/rareté |
| Boss | Attaques annoncées : siphon d'oxygène, onde de choc, ralentissement de vortex ; immunité complète des habitats |
| Harpon | Projectile visible, corde, recul, sons et impact ; collision balayée côté serveur, portée et cadence configurables |
| Habitats | Huit bulles protégées, sécurisation automatique, incubateur, atelier et présentoirs des douze espèces possédées les plus rentables |
| Collection | 61 animaux d'éclosion, au moins dix par palier ; huit hybrides de fusion ; bestiaire avec modèles et espèces inconnues `???` |
| Économie | Production connectée par minute, prix configurables, sept équipements améliorables |
| Fusion | Trois identiques → Gold → Diamond → Mythic ; cinq recettes connues et trois recettes secrètes privées côté serveur |
| Phénomènes | Paliers de 5, 15 et 40 minutes ; avertissement, courants, obscurité, gardiens renforcés et probabilités modifiées |
| Prestige | Progression recommençable, bonus permanents d'argent, oxygène, nage, harpon et coût de fusion |
| Personnalisation | Palettes, aquarium, statue, bulles et effets de prestige persistants |
| Classements | Six classements du serveur : argent, valeur de collection, vols, profondeur, animaux rares et fusions découvertes |
| Persistance | Profils DataStore, bail de session, sauvegarde périodique, départ et fermeture, protection contre les profils incompatibles |

Les modèles sont des créations procédurales stylisées à base de primitives Roblox. Les variantes de certaines espèces partagent une silhouette et se distinguent par leur palette, leur nom et leurs statistiques.

## Commandes

| Action | Clavier/souris | Manette | Mobile |
| --- | --- | --- | --- |
| Nager | WASD / commandes Roblox locales | Stick gauche | Joystick |
| Monter / descendre | Espace / Ctrl | LB / RB | ↑ / ↓ |
| Propulseur | Shift | X | BOOST |
| Harpon | Viser et clic gauche | Viser au centre et RT | Réticule central et TIRER |
| Œuf / incubateur / atelier | Interaction Roblox E | Interaction Roblox | Bouton contextuel |

Le retour rapide est interdit avec un œuf. Un contact physique entre personnages ne vole jamais un œuf. Un harpon ne blesse pas les joueurs : il fait tomber leur œuf lorsqu'une collision valide a lieu en exploration. Le même harpon peut combattre les gardiens.

## Développer dans le cloud Linux

Python 3.12 suffit pour installer les outils épinglés :

```sh
cd /workspace/roblox-game
python3 tools/bootstrap.py
python3 tools/check.py
```

L'installation télécharge les versions officielles et vérifie les SHA-256 de `tools/toolchain.json`. Les outils et caches restent dans `.tools/`, ignoré par Git. Le vérificateur fonctionne aussi avec l'outillage déjà installé dans l'environnement cloud.

Pour travailler avec le plugin Rojo de Studio sur une machine compatible :

```sh
export PATH="$PWD/.tools/bin:$PATH"
rojo serve default.project.json --address 127.0.0.1 --port 34872
```

Ne pas présumer qu'un serveur Rojo cloud sera accessible depuis un Studio local : le fichier `.rbxl` permet d'ouvrir le jeu sans connexion au serveur de synchronisation. Aucun port public n'est requis pour construire ou tester les règles dans le cloud.

## Validation

`python3 tools/check.py` exécute :

- compilation des sources Luau et analyse des modules purs ;
- tests de probabilités, économie, équipements, inventaires, fusions, prestige et décoration ;
- scénarios des vrais modules serveur avec primitives moteur simulées : vol, bases, collisions, gardiens, événements, verrou et reconnexion DataStore ;
- construction `.rbxl` et `.rbxlx`, génération du sourcemap et vérification que toutes les sources sont incluses ;
- analyse avec `luau-lsp` et les définitions de l'API Roblox épinglées.

Le workflow GitHub Actions reprend cette commande et conserve les deux fichiers construits. Son exécution sur GitHub nécessite un commit/push ; la validation effectuée ici est locale.

Ces contrôles ne remplacent pas Roblox Studio : le rendu, la physique réseau, les contrôles tactiles réels, la latence et l'accès DataStore distant doivent suivre la procédure de [tests Studio](docs/STUDIO_TESTS.md). Aucun essai natif Studio n'a été exécuté dans le cloud Linux.

## Régler le jeu

Les valeurs publiques sont centralisées dans `src/shared/Config.luau` : probabilités par profondeur, catalogues, revenus, tailles, ralentissements, oxygène, équipement, harpons, durées et bonus d'événement. Les poids sont normalisés ; ils n'ont pas besoin de totaliser 100.

La combinaison débloque les paliers aux niveaux **1 / 10 / 20 / 35 / 50 / 75**. Chaque niveau réduit aussi la consommation liée à la pression. Les variantes produisent **Gold ×3,5 / Diamond ×12 / Mythic ×45**, avant le multiplicateur de prestige.

Pour revenir au test MVP initial, régler `Config.ActiveFloors = 3`. Les paliers supplémentaires ne sont alors pas construits et leurs œufs n'apparaissent pas. La configuration par défaut active les six paliers.

Les recettes complètes se trouvent exclusivement dans `src/server/FusionData.luau`. Le serveur ne transmet les recettes secrètes qu'après leur découverte. Les probabilités d'éclosion choisissent un animal du palier et de la rareté de l'œuf ; les hybrides `FusionOnly` sont exclus de l'éclosion.

## Sauvegarde et règles de propriété

Le profil contient argent, équipement (harpon compris), animaux normaux et variantes, bestiaire, œufs sécurisés, recettes, prestige, XP, profondeur record, statistiques et personnalisation. Le revenu est produit pendant la connexion, sans revenu hors ligne.

Les œufs en cours de transport restent dans le monde : une mort ou déconnexion les fait tomber. Un œuf arrivé dans l'habitat de son transporteur passe dans son inventaire persistant et disparaît du monde partagé. Tous les habitats protègent les visiteurs, mais seul son propre habitat sécurise un œuf pour soi.

Le prestige requiert la combinaison 20 et son prix affiché. Après une confirmation à deux étapes, il remet argent à 150, équipement à 1, XP à zéro et vide les animaux/variantes/œufs. Bestiaire, recettes découvertes, statistiques, record de profondeur et cosmétiques restent acquis.

Chaque action distante est limitée en fréquence et validée côté serveur. Le client transmet une intention de tir, un identifiant d'œuf ou une sélection de fusion ; il ne transmet jamais de montant à créditer, de rareté obtenue, de propriétaire choisi ou de résultat de collision. Le serveur vérifie aussi les déplacements et les zones protégées.

## Organisation

```text
src/shared/   Config, règles pures, modèles procéduraux
src/server/   Carte, œufs/spawns/vols, gardiens, harpon,
              DataStore, événements, recettes privées, orchestration
src/client/   Contrôles, atmosphère, effets et interface
tests/        Règles, progression et scénarios de services
tools/        Installation vérifiée et commande de validation
docs/         Procédure de tests dans Roblox Studio
build/        Fichiers Roblox générés, non suivis par Git
```

Les budgets DataStore, les performances de génération de terrain, les tarifs de fin de jeu et les fréquences de butin doivent être évalués avec de vrais joueurs avant une publication publique. Aucun achat Robux, outil d'administration caché ou identifiant d'asset privé n'est nécessaire.
