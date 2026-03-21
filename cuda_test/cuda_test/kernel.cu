
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#pragma comment(lib, "cudart.lib")

#include <Kinect.h>
#pragma comment(lib, "kinect20.lib")

#include <opencv2\opencv.hpp>
#ifdef _DEBUG
#pragma comment(lib, "opencv_world300d.lib")
#else
#pragma comment(lib, "opencv_world300.lib")
#endif

#include "stdafx.h"
#include <Windows.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string.h>

#define N 217088


// kinect functions
void getKinectData();
// file functions
void WriteFile(UINT16* depth_data, UINT dBufferSize, int fNum);

// cuda functions
cudaError_t getDepthWithCuda(UINT16* c_depth, unsigned char* c_bodyIndex, UINT16* ResultBodyIdxDepth, int BufferSize);

__global__ void setBodyIdxDepth(UINT16* c_depth, unsigned char* c_bodyIndex, UINT16* c_BodyIdxDepthMat)
{
	int index = blockIdx.x + blockIdx.y * 512;

#if 0
	printf("blockIdx.x:%d, blockIdx.y:%d\n", blockIdx.x, blockIdx.y);
#else
	if (index > N)
	{
		printf("Error : Index Out of Size!\n");
		return;
	}

	else
	{
		if (c_bodyIndex[index] != 0xff)
		{
			c_BodyIdxDepthMat[index] = c_depth[index];
		}
		else
			c_BodyIdxDepthMat[index] = 0xffff;
	}
#endif
}

// to sun: 미안해요. 전 그냥 C 스타일로 갈게요.
// to sun 이거 좀 귀찮은거 같아요;
int check_memory()
{
	// check device information
	cudaDeviceProp prop;
	int count;
	cudaError_t cudaStatus = cudaGetDeviceCount(&count);
	if (cudaStatus == cudaSuccess)
	{
		std::cout << "device count : " << count << std::endl;
		for (int i = 0; i < count; i++)
		{
			if (cudaSuccess == (cudaStatus = cudaGetDeviceProperties(&prop, i)))
			{
				std::cout << "name : " << prop.name << std::endl;
				std::cout << "total global mem : " << prop.totalGlobalMem << std::endl;
				std::cout << "total constant mem " << prop.totalConstMem << std::endl;
				std::cout << "max thread per block : " << prop.maxThreadsPerBlock << std::endl;
				std::cout << "max thread 0 dim : " << prop.maxThreadsDim[0] << std::endl;
				std::cout << "max thread 1 dim : " << prop.maxThreadsDim[1] << std::endl;
				std::cout << "max thread 2 dim : " << prop.maxThreadsDim[2] << std::endl;
				std::cout << "max thread 3 dim : " << prop.maxThreadsDim[3] << std::endl;
				std::cout << "max grid 0 size : " << prop.maxGridSize[0] << std::endl;
				std::cout << "max grid 1 size : " << prop.maxGridSize[1] << std::endl;
				std::cout << "max grid 2 size : " << prop.maxGridSize[2] << std::endl;
				std::cout << "max texture 1d  : " << prop.maxTexture1D << std::endl;
			}
		}
	}
	return 0;
}

int main3()
{

	cudaError_t cudaStatus;


	//get kinect frame
	getKinectData();

	// cudaDeviceReset must be called before exiting in order for profiling and
	// tracing tools such as Nsight and Visual Profiler to show complete traces.
	cudaStatus = cudaDeviceReset();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return 1;
	}

	return 0;
}

