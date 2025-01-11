#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
// int sleep(int x)
// {
//     // sle
// }
int main(int argc, char *argv[])
{
    // 参数为 sleep
    if (argc < 2)
    {
        fprintf(2, "Usage: sleep times \n");
        exit(1);
    }
    int time_x = atoi(argv[1]);
    // printf("%s %d \n", argv[1], time_x);
    if (sleep(time_x) < 0)
        fprintf(2, "rm: %s failed to delete\n", argv[0]);

    exit(0); // 正常退出
}