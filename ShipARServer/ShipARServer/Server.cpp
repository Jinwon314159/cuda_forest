#include "stdafx.h"
#include "Server.h"

#include "caleb.cuh"
#pragma comment(lib, "garden.lib")
#include <crtdbg.h>

const int ERROR_CODE_UNKNOWN_ERROR = 200;
const int ERROR_CODE_FILE_NOT_FOUNT = 300;
const int ERROR_CODE_INVALID_SESSION_ID = 301;
const int ERROR_CODE_INVALID_BLOCK_ID = 302;

bool checkExistFile(const string& path)
{
	cout << "Check exist file : " << path << endl;
	struct _stat64 info;
	return _stat64(path.c_str(), &info) == 0;
}

bool checkExistFile(char *path)
{
	struct _stat64 info;
	return _stat64(path, &info) == 0;
}


vector<string> GetAllFileLists(string folder, string ext)
{
	vector<string> fileLists;
	string searchPath = folder + "\\*." + ext;
	WIN32_FIND_DATAA fd;
	HANDLE hFind = ::FindFirstFileA(searchPath.c_str(), &fd);
	do {
		if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
			fileLists.push_back(LPCSTR(fd.cFileName));
		}
	} while (::FindNextFileA(hFind, &fd));
	::FindClose(hFind);
	return fileLists;
}


vector<int> GetMinMaxIndex(string folder, string ext)
{
	vector<int> minMaxLists;
	vector<string> files = GetAllFileLists(folder, ext);
	if (files.size() > 0)
	{
		string start_name = files.at(0);
		string end_name = files.at(files.size() - 1);
		int point_index = start_name.find("_", 0) + 1;
		int start_index = (int)strtol(start_name.substr(point_index).c_str(), (char**)NULL, 10);
		int end_index = (int)strtol(end_name.substr(point_index).c_str(), (char**)NULL, 10);
		minMaxLists.push_back(start_index);
		minMaxLists.push_back(end_index);
	}
	else
	{
		minMaxLists.push_back(0);
		minMaxLists.push_back(0);
	}
	
	return minMaxLists;
}


void CreateDirectories(char* sessionid)
{
	char path[256];
	sprintf_s(path, "%s\\%s", GARDEN_PATH, sessionid);
	CreateDirectoryA(path, NULL);
	sprintf_s(path, "%s\\%s\\%s", GARDEN_PATH, sessionid, COLOR_PATH);
	CreateDirectoryA(path, NULL);
	sprintf_s(path, "%s\\%s\\%s", GARDEN_PATH, sessionid, DEPTH_PATH);
	CreateDirectoryA(path, NULL);
	sprintf_s(path, "%s\\%s\\%s", GARDEN_PATH, sessionid, TANGO_PATH);
	CreateDirectoryA(path, NULL);
	sprintf_s(path, "%s\\%s\\%s", GARDEN_PATH, sessionid, FRUIT_PATH);
	CreateDirectoryA(path, NULL);
	sprintf_s(path, "%s\\%s\\%s", GARDEN_PATH, sessionid, RESULT_PATH);
	CreateDirectoryA(path, NULL);
}


void SendResult(CLIENT_DATA* clntData, IO_DATA* ioData)
{
	// TODO : 진척률 계산이 완료(session id에 해당하는 파일이 존재하는 경우)된 경우 결과 전송
	char result[MTU_SIZE] = { 0 };
	char result_path[256] = { 0 };
	sprintf_s(result_path, "%s\\%s\\%s\\%s", GARDEN_PATH, ioData->header.session_id, RESULT_PATH, RESULT_FILE);
	bool checkResult = checkExistFile(string(result_path));
	int read = 0;
	if (checkResult)
	{
		int send_bytes = 0;
		FILE *file;
		fopen_s(&file, result_path, "rb");
		fseek(file, 0, SEEK_END);
		int filesize = ftell(file);
		fseek(file, 0, SEEK_SET);
		printf("# send file size: %d bytes\n", filesize);
		_itoa_s(filesize, result, 10);
		ioData->wsaBuf.buf = result;
		ioData->wsaBuf.len = MTU_SIZE;
		::WSASend(clntData->sock, &(ioData->wsaBuf), 1, NULL, 0, NULL, NULL);	// send file size
		while (1)	// send file contents
		{
			read = fread(result, 1, MTU_SIZE, file);
			if (read == 0)
				break;
			send_bytes += read;
			ioData->wsaBuf.buf = result;
			ioData->wsaBuf.len = read;
			::WSASend(clntData->sock, &(ioData->wsaBuf), 1, NULL, 0, NULL, NULL);
		}
		fclose(file);
		file = 0;
		printf("# send complete...\n");
	}
	else
	{
		sprintf_s(result, "%d", 0);
		ioData->wsaBuf.buf = result;
		ioData->wsaBuf.len = strlen(result);
		::WSASend(clntData->sock, &(ioData->wsaBuf), 1, NULL, 0, NULL, NULL);	// send file size (0)
	}
}


