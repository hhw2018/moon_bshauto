#define _GNU_SOURCE
#include <unistd.h>
#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>

static int processors= 0;     /* Number of CPU processors.. */
static int percentage = 0;    /* CPU utilization percentage. */
static int TOTAL_TIME = 400; /* 1000 ms total. */

static void usage() {
    printf("Usage: eat_cpu perc cpu_id cpu_id ...\n");
    printf("  perc  : CPU utilization percentage.\n");
    printf("  cpu_id: CPU processor id.\n");
    exit(1);
}

static long long int now_ms() {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC_COARSE, &now);
    return now.tv_sec*1000 + now.tv_nsec/1000000;
}

static void loop() {
    int work_time = TOTAL_TIME * percentage / 100;
    int idle_time = TOTAL_TIME - work_time;
    long long int start = 0;

    while (1) {
        start = now_ms();
        /* Working for %percentage TOTAL_TIME ms */
        while (now_ms() - start <= work_time);

        /* Sleep for TOTAL_TIME-work_time ms*/
        usleep(idle_time);
    }
}

static void *eat_cpu(void *arg) {
    int ret = 0;
    int i = 0;
    int id = *(int *)arg;
    cpu_set_t mask, get;

    CPU_ZERO(&get);
    CPU_ZERO(&mask);
    CPU_SET(id, &mask);

    ret = pthread_setaffinity_np(pthread_self(), sizeof(mask), &mask); 
    assert(ret == 0);

    ret = pthread_getaffinity_np(pthread_self(), sizeof(get), &get);
    assert(ret == 0);
    assert(CPU_ISSET(id, &get));

    loop();
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        usage();
    }

    processors = sysconf(_SC_NPROCESSORS_CONF);
    int *cpu_id = (int *)malloc(sizeof(int) * processors);
    int thd_cnt = argc - 2, i = 0;
    int ret = 0;
    pthread_t tid;

    percentage = atoi(argv[1]);

    for (i = 0; i < thd_cnt; ++i) {
        cpu_id[i] = atoi(argv[i + 2]);
        if (cpu_id[i] < processors) {
            ret = pthread_create(&tid, NULL, eat_cpu, &cpu_id[i]);
            assert(ret == 0);
        }
    }

    pause();
}

