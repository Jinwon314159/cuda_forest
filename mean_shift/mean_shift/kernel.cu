
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <Windows.h>
#include "mean_shift.h"


int main()
{
	cudaError_t status = cudaSuccess;
	
	run();
	cv::destroyAllWindows();

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    status = cudaDeviceReset();
    if (status != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }

    return 0;
}
