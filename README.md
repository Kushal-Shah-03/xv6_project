# Report

## Modified Priority-Based Scheduler in xv-6

#### Introduction
This project involves the implementation of a preemptive scheduler in the xv-6 operating system, which schedules processes on the basis of priority. The scheduler will select the process based on their priority, for this we have implemented two types of priorities: Static Priority (SP) and Dynamic Priority (DP). SP can be defined by the user, the valid ranges from 0 to 100, with lower values indicating higher priority. The default value of SP is set to be 50. DP is determined by the SP and the Recent Behavior Index (RBI), which is the weighted sum of Running Time (RTime), Sleeping Time (STime), and Waiting Time (WTime), the formula is given on the course website. DP is used for scheduling the processes, the process with lower DP, is scheduled first. Tie-breakers have been implemented in the form of number of time's a process has been scheduled, time of creation of process.

#### Assumption
Since, it was slightly unclear, I have assumed that the process with the lower creation time is given priority in case of tie-breaks with other parameters, and similarly the process with the less number of schedules, should be given priority in case of tie-breaks.
Any changes in this assumption , can be achieved just by a simple change of less than greater than signs.

#### Implementation
- Calculating DP

    The formula used to calculate DP is:
    DP = min(SP + RBI, 100)

    while we can calculate RBI using the following formula:

    p->RBI=(((3*p->Rtime-p->stime-p->wtime)*50)/(p->Rtime+p->wtime+p->stime+1));

- System Call: set_priority()
    Enables users to set the SP of a process. The function declaration is:
        
    int set_priority(int pid, int priority)
    
    Thus we can the priority of the process with the given pid to the priority passed as an argument to the function.

    To do this, we have added parts related to function in syscall.c and sysproc.c, as well as in proc.h,
    inside the function, we get the arguments using argint function, then find the process with the given pid, by iterating through all processes, then we will change it's DP value, corresponding to the new priority entered, note it's RBI is also reset back to 25. Then if the new DP is of higher priority than the old DP, we call yield(), in case this process is now with the lowest priority.


- Struct Proc
    New variables have been added to struct proc, to implement PBS :

    Rtime: Total time the process has been running since it was last scheduled.
    stime: Total time the process has spent sleeping since it was last scheduled.
    wtime: Total time the process has spent waiting in the ready queue.
    
    These attributes are incremented at each tick (inside update time function, depending on if the process is sleeping running or runnable), and once a process is scheduled, they are reset to 0, except for wtime.

#### Results and Analysis
The PBS scheduler is implemented to improve task execution by considering a static priority as well as the recent behavior of processes. The set_priority() system call enables users with control over the SP of their processes.

The SP enables users to set a base priority, allowing users to choose which processes to place at higher priorities thus setting importance of a process. On the other hand, the recent behaviour, is calculated taking into consideration various parameters like Rtime, wtime, and stime, this enables the introduction of a dynamic element to the prioritization. By taking into consideration the recent behavior of processes. This approach ensures that processes exhibiting varying levels of activity, sleep, and waiting times are appropriately prioritized based on their real-time characteristics, and helps prevent starvation of processes, as well as obtaining a balance turnaround and response time in an ideal scenario.

Since, as the processes, get scheduled their wtime reaches a very high value overtime, and this makes RBI<0 and for an RBI value <0 we , set RBI to 0, so overtime only the SP suggested, by the user, takes effect, but initially, the wtime,stime and Rtime play a role in dynamically adjusting priorities, I tried two test cases, the lines for those are commented in schedulertests, and these testcases fit the expected result of PBS.

Average rtime 18,  wtime 138 for one CPU
Average rtime 14,  wtime 116 for multiple CPU's

## Cafe Sim Report

#### Implementation Details
The task was to simulate a small cafe, given the constraints specified in the project document, by using multi-threading concepts to simulate the cafe effeciently, The code uses semaphores and mutex locks to ensure thread safety and to avoid  deadlocks. I have considered each customer as a separate thread, while each barista is accounted for using a semaphore to limit the number of concurrent orders being processed, and then maintaining which barista is completing an order in an array, guarded by mutex locks.

#### Thread Structure
Each customer thread simulates the entire order process. The barista are controlled using semaphores to prevent overloading and ensure orderly processing of orders. Mutex locks are used to synchronize access to shared resources. The customer thread, is initiated after the arrival of a customer, and it then waits on a barista, using sem_timedwait fxn, with time as it's tolerance time, if it runs out of tolerance, then it prints that the customer left, and posts to baristas, while if it gets a sem_post it will find the lowest index barista, by iterating through the semaphores, and sets that barista to occupied, and now it will wait till either it's tolerance runs, out leading to the wastage of that coffee, or it takes that order and leaves, the timings are synchornized using sleep, and to ensure the threads function in indexed, order, they are queued one after the other in sem_timedwait(), the inherent queue of this function, ensures the indexing.

