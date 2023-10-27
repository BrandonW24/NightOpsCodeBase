do -- script explosion 
	
	-- get reference to the script
	local explosion = LUA.script;
	local obj = explosion.gameObject;


	function explosion.OnTriggerEnter(collision)
	
		local hitGameObject = collision.gameObject;

		--if we hit a player
		local hitGamePlayer = hitGameObject.GetComponent(GamePlayer); --GamePlayer type

		local gameObject_hitObject = collision.gameObject; --GameObject type
		local mlplayer_hitPlayer = gameObject_hitObject.GetPlayer(); --MLPlayer type


		if (mlplayer_hitPlayer) then
			if(mlplayer_hitPlayer.PlayerRoot ~= nil) then
				local newGamePlayer_player = mlplayer_hitPlayer.PlayerRoot.GetComponent(NewGamePlayer);

				--additional nil checks
				if(newGamePlayer_player ~= nil) then
					if(newGamePlayer_player.script ~= nil) then
						newGamePlayer_player.script.TakeDamage(100, 0);

					end
				end
			end
		end


	end

	-- start only called at beginning
	function explosion.Start()
	
	
	end

	
	-- update called every frame
	function explosion.Update()

	
	end
end