#include "kernel/types.h"
#include "kernel/fcntl.h"
#include "kernel/stat.h"
#include "kernel/fs.h"
#include "user/user.h"

char *ToFileName(char *path)
{
  static char buf[DIRSIZ + 1];
  char *p;
  // first character after last slash.
  for (p = path + strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;
  memmove(buf, p, strlen(p) + 1);
  return buf;
}

void Find(char *path, char *findname)
{
  int fd;
  struct stat st;
  if ((fd = open(path, O_RDONLY)) < 0)
  {
    fprintf(2, "find: cannot open %s\n", path);
    return;
  }

  if (fstat(fd, &st) < 0) //-1 error
  {
    fprintf(2, "find: cannot stat %s\n", path);
    close(fd);
    return;
  }

  struct dirent de;
  char buf[512], *p;
  switch (st.type)
  {
  case T_DIR:
   
    if (strlen(path) + 1 + DIRSIZ + 1 > sizeof(buf))
    {
      printf("find: path too long\n");
      break;
    }
    strcpy(buf, path);
    p = buf + strlen(buf);
    *p++ = '/';
    while (read(fd, &de, sizeof(de)) == sizeof(de))
    {
      // printf("de.name:%s, de.inum:%d\n", de.name, de.inum);
      if (de.inum == 0 || strcmp(de.name, ".") == 0 || strcmp(de.name, "..") == 0)
        continue;
      memmove(p, de.name, DIRSIZ);
      p[DIRSIZ] = 0;
      Find(buf, findname);
    }
    break;
  case T_FILE:
    if (strcmp(ToFileName(path), findname) == 0)
    {
      printf("%s\n", path);
    }
    break;
  case T_DEVICE:
    break;
  default:
    break;
  }
  close(fd);
}

int main(int argc, char *argv[])
{
  if (argc < 3)
  {
    fprintf(2, "there are something wrong in argument.\n");
    exit(1);
  }
  Find(argv[1], argv[2]);
  exit(0);
}
