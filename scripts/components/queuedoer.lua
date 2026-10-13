local BannedActions = {
	[ACTIONS.WALKTO]		= true,	-- 走向
	[ACTIONS.RUMMAGE]		= true,	-- 翻找
	[ACTIONS.LOOKAT]		= true,	-- 检查
	[ACTIONS.TALKTO]		= true,	-- 交谈
	[ACTIONS.FISHOCEAN]		= true,	-- 海钓
	[ACTIONS.FISH]			= true,	-- 钓鱼
	[ACTIONS.REEL]			= true,	-- 上钩收线
	[ACTIONS.FORCEATTACK]	= true,	-- 强制攻击
	[ACTIONS.ATTACK]		= true,	-- 攻击
	[ACTIONS.STORE]			= true,	-- 存放
	[ACTIONS.JUMPIN]		= true,	-- 跳入
	[ACTIONS.COMBINESTACK]	= true,	-- 合并堆放
	[ACTIONS.TRAVEL]		= true,	-- 旅行
	[ACTIONS.RIDE_MOUNT]	= true,	-- 骑乘
	[ACTIONS.DISMOUNT]		= true,	-- 下来
}
local WorkActions = {
	[ACTIONS.MINE]			= 0,	-- 开采
	[ACTIONS.HAMMER]		= 0,	-- 锤击
	[ACTIONS.DIG]			= 0,	-- 挖掘
	[ACTIONS.CHOP]			= 4,	-- 砍伐
}
local Repeat_Fn = {
	[ACTIONS.GIVE] = function(self, ent, item)
		return
		(ent.components.trader and ent.components.trader:CanAccept(item, self.inst))
		or (ent.components.shelfer and ent.components.shelfer:CanAccept(item, self.inst))
		or (ent.components.appeasable and ent.components.appeasable:CanAccept(item, self.inst))
		or (ent.components.payable and ent.components.payable:CanAccept(item, self.inst))
		or ent.components.usableitem 
	end,
	[ACTIONS.SHAVE] = function(_, ent) return ent.components.beard and ent.components.beard:ShouldTryToShave() end,
	[ACTIONS.ADDFUEL] = function(_, ent) return ent.components.fueled and ent.components.fueled:GetPercent() < .95 end,
	[ACTIONS.HARVEST] = function(_, ent) return not (ent.components.breeder and ent.components.breeder.volume <= 1) end,
	[ACTIONS.COOK] = function() return true end,
	[ACTIONS.UNWRAP] = function() return true end,
	[ACTIONS.FERTILIZE] = function() return true end,
}
local Linked_Fn = {
	[ACTIONS.ACTIVATE] = function(self, ent)
		if ent.prefab == "dirtpile" then
			local dirt = GetWorld().components.hunter and GetWorld().components.hunter.lastdirt
			if dirt then self:DoAction(dirt, ACTIONS.ACTIVATE) end
		elseif ent.prefab == "whale_bubbles" then
			local dirt = GetWorld().components.whalehunter and GetWorld().components.whalehunter.lastdirt
			if dirt then self:DoAction(dirt, ACTIONS.ACTIVATE) end
		end
	end,
	[ACTIONS.CHOP] = function(self, ent)
		if self.linked and ent:IsValid() and ent:HasTag("stump") then
			while ent:IsValid() do
				local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				if not ((self.inst.components.worker and self.inst.components.worker:CanDoAction(ACTIONS.DIG)) or (item and item.components.tool and item.components.tool:CanDoAction(ACTIONS.DIG))) then
					item = self:AutoEquipByAction(ACTIONS.DIG)
					if not item then return end
				end
				local failed = self:DoAction(ent, ACTIONS.DIG, item)
				if failed then break end
			end
		end
	end,
}

if ACTIONS.RANGEDSMOTHER then
	BannedActions[ACTIONS.RANGEDSMOTHER] = true		-- 范围扑灭
end
if ACTIONS.RANGEDLIGHT then
	BannedActions[ACTIONS.RANGEDLIGHT] = true		-- 范围点燃
end
if ACTIONS.LAUNCH_THROWABLE then
	BannedActions[ACTIONS.LAUNCH_THROWABLE] = true	-- 发射炮弹
end
if ACTIONS.CHARGE_UP then
	BannedActions[ACTIONS.CHARGE_UP] = true			-- 充能
end
if ACTIONS.USEDOOR then
	BannedActions[ACTIONS.USEDOOR] = true			-- 进入
end
if ACTIONS.HACK then
	WorkActions[ACTIONS.HACK] = 4					-- 劈砍
end
if ACTIONS.SHEAR then
	WorkActions[ACTIONS.SHEAR] = 5					-- 剪
end
if ACTIONS.ADDWETFUEL then
	Repeat_Fn[ACTIONS.ADDWETFUEL] = function(_, ent) return ent.components.fueled and ent.components.fueled:GetPercent() < .95 end
end
if ACTIONS.UPGRADE then
	Repeat_Fn[ACTIONS.UPGRADE] = function() return true end
end

local QueueDoer = Class(function(self, inst)
	self.inst   = inst
	self.rgb    = {.80, .05, .05}
	self.shown  = true
	self.ui_pos = {x = 0, y = 0, z = 0}
	self.range  = TUNING.CONFIG_DEFAULT.RANGE
	self.force  = TUNING.CONFIG_DEFAULT.FORCE
	self.remode = TUNING.CONFIG_DEFAULT.REMODE
	self.pickup = TUNING.CONFIG_DEFAULT.PICKUP
	self.linked = TUNING.CONFIG_DEFAULT.LINKED
	self.remote = TUNING.CONFIG_DEFAULT.REMOTE
	self.isbanned  = BannedActions
	self.worktimes = WorkActions
	self.repeat_fn = Repeat_Fn
	self.linked_fn = Linked_Fn
	self.hexagon   = false
	self.set_spacing   = 0
	self.marked_list   = {}
	self.pickup_list   = {}
	self.entity_list   = {}
	self.action_list   = {}
	self.placer_list   = {}
	self.position_list = {}
	self.grid_list     = {}
	self.queue_thread  = nil
	self.select_thread = nil
	self.selecttext    = nil
	self.selectline    = nil
	self.left_time     = 0
	self.left_prev     = false
	self.right_time    = 0
	self.right_prev    = false
	self.middle_prev   = false
	self.last_recname  = nil
	self.inst:ListenForEvent("makerecipe", function(inst, data)
		if data and data.recipe then
			self.last_recname = data.recipe.name
		end
	end)
end)
-- MODAPI
function QueueDoer:AddActionToList(list_name, action, value)
	local lists = {
		BannedActions = { list = self.isbanned, type = "boolean", default = true },
		WorkActions   = { list = self.worktimes, type = "number", default = 0 },
		Repeat_Fn     = { list = self.repeat_fn, type = "function", default = nil },
		Linked_Fn     = { list = self.linked_fn, type = "function", default = nil },
	}
	
	local entry = lists[list_name]
	if not entry then
		print("[QueueDoer:AddActionToList] unknown list: "..list_name)
		return false
	end
	
	if value ~= nil and type(value) ~= entry.type then
		print("[QueueDoer:AddActionToList] expected "..entry.type.." for "..list_name..", got "..type(value))
		return false
	end
	
	local list = entry.list
	if list[action] then return true end
	
	list[action] = value or entry.default
	return true
