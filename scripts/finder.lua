local function KillFlash(inst)
	if inst.flash_task then
		inst.flash_task:Cancel()
		inst.flash_task = nil
	end
	inst:SetAddColour(0, 0, 0, 1)
end
local OMEGA = 3 * math.pi / 2
local function UpdateFlash(inst, time)
	local t = GetTime() - time
	local value = (math.sin(t * OMEGA) + 1) * 0.5
	inst:SetAddColour(value, 0, 0, 1)
end
local function StartFlash(inst)
	KillFlash(inst)
	local time = GetTime()
	inst.flash_task = inst:DoPeriodicTask(0, UpdateFlash, nil, time)
end
local function ClearMarks(marks)
	for _, mark in ipairs(marks) do
		if mark.entity and mark.entity:IsValid() then KillFlash(mark.entity) end
		if mark.effect and mark.effect:IsValid() then mark.effect:Remove() end
	end
end
local function FoucsChange(inst, data, marks)
	ClearMarks(marks)
	local newmarks = {}
	if inst and data and data.item then
		local x, _, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, 30, nil, {"player", "FX", "NOCLICK", "DECOR", "INLIMBO"})
		for _, ent in ipairs(ents) do
			if ent and ent.entity:IsVisible() and ent.components.container and ent.components.container:Has(data.item.prefab, 1) then
				StartFlash(ent)
				local fx = ent:SpawnChild("shadowcurse")
				table.insert(newmarks, {entity = ent, effect = fx})
			end
		end
	end
	return newmarks
end
AddPlayerPostInit(function(inst)
	inst.activemarks = {}
	inst:ListenForEvent("newactiveitem", function(inst, data) inst.activemarks = FoucsChange(inst, data, inst.activemarks) end)
end)
local ICON_REVERSE = {}
if SW_ICONS then
	for prefab, icon in pairs(SW_ICONS) do
		ICON_REVERSE[icon] = prefab
	end
end
if PORK_ICONS then
	for prefab, icon in pairs(PORK_ICONS) do
		ICON_REVERSE[icon] = prefab
	end
end
AddClassPostConstruct("widgets/ingredientui", function(self, atlas, image, quantity, on_hand, has_enough, name, owner)
	local oldOnGainFocus = self.OnGainFocus
	local oldOnLoseFocus = self.OnLoseFocus
	local oldKill = self.Kill
	local oldOnControl = self.OnControl
	local fouse_prefab = string.gsub(image or "", "%.tex$", "")
	if ICON_REVERSE[fouse_prefab] then
		fouse_prefab = ICON_REVERSE[fouse_prefab]
	end
	self.recipemarks = {}
	function self:OnGainFocus(...)
		oldOnGainFocus(self, ...)
		self.recipemarks = FoucsChange(owner, {item = {prefab = fouse_prefab}}, self.recipemarks)
	end
	function self:OnLoseFocus(...)
		oldOnLoseFocus(self, ...)
		ClearMarks(self.recipemarks)
		self.recipemarks = {}
	end
	function self:Kill(...)
		oldKill(self, ...)
		ClearMarks(self.recipemarks)
		self.recipemarks = {}
	end
	function self:OnControl(control, down, ...)
		if oldOnControl(self, control, down, ...) then return true end
		if control == CONTROL_SECONDARY and down then
			local need = quantity - on_hand
			if need <= 0 then
				local test = SpawnPrefab(fouse_prefab)
				need = test and test.components.stackable and test.components.stackable.maxsize or 1
				if test then test:Remove() end
			end
			while need > 0 do
				local ent = FindEntity(owner, 30, function(ent) return ent and ent.components.container and ent.components.container:Has(fouse_prefab, 1) end)
				if ent then
					for _, item in ipairs(ent.components.container:FindItems(function(item) return item.prefab == fouse_prefab end)) do
						if need > 0 then
							if item.components.stackable then
								local get = math.min(item.components.stackable.stacksize, need)
								need = need - get
								owner.components.inventory:GiveItem(item.components.stackable:Get(get), nil, Vector3(TheSim:GetScreenPos(ent.Transform:GetWorldPosition())))
							else
								need = need - 1
								owner.components.inventory:GiveItem(item, nil, Vector3(TheSim:GetScreenPos(ent.Transform:GetWorldPosition())))
							end
						else
							break
						end
					end
				else
					break
				end
			end
			return true
		end
		return false
	end
	self:SetTooltip((name or "").."\n"..STRINGS.RMB..": "..(has_enough and STRINGS.MOUSE_DRAG.CONTROLS.COLLECT_MORE or STRINGS.MOUSE_DRAG.CONTROLS.COLLECT))
end)