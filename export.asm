
_export:     file format elf32-i386


Disassembly of section .text:

00000000 <main>:
#include "user.h"
#include "param.h"

int
main(int argc, char *argv[])
{
   0:	55                   	push   %ebp
   1:	89 e5                	mov    %esp,%ebp
   3:	83 e4 f0             	and    $0xfffffff0,%esp
   6:	81 ec a0 00 00 00    	sub    $0xa0,%esp
  char path_to_add[INPUT_BUF];
  int i,j=0;
   c:	c7 84 24 98 00 00 00 	movl   $0x0,0x98(%esp)
  13:	00 00 00 00 
  int pathnum = 0;
  17:	c7 84 24 94 00 00 00 	movl   $0x0,0x94(%esp)
  1e:	00 00 00 00 
  //char *paths[MAX_PATH_ENTRIES][INPUT_BUF];

  if(argc <= 1){
  22:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  26:	7f 19                	jg     41 <main+0x41>
    printf(2, "error! must add paths to export\n");
  28:	c7 44 24 04 9c 08 00 	movl   $0x89c,0x4(%esp)
  2f:	00 
  30:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
  37:	e8 9b 04 00 00       	call   4d7 <printf>
    exit();
  3c:	e8 17 03 00 00       	call   358 <exit>
  }

  else{
      for(i = 0; argv[1][i] && pathnum<INPUT_BUF; i++){
  41:	c7 84 24 9c 00 00 00 	movl   $0x0,0x9c(%esp)
  48:	00 00 00 00 
  4c:	eb 78                	jmp    c6 <main+0xc6>
	  if (argv[1][i] != ':'){
  4e:	8b 45 0c             	mov    0xc(%ebp),%eax
  51:	83 c0 04             	add    $0x4,%eax
  54:	8b 10                	mov    (%eax),%edx
  56:	8b 84 24 9c 00 00 00 	mov    0x9c(%esp),%eax
  5d:	01 d0                	add    %edx,%eax
  5f:	0f b6 00             	movzbl (%eax),%eax
  62:	3c 3a                	cmp    $0x3a,%al
  64:	74 2b                	je     91 <main+0x91>
	      path_to_add[j] = argv[1][i];
  66:	8b 45 0c             	mov    0xc(%ebp),%eax
  69:	83 c0 04             	add    $0x4,%eax
  6c:	8b 10                	mov    (%eax),%edx
  6e:	8b 84 24 9c 00 00 00 	mov    0x9c(%esp),%eax
  75:	01 d0                	add    %edx,%eax
  77:	0f b6 10             	movzbl (%eax),%edx
  7a:	8d 44 24 14          	lea    0x14(%esp),%eax
  7e:	03 84 24 98 00 00 00 	add    0x98(%esp),%eax
  85:	88 10                	mov    %dl,(%eax)
	      j++;
  87:	83 84 24 98 00 00 00 	addl   $0x1,0x98(%esp)
  8e:	01 
  8f:	eb 2d                	jmp    be <main+0xbe>
	  }
	  else {
	      path_to_add[j] = 0;
  91:	8d 44 24 14          	lea    0x14(%esp),%eax
  95:	03 84 24 98 00 00 00 	add    0x98(%esp),%eax
  9c:	c6 00 00             	movb   $0x0,(%eax)
	      add_path(path_to_add);
  9f:	8d 44 24 14          	lea    0x14(%esp),%eax
  a3:	89 04 24             	mov    %eax,(%esp)
  a6:	e8 4d 03 00 00       	call   3f8 <add_path>
	      j = 0;
  ab:	c7 84 24 98 00 00 00 	movl   $0x0,0x98(%esp)
  b2:	00 00 00 00 
	      pathnum++;
  b6:	83 84 24 94 00 00 00 	addl   $0x1,0x94(%esp)
  bd:	01 
    printf(2, "error! must add paths to export\n");
    exit();
  }

  else{
      for(i = 0; argv[1][i] && pathnum<INPUT_BUF; i++){
  be:	83 84 24 9c 00 00 00 	addl   $0x1,0x9c(%esp)
  c5:	01 
  c6:	8b 45 0c             	mov    0xc(%ebp),%eax
  c9:	83 c0 04             	add    $0x4,%eax
  cc:	8b 10                	mov    (%eax),%edx
  ce:	8b 84 24 9c 00 00 00 	mov    0x9c(%esp),%eax
  d5:	01 d0                	add    %edx,%eax
  d7:	0f b6 00             	movzbl (%eax),%eax
  da:	84 c0                	test   %al,%al
  dc:	74 0e                	je     ec <main+0xec>
  de:	83 bc 24 94 00 00 00 	cmpl   $0x7f,0x94(%esp)
  e5:	7f 
  e6:	0f 8e 62 ff ff ff    	jle    4e <main+0x4e>
	      j = 0;
	      pathnum++;
	  }
      }
  }
  exit();
  ec:	e8 67 02 00 00       	call   358 <exit>
  f1:	90                   	nop
  f2:	90                   	nop
  f3:	90                   	nop

000000f4 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
  f4:	55                   	push   %ebp
  f5:	89 e5                	mov    %esp,%ebp
  f7:	57                   	push   %edi
  f8:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
  f9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  fc:	8b 55 10             	mov    0x10(%ebp),%edx
  ff:	8b 45 0c             	mov    0xc(%ebp),%eax
 102:	89 cb                	mov    %ecx,%ebx
 104:	89 df                	mov    %ebx,%edi
 106:	89 d1                	mov    %edx,%ecx
 108:	fc                   	cld    
 109:	f3 aa                	rep stos %al,%es:(%edi)
 10b:	89 ca                	mov    %ecx,%edx
 10d:	89 fb                	mov    %edi,%ebx
 10f:	89 5d 08             	mov    %ebx,0x8(%ebp)
 112:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 115:	5b                   	pop    %ebx
 116:	5f                   	pop    %edi
 117:	5d                   	pop    %ebp
 118:	c3                   	ret    

00000119 <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 119:	55                   	push   %ebp
 11a:	89 e5                	mov    %esp,%ebp
 11c:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 11f:	8b 45 08             	mov    0x8(%ebp),%eax
 122:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 125:	90                   	nop
 126:	8b 45 0c             	mov    0xc(%ebp),%eax
 129:	0f b6 10             	movzbl (%eax),%edx
 12c:	8b 45 08             	mov    0x8(%ebp),%eax
 12f:	88 10                	mov    %dl,(%eax)
 131:	8b 45 08             	mov    0x8(%ebp),%eax
 134:	0f b6 00             	movzbl (%eax),%eax
 137:	84 c0                	test   %al,%al
 139:	0f 95 c0             	setne  %al
 13c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 140:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
 144:	84 c0                	test   %al,%al
 146:	75 de                	jne    126 <strcpy+0xd>
    ;
  return os;
 148:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 14b:	c9                   	leave  
 14c:	c3                   	ret    

0000014d <strcmp>:

int
strcmp(const char *p, const char *q)
{
 14d:	55                   	push   %ebp
 14e:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 150:	eb 08                	jmp    15a <strcmp+0xd>
    p++, q++;
 152:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 156:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 15a:	8b 45 08             	mov    0x8(%ebp),%eax
 15d:	0f b6 00             	movzbl (%eax),%eax
 160:	84 c0                	test   %al,%al
 162:	74 10                	je     174 <strcmp+0x27>
 164:	8b 45 08             	mov    0x8(%ebp),%eax
 167:	0f b6 10             	movzbl (%eax),%edx
 16a:	8b 45 0c             	mov    0xc(%ebp),%eax
 16d:	0f b6 00             	movzbl (%eax),%eax
 170:	38 c2                	cmp    %al,%dl
 172:	74 de                	je     152 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 174:	8b 45 08             	mov    0x8(%ebp),%eax
 177:	0f b6 00             	movzbl (%eax),%eax
 17a:	0f b6 d0             	movzbl %al,%edx
 17d:	8b 45 0c             	mov    0xc(%ebp),%eax
 180:	0f b6 00             	movzbl (%eax),%eax
 183:	0f b6 c0             	movzbl %al,%eax
 186:	89 d1                	mov    %edx,%ecx
 188:	29 c1                	sub    %eax,%ecx
 18a:	89 c8                	mov    %ecx,%eax
}
 18c:	5d                   	pop    %ebp
 18d:	c3                   	ret    

0000018e <strlen>:

uint
strlen(char *s)
{
 18e:	55                   	push   %ebp
 18f:	89 e5                	mov    %esp,%ebp
 191:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 194:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 19b:	eb 04                	jmp    1a1 <strlen+0x13>
 19d:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 1a1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 1a4:	03 45 08             	add    0x8(%ebp),%eax
 1a7:	0f b6 00             	movzbl (%eax),%eax
 1aa:	84 c0                	test   %al,%al
 1ac:	75 ef                	jne    19d <strlen+0xf>
    ;
  return n;
 1ae:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 1b1:	c9                   	leave  
 1b2:	c3                   	ret    

000001b3 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1b3:	55                   	push   %ebp
 1b4:	89 e5                	mov    %esp,%ebp
 1b6:	83 ec 0c             	sub    $0xc,%esp
  stosb(dst, c, n);
 1b9:	8b 45 10             	mov    0x10(%ebp),%eax
 1bc:	89 44 24 08          	mov    %eax,0x8(%esp)
 1c0:	8b 45 0c             	mov    0xc(%ebp),%eax
 1c3:	89 44 24 04          	mov    %eax,0x4(%esp)
 1c7:	8b 45 08             	mov    0x8(%ebp),%eax
 1ca:	89 04 24             	mov    %eax,(%esp)
 1cd:	e8 22 ff ff ff       	call   f4 <stosb>
  return dst;
 1d2:	8b 45 08             	mov    0x8(%ebp),%eax
}
 1d5:	c9                   	leave  
 1d6:	c3                   	ret    

000001d7 <strchr>:

char*
strchr(const char *s, char c)
{
 1d7:	55                   	push   %ebp
 1d8:	89 e5                	mov    %esp,%ebp
 1da:	83 ec 04             	sub    $0x4,%esp
 1dd:	8b 45 0c             	mov    0xc(%ebp),%eax
 1e0:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 1e3:	eb 14                	jmp    1f9 <strchr+0x22>
    if(*s == c)
 1e5:	8b 45 08             	mov    0x8(%ebp),%eax
 1e8:	0f b6 00             	movzbl (%eax),%eax
 1eb:	3a 45 fc             	cmp    -0x4(%ebp),%al
 1ee:	75 05                	jne    1f5 <strchr+0x1e>
      return (char*)s;
 1f0:	8b 45 08             	mov    0x8(%ebp),%eax
 1f3:	eb 13                	jmp    208 <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 1f5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 1f9:	8b 45 08             	mov    0x8(%ebp),%eax
 1fc:	0f b6 00             	movzbl (%eax),%eax
 1ff:	84 c0                	test   %al,%al
 201:	75 e2                	jne    1e5 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 203:	b8 00 00 00 00       	mov    $0x0,%eax
}
 208:	c9                   	leave  
 209:	c3                   	ret    

0000020a <gets>:

char*
gets(char *buf, int max)
{
 20a:	55                   	push   %ebp
 20b:	89 e5                	mov    %esp,%ebp
 20d:	83 ec 28             	sub    $0x28,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 210:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 217:	eb 44                	jmp    25d <gets+0x53>
    cc = read(0, &c, 1);
 219:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 220:	00 
 221:	8d 45 ef             	lea    -0x11(%ebp),%eax
 224:	89 44 24 04          	mov    %eax,0x4(%esp)
 228:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
 22f:	e8 3c 01 00 00       	call   370 <read>
 234:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 237:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 23b:	7e 2d                	jle    26a <gets+0x60>
      break;
    buf[i++] = c;
 23d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 240:	03 45 08             	add    0x8(%ebp),%eax
 243:	0f b6 55 ef          	movzbl -0x11(%ebp),%edx
 247:	88 10                	mov    %dl,(%eax)
 249:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
    if(c == '\n' || c == '\r')
 24d:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 251:	3c 0a                	cmp    $0xa,%al
 253:	74 16                	je     26b <gets+0x61>
 255:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 259:	3c 0d                	cmp    $0xd,%al
 25b:	74 0e                	je     26b <gets+0x61>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 25d:	8b 45 f4             	mov    -0xc(%ebp),%eax
 260:	83 c0 01             	add    $0x1,%eax
 263:	3b 45 0c             	cmp    0xc(%ebp),%eax
 266:	7c b1                	jl     219 <gets+0xf>
 268:	eb 01                	jmp    26b <gets+0x61>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 26a:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 26b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 26e:	03 45 08             	add    0x8(%ebp),%eax
 271:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 274:	8b 45 08             	mov    0x8(%ebp),%eax
}
 277:	c9                   	leave  
 278:	c3                   	ret    

00000279 <stat>:

int
stat(char *n, struct stat *st)
{
 279:	55                   	push   %ebp
 27a:	89 e5                	mov    %esp,%ebp
 27c:	83 ec 28             	sub    $0x28,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 27f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
 286:	00 
 287:	8b 45 08             	mov    0x8(%ebp),%eax
 28a:	89 04 24             	mov    %eax,(%esp)
 28d:	e8 06 01 00 00       	call   398 <open>
 292:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 295:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 299:	79 07                	jns    2a2 <stat+0x29>
    return -1;
 29b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 2a0:	eb 23                	jmp    2c5 <stat+0x4c>
  r = fstat(fd, st);
 2a2:	8b 45 0c             	mov    0xc(%ebp),%eax
 2a5:	89 44 24 04          	mov    %eax,0x4(%esp)
 2a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2ac:	89 04 24             	mov    %eax,(%esp)
 2af:	e8 fc 00 00 00       	call   3b0 <fstat>
 2b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 2b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2ba:	89 04 24             	mov    %eax,(%esp)
 2bd:	e8 be 00 00 00       	call   380 <close>
  return r;
 2c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 2c5:	c9                   	leave  
 2c6:	c3                   	ret    

000002c7 <atoi>:

int
atoi(const char *s)
{
 2c7:	55                   	push   %ebp
 2c8:	89 e5                	mov    %esp,%ebp
 2ca:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 2cd:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 2d4:	eb 23                	jmp    2f9 <atoi+0x32>
    n = n*10 + *s++ - '0';
 2d6:	8b 55 fc             	mov    -0x4(%ebp),%edx
 2d9:	89 d0                	mov    %edx,%eax
 2db:	c1 e0 02             	shl    $0x2,%eax
 2de:	01 d0                	add    %edx,%eax
 2e0:	01 c0                	add    %eax,%eax
 2e2:	89 c2                	mov    %eax,%edx
 2e4:	8b 45 08             	mov    0x8(%ebp),%eax
 2e7:	0f b6 00             	movzbl (%eax),%eax
 2ea:	0f be c0             	movsbl %al,%eax
 2ed:	01 d0                	add    %edx,%eax
 2ef:	83 e8 30             	sub    $0x30,%eax
 2f2:	89 45 fc             	mov    %eax,-0x4(%ebp)
 2f5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2f9:	8b 45 08             	mov    0x8(%ebp),%eax
 2fc:	0f b6 00             	movzbl (%eax),%eax
 2ff:	3c 2f                	cmp    $0x2f,%al
 301:	7e 0a                	jle    30d <atoi+0x46>
 303:	8b 45 08             	mov    0x8(%ebp),%eax
 306:	0f b6 00             	movzbl (%eax),%eax
 309:	3c 39                	cmp    $0x39,%al
 30b:	7e c9                	jle    2d6 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 30d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 310:	c9                   	leave  
 311:	c3                   	ret    

00000312 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 312:	55                   	push   %ebp
 313:	89 e5                	mov    %esp,%ebp
 315:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;
  
  dst = vdst;
 318:	8b 45 08             	mov    0x8(%ebp),%eax
 31b:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 31e:	8b 45 0c             	mov    0xc(%ebp),%eax
 321:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 324:	eb 13                	jmp    339 <memmove+0x27>
    *dst++ = *src++;
 326:	8b 45 f8             	mov    -0x8(%ebp),%eax
 329:	0f b6 10             	movzbl (%eax),%edx
 32c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 32f:	88 10                	mov    %dl,(%eax)
 331:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 335:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  char *dst, *src;
  
  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 339:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
 33d:	0f 9f c0             	setg   %al
 340:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
 344:	84 c0                	test   %al,%al
 346:	75 de                	jne    326 <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 348:	8b 45 08             	mov    0x8(%ebp),%eax
}
 34b:	c9                   	leave  
 34c:	c3                   	ret    
 34d:	90                   	nop
 34e:	90                   	nop
 34f:	90                   	nop

00000350 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 350:	b8 01 00 00 00       	mov    $0x1,%eax
 355:	cd 40                	int    $0x40
 357:	c3                   	ret    

00000358 <exit>:
SYSCALL(exit)
 358:	b8 02 00 00 00       	mov    $0x2,%eax
 35d:	cd 40                	int    $0x40
 35f:	c3                   	ret    

00000360 <wait>:
SYSCALL(wait)
 360:	b8 03 00 00 00       	mov    $0x3,%eax
 365:	cd 40                	int    $0x40
 367:	c3                   	ret    

00000368 <pipe>:
SYSCALL(pipe)
 368:	b8 04 00 00 00       	mov    $0x4,%eax
 36d:	cd 40                	int    $0x40
 36f:	c3                   	ret    

00000370 <read>:
SYSCALL(read)
 370:	b8 05 00 00 00       	mov    $0x5,%eax
 375:	cd 40                	int    $0x40
 377:	c3                   	ret    

00000378 <write>:
SYSCALL(write)
 378:	b8 10 00 00 00       	mov    $0x10,%eax
 37d:	cd 40                	int    $0x40
 37f:	c3                   	ret    

00000380 <close>:
SYSCALL(close)
 380:	b8 15 00 00 00       	mov    $0x15,%eax
 385:	cd 40                	int    $0x40
 387:	c3                   	ret    

00000388 <kill>:
SYSCALL(kill)
 388:	b8 06 00 00 00       	mov    $0x6,%eax
 38d:	cd 40                	int    $0x40
 38f:	c3                   	ret    

00000390 <exec>:
SYSCALL(exec)
 390:	b8 07 00 00 00       	mov    $0x7,%eax
 395:	cd 40                	int    $0x40
 397:	c3                   	ret    

00000398 <open>:
SYSCALL(open)
 398:	b8 0f 00 00 00       	mov    $0xf,%eax
 39d:	cd 40                	int    $0x40
 39f:	c3                   	ret    

000003a0 <mknod>:
SYSCALL(mknod)
 3a0:	b8 11 00 00 00       	mov    $0x11,%eax
 3a5:	cd 40                	int    $0x40
 3a7:	c3                   	ret    

000003a8 <unlink>:
SYSCALL(unlink)
 3a8:	b8 12 00 00 00       	mov    $0x12,%eax
 3ad:	cd 40                	int    $0x40
 3af:	c3                   	ret    

000003b0 <fstat>:
SYSCALL(fstat)
 3b0:	b8 08 00 00 00       	mov    $0x8,%eax
 3b5:	cd 40                	int    $0x40
 3b7:	c3                   	ret    

000003b8 <link>:
SYSCALL(link)
 3b8:	b8 13 00 00 00       	mov    $0x13,%eax
 3bd:	cd 40                	int    $0x40
 3bf:	c3                   	ret    

000003c0 <mkdir>:
SYSCALL(mkdir)
 3c0:	b8 14 00 00 00       	mov    $0x14,%eax
 3c5:	cd 40                	int    $0x40
 3c7:	c3                   	ret    

000003c8 <chdir>:
SYSCALL(chdir)
 3c8:	b8 09 00 00 00       	mov    $0x9,%eax
 3cd:	cd 40                	int    $0x40
 3cf:	c3                   	ret    

000003d0 <dup>:
SYSCALL(dup)
 3d0:	b8 0a 00 00 00       	mov    $0xa,%eax
 3d5:	cd 40                	int    $0x40
 3d7:	c3                   	ret    

000003d8 <getpid>:
SYSCALL(getpid)
 3d8:	b8 0b 00 00 00       	mov    $0xb,%eax
 3dd:	cd 40                	int    $0x40
 3df:	c3                   	ret    

000003e0 <sbrk>:
SYSCALL(sbrk)
 3e0:	b8 0c 00 00 00       	mov    $0xc,%eax
 3e5:	cd 40                	int    $0x40
 3e7:	c3                   	ret    

000003e8 <sleep>:
SYSCALL(sleep)
 3e8:	b8 0d 00 00 00       	mov    $0xd,%eax
 3ed:	cd 40                	int    $0x40
 3ef:	c3                   	ret    

000003f0 <uptime>:
SYSCALL(uptime)
 3f0:	b8 0e 00 00 00       	mov    $0xe,%eax
 3f5:	cd 40                	int    $0x40
 3f7:	c3                   	ret    

000003f8 <add_path>:
 3f8:	b8 16 00 00 00       	mov    $0x16,%eax
 3fd:	cd 40                	int    $0x40
 3ff:	c3                   	ret    

00000400 <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 400:	55                   	push   %ebp
 401:	89 e5                	mov    %esp,%ebp
 403:	83 ec 28             	sub    $0x28,%esp
 406:	8b 45 0c             	mov    0xc(%ebp),%eax
 409:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 40c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
 413:	00 
 414:	8d 45 f4             	lea    -0xc(%ebp),%eax
 417:	89 44 24 04          	mov    %eax,0x4(%esp)
 41b:	8b 45 08             	mov    0x8(%ebp),%eax
 41e:	89 04 24             	mov    %eax,(%esp)
 421:	e8 52 ff ff ff       	call   378 <write>
}
 426:	c9                   	leave  
 427:	c3                   	ret    

00000428 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 428:	55                   	push   %ebp
 429:	89 e5                	mov    %esp,%ebp
 42b:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 42e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 435:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 439:	74 17                	je     452 <printint+0x2a>
 43b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 43f:	79 11                	jns    452 <printint+0x2a>
    neg = 1;
 441:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 448:	8b 45 0c             	mov    0xc(%ebp),%eax
 44b:	f7 d8                	neg    %eax
 44d:	89 45 ec             	mov    %eax,-0x14(%ebp)
 450:	eb 06                	jmp    458 <printint+0x30>
  } else {
    x = xx;
 452:	8b 45 0c             	mov    0xc(%ebp),%eax
 455:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 458:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 45f:	8b 4d 10             	mov    0x10(%ebp),%ecx
 462:	8b 45 ec             	mov    -0x14(%ebp),%eax
 465:	ba 00 00 00 00       	mov    $0x0,%edx
 46a:	f7 f1                	div    %ecx
 46c:	89 d0                	mov    %edx,%eax
 46e:	0f b6 90 00 0b 00 00 	movzbl 0xb00(%eax),%edx
 475:	8d 45 dc             	lea    -0x24(%ebp),%eax
 478:	03 45 f4             	add    -0xc(%ebp),%eax
 47b:	88 10                	mov    %dl,(%eax)
 47d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
 481:	8b 55 10             	mov    0x10(%ebp),%edx
 484:	89 55 d4             	mov    %edx,-0x2c(%ebp)
 487:	8b 45 ec             	mov    -0x14(%ebp),%eax
 48a:	ba 00 00 00 00       	mov    $0x0,%edx
 48f:	f7 75 d4             	divl   -0x2c(%ebp)
 492:	89 45 ec             	mov    %eax,-0x14(%ebp)
 495:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 499:	75 c4                	jne    45f <printint+0x37>
  if(neg)
 49b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 49f:	74 2a                	je     4cb <printint+0xa3>
    buf[i++] = '-';
 4a1:	8d 45 dc             	lea    -0x24(%ebp),%eax
 4a4:	03 45 f4             	add    -0xc(%ebp),%eax
 4a7:	c6 00 2d             	movb   $0x2d,(%eax)
 4aa:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
 4ae:	eb 1b                	jmp    4cb <printint+0xa3>
    putc(fd, buf[i]);
 4b0:	8d 45 dc             	lea    -0x24(%ebp),%eax
 4b3:	03 45 f4             	add    -0xc(%ebp),%eax
 4b6:	0f b6 00             	movzbl (%eax),%eax
 4b9:	0f be c0             	movsbl %al,%eax
 4bc:	89 44 24 04          	mov    %eax,0x4(%esp)
 4c0:	8b 45 08             	mov    0x8(%ebp),%eax
 4c3:	89 04 24             	mov    %eax,(%esp)
 4c6:	e8 35 ff ff ff       	call   400 <putc>
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 4cb:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 4cf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 4d3:	79 db                	jns    4b0 <printint+0x88>
    putc(fd, buf[i]);
}
 4d5:	c9                   	leave  
 4d6:	c3                   	ret    

000004d7 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 4d7:	55                   	push   %ebp
 4d8:	89 e5                	mov    %esp,%ebp
 4da:	83 ec 38             	sub    $0x38,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 4dd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 4e4:	8d 45 0c             	lea    0xc(%ebp),%eax
 4e7:	83 c0 04             	add    $0x4,%eax
 4ea:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 4ed:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 4f4:	e9 7d 01 00 00       	jmp    676 <printf+0x19f>
    c = fmt[i] & 0xff;
 4f9:	8b 55 0c             	mov    0xc(%ebp),%edx
 4fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
 4ff:	01 d0                	add    %edx,%eax
 501:	0f b6 00             	movzbl (%eax),%eax
 504:	0f be c0             	movsbl %al,%eax
 507:	25 ff 00 00 00       	and    $0xff,%eax
 50c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 50f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 513:	75 2c                	jne    541 <printf+0x6a>
      if(c == '%'){
 515:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 519:	75 0c                	jne    527 <printf+0x50>
        state = '%';
 51b:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 522:	e9 4b 01 00 00       	jmp    672 <printf+0x19b>
      } else {
        putc(fd, c);
 527:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 52a:	0f be c0             	movsbl %al,%eax
 52d:	89 44 24 04          	mov    %eax,0x4(%esp)
 531:	8b 45 08             	mov    0x8(%ebp),%eax
 534:	89 04 24             	mov    %eax,(%esp)
 537:	e8 c4 fe ff ff       	call   400 <putc>
 53c:	e9 31 01 00 00       	jmp    672 <printf+0x19b>
      }
    } else if(state == '%'){
 541:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 545:	0f 85 27 01 00 00    	jne    672 <printf+0x19b>
      if(c == 'd'){
 54b:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 54f:	75 2d                	jne    57e <printf+0xa7>
        printint(fd, *ap, 10, 1);
 551:	8b 45 e8             	mov    -0x18(%ebp),%eax
 554:	8b 00                	mov    (%eax),%eax
 556:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
 55d:	00 
 55e:	c7 44 24 08 0a 00 00 	movl   $0xa,0x8(%esp)
 565:	00 
 566:	89 44 24 04          	mov    %eax,0x4(%esp)
 56a:	8b 45 08             	mov    0x8(%ebp),%eax
 56d:	89 04 24             	mov    %eax,(%esp)
 570:	e8 b3 fe ff ff       	call   428 <printint>
        ap++;
 575:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 579:	e9 ed 00 00 00       	jmp    66b <printf+0x194>
      } else if(c == 'x' || c == 'p'){
 57e:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 582:	74 06                	je     58a <printf+0xb3>
 584:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 588:	75 2d                	jne    5b7 <printf+0xe0>
        printint(fd, *ap, 16, 0);
 58a:	8b 45 e8             	mov    -0x18(%ebp),%eax
 58d:	8b 00                	mov    (%eax),%eax
 58f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
 596:	00 
 597:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
 59e:	00 
 59f:	89 44 24 04          	mov    %eax,0x4(%esp)
 5a3:	8b 45 08             	mov    0x8(%ebp),%eax
 5a6:	89 04 24             	mov    %eax,(%esp)
 5a9:	e8 7a fe ff ff       	call   428 <printint>
        ap++;
 5ae:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 5b2:	e9 b4 00 00 00       	jmp    66b <printf+0x194>
      } else if(c == 's'){
 5b7:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 5bb:	75 46                	jne    603 <printf+0x12c>
        s = (char*)*ap;
 5bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5c0:	8b 00                	mov    (%eax),%eax
 5c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 5c5:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 5c9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 5cd:	75 27                	jne    5f6 <printf+0x11f>
          s = "(null)";
 5cf:	c7 45 f4 bd 08 00 00 	movl   $0x8bd,-0xc(%ebp)
        while(*s != 0){
 5d6:	eb 1e                	jmp    5f6 <printf+0x11f>
          putc(fd, *s);
 5d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5db:	0f b6 00             	movzbl (%eax),%eax
 5de:	0f be c0             	movsbl %al,%eax
 5e1:	89 44 24 04          	mov    %eax,0x4(%esp)
 5e5:	8b 45 08             	mov    0x8(%ebp),%eax
 5e8:	89 04 24             	mov    %eax,(%esp)
 5eb:	e8 10 fe ff ff       	call   400 <putc>
          s++;
 5f0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 5f4:	eb 01                	jmp    5f7 <printf+0x120>
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 5f6:	90                   	nop
 5f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 5fa:	0f b6 00             	movzbl (%eax),%eax
 5fd:	84 c0                	test   %al,%al
 5ff:	75 d7                	jne    5d8 <printf+0x101>
 601:	eb 68                	jmp    66b <printf+0x194>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 603:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 607:	75 1d                	jne    626 <printf+0x14f>
        putc(fd, *ap);
 609:	8b 45 e8             	mov    -0x18(%ebp),%eax
 60c:	8b 00                	mov    (%eax),%eax
 60e:	0f be c0             	movsbl %al,%eax
 611:	89 44 24 04          	mov    %eax,0x4(%esp)
 615:	8b 45 08             	mov    0x8(%ebp),%eax
 618:	89 04 24             	mov    %eax,(%esp)
 61b:	e8 e0 fd ff ff       	call   400 <putc>
        ap++;
 620:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 624:	eb 45                	jmp    66b <printf+0x194>
      } else if(c == '%'){
 626:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 62a:	75 17                	jne    643 <printf+0x16c>
        putc(fd, c);
 62c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 62f:	0f be c0             	movsbl %al,%eax
 632:	89 44 24 04          	mov    %eax,0x4(%esp)
 636:	8b 45 08             	mov    0x8(%ebp),%eax
 639:	89 04 24             	mov    %eax,(%esp)
 63c:	e8 bf fd ff ff       	call   400 <putc>
 641:	eb 28                	jmp    66b <printf+0x194>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 643:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
 64a:	00 
 64b:	8b 45 08             	mov    0x8(%ebp),%eax
 64e:	89 04 24             	mov    %eax,(%esp)
 651:	e8 aa fd ff ff       	call   400 <putc>
        putc(fd, c);
 656:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 659:	0f be c0             	movsbl %al,%eax
 65c:	89 44 24 04          	mov    %eax,0x4(%esp)
 660:	8b 45 08             	mov    0x8(%ebp),%eax
 663:	89 04 24             	mov    %eax,(%esp)
 666:	e8 95 fd ff ff       	call   400 <putc>
      }
      state = 0;
 66b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 672:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 676:	8b 55 0c             	mov    0xc(%ebp),%edx
 679:	8b 45 f0             	mov    -0x10(%ebp),%eax
 67c:	01 d0                	add    %edx,%eax
 67e:	0f b6 00             	movzbl (%eax),%eax
 681:	84 c0                	test   %al,%al
 683:	0f 85 70 fe ff ff    	jne    4f9 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 689:	c9                   	leave  
 68a:	c3                   	ret    
 68b:	90                   	nop

0000068c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 68c:	55                   	push   %ebp
 68d:	89 e5                	mov    %esp,%ebp
 68f:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 692:	8b 45 08             	mov    0x8(%ebp),%eax
 695:	83 e8 08             	sub    $0x8,%eax
 698:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 69b:	a1 1c 0b 00 00       	mov    0xb1c,%eax
 6a0:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6a3:	eb 24                	jmp    6c9 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6a8:	8b 00                	mov    (%eax),%eax
 6aa:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6ad:	77 12                	ja     6c1 <free+0x35>
 6af:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6b2:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6b5:	77 24                	ja     6db <free+0x4f>
 6b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6ba:	8b 00                	mov    (%eax),%eax
 6bc:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6bf:	77 1a                	ja     6db <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6c1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6c4:	8b 00                	mov    (%eax),%eax
 6c6:	89 45 fc             	mov    %eax,-0x4(%ebp)
 6c9:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6cc:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 6cf:	76 d4                	jbe    6a5 <free+0x19>
 6d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6d4:	8b 00                	mov    (%eax),%eax
 6d6:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 6d9:	76 ca                	jbe    6a5 <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 6db:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6de:	8b 40 04             	mov    0x4(%eax),%eax
 6e1:	c1 e0 03             	shl    $0x3,%eax
 6e4:	89 c2                	mov    %eax,%edx
 6e6:	03 55 f8             	add    -0x8(%ebp),%edx
 6e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6ec:	8b 00                	mov    (%eax),%eax
 6ee:	39 c2                	cmp    %eax,%edx
 6f0:	75 24                	jne    716 <free+0x8a>
    bp->s.size += p->s.ptr->s.size;
 6f2:	8b 45 f8             	mov    -0x8(%ebp),%eax
 6f5:	8b 50 04             	mov    0x4(%eax),%edx
 6f8:	8b 45 fc             	mov    -0x4(%ebp),%eax
 6fb:	8b 00                	mov    (%eax),%eax
 6fd:	8b 40 04             	mov    0x4(%eax),%eax
 700:	01 c2                	add    %eax,%edx
 702:	8b 45 f8             	mov    -0x8(%ebp),%eax
 705:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 708:	8b 45 fc             	mov    -0x4(%ebp),%eax
 70b:	8b 00                	mov    (%eax),%eax
 70d:	8b 10                	mov    (%eax),%edx
 70f:	8b 45 f8             	mov    -0x8(%ebp),%eax
 712:	89 10                	mov    %edx,(%eax)
 714:	eb 0a                	jmp    720 <free+0x94>
  } else
    bp->s.ptr = p->s.ptr;
 716:	8b 45 fc             	mov    -0x4(%ebp),%eax
 719:	8b 10                	mov    (%eax),%edx
 71b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 71e:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 720:	8b 45 fc             	mov    -0x4(%ebp),%eax
 723:	8b 40 04             	mov    0x4(%eax),%eax
 726:	c1 e0 03             	shl    $0x3,%eax
 729:	03 45 fc             	add    -0x4(%ebp),%eax
 72c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 72f:	75 20                	jne    751 <free+0xc5>
    p->s.size += bp->s.size;
 731:	8b 45 fc             	mov    -0x4(%ebp),%eax
 734:	8b 50 04             	mov    0x4(%eax),%edx
 737:	8b 45 f8             	mov    -0x8(%ebp),%eax
 73a:	8b 40 04             	mov    0x4(%eax),%eax
 73d:	01 c2                	add    %eax,%edx
 73f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 742:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 745:	8b 45 f8             	mov    -0x8(%ebp),%eax
 748:	8b 10                	mov    (%eax),%edx
 74a:	8b 45 fc             	mov    -0x4(%ebp),%eax
 74d:	89 10                	mov    %edx,(%eax)
 74f:	eb 08                	jmp    759 <free+0xcd>
  } else
    p->s.ptr = bp;
 751:	8b 45 fc             	mov    -0x4(%ebp),%eax
 754:	8b 55 f8             	mov    -0x8(%ebp),%edx
 757:	89 10                	mov    %edx,(%eax)
  freep = p;
 759:	8b 45 fc             	mov    -0x4(%ebp),%eax
 75c:	a3 1c 0b 00 00       	mov    %eax,0xb1c
}
 761:	c9                   	leave  
 762:	c3                   	ret    

