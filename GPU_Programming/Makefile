# Copyright (c) 2020 NVIDIA Corporation.  All rights reserved. 
CC := nvc++
CFLAGS := -O3 -acc -ta=tesla,managed,lineinfo -w
# CFLAGS := -O3 -w
ACCFLAGS := -Minfo=accel
LDFLAGS :=  -lnetcdf -ldl
NVTXLIB := -I/opt/nvidia/hpc_sdk/Linux_x86_64/22.3/cuda/11.6/include -L/opt/nvidia/hpc_sdk/Linux_x86_64/22.3/cuda/11.6/lib64 -lnvToolsExt

miniWeather: miniWeather_serial.cpp
	${CC} ${CFLAGS} ${ACCFLAGS} -o miniWeather miniWeather_serial.cpp ${NVTXLIB} ${LDFLAGS}

clean:
	rm -f *.o miniWeather