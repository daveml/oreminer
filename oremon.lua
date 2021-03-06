local __sideRn = "left"
local __sideMon = "back"

local w, h 
local wm, hm, monitor

function Init()
	rednet.open(__sideRn)
	monitor = peripheral.wrap(__sideMon)
	wm, hm = monitor.getSize()
	monitor.setTextScale(1)
	print("MyId => ", os.computerID())
	monitor.clear()
	monitor.setCursorPos(1,1)
	monitor.write("MyId => ", os.computerID())
end

local CartStatus = {
	{1,1,"    Last Cart Scan Status"},
	{1,2,"-----------------------------"},event
	{1,3,"        Cart Type => "},
	{1,4,"     Cargo Empty? => "},
	{1,5,"      Cargo Full? => "},
	{1,6,"Railer has rails? => "},
	{1,7,"     Has Torches? => "},
	{1,8,"Bridge Materials? => "},
	{1,9,"-----------------------------"}}
	
local clrCartStatus = {
	{23,3,"        "},
	{23,4,"        "},
	{23,5,"        "},
	{23,6,"        "},
	{23,7,"        "},
	{23,8,"        "}}rednet
	
local setCartStatus = {
	{23,3,"        "},
	{23,4,"        "},
	{23,5,"        "},
	{23,6,"        "},
	{23,7,"        "},
	{23,8,"        "}}

function screenDraw(blob)
	for k,v in pairs(blob) do
		monitor.setCursorPos(v[1],v[2])
		monitor.write(v[3])
	end
end
	
Init()

while true do
	
    event, param1, param2 = os.pullEvent()

	if event == "char" then
		if param1 == "e" then
		    break
		end
	end

	if event == "rednet_message" then
		
		if string.find(param2, "CARTSCAN:") then
			print("cartScan msg received!")
			print(param2)
			local stat = setCartStatus
			i=1
			for v in string.gmatch(param2, ":(%w+)") do
   				print(v)
   				stat[i][3] = v
   				i=i+1
			end
			screenDraw(clrCartStatus)
			screenDraw(CartStatus)
			screenDraw(stat)
		end
	end		


end
