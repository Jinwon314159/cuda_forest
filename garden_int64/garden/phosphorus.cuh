/*
	[ phosphorus (P, 인) ]
	 질소는 식물에게 가장 필요한 macronutrient 중 하나의 영양소이다.
	 (참고: https://en.wikipedia.org/wiki/Plant_nutrition)
	 phosphorus 클래스는 데이터 생성 결과인 fig_nutreint 클래스에 대한 "파일"을 관리하는 클래스이다.
*/
#pragma once

#include "global.cuh"
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>

class phosphorus
{
public:
	bool writeNutrients(fig_nutrient* nutrient_, int cnt, int idx);
	bool readNutrients(char* path, fig_nutrient** nutrient_, int *count); // count : 클래스 배열 갯수

}; 