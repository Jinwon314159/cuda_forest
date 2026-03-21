#include "calcium.cuh"
float radius;
float radius_origin;
float phi;
float theta;

CRITICAL_SECTION cs;
RUNNING_STATE* pState = NULL;

// point
MyColorSpacePoint* colorPoints = NULL;
MyCameraSpacePoint* cameraPoints = NULL;
MyBody3D bodies3D[BODY_COUNT] = { 0 };

// buffer
RGBQUAD *pColorBuffer = NULL;
UINT16* pDepthBuffer = NULL;
int* plabelBuffer = NULL;
UINT16* pBodyIndexDepthBuffer = NULL;

int pBodyIndexCount = 0;

//depth w/h
int p_dwidth;
int p_dheight;

//color w/h
int p_cwidth;
int p_cheight;

// window w/h
int win_width;
int win_height;

// mouse position
int mouse_point[1][2];
int mouse_curser[1][2];
bool is_click = false; // 마우스 왼쪽 클릭을 했나 안했나?
bool is_tracking = false; // 라벨링 시작 후 마우스 위치를 감지하나 안하나
bool is_curser = false; // 마우스 커서 브러쉬 생성?
bool is_color = false;
bool is_erase = false;
bool is_after_menu = false;

// brush 
int brush_size = 0;
int brush_color_index = 0;
// brush color (B G R)
int brush_color[][3] = { { 36, 28, 237 }, { 29, 230, 168 }, { 84, 79, 33 }, { 76, 177, 34 }, { 84, 33, 33 },
{ 239, 183, 0 }, { 222, 255, 104 }, { 243, 109, 77 }, { 33, 84, 79 }, { 0, 242, 255 },
{ 42, 33, 84 }, { 14, 194, 255 }, { 193, 94, 255 }, { 0, 126, 255 }, { 189, 249, 255 },
{ 188, 249, 211 }, { 213, 165, 181 }, { 153, 54, 47 }, { 79, 33, 84 }, { 177, 163, 255 }, 
{ 142, 255, 86 }, { 156, 228, 245 }, { 97, 187, 157 }, { 152, 49, 111 }, { 84, 33, 69 },
{ 60, 90, 156 }, { 146, 122, 255 }, { 122, 170, 229 }
};

// label 
int labeled_pixel_count = 0;

RederingMode renderingMode = VideoMapping;

calcium::calcium()
{
}

void calcium::setBody3D(int idx, bool tracked, MyBody3D* body3D)
{
	EnterCriticalSection(&cs);
	bodies3D[idx].tracked = tracked;
	if (tracked)
		memcpy(&bodies3D[idx], body3D, sizeof(MyBody3D));
	LeaveCriticalSection(&cs);
}

