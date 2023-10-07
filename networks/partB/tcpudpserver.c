#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <sys/time.h>
#include <errno.h>

struct Data
{
  char s1;
  char s2;
  char s3;
  char s4;
  char s5;
  int npackets;
  int currpacket;
  int msgno;
};

int main(int argc, char **argv)
{
      int msgno=-1;
      int port = 5600;

      char *ip = "127.0.0.1";

      int sockfdrecv;
      struct sockaddr_in server_addr, client_addr;
      // char buffer[1024];
      socklen_t addr_sizerecv=sizeof(client_addr);
      int n;

      sockfdrecv = socket(AF_INET, SOCK_DGRAM, 0);
      if (sockfdrecv < 0)
      {
        perror("socket error");
        exit(1);
      }
      int flags = fcntl(sockfdrecv, F_GETFL);
      flags |= O_NONBLOCK;
      fcntl(sockfdrecv, F_SETFL, flags);

      memset(&server_addr, '\0', sizeof(server_addr));
      server_addr.sin_family = AF_INET;
      server_addr.sin_port = htons(port);
      server_addr.sin_addr.s_addr = inet_addr(ip);
      if (server_addr.sin_addr.s_addr == -1)
      {
        perror("inet_addr error");
        exit(1);
      }

    port=5601;

      int sockfdsend;
      struct sockaddr_in addr;
      char buffer[1024];
      socklen_t addr_sizesend=sizeof(addr);

      sockfdsend = socket(AF_INET, SOCK_DGRAM, 0);
      if (sockfdsend < 0)
      {
        perror("Socket error");
        exit(1);
      }
      flags = fcntl(sockfdsend, F_GETFL);
      flags |= O_NONBLOCK;
      fcntl(sockfdsend, F_SETFL, flags);
      memset(&addr, '\0', sizeof(addr));
      addr.sin_family = AF_INET;
      addr.sin_port = htons(port);
      addr.sin_addr.s_addr = inet_addr(ip);
      if (addr.sin_addr.s_addr == -1)
      {
        perror("inet_addr error");
        exit(1);
      }

  int flagging = 0;
  int send = 0;
  int recv = 1;
  while (1)
  {
  if (recv == 1)
    {
      int port=5600;
      int sockfd=sockfdrecv;
      socklen_t addr_size=addr_sizerecv;
      // printf("Hi\n");
      if (flagging == 0)
      {
        n = bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (n < 0)
        {
          perror("bind error");
          exit(1);
        }
        flagging = 1;
      }

      //   bzero(buffer, 1024);
        // addr_size = sizeof(client_addr);
      struct Data *Data1 = malloc(sizeof(struct Data));
      // Data1->string=malloc(sizeof(char)*11);
      int npackets = -1;
      while (1)
      {
        int flag = 1;
        if (recvfrom(sockfd, Data1, sizeof(struct Data), 0, (struct sockaddr *)&client_addr, &addr_size) == -1)
        {
          if (errno == EAGAIN)
          {
            flag = 0;
          }
          else
          {
            printf("%d", errno);
            perror("recvfrom error");
            exit(1);
          }
        }
        if (flag == 1&&Data1->msgno!=msgno)
        {
          break;
        }
      }
      npackets = Data1->npackets;
      msgno=Data1->msgno;
      int visited[npackets];
      for (int i = 0; i < npackets; i++)
        visited[i] = 0;
      int currpacket = Data1->currpacket;
      visited[currpacket] = 1;
      if (sendto(sockfd, &currpacket, sizeof(int), 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
      {
        perror("sendto error");
        exit(1);
      }
      struct Data Data[npackets];
      Data[Data1->currpacket] = *Data1;
      int recvpacket = 0;
      int allcount = 1;
      while (allcount < npackets)
      {
        while (1)
        {
          int flag = 1;
          if (recvfrom(sockfd, Data1, sizeof(struct Data), 0, (struct sockaddr *)&client_addr, &addr_size) == -1)
          {
            if (errno == EAGAIN)
            {
              flag = 0;
            }
            else
            {
              printf("%d", errno);
              perror("recvfrom error");
              exit(1);
            }
          }
          if (flag == 1&&msgno==Data1->msgno)
          {
            break;
          }
        }
        if (visited[Data1->currpacket] == 1)
          continue;
        visited[Data1->currpacket] = 1;
        allcount++;
        // npackets = Data1->npackets;
        int currpacket = Data1->currpacket;
        Data[Data1->currpacket] = *Data1;
        if (sendto(sockfd, &currpacket, sizeof(int), 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
        {
          perror("sendto error");
          exit(1);
        }
      }
      for (int i = 0; i < npackets; i++)
      {
        printf("%c%c%c%c%c", Data[i].s1, Data[i].s2, Data[i].s3, Data[i].s4, Data[i].s5);
      }
      printf("\n");
      // printf("[+]Data recv: %s\n", buffer);

      // bzero(buffer, 1024);
      // strcpy(buffer, "Welcome to the UDP Server.");
      // if (sendto(sockfd, buffer, 1024, 0, (struct sockaddr *)&client_addr, sizeof(client_addr)) == -1)
      // {
      //   perror("sendto error");
      //   exit(1);
      // }
      // printf("[+]Data send: %s\n", buffer);u
      recv = 0;
      send = 1;
    }
  if (send == 1)
    {
      int port=5601;
      int sockfd=sockfdsend;
      socklen_t addr_size=addr_sizesend;
      scanf("%s", buffer);
      int datalen = strlen(buffer);
      for (int i = 0; i < 5; i++)
      {
        buffer[strlen(buffer) + i] = '\0';
      }
      // defining packet size as 10 bytes
      int npackets;
      if (datalen % 5 == 0)
        npackets = datalen / 5;
      else
      {
        npackets = datalen / 5 + 1;
      }
      struct Data *Data[npackets];
      int flag = 0;
      for (int i = 0; i < npackets; i++)
      {
        Data[i] = malloc(sizeof(Data));
        Data[i]->npackets = npackets;
        Data[i]->currpacket = i;
        Data[i]->s1 = buffer[i * 5];
        Data[i]->s2 = buffer[i * 5 + 1];
        Data[i]->s3 = buffer[i * 5 + 2];
        Data[i]->s4 = buffer[i * 5 + 3];
        Data[i]->s5 = buffer[i * 5 + 4];
        Data[i]->msgno=msgno;
      }
      int Sent[npackets];
      for (int i = 0; i < npackets; i++)
        Sent[i] = 0;
      int allsent = 0;
      int *recvpacket = malloc(sizeof(int));
      struct timeval Sending[npackets];
      struct timeval Compare;
      while (allsent < npackets)
      {
        // printf("Hi\n");
        for (int i = 0; i < npackets; i++)
        {
          if (Sent[i] == 0)
          {
            gettimeofday(&Sending[i], NULL);
            if (sendto(sockfd, Data[i], sizeof(struct Data), 0, (struct sockaddr *)&addr, sizeof(addr)) == -1)
            {
              perror("Sendto error");
              exit(1);
            }
            int flagging2 = 0;
            if (recvfrom(sockfd, recvpacket, sizeof(int), 0, (struct sockaddr *)&addr, &addr_size) == -1)
            {
              if (errno != EWOULDBLOCK || errno != EAGAIN)
              {
                perror("Recvfrom error");
                exit(1);
              }
              else
              {
                flagging2 = 1;
              }
            }
            if (flagging2 == 0 && *recvpacket != -1)
            {
              if (Sent[*recvpacket] == 0)
              {
                Sent[*recvpacket] = 1;
                allsent++;
                // printf("%d\n",*recvpacket);
                fflush(stdout);
              }
            }
          }
          for (int j = 0; j < npackets; j++)
          {
            if (Sent[j] == 0)
            {
              gettimeofday(&Compare, NULL);
              if (Compare.tv_sec - Sending[j].tv_sec > 1 || ((Compare.tv_usec - Sending[j].tv_usec) / 100000 >= 1))
              {
                gettimeofday(&Sending[j], NULL);
                if (sendto(sockfd, Data[j], sizeof(struct Data), 0, (struct sockaddr *)&addr, sizeof(addr)) == -1)
                {
                  perror("Sendto error");
                  exit(1);
                }
                int flagging = 0;
                if (recvfrom(sockfd, recvpacket, sizeof(int), 0, (struct sockaddr *)&addr, &addr_size) == -1)
                {
                  if (errno != EWOULDBLOCK || errno != EAGAIN)
                  {
                    perror("Recvfrom error");
                    exit(1);
                  }
                  else
                  {
                    flagging = 1;
                  }
                }
                if (flagging == 0 && *recvpacket != -1)
                {
                  if (Sent[*recvpacket] == 0)
                  {
                    Sent[*recvpacket] = 1;
                    allsent++;
                    // printf("%d\n",*recvpacket);
                    fflush(stdout);
                  }
                }
              }
            }
          }
        }
      }
      send = 0;
      recv = 1;
    }
  }
    // printf("[+]Data sent: %s\n", buffer);
  return 0;
}