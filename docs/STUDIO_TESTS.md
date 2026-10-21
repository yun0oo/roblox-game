# Vérification dans Roblox Studio

Procédure préparée, **non exécutée dans le cloud Linux**. Les tests automatisés utilisent des primitives moteur simulées ; le rendu, la physique, le réseau et DataStore réel demandent Roblox Studio sur Windows/macOS.

Utiliser une expérience privée avec deux joueurs locaux, puis huit pour les performances. Toute accélération des timers ou attribution de gold de test doit rester dans une copie privée, avec restauration des valeurs de production avant publication.

## Démarrage et navire

- Ouvrir le `.rbxl` non publié et appuyer sur F5 sans changer de case API. Vérifier le personnage, le chargement puis l'arrivée dans sa propre galerie, avec le statut de session temporaire.
- Vérifier l'absence d'erreur serveur/client dans Output. Refaire le démarrage dans une expérience privée publiée avec API désactivées.
- Parcourir le navire : pont continu, coque, hublots, proue, passerelle, huit galeries, aquariums, garde-corps vitrés et pancartes. Le portrait, le pseudo et le niveau doivent correspondre au propriétaire, y compris après départ/réattribution.
- Tous plongent au bassin central. Tester les deux filets grimpables, sur toute leur largeur et dans les deux sens, et le refus de traverser la surface ailleurs. Nager dans six directions, utiliser le propulseur, mourir et réapparaître.
- Tester R6 et R15, y compris un avatar à échelle personnalisée : masque, harnais, bouteilles, épaulières, palmes, lampe et turbines suivent correctement les membres sans gêner les contrôles ou modifier les vêtements.

## Sept marchands et interface

- Vérifier les sept stands, leurs couleurs, noms, spécialités, visages et orientations vers la promenade.
- E à chaque stand ouvre la bonne spécialité. Le panneau montre le plongeur équipé, le niveau, les effets actuels/suivants, le prix et le solde.
- Depuis le menu, parcourir les spécialités à distance : Localiser ferme le panneau et guide vers le bon marchand ; il ne débite rien.
- Acheter près du marchand correct : une seule dépense, un seul niveau, effet réel et mise à jour immédiate sur l'avatar. Un achat Harpon remplace l'arme tenue sans duplicata.
- Refaire avec gold insuffisants, niveau maximum, mauvais marchand et requête distante hors portée : aucun débit ni amélioration indue.
- La pancarte dorée d'amélioration de base est séparée du dépôt d'œufs. F ouvre Base & Aquarium ; comparer le prochain niveau et le bonus avant achat.
- Vérifier les cinq niveaux, croissance de la cuve, filtres et éclairages, absence de coraux et de rochers, capacité exposée et bonus de revenu. L'achat exige sa propre galerie et la proximité de sa pancarte.
- Depuis le menu à distance, Localiser guide vers sa propre pancarte. La pancarte d'un autre joueur ne donne aucun achat.
- Tester les panneaux à petite résolution, le défilement, la fermeture, les touches manette et les boutons tactiles.

## Collecte et inventaire

- Observer six œufs maximum et **un seul boss par palier**. Attendre plusieurs cycles : positions et raretés varient, sans doublon de nid.
- Comparer les six auras et grandes coques ovoïdes, de Common à Secret. E doit fonctionner à la surface de chaque taille, sans traverser les murs.
- Ramasser sous l'eau : retrait immédiat du monde, notification et entrée dans Inventaire. Aucun modèle derrière le joueur, ni ralentissement lié au transport.
- Deux joueurs activent simultanément le même œuf : un seul le reçoit. Répéter le prompt ou son identifiant ne duplique rien.
- Remplir les 24 places : la collecte supplémentaire échoue et l'œuf reste disponible.
- Toucher le collecteur ou tirer à côté : aucun effet. Le toucher au harpon hors base : l’œuf non sécurisé quitte son inventaire et réapparaît au sol. Vérifier la disparition de sa surbrillance, puis sa réapparition sur le nouveau transporteur après ramassage. Les œufs déjà sécurisés ne bougent jamais.
- Mourir ou quitter sous l’eau avec l’œuf non sécurisé : il tombe. Rejoindre sa propre galerie avant : sécurisation, suppression de la surbrillance et sauvegarde permanente. Vérifier le refus du retour rapide avec un œuf non sécurisé, y compris un ramassage pendant les quatre secondes de retour. Rejoindre une autre galerie protège du harpon mais ne sécurise pas l’œuf.

## Boss et harpon

