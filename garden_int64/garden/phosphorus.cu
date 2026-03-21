#include "phosphorus.cuh"

bool phosphorus::writeNutrients(fig_nutrient* nutrient_, int cnt, int idx)
{
	// cnt : 클래스 인덱스 갯수
	// idx : 파일 번호
	FILE *dst;
	errno_t err;

	std::string sfilename = "./data/fig_nutrient/nutrients_";
	sfilename += std::to_string(idx);
	sfilename += ".dat";

	const char *filename = sfilename.c_str();

	err = fopen_s(&dst, filename, "wb");
	if (err != 0)
	{
		std::cerr << "Error: writeNutrients() file open " << std::endl;
		return false;
	}

	err = fwrite(nutrient_, sizeof(fig_nutrient), cnt, dst);
	if (err != cnt)
	{
		std::cerr << "Error: writeNutrients() file write" << std::endl;
		return false;
	}
	fclose(dst);

	return true;
}

bool phosphorus::readNutrients(char* path, fig_nutrient** nutrient_, int *count)
{
	FILE *fp = NULL; 
	fopen_s(&fp, path, "rb");
	
	if (NULL == fp)
	{
		std::cerr << "Error: open nutrient file" << std::endl;
		return false;
	}

	long len; // len = file size (bytes)
	fseek(fp, 0L, SEEK_END);
	len = ftell(fp);

	fseek(fp, 0L, SEEK_SET);

	//long nlen = sizeof(fig_nutrient);

	int fig_count = (int)(len / (long)sizeof(fig_nutrient)); // 클래스 배열 갯수
	*count = fig_count;

	//free(*nutrient_);
	*nutrient_ = (fig_nutrient*)malloc(fig_count * sizeof(fig_nutrient));


	int count_ = fread((*nutrient_), sizeof(fig_nutrient), fig_count, fp);

	if (count_ != fig_count)
	{
		std::cout << "Error: read nutrients file" << std::endl;
		return false;
	}
	
	fclose(fp);

	return true;
}