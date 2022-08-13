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

char *locknames[] =
    {
        "kmem_cpu_0",
        "kmem_cpu_1",
        "kmem_cpu_2",
        "kmem_cpu_3",
        "kmem_cpu_4",
        "kmem_cpu_5",
        "kmem_cpu_6",
        "kmem_cpu_7",
};

void kinit()
{
  // initlock(&kmem.lock, "kmem");
  for (int i = 0; i < NCPU; i++)
  { // init all lock
    initlock(&kmem[i].lock, locknames[i]);
  }
  freerange(end, (void *)PHYSTOP);
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

  push_off();
  int cpuno = cpuid();
  

  acquire(&kmem[cpuno].lock);
  r->next = kmem[cpuno].freelist;
  kmem[cpuno].freelist = r;
  release(&kmem[cpuno].lock);
  pop_off();

}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  push_off();
  int cpuno = cpuid();
  
  
  acquire(&kmem[cpuno].lock);

  // r = kmem.freelist;
  // if (r)
  //   kmem.freelist = r->next;
  // release(&kmem.lock);

  if(!kmem[cpuno].freelist)
  { // no page left
    int steal = 64; // steal 48 pages from other cpu
   
    for (int i = 0; i < NCPU; i++)
    {
      if (i == cpuno)
        continue; // no self-robbery

      acquire(&kmem[i].lock);
      struct run *tempr = kmem[i].freelist;
      
      while (tempr && steal)
      {
        kmem[i].freelist = tempr->next;//steal one page
        tempr->next = kmem[cpuno].freelist;//set null
        kmem[cpuno].freelist = tempr;
        tempr = kmem[i].freelist;
        steal--;
      }
      
      release(&kmem[i].lock);
      if (steal == 0)
        break; // done stealing
    }
   
  }

  r = kmem[cpuno].freelist;
  if (r) 
     kmem[cpuno].freelist = r->next;
  release(&kmem[cpuno].lock);
  pop_off();
  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
  return (void *)r;
}
