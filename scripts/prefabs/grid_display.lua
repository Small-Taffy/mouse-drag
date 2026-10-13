local assets =
{
	Asset("ANIM", "anim/grid_display.zip"),
}

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	
	inst.AnimState:SetBank("grid_display")
	inst.AnimState:SetBuild("grid_display")
	inst.AnimState:PlayAnimation("idle")
	
	inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)
	
	inst:AddTag("FX")
	inst:AddTag("NOBLOCK")
	inst:AddTag("NOCLICK")
	inst:AddTag("notarget")
	
	inst.persists = false
	
	return inst
end

return Prefab("fx/grid_display", fn, assets)