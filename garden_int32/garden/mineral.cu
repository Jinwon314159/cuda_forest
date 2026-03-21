#include "mineral.cuh"

#define WIDTH 512
#define HEIGHT 424
#define N 271088 // 512 * 424
#define THREAD_NUM 1

// global class
potassium g_potassium;
nitrogen nitrogen_; // kinect 
calcium calcium_; // point cloud

// cuda functions
cudaError_t setData_Cuda(UINT16* depth_data, unsigned char* body_Index, UINT16* ResultBodyIdxDepth, int height, int width);

// global variables
UINT16* resultBodyIndexdepth_ = NULL; // result
fig_nutrient *temp = NULL; // temp 
static RUNNING_STATE gState = NONE;
int frame_count = 0;
int bodyIndex_count = 0; // body pixel each frame
int current_bodyIndex_count = 0;
int total_bodyIndex_count = 0; // body pixel each frame
int nutrient_size = 0; // class size

// depth h/w
int dheight = 424;
int dwidth = 512;
// color h/w
int cheight = 1080;
int cwidth = 1920;

// common functions
int checkBodyPixel(UINT16* resultBodyIndexdepth, int width, int height);
void setNutrient(UINT16* resultBodyIndexdepth, int width, int height, int count, int frame_count);
void setNutrients(fig_nutrient* nutrient_, UINT16* resultBodyIndexdepth, int width, int height, int bodyIndex_count, int frame_count, int findex);


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

#if 0
	// show depth
	cv::Mat DepthMat = cv::Mat(height, width, CV_16UC1, ResultBodyIdxDepth).clone();
	cv::imwrite("aaa.png", DepthMat);
#endif

	return cudaStatus;
}

unsigned int __stdcall update_MultiFrame(void*)
{
	cudaError_t cudaStatus;

	// buffer data
	UINT16* depth_data = NULL;
	unsigned char* body_index_data = NULL;
	RGBQUAD* color_data = NULL;

	// buffer size
	UINT buffer_size = 0; // depth (body index)
	UINT c_buffer_size = 0; // color

	//memory allocation
	cudaStatus = cudaHostAlloc(&depth_data, sizeof(UINT16) * dheight * dwidth, cudaHostAllocDefault);
	if (cudaSuccess != cudaStatus)
		return false;

	cudaStatus = cudaHostAlloc(&body_index_data, sizeof(unsigned char) * dheight * dwidth, cudaHostAllocDefault);
	if (cudaSuccess != cudaStatus)
		return false;

	color_data = (RGBQUAD*)calloc(cwidth * cheight, sizeof(RGBQUAD));

	while (1)
	{
		if (gState == PAUSE)
		{
			Sleep(10);
			continue;
		}
		else if (gState == STOP)
			break;

		if (nitrogen_.setKinectData(depth_data, body_index_data, color_data, &buffer_size, &c_buffer_size, &dheight, &dwidth, &cheight, &cwidth))
		{
			ColorSpacePoint* colorSpacePoints = new ColorSpacePoint[c_buffer_size];
			CameraSpacePoint* cameraSpacePoints = new CameraSpacePoint[c_buffer_size];

			// kinect mapper function
			if (!nitrogen_.kinectMapper(depth_data, buffer_size, colorSpacePoints, cameraSpacePoints))
			{
				fprintf(stderr, "kinect mapper failed!");
				continue;
			}

			// set point cloud information
			calcium_.draw_depth_3d(buffer_size, depth_data, buffer_size, colorSpacePoints, cameraSpacePoints);
			// set color information
			calcium_.draw_color(c_buffer_size, color_data);

			//resultBodyIndexdepth = new UINT16[buffer_size];
			resultBodyIndexdepth_ = (UINT16*)malloc(sizeof(UINT16) * buffer_size);

			frame_count++;
			if (frame_count < 10)
			{
				nitrogen_.releaseFrame();
				printf("frame count : %d\n", frame_count);
				continue;
			}

			cudaStatus = setData_Cuda(depth_data, body_index_data, resultBodyIndexdepth_, dheight, dwidth);
			if (cudaStatus != cudaSuccess) {
				fprintf(stderr, "setData_Cuda failed!");
				continue;
			}

			int count = 0; // body pixel each frame
			count = checkBodyPixel(resultBodyIndexdepth_, dheight, dwidth);

			if (count != 0)
			{
				setNutrient(resultBodyIndexdepth_, dwidth, dheight, count, frame_count);

				// write depth file
				//nitrogen_.writeDepthFile(resultBodyIndexdepth_, buffer_size, frame_count);

				gState = STOP; // 성공적으로 한 프레임을 읽었을 때 while 문을 멈추고 nutrient를 생성하여 준다.
			}

			nitrogen_.releaseFrame();

			delete[]cameraSpacePoints;
			delete[]colorSpacePoints;

		}
		else
		{
			nitrogen_.releaseFrame();
			continue;
		}

		if (cv::waitKey(30) == VK_ESCAPE)
			break;

	} // while loop
			
	free(color_data);
	depth_data = NULL;
	body_index_data = NULL;
	color_data = NULL;

	calcium_.stop();

	return 0;
}


