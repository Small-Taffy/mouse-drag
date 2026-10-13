local Widget = require "widgets/widget"
local Image  = require "widgets/image"

local SelectLine = Class(Widget, function(self)
	Widget._ctor(self, "selectline")
	
	self.segs = {}
	for i = 1, 4 do
		local line = self:AddChild(Image("images/global.xml", "square.tex"))
		line:SetVAnchor(ANCHOR_MIDDLE)
		line:SetHAnchor(ANCHOR_MIDDLE)
		line:SetSize(1, 2)
		line:SetTint(1, 1, 1, 1)
		self.segs[i] = line
	end
	self.pts = {}
end)

function SelectLine:SetWorldRect(firstpos, lastpos)
	local right = TheCamera:GetRightVec()
	local down  = TheCamera:GetDownVec()
	
	local center = Vector3((firstpos.x + lastpos.x) / 2, 0, (firstpos.z + lastpos.z) / 2)
	local offset = firstpos - center
	local halfW = math.abs(offset:Dot(right))
	local halfH = math.abs(offset:Dot(down))
	
	local wPts = {
		center - right * halfW - down * halfH,
		center + right * halfW - down * halfH,
		center + right * halfW + down * halfH,
		center - right * halfW + down * halfH,
	}
	local sPts = {}
	for i = 1, 4 do
		local sx, sy = TheSim:GetScreenPos(wPts[i].x, wPts[i].y, wPts[i].z)
		if not (sx and sy) then return end
		sPts[i] = Vector3(sx, sy, 0)
	end
	self.pts = sPts
end

function SelectLine:OnUpdate()
	if #self.pts ~= 4 then return end
	
	local scrW, scrH = TheSim:GetScreenSize()
	for i = 1, 4 do
		local a = self.pts[i]
		local b = self.pts[i % 4 + 1]
		local dx, dy = b.x - a.x, b.y - a.y
		local len  = math.sqrt(dx * dx + dy * dy)
		local midX = (a.x + b.x - scrW) / 2
		local midY = (a.y + b.y - scrH) / 2
		local rot  = math.atan2(dy, dx) * RADIANS
		self.segs[i]:SetPosition(midX, midY, 0)
		self.segs[i]:SetRotation(-rot)
		self.segs[i]:SetSize(len, 2)
	end
end

function SelectLine:Start()
	self:Show()
	self:StartUpdating()
end

function SelectLine:Stop()
	self:StopUpdating()
	self:Hide()
end

return SelectLine