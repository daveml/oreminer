-- OreMiner
--[[ this is also a comment
and so is this
]]--

function colorTest(code, color)
	return ((code % (color*2)) > (color-1))
end
-- op = read() -- this code creates a variable called 'op', the read() function stalls the program to accept user input, which is stored in op
print("OreMiner") -- jusdt gives us some space to work with

__rsbSideIn = "left"
__rsbSideOut = "right"
__miner = "Miner"
__derailer = "Derailer"

colors = {white=1,orange=2,magenta=4,lightblue=8,yellow=16,lime=32,pink=64,gray=128,lightgray=256,cyan=512,purple=1024,blue=2048,brown=4096,green=8192,red=16384, black=32768}
rsbInputs = {read_done=1,sys_test=2,sys_on=4,s5_torches=8,s3_cargo2=16,lime=32,s6_bridge=64,gray=128,lightgray=256,cyan=512,departure=1024,s2_cargo1=2048,s4_rails=4096,arrival=8192,s1_carttype=16384, black=32768}
rsbOutputs = {rs_general=1,send_derailer=2,sys_test=4,unload=8,sw_cartpark=16,lime=32,sys_fault=64,gray=128,lightgray=256,rs_fuel=512,send_miner=1024,rs_rails=2048,sensor_reset=4096,sys_running=8192,sw_mine=16384, sys_stop=32768}

sensorCartType = {__miner,__derailer}
sensorCargoFull = {false,true}
sensorCargoEmpty = {false, true}
sensorHasRails = {false,true}
sensorHasTorches = {false,true}
sensorHasBridge = {false,true}

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
	Cart.cargoFull = true
	Cart.cargoEmpty = true
	Cart.hasRails = true
	Cart.hasTorches = true
	Cart.hasBridge = true
end

function resetCart()
	Cart.cartType = __derailer
	Cart.cargoFull = false
	Cart.cargoEmpty = false
	Cart.hasRails = false
	Cart.hasTorches = false
	Cart.hasBridge = false
end

function Init()	
	resetCart()
	menuShow()
end

function menuShow()
	print("")
	print("1 - Run Output Test")
	print("2 - Check Inputs Test")
	print("3 - Scan Cart")
	print("4 - Print Cart")
	print("5 - Reset Cart")
end


Init()
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
			Cart.cartEmpty = true
		end
		if colorTest(input, rsbInputs.s3_cargo2) then
			Cart.cartFull = true
		end
		if colorTest(input, rsbInputs.s4_rails) then
			Cart.hasRails = true
		end
		if colorTest(input, rsbInputs.s5_torches) then
			Cart.hasTorches = true
		end
		if colorTest(input, rsbInputs.s6_bridge) then
			Cart.hasBridge = true
		end
		if colorTest(input, rsbInputs.read_done) then
			print("Cart scan complete!\n")
			for k,v in pairs(Cart) do print(k," - ",v) end
		end
	end	
end

