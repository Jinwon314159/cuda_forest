//CUDA
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#pragma comment(lib, "cudart.lib")

//Kinect
#include <Kinect.h>
#pragma comment(lib, "kinect20.lib")

//OpenCV
#include <opencv2\opencv.hpp>
#ifdef _DEBUG
#pragma comment(lib, "opencv_world300d.lib")
#else
#pragma comment(lib, "opencv_world300.lib")
#endif

#include "stdafx.h"
#include "fignutrient.h"

#include <Windows.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <string.h>