#pragma once
#include "global.cuh"

/*
Tools
*/
class garden_tools
{
public:
	garden_tools();
	~garden_tools();

	bool prepare(int t, int range_int_min, int range_int_max);

	//void clean();

	unsigned long core_count;

	int T;

	std::random_device *_rd_int[MAX_TREE_NUM];
	std::mt19937 *_gen_int[MAX_TREE_NUM];
	std::uniform_int_distribution<int> *_dist_int[MAX_TREE_NUM];
	std::random_device *_rd_float[MAX_TREE_NUM];
	std::mt19937 *_gen_float[MAX_TREE_NUM];
	std::uniform_real_distribution<float> *_dist_float[MAX_TREE_NUM];

	int rand_int(int t_idx);

	float rand_float(int t_idx);

	int in_count;
	cudaDeviceProp *prop;

	size_t get_total_global_mem(/*int index*/);

	size_t idle_memory();

	cudaStream_t stream[MAX_STREAM_NUM];
	int stream_count;

private:
	unsigned long getNumberOfProcessors();
};
