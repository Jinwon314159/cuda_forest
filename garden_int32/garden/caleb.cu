#include "garden.cuh"
#include "regression.cuh"// linear regression

#define NUTRIENTS_COUNT 5
#define ITERATION 0
#define NIT 0
#define LINEAR 1

// number of trees
int T = 2;

// garden
garden g;

// truck
garden_truck truck;

// greenhouse
garden_greenhouse greenhouse;

// variety
fig_variety variety = { MAX_CELL_NUM, MAX_TW_NUM, 2000, 0.001f, 100000, {-65535.0f, 65535.0f}, 1 };

// tools 
garden_tools tools;

// factory
factory fertilizer_factory;

int main(int argc, char* argv[])
{
	// Help : 실행 시 argv[1]에 test를 입력하면 test 모드로 동작, 아무것도 입력하지 않는 경우 training 모드로 동작
	// Ex) Garden test [Enter] => test mode, Garden [Enter] => training mode

	// tools
	if (!tools.prepare(T, -BUCKET_HEIGHT, BUCKET_HEIGHT)) return -1;

	// plant
	g.build(&truck, &greenhouse, &tools, &variety, T);

	if (argc > 1 && strcmp(argv[1], "test") == 0)
	{
		truck.do_harvest = true;
	}

	// replant trees from warehouse_
	if (truck.move_trees_from_warehouse("trees.warehouse", truck.do_harvest))
	{
		g.replant_from_truck(&truck, &greenhouse, &tools, &variety, truck.T);
		g.move_to_greenhouse();
	}
	// _replant trees from warehouse

	int start_index = 0; //349;
	int end_index = 20; //349;
	int fertilizer_count = 0;
	js_mart js_mart_;

#if NIT // case: kinect data

	int nu_count = 0; // truck 에 받아온 nutrient 배열 갯수
	int file_index = 0; // depth file을 작성한 file index
	unsigned short *water_; // factory에서 받아올 water_
	water_ = (unsigned short*)malloc(sizeof(unsigned short)* BUCKET_WIDTH * BUCKET_HEIGHT);

	while(1)
	{
		fertilizer_factory.quickDelivery(&truck, water_, &nu_count, &file_index, argc, argv);

		if (nu_count == 0)
			continue;

		truck.load_water(water_);
		 
#elif ITERATION // case: iteration + virtual data

	int iteration = 3; // 0이 되면 안된다.
	js_mart js_mart_;
	int type = 0; // 0 : virtual data, 1: kinect data

	for(int k = 0; k < iteration; k++)
	{
		// move to greenhouse
		if (!g.move_to_greenhouse()) return -1;

		fertilizer_factory.order(start_index, end_index, iteration, k, &fertilizer_count);
		//js_mart_.packaging();
		truck.load_water(start_index, end_index);

#else // case: virtual data 

	while (1)
	{
		// move to greenhouse
		if (!g.move_to_greenhouse()) return -1;

		fertilizer_factory.order(start_index, end_index, 1, 0, &fertilizer_count);

		truck.load_water(start_index, end_index);

#endif
		// pour buckets of water
		if (!greenhouse.pour(&truck)) return -1;
#if NIT
		if (truck.do_harvest)	// test
		{
			if (!g.harvest(&truck)) return -1;
			js_mart_.packaging(truck.finest_fruits, truck.finest_fruits_count);
		}
		else {	// training
			if (!g.give(&truck)) return -1;
			truck.calculate_error_rate();
		}
#else

#if LINEAR
		inspector inspector_;
		inspector_.init(end_index - start_index + 1);
#endif
		for (int i = start_index; i <= end_index; i++)
		{
			fertilizer_factory.delivery(&truck, i - start_index);
			printf("fertilizer #%d has arrived.\n", i);

			if (truck.do_harvest)	// test
			{
				if (!g.harvest(&truck)) return -1;
				js_mart_.packaging(truck.finest_fruits, truck.finest_fruits_count);
#if LINEAR
				inspector_.setting_value(truck.finest_fruits, truck.finest_fruits_count);
#endif
			}
			else {	// training
				if (!g.give(&truck)) return -1;
				truck.calculate_error_rate();
			}
			if (i == end_index) {
				exit(0);
			}
		}
#if LINEAR
		inspector_.check_direction();
		inspector_.clear();
#endif

#endif

		if (!truck.do_harvest)
		{
			if (!g.move_to_garden()) return -1;

			if (!g.replant()) return -1;

			if (truck.get_error_rate())
			{
				printf("==>error rate: %.2f%% (best!!)\n", truck.best);
				g.load_on_truck();
				truck.move_trees_to_warehouse("trees.warehouse");
			}
			else
				printf("==>error rate: %.2f%% (best: %.2f%%)\n", truck.error_rate, truck.best);
			truck.reset_error_rate();

			tools.idle_memory();
		}
	}

#if NIT // case: kinect data
	free(water_);
#endif
	return 0;
}