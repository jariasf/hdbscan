--------------------------------------------------------------------------------
-- Tree handling (condensing, finding stable clusters and cluster labels)
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

--[[
	Perform a breadth first search on a tree
	
	Input:
		- hierarchy: Hierarchical tree represented by edge lists.
		- root: Starting node of the BFS traversal.

	Output:
		- bfs_traversal: List of traversed nodes.
--]]
function bfsTraversalFromHierarchy(hierarchy, root)
	local num_leaves = #hierarchy + 1
	local queue = {root}
	local bfs_traversal = {root}
	while #queue > 0 do
		local new_queue = {}
		for _,current_node in ipairs(queue) do
			local correct_index = current_node - num_leaves
			if( correct_index > 0 ) then --only intermediate nodes
				local current_edge = hierarchy[correct_index]
				table.insert(new_queue, current_edge.initial)
				table.insert(new_queue, current_edge.final)
				
				table.insert(bfs_traversal, current_edge.initial)
				table.insert(bfs_traversal, current_edge.final)
			end
		end			
		queue = new_queue
	end
	return bfs_traversal
end


--[[
	Condense a tree according to a minimum cluster size. This is akin to the runt pruning procedure of Stuetzle.
	
	Input:
		- hierarchy: Hierarchical tree represented by edge lists.
		- min_cluster_size: The minimum size of clusters to consider.

	Output:
		- condensed: Condensed tree represented by an edge list with a parent, child, lambda_val and child_size.
--]]
function condenseTree(hierarchy, min_cluster_size)
	
	local num_leaves = #hierarchy + 1
	local root = 2 * num_leaves - 1
	
	local relabel = {}
	local visited = {}
	
	relabel[root] = num_leaves + 1
	local next_label = num_leaves + 2
	local condensed = {}		

	for _,node_id in ipairs(bfsTraversalFromHierarchy(hierarchy,root)) do
		-- unvisited intermediate nodes
		if( (visited[node_id] == nil or visited[node_id] == false) and node_id > num_leaves ) then
			local correct_index = node_id - num_leaves
			local left_child_id = hierarchy[correct_index].initial
			local right_child_id = hierarchy[correct_index].final
			local weight = hierarchy[correct_index].weight 

			local lambda = math.huge -- infinite
			if( weight > 0 ) then lambda = 1/weight end


			local left_size = 1
			if left_child_id - num_leaves > 0 then 
				left_size = hierarchy[left_child_id - num_leaves].size 
			end
			
			local right_size = 1
			if right_child_id - num_leaves > 0 then 
				right_size = hierarchy[right_child_id - num_leaves].size 
			end

			if( left_size >= min_cluster_size and right_size >= min_cluster_size ) then
				-- correct split, assign new labels to children
				relabel[left_child_id] = next_label
				next_label = next_label + 1
				
				relabel[right_child_id] = next_label
				next_label = next_label + 1
				
				-- add condensed clusters
				table.insert(condensed, HierarchicalEdge(relabel[node_id], relabel[left_child_id], lambda, left_size ))
				table.insert(condensed, HierarchicalEdge(relabel[node_id], relabel[right_child_id], lambda, right_size ))

			elseif( left_size < min_cluster_size and right_size < min_cluster_size ) then
				-- spurious components, cluster has disappeared, mark all subcomponents as NULL
				
				for _,subnode_id in ipairs( bfsTraversalFromHierarchy(hierarchy, left_child_id) ) do
					visited[subnode_id] = true
					if( subnode_id <= num_leaves) then
						table.insert(condensed, HierarchicalEdge(relabel[node_id], subnode_id, lambda, 1))
					end
				end
		
				for _,subnode_id in ipairs( bfsTraversalFromHierarchy(hierarchy, right_child_id) ) do
					visited[subnode_id] = true
					if( subnode_id <= num_leaves) then
						table.insert(condensed, HierarchicalEdge(relabel[node_id], subnode_id, lambda, 1))
					end
				end

			elseif( left_size < min_cluster_size ) then
				for _,subnode_id in ipairs( bfsTraversalFromHierarchy(hierarchy, left_child_id) ) do
					visited[subnode_id] = true
					if( subnode_id <= num_leaves) then
						table.insert(condensed, HierarchicalEdge(relabel[node_id], subnode_id, lambda, 1))
					end
				end

				-- right child was correct, it mantains the label of its parent
				relabel[right_child_id] = relabel[node_id]
				
			elseif( right_size < min_cluster_size ) then
				for _,subnode_id in ipairs( bfsTraversalFromHierarchy(hierarchy, right_child_id) ) do
					visited[subnode_id] = true
					if( subnode_id <= num_leaves) then
						table.insert(condensed, HierarchicalEdge(relabel[node_id], subnode_id, lambda, 1))
					end
				end

				-- left child was correct, it mantains the label of its parent
				relabel[left_child_id] = relabel[node_id]
			end

		end
	end
	return condensed
