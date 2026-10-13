local Widget = require "widgets/widget"
local Text   = require "widgets/text"

local SelectText = Class(Widget, function(self)
	Widget._ctor(self, "selecttext")
	
	self.text = self:AddChild(Text(DEFAULTFONT, 100, ""))
	self.text:SetVAlign(ANCHOR_BOTTOM)
	self.text:SetHAlign(ANCHOR_MIDDLE)
end)

function SelectText:SetText(string, pos)
	local x, y = TheSim:GetScreenPos(pos:Get())
	self.text:SetString(string)
	self.text:SetPosition(x, y + 50)
end

function SelectText:Start()
	self:Show()
end

function SelectText:Stop()
	self:Hide()
end

return SelectText