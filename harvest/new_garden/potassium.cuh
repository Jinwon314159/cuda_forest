/*
[ potassium (K, 칼륨) ]
칼륨은 식물에게 가장 필요한 macronutrient 중 하나의 영양소이다.
(참고: https://en.wikipedia.org/wiki/Plant_nutrition)
potassium 클래스는 단지 "가상 데이터"에 대한 "파일"을 관리하는 클래스이다.
*/
#pragma once

#include "global.cuh"

//OpenCV
#include <opencv2\opencv.hpp>
#ifdef _DEBUG
#pragma comment(lib, "opencv_world300d.lib")
#else
#pragma comment(lib, "opencv_world300.lib")
#endif

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>