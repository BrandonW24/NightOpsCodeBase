do -- script ArenaLift 
	
	--[[
	This is a script that handles logic for controlling a lift
	These are pre-placed in the arena and can be used any time.
	These are interacted with when the "LOCAL PLAYER" enters the trigger volume, and raises the platform all the way to its raised position.

	As for server code, only events are syncronized which set the "bool_localLiftState".
	]]--

	-- get reference to the script
	local ArenaLift = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--these variables are exposed and accessible through the unity inspector

	local gameObject_liftDefaultPositionObject = SerializedField("Default Position", GameObject); --the gameobject that acts as the default position for the lift
	local gameObject_liftRasiedPositionObject = SerializedField("Rasied Positon", GameObject); --the gameobject that acts as the raised position for the lift
	local gameObject_liftObject = SerializedField("Lift", GameObject); --the lift object itself
	local number_liftSpeed = SerializedField("Speed", Number); --the speed at which the lift

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local bool_localLiftState = false; --the current state of the lift, false = default position, true = raised position

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	--runs every frame, depending on the lift state the lift object's poition will be gradually interpolated to be either at the raised position or the default position.
	local function UpdateLiftAnimation()
		if(bool_localLiftState == true) then
			gameObject_liftObject.transform.position = Vector3.Lerp(gameObject_liftObject.transform.position, gameObject_liftRasiedPositionObject.transform.position, Time.deltaTime * number_liftSpeed);
		else
			gameObject_liftObject.transform.position = Vector3.Lerp(gameObject_liftObject.transform.position, gameObject_liftDefaultPositionObject.transform.position, Time.deltaTime * number_liftSpeed);
		end
	end

	--when a player enters the trigger volume, the lift is activated
	local function ActivateLift()
		bool_localLiftState = true;
	end

	--when a player leaves the trigger volume, the lift is deactivated
	local function DeactivateLift()
		bool_localLiftState = false;
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function ArenaLift.Start()
		--these are added to the lua events registry so we can do a synchronized call of these functions across all clients later.
		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(ArenaLift, "A", ActivateLift);
		LuaEvents.AddLocal(ArenaLift, "B", DeactivateLift);
	end

	-- update called every frame
	function ArenaLift.Update()
		UpdateLiftAnimation();
	end

	--NOTE TO SELF: The local player is the only one that seems to trip these (other players do have colliders, but no rigidbody perhaps?)
	function ArenaLift.OnTriggerEnter(other)

		--if the object that entered the trigger volume is infact a player
		if(other.gameObject.IsPlayer() == true) then
			--call ActivateLift() for all clients
			LuaEvents.InvokeLocalForAll(ArenaLift, "A");
		end

	end

	--NOTE TO SELF: The local player is the only one that seems to trip these (other players do have colliders, but no rigidbody perhaps?)
	function ArenaLift.OnTriggerExit(other)

		--if the object that entered the trigger volume is infact a player
		if(other.gameObject.IsPlayer() == true) then
			--call DeactivateLift() for all clients
			LuaEvents.InvokeLocalForAll(ArenaLift, "B");
		end

	end
end