do -- script RenderingManager 
	
	-- get reference to the script
	local RenderingManager = LUA.script;
	
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PUBLIC VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local gameObject_clientUI = SerializedField("(UI) Local UI", GameObject);
	local gameObject_masterClientUI = SerializedField("(UI) Master Client UI", GameObject);

	local gameObject_depthHack = SerializedField("(FOG) Depth Hack", GameObject);
	local gameObject_volumeArena = SerializedField("(FOG) Volume Arena", GameObject);
	local gameObject_volumeLobby = SerializedField("(FOG) Volume Lobby", GameObject);
	local gameObject_motionBlur = SerializedField("Motion Blur", GameObject);
	local gameObject_bloom = SerializedField("Bloom", GameObject);
	local gameObject_color = SerializedField("Color", GameObject);
	local gameObject_particles = SerializedField("Particles", GameObject);

	local material_on = SerializedField("(BUTTON) UI On", Material);
	local material_off = SerializedField("(BUTTON) UI Off", Material);
	local material_pointer = SerializedField("(BUTTON) UI Pointer", Material);

	local gameObject_fogButton = SerializedField("(BUTTON) Fog Button", GameObject);
	local gameObject_particlesButton = SerializedField("(BUTTON) Particles Button", GameObject);
	local gameObject_colorButton = SerializedField("(BUTTON) Color Button", GameObject);
	local gameObject_bloomButton = SerializedField("(BUTTON) Bloom Button", GameObject);
	local gameObject_motionBlurButton = SerializedField("(BUTTON) Motion Blur Button", GameObject);

	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| PRIVATE VARIABLES ||||||||||||||||||||||||||||||||||||||||||||||

	local mlplayer_localPlayer = nil;

	local mlclickable_fogButton = nil;
	local mlclickable_particlesButton = nil;
	local mlclickable_colorButton = nil;
	local mlclickable_bloomButton = nil;
	local mlclickable_motionBlurButton = nil;

	local renderer_fogButton = nil;
	local renderer_particlesButton = nil;
	local renderer_colorButton = nil;
	local renderer_bloomButton = nil;
	local renderer_motionBlurButton = nil;

	local bool_fogToggle = true;
	local bool_particlesToggle = true;
	local bool_colorToggle = true;
	local bool_bloomToggle = true;
	local bool_motionBlurToggle = true;

	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MAIN ||||||||||||||||||||||||||||||||||||||||||||||

	local function UpdateRendererMaterial(renderer_mesh, bool_toggle)
		if(bool_toggle == true) then
			renderer_mesh.sharedMaterial = material_on;
		else
			renderer_mesh.sharedMaterial = material_off;
		end
	end

	local function SetRenderingSettings()
		if(mlplayer_localPlayer.isMasterClient == true) then
			gameObject_clientUI.SetActive(false);
			gameObject_masterClientUI.SetActive(true);

			--fog
			gameObject_depthHack.SetActive(false);
			gameObject_volumeArena.SetActive(false);
			gameObject_volumeLobby.SetActive(false);

			--color (not disabling since its vital to the look of the world)
			--gameObject_color.SetActive(false);

			--bloom
			gameObject_bloom.SetActive(false);

			--particles
			gameObject_particles.SetActive(false);

			--motion blur
			gameObject_motionBlur.SetActive(false);
		else
			gameObject_clientUI.SetActive(true);
			gameObject_masterClientUI.SetActive(false);
		end
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| MLCLICKABLE CALLBACKS ||||||||||||||||||||||||||||||||||||||||||||||

	local function Fog_OnClick()
		bool_fogToggle = not bool_fogToggle;
		gameObject_depthHack.SetActive(bool_fogToggle);
		gameObject_volumeArena.SetActive(bool_fogToggle);
		gameObject_volumeLobby.SetActive(bool_fogToggle);

		UpdateRendererMaterial(renderer_fogButton, bool_fogToggle);
	end

	local function Particles_OnClick()
		bool_particlesToggle = not bool_particlesToggle;
		gameObject_particles.SetActive(bool_particlesToggle);

		UpdateRendererMaterial(renderer_particlesButton, bool_particlesToggle);
	end

	local function Color_OnClick()
		bool_colorToggle = not bool_colorToggle;
		gameObject_color.SetActive(bool_colorToggle);

		UpdateRendererMaterial(renderer_colorButton, bool_colorToggle);
	end

	local function Bloom_OnClick()
		bool_bloomToggle = not bool_bloomToggle;
		gameObject_bloom.SetActive(bool_bloomToggle);

		UpdateRendererMaterial(renderer_bloomButton, bool_bloomToggle);
	end

	local function MotionBlur_OnClick()
		bool_motionBlurToggle = not bool_motionBlurToggle;
		gameObject_motionBlur.SetActive(bool_motionBlurToggle);

		UpdateRendererMaterial(renderer_motionBlurButton, bool_motionBlurToggle);
	end

	local function Fog_OnPointerEnter()
		renderer_fogButton.sharedMaterial = material_pointer;
	end

	local function Particles_OnPointerEnter()
		renderer_particlesButton.sharedMaterial = material_pointer;
	end

	local function Color_OnPointerEnter()
		renderer_colorButton.sharedMaterial = material_pointer;
	end

	local function Bloom_OnPointerEnter()
		renderer_bloomButton.sharedMaterial = material_pointer;
	end

	local function MotionBlur_OnPointerEnter()
		renderer_motionBlurButton.sharedMaterial = material_pointer;
	end

	local function Fog_OnPointerExit()
		UpdateRendererMaterial(renderer_fogButton, bool_fogToggle);
	end

	local function Particles_OnPointerExit()
		UpdateRendererMaterial(renderer_particlesButton, bool_particlesToggle);
	end

	local function Color_OnPointerExit()
		UpdateRendererMaterial(renderer_colorButton, bool_colorToggle);
	end

	local function Bloom_OnPointerExit()
		UpdateRendererMaterial(renderer_bloomButton, bool_bloomToggle);
	end

	local function MotionBlur_OnPointerExit()
		UpdateRendererMaterial(renderer_motionBlurButton, bool_motionBlurToggle);
	end

	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||
	--|||||||||||||||||||||||||||||||||||||||||||||| UNITY FUNCTIONS ||||||||||||||||||||||||||||||||||||||||||||||

	-- start only called at beginning
	function RenderingManager.Start()
		mlplayer_localPlayer = Room.GetLocalPlayer();

		mlclickable_fogButton = gameObject_fogButton.GetComponent(MLClickable);
		mlclickable_particlesButton = gameObject_particlesButton.GetComponent(MLClickable);
		mlclickable_colorButton = gameObject_colorButton.GetComponent(MLClickable);
		mlclickable_bloomButton = gameObject_bloomButton.GetComponent(MLClickable);
		mlclickable_motionBlurButton = gameObject_motionBlurButton.GetComponent(MLClickable);

		renderer_fogButton = gameObject_fogButton.GetComponent(Renderer);
		renderer_particlesButton = gameObject_particlesButton.GetComponent(Renderer);
		renderer_colorButton = gameObject_colorButton.GetComponent(Renderer);
		renderer_bloomButton = gameObject_bloomButton.GetComponent(Renderer);
		renderer_motionBlurButton = gameObject_motionBlurButton.GetComponent(Renderer);

		mlclickable_fogButton.OnClick.Add(Fog_OnClick);
		mlclickable_particlesButton.OnClick.Add(Particles_OnClick);
		mlclickable_colorButton.OnClick.Add(Color_OnClick);
		mlclickable_bloomButton.OnClick.Add(Bloom_OnClick);
		mlclickable_motionBlurButton.OnClick.Add(MotionBlur_OnClick);

		mlclickable_fogButton.OnPointerEnter.Add(Fog_OnPointerEnter);
		mlclickable_particlesButton.OnPointerEnter.Add(Particles_OnPointerEnter);
		mlclickable_colorButton.OnPointerEnter.Add(Color_OnPointerEnter);
		mlclickable_bloomButton.OnPointerEnter.Add(Bloom_OnPointerEnter);
		mlclickable_motionBlurButton.OnPointerEnter.Add(MotionBlur_OnPointerEnter);

		mlclickable_fogButton.OnPointerExit.Add(Fog_OnPointerExit);
		mlclickable_particlesButton.OnPointerExit.Add(Particles_OnPointerExit);
		mlclickable_colorButton.OnPointerExit.Add(Color_OnPointerExit);
		mlclickable_bloomButton.OnPointerExit.Add(Bloom_OnPointerExit);
		mlclickable_motionBlurButton.OnPointerExit.Add(MotionBlur_OnPointerExit);

		UpdateRendererMaterial(renderer_fogButton, bool_fogToggle);
		UpdateRendererMaterial(renderer_particlesButton, bool_particlesToggle);
		UpdateRendererMaterial(renderer_colorButton, bool_colorToggle);
		UpdateRendererMaterial(renderer_bloomButton, bool_bloomToggle);
		UpdateRendererMaterial(renderer_motionBlurButton, bool_motionBlurToggle);

		SetRenderingSettings();
	end
	
	-- update called every frame
	function RenderingManager.Update()

	end
end