void draw()
{
	EnterCriticalSection(&cs);

	// Depth 그리기
	glBegin(GL_POINTS);
	for (int y = 0; y < p_dheight; y++)
	{
		for (int x = 0; x < p_dwidth; x++)
		{
			int idx = p_dwidth * y + x; // dWidth = 512
			GLfloat val = (GLfloat)pDepthBuffer[idx];
			MyCameraSpacePoint camera_point = cameraPoints[idx];
			MyColorSpacePoint color_point = colorPoints[idx];

			GLfloat r = 1.0f;
			GLfloat g = 1.0f;
			GLfloat b = 1.0f;

			if (renderingMode == ColorMapping)
			{
				GLfloat range = 700.0f;
				GLfloat step = 500.0f;
				GLfloat s = radius_origin + 1350;
				GLfloat pr = s;
				GLfloat pg = s + step;
				GLfloat pb = s + 2 * step;

				r = (range - (val - pr)) / range;
				if (val < pr - range) r = 1.0f;
				if (val > pr + range) r = 0.0f;

				g = (range - abs(pg - val)) / range;
				if (val < pg - range) g = 0.0f;
				if (val > pg + range) g = 0.0f;

				b = (range - (pb - val)) / range;
				if (val < pb - range) b = 0.0f;
				if (val > pb + range) b = 1.0f;
			}
			else
			{
				int p_x = (int)round(colorPoints[idx].X);
				int p_y = (int)round(colorPoints[idx].Y);
				if (p_x >= 0 && p_x < p_cwidth && p_y >= 0 && p_y < p_cheight)
				{
					int cidx = p_y * p_cwidth + p_x;
					RGBQUAD rgbx = pColorBuffer[cidx];
					r = rgbx.rgbRed / 256.0f;
					g = rgbx.rgbGreen / 256.0f;
					b = rgbx.rgbBlue / 256.0f;
				}
			}
			glColor3f(r, g, b);

			GLfloat px = camera_point.X;
			GLfloat py = camera_point.Y;
			GLfloat pz = camera_point.Z - 2.5f;
			glVertex3f(px, py, pz);
		}
	}
	glEnd();

	// Body 그리기
	for (int i = 0; i < BODY_COUNT; i++)
	{
		if (bodies3D[i].tracked)
		{
			//= 관절 그리기 =========================================================
			GLfloat px, py, pz;
			for (int j = 0; j < 28; j++)
			{
				//if (j == 0)
				{
					glColor3f(1.0f, 0.0f, 0.0f);
					double sr = 0.035;
					px = bodies3D[i].joints[j].Position.X;
					py = bodies3D[i].joints[j].Position.Y;
					pz = bodies3D[i].joints[j].Position.Z - 2.5f;
					glPushMatrix();
					glTranslated(px, py, pz);
					glutSolidSphere(sr, 50, 50);
					glPopMatrix();
				}
				/*
				else
				if (j == JointType_ShoulderLeft ||
				j == JointType_ElbowLeft ||
				j == JointType_WristLeft ||
				j == JointType_HandLeft ||
				j == JointType_HandTipLeft)
				{
				if (bodies3D[i].joints[j].TrackingState == TrackingState_Tracked)
				glColor3f(0.0f, 0.9f, 0.9f);
				else
				glColor3f(0.0f, 0.5f, 0.5f);
				}
				else
				if (j == JointType_ShoulderRight ||
				j == JointType_ElbowRight ||
				j == JointType_WristRight ||
				j == JointType_HandRight ||
				j == JointType_HandTipRight)
				{
				if (bodies3D[i].joints[j].TrackingState == TrackingState_Tracked)
				glColor3f(1.0f, 0.8f, 0.0f);
				else
				glColor3f(0.6f, 0.4f, 0.0f);
				}
				else
				if (j == JointType_SpineShoulder)
				{
				if (bodies3D[i].joints[j].TrackingState == TrackingState_Tracked)
				glColor3f(1.0f, 0.0f, 0.0f);
				else
				glColor3f(0.5f, 0.0f, 0.0f);
				}
				else
				{
				if (bodies3D[i].joints[j].TrackingState == TrackingState_Tracked)
				glColor3f(1.0f, 1.0f, 1.0f);
				else
				glColor3f(0.6f, 0.6f, 0.6f);
				}

				double sr = 0.02;
				if (j == JointType_SpineShoulder ||
				j == JointType_ShoulderRight ||
				j == JointType_ShoulderLeft)
				sr = 0.035;

				px = bodies3D[i].joints[j].Position.X;
				py = bodies3D[i].joints[j].Position.Y;
				pz = bodies3D[i].joints[j].Position.Z - z_shift;
				glPushMatrix();
				glTranslated(px, py, pz);
				glutSolidSphere(sr, 50, 50);
				glPopMatrix();
				*/
			}
			//======================================================================
		}
	}

	LeaveCriticalSection(&cs);
}