end

function QueueDoer:OnSave()
	return 
	{
		shown = self.shown,
		ui_pos = self.ui_pos,
		range = self.range,
		force = self.force,
		remode = self.remode,
		pickup = self.pickup,
		linked = self.linked,
		remote = self.remote,
		hexagon = self.hexagon,
		set_spacing = self.set_spacing,
	}
end

function QueueDoer:OnLoad(data)
	if data then
		if data.shown ~= nil then self.shown = data.shown end
		if data.ui_pos ~= nil then self.ui_pos = data.ui_pos end
		if data.range ~= nil then self.range = data.range end
		if data.force ~= nil then self.force = data.force end
		if data.remode ~= nil then self.remode = data.remode end
		if data.pickup ~= nil then self.pickup = data.pickup end
		if data.linked ~= nil then self.linked = data.linked end
		if data.remote ~= nil then self.remote = data.remote end
		if data.hexagon ~= nil then self.hexagon = data.hexagon end
		if data.set_spacing ~= nil then self.set_spacing = data.set_spacing end
	end
end
-- 退出队列
function QueueDoer:BreakCheck()
	local up    = TheInput:IsControlPressed(CONTROL_MOVE_UP)
	local down  = TheInput:IsControlPressed(CONTROL_MOVE_DOWN)
	local left  = TheInput:IsControlPressed(CONTROL_MOVE_LEFT)
	local right = TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)
	local ba    = self.inst.components.locomotor.bufferedaction
	return up or down or left or right or (ba and not ba.modpass)
end
-- 获取身上的相同物品
function QueueDoer:FindItem(useitem)
	if not useitem then return end
	local item = self.inst.components.inventory:FindItem(function(item)
		return item.prefab == useitem.prefab
	end)
	return item
end
-- 自动拿取
function QueueDoer:AutoActive(useitem, item)
	local active = self.inst.components.inventory:GetActiveItem()
	if active and active.prefab == useitem.prefab then return active end
	local old = item or self:FindItem(useitem)
	local new = old and self.inst.components.inventory:RemoveItem(old, true)
	if new then self.inst.components.inventory:GiveActiveItem(new) end
	return new
end
-- 自动装备
function QueueDoer:AutoEquip(useitem)
	for _, equip in pairs(self.inst.components.inventory.equipslots) do
		if equip and equip.prefab == useitem.prefab then
			return equip
		end
	end
	local item = self:FindItem(useitem)
	local success = self.inst.components.inventory:Equip(item)
	if item and not success then item = self:AutoActive(useitem, item) end
	return item
end
function QueueDoer:AutoEquipByAction(act)
	local item = self.inst.components.inventory:FindItem(function(item)
		return item.components.tool and item.components.tool:CanDoAction(act)
	end)
	local success = self.inst.components.inventory:Equip(item)
	if item and not success then item = self:AutoActive(item, item) end
	return item
end
-- 遍历建造护符
function QueueDoer:FindGreenAmulet()
	for _, equip in pairs(self.inst.components.inventory.equipslots) do
		if equip and equip.prefab == "greenamulet" then
			return equip
		end
	end
end
-- 清除所有可插入队列相关
function QueueDoer:RemoveAllAboutQueue()
	for ent, _ in pairs(self.entity_list) do
		if ent:IsValid() then ent:SetAddColour(0, 0, 0, 1) end
	end
	for _, ent in ipairs(self.placer_list) do
		if ent:IsValid() then ent:Remove() end
	end
	self.pickup_list   = {}
	self.entity_list   = {}
	self.action_list   = {}
	self.placer_list   = {}
	self.position_list = {}
end
-- 执行单个动作
function QueueDoer:DoAction(ent, act, inv, pos, recname, rot)
	if ent then
		local actions = {}
		for _, cmp in pairs(ent.components) do
			if cmp.CollectSceneActions then
				cmp:CollectSceneActions(self.inst, actions)
				cmp:CollectSceneActions(self.inst, actions, true)
			end
			if cmp.CollectInventoryActions then
				cmp:CollectInventoryActions(self.inst, actions)
				cmp:CollectInventoryActions(self.inst, actions, true)
			end
		end
		if inv then
			for _, cmp in pairs(inv.components) do
				if cmp.CollectUseActions then
					cmp:CollectUseActions(self.inst, ent, actions)
					cmp:CollectUseActions(self.inst, ent, actions, true)
				end
				if cmp.CollectEquippedActions then
					cmp:CollectEquippedActions(self.inst, ent, actions)
					cmp:CollectEquippedActions(self.inst, ent, actions, true)
				end
			end
		end
		local valid = false
		for _, action in ipairs(actions) do
			if action == act then
				valid = true
				break
			end
		end
		if not valid then 
			local worker = self.inst.components.worker
			local workable = ent.components.workable
			local hackable = ent.components.hackable
			valid = worker and worker:CanDoAction(act) and (workable and workable:IsActionValid(act, true) or hackable and hackable:IsActionValid(act, true))
		end
		if not valid then return true end
	end
	local succeed = false
	local failed  = false
	local ba = BufferedAction(self.inst, ent, act, inv, pos, recname, self.remote and math.huge or nil, rot)
	ba.modpass = true
	ba:AddSuccessAction(function() succeed = true end)
	ba:AddFailAction(function() failed = true end)
	if self.force then
		self.inst.components.playercontroller:DoAction(ba)
	end
	repeat
		if not (self.inst.sg:HasStateTag("busy") or self.inst.sg:HasStateTag("doing")) then
			self.inst.components.playercontroller:DoAction(ba)
		end
		if self:BreakCheck() then
			self:RemoveAllAboutQueue()
			failed = true
		end
		Sleep(0)
	until succeed or failed
	if succeed then
		local linked_fn = self.linked_fn[act]
		if linked_fn then linked_fn(self, ent) end
	end
	return failed
