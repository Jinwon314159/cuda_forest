/****************************************************************************
** Meta object code from reading C++ file 'JTGui_MainWindow.hxx'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.7.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../WViewer/JTAssistant/src/JTGui/JTGui_MainWindow.hxx"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'JTGui_MainWindow.hxx' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.7.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
struct qt_meta_stringdata_JTGui_TreeWidget_t {
    QByteArrayData data[5];
    char stringdata0[49];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_JTGui_TreeWidget_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_JTGui_TreeWidget_t qt_meta_stringdata_JTGui_TreeWidget = {
    {
QT_MOC_LITERAL(0, 0, 16), // "JTGui_TreeWidget"
QT_MOC_LITERAL(1, 17, 10), // "keyPressed"
QT_MOC_LITERAL(2, 28, 0), // ""
QT_MOC_LITERAL(3, 29, 10), // "QKeyEvent*"
QT_MOC_LITERAL(4, 40, 8) // "theEvent"

    },
    "JTGui_TreeWidget\0keyPressed\0\0QKeyEvent*\0"
    "theEvent"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_JTGui_TreeWidget[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    1,   19,    2, 0x06 /* Public */,

 // signals: parameters
    QMetaType::Void, 0x80000000 | 3,    4,

       0        // eod
};

void JTGui_TreeWidget::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        JTGui_TreeWidget *_t = static_cast<JTGui_TreeWidget *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->keyPressed((*reinterpret_cast< QKeyEvent*(*)>(_a[1]))); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        void **func = reinterpret_cast<void **>(_a[1]);
        {
            typedef void (JTGui_TreeWidget::*_t)(QKeyEvent * );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&JTGui_TreeWidget::keyPressed)) {
                *result = 0;
                return;
            }
        }
    }
}

const QMetaObject JTGui_TreeWidget::staticMetaObject = {
    { &QTreeWidget::staticMetaObject, qt_meta_stringdata_JTGui_TreeWidget.data,
      qt_meta_data_JTGui_TreeWidget,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *JTGui_TreeWidget::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *JTGui_TreeWidget::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_JTGui_TreeWidget.stringdata0))
        return static_cast<void*>(const_cast< JTGui_TreeWidget*>(this));
    return QTreeWidget::qt_metacast(_clname);
}

int JTGui_TreeWidget::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QTreeWidget::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 1)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 1)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 1;
    }
    return _id;
}

// SIGNAL 0
void JTGui_TreeWidget::keyPressed(QKeyEvent * _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}
struct qt_meta_stringdata_JTGui_KeyBindEdit_t {
    QByteArrayData data[1];
    char stringdata0[18];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_JTGui_KeyBindEdit_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_JTGui_KeyBindEdit_t qt_meta_stringdata_JTGui_KeyBindEdit = {
    {
QT_MOC_LITERAL(0, 0, 17) // "JTGui_KeyBindEdit"

    },
    "JTGui_KeyBindEdit"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_JTGui_KeyBindEdit[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       0,    0, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

       0        // eod
};

void JTGui_KeyBindEdit::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    Q_UNUSED(_o);
    Q_UNUSED(_id);
    Q_UNUSED(_c);
    Q_UNUSED(_a);
}

const QMetaObject JTGui_KeyBindEdit::staticMetaObject = {
    { &QLineEdit::staticMetaObject, qt_meta_stringdata_JTGui_KeyBindEdit.data,
      qt_meta_data_JTGui_KeyBindEdit,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *JTGui_KeyBindEdit::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *JTGui_KeyBindEdit::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_JTGui_KeyBindEdit.stringdata0))
        return static_cast<void*>(const_cast< JTGui_KeyBindEdit*>(this));
    return QLineEdit::qt_metacast(_clname);
}