//getNutrients
// 데이터를 읽어서 nutrient 클래스로 정보를 가공한 뒤
// 그 결과, nutrient_로 반환해주는 함수
bool mineral::getNutrients(fig_nutrient** nutrient_, int index, int type)
{
	UINT16* depth_data = NULL;
	UINT buffer_size = 0; // depth buffer size
	unsigned char* body_index_data = NULL;
	
	int height = 0;
	int width = 0;

	int file_cnt = 1; // file 갯수

	UINT16* resultBodyIndexdepth; // result
	potassium potassium_; // !!!! global 변수로 호출한 potassium 클래스 사용을 권장

	cudaError_t cudaStatus;

	cudaStatus = cudaHostAlloc(&depth_data, sizeof(UINT16) * HEIGHT * WIDTH, cudaHostAllocDefault);
	if (cudaSuccess != cudaStatus)
		return false;

	cudaStatus = cudaHostAlloc(&body_index_data, sizeof(unsigned char) * HEIGHT * WIDTH, cudaHostAllocDefault);
	if (cudaSuccess != cudaStatus)
		return false;
	
#if 0 // 한번에 여러 개(findex 만큼)의 파일을 읽어오는 경우
	for (int findex = 0; findex < file_cnt; findex++)
	{
		//potassium_.set_potassium(depth_data, body_index_data, HEIGTH, WIDTH, findex)
#endif
		bool result_;
		if (type == 0) // virtual data
			result_ = potassium_.set_potassium(depth_data, body_index_data, HEIGHT, WIDTH, index);
		else if (type == 1) // real data -> nitrogen으로 바꿔야함
			result_ = potassium_.set_potassium(depth_data, body_index_data, HEIGHT, WIDTH, index);
		else
		{
			std::cout << "Error : getNutrient type is invalid" << std::endl;
			return false;
		}

		if (result_)
		{
			height = 424; // file에서는 이 값들을 가져올 수 없으니 이렇게 값을 할당
			width = 512;
			buffer_size = height * width;

			resultBodyIndexdepth = new UINT16[buffer_size];
			
			cudaStatus = setData_Cuda(depth_data, body_index_data, resultBodyIndexdepth, height, width);
			if (cudaStatus != cudaSuccess) {
				fprintf(stderr, "setData_Cuda failed!");
				//continue;
				return false;
			}

			int cal = calculateBodyPixel(resultBodyIndexdepth, height, width);

			if (cal != 0)
			{
				//nutrient_ = new fig_nutrient[bodyIndex_count]; // 각 프레임에 한번씩 생성됨
				//free(*nutrient_);
				*nutrient_ = (fig_nutrient*)malloc(bodyIndex_count * sizeof(fig_nutrient));

				//setNutrients(nutrient_, resultBodyIndexdepth, width, height, bodyIndex_count, frame_count, findex);
				setNutrients(*nutrient_, resultBodyIndexdepth, width, height, bodyIndex_count, frame_count, index);

				current_bodyIndex_count = bodyIndex_count; // 현재 프레임의 bodyindex 값을 저장
				total_bodyIndex_count += bodyIndex_count; // bodyindex 값을 누적
#if 1
				// write depth file
				potassium_.writeDepthFile(resultBodyIndexdepth, buffer_size, frame_count);
				// write label file
				potassium_.writeLabelFile(resultBodyIndexdepth, width, height, total_bodyIndex_count);
				
#endif
				frame_count++; // frame 번호가 0부터 시작됨

			} // if cal
			else
				return false;

			bodyIndex_count = 0;
		}
#if 0
	} // for
#endif
	return true;
}

