#include "truck.cuh"

garden_truck::garden_truck()
{
	if (Version == NULL)
		Version = new char[4];
	Version = "V001";
	T = 0;

	nutrients_count = 0;
	nutrients_total_size = 0;
	nutrients = 0;

	fruits_count = 0;
	fruits_total_size = 0;
	fruits = 0;

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

	best = DBL_MAX;
	reset_error_rate();
}

bool garden_truck::ready(unsigned int tr_cnt, unsigned int nu_cnt)
{
	cudaError_t status;

	T = tr_cnt;

	nutrients_count = nu_cnt;
	nutrients_total_size = sizeof(fig_nutrient) * nutrients_count;
	if (nutrients) { cudaFreeHost(nutrients); nutrients = 0; }
	status = cudaHostAlloc(&nutrients, nutrients_total_size, cudaHostAllocDefault);
	if (status != cudaSuccess) return false;

	fruits_count = nu_cnt;
	fruits_total_size = sizeof(fig_fruit) * fruits_count * T;
	if (fruits) { cudaFreeHost(fruits); fruits = 0; }
	status = cudaHostAlloc(&fruits, fruits_total_size, cudaHostAllocDefault);
	if (status != cudaSuccess) return false;

	finest_fruits_count = nu_cnt;
	finest_fruits_total_size = sizeof(fig_finest_fruit) * finest_fruits_count;
	if (finest_fruits) { cudaFreeHost(finest_fruits); finest_fruits = 0; }
	status = cudaHostAlloc(&finest_fruits, finest_fruits_total_size, cudaHostAllocDefault);
	if (status != cudaSuccess) return false;

	buckets_count = 1;
	water_total_amount = sizeof(unsigned short)* BUCKET_WIDTH * BUCKET_HEIGHT;
	if (water) { cudaFreeHost(water); water = 0; }
	status = cudaHostAlloc(&water, water_total_amount, cudaHostAllocDefault);
	if (status != cudaSuccess) return false;

	return false;
}

garden_truck::~garden_truck()
{
	if (nutrients) { cudaFreeHost(nutrients); nutrients = 0; }
	if (fruits) { cudaFreeHost(fruits); fruits = 0; }

	if (trees) { cudaFreeHost(trees); trees = 0; }
	if (branches) { cudaFreeHost(branches); branches = 0; }
	if (twigs) { cudaFreeHost(twigs); twigs = 0; }

	if (water) { cudaFree(water); water = 0; }
}

