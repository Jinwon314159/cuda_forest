#include "garden.cuh"
#include "farmer_5jk.cuh"

// number of trees
int T = 2;

// garden
garden g;

// truck
garden_truck truck;

// greenhouse
garden_greenhouse greenhouse;

// variety
fig_variety variety = { MAX_CELL_NUM, MAX_TW_NUM, 2000, 0.001f, 100000, { -65535.0f, 65535.0f }, 1 };

// tools 
garden_tools tools;

// factory
factory fertilizer_factory;

// farmer_5jk
farmer_5jk farmer;

int main(int argc, char* argv[])
{
	cudaDeviceReset();

	// Help : 실행 시 argv[1]에 test를 입력하면 test 모드로 동작, 아무것도 입력하지 않는 경우 training 모드로 동작
	// Ex) Garden test [Enter] => test mode, Garden [Enter] => training mode
	tools.idle_memory();

	// tools
	if (!tools.prepare(T, -BUCKET_HEIGHT, BUCKET_HEIGHT)) return -1;

	// plant
	g.build(&truck, &greenhouse, &tools, &variety, T);

	truck.do_harvest = true;

	// replant trees from warehouse_
	if (truck.move_trees_from_warehouse("trees.warehouse", truck.do_harvest))
	{
		g.replant_from_truck(&truck, &greenhouse, &tools, &variety, truck.T);
		g.move_to_greenhouse();
	}
	else
	{
		printf("failed to read warehouse.\n");
		return 0;
	}

	ThreadParam param;
	param.g = &g;
	param.m = 0; // &mart;
	param.f = &fertilizer_factory;

	farmer.work(&param, argc, argv);

	return 0;
}