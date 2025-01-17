#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

// 返回path指向的文件名称
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
  // 除了 DIRSIZE 之外的剩余空间被置为空
  // 指针指向某一内存区域 填充的数据 填充给的字节数
  // buf 指向数组首部(char型指针)
  memset(buf + strlen(p), ' ', DIRSIZ - strlen(p));
  return buf;
}

void ls(char *path)
{
  char buf[512], *p;
  int fd;
  struct dirent de; // 目录项  inode编号 + 文件名称
  struct stat st;   // 文件信息：inode、大小、链接计数、文件类型

  if ((fd = open(path, 0)) < 0) // 打开path路径指定的文件
  {
    fprintf(2, "ls: cannot open %s\n", path);
    return;
  }

  if (fstat(fd, &st) < 0) // fstat系统调用获取打开文件的状态信息
  {
    fprintf(2, "ls: cannot stat %s\n", path);
    close(fd);
    return;
  }

  switch (st.type)
  {
  case T_FILE: // 如果ls普通文件
    printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
    break;

  case T_DIR: // 目录文件中存储的都是文件名称？
    if (strlen(path) + 1 + DIRSIZ + 1 > sizeof buf)
    {
      printf("ls: path too long\n");
      break;
    }

    strcpy(buf, path);
    p = buf + strlen(buf);
    *p++ = '/';

    while (read(fd, &de, sizeof(de)) == sizeof(de)) // 每次读一个 de 大小
    {
      if (de.inum == 0)
        continue;

      memmove(p, de.name, DIRSIZ); // dest src size // 复制读取到的文件名称

      p[DIRSIZ] = 0;

      if (stat(buf, &st) < 0) // stat 函数通过文件路径来获取文件的状态信息
      {
        printf("ls: cannot stat %s\n", buf);
        continue;
      }

      printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
}

// ls
int main(int argc, char *argv[])
{
  int i;

  if (argc < 2) // 0 1
  {
    ls("."); // 默认 只有1个参数 此时 为 ls
    exit(0);
  }
  for (i = 1; i < argc; i++)
    ls(argv[i]);
  exit(0);
}
