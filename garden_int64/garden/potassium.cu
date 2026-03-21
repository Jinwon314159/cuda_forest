#include "potassium.cuh"

void potassium::writeLabelFile(UINT16* depth_data, int dWidth, int dHeight, int body_index_count)
{
	int fbodyindex_count = 0;

	// label file
	std::ofstream labelfile;
	std::string lfilename = "label_data.train.txt";

	labelfile.open(lfilename, std::ios::out | std::ios::app);

	// meta file
	std::ofstream metafile;
	std::string mfilename = "meta_data.train.txt";

	metafile.open(mfilename, std::ios::out | std::ios::app);


	if (labelfile.is_open() && metafile.is_open())
	{
		for (int y = 0; y < dHeight; y++)
		{
			for (int x = 0; x < dWidth; x++)
			{
				unsigned int index = x + y * dWidth;

				if (0xffff != depth_data[index])
				{
					labelfile << (unsigned short)1 << " " << (unsigned short)x << " " << (unsigned short)y << "\n";
					++fbodyindex_count; // 1부터 시작
				}
				else
					labelfile << (unsigned short)0 << " " << (unsigned short)x << " " << (unsigned short)y << "\n";

			}
		}// for y

		std::cout << "body index count (file function) : " << fbodyindex_count << std::endl;
		metafile << body_index_count << " ";

	}
	else
	{
		std::cerr << "Error : file open!" << std::endl;
	}
	labelfile.close();
	metafile.close();
}

void potassium::writeDepthFile(UINT16* depth_data, UINT dBufferSize, int fNum)
{
	FILE *dst;
	errno_t err;

	this->count = fNum; // set current frame number

	// depth file
	std::string d_filename = "./depth_data(";
	d_filename += std::to_string(fNum);
	d_filename += ").dat";

	const char *dfilename = d_filename.c_str();

	// depth file
	err = fopen_s(&dst, dfilename, "w+");
	if (err != 0)
	{
		std::cerr << "File Open error!" << std::endl;
		return;
	}

	err = fwrite(depth_data, sizeof(UINT16), dBufferSize, dst);
	if (err != dBufferSize)
	{
		std::cerr << "File Write error!" << std::endl;
		return;
	}

	fclose(dst);
}

bool potassium::readDepthFile(char* path, UINT16* depthData, int h, int w)
{
	FILE *fp = fopen(path, "rb");
	int size_ = h * w;

	if (NULL == fp)
	{
		std::cerr << "Error: open depth file" << std::endl;
		return false;
		// return;
	}
	int count_ = fread(depthData, sizeof(UINT16), size_, fp);

	if (size_ != count_)
	{
		std::cout << "Error: read depth file" << std::endl;
		return false;
	}
	fclose(fp);
	return true;
}

bool potassium::readBodyIndexFile(char* path, unsigned char* bodyIndexData_, int h, int w)
{
	FILE *fp = fopen(path, "r");
	if (NULL == fp)
	{
		std::cerr << "Error: read bodyindex file" << std::endl;
		return false;
	}

	int line_num = 0;
	char buf[800];
	while (NULL != fgets(buf, sizeof(buf), fp))
	{
		line_num++;
		if (line_num == 1)
			continue;

		std::string s;
		int buf_num = 1;
		int x, y;
		for (int i = 0; i < sizeof(buf); i++)
		{
			if (buf[i] == '\n' || buf_num > 2)
				break;

			s += buf[i];
			if (buf[i] == ' ')
			{
				int value = atoi(s.c_str());
				s.clear();
				if (buf_num == 1)
				{
					x = value;
				}
				else
				{
					y = value;
					int index = x + y * w;
					bodyIndexData_[index] = 0;
				}
				buf_num++;
			}

		}
	}
	fclose(fp);
	return true;
}

bool potassium::set_potassium(UINT16* depthData_, unsigned char* bodyIndexData_, int height_, int width_, int idx)
{
	int size_ = (height_)* (width_);
	std::string sidx = std::to_string(idx);
	std::string bpath = "./data/bodyframe/bodyframe.";
	bpath += sidx;
	bpath += ".txt";

	std::string dpath = "./data/depth/depth_";
	dpath += sidx;
	dpath += ".dat";

	char *b_path = (char*)bpath.c_str();
	char *d_path = (char*)dpath.c_str();

	//bodyindex
	unsigned char* bodyIndexData = (unsigned char*)malloc(size_ *sizeof(unsigned char));
	memset(bodyIndexData, 0xff, size_ *sizeof(unsigned char));

	if (!(this->readBodyIndexFile(b_path, bodyIndexData, height_, width_)))
		return false;
	memcpy(bodyIndexData_, bodyIndexData, size_ * sizeof(unsigned char));

	// depth
	UINT16* depthData = (UINT16*)malloc(size_ *sizeof(UINT16));

	if (!(this->readDepthFile(d_path, depthData, height_, width_)))
		return false;
	memcpy(depthData_, depthData, size_ * sizeof(UINT16));

	return true;
}

