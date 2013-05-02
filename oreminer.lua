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

if type(bit) == 'nil' then
	print("loading bit")
	package.path = '..\\stateMgr\\?.lua;' .. package.path
	bit = require 'bit.numberlua'
end

if type(deferHdl) == 'nil' then
	print("loading deferHdl")
	package.path = '..\\stateMgr\\?.lua;' .. package.path
	deferHandle = require 'deferHdl'
end	

local Event = {Timer="timer",Redstone="redstone", Char="char", Rednet="rednet_message", 
				Push="push", Key="key", Timer="timer", Alarm="alarm", Terminate="terminate",
				Disk="disk", Disk_eject="disk_eject", Peripheral="peripheral", 
				Peripheral_detached="peripheral_detached"}

local __IDLE = 10
local __RUNNING = 2
local __STARTUP = 3

local deferHandlers = {}

rsbIn = {read_done=1,sys_test=2,sys_on=4,s5_torches=8,
		 s3_cargo2=16,lime=32, s6_bridge=64,gray=128,
		 lightgray=256,depart_stateok=512,departure=1024,s2_cargo1=2048,
		 s4_rails=4096,arrival=8192,s1_carttype=16384, downhill=32768}

rsbOut = {rs_general=1,send_derailer=2,sys_test=4,unload=8,
		  sw_cartpark=16,lime=32,sys_fault=64,gray=128,
		  lightgray=256,rs_fuel=512,send_miner=1024,rs_rails=2048,
		  sensor_reset=4096,sys_running=8192,sw_mine=16384, sys_stop=32768}

deferHandlers.UI = 
			{name = "UI", 
				handlerF = nil,
				events={Event.Char},
				masks={}
			}

-- waits for system_on=1
deferHandlers.Idle = 
			{name = "Idle", 
				handlerF = nil,
				events={Event.Redstone},
				masks={{en=true,param="left",mask=rsbIn.sys_on}}
			}

-- waits for system_on=0, places system into recovery mode
deferHandlers.Running = 
			{name = "Running", 
				handlerF = nil,
				events={Event.Redstone},
				masks={{en=true,param="left",mask=rsbIn.sys_on}}
			}

-- system shutdown, waits for carts to return to parked states, how to detect this in steady state?
deferHandlers.Recovery = 
			{name = "Recovery", 
				handlerF = nil,
				events={Event.Redstone},
				masks={{en=true,param="left",mask=rsbIn.sys_on}}
			}

-- cycles miner through fueling/resupply stations
deferHandlers.Start_loadMiner = 
			{name = "Start_loadMiner", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.sys_on}}
			}

-- cycles derailer through fueling station
deferHandlers.Start_loadDerailer = 
			{name = "Start_loadDerailer", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.sys_on}}
			}
			
-- checks departure state and sets outbound or turns cart back
deferHandlers.Send_Miner = 
			{name = "Send_Miner", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.depart_stateok+rsbIn.departure}}
			}
			
-- resets outbound switch track
deferHandlers.Outbound = 
			{name = "Outbound", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.outbound}}
			}

-- waits for mining cart to return
deferHandlers.Mining = 
			{name = "Mining", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.outbound}}
			}

-- puts into Miner scan
deferHandlers.Arrival_Miner_Cart = 
			{name = "Arrival_Cart", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.arrival}}
			}
			
-- check the cart scan, send the derailer or.... mine again
deferHandlers.Arrival_Miner_Scan = 
			{name = "Arrival_Miner_Scan", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.read_done+rsbIn.s5_torches+
						rsbIn.s3_cargo2+rsbIn.s6_bridge+rsbIn.s2_cargo1+
						rsbIn.s4_rails+s1_carttype}}
			}
			
-- puts into Derailer scan
deferHandlers.Arrival_Miner_Cart = 
			{name = "Arrival_Cart", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.arrival}}
			}
			
-- check the cart scan, send the miner
deferHandlers.Arrival_Derailer_Scan = 
			{name = "Arrival_Miner_Scan", 
				handlerF = nil,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.read_done+rsbIn.s5_torches+
						rsbIn.s3_cargo2+rsbIn.s6_bridge+rsbIn.s2_cargo1+
						rsbIn.s4_rails+s1_carttype}}
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

			

deferHandlers.State1 = 
			{name = "State1", 
				handlerF = deferHdl.nilHandleF,
				events={__Redstone},
				masks={{en=true,param="left",mask=rsbIn.arrival}}
			}

deferHandlers[__IDLE].handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)
	print(Handler.name.." Handling event:"..EventT.name)
	deferHandle.remove(dH, Handler)
	deferHandle.add(dH, deferHandlers[__RUNNING])
end

deferHandlers[__RUNNING].handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)
	print(Handler.name.." Handling event:"..EventT.name..EventT.p1..EventT.p2)
	deferHandle.remove(dH, Handler)
	deferHandle.add(dH, deferHandlers[__STATE1])
end

deferHandlers[__STATE1].handlerF = function (dH, Handler, EventT)
	deferHandle.clearevent(EventT)
	print(Handler.name.." Handling event:"..EventT.name..EventT.p1..EventT.p2)
end



function colorTest(code, color)
	return ((code % (color*2)) > (color-1))
