//////////////////////////////////////////////
// Now learn this lesson from the fig tree: //
// As soon as its twigs get tender          //
// and its leaves come out,                 //
// you know that summer is near.            //
//                          - Matthew 24:32 //
//////////////////////////////////////////////

#pragma once

#include "global.cuh"
#include "fig_branch.cuh"
#include "fig_tree.cuh"
#include "mineral.cuh" // factory 존재하면 지워도 될 듯
#include "factory.cuh"
#include "js_mart.cuh"

// variable(가변) memory size의 ORF를 구성해서 제한 없이 무럭무럭 자라도록 한다.

// 아직 split되지 않은 (leaf) node에서는 random test가 hyper parameters (alpha, beta)를 충족하기 전까지 계속 일어나야 한다.

class garden
{
public:
	garden(){
		truck = 0;
		greenhouse = 0;
		tools = 0;
		trees = 0;

		branches_count = 0;
		endpoints_count = 0;
	};

	~garden(){
		destroy();

		cudaDeviceReset();
	};

	unsigned int T; // number of trees
	fig_variety *variety;
	fig_tree **trees;

	void build(garden_truck *tk, garden_greenhouse *gh, garden_tools *tl, fig_variety *v, unsigned int t);

	bool load_on_truck();
	bool move_to_greenhouse();

	bool harvest(garden_truck *truck);

	bool give(garden_truck *truck);

	//bool hint(garden_truck *truck);
	//bool of(garden_truck *truck);
	//bool green(garden_truck *truck);

	bool move_to_garden();

	bool replant();
	bool replant_from_truck(garden_truck *tk, garden_greenhouse *gh, garden_tools *tl, fig_variety *v, unsigned int t);

	void destroy();

	garden_tools *tools;
	garden_truck *truck;
	garden_greenhouse *greenhouse;

	unsigned int branches_count;
	unsigned int endpoints_count;

	size_t in_mem_size;
};