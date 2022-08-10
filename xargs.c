#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/param.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   if (argc < 2)
   {
      fprintf(2, "there are something wrong in argument.\n");
      exit(1);
   }
   char *split[MAXARG];
   int index=0;
   // printf("%d\n",argc);
   for (int i = 1; i < argc; i++)
   {
      split[index++] = argv[i];
      // printf(split[i - 1]);
      // printf("        ");
   }
   int n = 0;
   char buf[512] = {"\0"};

   while ((n = read(0, buf, 512)) > 0)
   {
      char temp[512]= {"\0"};
      split[index]=temp;
      for (int i = 0; i < n; i++)
      {
         if (buf[i] == '\n')
         {
            if (fork() == 0)
            {
               exec(argv[1], split);
            }
            else
            {
               wait(0);
            }
         }
         else
         {
            temp[i] = buf[i];
         }
      }
   }

   exit(0);
}
