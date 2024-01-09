#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
// #include <sys/time.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>
#include <string.h>

typedef struct Machine{
    int t_start;
    int t_stop;
    int state;
}Machine;

typedef struct Flavour{
    char name[1024];
    int time;
}Flavour;

typedef struct Topping{
    char name[1024];
    int quantity;
}Topping;
typedef struct Customer{
    int num_order;
    int t_arr;
    int pos;
}Customer;

typedef struct Order{
    int cust_number;
    int flavour;
    int toppings[50]; 
    int top_count;
    int n_orders;
    int order_index;
    int t_arr;
    int state;
    int total_order_index;
}Order;

Machine* Mac;
Flavour* Flav;
Topping* Top;
Order Ord[1024];
pthread_t* Orders;
Customer Cust[100];

int order_count=0;
int total_time=0;
int cust_count_in_parlour=0;
int cust_count=0;
sem_t* Order_flag;
int machine_check=-1;
int max_t_stop=-1;
int limited_ingredient=0;

enum Pos {not_arrived,inparlour,rejected,completed};
enum Mach {occupied,not_occupied,not_active};
enum State {order_not_arrived,reject,pending,done,processing};

sem_t mutex;
sem_t machines;

int Find_next_customer(int index)
{
    // sem_post(&Order_flag[index]);
    int flag=0;
    for (int i=index+1;i<order_count;i++)
    {
        if (Ord[i].state==pending)
        {
            flag=1;
            sem_post(&Order_flag[i]);
            break;
        }
    }
    if (flag==0)
    {
        return 0;
    }
    else
    return 1;
}

void Return_fxn(Order* Curr_order)
{
    for (int i=0;i<order_count;i++)
    {
        if (Curr_order->cust_number==Ord[i].cust_number)
        {
            Ord[i].state=reject;
        }
    }
    // int flag=0;
    // for (int i=Curr_order->total_order_index+1;i<order_count;i++)
    // {
    //     if (Ord[i].state==pending)
    //     {
    //         flag=1;
    //         sem_post(&Order_flag[i]);
    //         break;
    //     }
    // }
    Cust[Curr_order->cust_number].pos=rejected;
    cust_count_in_parlour--;
    int flag=Find_next_customer(Curr_order->total_order_index);
    if (flag==0)
    {
        sem_post(&machines);
    }
    sem_post(&mutex);
    return;
}

