all: paralelo_openmp paralelo_cuda

paralelo_openmp: trab2.cpp
	mpic++ trab2.cpp -o Trabalho3_OpenMP -fopenmp

paralelo_cuda: trab3.cu
	nvcc trab3.cu -o Trabalho3_Cuda

clean:
	rm Trabalho3_Cuda Trabalho3_OpenMP
