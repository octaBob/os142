// Console input and output.
// Input is from the keyboard or serial port.
// Output is written to the screen and serial port.

#include "types.h"
#include "defs.h"
#include "param.h"
#include "traps.h"
#include "spinlock.h"
#include "fs.h"
#include "file.h"
#include "memlayout.h"
#include "mmu.h"
#include "proc.h"
#include "x86.h"

static void consputc(int);

static int panicked = 0;

static struct {
  struct spinlock lock;
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    x = -xx;
  else
    x = xx;

  i = 0;
  do{
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
    consputc(buf[i]);
}
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
  if(locking)
    acquire(&cons.lock);

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    if(c != '%'){
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    case 'd':
      printint(*argp++, 10, 1);
      break;
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
      break;
    case '%':
      consputc('%');
      break;
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
      consputc(c);
      break;
    }
  }

  if(locking)
    release(&cons.lock);
}

void
panic(char *s)
{
  int i;
  uint pcs[10];
  
  cli();
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
  for(;;)
    ;
}

//PAGEBREAK: 50
#define BACKSPACE 0x100
#define CRTPORT 0x3d4
#define UPARROW 0xE2
#define DOWNARROW 0xE3
#define LEFTARROW 0xE4
#define RIGHTARROW 0xE5

static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
  pos = inb(CRTPORT+1) << 8;
  outb(CRTPORT, 15);
  pos |= inb(CRTPORT+1);
  
  if(c == '\n')
    pos += 80 - pos%80;
  
  else if((c == BACKSPACE)||(c == LEFTARROW)){
    if(pos > 0)
      --pos;
  }
  
  else if(c== RIGHTARROW){
     if(pos > 0)
	++pos;

  }else 
  crt[pos++] = (c&0xff) | 0x0700;  // black on white
  
  
  if((pos/80) >= 24){  // Scroll up.
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
    pos -= 80;
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
  }
  
  outb(CRTPORT, 14);
  outb(CRTPORT+1, pos>>8);
  outb(CRTPORT, 15);
  outb(CRTPORT+1, pos);
  if(c==BACKSPACE)
      crt[pos] = ' ' | 0x0700;
}

void
consputc(int c)
{
  if(panicked){
    cli();
    for(;;)
      ;
  }

  if(c == BACKSPACE){
    uartputc('\b'); uartputc(' '); uartputc('\b');
  } else
    uartputc(c);
  cgaputc(c);
}

#define INPUT_BUF 128
struct {
  struct spinlock lock;
  char buf[INPUT_BUF];
  uint r;  // Read index
  uint w;  // Write index
  uint e;  // Edit index
  uint rm; // Right-most index
} input;

#define C(x)  ((x)-'@')  // Control-x

//-----------------PATCH--------------------//


static char history[MAX_HISTORY_LENGTH][INPUT_BUF];
static int hstryNext = 0;
static int hstryPos = 0;
static int numOentries = 0;
//-----------------PATCH--------------------//