bool potassium::readPngFile(cv::Mat& img, int idx)
{
	cv::String filename = "./data/color/color_512_424_";
	filename += (cv::String)std::to_string(idx);
	filename += ".png";

	img = cv::imread(filename);

	return true;
}

bool potassium::set_potassium(cv::Mat& img, int idx, int* count)
{
	cv::String filename = "./data/color/color_512_424_";
	filename += (cv::String)std::to_string(idx);
	filename += ".png";

	cv::Mat png_ = cv::imread(filename);

	int bodyidx_count = 0;

	for (int y = 0; y < png_.rows; y++) //height
	{
		for (int x = 0; x < png_.cols; x++) //width
		{
			cv::Vec3b value = png_.at<cv::Vec3b>(y, x);

			// b g r 
			if (value == cv::Vec3b(36, 28, 237))
			{
				img.at<int>(y, x) = 0;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(29, 230, 168))
			{
				img.at<int>(y, x) = 1;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 79, 33))
			{
				img.at<int>(y, x) = 2;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(76, 177, 34))
			{
				img.at<int>(y, x) = 3;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 33, 33))
			{
				img.at<int>(y, x) = 4;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(239, 183, 0))
			{
				img.at<int>(y, x) = 5;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(222, 255, 104))
			{
				img.at<int>(y, x) = 6;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(243, 109, 77))
			{
				img.at<int>(y, x) = 7;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(33, 84, 79))
			{
				img.at<int>(y, x) = 8;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(0, 242, 255))
			{
				img.at<int>(y, x) = 9;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(42, 33, 84))
			{
				img.at<int>(y, x) = 10;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(14, 194, 255))
			{
				img.at<int>(y, x) = 11;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(193, 94, 255))
			{
				img.at<int>(y, x) = 12;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(0, 126, 255))
			{
				img.at<int>(y, x) = 13;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(189, 249, 255))
			{
				img.at<int>(y, x) = 14;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(188, 249, 211))
			{
				img.at<int>(y, x) = 15;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(213, 165, 181))
			{
				img.at<int>(y, x) = 16;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(153, 54, 47))
			{
				img.at<int>(y, x) = 17;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(79, 33, 84))
			{
				img.at<int>(y, x) = 18;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(177, 163, 255))
			{
				img.at<int>(y, x) = 19;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(142, 255, 86))
			{
				img.at<int>(y, x) = 20;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(156, 228, 245))
			{
				img.at<int>(y, x) = 21;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(97, 187, 157))
			{
				img.at<int>(y, x) = 22;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(152, 49, 111))
			{
				img.at<int>(y, x) = 23;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 33, 69))
			{
				img.at<int>(y, x) = 24;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(60, 90, 156))
			{
				img.at<int>(y, x) = 25;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(146, 122, 255))
			{
				img.at<int>(y, x) = 26;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(122, 170, 229))
			{
				img.at<int>(y, x) = 27;
				bodyidx_count++;
			}
		}
	}

	*count = bodyidx_count;
	
	return true;
}

// factory로부터 전달된 pile of data를 멤버변수로 저장하는 함수 
void potassium::set_pile(unsigned char* pile_, int size_)
{
	if (size_ <= 0)
	{
		std::cerr << "Error: set_pile() size" << std::endl;
		return;
	}

	this->pile_of_potassium = (unsigned char*)realloc(this->pile_of_potassium, sizeof(unsigned char) * size_);
	memcpy(this->pile_of_potassium, pile_, sizeof(unsigned char) * size_);

	this->size_of_pile = size_; // 512 * 424 * 3 * file 읽은 갯수
}

