#ifndef JTShot_HeaderFile
#define JTShot_HeaderFile

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


#pragma warning (push, 0)
#include <Eigen/Core>
#include <Eigen/Geometry>

#include <QApplication>
#include <QPoint>
#include <QStyleFactory>
#include <QCommandLineOption>
#include <QCommandLineParser>
#pragma warning (pop)

#include <JTGui/JTGui_MainWindow.hxx>

class JTShot
{
public:
    static int  Init(int argc, char **argv);
    static void Clean();
    static void SetWindowSize(int width, int height);
    static void SetExportMode(bool mode, bool enableMulti = false);
	static void SetExportPath(const QString& session, const QString& cPath, const QString& dPath);
    static void LoadFile(const QString& jt_fname, const QString& bow_fname);
    static void SetCamera(const QString& fname, bool isOrtho);
    static void SetMVPMatrix(float mat[16]);
	static void SetMVPMatrix(float mat[16], float prj[16]);
    static int  Run();

    static JTGui_MainWindow *myMainWindow;
    static QApplication     *myApp;
    static Eigen::Matrix4f   myMVP;
private:
    JTShot() {}
};

#endif // JTShot_HeaderFile