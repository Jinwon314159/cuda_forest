#include "nitrogen.cuh"

bool nitrogen::init()
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

	// depth, bodyindex, color frame
	hr = pKinectSensor->OpenMultiSourceFrameReader(FrameSourceTypes::FrameSourceTypes_Depth |
		FrameSourceTypes::FrameSourceTypes_BodyIndex |
		FrameSourceTypes::FrameSourceTypes_Color, &pMultiReader);

	if (FAILED(hr))
	{
		std::cerr << "Error : OpenMultiSourceFrameReader()" << std::endl;
		return false;
	}

	this->pColorRGBX = new RGBQUAD[1920 * 1080];

	hr = pKinectSensor->get_CoordinateMapper(&pCoordinateMapper);

	if (FAILED(hr))
	{
		std::cerr << "Error : get_CoordinateMapper()" << std::endl;
		return false;
	}

	return true;
}

bool nitrogen::setKinectData(UINT16* depthData_, unsigned char* bodyIndexData_, RGBQUAD* colorData_, UINT* dBufferSize_, UINT* cBufferSize_, int* dh_, int* dw_, int* ch_, int* cw_)
{
	bool ret = false;
	HRESULT hr, hr1, hr2, hr3;

	//Depth
	UINT16* depthData = NULL; // depth frame buffer
	UINT dBufferSize = 0;

	//BodyIndex
	unsigned char* bodyIndexData = NULL; // bodyindex frame buffer
	unsigned int bxBufferSize = 0;

	//Color
	ColorImageFormat imageFormat = ColorImageFormat_None;
	RGBQUAD *colorData = NULL; // color frame buffer
	UINT cBufferSize = 0;

	//Get Multi-Frame
	hr = pMultiReader->AcquireLatestFrame(&frame);
	if (SUCCEEDED(hr))
	{
		//Get Frames
		hr1 = frame->get_DepthFrameReference(&dfRef);
		hr2 = frame->get_BodyIndexFrameReference(&bxfRef);
		hr3 = frame->get_ColorFrameReference(&cfRef);

		if (SUCCEEDED(hr1) && SUCCEEDED(hr2) && SUCCEEDED(hr3))
		{
			hr1 = dfRef->AcquireFrame(&depthframe);
			hr2 = bxfRef->AcquireFrame(&bodyIdxframe);
			hr3 = cfRef->AcquireFrame(&colorframe);

			if (SUCCEEDED(hr1) && SUCCEEDED(hr2) && SUCCEEDED(hr3))
			{
				hr = depthframe->AccessUnderlyingBuffer(&dBufferSize, &depthData);
				hr1 = depthframe->get_FrameDescription(&pDescription);
				hr2 = bodyIdxframe->AccessUnderlyingBuffer(&bxBufferSize, &bodyIndexData);
				hr3 = colorframe->get_RawColorImageFormat(&imageFormat);

				if (SUCCEEDED(hr) && SUCCEEDED(hr1) && SUCCEEDED(hr2) && SUCCEEDED(hr3))
				{
					// depth frame
					pDescription->get_Height(&(this->dheight)); // 424
					pDescription->get_Width(&(this->dwidth)); // 512
					
					// body index frame
					if (bodyIndexData == NULL)
					{
						std::cerr << "bodyindex frame is null" << std::endl;
						return false;
					}

					memcpy(depthData_, depthData, dBufferSize * sizeof(UINT16));
					memcpy(bodyIndexData_, bodyIndexData, bxBufferSize * sizeof(unsigned char));
					*dw_ = this->dwidth;
					*dh_ = this->dheight;
					*dBufferSize_ = dBufferSize;

					// color frame
					colorframe->get_FrameDescription(&pDescription);

					pDescription->get_Height(&(this->cheight)); // 1020
					pDescription->get_Width(&(this->cwidth)); //1920

					if (imageFormat == ColorImageFormat_Bgra)
					{
						hr = colorframe->AccessRawUnderlyingBuffer(&cBufferSize, reinterpret_cast<BYTE**>(&colorData));
					}
					else if (this->pColorRGBX)
					{
						colorData = this->pColorRGBX;
						cBufferSize = (this->cwidth) * (this->cheight) * sizeof(RGBQUAD);
						hr = colorframe->CopyConvertedFrameDataToArray(cBufferSize, reinterpret_cast<BYTE*>(colorData), ColorImageFormat_Bgra);
					}
					else
					{
						hr = E_FAIL;
					}

					if (SUCCEEDED(hr))
					{
						ret = true;
						memcpy(colorData_, colorData, cBufferSize);
						*ch_ = this->cheight;
						*cw_ = this->cwidth;
						*cBufferSize_ = cBufferSize;
					}
				}
				this->releaseDescription();
				this->releaseFrame();
			}

			this->releaseRef();
		}

		this->releaseMultiFrame();
	}

	depthData = NULL;
	bodyIndexData = NULL;
	colorData = NULL;

	return ret;
}

