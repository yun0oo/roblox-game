# Underwater Egg

Jeu Roblox en Luau/Rojo : exploration de six profondeurs depuis le navire **Néréide**, huit galeries personnelles, aquariums géants et boss marins. Les modèles sont intégrés ; aucun import manuel, achat de modèle ou réglage API de maillage n'est requis.

**Plonger → esquiver le boss → récupérer des œufs dans l'inventaire → déposer dans son aquarium → attendre l'éclosion → produire des gold → acheter de l'équipement → descendre.**

## Télécharger et jouer sur Windows

- [Télécharger le ZIP](downloads/UnderwaterEgg.zip), puis l'extraire dans un nouveau dossier.
- Ouvrir `UnderwaterEgg.rbxl` dans Roblox Studio et appuyer sur **F5 / Play** pour jouer avec son personnage Roblox.
- Attendre le chargement du navire et de l'océan. Retrouvez votre portrait et votre pseudo au-dessus de votre aquarium.
- Tous les joueurs plongent et remontent par le bassin central, avec ses deux échelles.

Le [fichier Studio seul](downloads/UnderwaterEgg.rbxl) est également fourni. Sur une page GitHub, utiliser **Download raw file** pour télécharger le fichier.

Un fichier non publié démarre sans activer de case API. Sa session est marquée **NON SAUVEGARDÉ** : sa progression reste temporaire. Pour tester les vraies sauvegardes, publier une expérience privée et activer l'accès Studio aux services API dans ses paramètres de sécurité. Studio utilise un magasin distinct, `UnderwaterEgg_v1_Studio` ; une erreur de chargement en production ne crée jamais de profil de secours susceptible d'écraser les données.

Roblox Studio est nécessaire sur Windows/macOS pour jouer. Le cloud Linux construit les fichiers et vérifie le code ; il ne lance pas Studio. Configurer l'expérience pour huit joueurs. Pour un essai multijoueur, démarrer un serveur local avec deux joueurs dans Studio.

## Marché et équipement visible

Sept vrais marchands colorés occupent la promenade centrale du pont :

| Marchand | Spécialité | Équipement porté |
| --- | --- | --- |
| Capitaine Corail | Combinaison | Gilet, masque, harnais et couleurs de palier |
| Bulle | Oxygène | Bouteilles jumelles et détendeur |
| Flash | Nage | Palmes |
| Bastion | Protection | Épaulières renforcées |
| Luciole | Lampe | Lampe frontale |
| Turbo | Propulseur | Turbines dorsales |
| Trident | Harpon | Fusil avec canon, sandows, moulinet et pointe à ardillons |

Interagir avec **E** devant un stand ouvre sa spécialité. Le menu **Équipement** permet aussi de parcourir les sept boutiques : aperçu 3D du plongeur équipé, effets actuels et suivants, prix, solde, achat ou directions vers le marchand. Un achat n'est autorisé côté serveur qu'à proximité du bon spécialiste. Les visuels sont actualisés à l'achat, à la réapparition et au prestige. Les accessoires sont soudés, sans masse ni collision, compatibles R6/R15 ; ils conservent l'avatar et ses vêtements.

L'amélioration de la base est séparée : **F** à la pancarte dorée de sa propre galerie. Le panneau compare les capacités et revenus avant achat. À distance, il donne les directions vers cette pancarte.

| Niveau de base | Prix | Espèces exposées | Bonus de gold |
| --- | --- | --- | --- |
| Explorateur | Inclus | 4 | — |
| Océanographe | 600 | 6 | +10 % |
| Sanctuaire | 2 500 | 8 | +20 % |
| Atlantide | 12 500 | 10 | +30 % |
| Palais des abysses | 60 000 | 12 | +40 % |

La cuve grandit et reçoit filtres, coraux et cristaux. Le niveau de base reste acquis après un prestige.

## Œufs, inventaire et boss

Chaque palier possède 16 nids possibles et au plus six œufs actifs, choisis aléatoirement. Les grandes coques ovoïdes mesurent de 7,5 à 20 studs de haut ; particules, halo et aura indiquent leur rareté. Les œufs expirent et les événements renouvellent une partie des apparitions.

**Le ramassage ajoute immédiatement un œuf NON SÉCURISÉ à l'inventaire affiché, sans modèle derrière le personnage.** Son transporteur apparaît en surbrillance de la couleur de sa rareté. Un seul œuf non sécurisé peut voyager à la fois ; les autres places accueillent les œufs déjà sécurisés ou en incubation. Une requête répétée ou un simple contact ne transfère rien.

Un harpon valide fait tomber cet œuf : il réapparaît dans le monde et le premier joueur qui le ramasse devient son transporteur. Le changement de transporteur déplace la surbrillance et crédite un vol si l'interception venait d'un autre joueur. Une mort ou déconnexion en exploration fait aussi tomber l'œuf non sécurisé. Les événements ne le suppriment pas.

