#include "JTData_PCD.hxx"
#include <QFile>
#include <QVector>
#include <qtextstream.h>

using namespace Eigen;

float			 *JTData_PCD::myPCDBuffer = NULL;
int				  JTData_PCD::myPCDNumPoints = 0;

void JTData_PCD::LoadPCD(const QString& fname)
{
	QFile pcdFile(fname);

	// Write header of the PCD File
	if (!pcdFile.open(QIODevice::ReadOnly))
	{
		qInfo("Unable to open file for Point Cloud read.");
		return;
	}

	QTextStream pcdTxtIn(&pcdFile);
	QString line, dataType;
	int pcdWidth, pcdHeight;
	int numPoints = 0;


	pcdTxtIn.readLine();    // "# .PCD v.7 - Point Cloud Data file format\n";
	pcdTxtIn.readLine();	   // "VERSION .7\n";
	pcdTxtIn.readLine();	   // "FIELDS x y z rgba\n";
	pcdTxtIn.readLine();	   // "SIZE 4 4 4 4\n";
	pcdTxtIn.readLine();	   // "TYPE F F F U\n";
	pcdTxtIn.readLine();	   // "COUNT 1 1 1 1\n";
	pcdTxtIn >> line >> pcdWidth;  // "WIDTH " << numValidPoints << "\n";
	pcdTxtIn >> line >> pcdHeight; // "HEIGHT 1\n";
	pcdTxtIn.readLine();
	pcdTxtIn.readLine();	   // "VIEWPOINT 0 0 0 1 0 0 0\n";
	pcdTxtIn >> line >> numPoints; // "POINTS " << numValidPoints << "\n";
	pcdTxtIn.readLine();
	pcdTxtIn >> line >> dataType;

	if (dataType == "binary")
	{
		qInfo("Binary format not supported yet.");
		return;
	}

	float fx = 1740.41f;// 1042.77f;
	float fy = 1742.92f;// 1042.66f;
	float cx = 968.628f;// 606.079f;
	float cy = 541.049f;// 360.599f;
	float k1 = 0.0708872f;// 0.219327f;
	float k2 = -0.257949f;// -0.623225f;
	float k3 = 0.35117f;// 0.58662f;

	myPCDBuffer = new float[numPoints * 3];
	for (int i = 0; i < numPoints * 3; i += 3)
	{
		pcdTxtIn >> myPCDBuffer[i] >> myPCDBuffer[i + 1] >> myPCDBuffer[i + 2];
		pcdTxtIn.readLine();


		float px = myPCDBuffer[i];
		float py = myPCDBuffer[i + 1]; 
		float pz = myPCDBuffer[i + 2];

		float ru = sqrt((px * px + py * py) / (pz*pz));
		float rd = ru + k1 * ru * ru * ru + k2 * ru * ru * ru * ru * ru + k3 * ru * ru * ru * ru * ru * ru * ru;
		int x = (int)(px / pz * fx * rd / ru + cx);
		int y = (int)(py / pz * fy * rd / ru + cy);


		myPCDBuffer[i] = x;
		myPCDBuffer[i + 1] = y;
	}

	myPCDNumPoints = numPoints;
	qInfo("numPoints: %d", numPoints);
}

void JTData_PCD::UnloadPCD()
{
	delete[] myPCDBuffer;
	myPCDNumPoints = 0;
}


const float* JTData_PCD::GetPCDBuffer()
{
	return myPCDBuffer;
}

int JTData_PCD::GetPCDNumPoints()
{
	return myPCDNumPoints;
}