bool potassium::get_potassium(cv::Mat& img, int idx, int* count, int step, int rest_x, int rest_y)
{
	// img: bodyindex 에 해당되는 픽셀에 대해서만 값을 넣어줌(이미 30으로 초기화 된 mat)
	// idx : i 
	// count : bodyindex 몇개인지 반환
	int step_ = 512 * 424 * 3 * idx;

	int size = step_ / 3;
	//unsigned char *r, *b, *g;
	//r = new unsigned char[size];
	//b = new unsigned char[size];
	//g = new unsigned char[size];

	int bodyidx_count = 0;

	for (int y = rest_y; y < img.rows; y += step) //height
	{
		for (int x = rest_x; x < img.cols; x += step) //width
		{
			int index = y * 512 + x;

			unsigned char b, g, r; // RGB
			b = this->pile_of_potassium[step_ + index * 3];
			g = this->pile_of_potassium[step_ + (index * 3 + 1)];
			r = this->pile_of_potassium[step_ + (index * 3 + 2)];

			cv::Vec3b value = cv::Vec3b(b, g, r);
			if (value == cv::Vec3b(36, 28, 237))
			{
				img.at<int>(y, x) = 0;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(29, 230, 168))
			{
				img.at<int>(y, x) = 1;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 79, 33))
			{
				img.at<int>(y, x) = 2;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(76, 177, 34))
			{
				img.at<int>(y, x) = 3;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 33, 33))
			{
				img.at<int>(y, x) = 4;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(239, 183, 0))
			{
				img.at<int>(y, x) = 5;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(222, 255, 104))
			{
				img.at<int>(y, x) = 6;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(243, 109, 77))
			{
				img.at<int>(y, x) = 7;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(33, 84, 79))
			{
				img.at<int>(y, x) = 8;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(0, 242, 255))
			{
				img.at<int>(y, x) = 9;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(42, 33, 84))
			{
				img.at<int>(y, x) = 10;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(14, 194, 255))
			{
				img.at<int>(y, x) = 11;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(193, 94, 255))
			{
				img.at<int>(y, x) = 12;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(0, 126, 255))
			{
				img.at<int>(y, x) = 13;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(189, 249, 255))
			{
				img.at<int>(y, x) = 14;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(188, 249, 211))
			{
				img.at<int>(y, x) = 15;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(213, 165, 181))
			{
				img.at<int>(y, x) = 16;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(153, 54, 47))
			{
				img.at<int>(y, x) = 17;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(79, 33, 84))
			{
				img.at<int>(y, x) = 18;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(177, 163, 255))
			{
				img.at<int>(y, x) = 19;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(142, 255, 86))
			{
				img.at<int>(y, x) = 20;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(156, 228, 245))
			{
				img.at<int>(y, x) = 21;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(97, 187, 157))
			{
				img.at<int>(y, x) = 22;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(152, 49, 111))
			{
				img.at<int>(y, x) = 23;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 33, 69))
			{
				img.at<int>(y, x) = 24;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(60, 90, 156))
			{
				img.at<int>(y, x) = 25;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(146, 122, 255))
			{
				img.at<int>(y, x) = 26;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(122, 170, 229))
			{
				img.at<int>(y, x) = 27;
				bodyidx_count++;
			}
		}
	}

	*count = bodyidx_count;

	return true;
}

bool potassium::get_potassium(cv::Mat& img, int idx, int* count)
{
	// img: bodyindex 에 해당되는 픽셀에 대해서만 값을 넣어줌(이미 30으로 초기화 된 mat)
	// idx : i 
	// count : bodyindex 몇개인지 반환
	int step_ = 512 * 424 * 3 * idx;

	int size = step_ / 3;
	//unsigned char *r, *b, *g;
	//r = new unsigned char[size];
	//b = new unsigned char[size];
	//g = new unsigned char[size];

	int bodyidx_count = 0;

	for (int y = 0; y < img.rows; y++) //height
	{
		for (int x = 0; x < img.cols; x++) //width
		{
			int index = y * 512 + x;

			unsigned char b, g, r; // RGB
			b = this->pile_of_potassium[step_ + index * 3];
			g = this->pile_of_potassium[step_ + (index * 3 + 1)];
			r = this->pile_of_potassium[step_ + (index * 3 + 2)];

			cv::Vec3b value = cv::Vec3b(b, g, r);
			if (value == cv::Vec3b(36, 28, 237))
			{
				img.at<int>(y, x) = 0;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(29, 230, 168))
			{
				img.at<int>(y, x) = 1;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 79, 33))
			{
				img.at<int>(y, x) = 2;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(76, 177, 34))
			{
				img.at<int>(y, x) = 3;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 33, 33))
			{
				img.at<int>(y, x) = 4;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(239, 183, 0))
			{
				img.at<int>(y, x) = 5;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(222, 255, 104))
			{
				img.at<int>(y, x) = 6;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(243, 109, 77))
			{
				img.at<int>(y, x) = 7;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(33, 84, 79))
			{
				img.at<int>(y, x) = 8;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(0, 242, 255))
			{
				img.at<int>(y, x) = 9;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(42, 33, 84))
			{
				img.at<int>(y, x) = 10;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(14, 194, 255))
			{
				img.at<int>(y, x) = 11;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(193, 94, 255))
			{
				img.at<int>(y, x) = 12;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(0, 126, 255))
			{
				img.at<int>(y, x) = 13;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(189, 249, 255))
			{
				img.at<int>(y, x) = 14;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(188, 249, 211))
			{
				img.at<int>(y, x) = 15;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(213, 165, 181))
			{
				img.at<int>(y, x) = 16;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(153, 54, 47))
			{
				img.at<int>(y, x) = 17;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(79, 33, 84))
			{
				img.at<int>(y, x) = 18;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(177, 163, 255))
			{
				img.at<int>(y, x) = 19;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(142, 255, 86))
			{
				img.at<int>(y, x) = 20;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(156, 228, 245))
			{
				img.at<int>(y, x) = 21;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(97, 187, 157))
			{
				img.at<int>(y, x) = 22;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(152, 49, 111))
			{
				img.at<int>(y, x) = 23;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(84, 33, 69))
			{
				img.at<int>(y, x) = 24;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(60, 90, 156))
			{
				img.at<int>(y, x) = 25;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(146, 122, 255))
			{
				img.at<int>(y, x) = 26;
				bodyidx_count++;
			}
			else if (value == cv::Vec3b(122, 170, 229))
			{
				img.at<int>(y, x) = 27;
				bodyidx_count++;
			}
		}
	}

	*count = bodyidx_count;

	return true;
}