void drawBrush()
{
	EnterCriticalSection(&cs);

	if (!is_curser && (mouse_point[0][0] < 0 || mouse_point[0][1] < 0))
	{
		LeaveCriticalSection(&cs); 
		return;
	}

	if (is_curser)
	{
		glBegin(GL_QUADS);
		glColor3f(1, 1, 1);

		int x_ = p_dwidth - (mouse_curser[0][0] / 2);
		if (x_ < 0)
			x_ = 0;
		else if (x_ >= p_dwidth)
			x_ = p_dwidth - 1;

		int y_ = mouse_curser[0][1] / 2;
		if (y_ < 0)
			y_ = 0;
		else if (y_ >= p_dheight)
			y_ = p_dheight - 1;

		int idx_ = p_dwidth * y_ + x_;
		float r_ = 0.015 * brush_size;
		MyCameraSpacePoint test_p = cameraPoints[idx_];
		glVertex3f(test_p.X - r_, test_p.Y - r_, test_p.Z - 2.5f);
		glVertex3f(test_p.X - r_, test_p.Y + r_, test_p.Z - 2.5f);
		glVertex3f(test_p.X + r_, test_p.Y + r_, test_p.Z - 2.5f);
		glVertex3f(test_p.X + r_, test_p.Y - r_, test_p.Z - 2.5f);

		glEnd();
	}
	if (is_click && is_tracking && (is_color || is_erase))
	{
		int x_ = p_dwidth - (mouse_point[0][0] / 2);
		if (x_ < 0)
			x_ = 0;
		else if (x_ >= p_dwidth)
			x_ = p_dwidth - 1;

		int y_ = mouse_point[0][1] / 2;
		if (y_ < 0)
			y_ = 0;
		else if (y_ >= p_dheight)
			y_ = p_dheight - 1;

		int br = brush_size * 2;

		int start_y = (y_ - br) < 0 ? 0 : (y_ - br);
		int end_y = (y_ + br) >= p_dheight ? (p_dheight - 1) : (y_ + br);

		int start_x = (x_ - br) < 0 ? 0 : (x_ - br);
		int end_x = (x_ + br) >= p_dwidth ? (p_dwidth - 1) : (x_ + br);

		for (int i = start_y; i <= end_y; i++)
		{
			for (int j = start_x; j <= end_x; j++)
			{
				int idx_ = p_dwidth * i + j;
				
				if (is_erase)
					plabelBuffer[idx_] = 0; // 라벨링으로 선택하지 않은 픽셀 빼고 전부 0으로 처리
				else
					plabelBuffer[idx_] = brush_color_index; // label number
			}
		}

		labeled_pixel_count = 0;
		glBegin(GL_POINTS);
		for (int y = 0; y < p_dheight; y++)
		{
			for (int x = 0; x < p_dwidth; x++)
			{
				int index = p_dwidth * y + x;
				int index_label = plabelBuffer[index];
				if (index_label > 0)
				{
					labeled_pixel_count++;
					float r = brush_color[index_label - 1][2] / 255.0f;
					float g = brush_color[index_label - 1][1] / 255.0f;
					float b = brush_color[index_label - 1][0] / 255.0f;
					glColor3f(r, g, b); // r g b <- b g r

					MyCameraSpacePoint test_p = cameraPoints[index];
					glVertex3f(test_p.X, test_p.Y, test_p.Z - 2.51f);
				}
			}
		}
		glEnd();

	} // if(is_tracking)
	LeaveCriticalSection(&cs); 
}

