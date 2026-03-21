/****************************************************************************
** Meta object code from reading C++ file 'JTVis_Scene.hxx'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.7.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../WViewer/JTAssistant/src/JTVis/JTVis_Scene.hxx"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'JTVis_Scene.hxx' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.7.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
struct qt_meta_stringdata_JTVis_Scene_t {
    QByteArrayData data[11];
    char stringdata0[150];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    qptrdiff(offsetof(qt_meta_stringdata_JTVis_Scene_t, stringdata0) + ofs \
        - idx * sizeof(QByteArrayData)) \
    )
static const qt_meta_stringdata_JTVis_Scene_t qt_meta_stringdata_JTVis_Scene = {
    {
QT_MOC_LITERAL(0, 0, 11), // "JTVis_Scene"
QT_MOC_LITERAL(1, 12, 17), // "RequestViewUpdate"
QT_MOC_LITERAL(2, 30, 0), // ""
QT_MOC_LITERAL(3, 31, 20), // "RequestAnimationMode"
QT_MOC_LITERAL(4, 52, 9), // "isEnabled"
QT_MOC_LITERAL(5, 62, 21), // "RequestClearSelection"
QT_MOC_LITERAL(6, 84, 16), // "RequestSelection"
QT_MOC_LITERAL(7, 101, 12), // "JTData_Node*"
QT_MOC_LITERAL(8, 114, 7), // "theNode"
QT_MOC_LITERAL(9, 122, 15), // "LoadingComplete"
QT_MOC_LITERAL(10, 138, 11) // "ForceUpdate"

    },
    "JTVis_Scene\0RequestViewUpdate\0\0"
    "RequestAnimationMode\0isEnabled\0"
    "RequestClearSelection\0RequestSelection\0"
    "JTData_Node*\0theNode\0LoadingComplete\0"
    "ForceUpdate"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_JTVis_Scene[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       6,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       5,       // signalCount

 // signals: name, argc, parameters, tag, flags
       1,    0,   44,    2, 0x06 /* Public */,
       3,    1,   45,    2, 0x06 /* Public */,
       5,    0,   48,    2, 0x06 /* Public */,
       6,    1,   49,    2, 0x06 /* Public */,
       9,    0,   52,    2, 0x06 /* Public */,

 // slots: name, argc, parameters, tag, flags
      10,    0,   53,    2, 0x0a /* Public */,

 // signals: parameters
    QMetaType::Void,
    QMetaType::Void, QMetaType::Bool,    4,
    QMetaType::Void,
    QMetaType::Void, 0x80000000 | 7,    8,
    QMetaType::Void,

 // slots: parameters
    QMetaType::Void,

       0        // eod
};

void JTVis_Scene::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        JTVis_Scene *_t = static_cast<JTVis_Scene *>(_o);
        Q_UNUSED(_t)
        switch (_id) {
        case 0: _t->RequestViewUpdate(); break;
        case 1: _t->RequestAnimationMode((*reinterpret_cast< bool(*)>(_a[1]))); break;
        case 2: _t->RequestClearSelection(); break;
        case 3: _t->RequestSelection((*reinterpret_cast< JTData_Node*(*)>(_a[1]))); break;
        case 4: _t->LoadingComplete(); break;
        case 5: _t->ForceUpdate(); break;
        default: ;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        void **func = reinterpret_cast<void **>(_a[1]);
        {
            typedef void (JTVis_Scene::*_t)();
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&JTVis_Scene::RequestViewUpdate)) {
                *result = 0;
                return;
            }
        }
        {
            typedef void (JTVis_Scene::*_t)(bool );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&JTVis_Scene::RequestAnimationMode)) {
                *result = 1;
                return;
            }
        }
        {
            typedef void (JTVis_Scene::*_t)();
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&JTVis_Scene::RequestClearSelection)) {
                *result = 2;
                return;
            }
        }
        {
            typedef void (JTVis_Scene::*_t)(JTData_Node * );
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&JTVis_Scene::RequestSelection)) {
                *result = 3;
                return;
            }
        }
        {
            typedef void (JTVis_Scene::*_t)();
            if (*reinterpret_cast<_t *>(func) == static_cast<_t>(&JTVis_Scene::LoadingComplete)) {
                *result = 4;
                return;
            }
        }
    }
}

const QMetaObject JTVis_Scene::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_JTVis_Scene.data,
      qt_meta_data_JTVis_Scene,  qt_static_metacall, Q_NULLPTR, Q_NULLPTR}
};


const QMetaObject *JTVis_Scene::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *JTVis_Scene::qt_metacast(const char *_clname)
{
    if (!_clname) return Q_NULLPTR;
    if (!strcmp(_clname, qt_meta_stringdata_JTVis_Scene.stringdata0))
        return static_cast<void*>(const_cast< JTVis_Scene*>(this));
    if (!strcmp(_clname, "OpenGLFunctions"))
        return static_cast< OpenGLFunctions*>(const_cast< JTVis_Scene*>(this));
    return QObject::qt_metacast(_clname);
}

int JTVis_Scene::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 6)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 6;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 6)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 6;
    }
    return _id;
}

// SIGNAL 0
void JTVis_Scene::RequestViewUpdate()
{
    QMetaObject::activate(this, &staticMetaObject, 0, Q_NULLPTR);
}

// SIGNAL 1
void JTVis_Scene::RequestAnimationMode(bool _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void JTVis_Scene::RequestClearSelection()
{
    QMetaObject::activate(this, &staticMetaObject, 2, Q_NULLPTR);
}

// SIGNAL 3
void JTVis_Scene::RequestSelection(JTData_Node * _t1)
{
    void *_a[] = { Q_NULLPTR, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void JTVis_Scene::LoadingComplete()
{
    QMetaObject::activate(this, &staticMetaObject, 4, Q_NULLPTR);
}
QT_END_MOC_NAMESPACE
