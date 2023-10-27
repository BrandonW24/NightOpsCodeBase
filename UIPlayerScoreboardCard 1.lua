do -- script UIPlayerScoreboardCard 

	-- get reference to the script
	local UIPlayerScoreboardCard_cloud = LUA.script;
	
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local gameObject_playerNameText = SerializedField("Player Name Text", GameObject);
	local gameObject_playerKillsText = SerializedField("Player Kills Text", GameObject);
	local gameObject_playerAssistsText = SerializedField("Player Assists Text", GameObject);
	local gameObject_playerDeathsText = SerializedField("Player Deaths Text", GameObject);
	local gameObject_playerScoreText = SerializedField("Player Score Text", GameObject);

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	--player property keys
	local string_PLAYERKEY_serverKills = "Kills";
	local string_PLAYERKEY_serverDeaths = "Deaths";
	local string_PLAYERKEY_serverAssists = "Assists";

	local mlplayer_assignedPlayer = nil;
	
	local text_playerNameText = nil;
	local text_playerKillsText = nil;
	local text_playerAssistsText = nil;
	local text_playerDeathsText = nil;
	local text_playerScoreText = nil;

	local number_localKills = 0;
	local number_localAssists = 0;
	local number_localDeaths = 0;
	local number_localScore = 0;

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHARED ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHARED ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN - SHARED ||||||||||||||||||||||||||||||||||||||||||||||

	--Decodes an encoded GUID by putting back the hyphens.
	local function DecodeShortendGUID(string_encodedGUID)
		--Raw GUID: 3F2504E0-4F89-41D3-9A0C-0305E82C3301
		--Encoded GUID: 3F2504E04F8941D39A0C0305E82C3301
		--Pattern { 8 characters - 4 characters - 4 characters - 4 characters - 12 characters }

		local string_guidPart1 = string_encodedGUID:sub(1, 8); --good
		local string_guidPart2 = string_encodedGUID:sub(9, 12); --good
		local string_guidPart3 = string_encodedGUID:sub(13, 16);
		local string_guidPart4 = string_encodedGUID:sub(17, 20);
		local string_guidPart5 = string_encodedGUID:sub(21, 32);
		local string_combined = string_guidPart1 .. "-" .. string_guidPart2 .. "-" .. string_guidPart3 .. "-" .. string_guidPart4 .. "-" .. string_guidPart5;
		return string_combined;
	end

	--Encodes a raw GUID by removing the hyphens, saving 4 bytes... (every little bit helps?)
	local function EncodeShorterGUID(string_rawGUID)
		return string.gsub(string_rawGUID, '%-', '');
	end

	local function EncodeActorID(number_playerActorID)
		return tostring(number_playerActorID);
	end

	local function DecodeActorID(string_encodedPlayerActorID)
		return tonumber(string_encodedPlayerActorID);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	local function LocalUpdateText()
		if(mlplayer_assignedPlayer == nil) then return end

		number_localKills = mlplayer_assignedPlayer.GetProperty(string_PLAYERKEY_serverKills);
		number_localAssists = mlplayer_assignedPlayer.GetProperty(string_PLAYERKEY_serverAssists);
		number_localDeaths = mlplayer_assignedPlayer.GetProperty(string_PLAYERKEY_serverDeaths);
		number_localScore = mlplayer_assignedPlayer.Score;

		text_playerNameText.text = tostring(mlplayer_assignedPlayer.NickName);
		text_playerKillsText.text = tostring(number_localKills);
		text_playerAssistsText.text = tostring(number_localAssists);
		text_playerDeathsText.text = tostring(number_localDeaths);
		text_playerScoreText.text = tostring(number_localScore);
	end

	local function LocalSetPlayer(string_encodedPlayerActorID)
		local number_decodedPlayerActorID = DecodeActorID(string_encodedPlayerActorID);

		mlplayer_assignedPlayer = Room.FindPlayerByActorNumber(number_decodedPlayerActorID);

		LocalUpdateText();
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	function UIPlayerScoreboardCard.UpdateText()
		--Invoking LocalUpdateText() across all clients.
		LuaEvents.InvokeLocalForAll(UIPlayerScoreboardCard, "B");
	end

	function UIPlayerScoreboardCard.SetPlayer(number_playerActorID)
		local string_encodedPlayerActorID = EncodeActorID(number_playerActorID);

		--Invoking LocalSetPlayer() across all clients.
		LuaEvents.InvokeLocalForAll(UIPlayerScoreboardCard, "A", string_encodedPlayerActorID);
	end

	function UIPlayerScoreboardCard.IsSet()
		if(mlplayer_assignedPlayer == nil) then
			return false;
		else
			return true;
		end
	end

	function UIPlayerScoreboardCard.GetLocalScoreValue()
		return number_localScore;
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function UIPlayerScoreboardCard.Start()
		text_playerNameText = gameObject_playerNameText.GetComponent(Text);
		text_playerKillsText = gameObject_playerKillsText.GetComponent(Text);
		text_playerAssistsText = gameObject_playerAssistsText.GetComponent(Text);
		text_playerDeathsText = gameObject_playerDeathsText.GetComponent(Text);
		text_playerScoreText = gameObject_playerScoreText.GetComponent(Text);

		--NOTE: kept names small since they can affect server sync performance (I would prefer to have readable names... but they are costly)
		LuaEvents.AddLocal(UIPlayerScoreboardCard, "A", LocalSetPlayer);
		LuaEvents.AddLocal(UIPlayerScoreboardCard, "B", LocalUpdateText);
	end

	-- update called every frame
	function UIPlayerScoreboardCard.Update()

	end
end