bool CreateFailResult(string sessionId, int result_code) {
	printf("Result Code : %d\n", result_code);
	FILE *fp = 0;
	char result_path[256] = { 0 };
	sprintf_s(result_path, "%s\\%s\\%s\\%s", GARDEN_PATH, sessionId.c_str(), RESULT_PATH, RESULT_FILE);
	errno_t err = fopen_s(&fp, result_path, "w");
	if (err != 0) return false;

	fprintf_s(fp, "{\n");
	fprintf_s(fp, "  \"result code\": %d,\n", result_code);
	fprintf_s(fp, "  \"demand total\": %llu,\n", 0);
	fprintf_s(fp, "  \"supply total\": %llu,\n", 0);
	fprintf_s(fp, "  \"demand elasticity\": %f,\n", 0);
	fprintf_s(fp, "  \"sales\": []\n");
	fprintf_s(fp, "}\n");

	fclose(fp);
	fp = 0;
	return true;
}


Server *pServer;


Server::Server()
{
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
		ErrorHandling("WSAStartup() error!");
}


Server::~Server()
{
	WSACleanup();
}


int Server::setNIC()
{
	SOCKET sd = WSASocket(AF_INET, SOCK_DGRAM, 0, 0, 0, 0);
	if (sd == SOCKET_ERROR) {
		printf("Failed to get a socket. Error ");
		return -1;
	}

	INTERFACE_INFO InterfaceList[20];
	unsigned long nBytesReturned;
	if (WSAIoctl(sd, SIO_GET_INTERFACE_LIST, 0, 0, &InterfaceList,
		sizeof(InterfaceList), &nBytesReturned, 0, 0) == SOCKET_ERROR) {
		printf("Failed calling WSAIoctl: error ");
		return -1;
	}

	int n = 0;

	int nNumInterfaces = nBytesReturned / sizeof(INTERFACE_INFO);
	printf("There are %d interfaces:", nNumInterfaces);
	for (int i = 0; i < nNumInterfaces; ++i) {
		printf("\n");

		sockaddr_in *pAddress;
		pAddress = (sockaddr_in *)& (InterfaceList[i].iiAddress);
		printf(" [%d] %s\n", i, inet_ntoa(pAddress->sin_addr));

		if (strcmp(inet_ntoa(pAddress->sin_addr), "127.0.0.1") != 0)
		{
			n = i;
		}

		pAddress = (sockaddr_in *)& (InterfaceList[i].iiBroadcastAddress);
		printf(" has bcast %s", inet_ntoa(pAddress->sin_addr));

		pAddress = (sockaddr_in *)& (InterfaceList[i].iiNetmask);
		printf(" and netmask %s\n", inet_ntoa(pAddress->sin_addr));
	}

	memcpy(&m_nic, &InterfaceList[n], sizeof(INTERFACE_INFO));

	return n;
}


