#ifndef JTData_JSON_HeaderFile
#define JTData_JSON_HeaderFile


#pragma warning (push, 0)
#include <Eigen/Core>
#include <Eigen/Geometry>

#include <QFile>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QMap>
#include <QVector>
#pragma warning (pop)


#include <JTVis_TargetedCamera.hxx>

#define MAX_LABEL 28

enum Tag_Status
{
  NO_TAG_DATA,
  WORK_DONE,
  NEED_WORK
};

struct Label_Color
{
  unsigned char b;
  unsigned char g;
  unsigned char r;
  unsigned char a;
};

const QString STR_ON_DECK("OnDeck");
const QString STR_IN_POSITION("InPosition");
const QString STR_FIT_UP("Fit-Up");
const QString STR_INSTALL("Install");
const QString STR_INSPECTION("Inspection");

const QString STR_A3_CONFIRM_DATE = QString::fromLocal8Bit("A3 확정 : ");
const QString STR_SUPPLY_ARRIVE_RATE = QString::fromLocal8Bit("자재확보율 : ");
const QString STR_BOM_CONFIRM_DATE = QString::fromLocal8Bit("BOM 확정 : ");
const QString STR_BLUEPRINT_FIX_DATE = QString::fromLocal8Bit("도면출도 : ");
const QString STR_WORKER_PER_HOUR = QString::fromLocal8Bit("작업계량 : ");
const QString STR_DEFAULT_WORKER_PER_HOUR = QString::fromLocal8Bit("기준공수	: ");
const QString STR_CONSTRUCTION_STATUS = QString::fromLocal8Bit("설치현황 : ");
const QString STR_LINE_FEED = QString::fromLocal8Bit("\n");
const QString STR_PERCENT = QString::fromLocal8Bit("%");
const QString STR_MAN_HOUR = QString::fromLocal8Bit("M/H");

const int LONG_TAG_LENGTH = 76;
const int MIN_TAG_LENGTH = 36; // Min Length "00013885-0000-0000-2700-0F77E7568D07"

class JTData_Item
{
public:
  JTData_Item() : id(-2), status(NO_TAG_DATA) { }
  int id;
  Tag_Status status;
  float color[3];
  bool renderFlag;

  QString a3Date;
  int supply;
  QString bomConfirmDate;
  QString blueprintFixDate;
  int workerPerHour;
  int defaultWorkerPerHour;
  QString constructionStatus;
};

class JTData_JSON
{
public:
  //! Initialize CheckTagList
  static void LoadTagFile(const QString& fileName);
  static void SaveTagFile(const QString& fileName, const QVector<QString>& tagArray);
  static void LoadCamFile(const QString& fileName, const JTVis_TargetedCameraPtr camera);
  static void SaveCamFile(const QString& fileName, const JTVis_TargetedCameraPtr camera, bool debug);

  static bool IsEmpty();
  static void ClearData();

  static const JTData_Item* GetTagData(const QString& strTag);
  static const JTData_Item* GetTagData(const QString& strTag, int iterNum);
  static Tag_Status TagStatus(const QString& strTag);

  static QString CreateShortName(QString name);

  static int GetNumCombination();
  
private:
  JTData_JSON() { }

  static void ReadItemInfo(JTData_Item* item, QJsonObject job);

  static QMap<QString, JTData_Item *> myItems;
  static Label_Color					myItemLabel[MAX_LABEL];
};

#endif // JTData_JSON_HeaderFile