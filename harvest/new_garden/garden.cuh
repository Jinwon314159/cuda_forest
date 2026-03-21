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

		for (int b = 0; b < 6; b++)
		{
			mean_shift_data[b] = (double**)malloc(MAX_CELL_NUM * sizeof(double*));
#pragma omp parallel for
			for (int j = 0; j < MAX_CELL_NUM; j++)
				mean_shift_data[b][j] = (double*)calloc(BUCKET_SIZE, sizeof(double));

			mean_shift_xdata[b] = (double**)malloc(MAX_CELL_NUM * sizeof(double*));
#pragma omp parallel for
			for (int j = 0; j < MAX_CELL_NUM; j++)
				mean_shift_xdata[b][j] = (double*)calloc(BUCKET_SIZE, sizeof(double));

			mean_shift_ydata[b] = (double**)malloc(MAX_CELL_NUM * sizeof(double*));
#pragma omp parallel for
			for (int j = 0; j < MAX_CELL_NUM; j++)
				mean_shift_ydata[b][j] = (double*)calloc(BUCKET_SIZE, sizeof(double));
		}
	};

	~garden(){
		destroy();

		cudaDeviceReset();

		for (int b = 0; b < 6; b++)
		{
			for (int j = 0; j < MAX_CELL_NUM; j++)
				free(mean_shift_data[b][j]);
			free(mean_shift_data[b]);

			for (int j = 0; j < MAX_CELL_NUM; j++)
				free(mean_shift_xdata[b][j]);
			free(mean_shift_xdata[b]);

			for (int j = 0; j < MAX_CELL_NUM; j++)
				free(mean_shift_ydata[b][j]);
			free(mean_shift_ydata[b]);
		}

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

	unsigned __int64 branches_count;
	unsigned __int64 endpoints_count;

	size_t in_mem_size;

	double** mean_shift_data[6];
	double** mean_shift_xdata[6];
	double** mean_shift_ydata[6];
	int sx[6][MAX_CELL_NUM];
	int sy[6][MAX_CELL_NUM];
	int ex[6][MAX_CELL_NUM];
	int ey[6][MAX_CELL_NUM];


	void integral_image_cpu(double* in, int w, int h)
	{
		for (int x = 1; x < w; x++)
			in[x] += in[x - 1];
		for (int y = w; y < h * w; y += w)
			in[y] += in[y - w];
		for (int y = 1; y < h; y++)
		{
			unsigned int i = y * w;
			for (int x = 1; x < w; x++)
			{
				unsigned int j = i + x;
				in[j] = in[j] + in[j - 1] + in[j - BUCKET_WIDTH] - in[j - BUCKET_WIDTH - 1];
			}
		}
	};

	void integral_image_cpu2(double* in, int w, int h, int sx, int sy, int ex, int ey)
	{
		for (int x = sx + 1; x < ex + 1; x++)
			in[x] += in[x - 1];
		for (int y = sy + w; y < (ey + 1) * w; y += w)
			in[y] += in[y - w];
		for (int y = sy + 1; y < ey + 1; y++)
		{
			unsigned int i = y * w;
			for (int x = sx + 1; x < ex + 1; x++)
			{
				unsigned int j = i + x;
				in[j] = in[j] + in[j - 1] + in[j - BUCKET_WIDTH] - in[j - BUCKET_WIDTH - 1];
			}
		}
	};
	
	void mean_shift(double *data, int *x, int *y)
	{
		cv::Point step = { 10, 10 };// { (int)distance * 5, (int)distance * 5 };
		cv::Point center_pre = { BUCKET_WIDTH / 2 - 1, BUCKET_HEIGHT / 2 - 1 };
		cv::Point center_cur = { 0, 0 };
		cv::Point window_s = { center_pre.x - BUCKET_WIDTH / 2, center_pre.y - BUCKET_WIDTH / 2 };
		cv::Point window_e = { center_pre.x + BUCKET_WIDTH / 2, center_pre.y + BUCKET_WIDTH / 2 };
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
					if (x < window_s.x || x > window_e.x || y < window_s.y || y > window_e.y)
						continue;
					sum[t] += data[i];
					sum_x[t] += data[i] * x;
					sum_y[t] += data[i] * y;
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
			// printf("mean: (%d, %d)\n", mean_x, mean_y);

			// distance 구하기
			cv::Point p_diff = { center_cur.x - center_pre.x, center_cur.y - center_pre.y };
			distance = sqrt(pow(p_diff.x, 2) + pow(p_diff.y, 2));

			// 윈도우 크기를 다시 설정
			window_s += p_diff;
			if (window_s.x + step.x < center_cur.x || window_s.y + step.y < center_cur.y)
				window_s += step; // += (p2_center - window_s) / 2; // 
			else
				break;

			window_e += p_diff;
			if (window_e.x - step.x > center_cur.x || window_e.y - step.y > center_cur.y)
				window_e -= step; // -= (window_e - p2_center) / 2; // 
			else
				break;

			//if (n > 30 && distance < DISTANCE_THRESHOLD && center_cur.x - window_s.x < step.x * 4)
			if (distance < DISTANCE_THRESHOLD)
				break;

			// 윈도우 중심 위치를 다시 설정
			center_pre = center_cur;

			//int c = cv::waitKey(30);
		}
		*x = center_cur.x;
		*y = center_cur.y;
	};

	void mean_shift_from_integral_image(double *data, double* xdata, double* ydata, int *x, int *y, int sx, int sy, int ex, int ey)
	{
		cv::Point step = { 4, 4 }; // { (ex - sx) / 4 + 1, (ey - sy) / 4 + 1 };// { (int)distance * 5, (int)distance * 5 };
#if 0
		cv::Point center_pre = { BUCKET_WIDTH / 2, BUCKET_HEIGHT / 2 };
		cv::Point center_cur = { 0, 0 };
		cv::Point window_s = { center_pre.x - BUCKET_WIDTH / 2 + BUCKET_MARGIN, center_pre.y - BUCKET_HEIGHT / 2 + BUCKET_MARGIN };
		cv::Point window_e = { center_pre.x + BUCKET_WIDTH / 2 - BUCKET_MARGIN, center_pre.y + BUCKET_HEIGHT / 2 - BUCKET_MARGIN };
#else
		cv::Point center_pre = { (ex - sx) / 2, (ey - sy) / 2 };
		cv::Point center_cur = { 0, 0 };
		cv::Point window_s = { sx + BUCKET_MARGIN, sy + BUCKET_MARGIN };
		cv::Point window_e = { ex - BUCKET_MARGIN, ey - BUCKET_MARGIN };
#endif
		int A_index = 0, B_index = 0, C_index = 0, D_index = 0;
		double A = 0.0, B = 0.0, C = 0.0, D = 0.0;
		double distance = DBL_MAX;
		for (int n = 0; n < 1000; n++)
		{
			A_index = (window_s.y - 1) * BUCKET_WIDTH + (window_s.x - 1);
			B_index = (window_s.y - 1) * BUCKET_WIDTH + window_e.x;
			C_index = window_e.y * BUCKET_WIDTH + (window_s.x - 1);
			D_index = window_e.y * BUCKET_WIDTH + window_e.x;

			// 무게 중심을 구한다
			double sum = data[D_index] - data[B_index] - data[C_index] + data[A_index];
			double sum_x = xdata[D_index] - xdata[B_index] - xdata[C_index] + xdata[A_index];
			double sum_y = ydata[D_index] - ydata[B_index] - ydata[C_index] + ydata[A_index];

			center_cur.x = sum_x / sum;
			center_cur.y = sum_y / sum;

			cv::Point p_diff = { center_cur.x - center_pre.x, center_cur.y - center_pre.y };

			// distance 구하기
			distance = sqrt(pow(p_diff.x, 2) + pow(p_diff.y, 2));
			if (distance < DISTANCE_THRESHOLD)
				break;

			// 윈도우 크기를 다시 설정
			window_s += p_diff;
			window_e += p_diff;

#if 0
			step.x = (window_e.x - window_s.x) / 4 + 1;
			step.y = (window_e.y - window_s.y) / 4 + 1;
#endif

			if (window_s.x + step.x < center_cur.x - 8 || window_s.y + step.y < center_cur.y - 8)
			{
				window_s += step; // += (p2_center - window_s) / 2; // 
				window_s.x = (window_s.x < BUCKET_MARGIN) ? BUCKET_MARGIN : window_s.x;
				window_s.y = (window_s.y < BUCKET_MARGIN) ? BUCKET_MARGIN : window_s.y;
			}
			else
				break;

			if (window_e.x - step.x > center_cur.x + 8 || window_e.y - step.y > center_cur.y + 8)
			{
				window_e -= step; // -= (window_e - p2_center) / 2; // 
				window_e.x = (window_e.x >= BUCKET_WIDTH - BUCKET_MARGIN) ? BUCKET_WIDTH - BUCKET_MARGIN : window_e.x;
				window_e.y = (window_e.y >= BUCKET_HEIGHT - BUCKET_MARGIN) ? BUCKET_HEIGHT - BUCKET_MARGIN : window_e.y;
			}
			else
				break;

			if (window_s.x >= window_e.x || window_s.y >= window_e.y)
				break;

			// 윈도우 중심 위치를 다시 설정
			center_pre = center_cur;
		}
		*x = center_cur.x;
		*y = center_cur.y;
	};

	void visualize(garden_truck *truck, int x[][MAX_CELL_NUM], int y[][MAX_CELL_NUM], unsigned char* body_index_data, int* tracked, int joints_tracked[][MAX_CELL_NUM])
	{
		for (int b = 0; b < 6; b++)
		{
#pragma omp parallel for
			for (int j = 0; j < MAX_CELL_NUM; j++)
			{
				memset(mean_shift_data[b][j], 0.0, sizeof(double) * BUCKET_SIZE);
				memset(mean_shift_xdata[b][j], 0.0, sizeof(double) * BUCKET_SIZE);
				memset(mean_shift_ydata[b][j], 0.0, sizeof(double) * BUCKET_SIZE);
			};
		}

		for (int b = 0; b < 6; b++)
		{
			if (tracked[b] != 1) continue;
			for (int j = 0; j < MAX_CELL_NUM; j++)
			{
				sx[b][j] = BUCKET_WIDTH - 1;
				sy[b][j] = BUCKET_HEIGHT - 1;
			}
			memset(ex[b], 0, sizeof(int) * MAX_CELL_NUM);
			memset(ey[b], 0, sizeof(int) * MAX_CELL_NUM);
		}

#pragma omp parallel for
		for (int n = 0; n < truck->nutrients_count; n++)
		{
			int px = truck->finest_fruits[n].x;
			int py = truck->finest_fruits[n].y;
			int i = py * BUCKET_WIDTH + px;
			int b = body_index_data[i];
			if (b > 6) continue;

#ifdef FINEST_ONLY
			int j = truck->finest_fruits[n].label;

			joints_tracked[b][j] = 1;

			if (px < sx[b][j])
				sx[b][j] = px;
			if (py < sy[b][j])
				sy[b][j] = py;
			if (px > ex[b][j])
				ex[b][j] = px;
			if (py > ey[b][j])
				ey[b][j] = py;
			mean_shift_data[b][j][i] = truck->finest_fruits[n].probability;
			mean_shift_xdata[b][j][i] = px * truck->finest_fruits[n].probability;
			mean_shift_ydata[b][j][i] = py * truck->finest_fruits[n].probability;
#else
			for (int j = 0; j < MAX_CELL_NUM; j++)
			{
				if (truck->finest_fruits[n].probability[j] == 0.0) continue;
	
				if (px < sx[b][j])
					sx[b][j] = px;
				if (py < sy[b][j])
					sy[b][j] = py;
				if (px > ex[b][j])
					ex[b][j] = px;
				if (py > ey[b][j])
					ey[b][j] = py;

				mean_shift_data[b][j][i] = truck->finest_fruits[n].probability[j];
				mean_shift_xdata[b][j][i] = px * truck->finest_fruits[n].probability[j];
				mean_shift_ydata[b][j][i] = py * truck->finest_fruits[n].probability[j];
			}
#endif
		}

		for (int b = 0; b < 6; b++)
		{
			if (tracked[b] != 1) continue;

#if 0
			cv::Mat img = cv::Mat(BUCKET_HEIGHT, BUCKET_WIDTH, CV_64FC1, mean_shift_data[b][0]).clone();
			cv::imshow("img", img);
			cv::waitKey(1);
#endif

			// to generate integral image
#pragma omp parallel for
			for (int j = 0; j < MAX_CELL_NUM; j++)
			{
#if 0
				integral_image_cpu(mean_shift_data[b][j], BUCKET_WIDTH, BUCKET_HEIGHT);
				integral_image_cpu(mean_shift_xdata[b][j], BUCKET_WIDTH, BUCKET_HEIGHT);
				integral_image_cpu(mean_shift_ydata[b][j], BUCKET_WIDTH, BUCKET_HEIGHT);
#else
				integral_image_cpu2(mean_shift_data[b][j], BUCKET_WIDTH, BUCKET_HEIGHT, sx[b][j], sy[b][j], ex[b][j], ey[b][j]);
				integral_image_cpu2(mean_shift_xdata[b][j], BUCKET_WIDTH, BUCKET_HEIGHT, sx[b][j], sy[b][j], ex[b][j], ey[b][j]);
				integral_image_cpu2(mean_shift_ydata[b][j], BUCKET_WIDTH, BUCKET_HEIGHT, sx[b][j], sy[b][j], ex[b][j], ey[b][j]);
#endif
				if (sx[b][j] + 2 * BUCKET_MARGIN < ex[b][j] && sy[b][j] + 2 * BUCKET_MARGIN < ey[b][j])
					mean_shift_from_integral_image(mean_shift_data[b][j], mean_shift_xdata[b][j], mean_shift_ydata[b][j], &x[b][j], &y[b][j], sx[b][j], sy[b][j], ex[b][j], ey[b][j]);
			};

#if 0
			cv::Mat img2 = cv::Mat(BUCKET_HEIGHT, BUCKET_WIDTH, CV_64FC1, mean_shift_data[b][0]).clone();
			cv::imshow("img2", img2);
			cv::waitKey(1);
#endif
		}

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