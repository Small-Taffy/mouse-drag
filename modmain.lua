GLOBAL.setmetatable(env, {__index = function(_, v) return GLOBAL:rawget(v) end})
Assets = {
	Asset("ATLAS", "images/mods.xml"),
	Asset("IMAGE", "images/mods.tex"),
}
PrefabFiles = {
	"grid_display",
	"range_ring",
	"shadowcurse",
}
if LOC.GetLocaleCode() == "zh" then
	modimport("scripts/strings_zh.lua")
else
	modimport("scripts/strings_en.lua")
end
-- 排队论
modimport("scripts/queue.lua")
-- 物品指示收集
if GetModConfigData("Finder") then
	modimport("scripts/finder.lua")
end
-- 范围显示
if GetModConfigData("Range") then
	modimport("scripts/range.lua")
end
-- 改多数非工作长动作动作为短动作
if GetModConfigData("Short") then
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.PICK, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.HARVEST, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.UNWRAP, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BUILD, "doshortaction"))
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TERRAFORM, "doshortaction"))
end
-- 种植建造不受地面物品影响/全部零间距
if GetModConfigData("Ignorance") == 1 then
	AddClassPostConstruct("components/inventoryitem", function(self)
		self.inst:AddTag("NOBLOCK")
	end)
elseif GetModConfigData("Ignorance") == 2 then
	AddPrefabPostInitAny(function(inst)
		if inst.components.deployable then
			inst.components.deployable.min_spacing = 0
		end
	end)
	AddPlayerPostInit(function(inst)
		inst:DoTaskInTime(0, function()
			for _, recipe in pairs(Recipes) do
				recipe.min_spacing = 0
			end
		end)
	end)
end