void nitrogen::releaseMultiFrame()
{
	if (this->frame != NULL)
	{
		this->frame->Release();
		this->frame = NULL;
	}
}

void nitrogen::releaseFrame()
{
	// release frames
	if (this->depthframe != NULL) // depth
	{
		this->depthframe->Release();
		this->depthframe = NULL;
	}
	if (this->bodyIdxframe != NULL) // bodyindex
	{
		this->bodyIdxframe->Release();
		this->bodyIdxframe = NULL;
	}
	if (this->colorframe != NULL) // color
	{
		this->colorframe->Release();
		this->colorframe = NULL;
	}
}

void nitrogen::releaseRef()
{
	if (dfRef != NULL)
	{
		dfRef->Release();
		dfRef = NULL;
	}
	if (bxfRef != NULL)
	{
		bxfRef->Release();
		bxfRef = NULL;
	}
	if (cfRef != NULL)
	{
		cfRef->Release();
		cfRef = NULL;
	}
}

void nitrogen::releaseReader()
{
	if (pMultiReader != NULL)
	{
		pMultiReader->Release();
		pMultiReader = NULL;
	}
}
void nitrogen::releaseDescription()
{
	if (pDescription != NULL)
	{
		pDescription->Release();
		pDescription = NULL;
	}
}

void nitrogen::close()
{
	std::cout << "nitrogen::close()" << std::endl;
	pCoordinateMapper->Release();

	if (this->pColorRGBX)
	{
		delete this->pColorRGBX;
		this->pColorRGBX = NULL;
	}

	if (pKinectSensor)
		pKinectSensor->Close();

	if (pKinectSensor != NULL)
	{
		pKinectSensor->Release();
		pKinectSensor = NULL;
	}
}

bool nitrogen::kinectMapper(UINT16* depth_data, UINT buffer_size, ColorSpacePoint* colorSpacePoints_, CameraSpacePoint* cameraSpacePoints_)
{
	HRESULT hr = pCoordinateMapper->MapDepthFrameToCameraSpace(buffer_size, depth_data, buffer_size, cameraSpacePoints_);
	if (!SUCCEEDED(hr))
	{
		std::cerr << "Error : MapDepthFrameToCameraSpace()" << std::endl;
		return false;
	}

	hr = pCoordinateMapper->MapDepthFrameToColorSpace(buffer_size, depth_data, buffer_size, colorSpacePoints_);
	if (!SUCCEEDED(hr))
	{
		std::cerr << "Error : MapDepthFrameToColorSpace()" << std::endl;
		return false;
	}

	return true;
}

bool nitrogen::kinectMapper2(DepthSpacePoint depthSpacePoint_, UINT16 depth, CameraSpacePoint* cameraSpacePoint_)
{
	HRESULT hr = pCoordinateMapper->MapDepthPointToCameraSpace(depthSpacePoint_, depth, cameraSpacePoint_);
	if (!SUCCEEDED(hr))
	{
		std::cerr << "Error : MapDepthPointToCameraSpace()" << std::endl;
		return false;
	}
	return true;
}

void nitrogen::writeDepthFile(UINT16* depth_data, UINT dBufferSize, int fNum)
{
	FILE *dst;
	errno_t err;

	//this->count = fNum; // set current frame number

	// depth file
	std::string d_filename = "./data/depth/calcium_data/depth_data_";
	d_filename += std::to_string(fNum);
	d_filename += ".dat";

	const char *dfilename = d_filename.c_str();

	// depth file
	err = fopen_s(&dst, dfilename, "wb");
	if (err != 0)
	{
		std::cerr << "File Open error!" << std::endl;
		return;
	}

	err = fwrite(depth_data, sizeof(UINT16), dBufferSize, dst);
	if (err != dBufferSize)
	{
		std::cerr << "File Write error!" << std::endl;
		return;
	}

	fclose(dst);
}