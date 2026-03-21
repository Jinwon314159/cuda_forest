#pragma once

#include <stdio.h>
#include "global.cuh"

class inspector
{
public:
	void init(int size_);
	void setting_value(fig_finest_fruit* finest_fruits, int count);
	void check_direction();
	void clear();

private:
	int count; // 몇개의 식이 주어졌는지 갯수
	int coeff_count; // 독립변수 ( + 상수) 갯수
	int index;
	bool do_check = false;
	double *pr, *pl, *label_; // label_ -> 1: 앞
	double sum_all(double *x);
};


void inspector::init(int size_)
{
	this->count = size_;
	this->coeff_count = 3;
	this->index = 0;
	// memory allocation
	this->pr = (double*)calloc(sizeof(double), size_);
	this->pl = (double*)calloc(sizeof(double), size_);
	this->label_ = (double*)calloc(sizeof(double), size_);
}

void inspector::clear()
{
	this->count = 0;
	this->coeff_count = 0;
	this->index = 0;

	free(this->pr);
	free(this->pl);
	free(this->label_);
}

void inspector::setting_value(fig_finest_fruit* finest_fruits, int count)
{
	// 한 프레임때 마다 호출됨
	// 즉 여기서는 20번 호출될거임
	int shr_right_count = 0;
	double pro_right_sum = 0;
	
	int shr_left_count = 0;
	double pro_left_sum = 0;

	for (int i = 0; i < count; i++)
	{
		int x_ = finest_fruits[i].x;
		int y_ = finest_fruits[i].y;
		int label_ = finest_fruits[i].label;

		if (finest_fruits[i].label == 2 )//&& finest_fruits[i].probability > 0.5)
		{
			// left shoulder
			pro_left_sum += finest_fruits[i].probability;
			shr_left_count++;
		}
		else if (finest_fruits[i].label == 8 )//&& finest_fruits[i].probability > 0.5)
		{
			// right shoulder
			pro_right_sum += finest_fruits[i].probability;
			shr_right_count++;
		}
	}

	if (shr_left_count != 0 && shr_right_count != 0)
	{
		// 현재 프레임의 각 어깨 확률의 평균을 저장한다.
		int idx = this->index;

		pr[idx] = pro_right_sum / shr_right_count;
		pl[idx] = pro_left_sum / shr_left_count;
		label_[idx] = 1;

		idx++;
		this->index = idx;
		this->do_check = true;
	}
	else
		this->do_check = false;
}

void inspector::check_direction()
{
	if (!this->do_check)
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

double inspector::sum_all(double *x)
{
	int i;
	double sum = 0;
	for (i = 0; i < this->count; i++) {
		sum = sum + x[i];
	}
	return sum;
}