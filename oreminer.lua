-- OreMiner
--[[ this is also a comment
and so is this
]]--

function colorTest(code, color)
	return ((code % (color*2)) > (color-1))
end
-- op = read() -- this code creates a variable called 'op', the read() function stalls the program to accept user input, which is stored in op
print("OreMiner") -- jusdt gives us some space to work with

colors = {white=1,orange=2,magenta=4,lightblue=8,yellow=16,lime=32,pink=64,gray=128,lightgray=256,cyan=512,purple=1024,blue=2048,brown=4096,green=8192,red=16384, black=32768}
__rsbSideIn = "left"
__rsbSideOut = "right"
-- test = redstone.getBundledInput("left")

function checkOutputs()
	print("Running Output loop test")
	for color,code in pairs(colors) do
		redstone.setBundledOutput(__rsbSideOut, 65535)
		sleep(2)
		redstone.setBundledOutput(__rsbSideOut, 0)
		sleep(2)
	end
	print("End output test")
end

function checkInputs()
	print("Running Input check")
	test = redstone.getBundledInput(__rsbSideIn)
	print("code=", test)
	for color,code in pairs(colors) do
		if colorTest(test, code) then
			print(color," is ON")
		end	
	end	
	print("End inpout test")
end

while true do
	print("")
	print("1 - Run Output Test")
	print("2 - Check Inputs Test")
    event, param1, param2 = os.pullEvent()
    
    print(event, pram1, param2)
	
	if param1 == "1" then
	    checkOutputs()
	end
	if param1 == "2" then
	    checkInputs()
	end
	if param1 == "e" then
	    break
	end
end

