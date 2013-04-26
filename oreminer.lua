-- anything after two dashes is a comment, and wont be compiled.
--[[ this is also a comment
and so is this
]]--

--this tutorial will teach you the basics of the print() and read() functions, if statements, as well as some variable use and math operations.


print("Do you want to add, subtract, multiply or divide?") -- this code displays the question within the quotation marks
op = read() -- this code creates a variable called 'op', the read() function stalls the program to accept user input, which is stored in op
print("") -- just gives us some space to work with

print("what is the first number to be operated on?")

num1 = tonumber(read()) -- accepts the first number to be stored in the variable 'number1'
print("")

print("and the second number?")
num2 = tonumber(read())
print("")

-- now we operate on the number depending on what the user typed first

if op == "add" then -- if you need help with conditional statements, see this page: [1]
 result = num1+num2
print(result) -- this prints the result
end

if op == "multiply" then
 result = num1*num2 -- asterisk represents multiply
print(result)
end

if op == "divide" then
 result = num1/num2
print(result)
end

if op == "subtract" then
 result = num1-num2
print(result)
end