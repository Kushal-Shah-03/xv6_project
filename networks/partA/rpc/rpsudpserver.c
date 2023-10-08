#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    int port = 5800;
    int port2 = 5801;
    char *ip = "127.0.0.1";

    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    char buffer[1024];
    socklen_t addr_size;
    int n;

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("socket error");
        exit(1);
    }

    memset(&server_addr, '\0', sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = inet_addr(ip);
    if (server_addr.sin_addr.s_addr == -1)
    {
        perror("inet_addr error");
        exit(1);
    }

    n = bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (n < 0)
    {
        perror("bind error");
        exit(1);
    }

    int sockfd2;
    struct sockaddr_in server_addr2, client_addr2;
    char buffer2[1024];
    socklen_t addr_size2;

    sockfd2 = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd2 < 0)
    {
        perror("socket error");
        exit(1);
    }

    memset(&server_addr2, '\0', sizeof(server_addr2));
    server_addr2.sin_family = AF_INET;
    server_addr2.sin_port = htons(port2);
    server_addr2.sin_addr.s_addr = inet_addr(ip);
    if (server_addr2.sin_addr.s_addr == -1)
    {
        perror("inet_addr error");
        exit(1);
    }

    n = bind(sockfd2, (struct sockaddr *)&server_addr2, sizeof(server_addr2));
    if (n < 0)
    {
        perror("bind error");
        exit(1);
    }

    bzero(buffer, 1024);
    bzero(buffer2, 1024);
    addr_size = sizeof(client_addr);
    if (recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, &addr_size) == -1)
    {
        perror("recvfrom error");
        exit(1);
    }
    printf("Client1: %s\n", buffer);
    addr_size2 = sizeof(client_addr2);
    if (recvfrom(sockfd2, buffer2, 1024, 0, (struct sockaddr *)&client_addr2, &addr_size2) == -1)
    {
        perror("recvfrom error");
        exit(1);
    }
    printf("Client2: %s\n", buffer2);

    bzero(buffer, 1024);
    bzero(buffer2, 1024);
    strcpy(buffer, "Rock/Paper/Scissor");
    char *client1 = malloc(sizeof(char) * 100);
    char *client2 = malloc(sizeof(char) * 100);
    int playing = 1;
    while (1)
    {
        if (playing == 1)
        {
            strcpy(buffer2, "Rock/Paper/Scissor\n");
            if (sendto(sockfd, buffer2, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
            {
                perror("sendto error");
                exit(1);
            }
            if (sendto(sockfd2, buffer2, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2)) == -1)
            {
                perror("sendto error");
                exit(1);
            }
        }
        client1[0] = '\0';
        client2[0] = '\0';
        bzero(buffer, 1024);
        if (recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, &addr_size) == -1)
        {
            perror("recvfrom error");
            exit(1);
        }
        printf("Client1: %s\n", buffer);
        if (strcmp(buffer, "exit") == 0)
        {
            strcpy(buffer,"exit");
            if (sendto(sockfd2, buffer, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2)) == -1)
            {
                perror("sendto error");
                exit(1);
            }
            if (close(sockfd) == -1)
            {
                perror("Close error");
                exit(1);
            }
            if (close(sockfd2) == -1)
            {
                perror("Close error");
                exit(1);
            }
            exit(0);
        }
        bzero(buffer2, 1024);
        strcpy(client1, buffer);
        if (recvfrom(sockfd2, buffer2, 1024, 0, (struct sockaddr *)&client_addr2, &addr_size2) == -1)
        {
            perror("recvfrom error");
            exit(1);
        }
        printf("Client2: %s\n", buffer2);
        if (strcmp(buffer2, "exit") == 0)
        {
            strcpy(buffer,"exit");
            if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
            {
                perror("sendto error");
                exit(1);
            }
            if (close(sockfd) == -1)
            {
                perror("Close error");
                exit(1);
            }
            if (close(sockfd2) == -1)
            {
                perror("Close error");
                exit(1);
            }
            printf("[+]Client disconnected.\n\n");
            exit(0);
        }
        strcpy(client2, buffer2);
        if (client1[0] != '\0' && client2[0] != '\0')
        {
            if (playing == 1)
            {
                if ((strcmp(client1, "Rock") == 0 && strcmp(client2, "Paper") == 0) || (strcmp(client1, "Paper") == 0 && strcmp(client2, "Scissor") == 0) || (strcmp(client1, "Scissor") == 0 && strcmp(client2, "Rock") == 0))
                {
                    printf("Client 2 Wins\n");
                    strcpy(buffer, "You Lose\n To play again type yes or To quit type exit");
                    if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    strcpy(buffer, "You Win\n To play again type yes or To quit type exit");
                    if (sendto(sockfd2, buffer, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    playing = 0;
                }
                else if ((strcmp(client2, "Rock") == 0 && strcmp(client1, "Paper") == 0) || (strcmp(client2, "Paper") == 0 && strcmp(client1, "Scissor") == 0) || (strcmp(client2, "Scissor") == 0 && strcmp(client1, "Rock") == 0))
                {
                    printf("Client 1 Wins\n");
                    strcpy(buffer, "You Win\n To play again type yes or To quit type exit");
                    if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    strcpy(buffer, "You Lose\n To play again type yes or To quit type exit");
                    if (sendto(sockfd2, buffer, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    playing = 0;
                }
                else
                {
                    strcpy(buffer, "exit");
                    if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    if (sendto(sockfd2, buffer, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    if (close(sockfd) == -1)
                    {
                        perror("Close error");
                        exit(1);
                    }
                    if (close(sockfd2) == -1)
                    {
                        perror("Close error");
                        exit(1);
                    }
                    exit(1);
                }
            }
            else if (playing == 0)
            {
                playing = 1;
                if (strcmp(client1, "yes") != 0 || strcmp(client2, "yes") != 0)
                {
                    strcpy(buffer, "exit");
                    if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    if (sendto(sockfd2, buffer, 1024, 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2)) == -1)
                    {
                        perror("sendto error");
                        exit(1);
                    }
                    if (close(sockfd) == -1)
                    {
                        perror("Close error");
                        exit(1);
                    }
                    if (close(sockfd2) == -1)
                    {
                        perror("Close error");
                        exit(1);
                    }
                    exit(1);
                }
            }
        }
    }
    // if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
    // {
    //     perror("sendto error");
    //     exit(1);
    // }
    // printf("[+]Data send: %s\n", buffer);

    return 0;
}