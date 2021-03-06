#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>

static int dev_alloc(void** buff, size_t num_bytes)
{
	cudaError_t err = cudaSuccess;
	err = cudaMalloc((void**)buff, num_bytes);
	if(cudaSuccess != err) {
		fprintf(stderr, "cudaMalloc: %s\n", cudaGetErrorString(err));
		return 1;
	}
	return 0;
}

struct START_STOP {
	cudaEvent_t start;
	cudaEvent_t stop;
};

static int start_time(struct START_STOP* ss)
{
	cudaError_t err = cudaSuccess;
	
	err = cudaEventCreate(&ss->start);
	if(cudaSuccess != err) {
		fprintf(stderr, "cudaEventCreate: %s\n", cudaGetErrorString(err));
		return 4;
	}

	err = cudaEventCreate(&ss->stop);
	if(cudaSuccess != err) {
		cudaEventDestroy(ss->start);
		fprintf(stderr, "cudaEventCreate: %s\n", cudaGetErrorString(err));
		return 5;
	}

	err = cudaEventRecord(ss->start, 0);
	if(cudaSuccess != err) {
		cudaEventDestroy(ss->start);
		cudaEventDestroy(ss->stop);
		fprintf(stderr, "cudaEventRecord: %s\n", cudaGetErrorString(err));
		return 6;
	}
	return 0;
}

static int stop_time(struct START_STOP* ss, float* gpu_time)
{
	cudaError_t err = cudaSuccess;
	int res = 0;
	do {
		err = cudaEventRecord(ss->stop, 0);
		if(cudaSuccess != err) {
			fprintf(stderr, "cudaEventRecord: %s\n", cudaGetErrorString(err));
			res = 7;
			break;
		}
		err = cudaEventSynchronize(ss->stop);
		if(cudaSuccess != err) {
			fprintf(stderr, "cudaEventSynchronize: %s\n", cudaGetErrorString(err));
			res = 8;
			break;
		}
		err = cudaEventElapsedTime(gpu_time, ss->start, ss->stop);
		if(cudaSuccess != err) {
			fprintf(stderr, "cudaEventElapsedTime: %s\n", cudaGetErrorString(err));
			res = 9;
			break;
		}

	} while(0);
	
	cudaEventDestroy(ss->start);
	cudaEventDestroy(ss->stop);
	return res;
}


struct RR_2x2048 {
	float input[2][2048];
	float output[2];
};

__global__ static void reduce_2x2048(struct RR_2x2048* rr)
{
	volatile uint32_t i = threadIdx.x;
	volatile uint32_t j = blockIdx.x;

	__shared__ float ss[0x400];

	ss[i] = rr->input[j][i] + rr->input[j][i + 0x400];
	__syncthreads();

	if(i & 0x200)
		return;
	ss[i] += ss[i + 0x200];
	__syncthreads();
	if(i & 0x100)
		return;
	ss[i] += ss[i + 0x100];
	__syncthreads();
	if(i & 0x080)
		return;
	ss[i] += ss[i + 0x080];
	__syncthreads();
	if(i & 0x040)
		return;
	ss[i] += ss[i + 0x040];
	__syncthreads();
	if(i & 0x020)
		return;
	ss[i] += ss[i + 0x020];
	ss[i] += ss[i + 0x010];
	ss[i] += ss[i + 0x008];
	ss[i] += ss[i + 0x004];
	ss[i] += ss[i + 0x002];
	ss[i] += ss[i + 0x001];
	if(!i)
		rr->output[j] = ss[i];
}

static void init_2x2048(struct RR_2x2048* rr)
{
	uint32_t i;
	srand48(time(0));
	for(i = 0; i < 2048; i ++) {
		rr->input[0][i] = 2 * drand48() - 1;
	}
	for(i = 0; i < 2048; i ++) {
		rr->input[1][i] = 2 * drand48() - 1;
	}
	rr->output[1] = rr->output[0] = 0;
}

static float sum_2x2048(float data[2][2048])
{
	float res = 0;
	uint32_t i;
	for(i = 0; i < 2048; i ++) {
		res += data[0][i];
	}
	for(i = 0; i < 2048; i ++) {
		res += data[1][i];
	}
	return res;
}

static int copy_input_to_dev_2x2048(float dest[2][2048], float src[2][2048])
{
	cudaError_t err = cudaMemcpy(dest, src, sizeof(float[2][2048]), cudaMemcpyHostToDevice);
	if(cudaSuccess != err)
	{
		fprintf(stderr, "copy input - cudaMemcpy: %s\n", cudaGetErrorString(err));
		return 3;
	}
	return 0;
}

static int copy_output_to_host_2x2048(float dest[2], float src[2])
{
	cudaError_t err = cudaMemcpy(dest, src, sizeof(float[2]), cudaMemcpyDeviceToHost);
	if(cudaSuccess != err)
	{
		fprintf(stderr, "copy output - cudaMemcpy: %s\n", cudaGetErrorString(err));
		return 4;
	}
	return 0;
}

