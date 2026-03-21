#include "tools.cuh"

garden_tools::garden_tools()
{
	// check device information
	cudaError_t cudaStatus = cudaGetDeviceCount(&in_count);
	if (cudaStatus == cudaSuccess)
	{
		std::cout << "device count : " << in_count << std::endl;

		prop = (cudaDeviceProp*)malloc(sizeof(cudaDeviceProp) * in_count);

		for (int i = 0; i < in_count; i++)
		{
			if (cudaSuccess == (cudaStatus = cudaGetDeviceProperties(&prop[i], i)))
			{
				std::cout << "name : " << prop[i].name << std::endl;
				std::cout << "total global mem : " << prop[i].totalGlobalMem << std::endl;
				std::cout << "total constant mem " << prop[i].totalConstMem << std::endl;
				std::cout << "multi processor count: " << prop[i].multiProcessorCount << std::endl;
				std::cout << "max threads per multi processor" << prop[i].maxThreadsPerMultiProcessor << std::endl;
				std::cout << "max threads per block : " << prop[i].maxThreadsPerBlock << std::endl;
				std::cout << "max threads 0 dim : " << prop[i].maxThreadsDim[0] << std::endl;
				std::cout << "max threads 1 dim : " << prop[i].maxThreadsDim[1] << std::endl;
				std::cout << "max threads 2 dim : " << prop[i].maxThreadsDim[2] << std::endl;
				std::cout << "max grids 0 size : " << prop[i].maxGridSize[0] << std::endl;
				std::cout << "max grids 1 size : " << prop[i].maxGridSize[1] << std::endl;
				std::cout << "max grids 2 size : " << prop[i].maxGridSize[2] << std::endl;
				std::cout << "max texture 1d  : " << prop[i].maxTexture1D << std::endl;
			}
		}
	}

	for (int i = 0; i < T; i++)
	{
		_rd_int[i] = 0;
		_gen_int[i] = 0;
		_dist_int[i] = 0;
		_rd_float[i] = 0;
		_gen_float[i] = 0;
		_dist_float[i] = 0;
	}
}

garden_tools::~garden_tools()
{
	free(prop);

	for (int i = 0; i < T; i++)
	{
		if (_rd_int[i]) delete _rd_int[i];
		if (_gen_int[i]) delete _gen_int[i];
		if (_dist_int[i]) delete _dist_int[i];
		if (_rd_float[i]) delete _rd_float[i];
		if (_gen_float[i]) delete _gen_float[i];
		if (_dist_float[i]) delete _dist_float[i];
	}
}

bool garden_tools::prepare(int t, int range_int_min, int range_int_max)
{
	T = t;

	if (T > MAX_TREE_NUM)
	{
		printf("!!!! WARNING - You must redefine MAX_TREE_NUM !!!\n");
		return false;
	}

	core_count = getNumberOfProcessors();

	for (int i = 0; i < T; i++)
	{
		_rd_int[i] = new std::random_device();
		_gen_int[i] = new std::mt19937((*_rd_int[i])());
		_dist_int[i] = new std::uniform_int_distribution<int>(range_int_min, range_int_max);
		_rd_float[i] = new std::random_device();
		_gen_float[i] = new std::mt19937((*_rd_float[i])());
		_dist_float[i] = new std::uniform_real_distribution<float>(0.0f, 1.0f);
	}

	return true;
}

/*
void garden_tools::clean()
{
for (int i = 0; i < T; i++)
{
delete _rd_int[i]; _rd_int[i] = 0;
delete _gen_int[i]; _gen_int[i] = 0;
delete _dist_int[i]; _dist_int[i] = 0;
delete _rd_float[i]; _rd_float[i] = 0;
delete _gen_float[i]; _gen_float[i] = 0;
delete _dist_float[i]; _dist_float[i] = 0;
}
}
*/

int garden_tools::rand_int(int t_idx)
{
	return (*_dist_int[t_idx])(*_gen_int[t_idx]);
}

float garden_tools::rand_float(int t_idx)
{
	return (*_dist_float[t_idx])(*_gen_float[t_idx]);
}

size_t garden_tools::get_total_global_mem(/*int index*/)
{
	return prop[0].totalGlobalMem;
}

size_t garden_tools::idle_memory()
{
	size_t idle_byte, total_byte;
	cudaMemGetInfo(&idle_byte, &total_byte);
	printf("idle memory: %.2f%%\n", (double)idle_byte / (double)total_byte * 100.0);
	return idle_byte;
}

unsigned long garden_tools::getNumberOfProcessors()
{
	SYSTEM_INFO sysinfo;
	GetSystemInfo(&sysinfo);
	return sysinfo.dwNumberOfProcessors;
};