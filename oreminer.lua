-- OreMiner
--[[ this is also a comment
and so is this
]]--


op = read() -- this code creates a variable called 'op', the read() function stalls the program to accept user input, which is stored in op
print("OreMiner") -- just gives us some space to work with

num1 = 1;
colors = {white=1,orange=2,magenta=4,lightblue=8,yellow=16,lime=32,pink=64,gray=128,lightgray=256,cyan=512,purple=1024,blue=2048,brown=4096,green=8192,red=16384, black=32768}

while num1 ~= 0 do
	for color,code in pairs(colors) do
		print(color, (colors.test (redstone.getBundledInput("left"), code)))
	end	
   num1 = tonumber(read())
   print("Press a key, 0 to exit")
end
