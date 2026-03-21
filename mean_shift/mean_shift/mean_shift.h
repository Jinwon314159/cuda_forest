#pragma once

#include <Windows.h>
#include <random>
#include <omp.h>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>

#define W 512
#define H 424
#define IMG_SZ W * H
#define P_CNT 10000

#define THREADS_NUM 8 // IMG_SIZE를 나누었을 때 정수여야 한다.

#define DISTANCE_THRESHOLD 2

void run();