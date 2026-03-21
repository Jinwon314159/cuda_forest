#include "farmer_5jk.cuh"

#define WIDTH 512
#define HEIGHT 424
#define N 217088 // 512 * 424

factory* from_factory;

static RUNNING_STATE gState = NONE;

// depth h/w
int dheight = 424;
int dwidth = 512;
// color h/w
int cheight = 1080;
int cwidth = 1920;

int frame_count = 0;

// common function
int checkBodyPixel(UINT16* resultBodyIndexdepth);
int checkBodyPixel(unsigned char* bodyIndex, int* tracked, int* body_pixel_count);
void setNutrient(UINT16* resultBodyIndexdepth, fig_nutrient* nutrient);

__global__ void setData(UINT16* depth_data, unsigned char* body_Index, UINT16* c_BodyIdxDepthMat)
{
	// c_BodyIdxDepthMat = tmp_bodyIndexDepth
#if 0
	int index = threadIdx.x + threadIdx.y * WIDTH;
#else
	int index = blockIdx.x * blockDim.x + threadIdx.x;
#endif

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
		//else
			// background
			//c_BodyIdxDepthMat[index] = 0xffff;
	}
}

UINT16* c_depth;
unsigned char* c_bodyIndex;
UINT16* tmp_bodyIndexdepth;

bool init_Cuda()
{
	cudaError_t cudaStatus;

	// depth data
	cudaStatus = cudaMalloc((void**)&c_depth, N * sizeof(UINT16));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_depth, cudaMalloc failed!");
		return false;
	}

	// body index data
	cudaStatus = cudaMalloc((void**)&c_bodyIndex, N * sizeof(unsigned char));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_bodyIndex, cudaMalloc failed!");
		return false;
	}

	// temp(result) data
	cudaStatus = cudaMalloc((void**)&tmp_bodyIndexdepth, N * sizeof(UINT16));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "c_bodyIndex, cudaMalloc failed!");
		return false;
	}

	return true;
}

#if 0
cudaError_t setData_Cuda(UINT16* depth_data, unsigned char* body_Index, UINT16* ResultBodyIdxDepth, int height, int width)
{
	cudaError_t cudaStatus;
	int BufferSize = width * height;

	cudaStatus = cudaMemset(tmp_bodyIndexdepth, 0xffff, sizeof(UINT16) * BufferSize);

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
#if 1
	dim3 BlockDim(212, 1, 1);
	dim3 ThreadDim(1024, 1, 1);
#else
	dim3 BlockDim(512, 424, 1);
	dim3 ThreadDim(1, 1, 1);
#endif
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

	cv::Mat frame_body_index = cv::Mat(dheight, dwidth, CV_16UC1, ResultBodyIdxDepth).clone();
	//cv::imshow("frame_body_index", frame_body_index);
	//cv::waitKey(1);

	return cudaStatus;
}
#else
unsigned int setData_omp(UINT16* depth_data, unsigned char* body_Index, int* tracked, unsigned short* ResultBodyIdxDepth, fig_nutrient* nutrients)
{
	unsigned int nutrients_total = 0;

	for (int y = 0; y < dheight; y++)
	{
//#pragma omp parallel for
		for (int x = 0; x < dwidth; x++)
		{
			unsigned int i = x + y * dwidth;

			if (body_Index[i] != 0xff)
			{
				unsigned int b = body_Index[i];

				tracked[b] = 1;

				ResultBodyIdxDepth[b * N + i] = depth_data[i];

				// labeling updata!
				nutrients[nutrients_total].label = 0;
				nutrients[nutrients_total].bucket_index = b;
				nutrients[nutrients_total].x = x;
				nutrients[nutrients_total].y = y;

				nutrients_total++;
			}
		};
	};

	return nutrients_total;
}
#endif

void deinit_Cuda()
{
	cudaFree(c_depth);
	cudaFree(c_bodyIndex);
	cudaFree(tmp_bodyIndexdepth);
}

