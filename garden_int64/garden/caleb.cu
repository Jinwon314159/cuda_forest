#include "garden.cuh"
#include "inspector.cuh" // linear regression

#define NUTRIENTS_COUNT 5
//#define SUN 1
#define FER 1 // fertilizer factory
//#define LINEAR 1 // linear regression

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

#define THREADS_NUM 8 // BUCKET_SIZE를 나누었을 때 정수여야 한다.
#define DISTANCE_THRESHOLD 2
void mean_shift(float *data, int *x, int *y);
void visualize(garden_truck *truck);

//#define UNIFORM_DISTRIBUTED_NUTRIENTS
#define ITERATION_STEP 5
#define ITERATION 25  // 5 * 5
int sequence_x[ITERATION] = { 2, 2, 1, 2, 3, 1, 1, 3, 3, 2, 0, 2, 4, 1, 0, 0, 1, 3, 4, 4, 3, 0, 0, 4, 4 };
int sequence_y[ITERATION] = { 2, 1, 2, 3, 2, 1, 3, 3, 1, 0, 2, 4, 2, 0, 1, 3, 4, 4, 3, 1, 0, 0, 4, 4, 0 };

int main(int argc, char* argv[])
{
	cudaDeviceReset();

	// tools
	if (!tools.prepare(T, -BUCKET_HEIGHT / 4, BUCKET_HEIGHT / 4)) return -1;

	// plant
	g.build(&truck, &greenhouse, &tools, &variety, T);

	if (argc > 1 && strcmp(argv[1], "test") == 0)
	{
		truck.do_harvest = true;
	}

	// replant trees from warehouse_
	if (truck.move_trees_from_warehouse("trees_0.warehouse", truck.do_harvest))
	{
		g.replant_from_truck(&truck, &greenhouse, &tools, &variety, truck.T);
	}
	// _replant trees from warehouse

	int start_index = 0;
	int end_index = 83; //1252; // 308; // 4040
	end_index++;
	int fertilizer_step = 84; // 1000;
	int fertilizer_count = 0;
	js_mart js_mart_;
	int harvest_count = 0;

	cudaEvent_t start, stop;
	float elapsed;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

#if LINEAR
	inspector inspector_;
	inspector_.init(end_index - start_index);
#endif

#ifdef UNIFORM_DISTRIBUTED_NUTRIENTS
	while (1)
	for (int iteration = 0; iteration < ITERATION; iteration++)
#else
	int iteration = 0;
	while (1)
#endif
	{
		printf("<<iteration: %d>>\n", iteration);
		cudaEventRecord(start, 0);

		// move to greenhouse
		if (!truck.do_harvest)
			if (!g.move_to_greenhouse()) return -1;

		for (int s = start_index; s < end_index; s += fertilizer_step)
		{
			int e = (s + fertilizer_step > end_index ) ? end_index : s + fertilizer_step;
			fertilizer_factory.order(s, e, &fertilizer_count);

			truck.load_water(s, e);

			for (int i = s; i < e; i++)
			{
#ifdef UNIFORM_DISTRIBUTED_NUTRIENTS
				fertilizer_factory.delivery(&truck, i - s, ITERATION_STEP, sequence_x[iteration], sequence_y[iteration]);
#else
				fertilizer_factory.delivery(&truck, i - s);
#endif
				if (truck.do_harvest)	// test
				{
					if (!g.harvest(&truck)) return -1;
					js_mart_.packaging(truck.finest_fruits, truck.finest_fruits_count);
#if LINEAR
					if (s < 84)
						inspector_.set_value(truck.finest_fruits, truck.finest_fruits_count, i);
					else
						inspector_.test(truck.finest_fruits, truck.finest_fruits_count, i);
#endif
				}
				else {	// training
					if (!g.give(&truck)) return -1;
					truck.calculate_error_rate();
				}
			}
#if LINEAR
			inspector_.check_direction();
			inspector_.clear();
#endif
		}

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

		cudaEventRecord(stop, 0);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&elapsed, start, stop);
		printf("[%d] taken time: %3.1f ms\n", iteration, elapsed);
		printf("\n");

		harvest_count++;
		if (truck.do_harvest && harvest_count >= (end_index - start_index))
		{
			break;
		}

#ifndef UNIFORM_DISTRIBUTED_NUTRIENTS
		iteration++;
#endif
	};
	
	//fertilizer_factory.destroy();
	
	return 0;
}

