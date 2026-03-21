#include "truck.cuh"

garden_truck::garden_truck()
{
	Version[0] = 'V';
	Version[1] = '0';
	Version[2] = '0';
	Version[3] = '1';
	Version[4] = 0;

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

	best = DBL_MAX;
	reset_error_rate();
}

garden_truck::~garden_truck()
{
	cudaError_t status = cudaSuccess;

	if (nutrients) { cudaFreeHost(nutrients); nutrients = 0; }
	if (fruits) { cudaFreeHost(fruits); fruits = 0; }
	if (finest_fruits) { cudaFreeHost(finest_fruits); finest_fruits = 0; }

	if (trees) { cudaFreeHost(trees); trees = 0; }
	if (branches) { cudaFreeHost(branches); branches = 0; }
	if (twigs) { cudaFreeHost(twigs); twigs = 0; }
	
	if (water) { cudaFreeHost(water); water = 0; }
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

	if (nutrients_count != nu_cnt)
	{
		nutrients_count = nu_cnt;

		nutrients_total_size = sizeof(fig_nutrient) * nutrients_count;

		if (nutrients) { cudaFreeHost(nutrients); nutrients = 0; }

		status = cudaHostAlloc(&nutrients, nutrients_total_size, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	status = cudaMemcpy(nutrients, nu, nutrients_total_size, cudaMemcpyHostToHost);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_truck::load_fruits(fig_fruit *fr, unsigned int fr_cnt)
{
	cudaError_t status;

	if (fruits_count != fr_cnt)
	{
		fruits_count = fr_cnt;

		fruits_total_size = sizeof(fig_fruit) * nutrients_count * T;

		if (fruits) { cudaFreeHost(fruits); fruits = 0; }

		status = cudaHostAlloc(&fruits, fruits_total_size, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	status = cudaMemcpy(fruits, fr, fruits_total_size, cudaMemcpyDeviceToHost);
	if (status != cudaSuccess) return false;

	return true;
}

bool garden_truck::load_water(char* session_path, int start_index, int end_index)
{
	cudaError_t status;

	unsigned int bucket_size = sizeof(unsigned short)* BUCKET_SIZE;

	if (buckets_count != end_index - start_index)
	{
		buckets_count = end_index - start_index;

		water_total_amount = bucket_size * buckets_count;

		if (water) { cudaFreeHost(water); water = 0; }

		status = cudaHostAlloc(&water, water_total_amount, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	for (int i = start_index; i < end_index; i++)
	{
		// depth file
		char depth_file_path[256] = { 0 };

		if (!this->do_harvest)
			sprintf(depth_file_path, "%s\\%s\\"DEPTH_PATH, GARDEN_PATH, session_path, i);
		else
			sprintf(depth_file_path, "%s\\%s\\"TANGO_PATH, GARDEN_PATH, session_path, i);

		FILE* fp;
		errno_t err = fopen_s(&fp, depth_file_path, "rb");
		if (err != 0)
			return false;

		int count = BUCKET_WIDTH * BUCKET_HEIGHT;
		if (count != fread(water + count * (i - start_index), sizeof(unsigned short), count, fp))
		{
			std::cout << "Error: fill_water() file read fail!" << std::endl;
			fclose(fp);

			return false;
		}

		fclose(fp);

#if 0
		if (this->do_harvest)
		{
			cv::Mat img = cv::Mat(BUCKET_HEIGHT, BUCKET_WIDTH, CV_16UC1, water).clone();
			cv::imshow("tango", img);
			cv::waitKey(0);
			img.release();
		}
#endif
	}

	return true;
}

void garden_truck::accumulate_error_rate()
{
	bool ret = false;
	double err = 0.0;

	accumulated += nutrients_count * T;

#pragma omp parallel for
	for (int t = 0; t < T; t++)
	{
		//unsigned int fruit_index = omp_get_thread_num() * nutrients_count;
		unsigned int fruit_index = t * nutrients_count;
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
	memset(true_count, 0, sizeof(unsigned __int64) * MAX_TREE_NUM);
	memset(false_count, 0, sizeof(unsigned __int64) * MAX_TREE_NUM);
}

void garden_truck::move_trees_to_warehouse(char* warehouse_address)
{
	FILE* fp;
	errno_t err = -1;
	while (err != 0)
	{
		err = fopen_s(&fp, warehouse_address, "wb");
		Sleep(10);
	}

	size_t len1 = 0, len2 = 0;

	fwrite(Version, sizeof(char), 4, fp);	// Version
	fwrite(&T, sizeof(unsigned int), 1, fp);	// T (count of trees)	
	fwrite(&branches_count, sizeof(unsigned __int64), 1, fp);	// count of branches
	fwrite(&endpoints_count, sizeof(unsigned __int64), 1, fp);	// count of endpoints
	fwrite(trees, sizeof(unsigned __int64), T, fp);	// trees
	
	//printf("writing branches...\n");
	len1 = branches_count;
	//printf("%d", branches_count);
	for (unsigned long long i = 0; i < len1; i++)
	{
		len2 += fwrite(&branches[i], sizeof(cuda_branch), 1, fp);	// branches
		//printf(".");
	}
	//printf("\n");
	if (len1 != len2)
		printf("something's gone wrong.\n");

	fwrite(&error_rate, sizeof(double), 1, fp);	// error rate (best)

	fflush(fp);

	//printf("writing twigs...\n");
	len1 = MAX_TW_NUM * endpoints_count;
	len2 = 0;
	//printf("%d", endpoints_count);
	for (unsigned long long i = 0; i < len1; i += MAX_TW_NUM)
	{
		len2 += fwrite(&twigs[i], sizeof(fig_twig), MAX_TW_NUM, fp);	// twigs
		//printf(".");
	}
	//printf("\n");
	if (len1 != len2)
		printf("something's gone wrong.\n");

	fflush(fp);
	fclose(fp);
	//printf("writing ended\n");

}

unsigned int garden_truck::move_trees_from_warehouse(char* warehouse_address, bool do_harvest)
{
	bool support_version = false;
	cudaError_t status;

	FILE* fp;
	errno_t err = fopen_s(&fp, warehouse_address, "rb");
	if (err != 0)
		return 0;

	size_t r_size;
	char _version[5] = { 0 };
	r_size = fread(_version, sizeof(char), 4, fp);
	if (r_size > 0)
	{
		if (_version == NULL || strncmp(_version, "V001", 4) != 0)
			support_version = false;
		else
		{
			strcpy(Version, _version);
			support_version = true;
		}
	}
	else
		return 0;

	unsigned int _tree_count;
	unsigned __int64 _branches_count;
	unsigned __int64 _endpoints_count;
	if (!support_version && fseek(fp, 0, 0) < 0)
	{
		printf("* Warning : FILE_READ_ERROR\n");
		return 0;
	}
	fread(&_tree_count, sizeof(unsigned int), 1, fp);
	fread(&_branches_count, sizeof(unsigned __int64), 1, fp);
	fread(&_endpoints_count, sizeof(unsigned __int64), 1, fp);

	load_trees(_tree_count, _branches_count, _endpoints_count);	// 나무 구성

	size_t len = fread(this->trees, sizeof(unsigned __int64), _tree_count, fp);
	printf("len: %d\n", len);

	cuda_branch *_branches = (cuda_branch *)malloc(sizeof(cuda_branch) * _branches_count);
	for (unsigned long long i = 0; i < branches_count; i++)
	{
		fread(&_branches[i], sizeof(struct cuda_branch), 1, fp);
	}
	memcpy(this->branches, _branches, sizeof(cuda_branch) * _branches_count);
	free(_branches);

	if (support_version)
	{
		if (strncmp(Version, "V001", 4) == 0)	// V001인 경우 error rate를 읽음
		{
			fread(&error_rate, sizeof(double), 1, fp);
			this->best = this->error_rate;
		}
	}

	size_t len1 = _endpoints_count * MAX_TW_NUM;
	size_t len2 = 0;
	//if (!do_harvest)	// harvest의 경우 twig을 load하지 않도록 함 (현재 메모리 문제 발생)
	{
		for (int i = 0; i < _endpoints_count; i++)
			len2 += fread(&this->twigs[i * MAX_TW_NUM], sizeof(fig_twig), MAX_TW_NUM, fp);

		if (len1 != len2)
		{
			printf("something's wrong.\n");
			_tree_count = 0;
		}
	}

	if (support_version)
		printf("# move trees from warehouse : %u, error rate : %.7f%%\n", _tree_count, error_rate);
	else
		printf("# move trees from warehouse : %u\n", _tree_count);

	fclose(fp);

	return _tree_count;
}

bool garden_truck::load_finest_fruits(fig_finest_fruit *fr, unsigned int fr_cnt)
{
	cudaError_t status;

	if (finest_fruits_count != fr_cnt)
	{
		finest_fruits_count = fr_cnt;

		finest_fruits_total_size = sizeof(fig_finest_fruit)* nutrients_count;

		if (finest_fruits) { cudaFreeHost(finest_fruits); finest_fruits = 0; }

		status = cudaHostAlloc(&finest_fruits, finest_fruits_total_size, cudaHostAllocDefault);
		if (status != cudaSuccess) return false;
	}

	status = cudaMemcpy(finest_fruits, fr, finest_fruits_total_size, cudaMemcpyDeviceToHost);
	if (status != cudaSuccess) return false;

	return true;
}