void
consoleintr(int (*getc)(void))
{
  int i,j;
  int c;
  acquire(&input.lock);
  while((c = getc()) >= 0){
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
	input.rm--;
        consputc(BACKSPACE);
      }
      break;
       //------------------- PATCH ------------------//
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
	consputc(BACKSPACE);
	input.e--;
	input.rm--;
	if(input.e < input.rm){ //if cursor is not at end of sentance
	  for (i=input.e; i<=input.rm; i++){
	      input.buf[i % INPUT_BUF] = input.buf[i+1 %INPUT_BUF];
	  }
	  for(i = input.e; i <=input.rm; i++)
	      consputc(input.buf[i %INPUT_BUF]);
	  
	  for(i = input.e; i <=input.rm; ++i)
	      consputc(LEFTARROW);
	}
	
      }
      break;
    case UPARROW:
	if(numOentries >=  MAX_HISTORY_LENGTH){
	  if(!((hstryPos %  MAX_HISTORY_LENGTH) ==  (hstryNext+1 %  MAX_HISTORY_LENGTH))){
	      for(i=input.w ; i<input.rm; i++){
	      consputc(BACKSPACE);
	      input.e--;
	      }
	      
	      hstryPos--;
	      for(i = input.w; i<input.rm; i++){
		input.buf[i] = history[hstryPos][i];
	      }
	      cprintf("buf:%s\n",input.buf);
	      input.e += strlen(history[hstryPos]);
	      input.rm = input.e;
	      for(i = input.w; i<input.rm; i++){
		  consputc(input.buf[i]);
	      }
	      
	    
	  }
	}
	else{
	  if((hstryPos %  MAX_HISTORY_LENGTH) > 0){
	      for(i=input.rm ; i>input.w; i--){
		  consputc(BACKSPACE);
		  input.rm--;
		  input.e--;
	      }	
	      hstryPos--;
	      for(i = input.w,j=0; j<(strlen(history[hstryPos])); i++,j++){
		  input.buf[i] = history[hstryPos][j];
	      }
// 	      cprintf("buf:%s\n",input.buf);
// 	      input.e = strlen(history[hstryPos]);
// 	      //cprintf("e:%d\n",input.e);
// // 		  cprintf("buf:%s\n",input.buf);
// 	      input.rm = input.e;
// 
// // 		  cprintf("rm:%d\n",input.rm);
// // 		  cprintf("w:%d\n",input.w);
// 	      for(i = input.w; i<=input.rm; i++){
// 		  consputc(input.buf[i]);
// 	      }
// 	      for(i = input.w; i<input.rm-1; i++){
// 		  consputc(LEFTARROW);
// 	      }
	      
	  }
	      
	    }
	break;
	
    case DOWNARROW:
	if(hstryPos<=hstryNext){
	    if(numOentries >  MAX_HISTORY_LENGTH){
	      input.e++;
	      consputc(RIGHTARROW);
	    }
	}
	break;
      
      
    case RIGHTARROW:
	if(input.e < input.rm){
	  input.e++;
	  consputc(RIGHTARROW);
	}
	break;
    case LEFTARROW:
	if(input.e != input.w){
	  input.e--;
	  consputc(LEFTARROW);
	}
	break;
    //------------------- PATCH ------------------//
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
        c = (c == '\r') ? '\n' : c;
	
	if((c == '\n')&&(input.e<input.rm)){ // case of enter in mid of sentance
	  
	  input.e = input.rm;
	  input.buf[input.e++ % INPUT_BUF] = c;
	  consputc(c);
	  //cprintf("buf enter after left:%s\n",input.buf);
	}else{
	 for (i=input.rm; i>input.e; i--){ //put letter in middle of sentance
 	    input.buf[i % INPUT_BUF] = input.buf[i-1 %INPUT_BUF];
	 }
	  input.buf[input.e++ % INPUT_BUF] = c;
	  consputc(c);

	  for(i = input.e; i <= input.rm; ++i)
	    consputc(input.buf[i]);
	  input.rm++;
	  for(i = input.e; i < input.rm; ++i)
	    consputc(LEFTARROW);
	}

        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
	  //cprintf("buf:%s\n",input.buf);
          input.w = input.e;
	  input.rm = input.e;
	  
	  //
	  j =0;
	  char command[INPUT_BUF];
	  memset(&command[0], 0, sizeof(command));
	  for (i=input.r; i < input.rm-1; i++) {
	    command[j] = input.buf[i %INPUT_BUF];
	    j++;
	    //cprintf("buf:%s\n",input.buf);
	  }
//  	  cprintf("command is:%s",command);
	  //command[j-1] = '\n'; 
	  strncpy(history[hstryNext],command,strlen(command));
	  hstryNext = ((hstryNext+1) %  MAX_HISTORY_LENGTH);
	  hstryPos = hstryNext;
	  numOentries++;
	  //cprintf("next:%d\n",hstryNext);
// 	  for (i=0; i < hstryNext; i++) {
// 	      cprintf("history:%s\n",history[i]);
// 	  }

          wakeup(&input.r);
        }
      }
      break;
    }
  }
  release(&input.lock);
}

int
consoleread(struct inode *ip, char *dst, int n)
{
  uint target;
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
      if(proc->killed){
        release(&input.lock);
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
    if(c == C('D')){  // EOF
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
  }
  release(&input.lock);
  ilock(ip);

  return target - n;
}

int
consolewrite(struct inode *ip, char *buf, int n)
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
    consputc(buf[i] & 0xff);
  release(&cons.lock);
  ilock(ip);

  return n;
}

void
consoleinit(void)
{
  initlock(&cons.lock, "console");
  initlock(&input.lock, "input");

  devsw[CONSOLE].write = consolewrite;
  devsw[CONSOLE].read = consoleread;
  cons.locking = 1;

  picenable(IRQ_KBD);
  ioapicenable(IRQ_KBD, 0);
}