static int test_reduce_2x2048()
{
	cudaError_t err = cudaSuccess;
	struct RR_2x2048 rr, *dev_rr;
	struct START_STOP ss;
	float gpu_time = 0;
	int res = 0;

	if((res = dev_alloc((void**)&dev_rr, sizeof(rr))))
		return res;

	init_2x2048(&rr);

	do {
		if((res = copy_input_to_dev_2x2048(dev_rr->input, rr.input)))
			break;

		if((res = start_time(&ss)))
			break;

		reduce_2x2048<<<2, 0x400>>>(dev_rr);

		if((res = stop_time(&ss, &gpu_time)))
			break;

		if((res = copy_output_to_host_2x2048(rr.output, dev_rr->output)))
			break;

		printf("GOLD: %.8g\n", sum_2x2048(rr.input));
		printf("CALC: %.8g (%g ms, %s)\n", rr.output[0] + rr.output[1], gpu_time, __func__);
	}while(0);

	err = cudaFree(dev_rr);

    cudaDeviceReset();

	if(cudaSuccess != err)
	{
		fprintf(stderr, "cudaFree: %s\n", cudaGetErrorString(err));
		return 2;
	}

	return res;
}


struct RR_64x64 {
	float	input[64][64];
	float	output[64];
};

__global__ static void reduce_64x64(struct RR_64x64* rr)
{
	volatile uint32_t i = threadIdx.x;
	volatile uint32_t j = blockIdx.x;

	__shared__ float ss[0x20];

	ss[i] = rr->input[j][i] + rr->input[j][i + 0x20];

	ss[i] += ss[i + 0x010];
	ss[i] += ss[i + 0x008];
	ss[i] += ss[i + 0x004];
	ss[i] += ss[i + 0x002];
	ss[i] += ss[i + 0x001];
	if(!i)
		rr->output[j] = *ss;
}

__global__ static void reduce_1x64(float data[64])
{
	volatile uint32_t i = threadIdx.x;

	__shared__ float ss[0x20];

	ss[i] = data[i] + data[i + 0x20];

	ss[i] += ss[i + 0x010];
	ss[i] += ss[i + 0x008];
	ss[i] += ss[i + 0x004];
	ss[i] += ss[i + 0x002];
	ss[i] += ss[i + 0x001];
	if(!i)
		data[0] = *ss;
}

static void init_64x64(struct RR_64x64* rr)
{
	uint32_t i, j;
	srand48(time(0));
	for(j = 0; j < 64; j ++) {
		for(i = 0; i < 64; i ++) {
			rr->input[j][i] = 2 * drand48() - 1;
		}
		rr->output[j] = 0;
	}
}

static float sum_64x64(float data[64][64])
{
	float res = 0;
	uint32_t i, j;
	for(j = 0; j < 64; j ++) {
		for(i = 0; i < 64; i ++) {
			res += data[j][i];
		}
	}
	return res;
}

static int copy_input_to_dev_64x64(float dest[64][64], float src[64][64])
{
	cudaError_t err = cudaMemcpy(dest, src, sizeof(float[64][64]), cudaMemcpyHostToDevice);
	if(cudaSuccess != err)
	{
		fprintf(stderr, "copy input - cudaMemcpy: %s\n", cudaGetErrorString(err));
		return 3;
	}
	return 0;
}

static int copy_output_to_host_64x64(float dest[64], float src[64])
{
	cudaError_t err = cudaMemcpy(dest, src, sizeof(float[64]), cudaMemcpyDeviceToHost);
	if(cudaSuccess != err)
	{
		fprintf(stderr, "copy output - cudaMemcpy: %s\n", cudaGetErrorString(err));
		return 4;
	}
	return 0;
}

static int test_reduce_64x64()
{
	cudaError_t err = cudaSuccess;
	struct RR_64x64 rr, *dev_rr;
	struct START_STOP ss;
	float gpu_time = 0;
	int res = 0;

	if((res = dev_alloc((void**)&dev_rr, sizeof(rr))))
		return res;

	init_64x64(&rr);

	do {
		if((res = copy_input_to_dev_64x64(dev_rr->input, rr.input)))
			break;
    
		if((res = start_time(&ss)))
			break;

		reduce_64x64<<<64, 0x20>>>(dev_rr);
		reduce_1x64<<<1, 0x20>>>(dev_rr->output);

		if((res = stop_time(&ss, &gpu_time)))
			break;

		if((res = copy_output_to_host_64x64(rr.output, dev_rr->output)))
			break;

		printf("GOLD: %.8g\n", sum_64x64(rr.input));
		printf("CALC: %.8g (%g ms, %s)\n", rr.output[0], gpu_time, __func__);
	}while(0);

	err = cudaFree(dev_rr);

    cudaDeviceReset();

	if(cudaSuccess != err)
	{
		fprintf(stderr, "cudaFree: %s\n", cudaGetErrorString(err));
		return 2;
	}

	return res;
}

main(void)
{
	int res = 0;

	if((res = test_reduce_64x64()))
		return res;
	return test_reduce_2x2048();
}


