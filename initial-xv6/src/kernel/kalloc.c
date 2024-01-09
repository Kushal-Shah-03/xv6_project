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

struct run {
  struct run *next;
};

// #ifndef KMEM
// #define KMEM
struct KMEM kmem;
// #endif
int cow_count[PHYSTOP / PGSIZE];

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  for (int i=0;i<PHYSTOP/PGSIZE;i++)
  {
    acquire(&kmem.lock);
    cow_count[i]=-1;
    release(&kmem.lock);
  }
  freerange(end, (void*)PHYSTOP);  
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    {
      acquire(&kmem.lock);
    if(p < end || (uint64)p >= PHYSTOP)
    {
      panic("C");
    }
      // if (PA2PTE(p)&PTE_COW)
      // cow_count[(uint64)p >> PGSHIFT]=-1;
      release(&kmem.lock);
      kfree(p);
    }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");
  acquire(&kmem.lock);
  if (cow_count[(uint64)pa >> PGSHIFT]>-1)
  {
    cow_count[(uint64)pa >> PGSHIFT]--;
    if (cow_count[(uint64)pa >> PGSHIFT]==0)
    {
      cow_count[(uint64)pa >> PGSHIFT]=-1;
    }
    release(&kmem.lock);
    return;
    // printf("%d\n",cow_count[(uint64)pa >> PGSHIFT]);
    // panic("kfree_cowcount");
  }
  release(&kmem.lock);
  
  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    {
      kmem.freelist = r->next;
      cow_count[(uint64)r >> PGSHIFT] = -1;                   
      // if (PA2PTE((char*)r) & PTE_COW)
      // {
      //   panic("Galat");
      //   cow_count[(uint64)r >> PGSHIFT] = -1; 
      // }
    }
  release(&kmem.lock);

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
