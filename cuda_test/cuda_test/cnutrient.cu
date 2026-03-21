#include "cnutrient.cuh"
#include "FileManager.h"
#include "kinectManager.h"

#define N 217088 // 512 * 424
#define WIDTH 512
#define HEIGHT 424

//common functions
int calculateBodyPixel(UINT16* resultBodyIndexdepth, int width, int height);
bool setKinectData();
void setNutrients(UINT16* resultBodyIndexdepth, int width, int height, int bodyIndex_count, int frame_count);
void delNutrients();
void reset();

//cuda functions
cudaError_t setData_Cuda(UINT16* depth_data, unsigned char* body_Index, UINT16* ResultBodyIdxDepth, int height, int width);

// global variables
int frame_count = 0;
int bodyIndex_count = 0; // body pixel each frame
int total_bodyIndex_count = 0; // body pixel each frame
int nutrient_size = 0; // class size

fignutrient* nutrient;

// call this kernel function when each frame comes from kinect
__global__ void setData(UINT16* depth_data, unsigned char* body_Index, UINT16* c_BodyIdxDepthMat)
{
	// c_BodyIdxDepthMat = tmp_bodyIndexDepth
	int index = blockIdx.x + blockIdx.y * WIDTH;

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
		if (body_Index[index] != 0xff)
		{
			// body
			c_BodyIdxDepthMat[index] = depth_data[index];
		}
		else
			// background
			c_BodyIdxDepthMat[index] = 0xffff;
	}
#endif
}

int main()
{

	//memoryAlloc_Cuda(WIDTH, HEIGHT);
	cudaError_t cudaStatus;

	if (!setKinectData())
	{
		std::cerr << "Error: setKinectData()" << std::endl;
		return -1;
	}
	
	// cudaDeviceReset must be called before exiting in order for profiling and
	// tracing tools such as Nsight and Visual Profiler to show complete traces.
	cudaStatus = cudaDeviceReset();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return -1;
	}

	reset();

	return 0;
}


cudaError_t setData_Cuda(UINT16* depth_data, unsigned char* body_Index, UINT16* ResultBodyIdxDepth, int height, int width)
{
	UINT16* c_depth;
	unsigned char* c_bodyIndex;
	UINT16* tmp_bodyIndexdepth;
	int* bodycount;

	cudaError_t cudaStatus;
	int BufferSize = width * height;

	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
	}

	// depth data
	cudaStatus = cudaMalloc((void**)&c_depth, BufferSize * sizeof(UINT16));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_depth, cudaMalloc failed!");
	}

	// body index data
	cudaStatus = cudaMalloc((void**)&c_bodyIndex, BufferSize * sizeof(unsigned char));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_bodyIndex, cudaMalloc failed!");
	}

	// temp(result) data
	cudaStatus = cudaMalloc((void**)&tmp_bodyIndexdepth, BufferSize * sizeof(UINT16));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_bodyIndex, cudaMalloc failed!");
	}

	// Copy input vectors from host memory to GPU buffers.
	cudaStatus = cudaMemcpy(c_depth, depth_data, BufferSize * sizeof(UINT16), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
	}

	cudaStatus = cudaMemcpy(c_bodyIndex, body_Index, BufferSize * sizeof(unsigned char), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
	}

#if 1
	// call kernel function
	dim3 BlockDim(512, 424, 1);
	dim3 ThreadDim(1, 1, 1);
	setData << <BlockDim, ThreadDim >> >(c_depth, c_bodyIndex, tmp_bodyIndexdepth);

	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
	}
#endif

	// cudaDeviceSynchronize waits for the kernel to finish, and returns
	// any errors encountered during the launch.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(ResultBodyIdxDepth, tmp_bodyIndexdepth, BufferSize * sizeof(UINT16), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "bodyIndexdepth, cudaMemcpy failed!");
	}

	cudaFree(c_depth);
	cudaFree(c_bodyIndex);
	cudaFree(tmp_bodyIndexdepth);

#if 1
	// show depth
	cv::Mat DepthMat = cv::Mat(height, width, CV_16UC1, ResultBodyIdxDepth).clone();
	cv::imwrite("aaa.png", DepthMat);
#endif

	return cudaStatus;
}