end
-- 自动拾取
function QueueDoer:AutoPickUp(pos)
	self.pickup_list = TheSim:FindEntities(pos.x, 0, pos.z, 3, nil, {"player", "flower", "flower_rainforest", "trap", "FX", "NOCLICK", "DECOR", "INLIMBO"})
	while #self.pickup_list > 0 do
		local ent = self.pickup_list[1]
		if ent:IsValid() and ent.components.inventoryitem and ent.components.inventoryitem.canbepickedup then
			self:DoAction(ent, ACTIONS.PICKUP)
		end
		table.remove(self.pickup_list, 1)
	end
end
-- 依据action_list表中实体与动作，按实体与玩家距离逐个做完
function QueueDoer:PushEntityQueue()
	if self.queue_thread then return end
	self.queue_thread = self.inst:StartThread(function()
		while #self.action_list > 0 do
			local minIdx = 1
			local minDSq  = self.action_list[1].target:IsValid() and self.action_list[1].target:GetDistanceSqToInst(self.inst) or math.huge
			for i = 2, #self.action_list do
				local DSq = self.action_list[i].target:IsValid() and self.action_list[i].target:GetDistanceSqToInst(self.inst) or math.huge
				if DSq < minDSq then
					minDSq = DSq
					minIdx = i
				end
			end
			local ba = self.action_list[minIdx]
			local ent = ba.target
			local act = ba.action
			local inv = ba.invobject
			if ent:IsValid() then
				local pos = ent:GetPosition()
				local repeat_fn = (self.remode >= 1 and self.repeat_fn[act]) or (self.remode == 2 and function() return true end) or nil
				if self.worktimes[act] then
					while ent:IsValid() do
						local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
						if not ((self.inst.components.worker and self.inst.components.worker:CanDoAction(act)) or (item and item.components.tool and item.components.tool:CanDoAction(act))) then
							item = self:AutoEquip(inv)
							if not item then
								item = self:AutoEquipByAction(act)
								if not item then break end
							end
						end
						local failed = self:DoAction(ent, act, item)
						if failed then break end
						Sleep(self.worktimes[act] * FRAMES)
					end
				elseif inv then
					if repeat_fn then
						while ent:IsValid() do
							if not (inv:IsValid() and inv.components.inventoryitem and inv.components.inventoryitem.owner == self.inst) then inv = self:AutoEquip(inv) end
							if not inv then break end
							if not repeat_fn(self, ent, inv) then break end
							local failed = self:DoAction(ent, act, inv)
							if failed then break end
						end
					else
						if not (inv:IsValid() and inv.components.inventoryitem and inv.components.inventoryitem.owner == self.inst) then inv = self:AutoEquip(inv) end
						if inv then self:DoAction(ent, act, inv) end
					end
				else
					if repeat_fn then
						while ent:IsValid() do
							if not repeat_fn(self, ent) then break end
							local failed = self:DoAction(ent, act)
							if failed then break end
						end
					else
						self:DoAction(ent, act)
					end
				end
				if self.pickup then self:AutoPickUp(pos) end
			end
			table.remove(self.action_list, minIdx)
			self.entity_list[ent] = nil
			if ent:IsValid() then ent:SetAddColour(0, 0, 0, 1) end
		end
		self:RemoveAllAboutQueue()
		self.queue_thread = nil
	end)
end
-- 依据动作，按position_list表里顺序，逐个做完
function QueueDoer:PushPointQueue(act, object, rot)
	if self.queue_thread then return end
	local hand = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	local IAI = hand and hand.prefab == "iai_pitchfork"
	local amulet = self:FindGreenAmulet()
	self.queue_thread = self.inst:StartThread(function()
		while #self.position_list > 0 do
			local pos = self.position_list[1]
			if act == ACTIONS.DEPLOY then
				local item = self.inst.components.inventory:GetActiveItem()
				if not item then item = self:AutoActive(object) end
				if not item then break end
				if item.components.deployable and item.components.deployable:CanDeploy(pos, true) then
					local newact = IAI and ACTIONS.IAI_DEPLOYTURF or ACTIONS.DEPLOY
					self:DoAction(nil, newact, item, pos, nil, rot)
				end
			elseif act == ACTIONS.BUILD then
				if amulet then
					local item = self:FindGreenAmulet()
					if not item then item = self:AutoEquip(amulet) end
					if not item then break end
				end
				if self.inst.components.builder:CanBuild(object.name) and self.inst.components.builder:CanBuildAtPoint(pos, object) then
					self:DoAction(nil, act, nil, pos, object.name, rot)
				end
			elseif act == ACTIONS.TERRAFORM then
				local item = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				if not item then item = self:AutoEquip(object) end
				if not item then break end
				if item.components.terraformer and item.components.terraformer:CanTerraformPoint(pos) then
					local newact = IAI and ACTIONS.IAI_TERRAFORMER or ACTIONS.TERRAFORM
					self:DoAction(nil, newact, item, pos)
					if self.pickup and not IAI then self:AutoPickUp(pos) end
				end
			else
				local item = self.inst.components.inventory:GetActiveItem()
				if not item then item = self:AutoActive(object) end
				if not item then break end
				self:DoAction(nil, act, item, pos)
			end
			table.remove(self.position_list, 1)
			local placer = table.remove(self.placer_list, 1)
			if placer and placer:IsValid() then placer:Remove() end
		end
		self:RemoveAllAboutQueue()
		self.queue_thread = nil
	end)
end
-- 烹饪队列
function QueueDoer:OnCook(target)
	if not target.components.container then return end
	local foods = {}
	local cookpots = {}
	for slot, food in pairs(target.components.container.slots) do
		foods[slot] = food
	end
	local x, _, z = target.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, self.range, nil, {"FX", "NOCLICK", "DECOR", "INLIMBO", "burnt"})
	for _, ent in ipairs(ents) do
		if ent.prefab == target.prefab then
			table.insert(cookpots, ent)
		end
	end
	local function NotCooking(ent) local cooker = ent.components.stewer or ent.components.melter return cooker and not cooker.cooking end
	self.queue_thread = self.inst:StartThread(function()
		while #cookpots > 0 do
			local minIdx = 1
			local minDSq  = cookpots[1]:IsValid() and NotCooking(cookpots[1]) and cookpots[1]:GetDistanceSqToInst(self.inst) or math.huge
			for i = 2, #cookpots do
				local DSq = cookpots[i]:IsValid() and NotCooking(cookpots[i]) and cookpots[i]:GetDistanceSqToInst(self.inst) or math.huge
				if DSq < minDSq then
					minDSq = DSq
					minIdx = i
				end
			end
			local cookpot = cookpots[minIdx]
			if not cookpot:IsValid() then break end
			local cooker = cookpot.components.stewer or cookpot.components.melter
			if cooker and not cooker.cooking then
				if cooker:IsDone() then
					local failed = self:DoAction(cookpot, ACTIONS.HARVEST, nil, nil, nil, nil, true)
					if failed then break end
				end
				local container = cookpot.components.container
				if container and container.canbeopened then
					for slot, food in pairs(foods) do
						if not cookpot:IsValid() then break end
						if food and not container.slots[slot] then
							local item = self:FindItem(food)
							if not item then break end
							local failed = self:DoAction(cookpot, ACTIONS.STORE, item)
							if failed then break end
						end
					end
					if not (cookpot:IsValid() and cooker:CanCook()) then break end
					cooker:StartCooking()
				else
					table.remove(cookpots, minIdx)
				end
			else
				if self:BreakCheck() then break end
				Sleep(15 * FRAMES)
			end
		end
		self:RemoveAllAboutQueue()
		self.queue_thread = nil
	end)
