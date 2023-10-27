do -- script NewNewGameManager 
	
	-- get reference to the script
	local NewGameManager = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are exposed and accessible through the unity inspector
	
	local number_playerMaxHealth = SerializedField("(Player Properties) Max Health", Number);
	local number_maxMatchTime = SerializedField("(Properties) Max Time Seconds", Number);
	local number_respawnTime = SerializedField("(Properties) Respawn Time Length Seconds", Number);
	local gameObjects_arenaSpawns = SerializedField("(Objects) Arena Spawn Points", GameObject, 16);
	local gameObjects_lobbySpawns = SerializedField("(Objects) Lobby Spawn Points", GameObject, 16);
	local gameObjects_powerupSpawns = SerializedField("(Objects) Powerup Spawn Points", GameObject, 16);
	local textMeshes_timerTexts = SerializedField("(Objects) Timer Texts", TextMesh, 12);
	local gameObjects_respawnTimerTexts = SerializedField("(Objects) Respawn Timer Text", GameObject, 4);
	local gameObject_respawnArea = SerializedField("(Objects) Respawn Area", GameObject);
	local gameObject_lobbyDoorsButton = SerializedField("LobbyDoorsButton", GameObject);
	local gameObject_playerUICardParentPrefab = SerializedField("Player UI Cards Parent", GameObject);
	local gameObject_playerUICardPrefab = SerializedField("Player UI Card Prefab", GameObject);
	local gameObject_playerDeathPrefab = SerializedField("Player Death Prefab", GameObject);
	local gameObject_ammoPowerupPrefab = SerializedField("Ammo Powerup Prefab", GameObject);
	local gameObject_healthPowerupPrefab = SerializedField("Health Powerup Prefab", GameObject);
	local number_powerupNextSpawnTime = SerializedField("(Properties) Powerup Next Spawn Time", Number);
	local audioClip_gameErrorSound = SerializedField("(Sounds) Game Error Sound", AudioClip);
	local gameObject_centerTurretGameObject = SerializedField("Center Turret", GameObject);
	local textMesh_gameManagerText = SerializedField("(Objects) Game Manager Text", TextMesh);
	local number_maxMoveToLobbyTimes = SerializedField("(Properties) Max Times to try moving back to lobby", Number);
	local number_maxMoveToArenaTimes = SerializedField("(Properties) Max Times to move players to arena", Number);
	local audioSource_preGameSoundtrack = SerializedField("(Objects) Pre Game Soundtrack", AudioSource);
	local audioSource_gameSoundtrack = SerializedField("(Objects) Game Soundtrack", AudioSource);
	local gameObject_specatorCameras = SerializedField("(Objects) Spectator Cameras", GameObject);
	local number_scoreboardSetCardsTickRate = SerializedField("(Properties) Scoreboard Set Cards Tick Rate", Number);

	local cloudvariabletextobject = SerializedField("Cloud variable text object", TextMesh);

	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are syncronized across clients
	--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)

	local server_number_matchTimer = SyncVar(NewGameManager, "a");
	local server_bool_matchOngoing = SyncVar(NewGameManager, "b");

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local number_matchTimer = 0;
	local number_matchTimerEnd = 0;
	local bool_matchOngoing = false;

	local audioSource_manager = nil;
	local mlplayer_localPlayer = nil;

	local bool_movingPlayersToArena = false;
	local bool_returningPlayersToLobby = false;
	local number_currentTimesMovedToLobby = 0;
	local number_currentTimesMovedToArena = 0;
	local number_scoreboardSetCardsNextTickTime = 0;
	local number_computeMatchTimeNextTick = 0;

	local textArray_respawnTimerText = {}; --Text[] array
	local gameObjects_scoreCardsArray = {}; --GameObject[] array
	local NewGamePlayer_Array_ProxyPlayersInRoom = {}; --NewGamePlayer[] array

	local number_powerup_nextTime = 0;
	local bool_scoreboardCards_initalized = false;

	--Cloud variable information
	local SCORE_KEY = "score";
    local localPlayerScore = 0;
	local results_fromCloud = nil;
	local scorearray = {};

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHARED ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHARED ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHARED ||||||||||||||||||||||||||||||||||||||||||||||

	local function GetRandomPositionFromArray(GameObjectLocations_Array)
		local randomIndex = math.random(1, #GameObjectLocations_Array);

		return GameObjectLocations_Array[randomIndex].transform.position;
	end

	local function GetFormattedTimeText(timeValue)
		local number_minutes = Mathf.Floor(timeValue / 60);
		local number_seconds = Mathf.Round(timeValue % 60);

		local string_zeroTextPadding = "";

		if (number_seconds < 10) then string_zeroTextPadding = "0"; end
		
		local string_final = tostring(number_minutes) .. ":" .. string_zeroTextPadding .. tostring(number_seconds);
		return string_final;
	end

	local function EncodeActorID(number_playerActorID)
		return tostring(number_playerActorID);
	end

	local function DecodeActorID(string_encodedPlayerActorID)
		return tonumber(string_encodedPlayerActorID);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SPECTATOR CAMERAS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SPECTATOR CAMERAS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SPECTATOR CAMERAS ||||||||||||||||||||||||||||||||||||||||||||||

	local function SetSpecatorCamerasVisibility()
		local newGamePlayer = mlplayer_localPlayer.PlayerRoot.GetComponent(NewGamePlayer);

		if(newGamePlayer.script.GetPlayerIsCurrentlyInMatchState() == true) then
			gameObject_specatorCameras.SetActive(false);
		else
			gameObject_specatorCameras.SetActive(true);
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - POWERUPS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - POWERUPS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - POWERUPS ||||||||||||||||||||||||||||||||||||||||||||||

	--[[
		Encodes a parameter call for spawning a powerup in an arena.
		Because in lua numbers are naturally doubles, and when passed through the photon servers a number call is 9 bytes!
		And because we need to pass in 2 number parameters (1 for what powerup to use, and 1 for what powerup location to use)... thats 18 bytes!
		So to save on space they will be encoded into a string, and the precision will be reduced.
		Strings in photon are 5 + length of string bytes long. (according to yashar, size = 4(int32 size) + 1(byte type) + string.length)
		For this since we are only really working with integers, the precison afforded by "double" is WAY over what we need.
		- So first integer is only going to be one digit (to select which powerup to spawn).
		- The next integer varies from 1 to 2 digits (the index of the powerup spawn location array to use)
		So all together, the byte size of the encoded call is around 7 - 8 bytes (12 - 11 bytes saved)
	--]]
	local function Powerups_EncodeParameters(number_selection, number_index)
		return tostring(number_selection) .. tostring(number_index);
	end

	local function Powerups_SpawnPowerupInArena(string_encodedParameters)
		--decode our encoded parameters
		local number_selection = tonumber(string_encodedParameters:sub(1, 1)); --always 1 digit
		local number_index = tonumber(string_encodedParameters:sub(2, string.len(string_encodedParameters))); --varies from 1 to 2 digits

		local powerupLocation = gameObjects_powerupSpawns[number_index].transform.position;

		if(number_selection > 2) then
			Object.Instantiate(gameObject_healthPowerupPrefab, powerupLocation, Quaternion(0, 0, 0, 0));
			Debug.Log("Spawning Powerup (Health)...");
		else
			Object.Instantiate(gameObject_ammoPowerupPrefab, powerupLocation, Quaternion(0, 0, 0, 0));
			Debug.Log("Spawning Powerup (Ammo)...");
		end
	end

	local function Powerups_UpdateSpawnPowerups()
		if (mlplayer_localPlayer.isMasterClient == true) then
			if (bool_matchOngoing == true) then
				if(number_powerup_nextTime < Time.time) then
					local number_randomPowerupSelection = math.random(1, 4);
					local number_randomPowerupLocationIndex = math.random(1, #gameObjects_powerupSpawns);
					local string_encodedParameters = Powerups_EncodeParameters(number_randomPowerupSelection, number_randomPowerupLocationIndex);

					--Invoke Powerups_SpawnPowerupInArena() across all clients.
					LuaEvents.InvokeLocalForAll(NewGameManager, "I", string_encodedParameters);

					number_powerup_nextTime = Time.time + number_powerupNextSpawnTime;
				end
			end
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SCOREBOARD ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SCOREBOARD ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SCOREBOARD ||||||||||||||||||||||||||||||||||||||||||||||
	--These functions handle most of the scoreboard logic for the game.

	--This instantiates a scoreboard card and adds it to the "gameObjects_scoreCardsArray" array.
	local function Scoreboard_CreateCard()
		--spawn our scoreboard card prefab, and parent it to the scoreboard cards parent.
		local gameObject_playerUICard = Object.Instantiate(gameObject_playerUICardPrefab, Vector3(0, 0, 0), Quaternion(0, 0, 0, 0));
		gameObject_playerUICard.transform.SetParent(gameObject_playerUICardParentPrefab.transform);

		--because we parrented it to a UI group that has a stacking component (i.e. automatically moves and spaces UI elements within it)
		--make sure we are zeroed out as to not screw things up.
		gameObject_playerUICard.transform.localPosition = Vector3(0, 0, 0);
		gameObject_playerUICard.transform.localRotation = Quaternion(0, 0, 0, 0);
		gameObject_playerUICard.transform.localScale = Vector3(1, 1, 1); --this is important as scale changes

		--add it to our 
		table.insert(gameObjects_scoreCardsArray, gameObject_playerUICard);
	end

	--Destroys all of the score cards inside of "gameObjects_scoreCardsArray" and clears the array.
	local function Scoreboard_CleanupCards()
		for i, gameObject_scoreCard in ipairs(gameObjects_scoreCardsArray) do
			Object.Destroy(gameObject_scoreCard);
		end

		gameObjects_scoreCardsArray = {};
	end

	--Calls UpdateText() on all of the score cards in the "gameObjects_scoreCardsArray" array.
	local function Scoreboard_UpdateCards()
		for i, gameObject_scoreCard in ipairs(gameObjects_scoreCardsArray) do
			--NOTE: I would prefer to precache the entire array so we don't have to do a GetComponent() call
			--for each element in the list which can become expensive, but there have been issues before somehow where 
			--the object reference gets lost somehow? so we do a call to make sure that we do infact have it.
			local card = gameObject_scoreCard.GetComponent(UIPlayerScoreboardCard);
			card.script.UpdateText();
		end
	end

	--Cleans up the scoreboard list before, and creates a new list of scoreboard cards matching the amount of players in the room.
	local function Scoreboard_CreateCards()
		Debug.Log("creating scoreboard cards...");

		--clear our list if we had one before
		Scoreboard_CleanupCards();

		--set this to false as on this frame we are only going to be instantiating new cards (because we can't access our scorecard script on that prefab, not yet)
		--this is important to have to handle setting up our cards which is found in NewGameManager.Update().
		bool_scoreboardCards_initalized = false;

		--get all the players in the room
		local mlplayers_playersInRoom = Room.GetAllPlayers();

		--spawn a card for each player
		for i, mlplayer_player in ipairs(mlplayers_playersInRoom) do
			Scoreboard_CreateCard();
		end
	end

	--Iterates through our list of scoreboard cards, and attempts to set the player that each one watches.
	--If it fails too then the scoreboard cards are not initalized and this will keep running until it is initalized.
	local function Scoreboard_SetPlayers()
		Debug.Log("setting scoreboard cards...");

		--When players are in the process of joining the room, while the player count changes, the MLPlayer component on it is not fully initalized.
		--so we can't pull its GUID, we can only wait until they have finished joining the room where we can pull that data.
		--and in addition to that the time it would take to do that can change drastically, there is really no certain way to know.
		--NOTE: ideally we do it all with OnPlayerJoin and OnPlayerLeave, however we can't do that... (otherwise it would have been done that way)
		--because we'd have to spawn a scoreboard card, and we can't access our scoreboard card script on it until a few frames later when its initalized.
		--NOTE 2: I have attempted when spawning the scoreboard card to change the name of the object to the GUID of the player it is supposed to watch,
		--so when the card does get initalized it will check its own name to get the player GUID it needs to watch, but this doesn't work across clients.
		--NOTE 3: So learned about MLPlayer.ActorID, for the current needs of the scoreboard this DRASTICALLY reduces the data needed since ActorID's are persistent.

		--get the players in the room
		local mlplayers_playersInRoom = Room.GetAllPlayers();

		--a check that will be incremented for every sucessfully set scorecard.
		--this number should match the amount of players in the room currently after the loop.
		--if it doesn't then the list wasn't fully initalized.
		local number_initalizationChecks = 0;

		--iterate through each MLPlayer in the room.
		for i, mlplayer_player in ipairs(mlplayers_playersInRoom) do
			--get our scorecard gameobject by index and get the script on it (the length of our scorecard array should match the amount of players in mlplayers_playersInRoom)
			local card = gameObjects_scoreCardsArray[i].GetComponent(UIPlayerScoreboardCard);

			--some checks to make sure its safe
			if(card ~= nil) then
				if(card.script ~= nil) then
					--set the player actor ID on the card
					card.script.SetPlayer(mlplayer_player.ActorID);

					--now check if it was set...
					--internally for the script it will do a Room.FindPlayerByGuid() to get the MLPlayer object.
					--if it was set then the initalization check will be incremented.
					if(card.script.IsSet() == true) then
						number_initalizationChecks = number_initalizationChecks + 1;
					end
				end
			end
		end

		--if the amount of initalization checks is less than the players that are in the room, then we failed to initalize.
		--if it matches then we are sucessful.
		if(number_initalizationChecks < #mlplayers_playersInRoom) then
			bool_scoreboardCards_initalized = false;
		else
			bool_scoreboardCards_initalized = true;
			Debug.Log("scoreboard cards sucessfully initalized!");
		end
	end

	local function Scoreboard_SortCards()
		local UIPlayerScoreboardCard_previousCard = nil;

		for i, gameObject_scoreCard in ipairs(gameObjects_scoreCardsArray) do
			local card = gameObject_scoreCard.GetComponent(UIPlayerScoreboardCard);

			if(UIPlayerScoreboardCard_previousCard ~= nil) then
				local number_currentScoreCardValue = card.script.GetLocalScoreValue();
				local number_previousScoreCardValue = UIPlayerScoreboardCard_previousCard.script.GetLocalScoreValue();

				local number_currentCardSiblingIndex = gameObject_scoreCard.transform.GetSiblingIndex();
				local number_previousCardSiblingIndex = UIPlayerScoreboardCard_previousCard.gameObject.transform.GetSiblingIndex();

				if(number_currentScoreCardValue > number_previousScoreCardValue) then
					gameObject_scoreCard.transform.SetSiblingIndex(number_previousCardSiblingIndex);
					UIPlayerScoreboardCard_previousCard.gameObject.transform.SetSiblingIndex(number_currentCardSiblingIndex);
				else
					gameObject_scoreCard.transform.SetSiblingIndex(number_currentCardSiblingIndex);
					UIPlayerScoreboardCard_previousCard.gameObject.transform.SetSiblingIndex(number_previousCardSiblingIndex);
				end

				--Transform.SetSiblingIndex(index)
				--Transform.SetAsFirstSibling()
				--Transform.SetAsLastSibling() 
				--Transform.GetSiblingIndex()
			end

			UIPlayerScoreboardCard_previousCard = card;
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| CLOUD VARIABLE DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| CLOUD VARIABLE DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| CLOUD VARIABLE DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

			--@param result ScoreBoardEntry[]
	local function OnSuccess(result)
		-- Success
		Debug:log("Cloud collected scoreboard successfully");    

		scorearray = {};

		for i,v in ipairs(result) do
			Debug:Log(string.format("Rank: %02d, Player: %s, Score: %.2f",i, v.UserDisplayName, v.Value));   
			results_fromCloud = string.format("Rank: %2d, %s, Score: %2d \n \n ",i, v.UserDisplayName, v.Value);
			table.insert(scorearray, results_fromCloud);
			Debug.log("Value has been added to score array");

		end  

		--for i, cloudinfo in pairs(scorearray) do
		--cloudvariabletextobject.text = cloudvariabletextobject.text .. cloudinfo[i].text;
		--end

		cloudvariabletextobject.text = table.concat(scorearray);
		
	end

	local function OnRejected()
		-- Rejected 
		Debug:log("Cloud not collect scoreboard");    
	end

	--@param err string
	local function OnError(err)
		Debug:Log(string.format("Failed: %s", err));     
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - WARPING/POSITIONING ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - WARPING/POSITIONING ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - WARPING/POSITIONING ||||||||||||||||||||||||||||||||||||||||||||||

	local function DestroyAllGameProps()
		--Self note: tried to do it just with using the Component names but that didn't work...
		--so this method, while its more expensive, certainly can still get the job done and does work.
		local GameObjectArray = Object.FindObjectsOfType(GameObject);

		for i, GameObjectItem in ipairs(GameObjectArray) do
			local WeaponScriptObject = GameObjectItem.GetComponent(WeaponScript);
			local HealthPowerupObject = GameObjectItem.GetComponent(HealthPowerup);
			local AmmoPowerupObject = GameObjectItem.GetComponent(AmmoPowerup);
			local CanFluidObject = GameObjectItem.GetComponent(CanFluid);

			if(WeaponScriptObject ~= nil) then
				--WeaponScriptObject.script.ForceRelease();
				WeaponScriptObject.gameObject.GetComponent(MLGrab).ForceRelease();
				Object.Destroy(GameObjectItem.transform.root.gameObject, 0);
			end

			if(HealthPowerupObject ~= nil) then
				Object.Destroy(GameObjectItem.transform.root.gameObject, 0);
			end

			if(AmmoPowerupObject ~= nil) then
				Object.Destroy(GameObjectItem.transform.root.gameObject, 0);
			end

			if(CanFluidObject ~= nil) then
				CanFluidObject.script.ForceRelease();
				Object.Destroy(GameObjectItem.transform.root.gameObject, 0);
			end
		end

		if CloudVariables.IsEnabled then
			Debug.log("Cloud variables are enabled, attempting to get scoreboard...");
			CloudVariables:GetScoreBoard("NightOps_score").Then(OnSuccess, OnRejected).Catch(OnError);
		end

	end

	local function DestroyAllCans()
		--Self note: tried to do it just with using the Component names but that didn't work...
		--so this method, while its more expensive, certainly can still get the job done and does work.
		local GameObjectArray = Object.FindObjectsOfType(GameObject);

		for i, GameObjectItem in ipairs(GameObjectArray) do
			local CanFluidObject = GameObjectItem.GetComponent(CanFluid);

			if(CanFluidObject ~= nil) then
				CanFluidObject.script.ForceRelease();
				Object.Destroy(GameObjectItem.transform.root.gameObject, 0);
			end
		end
	end

	local function DestroyAllUnequippedWeapons()
		--Self note: tried to do it just with using the Component names but that didn't work...
		--so this method, while its more expensive, certainly can still get the job done and does work.
		local GameObjectArray = Object.FindObjectsOfType(GameObject);

		for i, GameObjectItem in ipairs(GameObjectArray) do
			local WeaponScriptObject = GameObjectItem.GetComponent(WeaponScript);

			if(WeaponScriptObject ~= nil) then
				if(WeaponScriptObject.script.IsHeld() == false) then
					WeaponScriptObject.script.ForceRelease();
					Object.Destroy(GameObjectItem.transform.root.gameObject, 0);
				end
			end
		end
	end

	local function MovePlayersToLobby()
		for i, NewGamePlayer_Object in ipairs(NewGamePlayer_Array_ProxyPlayersInRoom) do
			local location = GetRandomPositionFromArray(gameObjects_lobbySpawns);

			NewGamePlayer_Object.script.WarpToPoint(location);
			NewGamePlayer_Object.script.SetCurrentlyInMatch(false);
		end

		SetSpecatorCamerasVisibility();

		number_currentTimesMovedToLobby = number_currentTimesMovedToLobby + 1;
	end

	local function MoveEligiblePlayersToArenaOrLobby()
		for i, NewGamePlayer_Object in ipairs(NewGamePlayer_Array_ProxyPlayersInRoom) do
			local arenaLocation = GetRandomPositionFromArray(gameObjects_arenaSpawns);
			local lobbyLocation = GetRandomPositionFromArray(gameObjects_lobbySpawns);

			if(NewGamePlayer_Object.script.GetPlayerHasWeapon() == true) then
				NewGamePlayer_Object.script.WarpToPoint(arenaLocation);
				NewGamePlayer_Object.script.SetCurrentlyInMatch(true);
			else
				NewGamePlayer_Object.script.WarpToPoint(lobbyLocation);
				NewGamePlayer_Object.script.SetCurrentlyInMatch(false);
			end
		end

		--number_currentTimesMovedToArena = number_currentTimesMovedToArena + 1;
	end

	local function RevertPlayerModesAndStats()
		for i, NewGamePlayer_Object in ipairs(NewGamePlayer_Array_ProxyPlayersInRoom) do
			NewGamePlayer_Object.script.ResetPlayerStats();
			NewGamePlayer_Object.script.ResetModes();
		end
	end

	local function StartMovingPlayersBackToLobby()
		bool_returningPlayersToLobby = true;
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - TIME ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - TIME ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - TIME ||||||||||||||||||||||||||||||||||||||||||||||

	local function Time_UpdateText()
		if (textMeshes_timerTexts) then
			for i, timerTextMesh in ipairs(textMeshes_timerTexts) do
				timerTextMesh.text = GetFormattedTimeText(number_matchTimer);
			end
		end
	end

	local function Time_ComputeTime()
		if (mlplayer_localPlayer.isMasterClient == true) then
			if (bool_matchOngoing == true) then

				number_matchTimer = number_matchTimer - Time.deltaTime;

				--NOTE: This only triggers once
				if(number_matchTimer <= 0) then
					--Invoke RemovePlayersFromTurret() across all clients.
					LuaEvents.InvokeLocalForAll(NewGameManager, "H");

					--Invoke MovePlayersToLobby() across all clients.
					--LuaEvents.InvokeLocalForAll(NewGameManager, "E");

					--Invoke DestroyAllGameProps() across all clients.
					LuaEvents.InvokeLocalForAll(NewGameManager, "G");

					--Invoke RevertPlayerModesAndStats() across all clients.
					LuaEvents.InvokeLocalForAll(NewGameManager, "F");

					--Invoke StartMovingPlayersBackToLobby() across all clients.
					LuaEvents.InvokeLocalForAll(NewGameManager, "J");

					bool_matchOngoing = false;
					server_bool_matchOngoing.SyncSet(bool_matchOngoing);
				end

			else
				number_matchTimer = 0;
				number_matchTimerEnd = 0;
			end

			if(Time.time > number_computeMatchTimeNextTick) then
				server_number_matchTimer.SyncSet(number_matchTimer);
				number_computeMatchTimeNextTick = Time.time + 1.0;
			end
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	local function PlayGameErrorSound()
		audioSource_manager.PlayOneShot(audioClip_gameErrorSound);
	end

	local function UpdatePlayerScores()
		local MLPlayer_Array_NewPlayersInRoom = Room.GetAllPlayers();

		for i, MLPlayer_Object in ipairs(MLPlayer_Array_NewPlayersInRoom) do
			if(MLPlayer_Object.PlayerRoot ~= nil) then
				local newGamePlayerObject = MLPlayer_Object.PlayerRoot.GetComponent(NewGamePlayer);
				newGamePlayerObject.UpdateScore();
			end
		end
	end

	local function CanStartMatch()
		local readyPlayerCount = 0;

		for i, NewGamePlayer_Object in ipairs(NewGamePlayer_Array_ProxyPlayersInRoom) do
			if(NewGamePlayer_Object.script.GetPlayerHasWeapon() == true) then
				readyPlayerCount = readyPlayerCount + 1;
			end
		end

		if(readyPlayerCount > 1) then
			return true;
		else
			return false;
		end
	end

	local function LocalStartMatch()
		Debug.Log("LocalStartMatch");

		if (bool_matchOngoing == false) and (CanStartMatch() == true) then
			number_matchTimerEnd = Time.time + number_maxMatchTime;
			number_matchTimer = number_matchTimerEnd - Time.time;

			textMesh_gameManagerText.text = "";

			--bool_movingPlayersToArena = true;
			--number_currentTimesMovedToArena = 0;
			--MoveEligiblePlayersToArenaOrLobby();

			--Invoke MoveEligiblePlayersToArenaOrLobby() across all clients.
			LuaEvents.InvokeLocalForAll(NewGameManager, "K");

			--Invoke DestroyAllCans() across all clients.
			LuaEvents.InvokeLocalForAll(NewGameManager, "L");

			SetSpecatorCamerasVisibility();

			audioSource_preGameSoundtrack.Stop();
			audioSource_gameSoundtrack.Stop();
			audioSource_gameSoundtrack.Play();

			bool_matchOngoing = true;
			server_bool_matchOngoing.SyncSet(bool_matchOngoing);

			local lobbyDoorsButtonObject = gameObject_lobbyDoorsButton.GetComponent(LobbyDoorsButton);
			lobbyDoorsButtonObject.script.ForceCloseDoors();

		elseif (bool_matchOngoing == true) then
			local errorText = "Match currently in progress.";
			textMesh_gameManagerText.text = errorText;
		else
			--Invoke PlayGameErrorSound() across all clients.
			LuaEvents.InvokeLocalForAll(NewGameManager, "D");

			local errorText = "At least 2 players must have weapons";
			errorText = errorText .. "\n";
			errorText = errorText .. "before starting a new match!";
			errorText = errorText .. "\n";
			errorText = errorText .. "You can find them along the wall behind you!";

			textMesh_gameManagerText.text = errorText;
		end

		Scoreboard_UpdateCards();
		Scoreboard_SortCards();
	end

	local function LocalReportDamagedPlayer()
		UpdatePlayerScores();
		Scoreboard_UpdateCards();
		Scoreboard_SortCards();
	end

	local function LocalStartRespawnPlayer(string_encodedHitPlayerActorID)
		local number_decodedHitPlayerActorID = DecodeActorID(string_encodedHitPlayerActorID);
		local mlplayer_hitPlayer = Room.FindPlayerByActorNumber(number_decodedHitPlayerActorID);
		local newGamePlayer_hitPlayer = mlplayer_hitPlayer.PlayerRoot.GetComponent(NewGamePlayer);

		newGamePlayer_hitPlayer.script.StartRespawnPlayer();

		local vector3_spawnedPrefabPosition = Vector3(0, 0, 0);
		vector3_spawnedPrefabPosition.x = (mlplayer_hitPlayer.AvatarTrackedObject.transform.position.x + mlplayer_hitPlayer.PlayerRoot.transform.position.x) / 2.0;
		vector3_spawnedPrefabPosition.y = (mlplayer_hitPlayer.AvatarTrackedObject.transform.position.y + mlplayer_hitPlayer.PlayerRoot.transform.position.y) / 2.0;
		vector3_spawnedPrefabPosition.z = (mlplayer_hitPlayer.AvatarTrackedObject.transform.position.z + mlplayer_hitPlayer.PlayerRoot.transform.position.z) / 2.0;

		Object.Instantiate(gameObject_playerDeathPrefab, vector3_spawnedPrefabPosition, Quaternion(0, 0, 0, 0));
	end

	local function GetCurrentPlayersInWorld()
		NewGamePlayer_Array_ProxyPlayersInRoom = {};
		--Scoreboard_CleanupCards();

		local MLPlayer_Array_NewPlayersInRoom = Room.GetAllPlayers();

		for i, MLPlayer_Object in ipairs(MLPlayer_Array_NewPlayersInRoom) do
			if(MLPlayer_Object.PlayerRoot ~= nil) then
				local newGamePlayerObject = MLPlayer_Object.PlayerRoot.GetComponent(NewGamePlayer);

				if(newGamePlayerObject == nil) then
					local NewGamePlayer_NewPlayer = MLPlayer_Object.PlayerRoot.AddComponent(NewGamePlayer);
					NewGamePlayer_NewPlayer.script.SetMaxHealth(number_playerMaxHealth);
					NewGamePlayer_NewPlayer.script.SetRespawnTimeLength(number_respawnTime);
					NewGamePlayer_NewPlayer.script.InitalizePlayer(MLPlayer_Object, NewGameManager);

					table.insert(NewGamePlayer_Array_ProxyPlayersInRoom, NewGamePlayer_NewPlayer);
				else
					table.insert(NewGamePlayer_Array_ProxyPlayersInRoom, newGamePlayerObject);
				end
			end
		end
	end

	local function InitalizeNewGameManager()
		GetCurrentPlayersInWorld();
		Scoreboard_CreateCards();
	end

	local function RemovePlayersFromTurret()
		--Self Note: Ideally precaching would be better but for some reason it doesn't work here... (I geuss it just looses its object reference)
		--Doing a GetComponent just to call a method on the script.
		gameObject_centerTurretGameObject.GetComponent(MountedTurret).script.KickPlayerOut();
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	function NewGameManager.GetRespawnAreaPosition()
		return gameObject_respawnArea.transform.position;
	end

	function NewGameManager.GetArenaSpawnPosition()
		return GetRandomPositionFromArray(gameObjects_arenaSpawns);
	end

	function NewGameManager.GetCurrentMatchState()
		return bool_matchOngoing;
	end

	function NewGameManager.SetRespawnTimerTextObject(timeValue)
		for i, Text_respawnTimerText in ipairs(textArray_respawnTimerText) do
			Text_respawnTimerText.text = GetFormattedTimeText(timeValue);
		end
	end

	function NewGameManager.StartMatch()
		--Invoke LocalStartMatch() across all clients.
		LuaEvents.InvokeLocalForAll(NewGameManager, "A");
	end

	function NewGameManager.EndMatch()
		--Invoke LocalEndMatch() across all clients.
		server_number_matchTimer.SyncSet(0);
		--Invoke DestroyAllGameProps() across all clients.
		LuaEvents.InvokeLocalForAll(NewGameManager, "G");

		--Invoke RevertPlayerModesAndStats() across all clients.
		LuaEvents.InvokeLocalForAll(NewGameManager, "F");
		LuaEvents.InvokeLocalForAll(NewGameManager, "J");

		textMesh_gameManagerText.text = "Match ended.";

		bool_matchOngoing = false;
		server_bool_matchOngoing.SyncSet(bool_matchOngoing);

	end


	--function NewGameManager.ReportDamagedPlayer(hitPlayerGUID)
		--Invoke LocalReportDamagedPlayer() across all clients.
		--LuaEvents.InvokeLocalForAll(NewGameManager, "B", hitPlayerGUID);
	--end

	function NewGameManager.ReportDamagedPlayer()
		--Invoke LocalReportDamagedPlayer() across all clients.
		LuaEvents.InvokeLocalForAll(NewGameManager, "B");
	end

	function NewGameManager.RespawnPlayer(number_hitPlayerActorID)
		local string_encodedHitPlayerActorID = EncodeActorID(number_hitPlayerActorID);

		--Invoke LocalStartRespawnPlayer() across all clients.
		LuaEvents.InvokeLocalForAll(NewGameManager, "C", string_encodedHitPlayerActorID);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| ROOM CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| ROOM CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| ROOM CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function OnPlayerJoin()
		GetCurrentPlayersInWorld();
		Scoreboard_CreateCards();
	end

	local function OnPlayerLeave()
		GetCurrentPlayersInWorld();
		Scoreboard_CreateCards();
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function server_number_matchTimer_OnChange(value)
		number_matchTimer = value;
	end

	local function server_number_matchTimer_OnSet(value)
		number_matchTimer = value;
	end

	local function server_bool_matchOngoing_OnChange(value)
		bool_matchOngoing = value;
	end

	local function server_bool_matchOngoing_OnSet(value)
		bool_matchOngoing = value;
	end


	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function NewGameManager.Start()
		mlplayer_localPlayer = Room.GetLocalPlayer();

		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(NewGameManager, "A", LocalStartMatch);
		LuaEvents.AddLocal(NewGameManager, "B", LocalReportDamagedPlayer);
		LuaEvents.AddLocal(NewGameManager, "C", LocalStartRespawnPlayer);
		LuaEvents.AddLocal(NewGameManager, "D", PlayGameErrorSound);
		LuaEvents.AddLocal(NewGameManager, "E", MovePlayersToLobby);
		LuaEvents.AddLocal(NewGameManager, "F", RevertPlayerModesAndStats);
		LuaEvents.AddLocal(NewGameManager, "G", DestroyAllGameProps);
		LuaEvents.AddLocal(NewGameManager, "H", RemovePlayersFromTurret);
		LuaEvents.AddLocal(NewGameManager, "I", Powerups_SpawnPowerupInArena);
		LuaEvents.AddLocal(NewGameManager, "J", StartMovingPlayersBackToLobby);
		LuaEvents.AddLocal(NewGameManager, "K", MoveEligiblePlayersToArenaOrLobby);
		LuaEvents.AddLocal(NewGameManager, "L", DestroyAllCans);

		Room.OnPlayerJoin.Add(OnPlayerJoin);
		Room.OnPlayerLeft.Add(OnPlayerLeave);

		server_number_matchTimer.OnVariableChange.Add(server_number_matchTimer_OnChange);
		server_number_matchTimer.OnVariableSet.Add(server_number_matchTimer_OnSet);
		server_bool_matchOngoing.OnVariableChange.Add(server_bool_matchOngoing_OnChange);
		server_bool_matchOngoing.OnVariableSet.Add(server_bool_matchOngoing_OnSet);

		audioSource_manager = NewGameManager.gameObject.GetComponent(AudioSource);

		for i, GameObject_respawnTimerText in ipairs(gameObjects_respawnTimerTexts) do
			local Text_respawnTimerText = GameObject_respawnTimerText.GetComponent(Text);
			table.insert(textArray_respawnTimerText, Text_respawnTimerText);
		end

		textMesh_gameManagerText.text = "";

		InitalizeNewGameManager();

		--CloudVariables

		if CloudVariables.IsEnabled then
			Debug.log("Cloud variables are enabled, attempting to get scoreboard...");
			CloudVariables:GetScoreBoard("NightOps_score").Then(OnSuccess, OnRejected).Catch(OnError);
		end

		if(bool_matchOngoing == true) then
			audioSource_preGameSoundtrack.Stop();
			audioSource_gameSoundtrack.Stop();
			audioSource_gameSoundtrack.Play();
		else
			audioSource_gameSoundtrack.Stop();
			audioSource_preGameSoundtrack.Stop();
			audioSource_preGameSoundtrack.Play();
		end
	end

	-- update called every frame
	function NewGameManager.Update()
		Time_UpdateText();
		Time_ComputeTime();
		Powerups_UpdateSpawnPowerups();

		--brute force to set the scoreboard cards to watch an MLPlayer in the room... (tried to set them once but that does not work at all)
		--if the scoreboard cards are still not fully initalized, keep trying to set them until they eventually are (this works but it takes a large amount of time before it eventually does it)
		--self note: I suppose we could delegate this to a courtine but the thing is that we don't know how long we need to wait until we can set the cards!!!
		if(bool_scoreboardCards_initalized == false) then
			if(Time.time > number_scoreboardSetCardsNextTickTime) then
				Scoreboard_SetPlayers();

				number_scoreboardSetCardsNextTickTime = Time.time + number_scoreboardSetCardsTickRate;
			end
		end

		--another brute force send players back to the lobby after a match has finished...
		--(in an attempt to fix a bug where some players are not sent back to the lobby after a match has completed)
		if(bool_returningPlayersToLobby == true) then
			--Invoke MovePlayersToLobby() across all clients.
			LuaEvents.InvokeLocalForAll(NewGameManager, "E");

			if(number_currentTimesMovedToLobby >= number_maxMoveToLobbyTimes) then
				bool_returningPlayersToLobby = false;
				number_currentTimesMovedToLobby = 0;
			end

			audioSource_gameSoundtrack.Stop();
			audioSource_preGameSoundtrack.Stop();
			audioSource_preGameSoundtrack.Play();
		end

		--another brute force send players back to the lobby after a match has finished...
		--(in an attempt to fix a bug where some players are not sent back to the lobby after a match has completed)
		--if(bool_movingPlayersToArena == true) then
			--Invoke MoveEligiblePlayersToArenaOrLobby() across all clients.
			--LuaEvents.InvokeLocalForAll(NewGameManager, "K");

			--if(number_currentTimesMovedToArena >= number_maxMoveToArenaTimes) then
				--bool_movingPlayersToArena = false;
				--number_currentTimesMovedToArena = 0;
			--end
		--end
	end
end