#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int i;
    int j = 0;
    int k;
    int l, m = 0;
    char block[32];
    char buf[32];
    char *p = buf;
    char *lineSplit[32];
    for (i = 1; i < argc; i++)
    {
        lineSplit[j++] = argv[i];
    }
    while ((k = read(0, block, sizeof(block))) > 0)
    {
        for (l = 0; l < k; l++)
        {
            if (block[l] == '\n')
            {
                buf[m] = 0;
                m = 0;
                lineSplit[j++] = p;
                p = buf;
                lineSplit[j] = 0;
                j = argc - 1;
                if (fork() == 0)
                {
                    exec(argv[1], lineSplit);
                }
                wait(0);
            }
            else if (block[l] == ' ')
            {
                buf[m++] = 0;
                lineSplit[j++] = p;
                p = &buf[m];
            }
            else
            {
                buf[m++] = block[l];
            }
        }
    }
    exit(0);
}

// // #define MAXARG       32  // max exec arguments
// #include "kernel/types.h"
// #include "kernel/stat.h"
// #include "kernel/param.h"
// #include "user/user.h"

// /*
//     从标准输入中读取一行 并将其作为命令的参数
//     echo hello | xargs echo world
//                         --> world hello
// */
// int main(int argc, char *argv[]) // xargs echo bye
// {
//     if (argc < 2)
//     {
//         fprintf(2, "Usage: xargs command...\n");
//         exit(1);
//     }
//     // 获取 xargs参数
//     char *params[MAXARG];
//     int maxarg_size = 0;
//     for (int i = 1; i < argc; i++)
//         params[maxarg_size++] = argv[i];

//     int state = 0;
//     int buf_read = 0;
//     while (!state) // 循环n行
//     {
//         // 读取一行
//         char *str;
//         char buf[100]; // 最多读取 100 字节一行
//         while (1)
//         {
//             int flag = read(0, buf + buf_read, 1); // 0 EOF -1 ERROR 别的为实际读取的字节
//             if (flag == -1)                        // 异常情况
//             {
//                 fprintf(2, "ERROR");
//                 exit(1);
//             }

//             if (flag == 0)
//                 exit(0);

//             buf_read += flag;

//             if (buf[buf_read - 1] == '\n') // 遇见了换行符号
//                 break;
//         }

//         str = (char *)malloc(buf_read + 1); // 返回类型为void* 所以需要强制转换

//         memcpy(str, buf, buf_read); // buf 复制到str中
//         str[buf_read] = '\0';
//         // 此时 str 为第一行 即为第一行参数

//         int pid = fork();
//         if (pid != 0)
//             wait(&pid);
//         else if (pid == 0)
//         {
//             params[maxarg_size++] = str; // 一行做一个参数
//             exec(argv[1], params);
//         }
//         free(str);

//         maxarg_size = argc - 1;
//     }

//     exit(0);
// }

// //    每次读取一行直到遇到了 '\n' 然后fork一个子进程执行
