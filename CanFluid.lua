do -- script CanFluid 
	
	--[[
	This is a script that handles logic for water cans.
	These can be spawned from a vending machine.
    As for interaction the player can grab these, open with trigger, and tilt the can to a specific angle where "water" will be drained.

	As for server code, only events are syncronized which set the "bool_localLiftState".
	]]--

	-- get reference to the script
	local CanFluid = LUA.script;

    --|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
    --these variables are exposed and accessible through the unity inspector

    local gameObject_closedMesh = SerializedField("closedMesh", GameObject); --gameobject with the closed can mesh
    local gameObject_openedMesh = SerializedField("openedMesh", GameObject); --gameobject with the opened can mesh
    local number_fluidDrainRate = SerializedField("fluidDrainRate", Number); --how quickly the fluid "drains" from the can
    local number_fluidAmount = SerializedField("fluidAmount", Number); --how much "fluid" is in the can
    local number_pourAngle = SerializedField("pourAngle", Number); --the angle at which the can will start draining when emptied
    local audioSource_openAudio = SerializedField("openAudio", AudioSource); --the audio source to use when the can is opened
    local audioSource_pourAudio = SerializedField("pourAudio", AudioSource); --the audio source to use when the can is pouring.
    local playableDirector_particleTimeline = SerializedField("particleTimeline", PlayableDirector); --the sequence to play for when the can is pouring (since there is no particle SDK support, we can use sequences and "signal" assets to tell the water particle system to start/stop)

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

    local bool_isOpened = false; --the current state of the can
    local mlgrab_grab = nil;
    local mlplayer_localPlayer = nil;

    --|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

    --Added to LuaEvents so this can be called across clients.
    local function LocalForceRelease()
		mlgrab_grab.ForceRelease();
	end

	local function OpenCan()
        audioSource_openAudio.Play();
        bool_isOpened = true;

        gameObject_closedMesh.SetActive(false);
        gameObject_openedMesh.SetActive(true);
	end

    --properly plays a looping audio source
	local function PlayLoopingAudio(audioSource_source)
        if (audioSource_source.isActiveAndEnabled == true) then
            --if loop is set to false for some reason, then set it back to true
            if (audioSource_source.loop == false) then
                audioSource_source.loop = true;
			end

            --if its not playing, make sure it plays
            if (audioSource_source.isPlaying == false) then
                audioSource_source.Play();
			end
		end
    end

    --|||||||||||||||||||||||||||||||||||||||||||||| MLGRAB CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLGRAB CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLGRAB CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function OnClick()
        OpenCan();
	end

    --|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

    function CanFluid.ForceRelease()
        --Invoke LocalForceRelease() across clients to be absolutely sure that we forcibly release this object.
        LuaEvents.InvokeLocalForAll(WeaponScript, "A");
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function CanFluid.Start()
		mlgrab_grab = CanFluid.gameObject.GetComponent(MLGrab);

        mlgrab_grab.OnPrimaryTriggerDown.Add(OnClick);

        --NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
        LuaEvents.AddLocal(CanFluid, "A", LocalForceRelease);
	end

	-- update called every frame
	function CanFluid.Update()
		if (number_fluidAmount <= 0.0) then
            audioSource_pourAudio.enabled = false;
            do return end
		end

        if (bool_isOpened == true) then
            local number_canAngle = Vector3.Angle(-CanFluid.gameObject.transform.up, -Vector3.up);

            if (number_canAngle > number_pourAngle) then
                audioSource_pourAudio.enabled = true;
                PlayLoopingAudio(audioSource_pourAudio);

                --if (playableDirector_particleTimeline.state == not PlayState.Playing) then
                    --playableDirector_particleTimeline.Play();
                --end

                number_fluidAmount = number_fluidAmount - (number_fluidDrainRate * Time.deltaTime);
            else
                --playableDirector_particleTimeline.Stop();
                audioSource_pourAudio.enabled = false;
			end
        end
	end
end