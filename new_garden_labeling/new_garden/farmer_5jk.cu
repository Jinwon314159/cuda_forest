#include "farmer_5jk.cuh"

#define WIDTH 512
#define HEIGHT 424
#define N 271088 // 512 * 424

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
int checkBodyPixel(unsigned char* bodyIndex);
void setNutrient(UINT16* resultBodyIndexdepth, fig_nutrient* nutrient);
void setNutrient(int* labelbuffer, fig_nutrient* nutrient);
void setNutrient(int* labelbuffer, fig_nutrient* nutrient, int nu_size, UINT16* bodyindexdepth);

__global__ void setData(UINT16* depth_data, unsigned char* body_Index, UINT16* c_BodyIdxDepthMat)
{
	// c_BodyIdxDepthMat = tmp_bodyIndexDepth
	int index = blockIdx.x + blockIdx.y * WIDTH;

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
}

cudaError_t setData_Cuda(UINT16* depth_data, unsigned char* body_Index, UINT16* ResultBodyIdxDepth, int height, int width)
{
	UINT16* c_depth;
	unsigned char* c_bodyIndex;
	UINT16* tmp_bodyIndexdepth;

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

	return cudaStatus;
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
	// label buffer
	int* labelBuffer = NULL;

	// buffer size
	UINT buffer_size = 0; // depth (body index)
	UINT c_buffer_size = 0; // color

	// result
	UINT16* result_BodyIndexdepth = NULL; // result
	fig_nutrient *result_nutrient = NULL;

	int tmp_cnt = 0;

	while (1)
	{
		if (gState == STOP)
			break;

		if (gState == RUN)
		{
			//memory allocation
			cudaStatus = cudaHostAlloc(&depth_data, sizeof(UINT16) * dheight * dwidth, cudaHostAllocDefault);
			if (cudaSuccess != cudaStatus)
			{
				std::cout << "Error :cudaHostAlloc, depth_data " << std::endl;
				continue;
			}
			cudaStatus = cudaHostAlloc(&body_index_data, sizeof(unsigned char) * dheight * dwidth, cudaHostAllocDefault);
			if (cudaSuccess != cudaStatus)
			{
				std::cout << "Error :cudaHostAlloc, body_index_data " << std::endl;
				continue;
			}

			if (NULL == color_data)
				color_data = (RGBQUAD*)calloc(cwidth * cheight, sizeof(RGBQUAD));
			else
			{
				free(color_data);
				color_data = NULL;
				color_data = (RGBQUAD*)calloc(cwidth * cheight, sizeof(RGBQUAD));
			}


			if (from_factory->nitrogen_.setKinectData(depth_data, body_index_data, color_data, &buffer_size, &c_buffer_size, &dheight, &dwidth, &cheight, &cwidth))
			{
				ColorSpacePoint* colorSpacePoints = new ColorSpacePoint[c_buffer_size];
				CameraSpacePoint* cameraSpacePoints = new CameraSpacePoint[c_buffer_size];

				// kinect mapper function
				if (!(from_factory->nitrogen_.kinectMapper(depth_data, buffer_size, colorSpacePoints, cameraSpacePoints)))
				{
					std::cout << "kinect mapper failed!" << std::endl;
					continue;
				}

				// set point cloud information
				from_factory->calcium_.draw_depth_3d(buffer_size, depth_data, buffer_size, colorSpacePoints, cameraSpacePoints);
				// set color information
				from_factory->calcium_.draw_color(c_buffer_size, color_data);

				// body index 가 아무 것도 없는 프레임인 경우엔 하위 작업을 하지 않고 넘긴다.
				int body_count = checkBodyPixel(body_index_data);
				if (body_count <= 0)
				{
					buffer_size = 0;
					c_buffer_size = 0;

					delete cameraSpacePoints;
					delete colorSpacePoints;

					// release cuda host memory
					cudaFreeHost(depth_data);
					depth_data = NULL;

					cudaFreeHost(body_index_data);
					body_index_data = NULL;

					free(color_data);
					color_data = NULL;

					from_factory->nitrogen_.releaseFrame();

					continue;
				} // if bodycount <= 0

				std::cout << " * body count != 0" << std::endl;
				result_BodyIndexdepth = (UINT16*)malloc(sizeof(UINT16) * buffer_size);

				cudaStatus = setData_Cuda(depth_data, body_index_data, result_BodyIndexdepth, dheight, dwidth);
				if (cudaStatus != cudaSuccess) {
					fprintf(stderr, "setData_Cuda failed!");
					continue;
				}
				// 현재 확인된 bodyindex depth 버퍼와 body count를 calcium으로 저장한다.
				from_factory->calcium_.setBodyIndexBuffer(dheight * dwidth, result_BodyIndexdepth, body_count);

				// body count 만큼만 nutrient를 생성함
				result_nutrient = (fig_nutrient*)malloc(sizeof(fig_nutrient) * body_count);
				setNutrient(result_BodyIndexdepth, result_nutrient);

				// load informations to truck
				truck_->load_nutrients(result_nutrient, body_count);
				truck_->load_water(result_BodyIndexdepth);

				g_->greenhouse->pour(truck_);

				if (truck_->do_harvest)	// test
				{
					if (!g_->harvest(truck_)) return -1;
#if 1
					//m_->packaging(truck_->finest_fruits, truck_->finest_fruits_count);
					int x[MAX_CELL_NUM] = { 0 };
					int y[MAX_CELL_NUM] = { 0 };
					g_->visualize(truck_, x, y);
					MyBody3D body;
					body.tracked = true;
					for (int i = 0; i < MAX_CELL_NUM; i++)
					{
						int idx = WIDTH * y[i] + x[i];
						if (idx > 0)
						{
							DepthSpacePoint d = { x[i], y[i] };
							CameraSpacePoint c;
							from_factory->nitrogen_.kinectMapper2(d, depth_data[idx], &c);
							body.joints[i].Position = c;
						}
					}
					from_factory->calcium_.setBody3D(0, true, &body);
#endif
				}
				else {	// training
					//if (!g.give(&truck_)) return -1;
					//truck_->calculate_error_rate();
				}

				from_factory->nitrogen_.releaseFrame();

				buffer_size = 0;
				c_buffer_size = 0;

				delete cameraSpacePoints;
				delete colorSpacePoints;

				free(result_BodyIndexdepth);
				result_BodyIndexdepth = NULL;

				free(result_nutrient);
				result_nutrient = NULL;

			} // if setKinectData()

			if (cv::waitKey(30) == VK_ESCAPE)
				break;

			from_factory->nitrogen_.releaseFrame();

			// release memory
			cudaFreeHost(depth_data);
			depth_data = NULL;

			cudaFreeHost(body_index_data);
			body_index_data = NULL;

			free(color_data);
			color_data = NULL;
		} // if run

		if (gState == PAUSE)
		{
			Sleep(10);

			if (from_factory->calcium_.is_labeled)
			{
				if (labelBuffer == NULL)
					labelBuffer = (int*)malloc(sizeof(int)* dheight * dwidth);
				else
				{
					free(labelBuffer);
					labelBuffer = NULL;
					labelBuffer = (int*)malloc(sizeof(int)* dheight * dwidth);
				}

				//int label_count = from_factory->calcium_.getLabelBuffer(labelBuffer);
				int nutrient_size = from_factory->calcium_.getCurrentBodyIndexCount();
				if (nutrient_size > 0) //label_count >= 0
				{
					// bodyindex가 없는 경우는 nutrient를 생성하지 않도록 한다.
					fig_nutrient* result_label_nutrient = NULL;
					result_label_nutrient = (fig_nutrient*)malloc(sizeof(fig_nutrient) * nutrient_size);

					// calcium이 들고 있는 bodyindexdepth 버퍼를 가져온다. (bodyIndexDepth_Buffer에 담아온다.)
					UINT16* bodyIndexDepth_Buffer = (UINT16*)malloc(sizeof(UINT16)*dheight *dwidth);
					from_factory->calcium_.getBodyIndexDepthBuffer(bodyIndexDepth_Buffer);

					setNutrient(labelBuffer, result_label_nutrient, nutrient_size, bodyIndexDepth_Buffer);

					// 현재 라벨링한 depth 정보 가져오기
					UINT16 *depth_tmp = (UINT16*)malloc(sizeof(UINT16) * dwidth * dheight);
					//from_factory->calcium_.getDepthBuffer(depth_tmp);
					from_factory->calcium_.getBodyIndexDepthBuffer(depth_tmp);

					// 파일로 저장하기
					phosphorus phosphorus_;
					if (!phosphorus_.writeNutrients(result_label_nutrient, nutrient_size, 0))
					{
						std::cout << "fail : save nutrient file" << std::endl;
					}
					if (!phosphorus_.writeDepthFile(depth_tmp, dwidth * dheight))
					{
						std::cout << "fail : save depth file" << std::endl;
					}

					free(result_label_nutrient);
					result_label_nutrient = NULL;

					free(depth_tmp);
					depth_tmp = NULL;

					from_factory->calcium_.is_labeled = false;
					gState = RUN;
					std::cout << "success : save labeled pixel!" << std::endl;

				} // if labelcount
				else
				{
					from_factory->calcium_.is_labeled = false;
					gState = RUN;
					std::cout << "fail : Check body index frame" << std::endl;
				}
				if (labelBuffer != NULL)
				{
					free(labelBuffer);
					labelBuffer = NULL;
				}
			} // if is_label 
			
			from_factory->nitrogen_.releaseFrame();

			buffer_size = 0;
			c_buffer_size = 0;
			
			//continue;
		} // if pause

	} // while loop

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
	std::cout << "dddd" << std::endl;

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
int checkBodyPixel(unsigned char* bodyIndex)
{
	int bodyIndex_count = 0; // body pixel each frame

	for (int y = 0; y < dheight; y++)
	{
		for (int x = 0; x < dwidth; x++)
		{
			unsigned int index = x + y * dwidth;

			if (bodyIndex[index] != 0xff)
				bodyIndex_count++;
		}
	}

	if (bodyIndex_count > 0)
		return bodyIndex_count;
	else
		return 0;
}

void setNutrient(UINT16* resultBodyIndexdepth, fig_nutrient* nutrient)
{
	int nut_num = 0;

	for (int y = 0; y < dheight; y++)
	{
		for (int x = 0; x < dwidth; x++)
		{
			unsigned int index = x + y * dwidth;

			if (x > 10 && x < (dwidth - 10) && y > 10 && y < (dheight - 10)  && resultBodyIndexdepth[index] != 0xffff)
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

void setNutrient(int* labelbuffer, fig_nutrient* nutrient)
{
	for (int y = 0; y < dheight; y++)
	{
		for (int x = 0; x < dwidth; x++)
		{
			unsigned int index = x + y * dwidth;

			if (labelbuffer[index] > 0)
				int a = 0;

			nutrient[index].label = labelbuffer[index];
			nutrient[index].bucket_index = 0;
			nutrient[index].x = x;
			nutrient[index].y = y;
#if 0
			// 라벨링한 픽셀만 저장하는 경우
			if (labelbuffer[index] > 0)
			{
				nutrient[nut_num].label = labelbuffer[index];
				nutrient[nut_num].bucket_index = 0;
				nutrient[nut_num].x = x;
				nutrient[nut_num].y = y;
				nut_num++;
			}
#endif
			
		}// for x
	} // for y
}

void setNutrient(int* labelbuffer, fig_nutrient* nutrient, int nu_size, UINT16* bodyindexdepth)
{
	int nu_num = 0;
	for (int y = 0; y < dheight; y++)
	{
		for (int x = 0; x < dwidth; x++)
		{
			unsigned int index = x + y * dwidth;

			if (x > 10 && x < (dwidth - 10) && y > 10 && y < (dheight - 10) && bodyindexdepth[index] != 0xffff)
			{
				nutrient[nu_num].label = labelbuffer[index];
				nutrient[nu_num].bucket_index = 0;
				nutrient[nu_num].x = x;
				nutrient[nu_num].y = y;
				nu_num++;
			}
		}// for x
	} // for y

	if (nu_num != nu_size)
	{
		std::cout << "nu_num != nu_size" << std::endl;
	}

}