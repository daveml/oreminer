-- OreMiner
--[[ this is also a comment
and so is this
]]--

function colorTest(code, color)
	return ((code % (color*2)) > (color-1))
end
-- op = read() -- this code creates a variable called 'op', the read() function stalls the program to accept user input, which is stored in op
print("OreMiner") -- jusdt gives us some space to work with

for k,v in pairs(redstone.getSides()) do
 print(k,v)
end

num1 = 1;
colors = {white=1,orange=2,magenta=4,lightblue=8,yellow=16,lime=32,pink=64,gray=128,lightgray=256,cyan=512,purple=1024,blue=2048,brown=4096,green=8192,red=16384, black=32768}
-- test = redstone.getBundledInput("left")
while num1 ~= 0 do
	test = redstone.getBundledInput("left")
	for color,code in pairs(colors) do
		if colorTest(test, code) then
			print(color," is ON")
		end	
--		print(color, code)
--      print(test)
--		print(color, (colors.test (redstone.getBundledInput("left"), code)))
	end	
   num1 = tonumber(read())
   print("Press a key, 0 to exit")
end

