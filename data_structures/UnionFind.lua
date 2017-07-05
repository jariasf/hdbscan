--------------------------------------------------------------------------------
-- Union-Find with path compression and union by rank
--------------------------------------------------------------------------------
-- Author: Jhosimar Arias
--------------------------------------------------------------------------------

do
	local UnionFind = torch.class("UnionFind")
	
	function UnionFind:__init() 
		UnionFind:Clear()
	end
		
	-- Initially all elements are their own connected component
	-- input: 
	--		- ids: list of element ids - {2,4,6,1,50}
	function UnionFind:MakeSetById(ids)
		local num_elements = #ids
		for i=1, num_elements do
			self.parent[ids[i]] = ids[i]
			self.rank[ids[i]] = 0
			self.size[ids[i]] = 1
		end
		self.num_components = num_elements
		self.elements = ids
	end

	-- Initially all elements are their own connected component
	-- input: 
	--		- num_elements: number of vertices, assuming ids [1,num_elements]
	function UnionFind:MakeSet(num_elements)
		for i=1, num_elements do
			self.parent[i] = i
			self.rank[i] = 0
			self.size[i] = 1
		end
		self.num_components = num_elements
		self.elements = ids
	end

	-- Connect two components given by two nodes
	-- input: 
	--		- x, y: nodes to connect
	-- O(n) worst case
	function UnionFind:Union(x, y)
		local xRoot = UnionFind:Find(x)
		local yRoot = UnionFind:Find(y)
		if( xRoot ~= yRoot ) then
			self.parent[ xRoot ] = yRoot
			self.num_components = self.num_components - 1
			self.size[ yRoot ] = self.size[ yRoot ] + self.size[ xRoot]
		end
	end

	-- Connect two components given by two nodes
	-- input: 
	--		- x, y: nodes to connect
	-- O(log(n)) worst case
	function UnionFind:UnionByRank(x, y)
		local xRoot = UnionFind:Find(x)
		local yRoot = UnionFind:Find(y)
		if( xRoot ~= yRoot ) then
			self.num_components = self.num_components - 1
			if( self.rank[xRoot] > self.rank[yRoot] ) then
				self.parent[ yRoot ] = xRoot
				self.size[ xRoot ] = self.size[ xRoot ] + self.size[ yRoot]
			else
				self.parent[ xRoot ] = yRoot
				self.size[ yRoot ] = self.size[ yRoot ] + self.size[ xRoot]
				if( self.rank[ xRoot ] == self.rank[ yRoot ] ) then
					self.rank[ yRoot ] = self.rank[ yRoot ] + 1
				end
			end
		end
	end	
		
	-- Find the component of the given node
	-- input: node id
	-- output: representative id of the component
	function UnionFind:Find(x)
		if( x == self.parent[x] ) then
			return x
		end
		self.parent[x] = UnionFind:Find(self.parent[x])
		return self.parent[x]
	end	

	-- Check if two nodes are part of the same component
	-- input: 
	--		- x, y: nodes to check
	function UnionFind:SameComponent(x, y)
		if( Find(x) == Find(y) ) then
			return true
		end
		return false
	end	

	-- Return the number of components
	function UnionFind:NumberOfComponents()
		return self.num_components
	end
	
	-- Count number of elements per component
	function UnionFind:CountNumberOfElements()
		local count = {}
		for i=1,#self.elements do
			local root = Find(self.elements[i])
			count[root] = count[root] + 1
		end	
		return count
	end

	-- Number of elements for x's component
	-- input:
	--		- x: node to query
	function UnionFind:NumberOfElements(x)
		return self.size[ self:Find(x) ]
	end

	-- Clear variables
	function UnionFind:Clear()
		self.parent = {}
		self.num_components = 0
		self.rank = {}
		self.size = {}
	end

end
