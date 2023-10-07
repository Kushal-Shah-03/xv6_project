#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

int main(int argc, char **argv)
{
    char *ip = "127.0.0.1";
    int port = 5800;

    int sockfd;
    struct sockaddr_in addr;
    char buffer[1024];
    socklen_t addr_size;
    int n;
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0)
    {
        perror("Socket error");
        exit(1);
    }
    memset(&addr, '\0', sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(ip);
    if (addr.sin_addr.s_addr == -1)
    {
        perror("inet_addr error");
        exit(1);
    }
    bzero(buffer, 1024);
    strcpy(buffer, "Hello, World!");
    if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, sizeof(addr)) == -1)
    {
        perror("Sendto error");
        exit(1);
    }
    printf("[+]Data send: %s\n", buffer);

    bzero(buffer, 1024);
    addr_size = sizeof(addr);
    while (1)
    {
        bzero(buffer, 1024);
        if (recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size) == -1)
        {
            perror("Recvfrom error");
            exit(1);
        }
        if (strcmp(buffer, "exit") == 0)
        {
            printf("Disconnected from the server.\n");
            exit(1);
        }
        printf("Server: %s\n", buffer);
        scanf("%s", buffer);
        if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, sizeof(addr)) == -1)
        {
            perror("sendto error");
            exit(1);
        }
    }
    // if (recvfrom(sockfd, buffer, 1024, 0, (struct sockaddr *)&addr, &addr_size) == -1)
    // {
    //     perror("Recvfrom error");
    //     exit(1);
    // }
    // printf("[+]Data recv: %s\n", buffer);

    return 0;
}