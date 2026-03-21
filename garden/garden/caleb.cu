#include "caleb.cuh"
#include "tools.cuh"
#include "truck.cuh"
#include "greenhouse.cuh"
#include "garden.cuh"

#define THREADS_NUM 8 // BUCKET_SIZE를 나누었을 때 정수여야 한다.
#define DISTANCE_THRESHOLD 2
void mean_shift(float *data, int *x, int *y);
void visualize(garden_truck *truck);

//#define UNIFORM_DISTRIBUTED_NUTRIENTS
#define ITERATION_STEP 5
#define ITERATION 25  // 5 * 5
int sequence_x[ITERATION] = { 2, 2, 1, 2, 3, 1, 1, 3, 3, 2, 0, 2, 4, 1, 0, 0, 1, 3, 4, 4, 3, 0, 0, 4, 4 };
int sequence_y[ITERATION] = { 2, 1, 2, 3, 2, 1, 3, 3, 1, 0, 2, 4, 2, 0, 1, 3, 4, 4, 3, 1, 0, 0, 4, 4, 0 };

void curr_time()
{
	time_t t = time(0);
	struct tm * now = localtime(&t);
	char buf[80];
	strftime(buf, sizeof(buf), "%Y-%m-%d %X", now);
	printf("%s\n", buf);
}

GARDEN_API bool grow(GROW_PARAMETERS* params)
{
	// garden
	garden g;

	// truck
	garden_truck truck;

	// greenhouse
	garden_greenhouse greenhouse;

	// variety
	fig_variety variety = { MAX_CELL_NUM, MAX_TW_NUM, 2000, 0.03f, 10000000, { -65535.0f, 65535.0f }, 1 };

	// tools 
	garden_tools tools;

	// factory
	garden_factory factory;

	// number of trees
	int T = 1;

	// tools
	if (!tools.prepare(T, -BUCKET_HEIGHT / 4, BUCKET_HEIGHT / 4)) return -1;

	// plant
	g.build(&truck, &greenhouse, &tools, &variety, T);

	// harvest mode?
	truck.do_harvest = false;

	// replant trees from warehouse_
	char warehouse_path[256] = { 0 };
	sprintf_s(warehouse_path, "%s\\%s\\trees.warehouse", GARDEN_PATH, params->session);
	if (truck.move_trees_from_warehouse(warehouse_path, truck.do_harvest))
	{
		if (!g.replant_from_truck(&truck, &greenhouse, &tools, &variety, truck.T))
			return false;
	}

	int start_index = params->start;
	int end_index = params->end + 1;
	int index_step = 1; // 10;

	js_mart js_mart_;

	cudaEvent_t start, stop;
	float elapsed;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	int iteration = 0;
	while (1)
	{
		printf("<<iteration: %d>>\n", iteration);
		curr_time();
		cudaEventRecord(start, 0);

		// move to greenhouse
		if (!g.move_to_greenhouse()) return false;

		printf("give\n");
		for (int s = start_index; s < end_index; s += index_step)
		{
			int e = (s + index_step > end_index) ? end_index : s + index_step;

			if (!truck.load_water(params->session, s, e)) return false;

			// pour buckets of water
			if (!greenhouse.pour(&truck)) return false;

			// produce
			if (!factory.produce(params->session, &truck, s, e)) return false;

			//give
			if (!g.give(&truck)) return false;
		}

		printf("synthesize\n");
		g.synthesize(&truck);

		printf("store\n");
		for (int s = start_index; s < end_index; s += index_step)
		{
			int e = (s + index_step > end_index) ? end_index : s + index_step;

			if (!truck.load_water(params->session, s, e)) return false;

			// pour buckets of water
			if (!greenhouse.pour(&truck)) return false;

			// produce
			if (!factory.produce(params->session, &truck, s, e)) return false;

			// store
			if (!g.store(&truck)) return false;

			truck.accumulate_error_rate();
		}

		if (!g.move_to_garden()) return false;

		if (!g.replant()) return false;

		if (truck.get_error_rate())
		{
			printf("==>error rate: %.7f%% (best!!)\n", truck.best);
			curr_time();
			g.load_on_truck();
			truck.move_trees_to_warehouse(warehouse_path);
		}
		else
			printf("==>error rate: %.4f%% (best: %.4f%%)\n", truck.error_rate, truck.best);

		tools.idle_memory();

		cudaEventRecord(stop, 0);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&elapsed, start, stop);
		printf("[%d] taken time: %3.1f ms\n", iteration, elapsed);
		printf("\n");

		if (truck.best < 1.0) // !!!!!!!!!! termination condition !!!!!!!!!!!!
			break;
		truck.reset_error_rate();

		iteration++;
	}
	
	return true;
}

