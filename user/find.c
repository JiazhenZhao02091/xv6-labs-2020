#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

// 返回path路径指向的文件名称
char *fmtname(char *path);
int find(char *path, char *name, int flag);
// find dir name
int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        fprintf(2, "Usage: find dir name\n");
        exit(1);
    }
    // find dir name
    char *dir = argv[1];  // dir
    char *name = argv[2]; // name

    if (find(dir, name, 0) == -1)
        printf("\n");

    exit(0);
}
// 在 path 寻找 name 的文件
int find(char *path, char *name, int flag) // flag == 0 --> 目录为 ./..
{

    int x = 0; // false
    char buf[512], *p;
    int fd;
    struct dirent de; // inum、name
    struct stat st;   // 文件信息：inode、大小、链接计数、文件类型

    if ((fd = open(path, 0)) < 0) // 打开 path文件（普通文件 或者 目录文件）
    {
        fprintf(2, "ls: cannot open %s\n", path);
        return -1;
    }

    if (fstat(fd, &st) < 0) // fstat系统调用获取打开文件的状态信息
    {
        fprintf(2, "ls: cannot stat %s\n", path);
        close(fd);
        return -1;
    }

    switch (st.type)
    {

    case T_FILE:
        // printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
        printf("所输入目录名不正确%s\n", fmtname(path));
        break;

    case T_DIR:
        // printf("T_DIR\n");
        if (strlen(path) + 1 + DIRSIZ + 1 > sizeof buf)
        {
            printf("ls: path too long\n");
            break;
        }
        strcpy(buf, path);
        p = buf + strlen(buf); // p 指向 buf
        *p++ = '/';

        while (read(fd, &de, sizeof(de)) == sizeof(de)) // 每次读一个 de 结构体 即读取一个文件
        {
            if (de.inum == 0)
                continue;

            // p指针位置未改变,保证了每次只会添加一个文件路径
            // DIRSIZE 保证了目录项的最大长度
            memmove(p, de.name, DIRSIZ); // dest src size // 移动de位置到p末尾，即buf末尾
            p[DIRSIZ] = 0;

            if (stat(buf, &st) < 0) // stat 函数通过文件路径来获取文件的状态信息
            {
                printf("ls: cannot stat %s\n", buf);
                continue;
            }

            if (st.type == T_DIR)
            {
                if (strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0)
                    continue;
                find(buf, name, 1);
            }
            if (st.type == T_FILE)
            {
                if (strcmp(name, fmtname(buf)) == 0) // 比较文件名
                {
                    x = 1;
                    printf("%s\n", buf);
                }
            }
        }
        break;
    }
    if (x > 0)
    {
        close(fd);
        return 0;
    }
    close(fd);
    return -1;
}
// 返回path路径指向的文件名称
char *fmtname(char *path)
{
    static char buf[DIRSIZ + 1];
    char *p;

    // Find first character after last slash.
    for (p = path + strlen(path); p >= path && *p != '/'; p--)
        ;
    p++;

    // Return blank-padded name.
    if (strlen(p) >= DIRSIZ)
        return p;
    memmove(buf, p, strlen(p));
    // memset(buf + strlen(p), ' ', DIRSIZ - strlen(p));    填充0
    buf[strlen(p)] = 0;
    return buf;
}
