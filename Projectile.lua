do -- script Projectile 
	
	-- get reference to the script
	local Projectile = LUA.script;

	--public
	local gameObject_impactEffectPrefab = SerializedField("(Effects) Impact Effect", GameObject);
	local number_damageAmount = SerializedField("(Properties) Damage Points", Number); 
	
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	--called when the projectile collides with an object
	local function ProjectileImpact(collisionObject)
		--spawn the impact effect
		local gameObject_impactEffectInstance = Object.Instantiate(gameObject_impactEffectPrefab, Projectile.gameObject.transform.position, Projectile.gameObject.transform.rotation);

		--get the player object
		--local gamePlayerObject = collisionObject.gameObject.GetComponent(GamePlayer).script;
		
		--if there is a player object, then apply damage
		--if (gamePlayerObject) then
			--gamePlayerObject.TakeDamage(number_damageAmount);
		--end

		--destroy the projectile on impact
		Object.Destroy(Projectile.gameObject);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- when the projectile collides with an object
	function Projectile.OnCollisionEnter(collision)
		ProjectileImpact(collision);
	end

	-- start only called at beginning
	function Projectile.Start()

	end
	
	-- update called every frame
	function Projectile.Update()

	end
end