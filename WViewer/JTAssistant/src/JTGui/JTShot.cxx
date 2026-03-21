#include "JTShot.hxx"


#ifdef _WIN32
#include <Windows.h>
#endif

#include <Message.hxx>
#include <Message_Messenger.hxx>
#include <Message_PrinterOStream.hxx>


using namespace Eigen;

QApplication	 *JTShot::myApp = NULL;
JTGui_MainWindow *JTShot::myMainWindow = NULL;
Matrix4f		  JTShot::myMVP;


int JTShot::Init(int argc, char **argv)
{
    myApp = new QApplication(argc, argv);

    QCoreApplication::setApplicationName("JTAssistant");

    QStringList paths = QCoreApplication::libraryPaths();
    paths.append(".");
    paths.append("platforms");
    QCoreApplication::setLibraryPaths(paths);

    // command line tools

    QCommandLineParser aParser;
    aParser.setApplicationDescription(QCoreApplication::translate("main",
        "Viewer for JT files."));

    aParser.addHelpOption();

    aParser.addPositionalArgument("filename", QCoreApplication::translate("main",
        "JT file to open (8 or 9 JT format version)."));

    QCommandLineOption aBenchmarkOption(QStringList() << "b" << "benchmark",
        QCoreApplication::translate("main",
        "Measure loading time."));
    aParser.addOption(aBenchmarkOption);

    QCommandLineOption aLogOption(QStringList() << "l" << "log",
        QCoreApplication::translate("main",
        "Enables logging."));
    aParser.addOption(aLogOption);

    aParser.process(*myApp);

    const QStringList anArgs = aParser.positionalArguments();

    Handle(Message_PrinterOStream) aCoutPrinter
        = Handle(Message_PrinterOStream)::DownCast(::Message::DefaultMessenger()->ChangePrinters().First());
    if (!aCoutPrinter.IsNull())
    {
#ifdef _DEBUG
        aCoutPrinter->SetTraceLevel(Message_Trace);
#else
        aCoutPrinter->SetTraceLevel(aParser.isSet(aLogOption) ? Message_Trace : Message_Alarm);
#endif
    }

    // window
    QApplication::setStyle(QStyleFactory::create("Fusion"));


#if !defined (_DEBUG) && defined (_WIN32)
    if (anArgs.size() == 0)
    {
        if (!aParser.isSet(aLogOption))
        {
            FreeConsole();
        }
    }
#endif

    JTCommon_CmdArgs aParams = { anArgs.size() == 0 ? "" : anArgs.at(0), aParser.isSet(aBenchmarkOption) };

    myMainWindow = new JTGui_MainWindow();
    myMainWindow->setCmdArgs(aParams);
    myMainWindow->show();

    return 1;
}

void JTShot::Clean()
{
    if (myMainWindow) delete myMainWindow;
    if (myApp) delete myApp;
}

void JTShot::SetWindowSize(int width, int height)
{
    myMainWindow->setOSWindowSize(width, height);
}


void JTShot::SetExportMode(bool mode, bool enableMulti)
{
    myMainWindow->setOSExportMode(mode, enableMulti);
}

void JTShot::SetExportPath(const QString& session, const QString& cPath, const QString& dPath)
{
	myMainWindow->setOSExportPath(session, cPath, dPath);
}


void JTShot::LoadFile(const QString& jt_fname, const QString& bow_fname)
{
    myMainWindow->loadOSFile(jt_fname, bow_fname);
}


void JTShot::SetCamera(const QString& fname, bool isOrtho)
{
    myMainWindow->ImportCameraParams(fname, isOrtho);
}

