#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "spinlock.h"
#include "proc.h"

// typedef uint64 pte_t;
// typedef uint64 *pagetable_t; // 512 PTEs // pagetable_t is a pointer.
/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable; // 内核的页表

extern char etext[]; // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

/*
 * create a direct-map page table for the kernel.
 * 创建一个直接映射的页表对于内核.
 */
void kvminit()
{
  kernel_pagetable = (pagetable_t)kalloc(); // 获取一个physical页来存放页表
  memset(kernel_pagetable, 0, PGSIZE);

  // 添加内核页表映射
  // kvmmap va pa size perm
  // uart registers
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // CLINT
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);

  // PLIC
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
}

// 创建一个新的内核页表
pagetable_t kvminit_2(void)
{
  // 获取一个用户页表
  pagetable_t pt = uvmcreate();
  if (pt == 0)
    return 0;

  // 添加用户页表映射
  uvmmap(pt, UART0, UART0, PGSIZE, PTE_R | PTE_W);
  uvmmap(pt, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
  uvmmap(pt, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
  uvmmap(pt, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
  uvmmap(pt, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
  uvmmap(pt, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
  uvmmap(pt, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  return pt;
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
  w_satp(MAKE_SATP(kernel_pagetable));
  sfence_vma(); // 刷新TLB
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if (va >= MAXVA)
    panic("walk");

  for (int level = 2; level > 0; level--)
  {
    pte_t *pte = &pagetable[PX(level, va)]; // 分离指针比特位
    if (*pte & PTE_V)                       // 判断有效位
    {
      // 从页表项中提取物理地址
      pagetable = (pagetable_t)PTE2PA(*pte); // pte -> pa //找了一级的页表项
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }

  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0); // address of the PTE.
  if (pte == 0)
    return 0;
  if ((*pte & PTE_V) == 0)
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte); // 将 pte --> pa
  return pa;
}

//-----------------

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void kvmmap(uint64 va, uint64 pa, uint64 sz, int perm)
{
  if (mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// add a mapping to the pagetable .
void uvmmap(pagetable_t pagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if (mappages(pagetable, va, sz, pa, perm) != 0)
    panic("uvmmap");
}

// translate a kernel virtual address to
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned. // 假设va是页对齐的。
uint64 kvmpa(uint64 va)
{
  uint64 off = va % PGSIZE;
  pte_t *pte;
  uint64 pa;

  pte = walk(myproc()->kernel_pagetable, va, 0);
  // pte = walk(kernel_pagetable, va, 0);

  if (pte == 0)
    panic("kvmpa");
  if ((*pte & PTE_V) == 0)
    panic("kvmpa");
  pa = PTE2PA(*pte);
  return pa + off;
}

/*
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa.
// va and size might not be page-aligned.
// Returns 0 on success, -1 if walk() couldn't allocate a needed page-table page.
// 为从va开始的虚拟地址创建指向从pa开始的物理地址的PTE。
// 映射
  PTE: va --> pa (page)
*/
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) // perm: 权限
{
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va); // va 向下取整到页的整数倍
  last = PGROUNDDOWN(va + size - 1);
  for (;;)
  {
    if ((pte = walk(pagetable, a, 1)) == 0) // 找a对应的页的页表项的地址  address of the PTE.
      return -1;
    if (*pte & PTE_V)
      panic("remap");                 // 重复映射
    *pte = PA2PTE(pa) | perm | PTE_V; // 设置 pte : 地址,权限,有效位
    if (a == last)                    // 判断是否映射结束 从 a 到 end
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// 移除n个映射页,从va开始的,且va必须是页对齐的。映射必须存在。
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if (do_free)
    {
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa); // 使用kfree函数释放物理页
    }
    *pte = 0; // 设置为0就是释放页表项了,即va对应的页表项设置为0
  }
}

// 创建一个新的页表
// create an empty user page table.
// returns 0 if out of memory.
pagetable_t uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
  if (pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if (sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
  memmove(mem, src, sz);
}

// 分配物理内存和PTEs，以将进程从oldsz增长到newsz，newsz不需要对齐到页。返回新的大小或错误时为0。
// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64 uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if (newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for (a = oldsz; a < newsz; a += PGSIZE)
  {
    mem = kalloc();
    if (mem == 0)
    {
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
    memset(mem, 0, PGSIZE);
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W | PTE_X | PTE_R | PTE_U) != 0)
    {
      kfree(mem);
      uvmdealloc(pagetable, a, oldsz);
      return 0;
    }
  }
  return newsz;
}

// 释放用户页，以将进程大小从oldsz减小到newsz。oldsz和newsz不需要对齐到页，newsz不需要小于oldsz。
// oldsz可以大于实际进程大小。返回新的进程大小。
// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64 uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if (newsz >= oldsz)
    return oldsz;

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
  {
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages. 递归的释放页表页
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
  {
    pte_t pte = pagetable[i];                                  // 访问第 i 个页表pte，每个pte64bit
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0) // 最后一层页表中页表项中W位，R位，X位起码有一位会被设置为1
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte); // 不是最低一级的页表，继续递归释放页表项
      freewalk((pagetable_t)child);
      pagetable[i] = 0; // 释放页表项
    }
    else if (pte & PTE_V)
    {
      panic("freewalk: leaf");
    }
  }
  kfree((void *)pagetable); // 释放一整页，这个页里面存放是的是页表项--页表
}

