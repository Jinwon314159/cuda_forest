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

// buffer
RGBQUAD *pColorBuffer = NULL;
UINT16* pDepthBuffer = NULL;

//depth w/h
int p_dwidth;
int p_dheight;

//colro w/h
int p_cwidth;
int p_cheight;

// window w/h
int win_width;
int win_height;

RederingMode renderingMode = VideoMapping;

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

	glFlush();
	glutSwapBuffers();

	Sleep(1); // ????
}

void reshape(int w, int h)
{
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

	LeaveCriticalSection(&cs);
}

void calcium::draw_depth_3d(UINT len, UINT16* buf, int pointCnt, void* color_points, void* camera_points)
{
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
	//glutInitWindowSize(p_cwidth/2, p_cheight/2);

	glutCreateWindow("test");
	glutDisplayFunc(display);
	glutSpecialFunc(specialkey);
	glutKeyboardFunc(shortkey);
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

	free(colorPoints);
	free(cameraPoints);
	free(pDepthBuffer);
	free(pColorBuffer);
	DeleteCriticalSection(&cs);
}