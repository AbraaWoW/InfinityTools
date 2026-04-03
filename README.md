# Infinity Tools
Suite d’addons modulaire pour WoW qui regroupe une UI centrale, des outils Mythic+, un tracker de combats (InfinityBoss) et un moteur JSON/LibreSprites adaptable aux besoins de raid et de donjon.

## Organisation
- **InfinityCore** : moteur principal `InfinityTools` + `InfinityGrid`, système de modules, gestion des profils, skins ElvUI/NDui et helpers communs.  
- **UI/** : panneau de configuration (`RRTUI`) avec onglets General, Raid, Note, QoL, Tools, Boss, etc., barre de statut personnalisée et état dynamique.  
- **InfinityMythicPlus** : modules et extensions ciblant Mythic+ et utilities M+.  
- **InfinityBoss** (+ `InfinityBossData`, `InfinityBossVoice`) : UI personnalisée pour les boss, base de données d’évènements/déclencheurs et packs vocaux.  
- **Libs**, **InfinityMedia**, **Media**, **Scripts** : dépendances tierces, textures, sons, macros utilitaires utilisés par les extensions.  
- **Modules/** : composants partagés, par exemple `PrivateAura`, `Modules` de testing, etc.

## Modules InfinityMythicPlus
### Utilitaires généraux (`RevTools.*`)
- `MiniTools`, `StreamerTools`, `AutoBuy`, `CastSequence`, `ChatChannelBar`, `MicroMenu`, `PlayerPosition`, `PlayerStats`, `RaidMarkerPanel`, `SpellAlert` (+ panneau complet) : raccourcis, auto-achats, barres de minuterie, marqueurs, alertes visuelles et audit de stats.  
- `PveInfoPanel`, `PveKeystoneInfo`, `CDTracker`, `SpellAlert`, `YYSound`: affichages complémentaires autour du PVE/Mythic+.  

### Informations Mythic+ (`RevMplusInfo.*`)
- `MDTIconHook`, `MythicIcon`, `RunHistory`, `SpellInfo`, `Tooltip`, `TeleMsg`, `MythicFrame`, `SpellData` : réécritures de l’UI MDT, historique des runs, lookup d’informations sur les sorts, tooltips enrichis, affichage “Mythic+ Info”.  
- `MythicDamage`, `MythicCast`, `InterruptTracker` : calculs de dégâts, suivi des sorts, moniteur de casts et interruptions.  

### Fonctionnalités spécifique aux classes (`RevClass.*`)
- `BrewmasterStagger`, `FocusCast`, `NoMoveSkillAlert`, `RangeCheck`, `SpellEffectAlpha`, `SpellQueue`, `PlayerStats` : aides de classe (scaling, alertes de déplacement, queue) partagées entre modules.  

### Minis et PTR
- `RevPTR.MiniTools`, `RevPTR.SetKey` : utilitaires de PTR pour tests et manipulations rapides.

## InfinityBoss
- Interface dédiée pour bosses avec onglets, timelines fixes, import/export, gestionnaire d’alerte et d’assignations.  
- Base de données `InfinityBossData` garde les scripts d’évènements ; `InfinityBossVoice` fournit la lecture vocale.  
- Changelog accessible manuellement (popup supprimé sauf clic sur le bouton) et panneaux d’options on-the-fly.  

## Infinity Raid Tools UI
- Le panel principal (`RRTUI`) regroupe onglets `General`, `Raid`, `Note`, `PrivateAura`, `EncounterAlerts`, `QoL`, `Tools`, `Boss`.  
- Barre de statut personnalisée avec lien Twitch (`https://www.twitch.tv/abraa_`) et thème dynamique synchronisé sur RRT.  
- Section Tools ouvre la configuration Infinity Tools/MythicPlus ; onglet Boss garde un bouton “Changelog”.

## Installation & configuration
1. Copier l’ensemble du dossier dans `World of Warcraft/_retail_/Interface/AddOns`.  
2. Activer `InfinityTools` (et `InfinityBoss`/`InfinityMythicPlus` si besoin) via l’écran d’addons ou `/iboss`.  
3. Utiliser `/it` ou `Infinity Tools → Tools` pour ouvrir la fenêtre `RRTUI`, activer les modules, basculer les onglets et modifier les options.  
4. Chaque module expose son propre layout : `InfinityTools:RegisterModuleLayout`. Les settings sont persistés via `InfinityToolsDB`.

## Ressources externes
- **Twitch** : https://www.twitch.tv/abraa_  
- **CurseForge** : https://www.curseforge.com/wow/addons/infinitytools  

## Contribution
- Ajouter des modules dans `InfinityMythicPlus/Modules` ou `InfinityBoss`.  
- Respecter le système `REGISTER_LAYOUT()` pour que l’UI les expose dans `InfinityTools`.  
- Garder `InfinityTools` comme alias global tant que les modules tiers y accèdent.
