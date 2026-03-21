#include "kinectManager.h"

bool kinect_manager::init()
{
	HRESULT hr = GetDefaultKinectSensor(&pKinectSensor);
	if (FAILED(hr))
	{
		std::cerr << "Error : GetDefaultKinectSensor" << std::endl;
		return false;
	}

	hr = pKinectSensor->Open();
	if (FAILED(hr))
	{
		std::cerr << "Error : pKinectSensor::Open()" << std::endl;
		return false;
	}

	hr = pKinectSensor->OpenMultiSourceFrameReader(FrameSourceTypes::FrameSourceTypes_Depth |
		FrameSourceTypes::FrameSourceTypes_BodyIndex, &pMultiReader);
	if (FAILED(hr))
	{
		std::cerr << "Error : OpenMultiSourceFrameReader()" << std::endl;
		return false;
	}

	return true;
}

bool kinect_manager::setKinectData(UINT16* depthData_, unsigned char* bodyIndexData_, UINT* dBufferSize_, int* height_, int* width_)
{
	HRESULT hr;

	//Depth
	UINT16* depthData = NULL; // depth frame buffer
	UINT dBufferSize = 0;

	//BodyIndex
	unsigned char* bodyIndexData = nullptr; // bodyindex frame buffer
	unsigned int bxBufferSize = 0;

	//Get Multi-Frame
	hr = pMultiReader->AcquireLatestFrame(&frame);
	if (SUCCEEDED(hr))
	{
		//Get Depth Frame
		hr = frame->get_DepthFrameReference(&dfRef);
		if (SUCCEEDED(hr))
		{
			//Depth
			hr = dfRef->AcquireFrame(&depthframe);
			if (SUCCEEDED(hr))
			{
				hr = depthframe->AccessUnderlyingBuffer(&dBufferSize, &depthData);
				if (!SUCCEEDED(hr)){
					std::cerr << "Error: Depthframe->AccessUnderlyingBuffer()" << std::endl;
					return false;
				}

				hr = depthframe->get_FrameDescription(&pDescription);
				if (!SUCCEEDED(hr)){
					std::cerr << "Error: Depthframe->get_FrameDescription()" << std::endl;
					return false;
				}

				pDescription->get_Height(&(this->height)); // 424
				pDescription->get_Width(&(this->width)); // 512

				//Get BodyIndex Frame
				hr = frame->get_BodyIndexFrameReference(&bxfRef);
				if (SUCCEEDED(hr))
				{
					//BodyIndex
					hr = bxfRef->AcquireFrame(&bodyIdxframe);
					if (SUCCEEDED(hr))
					{
						hr = bodyIdxframe->AccessUnderlyingBuffer(&bxBufferSize, &bodyIndexData);
						if (SUCCEEDED(hr))
						{
							if (bodyIndexData == nullptr || bodyIndexData == NULL)
							{
								std::cerr << "bodyindex frame is null" << std::endl;
								return false;
							}

							memcpy(depthData_, depthData, dBufferSize * sizeof(UINT16));
							memcpy(bodyIndexData_, bodyIndexData, bxBufferSize * sizeof(unsigned char));
							*width_ = this->width;
							*height_ = this->height;
							*dBufferSize_ = dBufferSize;

						}
						else return false;
						// body index frame
					}
					else return false;
				}
				else return false;
			} // depth frame
			else return false;
		} // depth frame ref
		else return false;
	} // multi frame
	else return false;

	this->releaseFrame();
	this->releaseMultiFrame();

	return true;
		
}
void kinect_manager::releaseMultiFrame()
{
	if (this->frame != nullptr)
	{
		this->frame->Release();
		this->frame = nullptr;
	}
}

void kinect_manager::releaseFrame()
{
	// release frames
	if (this->depthframe != nullptr)
	{
		this->depthframe->Release();
		this->depthframe = nullptr;
	}
	if (this->bodyIdxframe != nullptr)
	{
		this->bodyIdxframe->Release();
		this->bodyIdxframe = nullptr;
	}
}

void kinect_manager::releaseRef()
{
	dfRef->Release();
	dfRef = nullptr;
	bxfRef->Release();
	bxfRef = nullptr;
}

void kinect_manager::close()
{
	if (pKinectSensor)
		pKinectSensor->Close();

	pKinectSensor->Release();
}