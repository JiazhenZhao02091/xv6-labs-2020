#include "kernel/param.h"
#include "kernel/fcntl.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/riscv.h"
#include "kernel/fs.h"
#include "user/user.h"

// Function declarations

#define MAP_FAILED ((char *) -1)
#define TESTFILE "mmapfile.txt"



void error(char *msg) {
    printf("错误: %s\n", msg);
    exit(1);
}

// 创建测试文件
void create_test_file(char *content, int size) {
  unlink(TESTFILE);
  int fd = open(TESTFILE, O_WRONLY | O_CREATE);
  if (fd < 0) error("无法创建测试文件");
  
  if (write(fd, content, size) != size)
    error("写入测试文件失败");
  
  close(fd);
}

// 基本映射测试
void basic_mapping_test() {
  printf("\n=== 基本内存映射测试 ===\n");
  
  // 创建测试文件
  char content[PGSIZE];
  for (int i = 0; i < PGSIZE; i++)
    content[i] = 'A' + (i % 26);
  create_test_file(content, PGSIZE);
  
  // 打开文件
  int fd = open(TESTFILE, O_RDONLY);
  if (fd < 0) error("无法打开测试文件");
  
  printf("1. 映射文件到内存 (只读)\n");
  char *addr = mmap(0, PGSIZE, PROT_READ, MAP_PRIVATE, fd, 0);
  if (addr == MAP_FAILED) error("mmap失败");
  
  // 验证映射内容
  printf("2. 验证映射内容\n");
  for (int i = 0; i < PGSIZE; i++) {
    if (addr[i] != content[i])
      error("映射内容不匹配");
  }
  printf("   映射内容正确\n");
  
  // 尝试修改只读映射 (应该会失败)
  printf("3. 尝试修改只读映射 (应该会失败)\n");
  // 注意：在实际运行时这会导致段错误，这里跳过实际修改
  printf("   跳过实际修改以避免段错误\n");
  
  // 解除映射
  printf("4. 解除映射\n");
  if (munmap(addr, PGSIZE) < 0)
    error("munmap失败");
  
  close(fd);
  printf("基本映射测试成功\n");
}

