#include "js_mart.cuh"

void js_mart::packaging(char* session_path, fig_finest_fruit* finest_fruits, int count)
{
	cv::Mat result(BUCKET_HEIGHT, BUCKET_WIDTH, CV_8UC3, cv::Scalar(255, 255, 255));

	for (int i = 0; i < count; i++)
	{
		int x_ = finest_fruits[i].x;
		int y_ = finest_fruits[i].y;
		int label_ = finest_fruits[i].label;
		if (finest_fruits[i].label >= 0 && finest_fruits[i].probability >= 0.5)
			result.at<cv::Vec3b>(y_, x_) = this->wrapping_paper.at<cv::Vec3b>(label_, 0);
		else
			result.at<cv::Vec3b>(y_, x_) = this->wrapping_paper.at<cv::Vec3b>(MAX_CELL_NUM - 1, 0);

#if 0
		if (i % 1000 == 0)
			printf("prob: %f\n", finest_fruits[i].probability);
#endif
	}
	
	char result_file_path[256] = { 0 };
	sprintf(result_file_path, "%s\\%s\\"FRUIT_PATH, GARDEN_PATH, session_path, this->num);
	cv::imwrite(result_file_path, result);
	result.release();

	this->num++;
}