int Server::run()
{
	HANDLE hThread[255];
	SYSTEM_INFO systemInfo;
	SOCKADDR_IN servAddr;
	CLIENT_DATA* clntData;
	IO_DATA* ioData;

	int flags;
	int recvBytes;

	m_servData.setRun(true);
	m_servData.hCompletionPort = CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, 0, 0);

	GetSystemInfo(&systemInfo);
	unsigned int nProcessors = systemInfo.dwNumberOfProcessors / 2;

	hThread[nProcessors + 1] = (HANDLE)_beginthreadex(NULL, 0, ConsoleUIThread, (LPVOID)this, 0, NULL);

	for (unsigned int i = 0; i < nProcessors; i++)
		hThread[i] = (HANDLE)_beginthreadex(NULL, 0, CompletionThread, (LPVOID)&m_servData, 0, NULL);

	// Task Scheduler
	hThread[nProcessors + 2] = (HANDLE)_beginthreadex(NULL, 0, SchedulerThread, (LPVOID)this, 0, NULL);

	m_hServSock = WSASocket(AF_INET, SOCK_STREAM, 0, NULL, 0, WSA_FLAG_OVERLAPPED);
	memcpy(&servAddr, &m_nic.iiAddress, sizeof(SOCKADDR_IN));
	servAddr.sin_family = AF_INET;
	servAddr.sin_port = htons(SERV_PORT);

	::bind(m_hServSock, (SOCKADDR*)&servAddr, sizeof(servAddr));
	::listen(m_hServSock, 5);
	
	while (m_servData.getRun())
	{
		SOCKET hClntSock;
		SOCKADDR_IN clntAddr;
		int addrLen = sizeof(clntAddr);

		hClntSock = ::WSAAccept(m_hServSock, (SOCKADDR*)&clntAddr, &addrLen, NULL, NULL);

		if (hClntSock == INVALID_SOCKET) {
			printf("accept failed with error: %d\n", WSAGetLastError());
			continue;
		}
		else
			printf("[%d] accepted.\n", hClntSock);

		m_servData.addClntCnt();

		// 연결된 클라이언트의 소켓 핸들 정보와 주소 정보 설정
		clntData = (CLIENT_DATA*)malloc(sizeof(CLIENT_DATA));
		clntData->sock = hClntSock;
		memcpy(&(clntData->addr), &clntAddr, addrLen);

		CreateIoCompletionPort((HANDLE)hClntSock, m_servData.hCompletionPort, (ULONG_PTR)clntData, 0);

		ioData = (IO_DATA*)malloc(sizeof(IO_DATA));
		::memset(ioData, 0, sizeof(IO_DATA));
		ioData->wsaBuf.len = MTU_SIZE;
		ioData->wsaBuf.buf = ioData->buf;
		ioData->p = (byte*)&ioData->header;
		ioData->output = 0;
		ioData->state = INIT;

		// 클라이언트 IP 주소 얻기
		printf("# Connected client addr : %s\n", inet_ntoa(clntAddr.sin_addr));

		flags = 0;

		::WSARecv(clntData->sock,
			&(ioData->wsaBuf),
			1,
			(LPDWORD)&recvBytes,
			(LPDWORD)&flags,
			&(ioData->overlapped),
			NULL
			);
	}

	for (unsigned int i = 0; i < nProcessors + 1; i++)
		WaitForSingleObject(hThread[i], INFINITE);

	return 0;
}


