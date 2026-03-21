#pragma once

#include <stdio.h>
#include "global.cuh"

#define FILE 1 // 프레임 단위로 양쪽 어깨 확률의 평균을 저장하는 파일
#define P_FILE 1
#define COEFF 7 // coefficient 갯수

class inspector
{
public:
	void init(int size_);
	void set_value(fig_finest_fruit* finest_fruits, int count, int i_);
	void check_direction();
	void test(fig_finest_fruit* finest_fruits, int count, int i_);
	void clear();

private:
	int count; // 몇개의 식이 주어졌는지 갯수
	int coeff_count; // 독립변수 ( + 상수) 갯수
	double *coefficients; // 계수 배열
	int index;
	int is_zero_right = 0;
	int is_zero_left = 0;
	bool do_check = false;
	// pr : right shoulder의 확률 평균
	// pl : left shoulder의 확률 평균
	// vrx : right shoulder의 x 위치 분산
	// vry : right shoulder의 y 위치 분산
	// vlx : left shoulder의 x 위치 분산
	// vly : left shoulder의 y 위치 분산
	double *pr, *pl, *vrx, *vlx, *vry, *vly, *label_;
	double sum_all(double *x);
	void linear_regression();
	void linear_regression_();
	//file
	bool is_file = true;
	std::ofstream labelfile;
	std::ofstream pfile;
};


void inspector::init(int size_)
{
	this->count = size_;
	//this->coeff_count = 3;
	this->index = 0;
	this->is_zero_left = 0;
	this->is_zero_right = 0;
	// memory allocation
	this->pr = (double*)calloc(sizeof(double), size_);
	this->pl = (double*)calloc(sizeof(double), size_);
	this->vrx = (double*)calloc(sizeof(double), size_);
	this->vlx = (double*)calloc(sizeof(double), size_);
	this->vry = (double*)calloc(sizeof(double), size_);
	this->vly = (double*)calloc(sizeof(double), size_);
	this->label_ = (double*)calloc(sizeof(double), size_);
	this->coefficients = (double*)calloc(sizeof(double), COEFF);

#if FILE
	std::string lfilename = "shoulder.csv";
	labelfile.open(lfilename, std::ios::out | std::ios::app);
	if (!labelfile.is_open())
	{ 
		std::cout << "file open error!" << std::endl;
		is_file = false;
	}
	else
		labelfile << "label,pr,pl,vrx,vry,vlx,vly\n";
#endif

#if P_FILE
	std::string pfilename = "shoulder_position.csv";
	pfile.open(pfilename, std::ios::out | std::ios::app);
	if (!pfile.is_open())
	{
		std::cout << "position file open error!" << std::endl;
	}
	else
		pfile << "count,dir,x,y\n";
#endif

}

void inspector::clear()
{
	this->count = 0;
	this->coeff_count = 0;
	this->index = 0;

	free(this->pr);
	free(this->pl);
	free(this->vrx);
	free(this->vlx);
	free(this->vry);
	free(this->vly);
	free(this->label_);
	free(this->coefficients);

#if FILE
	if (is_file)
	{
		labelfile.close();
	}
#endif
#if P_FILE
	pfile.close();
#endif
}

void inspector::test(fig_finest_fruit* finest_fruits, int count, int i_)
{

}

