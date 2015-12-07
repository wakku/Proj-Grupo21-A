/* Grupo 21 A:
Fernando Gorodscy - 7152354
Leonardo Rebelo - 5897894
*/

#include "opencv2/opencv.hpp"
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

using namespace std;
using namespace cv;

#define nThreadsPorBloco 512

__global__ void blur( int *in_image, int *out_image, int *cols, int *rows) {
    
	int v, i, j, k, w;
	int media;

	int offset = threadIdx.x + blockIdx.x * blockDim.x;
	i = offset/(*cols);
	j = offset - i*(*cols);
            
    media = 0;
    v = 0;

    for(k = -2; k <= 2; k++){
        for(w = -2; w <= 2; w++){
            if((i + k >= 0) && (i + k < *rows) && (j + w >= 0) && (j + w < *cols)){
                media += in_image[(i+k)*(*cols) + (j+w)];
                v++;
            }
        }
    }

    out_image[offset] = media/v;

	//out_image[offset] = 0;
}

int main(int argc, const char* argv[]){
   
    time_t inicioTempo = time(NULL);
    time_t tempo;

    //Matrizes que guardam os canais de cor
	Mat in_image = imread(argv[1], 1);
	Mat out_image = imread(argv[1], 1);

	// Alocacao de memoria no device
    int *dev_out_image[3];
	cudaMalloc((void**)&dev_out_image[0], in_image.cols*in_image.rows*sizeof(int));
    cudaMalloc((void**)&dev_out_image[1], in_image.cols*in_image.rows*sizeof(int));
    cudaMalloc((void**)&dev_out_image[2], in_image.cols*in_image.rows*sizeof(int));


	int *dev_in_image[3];
	cudaMalloc( (void**)&dev_in_image[0], in_image.cols*in_image.rows*sizeof(int));
    cudaMalloc( (void**)&dev_in_image[1], in_image.cols*in_image.rows*sizeof(int));
    cudaMalloc( (void**)&dev_in_image[2], in_image.cols*in_image.rows*sizeof(int));

	int *dev_rows, *dev_cols;
	cudaMalloc( (void**)&dev_cols, sizeof(int));
	cudaMalloc( (void**)&dev_rows, sizeof(int));

	

    
    // Alocacao de memoria no host
	int *int_out_image[3];
    int_out_image[0] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);
    int_out_image[1] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);
    int_out_image[2] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);

	int *int_in_image[3];
	int_in_image[0] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);
    int_in_image[1] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);
    int_in_image[2] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);

    tempo = time(NULL) - inicioTempo;
    //Arquivo salvo na memoria principal.
    //Copiando para memoria da placa...

	// Convert Mat to int**
    for(int i = 0; i < in_image.rows; i++){
        for(int j = 0; j < in_image.cols; j++){
            int_in_image[0][i * in_image.cols + j] = in_image.at<Vec3b>(i, j)[0];
            int_in_image[1][i * in_image.cols + j] = in_image.at<Vec3b>(i, j)[1];
            int_in_image[2][i * in_image.cols + j] = in_image.at<Vec3b>(i, j)[2];
        }
    }

    // copia as matrizes da memoria do host para o device
    //cudaMemcpy( dev_out_image, &out_image, out_image.elemSize(), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_in_image[0], int_in_image[0], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_in_image[1], int_in_image[1], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_in_image[2], int_in_image[2], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_out_image[0], int_out_image[0], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_out_image[1], int_out_image[1], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_out_image[2], int_out_image[2], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_cols, &in_image.cols, sizeof(int), cudaMemcpyHostToDevice );
	cudaMemcpy( dev_rows, &in_image.rows, sizeof(int), cudaMemcpyHostToDevice );

    //Vetor copiado para memoria da placa.
    //Aplicando filtro de blur...

    //Realiza o filtro blur em cada matriz
    blur<<<in_image.cols*in_image.rows/nThreadsPorBloco,nThreadsPorBloco>>>( dev_in_image[0], dev_out_image[0], dev_cols, dev_rows);
	blur<<<in_image.cols*in_image.rows/nThreadsPorBloco,nThreadsPorBloco>>>( dev_in_image[1], dev_out_image[1], dev_cols, dev_rows);
	blur<<<in_image.cols*in_image.rows/nThreadsPorBloco,nThreadsPorBloco>>>( dev_in_image[2], dev_out_image[2], dev_cols, dev_rows);

    tempo = time(NULL) - inicioTempo;
    //Filtro Aplicado.
    //Copiando vetor para memoria principal...

    // Copia de volta as matrizes da memoria do Device para o Host
    cudaMemcpy( int_out_image[0], dev_out_image[0], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );
    cudaMemcpy( int_out_image[1], dev_out_image[1], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );
    cudaMemcpy( int_out_image[2], dev_out_image[2], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );
	cudaMemcpy( int_in_image[0], dev_in_image[0], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );
    cudaMemcpy( int_in_image[1], dev_in_image[1], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );
    cudaMemcpy( int_in_image[2], dev_in_image[2], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );

    // Convert int to Mat
    for(int i = 0; i < in_image.rows; i++){
        for(int j = 0; j < in_image.cols; j++){
            out_image.at<Vec3b>(i, j)[0] = int_out_image[0][i * in_image.cols + j];
            out_image.at<Vec3b>(i, j)[1] = int_out_image[1][i * in_image.cols + j];
            out_image.at<Vec3b>(i, j)[2] = int_out_image[2][i * in_image.cols + j];
        }
    }

	imwrite(argv[2], out_image);

	for(int i = 0; i < out_image.rows; i++){
        for(int j = 0; j < out_image.cols; j++){
            in_image.at<Vec3b>(i, j)[0] = int_in_image[0][i * in_image.cols + j];
            in_image.at<Vec3b>(i, j)[1] = int_in_image[1][i * in_image.cols + j];
            in_image.at<Vec3b>(i, j)[2] = int_in_image[2][i * in_image.cols + j];
        }
    }

	imwrite(argv[1], in_image);

    tempo = time(NULL) - inicioTempo;
    //Liberando memoria...

    in_image.release();
    out_image.release();
    cudaFree( dev_in_image );
    cudaFree( dev_out_image );

    tempo = time(NULL) - inicioTempo;
    //Memoria liberada.
    
    return 0;
}
