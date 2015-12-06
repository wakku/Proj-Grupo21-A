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

__host__ __device__ void teste(Mat *out_image, float media_R, float media_G, float media_B, int v, int i, int j)
{
	out_image->at<Vec3b>(i, j)[0] = media_R/v;
	out_image->at<Vec3b>(i, j)[1] = media_G/v;
    out_image->at<Vec3b>(i, j)[2] = media_B/v;
}


__global__ void blur( Mat *in_image, Mat *out_image) {
    
	uint8_t* pixelPtr = (uint8_t*)in_image->data;
	int v, i, j, k, w;        
	float media_R, media_G, media_B;

    for(i = 0; i < in_image->rows; i++){
        for(j = 0; j < in_image->cols; j++){
            
            media_R = 0;
            media_G = 0;
            media_B = 0;
            v = 0;

            for(k = -2; k <= 2; k++){
                for(w = -2; w <= 2; w++){
                    if((i + k >= 0) && (i + k < in_image->rows) && (j + w >= 0) && (j + w < in_image->cols)){
                        media_R += pixelPtr[(i+k)*in_image->cols + (j+w) + 0];
                        media_G += pixelPtr[(i+k)*in_image->cols + (j+w) + 1];
                        media_B += pixelPtr[(i+k)*in_image->cols + (j+w) + 2];
                        v++;
                    }
                }
            }
			

			teste(out_image, media_R, media_G, media_B, v, i, j); //isso foi um teste que nao deu certo, usando function global dentro de
 			//outra global
            //out_image->at<Vec3b>(i, j)[0] = media_R/v;
            //out_image->at<Vec3b>(i, j)[1] = media_G/v;
            //out_image->at<Vec3b>(i, j)[2] = media_B/v;
        }
    }
}

int main(int argc, const char* argv[]){
   
    time_t inicioTempo = time(NULL);
    time_t tempo;

    //Matrizes que guardam os canais de cor
	Mat in_image;
	Mat out_image;

    in_image = imread(argv[0], 1);
    out_image = imread(argv[0], 1);

    Mat *dev_out_image;
    Mat *dev_in_image;

    // Alocacao de memoria no device
    cudaMalloc( (void**)&dev_out_image, in_image.elemSize());
    cudaMalloc( (void**)&dev_in_image, in_image.elemSize());

	memset (&dev_out_image,0,fullSize);
    memset (&dev_in_image,0,fullSize);

    tempo = time(NULL) - inicioTempo;
    printf("Arquivo salvo na memoria principal.\n");
    printf("%ld : Copiando para memoria da placa...\n", tempo);

    // copia as matrizes da memoria do host para o device
    cudaMemcpy( dev_in_image, &in_image, in_image.elemSize(), cudaMemcpyHostToDevice );
    cudaMemcpy( dev_out_image, &out_image, in_image.elemSize(), cudaMemcpyHostToDevice );

    printf("%ld : Vetor copiado para memoria da placa.\n", tempo);
    printf("Aplicando filtro de blur...\n");

    //Realiza o filtro blur em cada matriz
    blur<<<in_image.elemSize()/nThreadsPorBloco,nThreadsPorBloco>>>( dev_in_image, dev_out_image);

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Filtro Aplicado.\n",tempo);
    printf("Copiando vetor para memoria principal...\n ");

    // Copia de volta as matrizes da memoria do Device para o Host
    cudaMemcpy( &out_image, dev_out_image, in_image.elemSize(), cudaMemcpyDeviceToHost );

    imwrite(argv[1], out_image);

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Arquivo salvo em out.ppm\n",tempo);
    printf("Liberando memoria..\n");

    in_image.release();
    out_image.release();
    cudaFree( dev_in_image );
    cudaFree( dev_out_image );

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Memoria liberada.\n",tempo);
    
    return 0;
}
