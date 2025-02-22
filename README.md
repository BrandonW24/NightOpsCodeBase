### **NewGameManager.lua**

#### Key Functions:

1. **`LocalStartMatch()`**
   This function is responsible for starting a match. It checks if at least two players have weapons and are ready to play. If conditions are met, it initializes the match timer, moves eligible players to the arena, and starts the game soundtrack. It also ensures that the lobby doors are closed and updates the scoreboard.
2. **`Time_ComputeTime()`**
   This function manages the match timer. It decrements the timer each frame and checks if the match has ended. When the timer reaches zero, it triggers the end of the match, moving players back to the lobby, resetting their stats, and cleaning up game props.
3. **`Powerups_UpdateSpawnPowerups()`**
   This function handles the spawning of powerups (e.g., health and ammo) during the match. It randomly selects a powerup type and spawn location, then syncs the spawn across all clients. Powerups are spawned at regular intervals defined by `number_powerupNextSpawnTime`.
4. **`Scoreboard_SetPlayers()`**
   This function initializes the scoreboard by assigning each player to a scorecard. It ensures that the scoreboard is updated with the correct player data, including kills, deaths, and assists. It also handles the sorting of players based on their scores.

------

### **WeaponScript.lua**

#### Key Functions:

1. **`FireLogic()`**
   This function handles the firing logic for weapons. It checks if the weapon can fire (based on ammo, fire rate, and reload state), then performs a raycast or spawns a projectile depending on the weapon type. It also applies damage to players or objects hit by the weapon and triggers visual and audio effects.
2. **`Reload()`**
   This function manages the reloading of weapons. It checks if the player has enough ammo clips, reduces the clip count, and refills the weapon's ammo. If no clips are available, it plays an empty sound. The reloading process is synced across all clients.
3. **`PlayGunSound(soundStringIdentifier)`**
   This function plays different gun sounds (e.g., firing, reloading, empty) based on the provided identifier. It uses a string-based system to reduce network overhead when syncing sounds across clients.
4. **`OnPrimaryGrabBegin()`**
   This function is triggered when a player grabs a weapon. It sets the weapon's owner, updates the player's state to indicate they have a weapon, and plays a grab sound. It also ensures the weapon's local and non-local objects are correctly enabled or disabled.

------

### **NewGamePlayer.lua**

#### Key Functions:

1. **`TakeDamage(number_damageAmount, number_fromPlayerActorID)`**
   This function handles player damage. It reduces the player's health and checks if the player has been defeated. If the player's health reaches zero, it triggers respawn logic, updates kill/death/assist stats, and syncs the changes across all clients.
2. **`LocalStartRespawnPlayer()`**
   This function initiates the respawn process for a player. It moves the player to the respawn area, starts a respawn timer, and updates the respawn timer UI. Once the timer ends, the player is moved back to the arena.
3. **`LocalResetModes()`**
   This function resets the player's state at the end of a match. It clears their weapon, match state, and death status. It also updates the player's score in the cloud variables, ensuring persistent score tracking across sessions.
4. **`DeliverResultsToPlayers()`**
   This function updates player stats (kills, deaths, assists) when a player is defeated. It ensures that the player who delivered the final blow gets a kill, and any players who dealt damage get assists.

------

### **MountedTurret.lua**

#### Key Functions:

1. **`FireLogic()`**
   This function handles the turret's firing logic. It performs a raycast to detect hits, applies damage to players or objects, and spawns hit effects. It also triggers visual effects like muzzle flashes and plays firing sounds.
2. **`UpdateInput_Movement()`**
   This function processes player input to control the turret's movement. It reads joystick input to rotate the turret horizontally and vertically, ensuring smooth and responsive controls. The turret's rotation is synced across all clients.
3. **`LocalApplyDamageToPlayer(number_newDamageAmount, number_newPlayerActorID)`**
   This function applies damage to the player controlling the turret. If the player's health drops to zero, they are ejected from the turret, and the turret is deactivated.
4. **`OnSeated()`**
   This function is triggered when a player enters the turret. It sets the turret's active state, enables the turret's controls, and plays an activation sound. It also ensures the turret's UI and visual effects are updated.

------

### **LobbyDoorsButton.lua**

#### Key Functions:

1. **`ToggleDoor()`**
   This function toggles the state of the lobby doors (open/closed). It ensures that the doors only operate when a match is not in progress and syncs the door state across all clients. It also triggers door animations.
2. **`SetDoorState(value)`**
   This function sets the door state (open or closed) based on the provided value. It updates the door's visual state and ensures the change is synced across all clients.
3. **`UpdateDoorDirector()`**
   This function manages the door animations. It stops any ongoing animations and plays the appropriate sequence (opening or closing) based on the current door state.

------

### **RenderingManager.lua**

#### Key Functions:

1. **`SetRenderingSettings()`**
   This function configures rendering settings based on whether the player is the master client or a regular client. It disables certain visual effects (e.g., fog, bloom) for the master client to optimize performance.

