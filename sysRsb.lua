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
	return {1,"top"}
end


local rsImpl = {}
if type(redstone) == 'nil' then
	print("setting redstone Tblib api")
	rsImpl = {}
	rsImpl.getSides = _rsGetSides
	rsImpl.getBundledInput = _rsbGetBundledInput
	rsImpl.getBundledOutput = _rsbGetOutputRaw
	rsImpl.setBundledOutput = _rsbSetOutputRaw
else
	rsImpl = redstone
end


--local rsCtx = {}

function M.Ctx_init()
	local input = 0
	local outputInit = 0
	-- k=Index of side, v=string name of side
	for Idx,NameSide in pairs(rsImpl.getSides()) do
		local Active = rsImpl.getBundledInput(NameSide)
		if(Active == true) then
			side = 2^16 + (tonumber(k)-1)
			input = input + (side+rsImpl.getBundledInput(NameSide))
			rsImpl.setBundledOutput(NameSide, outputInit)
			local outputVal = rsImpl.getBundledOutput(NameSide)
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
				local Output = rsImpl.getBundledOutput(v.name)
				rsCtx[side].valOutput = Output
				Changed[side] = rsCtx[side]
			end
		end
	end
	return Changed
end

function M.Ctx_get()
	for side,v in pairs(rsCtx) do
		local Active = rsImpl.getInput(v.name)
		if(Active == true) then
			local Input  = (side+rsImpl.getBundledInput(v.name))
			local Output = rsImpl.getBundledOutput(v.name)
			rsCtx[side].valInput  = Input
			rsCtx[side].valOutput = Output
		end
	end
	return rsCtx
end

function M.set_Ctx(Ctx)
	for side,v in pairs(Ctx) do
		rsImpl.setBundledOutput(Ctx[side].NameSide, Ctx[side].valOutput)
	end
end


function M.set_Bits(val)
	local side = bit.band(val, 458752)
	local curVal = rsImpl.getBundledOutput(rsCtx[side])
	local newVal = bit.band(val, 65535)
	newVal = bit.band(curVal, newVal);
	rsImpl.setBundledOutput(rsCtx[side], newVal)
end

function M.clr_Bits(val)
	local side = bit.band(val, 458752)
	local curVal = rsImpl.getBundledOutput(rsCtx[side])
	local newVal = bit.band(val, 65535)
	local mask = bit.bnot(newVal)
	newVal = bit.band(curVal, mask)
	rs.Impl.setBundledOutput(rsCtx[side], newVal)
end

return M