#if 1
void JTShot::SetMVPMatrix(float mat[16])
{
#if 0
    // Tango Projection Mat
    static float pMat[16] = {
        1.62933, 0.f, 0.0530016, 0.f,
        0.f, 2.89628, 0.00166385, 0.f,
        0.f, 0.f, -1.002f, -0.2002f,
        0.f, 0.f, -1.0, 0.f };
#else
    static float pMat[16] = {
        1.812926, 0.000000, -0.008988, 0.000000,
        0.000000, 3.227633, 0.001942, 0.000000,
        0.000000, 0.000000, -1.002002, -0.200200,
        0.000000, 0.000000, -1.000000, 0.000000
    };
#endif
    Matrix4f projM = Matrix4f(pMat);

    // Apply to the given MVP... 
    myMVP = Matrix4f(mat);
	myMVP = projM.transpose() * myMVP.transpose();
	//myMVP = projM.transpose() * myMVP;
	//myMVP = Matrix4f(mat).transpose();
	//myMVP = projM * myMVP;
#if 0
    //// "hard coded adjustments"
    //-------------------------------------------------//
    // Testing desired rotation and translationg here..
    // Test 15 degree rotation about the X axis... 
    AngleAxisf myRotation = AngleAxisf::Identity();
    Affine3f aRotation = Affine3f::Identity();
    Affine3f aTranslation = Affine3f::Identity();

    // Translate...
    aTranslation.translation() = -Vector3f(0, 530, 100);

    // Rotatate some angle...
    float angleAroundX = 0; // -5.0f / 180.0f * static_cast<float> (M_PI);
    float angleAroundY = 0; // 15.0f / 180.0f * static_cast<float>(	M_PI);
    float angleAroundZ = 3.4f / 360.0f; //; // 15.0f / 180.0f * static_cast<float>(M_PI);
    myRotation = AngleAxisf(angleAroundX, Vector3f::UnitX()) *
        AngleAxisf(angleAroundY, Vector3f::UnitY()) *
        AngleAxisf(angleAroundZ, Vector3f::UnitZ()) *
        myRotation;
    aRotation = myRotation.matrix();

    // Uncomment below to see.. 
    //myMVP = myMVP * aRotation.matrix() ;
    myMVP = myMVP * aRotation.matrix() * aTranslation.matrix();
#endif

    myMainWindow->setOSMVPMatrix(myMVP);
}
#else
void JTShot::SetMVPMatrix(float mat[16])
{	

    //-------------------------------------------------//
    // Testing desired rotation and translationg here..
    // Test 15 degree rotation about the X axis... 

    AngleAxisf myRotation = AngleAxisf::Identity();
    Affine3f aRotation = Affine3f::Identity();
    Affine3f aTranslation = Affine3f::Identity();

    // Translate...
    aTranslation.translation() = -Vector3f(0, 530, 100);

    // Rotatate some angle...
    float angleAroundX = 0; // -5.0f / 180.0f * static_cast<float> (M_PI);
    float angleAroundY = 0; // 15.0f / 180.0f * static_cast<float>(	M_PI);
    float angleAroundZ = 3.4f / 360.0f; //; // 15.0f / 180.0f * static_cast<float>(M_PI);
    myRotation = AngleAxisf(angleAroundX, Vector3f::UnitX()) *
                 AngleAxisf(angleAroundY, Vector3f::UnitY()) *
                 AngleAxisf(angleAroundZ, Vector3f::UnitZ()) *
                 myRotation;
    aRotation = myRotation.matrix();

    static float pMat[16] = { 1.62933, 0.f, 0.0530016, 0.f,
        0.f, 2.89628, 0.00166385, 0.f,
        0.f, 0.f, -1.002f, -0.2002,
        0.f, 0.f, -1.0, 0.f };
    Matrix4f projM = Matrix4f(pMat);


    
    // Apply to the given MVP... 
    myMVP = Matrix4f(mat);
    myMVP = projM.transpose() * myMVP.transpose();
    // Uncomment below to see.. 
    //myMVP = myMVP * aRotation.matrix() ;
    myMVP = myMVP * aRotation.matrix() * aTranslation.matrix();




    myMainWindow->setOSMVPMatrix(myMVP);
}
#endif

void JTShot::SetMVPMatrix(float mat[16], float prj[16])
{
	Matrix4f projM = Matrix4f(prj);

	// Apply to the given MVP... 
	myMVP = Matrix4f(mat);
	myMVP = projM.transpose() * myMVP.transpose();
	myMainWindow->setOSMVPMatrix(myMVP);
}

int JTShot::Run()
{
    return myApp->exec();
}