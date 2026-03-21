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

#define THREADS_NUM 8 // BUCKET_SIZE를 나누었을 때 정수여야 한다.
#define DISTANCE_THRESHOLD 2

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
			else
				break;

			p2_window += p_diff;
			if (p2_window.x - step.x > center_cur.x || p2_window.y - step.y > center_cur.y)
				p2_window -= step; // -= (p2_window - p2_center) / 2; // 
			else
				break;

			//if (n > 30 && distance < DISTANCE_THRESHOLD && center_cur.x - p1_window.x < step.x * 4)
			if (distance < DISTANCE_THRESHOLD)
				break;

			// 윈도우 중심 위치를 다시 설정
			center_pre = center_cur;

			//int c = cv::waitKey(30);
		}
		*x = center_cur.x;
		*y = center_cur.y;
	};

	void visualize(garden_truck *truck, int *x, int *y)
	{
#if 0
		cv::Vec3b data[BUCKET_SIZE] = { 0x5F, 0x5F, 0x5F };
		cv::Mat img = cv::Mat(BUCKET_HEIGHT, BUCKET_WIDTH, CV_8UC3, (void*)data).clone();
		img.convertTo(img, CV_8UC3, 0xFF, 0xFF);

#pragma omp parallel for
		for (int i = 0; i < truck->nutrients_count; i++)
		{
			int x = truck->nutrients[i].x;
			int y = truck->nutrients[i].y;
			if (truck->finest_fruits[i].label == 0)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(36, 28, 237);
			if (truck->finest_fruits[i].label == 1)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(29, 230, 168);
			if (truck->finest_fruits[i].label == 2)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(84, 79, 33);
			if (truck->finest_fruits[i].label == 3)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(76, 177, 34);
			if (truck->finest_fruits[i].label == 4)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(84, 33, 33);
			if (truck->finest_fruits[i].label == 5)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(239, 183, 0);
			if (truck->finest_fruits[i].label == 6)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(222, 255, 104);
			if (truck->finest_fruits[i].label == 7)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(243, 109, 77);
			if (truck->finest_fruits[i].label == 8)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(33, 84, 79);
			if (truck->finest_fruits[i].label == 9)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(0, 242, 255);
			if (truck->finest_fruits[i].label == 10)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(42, 33, 84);
			if (truck->finest_fruits[i].label == 11)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(14, 194, 255);
			if (truck->finest_fruits[i].label == 12)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(193, 94, 255);
			if (truck->finest_fruits[i].label == 13)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(0, 126, 255);
			if (truck->finest_fruits[i].label == 14)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(189, 249, 255);
			if (truck->finest_fruits[i].label == 15)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(188, 249, 211);
			if (truck->finest_fruits[i].label == 16)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(213, 165, 181);
			if (truck->finest_fruits[i].label == 17)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(153, 54, 47);
			if (truck->finest_fruits[i].label == 18)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(79, 33, 84);
			if (truck->finest_fruits[i].label == 19)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(177, 163, 255);
			if (truck->finest_fruits[i].label == 20)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(142, 255, 86);
			if (truck->finest_fruits[i].label == 21)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(156, 228, 245);
			if (truck->finest_fruits[i].label == 22)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(97, 187, 157);
			if (truck->finest_fruits[i].label == 23)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(152, 49, 111);
			if (truck->finest_fruits[i].label == 24)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(84, 33, 69);
			if (truck->finest_fruits[i].label == 25)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(60, 90, 156);
			if (truck->finest_fruits[i].label == 26)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(146, 122, 255);
			if (truck->finest_fruits[i].label == 27)
				img.at<cv::Vec3b>(y, x) = cv::Vec3b(122, 170, 229);
		}
#endif

		float **mean_shift_data = (float**)malloc(MAX_CELL_NUM * sizeof(float*));
#pragma omp parallel for
		for (int j = 0; j < MAX_CELL_NUM; j++)
			mean_shift_data[j] = (float*)calloc(BUCKET_SIZE, sizeof(float));
		//memset(data, 255.0f, sizeof(float) * BUCKET_SIZE);

#pragma omp parallel for
		for (int n = 0; n < truck->nutrients_count; n++)
		{
			int px = truck->finest_fruits[n].x;
			int py = truck->finest_fruits[n].y;
			int idx = py * BUCKET_WIDTH + px;
			mean_shift_data[truck->finest_fruits[n].label][idx] = truck->finest_fruits[n].probability; // (float)truck->branches[.branch_index].cells[truck->finest_fruits[n].label] / (float)truck->branches[truck->finest_fruits[n].branch_index].total_nutrients;
		}

#if 1
		for (int j = 0; j < MAX_CELL_NUM; j++)
			mean_shift(mean_shift_data[j], &x[j], &y[j]);
#else
		mean_shift(mean_shift_data[0], &x[0], &y[0]);
#endif

#if 0
		for (int j = 0; j < MAX_CELL_NUM; j++)
		{
			cv::Point p = { x[j], y[j] };
			cv::circle(img, p, 7, cv::Scalar(0, 0, 0), -1);
		}
		//cv::imwrite("joint.bmp", joint);
		cv::imwrite("./data/result/result.bmp", img);
#endif
	};
};