end
-- op = read() -- this code creates a variable called 'op', the read() function stalls the program to accept user input, which is stored in op
print("OreMiner") -- jusdt gives us some space to work with

__rsbSideIn = "left"
__rsbSideOut = "right"
__miner = "Miner"
__derailer = "Derailer"
__false = 0
__true = 1

-- sys_state = {idle="Idle", startup="Startup", mining="Mining", unloading="Unloading", derailing="Derailing", test="Test", fault="FAULT")
colors = {white=1,orange=2,magenta=4,lightblue=8,yellow=16,lime=32,pink=64,gray=128,lightgray=256,cyan=512,purple=1024,blue=2048,brown=4096,green=8192,red=16384, black=32768}
rsbIn = {read_done=1,sys_test=2,sys_on=4,s5_torches=8,s3_cargo2=16,lime=32,s6_bridge=64,gray=128,lightgray=256,depart_stateok=512,departure=1024,s2_cargo1=2048,s4_rails=4096,arrival=8192,s1_carttype=16384, downhill=32768}
rsbOut = {rs_general=1,send_derailer=2,sys_test=4,unload=8,sw_cartpark=16,lime=32,sys_fault=64,gray=128,lightgray=256,rs_fuel=512,send_miner=1024,rs_rails=2048,sensor_reset=4096,sys_running=8192,sw_mine=16384, sys_stop=32768}

--[[
local sysStates = {
	{"Idle", rsbIn.sys_test+rsbIn.sys_on, 65535-rsbOut.send_miner-rsbOut.send_derailer},
	{"Startup", rsbIn.read_done+rsbIn.sys_test+rsbInp.sys_on+rsbIn.s5_torches+rsbInp.s3_cargo2+rsbIn.s6_bridge+rsbIn.depart_stateok+rsbIn.departure+rsbIn.s2_cargo1+rsbIn.s4_rails+rsbIn.arrival+rsbIn.s1_carttype, 65535},
	{"Mining", rsbIn.downhill+rsbInp.sys_on, 65535},
	{23,6,"        "},
	{23,7,"        "},
	{23,8,"        "}}
]]

sensorCartType = {__miner,__derailer}
sensorCargoFull = {__false,__true}
sensorCargoEmpty = {__false, __true}
sensorHasRails = {__false,__true}
sensorHasTorches = {__false,__true}
sensorHasBridge = {__false,__true}

Cart = { [sensorCartType]="cartType", [sensorCargoFull]="cargoFull", [sensorCargoEmpty]="cargoEmpty", [sensorHasRails]="hasRails", [sensorHasTorches]="hasTorches", [sensorHasBridge]="hasBridge" }

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
	test = redstone.getBundledInput(__rsbSideIn)
	print("code=", test)
	for color,code in pairs(rsbInputs) do
		if colorTest(test, code) then
			print(color," is ON")
		end	
	end	
	print("End inpout test")
end

function readCart()
	Cart.cartType = __miner
	Cart.cargoFull = __true
	Cart.cargoEmpty = __true
	Cart.hasRails = __true
	Cart.hasTorches = __true
	Cart.hasBridge = __true
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
	myTimer = os.startTimer(1)
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

function rsbSetOutput(val)
	local curOutput = redstone.getBundledOutput(__rsbSideOut)
	local newOutput = bit.bor(curOutput, val)
	redstone.setBundledOutput(__rsbSideOut, newOutput)
end

function rsbClrOutput(val)
	local curOutput = redstone.getBundledOutput(__rsbSideOut)
	local mask = bit.bnot(val)
	local newOutput = bit.band(curOutput, mask)
	redstone.setBundledOutput(__rsbSideOut, newOutput)
end

function rsbGetOutput(val)
	local curOutput = redstone.getBundledOutput(__rsbSideOut)
	local current = bit.band(curOutput, val)
	return current
end

function rsbToggleOutput(val)
	if rsbGetOutput(val) == 0 then
		rsbSetOutput(val)
	else
		rsbClrOutput(val)
	end
end

function sendRailRemover()
	rsbToggleOutput(rsbOutputs.send_derailer)
end

function sendMiner()
	rsbToggleOutput(rsbOutputs.send_miner)
end

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

function main()
	Init()

	print("OreMiner v0.1a")
	
	local dH = deferHandle.init()
	
	deferHandle.setMaskHandler(dH, Test_MaskHandleF, __Redstone)
	
	deferHandle.add(dH, deferHandlers[__IDLE])
	deferHandle.add(dH, deferHandlers[__RUNNING])
	
	deferHandle.handle(dH, deferHandle.newevent(__Timer))
	deferHandle.handle(dH, deferHandle.newevent(__Redstone,1,2))
	deferHandle.handle(dH, deferHandle.newevent(__Timer))
	deferHandle.handle(dH, deferHandle.newevent(__Redstone,1,2))
	deferHandle.handle(dH, deferHandle.newevent(__Char))
	deferHandle.handle(dH, deferHandle.newevent(__Rednet,1,2))

	deferHandle.handle(dH, deferHandle.newevent(__Timer))
	deferHandle.handle(dH, deferHandle.newevent(__Timer))
end

main()



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