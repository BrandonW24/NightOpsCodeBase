do -- script MountedTurret 
	
	-- get reference to the script
	local MountedTurret = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are exposed and accessible through the unity inspector

	local gameObject_mlStationObject = SerializedField("Station", GameObject); --GameObject type
	local number_turretMaxVerticalAngle = SerializedField("Max Vertical Angle", Number); --Number type
	local number_turretMinVerticalAngle = SerializedField("Min Vertical Angle", Number); --Number type
	local number_turretHorizontalSpeed = SerializedField("Horizontal Speed", Number); --Number type
	local number_turretVerticalSpeed = SerializedField("Vertical Speed", Number); --Number type
	local gameObject_turretHorizontalObject = SerializedField("Turret Horizontal", GameObject); --GameObject type
	local gameObject_turretVerticalObject = SerializedField("Turret Vertical", GameObject); --GameObject type

	local audioSource_turretLoopingSource = SerializedField("(SOUND) Looping Audio Source", AudioSource); --AudioSource type
	local audioClip_turretMoveSound = SerializedField("(SOUND) Move Sound", AudioClip); --AudioClip type
	local audioClip_turretActiveSound = SerializedField("(SOUND) Active Sound", AudioClip); --AudioClip type
	local audioClip_turretLeaveSound = SerializedField("(SOUND) Leave Sound", AudioClip); --AudioClip type

	local number_turretFireRate = SerializedField("(GUNS) Fire Rate", Number); --Number type
	local number_turretRaycastForce = SerializedField("(GUNS) Raycast Force", Number); --Number type
	local number_turretDamage = SerializedField("(GUNS) Damage", Number); --Number type
	local gameObject_turretHitPrefab = SerializedField("(GUNS) Hit Prefab", GameObject); --GameObject type
	local number_turretHitHeightOffset = SerializedField("(Fire) Hit Prefab Height Offset", Number);
	local gameObject_turretBarrelOrigin = SerializedField("(GUNS) Barrel Origin", GameObject); --GameObject type
	local gameObject_turretLazerPointers = SerializedField("(GUNS) Lazer Pointers", GameObject); --GameObject type
	local playableDirector_fireSequence = SerializedField("(GUNS) Fire Sequence", PlayableDirector);

	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are syncronized across clients
	--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)

	local number_server_turretHorizontalY = SyncVar(MountedTurret, "a");
	local number_server_turretVerticalX = SyncVar(MountedTurret, "b");
	local bool_server_isMoving = SyncVar(MountedTurret, "c");
	local bool_server_isActive = SyncVar(MountedTurret, "d");

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local number_localTurretHorizontalY = 0;
	local number_localTurretVerticalX = 0;
	local number_nextTurretFireTime = 0;

	local bool_isMoving = false;
	local bool_isActive = false;

    local mlstation_station = nil;
	local mlplayer_staionedPlayer = nil;
	local mlplayer_staionedPlayerGUID = nil;
	local userInput_playerInput = nil;
	local audioSource_turret = nil;
	local sphereCollider_turret = nil;

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - AUDIO ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - AUDIO ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - AUDIO ||||||||||||||||||||||||||||||||||||||||||||||

	--NOTE: I want to reduce code redudancy, and because AudioClip is not a serialized object that can be passed through LuaEvent calls..
	--we can get around it by just passing in a single length string (5 + [length of string] bytes) which is serialized, and using that value to indicate which sound to play.
	--considered doing a value but since numbers in lua are considered doubles (64 bit/8 bytes or 9 bytes because of photon) a single length string would be smaller
	local function PlayTurretSound(soundStringIdentifier)
		if(soundStringIdentifier == "L") then --LEAVING
			audioSource_weaponSource.PlayOneShot(audioClip_turretLeaveSound);
		elseif(soundStringIdentifier == "A") then --ACTIVE
			audioSource_weaponSource.PlayOneShot(audioClip_turretActiveSound);
		end
	end

	local function PlayLoopingMovingSound()
		if(audioSource_turretLoopingSource.isPlaying == false) then
			audioSource_turretLoopingSource.Play();
			audioSource_turretLoopingSource.clip = audioClip_turretMoveSound;
			audioSource_turretLoopingSource.loop = true;
		end
	end

	local function StopLoopingMovingSound()
		audioSource_turretLoopingSource.Stop();
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHOOTING ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHOOTING ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHOOTING ||||||||||||||||||||||||||||||||||||||||||||||

	local function SpawnHitEffect(position, rotation)
		Object.Instantiate(gameObject_turretHitPrefab, position, rotation);
	end

	local function FireVisuals()
		if (playableDirector_fireSequence) then
			playableDirector_fireSequence.Stop();
			playableDirector_fireSequence.Play();
		end
	end

	local function FireLogic()
		local ray = PhysicRay(gameObject_turretBarrelOrigin.transform.position, gameObject_turretBarrelOrigin.transform.forward); --PhysicRay type

		--IMPORTANT: MAKES sure that we don't hit any triggers
		ray.queryTriggerInteraction = QueryTriggerInteraction.Ignore;

		local hit, cast = Physics:Raycast(ray);

		if (hit) then
			local hitPosition = cast.point; --Vector3 type
			local hitNormal = cast.normal; --Vector3 type
			local hitGameObject = cast.transform.gameObject; --GameObject type
			local hitMLPlayer = hitGameObject.GetPlayer(); --MLPlayer type
			local hitRigidbody = hitGameObject.GetComponent(Rigidbody);

			if (hitRigidbody) then
				local forceVector = gameObject_turretBarrelOrigin.transform.forward * number_turretRaycastForce; --Vector3 type
				hitRigidbody.AddForceAtPosition(forceVector, hitPosition);
			end

			if (hitMLPlayer) then
				if(hitMLPlayer.PlayerRoot ~= nil) then
					local newGamePlayerObject = hitMLPlayer.PlayerRoot.GetComponent(NewGamePlayer);
					newGamePlayerObject.script.TakeDamage(number_turretDamage, mlplayer_staionedPlayerGUID);
				end
			end

			if (gameObject_turretHitPrefab) then
				local newHitPosition = hitPosition + (hitNormal * number_turretHitHeightOffset); --Vector3 type
				local newHitRotation = Quaternion.LookRotation(hitNormal, Vector3.up); --Quaternion type

				--SELF NOTE: The parameter types that you pass through with these calls have to be serializable
				--https://sdk.massiveloop.com/getting_started/scripting/SerializableTypes.html
				--Invoke SpawnHitEffect() across all clients.
				LuaEvents.InvokeLocalForAll(MountedTurret, "C", newHitPosition, newHitRotation);
			end
		end

		--Invoke FireVisuals() across all clients
		LuaEvents.InvokeLocalForAll(MountedTurret, "A");
	end

	local function UpdateInput_Shooting()
		if(userInput_playerInput == nil) then return end

		local input_leftTrigger = userInput_playerInput.LeftTrigger; --Number type
		local input_rightTrigger = userInput_playerInput.RightTrigger; --Number type
		local input_leftPrimary = userInput_playerInput.LeftPrimary; --Boolean type
		local input_rightPrimary = userInput_playerInput.RightPrimary; --Boolean type

		--if(input_leftTrigger > 0.5) or (input_rightTrigger > 0.5) or (input_leftPrimary == true) or (input_rightPrimary == true) then
		if(input_leftTrigger > 0.5) or (input_rightTrigger > 0.5) then

			if(mlplayer_staionedPlayer.isLocal == true) then
				if(number_nextTurretFireTime < Time.time) then
					FireLogic();

					number_nextTurretFireTime = Time.time + number_turretFireRate;
				end
			end

		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - MOVEMENT ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - MOVEMENT ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - MOVEMENT ||||||||||||||||||||||||||||||||||||||||||||||

	local function UpdateInput_Movement()
		if(userInput_playerInput == nil) then return end

		local input_leftControl = userInput_playerInput.LeftControl; --Vector2 type

		local deadzoneThreshold = 0.5;

		--------------------- HORIZONTAL CONTROL ---------------------
		if (input_leftControl.x > deadzoneThreshold) then --turn the turret to the right
			if(mlplayer_staionedPlayer.isLocal == true) then
				number_localTurretHorizontalY = number_localTurretHorizontalY + (number_turretHorizontalSpeed * Time.deltaTime);
				number_server_turretHorizontalY.SyncSet(number_localTurretHorizontalY);

				bool_isMoving = true;
				bool_server_isMoving.SyncSet(bool_isMoving);
			end
		elseif (input_leftControl.x < -deadzoneThreshold) then --turn the turret to the left
			if(mlplayer_staionedPlayer.isLocal == true) then
				number_localTurretHorizontalY = number_localTurretHorizontalY - (number_turretHorizontalSpeed * Time.deltaTime);
				number_server_turretHorizontalY.SyncSet(number_localTurretHorizontalY);

				bool_isMoving = true;
				bool_server_isMoving.SyncSet(bool_isMoving);
			end
		--------------------- VERTICAL CONTROL ---------------------
		elseif (input_leftControl.y > deadzoneThreshold) then --move the turret up
			if(number_localTurretVerticalX < number_turretMaxVerticalAngle) then
				if(mlplayer_staionedPlayer.isLocal == true) then
					number_localTurretVerticalX = number_localTurretVerticalX + (number_turretVerticalSpeed * Time.deltaTime);
					number_server_turretVerticalX.SyncSet(number_localTurretVerticalX);

					bool_isMoving = true;
					bool_server_isMoving.SyncSet(bool_isMoving);
				end
			end
		elseif (input_leftControl.y < -deadzoneThreshold) then --move the turret down
			bool_isMoving = true;

			if(number_localTurretVerticalX > number_turretMinVerticalAngle) then
				if(mlplayer_staionedPlayer.isLocal == true) then
					number_localTurretVerticalX = number_localTurretVerticalX - (number_turretVerticalSpeed * Time.deltaTime);
					number_server_turretVerticalX.SyncSet(number_localTurretVerticalX);

					bool_isMoving = true;
					bool_server_isMoving.SyncSet(bool_isMoving);
				end
			end
		else --player stopped moving joystick
			if(mlplayer_staionedPlayer.isLocal == true) then
				bool_isMoving = false;
				bool_server_isMoving.SyncSet(bool_isMoving);
			end
		end
	end

	local function MoveTurret()
		--euler and local eulers are broken, you can't set them on the current SDK version at the time of writing
		--gameObject_turretHorizontalObject.transform.localEulerAngles = Vector3(0, number_localTurretHorizontalY, 0);
		--gameObject_turretVerticalObject.transform.localEulerAngles = Vector3(number_localTurretVerticalX, 0, 0);

		gameObject_turretHorizontalObject.transform.localRotation = Quaternion.Euler(0, number_localTurretHorizontalY, 0);
		gameObject_turretVerticalObject.transform.localRotation = Quaternion.Euler(number_localTurretVerticalX, 0, 0);
	end

	local function PlayTurretMovingSounds()
		if(bool_isMoving == true) then
			PlayLoopingMovingSound();
		else
			StopLoopingMovingSound();
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - TAKE DAMAGE ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - TAKE DAMAGE ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - TAKE DAMAGE ||||||||||||||||||||||||||||||||||||||||||||||

	local function SetTurretObjects()
		if(bool_isActive == true) then
			gameObject_turretLazerPointers.SetActive(true);

			if(sphereCollider_turret ~= nil) then
				sphereCollider_turret.enabled = true;
			end
		else
			gameObject_turretLazerPointers.SetActive(false);

			if(sphereCollider_turret ~= nil) then
				sphereCollider_turret.enabled = false;
			end
		end
	end

	local function LocalKickPlayerOut()
		mlstation_station.RemovePlayer();
	end

	local function LocalApplyDamageToPlayer(number_newDamageAmount, number_newPlayerActorID)
		if(mlplayer_staionedPlayer == nil) then return end

		local newGamePlayer_player = mlplayer_staionedPlayer.PlayerRoot.GetComponent(NewGamePlayer);
		local number_currPlayerHealth = newGamePlayer_player.script.GetPlayerHealth();
		local number_deductedDamage = number_currPlayerHealth - number_newDamageAmount;

		if(number_deductedDamage <= 0) then
			--Invoke LocalKickPlayerOut() across all clients.
			LuaEvents.InvokeLocalForAll(MountedTurret, "E");
			bool_isMoving = false;
		end

		newGamePlayer_player.script.TakeDamage(number_newDamageAmount, number_newPlayerActorID);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MLSTATION CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLSTATION CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLSTATION CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function OnSeated()
		mlplayer_staionedPlayer = mlstation_station.GetPlayer();
		mlplayer_staionedPlayerGUID = mlplayer_staionedPlayer.Guid;
		userInput_playerInput = mlstation_station.GetInput();

		--Invoke PlayTurretSound() to play an active sound across all clients.
		LuaEvents.InvokeLocalForAll(MountedTurret, "B", "A");

		if(mlplayer_staionedPlayer.isLocal == true) then
			bool_isActive = true;
			bool_server_isActive.SyncSet(bool_isActive);
		end
	end

	local function OnLeft()
		if(mlplayer_staionedPlayer.isLocal == true) then
			bool_isActive = false;
			bool_server_isActive.SyncSet(bool_isActive);
		end

		mlplayer_staionedPlayer = nil;
		mlplayer_staionedPlayerGUID = nil;
		userInput_playerInput = nil;

		bool_isMoving = false;

		--SELF NOTE: The parameter types that you pass through with these calls have to be serializable
		--https://sdk.massiveloop.com/getting_started/scripting/SerializableTypes.html

		--Invoke PlayTurretSound() to play a leaving sound across all clients.
		LuaEvents.InvokeLocalForAll(MountedTurret, "B", "L");
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| SERVER DATA CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function number_server_turretHorizontalY_OnChange(value)
		number_localTurretHorizontalY = value;
	end

	local function number_server_turretHorizontalY_OnSet(value)
		number_localTurretHorizontalY = value;
	end

	local function number_server_turretVerticalX_OnChange(value)
		number_localTurretVerticalX = value;
	end

	local function number_server_turretVerticalX_OnSet(value)
		number_localTurretVerticalX = value;
	end

	local function bool_server_isMoving_OnChange(value)
		bool_isMoving = value;
	end

	local function bool_server_isMoving_OnSet(value)
		bool_isMoving = value;
	end

	local function bool_server_isActive_OnChange(value)
		bool_isActive = value;
	end

	local function bool_server_isActive_OnSet(value)
		bool_isActive = value;
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	function MountedTurret.KickPlayerOut()
		--Invoke LocalKickPlayerOut() across all clients.
		LuaEvents.InvokeLocalForAll(MountedTurret, "E");
	end

	function MountedTurret.ResetTurret()
		gameObject_turretLazerPointers.SetActive(false);
	end

	function MountedTurret.ApplyDamageToPlayer(number_newDamageAmount, number_newPlayerActorID)
		--Invoke LocalApplyDamageToPlayer() across all clients.
		LuaEvents.InvokeLocalForAll(MountedTurret, "D", number_newDamageAmount, number_newPlayerActorID);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function MountedTurret.Start()
		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(MountedTurret, "A", FireVisuals);
		LuaEvents.AddLocal(MountedTurret, "B", PlayTurretSound);
		LuaEvents.AddLocal(MountedTurret, "C", SpawnHitEffect);
		LuaEvents.AddLocal(MountedTurret, "D", LocalApplyDamageToPlayer);
		LuaEvents.AddLocal(MountedTurret, "E", LocalKickPlayerOut);

		mlstation_station = gameObject_mlStationObject.GetComponent(MLStation);
		audioSource_turret = MountedTurret.gameObject.GetComponent(AudioSource);
		sphereCollider_turret = MountedTurret.gameObject.GetComponent(SphereCollider);

		mlstation_station.OnPlayerSeated.Add(OnSeated);
        mlstation_station.OnPlayerLeft.Add(OnLeft);

		number_server_turretHorizontalY.OnVariableChange.Add(number_server_turretHorizontalY_OnChange);
		number_server_turretHorizontalY.OnVariableSet.Add(number_server_turretHorizontalY_OnSet);
		number_server_turretVerticalX.OnVariableChange.Add(number_server_turretVerticalX_OnChange);
		number_server_turretVerticalX.OnVariableSet.Add(number_server_turretVerticalX_OnSet);
		bool_server_isMoving.OnVariableChange.Add(bool_server_isMoving_OnChange);
		bool_server_isMoving.OnVariableSet.Add(bool_server_isMoving_OnSet);
		bool_server_isActive.OnVariableChange.Add(bool_server_isActive_OnChange);
		bool_server_isActive.OnVariableSet.Add(bool_server_isActive_OnSet);

		gameObject_turretLazerPointers.SetActive(false);
	end

	-- update called every frame
	function MountedTurret.Update()
		UpdateInput_Shooting();
		UpdateInput_Movement();

		MoveTurret();
		PlayTurretMovingSounds();
		SetTurretObjects();
	end
end