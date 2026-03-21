#include "JTData_JSON.hxx"
#include "JTData_Combination.hxx"
#include "qdebug.h"

using namespace Eigen;

QMap<QString, JTData_Item*> JTData_JSON::myItems;

Label_Color JTData_JSON::myItemLabel[MAX_LABEL] = {
  { 36, 28, 237, 0 },		// 0
  { 29, 230, 168, 0 },	// 1
  { 84, 79, 33, 0 },		// 2
  { 76, 177, 34, 0 },		// 3
  { 84, 33, 33, 0 },		// 4
  { 239, 183, 0, 0 },		// 5
  { 222, 255, 104, 0 },	// 6
  { 243, 109, 77, 0 },	// 7
  { 33, 84, 79, 0 },		// 8
  { 0, 242, 255, 0 },		// 9
  { 42, 33, 84, 0 },		// 10
  { 14, 194, 255, 0 },	// 11
  { 193, 94, 255, 0 },	// 12
  { 0, 126, 255, 0 },		// 13
  { 189, 249, 255, 0 },	// 14
  { 188, 249, 211, 0 },	// 15
  { 213, 165, 181, 0 },	// 16
  { 153, 54, 47, 0 },		// 17
  { 79, 33, 84, 0 },		// 18
  { 177, 163, 255, 0 },	// 19
  { 142, 255, 86, 0 },	// 20
  { 156, 228, 245, 0 },	// 21
  { 97, 187, 157, 0 },	// 22
  { 152, 49, 111, 0 },	// 23
  { 84, 33, 69, 0 },		// 24
  { 60, 90, 156, 0 },		// 25
  { 146, 122, 255, 0 },	// 26
  { 192, 192, 192, 0 }	// 27 Default Done Color
};

static int uniqueID = 0;
static int maxCombination = 0;

//=======================================================================
// function : LoadTagStatusFile
// purpose  : A JT model file may have an extra .json file that describes
//			  status of each part uniquely identified by a TAG ID.
//			  The file contains th JOBLIST which is a list of items which cotains
//		      TAG, Work status {Work, Done}
//			{ "JOBLIST : [ 
//			  {
//				  "TAG" : "...",
//				  "STATUS" : "Work | Done"
//			  }
//			  ...
//          }
//
// for example...				
// {
// 	 "JOBLIST":[
// 	 {
//		"TAG" : "BG402F                                  00013885-0000-0000-2700-0F77E7568D07",
// 	 	"STATUS": "Work",  	
// 	  }  
// }
//=======================================================================
void JTData_JSON::LoadTagFile(const QString& fileName)
{
  if (fileName.isEmpty()) return;

  QString strReadAll;
  QFile file;

  file.setFileName(fileName);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
  strReadAll = file.readAll();
  file.close();

  QJsonDocument doc = QJsonDocument::fromJson(strReadAll.toUtf8());
  if (doc.isEmpty()) return;
  QJsonObject jsonObj = doc.object();
  QJsonArray jsonArray = jsonObj["JOBLIST"].toArray();
  if (jsonArray.isEmpty()) return;

  ClearData();

  foreach(const QJsonValue & value, jsonArray)
  {
    QJsonObject job   = value.toObject();
    QJsonValue tag    = job["TAG"];
    QString strTag    = CreateShortName(tag.toString());
    QJsonValue status = job["STATUS"];
    QString strStatus = status.toString();		

    JTData_Item *item = new JTData_Item();

    if (strStatus.compare("Done") == 0)
    {
      item->id	   = 27;			  // Asssign 0 for Done work
      item->status   = WORK_DONE;
#if 0
      item->color[0] = static_cast<float>(myItemLabel[item->id].r) / 255.0f;
      item->color[1] = static_cast<float>(myItemLabel[item->id].g) / 255.0f;
      item->color[2] = static_cast<float>(myItemLabel[item->id].b) / 255.0f;
#else
      item->color[0] = static_cast<float>(192) / 255.0f;
      item->color[1] = static_cast<float>(192) / 255.0f;
      item->color[2] = static_cast<float>(192) / 255.0f;
#endif
    }
    else if (strStatus.compare("Work") == 0)
    {
      item->id	   = uniqueID++;  // Assign unique ID for work items
      item->status   = NEED_WORK;
      if (item->id >= MAX_LABEL)
      {
        qFatal("Exceeded the maximum number of labels");			
        item->color[0] = 1.0f;
        item->color[1] = 1.0f;
        item->color[2] = 0.0f;
      }
      else
      {
        item->color[0] = static_cast<float>(myItemLabel[item->id].r) / 255.0f;
        item->color[1] = static_cast<float>(myItemLabel[item->id].g) / 255.0f;
        item->color[2] = static_cast<float>(myItemLabel[item->id].b) / 255.0f;
      }
    }

    myItems.insert(strTag, item);

#if 0
	if (uniqueID >= MAX_LABEL)
	{
		break;
	}
#endif
  }

  maxCombination = (int)pow(2, uniqueID);
}

