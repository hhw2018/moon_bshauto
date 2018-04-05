#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>
#include <pthread.h>

/* One thread eats MAX_MEM_CNT G memory at most */
#define MAX_MEM_CNT 2

/* One process create MAX_THD_CNT threads at most */
#define MAX_THD_CNT 10

static pthread_mutex_t mutex;

void usage() {
    printf("Usage: eat_mem mem_size\n");
    printf("  mem_size: Amount of memory space to be filled(unit: MB).\n");
    exit(1);
}

void * eat_mem (void *arg) {
    int cnt = *(int *)arg;
    int granularity = 1;
    int loop_cnt = 0, mem_cnt = 0;
    int i=0;
    char **mem = NULL;

    if (cnt > 1024) {
        granularity = 20;
    } else if (cnt > 100) {
        granularity = 10;
    }
    
    loop_cnt = cnt / granularity;
    loop_cnt = (loop_cnt>0 ? loop_cnt : 1);
    mem_cnt  = cnt / loop_cnt;
    mem = (char **)malloc(sizeof(char*) * loop_cnt);

    while (loop_cnt-- > 0) {
        mem[i] = (char *)malloc(sizeof(char) * granularity * 1024 * 1024);
        memset((void*)mem[i++], 0xff, sizeof(char)*granularity*1024*1024);
    }

    /* Wait here, never return. */
    pthread_mutex_lock(&mutex);
    printf("Never come here.\n");
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        usage();
    }

    int ret = pthread_mutex_init(&mutex, NULL);
    assert(ret == 0);

    int cnt = atoi(argv[1]);
    int g_cnt = cnt / (MAX_MEM_CNT  * 1024);
    int mem_cnt = 0;
    pthread_t tid;

    g_cnt = (g_cnt>MAX_THD_CNT ? MAX_THD_CNT : (g_cnt>0?g_cnt:1));
    mem_cnt = cnt / g_cnt;

    pthread_mutex_lock(&mutex);

    while (g_cnt-- > 0) {
        pthread_create(&tid, NULL, eat_mem, (void*)&mem_cnt);
    }

    pause();
}