void mean_shift(float *data, int *x, int *y)
{
	cv::Point step = { 4, 4 };// { (int)distance * 5, (int)distance * 5 };
	cv::Point center_pre = { BUCKET_WIDTH / 2 - 1, BUCKET_HEIGHT / 2 - 1 };
	cv::Point center_cur = { 0, 0 };
	cv::Point p1_window = { center_pre.x - BUCKET_WIDTH / 2, center_pre.y - BUCKET_WIDTH / 2 };
	cv::Point p2_window = { center_pre.x + BUCKET_WIDTH / 2, center_pre.y + BUCKET_WIDTH / 2 };
	double distance = DBL_MAX;
	for (int n = 0; n < 1000; n++)
	{
		// 무게 중심을 구한다
		double sum[THREADS_NUM] = { 0 }, sum_x[THREADS_NUM] = { 0 }, sum_y[THREADS_NUM] = { 0 };
#pragma omp parallel num_threads(THREADS_NUM)
		{
			int i = 0;
			int t = omp_get_thread_num();
			for (i = t * (BUCKET_SIZE / THREADS_NUM); i < (t + 1) * (BUCKET_SIZE / THREADS_NUM); i++)
			{
				int x = i % BUCKET_WIDTH;
				int y = (int)(i / BUCKET_WIDTH);
				if (x < p1_window.x || x > p2_window.x || y < p1_window.y || y > p2_window.y)
					continue;
				sum[t] += (double)data[i];
				sum_x[t] += (double)data[i] * (double)x;
				sum_y[t] += (double)data[i] * (double)y;
			}
		};
		for (int t = 1; t < THREADS_NUM; t++)
		{
			sum[0] += sum[t];
			sum_x[0] += sum_x[t];
			sum_y[0] += sum_y[t];
		}
		center_cur.x = sum_x[0] / sum[0];
		center_cur.y = sum_y[0] / sum[0];
		//printf("mean: (%d, %d)\n", mean_x, mean_y);

#if 0
		cv::Mat img32, cimg;
		img32 = cv::Mat(BUCKET_HEIGHT, BUCKET_WIDTH, CV_32FC1, data).clone();
		cv::cvtColor(img32, cimg, CV_GRAY2BGR);

		cv::rectangle(cimg, p1_window, p2_window, cv::Scalar(0, 0, 255), 3);
		cv::circle(cimg, center_cur, 7, cv::Scalar(0, 255, 0), -1);

		cv::imshow("mean_shift", cimg);
		cv::imwrite("C:\\Users\\Joshua.Lee\\Desktop\\mean_shift.bmp", cimg);
#endif

		// distance 구하기
		cv::Point p_diff = { center_cur.x - center_pre.x, center_cur.y - center_pre.y };
		distance = sqrt(pow(p_diff.x, 2) + pow(p_diff.y, 2));

		// 윈도우 크기를 다시 설정
		p1_window += p_diff;
		if (p1_window.x + step.x < center_cur.x || p1_window.y + step.y < center_cur.y)
			p1_window += step; // += (p2_center - p1_window) / 2; // 

		p2_window += p_diff;
		if (p2_window.x - step.x > center_cur.x || p2_window.y - step.y > center_cur.y)
			p2_window -= step; // -= (p2_window - p2_center) / 2; // 

		if (n > 30 && distance < DISTANCE_THRESHOLD && center_cur.x - p1_window.x < step.x * 4)
			break;

		// 윈도우 중심 위치를 다시 설정
		center_pre = center_cur;

		int c = cv::waitKey(30);
	}
	*x = center_cur.x;
	*y = center_cur.y;
}