end
-- 晾晒队列
function QueueDoer:OnDry(target)
	if not target.components.container then return end
	local foods = {}
	local have = false
	local take = false
	for slot, food in pairs(target.components.container.slots) do
		if food then
			if food.components.dryable then have = true
			else take = true break
			end
		end
		foods[slot] = food
	end
	if not (have or take) then return end
	self.queue_thread = self.inst:StartThread(function()
		local meatracks = {}
		local x, _, z = target.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, 0, z, self.range, nil, {"FX", "NOCLICK", "DECOR", "INLIMBO", "burnt"})
		if take then
			for _, ent in ipairs(ents) do
				if ent.prefab == target.prefab and ent.components.container and not ent.components.container:IsEmpty() then
					table.insert(meatracks, ent)
				end
			end
			for _, meatrack in ipairs(meatracks) do
				if meatrack:IsValid() and meatrack.components.container then
					if not meatrack.components.container:IsOpen() then
						local failed = self:DoAction(meatrack, ACTIONS.RUMMAGE)
						if failed then break end
					end
					for _, food in pairs(meatrack.components.container.slots) do
						if not meatrack:IsValid() then break end
						if food and food:IsValid() and not food.components.dryable then
							self.inst.components.inventory:GiveItem(food, nil, Vector3(TheSim:GetScreenPos(meatrack.Transform:GetWorldPosition())))
						end
					end
				end
			end
		else
			for _, ent in ipairs(ents) do
				if ent.prefab == target.prefab and ent.components.container and not ent.components.container:IsFull() then
					table.insert(meatracks, ent)
				end
			end
			local isbreak = false
			for _, meatrack in ipairs(meatracks) do
				if meatrack:IsValid() and meatrack.components.container then
					for slot, food in pairs(foods) do
						if not meatrack:IsValid() then isbreak = true break end
						if food and not meatrack.components.container.slots[slot] then
							local item = self:FindItem(food)
							if not item then isbreak = true break end
							local failed = self:DoAction(meatrack, ACTIONS.STORE, item)
							if failed then isbreak = true break end
						end
					end
				end
				if isbreak then break end
			end
		end
		self:RemoveAllAboutQueue()
		self.queue_thread = nil
	end)
end
-- 钓鱼队列
function QueueDoer:OnFish(target)
	local rod = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
	if not (rod and rod.components.fishingrod) then return end
	local ponds = {}
	local x, _, z = target.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, self.range, nil, {"FX", "NOCLICK", "DECOR", "INLIMBO"})
	for _, ent in ipairs(ents) do
		if ent.prefab == target.prefab then
			if ent.components.fishable and ent.components.fishable:GetFishPercent() > 0 then
				table.insert(ponds, ent)
			end
		end
	end
	local function HaveFish(ent) return ent.components.fishable and ent.components.fishable:GetFishPercent() > 0 end
	self.queue_thread = self.inst:StartThread(function()
		local isbreak = false
		while #ponds > 0 do
			local pond
			if self.remode == 2 then
				local minIdx = 1
				local minDSq  = ponds[1]:IsValid() and HaveFish(ponds[1]) and ponds[1]:GetDistanceSqToInst(self.inst) or math.huge
				for i = 2, #ponds do
					local DSq = ponds[i]:IsValid() and HaveFish(ponds[i]) and ponds[i]:GetDistanceSqToInst(self.inst) or math.huge
					if DSq < minDSq then
						minDSq = DSq
						minIdx = i
					end
				end
				pond = ponds[minIdx]
			else
				local maxIdx = 1
				local maxNum = ponds[1]:IsValid() and ponds[1].components.fishable and ponds[1].components.fishable:GetFishPercent() or 0
				for i = 2, #ponds do
					local Num = ponds[i]:IsValid() and ponds[i].components.fishable and ponds[i].components.fishable:GetFishPercent() or 0
					if Num > maxNum then
						maxNum = Num
						maxIdx = i
					end
				end
				pond = ponds[maxIdx]
			end
			if not (pond:IsValid() and HaveFish(pond)) then break end
			if not rod:IsValid() then rod = self:AutoEquip(rod) end
			if not rod then break end
			local caught = false
			local function OnNibble(inst, data)
				if not rod:IsValid() then rod = self:AutoEquip(rod) end
				if not rod then isbreak = true return end
				local ba = BufferedAction(inst, pond, ACTIONS.REEL, rod, nil, nil, self.remote and math.huge or nil)
				ba.modpass = true
				inst:DoTaskInTime(3 * FRAMES, function(inst) inst.components.playercontroller:DoAction(ba) end)
			end
			local function OnStrain(inst, data)
				if not rod:IsValid() then rod = self:AutoEquip(rod) end
				if not rod then isbreak = true return end
				local ba = BufferedAction(inst, pond, ACTIONS.REEL, rod, nil, nil, self.remote and math.huge or nil)
				ba.modpass = true
				inst:DoTaskInTime(3 * FRAMES, function(inst) inst.components.playercontroller:DoAction(ba) end)
			end
			local function OnCollect(inst, data)
				if self.pickup and data.fish then
					local ba = BufferedAction(inst, data.fish, ACTIONS.PICKUP, nil, nil, nil, self.remote and math.huge or nil)
					ba.modpass = true
					inst.components.playercontroller:DoAction(ba)
					inst:DoTaskInTime(15 * FRAMES, function() caught = true end)
				else
					caught = true
				end
			end
			local function OnLose() isbreak = true end
			self.inst:ListenForEvent("fishingnibble", OnNibble)
			self.inst:ListenForEvent("fishingstrain", OnStrain)
			self.inst:ListenForEvent("fishingcollect", OnCollect)
			self.inst:ListenForEvent("fishingloserod", OnLose)
			local ba = BufferedAction(self.inst, pond, ACTIONS.FISH, rod, nil, nil, self.remote and math.huge or nil)
			ba.modpass = true
			self.inst.components.playercontroller:DoAction(ba)
			repeat
				if self:BreakCheck() then isbreak = true end
				Sleep(0)
			until caught or isbreak
			self.inst:RemoveEventCallback("fishingnibble", OnNibble)
			self.inst:RemoveEventCallback("fishingstrain", OnStrain)
			self.inst:RemoveEventCallback("fishingcollect", OnCollect)
			self.inst:RemoveEventCallback("fishingloserod", OnLose)
			if isbreak then break end
		end
		self:RemoveAllAboutQueue()
		self.queue_thread = nil
	end)
