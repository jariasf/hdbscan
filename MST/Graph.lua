--------------------------------------------------------------------------------
-- Graph Representations
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

do
	local Edge = torch.class("Edge")
	function Edge:__init(initial, final, weight)
		self.initial = initial
		self.final = final
		self.weight = weight
	end
end


do
	local HierarchicalEdge = torch.class("HierarchicalEdge")
	function HierarchicalEdge:__init(initial, final, weight, size)
		self.initial = initial
		self.final = final
		self.weight = weight
		self.size = size
	end
end
