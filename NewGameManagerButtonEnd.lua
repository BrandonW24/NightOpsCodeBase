do -- script NewGameManagerButtonEnd 
	
	-- get reference to the script
	local NewGameManagerButtonEnd = LUA.script;

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local gameObject_gameManager = SerializedField("New Game Manager Object", GameObject);

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local mlclickable_button = nil;
	
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function OnClick()
		gameObject_gameManager.GetComponent(NewGameManager).script.EndMatch();
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function NewGameManagerButtonEnd.Start()
		mlclickable_button = NewGameManagerButtonEnd.gameObject.GetComponent(MLClickable);
		mlclickable_button.OnClick.Add(OnClick);
	end

	-- update called every frame
	function NewGameManagerButtonEnd.Update()

	end
end