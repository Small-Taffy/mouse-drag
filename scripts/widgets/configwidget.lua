local Widget = require "widgets/widget"
local Text   = require "widgets/text"
local Image = require "widgets/image"
local ConfigSpinner = require "widgets/configspinner"

local function RangeScale(inst, range)
	if not (inst and inst:IsValid()) then return end
	local scale = math.sqrt(range * 17 / 106)
	local sx, sy, sz = 1, 1, 1
	local parent = inst.entity:GetParent()
	if parent then
		sx, sy, sz = parent.Transform:GetScale()
	end
	inst.Transform:SetScale(scale / sx, scale / sy, scale / sz)
end
local function RemoveRangeRing(owner)
	if owner and owner.range_ring then
		if owner.range_ring:IsValid() then
			owner.range_ring:Remove()
		end
		owner.range_ring = nil
	end
end
local function SpawnRangeRing(owner, range)
	RemoveRangeRing(owner)
	owner.range_ring = owner:SpawnChild("range_ring")
	RangeScale(owner.range_ring, range)
	owner.range_ring:DoTaskInTime(0, function(inst) inst:SetAddColour(.25, .75, .25, 1) end)
end

local options_bool = {
	{ text = STRINGS.MOUSE_DRAG.OPTIONS.FALSE, data = false },
	{ text = STRINGS.MOUSE_DRAG.OPTIONS.TRUE, data = true },
}
local ConfigWidget = Class(Widget, function(self, owner, queuedoer)
	Widget._ctor(self, "ConfigWidget")
	
	self.owner = owner
	self.queuedoer = queuedoer
	self.shown = self.queuedoer.shown
	self.ui_pos = self.queuedoer.ui_pos
	self.offset = Vector3(0, 0, 0)
	
	self.root = self:AddChild(Widget("ROOT"))
	self.root:SetVAnchor(ANCHOR_TOP)
	self.root:SetHAnchor(ANCHOR_LEFT)
	self.root:SetPosition(self.ui_pos)
	self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
	
	self.bt = self.root:AddChild(Widget("ROOT"))
	self.bt:SetPosition(0, 0, 0)
	
	self.introduction = self.bt:AddChild(Text(BUTTONFONT, 16, ""))
	self.introduction:SetVAlign(ANCHOR_TOP)
	self.introduction:SetHAlign(ANCHOR_LEFT)
	self.introduction:SetRegionSize(290, 200)
	self.introduction:EnableWordWrap(true)
	self.introduction:SetPosition(239, -250, 0)
	
	self.rangebutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.RANGE,
		{
			{ text = "5", data = 5 },
			{ text = "10", data = 10 },
			{ text = "15", data = 15 },
			{ text = "20", data = 20 },
			{ text = "25", data = 25 },
			{ text = "30", data = 30 },
			{ text = "35", data = 35 },
			{ text = "40", data = 40 },
			{ text = "45", data = 45 },
			{ text = "50", data = 50 },
		},
		self.queuedoer.range,
		function(data)
			self.queuedoer.range = data
			RangeScale(self.owner.range_ring, data)
		end
	))
	self.rangebutton:SetPosition(150, -60, 0)
	self.rangebutton.OnGainFocus = function()
		SpawnRangeRing(self.owner, self.queuedoer.range)
		self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.RANGE)
	end
	self.rangebutton.OnLoseFocus = function()	
		RemoveRangeRing(self.owner)
		if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.RANGE then
			self.introduction:SetString("")
		end
	end
	
	self.spacingbutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.SPACING,
		{
			{ text = "0.0", data = 0.0 },
			{ text = "0.5", data = 0.5 },
			{ text = "1.0", data = 1.0 },
			{ text = "1.5", data = 1.5 },
			{ text = "2.0", data = 2.0 },
			{ text = "2.5", data = 2.5 },
			{ text = "3.0", data = 3.0 },
			{ text = "3.5", data = 3.5 },
			{ text = "4.0", data = 4.0 },
			{ text = "4.5", data = 4.5 },
			{ text = "5.0", data = 5.0 },
			{ text = "5.5", data = 5.5 },
			{ text = "6.0", data = 6.0 },
			{ text = "6.5", data = 6.5 },
			{ text = "7.0", data = 7.0 },
			{ text = "7.5", data = 7.5 },
			{ text = "8.0", data = 8.0 },
		},
		self.queuedoer.set_spacing,
		function(data) self.queuedoer.set_spacing = data end
	))
	self.spacingbutton.OnGainFocus = function() self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.SPACING) end
	self.spacingbutton.OnLoseFocus = function() if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.SPACING then self.introduction:SetString("") end end
	self.spacingbutton:SetPosition(300, -60, 0)
	
	self.remodebutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.REMODE,
		{
			{ text = STRINGS.MOUSE_DRAG.OPTIONS.ONCE, data = 0 },
			{ text = STRINGS.MOUSE_DRAG.OPTIONS.DEFEAULT, data = 1 },
			{ text = STRINGS.MOUSE_DRAG.OPTIONS.REPEAT, data = 2 },
		},
		self.queuedoer.remode,
		function(data) self.queuedoer.remode = data end
	))
	self.remodebutton.OnGainFocus = function() self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.REMODE) end
	self.remodebutton.OnLoseFocus = function() if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.REMODE then self.introduction:SetString("") end end
	self.remodebutton:SetPosition(150, -84, 0)
	
	self.modebutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.PTMODE,
		{
			{ text = STRINGS.MOUSE_DRAG.OPTIONS.SQUARE, data = false },
			{ text = STRINGS.MOUSE_DRAG.OPTIONS.HEXAGON, data = true },
		},
		self.queuedoer.hexagon,
		function(data) self.queuedoer.hexagon = data end
	))
	self.modebutton.OnGainFocus = function() self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.PTMODE) end
	self.modebutton.OnLoseFocus = function() if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.PTMODE then self.introduction:SetString("") end end
	self.modebutton:SetPosition(300, -84, 0)
	
	self.pickupbutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.PICKUP,
		options_bool,
		self.queuedoer.pickup,
		function(data) self.queuedoer.pickup = data end
	))
	self.pickupbutton.OnGainFocus = function() self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.PICKUP) end
	self.pickupbutton.OnLoseFocus = function() if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.PICKUP then self.introduction:SetString("") end end
	self.pickupbutton:SetPosition(150, -108, 0)
	
	self.linkedbutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.LINKED,
		options_bool,
		self.queuedoer.linked,
		function(data) self.queuedoer.linked = data end
	))
	self.linkedbutton.OnGainFocus = function() self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.LINKED) end
	self.linkedbutton.OnLoseFocus = function() if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.LINKED then self.introduction:SetString("") end end
	self.linkedbutton:SetPosition(300, -108, 0)
	
	self.forcebutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.FORCE,
		options_bool,
		self.queuedoer.force,
		function(data) self.queuedoer.force = data end
	))
	self.forcebutton.OnGainFocus = function() self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.FORCE) end
	self.forcebutton.OnLoseFocus = function() if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.FORCE then self.introduction:SetString("") end end
	self.forcebutton:SetPosition(150, -132, 0)
	
	self.remotebutton = self.bt:AddChild(ConfigSpinner(
		STRINGS.MOUSE_DRAG.BUTTONS.REMOTE,
		options_bool,
		self.queuedoer.remote,
		function(data) self.queuedoer.remote = data end
	))
	self.remotebutton.OnGainFocus = function() self.introduction:SetString(STRINGS.MOUSE_DRAG.INTRODUCTION.REMOTE) end
	self.remotebutton.OnLoseFocus = function() if self.introduction:GetString() == STRINGS.MOUSE_DRAG.INTRODUCTION.REMOTE then self.introduction:SetString("") end end
	self.remotebutton:SetPosition(300, -132, 0)
	
	if self.shown then
		self.bt:Show()
	else
		self.bt:Hide()
	end
	
	self.mods = self.root:AddChild(Image("images/mods.xml", "mods.tex"))
	self.mods:SetSize(30, 30)
	self.mods:SetPosition(70, -96, 0)
	self.mods.OnControl = function(_, control, down)
		if control == CONTROL_ACCEPT and down then
			self.shown = not self.shown
			self.queuedoer.shown = self.shown
			if self.shown then
				self.bt:Show()
			else
				self.bt:Hide()
			end
			TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
			return true
		end
		if control == CONTROL_SECONDARY then
			if down then
				self.offset = TheInput:GetScreenPosition() - self.root:GetPosition()
				self:StartUpdating()
				return true
			else
				self:StopUpdating()
				local pos = self.root:GetPosition()
				self.queuedoer.ui_pos = {x = pos.x, y = pos.y, z = pos.z}
				return true
			end
		end
		return false
	end
	self.mods:SetTooltip(" ".."\n"..STRINGS.RMB..": "..STRINGS.MOUSE_DRAG.CONTROLS.DRAG)
end)

function ConfigWidget:OnUpdate()
	self.root:SetPosition(TheInput:GetScreenPosition() - self.offset)
end

return ConfigWidget