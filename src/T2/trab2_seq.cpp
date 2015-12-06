#include <cv.h>
#include <highgui.h>

using namespace std;
using namespace cv;

Mat in_image;
Mat out_image;

void calc_node(int num_nodes, int posicao, string path_input, string path_output){

    in_image = imread(path_input, 1);
    out_image = imread(path_input, 1);
    int n_threads = 1;
    
    int cn = in_image.channels();
    

    //total de pixels a serem percorridos por cada node
    int total_node = in_image.rows*in_image.cols/num_nodes;

    //posicao na imagem onde esse node ira iniciar
    int start_node = posicao*total_node;

    //quantidade de pixel que cada thread ira processar
    int total_thread = total_node/n_threads;
    
    int count, i, j, k, w, start_thread, start_row, start_col, v, adicional; 
    double media_R, media_G, media_B;

        
	uint8_t* pixelPtr = (uint8_t*)in_image.data;

	start_thread = 0;
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
    

    imwrite(path_output, out_image);
}

int main( int argc, char** argv ){

    calc_node(1, 0, argv[1], argv[2]);

    return 0;
    

}
