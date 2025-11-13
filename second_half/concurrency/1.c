#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
// #include <sys/time.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <string.h>

typedef struct Coffee{
    char name[1024];
    int time;
}Coffee;

sem_t mutex;
sem_t Bar_sem;
int * Bars;
Coffee* Cof;
int bar;
int total_time=0;
int waste=0;
int fin_count=0;
int w_time=0;

typedef struct Customer{
    int index;
    int t_arr;
    int t_tol;
    int c_id;
    char c_name[1024];
    int bar;
}Customer;

void* consumer(void* arg)
{
    sem_wait(&mutex);
    int time_star=total_time;
    // printf("%d\n",total_time);
    sem_post(&mutex);
    usleep(5000);
    sleep(1);
    struct timespec tol_time;
    Customer* Cust=(Customer*)arg;
    // while(1)
    // {   
        sem_wait(&mutex);
    //     if (time_star!=total_time)
    //     {
            clock_gettime(CLOCK_REALTIME,&tol_time);
            int time_diff=Cust->t_tol-total_time+Cust->t_arr;
            tol_time.tv_sec+=((10000000+tol_time.tv_nsec)/1e9)+time_diff;
            tol_time.tv_nsec=((10000000+tol_time.tv_nsec)%(int)1e9);
            sem_post(&mutex);
            // break;
    //     }
        // sem_post(&mutex);
    // }
    // printf("%d\n",time_diff);
    int s = sem_timedwait(&Bar_sem, &tol_time);
    // printf("a");
    // while (time_star==total_time)
    // {
    //     // time_star++;
    // }
    // int time_since_bar_free=total_time;
    if (s == -1) {
        if (errno == ETIMEDOUT)
            {
                sem_wait(&mutex);
                w_time+=(total_time-Cust->t_arr);
                printf("\033[0;31mCustomer %d leaves without their order at %d second(s)\033[1;0m\n",Cust->index,total_time);
                fin_count++;
                sem_post(&mutex);
                // idk
                // sem_post(&Bar_sem);
                return NULL;
                printf("sem_timedwait() timed out\n");
            }
        else
            perror("sem_timedwait");
    } else
    {
        int wth_time;
        int index=-1;
        sem_wait(&mutex);
        // printf("%d\n",total_time);
        wth_time=total_time;
        for (int i=0;i<bar;i++)
        {
            if (Bars[i]==-1)
            {
                Bars[i]=1;
                index=i;
                sem_post(&mutex);
                break;
            }
        }
        if (index==-1)
        {
            // printf("Hi");
        }
        sem_wait(&mutex);
        if (total_time-time_star==Cust->t_tol||index==-1)
        {
            if (index==-1)
            {
                sem_post(&mutex);
                sleep(1);
                sem_wait(&mutex);
            }
            fin_count++;
            if (Bars[index]==1)
            {
                Bars[index]=-1;
            }
            w_time+=(total_time-Cust->t_arr);
            printf("\033[0;31mCustomer %d leaves without their order at %d second(s)\033[1;0m\n",Cust->index,total_time);
            sem_post(&mutex);
            // printf("alpha");
            sem_post(&Bar_sem);
            return NULL;
        }
        sem_post(&mutex);
        // sem_post(&mutex);
        // sem_wait(&mutex);
        // printf("%d\n",bar);
        int free_flag=0;
        // int notfound=1;
        // while (notfound)
        // {
        //     for (int i=0;i<bar;i++)
        //     {
        //         printf("a %d a",Bars[i]);
        //         if (Bars[i]==-1)
        //         {
        //             // free_flag=1;
        //             Bars[i]=1;
        //             index=i;
        //             notfound=0;
        //             break;
        //         }
        //     }
        //     sem_post(&mutex);
        //     sleep(1);
        //     sem_wait(&mutex);
        // }
        sem_wait(&mutex);
        int time_temp=total_time;
        w_time+=(total_time-Cust->t_arr);
        printf("\033[0;36mBarista %d begins preparing the order of customer %d at %d second(s)\033[1;0m\n",index+1,Cust->index,time_temp);
        sem_post(&mutex);

        // while(time_since_bar_free!=total_time-1)
        // {
            
        // }
        // sleep(1);
        // int inc=0;
        // if (free_flag==1)
        // {
        //     inc++;
        //     sleep(1);
        // }
        int flag=0;
        sem_wait(&mutex);
        int flagging=0;
        while (total_time-time_temp<Cof[Cust->c_id].time)
        {
            // sem_wait(&mutex);
            sem_post(&mutex);
            sem_wait(&mutex);
            if (flag==0&&(total_time-time_star==Cust->t_tol))
            {
                if (total_time-time_temp==Cof[Cust->c_id].time)
                {
                    sem_post(&mutex);
                    flagging=1;
                    break;
                }
                printf("\033[0;31mCustomer %d leaves without their order at %d second(s)\033[1;0m\n",Cust->index,total_time);
                waste++;
                flag=1;
            }
            // sleep(1);
            // time_temp++;
        }
        if (flagging==1)
        sem_wait(&mutex);
        // else
        // sem_post(&mutex);
        printf("\033[0;34mBarista %d completes the order of customer %d at %d second(s)\033[1;0m\n",index+1,Cust->index,total_time);
        int end_time=total_time;
        sem_post(&mutex);
        if (flag==1)
        {
            // waste++;
        }
        else
        {
            sem_wait(&mutex);
            printf("\033[0;32mCustomer %d leaves with their order at %d second(s)\033[1;0m\n",Cust->index,end_time);
            sem_post(&mutex);
            // return;
        }
        // sleep(1);
        // sem_post(&Bar_sem);
        sem_wait(&mutex);
        // if (end_time==total_time)
        // Bars[index]=-2;
        fin_count++;
        Bars[index]=-2;
        // else
        // Bars[index]=-1;
        // printf("Bye");
        sem_post(&mutex);
        // printf("sem_timedwait() succeeded\n");
    }
}

