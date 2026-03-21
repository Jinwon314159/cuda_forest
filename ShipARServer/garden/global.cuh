#pragma once

#include <omp.h>
#include <time.h>
#include <random>
#include <memory.h>
#include <Windows.h>
#include <assert.h>
#include <iostream>

// CUDA
#include "device_functions.h"
#include "cuda_runtime.h"
#include "driver_types.h"
#include "device_launch_parameters.h"
#pragma comment(lib, "cudart.lib")

//OpenCV
#include <opencv2\opencv.hpp>

//#define WATER_TEXTURE

#define GARDEN_PATH	"D:\\ShipAR_DATA"
#define COLOR_PATH "color\\color_%d.png"
#define DEPTH_PATH "depth\\depth_%d.dep"
#define TANGO_PATH "tango\\tango_%d.dep"
#define FRUIT_PATH "fruit\\fruit_%d.png"
#define PROB_PATH  "fruit\\fruit_%d.prob"
#define SALES_PATH "result\\sales.json"
#define SALES_SCORE_PATH "result\\sales.score.json"

#define MAX_TREE_NUM 10
#define MAX_CELL_NUM 28 // max number of classes
#define MAX_TW_NUM 200 // max number of features (split methods)
#define MAX_STREAM_NUM 24
#define NUTRIENTS_STEP 5000

#define BUCKET_WIDTH 320 //1280 // 512
#define BUCKET_HEIGHT 180 //720 // 424
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

