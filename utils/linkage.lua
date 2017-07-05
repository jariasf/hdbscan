--------------------------------------------------------------------------------
-- Single linkage implementation based on Minimum spanning tree
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

	--[[
		Compute the hierarchical tree based on minimum spanning tree
		
		Input:
			- mst: Minimum spanning tree represented by edge's lists.
			- sort: Setting to True will sort the mst by weights (mandatory for Prim algorithm)

		Output:
			- hierarchy: Hierarchical tree of connected components.

	--]]
	function singleLinkageHierarchy(mst, sort)
		-- Leaves will have id [1,num_elements] and intermediate nodes will have [num_elements + 1, 2*num_elements -1]
		-- Hierarchy will have indices from [1,num_elements-1] = number of edges
		-- To access indices correctly from node_id = intermediate_node_id - num_elements
		
		if( sort == true ) then -- prim implementation requires to sort, kruskal does not
			table.sort(mst, function(a,b) return a.weight < b.weight end )
		end

		local num_vertices = #mst + 1
		local num_hierarchy_vertices = num_vertices * 2 - 1 -- hierarchy creates new vertices at each union 
		local uf = UnionFind()
		uf:MakeSet(num_hierarchy_vertices)

		for i=num_vertices, num_hierarchy_vertices do --intermediate nodes does not have initial size
			uf.size[i] = 0
		end

		local hierarchy = {}

		for i=1,#mst do
			local current_edge = mst[i]
			local initial = current_edge.initial
			local final = current_edge.final
			local weight = current_edge.weight

			local initial_root = uf:Find(initial)
			local final_root = uf:Find(final)
			local num_elements_initial = uf:NumberOfElements(initial_root)
			local num_elements_final = uf:NumberOfElements(final_root)
			local total_elements = num_elements_initial + num_elements_final		

			hierarchy[ #hierarchy + 1 ] = HierarchicalEdge(initial_root, final_root, weight, total_elements)
			
			-- union of children to intermediate node in hierarchy
			-- assume that in Union(a,b) --> b is always the parent
			
			uf:Union( initial_root, i + num_vertices ) 
			uf:Union( final_root, i + num_vertices )
		end

		return hierarchy	
	end
