#include "garden.cuh"

texture<unsigned short, 1, cudaReadModeElementType> water_texture;
unsigned short *water = 0;

// 정원을 만들고 나무를 심는다.
void garden::build(garden_truck *tk, garden_greenhouse *gh, garden_tools *tl, fig_variety *v, unsigned int t)
{
	truck = tk;

	greenhouse = gh;

	tools = tl;

	variety = v;

	T = t;

	in_mem_size = tools->get_total_global_mem();

	// cuda 메모리에 기본 root 노드 T개를 할당한다.
	trees = (fig_tree**)malloc(sizeof(fig_tree*) * T);
	for (unsigned int t = 0; t < T; t++)
	{
		trees[t] = new fig_tree;
		trees[t]->plant(t, variety, tools);
	}

	buckets_count = 0;
	water_total_amount = 0;
	water = 0;
}

void garden::destroy()
{
	if (trees)
	{
		for (unsigned int t = 0; t < T; t++)
			delete trees[t];
		free(trees);
		trees = 0;
	}

	if (water) { cudaFree(water); water = 0; }
}

// 나무를 트럭에 싣는다.
bool garden::load_on_truck()
{
	/* load trees on cuda memory */
	cudaError_t status = cudaSuccess;

	// 1. prepare
	// 나무의 분량을 파악
	// get number of branches in each tree
	branches_count = 0;
	unsigned __int64 *num_branches = new unsigned __int64[T];
	for (unsigned int t = 0; t < T; ++t)
	{
		num_branches[t] = trees[t]->get_num_branches();
		branches_count += num_branches[t];
	}
	delete num_branches;

	// get number of leaves/nodes in each tree
	endpoints_count = 0;
	unsigned __int64 *num_endpoints = new unsigned __int64[T];
	for (unsigned int t = 0; t < T; ++t)
	{
		num_endpoints[t] = trees[t]->get_num_endpoints();
		endpoints_count += num_endpoints[t];
	}
	delete num_endpoints;

	// 분량 만큼 트럭을 준비
	truck->load_trees(T, branches_count, endpoints_count);


	// 2. dig out
	// 나무를 파내고 하나 씩 트럭에 싣는다
	// recursive하게 탐색하면서 branches, leaves, nodes가 동시에 할당되도록
	unsigned __int64 truck_branch_index = 0;
	unsigned __int64 truck_endpoint_index = 0;
	for (unsigned __int64 t = 0; t < T; ++t)
	{
		truck->trees[t] = truck_branch_index; // trunk트렁크 branch의 위치를 표기
		if (!trees[t]->dig_up_trees(truck->trees[t], truck, &truck_branch_index, &truck_endpoint_index))
			return false;
	}

	return true;
}

