do -- script SelfDestruct 
	
	-- get reference to the script
	local SelfDestruct = LUA.script;
	
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local number_timeDelay = SerializedField("Time Delay", Number); --how long until the object destroys itself

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function SelfDestruct.Start()
		--Object.Destroy(SelfDestruct.gameObject, number_timeDelay);
		Object.Destroy(SelfDestruct.gameObject, .5);
	end

	
	-- update called every frame
	function SelfDestruct.Update()

	end
end