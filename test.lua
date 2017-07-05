require "HDBSCAN"

function readData(dirname)
	local f = io.open(dirname,"r")
	local data = {}
	local index = 1
	for line in f:lines() do
		local tokens = line:split(" ")
		if( data[index] == nil ) then
			data[index] = {}
		end
		for i=1,#tokens do
			data[index][i] = tonumber(tokens[i])
		end		
		index = index + 1		
	end
	f:close()
	return data 
end

local data = readData("data_test.txt")
local tensorData = torch.DoubleTensor(#data, #data[1])

for i=1,#data do
	for j =1, #data[i] do
		tensorData[i][j] = data[i][j]
	end
end

local n = tensorData:size(1)
local indices = {}
for i=1,n do
	indices[i] = i
end

print("Initializing hdbscan")
local hdbscan = HDBSCAN(4, 4, "euclidean", false)

local labels = hdbscan:fit(tensorData, indices )

io.write("[")
for i=1,#labels do
	if(i > 1) then io.write(",") end 
		io.write(labels[i])
end
io.write("]\n")

