#include "caleb.cuh"
#include "tools.cuh"
#include "truck.cuh"
#include "greenhouse.cuh"
#include "garden.cuh"

#include <opencv2\opencv.hpp>

#define THREADS_NUM 8 // BUCKET_SIZE를 나누었을 때 정수여야 한다.
#define DISTANCE_THRESHOLD 2
void mean_shift(float *data, int *x, int *y);
void visualize(garden_truck *truck);

//#define UNIFORM_DISTRIBUTED_NUTRIENTS
#define ITERATION_STEP 5
#define ITERATION 25  // 5 * 5
int sequence_x[ITERATION] = { 2, 2, 1, 2, 3, 1, 1, 3, 3, 2, 0, 2, 4, 1, 0, 0, 1, 3, 4, 4, 3, 0, 0, 4, 4 };
int sequence_y[ITERATION] = { 2, 1, 2, 3, 2, 1, 3, 3, 1, 0, 2, 4, 2, 0, 1, 3, 4, 4, 3, 1, 0, 0, 4, 4, 0 };

time_t start_time = 0;

time_t curr_time()
{
	time_t t = time(0);
	struct tm * now = localtime(&t);

	char buf[80];
	strftime(buf, sizeof(buf), "%Y-%m-%d %X", now);
	printf("%s\n", buf);

	return t;
}

GARDEN_API bool grow(GROW_PARAMETERS* params)
{
	start_time = curr_time();

	// garden
	garden g;

	// truck
	garden_truck truck;

	// greenhouse
	garden_greenhouse greenhouse;

	// variety
	fig_variety variety = { MAX_CELL_NUM, MAX_TW_NUM, 2000, 0.03f, 500000, { -65535.0f, 65535.0f }, 1 };

	// tools 
	garden_tools tools;

	// factory
	garden_factory factory;

	// number of trees
	int T = 4; // 10;

	// tools
	if (!tools.prepare(T, -BUCKET_HEIGHT / 8, BUCKET_HEIGHT / 8)) return -1;

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
	int index_step = 10;

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
			printf("==>error rate: %.4f%% (best!!)\n", truck.best);
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

		if (truck.best < 3.0 || curr_time() - start_time > 180) // !!!!!!!!!! termination condition !!!!!!!!!!!!
			break;
		truck.reset_error_rate();

		iteration++;
	}

	return true;
}