cudaError_t getDepthWithCuda(UINT16* depth, unsigned char* bodyIndex, UINT16* ResultBodyIdxDepth, int height, int width)
{
	int BufferSize = height * width;
	cudaError_t cudaStatus;

	// original data
	UINT16* c_depth;
	unsigned char* c_bodyIndex;

	// temp data
	UINT16* tmp_bodyIndexdepth;
	unsigned char* tmp_bodyIndex;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		goto Error;
	}

	// 매번 cudaMalloc 해줄 필요는 없을거 같네요
	// c_depth, c_bodyIndex, tmp_bodyIndexdepth를 전역변수로 선언해주고
	// memory allocation 하는 함수를 따로 선언해서 main함수에서 한 번 만 실행되게 하는게 좋을거 같아요.
	// Allocate GPU buffers for three vectors (two input, one output)    .
	cudaStatus = cudaMalloc((void**)&c_depth, BufferSize * sizeof(UINT16));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_depth, cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&c_bodyIndex, BufferSize * sizeof(unsigned char));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_bodyIndex, cudaMalloc failed!");
		goto Error;
	}

	cudaStatus = cudaMalloc((void**)&tmp_bodyIndexdepth, BufferSize * sizeof(UINT16));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_bodyIndex, cudaMalloc failed!");
		goto Error;
	}

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(c_depth, depth, BufferSize * sizeof(UINT16), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	cudaStatus = cudaMemcpy(c_bodyIndex, bodyIndex, BufferSize * sizeof(unsigned char), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;
	}

	// call kernel function
	dim3 BlockDim(512, 424, 1);
	dim3 ThreadDim(1, 1, 1);
	setBodyIdxDepth << <BlockDim, ThreadDim>> >(c_depth, c_bodyIndex, tmp_bodyIndexdepth);

	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(ResultBodyIdxDepth, tmp_bodyIndexdepth, BufferSize * sizeof(UINT16), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "bodyIndexdepth, cudaMemcpy failed!");
		goto Error;
	}

Error:
	cudaFree(c_depth);
	cudaFree(c_bodyIndex);
	cudaFree(tmp_bodyIndexdepth);


	return cudaStatus;
}

