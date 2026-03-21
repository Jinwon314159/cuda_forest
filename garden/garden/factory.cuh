#pragma once

#include "global.cuh"
#include "truck.cuh"

class garden_factory
{
public:
	garden_factory();
	~garden_factory();

	bool produce(char* session_path, garden_truck* truck, unsigned int start, unsigned int end, bool harvest = false);
	unsigned long get_label_from_color(unsigned char b, unsigned char g, unsigned char r);
};