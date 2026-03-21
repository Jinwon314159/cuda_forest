/*
	[ nitrogen (N, 질소) ]
	 질소는 식물에게 가장 필요한 macronutrient 중 하나의 영양소이다.
	 (참고: https://en.wikipedia.org/wiki/Plant_nutrition)
	 nitrogen 클래스는 단지 키넥트로 부터의 "실제 데이터"에 대한 "파일"을 관리하는 클래스이다.
*/
#pragma once

#include "global.cuh"

//Kinect
#include <Kinect.h>
#pragma comment(lib, "kinect20.lib")
 
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string>


class nitrogen
{
public:
	// depth width & height
	int dwidth;
	int dheight;
	int cwidth;
	int cheight;

	bool init();
	bool setKinectData(UINT16* depthData_, unsigned char* bodyIndexData_, RGBQUAD *colorData_, UINT* dBufferSize_, UINT* cBufferSize_, int* dh_, int* dw_, int* ch_, int* cw_);
	void releaseFrame();
	void releaseMultiFrame();
	void releaseRef(); // release references
	void releaseReader();
	void close(); // close & release kinect sensor

	// mapper function
	bool kinectMapper(UINT16* depth_data, UINT buffer_size, ColorSpacePoint* colorSpacePoints_, CameraSpacePoint* cameraSpacePoints_);

	~nitrogen()
	{
		delete &(this->cwidth);
		delete &(this->cheight);

		delete this->pKinectSensor;
		delete this->pMultiReader;
		delete this->pDescription;

		delete this->dfRef;
		delete this->bxfRef;
		delete this->cfRef;

		delete this->frame;
		delete this->depthframe;
		delete this->bodyIdxframe;
		delete this->colorframe;
	}
private:
	IKinectSensor* pKinectSensor = NULL;
	IMultiSourceFrameReader* pMultiReader = NULL;
	IFrameDescription* pDescription = NULL; //Description
	// Frame References
	IDepthFrameReference* dfRef = NULL;
	IBodyIndexFrameReference* bxfRef = NULL;
	IColorFrameReference *cfRef = NULL;
	// frame
	IMultiSourceFrame* frame = NULL; //MultiFrame
	IDepthFrame* depthframe = NULL;
	IBodyIndexFrame* bodyIdxframe = NULL;
	IColorFrame* colorframe = NULL;
};