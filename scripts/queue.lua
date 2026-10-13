TUNING.CONFIG_DEFAULT = {
	RANGE = GetModConfigData("range_default"),
	PICKUP = GetModConfigData("pickup_default"),
	REMODE = GetModConfigData("remode_default"),
	LINKED = GetModConfigData("linked_default"),
	FORCE = GetModConfigData("force_default"),
	REMOTE = GetModConfigData("remote_default"),
}
--官方定义了间距但没限定种植条件
local NoSpacing = {"lureplantbulb", "spidereggsack"}
for _, prefab in ipairs(NoSpacing) do
	AddPrefabPostInit(prefab, function(inst)
		if inst.components.deployable then
			inst.components.deployable.min_spacing = 0
		end
	end)
end
-- SHIFT按下后禁左右键控制
AddClassPostConstruct("components/playercontroller", function(self)
	local oldOnLeftClick = self.OnLeftClick
	function self:OnLeftClick(down)
		if TheInput:IsKeyDown(KEY_SHIFT) and down then return end
		return oldOnLeftClick(self, down)
	end
	local oldOnRightClick = self.OnRightClick
	function self:OnRightClick(down)
		if TheInput:IsKeyDown(KEY_SHIFT) and down then return end
		return oldOnRightClick(self, down)
	end
end)
-- 添加组件
local Colours = {
	C1 = {.80, .05, .05},
	C2 = {.25, .75, .25},
	C3 = {.10, .10, .99},
	C4 = {.90, .10, .80},
	C5 = {.85, .40, .00},
	C6 = {.00, .65, .90},
	C7 = {.35, .00, .99},
}
local rgb = Colours[GetModConfigData("Colour")]
local KEY_ACTION = GetModConfigData("Action")
local KEY_RECIPE = GetModConfigData("Recipe")
local KEY_GRID = GetModConfigData("Grid")
local ConfigWidget = require "widgets/configwidget"
AddPlayerPostInit(function(inst)
	inst:AddComponent("queuedoer")
	inst.components.queuedoer.rgb = rgb
	TheInput:AddControlHandler(CONTROL_PRIMARY, function(down) inst.components.queuedoer:OnLeftClick(down) end)
	TheInput:AddControlHandler(CONTROL_SECONDARY, function(down) inst.components.queuedoer:OnRightClick(down) end)
	TheInput:AddKeyDownHandler(KEY_LALT, function() inst.components.queuedoer:OnListen() end)
	TheInput:AddKeyDownHandler(KEY_RALT, function() inst.components.queuedoer:OnListen() end)
	TheInput:AddKeyDownHandler(KEY_ACTION, function() inst.components.queuedoer:OnAction() end)
	TheInput:AddKeyDownHandler(KEY_RECIPE, function() inst.components.queuedoer:OnRecipe() end)
	TheInput:AddKeyDownHandler(KEY_GRID, function() inst.components.queuedoer:OnGrid() end)
	inst:DoTaskInTime(0, function(inst)
		if inst.HUD and inst.HUD.controls then
			inst.configwidget = inst.HUD.controls:AddChild(ConfigWidget(inst, inst.components.queuedoer))
		end
	end)
end)