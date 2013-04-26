local __sideRn = "left"
local __sideMon = "back"
local __myId = os.getComputerID()

local w, h 
local wm, hm, monitor

function Init()
	rednet.open(__sideRn)
	print("MyId => ",__myID)
	monitor = peripheral.wrap(__sideMon)
	wm, hm = monitor.getSize()
	monitor.setTextScale(1)
	monitor.clear()
end

local CartStatus = {
	{1,1,"       Cart Scan Status"},
	{1,2,"-----------------------------"},
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
	{23,8,"        "}}
	
function screenDraw(blob)
	monitor.clear()

	for x,y,str in pairs(blob) do
		monitor.setCursorPos(x,y)
		monitor.write(str)
	end
end
	
Init()

while true do
	
    event, param1, param2 = os.pullEvent()

	if event == "rednet_message" then
		
		if string.find(param2, "CARTSCAN:") then
			print("cartScan msg received!")
			print(param2)
			monitor.write(param2)
		end
	end		

    
end