L'arrivée dans **sa propre galerie** sécurise automatiquement l'œuf dans l'inventaire persistant et retire la surbrillance. Il devient définitivement protégé. Toute la zone du navire est sans interception ; visiter une autre galerie ne donne pas la propriété permanente de l'œuf. L'inventaire a 24 places ; s'il est plein, le ramassage laisse l'œuf dans le monde.

**Un seul boss géant par profondeur** surveille tous les nids de sa zone : Tyran du récif, Requin gobelin géant, Raie titan d’Atlantis, Baudroie des abysses, Mégalodon ancestral et Léviathan primordial. Il patrouille, repère les plongeurs dans tout le palier, poursuit et attaque. Sa santé, sa taille, ses dégâts et sa vitesse augmentent avec la profondeur. Ramasser, expirer ou renouveler un œuf ne supprime jamais le boss partagé. Un boss vaincu laisse un répit de 50 à 75 secondes avant de réapparaître.

Le harpon tire un vrai projectile, avec corde, recul, sons, collision balayée, portée et cooldown validés côté serveur. Il combat les boss et permet de voler les œufs non sécurisés des autres joueurs, sans leur infliger de dégâts. Les œufs sécurisés restent toujours protégés. Le navire entier est une zone sans combat.

Tous les paliers restent accessibles sans niveau minimum bloquant. Les combinaisons **1 / 10 / 20 / 35 / 50 / 75** sont recommandées. Sous le niveau conseillé, les boss gagnent jusqu'à **85 % de vitesse** et **150 % de dégâts**. La vitesse de base passe de 14 à 46 studs/s. Oxygène, pression, protection, nage et propulseur ont des effets réels ; des stations O₂ permettent de recharger.

## Aquarium, collection et progression

Déposer un œuf avec **E** devant sa cuve d’incubation vitrée, séparée de l’aquarium des animaux, ou **Inventaire → Déposer** dans sa galerie, lance l'incubation. L'œuf devient visible dans la cuve à œufs, puis l’animal apparaît automatiquement dans l’aquarium, même si le propriétaire explore ailleurs.

| Rareté | Incubation après dépôt | Aura |
| --- | --- | --- |
| Common | 15 s | Blanche |
| Rare | 40 s | Bleue |
| Epic | 90 s | Violette |
| Legendary | 3 min | Dorée |
| Mythic | 6 min | Rose |
| Secret | 12 min | Turquoise |

Les échéances sont sauvegardées avec les œufs : une reconnexion ne remet pas le délai à zéro. Un œuf prêt pendant une absence éclot au retour. Les animaux produisent des gold pendant la connexion ; toute la collection produit, même quand seule une partie est exposée.

- Six paliers : récif, épave, ruines, forêt abyssale, grande abyss et fosse interdite.
- 61 animaux d'éclosion, au moins dix par palier, et huit hybrides de fusion. Bestiaire 3D ; espèces inconnues `???`.
- Fusion de trois identiques : Gold ×3,5, Diamond ×12, Mythic ×45. Cinq recettes connues et trois secrètes ; les recettes secrètes restent privées côté serveur avant découverte.
- Événements de 5, 15 et 40 minutes : avertissements, bonus de rareté, courants et gardiens renforcés. Attaques spéciales annoncées des boss profonds : siphon, choc et vortex.
- Prestige avec bonus permanents ; décorations et palettes de galerie ; six classements du serveur.
- DataStore avec bail de session, sauvegarde périodique, départ et fermeture ; validation des actions et déplacements côté serveur.

La direction graphique suit un style Roblox coloré : sols de galerie à tenons, clôtures en bois, silhouettes lisibles, yeux expressifs, navire bleu/blanc/or, stands rayés et aquariums lumineux. Certaines espèces partagent une silhouette et se distinguent par leur palette et leurs statistiques. Dix-sept modèles sources CC0 de Microsoft, Kenney et Quaternius sont intégrés et adaptés ; quinze nouveaux modèles Quaternius donnent de véritables silhouettes distinctes aux poissons et aux boss. Les palettes sont adaptées au jeu ; certaines espèces partagent encore une silhouette. Les coraux, cuves et accessoires sont originaux. Voir [les crédits](assets/CREDITS.md).

## Commandes

| Action | Clavier/souris | Manette | Mobile |
| --- | --- | --- | --- |
| Nager | WASD / commandes Roblox | Stick gauche | Joystick |
| Monter / descendre | Espace / Ctrl | LB / RB | ↑ / ↓ |
| Propulseur | R | X | BOOST |
| Verrouillage caméra | Shift (bascule) | Visée centrée | Visée centrée |
| Harpon | Viser et clic | Réticule et RT | Réticule et TIRER |
| Œuf / aquarium / marchand | E | Interaction Roblox | Bouton contextuel |
| Pancarte de base | F | Interaction Roblox | Bouton contextuel |

Le viseur est visible avec le harpon équipé : il suit la souris en mode libre et reste centré avec Shift, sur manette et sur mobile. Shift active une caméra à l’épaule, avec orientation du personnage dans la direction de visée ; une seconde pression rétablit la caméra libre. Les menus et la perte de focus libèrent le curseur. Le retour rapide prend quatre secondes et exige de ne pas transporter d’œuf non sécurisé, y compris à la fin du délai.

