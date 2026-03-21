#pragma once
#include "global.cuh"

/*
Truck
*/
class garden_truck
{
public:
	garden_truck();
	~garden_truck();

	char Version[5];	// version of truck

	unsigned int T; // number of trees

	unsigned int nutrients_count;
	size_t nutrients_total_size;
	fig_nutrient *nutrients;
	bool fertilizer_bag(unsigned int nu_cnt);
	bool load_nutrients(fig_nutrient *nu, unsigned int nu_cnt);

	unsigned int fruits_count;
	size_t fruits_total_size;
	fig_fruit *fruits;
	bool load_fruits(fig_fruit *fr, unsigned int fr_cnt);

	unsigned int finest_fruits_count;
	size_t finest_fruits_total_size;
	fig_finest_fruit *finest_fruits;
	bool load_finest_fruits(fig_finest_fruit *fr, unsigned int fr_cnt);

	unsigned __int64 branches_count;
	unsigned __int64 endpoints_count;
	size_t trees_total_size;
	size_t branches_total_size;
	size_t twigs_total_size;
	unsigned __int64 *trees;
	cuda_branch *branches;
	fig_twig *twigs;
	bool load_trees(unsigned int tr_cnt, unsigned __int64 br_cnt, unsigned __int64 ep_cnt);

	unsigned int buckets_count;
	size_t water_total_amount;
	unsigned short *water;
	bool load_water(char* session_path, int start_index, int end_index);

	unsigned __int64 true_count[MAX_TREE_NUM];
	unsigned __int64 false_count[MAX_TREE_NUM];
	unsigned __int64 accumulated;
	double best;
	double error_rate;
	void accumulate_error_rate();
	bool get_error_rate();
	void reset_error_rate();

	bool do_harvest = false;
	void move_trees_to_warehouse(char* warehouse_address);	// store trees at warehouse
	unsigned int move_trees_from_warehouse(char* warehouse_address, bool do_harvest);	// take out trees from warehouse
};