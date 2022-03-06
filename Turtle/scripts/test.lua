rednet.open("right")
local senderId, msg, distance = rednet.receive()
print(msg)
loadstring(msg)()
