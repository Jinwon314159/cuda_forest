#pragma once

//#define MEMORY_LEAK_CHECK
#ifdef MEMORY_LEAK_CHECK
#include <Psapi.h>
#endif

#ifdef GARDEN_EXPORTS
#define GARDEN_API __declspec(dllexport)
#else
#define GARDEN_API __declspec(dllimport)
#endif

struct GARDEN_API GROW_PARAMETERS
{
	// session id
	char* session;
	// start index
	int start;
	// end index
	int end;
};
GARDEN_API bool grow(GROW_PARAMETERS* params);

struct GARDEN_API HARVEST_PARAMETERS
{
	// session id
	char* session;
	// start index
	int start;
	// end index
	int end;
};
GARDEN_API bool harvest(HARVEST_PARAMETERS* params);

struct GARDEN_API SELL_PARAMETERS
{
	// session id
	char* session;
	// grow start index
	int grow_start;
	// grow end index
	int grow_end;
	// harvest start index
	int harvest_start;
	// harvest end index
	int harvest_end;
};
GARDEN_API bool sell(SELL_PARAMETERS* params);