// 메모리에 올라간 데이터(png)를 읽어서 nutrient로 생성하는 함수 
bool mineral::feedNutrients(fig_nutrient** nutrient_, int index, int type, int* count)
{
	// index : file number
	// type : virtual or real data
	// count : count of class array
	UINT16* resultBodyIndexdepth; // result
	potassium potassium_; // file class

	int count_ = 0;

	cv::Mat result(HEIGHT, WIDTH, CV_32S);
	result = cv::Scalar(30); // result 모든 원소값 30으로 초기화

	if (!potassium_.set_potassium(result, index, &count_))
		return false;

	if (count_ == 0) // count = 0 이면 bodyindex가 존재하지 않은 파일을 읽음
		return false;

	*nutrient_ = (fig_nutrient*)malloc(count_ * sizeof(fig_nutrient));
	
	int nut_num = 0; // 배열 인덱싱을 위한 변수

	for (int y = 0; y < result.rows; y++) //height
	{
		for (int x = 0; x < result.cols; x++) //width
		{
			int value = result.at<int>(y, x);

			if (value != 30)
			{
				(*nutrient_)[nut_num].x = (unsigned __int64)x;
				(*nutrient_)[nut_num].y = (unsigned __int64)y;
				(*nutrient_)[nut_num].bucket_index = (unsigned __int64)index;
				(*nutrient_)[nut_num].label = (unsigned __int64)value;

				nut_num++;
			}
		}
		
	}

	if (count_ != nut_num)
	{
		std::cout << "Error : count_ != nut_num" << std::endl;
		return false;
	}

	*count = count_; // 총 클래스 배열 갯수
	
	return true;
}


void mineral::reset()
{
	frame_count = 0;
	bodyIndex_count = 0;
	nutrient_size = 0;
}

bool mineral::saveNutrient(fig_nutrient *nutrient_, int nutrients_count, int index)
{
	phosphorus phosphorus_;
	if (phosphorus_.writeNutrients(nutrient_, nutrients_count, index))
		return true;

	return false;
}

bool mineral::loadNutrient(fig_nutrient **nutrient_, int* count_, int index)
{
	// count_ : 배열 갯수
	phosphorus phosphorus_;
	std::string path = "./data/fig_nutrient/nutrients_";
	path += std::to_string(index);
	path += ".dat";

	char *p = (char*)path.c_str();

	fig_nutrient* nutrient_tmp = new fig_nutrient[3];
	int nu_count = 0;

	if (!phosphorus_.readNutrients(p, &nutrient_tmp, &nu_count))
		return false;

	*nutrient_ = (fig_nutrient*)malloc(sizeof(fig_nutrient)*nu_count);
	memcpy(*nutrient_, nutrient_tmp, sizeof(fig_nutrient)*nu_count);

	*count_ = nu_count;

	free(nutrient_tmp);

	return true;
}

bool mineral::run(fig_nutrient **nutrient_, int *nutrients_count, int count, int type)
{
	// *nutrients_count : nutrient_ 클래스의 index 갯수를 저장하는 변수 
	// count : 읽어야 하는 데이터 번호
	// type : 0 -> virtual data
	//        1 -> real data
	fig_nutrient* nutrient_tmp = new fig_nutrient[MIN_SIZE];

#if 1 
	// png 파일에서 body index pixel을 읽어 fig_nutrient를 채워주는 부분
	int nut_count = 0;

	if (!feedNutrients(&nutrient_tmp, count, type, &nut_count))
	{
		std::cerr << "Error : run() -> feedNutrients()" << std::endl;
		return false;
	}

	*nutrient_ = (fig_nutrient*)malloc(sizeof(fig_nutrient)*nut_count);
	memcpy(*nutrient_, nutrient_tmp, sizeof(fig_nutrient)*nut_count);

	*nutrients_count = nut_count;

#else
	// bodyframe.txt와 depth.dat를 읽어 fig_nutrient를 채워주는 부분
	// 단, 바디파트에 대한 labeling은 포함되지 않음
	if (!(this->getNutrients(&nutrient_tmp, count, type))) // real or virtual data?
	{
		std::cerr << "Error : run() -> getNutrients()" << std::endl;
		return false;
	}

	*nutrient_ = (fig_nutrient*)malloc(sizeof(fig_nutrient)*current_bodyIndex_count);
	memcpy(*nutrient_, nutrient_tmp, sizeof(fig_nutrient)*current_bodyIndex_count);
	
	*nutrients_count = current_bodyIndex_count;
#endif

	free(nutrient_tmp);
	this->reset();
	
	return true;
}

