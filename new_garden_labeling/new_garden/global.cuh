#pragma once

#include <omp.h>
#include <random>
#include <memory.h>
#include <Windows.h>
#include <assert.h>
#include <iostream>
#include "device_functions.h"
#include "cuda_runtime.h"
#include "driver_types.h"
#include "device_launch_parameters.h"
#pragma comment(lib, "cudart.lib")

#define MAX_TREE_NUM 32
#define MAX_CELL_NUM 28 // max number of classes
#define MAX_TW_NUM 100 // max number of features (split methods)

#define BUCKET_WIDTH 512
#define BUCKET_HEIGHT 424
#define BUCKET_SIZE BUCKET_WIDTH * BUCKET_HEIGHT
#define BASE_DISTANCE 2000.0f

// pixel data
struct fig_nutrient
{
	unsigned __int64 x; // position x
	unsigned __int64 y; // position y
	unsigned __int64 label;
	unsigned __int64 bucket_index; // frame index
};

struct threshold_range
{
	double min;
	double max;
};

// 품종
// http://www.gardeningknowhow.com/edible/fruits/figs/different-types-of-fig-trees.htm
struct fig_variety
{
	unsigned __int64 nc; // number of classes
	unsigned __int64 tw; // number of twigs (random test)
	// "The survival of the fittest"에 의해 가지치기 되는 조건 2가지
	unsigned __int64 an; // 몇 개 absorb 이후부터 가지치기 시작 하는가?
	double ig; // "information gain"을 봐서 어느 정도 이상일 때 적합한 가지인지 판단 하는가?
	unsigned __int64 nl; // 몇 개 absorb 이후부터 (노답 일 경우) 리셋 하는가?
	threshold_range range; // 처음에는 -65535 ~ 65535 사이의 값으로 설정한다
	unsigned __int64 grow;
};

// feature & response
// http://forestry.oxfordjournals.org/content/29/1/22.abstract
struct fig_split_feature
{
	// features
	__int64 ux;
	__int64 uy;
	__int64 vx;
	__int64 vy;
};

// branch memory on cuda
struct cuda_branch
{
	unsigned __int64 total_nutrients;
	unsigned __int64 cells[MAX_CELL_NUM];
	unsigned __int64 parent_index;
	unsigned __int64 left_child_index;
	unsigned __int64 endpoint_index;
	double threshold;
	fig_split_feature split_feature;
};

struct fig_fruit
{
	unsigned __int64 label;
	unsigned __int64 branch_index;
	unsigned __int64 endpoint_index;
};

struct fig_finest_fruit
{
	unsigned __int64 x;
	unsigned __int64 y;
	unsigned __int64 label;
	double probability;
};

struct fig_twig
{
	unsigned __int64 left_total_nutrients;
	unsigned __int64 left_cells[MAX_CELL_NUM];
	unsigned __int64 right_total_nutrients;
	unsigned __int64 right_cells[MAX_CELL_NUM];
	fig_split_feature split_feature; // selected feature
	double threshold; // selected threshold
#if 1
#if 1
	double threshold_sum[MAX_CELL_NUM];
	unsigned __int64 threshold_nutrients[MAX_CELL_NUM];
#else
	double threshold_sum;
	unsigned __int64 total_nutrients;
#endif
#else
	double min_threshold;
	double max_threshold;
#endif
};

struct ThreadParam
{
	void* g;
	void* m;
	void* f;
};

#include "tools.cuh"
#include "truck.cuh"

/*
Truck
*/
class garden_truck
{
public:
	garden_truck();
	~garden_truck();

	char *Version;	// version of truck

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

	unsigned int branches_count;
	unsigned int endpoints_count;
	size_t trees_total_size;
	size_t branches_total_size;
	size_t twigs_total_size;
	unsigned __int64 *trees;
	cuda_branch *branches;
	fig_twig *twigs;
	bool load_trees(unsigned int tr_cnt, unsigned int br_cnt, unsigned int ep_cnt);

	unsigned int buckets_count;
	size_t water_total_amount;
	unsigned short *water;
	bool load_water(int start_index, int end_index);
	bool load_water(unsigned short* data_);

	unsigned __int64 true_count[MAX_CELL_NUM];
	unsigned __int64 false_count[MAX_CELL_NUM];
	unsigned __int64 accumulated;
	double best;
	double error_rate;
	void calculate_error_rate();
	bool get_error_rate();
	void reset_error_rate();

	bool do_harvest = false;
	void move_trees_to_warehouse(char* warehouse_address);	// store trees at warehouse
	bool move_trees_from_warehouse(char* warehouse_address, bool do_harvest);	// take out trees from warehouse
};

#include "greenhouse.cuh"
