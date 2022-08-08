#include "kernel/types.h"
#include "user/user.h"

#define MAX 35

int Process(int readin, int writeout)
{
  int pid = fork();
  if (pid == 0)
  {
    close(writeout);
    int prime, number;
    read(readin, &prime, sizeof(int));
    printf("prime %d\n", prime);

    int p2[2];
    while (read(readin, &number, sizeof(int)) > 0)
    {
      //printf("number     %d    ", number);
      //printf("number  prime     %d    ", number % prime);
      if (number % prime != 0) //      
      {
        if (number >= MAX)
            break;
        if (pid == 0)
        {
          pipe(p2);
          pid = Process(p2[0], p2[1]);
        }
        write(p2[1], &number, sizeof(int));
      }
    }
    close(p2[1]);
    if (pid > 0)
      wait(0);  
  }
  else
  {
    close(readin);
  }
  return pid; 
}

int main(int argc, char *argv[])
{
  int p1[2];
  pipe(p1);
  if (Process(p1[0], p1[1]) > 0)
  {
    for (int i = 2; i <= MAX; i++)
    {
      //printf("mainwrite     %d    ", i);
      write(p1[1], &i, sizeof(int));
    }
    close(p1[1]); // stop write
    wait(0);
  }

  exit(0);
}
