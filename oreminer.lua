-- OreMiner
--[[ this is also a comment
and so is this
]]--

--[[
function os.startTimer(val)
end
function os.pullEvent()
end
]]--

function _pullEvent()
	return io.read()
end

function _queueEvent(Event)
	print("TB QUEUE EVENT CALLED: ", Event)
end


if type(os.loadAPI) == 'nil' then

	print("loading bit")
	package.path = '..\\stateMgr\\?.lua;' .. package.path
	require("numberlua")
	bit = require 'numberlua'

	print("loading deferHdl")
	package.path = '..\\stateMgr\\?.lua;' .. package.path
	deferHandle = require 'deferHdl'
	os.pullEvent = _pullEvent
	os.queueEvent = _queueEvent

	Rsb = require 'sysRsb'
	ConfFile = require 'utilConfFile'

end

local RsbCtx = {}


--[[
local _TB_RSB_INPUT_VAL = 0
local _TB_RSB_OUTPUT_VAL = 0

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

if type(redstone) == 'nil' then
print("setting redstone api")
	redstone = {}
	redstone.getBundledInput = _rsbGetBundledInput
	redstone.getBundledOutput = _rsbGetOutputRaw
	redstone.setBundledOutput = _rsbSetOutputRaw
end
--]]


local __miner = "Miner"
local __derailer = "Derailer"
local __util = "UtilCart"
local __false = 0
local __true = 1
local sensorHasBridge = {__false,__true}
local Event = {Timer="timer",Redstone="redstone", Char="char", Rednet="rednet_message",
				Push="push", Key="key", Timer="timer", Alarm="alarm", Terminate="terminate",
				Disk="disk", Disk_eject="disk_eject", Peripheral="peripheral",
				Peripheral_detached="peripheral_detached", Check_Recovery="check_recovery"}

-- Set the cart up as a integer dictionary to make it easier to pass over Rednet
local sensorCartType = {__miner,__derailer, __util}
local sensorCargoFull = {__false,__true}
local sensorCargoEmpty = {__false, __true}
local sensorHasRails = {__false,__true}
local sensorHasTorches = {__false,__true}

local sensorCartPos = {0,0,0}

local Cart = {
	[sensorCartType]="cartType", [sensorCargoFull]="cargoFull", [sensorCargoEmpty]="cargoEmpty",
	[sensorHasRails]="hasRails", [sensorHasTorches]="hasTorches", [sensorHasBridge]="hasBridge",
	[sensorCartPos]="lastPos" }

local deferHandlers = {}

local colors = {side=nil,
				m={	white=1,orange=2,magenta=4,lightblue=8,
					yellow=16,lime=32,pink=64,gray=128,
					lightgray=256,cyan=512,purple=1024,blue=2048,
					brown=4096,green=8192,red=16384, black=32768}}

local rsbIn1 = {side=nil,
				m={	sys_on=0,sys_test=0,
					s_EntryExit=0,s_CartTypeMiner=0,s_CartTypeDerail=0,s_CartTypeUtil=0,
					s_cargoNotFull=0, s_CargoEmpty=0, s_NoRails=0, s_ScanDone=0 }}

local rsbOut1 = {side=nil,
				m={	TrkSw_Mine=0,TrkSw_CartUtil=0,TrkSw_CartDerail=0,
					Park_CartMiner=0,Park_CartDerail=0,Park_CartUtil=0,
					Ind_Alarm=0,Ind_SysOn=0,Ind_SysTest=0}}

local rsInputs = {}
local rsOutputs = {}
local rsInputNames = {	"sys_on","sys_test",
					"s_EntryExit","s_CartTypeMiner","s_CartTypeDerail","s_CartTypeUtil",
					"s_cargoNotFull", "s_CargoEmpty", "s_NoRails", "s_ScanDone" }

local rsOutputNames = {"TrkSw_Mine","TrkSw_CartUtil","TrkSw_CartDerail",
					"Park_CartMiner","Park_CartDerail","Park_CartUtil",
					"Ind_Alarm","Ind_SysOn","Ind_SysTest" }

function rsInit()
	for x,Name in pairs(rsInputNames) do
		rsInputs[Name] = 0
	end
	for x,Name in pairs(rsOutputNames) do
		rsOutputs[Name] = 0
	end
end

function rsSetup(params)
	for x,Name in pairs(rsInputNames) do
		rsInputs[Name] = params[Name]
	end
	for x,Name in pairs(rsOutputNames) do
		rsOutputs[Name] = params[Name]
	end
end

function rsParamsSetup(params)
	for x,Name in pairs(rsInputNames) do
		params[Name] = rsInputs[Name]
	end
	for x,Name in pairs(rsOutputNames) do
		params[Name] = rsOutputs[Name]
	end
