local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Spinner = require "widgets/spinner"

local ConfigSpinner = Class(Widget, function(self, label, options, default_value, on_changed_fn)
	Widget._ctor(self, "ConfigSpinner")
	
	self.spinner = self:AddChild(Spinner(options, 190, 50))
	self.spinner:SetTextColour(0, 0, 0, 1)
	self.spinner:SetPosition(35, 0, 0)
	self.spinner:SetScale(0.5)
	
	if default_value ~= nil then
		self.spinner:SetSelected(default_value)
	end
	
	if on_changed_fn ~= nil then
		self.spinner:SetOnChangedFn(on_changed_fn)
	end
	
	self.label = self.spinner:AddChild(Text(BUTTONFONT, 30, label or ""))
	self.label:SetPosition(-140, 0, 0)
	self.label:SetRegionSize(180, 50)
	self.label:SetVAlign(ANCHOR_MIDDLE)
	self.label:SetHAlign(ANCHOR_MIDDLE)
end)

function ConfigSpinner:SetSelected(data)
	self.spinner:SetSelected(data)
end

function ConfigSpinner:GetSelected()
	return self.spinner:GetSelected()
end

function ConfigSpinner:SetEnabled(enabled)
	self.spinner:SetEnabled(enabled)
end

return ConfigSpinner