- Le même boss patrouille entre les nids et poursuit un joueur dans toute sa profondeur. Collecter, expirer ou renouveler un œuf ne doit pas supprimer le boss.
- Comparer les six silhouettes et tailles, cornes, yeux, tentacules et dents. Les profondeurs augmentent vitesse, santé et dégâts ; un plongeur mal équipé doit être rattrapé.
- Le harpon affiche canon, flèche, sandows, moulinet, corde, ardillons, animation et impact. Tester ses trois niveaux et chaque limite de portée.
- Tirer à côté : aucun dégât. Un mur bloque le tir. Un coup valide blesse le boss ; un joueur touché ne perd pas de santé, mais son œuf non sécurisé tombe. Le cooldown refuse les tirs trop rapprochés.
- Vaincre un boss : il disparaît une fois et les œufs restent. Il réapparaît seul après 50 à 75 secondes selon le palier, même sans nouvelle apparition d'œuf.
- Aux profondeurs avancées, esquiver les zones annoncées de siphon, choc et vortex. Le pont et toutes les galeries sont immunisés.

## Viseur et caméra M

- Équiper le harpon : viseur visible au curseur sur PC, au centre sur mobile/manette. Sans harpon ou avec un menu ouvert, il disparaît. Comparer son point avec le rayon de visée et l’impact du projectile.
- Appuyer sur M : curseur bloqué au centre, caméra à l’épaule, personnage orienté avec la caméra. Marcher, nager et viser en haut/en bas ; les déplacements restent valides côté serveur.
- Appuyer une seconde fois : retour à la caméra libre, sans décalage résiduel. La rotation avec clic droit doit continuer à fonctionner en mode libre.
- Ouvrir une boutique en mode verrouillé : curseur libre pour acheter et fermer ; le verrouillage reprend à la fermeture. Alt-Tab libère aussi le pointeur. Tester mort/réapparition, saisie dans un champ texte et escalade des filets.
- Maj gauche et droite déclenchent le propulseur sur PC ; M bascule uniquement la caméra. R est libre. Vérifier qu’aucun verrouillage natif Shift ne se superpose.

## Oxygène et progression

- Avec la combinaison 1, traverser les paliers 2 à 6 : avertissement sans mur ni téléportation de niveau. Comparer la survie avec les combinaisons conseillées 10/20/35/50/75 et les protections améliorées.
- Mesurer réserve, consommation en profondeur, stations O₂ et recharge en surface. À zéro, la santé diminue ; les œufs sécurisés sont conservés, l’œuf non sécurisé tombe.
- Vérifier les effets réels de nage, protection, combinaison, lampe et propulseur après achat.

## Aquarium et économie

- Un œuf d'inventaire n'éclot pas avant dépôt. E au terminal ou Inventaire → Déposer, dans sa propre galerie, démarre l'incubation et expose l'œuf dans la cuve.
- Délais : 15/40/90/180/360/720 secondes selon rareté. Répéter la requête ne remet pas le timer à zéro ni ne l'accélère.
- Quitter sa galerie : éclosion automatique et animal visible à l'échéance. Avec DataStore réel, une reconnexion conserve le délai et termine une incubation dépassée.
- Observer les animaux nager dans les vitres, les bulles et les éclairages. Vérifier que tous les revenus sont crédités pendant une minute connecté, puis acheter un équipement avec ces gold.
- Vérifier bestiaire, fusion classique, recettes connues/secrètes, expérience inconnue sans consommation, prestige et cosmétiques.
- Un prestige garde le niveau de base, actualise les équipements portés et remplace le harpon ; aucune pièce ancienne ni arme supplémentaire ne doit rester.

## Événements, sauvegarde et performances

- Tester les avertissements et événements 300/900/2400 s ; bonus de rareté, danger, courants et obscurité. Les œufs transportés ou tombés et les boss partagés survivent au renouvellement des œufs.
- Avec API activées dans une expérience privée, tester sauvegarde périodique, départ, fermeture et reconnexion. Vérifier tous les champs, les échéances et le niveau de base.
- Tester le refus d'une deuxième session concurrente et l'absence d'écriture de secours après erreur de chargement. Studio utilise uniquement le magasin suffixé `_Studio`.
- Tester le rendu de secours sans API de maillage, puis le rendu natif si disponible. Aucune activation particulière ne doit être requise pour afficher les modèles.
- Mesurer FPS/mémoire avec huit joueurs, aquariums pleins, six boss et 36 œufs. Vérifier la distance d'affichage, le chargement progressif et la destruction des modèles devenus lointains.

N'annoncer le gameplay natif et la qualité graphique validés qu'après ces essais. Ajuster l'économie et les performances à partir de sessions réelles avant une publication publique.

## Récif, cuves et ordinateurs — nouvelle version

