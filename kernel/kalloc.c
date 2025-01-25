// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

// char类型指针可以进行加减运算，且char字节为1，所以每次加减大小为1.
extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
  struct run *next;
};

struct
{
  struct spinlock lock;
  struct run *freelist;
} kmem;

// 初始化物理内存空间
void kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void *)PHYSTOP);
}

// 初始化
void freerange(void *pa_start, void *pa_end)
{
  char *p;                                 // type
  p = (char *)PGROUNDUP((uint64)pa_start); // PGROUNDUP: round up to the next page 向上取整一个页的大小位置
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
// 释放一个物理页
void kfree(void *pa)
{
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP) // 判断异常，pa所指的地址不是页的起始地址或者pa所指的地址越界
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE); // 用1填充一页

  r = (struct run *)pa; // 将pa强制转换成一个run类型的指针，只会改变解释方式，不会改变实际内容（即指向的还是同一个地址）。%p打印指针地址(16进制)--void*类型

  // 头插法
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
// 分配一个页
void *
kalloc(void)
{
  struct run *r;

  // 从freelist中分配一个页
  acquire(&kmem.lock);
  r = kmem.freelist;
  if (r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
  return (void *)r;
}