end
-- 阅读队列
function QueueDoer:OnRead(data)
	if data and data.action and (data.action.action == ACTIONS.READ or data.action.action == ACTIONS.EAT) and not self.queue_thread then
		local ent = data.action.invobject
		local act = data.action.action
		local owner = ent and ent:IsValid() and ent.components.inventoryitem and ent.components.inventoryitem:GetContainer()
		if not owner then return end
		local numslots = owner:GetNumSlots()
		self.queue_thread = self.inst:StartThread(function()
			while true do
				Sleep(FRAMES * 2)
				local slotnum = owner:GetItemSlot(ent)
				if not slotnum then break end
				for i = 1, numslots do
					local slot = (slotnum + i - 1) % numslots + 1
					local item = owner:GetItemInSlot(slot)
					if item and item.components.book and item.components.book.action == ACTIONS.READ then ent = item act = ACTIONS.READ break end
					if item and item.components.edible and self.inst.components.eater:CanEat(item) then ent = item act = ACTIONS.EAT break end
				end
				if not (ent and ent:IsValid() and ((ent.components.finiteuses and ent.components.finiteuses.current > 0) or (ent.time and ent.time > 0) or ent.components.edible)) then break end
				local failed = self:DoAction(ent, act)
				if failed then break end
			end
			self:RemoveAllAboutQueue()
			self.queue_thread = nil
		end)
	end
end
-- 对实体匹配动作
function QueueDoer:GetEntityAction(ent, right)
	local lmbs = self.inst.components.playeractionpicker:GetClickActions(ent, ent:GetPosition())
	local rmbs = self.inst.components.playeractionpicker:GetRightClickActions(ent, ent:GetPosition())
	local lmb  = lmbs and lmbs[1]
	local rmb  = rmbs and rmbs[1]
	local act
	if right then
		act = not (lmb and rmb and lmb.action == rmb.action) and rmb
	else
		act = lmb
	end
	if act and act.target and not (
		self.isbanned[act.action]
		or (act.action == ACTIONS.HARVEST and act.target.components.occupiable)
		or (act.action == ACTIONS.ACTIVATE and act.target.prefab ~= "dirtpile" and act.target.prefab ~= "whale_bubbles")
	) then
		return act
	end
end
-- 返回实体表的动作列表
function QueueDoer:MatchEntityQueue(ents, right)
	for _, ent in ipairs(ents) do
		if ent and ent:IsValid() and not self.entity_list[ent] then
			local act = self:GetEntityAction(ent, right)
			if act then
				self.entity_list[act.target] = true
				table.insert(self.action_list, act)
				ent:SetAddColour(self.rgb[1], self.rgb[2], self.rgb[3], 1)
			elseif self.marked_list[ent] then
				ent:SetAddColour(0, 0, 0, 1)
			end
		end
	end
	self.marked_list = {}
end
-- 对实体表更新高亮
function QueueDoer:UpdateMarkedEntity(ents, right)
	local marked_list = {}
	for _, ent in ipairs(ents) do
		if ent and ent:IsValid() and not self.entity_list[ent] then
			if self.marked_list[ent] then
				marked_list[ent] = true
				self.marked_list[ent] = nil
			elseif self:GetEntityAction(ent, right) then
				marked_list[ent] = true
				ent:SetAddColour(self.rgb[1], self.rgb[2], self.rgb[3], 1)
			end
		end
	end
	for ent, _ in pairs(self.marked_list) do
		if ent:IsValid() then ent:SetAddColour(0, 0, 0, 1) end
	end
	self.marked_list = marked_list
end
-- 获取矩形范围内实体
function QueueDoer:FindEntitiesInRectangle(firstpos, lastpos, must_tags, cant_tags)
	-- 相机方向向量
	local right = TheCamera:GetRightVec()
	local down  = TheCamera:GetDownVec()
	-- 中心点与偏移投影
	local center = Vector3((firstpos.x + lastpos.x) / 2, 0, (firstpos.z + lastpos.z) / 2)
	local offset = Vector3(firstpos.x, 0, firstpos.z) - center
	local halfW = math.abs(offset:Dot(right))
	local halfH = math.abs(offset:Dot(down))
	-- 判断是否在矩形内
	local function IsInRect(pos)
		local offsetProj = pos - center
		local projW = math.abs(offsetProj:Dot(right))
		local projH = math.abs(offsetProj:Dot(down))
		return projW <= halfW and projH <= halfH
	end
	-- 先圆形粗扫再筛选
	local raws = TheSim:FindEntities(center.x, 0, center.z, offset:Length(), must_tags, cant_tags)
	local ents = {}
	for _, raw in ipairs(raws) do
		local pos = raw:GetPosition()
		if IsInRect(pos) then
			table.insert(ents, raw)
		end
	end
	return ents
end
-- 点位参数预览
local SelectText = require "widgets/selecttext"
function QueueDoer:UpdateSelectText(string, pos)
	if self.selecttext then
		self.selecttext:SetText(string, pos)
	else
		if self.inst.HUD and self.inst.HUD.controls then
			self.selecttext = self.inst.HUD.controls:AddChild(SelectText(self.inst))
			self.selecttext.inst.OnRemoveEntity = function(_) self.selecttext = nil end
			self.selecttext:MoveToBack()
			self.selecttext:Start()
		end
	end
end
function QueueDoer:RemoveSelectText()
	if self.selecttext then
		self.selecttext:Stop()
		self.selecttext:Kill()
		self.selecttext = nil
	end