GARDEN_API bool harvest(HARVEST_PARAMETERS* params)
{
	char depth_path[256] = { 0 };
	sprintf_s(depth_path, "%s\\%s\\"DEPTH_PATH, GARDEN_PATH, params->session, 0);

	unsigned short *depth = (unsigned short*)malloc(sizeof(unsigned short) * BUCKET_SIZE);

	size_t sz = BUCKET_SIZE;

	FILE* fp = 0;
	if (fopen_s(&fp, depth_path, "rb") != 0) return false;
	if (fread(depth, sizeof(unsigned short), BUCKET_SIZE, fp) != BUCKET_SIZE)
	{
		fclose(fp);
		return false;
	}
	fclose(fp);

	cv::Mat depth_img = cv::Mat(BUCKET_HEIGHT, BUCKET_WIDTH, CV_16UC1, depth).clone();

	// downsampling
	unsigned short * p_dst = 0;
	for (int i = params->start; i < params->end + 1; i++)
	{
		char path[256] = { 0 };
		char path_png[256] = { 0 };
		sprintf_s(path, "%s\\%s\\"TANGO_PATH, GARDEN_PATH, params->session, i);

		FILE* in = 0;
		if (fopen_s(&in, path, "rb") != 0) return false;

		fseek(in, 0L, SEEK_END);
		size_t sz = ftell(in);
		fseek(in, 0L, SEEK_SET);

		int w = 0, h = 0;
		if (sz == 115200)
		{
			w = 320;
			h = 180;
		}
		else if (sz == 1843200)
		{
			w = 1280;
			h = 720;
		}
		else if (sz == 4147200)
		{
			w = 1920;
			h = 1080;
		}
		else
		{
			printf("not supported resolution\n");
			fclose(in);
			return false;
		}

		unsigned short *tango = (unsigned short*)malloc(sizeof(unsigned short) * w * h);

		if (fread(tango, sizeof(unsigned short), w * h, in) != w * h)
		{
			fclose(in);
			return false;
		}
		fclose(in);

		// to save original image
#if 1
		sprintf_s(path_png, "%s.original.png", path);

		unsigned short *tango_original = (unsigned short*)malloc(sizeof(unsigned short) * w * h);
		memcpy(tango_original, tango, sizeof(unsigned short) * w * h);
		for (int p = 0; p < BUCKET_SIZE; p++)
			tango_original[p] *= 8;

		cv::Mat tango_img = cv::Mat(h, w, CV_16UC1, tango_original).clone();
		cv::imwrite(path_png, tango_img);
		tango_img.release();

		free(tango_original);
#endif

		// flip
#if 0
		if (i == 1)
		{
			unsigned short* temp = (unsigned short*)malloc(sizeof(unsigned short) * w);
			for (int y = 0; y < h / 2; y++)
			{
				int src_idx = y * w;
				int dst_idx = (h - y - 1) * w;
				memcpy(temp, tango + src_idx, sizeof(unsigned short) * w);
				memcpy(tango + src_idx, tango + dst_idx, sizeof(unsigned short) * w);
				memcpy(tango + dst_idx, temp, sizeof(unsigned short) * w);
			}
			free(temp);
		}
#endif

		// hole filling trick
#if 1
		cv::Mat depth_upsampled;
		cv::resize(depth_img, depth_upsampled, cv::Size(w, h));
		p_dst = (unsigned short*)depth_upsampled.data;
		for (int p = 0; p < w * h; p++)
		{
			if (tango[p] == 0 || tango[p] == 0xFFFF)
				tango[p] = p_dst[p];
		}
		depth_upsampled.release();
#endif

		// resize and overwrite original data
		cv::Mat src = cv::Mat(h, w, CV_16UC1, tango).clone();
		cv::Mat dst;
		cv::resize(src, dst, cv::Size(BUCKET_WIDTH, BUCKET_HEIGHT));

		FILE* out = 0;
		if (fopen_s(&out, path, "wb") != 0) return false;
		if (fwrite(dst.data, sizeof(unsigned short), BUCKET_SIZE, out) != BUCKET_SIZE)
		{
			fclose(out);
			return false;
		}
		fclose(out);

		// to save hole filled image
#if 1
		p_dst = (unsigned short*)dst.data;
		for (int p = 0; p < BUCKET_SIZE; p++)
			p_dst[p] *= 8;
		sprintf_s(path_png, "%s.filled.png", path);
		//cv::flip(dst, dst, 0);
		cv::imwrite(path_png, dst);
#endif

		free(tango);
	}
	depth_img.release();
	free(depth);


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
	double supply_prob[MAX_CELL_NUM] = { 0.0 };
	double supply_prob_sum[MAX_CELL_NUM] = { 0.0 };
	double supply_rate[MAX_CELL_NUM] = { 0.0f };
	double quality_rate[MAX_CELL_NUM] = { 0.0f };

	FILE* fp = 0;

	garden_factory factory;

	for (int i = params->grow_start; i < params->grow_end + 1; i++)
	{
		char color_file_path[256] = { 0 };
		sprintf(color_file_path, "%s\\%s\\"COLOR_PATH, GARDEN_PATH, params->session, i);
		cv::Mat color = cv::imread(color_file_path);
		if (!color.data)
			return false;

		for (int p = 0; p < BUCKET_SIZE * 3; p += 3)
		{
			unsigned long label = factory.get_label_from_color(color.data[p], color.data[p + 1], color.data[p + 2]);
			if (label == MAXUINT32) continue;
			demand_cnt[label]++;
			if (label < MAX_CELL_NUM - 1)
				demand_total++;
		}

		color.release();
	}

	for (int i = params->harvest_start; i < params->harvest_end + 1; i++)
	{
		char fruit_file_path[256] = { 0 };
		sprintf(fruit_file_path, "%s\\%s\\"FRUIT_PATH, GARDEN_PATH, params->session, i);
		cv::Mat fruit = cv::imread(fruit_file_path);
		if (!fruit.data)
			return false;

		for (int p = 0; p < BUCKET_SIZE * 3; p += 3)
		{
			unsigned long label = factory.get_label_from_color(fruit.data[p], fruit.data[p + 1], fruit.data[p + 2]);
			if (label == MAXUINT32) continue;
			supply_cnt[label]++;
			if (label < MAX_CELL_NUM - 1)
				supply_total++;
		}

		fruit.release();

		char prob_file_path[256] = { 0 };
		sprintf(prob_file_path, "%s\\%s\\"PROB_PATH, GARDEN_PATH, params->session, i);
		if (fopen_s(&fp, prob_file_path, "rb") != 0) return false;
		if (fread(supply_prob, sizeof(double), MAX_CELL_NUM, fp) != MAX_CELL_NUM)
		{
			fclose(fp);
			return false;
		}
		fclose(fp);
		for (int l = 0; l < MAX_CELL_NUM; l++)
			supply_prob_sum[l] += supply_prob[l];
	}


	demand_elasticity = (demand_total != 0 && supply_total != 0) ? (double)demand_total / (double)supply_total : 0.0;

	for (int i = 0; i < MAX_CELL_NUM - 1; i++)
	{
		supply_rate[i] = (supply_cnt[i] != 0 && demand_cnt[i] != 0) ? supply_cnt[i] / (double)demand_cnt[i] * 100 : 0.0;
		quality_rate[i] = (supply_cnt[i] != 0 && demand_cnt[i] != 0) ? supply_prob_sum[i] / (double)supply_cnt[i] * 100 : 0.0;
	}

	char sales_file_path[256] = { 0 };
	sprintf(sales_file_path, "%s\\%s\\"SALES_PATH, GARDEN_PATH, params->session);
	errno_t err = fopen_s(&fp, sales_file_path, "w");
	if (err != 0) return false;

	fprintf_s(fp, "{\n");
	fprintf_s(fp, "  \"result code\": %d,\n", 0);
	fprintf_s(fp, "  \"demand total\": %llu,\n", demand_total);
	fprintf_s(fp, "  \"supply total\": %llu,\n", supply_total);
	fprintf_s(fp, "  \"demand elasticity\": %f,\n", demand_elasticity);
	fprintf_s(fp, "  \"sales\": [\n");
	for (int i = 0; i < MAX_CELL_NUM - 1; i++)
	{
		fprintf_s(fp, "    {\n");
		fprintf_s(fp, "      \"label\": %d,\n", i);
		fprintf_s(fp, "      \"demand\": %llu,\n", demand_cnt[i]);
		fprintf_s(fp, "      \"supply\": %llu,\n", supply_cnt[i]);
		//fprintf_s(fp, "      \"rate\": %f,\n", quality_rate[i]);
		fprintf_s(fp, "      \"rate\": 0,\n");

		if (supply_rate[i] >= 50.0 && quality_rate[i] >= 50.0)
			fprintf_s(fp, "      \"result\": %s\n", "\"yes\"");
		else
			fprintf_s(fp, "      \"result\": %s\n", "\"no\"");

		if (i < MAX_CELL_NUM - 2)
			fprintf_s(fp, "    },\n");
		else
			fprintf_s(fp, "    }\n");
	}
	fprintf_s(fp, "  ]\n");
	fprintf_s(fp, "}\n");

	fclose(fp);

#if 1
	char sales_score_file_path[256] = { 0 };
	sprintf(sales_score_file_path, "%s\\%s\\"SALES_SCORE_PATH, GARDEN_PATH, params->session);
	err = fopen_s(&fp, sales_score_file_path, "w");
	if (err != 0) return false;

	fprintf_s(fp, "{\n");
	fprintf_s(fp, "  \"result code\": %d,\n", 0);
	fprintf_s(fp, "  \"demand total\": %llu,\n", demand_total);
	fprintf_s(fp, "  \"supply total\": %llu,\n", supply_total);
	fprintf_s(fp, "  \"demand elasticity\": %f,\n", demand_elasticity);
	fprintf_s(fp, "  \"sales\": [\n");
	for (int i = 0; i < MAX_CELL_NUM - 1; i++)
	{
		fprintf_s(fp, "    {\n");
		fprintf_s(fp, "      \"label\": %d,\n", i);
		fprintf_s(fp, "      \"demand\": %llu,\n", demand_cnt[i]);
		fprintf_s(fp, "      \"supply\": %llu,\n", supply_cnt[i]);
		fprintf_s(fp, "      \"supply rate\": %f,\n", supply_rate[i]);
		fprintf_s(fp, "      \"quality rate\": %f,\n", quality_rate[i]);

		if (supply_rate[i] >= 50.0 && quality_rate[i] >= 50.0)
			fprintf_s(fp, "      \"result\": %s\n", "\"yes\"");
		else
			fprintf_s(fp, "      \"result\": %s\n", "\"no\"");

		if (i < MAX_CELL_NUM - 2)
			fprintf_s(fp, "    },\n");
		else
			fprintf_s(fp, "    }\n");
	}
	fprintf_s(fp, "  ]\n");
	fprintf_s(fp, "}\n");

	fclose(fp);
#endif

	return true;
}