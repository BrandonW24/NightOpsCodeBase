do -- script VendingMachine 
	
	-- get reference to the script
	local VendingMachine = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local playableDirector_animation = SerializedField("Animation Sequence", PlayableDirector);
	local gameObject_canPrefab = SerializedField("Can Prefab", GameObject);
	local gameObject_canSpawnLocation = SerializedField("Can Spawn", GameObject);
	local number_canSpawnTime = SerializedField("Can Spawn Time", Number);

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local number_nextCanSpawnTime = 0;
	local mlclickable_button = nil;
	local mlplayer_localPlayer = nil;

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	local function SpawnCan()
		--make sure that we can't spawn a can immedieatly after spawning one.
		if(Time.time < number_nextCanSpawnTime) then return end

		--play the animation/sound of the drawer opening
		playableDirector_animation.Stop();
		playableDirector_animation.Play();

		----------------- MASTER CLIENT -----------------
		--spawn a can ONLY on the master client
		if(mlplayer_localPlayer.isMasterClient == true) then
			Object.Instantiate(gameObject_canPrefab, gameObject_canSpawnLocation.transform.position, gameObject_canSpawnLocation.transform.rotation); --GameObject type
		end
		
		--increment the next time we can spawn a new can
		number_nextCanSpawnTime = Time.time + number_canSpawnTime;
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function OnClick()
		--Invoking SpawnCan() across all clients.
		LuaEvents.InvokeLocalForAll(VendingMachine, "A");
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function VendingMachine.Start()
		mlplayer_localPlayer = Room.GetLocalPlayer();

		mlclickable_button = VendingMachine.gameObject.GetComponent(MLClickable);
		mlclickable_button.OnClick.Add(OnClick);

		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(VendingMachine, "A", SpawnCan);
	end

	-- update called every frame
	function VendingMachine.Update()

	end
end