void display(void)
{
	float   x, y, z;

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	x = radius * sin(phi);
	y = radius * cos(phi) * sin(theta);
	z = radius * cos(phi) * cos(theta);

	gluLookAt(x, y, z, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

	draw();
	drawBrush();
	
	glFlush();
	glutSwapBuffers();

	//Sleep(1); // ????
}

void reshape(int w, int h)
{
	// 창의 크기가 바뀔 때 새로운 창의 크기를 저장
	win_width = w;
	win_height = h;

	glViewport(0, 0, w, h);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	gluPerspective(60.0, 1.0, 1.0, 10000.0);
}

void setRenderingMode(RederingMode mode)
{
	EnterCriticalSection(&cs);
	renderingMode = mode;
	LeaveCriticalSection(&cs);
}

void mainMenu(int value)
{
	switch (value)
	{
	case START:
		std::cout << "start labeling!" << std::endl;
		is_tracking = true;
		is_curser = true;
		*pState = PAUSE;
		break;
	case ERASE:
		is_erase = true;
		mouse_point[0][0] = -1;
		mouse_point[0][1] = -1;
		brush_color_index = 0;
		break;
	case CANCEL:
		is_tracking = false;
		is_curser = false;
		is_erase = false;
		brush_size = 0;
		brush_color_index = 0;
		mouse_point[0][0] = -1;
		mouse_point[0][1] = -1;
		(int*)memset(plabelBuffer, 0, p_dwidth * p_dheight * sizeof(int)); // 0로 초기화
		std::cout << "stop labeling!" << std::endl;
		*pState = RUN;
		break;
	case END:
		is_tracking = false;
		is_curser = false;
		is_erase = false;
		calcium::is_labeled = true;
		mouse_point[0][0] = -1;
		mouse_point[0][1] = -1;
		brush_size = 0;
		brush_color_index = 0;
		(int*)memset(plabelBuffer, 0, p_dwidth * p_dheight * sizeof(int)); // 0로 초기화
		break;
	}

}

void sizeMenu(int value)
{
	//is_after_menu = true;
	switch (value)
	{
	case SIZE1:
		brush_size = 1;
		break;
	case SIZE2:
		brush_size = 2;
		break;
	case SIZE3:
		brush_size = 3;
		break;
	case SIZE4:
		brush_size = 4;
		break;
	case SIZE5:
		brush_size = 5;
		break;
	}
}

void colorMenu(int value)
{
	is_color = true;
	is_erase = false;
	brush_color_index = value;
	is_after_menu = true;
	mouse_point[0][0] = -1;
	mouse_point[0][1] = -1;
}

void createMenu()
{
	// create brush size menu
	int sizeSub = glutCreateMenu(sizeMenu);
	glutAddMenuEntry("brush size 1", SIZE1);
	glutAddMenuEntry("brush size 2", SIZE2);
	glutAddMenuEntry("brush size 3", SIZE3);
	glutAddMenuEntry("brush size 4", SIZE4);
	glutAddMenuEntry("brush size 5", SIZE5);

	// create brush color menu
	int colorSub = glutCreateMenu(colorMenu);
	glutAddMenuEntry("head", 1);
	glutAddMenuEntry("neck", 2);
	glutAddMenuEntry("left shoulder", 3);
	glutAddMenuEntry("left upper arm", 4);
	glutAddMenuEntry("left elbow", 5);
	glutAddMenuEntry("left lower arm", 6);
	glutAddMenuEntry("left wrist", 7);
	glutAddMenuEntry("left hand", 8);
	glutAddMenuEntry("right shoulder", 9);
	glutAddMenuEntry("right upper arm", 10);
	glutAddMenuEntry("right elbow", 11);
	glutAddMenuEntry("right lower arm", 12);
	glutAddMenuEntry("right wrist", 13);
	glutAddMenuEntry("right hand", 14);
	glutAddMenuEntry("left trunk", 15);
	glutAddMenuEntry("right trunk", 16);
	glutAddMenuEntry("left hip", 17);
	glutAddMenuEntry("right hip", 23);
	glutAddMenuEntry("left thigh", 18); // 허벅지
	glutAddMenuEntry("left knee", 19);
	glutAddMenuEntry("left calf", 20); // 종아리
	glutAddMenuEntry("left ankle", 21);
	glutAddMenuEntry("left foot", 22);
	glutAddMenuEntry("right thigh", 24); 
	glutAddMenuEntry("right knee", 25);
	glutAddMenuEntry("right calf", 26);
	glutAddMenuEntry("right ankle", 27);
	glutAddMenuEntry("right foot", 28);

	// create main menu
	GLint main_id = glutCreateMenu(mainMenu);
	glutAddMenuEntry("start labeling", START);
	glutAddSubMenu("brush size", sizeSub);
	glutAddSubMenu("body part", colorSub);
	glutAddMenuEntry("erase", ERASE);
	glutAddMenuEntry("cancel", CANCEL);
	glutAddMenuEntry("save labeling", END);
}

void specialkey(int key, int x, int y) {
	switch (key) {
	case GLUT_KEY_LEFT:
		theta = 0;
		phi -= 0.1f;
		break;
	case GLUT_KEY_RIGHT:
		theta = 0;
		phi += 0.1f;
		break;
	case GLUT_KEY_UP:
		phi = 0;
		theta -= 0.1f;
		if (theta < -PI / 2)
			theta = -PI / 2;
		break;
	case GLUT_KEY_DOWN:
		phi = 0;
		theta += 0.1f;
		if (theta > PI / 2)
			theta = PI / 2;
		break;
	case GLUT_KEY_F1:   glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-1.0*radius, radius, -1.0*radius, radius, -1.0*radius, radius);
		break;
	case GLUT_KEY_F2:   glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluPerspective(60.0, 1.0, 100.0, 10000.0);
		break;
	default:
		break;
	}
}