unsigned int __stdcall produce_product(void* param)
{
	cudaError_t cudaStatus;

	// garden truck which is transmitted by parameter
	garden* g_ = (garden*)(((ThreadParam*)param)->g);
	//js_mart* m_ = (js_mart*)(((ThreadParam*)param)->m);
	garden_truck* truck_ = g_->truck;

	// buffer data
	UINT16* depth_data = NULL;
	unsigned char* body_index_data = NULL;
	RGBQUAD* color_data = NULL;

	// buffer size
	UINT buffer_size = 0; // depth (body index)
	UINT c_buffer_size = 0; // color

	// water
	unsigned short* water = (unsigned short*)malloc(sizeof(unsigned short) * 6 * N);

	// nutrients
	fig_nutrient *result_nutrient = (fig_nutrient*)malloc(sizeof(fig_nutrient) * WIDTH * HEIGHT);

	depth_data = (UINT16*)malloc(sizeof(UINT16) * N);
	body_index_data = (unsigned char*)malloc(sizeof(unsigned char) * N);
	color_data = (RGBQUAD*)calloc(cwidth * cheight, sizeof(RGBQUAD));

	ColorSpacePoint* colorSpacePoints = new ColorSpacePoint[cheight * cwidth];
	CameraSpacePoint* cameraSpacePoints = new CameraSpacePoint[cheight * cwidth];

	//int** joints_tracked = (int**)malloc(sizeof(int*) * 6);
	//for (int i = 0; i < 6; i++)
	//	joints_tracked[i] = (int*)calloc(MAX_CELL_NUM, sizeof(int));

	while (1)
	{
		if (gState == PAUSE)
		{
			Sleep(10);
			continue;
		}
		else if (gState == STOP)
			break;

		if (from_factory->nitrogen_.setKinectData(depth_data, body_index_data, color_data, &buffer_size, &c_buffer_size, &dheight, &dwidth, &cheight, &cwidth))
		{
			// kinect mapper function
			if (!(from_factory->nitrogen_.kinectMapper(depth_data, buffer_size, colorSpacePoints, cameraSpacePoints)))
			{
				fprintf(stderr, "kinect mapper failed!");
				continue;
			}

			// set point cloud information
			from_factory->calcium_.draw_depth_3d(buffer_size, depth_data, buffer_size, colorSpacePoints, cameraSpacePoints);
			// set color information
			from_factory->calcium_.draw_color(c_buffer_size, color_data);

			memset(water, 0xff, sizeof(unsigned short) * 6 * N);

			int tracked[6] = { 0 };
			unsigned int nutrients_count = setData_omp(depth_data, body_index_data, tracked, water, result_nutrient);
			if (nutrients_count <= 0)
			{
				from_factory->nitrogen_.releaseFrame();
				continue;
			}

			// nutrients를 cuda의 메모리로 올리고 
			g_->greenhouse->give(result_nutrient, nutrients_count);
			g_->greenhouse->fruit_box(nutrients_count);
			g_->greenhouse->finest_fruit_box(nutrients_count);
			g_->greenhouse->pour(water, 6, N);

			// harvest
			if (!g_->harvest(truck_))
			{
				from_factory->nitrogen_.releaseFrame();
				continue;
			}

			int x[6][MAX_CELL_NUM] = { 0 };
			int y[6][MAX_CELL_NUM] = { 0 };
			//for (int i = 0; i < 6; i++)
			//	memset(&joints_tracked[i], 0, sizeof(int) * MAX_CELL_NUM);
			int joints_tracked[6][MAX_CELL_NUM] = { 0 };

			js_mart js;
			js.packaging(truck_->finest_fruits, truck_->finest_fruits_count);
			g_->visualize(truck_, x, y, body_index_data, tracked, joints_tracked);

			for (int b = 0; b < 6; b++)
			{
				if (tracked[b] != 1)
				{
					from_factory->calcium_.setBody3D(b, false, NULL);
					continue;
				}

				MyBody3D body;
				body.tracked = true;
				for (int j = 0; j < MAX_CELL_NUM; j++)
				{
					int idx = WIDTH * y[b][j] + x[b][j];
					if (idx > 0)
					{
						DepthSpacePoint d = { x[b][j], y[b][j] };
						CameraSpacePoint c;
						from_factory->nitrogen_.kinectMapper2(d, depth_data[idx], &c);
						body.joints[j].Position = c;
						//body.joints[j].Position.Z += 0.04;
						body.joints[j].TrackingState = (joints_tracked[b][j] == 1) ? TrackingState_Tracked : TrackingState_NotTracked;
					}
					else
						body.joints[j].TrackingState = TrackingState_NotTracked;
				}
				from_factory->calcium_.setBody3D(b, true, &body);
			}
		}
		else
		{
			for (int b = 0; b < 6; b++)
				from_factory->calcium_.setBody3D(b, false, NULL);

			from_factory->nitrogen_.releaseFrame();

			continue;
		}

		//if (cv::waitKey(1) == VK_ESCAPE)
		//break;
	} // while loop

	//for (int i = 0; i < 6; i++)
	//	free(joints_tracked[i]);
	//free(joints_tracked);

	delete cameraSpacePoints;
	delete colorSpacePoints;

	// release memory
	//cudaFreeHost(depth_data);
	free(depth_data);
	//cudaFreeHost(body_index_data);
	free(body_index_data);
	free(color_data);
	free(result_nutrient);
	free(water);

	deinit_Cuda();

	// opengl stop
	from_factory->calcium_.stop();

	return 0;
}