int mineral::calculateBodyPixel(UINT16* resultBodyIndexdepth, int width, int height)
{
	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			unsigned int index = x + y * width;

			if (resultBodyIndexdepth[index] != 0xffff)
			{
				bodyIndex_count++;
			}
		}// for x
	} // for y

	if (bodyIndex_count > 0)
		return bodyIndex_count;
	else
		return 0;
}

// 메모리에 올려져 있는 데이터를 가져와서 nutrient 배열로 생성하여 반환해주는 함수
bool mineral::generateNutrients(fig_nutrient* nutrient_, int index, int* count)
{
	// index : file number(== i)
	// count : count of class array

	int count_ = 0;

	cv::Mat result(HEIGHT, WIDTH, CV_32S);
	result = cv::Scalar(30); // result 모든 원소값 30으로 초기화

	if (!g_potassium.get_potassium(result, index, &count_))
		return false;

	if (count_ == 0) // count = 0 이면 bodyindex가 존재하지 않은 파일을 읽음
		return false;

	int nut_num = 0; // 배열 인덱싱을 위한 변수

	for (int y = 0; y < result.rows; y++) //height
	{
		for (int x = 0; x < result.cols; x++) //width
		{
			int value = result.at<int>(y, x);

			if (value != 30)
			{
				nutrient_[nut_num].x = (unsigned __int64)x;
				nutrient_[nut_num].y = (unsigned __int64)y;
				nutrient_[nut_num].bucket_index = (unsigned __int64)index;
				nutrient_[nut_num].label = (unsigned __int64)value;

				nut_num++;
			}
		}

	}

	if (count_ != nut_num)
	{
		std::cout << "Error : count_ != nut_num" << std::endl;
		return false;
	}

	*count = count_; // 총 클래스 배열 갯수

	return true;
}

bool mineral::generateNutrients(fig_nutrient* nutrient_, int index, int* count, bool harvest)
{
	// index : file number(== i)
	// type : virtual or real data
	// count : count of class array

	int count_ = 0;

	cv::Mat result(HEIGHT, WIDTH, CV_32S);
	result = cv::Scalar(30); // result 모든 원소값 30으로 초기화

	if (!harvest)
	{
		if (!g_potassium.get_potassium(result, index, &count_))
			return false;

		if (count_ == 0) // count = 0 이면 bodyindex가 존재하지 않은 파일을 읽음
			return false;
	}

	int nut_num = 0; // 배열 인덱싱을 위한 변수

	for (int y = 0; y < result.rows; y++) //height
	{
		for (int x = 0; x < result.cols; x++) //width
		{
			if (!harvest)
			{
				int value = result.at<int>(y, x);

				if (value != 30)
				{
					nutrient_[nut_num].x = (unsigned __int64)x;
					nutrient_[nut_num].y = (unsigned __int64)y;
					nutrient_[nut_num].bucket_index = (unsigned __int64)index;
					nutrient_[nut_num].label = (unsigned __int64)value;
					nut_num++;
				}
			}
			else
			{
				nutrient_[nut_num].x = (unsigned __int64)x;
				nutrient_[nut_num].y = (unsigned __int64)y;
				nutrient_[nut_num].bucket_index = (unsigned __int64)index;
				nut_num++;
			}
		}
	}

	if (!harvest)
	{
		if (count_ != nut_num)
		{
			std::cout << "Error : count_ != nut_num" << std::endl;
			return false;
		}
	}
	else
	{
		count_ = nut_num;
	}


	*count = count_; // 총 클래스 배열 갯수

	return true;
}

