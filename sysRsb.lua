-- deferHdl
local M = {_TYPE='module', _NAME='sysRsb', _VERSION='0.1'}

function class()
    local cls = {}
    cls.__index = cls
    return setmetatable(cls, {__call = function (c, ...)
        local instance = setmetatable({}, cls)
        if cls.__init then
            cls.__init(instance, ...)
        end
        return instance
    end})
end

--
-- Redstone implification
--
local function _rsbGetBundledInput()
	print("_TBLIB ENTER: RSBIN=",_TB_RSB_INPUT_VAL," INPUT NEW VAL: ")
	_TB_RSB_INPUT_VAL = tonumber(io.read())
	return _TB_RSB_INPUT_VAL
end

local function _rsbGetOutputRaw(side)
	print("_TBLIB ENTER: RSBOUT=",_TB_RSB_OUTPUT_VAL, "INPUT NEW VAL: ")
	_TB_RSB_OUTPUT_VAL = tonumber(io.read())
	return _TB_RSB_OUTPUT_VAL
end

local function _rsbSetOutputRaw(side, val)
	print("_TBLIB OUT: RSBOUTPUT= ", val)
	_TB_RSB_OUTPUT_VAL = val
	return 0
end

local function _rsGetSides()
	return {"top"}
end

local function _rsGetInput(side)
	if(side == "top") then
		return true
	else
		return false
	end
end
--
--
--
local RsImpl = {}
--local RsBit = {}
local RsBit = class()
local RsSide = class()

function RsImpl.init()
	local Self = {
	}
	-- Detect what redstone impl to use
	--
	print("sysRsb initialization")
	print("Determining what redstone impl to use..")
	if type(redstone) == 'nil' then
		print("..Setting up redstone Tblib api")
		-- Mock the 'redstone' accessors we will use
		Self.getSides = _rsGetSides
		Self.getInput = _rsGetInput
		Self.getBundledInput = _rsbGetBundledInput
		Self.getBundledOutput = _rsbGetOutputRaw
		Self.setBundledOutput = _rsbSetOutputRaw
	else
		-- We can use the real deal
		print("..Setting up 'redstone' api")
		Self = redstone
	end
	return Self
end


function RsBit:__init(Idx)
	self._Idx = 0
	self._Val = 0

	local function _Init(Idx)
		self._Idx = Idx
		self._Val = 2^tonumber(Idx)
	end

	_Init(Idx)

end

function RsBit:set()
	local NewVal = bit.bor(self:Output_get(), _Val)
	self:set_OutputNow(NewVal)
end
function RsBit:clr()
	local CurVal = self:Output_get()
	local MaskVal = bit.bnot(self._Val)
	self:set_OutputNow(bit.band(CurVal, MaskVal))
end
function RsBit:IsSet()
	local Val = self:Input_get()
	if(bit.band(Val, _Val) ~= 0) then
		return true
	else
		return false
	end
end
function RsBit:IsSet_output()
	local Val = self:Ouput_get()
	if(bit.band(Val, _Val) ~= 0) then
		return true
	else
		return false
	end
end


function RsSide:__init(rsImpl, NameIndex, NameStr)
	self.InputVal = 0
	self.OutputVal = 0

	self._Name = ""
	self._Side = 0
	self._rsImpl = {}
	self._Bits = {}

	local function _init(rsImpl, NameIndex, NameStr)
	print("init:",rsImpl,":",NameIndex,":",NameStr)
		self._Name = NameStr
		self._rsImpl = rsImpl
		self._Side = 2^16 + (tonumber(NameIndex)-1)
		for i = 0,15 do
			self._Bits[i] = RsBit(i)
		end
		self:_Input_get()
		self:_set_Output(0)
		self:_Output_get()
		print("update=",update)
	end
	--
	-- Public API
	--

	_init(rsImpl, NameIndex, NameStr)
end

function RsSide:_toBits(val)
	return bit.band(val, 65535)
end
function RsSide:_fromBits(val)
	return bit.bor(val, self._Side)
end
function RsSide:_Input_get()
	return self:_fromBits(self._rsImpl.getBundledInput(self._Name))
end
function RsSide:_Input_update()
	self.InputVal = _Input_get()
	return self.InputVal
end
function RsSide:_Output_get()
	return self:_fromBits(self._rsImpl.getBundledOutput(self._Name))
end
function RsSide:_Output_update()
	self.OutputVal = self:_Output_get()
	return self.OutputVal
end
function RsSide:_set_Output(value)
	self.OutputVal = value
	return
end
function RsSide:_commit_Output()
	local setval = self:_toBits(self.OutputVal)
	self._rsImpl.setBundledOutput(self.Name, setval)
	self:_Output_update()
	return
end

function RsSide:Name_get()
	return self._Name
end
function RsSide:DidChange_update_Input()
	local NewVal = self:_Input_get()
	if(NewVal ~= self.InputVal) then
		self.InputVal = NewVal
		return true
	else
		return false
	end
end
function RsSide:DidChange_update()
	self:_Output_get()
	return self:DidChange_update_Input()
end
function RsSide:Input_get()
	return self:_toBits(self.InputVal)
end
function RsSide:Output_get()
	return self:_toBits(self.OutputVal)
end
function RsSide:set_OutputNow(NewVal)
	self:_set_Output(NewVal)
	self:_commit_Output()
end
function RsSide:Input_getNew()
	return self:_Input_update()
end
function RsSide:update()
	self:_Input_get()
	self:_commit_Output()
end



function M.init()
	local Self = {

	}

	local _rsState = {}
	local _rsImpl = RsImpl.init()

	-- Returns an rsState containing all side that Changed
	function Self.get_Changed()
		local Changed = {}
		for idx, Side in pairs(_rsState) do
			if(Side.DidChange_update_Input()) then
				Changed[idx] = Side
			end
		end
		return Changed
	end

	-- Retrieves and returns the state of all sides
	function Self.State_get()
		for idx, Side in pairs(_rsState) do
			Side:update()
		end
		return _rsState
	end

	function Self.set_State(State)
		for idx, Side in pairs(State) do
			Side.update()
		end
	end

	--
	-- Init
	--
	local function _init()
		--
		-- Idx=Index of side
		for Idx,NameSide in pairs(_rsImpl.getSides()) do
			local Active = _rsImpl.getInput(NameSide)
			if(Active == true) then
				print("side init",_rsImpl,Idx,NameSide)
				local side = RsSide(_rsImpl, Idx, NameSide)
			print("activatating:",Idx,":",side)
				_rsState[Idx] = side
			end
		end
	end

	_init()

	return Self

end


function blitTable(T)
	local k = {}
	local v = {}
	for k,v in pairs(T) do
		print(k,v)
		if(type(k) == "table") then
			blitTable(k)
		end
		if(type(v) == "table") then
			blitTable(v)
		end
	end
end
return M
