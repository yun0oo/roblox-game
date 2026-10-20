# Validation native Roblox Studio

État : procédure préparée, **non exécutée dans l'environnement Linux**. Les tests Luau et les builds sont indépendants de cette validation native.

Utiliser d'abord une expérience privée et deux joueurs locaux. Tester le MVP avec `Config.ActiveFloors = 3`, puis les six paliers. Revenir aux valeurs de production après toute accélération des timers ou attribution de monnaie par la console serveur. Aucune commande d'administration distante n'est incluse.

## Démarrage et déplacement

- Commencer avec le fichier `.rbxl` non publié, sans changer les réglages API, puis appuyer sur **F5 / Play**. Vérifier le personnage Roblox pendant le chargement, puis son arrivée dans son habitat ; l'interface doit indiquer la session Studio non sauvegardée.
- Refaire le test dans une expérience privée publiée avec accès API désactivé : le démarrage doit également réussir en session temporaire.
- Ouvrir le fichier construit, lancer le serveur et vérifier l'absence d'erreurs dans Output côté serveur et clients.
- Vérifier la génération de l'eau, des huit bulles et des paliers actifs ; les passages du puits central doivent rester traversables.
- Vérifier que chacun apparaît dans son propre habitat avec son harpon et une réserve d'oxygène pleine.
- Nager dans les six directions, utiliser le propulseur, mourir puis réapparaître ; vérifier la caméra, la lampe et les animations.
- Tester l'émulateur tactile et une manette : réticule central, tir, montée, descente, achat, défilement et fermeture des panneaux.
- Mesurer la durée de génération de terrain, la mémoire serveur/client et les images/seconde. Faire un essai avec huit clients avant publication publique.

## Œufs et gardiens

- Observer six œufs maximum par palier, chacun accompagné d'un gardien. Les nids occupés ne doivent pas recevoir un deuxième œuf.
- Attendre les cycles et expirations : plusieurs positions et raretés doivent apparaître, avec des variations à l'intérieur des nids.
- Attirer un gardien, esquiver, l'éloigner du nid et vérifier son retour. Le combattre au harpon et récupérer l'œuf.
- Vérifier qu'aucun gardien ni attaque spéciale ne blesse un joueur dans une bulle.
- Aux paliers profonds, vérifier les avertissements d'attaque puis les effets de siphon, onde de choc et vortex. Les joueurs doivent pouvoir esquiver avant l'impact.

## Interception à deux joueurs

1. A prend un œuf ; vérifier sa visibilité et le ralentissement de nage.
2. B touche simplement A avec son personnage : aucun transfert ni chute.
3. B tire à côté de A : aucun effet de gameplay.
4. B touche un joueur sans œuf : aucun dégât et aucun vol.
5. B touche A dans la portée : l'œuf tombe, sans transfert automatique.
6. B récupère l'œuf tombé : il devient transporteur et gagne un vol réussi.
7. A poursuit B et peut l'intercepter à son tour après son cooldown.
8. Tirer à travers une paroi : elle bloque le projectile. Tester également chaque extrémité de portée et les niveaux de harpon 1/2/3.
9. A entre dans sa propre bulle pendant qu'un projectile arrive : l'œuf doit rester sécurisé, même à la limite de la zone.
10. B entre dans la bulle de A avec son propre œuf : B est protégé, mais seul l'habitat de B peut sécuriser cet œuf pour lui.
11. Tester une mort/déconnexion avec un œuf en exploration, dans sa base et en visite dans une autre base.

## Progression et oxygène

- Avec la combinaison 1, tenter le palier 2 : avertissement et retour au-dessus de la limite.
- Tester les seuils 10 / 20 / 35 / 50 / 75 sans réinitialiser les gains.
- Comparer la réserve maximale et la consommation après amélioration ; vérifier chaque station O₂ et le rechargement en bulle.
- À oxygène critique : avertissement ; à zéro : baisse de santé, puis chute d'un œuf transporté à la mort.
- Vérifier les coûts et l'effet des sept équipements, y compris la recharge du propulseur et la portée de lampe.

## Éclosion, collection et fusion

- Ramener un œuf : message de sécurisation, ajout à l'incubateur, retrait définitif du monde partagé.
- Faire éclore par l'incubateur et par l'interface. Répéter un identifiant d'œuf déjà consommé ne doit créer aucun animal supplémentaire.
- Vérifier l'animation et le nouveau modèle sur le présentoir ; une espèce inconnue passe de `???` à son entrée complète.
- Pendant une minute connecté, comparer le revenu réel au revenu affiché ; vérifier les revenus des paliers profonds.
- Fusionner trois normaux en Gold, trois Gold en Diamond et trois Diamond en Mythic. Vérifier consommation, prix et multiplicateurs.
- Tester les cinq recettes connues, une recette secrète, une combinaison inconnue, un manque d'ingrédients et un manque d'argent.
- Une recette secrète doit apparaître après découverte ; rejouer la même recette ne doit pas annoncer une nouvelle découverte.

## Événements

- En copie de test uniquement, réduire les trois intervalles et leurs durées dans Config afin de vérifier les transitions rapidement.
- Vérifier l'avertissement, le début, les courants et l'obscurité, les nouveaux poids d'œufs et la force des gardiens.
- Un œuf porté ou tombé doit survivre au renouvellement des œufs sauvages lors d'un événement.
- L'événement légendaire doit prévaloir sur les événements inférieurs simultanés, puis expirer.
- Restaurer 300 / 900 / 2400 secondes avant la construction destinée à publication.

## Prestige, décoration et classements

- Acheter une palette, un aquarium, les bulles et la statue. Les achats répétés d'un objet possédé ne doivent pas refaire payer.
- Vérifier chacun des six tris de classement avec des joueurs ayant des statistiques différentes.
- Le prestige insuffisant doit être refusé. Un prestige valide demande une confirmation, efface uniquement les éléments annoncés et conserve bestiaire/recettes/décorations/statistiques.
- Vérifier les bonus du prestige dans le revenu, la réserve, la vitesse et les fusions suivantes.

## DataStore réel

- Activer les API sur une expérience privée, quitter puis revenir. Vérifier tous les champs du profil, dont les variantes et cosmétiques.
- Vérifier une sauvegarde périodique, une déconnexion normale et une fermeture du serveur.
- Essayer de rejoindre pendant qu'un bail de session est encore détenu : le second chargement doit être refusé sans écraser les données.
- Désactiver l'accès API dans Studio : la session temporaire doit être signalée et ne doit écrire aucun profil de secours.
- Les tests Studio utilisent le suffixe `_Studio`. Ne pas changer ce nom pour pointer sur les profils des joueurs en production.

## Avant publication publique

Ne considérer le gameplay natif validé qu'après réussite de ces essais. Ajuster les valeurs économiques et les probabilités à partir de sessions réelles ; les tableaux configurables facilitent ces ajustements. Publier via Roblox Studio lorsque la validation multijoueur, la persistance réelle et les performances sont satisfaisantes.