end


--[[
	Compute the stability values from the condensed tree
	
	Input:
		- condensed_tree: Condensed tree represented by an edge list with a parent, child, lambda_val and child_size.

	Output:
		- stability: Stability map for each node of the tree, map is represented by [node_id]->value

--]]
function computeStability(condensed_tree)
	-- sort by lambda value
	table.sort(condensed_tree, function(a,b) return a.weight < b.weight end )
	local num_edges = #condensed_tree
	
	-- compute minimum lambda value
	local root = -1
	local birth = {}
	local last_child = -1
	for i=1,num_edges do
		local child = condensed_tree[i].final
		local lambda = condensed_tree[i].weight
		if( last_child ~= child ) then
			birth[child] = lambda
			last_child = child
		end
		
		if( root == -1 ) then root = condensed_tree[i].initial	
		else root = math.min(root, condensed_tree[i].initial) end
	end
	birth[root] = 0		
	
	-- compute stability
	local stability = {}
	for i=1,num_edges do
		local parent = condensed_tree[i].initial
		local child = condensed_tree[i].final
		local lambda = condensed_tree[i].weight
		local size = condensed_tree[i].size
		if( stability[parent] == nil ) then stability[parent] = 0 end
		stability[parent] = stability[parent] + (lambda - birth[parent]) * size
	end

	return stability
end