end

function rsbGetInputRaw(side)
	return  Rsb.Ctx_getBundledInput(side)
end

function rsbGetOutputRaw(side)
--	local rsbCtx = rSB.Ctx_get()
	--for key, ctx in pairs(rsbCtx) do

	--return W
end

function rsbSetOutputRaw(side, val)
	return Rsb.set(val)
end

function rsbSetOutput(side, val)
	local curOutput = rsbGetOutputRaw(side)
	local newOutput = bit.bor(curOutput, val)
	rsbSetOutputRaw(side, newOutput)
end

function rsbClrOutput(side, val)
	local curOutput = rsbGetOutputRaw(side)
	local mask = bit.bnot(val)
	local newOutput = bit.band(curOutput, mask)
	rsbSetOutputRaw(side, newOutput)
end

function rsbGetOutput(side, val)
	local curOutput = rsbGetOutputRaw(side)
	local current = bit.band(curOutput, val)
	return current
end

function rsbToggleOutput(side, val)
	if rsbGetOutput(side, val) == 0 then
		rsbSetOutput(side, val)
	else
		rsbClrOutput(side, val)
	end
end

function sendRailRemover()
	rsbToggleOutput(rsbOut1.send_derailer)
end

function sendMiner()
	rsbToggleOutput(rsbOut1.send_miner)
end

function QueueNewEvent(Event, p1, p2, p3, p4)
	os.queueEvent(Event)
end

deferHandlers.UI =
			{name = "UI",
				handlerF = nil,
				events={Event.Char},
				masks={}
			}
deferHandlers.UI.handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)
		if EventT.p1 == "1" then
		    checkOutputs()
		elseif EventT.p1 == "2" then
		    checkInputs()
		elseif EventT.p1 == "3" then
		    readCart()
		elseif EventT.p1 == "4" then
			for k,v in pairs(Cart) do print(k," - ",v) end
		elseif EventT.p1 == "5" then
		    resetCart()
		elseif EventT.p1 == "t" then
			monCmd = "CARTSCAN:"..Cart.cartType..":"..Cart.cargoEmpty..":"..Cart.cargoFull..":"..Cart.hasRails..":"..Cart.hasTorches..":"..Cart.hasBridge.."::"
			rednet.broadcast(monCmd)
		else
			menuShow()
		end
end


-- checks inputs, puts system into idle
deferHandlers.Init =
			{name = "Init",
				events={Event.Push, Event.Char},
				masks={}
			}

deferHandlers.Init.handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)
	--rsbSetOutputRaw(rsbOut1.side, 0)

	rsbCtx = RsbCtx.State_get()

	for idx, Side in pairs(rsbCtx) do
		if Side:Output_get() ~= 0 then
			print("ERROR-Unable to clear outputs! System cannot start:",side,";",v)
			return
		end
		if Side:Input_get() ~= 0 then
			print("ERROR-Input active, please reset before system can start:",side,";",v)
			return
		end
	end


	print("Press any key to continue")
	print("I/O checks PASSED, starting system")
	Init()
	deferHandle.remove(dH, Handler)
	deferHandle.add(dH, deferHandlers.Idle)
	deferHandle.add(dH, deferHandlers.UI)
	QueueNewEvent(Event.Push)
end


-- waits for system_on=1
deferHandlers.Idle =
			{name = "Idle",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.sys_on}}
			}

deferHandlers.Idle.handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)

	-- sys_on received
	print("System turning ON")
	deferHandle.remove(dH, Handler)
	deferHandle.add(dH, deferHandlers.Recovery)

end

-- waits for system_on=0, places system into recovery mode
deferHandlers.Running =
			{name = "Running",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.sys_on}}
			}

-- system shutdown, waits for carts to return to parked states, how to detect this in steady state?
deferHandlers.Recovery =
			{name = "Recovery",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.sys_on}}
			}
deferHandlers.Recovery.handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)

	-- sys_on=0 received
	print("System turning off, recovery mode activated")
	-- make sure mine switch track is clear
	rsbClrOutput(rsbOut1.side, rsbOut1.m.sw_mine)

	-- remove all handlers
	for HdlKey, Hdlr in pairs(dH.queue) do
		deferHandle.remove(dH, Hdlr)
	end

	deferHandle.add(dH, deferHandlers.Recovery_Pend)
end

-- system shutdown, waits for carts to return to parked states, how to detect this in steady state?
deferHandlers.Recovery_Pend =
			{name = "Recovery_Pend",
				events={Event.Redstone, Event.Check_Recovery},
				masks={{en=true,param=rsbIn1.mine_park, rsbIn1.derailer_park}}
			}