bool garden_truck::load_trees(unsigned int tr_cnt, unsigned __int64 br_cnt, unsigned __int64 ep_cnt)
{
	cudaError_t status;

	if (T != tr_cnt)
	{
		T = tr_cnt;

		trees_total_size = sizeof(unsigned __int64) * T;

		if (trees) { cudaFreeHost(trees); trees = 0; }

		status = cudaHostAlloc(&trees, trees_total_size, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	if (branches_count != br_cnt)
	{
		branches_count = br_cnt;

		branches_total_size = sizeof(cuda_branch) * branches_count;

		if (branches) { cudaFreeHost(branches); branches = 0; }

		status = cudaHostAlloc(&branches, branches_total_size, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	if (endpoints_count != ep_cnt)
	{
		endpoints_count = ep_cnt;

		twigs_total_size = sizeof(fig_twig) * MAX_TW_NUM * endpoints_count;

		if (twigs) { cudaFreeHost(twigs); twigs = 0; }

		status = cudaHostAlloc(&twigs, twigs_total_size, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	return true;
}

bool garden_truck::fertilizer_bag(unsigned int nu_cnt)
{
	cudaError_t status;

	if (nutrients_count != nu_cnt)
	{
		nutrients_count = nu_cnt;

		nutrients_total_size = sizeof(fig_nutrient) * nutrients_count;

		if (nutrients) { cudaFreeHost(nutrients); nutrients = 0; }

		status = cudaHostAlloc(&nutrients, nutrients_total_size, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	return true;
}

bool garden_truck::load_nutrients(fig_nutrient *nu, unsigned int nu_cnt)
{
	cudaError_t status;

	nutrients_count = nu_cnt;

	nutrients_total_size = sizeof(fig_nutrient) * nutrients_count;

	status = cudaMemcpy(nutrients, nu, nutrients_total_size, cudaMemcpyHostToHost);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_truck::load_fruits(fig_fruit *fr, unsigned int fr_cnt)
{
	cudaError_t status;

	fruits_count = fr_cnt;

	fruits_total_size = sizeof(fig_fruit) * nutrients_count * T;

	status = cudaMemcpy(fruits, fr, fruits_total_size, cudaMemcpyDeviceToHost);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_truck::load_water(int start_index, int end_index)
{
	cudaError_t status;

	unsigned int bucket_size = sizeof(unsigned short)* BUCKET_WIDTH * BUCKET_HEIGHT;

	if (buckets_count != end_index - start_index + 1)
	{
		buckets_count = end_index - start_index + 1;

		water_total_amount = bucket_size * buckets_count;

		if (water) { cudaFreeHost(water); water = 0; }

		status = cudaHostAlloc(&water, water_total_amount, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	for (int i = start_index; i <= end_index; i++)
	{
		// depth file
		char depth_file_path[256] = { 0 };
		//sprintf(depth_file_path, "..\\..\\sun_data\\depthdata.%d.dat", bucket_index);
		sprintf(depth_file_path, ".\\data\\depth\\depth_%d.dat", i);

		FILE* fp;
		fopen_s(&fp, depth_file_path, "rb");

		int count = BUCKET_WIDTH * BUCKET_HEIGHT;
		if (count != fread(water + count * (i - start_index), sizeof(unsigned short), count, fp))
		{
			std::cout << "Error: fill_water() file read fail!" << std::endl;
			fclose(fp);

			return false;
		}

		fclose(fp);
	}

	return true;
}

bool garden_truck::load_water(unsigned short* data_)
{
	cudaError_t status;

	status = cudaMemcpy(water, data_, water_total_amount, cudaMemcpyHostToHost);
	if (status != cudaSuccess) return false;

	return true;
}

void garden_truck::calculate_error_rate()
{
	bool ret = false;
	double err = 0.0;

	accumulated += nutrients_count * T;

#pragma omp parallel num_threads(T)
	{
		unsigned int fruit_index = omp_get_thread_num() * nutrients_count;
		for (int i = 0; i < nutrients_count; i++)
		{
			if (nutrients[i].label == fruits[fruit_index + i].label)
				true_count[omp_get_thread_num()]++;
			else
				false_count[omp_get_thread_num()]++;
		}
	}
}

bool garden_truck::get_error_rate()
{
	bool ret = false;
	double err = 0.0;

	for (int t = 0; t < T; t++)
		err += false_count[t];
	err = err / accumulated * 100;

	error_rate = err;

	if (err < best)
	{
		ret = true;
		best = err;
	}
	return ret;
}

void garden_truck::reset_error_rate()
{
	accumulated = 0;
	error_rate = DBL_MAX;
	memset(true_count, 0, sizeof(unsigned __int64) * MAX_CELL_NUM);
	memset(false_count, 0, sizeof(unsigned __int64) * MAX_CELL_NUM);
}

void garden_truck::move_trees_to_warehouse(char* warehouse_address)
{
	FILE* fp;
	fopen_s(&fp, warehouse_address, "wb");
	fwrite(Version, sizeof(char), 4, fp);	// Version
	fwrite(&T, sizeof(unsigned int), 1, fp);	// T (count of trees)	
	fwrite(&branches_count, sizeof(unsigned __int64), 1, fp);	// count of branches
	fwrite(&endpoints_count, sizeof(unsigned __int64), 1, fp);	// count of endpoints
	fwrite(trees, sizeof(unsigned __int64), T, fp);	// trees
	fwrite(branches, sizeof(struct cuda_branch), branches_count, fp);	// branches
	fwrite(&error_rate, sizeof(double), 1, fp);	// error rate (best)
	fwrite(twigs, sizeof(struct fig_twig), endpoints_count * MAX_TW_NUM, fp);	// twigs
	fclose(fp);
}

bool garden_truck::move_trees_from_warehouse(char* warehouse_address, bool do_harvest)
{
	bool ret = true, support_version = false;
	cudaError_t status;

	FILE* fp;
	errno_t err = fopen_s(&fp, warehouse_address, "rb");
	if (err != 0)
		return false;

	size_t r_size;
	char _version[4];
	r_size = fread(_version, sizeof(_version), 1, fp);
	if (r_size > 0)
	{
		if (_version == NULL || strstr(_version, "V") == NULL)
			support_version = false;
		else
		{
			Version = _version;
			support_version = true;
		}
	}
	else
	{
		return false;
	}

	unsigned int _tree_count;
	unsigned __int64 _branches_count;
	unsigned __int64 _endpoints_count;
	if (!support_version && fseek(fp, 0, 0) < 0)
	{
		printf("* Warning : FILE_READ_ERROR\n");
		return false;
	}
	fread(&_tree_count, sizeof(unsigned int), 1, fp);
	fread(&_branches_count, sizeof(unsigned __int64), 1, fp);
	fread(&_endpoints_count, sizeof(unsigned __int64), 1, fp);

	load_trees(_tree_count, _branches_count, _endpoints_count);	// 나무 구성

	fread(this->trees, sizeof(unsigned __int64), _tree_count, fp);
	cuda_branch *_branches = (cuda_branch *)malloc(sizeof(struct cuda_branch) * _branches_count);
	fread(_branches, sizeof(struct cuda_branch), _branches_count, fp);

	status = cudaMemcpy(this->branches, _branches, sizeof(struct cuda_branch) * _branches_count, cudaMemcpyHostToHost);
	free(_branches);

	if (status != cudaSuccess)
		ret = false;

	if (support_version)
	{
		if (strncmp(Version, "V001", 4) == 0)	// V001인 경우 error rate를 읽음
		{
			fread(&error_rate, sizeof(double), 1, fp);
		}
	}

	if (!do_harvest)	// harvest의 경우 twig을 load하지 않도록 함 (현재 메모리 문제 발생)
		fread(this->twigs, sizeof(struct fig_twig), _endpoints_count * MAX_TW_NUM, fp);

	fclose(fp);

	if (support_version)
		printf("# move trees from warehouse : %u, error rate : %.2f%%\n", _tree_count, error_rate);
	else
		printf("# move trees from warehouse : %u\n", _tree_count);

	return ret;
}

bool garden_truck::load_finest_fruits(fig_finest_fruit *fr, unsigned int fr_cnt)
{
	cudaError_t status;

	finest_fruits_count = fr_cnt;

	finest_fruits_total_size = sizeof(fig_finest_fruit) * nutrients_count;

	status = cudaMemcpy(finest_fruits, fr, finest_fruits_total_size, cudaMemcpyDeviceToHost);
	if (status != cudaSuccess) return false;

	return true;
}