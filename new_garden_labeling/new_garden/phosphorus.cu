#include "phosphorus.cuh"

bool phosphorus::writeNutrients(fig_nutrient* nutrient_, int cnt, int idx)
{
	if (cnt == 0)
		return false;

	// cnt : 클래스 인덱스 갯수
	// idx : 파일 번호
	FILE *dst;
	errno_t err;

	// 현재시간
	time_t current_time;
	struct tm *current_tm;
	current_time = time(NULL);
	current_tm = localtime(&current_time);

	//std::string sfilename = "./data/fig_nutrient/nutrients_";
	std::string sfilename = "./result_data/nutrients/";
	std::string current_ = std::to_string(current_tm->tm_year + 1900);
	current_ += std::to_string(current_tm->tm_mon + 1);
	current_ += std::to_string(current_tm->tm_mday);
	current_ += "_";
	current_ += std::to_string(current_tm->tm_hour);
	current_ += std::to_string(current_tm->tm_min);
	current_ += std::to_string(current_tm->tm_sec);

	this->current_file_name = current_;

	sfilename += current_;
	//sfilename += std::to_string(idx);
	sfilename += ".dat";

	const char *filename = sfilename.c_str();

	err = fopen_s(&dst, filename, "wb");
	if (err != 0)
	{
		std::cerr << "Error: writeNutrients() file open " << std::endl;
		fclose(dst);
		return false;
	}

	int write_count = fwrite(nutrient_, sizeof(fig_nutrient), cnt, dst);
	if (write_count != cnt)
	{
		std::cerr << "Error: writeNutrients() file write" << std::endl;
		fclose(dst);
		return false;
	}
	fclose(dst);

	return true;
}

bool phosphorus::readNutrients(char* path, fig_nutrient** nutrient_, int *count)
{
	FILE *fp = NULL;
	fopen_s(&fp, path, "rb");

	if (NULL == fp)
	{
		std::cerr << "Error: open nutrient file" << std::endl;
		fclose(fp);
		return false;
	}

	long len; // len = file size (bytes)
	fseek(fp, 0L, SEEK_END);
	len = ftell(fp);

	fseek(fp, 0L, SEEK_SET);

	//long nlen = sizeof(fig_nutrient);

	int fig_count = (int)(len / (long)sizeof(fig_nutrient)); // 클래스 배열 갯수
	*count = fig_count;

	//free(*nutrient_);
	*nutrient_ = (fig_nutrient*)malloc(fig_count * sizeof(fig_nutrient));


	int count_ = fread((*nutrient_), sizeof(fig_nutrient), fig_count, fp);

	if (count_ != fig_count)
	{
		std::cout << "Error: read nutrients file" << std::endl;
		fclose(fp);
		return false;
	}

	fclose(fp);

	return true;
}

bool phosphorus::writeDepthFile(UINT16* depth_data, UINT dBufferSize)
{
	FILE *dst;
	errno_t err;

	// depth file
	std::string d_filename = "./result_data/depth_raw/";
	d_filename += this->current_file_name;
	d_filename += ".dat";

	const char *dfilename = d_filename.c_str();

	// depth file
	err = fopen_s(&dst, dfilename, "wb+");
	if (err != 0)
	{
		std::cerr << "File Open error!" << std::endl;
		fclose(dst);
		return false;
	}

	err = fwrite(depth_data, sizeof(UINT16), dBufferSize, dst);
	if (err != dBufferSize)
	{
		std::cerr << "File Write error!" << std::endl;
		fclose(dst);
		return false;
	}

	fclose(dst);

	//cv::Mat d = cv::Mat(424, 512, CV_16UC1, depth_data).clone();
	//cv::imwrite("./data/aaa.png", d);

	return true;
}