int main()
{
    int k,n;
    scanf("%d%d%d",&bar,&k,&n);
    Bars=malloc(sizeof(int)*bar);
    for (int i=0;i<bar;i++)
    {
        Bars[i]=-2;
    }
    Cof = malloc(sizeof(struct Coffee)*k);
    for (int i=0;i<k;i++)
    {
        scanf("%s %d",Cof[i].name,&Cof[i].time);
    }
    Customer Cust[n];
    int ind;
    char temp[1024];
    for (int i=1;i<n+1;i++)
    {
        scanf("%d",&ind);
        Cust[ind-1].index=i;
        scanf("%s %d %d",Cust[ind-1].c_name,&Cust[ind-1].t_arr,&Cust[ind-1].t_tol);
        Cust[ind-1].t_tol++;
        Cust[ind-1].bar=-1;
        for (int j=0;j<k;j++)
        {
            if (strcmp(Cust[ind-1].c_name,Cof[j].name)==0)
            {
                Cust[ind-1].c_id=j;
            }
        }
    }
    // printf("%d\n",bar);
    sem_init(&Bar_sem,0,0);
    sem_init(&mutex,0,1);
    pthread_t customers[n];
    while (1)
    {
        for (int i=0;i<n;i++)
        {
            if (Cust[i].t_arr==total_time)
            {
                sem_wait(&mutex);
                printf("\033[0;37mCustomer %d arrives at %d second(s)\n\033[1;0m",i+1,total_time);
                printf("\033[0;33mCustomer %d orders a %s\033[1;0m\n",i+1,Cust[i].c_name);
                sem_post(&mutex);
                pthread_create(&customers[i],NULL,consumer,(void*)&Cust[i]);
                usleep(500);
            }
        }
        sleep(1);
        sem_wait(&mutex);
        for (int i=0;i<bar;i++)
        {
            if (Bars[i]==-2)
            {
                Bars[i]=-1;
                sem_post(&Bar_sem);
            }
        }
        // sem_post(&mutex);
        // sem_wait(&mutex);
        total_time++;
        if (fin_count==n)
        {
            printf("%d coffee wasted\n",waste);
            printf("Avg wtime = %.2f \n",w_time/(float)n);
            return 0;
        }
        sem_post(&mutex);
    }
    // return 0;
}