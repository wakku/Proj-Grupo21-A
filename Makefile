all: sequencial paralelo_openmp paralelo_cuda

sequencial: src/T2/trab2_seq.cpp 
	g++ -I/usr/include/opencv -I/usr/include/opencv2 -L/usr/include/opencv/lib/ -g -o bin/smooth_seq  src/T2/trab2_seq.cpp -lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_ml -lopencv_video -lopencv_features2d -lopencv_calib3d -lopencv_objdetect -lopencv_contrib -lopencv_legacy -lopencv_stitching

paralelo_openmp: src/T2/trab2.cpp
	g++ -I/usr/include/opencv -I/usr/include/opencv2 -L/usr/include/opencv/lib/ -g -o bin/smooth_openmp  src/T2/trab2.cpp -lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_ml -lopencv_video -lopencv_features2d -lopencv_calib3d -lopencv_objdetect -lopencv_contrib -lopencv_legacy -lopencv_stitching -fopenmp

paralelo_cuda: src/T3/trab3.cu
	nvcc `pkg-config --cflags opencv` src/T3/trab3.cu -o bin/smooth_cuda `pkg-config --libs opencv`

clean:
	rm bin/*