unsigned int Server::CompletionThread(LPVOID pParam)
{
	::printf("CompletionThread started.\n");

	SERVER_DATA* pServData = (SERVER_DATA*)pParam;
	HANDLE hCompletionPort = pServData->hCompletionPort;
	DWORD BytesTransferred;
	CLIENT_DATA* clntData;
	IO_DATA* ioData;
	DWORD flags;
	int result = -1;

	while (1)
	{
		bool ret = GetQueuedCompletionStatus(hCompletionPort, &BytesTransferred, (PULONG_PTR)&clntData, (LPOVERLAPPED*)&ioData, 1000);
		
		if (!ret)
		{
			if (!pServData->getRun())
			{
				::printf("Break;\n");
				break;
			}
			else
				continue;
		}

		if (BytesTransferred == 0)	// EOF
		{
			if (clntData && clntData != NULL && clntData != (CLIENT_DATA*)0xcccccccc && clntData->sock != 0xfeeefeee)
			{
				::printf("free - clntData\n");
				::closesocket(clntData->sock);
				free(clntData);
				clntData = NULL;
				pServData->subClntCnt();
			}
			if (ioData != NULL && ioData != (IO_DATA*)0xcccccccc)
			{
				if (ioData != NULL && ioData->header.cmd == RECEIVE_DATA && ioData->state != BYE)
				{
					::printf("#session : %s, file index : %d, state : %d\n", ioData->header.session_id, ioData->file_index, BYE);
					CreateFailResult(ioData->header.session_id, ERROR_CODE_FILE_NOT_FOUNT);
				}
				if (ioData->output != 0)
				{
					fclose(ioData->output);
					ioData->output = 0;
				}
				::printf("free - ioData\n");
				free(ioData);
				ioData = NULL;
			}
			continue;
		}

		if (BytesTransferred + ioData->clen >= MTU_SIZE * 2)
		{
			printf("error\n");
		}

		ioData->clen += BytesTransferred;	// 현재까지 수신된 data bytes
		printf("# clen : %d, %d\n", ioData->clen, BytesTransferred);

		while (ioData->clen > 0)
		{
			if (ioData->state == INIT && ioData->clen >= sizeof(HEADER))
			{
				memcpy(ioData->p, ioData->buf, sizeof(HEADER));
				memcpy(ioData->buf, ioData->buf + sizeof(HEADER), ioData->clen - sizeof(HEADER));
				ioData->clen -= sizeof(HEADER);
				ioData->wsaBuf.buf = ioData->buf + ioData->clen;

				HEADER* info = (HEADER*)&ioData->header;
				ioData->state = FILEINFO;
				ioData->body_size = 0;
				ioData->file_index = 1;

				if (info->cmd == RECEIVE_DATA)
				{
					CreateDirectories(ioData->header.session_id);
				}
			}

			if (ioData->header.cmd == SEND_RESULT)
			{
				printf("# SEND_RESULT: %s\n", ioData->header.session_id);
				SendResult(clntData, ioData);
				ioData->clen -= sizeof(HEADER);
				ioData->p = (byte*)&ioData->header + ioData->clen;
			}
			else
			{
				if (ioData->state == FILEINFO && ioData->clen >= sizeof(FILE_INFO))
				{
					memcpy(&ioData->file_info, ioData->buf, sizeof(FILE_INFO));
					memcpy(ioData->buf, ioData->buf + sizeof(FILE_INFO), ioData->clen - sizeof(FILE_INFO));
					ioData->clen -= sizeof(FILE_INFO);
					ioData->wsaBuf.buf = ioData->buf + ioData->clen;

					switch (ioData->file_info.type)
					{
					case 0:
						sprintf_s(ioData->filename, "%s\\%s\\%s", GARDEN_PATH, ioData->header.session_id, MATRIX_FILE);
						break;
					case 1:
						sprintf_s(ioData->filename, "%s\\%s\\%s\\%s", GARDEN_PATH, ioData->header.session_id, TANGO_PATH, TANGO_FILE);
						break;
					case 2:
						sprintf_s(ioData->filename, "%s\\%s\\%s", GARDEN_PATH, ioData->header.session_id, BOW_FILE);
						break;
					}
					
					errno_t err = fopen_s(&ioData->output, ioData->filename, "wb");
					if (err != 0)
					{
						::closesocket(clntData->sock);
						break;
					}

					ioData->state = FILEBODY;
				}
				
				if (ioData->state == FILEBODY && ioData->clen > 0)
				{
					size_t len = (ioData->clen > ioData->file_info.length) ? ioData->file_info.length : ioData->clen;
					if (fwrite(ioData->buf, sizeof(char), len, ioData->output) != len)
					{
						::closesocket(clntData->sock);
						break;
					}
					memcpy(ioData->buf, ioData->buf + len, ioData->clen - len);
					ioData->clen -= len;
					ioData->wsaBuf.buf = ioData->buf + ioData->clen;

					ioData->file_info.length -= len;
					if (ioData->file_info.length == 0)
					{
						fclose(ioData->output);
						ioData->output = 0;

						if (ioData->file_index < ioData->header.total_file_count)
						{
							ioData->file_index++;
							ioData->state = FILEINFO;
						}
						else
						{
							ioData->state = BYE;

							// JOB 추가
							JOB job;
							memset(job.sessionId, 0, sizeof(job));
							memset(job.blockId, 0, sizeof(job.blockId));
							strcpy_s(job.sessionId, ioData->header.session_id);
							strcpy_s(job.blockId, ioData->header.block_id);
							pServer->Queue.push(job);
						}
					}
				}
				else
					break;
			}
		}

		memset(&(ioData->overlapped), 0, sizeof(OVERLAPPED));
		ioData->wsaBuf.len = MTU_SIZE;
		//ioData->wsaBuf.buf = ioData->buf + ioData->clen;

		flags = 0;
		::WSARecv(clntData->sock, &(ioData->wsaBuf), 1, NULL, &flags, &(ioData->overlapped), NULL);
	}

	return 0;
}


unsigned int Server::ConsoleUIThread(LPVOID pParam)
{
	if (pServer == NULL)
		pServer = (Server*)pParam;

	Sleep(500);
	::printf("\n\nPress 'q' to quit: \n");
	// wait for q key press
	while (!_kbhit() || _getch() != 'q') { Sleep(1000); }

	pServer->stop();

	return 0;
}