// greenhouse로 나무들을 옮긴다.
bool garden::move_to_greenhouse()
{
	cudaError_t status = cudaSuccess;

	load_on_truck();

	// 1. greenhouse의 땅을 판다
	if (!greenhouse->dig_up_land(T, branches_count, endpoints_count))
		return false;

	// 2. move
	// 이동
	status = cudaMemcpy(greenhouse->trees, truck->trees, truck->trees_total_size, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;
	status = cudaMemcpy(greenhouse->branches, truck->branches, truck->branches_total_size, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;
	status = cudaMemcpy(greenhouse->twigs, truck->twigs, truck->twigs_total_size, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;

	return true;
}

__device__ float get_h2o(
	unsigned short *water,
	unsigned short bucket_index,
	int x, int y)
{
	float ret = 0.0f;

	if (x < 0 || y < 0 || x > BUCKET_WIDTH - 1 || y > BUCKET_HEIGHT - 1)
		return (float)USHRT_MAX;

	size_t idx = BUCKET_WIDTH * BUCKET_HEIGHT * bucket_index + y * BUCKET_WIDTH + x;
	//ret = (float)water[idx];
	ret = (float)tex1Dfetch(water_texture, idx);

	if (ret <= 0.0f)
		ret = FLT_MIN; //0.000000000000000001f;

	return ret;
}

__device__ float get_response(
	fig_split_feature f,
	unsigned short *water,
	unsigned short bucket_index,
	unsigned short qx, unsigned short qy)
{
	float qval = get_h2o(water, bucket_index, qx, qy);

	int pux = qx + (int)(f.ux * BASE_DISTANCE / qval + 0.5f);
	int puy = qy + (int)(f.uy * BASE_DISTANCE / qval + 0.5f);

	int pvx = qx + (int)(f.vx * BASE_DISTANCE / qval + 0.5f);
	int pvy = qy + (int)(f.vy * BASE_DISTANCE / qval + 0.5f);

	float uval = get_h2o(water, bucket_index, pux, puy);
	float vval = get_h2o(water, bucket_index, pvx, pvy);

	return uval - vval;
}

// 병렬 기준: nutrient
__global__ void absorb(
	unsigned int tree_index,
	unsigned __int64 trunk_index,
	fig_nutrient *nutrients, unsigned int nu_start, unsigned int nu_end, unsigned __int64 nutrients_count,
	cuda_branch *branches,
	unsigned short *water,
	fig_fruit *fruits)
{
	unsigned int nutrient_index = nu_start + blockIdx.x;
	if (nutrient_index >= nu_end) return;
	unsigned int fruit_index = tree_index * nutrients_count + nutrient_index;
	unsigned __int64 branch_index = trunk_index;

	while (1)
	{
		// children이 없으면(ULLONG_MAX) endpoint 임
		if (branches[branch_index].left_child_index == ULLONG_MAX)
		{
			fruits[fruit_index].branch_index = branch_index;
			fruits[fruit_index].endpoint_index = branches[branch_index].endpoint_index;

			if (tree_index == 1 && fruits[fruit_index].endpoint_index != 1)
			{
				int t = 0;
				t = 1;
			}

			unsigned __int64 max_value = 0;
			unsigned int label = 0;
			for (unsigned int i = 0; i < MAX_CELL_NUM; i++)
			{
				if (branches[branch_index].cells[i] > max_value)
				{
					max_value = branches[branch_index].cells[i];
					label = i;
				}
			}
			fruits[fruit_index].label = label;

			//printf("absorb - %d - <%d> fruits[%d] - branch_index:%d, endpoint_index:%d, result_label:%d\n", nutrient_index, nutrients[nutrient_index].label, fruit_index, fruits[fruit_index].branch_index, fruits[fruit_index].endpoint_index, fruits[fruit_index].label);
			break;
		}
		// children이 있으면 더 내려가야 한다.
		else
		{
			float response = get_response(branches[branch_index].split_feature, water, nutrients[nutrient_index].bucket_index, nutrients[nutrient_index].x, nutrients[nutrient_index].y);
			if (response < branches[branch_index].threshold)
				branch_index = branches[branch_index].left_child_index;
			else
				branch_index = branches[branch_index].left_child_index + 1;
		}
	}
}

// 병렬 기준: nutrient
__global__ void pickout(
	unsigned int T,
	fig_nutrient *nutrients, unsigned int nu_start, unsigned int nu_end, unsigned __int64 nutrients_count,
	cuda_branch *branches, unsigned __int64 branches_count,
	fig_twig *twigs, unsigned __int64 endpoints_count,
	unsigned short *water,
	fig_fruit *fruits,
	fig_finest_fruit *finest_fruits)
{
	unsigned int nutrient_index = nu_start + blockIdx.x;
	if (nutrient_index >= nu_end) return;
	fig_nutrient nutrient = nutrients[nutrient_index];

	unsigned int fruit_index = 0;
	double probs[MAX_CELL_NUM] = { 0 };
	unsigned long long total_counts = 1;
	unsigned long long branch_index = 0;

	for (int i = 0; i < T; i++)
	{
		fruit_index = nutrient_index + i * nutrients_count;
		branch_index = fruits[fruit_index].branch_index;
		total_counts = branches[branch_index].total_nutrients;

		for (int j = 0; j < MAX_CELL_NUM; j++)
		{
			double prob = (double)branches[branch_index].cells[j] / (double)total_counts;
			probs[j] += prob;
		}
	}

	for (int i = 0; i < MAX_CELL_NUM; i++)
	{
		probs[i] /= T;
	}

	// MAX probability 찾기
	double max_probability = 0;
	unsigned long long max_index = -1;
	for (int i = 0; i < MAX_CELL_NUM; i++)
	{
		if (probs[i] > max_probability)
		{
			max_probability = probs[i];
			max_index = i;
		}
	}

	finest_fruits[nutrient_index].x = nutrient.x;
	finest_fruits[nutrient_index].y = nutrient.y;
	finest_fruits[nutrient_index].probability = max_probability;
	finest_fruits[nutrient_index].label = max_index;
}

// 병렬 기준: twig
__global__ void sum_responses(
	unsigned int tree_index,
	fig_nutrient *nutrients, unsigned int nu_start, unsigned int nu_end, unsigned int nutrients_count,
	fig_twig *twigs, unsigned __int64 tw_start,
	unsigned short *water,
	fig_fruit * fruits)
{
	unsigned __int64 twig_index = tw_start + blockIdx.x;
	if (twigs[twig_index].left_total_nutrients + twigs[twig_index].right_total_nutrients != 0) return; // 이미 결정되어 있다는 뜻
	unsigned int fruit_index = tree_index * nutrients_count;

	for (unsigned int i = nu_start; i < nu_end; i++)
	{
		if (fruits[fruit_index + i].endpoint_index == (unsigned __int64)(twig_index / MAX_TW_NUM))
		{
			float response = get_response(twigs[twig_index].split_feature, water, nutrients[i].bucket_index, nutrients[i].x, nutrients[i].y);
			twigs[twig_index].threshold_sum[nutrients[i].label] += response;
			twigs[twig_index].threshold_nutrients[nutrients[i].label]++;
			//printf("twig_index:%d, nutrient_index:%d, label:%d, response:%f, sum:%f, cnt:%d\n", twig_index, i, nutrients[i].label, response, twigs[twig_index].threshold_sum[nutrients[i].label], twigs[twig_index].threshold_nutrients[nutrients[i].label]);
		}
	}
}

// 병렬 기준: twig
__global__ void decide_threshold(
	fig_twig *twigs, unsigned __int64 tw_start)
{
	unsigned __int64 twig_index = tw_start + blockIdx.x;
	if (twigs[twig_index].left_total_nutrients + twigs[twig_index].right_total_nutrients != 0) return; // 이미 결정되어 있다는 뜻

#if 1
#if 1
	unsigned int min_index = 0, max_index = 0;
	double mean[MAX_CELL_NUM] = { 0.0 };
	for (unsigned int i = 0; i < MAX_CELL_NUM; i++)
	{
		if (twigs[twig_index].threshold_sum[i] != 0 && twigs[twig_index].threshold_nutrients[i] != 0)
			mean[i] = twigs[twig_index].threshold_sum[i] / twigs[twig_index].threshold_nutrients[i];
		if (mean[i] < mean[min_index])
			min_index = i;
		if (mean[i] > mean[max_index])
			max_index = i;
	}
#if 0
	unsigned int step = 5;
	unsigned int rest = 0;
	rest = clock() % step;
#endif
	twigs[twig_index].threshold = mean[min_index] + (mean[max_index] - mean[min_index]) / 2; // / step * rest;
#else
	twigs[twig_index].threshold = twigs[twig_index].threshold_sum / twigs[twig_index].total_nutrients;
#endif
#else
	twigs[twig_index].threshold = (twigs[twig_index].min_threshold + twigs[twig_index].max_threshold) / 2;
	//twigs[twig_index].threshold = twigs[twig_index].min_threshold + (twigs[twig_index].max_threshold - twigs[twig_index].min_threshold) / MAX_TW_NUM * (twig_index % MAX_TW_NUM);
#endif
	//printf("twig_index:%d, min threshold:%f, max threshold:%f, threshold:%f\n", twig_index, twigs[twig_index].min_threshold, twigs[twig_index].max_threshold, twigs[twig_index].threshold);
}

// 병렬 기준: twig
__global__ void store(
	unsigned int tree_index,
	fig_nutrient *nutrients, unsigned int nu_start, unsigned int nu_end, unsigned int nutrients_count,
	fig_twig *twigs, unsigned __int64 tw_start,
	unsigned short *water,
	fig_fruit * fruits)
{
	unsigned __int64 twig_index = tw_start + blockIdx.x;
	unsigned int fruit_index = tree_index * nutrients_count;

	for (unsigned int i = nu_start; i < nu_end; i++)
	{
		if (fruits[fruit_index + i].endpoint_index == (unsigned __int64)(twig_index / MAX_TW_NUM))
		{
			//printf("twig_index:%d, fruit_index:%d, endpoint_index:%d\n", twig_index, fruit_index + i, fruit->endpoint_index);

			// evaluation을 먼저해서 left의 cells를 채울지 right의 cells를 채울지 결정한다.
			float response = get_response(twigs[twig_index].split_feature, water, nutrients[i].bucket_index, nutrients[i].x, nutrients[i].y);
			if (response < twigs[twig_index].threshold)
			{
				twigs[twig_index].left_total_nutrients++;
				twigs[twig_index].left_cells[nutrients[i].label]++;
			}
			else
			{
				twigs[twig_index].right_total_nutrients++;
				twigs[twig_index].right_cells[nutrients[i].label]++;
			}
		}
	}
}

// 비료를 주고 나무를 키운다.
bool garden::give(garden_truck *truck)
{
	bool ret = true;

	cudaError_t status = cudaSuccess;

	// pour buckets of water
	if (!this->pour(truck)) return false;

	// nutrients를 cuda의 메모리로 올리고 
	if (!greenhouse->give(truck->nutrients, truck->nutrients_count)) return false;
	if (!greenhouse->fruit_box(truck->nutrients_count)) return false;

	for ( int t = 0; t < T; t++)
	{
		unsigned int nu_step = tools->prop->maxThreadsPerMultiProcessor * tools->prop->multiProcessorCount; // greenhouse->nutrients_count; // tools->prop->maxThreadsPerMultiProcessor; // 

		// 1. absorb: 각 nutrient의 endpoint를 찾음
		// label 결과는 여기서 받는게 나을듯
		for (unsigned int nu_start = 0; nu_start < greenhouse->nutrients_count; nu_start += nu_step)
		{
			unsigned int nu_end = (nu_start + nu_step < greenhouse->nutrients_count) ? nu_start + nu_step : greenhouse->nutrients_count;
			dim3 block_dim(nu_end - nu_start, 1, 1);
			dim3 thread_dim(1, 1, 1);
			absorb << <block_dim, thread_dim >> > (
				t,
				trees[t]->trunk_index,
				greenhouse->nutrients, nu_start, nu_end, greenhouse->nutrients_count,
				greenhouse->branches,
				greenhouse->water,
				greenhouse->fruits);
		}

		status = cudaDeviceSynchronize();
		if (status != cudaSuccess) {
			fprintf(stderr, "cudaDeviceSynchronize returned error code %d!\n", status);
			ret = false;
		}

		unsigned int tw_step = tools->prop->maxThreadsPerMultiProcessor * tools->prop->multiProcessorCount / 2; // nu_step;
		nu_step = tw_step / 2;
		unsigned __int64 twigs_count = trees[t]->get_num_endpoints() * MAX_TW_NUM;
		unsigned __int64 tw_cumulative = 0;
		for (int i = 0; i < t; i++)
			tw_cumulative += trees[i]->get_num_endpoints() * MAX_TW_NUM;

		for (unsigned __int64 tw_start = tw_cumulative; tw_start < tw_cumulative + twigs_count; tw_start += tw_step)
		{
			unsigned __int64 tw_end = (tw_start + tw_step < tw_cumulative + twigs_count) ? tw_start + tw_step : tw_cumulative + twigs_count;
			dim3 block_dim(tw_end - tw_start, 1, 1);
			dim3 thread_dim(1, 1, 1);

			// 2. decide response: to decide min/max response of twigs
			for (unsigned int nu_start = 0; nu_start < greenhouse->nutrients_count; nu_start += nu_step)
			{
				unsigned int nu_end = (nu_start + nu_step < greenhouse->nutrients_count) ? nu_start + nu_step : greenhouse->nutrients_count;
				sum_responses << <block_dim, thread_dim >> > (
					t,
					greenhouse->nutrients, nu_start, nu_end, greenhouse->nutrients_count,
					greenhouse->twigs, tw_start,
					greenhouse->water,
					greenhouse->fruits);
			}

			status = cudaDeviceSynchronize();
			if (status != cudaSuccess) {
				fprintf(stderr, "cudaDeviceSynchronize returned error code %d!\n", status);
				ret = false;
			}

			// 3. decide threshold: to decide threshold of twigs
			decide_threshold << <block_dim, thread_dim >> > (
				greenhouse->twigs, tw_start);

			status = cudaDeviceSynchronize();
			if (status != cudaSuccess) {
				fprintf(stderr, "cudaDeviceSynchronize returned error code %d!\n", status);
				ret = false;
			}

			// 4. store: store nutrients to cells of each endpoint twig
#pragma omp parallel for
			for (int i = 0; i < tools->stream_count; i++)
				cudaStreamCreate(&tools->stream[i]);
			nu_step = greenhouse->nutrients_count;
			unsigned int nutrients_per_stream = (unsigned int)(nu_step / tools->stream_count) + 1;
			for (unsigned int nu = 0; nu < greenhouse->nutrients_count; nu += nu_step)
			{
#pragma omp parallel for
				for (int s = 0; s < tools->stream_count; s++)
				{
					//unsigned int nu_start = nu + omp_get_thread_num() * stream_step;
					unsigned int nu_start = nu + s * nutrients_per_stream;
					if (nu_start < greenhouse->nutrients_count)
					{
						unsigned int nu_end = (nu_start + nutrients_per_stream < greenhouse->nutrients_count) ? nu_start + nutrients_per_stream : greenhouse->nutrients_count;
						//store << <block_dim, thread_dim, 0, tools->stream[omp_get_thread_num()] >> > (
						store << <block_dim, thread_dim, 0, tools->stream[s] >> > (
							t,
							greenhouse->nutrients, nu_start, nu_end, greenhouse->nutrients_count,
							greenhouse->twigs, tw_start,
							greenhouse->water,
							greenhouse->fruits);
					}
				};
#pragma omp parallel for
				for (int s = 0; s < tools->stream_count; s++)
				{
					//status = cudaStreamSynchronize(tools->stream[omp_get_thread_num()]);
					status = cudaStreamSynchronize(tools->stream[s]);
					if (status != cudaSuccess) {
						fprintf(stderr, "cudaStreamSynchronize returned error code %d!\n", status);
						ret = false;
					}
				};
			}
#pragma omp parallel for
			for (int i = 0; i < tools->stream_count; i++)
				cudaStreamDestroy(tools->stream[i]);
		}
	};

	// 3. load fruits
	if (!truck->load_fruits(greenhouse->fruits, greenhouse->fruits_count)) return false;

#pragma omp parallel num_threads(T)
	//for (int t = 0; t < T; t++)
	{
		unsigned int fruit_index = omp_get_thread_num() * truck->nutrients_count;
		//unsigned int fruit_index = t * truck->nutrients_count;
		// nutrients 개수 만큼 loop
		for (unsigned int i = 0; i < truck->nutrients_count; i++)
		{
			unsigned __int64 branch_index = truck->fruits[fruit_index + i].branch_index;
			while (1)
			{
				truck->branches[branch_index].total_nutrients++;
				truck->branches[branch_index].cells[truck->nutrients[i].label]++;
				if (truck->branches[branch_index].parent_index != ULLONG_MAX)
					branch_index = truck->branches[branch_index].parent_index;
				else
					break;
			}
		}
	}

	return ret;
}

// 정원으로 다시 옮긴다.
bool garden::move_to_garden()
{
	cudaError_t status = cudaSuccess;

	status = cudaMemcpy(truck->trees, greenhouse->trees, greenhouse->trees_total_size, cudaMemcpyHostToDevice);
	//status = cudaMemcpy(truck->branches, greenhouse->branches, greenhouse->branches_total_size, cudaMemcpyHostToDevice);
	status = cudaMemcpy(truck->twigs, greenhouse->twigs, greenhouse->twigs_total_size, cudaMemcpyHostToDevice);

	return true;
}

// 정원에 다시 심는다.
bool garden::replant()
{
	bool ret = true;

#pragma omp parallel num_threads(T)
	//for (int t = 0; t < this->T; t++)
	{
		//if (!trees[t]->replant(this->truck))
		if (!trees[omp_get_thread_num()]->replant(this->truck))
			ret = false;
	};

	return ret;
}

// 비료를 주고 열매를 수확한다.
bool garden::harvest(garden_truck *truck)
{
	bool ret = true;

	cudaError_t status = cudaSuccess;

	// pour buckets of water
	if (!this->pour(truck)) return false;

	// nutrients를 cuda의 메모리로 올리고 
	if (!greenhouse->give(truck->nutrients, truck->nutrients_count)) return false;
	if (!greenhouse->fruit_box(truck->nutrients_count)) return false;
	if (!greenhouse->finest_fruit_box(truck->nutrients_count)) return false;

	cudaEvent_t start, stop;
	float elapsedTime = 0;
	status = cudaEventCreate(&start);
	if (status != cudaSuccess)
	{
		return false;
	}
	status = cudaEventCreate(&stop);
	if (status != cudaSuccess)
	{
		return false;
	}
	status = cudaEventRecord(start, 0);
	if (status != cudaSuccess)
	{
		return false;
	}

	for (unsigned int t = 0; t < T; t++)
	{
		// 1. absorb: 각 nutrient의 endpoint를 찾음
		// label 결과는 여기서 받는게 나을듯
		unsigned int step = tools->prop->maxThreadsPerMultiProcessor;	// truck->nutrients_total_size;
		for (unsigned int nu_start = 0; nu_start < greenhouse->nutrients_count; nu_start += step)
		{
			unsigned int nu_end = (nu_start + step < greenhouse->nutrients_count) ? nu_start + step : greenhouse->nutrients_count;
			dim3 absorb_block_dim(nu_end - nu_start, 1, 1);
			dim3 absorb_thread_dim(1, 1, 1);
			absorb << <absorb_block_dim, absorb_thread_dim >> > (
				t,
				trees[t]->trunk_index,
				greenhouse->nutrients, nu_start, nu_end, greenhouse->nutrients_count,
				greenhouse->branches, 
				greenhouse->water,
				greenhouse->fruits);

			status = cudaGetLastError();
			if (status != cudaSuccess) {
				fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(status));
				return false;
			}

			// cudaDeviceSynchronize waits for the kernel to finish, and returns
			// any errors encountered during the launch.
			status = cudaDeviceSynchronize();
			if (status != cudaSuccess) {
				fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", status);
				return false;
			}
		}
	}
	status = cudaEventRecord(stop, 0);
	if (status != cudaSuccess)
	{
		return false;
	}
	status = cudaEventSynchronize(stop);
	if (status != cudaSuccess)
	{
		return false;
	}
	status = cudaEventElapsedTime(&elapsedTime, start, stop);
	if (status != cudaSuccess)
	{
		return false;
	}
	printf("# ElapsedTime1 : %3.1f ms\n", elapsedTime);

	if (!truck->load_fruits(greenhouse->fruits, greenhouse->fruits_count)) return false;

	status = cudaEventRecord(start, 0);
	if (status != cudaSuccess)
	{
		return false;
	}
	// 2. pick out: 각 fruit별 probability 계산 및 label 선정
	unsigned int step = tools->prop->maxThreadsPerMultiProcessor;	// truck->nutrients_total_size;
	for (unsigned int nu_start = 0; nu_start < greenhouse->nutrients_count; nu_start += step)
	{
		unsigned int nu_end = (nu_start + step < greenhouse->nutrients_count) ? nu_start + step : greenhouse->nutrients_count;
		dim3 pickout_block_dim(nu_end - nu_start, 1, 1);
		dim3 pickout_thread_dim(1, 1, 1);
		pickout << <pickout_block_dim, pickout_thread_dim >> > (
			T,
			greenhouse->nutrients, nu_start, nu_end, greenhouse->nutrients_count,
			greenhouse->branches, greenhouse->branches_count,
			greenhouse->twigs, greenhouse->endpoints_count,
			greenhouse->water,
			greenhouse->fruits,
			greenhouse->finest_fruits);

		status = cudaGetLastError();
		if (status != cudaSuccess) {
			fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(status));
			return false;
		}

		// cudaDeviceSynchronize waits for the kernel to finish, and returns
		// any errors encountered during the launch.
		status = cudaDeviceSynchronize();
		if (status != cudaSuccess) {
			fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", status);
			return false;
		}
	}
	status = cudaEventRecord(stop, 0);
	if (status != cudaSuccess)
	{
		return false;
	}
	status = cudaEventSynchronize(stop);
	if (status != cudaSuccess)
	{
		return false;
	}
	status = cudaEventElapsedTime(&elapsedTime, start, stop);
	if (status != cudaSuccess)
	{
		return false;
	}
	printf("# ElapsedTime2 : %3.1f ms\n", elapsedTime);
	if (!truck->load_finest_fruits(greenhouse->finest_fruits, greenhouse->finest_fruits_count)) return false;

	return ret;
}

bool garden::replant_from_truck(garden_truck *tk, garden_greenhouse *gh, garden_tools *tl, fig_variety *v, unsigned int t)
{
	bool ret = true;

	destroy();

	// replant_trunk_start_
	truck = tk;
	greenhouse = gh;
	tools = tl;
	variety = v;
	T = t;

	in_mem_size = tools->get_total_global_mem();

	// cuda 메모리에 기본 root 노드 T개를 할당한다.
	trees = (fig_tree**)malloc(sizeof(fig_tree*)* T);
	for (unsigned int t = 0; t < T; t++)
	{
		trees[t] = new fig_tree;
		trees[t]->plant(t, truck, variety, tools);
	}
	// _replant_trunk_end

#pragma omp parallel num_threads(T)
	{
		if (!trees[omp_get_thread_num()]->replant_no_split(this->truck))
			ret = false;
	}

	return ret;
}

bool garden::pour(garden_truck *truck)
{
	cudaError_t status;

	if (buckets_count != truck->buckets_count)
	{
		buckets_count = truck->buckets_count;

		water_total_amount = truck->water_total_amount;

		if (water) {
			cudaUnbindTexture(water_texture);
			cudaFree(water);
			water = 0;
		}

		status = cudaMalloc(&water, water_total_amount);
		if (status != cudaSuccess) return false;

		cudaChannelFormatDesc channelDesc = cudaCreateChannelDesc(16, 0, 0, 0, cudaChannelFormatKindUnsigned);
		status = cudaBindTexture(NULL, &water_texture, water, &channelDesc);
		if (status != cudaSuccess) return false;
	}

	status = cudaMemcpy(water, truck->water, water_total_amount, cudaMemcpyHostToDevice);
	if (status != cudaSuccess) return false;

	return true;
}