bool setKinectData()
{
#if 1

	UINT16* depth_data = nullptr;
	unsigned char* body_index_data = nullptr;
	UINT buffer_size = 0; // depth buffer size
	int height = 0;
	int width = 0;

	UINT16* resultBodyIndexdepth; // result
	FileManager fileManager; // file class
	kinect_manager kinect_manager_;

	cudaError_t cudaStatus;

	// init kinect sensor
	if (!kinect_manager_.init())
	{
		std::cerr << "Error: Kinect Manager init()" << std::endl;
		return false;
	}

	cudaStatus = cudaHostAlloc(&depth_data, sizeof(UINT16) * HEIGHT * WIDTH, cudaHostAllocDefault);
	if (cudaSuccess != cudaStatus) 
		return false;
	
	cudaStatus = cudaHostAlloc(&body_index_data, sizeof(unsigned char) * HEIGHT * WIDTH, cudaHostAllocDefault);
	if (cudaSuccess != cudaStatus) 
		return false;
	

	while(1)
	{
		//setKinectData(UINT16* depthData_, unsigned char* bodyIndexData_, UINT dBufferSize_, int height_, int width_)
		if (kinect_manager_.setKinectData(depth_data, body_index_data, &buffer_size, &height, &width))
		{
			resultBodyIndexdepth = new UINT16[buffer_size];
			
			frame_count++;
			if (frame_count < 10)
			{
				kinect_manager_.releaseFrame();
				continue;
			}

			cudaStatus = setData_Cuda(depth_data, body_index_data, resultBodyIndexdepth, height, width);
			if (cudaStatus != cudaSuccess) {
				fprintf(stderr, "setData_Cuda failed!");
				continue;
			}


			int cal = calculateBodyPixel(resultBodyIndexdepth, height, width);

			if (cal != 0)
			{
				setNutrients(resultBodyIndexdepth, width, height, bodyIndex_count, frame_count);

				total_bodyIndex_count += bodyIndex_count;
#if 1
				// write depth file
				fileManager.WriteDepthFile(resultBodyIndexdepth, buffer_size, frame_count);
				// write label file
				fileManager.WriteLabelFile(resultBodyIndexdepth, width, height, total_bodyIndex_count);
#endif
				delNutrients(); //delete nutrient class
			}

			bodyIndex_count = 0;

		}
		else 
		{
			continue;
		}

		if (cv::waitKey(30) == VK_ESCAPE)
			break;
	} // while loop

	// release references
	kinect_manager_.releaseRef();

	// close kinect sensor
	kinect_manager_.close();

#else
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

	//Description
	IFrameDescription* pDescription;

	// Frame References
	IDepthFrameReference* dfRef = nullptr;
	IBodyIndexFrameReference* bxfRef = nullptr;

	// opencv matrix
	cv::Mat BodyIndexMat(height, width, CV_8UC3);

	while (1)
	{
		//Depth
		IDepthFrame* depthframe = nullptr;
		UINT16* depthData = NULL; // depth frame buffer
		UINT dBufferSize = 0;

		//BodyIndex
		IBodyIndexFrame* bodyIdxframe = nullptr;
		unsigned char* bodyIndexData = nullptr; // bodyindex frame buffer
		unsigned int bxBufferSize = 0;

		UINT16* resultBodyIndexdepth; // result
		FileManager fileManager; // file class

		cudaError_t cudaStatus;

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

					// result 객체 생성
					resultBodyIndexdepth = new UINT16[dBufferSize];

					//Get BodyIndex Frame
					hr = frame->get_BodyIndexFrameReference(&bxfRef);
					if (SUCCEEDED(hr))
					{
						//BodyIndex
						hr = bxfRef->AcquireFrame(&bodyIdxframe);
						if (SUCCEEDED(hr))
						{
							hr = bodyIdxframe->AccessUnderlyingBuffer(&bxBufferSize, &bodyIndexData);
							if (SUCCEEDED(hr))
							{
								if (bodyIndexData == nullptr || bodyIndexData == NULL)
								{
									std::cerr << "bodyindex frame is null" << std::endl;
									continue;
								}

								frame_count++;

								if (frame_count < 10)
								{
									std::cout << "frame : " << frame_count << std::endl;
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
									continue;
								}

								cudaStatus = setData_Cuda(depthData, bodyIndexData, resultBodyIndexdepth, dHeight, dWidth);
								if (cudaStatus != cudaSuccess) {
									fprintf(stderr, "setData_Cuda failed!");
									continue;
								}


								int cal = calculateBodyPixel(resultBodyIndexdepth, dHeight, dWidth);
								
								if (cal != 0)
								{
									setNutrients(resultBodyIndexdepth, dWidth, dHeight, bodyIndex_count, frame_count);
									
									total_bodyIndex_count += bodyIndex_count;
									
									// write depth file
									fileManager.WriteDepthFile(resultBodyIndexdepth, dBufferSize, frame_count);
									// write label file
									fileManager.WriteLabelFile(resultBodyIndexdepth, dWidth, dHeight, total_bodyIndex_count);

									delNutrients(); //delete nutrient class
								}
								
								bodyIndex_count = 0;

							} // body index frame
						}
					}
				}
			} // depth frame
		}

		// release frames
		if (frame != nullptr)
		{
			frame->Release();
			frame = nullptr;
		}
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
#endif
}

void setNutrients(UINT16* resultBodyIndexdepth, int width, int height, int bodyIndex_count, int frame_count)
{
	int nut_num = 0;

	nutrient = new fignutrient[bodyIndex_count]; // 각 프레임에 한번씩 생성됨
	nutrient_size = bodyIndex_count;

	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			unsigned int index = x + y * width;

			if (resultBodyIndexdepth[index] != 0xff)
			{
				nutrient[nut_num].label = 1;
				nutrient[nut_num].frame_Index = frame_count;
				nutrient[nut_num].x = (unsigned short)x;
				nutrient[nut_num].y = (unsigned short)y;
				
				nut_num++;
			}
		}// for x
	} // for y
}

void delNutrients()
{
	delete nutrient;
}

int calculateBodyPixel(UINT16* resultBodyIndexdepth, int width, int height)
{
	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			unsigned int index = x + y * width;

			if (resultBodyIndexdepth[index] != 0xff)
			{
				bodyIndex_count++;
			}
		}// for x
	} // for y

	if (bodyIndex_count > 0)
		return 1;
	else
		return 0;
}

void reset()
{
	frame_count = 0;
	bodyIndex_count = 0;
	nutrient_size = 0;
}

