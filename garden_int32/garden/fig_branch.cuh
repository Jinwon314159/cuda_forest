#pragma once
#include "global.cuh"

class fig_branch
{
public:
	fig_branch(unsigned int t_idx, fig_variety *v, garden_tools *t)
	{
		tree_index = t_idx;
		
		endpoint = true;
		variety = v;
		tools = t;

		threshold = FLT_MAX;

		total_nutrients = 0;
		memset(cells, 0, sizeof(unsigned __int64) * MAX_CELL_NUM);

		parent_total_nutrients = 0;
		memset(parent_cells, 0, sizeof(unsigned __int64) * MAX_CELL_NUM);

		twigs = 0;
		init();

		child[0] = 0, child[1] = 0;
	};

	// trunk
	fig_branch(unsigned int t_idx, garden_truck* truck, fig_variety *v, garden_tools *t)
	{
		tree_index = t_idx;

		branch_index = truck->trees[t_idx];
		cuda_branch branch = truck->branches[branch_index];
		split_feature = branch.split_feature;
		threshold = branch.threshold;
		parent_index = branch.parent_index;
		left_child_index = branch.left_child_index;
		endpoint_index = branch.endpoint_index;

		endpoint = true;
		variety = v;
		tools = t;

		total_nutrients = branch.total_nutrients;
		memset(cells, 0, sizeof(unsigned __int64)* MAX_CELL_NUM);

		parent_total_nutrients = 0;
		memset(parent_cells, 0, sizeof(unsigned __int64)* MAX_CELL_NUM);

		twigs = 0;

		for (int i = 0; i < truck->T; i++)
		{
			cells[i] = branch.cells[i];
		}

		child[0] = child[1] = 0;
		if (left_child_index < UINT_MAX)
		{
			endpoint = false;
			child[0] = new fig_branch(t_idx, left_child_index, truck, v, t);
			child[1] = new fig_branch(t_idx, left_child_index + 1, truck, v, t);
		}
		else {
			if (!truck->do_harvest)
				twigs = (fig_twig*)calloc(variety->tw, sizeof(fig_twig));
		}
	};

	// branch
	fig_branch(unsigned int t_idx, unsigned int branch_index_, garden_truck* truck, fig_variety *v, garden_tools *t)
	{
		tree_index = t_idx;

		branch_index = branch_index_;
		
		if (branch_index < UINT_MAX)
		{
			cuda_branch branch = truck->branches[branch_index];
			split_feature = branch.split_feature;
			threshold = branch.threshold;
			parent_index = branch.parent_index;
			left_child_index = branch.left_child_index;
			endpoint_index = branch.endpoint_index;
			total_nutrients = branch.total_nutrients;
			for (int i = 0; i < truck->T; i++)
			{
				cells[i] = branch.cells[i];
			}
		}

		endpoint = true;
		variety = v;
		tools = t;

		memset(cells, 0, sizeof(unsigned __int64)* MAX_CELL_NUM);

		parent_total_nutrients = 0;
		memset(parent_cells, 0, sizeof(unsigned __int64)* MAX_CELL_NUM);

		twigs = 0;

		child[0] = child[1] = 0;
		if (left_child_index < UINT_MAX)
		{
			endpoint = false;
			child[0] = new fig_branch(t_idx, left_child_index, truck, v, t);
			child[1] = new fig_branch(t_idx, left_child_index + 1, truck, v, t);
		} else {
			if (!truck->do_harvest)
				twigs = (fig_twig*)calloc(variety->tw, sizeof(fig_twig));
		}
	};

	~fig_branch()
	{
		if(twigs) free(twigs);
	};

	fig_variety *variety;
	garden_tools *tools;

	unsigned int tree_index;
	unsigned int parent_index;
	unsigned int branch_index;
	unsigned int left_child_index;
	unsigned int endpoint_index;

	fig_split_feature split_feature;
	float threshold;

	bool endpoint; // 초기값: true
	unsigned int label;
	unsigned __int64 parent_cells[MAX_CELL_NUM]; // 부모로 부터 물려 받은 cells는 기억해 뒀다가 reset 시에 복구
	unsigned __int64 parent_total_nutrients;
	unsigned __int64 cells[MAX_CELL_NUM];
	unsigned __int64 total_nutrients;
	fig_branch *child[2]; // endpoint = false와 함께 2개 생성 (0.left, 1.right)

	// define 'random tests'
	fig_twig* twigs; // 처음에 features * thresholds 개 생성 후, splitted = true와 함께 삭제

	// 잔가지 중 가장 알찬 녀석을 두 개 만 고르고 나머지는 가지치기
	// cuda kernel로 구현해야 할 듯
	float prune(int x, int y, unsigned short *original_image, unsigned short *integral_image);

	unsigned int get_num_branches()
	{
		unsigned int n = 0;
		if (!endpoint)
		{
			n += child[0]->get_num_branches();
			n += child[1]->get_num_branches();
		}
		return ++n;
	};

	unsigned int get_num_endpoints()
	{
		unsigned int n = 0;
		if (!endpoint)
		{
			n += child[0]->get_num_endpoints();
			n += child[1]->get_num_endpoints();
		}
		else
			++n;
		return n;
	};

	bool dig_up(unsigned int parent_index, unsigned int branch_index, garden_truck *truck, unsigned int *truck_branch_index, unsigned int *truck_endpoint_index);

	bool replant(garden_truck *truck);
	bool replant_no_split(garden_truck *truck);

private:
	bool split();
	double compute_gain(double prior_entropy, fig_twig* tw);

	void init()
	{
		total_nutrients = parent_total_nutrients;
		memcpy(cells, parent_cells, sizeof(unsigned __int64) * MAX_CELL_NUM);

		if (twigs) free(twigs);
		twigs = (fig_twig*)calloc(variety->tw, sizeof(fig_twig));
		for (unsigned int i = 0; i < variety->tw; i++)
		{
			signed short ux = 0, uy = 0, vx = 0, vy = 0;

			if ((unsigned int)(tools->rand_float(tree_index) + 0.5f) == 0)
			{
				while (ux == 0 && uy == 0)
				{
					ux = tools->rand_int(tree_index);
					uy = tools->rand_int(tree_index);
				}
			}

			while ((vx == 0 && vy == 0) || (vx == ux && vy == uy))
			{
				vx = tools->rand_int(tree_index);
				vy = tools->rand_int(tree_index);
			}

			twigs[i].split_feature.ux = ux;
			twigs[i].split_feature.uy = uy;
			twigs[i].split_feature.vx = vx;
			twigs[i].split_feature.vy = vy;

			twigs[i].threshold = (float)variety->range.min + (variety->range.max - variety->range.min) * tools->rand_float(tree_index);
		}
	};

	unsigned int argmax()
	{
		unsigned int ret = 0;
		unsigned __int64 max_value = 0;

		for (unsigned int i = 0; i < variety->nc; i++)
			if (cells[i] > max_value)
			{
				max_value = cells[i];
				ret = i;
			}

		return ret;
	};
};
