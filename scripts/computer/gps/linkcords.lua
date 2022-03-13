print('Enter in the x location of the computer')
local x = read()
print('Enter in the y location of the computer')
local y = read()
print('Enter in the z location of the computer')
local z = read()

shell.run("gps","host",x,y,z)