deferHandlers.Recovery_Pend.handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)

	-- recovery pending
	local rsbInputs = rsbGetInputRaw(rsbIn1.side)
--	if rxbInputs == bits.band(

	deferHandle.add(dH, deferHandlers.Recovery_Pend)
end


-- cycles miner through fueling/resupply stations
deferHandlers.Start_loadMiner =
			{name = "Start_loadMiner",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.sys_on}}
			}

-- cycles derailer through fueling station
deferHandlers.Start_loadDerailer =
			{name = "Start_loadDerailer",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.sys_on}}
			}

-- checks departure state and sets outbound or turns cart back
deferHandlers.Send_Miner =
			{name = "Send_Miner",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=0}}
			}

-- resets outbound switch track
deferHandlers.Outbound =
			{name = "Outbound",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=0}}
			}

-- waits for mining cart to return
deferHandlers.Mining =
			{name = "Mining",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=0}}
			}

-- puts into Miner scan
deferHandlers.Arrival_Miner_Cart =
			{name = "Arrival_Cart",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.EntryExit}}
			}

-- check the cart scan, send the derailer or.... mine again
deferHandlers.Arrival_Miner_Scan =
			{name = "Arrival_Miner_Scan",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.s_ScanDone+
						rsbIn1.m.s_CargoEmpty+rsbIn1.m.s_cargoNotFull+rsbIn1.m.s_NoRails+
						rsbIn1.m.s_CartTypeMiner+rsbIn1.m.s_CartTypeDerail}}
			}

-- puts into Derailer scan
deferHandlers.Arrival_Miner_Cart =
			{name = "Arrival_Cart",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.arrival}}
			}

-- check the cart scan, send the miner
deferHandlers.Arrival_Derailer_Scan =
			{name = "Arrival_Miner_Scan",
				events={Event.Redstone},
				masks={{en=true,param=rsbIn1.side,mask=rsbIn1.m.s_ScanDone+
						rsbIn1.m.s_CargoEmpty+rsbIn1.m.s_cargoNotFull+rsbIn1.m.s_NoRails+
						rsbIn1.m.s_CartTypeMiner+rsbIn1.m.s_CartTypeDerail}}
			}

-- Unload the cargo Manager, 'push' event
deferHandlers.Unload =
			{name = "Unload",
				handlerF = nil,
				events={},
				masks={}
			}

-- Reload the fuel depot, 'push' event
deferHandlers.FuelResupply =
			{name = "FuelResupply",
				handlerF = nil,
				events={},
				masks={}
			}

-- Reload the torch depot, 'push' event
deferHandlers.TorchResupply =
			{name = "TorchResupply",
				handlerF = nil,
				events={},
				masks={}
			}

-- Reload the bridge depot, 'push' event
deferHandlers.BridgeResupply =
			{name = "BridgeResupply",
				handlerF = nil,
				events={},
				masks={}
			}




local rsbStat = {}
rsbStat["left"] = {lastStatus=0}
rsbStat["right"] = {lastStatus=0}
rsbStat["top"] = {lastStatus=0}
rsbStat["back"] = {lastStatus=0}
rsbStat["bottom"] = {lastStatus=0}
rsbStat["front"] = {lastStatus=0}

function colorTest(code, color)
	return ((code % (color*2)) > (color-1))
end

print("OreMiner") -- jusdt gives us some space to work with

function checkOutputs()
	print("Running Output loop test")
	for color,code in pairs(colors) do
		redstone.setBundledOutput(__rsbSideOut, 65535)
		sleep(1)
		redstone.setBundledOutput(__rsbSideOut, 0)
		sleep(1)
	end
	print("End output test")
end

function checkInputs()
	print("Running Input check")
	test = rsbGetInputRaw(__rsbSideIn)
	print("code=", test)
	for color,code in pairs(rsbInputs) do
		if colorTest(test, code) then
			print(color," is ON")
		end
	end
	print("End input test")
end

function resetCart()
	Cart.cartType = __derailer
	Cart.cargoFull = __false
	Cart.cargoEmpty = __false
	Cart.hasRails = __false
	Cart.hasTorches = __false
	Cart.hasBridge = __false
end

function Init()
	resetCart()
	menuShow()
	--myTimer = os.startTimer(1)
end

function menuShow()
	print("")
	print("1 - Run Output Test")
	print("2 - Check Inputs Test")
	print("3 - Scan Cart")
	print("4 - Print Cart")
	print("5 - Reset Cart")
end


