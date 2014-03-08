-- deferHdl
local M = {_TYPE='module', _NAME='sysRsb', _VERSION='0.1'}

function _rsbGetBundledInput()
	print("_TBLIB ENTER: RSBIN=",_TB_RSB_INPUT_VAL," INPUT NEW VAL: ")
	_TB_RSB_INPUT_VAL = tonumber(io.read())
	return _TB_RSB_INPUT_VAL
end

function _rsbGetOutputRaw(side)
	print("_TBLIB ENTER: RSBOUT=",_TB_RSB_OUTPUT_VAL, "INPUT NEW VAL: ")
	_TB_RSB_OUTPUT_VAL = tonumber(io.read())
	return _TB_RSB_OUTPUT_VAL
end

function _rsbSetOutputRaw(side, val)
	print("_TBLIB OUT: RSBOUTPUT= ", val)
	_TB_RSB_OUTPUT_VAL = val
	return 0
end

function _rsGetSides()
	return {"top"}
end

function _rsGetInput(side)
	if(side == "top") then
		return true
	else
		return false
	end
end

local rsImpl = {}
if type(redstone) == 'nil' then
	print("setting redstone Tblib api")
	rsImpl = {}
	rsImpl.getSides = _rsGetSides
	rsImpl.getInput = _rsGetInput
	rsImpl.getBundledInput = _rsbGetBundledInput
	rsImpl.getBundledOutput = _rsbGetOutputRaw
	rsImpl.setBundledOutput = _rsbSetOutputRaw
else
	rsImpl = redstone
end


local rsCtx = {}

function M.Ctx_init()
	local input = 0
	local outputInit = 0
	-- k=Index of side, v=string name of side
	print(rsCtx)
	for Idx,NameSide in pairs(rsImpl.getSides()) do
		print("rsbinit:",Idx,NameSide)
		local Active = rsImpl.getInput(NameSide)
		print("active:",Active)
		if(Active == true) then
			side = 2^16 + (tonumber(Idx)-1)
			local input = (side+rsImpl.getBundledInput(NameSide))
			rsImpl.setBundledOutput(NameSide, outputInit)
			local outputVal = side+rsImpl.getBundledOutput(NameSide)
			rsCtx[side] = {Name=NameSide,ValInput=input, ValOutput=outputVal}
		end
	end
	return rsCtx
end

function M.Ctx_get_Changed()
	local Changed = {}
	for side,v in pairs(rsCtx) do
		local Active = rsImpl.getInput(v.name)
		if(Active == true) then
			local Input = (side+rsImpl.getBundledInput(v.name))
			-- only update if val is different
			if(Input ~= rsCtx[side].valInput) then
				rsCtx[side].valInput = Input
				local Output = side+rsImpl.getBundledOutput(v.name)
				rsCtx[side].valOutput = Output
				Changed[side] = rsCtx[side]
			end
		end
	end
	return Changed
end

function M.Ctx_get(rsCtx)
	print(rsCtx)

	for side,v in pairs(rsCtx) do
		local Active = rsImpl.getInput(v.name)
		if(Active == true) then
			local Input  = (side+rsImpl.getBundledInput(v.name))
			local Output = side+rsImpl.getBundledOutput(v.name)
			rsCtx[side].valInput  = Input
			rsCtx[side].valOutput = Output
		end
	end
	return rsCtx
end

function M.IsActive_check(Ctx, Mask)
	local MaskSide = bit.band(Mask, 458752)
	local MaskVal = bit.band(Mask, 65535)
	for side,val in pairs(Ctx) do
		if(bit.band(MaskSide, side)) then
			if(bit.band(MaskVal,val)) then
				return true
			end
		end
	end
	return false
end

function M.set_Ctx(Ctx)
	for side,val in pairs(Ctx) do
		local MaskVal = bit.band(Ctx[side].valOutput, 65535)
		rsImpl.setBundledOutput(Ctx[side].NameSide, MaskVal)
	end
end


function M.set_Bits(val)
	local side = bit.band(val, 458752)
	local curVal = rsImpl.getBundledOutput(rsCtx[side])
	local newVal = bit.band(val, 65535)
	newVal = bit.band(curVal, newVal);
	rsImpl.setBundledOutput(rsCtx[side].NameSide, newVal)
end

function M.clr_Bits(val)
	local side = bit.band(val, 458752)
	local curVal = rsImpl.getBundledOutput(rsCtx[side])
	local newVal = bit.band(val, 65535)
	local mask = bit.bnot(newVal)
	newVal = bit.band(curVal, mask)
	rs.Impl.setBundledOutput(rsCtx[side].NameSide, newVal)
end

return M
