do -- script HealthPowerup 
	
	--[[
	This is a script that handles logic for being an Health Powerup Object.
	These are objects that are spawned throughout an ongoing match.
	These are interacted with when the "LOCAL PLAYER" enters the trigger volume, and if they are eligible (i.e. they have low health, and are in a match) health for that player is given.
	Afterwards a used effect is spawned and the object itself is destroyed.

	There is no server side code in here, the most that happens in that regard is that this object is spawned and then destroyed.
	When the object gets destroyed, an event is called that spawns a powerup "used" effect on all clients.
	]]--

	-- get reference to the script
	local HealthPowerup = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are exposed and accessible through the unity inspector

	local number_powerupLifetime = SerializedField("(Properties) Lifetime", Number); --how long the powerup lasts before it destroys itself
	local number_powerupAmount = SerializedField("(Properties) Health Points", Number); --how many health points to add when this is used
	local gameObject_powerupUseEffect = SerializedField("(Effects) Use Effect", GameObject); --the prefab that spawns when the powerup is used
	
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	--spawns a used powerup effect to communicate when a powerup has been used/consumed.
	local function UsedPowerup()
		--spawn a powerup effect (if its assigned)
		if (gameObject_powerupUseEffect) then
			Object.Instantiate(gameObject_powerupUseEffect, HealthPowerup.gameObject.transform.position, Quaternion(0, 0, 0, 0));
		end

		--destroy the powerup since its been used
		Object.Destroy(HealthPowerup.gameObject, 0);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function HealthPowerup.Start()
		--Add this as a local event so we can call it for all other clients that are running this object
		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(HealthPowerup, "A", UsedPowerup);

		--destroy the powerup after it's time has passed...
		Object.Destroy(HealthPowerup.gameObject, number_powerupLifetime);
	end
	
	-- update called every frame
	function HealthPowerup.Update()

	end

	--NOTE TO SELF: The local player is the only one that seems to trip these (other players do have colliders, but no rigidbody perhaps?)
	function HealthPowerup.OnTriggerEnter(other)
		--NOTE: Normally these if statements are completely unecessary...
		--but during local testing ocasionally (and often in live server testing) some of these object references end up becoming nil for whatever reason.
		--to combat that and mitgate the amount of issues that would or could potentially occur at runtime, these checks are added.
		--if things are working again these can be removed later.
		if(other == nil) then return end
		if(other.gameObject == nil) then return end

		--don't continue if the gameobject is not an "MLPlayer" (or has the component)
		if(other.gameObject.IsPlayer() == false) then return end

		--get the MLPlayer component
		local mlplayerObject = other.gameObject.GetPlayer();

		--extra protection if these are nil...
		if(mlplayerObject == nil) then return end
		if(mlplayerObject.PlayerRoot == nil) then return end

		--get our custom player script which should be on the root.
		local newGamePlayerObject = mlplayerObject.PlayerRoot.GetComponent(NewGamePlayer);

		--extra protection if these are nil...
		if(newGamePlayerObject == nil) then return end
		if(newGamePlayerObject.script == nil) then return end

		--check if the player is eligible for getting a powerup, if not then don't continue
		if(newGamePlayerObject.script.CanGetHealthPowerup() == false) then return end

		--add health points to the player
		--and invoke UsedPowerup() which spawns an effect and destroys itself so it can't be used again across all clients.
		newGamePlayerObject.script.AddHealth(number_powerupAmount);
		LuaEvents.InvokeLocalForAll(HealthPowerup, "A");
	end
end