// kinect에서 읽어서 nutrient를 생성하는 함수
bool mineral::produce(fig_nutrient* nutrient_, unsigned short *water, int *count, int *findex, int argc, char** argv)
{
	cudaError_t cudaStatus;

	if (!nitrogen_.init())
	{
		std::cerr << "Error: nitrogen(Kinect Manager) init()" << std::endl;
		return false;
	}

	gState = RUN;

	//point cloud (openGL)
	calcium_.ready(argc, argv, dwidth, dheight, cwidth, cheight, &gState);

	// call thread function
	unsigned int id;
	HANDLE hThread[THREAD_NUM] = { 0 };
	hThread[0] = (HANDLE)_beginthreadex(
		NULL,
		0,
		update_MultiFrame,
		NULL,
		0,
		&id);

	// point cloud (OpenGL)
	calcium_.run();

	DWORD test = 0;
	for (int i = 0; i < THREAD_NUM; i++)
	{
		WaitForSingleObject(hThread[i], INFINITE);
		GetExitCodeThread(hThread[i], &test);
		CloseHandle(hThread[i]);
	}

	// temp 결과를 nutrient_로 메모리 복사 해주기
	memcpy(nutrient_, temp, sizeof(fig_nutrient) * nutrient_size);
	memcpy(water, resultBodyIndexdepth_, sizeof(unsigned short) * BUCKET_SIZE);


	*count = nutrient_size;
	*findex = frame_count; // depth file index 

	//release memory
	free(resultBodyIndexdepth_);
	free(temp);
	resultBodyIndexdepth_ = NULL;
	temp = NULL;

	// release references
	nitrogen_.releaseRef();
	// release multiframe reader and description
	nitrogen_.releaseReader();

	// close kinect sensor
	nitrogen_.close();

	// point cloud (OpenGL)
	calcium_.free_all();

	//calcium_.~calcium_();
	nitrogen_.~nitrogen_();


	// cudaDeviceReset must be called before exiting in order for profiling and
	// tracing tools such as Nsight and Visual Profiler to show complete traces.
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceReset failed!");
		return false;
	}
	reset();

	return true;

}

// factory에서 비료 덩어리를 potassium으로 넘겨주는 함수
bool mineral::makeMaterial(unsigned char* dp, int dp_size)
{
	if (dp_size <= 0)
	{
		std::cerr << "Error: pile of fertilizer size" << std::endl;
		return false;
	}

	g_potassium.set_pile(dp, dp_size);

}


void setNutrients(fig_nutrient* nutrient_, UINT16* resultBodyIndexdepth, int width, int height, int bodyIndex_count, int frame_count, int findex)
{
	int nut_num = 0;
	//nutrient_size = bodyIndex_count;

	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			unsigned int index = x + y * width;

			if (resultBodyIndexdepth[index] != 0xffff)
			{
				// labeling updata!
				nutrient_[nut_num].label = 1;
				nutrient_[nut_num].bucket_index = frame_count;
				nutrient_[nut_num].x = x;
				nutrient_[nut_num].y = y;

				nut_num++;
			}
		}// for x
	} // for y
}

// update_MultiFrame() 에서 호출됨
void setNutrient(UINT16* resultBodyIndexdepth, int width, int height, int count, int frame_count)
{
	int nut_num = 0;
	temp = (fig_nutrient*)malloc(sizeof(fig_nutrient) * count);

	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			unsigned int index = x + y * width;

			if (resultBodyIndexdepth[index] != 0xffff)
			{
				// labeling updata!
				temp[nut_num].label = 1;
				temp[nut_num].bucket_index = frame_count;
				temp[nut_num].x = x;
				temp[nut_num].y = y;

				nut_num++;
			}
		}// for x
	} // for y

	// temp 배열이 몇개의 원소를 가지는지에 대한 값을 반환
	nutrient_size = nut_num;
}

// bodyindex 갯수를 확인하여 반환해준다. 
int checkBodyPixel(UINT16* resultBodyIndexdepth, int width, int height)
{
	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			unsigned int index = x + y * width;

			if (resultBodyIndexdepth[index] != 0xffff)
			{
				bodyIndex_count++;
			}
		}// for x
	} // for y

	if (bodyIndex_count > 0)
		return bodyIndex_count;
	else
		return 0;
}