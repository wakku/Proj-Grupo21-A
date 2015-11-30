/* Grupo 21 A:
Fernando Gorodscy - 7152354
Leonardo Rebelo - 5897894
*/

#include <cv.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>

using namespace std;
using namespace cv;

#define sizeX 40000  // Invertido
#define sizeY 4048
#define nThreadsPorBloco 512

__global__ void blur( int *imagem_in, int *imagem_out, int colorOffset ) {

    int offset = threadIdx.x + blockIdx.x * blockDim.x;

    int media=0;

    int cx,cy;

 	//Calcula a media para o pixel do centro
    for (cx = -2; cx <= 2; cx++){
        for (cy = -2; cy <= 2; cy++){
            media = media + imagem_in[colorOffset + offset + cx+ sizeX*cy];
        }
    }

    media = media/25;

    cx = 0, cy = 0;

    imagem_out[ colorOffset + offset ] =  media;
}

int main(int argc, const char* argv[])
{   
    time_t inicioTempo = time(NULL);
    time_t tempo;

    int offsetR = 0;
    int offsetG = sizeX*sizeY;
    int offsetB = sizeX*sizeY*2;

    int i;
    int size = sizeof(int)*sizeX*sizeY;
    int fullSize = 3*size;

    //Vetor que guarda os canais de cor
    int *imagemRGB = (int *) malloc(fullSize); 
    int *outimagemRGB = (int *) malloc(fullSize);


    int *dev_outimagemRGB;
    int *dev_imagemRGB;

    // Alocacao de memoria no device
    cudaMalloc( (void**)&dev_outimagemRGB, fullSize);
    cudaMalloc( (void**)&dev_imagemRGB, fullSize);

    // Limpa os enderecos alocados para as matrizes
    memset (outimagemRGB,0,fullSize);
    memset (imagemRGB,0,fullSize);

    char linha[1000];
    int valor; //Pega o valor da linha
    int countCor = 0; // 0->R  1->G  2->B
    int ri = 0; //Contadores individuais das matrizes de cor
    int rj = 0;
    int gi = 0;
    int gj = 0;
    int bi = 0;
    int bj = 0;

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Abrindo arquivo e carregando na memoria...\n", tempo);

    // Abre o arquivo
    FILE * file;
    file = fopen( argv[0]  , "r");

    //Pula as 4 primeiras linhas, que sao comentarios e informacoes da imagem
    for ( i = 0; i < 4; i ++)
        fgets(linha, 1000, file);

    //Quebra a imagem ppm em no vetor
    while ( fgets(linha, 10, file)  != NULL ) {

        //Converte string para inteiro
        valor = atoi(linha); 

        //Verifica se chegou no no ultimo pixel de X e incrementa Y
        if(bi == sizeY){
            ri = 0;
            rj++;
            gi = 0;
            gj++;
            bi = 0;
            bj++;
            //printf("\n");
        }

         // How to do it.
         // [j,i]
         // j + sizeX*i

        if(countCor == 0){ //Salva em RED
            imagemRGB[offsetR + rj+ sizeX*ri] = valor;
            countCor = 1;
            ri++;
            continue;
        }
        if(countCor == 1){ //Salva em GREEN
            imagemRGB[offsetG +  gj+ sizeX*gi] = valor;
            countCor = 2;
            gi++;
            continue;
        }
        if(countCor == 2){ //Salva em BLUE
            imagemRGB[offsetB + bj+ sizeX*bi] = valor;
            countCor = 0;
            bi++;
            continue;
        } 
    }

    fclose(file);

    tempo = time(NULL) - inicioTempo;
    printf("Arquivo salvo na memoria principal.\n");
    printf("%ld : Copiando para memoria da placa...\n", tempo);

    // copia as matrizes da memoria do host para o device
    cudaMemcpy( dev_imagemRGB, imagemRGB, fullSize, cudaMemcpyHostToDevice );
    cudaMemcpy( dev_outimagemRGB, outimagemRGB, fullSize, cudaMemcpyHostToDevice );


    printf("%ld : Vetor copiado para memoria da placa.\n", tempo);
    printf("Aplicando filtro de blur...\n");

    //Realiza o filtro blur em cada matriz
    blur<<<sizeX*sizeY/nThreadsPorBloco,nThreadsPorBloco>>>( dev_imagemRGB, dev_outimagemRGB, offsetR);
    blur<<<sizeX*sizeY/nThreadsPorBloco,nThreadsPorBloco>>>( dev_imagemRGB, dev_outimagemRGB, offsetG);
    blur<<<sizeX*sizeY/nThreadsPorBloco,nThreadsPorBloco>>>( dev_imagemRGB, dev_outimagemRGB, offsetB);

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Filtro Aplicado.\n",tempo);
    printf("Copiando vetor para memoria principal...\n ");

    // Copia de volta as matrizes da memoria do Device para o Host
    cudaMemcpy( outimagemRGB, dev_outimagemRGB, fullSize, cudaMemcpyDeviceToHost );

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Vetor copiado para memoria principal...\n", tempo);
    printf("Salvando vetor no arquivo...\n");

    //Salva de volta como arquivo ppm
    // Abrir o arquivo
    FILE * out;
    out = fopen( argv[1] , "w+");
    char saida[1000];
    char aux[100];

    //Coloca as 4 primeiras linhas:
    fputs("P3\n",out);

    sprintf(saida,"%d %d\n",sizeY,sizeX);
    fputs(saida,out);

    sprintf(saida,"# Imagem dos Brother\n");
    fputs(saida,out);

    fputs("255\n",out);

    //Coloca as matrizes de cor na saida ppm
    countCor = 0;
    ri = 0;
    rj = 0;
    gi = 0;
    gj = 0;
    bi = 0;
    bj = 0;



    while ( rj < sizeX && ri < sizeX*3 ){

        if(bi == sizeY){
            ri = 0;
            rj++;
            gi = 0;
            gj++;
            bi = 0;
            bj++;
        }

        if(countCor == 0){ //Salva em RED
            sprintf(aux,"%d",outimagemRGB[offsetR +rj+ sizeX*ri]);
            strcpy (saida,aux);
            strcat(saida,"\n");
            fputs(saida,out);
            countCor = 1;
            ri++;
            continue;
        }
        if(countCor == 1){ //Salva em GREEN
            sprintf(aux,"%d",outimagemRGB[offsetG+ gj+ sizeX*gi]);
            strcpy (saida,aux);
            strcat(saida,"\n");
            fputs(saida,out);
            countCor = 2;
            gi++;
            continue;
        }
        if(countCor == 2){ //Salva em BLUE
            sprintf(aux,"%d",outimagemRGB[offsetB +bj+ sizeX*bi]);
            strcpy (saida,aux);
            strcat(saida,"\n");
            fputs(saida,out);
            countCor = 0;
            bi++;
            continue;
        }
    }

    fclose(out);

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Arquivo salvo em out.ppm\n",tempo);
    printf("Liberando memoria..\n");

    free( imagemRGB );
    free( outimagemRGB );
    cudaFree( dev_imagemRGB );
    cudaFree( dev_outimagemRGB );

    tempo = time(NULL) - inicioTempo;
    printf("%ld : Memoria liberada.\n",tempo);
    

    return 0;
}
