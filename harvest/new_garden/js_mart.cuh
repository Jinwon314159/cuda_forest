#pragma once

#include "global.cuh"

//OpenCV
#include <opencv2\opencv.hpp>
#ifdef _DEBUG
#pragma comment(lib, "opencv_world300d.lib")
#else
#pragma comment(lib, "opencv_world300.lib")
#endif

#define P_WIDTH 512
#define P_HEIGHT 424

class js_mart
{
public:
	js_mart()
	{
		this->num = 0;
		wrapping_paper = cv::Mat(28, 1, CV_8UC3);
		// B G R
		wrapping_paper.at<cv::Vec3b>(0, 0) = cv::Vec3b(188, 249, 211);
		wrapping_paper.at<cv::Vec3b>(1, 0) = cv::Vec3b(97, 187, 157);
		wrapping_paper.at<cv::Vec3b>(2, 0) = cv::Vec3b(189, 249, 255);
		wrapping_paper.at<cv::Vec3b>(3, 0) = cv::Vec3b(213, 165, 181);
		wrapping_paper.at<cv::Vec3b>(4, 0) = cv::Vec3b(29, 230, 168);
		wrapping_paper.at<cv::Vec3b>(5, 0) = cv::Vec3b(36, 28, 237);
		wrapping_paper.at<cv::Vec3b>(6, 0) = cv::Vec3b(84, 79, 33);
		wrapping_paper.at<cv::Vec3b>(7, 0) = cv::Vec3b(76, 177, 34);
		wrapping_paper.at<cv::Vec3b>(8, 0) = cv::Vec3b(84, 33, 33);
		wrapping_paper.at<cv::Vec3b>(9, 0) = cv::Vec3b(239, 183, 0);
		wrapping_paper.at<cv::Vec3b>(10, 0) = cv::Vec3b(222, 255, 104);
		wrapping_paper.at<cv::Vec3b>(11, 0) = cv::Vec3b(243, 109, 77);
		wrapping_paper.at<cv::Vec3b>(12, 0) = cv::Vec3b(33, 84, 79);
		wrapping_paper.at<cv::Vec3b>(13, 0) = cv::Vec3b(0, 242, 255);
		wrapping_paper.at<cv::Vec3b>(14, 0) = cv::Vec3b(42, 33, 84);
		wrapping_paper.at<cv::Vec3b>(15, 0) = cv::Vec3b(14, 194, 255);
		wrapping_paper.at<cv::Vec3b>(16, 0) = cv::Vec3b(193, 94, 255);
		wrapping_paper.at<cv::Vec3b>(17, 0) = cv::Vec3b(0, 126, 255);
		wrapping_paper.at<cv::Vec3b>(18, 0) = cv::Vec3b(153, 54, 47);
		wrapping_paper.at<cv::Vec3b>(19, 0) = cv::Vec3b(79, 33, 84);
		wrapping_paper.at<cv::Vec3b>(20, 0) = cv::Vec3b(177, 163, 255);
		wrapping_paper.at<cv::Vec3b>(21, 0) = cv::Vec3b(142, 255, 86);
		wrapping_paper.at<cv::Vec3b>(22, 0) = cv::Vec3b(156, 228, 245);
		wrapping_paper.at<cv::Vec3b>(23, 0) = cv::Vec3b(152, 49, 111);
		wrapping_paper.at<cv::Vec3b>(24, 0) = cv::Vec3b(84, 33, 69);
		wrapping_paper.at<cv::Vec3b>(25, 0) = cv::Vec3b(60, 90, 156);
		wrapping_paper.at<cv::Vec3b>(26, 0) = cv::Vec3b(146, 122, 255);
		wrapping_paper.at<cv::Vec3b>(27, 0) = cv::Vec3b(122, 170, 229);
	}
	void packaging(fig_finest_fruit* finest_fruits, int count);
//private:
	cv::Mat wrapping_paper;
	int num;
	//int wrapping(int label_);
};