int JTGui_KeyBindEdit::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QLineEdit::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    return _id;
}
struct qt_meta_stringdata_JTGui_ClickableLabel_t {
    QByteArrayData data[3];
    char stringdata0[30];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_JTGui_ClickableLabel_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_JTGui_ClickableLabel_t qt_meta_stringdata_JTGui_ClickableLabel = {
    {
QT_MOC_LITERAL(0, 0, 20), // "JTGui_ClickableLabel"
QT_MOC_LITERAL(1, 21, 7), // "clicked"
QT_MOC_LITERAL(2, 29, 0) // ""

    },
    "JTGui_ClickableLabel\0clicked\0"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_JTGui_ClickableLabel[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    0,   19,    2, 0x06 /* Public */,

 // signals: parameters
    QMetaType::Void,

       0        // eod
};

void JTGui_ClickableLabel::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        JTGui_ClickableLabel *_t = static_cast<JTGui_ClickableLabel *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->clicked(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        void **func = reinterpret_cast<void **>(_a[1]);
        {
            typedef void (JTGui_ClickableLabel::*_t)();
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&JTGui_ClickableLabel::clicked)) {
                *result = 0;
                return;
            }
        }
    }
    Q_UNUSED(_a);
}

const QMetaObject JTGui_ClickableLabel::staticMetaObject = {
    { &QLabel::staticMetaObject, qt_meta_stringdata_JTGui_ClickableLabel.data,
      qt_meta_data_JTGui_ClickableLabel,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *JTGui_ClickableLabel::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *JTGui_ClickableLabel::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_JTGui_ClickableLabel.stringdata0))
        return static_cast<void*>(const_cast< JTGui_ClickableLabel*>(this));
    return QLabel::qt_metacast(_clname);
}

int JTGui_ClickableLabel::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QLabel::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 1)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 1)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 1;
    }
    return _id;
}