GARDEN_API bool harvest(HARVEST_PARAMETERS* params)
{
	// garden
	garden g;

	// truck
	garden_truck truck;

	// greenhouse
	garden_greenhouse greenhouse;

	// variety
	fig_variety variety = { MAX_CELL_NUM, MAX_TW_NUM, 2000, 0.03f, 10000000, { -65535.0f, 65535.0f }, 1 };

	// tools 
	garden_tools tools;

	// factory
	garden_factory factory;

	// harvest mode?
	truck.do_harvest = true;

	// replant trees from warehouse_
	char warehouse_path[256] = { 0 };
	sprintf_s(warehouse_path, "%s\\%s\\trees.warehouse", GARDEN_PATH, params->session);
	// number of trees
	int T = truck.move_trees_from_warehouse(warehouse_path, truck.do_harvest);
	if (T > 0)
	{
		// tools
		if (!tools.prepare(T, -BUCKET_HEIGHT / 4, BUCKET_HEIGHT / 4)) return false;

		// plant
		if (!g.replant_from_truck(&truck, &greenhouse, &tools, &variety, T)) return false;

		// move to greenhouse
		if (!g.move_to_greenhouse()) return false;
		tools.idle_memory();
	}
	else
		return false;

	int start_index = params->start;
	int end_index = params->end + 1;
	
	js_mart js_mart_;

	cudaEvent_t start, stop;
	float elapsed;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	for (int s = start_index; s < end_index; s++)
	{
		printf("<<iteration: %d>>\n", s);
		curr_time();
		cudaEventRecord(start, 0);

		int e = s + 1;

		if (!truck.load_water(params->session, s, e)) return false;

		// pour buckets of water
		if (!greenhouse.pour(&truck)) return false;

		// produce
		if (!factory.produce(params->session, &truck, s, e, true)) return false;

		// harvest
		if (!g.harvest(&truck)) return false;
		js_mart_.packaging(params->session, truck.finest_fruits, truck.finest_fruits_count);

		cudaEventRecord(stop, 0);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&elapsed, start, stop);
		printf("[%d] taken time: %3.1f ms\n", s, elapsed);
		printf("\n");
	}
	return true;
}

GARDEN_API bool sell(SELL_PARAMETERS* params)
{
	unsigned long long demand_total = 0;
	unsigned long long supply_total = 0;
	double demand_elasticity = 0.0;
	unsigned long long demand_cnt[MAX_CELL_NUM] = { 0 };
	unsigned long long supply_cnt[MAX_CELL_NUM] = { 0 };
	double supply_rate[MAX_CELL_NUM] = { 0.0f };

	garden_factory factory;

	for (int i = params->harvest_start; i < params->harvest_end; i++)
	{
		char color_file_path[256] = { 0 };
		sprintf(color_file_path, "%s\\%s\\"COLOR_PATH, GARDEN_PATH, params->session, i);
		cv::Mat img = cv::imread(color_file_path);
		if (!img.data)
			return false;

		for (int p = 0; p < BUCKET_SIZE * 3; p += 3)
		{
			unsigned long label = factory.get_label_from_color(img.data[p], img.data[p + 1], img.data[p + 2]);
			if (label == MAXUINT32) continue;
			demand_cnt[label]++;
			if (label < MAX_CELL_NUM - 1)
				demand_total++;
		}
	}

	for (int i = params->harvest_start; i < params->harvest_end; i++)
	{
		char color_file_path[256] = { 0 };
		sprintf(color_file_path, "%s\\%s\\"FRUIT_PATH, GARDEN_PATH, params->session, i);
		cv::Mat img = cv::imread(color_file_path);
		if (!img.data)
			return false;

		for (int p = 0; p < BUCKET_SIZE * 3; p += 3)
		{
			unsigned long label = factory.get_label_from_color(img.data[p], img.data[p + 1], img.data[p + 2]);
			if (label == MAXUINT32) continue;
			supply_cnt[label]++;
			if (label < MAX_CELL_NUM - 1)
				supply_total++;
		}
	}

	demand_elasticity = (double)demand_total / (double)supply_total;

	for (int i = 0; i < MAX_CELL_NUM - 1; i++)
	{
		supply_rate[i] = ((supply_cnt[i] != 0 && demand_cnt[i] != 0)) ? (double)supply_cnt[i] / (double)demand_cnt[i] * demand_elasticity * 100 : 0.0;
	}

	FILE* fp = 0;
	char sales_file_path[256] = { 0 };
	sprintf(sales_file_path, "%s\\%s\\"SALES_PATH, GARDEN_PATH, params->session);
	errno_t err = fopen_s(&fp, sales_file_path, "w");
	if (err != 0) return false;

	fprintf_s(fp, "{\n");
	fprintf_s(fp, "  \"demand total\": %llu\n", demand_total);
	fprintf_s(fp, "  \"supply total\": %llu\n", supply_total);
	fprintf_s(fp, "  \"demand elasticity\": %f\n", demand_elasticity);
	fprintf_s(fp, "  \"sales\": [\n");
	for (int i = 0; i < MAX_CELL_NUM - 1; i++)
	{
		fprintf_s(fp, "    {\n");
		fprintf_s(fp, "      \"label\": %d\n", i);
		fprintf_s(fp, "      \"demand\": %llu\n", demand_cnt[i]);
		fprintf_s(fp, "      \"supply\": %llu\n", supply_cnt[i]);
		fprintf_s(fp, "      \"rate\": %f\n", supply_rate[i]);
		
		if (supply_rate[i] >= 50.0)
		fprintf_s(fp, "      \"result\": %s\n", "yes");
		else
		fprintf_s(fp, "      \"result\": %s\n", "no");
		
		if (i < MAX_CELL_NUM - 2)
			fprintf_s(fp, "    },\n");
		else
			fprintf_s(fp, "    }\n");
	}
	fprintf_s(fp, "  ]\n");
	fprintf_s(fp, "}\n");

	fclose(fp);

	return true;
}