bool farmer_5jk::work(ThreadParam* param, int argc, char** argv)
{
	cudaError_t cudaStatus;

	from_factory = (factory*)(param->f);

	if (!(from_factory->nitrogen_.init()))
	{
		std::cerr << "Error: nitrogen(Kinect Manager) init()" << std::endl;
		return false;
	}

	gState = RUN;

	//point cloud (openGL)
	from_factory->calcium_.ready(argc, argv, dwidth, dheight, cwidth, cheight, &gState);

	// call thread function
	unsigned int id;
	HANDLE hThread = 0;
	hThread = (HANDLE)_beginthreadex(
		NULL,
		0,
		produce_product,
		param,
		0,
		&id);

	// point cloud (OpenGL)
	from_factory->calcium_.run();

	DWORD test = 0;
	//for (int i = 0; i < THREAD_NUM; i++)
	{
		WaitForSingleObject(hThread, INFINITE);
		GetExitCodeThread(hThread, &test);
		CloseHandle(hThread);
	}

	// release references
	from_factory->nitrogen_.releaseRef();

	// release multiframe reader and description
	from_factory->nitrogen_.releaseReader();

	// close kinect sensor
	from_factory->nitrogen_.close();

	// point cloud (OpenGL)
	from_factory->calcium_.free_all();

	from_factory->nitrogen_.~nitrogen();

	from_factory->~factory();

	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return false;
	}

	return true;
}

// bodyindex 갯수를 확인하여 반환해준다. 
int checkBodyPixel(UINT16* resultBodyIndexdepth)
{
	int bodyIndex_count = 0; // body pixel each frame

	for (int y = 0; y < dheight; y++)
	{
		for (int x = 0; x < dwidth; x++)
		{
			unsigned int index = x + y * dwidth;

			if (resultBodyIndexdepth[index] != 0xffff)
				bodyIndex_count++;
		}
	}

	if (bodyIndex_count > 0)
		return bodyIndex_count;
	else
		return 0;
}

// body index frame (unsigned char* 타입)의 bodyindex 갯수를 확인하여 반환해준다. 
int checkBodyPixel(unsigned char* bodyIndex, int* tracked, int* body_pixel_count)
{
	int bodyIndex_count = 0; // body pixel each frame

#pragma omp parallel for
	for (int i = 0; i < dheight * dwidth; i++)
	{
		if (bodyIndex[i] != 0xff)
		{
			bodyIndex_count++;
			tracked[bodyIndex[i]] = 1;
			body_pixel_count[bodyIndex[i]]++;
		}
	}

	return bodyIndex_count;
}

void setNutrient(UINT16* resultBodyIndexdepth, fig_nutrient* nutrient)
{
	int nut_num = 0;

	for (int y = 0; y < dheight; y++)
	{
		for (int x = 0; x < dwidth; x++)
		{
			unsigned int index = x + y * dwidth;

			if (resultBodyIndexdepth[index] != 0xffff)
			{
				// labeling updata!
				nutrient[nut_num].label = 1;
				nutrient[nut_num].bucket_index = 0;
				nutrient[nut_num].x = x;
				nutrient[nut_num].y = y;

				nut_num++;
			}
		}// for x
	} // for y
}