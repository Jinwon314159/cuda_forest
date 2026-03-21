#ifndef JTData_PCD_HeaderFile
#define JTData_PCD_HeaderFile


#pragma warning (push, 0)
#include <Eigen/Core>
#include <Eigen/Geometry>
#include <qstring.h>

#pragma warning (pop)


class JTData_PCD
{
public:

	static void LoadPCD(const QString& fname);
	static const float* GetPCDBuffer();
	static void UnloadPCD();
	static int GetPCDNumPoints();
private:
	JTData_PCD() { }
	static float			*myPCDBuffer;
	static int				 myPCDNumPoints;

};


#endif // JTData_PCD_HeaderFile