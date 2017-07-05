--------------------------------------------------------------------------------
-- Minimum Spanning Tree: Kruskal Algorithm
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

require "./../data_structures/UnionFind"
require "./Graph"

do
	local MST = torch.class("MST")
	
	function MST:__init() end
	
	function MST:fit(adjacency_matrix)
		local num_vertices = #adjacency_matrix
		local edge_list = calculateEdgeList(adjacency_matrix, true)
		local num_edges = #edge_list
		local uf = UnionFind()
		local mst = {}		

		uf:MakeSet(num_vertices)
		
		for i=1,num_edges do
			local initial = edge_list[i].initial
			local final = edge_list[i].final
			local weight = edge_list[i].weight
			if( uf:Find(initial) ~= uf:Find(final) ) then
				uf:Union(initial, final)
				mst[ #mst + 1 ] = edge_list[i]
			end
		end
		
		return mst
	end

	function calculateEdgeList(adjacency_matrix, sorted)
		local num_vertices = #adjacency_matrix
		local edge_list = {}

		for i=1,num_vertices do
			for j=1,num_vertices do
				if( adjacency_matrix[i][j] > 0 ) then
					edge_list[#edge_list + 1] = Edge(i, j, adjacency_matrix[i][j])
				end
			end
		end

		if( sorted == true ) then
			table.sort(edge_list, function(a,b) return a.weight < b.weight end )
		end

		return edge_list
	end

end

--[[
--Test
require "Kruskal"
adjacency_matrix = {{0, 8, 0, 3}, {0, 0, 2, 5}, {0, 0, 0, 6}, {0, 0, 0, 0}}
mst = MST():fit(adjacency_matrix)
--]]