void mousewheel(int button, int state, int x, int y)
{
	switch (state) {
	case 1:
		radius += 0.1f;
		if (radius > -0.1f)
			radius = -0.1f;
		break;
	case -1:
		radius -= 0.1f;
		break;
	default:
		break;
	}
}

void shortkey(unsigned char key, int x, int y)
{
	// esc를 누르면 사각형 그려진거 취소하기
	switch (key) {
	case 'f':
		phi = 0;
		theta = 0;
		break;
	case 'b':
		phi = PI;
		break;
	case 'l':
		phi = 90;
		break;
	case 'r':
		phi = 3 * PI / 2;
		break;
	case 'c':
		setRenderingMode(ColorMapping);
		break;
	case 'v':
		setRenderingMode(VideoMapping);
		break;
	case 'x':
		*pState = STOP;
		break;
	case 32: // space bar
		if (*pState == RUN)
			*pState = PAUSE;
		else if (*pState == PAUSE)
			*pState = RUN;
		break;
	case 13: // enter
		if (*pState == PAUSE)
		{
			// record original noisy data
			// record ground truth data
		}
		break;
	default:  break;
	}
}

void mouseclick(int button, int state, int x, int y)
{
	if (is_tracking && button == GLUT_LEFT_BUTTON && state == GLUT_DOWN)
	{
		if (!is_after_menu)
		{
			std::cout << "mouse left click x : " << x << ", y : " << y << std::endl;
			mouse_point[0][0] = x;
			mouse_point[0][1] = y;

			is_click = true;
		}
		else
		{
			mouse_point[0][0] = -1;
			mouse_point[0][1] = -1;
			is_after_menu = false;
		}
	}

	glutPostRedisplay();
}

void mousepassive(int x, int y)
{
	if (is_curser)
	{
		mouse_curser[0][0] = x;
		mouse_curser[0][1] = y;
		glutPostRedisplay();
	}
}

void mousemove(int x, int y)
{
	if (is_curser)
	{
		mouse_curser[0][0] = x;
		mouse_curser[0][1] = y;
	}

	if (is_tracking && is_click && !is_after_menu)
	{
		//std::cout << "mouse move x : " << x << ", y : " << y << std::endl;
		mouse_point[0][0] = x;
		mouse_point[0][1] = y;
	}

	glutPostRedisplay();
}

void calcium::init()
{
	glClearColor(0.0, 0.0, 0.0, 0.0);
	glColor3f(1.0, 1.0, 0.0);
	radius = -3.0;
	phi = 0.0;
	theta = 0.0;
	glEnable(GL_DEPTH_TEST);

	radius_origin = 500;

	InitializeCriticalSection(&cs);	
	EnterCriticalSection(&cs);

	colorPoints = (MyColorSpacePoint*)calloc(p_dwidth * p_dheight, sizeof(MyColorSpacePoint));
	cameraPoints = (MyCameraSpacePoint*)calloc(p_dwidth * p_dheight, sizeof(MyCameraSpacePoint));

	pDepthBuffer = (UINT16*)calloc(p_dwidth * p_dheight, sizeof(UINT16));
	pColorBuffer = (RGBQUAD*)calloc(p_cwidth * p_cheight, sizeof(RGBQUAD));
	plabelBuffer = (int*)calloc(p_dwidth * p_dheight, sizeof(int));
	pBodyIndexDepthBuffer = (UINT16*)calloc(p_dwidth * p_dheight, sizeof(UINT16));
	//(int*)memset(plabelBuffer, 0, p_dwidth * p_dheight * sizeof(int)); // 0로 초기화(1부터 라벨 시작하니까)

	is_labeled = false;

	LeaveCriticalSection(&cs);
}

/* calcium member */
bool calcium::is_labeled;

