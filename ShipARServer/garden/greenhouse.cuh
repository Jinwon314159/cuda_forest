#pragma once
#include "global.cuh"
#include "truck.cuh"

/*
Greenhouse
*/
class garden_greenhouse
{
public:
	garden_greenhouse();
	~garden_greenhouse();

	unsigned int T; // number of trees

	unsigned int nutrients_count;
	size_t nutrients_total_size;
	fig_nutrient *nutrients;
	bool give(fig_nutrient *nu, unsigned int nu_cnt);

	unsigned int fruits_count;
	size_t fruits_total_size;
	fig_fruit *fruits;
	bool fruit_box(unsigned int fr_cnt);

	unsigned int finest_fruits_count;
	size_t finest_fruits_total_size;
	fig_finest_fruit *finest_fruits;
	bool finest_fruit_box(unsigned int fr_cnt);

	unsigned __int64 branches_count;
	unsigned __int64 endpoints_count;
	size_t trees_total_size;
	size_t branches_total_size;
	size_t twigs_total_size;
	unsigned __int64 *trees;
	cuda_branch *branches;
	fig_twig *twigs;
	bool dig_up_land(unsigned int tr_cnt, unsigned __int64 br_cnt, unsigned __int64 ep_cnt);

	unsigned int buckets_count;
	size_t water_total_amount;
	unsigned short *water;
	texture<unsigned short, 1, cudaReadModeElementType> water_texture;
	bool pour(garden_truck* truck);
};