// print page-info
static char *paths[] = {"..", ".. ..", ".. .. .."};
void vmprint(pagetable_t pagetable) // pt是个地址？对！
{
  printf("page table %p\n", (void *)pagetable);
  print_pagetable(pagetable, 0);
  // printf("vmprint 结束\n");
  // for (int i = 0; i < 512; i++)
  // {
  //   pte_t pte = pagetable[i]; // pagetable + i;
  //   if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
  //   {
  //     // this PTE points to a lower-level page table.
  //     uint64 child = PTE2PA(pte); // 不是最低一级的页表，继续递归释放页表项 child是一个物理地址
  //     printf("  %d: pte %p pa %p\n", i, (void *)pte, (void *)child);
  //     vmprint((pagetable_t)child);
  //     pagetable[i] = 0;
  //   }
  //   else if (pte & PTE_V)
  //   {
  //     printf("  %d: pte %p pa %p\n", i, (void *)pte, (void *)PTE2PA(pte));
  //   }
  // }
}

void print_pagetable(pagetable_t pt, uint64 flag)
{
  if (flag > 2)
    return;
  for (int i = 0; i < 512; i++)
  {
    pte_t pte = pt[i];
    if (pte & PTE_V)
    {
      printf("%s%d: pte %p pa %p\n", paths[flag], i, (void *)pte, (void *)PTE2PA(pte));
      uint64 child = PTE2PA(pte); // 不是最低一级的页表，继续递归释放页表项
      print_pagetable((pagetable_t)child, flag + 1);
    }
  }
}

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
  if (sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
}

// 给定父进程的页表，将其内存复制到子进程的页表中。
// Given a parent process's page table, copy
// its memory into a child's page table.
// 复制包括页表和物理内存你
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for (i = 0; i < sz; i += PGSIZE)
  {
    if ((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if ((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char *)pa, PGSIZE);
    if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)
    {
      kfree(mem);
      goto err;
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// 标记一个PTE为用户访问无效。被exec用于用户堆栈保护页。
// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;

  pte = walk(pagetable, va, 0);
  if (pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

// 从内核复制到用户空间。复制len字节从src到在给定的页表中的虚拟地址dstva。
// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
  {
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n; // src 未做映射.
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// 从用户复制到内核空间。复制len字节从在给定的页表中的虚拟地址srcva到dst。
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  return copyin_new(pagetable, dst, srcva, len);

  /* uint64 n, va0, pa0;

   while (len > 0)
   {
     va0 = PGROUNDDOWN(srcva);
     pa0 = walkaddr(pagetable, va0);
     if (pa0 == 0)
       return -1;
     n = PGSIZE - (srcva - va0);
     if (n > len)
       n = len;
     memmove(dst, (void *)(pa0 + (srcva - va0)), n);

     len -= n;
     dst += n;
     srcva = va0 + PGSIZE;
   }
   return 0;
   */
}

// 复制一个null结尾的字符串从用户到内核。复制字节到dst从虚拟地址srcva在给定的页表中，直到一个'\0'，或max。
// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  return copyinstr_new(pagetable, dst, srcva, max);
  /*
    uint64 n, va0, pa0;
    int got_null = 0;

    while (got_null == 0 && max > 0)
    {
      va0 = PGROUNDDOWN(srcva);
      pa0 = walkaddr(pagetable, va0);
      if (pa0 == 0)
        return -1;
      n = PGSIZE - (srcva - va0);
      if (n > max)
        n = max;

      char *p = (char *)(pa0 + (srcva - va0));
      while (n > 0)
      {
        if (*p == '\0')
        {
          *dst = '\0';
          got_null = 1;
          break;
        }
        else
        {
          *dst = *p;
        }
        --n;
        --max;
        p++;
        dst++;
      }

      srcva = va0 + PGSIZE;
    }
    if (got_null)
    {
      return 0;
    }
    else
    {
      return -1;
    }
    */
}

void u2kvmcopy(pagetable_t pagetable, pagetable_t kernelpt, uint64 oldsz, uint64 newsz)
{
  pte_t *pte_from, *pte_to;
  oldsz = PGROUNDUP(oldsz);
  for (uint64 i = oldsz; i < newsz; i += PGSIZE)
  {
    if ((pte_from = walk(pagetable, i, 0)) == 0)
      panic("u2kvmcopy: src pte does not exist");
    if ((pte_to = walk(kernelpt, i, 1)) == 0)
      panic("u2kvmcopy: pte walk failed");
    uint64 pa = PTE2PA(*pte_from);
    uint flags = (PTE_FLAGS(*pte_from)) & (~PTE_U);
    *pte_to = PA2PTE(pa) | flags;
  }
}
