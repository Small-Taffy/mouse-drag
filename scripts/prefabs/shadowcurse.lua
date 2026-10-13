local assets =
{
	Asset("ANIM", "anim/shadowcurse.zip"),
}

local function shadowcurse_fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	
	inst.Transform:SetScale(.75, .75, .75)
	
	inst.AnimState:SetBank("shadowcurse")
	inst.AnimState:SetBuild("shadowcurse")
	inst.AnimState:SetFinalOffset(7)
	inst.AnimState:SetLightOverride(1)
	
	inst:AddTag("FX")
	inst:AddTag("NOBLOCK")
	inst:AddTag("NOCLICK")
	inst:AddTag("notarget")
	
	inst.persists = false
	
	return inst
end

local function PlayAnimation(inst, i)
	i = i + 3
	if i > 6 then i = i % 6 end
	if inst and inst.AnimState then
		inst.AnimState:PlayAnimation("idle"..i)
		inst:DoTaskInTime(1, PlayAnimation, i)
	end
end

local function fn()
	local inst = shadowcurse_fn()
	PlayAnimation(inst, 3)
	local inst2 = shadowcurse_fn()
	inst:AddChild(inst2)
	inst2:DoTaskInTime(.33, PlayAnimation, 2)
	local inst3 = shadowcurse_fn()
	inst:AddChild(inst3)
	inst3:DoTaskInTime(.66, PlayAnimation, 1)
	return inst
end

return Prefab("fx/shadowcurse", fn, assets)