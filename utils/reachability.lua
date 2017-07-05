--------------------------------------------------------------------------------
-- Mutual Reachability Distance Computations 
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

	--[[
		Compute the weighted adjacency matrix of the mutual reachability graph of a distance matrix.
		
		Input:
			- data (NxM): Tensor representing the data to cluster.
			- indices (K): Indices to consider from the data (useful when working with batches).
			- min_samples: The number of points in a neighbourhood for a point to be considered a core point.

		Output:
			- distances (NxN): Weighted adjacency matrix of the mutual reachability graph.

	--]]
	function mutualReachability(data, indices, min_samples)
		-- TODO: Improve KNN algorithm
		local distances = calculateDistanceAllvsAll(data, indices)
		local knn = calculateKNN(indices, distances, min_samples + 1) -- includes itself
		local num_elements = #indices
		for i=1,num_elements do
			local current_index = indices[i]
			local core_distance_i = knn[ current_index ][#knn[current_index]][2] -- knn distance
			for j=1,num_elements do
				local adjacent_index = indices[j]
				local core_distance_j = knn[ adjacent_index ][#knn[adjacent_index]][2]
				distances[i][j] = math.max(distances[i][j], math.max( core_distance_i, core_distance_j ))
			end
		end
		return distances
	end


--Calculate euclidean distance between two tensor
function euclideanDistance(x, y)
	local distance = torch.sum( torch.pow( (x - y), 2) )
	return torch.sqrt(distance)
end


-- Calculate AllvsAll distances O(n^2)
-- input: data(NxK), list of indices
-- output: distances[i][j], mean of all the distances
function calculateDistanceAllvsAll(data, indices_list)
	local num_elements = #indices_list
	local mean = 0
    local cnt = 0
    local distance = {}
    for i=1,num_elements do
		distance[i] = {}
        for j=1,num_elements do
		    distance[i][j] = euclideanDistance(data[indices_list[i]], data[indices_list[j]])
        	if i ~= j then 
				mean = mean + distance[i][j]
            	cnt = cnt + 1
			end
		end
    end
	if cnt ~= 0 then mean = mean/cnt end
	return distance, mean
end

-- KNN O(n^2)
-- input: list of indices, pre-calculated distances AllvsAll,
--        k: number of nearest neighbors to consider
-- output: list of nearest neighbors for each index
--        knn[index_i] = [(index_j,distance_j),(index_k,distance_k),(index_v,distance_v)]
function calculateKNN(indices_list, distances, k)
	local num_elements = #indices_list
	local knn = {}

	for i=1,num_elements do
        local distancesRow = {}
        for j =1,num_elements do
            distancesRow[j] = {indices_list[j], distances[i][j]} -- adjacent and distance
        end

		table.sort( distancesRow, function( a, b ) return a[2] < b[2] end ) --sort in increasing order by distance	
		knn[indices_list[i]] = {}

		local neighbors = math.min(k, #distancesRow)
		for j=1,neighbors do
			knn[indices_list[i]][ #knn[indices_list[i]] + 1 ] = {distancesRow[j][1], distancesRow[j][2]}
		end	
	end
	return knn
end
--[[
Test
indices_list = {1,2,3, 4}
distances = {{1,2,3,4},{4,5,6,7}, {10,11,2,6}, {4,3,2,1}}
k=2
--]]
