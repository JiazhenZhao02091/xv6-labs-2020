// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.

#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

#define NBUCKET 13
#define HASH(i) (i % NBUCKET)
#define prin printf("---.\n")

// 链表法解决冲突
struct hashbuf
{
  struct buf head;      // 头节点
  struct spinlock lock; // 锁
};

// 匿名结构体
struct
{
  struct buf buf[NBUF];
  struct hashbuf buckets[NBUCKET];
  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
} bcache;

void binit(void)
{
  struct buf *b;
  char lockname[16];

  for (int i = 0; i < NBUCKET; ++i)
  {
    // 初始化散列桶的自旋锁
    snprintf(lockname, sizeof(lockname), "bcache_%d", i);
    initlock(&bcache.buckets[i].lock, lockname);

    // 初始化散列桶的头节点
    bcache.buckets[i].head.prev = &bcache.buckets[i].head;
    bcache.buckets[i].head.next = &bcache.buckets[i].head;
  }

  // Create linked list of buffers
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
  {
    // 利用头插法初始化缓冲区列表,全部放到散列桶0上
    b->next = bcache.buckets[0].head.next;
    b->prev = &bcache.buckets[0].head;
    initsleeplock(&b->lock, "buffer");
    bcache.buckets[0].head.next->prev = b;
    bcache.buckets[0].head.next = b;
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf *
bget(uint dev, uint blockno)
{
  struct buf *b;

  int id_b = HASH(blockno);
  acquire(&bcache.buckets[id_b].lock);

  for (b = bcache.buckets[id_b].head.next; b != &bcache.buckets[id_b].head; b = b->next)
  {
    if (b->dev == dev && b->blockno == blockno)
    {
      b->refcnt++;

      acquire(&tickslock);
      b->time_stamp = ticks;
      release(&tickslock);

      release(&bcache.buckets[id_b].lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  b = 0;
  int cycle = 0, t = id_b;
  struct buf *tmp;

  for (; cycle != NBUCKET; t = (t + 1) % NBUCKET)
  {
    cycle++;
    // 防止持有两个锁
    if (t != id_b)
    {
      if (!holding(&bcache.buckets[t].lock))
        acquire(&bcache.buckets[t].lock);
      else
        continue;
    }

    // 使用时间戳
    for (tmp = bcache.buckets[t].head.next; tmp != &bcache.buckets[t].head; tmp = tmp->next)
      if (tmp->refcnt == 0 && (b == 0 || tmp->time_stamp < b->time_stamp))
        b = tmp;

    if (b != 0)
    {
      // 插入到自己的桶中
      if (t != id_b)
      {
        b->next->prev = b->prev;
        b->prev->next = b->next;
        release(&bcache.buckets[t].lock);

        b->next = bcache.buckets[id_b].head.next;
        b->prev = &bcache.buckets[id_b].head;
        bcache.buckets[id_b].head.next->prev = b;
        bcache.buckets[id_b].head.next = b;
      }

      b->dev = dev;
      b->blockno = blockno;
      b->valid = 0;
      b->refcnt = 1;

      acquire(&tickslock);
      b->time_stamp = ticks;
      release(&tickslock);

      release(&bcache.buckets[id_b].lock);
      acquiresleep(&b->lock);
      return b;
    }
    else
    {
      // 释放对应桶的锁
      if (t != id_b)
        release(&bcache.buckets[t].lock);
    }
  }

  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf *
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if (!b->valid)
  {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void bwrite(struct buf *b)
{
  if (!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.  而不是放弃该buffer，只是刚刚使用完
// Move to the head of the most-recently-used list.
void brelse(struct buf *b)
{
  if (!holdingsleep(&b->lock))
    panic("brelse");

  int id_b = HASH(b->blockno);

  releasesleep(&b->lock);

  acquire(&bcache.buckets[id_b].lock);

  b->refcnt--;
  acquire(&tickslock);
  b->time_stamp = ticks;
  release(&tickslock);

  release(&bcache.buckets[id_b].lock);
}

void bpin(struct buf *b)
{
  int id_b = HASH(b->blockno);
  acquire(&bcache.buckets[id_b].lock);
  b->refcnt++;
  release(&bcache.buckets[id_b].lock);
}

void bunpin(struct buf *b)
{
  int id_b = HASH(b->blockno);
  acquire(&bcache.buckets[id_b].lock);
  b->refcnt--;
  release(&bcache.buckets[id_b].lock);
}
