#include "factory.cuh"

garden_factory::garden_factory()
{
	;
}

garden_factory::~garden_factory()
{
	;
}

bool garden_factory::produce(char* session_path, garden_truck* truck, unsigned int start, unsigned int end, bool harvest)
{
	bool ret = true;

	truck->fertilizer_bag(BUCKET_SIZE * (end - start));
	truck->nutrients_count = 0;

	if (!harvest)
	{
		for (unsigned long long i = start; i < end; i++)
		{
			char color_file_path[256] = { 0 };
			sprintf(color_file_path, "%s\\%s\\"COLOR_PATH, GARDEN_PATH, session_path, i);
			cv::Mat img = cv::imread(color_file_path);
			if (!img.data)
			{
				ret = false;
				break;
			}

			for (int y = 0; y < img.rows; y++)
			{
				for (int x = 0; x < img.cols; x++)
				{
					int depth_idx = (i - start) * BUCKET_SIZE + y * BUCKET_WIDTH + x;
					if (truck->water[depth_idx] == 0) continue;

					int color_idx = y * BUCKET_WIDTH * 3 + x * 3;
					unsigned long label = get_label_from_color(img.data[color_idx], img.data[color_idx + 1], img.data[color_idx + 2]);
					if (label == MAXUINT32) continue;

					truck->nutrients[truck->nutrients_count].x = x;
					truck->nutrients[truck->nutrients_count].y = y;
					truck->nutrients[truck->nutrients_count].label = label;
					truck->nutrients[truck->nutrients_count].bucket_index = i - start;
					truck->nutrients_count++;
				}
			}

			img.release();
		}
	}
	else
	{
		for (unsigned long long i = start; i < end; i++)
		{
			for (int y = 0; y < BUCKET_HEIGHT; y++)
			{
				for (int x = 0; x < BUCKET_WIDTH; x++)
				{
					int depth_idx = (i - start) * BUCKET_SIZE + y * BUCKET_WIDTH + x;
					if (truck->water[depth_idx] == 0) continue;

					truck->nutrients[truck->nutrients_count].x = x;
					truck->nutrients[truck->nutrients_count].y = y;
					truck->nutrients[truck->nutrients_count].label = MAXUINT64;
					truck->nutrients[truck->nutrients_count].bucket_index = i - start;
					truck->nutrients_count++;
				}
			}
		}
	}

	return ret;
}

unsigned long garden_factory::get_label_from_color(unsigned char b, unsigned char g, unsigned char r)
{
	if (b == 36 && g == 28 && r == 237)
		return 0;
	if (b == 29 && g == 230 && r == 168)
		return 1;
	if (b == 84 && g == 79 && r == 33)
		return 2;
	if (b == 76 && g == 177 && r == 34)
		return 3;
	if (b == 84 && g == 33 && r == 33)
		return 4;
	if (b == 239 && g == 183 && r == 0)
		return 5;
	if (b == 222 && g == 255 && r == 104)
		return 6;
	if (b == 243 && g == 109 && r == 77)
		return 7;
	if (b == 33 && g == 84 && r == 79)
		return 8;
	if (b == 0 && g == 242 && r == 255)
		return 9;
	if (b == 42 && g == 33 && r == 84)
		return 10;
	if (b == 14 && g == 194 && r == 255)
		return 11;
	if (b == 193 && g == 94 && r == 255)
		return 12;
	if (b == 0 && g == 126 && r == 255)
		return 13;
	if (b == 189 && g == 249 && r == 255)
		return 14;
	if (b == 188 && g == 249 && r == 211)
		return 15;
	if (b == 213 && g == 165 && r == 181)
		return 16;
	if (b == 153 && g == 54 && r == 47)
		return 17;
	if (b == 79 && g == 33 && r == 84)
		return 18;
	if (b == 177 && g == 163 && r == 255)
		return 19;
	if (b == 142 && g == 255 && r == 86)
		return 20;
	if (b == 156 && g == 228 && r == 245)
		return 21;
	if (b == 97 && g == 187 && r == 157)
		return 22;
	if (b == 152 && g == 49 && r == 111)
		return 23;
	if (b == 84 && g == 33 && r == 69)
		return 24;
	if (b == 60 && g == 90 && r == 156)
		return 25;
	if (b == 146 && g == 122 && r == 255)
		return 26;
	//if (b == 122 && g == 170 && r == 229)
	if (b == 192 && g == 192 && r == 192)
		return 27;
	return MAXUINT32;
}