unsigned int Server::SchedulerThread(LPVOID pParam)
{
	::printf("*** Job scheduler thread is started...\n");

	while (1)
	{
		if (!pServer->Queue.empty())
		{
			JOB job = pServer->Queue.front();
			pServer->Queue.pop();
			cout << "Job start, session id : " << job.sessionId << ", block id : " << job.blockId << endl;

			if (strlen(job.sessionId) == 0)
			{
				printf("---> ERROR : Invalid session id. (%s.jt)\n", job.sessionId);
				CreateFailResult(job.sessionId, ERROR_CODE_INVALID_SESSION_ID);
				continue;
			}

			char jt_file_path[256] = { 0 };
			sprintf_s(jt_file_path, JT_DATA_PATH"\\%s.jt", job.blockId);
			string jt_path(jt_file_path);
			if (!checkExistFile(jt_path))
			{
				printf("---> ERROR : No such jt file. (%s.jt)\n", job.blockId);
				CreateFailResult(job.sessionId, ERROR_CODE_INVALID_BLOCK_ID);
				continue;
			}

			// Call JT Assistant
			STARTUPINFOA si;
			PROCESS_INFORMATION pi;
			ZeroMemory(&si, sizeof(si));
			si.cb = sizeof(si);
			ZeroMemory(&pi, sizeof(pi));
			char jt_assisstant[256] = { 0 };
			char arguments[256] = { 0 };

			sprintf_s(jt_assisstant, JTASSISTANT_PATH);
			sprintf_s(arguments, "JTAssistant.exe -session %s -block %s -start 0 -end 0", job.sessionId, job.blockId);
			bool created = CreateProcessA(jt_assisstant, arguments, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi);
			if (!created)
			{
				printf("---> ERROR : Process can not create. (%s)\n", job.sessionId);
				CreateFailResult(job.sessionId, ERROR_CODE_UNKNOWN_ERROR);
				continue;
			}
			WaitForSingleObject(pi.hProcess, 1 * 60 * 1000);
			CloseHandle(pi.hProcess);
			CloseHandle(pi.hThread);

			Sleep(1000);

			char path[256] = { 0 };
			// Call garden grow
			sprintf_s(path, "%s\\%s\\%s", GARDEN_PATH, job.sessionId, DEPTH_PATH);
			vector<int> minMax = GetMinMaxIndex(string(path), "dep");
			printf("# call garden grow...min : %d, max : %d\n", minMax.at(0), minMax.at(1));
			pServer->RunGardenGrow(job.sessionId, minMax.at(0), minMax.at(1));

			// Call garden harvest
			printf("# call garden harvest...min : %d, max : %d\n", 0, 0);
			pServer->RunGardenHarvest(job.sessionId, 0, 0);

			// Call garden sales
			printf("# call garden sales...\n");
			pServer->RunGardenSell(job.sessionId, minMax.at(0), minMax.at(1), 0, 0);

			// Ready to response
			memset(path, 0, sizeof(path));
			sprintf_s(path, "%s\\%s\\%s\\%s", GARDEN_PATH, job.sessionId, RESULT_PATH, RESULT_FILE);
			if (checkExistFile(path))
			{
				printf("# ready to response : %s\n", job.sessionId);
			}
			else
			{
				CreateFailResult(job.sessionId, ERROR_CODE_UNKNOWN_ERROR);
				printf("# Error occurred : %s\n", job.sessionId);
			}
		}
		
		Sleep(1000);
	}

	return 0;
}


void Server::RunGardenGrow(char* sessionId, int start, int end)
{
	GROW_PARAMETERS params;
	params.session = sessionId;
	params.start = start;
	params.end = end;

	grow(&params);
}


void Server::RunGardenHarvest(char* sessionId, int start, int end)
{
	HARVEST_PARAMETERS params;
	params.session = sessionId;
	params.start = start;
	params.end = end;

	harvest(&params);
}


void Server::RunGardenSell(char* sessionId, int grow_start, int grow_end, int harvest_start, int harvest_end)
{
	SELL_PARAMETERS params;
	params.session = sessionId;
	params.grow_start = grow_start;
	params.grow_end = grow_end;
	params.harvest_start = harvest_start;
	params.harvest_end = harvest_end;

	sell(&params);
}

void Server::ErrorHandling(char *message)
{
	OutputDebugStringA(message);
	::printf("%s\n", message);

	fputs(message, stderr);
	fputc('\n', stderr);

	exit(1);
}