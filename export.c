#include "types.h"
#include "stat.h"
#include "user.h"
#include "param.h"

char buf[512];

void
export(char *paths)
{
  int n;


  if(paths == ""){
    printf(1, "export: not enough arguments\n");
    exit();
  }
}

int
main(int argc, char *argv[])
{
  int i;
  char *paths[MAX_PATH_ENTRIES][INPUT_BUF];

  if(argc <= 1){
    printf(2, "error! must add paths to export...\n");
    exit();
  }

  for(i = 1; i < argc; i++){
    if((fd = open(argv[i], 0)) < 0){
      printf(1, "cat: cannot open %s\n", argv[i]);
      exit();
    }
    cat(fd);
    close(fd);
  }
  exit();
}


int
main(int argc, char *argv[])
{
  int i;

  if(argc < 2){
    printf(2, "Usage: mkdir files...\n");
    exit();
  }

  for(i = 1; i < argc; i++){
    if(mkdir(argv[i]) < 0){
      printf(2, "mkdir: %s failed to create\n", argv[i]);
      break;
    }
  }

  exit();
}
