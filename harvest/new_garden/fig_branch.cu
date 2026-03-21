#include "fig_branch.cuh"

bool fig_branch::dig_up(unsigned __int64 parent_index, unsigned __int64 branch_index, garden_truck *truck, unsigned __int64 *truck_branch_index, unsigned __int64 *truck_endpoint_index)
{
	cudaError_t status = cudaSuccess;

	// 현재 branch의 indexes를 업데이트
	this->parent_index = parent_index;
	this->branch_index = branch_index;

	// 메모리 사이즈에 잘 맞춰서 인덱스를 증가시키고 포인터도 증가
	cuda_branch branch = { 0 };
	branch.parent_index = parent_index;
	branch.total_nutrients = this->total_nutrients;

	if (endpoint)
	{
		// 현재 branch의 indexes를 업데이트
		this->left_child_index = UINT_MAX;
		this->endpoint_index = *truck_endpoint_index;

		// endpoint라는 건,
		// 1. 아직 선택된 children이 없다는 것
		branch.left_child_index = UINT_MAX;
		// 2. cells에 영양소를 저장하고 있고 잔가지들이 나 있다는 것
		branch.endpoint_index = this->endpoint_index;

		// cells memory를 copy
		memcpy(branch.cells, this->cells, sizeof(unsigned __int64) * variety->nc);

		// branch memory를 copy
		status = cudaMemcpy(truck->branches + this->branch_index, &branch, sizeof(cuda_branch), cudaMemcpyHostToHost);
		if (status != cudaSuccess) return false;

		// twigs memory를 copy
		if (!truck->do_harvest)
		{
			status = cudaMemcpy(truck->twigs + this->endpoint_index * MAX_TW_NUM, this->twigs, sizeof(fig_twig)* MAX_TW_NUM, cudaMemcpyHostToHost);
			if (status != cudaSuccess) return false;
		}

		++*truck_endpoint_index;
	}
	else
	{
		// 현재 branch의 indexes를 업데이트
		this->left_child_index = *truck_branch_index;
		this->endpoint_index = UINT_MAX;

		// branch라는 건,
		// 1. children이 둘 있다는 것
		branch.left_child_index = this->left_child_index;
		// 2. 잎사귀와 잔가지가 사라졌다는 뜻
		branch.endpoint_index = UINT_MAX;
		// 3. u, v, threshold가 이미 정해져 있다는 것
		branch.split_feature = split_feature;
		branch.threshold = threshold;

		// cells memory를 copy
		memcpy(branch.cells, this->cells, sizeof(unsigned __int64) * variety->nc);

		// branch memory를 copy
		status = cudaMemcpy(truck->branches + this->branch_index, &branch, sizeof(cuda_branch), cudaMemcpyHostToHost);
		if (status != cudaSuccess) return false;

		*truck_branch_index += 2;

		child[0]->dig_up(branch_index, this->left_child_index, truck, truck_branch_index, truck_endpoint_index);
		child[1]->dig_up(branch_index, this->left_child_index + 1, truck, truck_branch_index, truck_endpoint_index);
	}

	return true;
}


bool fig_branch::replant(garden_truck *truck)
{
	cudaError_t status = cudaSuccess;

	// 1. 일단 지금 branch의 cells를 update한다
	this->total_nutrients = truck->branches[this->branch_index].total_nutrients;
	this->threshold = truck->branches[this->branch_index].threshold;
	status = cudaMemcpy(this->cells, truck->branches[this->branch_index].cells, sizeof(unsigned __int64) * MAX_CELL_NUM, cudaMemcpyHostToHost);
	if (status != cudaSuccess) return false;

	if (endpoint)
	{
		label = argmax();

		// 트럭에서 endpoint_index로 해당 twigs에 접근해서 MAX_TW_NUM 만큼 복사
		if (!truck->do_harvest)
			cudaMemcpy(this->twigs, truck->twigs + this->endpoint_index * MAX_TW_NUM, sizeof(fig_twig) * MAX_TW_NUM, cudaMemcpyHostToHost);

		// split
		split();
	}
	else
	{
		this->child[0]->replant(truck);
		this->child[1]->replant(truck);
	}

	return true;
}

