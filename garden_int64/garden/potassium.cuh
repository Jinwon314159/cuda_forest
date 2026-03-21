/*
	[ potassium (K, 칼륨) ]
	칼륨은 식물에게 가장 필요한 macronutrient 중 하나의 영양소이다.
	(참고: https://en.wikipedia.org/wiki/Plant_nutrition)
	potassium 클래스는 단지 "가상 데이터"에 대한 "파일"을 관리하는 클래스이다.
*/
#pragma once

#include "global.cuh"

#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>

#define P_WIDTH 512
#define P_HEIGHT 424
 
// VIRTUAL FILE MANAGER
class potassium
{
public:
	potassium()
	{
		this->count = 0;
		this->size_of_pile = 0;
	}
	~potassium()
	{
		free(this->pile_of_potassium);
	}

	void writeDepthFile(UINT16* depth_data, UINT dBufferSize, int fNum);
	void writeLabelFile(UINT16* depth_data, int dWidth, int dHeight, int body_index_count);
	
	bool set_potassium(UINT16* depthData_, unsigned char* bodyIndexData_, int height_, int width_, int idx);
	bool set_potassium(cv::Mat& img, int idx, int* count);
	void set_pile(unsigned char* pile_, int size_); // 파일 덩어리를 저장

	bool get_potassium(cv::Mat& img, int idx, int* count, int step, int rest_x, int rest_y);
	bool get_potassium(cv::Mat& img, int idx, int* count);


private:
	int count;
	unsigned char* pile_of_potassium; // factory로 부터 넘어오는 메모리에 올린 파일 덩어리
	int size_of_pile;

	bool readDepthFile(char* path, UINT16* depthData, int h, int w);
	bool readBodyIndexFile(char* path, unsigned char* bodyIndexData_, int h, int w);
	bool readPngFile(cv::Mat& img, int idx);
};