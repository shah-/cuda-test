#include <stdio.h>
#include <cuda_runtime.h>
#include <cuda_device_runtime_api.h>

static int z_print_props()
{
	int count = 0;
	int dev = 0;
	cudaDeviceProp prop;
	cudaError_t err = cudaGetDeviceCount(&count);
	if(err != cudaSuccess) {
		fprintf(stderr, "cudacudaGetDeviceCount: %s\n", cudaGetErrorString(err));
		return 1;
	}

	for(dev = 0; dev < count; dev ++) {
		err = cudaGetDeviceProperties(&prop, dev);
		if(err != cudaSuccess) {
			fprintf(stderr, "cudacudaGetDeviceCount: %s\n", cudaGetErrorString(err));
			return 2;
		}

		printf("DEVICE: %d\n===================\n", dev);
		printf("\tname:                      %s\n", prop.name);
		printf("\ttotalGlobalMem:            %u\n", prop.totalGlobalMem);
		printf("\tsharedMemPerBlock:         %u\n", prop.sharedMemPerBlock);
		printf("\tregsPerBlock:              %d\n", prop.regsPerBlock);
		printf("\twarpSize:                  %d\n", prop.warpSize);
		printf("\tmemPitch:                  %u\n", prop.memPitch);
		printf("\tmaxThreadsPerBlock:        %d\n", prop.maxThreadsPerBlock);
		printf("\tmaxThreadsDim[3]:          %d, %d, %d\n", prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
		printf("\tmaxGridSize[3]:            %d, %d, %d\n", prop.maxGridSize[0], prop.maxGridSize[1], prop.maxGridSize[2]);
		printf("\tclockRate:                 %d\n", prop.clockRate);
		printf("\ttotalConstMem:             %u\n", prop.totalConstMem);
		printf("\tmajor:                     %d\n", prop.major);
		printf("\tminor:                     %d\n", prop.minor);
		printf("\ttextureAlignment:          %u\n", prop.textureAlignment);
		printf("\ttexturePitchAlignment:     %u\n", prop.texturePitchAlignment);
		printf("\tdeviceOverlap:             %d\n", prop.deviceOverlap);
		printf("\tmultiProcessorCount:       %d\n", prop.multiProcessorCount);
		printf("\tkernelExecTimeoutEnabled:  %d\n", prop.kernelExecTimeoutEnabled);
		printf("\tintegrated:                %d\n", prop.integrated);
		printf("\tcanMapHostMemory:          %d\n", prop.canMapHostMemory);
		printf("\tcomputeMode:               %d\n", prop.computeMode);
		printf("\tmaxTexture1D:              %d\n", prop.maxTexture1D);
		printf("\tmaxTexture1DMipmap:        %d\n", prop.maxTexture1DMipmap);
		printf("\tmaxTexture1DLinear:        %d\n", prop.maxTexture1DLinear);
		printf("\tmaxTexture2D[2]:           %d, %d\n", prop.maxTexture2D[0], prop.maxTexture2D[1]);
		printf("\tmaxTexture2DMipmap[2]:     %d, %d\n", prop.maxTexture2DMipmap[0], prop.maxTexture2DMipmap[1]);
		printf("\tmaxTexture2DLinear[3]:     %d, %d, %d\n", prop.maxTexture2DLinear[0], prop.maxTexture2DLinear[1], prop.maxTexture2DLinear[2]);
		printf("\tmaxTexture2DGather[2]:     %d, %d\n", prop.maxTexture2DGather[0], prop.maxTexture2DGather[1]);
		printf("\tmaxTexture3D[3]:           %d, %d, %d\n", prop.maxTexture3D[0], prop.maxTexture3D[1], prop.maxTexture3D[2]);
		printf("\tmaxTexture3DAlt[3]:        %d, %d, %d\n", prop.maxTexture3DAlt[0], prop.maxTexture3DAlt[1], prop.maxTexture3DAlt[2]);
		printf("\tmaxTextureCubemap:         %d\n", prop.maxTextureCubemap);
		//    int    printf("\tmaxTexture1DLayered[2];     /**< Maximum 1D layered texture dimensions */
		//    int    printf("\tmaxTexture2DLayered[3];     /**< Maximum 2D layered texture dimensions */
		//    int    printf("\tmaxTextureCubemapLayered[2];/**< Maximum Cubemap layered texture dimensions */
		//    int    printf("\tmaxSurface1D;               /**< Maximum 1D surface size */
		//    int    printf("\tmaxSurface2D[2];            /**< Maximum 2D surface dimensions */
		//    int    printf("\tmaxSurface3D[3];            /**< Maximum 3D surface dimensions */
		//    int    printf("\tmaxSurface1DLayered[2];     /**< Maximum 1D layered surface dimensions */
		//    int    printf("\tmaxSurface2DLayered[3];     /**< Maximum 2D layered surface dimensions */
		//    int    printf("\tmaxSurfaceCubemap;          /**< Maximum Cubemap surface dimensions */
		//    int    printf("\tmaxSurfaceCubemapLayered[2];/**< Maximum Cubemap layered surface dimensions */
		//    size_t printf("\tsurfaceAlignment;           /**< Alignment requirements for surfaces */
		//    int    printf("\tconcurrentKernels;          /**< Device can possibly execute multiple kernels concurrently */
		//    int    printf("\tECCEnabled;                 /**< Device has ECC support enabled */
		//    int    printf("\tpciBusID;                   /**< PCI bus ID of the device */
		//    int    printf("\tpciDeviceID;                /**< PCI device ID of the device */
		//    int    printf("\tpciDomainID;                /**< PCI domain ID of the device */
		//    int    printf("\ttccDriver;                  /**< 1 if device is a Tesla device using TCC driver, 0 otherwise */
		//    int    printf("\tasyncEngineCount;           /**< Number of asynchronous engines */
		//    int    printf("\tunifiedAddressing;          /**< Device shares a unified address space with the host */
		//    int    printf("\tmemoryClockRate;            /**< Peak memory clock frequency in kilohertz */
		//    int    printf("\tmemoryBusWidth;             /**< Global memory bus width in bits */
		//    int    printf("\tl2CacheSize;                /**< Size of L2 cache in bytes */
		//    int    printf("\tmaxThreadsPerMultiProcessor;/**< Maximum resident threads per multiprocessor */
		//    int    printf("\tstreamPrioritiesSupported;  /**< Device supports stream priorities */
		//    int    printf("\tglobalL1CacheSupported;     /**< Device supports caching globals in L1 */
		//    int    printf("\tlocalL1CacheSupported;      /**< Device supports caching locals in L1 */
		//    size_t printf("\tsharedMemPerMultiprocessor; /**< Shared memory available per multiprocessor in bytes */
		//    int    printf("\tregsPerMultiprocessor;      /**< 32-bit registers available per multiprocessor */
		//    int    printf("\tmanagedMemory;              /**< Device supports allocating managed memory on this system */
		//    int    printf("\tisMultiGpuBoard;            /**< Device is on a multi-GPU board */
		//    int    printf("\tmultiGpuBoardGroupID;       /**< Unique identifier for a group of devices on the same multi-GPU board */
	}
	return 0;
}

main(void)
{
	return z_print_props();
}