// SIGNAL 0
void JTGui_ClickableLabel::clicked()
{
    QMetaObject::activate(this, &staticMetaObject, 0, Q_NULLPTR);
}
struct qt_meta_stringdata_JTGui_MainWindow_t {
    QByteArrayData data[44];
    char stringdata0[527];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_JTGui_MainWindow_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_JTGui_MainWindow_t qt_meta_stringdata_JTGui_MainWindow = {
    {
QT_MOC_LITERAL(0, 0, 16), // "JTGui_MainWindow"
QT_MOC_LITERAL(1, 17, 10), // "selectNode"
QT_MOC_LITERAL(2, 28, 0), // ""
QT_MOC_LITERAL(3, 29, 12), // "JTData_Node*"
QT_MOC_LITERAL(4, 42, 7), // "theNode"
QT_MOC_LITERAL(5, 50, 14), // "clearSelection"
QT_MOC_LITERAL(6, 65, 9), // "closeFile"
QT_MOC_LITERAL(7, 75, 8), // "openFile"
QT_MOC_LITERAL(8, 84, 11), // "closeWindow"
QT_MOC_LITERAL(9, 96, 12), // "showGUIItems"
QT_MOC_LITERAL(10, 109, 6), // "fitAll"
QT_MOC_LITERAL(11, 116, 15), // "updateStatusBar"
QT_MOC_LITERAL(12, 132, 16), // "selectionChanged"
QT_MOC_LITERAL(13, 149, 11), // "collapseAll"
QT_MOC_LITERAL(14, 161, 8), // "hideItem"
QT_MOC_LITERAL(15, 170, 8), // "viewOnly"
QT_MOC_LITERAL(16, 179, 7), // "viewAll"
QT_MOC_LITERAL(17, 187, 9), // "viewReset"
QT_MOC_LITERAL(18, 197, 7), // "viewTop"
QT_MOC_LITERAL(19, 205, 10), // "viewBottom"
QT_MOC_LITERAL(20, 216, 8), // "viewLeft"
QT_MOC_LITERAL(21, 225, 9), // "viewRight"
QT_MOC_LITERAL(22, 235, 9), // "viewFront"
QT_MOC_LITERAL(23, 245, 8), // "viewBack"
QT_MOC_LITERAL(24, 254, 14), // "updateSettings"
QT_MOC_LITERAL(25, 269, 17), // "updateMouseLayout"
QT_MOC_LITERAL(26, 287, 15), // "perspectiveMode"
QT_MOC_LITERAL(27, 303, 9), // "isEnabled"
QT_MOC_LITERAL(28, 313, 12), // "choosePreset"
QT_MOC_LITERAL(29, 326, 14), // "makeScreenshot"
QT_MOC_LITERAL(30, 341, 11), // "forceRotate"
QT_MOC_LITERAL(31, 353, 9), // "forceMove"
QT_MOC_LITERAL(32, 363, 9), // "forceZoom"
QT_MOC_LITERAL(33, 373, 21), // "resetForcedOperations"
QT_MOC_LITERAL(34, 395, 9), // "showAbout"
QT_MOC_LITERAL(35, 405, 18), // "pickSelectionColor"
QT_MOC_LITERAL(36, 424, 12), // "checkCmdArgs"
QT_MOC_LITERAL(37, 437, 10), // "fileLoaded"
QT_MOC_LITERAL(38, 448, 19), // "showTreeContextMenu"
QT_MOC_LITERAL(39, 468, 8), // "thePoint"
QT_MOC_LITERAL(40, 477, 19), // "showViewContextMenu"
QT_MOC_LITERAL(41, 497, 5), // "bool&"
QT_MOC_LITERAL(42, 503, 9), // "isSucceed"
QT_MOC_LITERAL(43, 513, 13) // "saveSelection"

    },
    "JTGui_MainWindow\0selectNode\0\0JTData_Node*\0"
    "theNode\0clearSelection\0closeFile\0"
    "openFile\0closeWindow\0showGUIItems\0"
    "fitAll\0updateStatusBar\0selectionChanged\0"
    "collapseAll\0hideItem\0viewOnly\0viewAll\0"
    "viewReset\0viewTop\0viewBottom\0viewLeft\0"
    "viewRight\0viewFront\0viewBack\0"
    "updateSettings\0updateMouseLayout\0"
    "perspectiveMode\0isEnabled\0choosePreset\0"
    "makeScreenshot\0forceRotate\0forceMove\0"
    "forceZoom\0resetForcedOperations\0"
    "showAbout\0pickSelectionColor\0checkCmdArgs\0"
    "fileLoaded\0showTreeContextMenu\0thePoint\0"
    "showViewContextMenu\0bool&\0isSucceed\0"
    "saveSelection"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_JTGui_MainWindow[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
      36,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: name, argc, parameters, tag, flags
       1,    1,  194,    2, 0x0a /* Public */,
       5,    0,  197,    2, 0x0a /* Public */,
       6,    0,  198,    2, 0x08 /* Private */,
       7,    0,  199,    2, 0x08 /* Private */,
       8,    0,  200,    2, 0x08 /* Private */,
       9,    0,  201,    2, 0x08 /* Private */,
      10,    0,  202,    2, 0x08 /* Private */,
      11,    0,  203,    2, 0x08 /* Private */,
      12,    0,  204,    2, 0x08 /* Private */,
      13,    0,  205,    2, 0x08 /* Private */,
      14,    0,  206,    2, 0x08 /* Private */,
      15,    0,  207,    2, 0x08 /* Private */,
      16,    0,  208,    2, 0x08 /* Private */,
      17,    0,  209,    2, 0x08 /* Private */,
      18,    0,  210,    2, 0x08 /* Private */,
      19,    0,  211,    2, 0x08 /* Private */,
      20,    0,  212,    2, 0x08 /* Private */,
      21,    0,  213,    2, 0x08 /* Private */,
      22,    0,  214,    2, 0x08 /* Private */,
      23,    0,  215,    2, 0x08 /* Private */,
      24,    0,  216,    2, 0x08 /* Private */,
      25,    0,  217,    2, 0x08 /* Private */,
      26,    1,  218,    2, 0x08 /* Private */,
      28,    0,  221,    2, 0x08 /* Private */,
      29,    0,  222,    2, 0x08 /* Private */,
      30,    0,  223,    2, 0x08 /* Private */,
      31,    0,  224,    2, 0x08 /* Private */,
      32,    0,  225,    2, 0x08 /* Private */,
      33,    0,  226,    2, 0x08 /* Private */,
      34,    0,  227,    2, 0x08 /* Private */,
      35,    0,  228,    2, 0x08 /* Private */,
      36,    0,  229,    2, 0x08 /* Private */,
      37,    0,  230,    2, 0x08 /* Private */,
      38,    1,  231,    2, 0x08 /* Private */,
      40,    2,  234,    2, 0x08 /* Private */,
      43,    0,  239,    2, 0x08 /* Private */,

 // slots: parameters
    QMetaType::Void, 0x80000000 | 3,    4,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::Bool,   27,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void,
    QMetaType::Void, QMetaType::QPoint,   39,
    QMetaType::Void, QMetaType::QPoint, 0x80000000 | 41,   39,   42,
    QMetaType::Void,

       0        // eod
};

void JTGui_MainWindow::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        JTGui_MainWindow *_t = static_cast<JTGui_MainWindow *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->selectNode((*reinterpret_cast< JTData_Node*(*)>(_a[1]))); break;
        case 1: _t->clearSelection(); break;
        case 2: _t->closeFile(); break;
        case 3: _t->openFile(); break;
        case 4: _t->closeWindow(); break;
        case 5: _t->showGUIItems(); break;
        case 6: _t->fitAll(); break;
        case 7: _t->updateStatusBar(); break;
        case 8: _t->selectionChanged(); break;
        case 9: _t->collapseAll(); break;
        case 10: _t->hideItem(); break;
        case 11: _t->viewOnly(); break;
        case 12: _t->viewAll(); break;
        case 13: _t->viewReset(); break;
        case 14: _t->viewTop(); break;
        case 15: _t->viewBottom(); break;
        case 16: _t->viewLeft(); break;
        case 17: _t->viewRight(); break;
        case 18: _t->viewFront(); break;
        case 19: _t->viewBack(); break;
        case 20: _t->updateSettings(); break;
        case 21: _t->updateMouseLayout(); break;
        case 22: _t->perspectiveMode((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 23: _t->choosePreset(); break;
        case 24: _t->makeScreenshot(); break;
        case 25: _t->forceRotate(); break;
        case 26: _t->forceMove(); break;
        case 27: _t->forceZoom(); break;
        case 28: _t->resetForcedOperations(); break;
        case 29: _t->showAbout(); break;
        case 30: _t->pickSelectionColor(); break;
        case 31: _t->checkCmdArgs(); break;
        case 32: _t->fileLoaded(); break;
        case 33: _t->showTreeContextMenu((*reinterpret_cast< const QPoint(*)>(_a[1]))); break;
        case 34: _t->showViewContextMenu((*reinterpret_cast< const QPoint(*)>(_a[1])),(*reinterpret_cast< bool(*)>(_a[2]))); break;
        case 35: _t->saveSelection(); break;
        default: ;
        }
    }
}

const QMetaObject JTGui_MainWindow::staticMetaObject = {
    { &QMainWindow::staticMetaObject, qt_meta_stringdata_JTGui_MainWindow.data,
      qt_meta_data_JTGui_MainWindow,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *JTGui_MainWindow::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *JTGui_MainWindow::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_JTGui_MainWindow.stringdata0))
        return static_cast<void*>(const_cast< JTGui_MainWindow*>(this));
    return QMainWindow::qt_metacast(_clname);
}

int JTGui_MainWindow::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QMainWindow::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 36)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 36;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 36)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 36;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