// 读写映射测试
void read_write_mapping_test() {
  printf("\n=== 读写映射测试 ===\n");
  
  // 创建测试文件
  char content[PGSIZE];
  for (int i = 0; i < PGSIZE; i++)
    content[i] = '0' + (i % 10);
  create_test_file(content, PGSIZE);
  
  // 打开文件 (读写模式)
  int fd = open(TESTFILE, O_RDWR);
  if (fd < 0) error("无法打开测试文件");
  
  printf("1. 映射文件到内存 (读写)\n");
  char *addr = mmap(0, PGSIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (addr == MAP_FAILED) error("mmap失败");
  
  // 修改映射内存
  printf("2. 修改映射内存\n");
  for (int i = 0; i < 100; i++) {
    addr[i] = 'X';
  }
  
  // 解除映射 (修改应该写回文件)
  printf("3. 解除映射 (修改应该写回文件)\n");
  if (munmap(addr, PGSIZE) < 0)
    error("munmap失败");
  
  close(fd);
  
  // 验证文件内容已被修改
  printf("4. 验证文件内容已被修改\n");
  fd = open(TESTFILE, O_RDONLY);
  if (fd < 0) error("无法打开测试文件");
  
  char buf[PGSIZE];
  if (read(fd, buf, PGSIZE) != PGSIZE)
    error("读取文件失败");
  
  for (int i = 0; i < 100; i++) {
    if (buf[i] != 'X')
      error("文件内容未被正确修改");
  }
  
  close(fd);
  printf("读写映射测试成功\n");
}

// 私有映射测试
void private_mapping_test() {
  printf("\n=== 私有映射测试 ===\n");
  
  // 创建测试文件
  char content[PGSIZE];
  for (int i = 0; i < PGSIZE; i++)
    content[i] = 'a' + (i % 26);
  create_test_file(content, PGSIZE);
  
  // 打开文件
  int fd = open(TESTFILE, O_RDWR);
  if (fd < 0) error("无法打开测试文件");
  
  printf("1. 创建私有映射 (MAP_PRIVATE)\n");
  char *addr = mmap(0, PGSIZE, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);
  if (addr == MAP_FAILED) error("mmap失败");
  
  // 修改映射内存
  printf("2. 修改私有映射内存\n");
  for (int i = 0; i < 100; i++) {
    addr[i] = 'Z';
  }
  
  // 解除映射 (修改不应该写回文件)
  printf("3. 解除映射 (修改不应该写回文件)\n");
  if (munmap(addr, PGSIZE) < 0)
    error("munmap失败");
  
  close(fd);
  
  // 验证文件内容未被修改
  printf("4. 验证文件内容未被修改\n");
  fd = open(TESTFILE, O_RDONLY);
  if (fd < 0) error("无法打开测试文件");
  
  char buf[PGSIZE];
  if (read(fd, buf, PGSIZE) != PGSIZE)
    error("读取文件失败");
  
  for (int i = 0; i < 100; i++) {
    if (buf[i] != 'a' + (i % 26))
      error("文件内容被错误地修改");
  }
  
  close(fd);
  printf("私有映射测试成功\n");
}

// 父子进程共享映射测试
void fork_mapping_test() {
  printf("\n=== 父子进程共享映射测试 ===\n");
  
  // 创建测试文件
  char content[PGSIZE];
  for (int i = 0; i < PGSIZE; i++)
    content[i] = 'A' + (i % 26);
  create_test_file(content, PGSIZE);
  
  // 打开文件
  int fd = open(TESTFILE, O_RDWR);
  if (fd < 0) error("无法打开测试文件");
  
  printf("1. 创建共享映射 (MAP_SHARED)\n");
  char *addr = mmap(0, PGSIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (addr == MAP_FAILED) error("mmap失败");
  
  // 创建子进程
  printf("2. 创建子进程\n");
  int pid = fork();
  if (pid < 0) error("fork失败");
  
  if (pid == 0) {
    // 子进程
    printf("3. 子进程修改映射内存\n");
    for (int i = 0; i < 100; i++) {
      addr[i] = 'C';  // C for Child
    }
    exit(0);
  } else {
    // 父进程
    wait(0);
    
    // 验证子进程的修改在父进程中可见
    printf("4. 验证子进程的修改在父进程中可见\n");
    for (int i = 0; i < 100; i++) {
      if (addr[i] != 'C')
        error("子进程的修改在父进程中不可见");
    }
    
    // 解除映射
    if (munmap(addr, PGSIZE) < 0)
      error("munmap失败");
  }
  
  close(fd);
  printf("父子进程共享映射测试成功\n");
}

// 内存映射原理说明
void explain_mmap() {
  printf("\n=== 内存映射文件原理 ===\n");
  printf("1. mmap系统调用将文件内容映射到进程的虚拟地址空间\n");
  printf("2. 映射类型:\n");
  printf("   - MAP_PRIVATE: 私有映射，修改不会写回文件\n");
  printf("   - MAP_SHARED: 共享映射，修改会写回文件并对其他进程可见\n");
  printf("3. 保护标志:\n");
  printf("   - PROT_READ: 只读访问\n");
  printf("   - PROT_WRITE: 可写访问\n");
  printf("   - PROT_EXEC: 可执行访问\n");
  printf("4. 优势:\n");
  printf("   - 减少内存使用 (按需加载页面)\n");
  printf("   - 避免额外的数据复制\n");
  printf("   - 简化文件I/O操作\n");
  printf("   - 便于进程间共享数据\n");
}

int main() {
  printf("===== 内存映射文件功能展示 =====\n");
  
  basic_mapping_test();
  read_write_mapping_test();
  private_mapping_test();
  fork_mapping_test();
  explain_mmap();
  
  // 清理测试文件
  unlink(TESTFILE);
  
  printf("\n===== 所有测试成功完成 =====\n");
  return 0;
}