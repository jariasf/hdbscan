# Hierarchical Density-Based Spatial Clustering (HDBSCAN)

Lua/Torch implementation of HDBSCAN based on the python scikit-learn source: https://github.com/scikit-learn-contrib/hdbscan.

Implemented *generic version* of HDBSCAN, python library offers other versions which include modifications such as *prim+kd_tree*, *boruvka+ball_tree* and others.

Differences in implementation:
* Kruskal for MST because it facilitates the process in some steps (Prim implementation is also available).
* Comparison of KNN by brute force O(n^2), requires improvements with an external library or by implementing better algorithms.

### Parameters

- **min_cluster_size:** The minimum size of clusters.
- **min_samples:** The number of samples in a neighbourhood for a point to be considered a core point.
- **metric:** The metric to use when calculating distance between instances in a feature array (currently supports only euclidean).
- **allow_single_cluster:** By default HDBSCAN will not produce a single cluster, settings this to true allows single cluster results.

### Example of usage
``` lua
require "HDBSCAN" --Load HDBSCAN file
...
hdbscan = HDBSCAN(4, 4, "euclidean", false) --Initialize class with specified parameters
cluster_labels = hdbscan:fit(data, indices) --Run the algorithm given data and indices
```

### Based on the paper:
R. Campello, D. Moulavi, and J. Sander, *Density-Based Clustering Based on Hierarchical Density Estimates* In: Advances in Knowledge Discovery and Data Mining, Springer, pp 160-172. 2013

## Author:

- Jhosimar George Arias Figueroa
