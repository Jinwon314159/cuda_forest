/*
[mineral]
mineral 클래스는 data generation과 file management에 대해 처리해주는 클래스이다.
mineral 클래스를 통해 potassium, nitrogen, phosphorus 클래스를 접근한다.
*/
#pragma once

#include "potassium.cuh" // virtual data file management
#include "nitrogen.cuh" // real data file management
#include "phosphorus.cuh" // nutrient file management
#include "calcium.cuh" // point cloud management