00000763 <morecore>:

static Header*
morecore(uint nu)
{
 763:	55                   	push   %ebp
 764:	89 e5                	mov    %esp,%ebp
 766:	83 ec 28             	sub    $0x28,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 769:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 770:	77 07                	ja     779 <morecore+0x16>
    nu = 4096;
 772:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 779:	8b 45 08             	mov    0x8(%ebp),%eax
 77c:	c1 e0 03             	shl    $0x3,%eax
 77f:	89 04 24             	mov    %eax,(%esp)
 782:	e8 59 fc ff ff       	call   3e0 <sbrk>
 787:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 78a:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 78e:	75 07                	jne    797 <morecore+0x34>
    return 0;
 790:	b8 00 00 00 00       	mov    $0x0,%eax
 795:	eb 22                	jmp    7b9 <morecore+0x56>
  hp = (Header*)p;
 797:	8b 45 f4             	mov    -0xc(%ebp),%eax
 79a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 79d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7a0:	8b 55 08             	mov    0x8(%ebp),%edx
 7a3:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 7a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7a9:	83 c0 08             	add    $0x8,%eax
 7ac:	89 04 24             	mov    %eax,(%esp)
 7af:	e8 d8 fe ff ff       	call   68c <free>
  return freep;
 7b4:	a1 1c 0b 00 00       	mov    0xb1c,%eax
}
 7b9:	c9                   	leave  
 7ba:	c3                   	ret    

