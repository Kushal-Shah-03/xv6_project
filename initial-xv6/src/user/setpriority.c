#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
    if (argc!=3)
    {
        printf("Invalid Arguments\n");
        return 0;
    }
    else
    {
        for (int i=1;i<3;i++)
        {
            int j=0;
            while (argv[i][j]!='\0')
            {
                if (argv[i][j]<'0'||argv[i][j]>'9')
                {
                    printf("Invalid Arguments\n");
                    return 0;
                }
                j++;
            }
        }
        int pid=atoi(argv[1]);
        int priority=atoi(argv[2]);
        set_priority(pid,priority);
    }
    return 0;
}