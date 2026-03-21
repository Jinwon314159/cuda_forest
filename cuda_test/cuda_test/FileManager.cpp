#include "FileManager.h"

void FileManager::WriteLabelFile(UINT16* depth_data, int dWidth, int dHeight, int body_index_count)
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
					labelfile << (unsigned short)1 << " " << (unsigned short)x <<" " << (unsigned short)y << "\n";
					++fbodyindex_count; // 1부터 시작
				}
				else
					labelfile << (unsigned short)0 << " " << (unsigned short)x <<" "<< (unsigned short)y << "\n";

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

void FileManager::WriteDepthFile(UINT16* depth_data, UINT dBufferSize, int fNum)
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