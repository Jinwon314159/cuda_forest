#pragma once
#include "global.cuh"

class fig_tree
{
public:
	fig_tree()
	{
		tree_index = UINT_MAX;

		trunk = 0;
		trunk_index = UINT_MAX;
	};
	~fig_tree()
	{
		if (trunk != 0)
			delete trunk;
	};

	unsigned int tree_index;

	fig_variety *variety; // Ç°Á¾
	
	fig_branch *trunk;
	unsigned int trunk_index;

	void plant(unsigned int t_idx, fig_variety *v, garden_tools* t)
	{
		tree_index = t_idx;
		variety = v;
		trunk = new fig_branch(t_idx, v, t);
	};

	unsigned int get_num_branches()
	{
		return trunk->get_num_branches();
	};

	unsigned int get_num_endpoints()
	{
		return trunk->get_num_endpoints();
	};

	bool dig_up_trees(unsigned int branch_index, garden_truck *truck, unsigned int *truck_branch_index, unsigned int *truck_endpoint_index)
	{
		trunk_index = branch_index;
		*truck_branch_index += 1;
		return trunk->dig_up(UINT_MAX, trunk_index, truck, truck_branch_index, truck_endpoint_index);
	};

	bool replant(garden_truck *truck)
	{
		return trunk->replant(truck);
	};

	bool replant_no_split(garden_truck *truck)
	{
		return trunk->replant_no_split(truck);
	};

	void plant(unsigned int t_idx, garden_truck *truck, fig_variety *v, garden_tools* t)
	{
		tree_index = t_idx;
		variety = v;
		trunk_index = truck->trees[tree_index];
		trunk = new fig_branch(t_idx, truck, v, t);
	};
};