#include "cnutrient.cuh"
#include "FileManager.h"

class kinect_manager
{
public:
	bool init();
	bool setKinectData(UINT16* depthData_, unsigned char* bodyIndexData_, UINT* dBufferSize_, int* height_, int* width_);
	void releaseFrame();
	void releaseMultiFrame();
	void releaseRef(); // release references
	void close(); // close & release kinect sensor
	
	int width;
	int height;

private:
	IKinectSensor* pKinectSensor = NULL;
	IMultiSourceFrameReader* pMultiReader = NULL;
	IFrameDescription* pDescription; //Description
	// Frame References
	IDepthFrameReference* dfRef = nullptr;
	IBodyIndexFrameReference* bxfRef = nullptr;
	// frame
	IMultiSourceFrame* frame = nullptr; //MultiFrame
	IDepthFrame* depthframe = nullptr;
	IBodyIndexFrame* bodyIdxframe = nullptr;
};