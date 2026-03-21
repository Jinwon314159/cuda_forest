// JT format reading and visualization tools
// Copyright (C) 2015 OPEN CASCADE SAS
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 2 of the License, or any later
// version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// Copy of the GNU General Public License is in LICENSE.txt and  
// on <http://www.gnu.org/licenses/>.

#include "global.hxx"

#include <JTGui/JTShot.hxx>
#include <JTData/JTData_JSON.hxx>
#include <JTData/JTData_PCD.hxx>

typedef enum
{
    WindowMode = 0,
    ExportMode
} ViewerMode;

struct RENDERER_PARAMETERS
{
    // session id
    char* session;
    // block id
    char* block;
    // start index
    int start;
    // end index
    int end;
};

void print_usage()
{
    printf("USAGE: JTAssistant -session \"session id\" -block \"block id\" -start 0 -end 0\n");
}

bool parse(int argc, char* argv[], RENDERER_PARAMETERS* params)
{
    if (argc != 9)
        return false;

    for (int i = 1; i < argc; i++)
    {
        if (strcmp("-session", argv[i]) == 0)
            params->session = argv[i + 1];
        if (strcmp("-block", argv[i]) == 0)
            params->block = argv[i + 1];
        if (strcmp("-start", argv[i]) == 0)
            params->start = atoi(argv[i + 1]);
        if (strcmp("-end", argv[i]) == 0)
            params->end = atoi(argv[i + 1]);
    }

    return true;
}

int main(int argc, char **argv)
{


#if 1
    RENDERER_PARAMETERS params;

    if (!parse(argc, argv, &params))
    {
        print_usage();
        return -1;
    }

    char jt_path[256] = { 0 };
    char mvp_path[256] = { 0 };
    char bow_path[256] = { 0 };
    char color_path[256] = { 0 };
    char depth_path[256] = { 0 };

    sprintf_s(jt_path, JT_PATH, params.block);
    sprintf_s(mvp_path, "%s\\%s\\" MVP_PATH, GARDEN_PATH, params.session);
    sprintf_s(bow_path, "%s\\%s\\" BOW_PATH, GARDEN_PATH, params.session);
    sprintf_s(color_path, "%s\\%s\\" COLOR_PATH, GARDEN_PATH, params.session, params.start);
    sprintf_s(depth_path, "%s\\%s\\" DEPTH_PATH, GARDEN_PATH, params.session, params.start);

    float mvp[16] = { 0 };
	float prj[16] = { 0 };

    FILE *fp = 0;
    errno_t err = fopen_s(&fp, mvp_path, "rb");
    if (err != 0)
    {
        qFatal("Unable to open matrix file");
        return -1;
    }
    
	fseek(fp, 0L, SEEK_END);
	size_t sz = ftell(fp);
	fseek(fp, 0L, SEEK_SET);

	if (sz == 128)
	{
		size_t len = fread(mvp, sizeof(float), 16, fp);

		if (len != 16)
		{
			fclose(fp);
			return -1;
		}

		len = fread(prj, sizeof(float), 16, fp);

		if (len != 16)
		{
			fclose(fp);
			return -1;
		}
	}
	else if (sz == 64)
	{
		size_t len = fread(mvp, sizeof(float), 16, fp);

		if (len != 16)
		{
			fclose(fp);
			return -1;
		}
	}
	else
	{
		return -1;
	}
#else

    float mvp[16] = { 1.348801e+000, -2.771612e-001, 1.912047e-002, 1.776856e-002,
        7.775455e-002, 1.489220e+000, 8.447167e-001, 7.849914e-001,
        1.372671e-001, 1.879849e+000, -6.663669e-001, -6.192517e-001,
        -2.396235e+004, 1.341576e+004, 1.084677e+004, 1.058056e+004 };

    char jt_path[256] = "C:\\Work\\Data\\E130S.jt"; // { 0 };
    char mvp_path[256] = "C:\\Work\\Data\\E130S.mvp"; // { 0 };
    char bow_path[256] = "C:\\Work\\Data\\E130S.json"; //{ 0 };
    char color_path[256] = "C:\\Work\\ShipAR_Data\\0\\color\\color_0.png"; //{ 0 };
    char depth_path[256] = "C:\\Work\\ShipAR_Data\\0\\depth\\depth_0.dep"; //{ 0 };

#endif

#if 0
    ViewerMode mode = WindowMode;
#else
    ViewerMode mode = ExportMode;
#endif
    
    JTShot::Init(1, argv);
    JTShot::LoadFile(QString(jt_path), QString(bow_path));
    JTShot::SetWindowSize(GARDEN_WIDTH, GARDEN_HEIGHT);

    if (mode == ExportMode)
        JTShot::SetExportMode(true, true);

	JTShot::SetExportPath(QString(params.session), QString(color_path), QString(depth_path));
	if (sz == 128)
	{
		JTShot::SetMVPMatrix(mvp, prj);
	}
	else
	{
		JTShot::SetMVPMatrix(mvp);
	}
    
    JTShot::Run();
    JTShot::Clean();
    
    return 0;
}
