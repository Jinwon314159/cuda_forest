#include "mean_shift.h"

void run()
{
	std::random_device rd;
	std::mt19937 gen(rd());
	std::uniform_int_distribution<unsigned short> dist(0, 0xFFFF);

	std::random_device rd_w;
	std::mt19937 gen_w(rd_w());
	std::normal_distribution<double> dist_w(300.0, 60.0);

	std::random_device rd_h;
	std::mt19937 gen_h(rd_h());
	std::normal_distribution<double> dist_h(150.0, 50.0);

	std::random_device rd_w1;
	std::mt19937 gen_w1(rd_w1());
	std::normal_distribution<double> dist_w1(100.0, 60.0);

	std::random_device rd_h1;
	std::mt19937 gen_h1(rd_h1());
	std::normal_distribution<double> dist_h1(250.0, 50.0);

	std::random_device rd_w2;
	std::mt19937 gen_w2(rd_w2());
	std::normal_distribution<double> dist_w2(250.0, 30.0);

	std::random_device rd_h2;
	std::mt19937 gen_h2(rd_h2());
	std::normal_distribution<double> dist_h2(400.0, 50.0);

	cv::namedWindow("mean_shift", cv::WINDOW_AUTOSIZE);
	HWND hwnd = (HWND)cvGetWindowHandle("mean_shift");
	while (IsWindowVisible(hwnd))
	{
		// to generate a random image
		unsigned short data[IMG_SZ] = { 0 };

		// 랜덤으로 임의의 샘플 이미지 생성
#pragma omp parallel for
		for (int i = 0; i < P_CNT; i++)
		{
			double x = dist_w(gen_w);
			double y = dist_h(gen_h);
			if (x < 0.0 || x > W - 1 || y < 0.0 || y > H - 1)
				continue;

			int idx = (int)y * W + (int)x;
			data[idx] = dist(gen);
		}
#pragma omp parallel for
		for (int i = 0; i < P_CNT / 2; i++)
		{
			double x = dist_w1(gen_w1);
			double y = dist_h1(gen_h1);
			if (x < 0.0 || x > W - 1 || y < 0.0 || y > H - 1)
				continue;

			int idx = (int)y * W + (int)x;
			data[idx] = dist(gen);
		}
#pragma omp parallel for
		for (int i = 0; i < P_CNT / 2; i++)
		{
			double x = dist_w2(gen_w1);
			double y = dist_h2(gen_h1);
			if (x < 0.0 || x > W - 1 || y < 0.0 || y > H - 1)
				continue;

			int idx = (int)y * W + (int)x;
			data[idx] = dist(gen);
		}


		cv::Point step = { 4, 4 };// { (int)distance * 5, (int)distance * 5 };
		cv::Point center_pre = { W / 2 - 1, H / 2 - 1 };
		cv::Point center_cur = { 0, 0 };
		cv::Point p1_window = { center_pre.x - W / 2, center_pre.y - W / 2 };
		cv::Point p2_window = { center_pre.x + W / 2, center_pre.y + W / 2 };
		double distance = DBL_MAX;
		for (int n = 0; n < 1000; n++)
		{
			// 무게 중심을 구한다
			double sum[THREADS_NUM] = { 0 }, sum_x[THREADS_NUM] = { 0 }, sum_y[THREADS_NUM] = { 0 };
#pragma omp parallel num_threads(THREADS_NUM)
			{
				int i = 0;
				int t = omp_get_thread_num();
				for (i = t * (IMG_SZ / THREADS_NUM); i < (t + 1) * (IMG_SZ / THREADS_NUM); i++)
				{
					int x = i % W;
					int y = (int)(i / W);
					if (x < p1_window.x || x > p2_window.x || y < p1_window.y || y > p2_window.y)
						continue;
					sum[t] += (double)data[i];
					sum_x[t] += (double)data[i] * (double)x;
					sum_y[t] += (double)data[i] * (double)y;
				}
			}
			for (int t = 1; t < THREADS_NUM; t++)
			{
				sum[0] += sum[t];
				sum_x[0] += sum_x[t];
				sum_y[0] += sum_y[t];
			}
			center_cur.x = sum_x[0] / sum[0];
			center_cur.y = sum_y[0] / sum[0];
			//printf("mean: (%d, %d)\n", mean_x, mean_y);

			cv::Mat img8, img16, cimg;
			img16 = cv::Mat(H, W, CV_16UC1, data).clone();
			img16.convertTo(img8, CV_8UC1);
			cv::cvtColor(img8, cimg, CV_GRAY2BGR);

			cv::rectangle(cimg, p1_window, p2_window, cv::Scalar(0, 0, 255), 3);
			cv::circle(cimg, center_cur, 7, cv::Scalar(0, 255, 0), -1);

			cv::imshow("mean_shift", cimg);

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
			if (c == 27 || c == 'x') return;
		}
		int c = cv::waitKey(0);
		if (c == 27 || c == 'x') return;
	}
}
