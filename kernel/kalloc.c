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
} kmem[NCPU];

void kinit()
{
  char p[7] = "kmem_ ";
  for (int i = 0; i < NCPU; i++)
  {
    p[5] = '0' + i;
    initlock(&kmem[i].lock, p);
  }
  freerange(end, (void *)PHYSTOP); // 初始将所有物理内存分配给一个CPU
  // initlock(&kmem.lock, "kmem");
  // freerange(end, (void *)PHYSTOP);
}

void freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char *)PGROUNDUP((uint64)pa_start);
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run *)pa;

  push_off(); // 关中断

  int id = cpuid(); // 获取当前CPU的ID
  acquire(&kmem[id].lock);
  r->next = kmem[id].freelist;
  kmem[id].freelist = r;
  release(&kmem[id].lock);

  pop_off(); // 开中断
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  push_off();       // 关中断
  int id = cpuid(); // 获取当前CPU的ID

  acquire(&kmem[id].lock);
  r = kmem[id].freelist;
  if (r)
    kmem[id].freelist = r->next;
  else
  {
    for (int i = 0; i < NCPU; i++)
    {
      if (i == id)
        continue;
      acquire(&kmem[i].lock);
      if (kmem[i].freelist)
      {
        r = kmem[i].freelist;
        kmem[i].freelist = r->next; // r未变
        release(&kmem[i].lock);
        break;
      }
      release(&kmem[i].lock);
    }
    // 下次再次进入该CPU时，当前进程仍然没有空闲
    // if (r)
    //   kmem[id].freelist = r->next; // 如果更改指针，则两个CPU将会共用一个freelist，违背了初始目的
  }
  release(&kmem[id].lock);

  pop_off(); // 开中断

  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
  return (void *)r;
}