## Développer et vérifier

```sh
cd /workspace/roblox-game
python3 tools/bootstrap.py
python3 tools/check.py
python3 tools/package.py
```

Python 3.12 installe les outils officiels épinglés avec vérification SHA-256. `.tools/` et `build/` sont ignorés par Git. Le vérificateur utilise aussi l'outillage partagé de l'environnement cloud.

`tools/check.py` compile et analyse les sources Luau, teste probabilités/économie/inventaires/fusions/prestige, les services serveur, le démarrage complet et les callbacks de boutique avec des primitives moteur simulées. Il vérifie la collecte simultanée, l’interception au harpon, les protections des bases, le viseur/verrouillage de caméra, le boss partagé et sa réapparition, les achats près du bon marchand, les sauvegardes et l'incubation. Il construit `.rbxl` et `.rbxlx`, vérifie les sources embarquées et exécute `luau-lsp` avec les définitions Roblox.

**Ces contrôles ne simulent pas le rendu ou la physique natifs Roblox.** Les essais visuels, réseau, mobile, performance et DataStore réel restent à effectuer selon [la procédure Studio](docs/STUDIO_TESTS.md). Aucun essai natif Studio n'a été exécuté ici.

`build/UnderwaterEgg-project.zip` contient les sources, tests et fichiers Studio. `tools/package.py` prépare le ZIP prêt à ouvrir dans `downloads/`. Le workflow GitHub Actions reprend la vérification.

La configuration publique est dans `src/shared/Config.luau` : prix, marchands, tailles, boss, probabilités, revenus et timers. Les poids sont normalisés. `ActiveFloors = 3` réactive le périmètre MVP ; la valeur livrée active six paliers. Les recettes sont exclusivement dans `src/server/FusionData.luau`.

Les modèles détaillés se construisent côté client, avec distance d'affichage et budget : jusqu'à 420 studs pour les boss, 270 pour le reste. EditableMesh est utilisé si disponible ; un rendu géométrique de secours fonctionne sans activer d'API. `python3 tools/check_art.py` vérifie provenance CC0, budgets et forme ovoïde. Blender sert uniquement à régénérer les données : `blender -b -t 2 --python tools/build_art.py`. `tools/preview_art.py` produit un aperçu hors ligne, qui n'est pas une capture Roblox.

Pour synchroniser localement avec le plugin Rojo de Studio : `.tools/bin/rojo serve default.project.json --address 127.0.0.1 --port 34872`. La synchronisation cloud vers un Studio local n'est pas présumée accessible ; le fichier `.rbxl` reste autonome.

## Sauvegarde

Le profil contient gold (champ historique `Money`), équipement, œufs sécurisés et échéances, animaux/variantes, bestiaire, recettes, prestige, XP, profondeur record, statistiques et personnalisation. Les sauvegardes existantes restent compatibles.

Le prestige réinitialise les éléments annoncés dans l'interface après confirmation ; base, bestiaire découvert, recettes, statistiques, record et cosmétiques restent acquis. Aucun achat Robux ni outil d'administration distant n'est nécessaire. L'équilibrage économique et les performances à huit joueurs doivent être évalués dans Studio avant une publication publique.

## Récif, laboratoire et nage

La première profondeur utilise des terrasses de sable ovales, des coraux ramifiés, des gorgones, des coraux en plateaux et des algues. Les grandes dalles rectangulaires et le cadre lumineux carré ont été retirés de ce palier ; la descente centrale reste libre.

Chaque galerie possède une **cuve d'incubation vitrée séparée** de l'aquarium : liquide, éclairage, coupelles, filtration et jusqu'à 24 œufs en incubation. Le résultat rejoint automatiquement l'aquarium. Le poste d'amélioration affiche son niveau et le prochain prix.

**E à l'ordinateur** de sa galerie ouvre sept destinations. Choisir un marchand téléporte gratuitement devant son stand et ouvre sa boutique. Le serveur impose la proximité de son propre ordinateur, contrôle la destination dans sa liste et applique un délai entre transferts. Une requête distante en exploration ne permet pas de fuir avec un œuf ; un œuf déjà arrivé dans sa galerie est sécurisé avant transfert.

Le contrôleur de nage ne relance plus l'état Swimming à chaque image. Une tolérance à la surface évite les transitions répétées. Les poses de nage R6/R15 remplacent temporairement la marche, adaptent l'inclinaison aux déplacements, maintiennent le harpon et sont calculées par chaque client pour tous les joueurs. Le retour sur le pont ou l'escalade restaure le comportement natif. Les tests de transitions et de restauration restent distincts d'une validation visuelle et physique dans Studio.

Pour inspecter les nouveaux modèles hors ligne : `blender -b -t 2 --python tools/preview_art.py -- --lod --marine`. Le rendu produit n'est pas une capture Roblox. Le build courant utilise les données incluses et ne nécessite pas Blender.
