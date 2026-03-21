#pragma once
#define _WINSOCK_DEPRECATED_NO_WARNINGS

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <WinSock2.h>
#include <WS2tcpip.h>
#include <Mstcpip.h>
#include <Windows.h>
#include <process.h>
#include <string>
#include <iostream>
#include <fstream>
#include <list>
#include <queue>
#include <sys/stat.h>

#pragma comment(lib, "ws2_32.lib")

#define SERV_PORT		7777	// server port no.
#define MTU_SIZE		1024
#define GARDEN_PATH		"C:\\ShipAR_DATA"
#define JT_DATA_PATH	"C:\\JT_DATA"
#define RENDERER_PATH	"C:\\windows_install_swp\\WViewer\\new_build\\JTAssistant\\Release\\"
#define COLOR_PATH		"color"
#define	DEPTH_PATH		"depth"
#define TANGO_PATH		"tango"
#define FRUIT_PATH		"fruit"
#define RESULT_PATH		"result"
#define TANGO_FILE		"tango_0.dep"
#define BOW_FILE		"bow.json"
#define RESULT_FILE		"sales.json"
#define MATRIX_FILE		"transform.mat"

#define RECEIVE_DATA	0
#define	SEND_RESULT		1

using namespace std;

typedef struct
{
	SOCKET sock;
	SOCKADDR_IN addr;
} CLIENT_DATA;

typedef struct {
	int cmd;
	char session_id[256];
	char block_id[256];
	int total_file_count;
} HEADER;

typedef struct
{
	int type;					// 0 : transform matrix, 1: tango depth, 2 : bow(bill of work)
	int length;
} FILE_INFO;

typedef enum
{
	INIT,
	FILEINFO,
	FILEBODY,
	BYE
} CLIENT_STATE;

typedef struct
{
	OVERLAPPED overlapped;
	WSABUF wsaBuf;
	char buf[MTU_SIZE * 2];

	HEADER header;
	FILE_INFO file_info;
	FILE *output;
	byte* p;
	char filename[256];			// 저장 파일명
	int clen;					// 전체 데이터 전송량
	int body_size;				// 전체 파일 사이즈
	int total_file_count;
	int file_index;				// 전송 대상 파일 인덱스
	int file_length;			// 전송될 파일 사이즈 (개별)
	int transferred;			// 전송된 바이트 수 (개별)
	char filebuf[MTU_SIZE * 2];
	CLIENT_STATE state;
} IO_DATA;

typedef struct
{
	char sessionId[256];
	char blockId[256];
} JOB;

class SERVER_DATA
{
private:
	bool m_bRun;
	int m_clntCnt;
	CRITICAL_SECTION m_cs;
public:
	HANDLE hCompletionPort;
	SERVER_DATA(void) {
		hCompletionPort = NULL;
		m_bRun = false;
		m_clntCnt = 0;
		InitializeCriticalSection(&m_cs);
	};
	~SERVER_DATA(void) { DeleteCriticalSection(&m_cs); };
	void setRun(bool run) {
		EnterCriticalSection(&m_cs);
		m_bRun = run;
		LeaveCriticalSection(&m_cs);
	};
	bool getRun() {
		bool ret = 0;
		EnterCriticalSection(&m_cs);
		ret = m_bRun;
		LeaveCriticalSection(&m_cs);
		return ret;
	};
	void addClntCnt() {
		EnterCriticalSection(&m_cs);
		++m_clntCnt;
		LeaveCriticalSection(&m_cs);
	};
	void subClntCnt() {
		EnterCriticalSection(&m_cs);
		--m_clntCnt;
		printf("a client has left out.. number of the rest is %d.\n", m_clntCnt);
		LeaveCriticalSection(&m_cs);
	};
	void setClntCnt(int cnt) {
		EnterCriticalSection(&m_cs);
		m_clntCnt = cnt;
		LeaveCriticalSection(&m_cs);
	};
	int getClntCnt() {
		int ret = 0;
		EnterCriticalSection(&m_cs);
		ret = m_clntCnt;
		LeaveCriticalSection(&m_cs);
		return ret;
	};
};

class Server
{
public:
	Server();
	~Server();

	SERVER_DATA m_servData;
	INTERFACE_INFO m_nic;
	SOCKET m_hServSock;
	list<string> List;
	list<string>::iterator wait_list;
	queue<JOB> Queue;
	
	int setNIC();
	int run();
	void ErrorHandling(char*);
	void stop() {
		::closesocket(m_hServSock);
		m_servData.setRun(false);
		printf("Terminating server...\n");
		Sleep(1500);
	};

	static unsigned int __stdcall CompletionThread(LPVOID pParam);
	static unsigned int __stdcall ConsoleUIThread(LPVOID pServer);
	static unsigned int __stdcall SchedulerThread(LPVOID pParam);

	void RunGardenGrow(char* sessionId, int start, int end);
	void RunGardenHarvest(char* sessionId, int start, int end);
	void RunGardenSell(char* sessionId, int grow_start, int grow_end, int harvest_start, int harvest_end);
};
