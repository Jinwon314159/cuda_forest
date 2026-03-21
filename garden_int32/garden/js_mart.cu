#include "js_mart.cuh"

void js_mart::packaging(fig_finest_fruit* finest_fruits, int count)
{
	cv::Mat result(P_HEIGHT, P_WIDTH, CV_8UC3, cv::Scalar(255, 255, 255));

	for (int i = 0; i < count; i++)
	{
		int x_ = finest_fruits[i].x;
		int y_ = finest_fruits[i].y;
		int label_ = finest_fruits[i].label;
		if (finest_fruits[i].label >= 0 && finest_fruits[i].probability > 0.5)
		{
			result.at<cv::Vec3b>(y_, x_) = this->wrapping_paper.at<cv::Vec3b>(label_, 0);
		}
	}
	
	cv::String filepath;

	char *fpath = new char[256];
	sprintf(fpath, "./data/result/test_%d.png", this->num);
	filepath = fpath;

	cv::imwrite(filepath, result);

	(this->num)++;
}