#### Color Coding

To ensure readability of code, we have implemented, color code, as stated in the project document

#### Questions

Average wait time and Coffee's wasted are calculated in the code itself, and it will differ from testcase to testcase
- If the cafe had infinite barrista's then the waiting time is always one, as they only wait for one second, the time difference between their arrival and the barrista taking up the order
- If the cafe had infinite barrista's then the number of coffee's wasted could either increase or decrease, in an idealistic scenario, if the tolerance time of a customer is atleast as much time as it will minimum take for the coffee to be prepared, then the number of coffee's wasted would be zero, but let's say a situation where all customers have less tolerance time, than time of preparation, in this case all coffee's would get wasted.


## Ice Cream Parlor Sim

#### Assumption

In Ice-Cream parlour, if the Ice cream parlour, instantly rejects the customer, due to unavilability of ingredients, then it's spot can immediately be filled by another customer, but if a machine rejected the customer's order, due to unavailability of ingredients, then the spot can be filled at the t+1'th second as asked in the question.
I have tried to follow all the constraints specified, in the doubts document, but since there were waay to many questions in the doubt document, I might have missed a case or two.

#### Implementation Details
The task was to simulate a small ice cream parlour, given the constraints specified in the project document, by using multi-threading concepts to simulate the cafe effeciently, The code uses semaphores and mutex locks to ensure thread safety and to avoid  deadlocks. I have considered each ordered as a separate thread, while each machine is accounted for using a semaphore to limit the number of concurrent orders being processed, and then maintaining which machine is completing an order in an array, guarded by mutex locks.

#### Thread Structure
Each order thread simulates the entire order process. The threads are controlled using semaphores to prevent overloading and ensure orderly processing of orders. Mutex locks are used to synchronize access to shared resources. The order thread, is initiated after the arrival of a customer, initially we check if it is possible to satisfy all orders of the customer, then it accepts the customer and then all it's orders are subsequently made into threads, and it then waits on a machine, using  a semaphore array and calling sem_wait() on it's index, with an entry for each order. When a machine, begins working, it will send a signal to the first non-fullfilled order by sem_posting on it, and determines if that machine, can satisfy that order, while checking for ingredient shortage as well, if the machine can fulfill the order, it starts waiting till it's completion, by setting that machine as occupied, and signalling to the machines lock, thus enabling other machines to be checked, if that machine, can't satisfy that order, then that order signals to the next non-fulfilled order in the array and checks if the machine can satisfy it and so on, if it is the last non-fulfilled order, and it can't be satisfied too, then we simply sem_post to machines, and the machine will be checked again at the next tick. Handling other edge cases, as specified in the doubts document, can be seen from the doubts document, I have used enums to make the code slightly more readable, and I have created a couple of helper functions to help identify the next order, and to return a rejected order. If the order is finished, it will print finished, and the thread returns, if all orders of a customer are finished, implemented using a counter in customer struct, we print the customer collects it's orders and leaves.

#### Color Coding

To ensure readability of code, we have implemented, color code, as stated in the project document

#### Questions

1. Minimizing Incomplete Orders:
    - The first step, would be to choose machines not based, on indexed, but by precalculating the scenario, in order to ensure that we can maximise a machines output, and maximise the number of fulfilled orders, since the order of customers, is known we can develop a simple algorithm, which helps us determine a suitable machine for a specific order, to maximise number of orders fulfilled.
    - Order Cancellation: Enable customers to cancel their orders to prevent incomplete orders and enhance customer satisfaction, for this we will need to enable user input, and modify our threads using another semaphore array for each customer, we will still keep the condition, of never stopping a machine mid-order.
    - Prioritize customers with orders that are guaranteed to be fulfilled, if the orders are large, then there is a chance that the order is only partially completed.
  
2. Ingredient Replenishment: 
  - Real-time Supplier Integration: Create a seperate thread to continuosly monitor ingredients which can trigger automatic replenishment orders when ingredients are depleted, below a certain bar and order ingredients accordingly, the order can be placed based on the expected ingredients required, this can be calculated using a simple algorithm.
  - Additionally in case we run out of ingredients, we can accept a few orders, for which ingredients are depleted, if the supplier of the ingredient is just about to arrive with the ingredients, by maintining a lower base time to select those orders.
  
3. Unserviced Orders: 
    - We can ensure that we reserve ingredients for all orders, rather than using up all ingredients on one order, this will lead to less number of unserviced orders, this can easily be implemented by having an upper cap on the number of ingredients to be used in one order.
    - Traffic-based planning: Conduct regular analysis to determine peak hours where more machines can be redistributed to, enable less unserviced orders.
    - We can keep a track of the expected time that the machines will consume to fulfill all pending orders, and then subtract that from the machine stop time and accept orders on the basis of that, rather than just current time and stop time.

