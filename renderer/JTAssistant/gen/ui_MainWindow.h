/********************************************************************************
** Form generated from reading UI file 'MainWindow.ui'
**
** Created by: Qt User Interface Compiler version 5.7.0
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QButtonGroup>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QFrame>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenu>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QScrollArea>
#include <QtWidgets/QSlider>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QSplitter>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QToolBar>
#include <QtWidgets/QToolButton>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>
#include "JTGui_MainWindow.hxx"

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QAction *actionOpen;
    QAction *actionExit;
    QAction *actionFitAll;
    QAction *actionZoom;
    QAction *actionZoomArea;
    QAction *actionMove;
    QAction *actionRotate;
    QAction *actionViewTop;
    QAction *actionViewBottom;
    QAction *actionViewLeft;
    QAction *actionViewDefault;
    QAction *actionClose;
    QAction *actionPrint;
    QAction *actionPrintPreview;
    QAction *actionCopy;
    QAction *actionAbout;
    QAction *actionHideItem;
    QAction *actionCollapseAll;
    QAction *actionViewOnly;
    QAction *actionViewAll;
    QAction *actionViewRight;
    QAction *actionViewFront;
    QAction *actionViewBack;
    QAction *actionSaveSelection;
    QAction *actionShowAxes;
    QAction *actionEnablePerspective;
    QAction *actionScreenshot;
    QAction *actionShowToolbar;
    QAction *actionShowBrowser;
    QWidget *myCentralWidget;
    QVBoxLayout *verticalLayout;
    QSplitter *mySplitter;
    QTabWidget *tabWidget;
    QWidget *myTabModel;
    QHBoxLayout *horizontalLayout;
    JTGui_TreeWidget *myTreeWidget;
    QWidget *myTabOptions;
    QVBoxLayout *verticalLayout_2;
    QScrollArea *scrollArea;
    QWidget *scrollAreaWidgetContents;
    QVBoxLayout *verticalLayout_6;
    QGroupBox *groupBox;
    QVBoxLayout *verticalLayout_3;
    QCheckBox *viewCullingCheckBox;
    QCheckBox *sizeCullingCheckBox;
    QSpacerItem *verticalSpacer_2;
    QCheckBox *myOsdCheck;
    QGroupBox *groupBox_2;
    QVBoxLayout *verticalLayout_4;
    QLabel *label;
    QSlider *lodQualitySlider;
    QGroupBox *groupBox_3;
    QVBoxLayout *verticalLayout_7;
    QHBoxLayout *horizontalLayout_8;
    QLabel *label_3;
    QToolButton *toolButton_2;
    QToolButton *toolButton;
    QToolButton *toolButton_3;
    QHBoxLayout *myKeyBindLayout_2;
    QLabel *label_9;
    JTGui_ClickableLabel *myColorLabel;
    QToolButton *myColorPickButton;
    QGroupBox *myCameraControlsBox;
    QVBoxLayout *verticalLayout_5;
    QCheckBox *myAnimateCheck;
    QCheckBox *myAutoFitCheck;
    QSpacerItem *verticalSpacer_3;
    QHBoxLayout *horizontalLayout_5;
    QLabel *label_4;
    QComboBox *myPresetComboBox;
    QHBoxLayout *myKeyBindLayout;
    QLabel *label_6;
    QHBoxLayout *horizontalLayout_3;
    QLabel *label_2;
    QToolButton *toolButton_6;
    QToolButton *toolButton_4;
    QToolButton *toolButton_5;
    QHBoxLayout *horizontalLayout_9;
    QLabel *label_7;
    QToolButton *toolButton_7;
    QToolButton *toolButton_8;
    QToolButton *toolButton_9;
    QHBoxLayout *horizontalLayout_10;
    QLabel *label_8;
    QToolButton *toolButton_10;
    QToolButton *toolButton_11;
    QToolButton *toolButton_12;
    QLabel *myMenuWarningLabel;
    QLabel *mySameButtonWarningLabel;
    QCheckBox *myZoomWithWheelCheck;
    QSpacerItem *verticalSpacer;
    QFrame *myContainer;
    QHBoxLayout *horizontalLayout_2;
    QMenuBar *menubar;
    QMenu *menuFile;
    QMenu *menuHelp;
    QMenu *menuView;
    QMenu *menuNavigation;
    QMenu *menuStandard_Views;
    QMenu *menuSelection;
    QMenu *menuWindow;
    QStatusBar *statusbar;
    QToolBar *myToolBar;
    QButtonGroup *myZoomingButtons;
    QButtonGroup *myRotationButtons;
    QButtonGroup *myPanningButtons;
    QButtonGroup *mySelectionButtons;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QStringLiteral("MainWindow"));
        MainWindow->resize(553, 280);
        QIcon icon;
        icon.addFile(QStringLiteral(":/desktop/res/icons/desktop/icon.png"), QSize(), QIcon::Normal, QIcon::Off);
        MainWindow->setWindowIcon(icon);
        actionOpen = new QAction(MainWindow);
        actionOpen->setObjectName(QStringLiteral("actionOpen"));
        QIcon icon1;
        icon1.addFile(QStringLiteral(":/desktop/res/icons/desktop/folder_b.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionOpen->setIcon(icon1);
        actionExit = new QAction(MainWindow);
        actionExit->setObjectName(QStringLiteral("actionExit"));
        actionFitAll = new QAction(MainWindow);
        actionFitAll->setObjectName(QStringLiteral("actionFitAll"));
        actionFitAll->setEnabled(true);
        QIcon icon2;
        icon2.addFile(QStringLiteral(":/desktop/res/icons/desktop/Fitall.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionFitAll->setIcon(icon2);
        actionZoom = new QAction(MainWindow);
        actionZoom->setObjectName(QStringLiteral("actionZoom"));
        actionZoom->setCheckable(true);
        actionZoom->setChecked(false);
        actionZoom->setEnabled(true);
        QIcon icon3;
        icon3.addFile(QStringLiteral(":/desktop/res/icons/desktop/Zoom.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionZoom->setIcon(icon3);
        actionZoomArea = new QAction(MainWindow);
        actionZoomArea->setObjectName(QStringLiteral("actionZoomArea"));
        actionZoomArea->setEnabled(true);
        actionMove = new QAction(MainWindow);
        actionMove->setObjectName(QStringLiteral("actionMove"));
        actionMove->setCheckable(true);
        actionMove->setEnabled(true);
        QIcon icon4;
        icon4.addFile(QStringLiteral(":/desktop/res/icons/desktop/Move.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionMove->setIcon(icon4);
        actionRotate = new QAction(MainWindow);
        actionRotate->setObjectName(QStringLiteral("actionRotate"));
        actionRotate->setCheckable(true);
        actionRotate->setEnabled(true);
        QIcon icon5;
        icon5.addFile(QStringLiteral(":/desktop/res/icons/desktop/Rotate.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionRotate->setIcon(icon5);
        actionViewTop = new QAction(MainWindow);
        actionViewTop->setObjectName(QStringLiteral("actionViewTop"));
        actionViewTop->setEnabled(true);
        QIcon icon6;
        icon6.addFile(QStringLiteral(":/desktop/res/icons/desktop/top36t.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionViewTop->setIcon(icon6);
        actionViewBottom = new QAction(MainWindow);
        actionViewBottom->setObjectName(QStringLiteral("actionViewBottom"));
        actionViewBottom->setEnabled(true);
        QIcon icon7;
        icon7.addFile(QStringLiteral(":/desktop/res/icons/desktop/bottom36t.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionViewBottom->setIcon(icon7);
        actionViewLeft = new QAction(MainWindow);
        actionViewLeft->setObjectName(QStringLiteral("actionViewLeft"));
        actionViewLeft->setEnabled(true);
        QIcon icon8;
        icon8.addFile(QStringLiteral(":/desktop/res/icons/desktop/left36t.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionViewLeft->setIcon(icon8);
        actionViewDefault = new QAction(MainWindow);
        actionViewDefault->setObjectName(QStringLiteral("actionViewDefault"));
        actionViewDefault->setEnabled(true);
        QIcon icon9;
        icon9.addFile(QStringLiteral(":/desktop/res/icons/desktop/Iso.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionViewDefault->setIcon(icon9);
        actionClose = new QAction(MainWindow);
        actionClose->setObjectName(QStringLiteral("actionClose"));
        actionClose->setEnabled(true);
        actionPrint = new QAction(MainWindow);
        actionPrint->setObjectName(QStringLiteral("actionPrint"));
        actionPrint->setEnabled(false);
        actionPrintPreview = new QAction(MainWindow);
        actionPrintPreview->setObjectName(QStringLiteral("actionPrintPreview"));
        actionPrintPreview->setEnabled(false);
        actionCopy = new QAction(MainWindow);
        actionCopy->setObjectName(QStringLiteral("actionCopy"));
        actionCopy->setEnabled(false);
        actionAbout = new QAction(MainWindow);
        actionAbout->setObjectName(QStringLiteral("actionAbout"));
        actionAbout->setEnabled(true);
        actionHideItem = new QAction(MainWindow);
        actionHideItem->setObjectName(QStringLiteral("actionHideItem"));
        actionCollapseAll = new QAction(MainWindow);
        actionCollapseAll->setObjectName(QStringLiteral("actionCollapseAll"));
        actionViewOnly = new QAction(MainWindow);
        actionViewOnly->setObjectName(QStringLiteral("actionViewOnly"));
        actionViewAll = new QAction(MainWindow);
        actionViewAll->setObjectName(QStringLiteral("actionViewAll"));
        actionViewRight = new QAction(MainWindow);
        actionViewRight->setObjectName(QStringLiteral("actionViewRight"));
        actionViewRight->setEnabled(true);
        QIcon icon10;
        icon10.addFile(QStringLiteral(":/desktop/res/icons/desktop/right36t.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionViewRight->setIcon(icon10);
        actionViewFront = new QAction(MainWindow);
        actionViewFront->setObjectName(QStringLiteral("actionViewFront"));
        actionViewFront->setEnabled(true);
        QIcon icon11;
        icon11.addFile(QStringLiteral(":/desktop/res/icons/desktop/front36t.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionViewFront->setIcon(icon11);
        actionViewBack = new QAction(MainWindow);
        actionViewBack->setObjectName(QStringLiteral("actionViewBack"));
        actionViewBack->setEnabled(true);
        QIcon icon12;
        icon12.addFile(QStringLiteral(":/desktop/res/icons/desktop/back36t.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionViewBack->setIcon(icon12);
        actionSaveSelection = new QAction(MainWindow);
        actionSaveSelection->setObjectName(QStringLiteral("actionSaveSelection"));
        actionSaveSelection->setEnabled(true);
        QIcon icon13;
        icon13.addFile(QStringLiteral(":/desktop/res/icons/desktop/folder.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionSaveSelection->setIcon(icon13);
        actionShowAxes = new QAction(MainWindow);
        actionShowAxes->setObjectName(QStringLiteral("actionShowAxes"));
        actionShowAxes->setCheckable(true);
        QIcon icon14;
        icon14.addFile(QStringLiteral(":/desktop/res/icons/desktop/Axes.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionShowAxes->setIcon(icon14);
        actionEnablePerspective = new QAction(MainWindow);
        actionEnablePerspective->setObjectName(QStringLiteral("actionEnablePerspective"));
        actionEnablePerspective->setCheckable(true);
        QIcon icon15;
        icon15.addFile(QStringLiteral(":/desktop/res/icons/desktop/hline.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionEnablePerspective->setIcon(icon15);
        actionScreenshot = new QAction(MainWindow);
        actionScreenshot->setObjectName(QStringLiteral("actionScreenshot"));
        QIcon icon16;
        icon16.addFile(QStringLiteral(":/desktop/res/icons/desktop/screenshot.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionScreenshot->setIcon(icon16);
        actionShowToolbar = new QAction(MainWindow);
        actionShowToolbar->setObjectName(QStringLiteral("actionShowToolbar"));
        actionShowToolbar->setCheckable(true);
        QIcon icon17;
        icon17.addFile(QStringLiteral(":/desktop/res/icons/desktop/gear.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionShowToolbar->setIcon(icon17);
        actionShowBrowser = new QAction(MainWindow);
        actionShowBrowser->setObjectName(QStringLiteral("actionShowBrowser"));
        actionShowBrowser->setCheckable(true);
        QIcon icon18;
        icon18.addFile(QStringLiteral(":/desktop/res/icons/desktop/group.png"), QSize(), QIcon::Normal, QIcon::Off);
        actionShowBrowser->setIcon(icon18);
        myCentralWidget = new QWidget(MainWindow);
        myCentralWidget->setObjectName(QStringLiteral("myCentralWidget"));
        verticalLayout = new QVBoxLayout(myCentralWidget);
        verticalLayout->setSpacing(0);
        verticalLayout->setObjectName(QStringLiteral("verticalLayout"));
        verticalLayout->setContentsMargins(0, 0, 0, 0);
        mySplitter = new QSplitter(myCentralWidget);
        mySplitter->setObjectName(QStringLiteral("mySplitter"));
        QSizePolicy sizePolicy(QSizePolicy::Preferred, QSizePolicy::Preferred);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(mySplitter->sizePolicy().hasHeightForWidth());
        mySplitter->setSizePolicy(sizePolicy);
        mySplitter->setStyleSheet(QStringLiteral(""));
        mySplitter->setFrameShape(QFrame::NoFrame);
        mySplitter->setFrameShadow(QFrame::Sunken);
        mySplitter->setLineWidth(1);
        mySplitter->setOrientation(Qt::Horizontal);
        mySplitter->setHandleWidth(3);
        tabWidget = new QTabWidget(mySplitter);
        tabWidget->setObjectName(QStringLiteral("tabWidget"));
        tabWidget->setLayoutDirection(Qt::LeftToRight);
        tabWidget->setStyleSheet(QStringLiteral(""));
        tabWidget->setTabPosition(QTabWidget::South);
        tabWidget->setTabShape(QTabWidget::Rounded);
        tabWidget->setElideMode(Qt::ElideNone);
        tabWidget->setUsesScrollButtons(true);
        tabWidget->setDocumentMode(true);
        tabWidget->setMovable(false);
        myTabModel = new QWidget();
        myTabModel->setObjectName(QStringLiteral("myTabModel"));
        sizePolicy.setHeightForWidth(myTabModel->sizePolicy().hasHeightForWidth());
        myTabModel->setSizePolicy(sizePolicy);
        horizontalLayout = new QHBoxLayout(myTabModel);
        horizontalLayout->setSpacing(0);
        horizontalLayout->setObjectName(QStringLiteral("horizontalLayout"));
        horizontalLayout->setContentsMargins(0, 0, 0, 0);
        myTreeWidget = new JTGui_TreeWidget(myTabModel);
        QTreeWidgetItem *__qtreewidgetitem = new QTreeWidgetItem();
        __qtreewidgetitem->setText(0, QStringLiteral("1"));
        myTreeWidget->setHeaderItem(__qtreewidgetitem);
        myTreeWidget->setObjectName(QStringLiteral("myTreeWidget"));
        myTreeWidget->setFrameShape(QFrame::NoFrame);
        myTreeWidget->setRootIsDecorated(true);
        myTreeWidget->setHeaderHidden(true);
        myTreeWidget->header()->setVisible(false);

        horizontalLayout->addWidget(myTreeWidget);

        tabWidget->addTab(myTabModel, QString());
        myTabOptions = new QWidget();
        myTabOptions->setObjectName(QStringLiteral("myTabOptions"));
        sizePolicy.setHeightForWidth(myTabOptions->sizePolicy().hasHeightForWidth());
        myTabOptions->setSizePolicy(sizePolicy);
        myTabOptions->setStyleSheet(QStringLiteral(""));
        verticalLayout_2 = new QVBoxLayout(myTabOptions);
        verticalLayout_2->setObjectName(QStringLiteral("verticalLayout_2"));
        scrollArea = new QScrollArea(myTabOptions);
        scrollArea->setObjectName(QStringLiteral("scrollArea"));
        scrollArea->setFrameShape(QFrame::NoFrame);
        scrollArea->setWidgetResizable(true);
        scrollAreaWidgetContents = new QWidget();
        scrollAreaWidgetContents->setObjectName(QStringLiteral("scrollAreaWidgetContents"));
        scrollAreaWidgetContents->setGeometry(QRect(0, 0, 227, 688));
        verticalLayout_6 = new QVBoxLayout(scrollAreaWidgetContents);
        verticalLayout_6->setSpacing(6);
        verticalLayout_6->setObjectName(QStringLiteral("verticalLayout_6"));
        verticalLayout_6->setContentsMargins(2, 0, 2, 0);
        groupBox = new QGroupBox(scrollAreaWidgetContents);
        groupBox->setObjectName(QStringLiteral("groupBox"));
        verticalLayout_3 = new QVBoxLayout(groupBox);
        verticalLayout_3->setObjectName(QStringLiteral("verticalLayout_3"));
        viewCullingCheckBox = new QCheckBox(groupBox);
        viewCullingCheckBox->setObjectName(QStringLiteral("viewCullingCheckBox"));
        viewCullingCheckBox->setChecked(true);

        verticalLayout_3->addWidget(viewCullingCheckBox);

        sizeCullingCheckBox = new QCheckBox(groupBox);
        sizeCullingCheckBox->setObjectName(QStringLiteral("sizeCullingCheckBox"));
        sizeCullingCheckBox->setChecked(true);

        verticalLayout_3->addWidget(sizeCullingCheckBox);

        verticalSpacer_2 = new QSpacerItem(20, 10, QSizePolicy::Minimum, QSizePolicy::Minimum);

        verticalLayout_3->addItem(verticalSpacer_2);

        myOsdCheck = new QCheckBox(groupBox);
        myOsdCheck->setObjectName(QStringLiteral("myOsdCheck"));
        myOsdCheck->setChecked(true);

        verticalLayout_3->addWidget(myOsdCheck);


        verticalLayout_6->addWidget(groupBox);

        groupBox_2 = new QGroupBox(scrollAreaWidgetContents);
        groupBox_2->setObjectName(QStringLiteral("groupBox_2"));
        verticalLayout_4 = new QVBoxLayout(groupBox_2);
        verticalLayout_4->setObjectName(QStringLiteral("verticalLayout_4"));
        label = new QLabel(groupBox_2);
        label->setObjectName(QStringLiteral("label"));
        label->setFrameShape(QFrame::NoFrame);

        verticalLayout_4->addWidget(label);

        lodQualitySlider = new QSlider(groupBox_2);
        lodQualitySlider->setObjectName(QStringLiteral("lodQualitySlider"));
        lodQualitySlider->setValue(25);
        lodQualitySlider->setOrientation(Qt::Horizontal);

        verticalLayout_4->addWidget(lodQualitySlider);


        verticalLayout_6->addWidget(groupBox_2);

        groupBox_3 = new QGroupBox(scrollAreaWidgetContents);
        groupBox_3->setObjectName(QStringLiteral("groupBox_3"));
        verticalLayout_7 = new QVBoxLayout(groupBox_3);
        verticalLayout_7->setObjectName(QStringLiteral("verticalLayout_7"));
        horizontalLayout_8 = new QHBoxLayout();
        horizontalLayout_8->setSpacing(0);
        horizontalLayout_8->setObjectName(QStringLiteral("horizontalLayout_8"));
        label_3 = new QLabel(groupBox_3);
        label_3->setObjectName(QStringLiteral("label_3"));
        QSizePolicy sizePolicy1(QSizePolicy::Fixed, QSizePolicy::Preferred);
        sizePolicy1.setHorizontalStretch(0);
        sizePolicy1.setVerticalStretch(0);
        sizePolicy1.setHeightForWidth(label_3->sizePolicy().hasHeightForWidth());
        label_3->setSizePolicy(sizePolicy1);
        label_3->setMinimumSize(QSize(55, 0));

        horizontalLayout_8->addWidget(label_3);

        toolButton_2 = new QToolButton(groupBox_3);
        mySelectionButtons = new QButtonGroup(MainWindow);
        mySelectionButtons->setObjectName(QStringLiteral("mySelectionButtons"));
        mySelectionButtons->addButton(toolButton_2);
        toolButton_2->setObjectName(QStringLiteral("toolButton_2"));
        QSizePolicy sizePolicy2(QSizePolicy::Minimum, QSizePolicy::Fixed);
        sizePolicy2.setHorizontalStretch(0);
        sizePolicy2.setVerticalStretch(0);
        sizePolicy2.setHeightForWidth(toolButton_2->sizePolicy().hasHeightForWidth());
        toolButton_2->setSizePolicy(sizePolicy2);
        toolButton_2->setCheckable(true);
        toolButton_2->setChecked(true);
        toolButton_2->setAutoExclusive(true);
        toolButton_2->setAutoRaise(true);

        horizontalLayout_8->addWidget(toolButton_2);

        toolButton = new QToolButton(groupBox_3);
        mySelectionButtons->addButton(toolButton);
        toolButton->setObjectName(QStringLiteral("toolButton"));
        sizePolicy2.setHeightForWidth(toolButton->sizePolicy().hasHeightForWidth());
        toolButton->setSizePolicy(sizePolicy2);
        toolButton->setCheckable(true);
        toolButton->setAutoRaise(true);

        horizontalLayout_8->addWidget(toolButton);

        toolButton_3 = new QToolButton(groupBox_3);
        mySelectionButtons->addButton(toolButton_3);
        toolButton_3->setObjectName(QStringLiteral("toolButton_3"));
        sizePolicy2.setHeightForWidth(toolButton_3->sizePolicy().hasHeightForWidth());
        toolButton_3->setSizePolicy(sizePolicy2);
        toolButton_3->setCheckable(true);
        toolButton_3->setAutoRaise(true);

        horizontalLayout_8->addWidget(toolButton_3);


        verticalLayout_7->addLayout(horizontalLayout_8);

        myKeyBindLayout_2 = new QHBoxLayout();
        myKeyBindLayout_2->setSpacing(5);
        myKeyBindLayout_2->setObjectName(QStringLiteral("myKeyBindLayout_2"));
        label_9 = new QLabel(groupBox_3);
        label_9->setObjectName(QStringLiteral("label_9"));
        sizePolicy1.setHeightForWidth(label_9->sizePolicy().hasHeightForWidth());
        label_9->setSizePolicy(sizePolicy1);
        label_9->setMinimumSize(QSize(50, 0));

        myKeyBindLayout_2->addWidget(label_9);

        myColorLabel = new JTGui_ClickableLabel(groupBox_3);
        myColorLabel->setObjectName(QStringLiteral("myColorLabel"));
        sizePolicy.setHeightForWidth(myColorLabel->sizePolicy().hasHeightForWidth());
        myColorLabel->setSizePolicy(sizePolicy);
        myColorLabel->setMinimumSize(QSize(50, 0));
        myColorLabel->setStyleSheet(QStringLiteral("QLabel { background-color : rgb(14, 255, 215); }"));
        myColorLabel->setFrameShape(QFrame::Box);

        myKeyBindLayout_2->addWidget(myColorLabel);

        myColorPickButton = new QToolButton(groupBox_3);
        myColorPickButton->setObjectName(QStringLiteral("myColorPickButton"));

        myKeyBindLayout_2->addWidget(myColorPickButton);


        verticalLayout_7->addLayout(myKeyBindLayout_2);


        verticalLayout_6->addWidget(groupBox_3);

        myCameraControlsBox = new QGroupBox(scrollAreaWidgetContents);
        myCameraControlsBox->setObjectName(QStringLiteral("myCameraControlsBox"));
        verticalLayout_5 = new QVBoxLayout(myCameraControlsBox);
        verticalLayout_5->setObjectName(QStringLiteral("verticalLayout_5"));
        myAnimateCheck = new QCheckBox(myCameraControlsBox);
        myAnimateCheck->setObjectName(QStringLiteral("myAnimateCheck"));

        verticalLayout_5->addWidget(myAnimateCheck);

        myAutoFitCheck = new QCheckBox(myCameraControlsBox);
        myAutoFitCheck->setObjectName(QStringLiteral("myAutoFitCheck"));

        verticalLayout_5->addWidget(myAutoFitCheck);

        verticalSpacer_3 = new QSpacerItem(20, 10, QSizePolicy::Minimum, QSizePolicy::Minimum);

        verticalLayout_5->addItem(verticalSpacer_3);

        horizontalLayout_5 = new QHBoxLayout();
        horizontalLayout_5->setSpacing(0);
        horizontalLayout_5->setObjectName(QStringLiteral("horizontalLayout_5"));
        label_4 = new QLabel(myCameraControlsBox);
        label_4->setObjectName(QStringLiteral("label_4"));
        sizePolicy1.setHeightForWidth(label_4->sizePolicy().hasHeightForWidth());
        label_4->setSizePolicy(sizePolicy1);
        label_4->setMinimumSize(QSize(55, 0));

        horizontalLayout_5->addWidget(label_4);

        myPresetComboBox = new QComboBox(myCameraControlsBox);
        myPresetComboBox->setObjectName(QStringLiteral("myPresetComboBox"));

        horizontalLayout_5->addWidget(myPresetComboBox);

        horizontalLayout_5->setStretch(1, 1);

        verticalLayout_5->addLayout(horizontalLayout_5);

        myKeyBindLayout = new QHBoxLayout();
        myKeyBindLayout->setSpacing(6);
        myKeyBindLayout->setObjectName(QStringLiteral("myKeyBindLayout"));
        label_6 = new QLabel(myCameraControlsBox);
        label_6->setObjectName(QStringLiteral("label_6"));

        myKeyBindLayout->addWidget(label_6);


        verticalLayout_5->addLayout(myKeyBindLayout);

        horizontalLayout_3 = new QHBoxLayout();
        horizontalLayout_3->setSpacing(0);
        horizontalLayout_3->setObjectName(QStringLiteral("horizontalLayout_3"));
        label_2 = new QLabel(myCameraControlsBox);
        label_2->setObjectName(QStringLiteral("label_2"));
        sizePolicy1.setHeightForWidth(label_2->sizePolicy().hasHeightForWidth());
        label_2->setSizePolicy(sizePolicy1);
        label_2->setMinimumSize(QSize(55, 0));

        horizontalLayout_3->addWidget(label_2);

        toolButton_6 = new QToolButton(myCameraControlsBox);
        myRotationButtons = new QButtonGroup(MainWindow);
        myRotationButtons->setObjectName(QStringLiteral("myRotationButtons"));
        myRotationButtons->addButton(toolButton_6);
        toolButton_6->setObjectName(QStringLiteral("toolButton_6"));
        QSizePolicy sizePolicy3(QSizePolicy::Expanding, QSizePolicy::Fixed);
        sizePolicy3.setHorizontalStretch(0);
        sizePolicy3.setVerticalStretch(0);
        sizePolicy3.setHeightForWidth(toolButton_6->sizePolicy().hasHeightForWidth());
        toolButton_6->setSizePolicy(sizePolicy3);
        toolButton_6->setCheckable(true);
        toolButton_6->setChecked(true);
        toolButton_6->setAutoExclusive(true);
        toolButton_6->setAutoRaise(true);

        horizontalLayout_3->addWidget(toolButton_6);

        toolButton_4 = new QToolButton(myCameraControlsBox);
        myRotationButtons->addButton(toolButton_4);
        toolButton_4->setObjectName(QStringLiteral("toolButton_4"));
        sizePolicy3.setHeightForWidth(toolButton_4->sizePolicy().hasHeightForWidth());
        toolButton_4->setSizePolicy(sizePolicy3);
        toolButton_4->setCheckable(true);
        toolButton_4->setAutoRaise(true);

        horizontalLayout_3->addWidget(toolButton_4);

        toolButton_5 = new QToolButton(myCameraControlsBox);
        myRotationButtons->addButton(toolButton_5);
        toolButton_5->setObjectName(QStringLiteral("toolButton_5"));
        sizePolicy3.setHeightForWidth(toolButton_5->sizePolicy().hasHeightForWidth());
        toolButton_5->setSizePolicy(sizePolicy3);
        toolButton_5->setCheckable(true);
        toolButton_5->setAutoRaise(true);

        horizontalLayout_3->addWidget(toolButton_5);


        verticalLayout_5->addLayout(horizontalLayout_3);

        horizontalLayout_9 = new QHBoxLayout();
        horizontalLayout_9->setSpacing(0);
        horizontalLayout_9->setObjectName(QStringLiteral("horizontalLayout_9"));
        label_7 = new QLabel(myCameraControlsBox);
        label_7->setObjectName(QStringLiteral("label_7"));
        sizePolicy1.setHeightForWidth(label_7->sizePolicy().hasHeightForWidth());
        label_7->setSizePolicy(sizePolicy1);
        label_7->setMinimumSize(QSize(55, 0));

        horizontalLayout_9->addWidget(label_7);

        toolButton_7 = new QToolButton(myCameraControlsBox);
        myPanningButtons = new QButtonGroup(MainWindow);
        myPanningButtons->setObjectName(QStringLiteral("myPanningButtons"));
        myPanningButtons->addButton(toolButton_7);
        toolButton_7->setObjectName(QStringLiteral("toolButton_7"));
        sizePolicy2.setHeightForWidth(toolButton_7->sizePolicy().hasHeightForWidth());
        toolButton_7->setSizePolicy(sizePolicy2);
        toolButton_7->setCheckable(true);
        toolButton_7->setChecked(false);
        toolButton_7->setAutoExclusive(true);
        toolButton_7->setAutoRaise(true);

        horizontalLayout_9->addWidget(toolButton_7);

        toolButton_8 = new QToolButton(myCameraControlsBox);
        myPanningButtons->addButton(toolButton_8);
        toolButton_8->setObjectName(QStringLiteral("toolButton_8"));
        sizePolicy2.setHeightForWidth(toolButton_8->sizePolicy().hasHeightForWidth());
        toolButton_8->setSizePolicy(sizePolicy2);
        toolButton_8->setCheckable(true);
        toolButton_8->setChecked(true);
        toolButton_8->setAutoRaise(true);

        horizontalLayout_9->addWidget(toolButton_8);

        toolButton_9 = new QToolButton(myCameraControlsBox);
        myPanningButtons->addButton(toolButton_9);
        toolButton_9->setObjectName(QStringLiteral("toolButton_9"));
        sizePolicy2.setHeightForWidth(toolButton_9->sizePolicy().hasHeightForWidth());
        toolButton_9->setSizePolicy(sizePolicy2);
        toolButton_9->setCheckable(true);
        toolButton_9->setAutoRaise(true);

        horizontalLayout_9->addWidget(toolButton_9);


        verticalLayout_5->addLayout(horizontalLayout_9);

        horizontalLayout_10 = new QHBoxLayout();
        horizontalLayout_10->setSpacing(0);
        horizontalLayout_10->setObjectName(QStringLiteral("horizontalLayout_10"));
        label_8 = new QLabel(myCameraControlsBox);
        label_8->setObjectName(QStringLiteral("label_8"));
        label_8->setEnabled(true);
        sizePolicy1.setHeightForWidth(label_8->sizePolicy().hasHeightForWidth());
        label_8->setSizePolicy(sizePolicy1);
        label_8->setMinimumSize(QSize(55, 0));

        horizontalLayout_10->addWidget(label_8);

        toolButton_10 = new QToolButton(myCameraControlsBox);
        myZoomingButtons = new QButtonGroup(MainWindow);
        myZoomingButtons->setObjectName(QStringLiteral("myZoomingButtons"));
        myZoomingButtons->addButton(toolButton_10);
        toolButton_10->setObjectName(QStringLiteral("toolButton_10"));
        toolButton_10->setEnabled(false);
        sizePolicy2.setHeightForWidth(toolButton_10->sizePolicy().hasHeightForWidth());
        toolButton_10->setSizePolicy(sizePolicy2);
        toolButton_10->setCheckable(true);
        toolButton_10->setChecked(false);
        toolButton_10->setAutoExclusive(true);
        toolButton_10->setAutoRaise(true);

        horizontalLayout_10->addWidget(toolButton_10);

        toolButton_11 = new QToolButton(myCameraControlsBox);
        myZoomingButtons->addButton(toolButton_11);
        toolButton_11->setObjectName(QStringLiteral("toolButton_11"));
        toolButton_11->setEnabled(false);
        sizePolicy2.setHeightForWidth(toolButton_11->sizePolicy().hasHeightForWidth());
        toolButton_11->setSizePolicy(sizePolicy2);
        toolButton_11->setCheckable(true);
        toolButton_11->setAutoRaise(true);

        horizontalLayout_10->addWidget(toolButton_11);

        toolButton_12 = new QToolButton(myCameraControlsBox);
        myZoomingButtons->addButton(toolButton_12);
        toolButton_12->setObjectName(QStringLiteral("toolButton_12"));
        toolButton_12->setEnabled(false);
        sizePolicy2.setHeightForWidth(toolButton_12->sizePolicy().hasHeightForWidth());
        toolButton_12->setSizePolicy(sizePolicy2);
        toolButton_12->setCheckable(true);
        toolButton_12->setChecked(true);
        toolButton_12->setAutoRaise(true);

        horizontalLayout_10->addWidget(toolButton_12);


        verticalLayout_5->addLayout(horizontalLayout_10);

        myMenuWarningLabel = new QLabel(myCameraControlsBox);
        myMenuWarningLabel->setObjectName(QStringLiteral("myMenuWarningLabel"));
        myMenuWarningLabel->setTextFormat(Qt::RichText);
        myMenuWarningLabel->setWordWrap(true);

        verticalLayout_5->addWidget(myMenuWarningLabel);

        mySameButtonWarningLabel = new QLabel(myCameraControlsBox);
        mySameButtonWarningLabel->setObjectName(QStringLiteral("mySameButtonWarningLabel"));

        verticalLayout_5->addWidget(mySameButtonWarningLabel);

        myZoomWithWheelCheck = new QCheckBox(myCameraControlsBox);
        myZoomWithWheelCheck->setObjectName(QStringLiteral("myZoomWithWheelCheck"));
        myZoomWithWheelCheck->setChecked(true);

        verticalLayout_5->addWidget(myZoomWithWheelCheck);


        verticalLayout_6->addWidget(myCameraControlsBox);

        verticalSpacer = new QSpacerItem(20, 40, QSizePolicy::Minimum, QSizePolicy::Expanding);

        verticalLayout_6->addItem(verticalSpacer);

        scrollArea->setWidget(scrollAreaWidgetContents);

        verticalLayout_2->addWidget(scrollArea);

        tabWidget->addTab(myTabOptions, QString());
        mySplitter->addWidget(tabWidget);
        myContainer = new QFrame(mySplitter);
        myContainer->setObjectName(QStringLiteral("myContainer"));
        QSizePolicy sizePolicy4(QSizePolicy::Preferred, QSizePolicy::Preferred);
        sizePolicy4.setHorizontalStretch(100);
        sizePolicy4.setVerticalStretch(0);
        sizePolicy4.setHeightForWidth(myContainer->sizePolicy().hasHeightForWidth());
        myContainer->setSizePolicy(sizePolicy4);
        myContainer->setMinimumSize(QSize(100, 100));
        myContainer->setFrameShape(QFrame::NoFrame);
        myContainer->setFrameShadow(QFrame::Sunken);
        horizontalLayout_2 = new QHBoxLayout(myContainer);
        horizontalLayout_2->setSpacing(0);
        horizontalLayout_2->setObjectName(QStringLiteral("horizontalLayout_2"));
        horizontalLayout_2->setContentsMargins(0, 0, 0, 0);
        mySplitter->addWidget(myContainer);

        verticalLayout->addWidget(mySplitter);

        MainWindow->setCentralWidget(myCentralWidget);
        menubar = new QMenuBar(MainWindow);
        menubar->setObjectName(QStringLiteral("menubar"));
        menubar->setGeometry(QRect(0, 0, 553, 21));
        menubar->setContextMenuPolicy(Qt::PreventContextMenu);
        menubar->setStyleSheet(QLatin1String("QMenuBar::item:selected {\n"
"    background: white;\n"
"}"));
        menuFile = new QMenu(menubar);
        menuFile->setObjectName(QStringLiteral("menuFile"));
        menuHelp = new QMenu(menubar);
        menuHelp->setObjectName(QStringLiteral("menuHelp"));
        menuView = new QMenu(menubar);
        menuView->setObjectName(QStringLiteral("menuView"));
        menuNavigation = new QMenu(menubar);
        menuNavigation->setObjectName(QStringLiteral("menuNavigation"));
        menuStandard_Views = new QMenu(menuNavigation);
        menuStandard_Views->setObjectName(QStringLiteral("menuStandard_Views"));
        menuStandard_Views->setEnabled(true);
        menuSelection = new QMenu(menubar);
        menuSelection->setObjectName(QStringLiteral("menuSelection"));
        menuWindow = new QMenu(menubar);
        menuWindow->setObjectName(QStringLiteral("menuWindow"));
        MainWindow->setMenuBar(menubar);
        statusbar = new QStatusBar(MainWindow);
        statusbar->setObjectName(QStringLiteral("statusbar"));
        MainWindow->setStatusBar(statusbar);
        myToolBar = new QToolBar(MainWindow);
        myToolBar->setObjectName(QStringLiteral("myToolBar"));
        myToolBar->setContextMenuPolicy(Qt::PreventContextMenu);
        myToolBar->setIconSize(QSize(32, 32));
        myToolBar->setFloatable(false);
        MainWindow->addToolBar(Qt::TopToolBarArea, myToolBar);

        menubar->addAction(menuFile->menuAction());
        menubar->addAction(menuNavigation->menuAction());
        menubar->addAction(menuSelection->menuAction());
        menubar->addAction(menuView->menuAction());
        menubar->addAction(menuWindow->menuAction());
        menubar->addAction(menuHelp->menuAction());
        menuFile->addAction(actionOpen);
        menuFile->addAction(actionClose);
        menuFile->addAction(actionExit);
        menuFile->addSeparator();
        menuHelp->addAction(actionAbout);
        menuView->addAction(actionShowAxes);
        menuView->addAction(actionEnablePerspective);
        menuView->addAction(actionScreenshot);
        menuNavigation->addAction(actionFitAll);
        menuNavigation->addAction(actionViewAll);
        menuNavigation->addAction(actionZoom);
        menuNavigation->addAction(actionMove);
        menuNavigation->addAction(actionRotate);
        menuNavigation->addAction(menuStandard_Views->menuAction());
        menuStandard_Views->addAction(actionViewDefault);
        menuStandard_Views->addAction(actionViewTop);
        menuStandard_Views->addAction(actionViewBottom);
        menuStandard_Views->addAction(actionViewLeft);
        menuStandard_Views->addAction(actionViewRight);
        menuStandard_Views->addAction(actionViewFront);
        menuStandard_Views->addAction(actionViewBack);
        menuSelection->addAction(actionHideItem);
        menuSelection->addAction(actionViewOnly);
        menuWindow->addAction(actionShowToolbar);
        menuWindow->addAction(actionShowBrowser);
        myToolBar->addAction(actionOpen);
        myToolBar->addSeparator();
        myToolBar->addAction(actionFitAll);
        myToolBar->addSeparator();
        myToolBar->addAction(actionZoom);
        myToolBar->addAction(actionMove);
        myToolBar->addAction(actionRotate);
        myToolBar->addSeparator();
        myToolBar->addAction(actionShowAxes);
        myToolBar->addAction(actionEnablePerspective);
        myToolBar->addAction(actionViewDefault);
        myToolBar->addAction(actionViewTop);
        myToolBar->addAction(actionViewBottom);
        myToolBar->addAction(actionViewLeft);
        myToolBar->addAction(actionViewRight);
        myToolBar->addAction(actionViewFront);
        myToolBar->addAction(actionViewBack);
        myToolBar->addSeparator();
        myToolBar->addAction(actionSaveSelection);

        retranslateUi(MainWindow);

        tabWidget->setCurrentIndex(1);


        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QApplication::translate("MainWindow", "JTAssistant", 0));
        actionOpen->setText(QApplication::translate("MainWindow", "Open...", 0));
        actionExit->setText(QApplication::translate("MainWindow", "Quit", 0));
        actionFitAll->setText(QApplication::translate("MainWindow", "Fit All", 0));
        actionZoom->setText(QApplication::translate("MainWindow", "Zoom", 0));
        actionZoomArea->setText(QApplication::translate("MainWindow", "Zoom Area", 0));
        actionMove->setText(QApplication::translate("MainWindow", "Pan", 0));
        actionRotate->setText(QApplication::translate("MainWindow", "Rotate", 0));
        actionViewTop->setText(QApplication::translate("MainWindow", "Top", 0));
#ifndef QT_NO_TOOLTIP
        actionViewTop->setToolTip(QApplication::translate("MainWindow", "Top view", 0));
#endif // QT_NO_TOOLTIP
        actionViewBottom->setText(QApplication::translate("MainWindow", "Bottom", 0));
#ifndef QT_NO_TOOLTIP
        actionViewBottom->setToolTip(QApplication::translate("MainWindow", "Bottom view", 0));
#endif // QT_NO_TOOLTIP
        actionViewLeft->setText(QApplication::translate("MainWindow", "Left", 0));
#ifndef QT_NO_TOOLTIP
        actionViewLeft->setToolTip(QApplication::translate("MainWindow", "Left view", 0));
#endif // QT_NO_TOOLTIP
        actionViewDefault->setText(QApplication::translate("MainWindow", "Default", 0));
#ifndef QT_NO_TOOLTIP
        actionViewDefault->setToolTip(QApplication::translate("MainWindow", "Default View", 0));
#endif // QT_NO_TOOLTIP
        actionClose->setText(QApplication::translate("MainWindow", "Close", 0));
        actionPrint->setText(QApplication::translate("MainWindow", "Print", 0));
        actionPrintPreview->setText(QApplication::translate("MainWindow", "Preview", 0));
        actionCopy->setText(QApplication::translate("MainWindow", "Copy", 0));
        actionAbout->setText(QApplication::translate("MainWindow", "About...", 0));
        actionHideItem->setText(QApplication::translate("MainWindow", "Hide", 0));
#ifndef QT_NO_TOOLTIP
        actionHideItem->setToolTip(QApplication::translate("MainWindow", "Hide", 0));
#endif // QT_NO_TOOLTIP
        actionCollapseAll->setText(QApplication::translate("MainWindow", "Collapse all", 0));
        actionViewOnly->setText(QApplication::translate("MainWindow", "View Only", 0));
        actionViewAll->setText(QApplication::translate("MainWindow", "View All", 0));
        actionViewRight->setText(QApplication::translate("MainWindow", "Right", 0));
#ifndef QT_NO_TOOLTIP
        actionViewRight->setToolTip(QApplication::translate("MainWindow", "Right view", 0));
#endif // QT_NO_TOOLTIP
        actionViewFront->setText(QApplication::translate("MainWindow", "Front", 0));
#ifndef QT_NO_TOOLTIP
        actionViewFront->setToolTip(QApplication::translate("MainWindow", "Front view", 0));
#endif // QT_NO_TOOLTIP
        actionViewBack->setText(QApplication::translate("MainWindow", "Back", 0));
#ifndef QT_NO_TOOLTIP
        actionViewBack->setToolTip(QApplication::translate("MainWindow", "Back view", 0));
#endif // QT_NO_TOOLTIP
        actionSaveSelection->setText(QApplication::translate("MainWindow", "Save Selection", 0));
#ifndef QT_NO_TOOLTIP
        actionSaveSelection->setToolTip(QApplication::translate("MainWindow", "Save Selection", 0));
#endif // QT_NO_TOOLTIP
        actionShowAxes->setText(QApplication::translate("MainWindow", "Show axes", 0));
#ifndef QT_NO_TOOLTIP
        actionShowAxes->setToolTip(QApplication::translate("MainWindow", "Show axes", 0));
#endif // QT_NO_TOOLTIP
        actionEnablePerspective->setText(QApplication::translate("MainWindow", "Perspective mode", 0));
#ifndef QT_NO_TOOLTIP
        actionEnablePerspective->setToolTip(QApplication::translate("MainWindow", "Perspective mode", 0));
#endif // QT_NO_TOOLTIP
        actionScreenshot->setText(QApplication::translate("MainWindow", "Screenshot", 0));
        actionShowToolbar->setText(QApplication::translate("MainWindow", "Show Toolbar", 0));
        actionShowBrowser->setText(QApplication::translate("MainWindow", "Show Model Browser", 0));
        tabWidget->setTabText(tabWidget->indexOf(myTabModel), QApplication::translate("MainWindow", "Model Browser", 0));
        groupBox->setTitle(QApplication::translate("MainWindow", "Culling", 0));
        viewCullingCheckBox->setText(QApplication::translate("MainWindow", "Enable view culling", 0));
        sizeCullingCheckBox->setText(QApplication::translate("MainWindow", "Enable size culling", 0));
        myOsdCheck->setText(QApplication::translate("MainWindow", "Statistics OSD", 0));
        groupBox_2->setTitle(QApplication::translate("MainWindow", "Level of Detail", 0));
        label->setText(QApplication::translate("MainWindow", "Quality", 0));
        groupBox_3->setTitle(QApplication::translate("MainWindow", "Selection", 0));
        label_3->setText(QApplication::translate("MainWindow", "Button:", 0));
        toolButton_2->setText(QApplication::translate("MainWindow", "Left", 0));
        toolButton->setText(QApplication::translate("MainWindow", "Middle", 0));
        toolButton_3->setText(QApplication::translate("MainWindow", "Right", 0));
        label_9->setText(QApplication::translate("MainWindow", "Color:", 0));
        myColorLabel->setText(QString());
        myColorPickButton->setText(QApplication::translate("MainWindow", "...", 0));
        myCameraControlsBox->setTitle(QApplication::translate("MainWindow", "Camera controls", 0));
        myAnimateCheck->setText(QApplication::translate("MainWindow", "Animated camera transitions", 0));
        myAutoFitCheck->setText(QApplication::translate("MainWindow", "Automatic Fit-All", 0));
        label_4->setText(QApplication::translate("MainWindow", "Preset:", 0));
        myPresetComboBox->clear();
        myPresetComboBox->insertItems(0, QStringList()
         << QApplication::translate("MainWindow", "Default", 0)
         << QApplication::translate("MainWindow", "OCCT", 0)
        );
        label_6->setText(QApplication::translate("MainWindow", "Key to operate camera:", 0));
        label_2->setText(QApplication::translate("MainWindow", "Rotation:", 0));
        toolButton_6->setText(QApplication::translate("MainWindow", "Left", 0));
        toolButton_4->setText(QApplication::translate("MainWindow", "Middle", 0));
        toolButton_5->setText(QApplication::translate("MainWindow", "Right", 0));
        label_7->setText(QApplication::translate("MainWindow", "Panning:", 0));
        toolButton_7->setText(QApplication::translate("MainWindow", "Left", 0));
        toolButton_8->setText(QApplication::translate("MainWindow", "Middle", 0));
        toolButton_9->setText(QApplication::translate("MainWindow", "Right", 0));
        label_8->setText(QApplication::translate("MainWindow", "Zooming:", 0));
        toolButton_10->setText(QApplication::translate("MainWindow", "Left", 0));
        toolButton_11->setText(QApplication::translate("MainWindow", "Middle", 0));
        toolButton_12->setText(QApplication::translate("MainWindow", "Right", 0));
        myMenuWarningLabel->setText(QApplication::translate("MainWindow", "<html><head/><body><p align=\"center\">Right mouse button used. </p><p align=\"center\">Context menu of viewer will be disabled.</p></body></html>", 0));
        mySameButtonWarningLabel->setText(QApplication::translate("MainWindow", "<html><head/><body><p align=\"center\">Two or more actions are assigned</p><p align=\"center\"> to the same button. </p><p align=\"center\">Please, correct the settings.</p></body></html>", 0));
        myZoomWithWheelCheck->setText(QApplication::translate("MainWindow", "Zoom with mouse wheel", 0));
        tabWidget->setTabText(tabWidget->indexOf(myTabOptions), QApplication::translate("MainWindow", "Settings", 0));
        menuFile->setTitle(QApplication::translate("MainWindow", "File", 0));
        menuHelp->setTitle(QApplication::translate("MainWindow", "Help", 0));
        menuView->setTitle(QApplication::translate("MainWindow", "View", 0));
        menuNavigation->setTitle(QApplication::translate("MainWindow", "Navigation", 0));
        menuStandard_Views->setTitle(QApplication::translate("MainWindow", "Standard View", 0));
        menuSelection->setTitle(QApplication::translate("MainWindow", "Selection", 0));
        menuWindow->setTitle(QApplication::translate("MainWindow", "Window", 0));
        myToolBar->setWindowTitle(QApplication::translate("MainWindow", "Main toolbar", 0));
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
