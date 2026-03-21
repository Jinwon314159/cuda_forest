// ShipARServer.cpp : 콘솔 응용 프로그램에 대한 진입점을 정의합니다.
//

#include "stdafx.h"
#include "Server.h"


int _tmain(int argc, _TCHAR* argv[])
{
	Server server;
	server.setNIC();
	server.run();

	return 0;
}