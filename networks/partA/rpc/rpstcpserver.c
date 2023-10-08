#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{

    char *ip = "127.0.0.1";
    int port = 5620;
    int port2 = 5621;

    int server_sock, client_sock;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_size;
    char buffer[1024];
    int n;

    server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]TCP server socket created.\n");

    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);
    if (server_addr.sin_addr.s_addr == -1)
    {
        perror("inet_addr error");
        exit(1);
    }

    n = bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (n < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }
    printf("[+]Bind to the port number: %d\n", port);

    if (listen(server_sock, 5) == -1)
    {
        perror("Listen error");
        exit(1);
    }
    printf("Listening...\n");

    int server_sock2, client_sock2;
    struct sockaddr_in server_addr2, client_addr2;
    socklen_t addr_size2;
    char buffer2[1024];
    int n2;

    server_sock2 = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock2 < 0)
    {
        perror("[-]Socket error");
        exit(1);
    }
    printf("[+]TCP server socket created.\n");

    memset(&server_addr2, '\0', sizeof(server_addr2));
    server_addr2.sin_family = AF_INET;
    server_addr2.sin_port = htons(port2);
    server_addr2.sin_addr.s_addr = inet_addr(ip);
    if (server_addr2.sin_addr.s_addr == -1)
    {
        perror("inet_addr error");
        exit(1);
    }

    n = bind(server_sock2, (struct sockaddr *)&server_addr2, sizeof(server_addr2));
    if (n < 0)
    {
        perror("[-]Bind error");
        exit(1);
    }
    printf("[+]Bind to the port number: %d\n", port2);

    if (listen(server_sock2, 5) == -1)
    {
        perror("Listen error");
        exit(1);
    }
    printf("Listening...\n");

    addr_size = sizeof(client_addr);
    client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &addr_size);
    if (client_sock == -1)
    {
        perror("Accept error");
        exit(1);
    }
    printf("Client 1 connected.\n");

    addr_size2 = sizeof(client_addr2);
    client_sock2 = accept(server_sock2, (struct sockaddr *)&client_addr2, &addr_size2);
    if (client_sock2 == -1)
    {
        perror("Accept error");
        exit(1);
    }
    printf("Client 2 connected.\n");
    char* client1=malloc(sizeof(char)*100);
    char* client2=malloc(sizeof(char)*100);
    int playing=1;
    while (1)
    {
        if (playing==1)
        { 
            strcpy(buffer2,"Rock/Paper/Scissor\n");
            if (send(client_sock, buffer2, strlen(buffer2), 0) == -1)
            {
                perror("Send Error");
                exit(1);
            }
            if (send(client_sock2, buffer2, strlen(buffer2), 0) == -1)
            {
                perror("Send Error");
                exit(1);
            }
        }
        client1[0]='\0';
        client2[0]='\0';
        bzero(buffer, 1024);
        if (recv(client_sock, buffer, sizeof(buffer), 0) == -1)
        {
            perror("Recv Error");
            exit(1);
        }
        printf("Client1: %s\n", buffer);
        if (strcmp(buffer, "exit") == 0)
        {
            if (close(client_sock) == -1)
            {
                perror("Close Error");
                exit(1);
            }
            printf("Client 1 disconnected.\n\n");
            strcpy(buffer,"exit");
            if (send(client_sock2, buffer, strlen(buffer), 0) == -1)
            {
                perror("Send Error");
                exit(1);
            }
            if (close(client_sock2) == -1)
            {
                perror("Close Error");
                exit(1);
            }
            exit(0);
        }
        bzero(buffer2, 1024);
        strcpy(client1,buffer);
        if (recv(client_sock2, buffer2, sizeof(buffer2), 0) == -1)
        {
            perror("Recv Error");
            exit(1);
        }
        printf("Client2: %s\n", buffer2);
        if (strcmp(buffer2, "exit") == 0)
        {
            if (close(client_sock2) == -1)
            {
                perror("Close Error");
                exit(1);
            }
            printf("Client 2 disconnected.\n\n");
            strcpy(buffer,"exit");
            if (send(client_sock, buffer, strlen(buffer), 0) == -1)
            {
                perror("Send Error");
                exit(1);
            }
            if (close(client_sock) == -1)
            {
                perror("Close Error");
                exit(1);
            }
            exit(0);
        }
        strcpy(client2,buffer2);
        if (client1[0]!='\0'&&client2[0]!='\0')
        {
            if (playing==1)
            {
                if ((strcmp(client1,"Rock")==0&&strcmp(client2,"Paper")==0)||(strcmp(client1,"Paper")==0&&strcmp(client2,"Scissor")==0)||(strcmp(client1,"Scissor")==0&&strcmp(client2,"Rock")==0))
                {
                    printf("Client 2 Wins\n");
                    strcpy(buffer,"You Lose\n To play again type yes or To quit type exit");
                    if (send(client_sock, buffer, strlen(buffer), 0) == -1)
                    {
                        perror("Send Error");
                        exit(1);
                    }
                    strcpy(buffer,"You Win\n To play again type yes or To quit type exit");
                    if (send(client_sock2, buffer, strlen(buffer), 0) == -1)
                    {
                        perror("Send Error");
                        exit(1);
                    }
                    playing=0;
                }
                else if ((strcmp(client2,"Rock")==0&&strcmp(client1,"Paper")==0)||(strcmp(client2,"Paper")==0&&strcmp(client1,"Scissor")==0)||(strcmp(client2,"Scissor")==0&&strcmp(client1,"Rock")==0))
                {
                    printf("Client 1 Wins\n");
                    strcpy(buffer,"You Win\n To play again type yes or To quit type exit");
                    if (send(client_sock, buffer, strlen(buffer), 0) == -1)
                    {
                        perror("Send Error");
                        exit(1);
                    }
                    strcpy(buffer,"You Lose\n To play again type yes or To quit type exit");
                    if (send(client_sock2, buffer, strlen(buffer), 0) == -1)
                    {
                        perror("Send Error");
                        exit(1);
                    }
                    playing=0;
                }
            }
            else if (playing==0)
            {
                playing=1;
                if (strcmp(client1,"yes")!=0&&strcmp(client2,"yes")!=0)
                {
                    strcpy(buffer,"exit");
                    if (send(client_sock, buffer, strlen(buffer), 0) == -1)
                    {
                        perror("Send Error");
                        exit(1);
                    }
                    if (send(client_sock2, buffer, strlen(buffer), 0) == -1)
                    {
                        perror("Send Error");
                        exit(1);
                    }
                    if (close(server_sock) == -1)
                    {
                        perror("Close Error");
                        exit(1);
                    }
                    if (close(server_sock2) == -1)
                    {
                        perror("Close Error");
                        exit(1);
                    }
                    exit(0);
                }
            }
            
        }
    }

    return 0;
}