#include <cv.h>
#include <highgui.h>
#include <omp.h>
#include <unistd.h>
#include <mpi.h>

using namespace std;
using namespace cv;

Mat in_image;
Mat out_image;

void calc_node(int num_nodes, int posicao, string path_input, string path_output){

    in_image = imread(path_input, 1);
    out_image = imread(path_input, 1);
    int n_threads = sysconf(_SC_NPROCESSORS_ONLN);
    
    int cn = in_image.channels();
    

    //total de pixels a serem percorridos por cada node
    int total_node = in_image.rows*in_image.cols/num_nodes;

    //posicao na imagem onde esse node ira iniciar
    int start_node = posicao*total_node;

    //quantidade de pixel que cada thread ira processar
    int total_thread = total_node/n_threads;
    
    int count, i, j, k, w, start_thread, start_row, start_col, v, adicional; 
    double media_R, media_G, media_B;

    int size, rank;

    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (rank > 0) // SLAVE
    {
        omp_set_dynamic(0);
        omp_set_num_threads(n_threads);

        // Process part of the image in parallel (using threads through OpenMP)
        #pragma omp parallel shared(total_thread, cn) private(count, i, j, k, w, start_thread, start_row, start_col, v, media_R, media_G, media_B) 
        {

            uint8_t* pixelPtr = (uint8_t*)in_image.data;

            start_thread = total_thread*omp_get_thread_num()+start_node;
            start_row = start_thread/in_image.cols;
            start_col = start_thread - start_row*in_image.cols;

            count = 0;

            j = start_col;
            for(i = start_row; count < total_thread; i++){
                while(j < in_image.cols && count < total_thread){

                    media_R = 0;
                    media_G = 0;
                    media_B = 0;
                    v = 0;

                    for(k = -2; k <= 2; k++){
                        for(w = -2; w <= 2; w++){
                            if((i + k >= 0) && (i + k < in_image.rows) && (j + w >= 0) && (j + w < in_image.cols)){
                                media_R += pixelPtr[(i+k)*in_image.cols*cn + (j+w)*cn + 0];
                                media_G += pixelPtr[(i+k)*in_image.cols*cn + (j+w)*cn + 1];
                                media_B += pixelPtr[(i+k)*in_image.cols*cn + (j+w)*cn + 2];
                                v++;
                            }
                        }  
                    }

                    out_image.at<Vec3b>(i, j)[0] = media_R/v;
                    out_image.at<Vec3b>(i, j)[1] = media_G/v;
                    out_image.at<Vec3b>(i, j)[2] = media_B/v;

                    j++;
                    count++;
                }


                j = 0;
            }
                #pragma omp barrier
        }

        MPI_Send(out_image.data, start_row * start_col * 3, MPI_BYTE, 0, 0, MPI_COMM_WORLD);
    }
    else // MASTER
    {
        bool typeOfImg = in_image->rows >= in_image->cols;
        bool fullyprocessed = false;
        img_buffer= new Mat[size-1];
        recv_request = new MPI_Request[size-1];
        int *flags = new int[size-1];
        for(i=0; i< size-1; i++){
            if(in_image->channels() == 3){ // RGB
                img_buffer[i] =  Mat(in_image->rows, in_image->cols, CV_8UC3);
                // Receive (partially) processed image and save into img_buffer
                MPI_Irecv(img_buffer[i].data, in_image->rows * in_image->cols * 3, MPI_BYTE, i+1, 0, MPI_COMM_WORLD, &(recv_request[i]));
            } else { // GRAYSCALE
                img_buffer[i] =  Mat(in_image->rows, in_image->cols, CV_8UC1);
                // Receive (partially) processed image and save into img_buffer
                MPI_Irecv(img_buffer[i].data, in_image->rows * in_image->cols, MPI_BYTE, i+1, 0, MPI_COMM_WORLD, &(recv_request[i]));               
            }
        }
        in_image->release();
        i = 0;
        fullyprocessed = false;
        while(!fullyprocessed){
            MPI_Test(&(recv_request[i]), &(flags[i]), &status);
            fullyprocessed = true;
            for(j = 0; j < size - 1; j++){
                if(flags[j] == 0){
                    fullyprocessed = false;
                    break;
                }
            }
            i++;
            if(i == size - 1)
                i = 0;
        }
        
        // img_buffer is now fully processed
        out_image = img_buffer;
    }

    imwrite(path_output, out_image);
}

int main( int argc, char** argv ){

    calc_node(1, 0, argv[1], argv[2]);

    return 0;
    

}