end
local function Snap10(pos) return Vector3(math.floor(pos.x + .5), 0, math.floor(pos.z + .5)) end
-- 获取矩形范围内坐标
function QueueDoer:FindPositionsInRectangle(firstpos, lastpos, step, maxnum, act, object)
	-- 相机方向向量
	local heading  = TheCamera:GetHeading()
	local rightVec = TheCamera:GetRightVec()
	local downVec  = TheCamera:GetDownVec()
	if heading % 2 == 0 then rightVec = Snap10(rightVec) downVec = Snap10(downVec) end
	-- 横纵向量投影
	local dxzVec = lastpos - firstpos
	local dxProj = dxzVec:Dot(rightVec)
	local dzProj = dxzVec:Dot(downVec)
	-- 横纵步数
	local nx     = math.ceil(math.abs(dxProj) / step)
	local nz     = math.ceil(math.abs(dzProj) / step)
	-- 横纵符号修正
	local dxNorm = math.floor((dxProj / math.abs(dxProj)) + .5)
	local dzNorm = math.floor((dzProj / math.abs(dzProj)) + .5)
	-- 横纵步长向量
	local dxVec  = rightVec * dxNorm * step
	local dzVec  = downVec  * dzNorm * step
	-- 蛇形生成
	local list = {}
	local cx, cz = 0, 0
	local valid = 0
	local isbreak = false
	for iz = 0, nz - 1 do
		cz = iz + 1
		local offsetZ = dzVec * iz
		local xStart, xStep
		if iz % 2 == 0 then
			xStart, xStep = 0, 1
		else
			xStart, xStep = nx - 1, -1
		end
		for ix = 0, nx - 1 do
			cx = math.max(cx, ix + 1)
			local xIdx = xStart + ix * xStep
			local offsetX = dxVec * xIdx
			local pos = firstpos + offsetX + offsetZ
			if (act == ACTIONS.DEPLOY and object and object.components.deployable and object.components.deployable:CanDeploy(pos, true))
				or (act == ACTIONS.BUILD and self.inst.components.builder:CanBuildAtPoint(pos, object))
				or (act == ACTIONS.TERRAFORM and object and object.components.terraformer and object.components.terraformer:CanTerraformPoint(pos))
				or act == ACTIONS.DROP then
				table.insert(list, pos)
				valid = valid + 1
			elseif step == 0 then
				isbreak = true break
			end
			if valid >= maxnum then isbreak = true break end
		end
		if isbreak then break end
	end
	local center = Vector3((firstpos.x + lastpos.x) / 2, 0, (firstpos.z + lastpos.z) / 2)
	self:UpdateSelectText((cx.."×"..cz.." S"..string.format("%.3g", step)), (center - downVec * math.abs(dzProj / 2)))
	return list
end
-- 获取圆形范围内坐标
local cos_sin = {
	{1, 0},
	{.5, .5 * math.sqrt(3) + 1e-2},
	{-.5, .5 * math.sqrt(3) + 1e-2},
	{-1, 0},
	{-.5, -.5 * math.sqrt(3) - 1e-2},
	{.5, -.5 * math.sqrt(3) - 1e-2},
}
function QueueDoer:FindPositionsInHexagon(firstpos, lastpos, step, maxnum, act, object)
	-- 相机方向向量
	local heading  = TheCamera:GetHeading()
	local rightVec = TheCamera:GetRightVec()
	local downVec  = TheCamera:GetDownVec()
	if heading % 2 == 0 then rightVec = Snap10(rightVec) downVec = Snap10(downVec) end
	-- 中心点到顶点的步长向量
	local pointVec = {}
	for i = 0, 5 do
		pointVec[i] = rightVec * cos_sin[i + 1][1] - downVec * cos_sin[i + 1][2]
	end
	-- 蜂巢形生成
	local list = {}
	table.insert(list, firstpos)
	local max_radius_sq = distsq(lastpos, firstpos)
	local max_radius = math.sqrt(max_radius_sq)
	local ring  = 1
	local valid = 1
	local count = 1
	local isbreak = false
	while true do
		-- 内切圆半径 > max_radius → 整层终止
		if step * ring * .866 > max_radius then break end
		-- 外接圆半径 > max_radius → 开始过滤
		local filtering = step * ring > max_radius
		-- 逐边采样（逆时针，每隔 step）
		for i = 0, 5 do
			local pos0 = firstpos + pointVec[i] * step * ring
			local edgeVec = pointVec[(i + 1) % 6] - pointVec[i]
			for j = 0, ring - 1 do
				local pos = pos0 + edgeVec * step * j
				if ((act == ACTIONS.DEPLOY and object and object.components.deployable and object.components.deployable:CanDeploy(pos, true))
					or (act == ACTIONS.BUILD and self.inst.components.builder:CanBuildAtPoint(pos, object))
					or act == ACTIONS.DROP) and (not filtering or distsq(pos, firstpos) < max_radius_sq) then
					table.insert(list, pos)
					valid = valid + 1
				elseif step == 0 then
					isbreak = true break
				end
				count = count + 1
				if valid >= maxnum then isbreak = true break end
			end
			if isbreak then break end
		end
		if isbreak then break end
		ring = ring + 1
	end
	self:UpdateSelectText(("R"..string.format("%.2f", max_radius).." S"..string.format("%.3g", step).." N"..count), firstpos)
	return list
end
-- 点位预览
function QueueDoer:UpdatePlacer(pos_list, placer_prefab, placer_ent)
	local rot = placer_ent and placer_ent:IsValid() and placer_ent.Transform:GetRotation() or 0
	local num = #self.position_list
	for i = 1, #pos_list do
		local pos = pos_list[i]
		local ent = self.placer_list[num + i]
		if not (ent and ent:IsValid()) then
			ent = SpawnPrefab(placer_prefab)
			ent:DoTaskInTime(0, function(inst) inst:SetAddColour(.25, .75, .25, 1) end)
		end
		ent.Transform:SetRotation(rot)
		ent.Transform:SetPosition(pos:Get())
		self.placer_list[num + i] = ent
	end
	for i = #pos_list + 1, (#self.placer_list - num) do
		local ent = self.placer_list[num + i]
		if ent and ent:IsValid() then ent:Remove() end
		self.placer_list[num + i] = nil
	end
	return rot
end
-- 框选线条
local SelectLine = require "widgets/selectline"
function QueueDoer:UpdateSelectLine(firstpos, lastpos)
	if self.selectline then
		self.selectline:SetWorldRect(firstpos, lastpos)
	else
		if self.inst.HUD and self.inst.HUD.controls then
			self.selectline = self.inst.HUD.controls:AddChild(SelectLine(self.inst))
			self.selectline.inst.OnRemoveEntity = function(_) self.selectline = nil end
			self.selectline:MoveToBack()
			self.selectline:Start()
		end
	end
end
function QueueDoer:RemoveSelectLine()
	if self.selectline then
		self.selectline:Stop()
		self.selectline:Kill()
		self.selectline = nil
	end
