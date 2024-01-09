#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void usertrap(void)
{
  int which_dev = 0;

  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if (r_scause() == 8)
  {
    // system call

    if (killed(p))
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sepc, scause, and sstatus,
    // so enable only now that we're done with those registers.
    intr_on();

    syscall();
  }
  else if ((which_dev = devintr()) != 0)
  {
    // ok
  }
  else
  {
    if (r_scause() == 15)
    {
      uint64 vir_addr = r_stval();
      int flag1 = 0;
      if (vir_addr >= MAXVA)
      {
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
        printf("Hi");
        setkilled(p);
        flag1 = 1;
      }
      if (flag1 == 0)
      {
        vir_addr = PGROUNDDOWN(vir_addr);
        pte_t *pte_temp = walk(p->pagetable, vir_addr, 0);
        uint flags = PTE_FLAGS(*pte_temp);
        // printf("L%dL",flags);
        // idk kab error throw karni hai agar valid page na ho tab karenge hi na? ya nahi?
        // if (((*pte_temp & PTE_V) && (*pte_temp & PTE_W))||!(*pte_temp & PTE_V))
        if (((*pte_temp&PTE_COW)==0)&(*pte_temp&PTE_W))
        {
          setkilled(p);
          if (killed(p))
          // return;
          exit(-1);
        }
        if ((*pte_temp & PTE_V) && (*pte_temp & PTE_W))
        {
          // printf("Hi\n");
          printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
          printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
          setkilled(p);
          flag1 = 1;
        }
        if (!(*pte_temp & PTE_V))
        {
          printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
          printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
          setkilled(p);
          flag1 = 1;
        }
        if (((uint64)PTE2PA(*pte_temp) <= KERNBASE || (uint64)PTE2PA(*pte_temp) >= PHYSTOP))
        {
          panic("D");
        }
        if (flag1 == 0)
        {
          if ((*pte_temp & PTE_COW))
          {
            acquire(&kmem.lock);
            if (cow_count[PTE2PA(*pte_temp) >> PGSHIFT] >= 1)
            {
              // acquire(&kmem.lock);
              --cow_count[PTE2PA(*pte_temp) >> PGSHIFT];
              if (cow_count[PTE2PA(*pte_temp) >> PGSHIFT] == 0)
              {
                cow_count[PTE2PA(*pte_temp) >> PGSHIFT] = -1;
                // *pte_temp = *pte_temp | PTE_W;
                // printf("M");
                // *pte_temp &= ~PTE_COW;
              }
              release(&kmem.lock);
              flags = flags | PTE_W;
              flags &= ~PTE_COW;
              uint64 phy_addr = PTE2PA(*pte_temp);
              char *mem = kalloc();
              if (mem == 0)
              {
                // uvmdealloc(pagetable, a, oldsz);
                // return 0;
                // *pte_temp|=PTE_V;
                setkilled(p);
                exit(-1);
                // panic("Kalloc failed");
              }
              if (*pte_temp & PTE_V)
               {} // *pte_temp &= ~PTE_V;
              else
              {
                setkilled(p);
                exit(-1);
              }
              memmove(mem, (char *)phy_addr, PGSIZE);
              // printf("a");
              if (mappages(p->pagetable, vir_addr, PGSIZE, (uint64)mem, flags)!=0)
              {
                setkilled(p);
                exit(-1);
              }
              // *pte_temp = *pte_temp | PTE_V;
            }
            else
            {
              *pte_temp = *pte_temp | PTE_W;
              *pte_temp &= ~PTE_COW;
              release(&kmem.lock);
            }
          }
          else
          {
            setkilled(p);
            // panic("Error");
          }
        }
      }
      // I don't think we need to do but let's see

      // if (count==1)
      // {
      //   acquire(&kmem.lock);

      //   release(&kmem.lock);
      //   *pte_temp=*pte_temp|PTE_W;
      // }
      // Parent page is set as writable only, when all other COW's with it are also set as writable
      // Idhar copy mem to the page somehow either map it idk
      // memmove(mem,(char*)P2V(vir_addr),PGSIZE);
      // *pte_temp = V2P(mem) | PTE_U | PTE_W;
      // return 0;
      // }
    }
    else
    {
      // for (p = proc; p < &proc[NPROC]; p++)
      // {
      //   if (p->state == UNUSED)
      //     continue;
      //   printf("%d %s %s %d", p->pid, p->state, p->name,p->SP);
      //   for(int i = 0; i < p->sz; i += PGSIZE)
      //   {
      //     pte_t* pte =walk(p->pagetable,i,0);
      //     acquire(&kmem.lock);
      //     printf("a%db%dc",cow_count[PTE2PA(*pte) >> PGSHIFT],*pte&PTE_U);
      //     release(&kmem.lock);

      //   }
      //   printf("\n");
      // }
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
      setkilled(p);
    }
    sfence_vma();
    // Ig add ref count as well idk

    // Errors
  }

  if (killed(p))
    exit(-1);

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2)
    yield();

  usertrapret();
}

//
// return to user space
//
void usertrapret(void)
{
  // printf("Hi\n");
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();

  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if (intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if ((which_dev = devintr()) == 0)
  {
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
  acquire(&tickslock);
  ticks++;
  update_time();
  // for (struct proc *p = proc; p < &proc[NPROC]; p++)
  // {
  //   acquire(&p->lock);
  //   if (p->state == RUNNING)
  //   {
  //     printf("here");
  //     p->rtime++;
  //   }
  //   // if (p->state == SLEEPING)
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
      (scause & 0xff) == 9)
  {
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if (irq == UART0_IRQ)
    {
      uartintr();
    }
    else if (irq == VIRTIO0_IRQ)
    {
      virtio_disk_intr();
    }
    else if (irq)
    {
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
  {
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if (cpuid() == 0)
    {
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  }
  else
  {
    return 0;
  }
}
