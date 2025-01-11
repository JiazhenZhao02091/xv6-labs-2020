// Mutual exclusion lock.
struct spinlock
{
  uint locked; // Is the lock held?

  // For debugging:
  char *name;      // Name of lock. 锁的名称
  struct cpu *cpu; // The cpu holding the lock.
};