000007bb <malloc>:

void*
malloc(uint nbytes)
{
 7bb:	55                   	push   %ebp
 7bc:	89 e5                	mov    %esp,%ebp
 7be:	83 ec 28             	sub    $0x28,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7c1:	8b 45 08             	mov    0x8(%ebp),%eax
 7c4:	83 c0 07             	add    $0x7,%eax
 7c7:	c1 e8 03             	shr    $0x3,%eax
 7ca:	83 c0 01             	add    $0x1,%eax
 7cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 7d0:	a1 1c 0b 00 00       	mov    0xb1c,%eax
 7d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
 7d8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 7dc:	75 23                	jne    801 <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 7de:	c7 45 f0 14 0b 00 00 	movl   $0xb14,-0x10(%ebp)
 7e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
 7e8:	a3 1c 0b 00 00       	mov    %eax,0xb1c
 7ed:	a1 1c 0b 00 00       	mov    0xb1c,%eax
 7f2:	a3 14 0b 00 00       	mov    %eax,0xb14
    base.s.size = 0;
 7f7:	c7 05 18 0b 00 00 00 	movl   $0x0,0xb18
 7fe:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 801:	8b 45 f0             	mov    -0x10(%ebp),%eax
 804:	8b 00                	mov    (%eax),%eax
 806:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 809:	8b 45 f4             	mov    -0xc(%ebp),%eax
 80c:	8b 40 04             	mov    0x4(%eax),%eax
 80f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 812:	72 4d                	jb     861 <malloc+0xa6>
      if(p->s.size == nunits)
 814:	8b 45 f4             	mov    -0xc(%ebp),%eax
 817:	8b 40 04             	mov    0x4(%eax),%eax
 81a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 81d:	75 0c                	jne    82b <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 81f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 822:	8b 10                	mov    (%eax),%edx
 824:	8b 45 f0             	mov    -0x10(%ebp),%eax
 827:	89 10                	mov    %edx,(%eax)
 829:	eb 26                	jmp    851 <malloc+0x96>
      else {
        p->s.size -= nunits;
 82b:	8b 45 f4             	mov    -0xc(%ebp),%eax
 82e:	8b 40 04             	mov    0x4(%eax),%eax
 831:	89 c2                	mov    %eax,%edx
 833:	2b 55 ec             	sub    -0x14(%ebp),%edx
 836:	8b 45 f4             	mov    -0xc(%ebp),%eax
 839:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 83c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 83f:	8b 40 04             	mov    0x4(%eax),%eax
 842:	c1 e0 03             	shl    $0x3,%eax
 845:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 848:	8b 45 f4             	mov    -0xc(%ebp),%eax
 84b:	8b 55 ec             	mov    -0x14(%ebp),%edx
 84e:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 851:	8b 45 f0             	mov    -0x10(%ebp),%eax
 854:	a3 1c 0b 00 00       	mov    %eax,0xb1c
      return (void*)(p + 1);
 859:	8b 45 f4             	mov    -0xc(%ebp),%eax
 85c:	83 c0 08             	add    $0x8,%eax
 85f:	eb 38                	jmp    899 <malloc+0xde>
    }
    if(p == freep)
 861:	a1 1c 0b 00 00       	mov    0xb1c,%eax
 866:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 869:	75 1b                	jne    886 <malloc+0xcb>
      if((p = morecore(nunits)) == 0)
 86b:	8b 45 ec             	mov    -0x14(%ebp),%eax
 86e:	89 04 24             	mov    %eax,(%esp)
 871:	e8 ed fe ff ff       	call   763 <morecore>
 876:	89 45 f4             	mov    %eax,-0xc(%ebp)
 879:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 87d:	75 07                	jne    886 <malloc+0xcb>
        return 0;
 87f:	b8 00 00 00 00       	mov    $0x0,%eax
 884:	eb 13                	jmp    899 <malloc+0xde>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 886:	8b 45 f4             	mov    -0xc(%ebp),%eax
 889:	89 45 f0             	mov    %eax,-0x10(%ebp)
 88c:	8b 45 f4             	mov    -0xc(%ebp),%eax
 88f:	8b 00                	mov    (%eax),%eax
 891:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 894:	e9 70 ff ff ff       	jmp    809 <malloc+0x4e>
}
 899:	c9                   	leave  
 89a:	c3                   	ret    