void visualize(garden_truck *truck)
{
	cv::Vec3b data[BUCKET_SIZE] = { 0x5F, 0x5F, 0x5F };
	cv::Mat img = cv::Mat(BUCKET_HEIGHT, BUCKET_WIDTH, CV_8UC3, (void*)data).clone();
	img.convertTo(img, CV_8UC3, 0xFF, 0xFF);

#pragma omp parallel for
	for (int i = 0; i < truck->nutrients_count; i++)
	{
		int x = truck->nutrients[i].x;
		int y = truck->nutrients[i].y;
		if (truck->fruits[i].label == 0)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(36, 28, 237);
		if (truck->fruits[i].label == 1)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(29, 230, 168);
		if (truck->fruits[i].label == 2)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(84, 79, 33);
		if (truck->fruits[i].label == 3)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(76, 177, 34);
		if (truck->fruits[i].label == 4)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(84, 33, 33);
		if (truck->fruits[i].label == 5)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(239, 183, 0);
		if (truck->fruits[i].label == 6)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(222, 255, 104);
		if (truck->fruits[i].label == 7)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(243, 109, 77);
		if (truck->fruits[i].label == 8)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(33, 84, 79);
		if (truck->fruits[i].label == 9)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(0, 242, 255);
		if (truck->fruits[i].label == 10)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(42, 33, 84);
		if (truck->fruits[i].label == 11)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(14, 194, 255);
		if (truck->fruits[i].label == 12)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(193, 94, 255);
		if (truck->fruits[i].label == 13)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(0, 126, 255);
		if (truck->fruits[i].label == 14)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(189, 249, 255);
		if (truck->fruits[i].label == 15)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(188, 249, 211);
		if (truck->fruits[i].label == 16)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(213, 165, 181);
		if (truck->fruits[i].label == 17)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(153, 54, 47);
		if (truck->fruits[i].label == 18)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(79, 33, 84);
		if (truck->fruits[i].label == 19)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(177, 163, 255);
		if (truck->fruits[i].label == 20)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(142, 255, 86);
		if (truck->fruits[i].label == 21)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(156, 228, 245);
		if (truck->fruits[i].label == 22)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(97, 187, 157);
		if (truck->fruits[i].label == 23)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(152, 49, 111);
		if (truck->fruits[i].label == 24)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(84, 33, 69);
		if (truck->fruits[i].label == 25)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(60, 90, 156);
		if (truck->fruits[i].label == 26)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(146, 122, 255);
		if (truck->fruits[i].label == 27)
			img.at<cv::Vec3b>(y, x) = cv::Vec3b(122, 170, 229);
	}

	int x[MAX_CELL_NUM] = { 0 };
	int y[MAX_CELL_NUM] = { 0 };
	float **mean_shift_data = (float**)malloc(MAX_CELL_NUM * sizeof(float*));
#pragma omp parallel for
	for (int j = 0; j < MAX_CELL_NUM; j++)
		mean_shift_data[j] = (float*)calloc(BUCKET_SIZE, sizeof(float));
	//memset(data, 255.0f, sizeof(float) * BUCKET_SIZE);

#pragma omp parallel for
	for (int n = 0; n < truck->nutrients_count; n++)
	{
		int x = truck->nutrients[n].x;
		int y = truck->nutrients[n].y;
		int idx = y * BUCKET_WIDTH + x;
		//if (truck.fruits[n].label == 0)
		mean_shift_data[truck->fruits[n].label][idx] = (float)truck->branches[truck->fruits[n].branch_index].cells[truck->fruits[n].label] / (float)truck->branches[truck->fruits[n].branch_index].total_nutrients;
	}

	for (int j = 0; j < MAX_CELL_NUM; j++)
		mean_shift(mean_shift_data[j], &x[j], &y[j]);

	for (int j = 0; j < MAX_CELL_NUM; j++)
	{
		cv::Point p = { x[j], y[j] };
		cv::circle(img, p, 7, cv::Scalar(0, 0, 0), -1);
	}
	//cv::imwrite("joint.bmp", joint);
	cv::imwrite("result.bmp", img);
}