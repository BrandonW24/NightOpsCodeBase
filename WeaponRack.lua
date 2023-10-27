do -- script WeaponRack 
	
	-- get reference to the script
	local WeaponRack = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local gameObject_gameManager = SerializedField("Game Manager Object", GameObject);
	local gameObject_weaponPrefab = SerializedField("Weapon Prefab", GameObject);
	local gameObject_weaponSpawnLocation = SerializedField("Weapon Spawn", GameObject);
	local audioClip_weaponSpawnSound = SerializedField("Weapon Spawn Sound", AudioClip);

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local audioSource_source = nil;
	local mlclickable_button = nil;
	local mlplayer_localPlayer = nil;

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	local function SpawnWeapon()
		----------------- MASTER CLIENT -----------------
		if(mlplayer_localPlayer.isMasterClient == true) then
			Object.Instantiate(gameObject_weaponPrefab, gameObject_weaponSpawnLocation.transform.position, gameObject_weaponSpawnLocation.transform.rotation); --GameObject type
		end

		audioSource_source.PlayOneShot(audioClip_weaponSpawnSound);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function OnClick()
		--Invoking SpawnWeapon() across all clients.
		LuaEvents.InvokeLocalForAll(WeaponRack, "A");
	end

	function WeaponRack.OnCollisionEnter(collision)

		if collision.gameObject.IsPlayer() then
			LuaEvents.InvokeLocalForAll(WeaponRack, "A");
		end
	end
	
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function WeaponRack.Start()
		mlplayer_localPlayer = Room.GetLocalPlayer();

		mlclickable_button = WeaponRack.gameObject.GetComponent(MLClickable);
		audioSource_source = WeaponRack.gameObject.GetComponent(AudioSource);

		mlclickable_button.OnClick.Add(OnClick);

		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(WeaponRack, "A", SpawnWeapon);
	end

	-- update called every frame
	function WeaponRack.Update()

	end
end