void WriteFile(UINT16* depth_data, UINT dBufferSize, int fNum)
{
	FILE *dst;

	cv::Mat img = cv::Mat(424, 512, CV_16UC1, depth_data).clone();
	std::string filename_png = "./depth_data(";
	filename_png += std::to_string(fNum);
	filename_png += ").png";
	cv::imwrite(filename_png, img);

	std::string filename = "./depth_data(";
	filename += std::to_string(fNum);
	filename += ").dat";

	const char *cfilename = filename.c_str();

	errno_t err;

	err = fopen_s(&dst, cfilename, "w+");
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

// 설명: body index가 0xffff 값을 가지는 위치의 depth 값 만 살려주는 함수?
void getKinectData()
{
	// kinect variables
	IKinectSensor* pKinectSensor = NULL;
	IMultiSourceFrameReader* pMultiReader = NULL;

	HRESULT hr = GetDefaultKinectSensor(&pKinectSensor);
	if (FAILED(hr))
	{
		std::cerr << "Error : GetDefaultKinectSensor" << std::endl;
		return;
	}

	hr = pKinectSensor->Open();
	if (FAILED(hr))
	{
		std::cerr << "Error : pKinectSensor::Open()" << std::endl;
		return;
	}

	hr = pKinectSensor->OpenMultiSourceFrameReader(FrameSourceTypes::FrameSourceTypes_Depth |
		FrameSourceTypes::FrameSourceTypes_BodyIndex, &pMultiReader);
	if (FAILED(hr))
	{
		std::cerr << "Error : OpenMultiSourceFrameReader()" << std::endl;
		return;
	}

	// Width & Height
	int width = 512;
	int height = 424;

	int dWidth = 0; //512
	int dHeight = 0; //424 

	//MultiFrame
	IMultiSourceFrame* frame = nullptr;
	IMultiSourceFrameReference* framaRef = nullptr;

	//Description
	IFrameDescription* pDescription;

	// Frame References
	IDepthFrameReference* dfRef = nullptr;
	IBodyIndexFrameReference* bxfRef = nullptr;

	// opencv matrix
	cv::Mat BodyIdxDepthMat(height, width, CV_16U);
	cv::Mat BodyIndexMat(height, width, CV_8UC3);

	int count = 0;

	while (1)
	{
		//Depth
		IDepthFrame* depthframe = nullptr;
		UINT16* depthData = NULL; // depth frame buffer
		UINT dBufferSize = 0;

		//BodyIndex
		IBodyIndexFrame* bodyIdxframe = nullptr;
		unsigned char* bxBuffer = nullptr; // bodyindex frame buffer
		unsigned int bxBufferSize = 0;

		UINT16* resultBodyIndexdepth;

		//Get Multi-Frame
		hr = pMultiReader->AcquireLatestFrame(&frame);
		if (SUCCEEDED(hr))
		{
			//Get Depth Frame
			hr = frame->get_DepthFrameReference(&dfRef);
			if (SUCCEEDED(hr))
			{
				//Depth
				hr = dfRef->AcquireFrame(&depthframe);
				if (SUCCEEDED(hr))
				{
					hr = depthframe->AccessUnderlyingBuffer(&dBufferSize, &depthData);
					if (!SUCCEEDED(hr)){
						std::cerr << "Error: Depthframe->AccessUnderlyingBuffer()" << std::endl;
						continue;
					}

					hr = depthframe->get_FrameDescription(&pDescription);
					if (!SUCCEEDED(hr)){
						std::cerr << "Error: Depthframe->get_FrameDescription()" << std::endl;
						continue;
					}

					pDescription->get_Height(&dHeight); // 424
					pDescription->get_Width(&dWidth); // 512

					cv::Mat DepthMat = cv::Mat(dHeight, dWidth, CV_16U, depthData).clone();
					cv::imshow("Depth", DepthMat);

					resultBodyIndexdepth = new UINT16[dBufferSize];

					//Get BodyIndex Frame
					hr = frame->get_BodyIndexFrameReference(&bxfRef);
					if (SUCCEEDED(hr))
					{
						//BodyIndex
						hr = bxfRef->AcquireFrame(&bodyIdxframe);
						if (SUCCEEDED(hr))
						{
							hr = bodyIdxframe->AccessUnderlyingBuffer(&bxBufferSize, &bxBuffer);
							if (SUCCEEDED(hr))
							{
#if 1
								// test cuda programming
								cudaError_t cudaStatus = getDepthWithCuda(depthData, bxBuffer, resultBodyIndexdepth, dHeight, dWidth);
								if (cudaStatus != cudaSuccess) {
									fprintf(stderr, "getDepthWithCuda failed!");
									return;
								}

								//write file
								count++;
								WriteFile(resultBodyIndexdepth, dBufferSize, count);

								// show body index 
								for (int y = 0; y < dHeight; y++)
								{
									for (int x = 0; x < dWidth; x++)
									{
										unsigned int index = y * dWidth + x;

										if (resultBodyIndexdepth[index] != 0xffff)
										{
											// set body index pixel color
											BodyIndexMat.at<cv::Vec3b>(y, x) = cv::Vec3b(0, 0, 255);
										}
										else
										{
											// set body index pixel color
											BodyIndexMat.at<cv::Vec3b>(y, x) = cv::Vec3b(0, 0, 0);
										}
									}
								}

								cv::imshow("BodyIndex", BodyIndexMat);
#endif // 0
							}
						}
					}
				}
			}
		}

		// release frames
		if (depthframe != nullptr)
		{
			depthframe->Release();
			depthframe = nullptr;
		}
		if (bodyIdxframe != nullptr)
		{
			bodyIdxframe->Release();
			bodyIdxframe = nullptr;
		}

		if (cv::waitKey(30) == VK_ESCAPE)
			break;
	}// while loop

	// release references
	dfRef->Release();
	dfRef = nullptr;
	bxfRef->Release();
	bxfRef = nullptr;

	if (pKinectSensor)
		pKinectSensor->Close();

	pKinectSensor->Release();
	cv::destroyAllWindows();
}
