--------------------------------------------------------------------------------
-- Hierarchical Density-Based Spatial Clustering
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

require "./MST/Kruskal"
require "./utils/reachability"
require "./utils/linkage"
require "./utils/tree"

do
	local HDBSCAN = torch.class("HDBSCAN")
	
	--[[ 
		Constructor Parameters: 
			- min_cluster_size (default=5): The minimum size of clusters
			- min_samples: The number of samples in a neighbourhood for a point to be considered a core point.
			- metric: The metric to use when calculating distance between instances in a feature array (currently supports only euclidean).
			- allow_single_cluster: Setting this to True will allow single cluster results.
	--]]
	function HDBSCAN:__init(min_cluster_size, min_samples, metric, allow_single_cluster)
		if( metric == nil ) then metric = "euclidean" end
		if( min_cluster_size == nil ) then min_cluster_size = 5 end
		self.min_cluster_size = min_cluster_size
		self.min_samples = min_samples
		self.metric = metric
		self.allow_single_cluster = allow_single_cluster
	end

	--[[
		Input:
			- data (NxM): Tensor representing the data to cluster.
			- indices (L): Indices to consider from the data (useful when working with batches).
		Output:
			- labels (N): Cluster labels for each point in the dataset. Noisy samples are given the label -1.
			- stabilities: Stability values obtained from the condensed tree.
			- condensed_tree: The condensed tree produced by HDBSCAN.
			- hierarchical_tree: The single linkage tree produced by HDBSCAN.
	--]]
	function HDBSCAN:fit(data, indices)
		local distances = mutualReachability(data, indices, self.min_samples)
		local mst = MST():fit(distances)
		local hierarchical_tree = singleLinkageHierarchy(mst, false)
		local condensed_tree = condenseTree(hierarchical_tree, self.min_cluster_size)
		local stability = computeStability(condensed_tree)
		local labels = getClusters(condensed_tree, stability, self.allow_single_cluster)
		return labels, stabilities, condensed_tree, hierarchical_tree
	end

end
