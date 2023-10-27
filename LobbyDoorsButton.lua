do -- script LobbyDoorsButton 
	
	-- get reference to the script
	local LobbyDoorsButton = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are exposed and accessible through the unity inspector

	local playableDirector_opening = SerializedField("Open Sequence", PlayableDirector);
	local playableDirector_closing = SerializedField("Close Sequence", PlayableDirector);
	local gameObject_gameManager = SerializedField("Game Manager", GameObject);

	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are syncronized across clients
	--NOTE: kept names small since they can affect server sync performance

	local bool_server_doorState = SyncVar(LobbyDoorsButton, "a");

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local bool_doorStateLocal = false;
	local mlplayer_localPlayer = nil;
	local mlclickable_click = nil;

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	local function UpdateDoorDirector()
		--if the door state is set to true, then its opening
		if (bool_doorStateLocal == true) then
			--stop both the sequences
			playableDirector_closing.Stop();
			playableDirector_opening.Stop();

			--play the opening sequence
			playableDirector_opening.RebuildGraph();
			playableDirector_opening.Play();
		end

		--if the door state is set to false, then its closing
		if (bool_doorStateLocal == false) then
			--stop both the sequences
			playableDirector_closing.Stop();
			playableDirector_opening.Stop();

			--play the closing sequence
			playableDirector_closing.RebuildGraph();
			playableDirector_closing.Play();
		end
	end

	local function SetDoorState(value)
		--if the current local player is nil then don't continue because we need it
		if(mlplayer_localPlayer == nil) then do return end end
		
		----------------- MASTER CLIENT -----------------
		--on the server side we set the door state locally and on the server.
		--note: for the non server side code look into the bool_server_doorState Set/Change variables where we update for the non master client players.
		if(mlplayer_localPlayer.isMasterClient == true) then

			bool_doorStateLocal = value;

			--set the server value
			bool_server_doorState.SyncSet(bool_doorStateLocal);

			--update the door sequences on the server side.
			UpdateDoorDirector();
		end
	end

	--Main Door function that gets called when the lobby door buttons are pressed
	local function ToggleDoor()
		--if the current local player is nil then don't continue because we need it
		if(mlplayer_localPlayer == nil) then return end

		--Self Note: Ideally precaching would be better but for some reason it doesn't work here... (I geuss it just looses its object reference)
		--So were doing a GetComponent just to call a method on the script.
		if(gameObject_gameManager.GetComponent(NewGameManager).script.GetCurrentMatchState() == true) then return end
		
		----------------- MASTER CLIENT -----------------
		--on the server side we set the door state locally and on the server.
		--note: for the non server side code look into the bool_server_doorState Set/Change variables where we update for the non master client players.
		if(mlplayer_localPlayer.isMasterClient == true) then

			--use the negate operator to get the opposite value of the current boolean so it acts like a toggle
			bool_doorStateLocal = not bool_doorStateLocal;

			--set the server value
			bool_server_doorState.SyncSet(bool_doorStateLocal);

			--update the door sequences on the server side.
			UpdateDoorDirector();
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	--Main "OnClick" which is called when the Clickable component is pressed.
	local function OnClick()
		--because the MLClickable OnClick is not syncronized, we treat this as a "substitue"
		--to where we use InvokeLocalForAll to do a synced execution for our main ToggleDoor() function.

		--invoke ToggleDoor() across all clients
		LuaEvents.InvokeLocalForAll(LobbyDoorsButton, "A");
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function bool_server_doorState_OnChange(value)
		--if the current local player is nil then don't continue because we need it
		if(mlplayer_localPlayer == nil) then do return end end

		----------------- NON MASTER CLIENT -----------------
		if(mlplayer_localPlayer.isMasterClient == false) then
			bool_doorStateLocal = value;
			UpdateDoorDirector();
		end
	end

	local function bool_server_doorState_OnSet(value)
		--if the current local player is nil then don't continue because we need it
		if(mlplayer_localPlayer == nil) then do return end end

		----------------- NON MASTER CLIENT -----------------
		if(mlplayer_localPlayer.isMasterClient == false) then
			bool_doorStateLocal = value;
			UpdateDoorDirector();
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	function LobbyDoorsButton.ForceOpenDoors()
		--invoke SetDoorState() and pass through "true" across all clients
		LuaEvents.InvokeLocalForAll(LobbyDoorsButton, "B", true);
	end

	function LobbyDoorsButton.ForceCloseDoors()
		--invoke SetDoorState() and pass through "false" across all clients
		LuaEvents.InvokeLocalForAll(LobbyDoorsButton, "B", false);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function LobbyDoorsButton.Start()
		--get the current player so we can execute code specifically on the server or client side.
		mlplayer_localPlayer = Room.GetLocalPlayer();

		--get the MLClickable that should be on the same gameobject this lua script is on
		mlclickable_click = LobbyDoorsButton.gameObject.GetComponent(MLClickable);

		--add our local OnClick function
		--it's worth noting that the OnClick is not synced between clients, but we work around that.
		mlclickable_click.OnClick.Add(OnClick);

		bool_server_doorState.OnVariableChange.Add(bool_server_doorState_OnChange);
		bool_server_doorState.OnVariableSet.Add(bool_server_doorState_OnSet);

		--add our events so they can be called across clients
		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(LobbyDoorsButton, "A", ToggleDoor); 
		LuaEvents.AddLocal(LobbyDoorsButton, "B", SetDoorState); 

		----------------- MASTER CLIENT -----------------
		if(mlplayer_localPlayer.isMasterClient == true) then
			bool_doorStateLocal = false;
			bool_server_doorState.SyncSet(bool_doorStateLocal);
		end

		----------------- NON MASTER CLIENT -----------------
		--get the door state from the server if we are not the master client
		if(mlplayer_localPlayer.isMasterClient == false) then
			--force update so we can try to get the latest value from the server
			bool_server_doorState.Update();

			--get the value from the server of the current door state
			bool_doorStateLocal = bool_server_doorState.SyncGet();
		end

		UpdateDoorDirector();
	end

	-- update called every frame
	function LobbyDoorsButton.Update()

	end
end