--[[
	Given a tree and stability map, produce the cluster labels for a flat clustering based on Excess of Mass algorithm

	Input:
		- condensed_tree: Condensed tree represented by an edge list with a parent, child, lambda_val and child_size.
		- stability: Stability map for each node of the tree, map is represented by [node_id]->value
		- allow_single_cluster: Whether to allow a single cluster to be selected by the Excess of Mass algorithm.

	Output:
		- labels: Cluster labels list for each point in the dataset. Noisy samples are given the label -1.

--]]
function getClusters(condensed_tree, stability, allow_single_cluster)
	-- sort stability keys to traverse tree bottom-up	
	local stability_keys = {}
	for key in pairs(stability) do
		table.insert(stability_keys, key)
	end		

	table.sort(stability_keys, function(a,b) return a > b end)
	if( allow_single_cluster ~= true ) then -- remove root
		table.remove(stability_keys, #stability_keys)
	end
	
	-- adjacency list of condensed tree (only cluster_size > 1)
	local num_edges = #condensed_tree		
	local adjacency_list = {}
	for i=1,num_edges do
		local parent = condensed_tree[i].initial
		local child = condensed_tree[i].final
		local lambda = condensed_tree[i].weight
		local size = condensed_tree[i].size			

		if( adjacency_list[parent] == nil ) then adjacency_list[parent] = {} end
		if( size > 1 ) then
			table.insert(adjacency_list[parent], child)			
		end
	end		

	-- Optimal selection of clusters		
	local is_cluster = {}
	local num_clusters = #stability_keys
	
	for i=1,num_clusters do -- Excess of Mass implementation
		local cluster_id = stability_keys[i]
		local children_stability = 0
		for j=1,#adjacency_list[ cluster_id ] do
			local child = adjacency_list[cluster_id][j]
			children_stability = children_stability + stability[child]
		end
		
		if( children_stability > stability[cluster_id] ) then --if S(Ci) < S(Cil) + S(Cir)
			is_cluster[ cluster_id ] = false
			stability[ cluster_id ] = children_stability
		else
			is_cluster[ cluster_id ] = true
			for _,child in ipairs(bfsTraversalFromGraph(adjacency_list, cluster_id)) do
				if( child ~= cluster_id ) then
					is_cluster[child] = false
				end
			end
		end
	end

	-- Mapping from node_ids to values between [1,num_clusters]
	local cluster_mapping = {}
	local id = 1
	for node_id, valid in pairs(is_cluster) do
		if( valid == true ) then
		--if( is_cluster[node_id] == true ) then
			cluster_mapping[node_id] = id
			id = id + 1
		end
	end
	
	local cluster_labels = doLabelling(condensed_tree, cluster_mapping, allow_single_cluster)
	--TODO 
	-- local probs = getProbabilities(condensed_tree, reverse_cluster_mapping, cluster_labels)
	-- local stabilities = getStability_scores(cluster_labels, clusters, stability, max_lambda)
	
	return cluster_labels
end


--[[
	Perform a breadth first search on a graph
	
	Input:
		- adjacency_list: Adjacency list representing a graph
		- root: Starting node of the BFS traversal.

	Output:
		- bfs_traversal: List of traversed nodes.
--]]
function bfsTraversalFromGraph(adjacency_list, root)
	local queue = {root}
	local bfs_traversal = {root}
	while #queue > 0 do
		local new_queue = {}
		for _,current_node in ipairs(queue) do
			for i=1,#adjacency_list[current_node] do
				local adjacent_node = adjacency_list[current_node][i]
				table.insert(new_queue, adjacent_node)
				table.insert(bfs_traversal, adjacent_node)
			end
		end			
		queue = new_queue
	end
	return bfs_traversal
end


--[[
	Do labeling of the condensed tree with the Excess of Mass algorithm		

	Input:
		- condensed_tree: Condensed tree represented by an edge list with a parent, child, lambda_val and child_size.
		- cluster_mapping: Mapping of condensed tree node_ids to values between [1,num_clusters]
		- allow_single_cluster: Whether to allow a single cluster to be selected by the Excess of Mass algorithm.

	Output:
		- labels: Cluster labels list for each point in the dataset. Noisy samples are given the label -1.
--]]
-- From leaves get the cluster which they belong to and assing their cluster id
function doLabelling(condensed_tree, cluster_mapping, allow_single_cluster) 
	
	local num_clusters = 0
	for _,_ in pairs(cluster_mapping) do num_clusters = num_clusters + 1 end

	local number_nodes = 0
	local root = -1

	for i=1,#condensed_tree do
		if( root == -1 or root > condensed_tree[i].initial ) then
			root = condensed_tree[i].initial
		end
		number_nodes = math.max( number_nodes, condensed_tree[i].initial )
	end
	
	local num_leaves = root - 1
	local uf = UnionFind()
	uf:MakeSet( number_nodes )
	
	-- assign each point to its closest parent
	local lambda_child = {}
	local lambda_max = {}
	for i=1,#condensed_tree do
		local parent = condensed_tree[i].initial
		local child = condensed_tree[i].final
		local lambda = condensed_tree[i].weight
		if cluster_mapping[child] == nil then
			uf:Union(child, parent)
		end
		
		-- used later when one cluster is allowed
		lambda_child[child] = lambda
		if( lambda_max[parent] == nil ) then lambda_max[parent] = lambda 
		else lambda_max[parent] = math.max(lambda_max[parent], lambda ) end
	end
	
	-- assign each point to a cluster
	local labels = {}
	for i=1,num_leaves do
		local cluster_id = uf:Find(i)
		if( cluster_id < root ) then
			labels[i] = -1
		elseif( cluster_id == root ) then
			if( num_clusters == 1 and allow_single_cluster == true and lambda_child[i] >= lambda_max[cluster_id] ) then
				labels[i] = cluster_mapping[ cluster_id ]
			else
				labels[i] = -1 -- noisy point
			end
		elseif( cluster_id > root ) then
			labels[i] = cluster_mapping[cluster_id]
		end
		
	end
	
	return labels

end
