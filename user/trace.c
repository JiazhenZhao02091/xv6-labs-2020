#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// 0     1   2    3      4
// trace 32 grep hello README

int main(int argc, char *argv[])
{
  int i;
  char *nargv[MAXARG];

  if (argc < 3 || (argv[1][0] < '0' || argv[1][0] > '9'))
  {
    fprintf(2, "Usage: %s mask command\n", argv[0]);
    exit(1);
  }

  if (trace(atoi(argv[1])) < 0) // trace system call
  {
    fprintf(2, "%s: trace failed\n", argv[0]);
    exit(1);
  }

  // excute the program.
  for (i = 2; i < argc && i < MAXARG; i++)
  {
    nargv[i - 2] = argv[i]; //  nargv[0] = argv[2]
  }
  exec(nargv[0], nargv);
  exit(0);
}