void JTData_JSON::SaveTagFile(const QString& fileName, const QVector<QString>& tagArray)
{
  if (tagArray.isEmpty())
  {
    qWarning("Tag array empty");
    return;
  }

  if (fileName.isEmpty())
  {
    qWarning("Filename empty");
    return;
  }

  QFile saveFile(fileName);
  if (!saveFile.open(QIODevice::WriteOnly)){
    qWarning("Couldn't open save file.");
    return;
  }

  QJsonObject jsonJob;
  QJsonArray jobList;
  foreach(const QString tag, tagArray) {
    QJsonObject jobObject;
    jobObject["TAG"] = tag;
    jobObject["STATUS"] = QString("Done");

    jobList.append(jobObject);
  }

  jsonJob["JOBLIST"] = jobList;
  QJsonDocument saveDoc(jsonJob);

  saveFile.write(saveDoc.toJson());
  saveFile.close();
}


void JTData_JSON::LoadCamFile(const QString& fileName, const JTVis_TargetedCameraPtr camera)
{
  QFile camFile(fileName);
  if (!camFile.open(QIODevice::ReadOnly)){
   qWarning("Couldn't open save file.");
    return;
  }
  float fBuffer[20] = { 0.0f };
  camFile.read((char*)fBuffer, sizeof(float)*20);
  camFile.close();

  int idx = 0;

  camera->SetFieldOfView(fBuffer[idx++]);
  camera->SetScale(fBuffer[idx++]); 
  camera->SetAspectRatio(fBuffer[idx++]);
  camera->SetDistance(fBuffer[idx++]);
  camera->SetZNear(fBuffer[idx++]);
  camera->SetZFar(fBuffer[idx++]);

  camera->SetTarget(Vector3f(fBuffer[idx], fBuffer[idx+1], fBuffer[idx+2]));
  idx += 3;
  camera->SetRotation(AngleAxisf(fBuffer[idx], Vector3f(fBuffer[idx+1], fBuffer[idx+2], fBuffer[idx+3])));
  idx += 4;
  if (fBuffer[idx] == 1.0f)
    camera->SetCameraMode(cmOrthographic);
  else
    camera->SetCameraMode(cmPerspective);

    /* Test...
  AngleAxisf myRotation = AngleAxisf::Identity();
  Affine3f aRotation = Affine3f::Identity();
  aRotation = myRotation.matrix();
  float angleAroundX = 15.0f / 180.0f * static_cast<float> (M_PI);	
  float angleAroundY = 0; // 15.0f / 180.0f * static_cast<float>(M_PI);

  myRotation = AngleAxisf(angleAroundX, Vector3f::UnitX()) *
    AngleAxisf(angleAroundY, Vector3f::UnitY()) *
    myRotation;

  myRotation = camera->Rotation() * myRotation;
  camera->SetRotation(myRotation);
    */
}

void JTData_JSON::SaveCamFile(const QString& fileName, const JTVis_TargetedCameraPtr camera, bool debug)
{
  QFile camFile(fileName);
  if (!camFile.open(QIODevice::WriteOnly)){
    qWarning("Couldn't open save file.");
    return;
  }

  float fBuffer[20] = { 0.0f };
  int idx = 0;

  // 13 float elements... a little hacky
  fBuffer[idx++] = camera->FieldOfView();
  fBuffer[idx++] = camera->Scale();
  fBuffer[idx++] = camera->AspectRatio();
  fBuffer[idx++] = camera->Distance();
  fBuffer[idx++] = camera->ZNear();
  fBuffer[idx++] = camera->ZFar();
  fBuffer[idx++] = camera->Target()[0];
  fBuffer[idx++] = camera->Target()[1];
  fBuffer[idx++] = camera->Target()[2];
  fBuffer[idx++] = camera->Rotation().angle();
  fBuffer[idx++] = camera->Rotation().axis()[0];
  fBuffer[idx++] = camera->Rotation().axis()[1];
  fBuffer[idx++] = camera->Rotation().axis()[2];
  fBuffer[idx++] = static_cast<float>(camera->IsOrthographic());

  camFile.write((char*)fBuffer, sizeof(float)*idx);
  camFile.close();

  if (debug)
  {
    QString fname = fileName;
    fname.append(".debug");
    QFile saveFile(fname);
    if (!saveFile.open(QIODevice::WriteOnly)){
      qWarning("Couldn't open save file.");
      return;
    }

    char cam_str[256] = { 0 };
    Matrix4f mvpMatrix;
    mvpMatrix = camera->ProjectionMatrix() * camera->ViewMatrix(); //  ProjectionMatrix()  * camera->ViewMatrix();

    QJsonObject jsonCam;
    sprintf_s(cam_str, "%.10f", camera->Scale());
    jsonCam["Scale"] = QString(cam_str);
    sprintf_s(cam_str, "%.10f", camera->AspectRatio());
    jsonCam["AspectRatio"] = QString(cam_str);
    sprintf_s(cam_str, "%.10f", camera->Distance());
    jsonCam["Distance"] = QString(cam_str);
    sprintf_s(cam_str, "%.10f", camera->FieldOfView());
    jsonCam["FieldofView"] = QString(cam_str);
    sprintf_s(cam_str, "%.10f", camera->ZNear());
    jsonCam["ZNear"] = QString(cam_str);
    sprintf_s(cam_str, "%.10f", camera->ZFar());
    jsonCam["ZFar"] = QString(cam_str);

    sprintf_s(cam_str, "%.6e, %.6e, %.6e", camera->Target()[0], camera->Target()[1], camera->Target()[2]);
    jsonCam["Target"] = QString(cam_str);

    sprintf_s(cam_str, "%.6e, %.6e, %.6e, %.6e", camera->Rotation().angle(),
    camera->Rotation().axis()[0],
    camera->Rotation().axis()[1],
    camera->Rotation().axis()[2]);
    jsonCam["Rotation"] = QString(cam_str);

    sprintf_s(cam_str, "%.0f", camera->IsOrthographic());
    jsonCam["Orthographic"] = QString(cam_str);

    sprintf_s(cam_str, "%.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e, %.6e",
    mvpMatrix.data()[0], mvpMatrix.data()[1], mvpMatrix.data()[2], mvpMatrix.data()[3],
    mvpMatrix.data()[4], mvpMatrix.data()[5], mvpMatrix.data()[6], mvpMatrix.data()[7],
    mvpMatrix.data()[8], mvpMatrix.data()[9], mvpMatrix.data()[10], mvpMatrix.data()[11],
    mvpMatrix.data()[12], mvpMatrix.data()[13], mvpMatrix.data()[14], mvpMatrix.data()[15]);
    jsonCam["MVP"] = QString(cam_str);

    QJsonDocument saveDoc(jsonCam);
    saveFile.write(saveDoc.toJson());
    saveFile.close();
  }
}

