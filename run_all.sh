#!/bin/sh

IMAGE_PATH="Imagens/"
RESULT_PATH="Resultados/"

echo "Building files...\n"
make

echo "Finished building files.\n"

cd $IMAGE_PATH

echo "Running Sequential:\n"

for image in *.jpg
do
	echo "$image"

	for i in $(seq 1 10)
	do
		/usr/bin/time -f "%e" ./../bin/smooth_seq "$image" "../$RESULT_PATH$image" 
	done
done

echo "Running OpenMP:\n"

for image in *.jpg
do
	echo "$image"

	for i in $(seq 1 10)
	do
		/usr/bin/time -f "%e" ./../bin/smooth_openmp "$image" "../$RESULT_PATH$image" 
	done
done

echo "Running Cuda:\n"

for image in *.jpg
do
	echo "$image"

	for i in $(seq 1 10)
	do
		/usr/bin/time -f "%e" ./../bin/smooth_cuda "$image" "../$RESULT_PATH$image" 
	done
done