void inspector::set_value(fig_finest_fruit* finest_fruits, int count, int i_)
{

	// 한 프레임때 마다 호출됨
	int shr_right_count = 0;
	double pro_right_sum = 0;
	double right_x_avg = 0;
	double right_y_avg = 0;
	double right_x_var = 0; // 분산
	double right_y_var = 0;
	double *right_index = (double*)malloc(sizeof(double) * count);

	int shr_left_count = 0;
	double pro_left_sum = 0;
	double left_x_avg = 0;
	double left_y_avg = 0;
	double left_x_var = 0; // 분산
	double left_y_var = 0;
	double *left_index = (double*)malloc(sizeof(double) * count);
	
	for (int i = 0; i < count; i++)
	{
		int x_ = finest_fruits[i].x;
		int y_ = finest_fruits[i].y;
		int label_ = finest_fruits[i].label;

		if (finest_fruits[i].label == 2)//&& finest_fruits[i].probability > 0.5)
		{
			// left shoulder
			pro_left_sum += finest_fruits[i].probability;
			left_x_avg += x_;
			left_y_avg += y_;
			left_index[shr_left_count] = i;
			shr_left_count++;
#if P_FILE
			pfile << shr_left_count <<"," << "left" << "," << x_ << "," << y_ << "\n";
#endif
		}
		else if (finest_fruits[i].label == 8)//&& finest_fruits[i].probability > 0.5)
		{
			// right shoulder
			pro_right_sum += finest_fruits[i].probability;
			right_x_avg += x_;
			right_y_avg += y_;
			right_index[shr_right_count] = i;
			shr_right_count++;
#if P_FILE
			pfile << shr_right_count << "," << "right" << "," << x_ << "," << y_ << "\n";
#endif
		}
	} //for

	// average
	if (shr_left_count == 0 && shr_right_count == 0)
	{
		this->is_zero_left++; 
		this->is_zero_right++;
		this->do_check = false;
	}
	else
	{
		// 현재 프레임의 각 어깨 확률의 평균을 저장한다.
		int idx = this->index;

		// left
		if (shr_left_count > 0)
		{
			pl[idx] = pro_left_sum / shr_left_count;
			left_x_avg /= shr_left_count;
			left_y_avg /= shr_left_count;
		}
		else
		{
			this->is_zero_left++;
			left_x_avg = 0;
			left_y_avg = 0;
			pl[idx] = 0;
		}

		// right
		if (shr_right_count > 0)
		{
			pr[idx] = pro_right_sum / shr_right_count;
			right_x_avg /= shr_right_count;
			right_y_avg /= shr_right_count;
		}
		else
		{
			this->is_zero_right++;
			right_x_avg = 0;
			right_y_avg = 0;
			pr[idx] = 0;
		}
		
		
		// labeling
		if (i_  <= 20)
			label_[idx] = 1;
		else
			label_[idx] = 0;

		// variance 구하기
		double diff_sum_left_x = 0;
		double diff_sum_left_y = 0;
		double diff_sum_right_x = 0;
		double diff_sum_right_y = 0;
		bool is_var = false;
		int var_index = (shr_left_count > shr_right_count) ? shr_left_count : shr_right_count;
		for (int j = 0; j < var_index; j++)
		{
			if (j < shr_left_count)//&& finest_fruits[i].probability > 0.5)
			{
				// left shoulder
				int l_idx = left_index[j];
				int x_ = finest_fruits[l_idx].x;
				int y_ = finest_fruits[l_idx].y;
				diff_sum_left_x += (x_ - left_x_avg) * (x_ - left_x_avg);
				diff_sum_left_y += (y_ - left_y_avg) * (y_ - left_y_avg);
				
				if (finest_fruits[l_idx].label == 2)
					is_var = true;
			}
			if (j < shr_right_count)//&& finest_fruits[i].probability > 0.5)
			{
				// right shoulder
				int r_idx = right_index[j];
				int x_ = finest_fruits[r_idx].x;
				int y_ = finest_fruits[r_idx].y;
				diff_sum_right_x += (x_ - right_x_avg) * (x_ - right_x_avg);
				diff_sum_right_y += (y_ - right_y_avg) * (y_ - right_y_avg);
				
				if (finest_fruits[r_idx].label == 8)
					is_var = true;
			}
		} // for
		if (is_var)
		{
			vrx[idx] = (shr_right_count == 0) ? 0 : diff_sum_right_x / shr_right_count;
			vry[idx] = (shr_right_count == 0) ? 0 : diff_sum_right_y / shr_right_count;
			vlx[idx] = (shr_left_count == 0) ? 0 : diff_sum_left_x / shr_left_count;
			vly[idx] = (shr_left_count == 0) ? 0 : diff_sum_left_y / shr_left_count;
		}
		else
		{
			vrx[idx] = 0;
			vry[idx] = 0;
			vlx[idx] = 0;
			vly[idx] = 0;
		}

		idx++;
		this->index = idx;
		this->do_check = true;
#if FILE
		if (is_file)
		{
			int idx_ = idx - 1;
			labelfile << label_[idx_] << "," << pr[idx_] << "," << pl[idx_] << "," << vrx[idx_] << "," << vry[idx_] << "," << vlx[idx_] << "," << vly[idx_] << "\n";
		}
#endif
	}
}

