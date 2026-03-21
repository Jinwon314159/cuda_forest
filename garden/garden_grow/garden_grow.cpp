// garden_grow.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include <stdio.h>
#include <string.h>
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>

#include "caleb.cuh"
#pragma comment(lib, "garden.lib")


void print_usage()
{
	printf("USAGE: garden_grow -session \"session id\" -start 0 -end 4\n");
}

bool parse(int argc, char* argv[], GROW_PARAMETERS* params)
{
	if (argc != 7)
		return false;

	for (int i = 1; i < argc; i++)
	{
		if (strcmp("-session", argv[i]) == 0)
			params->session = argv[i + 1];
		if (strcmp("-start", argv[i]) == 0)
			params->start = atoi(argv[i + 1]);
		if (strcmp("-end", argv[i]) == 0)
			params->end = atoi(argv[i + 1]);
	}

	return true;
}

int main(int argc, char* argv[])
{
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
	_CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_DEBUG);

	GROW_PARAMETERS params;

	if (!parse(argc, argv, &params))
	{
		print_usage();
		return -1;
	}

#ifdef MEMORY_LEAK_CHECK
	PROCESS_MEMORY_COUNTERS_EX mem1, mem2;
	GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&mem1, sizeof(PROCESS_MEMORY_COUNTERS_EX));

	size_t private_max = 0;
	while (1)
	{
		GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&mem1, sizeof(PROCESS_MEMORY_COUNTERS_EX));
#endif

		grow(&params);

#ifdef MEMORY_LEAK_CHECK
		GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&mem2, sizeof(PROCESS_MEMORY_COUNTERS_EX));
		if (mem2.PrivateUsage > private_max)
			private_max = mem2.PrivateUsage;
		printf("\nmax: %d, before: %d bytes, after: %d bytes, diff: %d bytes\n\n", private_max, mem1.PrivateUsage, mem2.PrivateUsage, mem2.PrivateUsage - mem1.PrivateUsage);
	}
#endif

	return 0;
}

