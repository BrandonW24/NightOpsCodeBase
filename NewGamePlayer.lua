do -- script NewGamePlayer 
	
	-- get reference to the script
	local NewGamePlayer = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	--player property keys
	local string_PLAYERKEY_hasWeapon = "HasWeapon";
	local string_PLAYERKEY_currentlyInMatch = "CurrentlyInMatch";
	local string_PLAYERKEY_serverIsDead = "IsDead";
	local string_PLAYERKEY_serverKills = "Kills";
	local string_PLAYERKEY_serverDeaths = "Deaths";
	local string_PLAYERKEY_serverAssists = "Assists";

	local number_maxHealth = 0;
	local number_currentRespawnTime = 0;
	local number_currentRespawnEndTime = 0;
	local number_respawnTimeLength = 0;

	local mlplayer_player = nil;
	local string_playerGUID = nil;

	local bool_isInitalized = false;
	local bool_respawning = false;

	local newGameManager_manager = nil; --NewGameManager type
	local number_killedByPlayerActorID = nil; --String type
	local numbers_tookDamageFromPlayerActorIDs = {}; --String[] type


	--Cloud variable key and localPlayerScore
	local SCORE_KEY = "NightOps_score";
	local localPlayerScore = 0;

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	local function LocalWarpToPoint(vector3_position)
		mlplayer_player.Teleport(vector3_position);
	end

	local function ResetPlayerHealth()
		mlplayer_player.Health = number_maxHealth;
	end

	local function LocalResetPlayerStats()
		mlplayer_player.Score = 0;
		mlplayer_player.SetProperty(string_PLAYERKEY_serverKills, 0);
		mlplayer_player.SetProperty(string_PLAYERKEY_serverDeaths, 0);
		mlplayer_player.SetProperty(string_PLAYERKEY_serverAssists, 0);
	end


	--This is called at the end of the match.
	--Cloud variable method is called : 
	--CloudVariables.RequestToPublish();
	--Matches typically last 4 minutes so this should be within the 3 minute time interval needed.

	local function LocalResetModes()
		bool_respawning = false;
		mlplayer_player.SetProperty(string_PLAYERKEY_hasWeapon, false);
		mlplayer_player.SetProperty(string_PLAYERKEY_currentlyInMatch, false);
		mlplayer_player.SetProperty(string_PLAYERKEY_serverIsDead, false);

		

		local number_playerKills = mlplayer_player.GetProperty(string_PLAYERKEY_serverKills);
		local number_playerAssists = mlplayer_player.GetProperty(string_PLAYERKEY_serverAssists);
		local number_playerDeaths = mlplayer_player.GetProperty(string_PLAYERKEY_serverDeaths);



	--	local RetrieveScore = CloudVariables.UserVariables.GetVariable(SCORE_KEY);

	--	Debug.log("Locally attempting to store player score changes into cloud storage variable keeper");
	--	Debug:Log(string.format("Score variable passed : %.2f ", mlplayer_player.Score));
	--	RetrieveScore = RetrieveScore + mlplayer_player.Score;
    --    if CloudVariables.IsEnabled and not CloudVariables.UserVariables.ReadOnly then
    --        CloudVariables.UserVariables.SetVariable(SCORE_KEY, RetrieveScore);
	--		Debug.log(string.format("Success in storing local changes to local cloud variable :  %.2f", RetrieveScore));
     --   end


	 
		Debug.log("Locally attempting to store player score changes into cloud storage variable keeper");
		local RetrieveScore = CloudVariables.UserVariables.GetVariable(SCORE_KEY);
		Debug:Log(string.format("Adding current score number : %.2f  to current cloud variable value : %.2f  ", ((number_playerKills * 100) + (number_playerAssists * 25) - (number_playerDeaths * 50)), RetrieveScore));
		RetrieveScore = RetrieveScore + ((number_playerKills * 100) + (number_playerAssists * 25) - (number_playerDeaths * 50));
		if CloudVariables.IsEnabled and not CloudVariables.UserVariables.ReadOnly then
			CloudVariables.UserVariables.SetVariable(SCORE_KEY, RetrieveScore);
			Debug.log(string.format("Success in storing local changes to local cloud variable :  %.2f", RetrieveScore));
		end



		Debug.log("End of match detected. Locally attempting to store player publish score to cloud storage.");
		CloudVariables.RequestToPublish();
		Debug.log("Request to publish completed!");

	end

	--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	--Cloud variable function here. Uses the method shared from the documentation on cloud variables.
	--|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

	local function LocalAddToPlayerScore(score)
		--Debug.log("Locally attempting to store player score changes into cloud storage variable keeper");
		--Debug:Log(string.format("Score variable passed : %.2f ", score));
		--local RetrieveScore = CloudVariables.UserVariables.GetVariable(SCORE_KEY);
		--Debug:Log(string.format("Adding current score number : %.2f  to current cloud variable value : %.2f  ", score, RetrieveScore));
		--RetrieveScore = RetrieveScore + score;
        --if CloudVariables.IsEnabled and not CloudVariables.UserVariables.ReadOnly then
      --      CloudVariables.UserVariables.SetVariable(SCORE_KEY, RetrieveScore);
	--		Debug.log(string.format("Success in storing local changes to local cloud variable :  %.2f", RetrieveScore));
    --    end
	end

	local function UpdateRespawnTimerText()
		local number_calculatedRespawnTime = Mathf.Max(0, number_currentRespawnEndTime - number_currentRespawnTime);
		newGameManager_manager.SetRespawnTimerTextObject(number_calculatedRespawnTime);
	end

	local function DeliverResultsToPlayers()
		--Add up the death count for the current player
		local number_currentDeaths = mlplayer_player.GetProperty(string_PLAYERKEY_serverDeaths);
		local number_incrementedDeaths = number_currentDeaths + 1;
		mlplayer_player.SetProperty(string_PLAYERKEY_serverDeaths, number_incrementedDeaths);

		--Increment the Kill Count for the player that dealt the final blow
		if(number_killedByPlayerActorID ~= nil) then
			local mlplayer_killedByPlayer = Room.FindPlayerByActorNumber(number_killedByPlayerActorID);

			if(mlplayer_killedByPlayer ~= nil) then
				local number_currentKills = mlplayer_killedByPlayer.GetProperty(string_PLAYERKEY_serverKills);
				local number_incrementedKills = number_currentKills + 1;
				mlplayer_killedByPlayer.SetProperty(string_PLAYERKEY_serverKills, number_incrementedKills);
			end
		end

		--Iterate through the list of players that we took damage from, and increment the assist count for those involved.
		if(numbers_tookDamageFromPlayerActorIDs ~= nil) then
			--Debug.log("Damage taken from multiple players detected");
			--Loop through the array of players that shot at us
			for i, number_assistingPlayerActorID in ipairs(numbers_tookDamageFromPlayerActorIDs) do
				Debug.log("Assist detected");
				--make sure its not the same player that delivered the final blow
				--if(number_assistingPlayerActorID ~= number_killedByPlayerActorID) then
					local mlplayer_assistingMLPlayer = Room.FindPlayerByActorNumber(number_assistingPlayerActorID);

					if(mlplayer_assistingMLPlayer ~= nil) then
						--debug.log("Assist detected");
						local number_currentAssists = mlplayer_assistingMLPlayer.GetProperty(string_PLAYERKEY_serverAssists);
						local oldAssistScore = number_currentAssists;
						local number_incrementedAssists = number_currentAssists + 1;

						if(number_assistingPlayerActorID == number_killedByPlayerActorID)then
							Debug.log("Same player detected, reverting to old assist score");
							number_incrementedAssists = oldAssistScore;
						end
			
						mlplayer_assistingMLPlayer.SetProperty(string_PLAYERKEY_serverAssists, number_incrementedAssists);
					end
				--end

			end

		end
	end

	local function LocalUpdateScore()
		--if(mlplayer_player.isLocal == false) then
			--return
		--end

		local number_playerKills = mlplayer_player.GetProperty(string_PLAYERKEY_serverKills);
		local number_playerAssists = mlplayer_player.GetProperty(string_PLAYERKEY_serverAssists);
		local number_playerDeaths = mlplayer_player.GetProperty(string_PLAYERKEY_serverDeaths);

		if(number_playerKills == nil) or (number_playerAssists == nil) then
			return
		end

		--|||||||||||||||||||||||||||||||||||
		--Cloud variable functionality below
		--|||||||||||||||||||||||||||||||||||

		local number_scoreValue = (number_playerKills * 100) + (number_playerAssists * 25) - (number_playerDeaths * 50);
		mlplayer_player.Score = number_scoreValue;



		--NewGamePlayer.AddToPlayerScore(number_scoreValue);
		
		--CloudVariables:RequestToPublish();


	end

	local function LocalStartRespawnPlayer()
		local vector3_warpPosition = newGameManager_manager.script.gameObject.GetComponent(NewGameManager).script.GetRespawnAreaPosition();
		mlplayer_player.Teleport(vector3_warpPosition);

		number_currentRespawnTime = Time.time;
		number_currentRespawnEndTime = Time.time + number_respawnTimeLength;
		bool_respawning = true;

		Debug.Log("respawning...");
	end

	local function LocalFinishRespawnPlayer()
		local vector3_arenaWarpPosition = newGameManager_manager.script.gameObject.GetComponent(NewGameManager).script.GetArenaSpawnPosition();

		mlplayer_player.Teleport(vector3_arenaWarpPosition);
		mlplayer_player.SetProperty(string_PLAYERKEY_serverIsDead, false);
		ResetPlayerHealth();

		bool_respawning = false;

		Debug.Log("respawning back in arena...");
	end

	local function ManageRespawnPlayer()
		if(bool_respawning == true) then
			number_currentRespawnTime = number_currentRespawnTime + Time.deltaTime;

			if(number_currentRespawnTime >= number_currentRespawnEndTime) then
				LuaEvents.InvokeLocalForAll(NewGamePlayer, "C");
			end

			UpdateRespawnTimerText();
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC GETTERS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC GETTERS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC GETTERS ||||||||||||||||||||||||||||||||||||||||||||||

	function NewGamePlayer.GetPlayer()
		return mlplayer_player;
	end

	function NewGamePlayer.GetPlayerName()
		return mlplayer_player.NickName;
	end

	function NewGamePlayer.GetPlayerHealth()
		return mlplayer_player.Health;
	end

	function NewGamePlayer.GetPlayerScore()
		return mlplayer_player.Score;
	end

	function NewGamePlayer.CanGetHealthPowerup()
		if(mlplayer_player.Health < number_maxHealth) and (mlplayer_player.GetProperty(string_PLAYERKEY_serverIsDead) == false) and (mlplayer_player.GetProperty(string_PLAYERKEY_currentlyInMatch) == true) then
			return true;
		else
			return false;
		end
	end

	function NewGamePlayer.GetPlayerDeadState()
		return mlplayer_player.GetProperty(string_PLAYERKEY_serverIsDead);
	end

	function NewGamePlayer.GetPlayerIsCurrentlyInMatchState()
		return mlplayer_player.GetProperty(string_PLAYERKEY_currentlyInMatch);
	end

	function NewGamePlayer.GetPlayerKills()
		return mlplayer_player.GetProperty(string_PLAYERKEY_serverKills);
	end

	function NewGamePlayer.GetPlayerDeaths()
		return mlplayer_player.GetProperty(string_PLAYERKEY_serverDeaths);
	end

	function NewGamePlayer.GetPlayerAssists()
		return mlplayer_player.GetProperty(string_PLAYERKEY_serverAssists);
	end

	function NewGamePlayer.GetPlayerHasWeapon()
		return mlplayer_player.GetProperty(string_PLAYERKEY_hasWeapon);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC SETTERS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC SETTERS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC SETTERS ||||||||||||||||||||||||||||||||||||||||||||||

	function NewGamePlayer.SetMaxHealth(newMaxHealth)
		number_maxHealth = newMaxHealth;
	end

	function NewGamePlayer.SetRespawnTimeLength(newRespawnLengthTime)
		number_respawnTimeLength = newRespawnLengthTime;
	end

	function NewGamePlayer.SetHasWeapon(value)
		mlplayer_player.SetProperty(string_PLAYERKEY_hasWeapon, value);
	end

	function NewGamePlayer.SetCurrentlyInMatch(value)
		mlplayer_player.SetProperty(string_PLAYERKEY_currentlyInMatch, value);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC ACTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC ACTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC ACTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	--note to self: mlplayer_player is not nil, but mlplayer_player.Health is nil
	function NewGamePlayer.InitalizePlayer(NewMLPlayer, NewGameManagerObject)
		if (bool_isInitalized) then return end

		mlplayer_player = NewMLPlayer;
		string_playerGUID = NewMLPlayer.Guid;

		if(mlplayer_player.Health == nil) then
			mlplayer_player.Health = number_maxHealth;
		end

		if(mlplayer_player.Score == nil) then
			mlplayer_player.Score = 0;
		end

		if(mlplayer_player.PropertyExists(string_PLAYERKEY_hasWeapon) == false) then
			mlplayer_player.SetProperty(string_PLAYERKEY_hasWeapon, false);
		end

		if(mlplayer_player.PropertyExists(string_PLAYERKEY_currentlyInMatch) == false) then
			mlplayer_player.SetProperty(string_PLAYERKEY_currentlyInMatch, false);
		end

		if(mlplayer_player.PropertyExists(string_PLAYERKEY_serverIsDead) == false) then
			mlplayer_player.SetProperty(string_PLAYERKEY_serverIsDead, false);
		end

		if(mlplayer_player.PropertyExists(string_PLAYERKEY_serverKills) == false) then
			mlplayer_player.SetProperty(string_PLAYERKEY_serverKills, 0);
		end

		if(mlplayer_player.PropertyExists(string_PLAYERKEY_serverDeaths) == false) then
			mlplayer_player.SetProperty(string_PLAYERKEY_serverDeaths, 0);
		end

		if(mlplayer_player.PropertyExists(string_PLAYERKEY_serverAssists) == false) then
			mlplayer_player.SetProperty(string_PLAYERKEY_serverAssists, 0);
		end

		newGameManager_manager = NewGameManagerObject;
		bool_isInitalized = true;
	end

	--SELF NOTE: For whatever reason I can't do an invokelocalforall in here, doesn't work and only calls for the sender
	function NewGamePlayer.TakeDamage(number_damageAmount, number_fromPlayerActorID);
		if(mlplayer_player.GetProperty(string_PLAYERKEY_serverIsDead) == true) or (mlplayer_player.GetProperty(string_PLAYERKEY_currentlyInMatch) == false) then return end

		--SELF NOTE: stored this in a variable, as the value is not immedieatly updated and changed for the if statement that checks if the health is <= 0 
		--(the player has to take damage again in order to trigger it) so the fix here is to store the deducted value
		local number_deductedHealth = mlplayer_player.Health - number_damageAmount;
		mlplayer_player.Health = number_deductedHealth;

		if(number_deductedHealth <= 0) then
			mlplayer_player.Health = 0;
			mlplayer_player.SetProperty(string_PLAYERKEY_serverIsDead, true);
			number_killedByPlayerActorID = number_fromPlayerActorID;

			DeliverResultsToPlayers();

			--self note: soooo really funky quirk here, normally .script works however it doesn't work in this instance.
			--decided to follow up the .script accessing by GetComponent and that seems to work strangely enough... (mabye newGameManager_manager somehow looses its reference?)
			newGameManager_manager.script.gameObject.GetComponent(NewGameManager).script.RespawnPlayer(mlplayer_player.ActorID)
		else
			mlplayer_player.SetProperty(string_PLAYERKEY_serverIsDead, false);
			table.insert(numbers_tookDamageFromPlayerActorIDs, number_fromPlayerActorID);
		end

		--self note: soooo really funky quirk here, normally .script works however it doesn't work in this instance.
		--decided to follow up the .script accessing by GetComponent and that seems to work strangely enough... (mabye newGameManager_manager somehow looses its reference?)
		newGameManager_manager.script.gameObject.GetComponent(NewGameManager).script.ReportDamagedPlayer();

		--Invoking LocalUpdateScore() across all clients.
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "D");
	end

	--note to self: mlplayer_player is not nil, but mlplayer_player.Health is nil
	function NewGamePlayer.EndMatchMode()
		ResetPlayerHealth()

		mlplayer_player.SetProperty(string_PLAYERKEY_hasWeapon, false);
		mlplayer_player.SetProperty(string_PLAYERKEY_currentlyInMatch, false);
		mlplayer_player.SetProperty(string_PLAYERKEY_serverIsDead, false);
	end

	function NewGamePlayer.WarpToPoint(vector3_position)
		--SELF NOTE: The parameter types that you pass through with these calls have to be serializable
		--https://sdk.massiveloop.com/getting_started/scripting/SerializableTypes.html
		--Invoking LocalWarpToPoint() across all clients.
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "A", vector3_position);
	end

	function NewGamePlayer.AddHealth(healthAmount)
		mlplayer_player.Health = Mathf.Clamp(mlplayer_player.Health + healthAmount, 0.0, number_maxHealth);
	end

	function NewGamePlayer.StartRespawnPlayer()
		--Invoking LocalStartRespawnPlayer() across all clients.
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "B");
	end

	function NewGamePlayer.FinishRespawnPlayer()
		--Invoking LocalFinishRespawnPlayer() across all clients.
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "C");
	end

	function NewGamePlayer.UpdateScore()
		--Invoking LocalUpdateScore() across all clients.
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "D");
	end

	function NewGamePlayer.ResetPlayerStats()
		--Invoking LocalResetPlayerStats() across all clients.
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "E");
	end

	function NewGamePlayer.ResetModes()
		--Invoking LocalResetModes() across all clients.
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "F");
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	function NewGamePlayer.AddToPlayerScore(score)
		LuaEvents.InvokeLocalForAll(NewGamePlayer, "G", score);
    end


	-- start only called at beginning
	function NewGamePlayer.Start()
		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(NewGamePlayer, "A", LocalWarpToPoint);
		LuaEvents.AddLocal(NewGamePlayer, "B", LocalStartRespawnPlayer);
		LuaEvents.AddLocal(NewGamePlayer, "C", LocalFinishRespawnPlayer);
		LuaEvents.AddLocal(NewGamePlayer, "D", LocalUpdateScore);
		LuaEvents.AddLocal(NewGamePlayer, "E", LocalResetPlayerStats);
		LuaEvents.AddLocal(NewGamePlayer, "F", LocalResetModes);

		--Cloud variable local function connection
		LuaEvents.AddLocal(NewGamePlayer, "G", LocalAddToPlayerScore);


		--Cloud variable check, this always passes here.
		if CloudVariables.IsEnabled then
            if CloudVariables.UserVariables.KeyExists(SCORE_KEY) then
				Debug.log("Key exists getting variable");
                localPlayerScore = CloudVariables.UserVariables.GetVariable(SCORE_KEY);
            else
                CloudVariables.UserVariables.SetVariable(SCORE_KEY, localPlayerScore);
				Debug.log("Key didn't exist.. Setting variable");

            end
        end


	end




	-- update called every frame
	function NewGamePlayer.Update()
		--TODO: PLEASE REPLACE THIS WITH A COURTINE INSTEAD
		ManageRespawnPlayer();
	end
end