int calcium::getLabelBuffer(int *buf)
{
	EnterCriticalSection(&cs);
	memcpy(buf, plabelBuffer, sizeof(int) * p_dwidth * p_dheight);
	// 복사해준 뒤, 리셋
	(int*)memset(plabelBuffer, 0, p_dwidth * p_dheight * sizeof(int));
	LeaveCriticalSection(&cs);

	return labeled_pixel_count;
}
void calcium::getDepthBuffer(UINT16 *buf)
{
	if (pDepthBuffer == NULL)
	{
		std::cout << "Error : getDepthBuffer() " << std::endl;
		return;
	}
	EnterCriticalSection(&cs);
	memcpy(buf, pDepthBuffer, sizeof(UINT16) * p_dwidth * p_dheight);
	LeaveCriticalSection(&cs);
}

void calcium::getBodyIndexDepthBuffer(UINT16* buf)
{
	if (pBodyIndexDepthBuffer == NULL)
	{
		std::cout << "Error : getBodyIndexDepthBuffer() " << std::endl;
		return;
	}
	EnterCriticalSection(&cs);
	memcpy(buf, pBodyIndexDepthBuffer, sizeof(UINT16) * p_dwidth * p_dheight);
	LeaveCriticalSection(&cs);
}

void calcium::draw_depth_3d(UINT len, UINT16* buf, int pointCnt, void* color_points, void* camera_points)
{
	if (len == 0 || pointCnt == 0 || len == NULL || pointCnt == NULL || buf == NULL || color_points == NULL || camera_points == NULL)
	{
		std::cout << "Error : draw_depth_3d() " << std::endl;
		return;
	}
	EnterCriticalSection(&cs);
	memcpy(colorPoints, color_points, sizeof(MyColorSpacePoint)*pointCnt);
	memcpy(cameraPoints, camera_points, sizeof(MyCameraSpacePoint)*pointCnt);
	memcpy(pDepthBuffer, buf, len*sizeof(UINT16));
	LeaveCriticalSection(&cs);
}

void calcium::draw_color(int len, RGBQUAD* frame)
{
	EnterCriticalSection(&cs);
	memcpy(pColorBuffer, frame, len);
	LeaveCriticalSection(&cs);
}

void calcium::setBodyIndexBuffer(int len, UINT16* buffer, int body_count)
{
	EnterCriticalSection(&cs);
	memcpy(pBodyIndexDepthBuffer, buffer, len*sizeof(UINT16));
	pBodyIndexCount = body_count;
	LeaveCriticalSection(&cs);
}

int calcium::getCurrentBodyIndexCount()
{
	// 현재 저장된 body index count를 반환
	return pBodyIndexCount;
}

void calcium::ready(int argc, char** argv, int dw, int dh, int cw, int ch, RUNNING_STATE* state)
{
	p_dheight = dh;
	p_dwidth = dw;

	p_cheight = ch;
	p_cwidth = cw;

	pState = state;

	win_width = p_dwidth * 2;
	win_height = p_dheight * 2;

	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH);
	glutInitWindowSize(win_width, win_height);

	glutCreateWindow("point cloud");
	glutDisplayFunc(display);
	glutSpecialFunc(specialkey);
	glutKeyboardFunc(shortkey);
	createMenu();
	glutAttachMenu(GLUT_RIGHT_BUTTON);
	glutMouseFunc(mouseclick); // mouse click
	glutMotionFunc(mousemove); // mouse move
	glutPassiveMotionFunc(mousepassive); // mouse passive motion
	glutMouseWheelFunc(mousewheel);
	glutReshapeFunc(reshape);
	glutIdleFunc(display);

	this->init();
}

void calcium::run()
{
	glutMainLoop();
}

void calcium::stop()
{
	glutSetOption(GLUT_ACTION_ON_WINDOW_CLOSE, GLUT_ACTION_GLUTMAINLOOP_RETURNS);
	glutLeaveMainLoop();
}

void calcium::free_all()
{
	pState = NULL;
	renderingMode = VideoMapping;
	pBodyIndexCount = 0;

	free(colorPoints);
	colorPoints = NULL;
	free(cameraPoints);
	cameraPoints = NULL;
	free(pDepthBuffer);
	pDepthBuffer = NULL;
	free(pColorBuffer);
	pColorBuffer = NULL;
	free(plabelBuffer);
	plabelBuffer = NULL;
	free(pBodyIndexDepthBuffer);
	pBodyIndexDepthBuffer = NULL;

	DeleteCriticalSection(&cs);
}