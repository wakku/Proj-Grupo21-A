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

__global__ void blur( Mat *in_image, int *out_image[3]) {
    
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
    
            out_image[0][i * in_image->cols + j] = media_R/v;
            out_image[1][i * in_image->cols + j] = media_G/v;
            out_image[2][i * in_image->cols + j] = media_B/v;
        }
    }
}

int main(int argc, const char* argv[]){
   
    time_t inicioTempo = time(NULL);
    time_t tempo;

    //Matrizes que guardam os canais de cor
    Mat in_image;
    Mat out_image;
    int *int_out_image[3];

    in_image = imread(argv[1], 1);
    out_image = imread(argv[1], 1);

    int *dev_out_image[3];
    Mat *dev_in_image;

    // Alocacao de memoria no device
    cudaMalloc( (void**)&dev_in_image, in_image.elemSize());
    cudaMalloc( (void**)&dev_out_image[0], in_image.cols*in_image.rows*sizeof(int));
    cudaMalloc( (void**)&dev_out_image[1], in_image.cols*in_image.rows*sizeof(int));
    cudaMalloc( (void**)&dev_out_image[2], in_image.cols*in_image.rows*sizeof(int));

    int_out_image[0] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);
    int_out_image[1] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);
    int_out_image[2] = (int*) malloc(sizeof(int)*in_image.cols*in_image.rows);

    memset (&dev_in_image,0,in_image.elemSize());
    memset (int_out_image[0],0,sizeof(int)*in_image.cols*in_image.rows);
    memset (int_out_image[1],0,sizeof(int)*in_image.cols*in_image.rows);
    memset (int_out_image[2],0,sizeof(int)*in_image.cols*in_image.rows);

    tempo = time(NULL) - inicioTempo;
    printf("Arquivo salvo na memoria principal.\n");
    printf("%ld : Copiando para memoria da placa...\n", tempo);

    // copia as matrizes da memoria do host para o device
    cudaMemcpy( dev_in_image, &in_image, in_image.elemSize(), cudaMemcpyHostToDevice );

    printf("%ld : Vetor copiado para memoria da placa.\n", tempo);
    printf("Aplicando filtro de blur...\n");

    //Realiza o filtro blur em cada matriz
    blur<<<in_image.elemSize()/nThreadsPorBloco,nThreadsPorBloco>>>( dev_in_image, dev_out_image);

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Filtro Aplicado.\n",tempo);
    printf("Copiando vetor para memoria principal...\n ");

    // Copia de volta as matrizes da memoria do Device para o Host
    cudaMemcpy( int_out_image[0], dev_out_image[0], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );
    cudaMemcpy( int_out_image[1], dev_out_image[1], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );
    cudaMemcpy( int_out_image[2], dev_out_image[2], in_image.cols*in_image.rows*sizeof(int), cudaMemcpyDeviceToHost );

    // Convert int to Mat
    for(int i = 0; i < in_image.rows; i++){
        for(int j = 0; j < in_image.cols; j++){
    
            out_image.at<Vec3b>(i, j)[0] = int_out_image[0][i * in_image.cols + j];
            out_image.at<Vec3b>(i, j)[1] = int_out_image[1][i * in_image.cols + j];
            out_image.at<Vec3b>(i, j)[2] = int_out_image[2][i * in_image.cols + j];
        }
    }

    imwrite(argv[2], out_image);

    tempo = time(NULL) - inicioTempo;
    cout << tempo << ": Arquivo salvo em " << argv[2] << endl;
    cout << "Liberando memoria..." << endl;

    in_image.release();
    out_image.release();
    cudaFree( dev_in_image );
    cudaFree( dev_out_image );

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Memoria liberada.\n",tempo);
    
    return 0;
}