void inspector::check_direction()
{
	this->coeff_count = COEFF;
	this->linear_regression_();
}

double inspector::sum_all(double *x)
{
	int i;
	double sum = 0;
	for (i = 0; i < this->count; i++) {
		sum = sum + x[i];
	}
	return sum;
}

void inspector::linear_regression()
{
	// 현재 상수 + 2개의 독립변수
	if (!this->do_check)
		return;

	if (this->index != this->count)
		return;

	int num = this->count;
	int mnum = this->coeff_count;

	double sum_pr = 0, sum_pl = 0, sum_la = 0, sum_pr2 = 0, sum_pl2 = 0, sum_prpl = 0, sum_prla = 0, sum_plla = 0;

	/*  메모리 할당  */
	double *pr2 = new double[num];
	double *pl2 = new double[num];
	double *prpl = new double[num];
	double *prla = new double[num];
	double *plla = new double[num];
	double *m_b = new double[num];

	//2차원 행렬 
	double **m_a = new double*[mnum];
	for (int i = 0; i < mnum; i++)
		m_a[i] = new double[mnum];

	double **m_au = new double*[mnum];
	for (int i = 0; i < mnum; i++)
		m_au[i] = new double[mnum * 2];

	double **m_ai = new double*[mnum];
	for (int i = 0; i < mnum; i++)
		m_ai[i] = new double[mnum];

	// 0으로 초기화가 필요한 행렬
	double *coeff = (double*)calloc(mnum, sizeof(double)); // ABC
	// 단위행렬
	double **m_i = (double**)calloc(mnum, sizeof(double*));
	for (int i = 0; i < mnum; i++)
		m_i[i] = (double*)calloc(mnum, sizeof(double));


	for (int i = 0; i < num; i++)
	{
		pr2[i] = pr[i] * pr[i];
		pl2[i] = pl[i] * pl[i];
		prpl[i] = pr[i] * pl[i];
		prla[i] = pr[i] * label_[i];
		plla[i] = pl[i] * label_[i];
	}

	sum_pr = sum_all(pr);
	sum_pl = sum_all(pl);
	sum_la = sum_all(label_);
	sum_pr2 = sum_all(pr2);
	sum_pl2 = sum_all(pl2);
	sum_prpl = sum_all(prpl);
	sum_prla = sum_all(prla);
	sum_plla = sum_all(plla);

	// coefficient matrix : A
	m_a[0][0] = num;
	m_a[0][1] = sum_pr;
	m_a[0][2] = sum_pl;

	m_a[1][0] = sum_pr;
	m_a[1][1] = sum_pr2;
	m_a[1][2] = sum_prpl;

	m_a[2][0] = sum_pl;
	m_a[2][1] = sum_prpl;
	m_a[2][2] = sum_pl2;

	// 단위행렬
	m_i[0][0] = 1.0;
	m_i[1][1] = 1.0;
	m_i[2][2] = 1.0;

	for (int i = 0; i < mnum; i++)
	{
		for (int j = 0; j < mnum; j++)
		{
			m_au[i][j] = m_a[i][j];
			m_au[i][j + mnum] = m_i[i][j];
		}
	}

	// coefficient matrix : B
	m_b[0] = sum_la;
	m_b[1] = sum_prla;
	m_b[2] = sum_plla;

	double pivot = 0, d;

	for (int i = 0; i < mnum; i++)
	{
		pivot = m_au[i][i];
		for (int j = 0; j < (2 * mnum); j++){
			if (pivot == 0)
				m_au[i][j] = 0;
			else
				m_au[i][j] = m_au[i][j] / pivot;
		}
		for (int k = 0; k < mnum; k++){
			d = m_au[k][i];
			for (int j = 0; j < (2 * mnum); j++){
				if (k != i) {
					m_au[k][j] = m_au[k][j] + (-1)*(m_au[i][j] * d);
				}
			}
		}
	}

	for (int i = 0; i < mnum; i++){
		for (int j = 0; j < mnum; j++){
			m_ai[i][j] = m_au[i][j + mnum];
		}
	}

	for (int i = 0; i < mnum; i++){
		double sum = 0;
		for (int j = 0; j < mnum; j++){
			sum = sum + m_ai[i][j] * m_b[j];
		}
		coeff[i] = sum;
	}

	printf("result\n");
	printf("label = (%.4lf) + (%.4lf)pr + (%.4lf)pl \n", coeff[0], coeff[1], coeff[2]);

	this->coefficients[0] = coeff[0]; // 상수
	this->coefficients[1] = coeff[1]; // coefficient of right
	this->coefficients[2] = coeff[2]; // coefficient of left

	/*  메모리 해제  */
	delete pr2; delete pl2; delete prpl; delete prla;
	delete plla; delete m_b;

	for (int i = 0; i < mnum; i++)
	{
		delete[] m_a[i];
		delete[] m_au[i];
		delete[] m_ai[i];
		free(m_i[i]);
	}
	delete[]m_a;
	delete[]m_au;
	delete[]m_ai;

	free(coeff);
	free(m_i);
}

