modimport("scripts/tuning_range.lua")
-- 将圈缩放至实际范围
local function RangeScale(inst, range)
	if not inst or range <= 0 then return end
	local scale = math.sqrt(range * 17 / 106)
	local sx, sy, sz = 1, 1, 1
	local parent = inst.entity:GetParent()
	if parent then
		sx, sy, sz = parent.Transform:GetScale()
	end
	inst.Transform:SetScale(scale / sx, scale / sy, scale / sz)
end
-- 聚焦物品栏物品的圈
local function RemoveRangeRing(item)
	local owner = GetPlayer()
	if owner and owner.range_ring and (not item or owner.range_ring_owner == item) then
		if owner.range_ring:IsValid() then
			owner.range_ring:Remove()
		end
		owner.range_ring = nil
		owner.range_ring_owner = nil
	end
end
local function SpawnRangeRing(item)
	RemoveRangeRing()
	if not (item and item:IsValid()) then return end
	local owner = GetPlayer()
	local range = TUNING.RANGE_ITEM[string.upper(item.prefab)]
	if not owner or not range then return end
	owner.range_ring = owner:SpawnChild("range_ring")
	owner.range_ring_owner = item
	RangeScale(owner.range_ring, range)
	owner.range_ring:DoTaskInTime(0, function(inst) inst:SetAddColour(.25, .75, .25, 1) end)
end
-- 劫持ItemTile焦点事件
AddClassPostConstruct("widgets/itemtile", function(self)
	local oldOnGainFocus = self.OnGainFocus
	function self:OnGainFocus(...)
		oldOnGainFocus(self, ...)
		SpawnRangeRing(self.item)
	end
	local oldOnLoseFocus = self.OnLoseFocus
	function self:OnLoseFocus(...)
		oldOnLoseFocus(self, ...)
		RemoveRangeRing(self.item)
	end
	local oldStartDrag = self.StartDrag
	function self:StartDrag(...)
		oldStartDrag(self, ...)
		RemoveRangeRing()
	end
	local oldKill = self.Kill
	function self:Kill(...)
		oldKill(self, ...)
		RemoveRangeRing()
	end
end)
-- 指向建筑的圈
local function OnRangeRing()
	local target = TheInput:GetWorldEntityUnderMouse()
	if not target then return end
	if target.range_ring then
		if target.range_ring:IsValid() then target.range_ring:Remove() end
		target.range_ring = nil
	else
		local range = TUNING.RANGE_BUILDINGS[string.upper(target.prefab)]
		if not range then return end
		target.range_ring = target:SpawnChild("range_ring")
		RangeScale(target.range_ring, range)
		target.range_ring:DoTaskInTime(0, function(inst) inst:SetAddColour(.25, .75, .25, 1) end)
	end
end
TheInput:AddControlHandler(CONTROL_PRIMARY, function(down)
	if TheInput:IsKeyDown(KEY_ALT) and down then
		OnRangeRing()
	end
end)
-- 建造模式的圈
local function LinkPlacerRangeRing(placer, recname)
	local range = TUNING.RANGE_BUILD_PLACERS[string.upper(recname)]
	if not placer or not range then return end
	local range_ring = placer:SpawnChild("range_ring")
	RangeScale(range_ring, range)
	placer.components.placer:LinkEntity(range_ring)
end
AddClassPostConstruct("components/playercontroller", function(self)
	local oldStartBuildPlacementMode = self.StartBuildPlacementMode
	function self:StartBuildPlacementMode(recipe, ...)
		oldStartBuildPlacementMode(self, recipe, ...)
		LinkPlacerRangeRing(self.placer, recipe.name)
	end
end)