- Au premier palier, descendre à 325 m : le sable doit être continu hors du passage central, sans ancien carré flottant. Parcourir toute la largeur et les quatre côtés, puis traverser l’ouverture ronde : elle doit rester libre. Répéter aux cinq autres profondeurs ; le dernier fond est fermé.
- Vérifier les parois sur toute leur hauteur, les corniches habillées, les herbiers rubanés, les grandes éponges creuses, les plateaux roses à polypes et les trois silhouettes de corail. Les quatre angles et le dessous des plateaux ne doivent pas donner sur un vide noir. Tester la lisibilité avec la lampe niveau 1 et pendant les événements.
- Observer les sept marchands de face et de côté : peau/coiffure, plastron, gemmes, épaulières, bottes et accessoires de métier. Vérifier les positions par rapport au comptoir, à l’enseigne et au point d’arrivée depuis l’ordinateur.
- Ouvrir les onglets Animaux / Œufs / Bestiaire : cartes hexagonales, sélection, aperçu 3D, nombre possédé, revenus, variantes, recette connue et espèces `???`. Parcourir toutes les pages, puis déposer un œuf sécurisé depuis sa fiche. Un œuf volable ne peut pas être incubé.
- Vérifier 1920×1080, 1280×720, portrait mobile et rotation : fiche à droite ou sous la grille, défilement et pagination accessibles, navigation compacte sur petit écran. Fermer/réouvrir les boutiques et tester M/Maj avec un menu ouvert.
- Comparer les modèles Quaternius : poisson-clown rayé, papillon, globe, lune, raie, espadon, dauphin, baleine et six boss. Vérifier leur orientation, leurs yeux et leurs dents, dans le rendu natif et dans le secours sans API de maillage.
- Déposer les 24 œufs de plusieurs raretés : ils restent dans la cuve d'incubation séparée sans dépasser les vitres. Les poissons ne doivent apparaître que dans l'aquarium principal, après l'échéance.
- E à son ordinateur : menu des sept destinations, téléportation devant le bon marchand et ouverture de sa spécialité. Contrôler l'absence de débit, la collision à l'arrivée et l'acceptation par le contrôle de déplacement serveur.
- Refuser le même transfert depuis l'exploration, depuis l'ordinateur d'un autre joueur, avec des coordonnées envoyées à la place d'une clé et pendant le cooldown.
- R6 et R15 : nager horizontalement, monter/descendre, rester immobile, viser au harpon et tourner en mode caméra M. La nage ne doit plus redémarrer à chaque image. Observer aussi le deuxième joueur.
- Osciller près de la surface : pas d'alternance rapide des poses. Remonter le filet, marcher sur le pont, mourir et réapparaître : vérifier la restauration de la marche et des joints.
- Tester huit clients avec aquariums pleins, cuves pleines et récifs visibles ; mesurer FPS/mémoire et vérifier le budget de détails. Ces essais natifs restent nécessaires avant publication.

## Modèles de décor importés

- Tester sans aucune API de maillage activée : les coraux roses, éponges bleues et algues courbées doivent être des sculptures complètes ; aucun ellipsoïde/cylindre de remplacement ne doit apparaître. Refaire avec le rendu natif disponible.
- Explorer les six fonds, les quatre parois, les corniches, l’épave et les arches. Vérifier les textures colorées des rochers et le sol toujours continu. Les jardins doivent aussi utiliser les nouveaux modèles dans les aquariums.
- S’éloigner des plantes puis revenir : changement de détail sans branches coupées ni modèles définitivement disparus. Contrôler une arrivée tardive et les réapparitions.
- Vérifier les œufs, boss, harpon et animaux près d’un récif dense : les budgets visuels sont distincts. Mesurer FPS/mémoire à huit joueurs, avant et après plusieurs allers-retours entre paliers. Les plafonds automatiques ne constituent pas une validation de performances natives.
- Les attributions apparaissent dans Guide ; les conditions intégrales sont dans le ZIP et dans ReplicatedStorage.ThirdPartyNotices.

## HUD discret et base rénovée

- Au pont avec oxygène plein : jauge O₂ cachée, gold et profondeur compacts ; ☰ ouvre/ferme les huit pages. Inventaire et harpon restent accessibles sans ouvrir ce menu.
- En plongée : O₂ réapparaît au-dessus de la barre d’outils native, passe au rouge sous 20 %, puis disparaît après recharge complète en surface. Vérifier ordinateur, mobile et format paysage sans chevauchement du joystick, des boutons tactiles ou de l’inventaire Roblox.
- L’événement tient sur une ligne ; son nom actif et sa durée restent lisibles. Maximum deux notifications ; elles disparaissent après cinq secondes. Un échec de sauvegarde reste affiché discrètement.
- Porter un œuf affiche le retour ; l’avoir sécurisé à la base affiche le dépôt. Une incubation commencée retire la consigne de dépôt inutile.
- Comparer la terrasse, les caisses Kenney, les parois nervurées, le verre et les reflets avec/sans API de maillage. Les cinq niveaux d’aquarium conservent une vue dégagée, sans corail ; le socle reste au même niveau et le portrait remonte avec la cuve.
- Observer le nouveau fusil Kenney en mouvement : son corps ne doit pas glisser par rapport à la poignée ou à la flèche. Tester nage, escalade, tir, corde et changements d’équipement en R6 et R15.
