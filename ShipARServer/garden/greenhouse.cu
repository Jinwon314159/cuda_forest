#include "greenhouse.cuh"

garden_greenhouse::garden_greenhouse()
{
	T = 0;

	nutrients_count = 0;
	nutrients_total_size = 0;
	nutrients = 0;

	fruits_count = 0;
	fruits_total_size = 0;
	fruits = 0;

	finest_fruits_count = 0;
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

garden_greenhouse::~garden_greenhouse()
{
	cudaError_t status = cudaSuccess;

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

	if (nutrients_count != nu_cnt)
	{
		nutrients_count = nu_cnt;
		nutrients_total_size = sizeof(fig_nutrient) * nutrients_count;

		if (nutrients) { cudaFree(nutrients); nutrients = 0; }

		status = cudaMalloc(&nutrients, nutrients_total_size);
		if (status != cudaSuccess) return false;
		cudaMemset(nutrients, 0, nutrients_total_size);
	}

	status = cudaMemcpy(nutrients, nu, nutrients_total_size, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_greenhouse::fruit_box(unsigned int fr_cnt)
{
	cudaError_t status;

	if (fruits_count != fr_cnt)
	{
		fruits_count = fr_cnt;
		fruits_total_size = sizeof(fig_fruit) * fruits_count * T;

		if (fruits) { cudaFree(fruits); fruits = 0; }

		status = cudaMalloc(&fruits, fruits_total_size);
		if (status != cudaSuccess) return false;
		cudaMemset(fruits, 0, fruits_total_size);
	}

	return true;
}

bool garden_greenhouse::finest_fruit_box(unsigned int fr_cnt)
{
	cudaError_t status;

	if (finest_fruits_count != fr_cnt)
	{
		finest_fruits_count = fr_cnt;
		finest_fruits_total_size = sizeof(fig_finest_fruit)* finest_fruits_count;

		if (finest_fruits) { cudaFree(finest_fruits); finest_fruits = 0; }

		status = cudaMalloc(&finest_fruits, finest_fruits_total_size);
		if (status != cudaSuccess) return false;
		cudaMemset(finest_fruits, 0, finest_fruits_total_size);
	}

	return true;
}

bool garden_greenhouse::dig_up_land(unsigned int tr_cnt, unsigned __int64 br_cnt, unsigned __int64 ep_cnt)
{
	cudaError_t status;

	if (T != tr_cnt)
	{
		T = tr_cnt;

		trees_total_size = sizeof(unsigned __int64) * T;

		if (trees) { cudaFree(trees); trees = 0; }

		status = cudaMalloc(&trees, trees_total_size);
		if (status != cudaSuccess) return false;
		cudaMemset(trees, 0, trees_total_size);
	}

	if (branches_count != br_cnt)
	{
		branches_count = br_cnt;

		branches_total_size = sizeof(cuda_branch) * branches_count;

		if (branches) { cudaFree(branches); branches = 0; }

		status = cudaMalloc(&branches, branches_total_size);
		if (status != cudaSuccess) return false;
		cudaMemset(branches, 0, branches_total_size);
	}

	if (endpoints_count != ep_cnt)
	{
		endpoints_count = ep_cnt;

		twigs_total_size = sizeof(fig_twig) * MAX_TW_NUM * endpoints_count;

		if (twigs) { cudaFree(twigs); twigs = 0; }

		status = cudaMalloc(&twigs, twigs_total_size);
		if (status != cudaSuccess) return false;
		cudaMemset(twigs, 0, twigs_total_size);
	}

	return true;
}

bool garden_greenhouse::pour(garden_truck *truck)
{
	cudaError_t status;

	if (buckets_count != truck->buckets_count)
	{
		buckets_count = truck->buckets_count;

		water_total_amount = truck->water_total_amount;

		if (water) {
#ifdef WATER_TEXTURE
			cudaUnbindTexture(water_texture);
#endif
			cudaFree(water);
			water = 0;
		}

		status = cudaMalloc(&water, water_total_amount);
		if (status != cudaSuccess) return false;
		cudaMemset(water, 0, water_total_amount);

#ifdef WATER_TEXTURE
#if 1
		water_texture.addressMode[0] = cudaAddressModeClamp;
		water_texture.filterMode = cudaFilterModePoint;
		water_texture.normalized = true; // access with normalized texture coordinates
		cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc(16, 0, 0, 0, cudaChannelFormatKindUnsigned);
		status = cudaBindTexture(NULL, &water_texture, water, &channelDesc);
#else
		status = cudaBindTexture(NULL, water_texture, water, cudaCreateChannelDesc(16, 0, 0, 0, cudaChannelFormatKindUnsigned));
#endif
		if (status != cudaSuccess) return false;
#endif
	}

	status = cudaMemcpy(water, truck->water, water_total_amount, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;

	return true;
}
