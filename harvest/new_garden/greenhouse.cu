#include "greenhouse.cuh"

garden_greenhouse::garden_greenhouse()
{
	T = 0;

	nutrients_count = 0;
	nutrients_total_size = 0;
	nutrients = 0;

	fruits_total_size = 0;
	fruits = 0;

	finest_fruits_total_size = 0;
	finest_fruits = 0;

	branches_count = 0;
	endpoints_count = 0;
	trees_total_size = 0;
	branches_total_size = 0;
	twigs_total_size = 0;
	trees = 0;
	branches = 0;
	twigs = 0;

	buckets_count = 0;
	water_total_amount = 0;
	water = 0;
}

bool garden_greenhouse::ready(unsigned int tr_cnt, unsigned int nu_cnt)
{
	cudaError_t status;

	T = tr_cnt;

	nutrients_count = nu_cnt;
	nutrients_total_size = sizeof(fig_nutrient) * nutrients_count;
	if (nutrients) { cudaFree(nutrients); nutrients = 0; }
	status = cudaMalloc(&nutrients, nutrients_total_size);
	if (status != cudaSuccess) return false;

	fruits_count = nu_cnt;
	fruits_total_size = sizeof(fig_fruit) * fruits_count * T;
	if (fruits) { cudaFree(fruits); fruits = 0; }
	status = cudaMalloc(&fruits, fruits_total_size);
	if (status != cudaSuccess) return false;

	finest_fruits_count = nu_cnt;
	finest_fruits_total_size = sizeof(fig_finest_fruit) * finest_fruits_count;
	if (finest_fruits) { cudaFree(finest_fruits); finest_fruits = 0; }
	status = cudaMalloc(&finest_fruits, finest_fruits_total_size);
	if (status != cudaSuccess) return false;

	buckets_count = 6;
	water_total_amount = sizeof(unsigned short)* BUCKET_WIDTH * BUCKET_HEIGHT * buckets_count;
	if (water) { cudaFreeHost(water); water = 0; }
	cudaHostAlloc(&water, water_total_amount, cudaHostAllocDefault);
	if (status != cudaSuccess) return false;

	return true;
}

garden_greenhouse::~garden_greenhouse()
{
	if (nutrients) { cudaFree(nutrients); nutrients = 0; }
	if (fruits) { cudaFree(fruits); fruits = 0; }
	if (finest_fruits) { cudaFree(finest_fruits); finest_fruits = 0; }

	if (trees) { cudaFree(trees); trees = 0; }
	if (branches) { cudaFree(branches); branches = 0; }
	if (twigs) { cudaFree(twigs); twigs = 0; }

	if (water) { cudaFree(water); water = 0; }
}

bool garden_greenhouse::give(fig_nutrient *nu, unsigned int nu_cnt)
{
	cudaError_t status;

	nutrients_count = nu_cnt;
	nutrients_total_size = sizeof(fig_nutrient) * nutrients_count;

	status = cudaMemcpy(nutrients, nu, nutrients_total_size, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_greenhouse::fruit_box(unsigned int fr_cnt)
{
	cudaError_t status;

	fruits_count = fr_cnt;
	fruits_total_size = sizeof(fig_fruit) * fruits_count * T;

	return true;
}

bool garden_greenhouse::finest_fruit_box(unsigned int fr_cnt)
{
	cudaError_t status;

	finest_fruits_count = fr_cnt;
	finest_fruits_total_size = sizeof(fig_finest_fruit) * finest_fruits_count;

	return true;
}

bool garden_greenhouse::dig_up_land(unsigned int tr_cnt, unsigned __int64 br_cnt, unsigned __int64 ep_cnt)
{
	cudaError_t status;

	T = tr_cnt;

	trees_total_size = sizeof(unsigned __int64) * T;

	if (trees) { cudaFree(trees); trees = 0; }

	status = cudaMalloc(&trees, trees_total_size);
	if (status != cudaSuccess) return false;


	branches_count = br_cnt;

	branches_total_size = sizeof(cuda_branch) * branches_count;

	if (branches) { cudaFree(branches); branches = 0; }

	status = cudaMalloc(&branches, branches_total_size);
	if (status != cudaSuccess) return false;


	endpoints_count = ep_cnt;

	twigs_total_size = sizeof(fig_twig) * MAX_TW_NUM * endpoints_count;

	if (twigs) { cudaFree(twigs); twigs = 0; }

	status = cudaMalloc(&twigs, twigs_total_size);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_greenhouse::dig_up_land_harvest(unsigned int tr_cnt, unsigned __int64 br_cnt, unsigned __int64 ep_cnt)
{
	cudaError_t status;

	T = tr_cnt;

	trees_total_size = sizeof(unsigned __int64)* T;

	if (trees) { cudaFree(trees); trees = 0; }

	status = cudaMalloc(&trees, trees_total_size);
	if (status != cudaSuccess) return false;


	branches_count = br_cnt;

	branches_total_size = sizeof(cuda_branch)* branches_count;

	if (branches) { cudaFree(branches); branches = 0; }

	status = cudaMalloc(&branches, branches_total_size);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_greenhouse::pour(garden_truck *truck)
{
	cudaError_t status;

	buckets_count = truck->buckets_count;

	water_total_amount = truck->water_total_amount;

	status = cudaMemcpy(water, truck->water, water_total_amount, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_greenhouse::pour(unsigned short* w, int b, int sz)
{
	cudaError_t status;

	buckets_count = b;

	water_total_amount = sizeof(unsigned short) * b * sz;

	status = cudaMemcpy(water, w, water_total_amount, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;

	return true;
}
