#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int filestream1[2]; // 0 read ; 1 write         父进程 --> 子进程
    int filestream2[2]; // 0 read ; 1 write         子进程 --> 父进程

    if (pipe(filestream1) != 0)
        exit(1);
    if (pipe(filestream2) != 0)
        exit(1);

    int pid = fork();
    if (pid > 0) // 父进程
    {
        // printf("This is father process.\n");
        char *s = "ping";
        write(filestream1[1], s, sizeof(s));
        read(filestream2[0], s, sizeof(s));
        wait(&pid); // 等待子进程结束
        printf("%d: received pong\n", getpid());
        exit(0);
    }
    else if (pid == 0) // 子进程
    {
        // printf("This is child process.\n");
        char *s = "pong";
        write(filestream2[1], s, sizeof(s));
        read(filestream1[0], s, sizeof(s));

        printf("%d: received ping\n", getpid());
        exit(0);
    }
    else
    {
        exit(1); // error
    }
    exit(0);
}

/*
    waitpid() / wait() ： 父进程等待子进程运行结束
*/