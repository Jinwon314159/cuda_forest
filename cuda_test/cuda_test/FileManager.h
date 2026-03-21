#pragma once
#include "cnutrient.cuh"

class FileManager
{
public:
	FileManager()
	{
		this->count = 0;
	}

	void WriteDepthFile(UINT16* depth_data, UINT dBufferSize, int fNum);
	void WriteLabelFile(UINT16* depth_data, int dWidth, int dHeight, int body_index_count);

private:
	int count;
};