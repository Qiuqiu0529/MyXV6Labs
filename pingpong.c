#include "kernel/types.h"
#include "user/user.h"


int main(int argc, char *argv[])
{
  int p1[2],p2[2];
  char buf[]={'A'};
  pipe(p1);
  pipe(p2);
  if(fork()==0) 
  {
    close(p1[1]);
    close(p2[0]);
    if(read(p1[0], buf,1)!=1)
    {
       printf("read from parent fails! \n");
       exit(1);
    }	
    printf("read from parent successes! \n");
    if(write(p2[1], buf,1)!=1)
    {
       printf("child read fails! \n");
       exit(1);
    }
    exit(0);
  }
  close(p1[0]);
  close(p2[1]);
  if(read(p2[0], buf,1)!=1)
  {
     printf("read from parent fails! \n");
     exit(1);
  }	
  printf("read from parent successes! \n");
  if(write(p1[1], buf,1)!=1)
  {
     printf("child read fails! \n");
     exit(1);
  }
  exit(0);
}