bool fig_branch::replant_no_split(garden_truck *truck)
{
	cudaError_t status = cudaSuccess;

	// 1. 일단 지금 branch의 cells를 update한다
	this->total_nutrients = truck->branches[this->branch_index].total_nutrients;
	this->threshold = truck->branches[this->branch_index].threshold;
	status = cudaMemcpy(this->cells, truck->branches[this->branch_index].cells, sizeof(unsigned __int64)* MAX_CELL_NUM, cudaMemcpyHostToHost);
	if (status != cudaSuccess) return false;

	if (endpoint)
	{
		label = argmax();

		// 트럭에서 endpoint_index로 해당 twigs에 접근해서 MAX_TW_NUM 만큼 복사
		if (!truck->do_harvest)
			cudaMemcpy(this->twigs, truck->twigs + this->endpoint_index * MAX_TW_NUM, sizeof(fig_twig)* MAX_TW_NUM, cudaMemcpyHostToHost);
	}
	else
	{
		this->child[0]->replant_no_split(truck);
		this->child[1]->replant_no_split(truck);
	}

	return true;
}

bool fig_branch::split()
{
	// 모든 cell의 합이 total_nutrients와 같지 않으면 에러
	unsigned __int64 sum = 0;
	for (unsigned int i = 0; i < this->variety->nc; i++)
		sum += this->cells[i];
	assert(sum == this->total_nutrients);

	if (!variety->grow)
		return false;

	// purity check
	for (unsigned int i = 0; i < this->variety->nc; i++)
		if (this->cells[i] == this->total_nutrients)
			return false;

	// alpha(hyperparameter) check
	if (this->total_nutrients < variety->an)
		return false;

	// prior_entropy
	double prior_entropy = 0.0;
	for (unsigned int i = 0; i < variety->nc; i++)
	{
		if (this->cells[i] != 0 && this->total_nutrients != 0)
		{
			double p = (double)this->cells[i] / (double)this->total_nutrients;
			prior_entropy -= p * log(p) / log(2.0);
		}
	}

	// information gain
	double gain[MAX_TW_NUM] = { 0.0 };
	double max_gain = 0.0;
	unsigned __int64 max_index = 0;
	for (unsigned __int64 i = 0; i < variety->tw; i++)
	{
		if (this->twigs[i].left_total_nutrients == 0 || this->twigs[i].right_total_nutrients == 0)
			continue;
		gain[i] = compute_gain(prior_entropy, &this->twigs[i]);
		if (gain[i] > max_gain)
		{
			max_gain = gain[i];
			max_index = i;
		}
	}

	// beta(hyperparameter) check
	if (max_gain < variety->ig)
	{
		// 답이 안나온다...리셋
		if (this->total_nutrients > this->parent_total_nutrients + variety->nl)
		{
			printf("branch_index:%d - reset twigs\n", this->branch_index);
			init();
		}

		return false;
	}

	printf("branch_index:%d - split\n", this->branch_index);

	// split
	this->endpoint = false;
	this->split_feature = this->twigs[max_index].split_feature;
	this->threshold = this->twigs[max_index].threshold;

	this->child[0] = new fig_branch(tree_index, variety, tools);
	memcpy(this->child[0]->cells, this->twigs[max_index].left_cells, sizeof(unsigned __int64) * MAX_CELL_NUM);
	this->child[0]->total_nutrients = this->twigs[max_index].left_total_nutrients;
	memcpy(this->child[0]->parent_cells, this->twigs[max_index].left_cells, sizeof(unsigned __int64) * MAX_CELL_NUM);
	this->child[0]->parent_total_nutrients = this->twigs[max_index].left_total_nutrients;

	this->child[1] = new fig_branch(tree_index, variety, tools);
	memcpy(this->child[1]->cells, this->twigs[max_index].right_cells, sizeof(unsigned __int64) * MAX_CELL_NUM);
	this->child[1]->total_nutrients = this->twigs[max_index].right_total_nutrients;
	memcpy(this->child[1]->parent_cells, this->twigs[max_index].right_cells, sizeof(unsigned __int64) * MAX_CELL_NUM);
	this->child[1]->parent_total_nutrients = this->twigs[max_index].right_total_nutrients;

	free(this->twigs);
	this->twigs = 0;

	return true;
}


double fig_branch::compute_gain(double prior_entropy, fig_twig* tw)
{
	double left_entropy = 0.0;
	for (unsigned int i = 0; i < variety->nc; i++)
	{
		if (tw->left_cells[i] != 0 && tw->left_total_nutrients != 0)
		{
			double p = (double)tw->left_cells[i] / (double)tw->left_total_nutrients;
			left_entropy -= p * log(p) / log(2.0);
		}
	}

	double right_entropy = 0.0;
	for (unsigned int i = 0; i < variety->nc; i++)
	{
		if (tw->right_cells[i] != 0 && tw->right_total_nutrients != 0)
		{
			double p = (double)tw->right_cells[i] / (double)tw->right_total_nutrients;
			right_entropy -= p * log(p) / log(2.0);
		}
	}

	double posterior_entropy = (tw->left_total_nutrients * left_entropy + tw->right_total_nutrients * right_entropy) / this->total_nutrients;

	return prior_entropy - posterior_entropy;
}