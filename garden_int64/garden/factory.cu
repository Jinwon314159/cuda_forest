#include "factory.cuh"

mineral mineral_;

// 선주문하는 함수 => caleb 농부가 선주문을 요청하면 데이터를 메모리에 올릴 수 있는 만큼 올리는 함수
void factory::order(int start, int end, int* fertilizer_count_)
{
	// setting
	this->start_index = start;
	this->end_index = end;

	this->total_file_count = end - start;

	int file_count = this->total_file_count;

	int result = 0;

	while (1)
	{
		result = this->produce(start, file_count);

		if (result != 0)
		{
			//this->fertilizer_count = result;
			*fertilizer_count_ = result;
			break;
		}
		else
		{
			// 실패한 경우 사이즈를 반으로 줄여서 다시 돌린다.
			file_count /= 2;
		}
	}

}

// 성공하면 potassium에게 넘겨주고 파일을 읽어드린 갯수만큼 반환
// 실패하면 0을 반환
int factory::produce(int start, int count)
{
	int start_ = start; // 첫 번째로 읽어드릴 파일명의 인덱스
	int end_ = start_ + count; // 마지막으로 읽어드릴 파일명의 인덱스 + 1

	int one_step = 512 * 424 * 3; // 3을 곱하는 이유? rbg 값을 저장하니까

	// 1. count 만큼 메모리를 할당해본다.
	this->data_pile = (unsigned char*)realloc(this->data_pile, one_step * count * sizeof(unsigned char));

	// 2-1. count 만큼 할당할 메모리가 없는 경우 -1을 반환해준다.
	if (this->data_pile == NULL)
		return 0;

	int step = 0; // 파일을 몇 번 읽었는지 체크하는 변수

	// 2-2. 성공하는 경우 start ~ end 범위의 png 데이터를 읽어와서 this->data_pile에 저장해준다.
	for (int i = start_; i < end_; i++)
	{
		char* file_path = new char[256];
		sprintf(file_path, DATA_PATH "\\color\\color_512_424_%d.png", i); //color_512_424_310
		//sprintf(file_path, ".\\data\\color\\mix\\color_512_424_%d.png", i); //linear regression test

		cv::Mat png_ = cv::imread(file_path);
		if (!png_.data)
		{
			std::cerr << "Error : read png file / path: "<< file_path << std::endl;
			return 0;
		}

		unsigned char* png_data = png_.data;
		unsigned size = png_.rows * png_.cols;

		// 한 개의 png파일을 읽을 때 마다 one_step 갯수 만큼 주소를 증가시켜준다.
		memcpy(((this->data_pile)+(step * one_step)), png_data, size * 3 * sizeof(unsigned char));
		
		step++;
	}

	// 3. data_pile에 잘 넣었다면 mineral로 넘겨준다. (mineral에서는 받은 data_pile을 potassuim으로 넘겨줄 것임)
	mineral_.makeMaterial(this->data_pile, one_step * count);

	// 4. 읽은 파일의 갯수를 반환
	return step;
}

bool factory::delivery(garden_truck* truck, int index, int step, int rest_x, int rest_y)
{
	int fer_count = 0;

	fig_nutrient *fertilizer = (fig_nutrient*)calloc(BUCKET_SIZE, sizeof(fig_nutrient));

	if (!mineral_.generateNutrients(fertilizer, index, &fer_count, step, rest_x, rest_y))
	{
		std::cerr << "Error : delivery()" << std::endl;
		return false;
	}

	truck->load_nutrients(fertilizer, fer_count);

	free(fertilizer);

	return true;
}

bool factory::delivery(garden_truck* truck, int index)
{
	int fer_count = 0;

	fig_nutrient *fertilizer = (fig_nutrient*)calloc(BUCKET_SIZE, sizeof(fig_nutrient));

	if (!mineral_.generateNutrients(fertilizer, index, &fer_count))
	{
		std::cerr << "Error : delivery()" << std::endl;
		return false;
	}

	truck->load_nutrients(fertilizer, fer_count);

	free(fertilizer);

	return true;
}

void factory::destroy()
{
	mineral_.destroy();
	this->~factory();
}