void* Order_fxn(void* arg)
{
    int index=*(int*)arg;
    Order* Curr_order=&Ord[index];
    while(1)
    {
        // sem_post(&mutex);
        sem_wait(&Order_flag[Curr_order->total_order_index]);
        // printf("Hi %d",index);
        // sem_wait(&mutex);
        // printf("L%dL",total_time);
        // fflush(stdout);
        for (int i=0;i<Curr_order->top_count;i++)
        {
            if (Top[Curr_order->toppings[i]].quantity==0)
            {
                printf("\033[0;31mCustomer %d rejected due to unavailability of ingredients\033[1;0m\n",Curr_order->cust_number+1);
                Cust[Ord[i].cust_number].pos=rejected;
                Return_fxn(Curr_order);
                return NULL;
            }
        }
        // printf("K%dK",Mac[machine_check].t_stop);
        int flagger=0;
        if (Mac[machine_check].t_start==Ord[index].t_arr&&Mac[machine_check].t_start==total_time)
        {
            flagger=1;
        }
        if (Ord[index].t_arr==total_time)
        {
            flagger=1;
        }
        if ((Flav[Curr_order->flavour].time<=(Mac[machine_check].t_stop-total_time))&&(flagger==0))
        {
            // printf("c%dc",total_time);
            Ord[index].state=processing;
            Mac[machine_check].state=occupied;
            int assigned_machine=machine_check;
            printf("\033[0;36mMachine %d starts preparing ice cream %d of customer %d at %d second(s)\033[1;0m\n",machine_check+1,Ord[index].order_index+1,Ord[index].cust_number+1,total_time);
            fflush(stdout);
            sem_post(&machines);
            int time_stop=total_time+Flav[Curr_order->flavour].time;
            for (int i=0;i<Curr_order->top_count;i++)
            {
                if (Top[Curr_order->toppings[i]].quantity>0)
                {
                    Top[Curr_order->toppings[i]].quantity--;
                }
            }
            // sem_post(&mutex);
            // printf("blahh");
            // fflush(stdout);
            int flag=0;
            // printf("a %d\n",total_time);
            sem_post(&mutex);
            while (1)
            {
                sem_wait(&mutex);
                if ((total_time==time_stop)&&(flag==0))
                {
                    printf("\033[0;34mMachine %d completes preparing ice cream %d of customer %d at %d seconds(s)\033[1;0m\n",assigned_machine+1,Curr_order->order_index+1,Curr_order->cust_number+1,total_time);
                    Cust[Curr_order->cust_number].num_order--;
                    Curr_order->state=completed;
                    sem_post(&mutex);
                    flag=1;
                    // return NULL;
                }
                if ((total_time==time_stop+1)&&(flag==1))
                {
                    sem_wait(&machines);
                    if (Mac[assigned_machine].t_stop<=total_time)
                    {
                        Mac[assigned_machine].state=not_occupied;
                    }
                    else
                    {
                        Mac[assigned_machine].state=not_active;
                    }
                    sem_post(&machines);
                    sem_post(&mutex);
                    return NULL;
                }
                sem_post(&mutex);
            }
        }
        else
        {
            // printf("Insuffecient time for this machine");
            fflush(stdout);
            // sem_post(&Order_flag[Curr_order->total_order_index]);
            int flag=Find_next_customer(Curr_order->total_order_index);
            if (flag==0)
            {
                sem_post(&machines);
            }
            sem_post(&mutex);
            // return NULL;
        }
    }
    // fflush(stdout);
}

