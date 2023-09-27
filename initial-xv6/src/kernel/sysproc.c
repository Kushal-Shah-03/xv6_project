#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sigalarm(void)
{
  // fork might work idk
  // int pid=sys_getpid();
  uint64 handler;
  int interval;
  argint(0, &interval);
  argaddr(1, &handler);
  struct proc *p=myproc();
  if (p->sigticks!=-1)
  {
    printf("Recursive call of sigalarm\n");
    return 0;
  }
  else
  {
    p->sigticks=interval;
    p->sighandler=handler;
  }
  // int ret=fork();
  // if (ret==0)
  // {
  //   // count n ticks somehow
  //   // send signal to pid to stop
  //   // execute fn
  //   // return signal to pid
  // }
  // else
  // {
  //   return 0;
  // }
  return 0;
}

uint64
sigreturn(void)
{
  struct proc* p=myproc();
  memmove(p->trapframe, p->alarmframe, PGSIZE);
  kfree(p->alarmframe);
  // p->alarmframe=0;
  // p->sigticks=-1;
  p->currticks=0;
  p->ishandler=0;
  return p->trapframe->a0;
}