void inspector::linear_regression_()
{
	// 현재 상수 + 6개의 독립변수 = 7개
	// 주의! (16.06.27)
	// 지금 문제 점은 상수보다 식의 갯수가 작으면
	// exe 파일이 트리거를 중단했다는 에러가 나옴.ㅠㅠ 
	if (!this->do_check)
		return;

	if (this->index != this->count)
		return;

	int num = this->count;
	int mnum = this->coeff_count;

	// AtA
	double sum_pr = 0, sum_pl = 0, sum_vrx = 0, sum_vry = 0, sum_vlx = 0, sum_vly = 0;
	double sum_pr2 = 0, sum_pl2 = 0, sum_vrx2 = 0, sum_vry2 = 0, sum_vlx2 = 0, sum_vly2 = 0;
	double sum_prpl = 0, sum_prvrx = 0, sum_prvry = 0, sum_prvlx = 0, sum_prvly = 0;
	double sum_plvrx = 0, sum_plvry = 0, sum_plvlx = 0, sum_plvly = 0;
	double sum_vrx_vry = 0, sum_vrx_vlx = 0, sum_vrx_vly = 0;
	double sum_vry_vlx = 0, sum_vry_vly = 0;
	double sum_vlx_vly = 0;

	// AtZ
	double sum_la = 0, sum_prla = 0, sum_plla = 0, sum_vrxla = 0, sum_vryla = 0, sum_vlxla = 0, sum_vlyla = 0;

	/*  메모리 할당  */
	double *pr2 = new double[num];
	double *pl2 = new double[num];
	double *vrx2 = new double[num];
	double *vry2 = new double[num];
	double *vlx2 = new double[num];
	double *vly2 = new double[num];

	double *prpl = new double[num];
	double *prvrx = new double[num];
	double *prvry = new double[num];
	double *prvlx = new double[num];
	double *prvly = new double[num];
	double *plvrx = new double[num];
	double *plvry = new double[num];
	double *plvlx = new double[num];
	double *plvly = new double[num];

	double *vrx_vry = new double[num];
	double *vrx_vlx = new double[num];
	double *vrx_vly = new double[num];
	double *vry_vlx = new double[num];
	double *vry_vly = new double[num];
	double *vlx_vly = new double[num];

	double *prla = new double[num];
	double *plla = new double[num];
	double *vrxla = new double[num];
	double *vryla = new double[num];
	double *vlxla = new double[num];
	double *vlyla = new double[num];

	double *m_b = new double[num];

	//2차원 행렬 
	double **m_a = new double*[mnum];
	for (int i = 0; i < mnum; i++)
		m_a[i] = new double[mnum];

	double **m_au = new double*[mnum];
	for (int i = 0; i < mnum; i++)
		m_au[i] = new double[mnum * 2];

	double **m_ai = new double*[mnum];
	for (int i = 0; i < mnum; i++)
		m_ai[i] = new double[mnum];

	// 0으로 초기화가 필요한 행렬
	double *coeff = (double*)calloc(mnum, sizeof(double)); // ABC
	// 단위행렬
	double **m_i = (double**)calloc(mnum, sizeof(double*));
	for (int i = 0; i < mnum; i++)
		m_i[i] = (double*)calloc(mnum, sizeof(double));


	for (int i = 0; i < num; i++)
	{
		pr2[i] = pr[i] * pr[i];
		pl2[i] = pl[i] * pl[i];
		vrx2[i] = vrx[i] * vrx[i];
		vry2[i] = vry[i] * vry[i];
		vlx2[i] = vlx[i] * vlx[i];
		vly2[i] = vly[i] * vly[i];

		prpl[i] = pr[i] * pl[i];
		prvrx[i] = pr[i] * vrx[i];
		prvry[i] = pr[i] * vry[i];
		prvlx[i] = pr[i] * vlx[i];
		prvly[i] = pr[i] * vly[i];
		plvrx[i] = pl[i] * vrx[i];
		plvry[i] = pl[i] * vry[i];
		plvlx[i] = pl[i] * vlx[i];
		plvly[i] = pl[i] * vly[i];

		vrx_vry[i] = vrx[i] * vry[i];
		vrx_vlx[i] = vrx[i] * vlx[i];
		vrx_vly[i] = vrx[i] * vly[i];
		vry_vlx[i] = vry[i] * vlx[i];
		vry_vly[i] = vry[i] * vly[i];
		vlx_vly[i] = vlx[i] * vly[i];

		prla[i] = pr[i] * label_[i];
		plla[i] = pl[i] * label_[i];
		vrxla[i] = vrx[i] * label_[i];
		vryla[i] = vry[i] * label_[i];
		vlxla[i] = vlx[i] * label_[i];
		vlyla[i] = vly[i] * label_[i];
	}

	sum_pr = sum_all(pr);
	sum_pl = sum_all(pl);
	sum_vrx = sum_all(vrx);
	sum_vry = sum_all(vry);
	sum_vlx = sum_all(vlx);
	sum_vly = sum_all(vly);

	sum_pr2 = sum_all(pr2);
	sum_pl2 = sum_all(pl2);
	sum_vrx2 = sum_all(vrx2);
	sum_vry2 = sum_all(vry2);
	sum_vlx2 = sum_all(vlx2);
	sum_vly2 = sum_all(vly2);

	sum_prpl = sum_all(prpl); 
	sum_prvrx = sum_all(prvrx); 
	sum_prvry = sum_all(prvry); 
	sum_prvlx = sum_all(prvlx); 
	sum_prvly = sum_all(prvly);

	sum_plvrx = sum_all(plvrx);
	sum_plvry = sum_all(plvry);
	sum_plvlx = sum_all(plvlx);
	sum_plvly = sum_all(plvly);
	sum_vrx_vry = sum_all(vrx_vry);
	sum_vrx_vlx = sum_all(vrx_vlx);
	sum_vrx_vly = sum_all(vrx_vly);
	sum_vry_vlx = sum_all(vry_vlx);
	sum_vry_vly = sum_all(vry_vly);
	sum_vlx_vly = sum_all(vlx_vly);

	sum_la = sum_all(label_);
	sum_prla = sum_all(prla);
	sum_plla = sum_all(plla);
	sum_vrxla = sum_all(vrxla);
	sum_vryla = sum_all(vryla);
	sum_vlxla = sum_all(vlxla);
	sum_vlyla = sum_all(vlyla);

	// coefficient matrix : A
	m_a[0][0] = num;
	m_a[0][1] = sum_pr;
	m_a[0][2] = sum_pl;
	m_a[0][3] = sum_vrx;
	m_a[0][4] = sum_vry;
	m_a[0][5] = sum_vlx;
	m_a[0][6] = sum_vly;

	m_a[1][0] = sum_pr;
	m_a[1][1] = sum_pr2;
	m_a[1][2] = sum_prpl;
	m_a[1][3] = sum_prvrx;
	m_a[1][4] = sum_prvry;
	m_a[1][5] = sum_prvlx;
	m_a[1][6] = sum_prvly;

	m_a[2][0] = sum_pl;
	m_a[2][1] = sum_prpl;
	m_a[2][2] = sum_pl2;
	m_a[2][3] = sum_plvrx;
	m_a[2][4] = sum_plvry;
	m_a[2][5] = sum_plvlx;
	m_a[2][6] = sum_plvly;

	m_a[3][0] = sum_vrx;
	m_a[3][1] = sum_prvrx;
	m_a[3][2] = sum_plvrx;
	m_a[3][3] = sum_vrx2;
	m_a[3][4] = sum_vrx_vry;
	m_a[3][5] = sum_vrx_vlx;
	m_a[3][6] = sum_vrx_vly;

	m_a[4][0] = sum_vry;
	m_a[4][1] = sum_prvry;
	m_a[4][2] = sum_plvry;
	m_a[4][3] = sum_vrx_vry;
	m_a[4][4] = sum_vry2;
	m_a[4][5] = sum_vry_vlx;
	m_a[4][6] = sum_vry_vly;

	m_a[5][0] = sum_vlx;
	m_a[5][1] = sum_prvlx;
	m_a[5][2] = sum_plvlx;
	m_a[5][3] = sum_vrx_vlx;
	m_a[5][4] = sum_vry_vlx;
	m_a[5][5] = sum_vlx2;
	m_a[5][6] = sum_vlx_vly;

	m_a[6][0] = sum_vly;
	m_a[6][1] = sum_prvly;
	m_a[6][2] = sum_plvly;
	m_a[6][3] = sum_vrx_vly;
	m_a[6][4] = sum_vry_vly;
	m_a[6][5] = sum_vlx_vly;
	m_a[6][6] = sum_vly2;

	// 단위행렬
	for (int k = 0; k < mnum; k++)
		m_i[k][k] = 1.0;

	for (int i = 0; i < mnum; i++)
	{
		for (int j = 0; j < mnum; j++)
		{
			m_au[i][j] = m_a[i][j];
			m_au[i][j + mnum] = m_i[i][j];
		}
	}

	// coefficient matrix : B
	m_b[0] = sum_la;
	m_b[1] = sum_prla;
	m_b[2] = sum_plla;
	m_b[3] = sum_vrxla;
	m_b[4] = sum_vryla;
	m_b[5] = sum_vlxla;
	m_b[6] = sum_vlyla;


	double pivot = 0, d;

	for (int i = 0; i < mnum; i++)
	{
		pivot = m_au[i][i];
		for (int j = 0; j < (2 * mnum); j++){
			if (pivot == 0)
				m_au[i][j] = 0;
			else
				m_au[i][j] = m_au[i][j] / pivot;
		}
		for (int k = 0; k < mnum; k++){
			d = m_au[k][i];
			for (int j = 0; j < (2 * mnum); j++){
				if (k != i) {
					m_au[k][j] = m_au[k][j] + (-1)*(m_au[i][j] * d);
				}
			}
		}
	}

	for (int i = 0; i < mnum; i++){
		for (int j = 0; j < mnum; j++){
			m_ai[i][j] = m_au[i][j + mnum];
		}
	}

	for (int i = 0; i < mnum; i++){
		double sum = 0;
		for (int j = 0; j < mnum; j++){
			sum = sum + m_ai[i][j] * m_b[j];
		}
		coeff[i] = sum;
	}

	printf("result\n");
	printf("label = (%.6lf) + (%.6lf)pr + (%.6lf)pl + (%.6lf)vrx + (%.6lf)vry + (%.6lf)vlx + (%.6lf)vly \n", coeff[0], coeff[1], coeff[2], coeff[3], coeff[4], coeff[5], coeff[6]);

	//this->coefficients[0] = coeff[0]; // 상수
	//this->coefficients[1] = coeff[1]; // coefficient of right
	//this->coefficients[2] = coeff[2]; // coefficient of left

	/*  메모리 해제  */
	for (int j = 0; j < mnum; j++)
	{
		delete[] m_a[j];
		delete[] m_au[j];
		//delete[] m_au[j * 2];
		delete[] m_ai[j];
		free(m_i[j]);
	}
	delete[]m_a;
	delete[]m_au;
	delete[]m_ai;

	free(coeff);
	free(m_i);

	delete pr2; delete pl2; delete vrx2; delete vry2; delete vlx2; delete vly2;

	delete prpl;
	delete prvrx;
	delete prvry;
	delete prvlx;
	delete prvly;
	delete plvrx;
	delete plvry;
	delete plvlx;
	delete plvly;

	delete vrx_vry;
	delete vrx_vlx;
	delete vrx_vly;
	delete vry_vlx;
	delete vry_vly;
	delete vlx_vly;

	delete prla; 
	delete plla; 
	delete vrxla;
	delete vryla;
	delete vlxla;
	delete vlyla;

	delete m_b;

}