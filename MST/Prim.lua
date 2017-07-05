--------------------------------------------------------------------------------
-- Minimum Spanning Tree: Prim Algorithm O(n^2)
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

require "./Graph"

do
	local MST = torch.class("MST")
	
	function MST:__init() end
	
	-- O(n^2)
	function MST:fit(adjacency_matrix)
		local num_vertices = #adjacency_matrix
		local visited = {}		
		local mst = {}	
		local distances = {}
		local parent = {}

		for i=1,num_vertices do
			distances[i] = math.huge
			visited[i] = false
			parent[i] = -1
		end
		
		distances[1] = 0

		for i=1,(num_vertices-1) do
			local initial = minKey(distances, visited, num_vertices)			
			visited[initial] = true
			for j=1,num_vertices do
				if( adjacency_matrix[initial][j] > 0 and adjacency_matrix[initial][j] < distances[j] and visited[j] ~= true ) then
					distances[j] = adjacency_matrix[initial][j]
					parent[j] = initial
				end
			end
		end	
		
		
		for i= 2, num_vertices do
			table.insert( mst, Edge(parent[i], i, distances[i]) )
		end

		return mst
	end

	function minKey(distances, visited, num_vertices)
		local minimum = math.huge -- infinite
		local minimum_index = -1
		for j=1,num_vertices do
			if(	distances[j] < minimum and visited[j] == false ) then
				minimum = distances[j]
				minimum_index = j
			end
		end
		return minimum_index
	end
end

--[[
--Test
require "Prim"
adjacency_matrix = {{2,2,2},{2,2,3},{2,3,2}} --{{0, 8, 0, 3}, {0, 0, 2, 5}, {0, 0, 0, 6}, {0, 0, 0, 0}}
mst = MST():fit(adjacency_matrix)
--]]
