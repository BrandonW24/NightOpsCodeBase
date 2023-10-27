do -- script AmmoPowerup 
	
	--[[
	This is a script that handles logic for being an Ammo Powerup Object.
	These are objects that are spawned throughout an ongoing match.
	These are interacted with when a weapon object enters the trigger volume, and if they are eligible (i.e. they have low ammo, and are in a match) the ammo for that weapon is replenished.
	Afterwards a used effect is spawned and the object itself is destroyed.

	There is no server side code in here, the most that happens in that regard is that this object is spawned and then destroyed.
	When the object gets destroyed, an event is called that spawns a powerup "used" effect on all clients.
	]]--

	-- get reference to the script
	local AmmoPowerup = LUA.script;
	
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are exposed and accessible through the unity inspector

	local number_powerupLifetime = SerializedField("(Properties) Lifetime", Number); --how long the powerup lasts before it destroys itself
	local gameObject_powerupUseEffect = SerializedField("(Effects) Use Effect", GameObject); --the prefab that spawns when the powerup is used

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	--spawns a used powerup effect to communicate when a powerup has been used/consumed.
	local function UsedPowerup()
		--spawn a powerup effect (if its assigned)
		if (gameObject_powerupUseEffect) then
			Object.Instantiate(gameObject_powerupUseEffect, AmmoPowerup.gameObject.transform.position, Quaternion(0, 0, 0, 0));
		end

		--destroy the powerup since its been used
		Object.Destroy(AmmoPowerup.gameObject, 0);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function AmmoPowerup.Start()
		--Add this as a local event so we can call it for all other clients that are running this object
		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(AmmoPowerup, "A", UsedPowerup);

		--destroy the powerup after it's time has passed (depending on what the lifetime value is set to)...
		Object.Destroy(AmmoPowerup.gameObject, number_powerupLifetime);
	end

	-- update called every frame
	function AmmoPowerup.Update()
	
	end

	--NOTE TO SELF: The local player is the only one that seems to trip these (other players do have colliders, but no rigidbody perhaps?)
	function AmmoPowerup.OnTriggerEnter(other)
		--NOTE: Normally these if statements are completely unecessary...
		--but during local testing ocasionally (and often in live server testing) some of these object references end up becoming nil for whatever reason.
		--to combat that and mitgate the amount of issues that would or could potentially occur at runtime, these checks are added.
		--if things are working again these can be removed later.
		if(other == nil) then return end
		if(other.gameObject == nil) then return end

		--get a gun script from the object that entered the trigger
		local GunComponent = other.gameObject.GetComponent(WeaponScript);

		--extra protection before we do anything...
		if(GunComponent == nil) then return end
		if(GunComponent.script == nil) then return end

		--check if the weapon is eligible to recieve a powerup
		if(GunComponent.script.CanGetAmmoPowerup() == true) then
		--if(other.gameObject.GetComponent(WeaponScript).script.CanGetAmmoPowerup() == true) then --GetComponent since in some instances even when cached, the object reference gets lost?

			--call the powerup function to replenish the ammo
			--and invoke UsedPowerup() which spawns an effect and destroys itself so it can't be used again across all clients.
			GunComponent.script.EquipPowerupAmmo();
			--other.gameObject.GetComponent(WeaponScript).script.EquipPowerupAmmo(); --GetComponent since in some instances even when cached, the object reference gets lost?
			LuaEvents.InvokeLocalForAll(AmmoPowerup, "A");
		end
	end
end