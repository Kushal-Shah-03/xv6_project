# XV6 Scheduling Algorithms

The report contains explanation about the implementation of the two implemented scheduling algorithms, FCFS (First Come First Sever) and MLFQ(Multi Level Feedback Queue), in the xv6 operating system.

## FCFS (First Come First Sever)

### Description of the Algorithm

FCFS is the scheduling algorithm in which the process the process with the lowest creation time (creation time refers to the tick number when the process was created) gets selected and scheduled. The process will run until it no longer needs CPU time. Thus this scheduler is non-preemptive.
### Implementation

To implement FCFS in xv6:

1. Introduced a variable (ctime) in the "struct proc" (found in proc.h) that will store the time of creation of the process (more specifically the tick of creation of the process).

2. Inside proc.c in void scheduler() function, select the process with the least creation time (ctime) by checking the creation time of all "RUNNABLE" processes, then execute the process, similar to how it was done in RR (Round Robin), by acquiring it's lock, setting it's state to "RUNNING", setting the process as the proc of the cpu, calling swtch function, and once it returns, again setting the proc of the cpu to 0 and releasing the lock on the process.

3. Then to make the scheduler non-preemptive, In trap.c, we will not run yield() in kernal and user trap. (This prevents the CPU from taking control after every tick, and the control will only be given back one process finishes executing)

NOTE: To run FCFS, run "make qemu SCHEDULER=FCFS"

## MLFQ (Multi Level Feedback Queue)

### Descritpion of the Algorithm

MLFQ is the scheduling algorithm in which the processes are moved between different priority queues based on their behaviour and CPU bursts. The processes with the highest priority get scheduled ( inRound Robin format from the highest priority queue). If a process consumes more CPU time than allocated for the current priority queue, then it is pushed to a lower priority queue. This will allow I/O bound and interactive processes to be present in the higher priority queues. To prevent starvation for the processes in the lower priority queues, one implements againg in MLFQ. MLFQ is a preemptive scheduler.

### Implementation

To implement MLFQ in xv6:

1. Introduce the following variables in struct proc in proc.c, these will help to store the required information about the process, to implement MLFQ

   - int nque; -  queue number
   - int quetick; - runtime in that queue (resets everytime process changes queue or another process get's scheduled)
   - int wtime; - the time (in ticks) elapsed since the last time the process ran

2. In void scheduler() in proc.c check for the highest priority occupied queue, by iterating through the proc array, trying to find the queue with the queue indexed 0 (max priority), and so on till we find a runnable process with the lowest priority in the queue, execute it, when the process get's preempted and comes back, again check if there is any other process with higher priority, if not execute the process again.

3. In void update_time() in proc.c check for if the process is runnable increment it's wtime, else set wtime of the process 0, also if the process is running, then increment it's quetick.

4. In trap.c check if any runnable process, has exceeded the aging time (in this case set to 30, by comparing wtime of the process with 30), if it has, set it's wtime to 0 and decrease it's priority (by moving it to lower priority queue), also check if the current running process, has exceeded the time slice corresponding to it's current priority queue (by comparing quetick with the time slice) (i,e 1 tick for queue 0 (max priority), 3 ticks for queue 1, 9 ticks for queue 2, 15 ticks for queue 3), if it has then set quetick of that process to 0 and push it to lower priority queue (unless it's in queue 3 in that case don't push it lower)
    
NOTE: To run MLFQ, run "make qemu SCHEDULER=MLFQ"

### Comparing Run time and Wait time between schedulers (For CPUS=1)

On running schedulertest

- RR - Rtime = 16 Wtime = 166
- MLFQ - Rtime = 18 Wtime = 169
- FCFS - Rtime = 20 Wtime = 137 

FCFS has the lowest wtime, this is because it schedules the process that arrive earlier, leading to less wtime as they get executed quicker.

Thus FCFS has less responsiveness, but better turnaround time.

MLFQ and RR have better responsiveness but higher turnaround times, this also leads to slighlty more rtime's in both MLFQ and RR, and more wtime as all processes wait more.

In this example MLFQ and RR have similar outputs for wtime, because all processes are taking roughly same time to complete, and using MLFQ doesn't make much change in resposne time and turaround time in this case.

Normally MLFQ attempts to strive a balance between the high turnaround time and low response time of RR and low turnaround time and high response time for FCFS, but in this case it's similar, due to the given example.




    
    