void JTData_JSON::ClearData()
{
  if (myItems.isEmpty()) return;

  foreach(JTData_Item* item, myItems)
  {
    delete item;
  }
  myItems.clear();
  uniqueID = 0;
}

bool JTData_JSON::IsEmpty()
{
  return myItems.isEmpty();
}

const JTData_Item* JTData_JSON::GetTagData(const QString& strTag)
{
  QString shortTag = CreateShortName(strTag);
  JTData_Item *item = myItems.value(shortTag);
  return item;
}

const JTData_Item* JTData_JSON::GetTagData(const QString& strTag, int iterNum)
{
	QString shortTag = CreateShortName(strTag);
	JTData_Item *item = myItems.value(shortTag);

    if (item->status == NEED_WORK)
    {
        if (item->id < MAX_ITEMS)
        {
            if (ComboTable[iterNum][item->id])
                item->renderFlag = true;
            else
                item->renderFlag = false;
        }
        else
        {
            qWarning("Exceeded the number of items regarding number of interations.");
        }
    }
    else
        item->renderFlag = true;
    return item;
}



Tag_Status JTData_JSON::TagStatus(const QString& strTag)
{ 
  QString shortTag = CreateShortName(strTag);
  JTData_Item *item = myItems.value(shortTag);
  if (item)
    return item->status;
  else
    return NO_TAG_DATA;
}

void JTData_JSON::ReadItemInfo(JTData_Item* item, QJsonObject job)
{
  // Item Info
  QJsonValue a3 = job["A3"];
  item->a3Date = a3.toString();

  QJsonValue supply = job["SUPPLY"];
  item->supply = supply.toInt();

  QJsonValue bomConfirm = job["BOM_CONFIRM"];
  item->bomConfirmDate = bomConfirm.toString();

  QJsonValue blueprintFix = job["BLUEPRINT_FIX"];
  item->blueprintFixDate = blueprintFix.toString();

  QJsonValue workerPerHourObject = job["WORKER_PER_HOUR"];
  item->workerPerHour = workerPerHourObject.toInt();

  QJsonValue defaultWorkerPerHourObject = job["DEFAULT_WORKER_PER_HOUR"];
  item->defaultWorkerPerHour = defaultWorkerPerHourObject.toInt();

  QJsonValue constructionStatus = job["CONSTRUCTION_STATUS"];
  item->constructionStatus = constructionStatus.toString();
}

QString JTData_JSON::CreateShortName(QString name)
{ 
  if (LONG_TAG_LENGTH != name.length())
    return name;

  QString shortName;
  shortName = name.left(name.length() - MIN_TAG_LENGTH);

  int blankCount = 0;
  for (int i = shortName.length() - 1; i >= 0; i--)
  {
    if (shortName.at(i) == ' ')
      blankCount++;
    else
      break;
  }

  shortName = shortName.left(shortName.length() - blankCount);

  return shortName;
}


int JTData_JSON::GetNumCombination()
{
    return maxCombination;
}