function cartShow()
	print("          Cart Status")
	print("-----------------------------")
	print("        Cart Type => ", Cart.cartType)
	print("     Cargo Empty? => ", Cart.cargoEmpty)
	print("      Cargo Full? => ", Cart.cargoFull)
	print("Railer has rails? => ", Cart.hasRails)
	print("     Has Torches? => ", Cart.hasTorches)
	print("Bridge Materials? => ", Cart.hasBridge)
	print("-----------------------------")

end

--[[
function processCart()
	if(Cart.cartType == __miner) then
		-- change the park switch track --
		rsbSetOutput(rsbOutputs.sw_cartpark)

		-- set the downhill switch track --


	end

end

function setSysFault()
	rsbSetOutput(rsbOutputs.sys_fault)
	SYS_FAULT = true
end
]]


function rsbStatusInit(deferHandlers)
	-- init all the masks to hold the proper status table
	for name,Handler in pairs(deferHandlers) do
		for MaskIdx, mask in ipairs(Handler.masks) do
			mask.status = rsbStat[mask.param]
		end
	end
end

function rsbMaskHandleF(maskE)
	local newstatus = rsbGetInputRaw(maskE.param)
	local oldstatus = maskE.status.lastStatus
	local chgstatus = bit.bxor(newstatus,oldstatus)
	local maskcheck = bit.band(chgstatus, maskE.mask)
	maskE.status.lastStatus = newstatus
	return maskcheck ~= 0
end

function getDefaultParams(params)

	rsParamsSetup(params)

end

function main()

	print("OreMiner v0.1a")


	local dH = deferHandle.init()
	RsbCtx = Rsb.init()
	local params = {}
	rsInit()
	ConfFile.get("cfg.txt", params)
	if next(params) == nil then
		print("No config file found. Getting defaults\n")
		getDefaultParams(params)
		ConfFile.set("cfg.txt", params)
	end

	for k,v in pairs(params) do
		print(k,v)
	end

	deferHandle.setMaskHandler(dH, rsbMaskHandleF, Event.redstone)
	rsbStatusInit(deferHandlers)

	deferHandle.add(dH, deferHandlers.Init)

	while true do
		event, param1, param2, param3, param4 = os.pullEvent()
		deferHandle.handle(dH, deferHandle.newevent(event, param1, param2, param3, param4))
	end

end

main()

return 0

--[[
while true do

    event, param1, param2 = os.pullEvent()

	if event == "char" then
		if param1 == "1" then
		    checkOutputs()
		end
		if param1 == "2" then
		    checkInputs()
		end
		if param1 == "3" then
		    readCart()
		end
		if param1 == "4" then
			for k,v in pairs(Cart) do print(k," - ",v) end
		end
		if param1 == "5" then
		    resetCart()
		end
		if param1 == "t" then
			monCmd = "CARTSCAN:"..Cart.cartType..":"..Cart.cargoEmpty..":"..Cart.cargoFull..":"..Cart.hasRails..":"..Cart.hasTorches..":"..Cart.hasBridge.."::"
			print(monCmd)
			rednet.broadcast(monCmd)
		end
		if param1 == "e" then
		    break
		end
		menuShow()
	end
	if event == "redstone" then
		input = redstone.getBundledInput(__rsbSideIn)

		if colorTest(input, rsbInputs.arrival) then
			print("Cart Arrival!")
			resetCart()
		end
		if colorTest(input, rsbInputs.s1_carttype) then
			Cart.cartType = __miner
		end
		if colorTest(input, rsbInputs.s2_cargo1) then
			Cart.cargoEmpty = __true
		end
		if colorTest(input, rsbInputs.s3_cargo2) then
			Cart.cargoFull = __true
		end
		if colorTest(input, rsbInputs.s4_rails) then
			Cart.hasRails = __true
		end
		if colorTest(input, rsbInputs.s5_torches) then
			Cart.hasTorches = __true
		end
		if colorTest(input, rsbInputs.s6_bridge) then
			Cart.hasBridge = __true
		end
		if colorTest(input, rsbInputs.read_done) then
			print("Cart scan complete!\n")
			cartShow()
			rednet.broadcast(monCmd)
			processCart()
		end
		if colorTest(input, rsbInputs.departure) then
			if departState then
				rsbSetOutput(rsbOutputs.sw_mine)
			else
				-- we did not leave in a proper state, missing rails, bridge supplies, etc
				setSysFault()
			end
		end
		if colorTest(input, rsbInputs.depart_stateok) then
			departState = true
	--		Cart.hasBridge = __true
		end


	end

	if event == "timer" then
		os.startTimer(1)
		if colorTest(input, rsbInputs.sys_on) then
			rsbToggleOutput(rsbOutputs.sys_running)
		end
	end
end
]]
