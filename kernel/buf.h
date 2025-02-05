struct buf
{
  int valid; // has data been read from disk? 快是否有效
  int disk;  // does disk "own" buf? 缓存是否进入了磁盘
  uint dev;
  uint blockno;
  struct sleeplock lock;
  uint refcnt;
  struct buf *prev; // LRU cache list
  struct buf *next;
  uchar data[BSIZE];
  int time_stamp; // 时间戳
};
