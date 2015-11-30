all: paralelo_openmp paralelo_cuda

paralelo_openmp: trab2.cpp
	g++ -I/usr/include/opencv -I/usr/include/opencv2 -L/usr/include/opencv/lib/ -g -o smooth_openmp  trab2.cpp -lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_ml -lopencv_video -lopencv_features2d -lopencv_calib3d -lopencv_objdetect -lopencv_contrib -lopencv_legacy -lopencv_stitching -fopenmp

paralelo_cuda: trab3.cu
	nvcc trab3.cu -o smooth_cuda `pkg-config --cflags --libs opencv`

clean:
	rm smooth_cuda smooth_openmp