2. **`UpdateRendererMaterial(renderer_mesh, bool_toggle)`**
   This function updates the material of a button based on its toggle state. It switches between "on," "off," and "pointer" materials to provide visual feedback for UI interactions.

3. **`Fog_OnClick()`**
   This function toggles fog effects on or off. It updates the fog's visual state and changes the button's material to reflect the current setting.

4. **`MotionBlur_OnClick()`**
   This function toggles motion blur effects on or off. It updates the motion blur's visual state and changes the button's material to reflect the current setting.

   

------



### **UIPlayerScoreboardCard.lua**

This script manages the UI elements for individual player scorecards on the scoreboard. It displays player stats such as kills, assists, deaths, and score. The script ensures that the scoreboard is updated in real-time as players earn points or take damage during the match.

#### Key Functions:

1. **`LocalUpdateText()`**
   This function updates the text fields on the scorecard with the latest player stats (kills, assists, deaths, and score). It is called whenever the player's stats change.
2. **`LocalSetPlayer(string_encodedPlayerActorID)`**
   This function assigns a player to the scorecard by decoding the player's Actor ID and finding the corresponding player in the room. It ensures that the scorecard displays the correct player's information.
3. **`SetPlayer(number_playerActorID)`**
   This function is called to assign a player to the scorecard. It encodes the player's Actor ID and invokes `LocalSetPlayer` across all clients to ensure synchronization.
4. **`UpdateText()`**
   This function triggers `LocalUpdateText` across all clients to ensure that the scorecard is updated with the latest player stats.

------

### **CanFluid.lua**

This script handles the behavior of water cans in the game. Players can grab these cans, open them, and tilt them to pour water. The script manages the can's state (open/closed), plays appropriate sounds, and handles the fluid draining mechanics.

#### Key Functions:

1. **`OpenCan()`**
   This function opens the can, playing a sound and switching the can's mesh from closed to open. It is triggered when the player interacts with the can.
2. **`PlayLoopingAudio(audioSource_source)`**
   This function ensures that the pouring sound loops correctly while the can is tilted and draining fluid.
3. **`Update()`**
   This function handles the fluid draining logic. It checks the can's angle and drains fluid if the can is tilted beyond a certain threshold. It also stops the pouring sound and particle effects when the can is upright or empty.
4. **`OnClick()`**
   This function is triggered when the player interacts with the can. It calls `OpenCan` to open the can and prepare it for pouring.

------

### **HealthPowerup.lua**

This script manages health powerups in the game. When a player with low health enters the powerup's trigger volume, they gain health, and the powerup is consumed. The script also spawns a visual effect when the powerup is used.

#### Key Functions:

1. **`UsedPowerup()`**
   This function spawns a visual effect to indicate that the powerup has been used and then destroys the powerup object. It is called across all clients to ensure synchronization.
2. **`OnTriggerEnter(other)`**
   This function is triggered when a player enters the powerup's trigger volume. It checks if the player is eligible to receive the powerup (i.e., they have low health and are in a match) and then applies the health boost. It also calls `UsedPowerup` to consume the powerup.

------

### **AmmoPowerup.lua** and **AmmoPowerup_non_expiring.lua**

These scripts manage ammo powerups in the game. When a weapon enters the powerup's trigger volume, the weapon's ammo is replenished, and the powerup is consumed. The non-expiring version of the script does not destroy the powerup after use.

#### Key Functions:

1. **`UsedPowerup()`**
   This function spawns a visual effect to indicate that the powerup has been used. In the standard version, it also destroys the powerup object. In the non-expiring version, the powerup remains in the game.
2. **`OnTriggerEnter(other)`**
   This function is triggered when a weapon enters the powerup's trigger volume. It checks if the weapon is eligible to receive the powerup (i.e., it has low ammo) and then replenishes the ammo. It also calls `UsedPowerup` to consume the powerup (in the standard version).

------

### **ArenaLift.lua**

This script controls the behavior of lifts in the arena. When a player enters the lift's trigger volume, the lift rises to its raised position. When the player exits, the lift returns to its default position.

#### Key Functions:

1. **`UpdateLiftAnimation()`**
   This function interpolates the lift's position between its default and raised positions based on the current state (`bool_localLiftState`). It is called every frame to ensure smooth movement.
2. **`ActivateLift()`**
   This function sets the lift's state to "raised" and is called when a player enters the lift's trigger volume. It is synchronized across all clients.
3. **`DeactivateLift()`**
   This function sets the lift's state to "default" and is called when a player exits the lift's trigger volume. It is synchronized across all clients.
4. **`OnTriggerEnter(other)`**
   This function is triggered when a player enters the lift's trigger volume. It calls `ActivateLift` to raise the lift.
5. **`OnTriggerExit(other)`**
   This function is triggered when a player exits the lift's trigger volume. It calls `DeactivateLift` to lower the lift.