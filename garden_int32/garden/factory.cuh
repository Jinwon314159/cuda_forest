/*
	factory
	 : fertilizer factory로 caleb에서 필요한 mineral을 효율적으로 공급해주는 클래스
	   + 데이터를 하나씩 읽어가며 러닝시키는 구조보다는 메모리에 올릴 수 있을 만큼 다 올리고 nutrient를 하나씩 공급해줌.
*/
#pragma once

#include "global.cuh"
#include "mineral.cuh"

class factory
{
public:
	factory()
	{
		this->fertilizer_count = 0;
		this->start_index = 0;
		this->end_index = 0;
		this->total_file_count = 0;
	}
	~factory()
	{
		this->fertilizer_count = 0;
		this->start_index = 0;
		this->end_index = 0;
		this->total_file_count = 0;

		free(this->data_pile);
	}

	/* virtual data function */
	//void order(int start, int end, int* fertilizer_count_);
	//int produce(int start, int count); // 데이터를 메모리에 올려서 읽어드린 갯수를 반환하는 함수 
	void order(int start, int end, int iter, int f_idx, int* fertilizer_count_);
	int produce(int start, int iter, int count);
	bool delivery(garden_truck* truck, int index); // nutrients 배열을 caleb에 전달하는 함수

	/* kinect data function */
	bool quickDelivery(garden_truck* truck, unsigned short *water_, int* count, int* index, int argc, char** argv);

private:
	int fertilizer_count; //읽은 데이터의 갯수를 저장하는 변수
	int start_index; // 첫 번째로 읽어드릴 파일명의 인덱스
	int end_index; // 마지막으로 읽어드릴 파일명의 인덱스
	int total_file_count; // ./data/color 폴더에 있는 총 데이터 갯수

	unsigned char* data_pile; // png 파일을 전부 들고 있을 변수
};