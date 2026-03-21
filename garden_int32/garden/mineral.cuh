/*
	[mineral]
	 mineral 클래스는 data generation과 file management에 대해 처리해주는 클래스이다.
	 mineral 클래스를 통해 potassium, nitrogen, phosphorus 클래스를 접근한다.
*/
#pragma once

#include "potassium.cuh" // virtual data file management
#include "nitrogen.cuh" // real data file management
#include "phosphorus.cuh" // nutrient file management
#include "calcium.cuh" // point cloud management

#define MIN_SIZE 3

class mineral
{
public:
	unsigned short* water_data;

	bool run(fig_nutrient **nutrient_, int *nutrients_count, int count, int type);
	bool saveNutrient(fig_nutrient *nutrient_, int nutrients_count, int index);
	bool loadNutrient(fig_nutrient **nutrient_, int* count_, int index);
	bool makeMaterial(unsigned char* dp, int dp_size); // factory에서 비료 덩어리를 potassium으로 넘겨주는 함수
    bool generateNutrients(fig_nutrient* nutrient_, int index, int* count);
	bool generateNutrients(fig_nutrient* nutrient_, int index, int* count, bool harvest);
	bool produce(fig_nutrient* nutrient_, unsigned short *water, int *count, int *findex, int argc, char** argv); // 키넥트 데이터를 기반으로 nutrient 생성하는 함수
	
private:
	bool feedNutrients(fig_nutrient** nutrient_, int index, int type, int* count);
	bool getNutrients(fig_nutrient** nutrient_, int index, int type); // count? index 
	//void setNutrients(fig_nutrient* nutrient_, UINT16* resultBodyIndexdepth, int width, int height, int bodyIndex_count, int frame_count, int findex);
	int feedNutrient(UINT16* resultBodyIndexdepth, int width, int height);
	void reset();
	int calculateBodyPixel(UINT16* resultBodyIndexdepth, int width, int height);
};