int main()
{
    sem_init(&mutex,0,1);
    int n,k,f,t;
    sem_init(&machines,0,1);
    scanf("%d%d%d%d",&n,&k,&f,&t);
    Mac=malloc(sizeof(Machine)*n);
    Flav=malloc(sizeof(Flavour)*f);
    Top=malloc(sizeof(Topping)*t);
    for (int i=0;i<n;i++)
    {
        scanf("%d%d",&Mac[i].t_start,&Mac[i].t_stop);
        if (Mac[i].t_stop>max_t_stop)
        {
            max_t_stop=Mac[i].t_stop;
        }
        Mac[i].state=not_active;
    }
    for (int i=0;i<f;i++)
    {
        scanf("%s %d",Flav[i].name,&Flav[i].time);
    }
    for (int i=0;i<t;i++)
    {
        scanf("%s %d",Top[i].name,&Top[i].quantity);
        if (Top->quantity>0)
        {
            limited_ingredient=1;
        }
    }
    char garbage;
    scanf("%c",&garbage);
    char* buffer=calloc(1024,sizeof(char));
    char* temp;
    while (1)
    {
        fgets(buffer,1024,stdin);
        if (buffer[0]=='\n')
        {
            break;
        }
        int c,t_arr,n_ice;
        int flag=1;
        temp=strtok(buffer," ");
        c=atoi(temp);
        temp=strtok(NULL," ");
        t_arr=atoi(temp);
        temp=strtok(NULL," \n");
        n_ice=atoi(temp);
        // printf("%d %d",n_ice,cust_count);
        Cust[cust_count].num_order=n_ice;
        Cust[cust_count].t_arr=t_arr;
        Cust[cust_count].pos=not_arrived;
        for (int i=0;i<n_ice;i++)
        {
            fgets(buffer,1024,stdin);
            temp=strtok(buffer," ");
            // strcpy(Ord[order_count].flavour,temp);
            for (int j=0;j<f;j++)
            {
                if (strcmp(temp,Flav[j].name)==0)
                {
                    Ord[order_count].flavour=j;
                    break;
                }
            }
            int top_count=0;
            while (1)
            {
                temp=strtok(NULL," \n");
                if (temp==NULL)
                {
                    break;
                }
                // int flagging=0;
                for (int j=0;j<t;j++)
                {
                    if (strcmp(temp,Top[j].name)==0)
                    {
                        // flagging=1;
                        Ord[order_count].toppings[top_count]=j;
                        break;
                    }
                }
                // strcpy(Ord[order_count].toppings[top_count],temp);
                top_count++;
            }
            Ord[order_count].cust_number=c-1;
            Ord[order_count].order_index=i;
            Ord[order_count].n_orders=n_ice;
            Ord[order_count].top_count=top_count;
            Ord[order_count].total_order_index=order_count;
            Ord[order_count].t_arr=t_arr;
            Ord[order_count].state=order_not_arrived;
            order_count++;
        }
        cust_count++;
    }
    Orders=(pthread_t*)malloc(sizeof(pthread_t)*order_count);
    Order_flag=malloc(sizeof(sem_t)*order_count);
    for (int i=0;i<order_count;i++)
    {
        sem_init(&Order_flag[i],0,0);
    }
    // printf("Kya");
    fflush(stdout);
    while (1)
    {
        sem_wait(&mutex);
        for (int i=0;i<cust_count;i++)
        {
            if (Cust[i].t_arr==total_time)
            {
                printf("\e[0;37mCustomer %d enters at %d second(s)\033[1;0m\n",i+1,total_time);
            }
        }
        for (int i=0;i<order_count;i++)
        {
            int topperings[t];
            for (int j=0;j<t;j++)
            topperings[j]=0;
            if ((Ord[i].t_arr==total_time)&&(Ord[i].state==order_not_arrived))
            {
                // printf("a%da",i);
                for (int j=0;j<order_count;j++)
                {
                    // printf("b%db",Ord[j].cust_number);
                    if ((Ord[j].cust_number==Ord[i].cust_number)&&Ord[j].state==order_not_arrived)
                    for (int k=0;k<Ord[j].top_count;k++)
                    {
                        topperings[Ord[j].toppings[k]]++;
                    }
                }
                for (int j=0;j<t;j++)
                {
                    if ((Top[j].quantity<topperings[j])&&(Top[j].quantity!=-1))
                    {
                        // printf("%d",topperings[j]);
                        for (int k=0;k<order_count;k++)
                        {
                            if (Ord[i].cust_number==Ord[k].cust_number)
                            {
                                Ord[k].state=reject;
                            }
                        }
                        Cust[Ord[i].cust_number].pos=rejected;
                        printf("\033[0;31mCustomer %d rejected because of unavailability of ingredients\033[1;0m\n",Ord[i].cust_number+1);
                        break;
                    }
                }
            }   
        }
        for (int i=0;i<order_count;i++)
        {
            if (Ord[i].t_arr<=total_time)
            {
                if (Cust[Ord[i].cust_number].pos==not_arrived)
                {
                    if (cust_count_in_parlour==k)
                    {
                        Cust[Ord[i].cust_number].pos=rejected;
                        printf("\033[0;31mCustomer %d leaves due to lack of seats in parlour\033[1;0m\n",Ord[i].cust_number+1);
                        continue;
                    }
                    else
                    {
                        Cust[Ord[i].cust_number].pos=inparlour;
                        cust_count_in_parlour++;
                    }
                }
                if (Cust[Ord[i].cust_number].pos==inparlour)
                {
                    if (Ord[i].state==order_not_arrived)
                    {
                        Ord[i].state=pending;
                        int* index=malloc(sizeof(int));
                        *index=i;
                        pthread_create(&Orders[i],NULL,Order_fxn,(void*)index);
                    }
                }
                if (Cust[Ord[i].cust_number].pos==rejected)
                {
                    Ord[i].state=reject;
                }
            }
        }
        for (int i=0;i<cust_count;i++)
        {
            if (Cust[i].t_arr==total_time&&Cust[i].pos!=rejected)
            {
                printf("\e[0;33mCustomer %d orders %d ice creams\033[1;0m\n",i+1,Cust[i].num_order);
                int count_ice=1;
                for (int j=0;j<order_count;j++)
                {
                    if (Ord[j].cust_number==i)
                    {
                        printf("\e[0;33mIce cream %d: %s ",count_ice,Flav[Ord[j].flavour].name);
                        for (int k=0;k<Ord[j].top_count;k++)
                        {
                            printf("%s ",Top[Ord[j].toppings[k]].name);
                        }
                        printf("\n\033[1;0m");
                        count_ice++;
                    }
                }
            }
        }
        sem_post(&mutex);
        for (int i=0;i<n;i++)
        {
            int flag=0;
            sem_wait(&mutex);
            sem_wait(&machines);
            if (Mac[i].t_start==total_time)
            {
                printf("\e[38;2;255;85;0m""Machine %d has started working at %d second(s)\033[1;0m\n",i+1,total_time);
            }
            if (Mac[i].t_stop==total_time)
            {
                printf("\e[38;2;255;85;0m""Machine %d has stopped working at %d second(s)\033[1;0m\n",i+1,total_time);
            }
            if (Mac[i].t_start<=total_time&&Mac[i].t_stop>=total_time)
            {
                if (Mac[i].state==not_occupied||Mac[i].state==not_active)
                {
                    // printf("pls %d",i);
                    for (int j=0;j<order_count;j++)
                    {
                        if (Ord[j].state==pending)
                        {
                            flag=1;
                            machine_check=i;
                            // printf("L%dL",total_time);
                            sem_post(&Order_flag[j]);
                            // sem_post(&mutex);
                            break;
                        }
                    }
                    
                }
            }
            if (flag==0)
            {
                sem_post(&machines);
                sem_post(&mutex);
            }
        }
        // if (flag==1)
        // {
        sem_wait(&machines);
            
        // }
        for (int i=0;i<order_count;i++)
        {
            if (Cust[Ord[i].cust_number].num_order==0)
            {
                printf("\033[0;32mCustomer %d has collected their order(s) and left at %d second(s)\033[1;0m\n",Ord[i].cust_number+1,total_time);
                cust_count_in_parlour--;
                Cust[Ord[i].cust_number].num_order=-1;
                Cust[Ord[i].cust_number].pos=completed;
            }
        }
        int flagger=0;
        for (int i=0;i<t;i++)
        {
            if (Top[i].quantity>0)
            {
                flagger=1;
            }
            if (limited_ingredient==0)
            {
                flagger=1;
            }
        }
        if (flagger==0)
        {    
            for (int i=0;i<t;i++)
            {
                Top[i].quantity=0;
            }
            for (int i=0;i<n;i++)
            {
                if (Mac[i].state==occupied)
                {
                    flagger=1;
                }
            }
            if (flagger==0)
            {
                for (int i=0;i<cust_count;i++)
                {
                    if (Cust[i].pos==inparlour||Cust[i].pos==not_arrived)
                    {
                        printf("Customer %d was not serviced due to unavailability of limited ingredients\n",i+1);
                    }
                }
                printf("Parlour Closed\n");
                // for (int i=0;i<order_count;i++)
                // pthread_cancel(Orders[i]);
                return 0;
            }
        }
        sem_post(&machines);
        total_time++;
        sleep(1);
        if (total_time==max_t_stop+1)
        {
            for (int i=0;i<cust_count;i++)
            {
                if (Cust[i].pos==inparlour||Cust[i].pos==not_arrived)
                {
                    printf("Customer %d was not serviced due to unavailability of machines\n",i+1);
                }
            }
            printf("Parlour Closed\n");
            // for (int i=0;i<order_count;i++)
            // pthread_cancel(Orders[i]);
            return 0;
        }
        // sem_post(&mutex);
    }
}

