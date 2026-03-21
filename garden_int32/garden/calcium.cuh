/*
	[ calcium( Ca, 칼슘 ) ]
	 칼슘은 식물에게 가장 필요한 macronutrient 중 하나의 영양소이다.
	 (참고: https://en.wikipedia.org/wiki/Plant_nutrition)
	 calcium 클래스는 nitrogen 클래스로부터 받아온 kinect data에 대한 pointcloud를 관리하는 클래스이다.
*/

#pragma once

#include "nitrogen.cuh"
#include "GL\freeglut.h"

#include <omp.h>
#include <conio.h>
#include <stdlib.h>
#include <process.h>
#include <stdio.h>
#include <math.h>
#include <iostream>

#define PI (float)3.1415926

typedef enum _RUNNING_STATE
{
	NONE,
	RUN,
	PAUSE,
	STOP
} RUNNING_STATE;

typedef struct _MyDepthSpacePoint
{
	float X;
	float Y;
} MyDepthSpacePoint;

typedef struct _MyColorSpacePoint
{
	float X;
	float Y;
} 	MyColorSpacePoint;

typedef struct _MyCameraSpacePoint
{
	float X;
	float Y;
	float Z;
} 	MyCameraSpacePoint;

typedef enum _RenderingMode
{
	VideoMapping,
	ColorMapping
} RederingMode;


// calcium 클래스
class calcium
{
public:
	void ready(int argc, char** argv, int dw, int dh, int cw, int ch, RUNNING_STATE* state);
	void run();
	void stop();
	void free_all();
	// depth 정보를 복사하는 함수
	void draw_depth_3d(UINT len, UINT16* buf, int pointCnt, void* color_points, void* camera_points);
	// color 정보를 복사하는 함수
	void draw_color(int len, RGBQUAD* frame);

private:
	void init();
};