end
-- 鼠标动作
local function HasTags(ent, tags, must)
	if not tags then return must end
	for _, tag in ipairs(tags) do
		if ent:HasTag(tag) then return true end
	end
	return false
end
function QueueDoer:SelectTargetQueue(target)
	if not self.queue_thread then
		local cooker = target.components.stewer or target.components.melter
		if cooker and cooker:CanCook() then
			return self:OnCook(target)
		elseif target.components.dryingrack then
			return self:OnDry(target)
		elseif target.components.fishable then
			return self:OnFish(target)
		end
	end
	self:MatchEntityQueue({target})
	self:PushEntityQueue()
end
function QueueDoer:OnLeftClick(down)
	if TheInput:IsKeyDown(KEY_SHIFT) and down then
		local now = GetTime()
		local dt = now - self.left_time
		if dt > .5 and not TheInput:GetHUDEntityUnderMouse() and not self.select_thread then
			self.select_thread = self.inst:StartThread(function()
				local firstpos = TheInput:GetWorldPosition()
				local target   = TheInput:GetWorldEntityUnderMouse()
				local must_tags = nil
				local cant_tags = {"player", "flower", "flower_rainforest", "FX", "NOCLICK", "DECOR", "INLIMBO"}
				local lastpos, ents
				repeat
					Sleep(0)
					lastpos = TheInput:GetWorldPosition()
					self:UpdateSelectLine(firstpos, lastpos)
					ents = self:FindEntitiesInRectangle(firstpos, lastpos, must_tags, cant_tags)
					self:UpdateMarkedEntity(ents)
					local leftNow  = TheInput:IsControlPressed(CONTROL_PRIMARY)
					local shiftNow = TheInput:IsKeyDown(KEY_SHIFT)
				until not leftNow or not shiftNow
				self:RemoveSelectLine()
				if (lastpos - firstpos):Length() < 1 then
					if self.entity_list[target] then
						for i, act in ipairs(self.action_list) do
							if act.target == target then
								table.remove(self.action_list, i)
								break
							end
						end
						self.entity_list[target] = nil
						if target:IsValid() then target:SetAddColour(0, 0, 0, 1)  end
					elseif self.marked_list[target] then
						self.marked_list[target] = nil
						if target:IsValid() then target:SetAddColour(0, 0, 0, 1) end
					elseif target and target:IsValid() and HasTags(target, must_tags, true) and not HasTags(target, cant_tags, false) then
						self:SelectTargetQueue(target)
					end
				else
					self:MatchEntityQueue(ents)
					self:PushEntityQueue()
				end
				self.select_thread = nil
			end)
		else
			local target = TheInput:GetWorldEntityUnderMouse()
			if target and not TheInput:GetHUDEntityUnderMouse() then
				local x, _, z = target.Transform:GetWorldPosition()
				local raws = TheSim:FindEntities(x, 0, z, self.range, nil, {"player", "FX", "NOCLICK", "DECOR", "INLIMBO"})
				local ents = {}
				if not (target:HasTag("stump") or target:HasTag("burnt")) and target.components.growable then
					local stage = target.components.growable.stage
					for _, raw in ipairs(raws) do
						if raw.prefab == target.prefab and raw.components.growable and raw.components.growable.stage == stage then
							table.insert(ents, raw)
						end
					end
				else
					for _, raw in ipairs(raws) do
						if raw.prefab == target.prefab then
							table.insert(ents, raw)
						end
					end
				end
				self:MatchEntityQueue(ents)
				self:PushEntityQueue()
			end
		end
		self.left_time = now
	end
