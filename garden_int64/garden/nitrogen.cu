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

	return true;
}

bool nitrogen::setKinectData(UINT16* depthData_, unsigned char* bodyIndexData_, RGBQUAD* colorData_, UINT* dBufferSize_, UINT* cBufferSize_, int* dh_, int* dw_, int* ch_, int* cw_)
{
	HRESULT hr;

	//Depth
	UINT16* depthData = NULL; // depth frame buffer
	UINT dBufferSize = 0;

	//BodyIndex
	unsigned char* bodyIndexData = NULL; // bodyindex frame buffer
	unsigned int bxBufferSize = 0;

	//Color
	ColorImageFormat imageFormat = ColorImageFormat_None;
	RGBQUAD *colorData = NULL; // color frame buffer
	RGBQUAD* pColorRGBX = NULL;
	UINT cBufferSize = 0;

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

				pDescription->get_Height(&(this->dheight)); // 424
				pDescription->get_Width(&(this->dwidth)); // 512

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

						}
						else return false;
						// body index frame
					}
					else return false;
				}
				else return false;

				//Get Color Frame
				hr = frame->get_ColorFrameReference(&cfRef);
				if (SUCCEEDED(hr))
				{
					hr = cfRef->AcquireFrame(&colorframe);
					if (SUCCEEDED(hr))
					{
						hr = colorframe->get_RawColorImageFormat(&imageFormat);
						if (SUCCEEDED(hr))
						{
							colorframe->get_FrameDescription(&pDescription);

							pDescription->get_Height(&(this->cheight)); // 1020
							pDescription->get_Width(&(this->cwidth)); //1920

							pColorRGBX = new RGBQUAD[cwidth * cheight];

							if (imageFormat == ColorImageFormat_Bgra)
							{
								hr = colorframe->AccessRawUnderlyingBuffer(&cBufferSize, reinterpret_cast<BYTE**>(&colorData));
							}
							else if (pColorRGBX)
							{
								colorData = pColorRGBX;
								cBufferSize = (this->cwidth) * (this->cheight) * sizeof(RGBQUAD);
								hr = colorframe->CopyConvertedFrameDataToArray(cBufferSize, reinterpret_cast<BYTE*>(colorData), ColorImageFormat_Bgra);
							}
							else
							{
								hr = E_FAIL;
							}

							if (SUCCEEDED(hr))
							{
								memcpy(colorData_, colorData, cBufferSize);
								*ch_ = this->cheight;
								*cw_ = this->cwidth;
								*cBufferSize_ = cBufferSize;
							}
							else return false;

						}
						else return false;

					} // acquire color frame
					else return false;

				}// color frame reference
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
		pMultiReader->Release();

	if (pDescription != NULL)
		pDescription->Release();
}

void nitrogen::close()
{
	if (pKinectSensor)
		pKinectSensor->Close();

	if (pKinectSensor != NULL)
		pKinectSensor->Release();
}

bool nitrogen::kinectMapper(UINT16* depth_data, UINT buffer_size, ColorSpacePoint* colorSpacePoints_, CameraSpacePoint* cameraSpacePoints_)
{
	ICoordinateMapper* pCoordinateMapper = NULL;

	//ColorSpacePoint* colorSpacePoints = new ColorSpacePoint[buffer_size];
	//CameraSpacePoint* cameraSpacePoints = new CameraSpacePoint[buffer_size];

	HRESULT hr = pKinectSensor->get_CoordinateMapper(&pCoordinateMapper);
	if (SUCCEEDED(hr))
	{
		hr = pCoordinateMapper->MapDepthFrameToCameraSpace(buffer_size, depth_data, buffer_size, cameraSpacePoints_);
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

	if (pCoordinateMapper != NULL)
		pCoordinateMapper->Release();

	return false;
}