end
function QueueDoer:OnRightClick(down)
	if TheInput:IsKeyDown(KEY_SHIFT) and down then
		local now = GetTime()
		local dt = now - self.right_time
		if dt > .5 and not TheInput:GetHUDEntityUnderMouse() and not self.select_thread then
			self.select_thread = self.inst:StartThread(function()
				local firstpos  = TheInput:GetWorldPosition()
				local target    = TheInput:GetWorldEntityUnderMouse()
				local active    = self.inst.components.inventory:GetActiveItem()
				local hand      = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				local control   = self.inst.components.playercontroller
				local placer    = control.placer
				local recipe    = control.placer_recipe
				local deplacer  = control.deployplacer
				local terraform = hand and hand.components.terraformer--control.terraformer
				if active or placer or terraform then
					local act, object, min_spacing, placer_ent, placer_prefab
					local function ToTilt(num) return TheCamera:GetHeading() % 2 == 1 and num * math.sqrt(2) or num end
					if placer or deplacer then
						act = placer and ACTIONS.BUILD or ACTIONS.DEPLOY
						object = recipe or active
						placer_ent = placer or deplacer
						placer_prefab = placer and placer.prefab or deplacer.prefab
						local placer_self = placer and placer.components.placer or deplacer.components.placer
						if placer_self.snap_to_tile then
							min_spacing = ToTilt(4)
							firstpos = Vector3(GetWorld().Map:GetTileCenterPoint(firstpos:Get()))
						elseif placer_self.snap_to_flood then
							min_spacing = ToTilt(2)
							firstpos = Vector3(math.floor(firstpos.x / 2) * 2 + 1, 0, math.floor(firstpos.z / 2) * 2 + 1)
						elseif placer_self.snap_to_meters then
							min_spacing = ToTilt(1)
							firstpos = Vector3(math.floor(firstpos.x) + .5, 0, math.floor(firstpos.z) + .5)
						else
							min_spacing = placer and recipe.min_spacing or active.components.deployable.min_spacing
							firstpos = Vector3(math.floor(firstpos.x * 2 + .5) / 2, 0, math.floor(firstpos.z * 2 + .5) / 2)
						end
					elseif terraform then
						act = ACTIONS.TERRAFORM
						object = hand
						placer_prefab = "gridplacer"
						min_spacing = ToTilt(4)
						firstpos = Vector3(GetWorld().Map:GetTileCenterPoint(firstpos:Get()))
					else
						act = ACTIONS.DROP
						object = active
						placer_prefab = "reticule"
						min_spacing = 0
						firstpos = Vector3(math.floor(firstpos.x * 2 + .5) / 2, 0, math.floor(firstpos.z * 2 + .5) / 2)
					end
					local step = math.max(self.set_spacing, min_spacing)
					local pos_list, rot
					repeat
						Sleep(3 * FRAMES)
						local lastpos = TheInput:GetWorldPosition()
						self:UpdateSelectLine(firstpos, lastpos)
						local itemnum = (act == ACTIONS.DEPLOY or act == ACTIONS.DROP) and (self.inst.components.inventory:Count(active.prefab) - #self.position_list) or 400
						if self.hexagon then pos_list = self:FindPositionsInHexagon(firstpos, lastpos, step, itemnum, act, object)
						else pos_list = self:FindPositionsInRectangle(firstpos, lastpos, step, itemnum, act, object)
						end
						rot = self:UpdatePlacer(pos_list, placer_prefab, placer_ent)
						local rightNow = TheInput:IsControlPressed(CONTROL_SECONDARY)
						local shiftNow = TheInput:IsKeyDown(KEY_SHIFT)
					until not rightNow or not shiftNow
					self:RemoveSelectLine()
					self:RemoveSelectText()
					for _, pos in ipairs(pos_list) do
						table.insert(self.position_list, pos)
					end
					self:PushPointQueue(act, object, rot)
				else
					local must_tags = nil
					local cant_tags = {"player", "flower", "flower_rainforest", "FX", "NOCLICK", "DECOR", "INLIMBO"}
					local lastpos,  ents
					repeat
						Sleep(0)
						lastpos = TheInput:GetWorldPosition()
						self:UpdateSelectLine(firstpos, lastpos)
						ents = self:FindEntitiesInRectangle(firstpos, lastpos, must_tags, cant_tags)
						self:UpdateMarkedEntity(ents, true)
						local rightNow = TheInput:IsControlPressed(CONTROL_SECONDARY)
						local shiftNow = TheInput:IsKeyDown(KEY_SHIFT)
					until not rightNow or not shiftNow
					self:RemoveSelectLine()
					if (lastpos - firstpos):Length() < 1 then
						ents = {}
						if self.entity_list[target] then
							for i, act in ipairs(self.action_list) do
								if act.target == target then
									table.remove(self.action_list, i)
									break
								end
							end
							self.entity_list[target] = nil
							if target:IsValid() then target:SetAddColour(0, 0, 0, 1)  end
						elseif self.marked_list[target] then
							self.marked_list[target] = nil
							if target:IsValid() then target:SetAddColour(0, 0, 0, 1) end
						elseif target and target:IsValid() and HasTags(target, must_tags, true) and not HasTags(target, cant_tags, false) then
							ents = {target}
						end
					end
					self:MatchEntityQueue(ents, true)
					self:PushEntityQueue()
				end
				self.select_thread = nil
			end)
		else
			local target = TheInput:GetWorldEntityUnderMouse()
			if target and not TheInput:GetHUDEntityUnderMouse() then
				local x, _, z = target.Transform:GetWorldPosition()
				local raws = TheSim:FindEntities(x, 0, z, self.range, nil, {"player", "FX", "NOCLICK", "DECOR", "INLIMBO"})
				local ents = {}
				if not (target:HasTag("stump") or target:HasTag("burnt")) and target.components.growable then
					local stage = target.components.growable.stage
					for _, raw in ipairs(raws) do
						if raw.prefab == target.prefab and raw.components.growable and raw.components.growable.stage == stage then
							table.insert(ents, raw)
						end
					end
				else
					for _, raw in ipairs(raws) do
						if raw.prefab == target.prefab then
							table.insert(ents, raw)
						end
					end
				end
				self:MatchEntityQueue(ents, true)
				self:PushEntityQueue()
			end
		end
		self.right_time = now
	end
end
-- 监听以获取容器物品执行动作
function QueueDoer:OnListen()
	if TheInput:IsKeyDown(KEY_CTRL) and not self.select_thread then
		self.select_thread = self.inst:StartThread(function()
			local function OnRead(inst, data) self:OnRead(data) end
			self.inst:ListenForEvent("actionsuccess", OnRead)
			repeat
				Sleep(0)
				local altNow  = TheInput:IsKeyDown(KEY_ALT)
				local ctrlNow = TheInput:IsKeyDown(KEY_CTRL)
			until not altNow or not ctrlNow
			self.inst:RemoveEventCallback("actionsuccess", OnRead)
			self.select_thread = nil
		end)
	end
end
-- 快速队列
function QueueDoer:OnAction()
	local right = TheInput:IsKeyDown(KEY_CTRL)
	local x, _, z = self.inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, self.range, nil, {"player", "flower", "flower_rainforest", "trap", "FX", "NOCLICK", "DECOR", "INLIMBO"})
	self:MatchEntityQueue(ents, right)
	self:PushEntityQueue()
end
-- 制作及制作队列
function QueueDoer:OnRecipe()
	local recname = self.last_recname
	if not recname then self.inst.components.talker:Say(STRINGS.MOUSE_DRAG.RECIPES.NOT_RECNAME) return end
	local builder = self.inst.components.builder
	local recipe = GetRecipe(recname)
	if not (builder:KnowsRecipe(recname) or CanPrototypeRecipe(recipe.level, builder.accessible_tech_trees)) then self.inst.components.talker:Say(STRINGS.MOUSE_DRAG.RECIPES.NOT_KNOWSRECIPE) return end
	if not builder:CanBuild(recname) then self.inst.components.talker:Say(STRINGS.MOUSE_DRAG.RECIPES.NOT_CANBUILD) return end
	if recipe.placer then
		self.inst.components.playercontroller:StartBuildPlacementMode(recipe, function(pt) return builder:CanBuildAtPoint(pt, recipe) end)
	else
		if TheInput:IsKeyDown(KEY_SHIFT) and not self.queue_thread then
			local amulet = self:FindGreenAmulet()
			self.queue_thread = self.inst:StartThread(function()
				while true do
					if amulet then
						local item = self:FindGreenAmulet()
						if not item then item = self:AutoEquip(amulet) end
						if not item then break end
					end
					if not builder:CanBuild(recname) then break end
					local failed = self:DoAction(nil, ACTIONS.BUILD, nil, nil, recname)
					if failed then break end
				end
				self:RemoveAllAboutQueue()
				self.queue_thread = nil
			end)
		else
			local ba = BufferedAction(self.inst, nil, ACTIONS.BUILD, nil, nil, recname)
			ba.modpass = true
			self.inst.components.playercontroller:DoAction(ba)
		end
	end
end
-- 地皮网格
function QueueDoer:OnGrid()
	if #self.grid_list == 0 then
		local cx, _, cz = GetWorld().Map:GetTileCenterPoint(self.inst.Transform:GetWorldPosition())
		for dx = -10, 10 do
			for dz = -10, 10 do
				local x = cx + dx * 4
				local z = cz + dz * 4
				local grid = SpawnPrefab("grid_display")
				grid.Transform:SetPosition(x, 0, z)
				table.insert(self.grid_list, grid)
			end
		end
	else
		for _, ent in ipairs(self.grid_list) do
			if ent and ent:IsValid() then ent:Remove() end
		end
		self.grid_list = {}
	end
end

return QueueDoer