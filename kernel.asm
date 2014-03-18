
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4 0f                	in     $0xf,%al

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 50 c6 10 80       	mov    $0x8010c650,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 bf 34 10 80       	mov    $0x801034bf,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	c7 44 24 04 58 82 10 	movl   $0x80108258,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 ec 4b 00 00       	call   80104c3a <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 90 db 10 80 84 	movl   $0x8010db84,0x8010db90
80100055:	db 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 94 db 10 80 84 	movl   $0x8010db84,0x8010db94
8010005f:	db 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 94 c6 10 80 	movl   $0x8010c694,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 94 db 10 80       	mov    0x8010db94,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 94 db 10 80       	mov    %eax,0x8010db94

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
801000ac:	72 bd                	jb     8010006b <binit+0x37>
    b->prev = &bcache.head;
    b->dev = -1;
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000ae:	c9                   	leave  
801000af:	c3                   	ret    

801000b0 <bget>:
// Look through buffer cache for sector on device dev.
// If not found, allocate fresh block.
// In either case, return B_BUSY buffer.
static struct buf*
bget(uint dev, uint sector)
{
801000b0:	55                   	push   %ebp
801000b1:	89 e5                	mov    %esp,%ebp
801000b3:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000b6:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801000bd:	e8 99 4b 00 00       	call   80104c5b <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 94 db 10 80       	mov    0x8010db94,%eax
801000c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000ca:	eb 63                	jmp    8010012f <bget+0x7f>
    if(b->dev == dev && b->sector == sector){
801000cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000cf:	8b 40 04             	mov    0x4(%eax),%eax
801000d2:	3b 45 08             	cmp    0x8(%ebp),%eax
801000d5:	75 4f                	jne    80100126 <bget+0x76>
801000d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000da:	8b 40 08             	mov    0x8(%eax),%eax
801000dd:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000e0:	75 44                	jne    80100126 <bget+0x76>
      if(!(b->flags & B_BUSY)){
801000e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e5:	8b 00                	mov    (%eax),%eax
801000e7:	83 e0 01             	and    $0x1,%eax
801000ea:	85 c0                	test   %eax,%eax
801000ec:	75 23                	jne    80100111 <bget+0x61>
        b->flags |= B_BUSY;
801000ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f1:	8b 00                	mov    (%eax),%eax
801000f3:	89 c2                	mov    %eax,%edx
801000f5:	83 ca 01             	or     $0x1,%edx
801000f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000fb:	89 10                	mov    %edx,(%eax)
        release(&bcache.lock);
801000fd:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100104:	e8 b4 4b 00 00       	call   80104cbd <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 59 48 00 00       	call   8010497d <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 90 db 10 80       	mov    0x8010db90,%eax
8010013d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100140:	eb 4d                	jmp    8010018f <bget+0xdf>
    if((b->flags & B_BUSY) == 0 && (b->flags & B_DIRTY) == 0){
80100142:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100145:	8b 00                	mov    (%eax),%eax
80100147:	83 e0 01             	and    $0x1,%eax
8010014a:	85 c0                	test   %eax,%eax
8010014c:	75 38                	jne    80100186 <bget+0xd6>
8010014e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100151:	8b 00                	mov    (%eax),%eax
80100153:	83 e0 04             	and    $0x4,%eax
80100156:	85 c0                	test   %eax,%eax
80100158:	75 2c                	jne    80100186 <bget+0xd6>
      b->dev = dev;
8010015a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010015d:	8b 55 08             	mov    0x8(%ebp),%edx
80100160:	89 50 04             	mov    %edx,0x4(%eax)
      b->sector = sector;
80100163:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100166:	8b 55 0c             	mov    0xc(%ebp),%edx
80100169:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = B_BUSY;
8010016c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
      release(&bcache.lock);
80100175:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010017c:	e8 3c 4b 00 00       	call   80104cbd <release>
      return b;
80100181:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100184:	eb 1e                	jmp    801001a4 <bget+0xf4>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100186:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100189:	8b 40 0c             	mov    0xc(%eax),%eax
8010018c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010018f:	81 7d f4 84 db 10 80 	cmpl   $0x8010db84,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 5f 82 10 80 	movl   $0x8010825f,(%esp)
8010019f:	e8 99 03 00 00       	call   8010053d <panic>
}
801001a4:	c9                   	leave  
801001a5:	c3                   	ret    

801001a6 <bread>:

// Return a B_BUSY buf with the contents of the indicated disk sector.
struct buf*
bread(uint dev, uint sector)
{
801001a6:	55                   	push   %ebp
801001a7:	89 e5                	mov    %esp,%ebp
801001a9:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  b = bget(dev, sector);
801001ac:	8b 45 0c             	mov    0xc(%ebp),%eax
801001af:	89 44 24 04          	mov    %eax,0x4(%esp)
801001b3:	8b 45 08             	mov    0x8(%ebp),%eax
801001b6:	89 04 24             	mov    %eax,(%esp)
801001b9:	e8 f2 fe ff ff       	call   801000b0 <bget>
801001be:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!(b->flags & B_VALID))
801001c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001c4:	8b 00                	mov    (%eax),%eax
801001c6:	83 e0 02             	and    $0x2,%eax
801001c9:	85 c0                	test   %eax,%eax
801001cb:	75 0b                	jne    801001d8 <bread+0x32>
    iderw(b);
801001cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001d0:	89 04 24             	mov    %eax,(%esp)
801001d3:	e8 94 26 00 00       	call   8010286c <iderw>
  return b;
801001d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801001db:	c9                   	leave  
801001dc:	c3                   	ret    

801001dd <bwrite>:

// Write b's contents to disk.  Must be B_BUSY.
void
bwrite(struct buf *b)
{
801001dd:	55                   	push   %ebp
801001de:	89 e5                	mov    %esp,%ebp
801001e0:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
801001e3:	8b 45 08             	mov    0x8(%ebp),%eax
801001e6:	8b 00                	mov    (%eax),%eax
801001e8:	83 e0 01             	and    $0x1,%eax
801001eb:	85 c0                	test   %eax,%eax
801001ed:	75 0c                	jne    801001fb <bwrite+0x1e>
    panic("bwrite");
801001ef:	c7 04 24 70 82 10 80 	movl   $0x80108270,(%esp)
801001f6:	e8 42 03 00 00       	call   8010053d <panic>
  b->flags |= B_DIRTY;
801001fb:	8b 45 08             	mov    0x8(%ebp),%eax
801001fe:	8b 00                	mov    (%eax),%eax
80100200:	89 c2                	mov    %eax,%edx
80100202:	83 ca 04             	or     $0x4,%edx
80100205:	8b 45 08             	mov    0x8(%ebp),%eax
80100208:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010020a:	8b 45 08             	mov    0x8(%ebp),%eax
8010020d:	89 04 24             	mov    %eax,(%esp)
80100210:	e8 57 26 00 00       	call   8010286c <iderw>
}
80100215:	c9                   	leave  
80100216:	c3                   	ret    

80100217 <brelse>:

// Release a B_BUSY buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100217:	55                   	push   %ebp
80100218:	89 e5                	mov    %esp,%ebp
8010021a:	83 ec 18             	sub    $0x18,%esp
  if((b->flags & B_BUSY) == 0)
8010021d:	8b 45 08             	mov    0x8(%ebp),%eax
80100220:	8b 00                	mov    (%eax),%eax
80100222:	83 e0 01             	and    $0x1,%eax
80100225:	85 c0                	test   %eax,%eax
80100227:	75 0c                	jne    80100235 <brelse+0x1e>
    panic("brelse");
80100229:	c7 04 24 77 82 10 80 	movl   $0x80108277,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 1a 4a 00 00       	call   80104c5b <acquire>

  b->next->prev = b->prev;
80100241:	8b 45 08             	mov    0x8(%ebp),%eax
80100244:	8b 40 10             	mov    0x10(%eax),%eax
80100247:	8b 55 08             	mov    0x8(%ebp),%edx
8010024a:	8b 52 0c             	mov    0xc(%edx),%edx
8010024d:	89 50 0c             	mov    %edx,0xc(%eax)
  b->prev->next = b->next;
80100250:	8b 45 08             	mov    0x8(%ebp),%eax
80100253:	8b 40 0c             	mov    0xc(%eax),%eax
80100256:	8b 55 08             	mov    0x8(%ebp),%edx
80100259:	8b 52 10             	mov    0x10(%edx),%edx
8010025c:	89 50 10             	mov    %edx,0x10(%eax)
  b->next = bcache.head.next;
8010025f:	8b 15 94 db 10 80    	mov    0x8010db94,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c 84 db 10 80 	movl   $0x8010db84,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 94 db 10 80       	mov    0x8010db94,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 94 db 10 80       	mov    %eax,0x8010db94

  b->flags &= ~B_BUSY;
80100288:	8b 45 08             	mov    0x8(%ebp),%eax
8010028b:	8b 00                	mov    (%eax),%eax
8010028d:	89 c2                	mov    %eax,%edx
8010028f:	83 e2 fe             	and    $0xfffffffe,%edx
80100292:	8b 45 08             	mov    0x8(%ebp),%eax
80100295:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80100297:	8b 45 08             	mov    0x8(%ebp),%eax
8010029a:	89 04 24             	mov    %eax,(%esp)
8010029d:	e8 b4 47 00 00       	call   80104a56 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 0f 4a 00 00       	call   80104cbd <release>
}
801002ae:	c9                   	leave  
801002af:	c3                   	ret    

801002b0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801002b0:	55                   	push   %ebp
801002b1:	89 e5                	mov    %esp,%ebp
801002b3:	53                   	push   %ebx
801002b4:	83 ec 14             	sub    $0x14,%esp
801002b7:	8b 45 08             	mov    0x8(%ebp),%eax
801002ba:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801002be:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801002c2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801002c6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801002ca:	ec                   	in     (%dx),%al
801002cb:	89 c3                	mov    %eax,%ebx
801002cd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801002d0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801002d4:	83 c4 14             	add    $0x14,%esp
801002d7:	5b                   	pop    %ebx
801002d8:	5d                   	pop    %ebp
801002d9:	c3                   	ret    

801002da <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 08             	sub    $0x8,%esp
801002e0:	8b 55 08             	mov    0x8(%ebp),%edx
801002e3:	8b 45 0c             	mov    0xc(%ebp),%eax
801002e6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801002ea:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801002ed:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801002f1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801002f5:	ee                   	out    %al,(%dx)
}
801002f6:	c9                   	leave  
801002f7:	c3                   	ret    

801002f8 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801002f8:	55                   	push   %ebp
801002f9:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801002fb:	fa                   	cli    
}
801002fc:	5d                   	pop    %ebp
801002fd:	c3                   	ret    

801002fe <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
801002fe:	55                   	push   %ebp
801002ff:	89 e5                	mov    %esp,%ebp
80100301:	83 ec 48             	sub    $0x48,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100304:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100308:	74 19                	je     80100323 <printint+0x25>
8010030a:	8b 45 08             	mov    0x8(%ebp),%eax
8010030d:	c1 e8 1f             	shr    $0x1f,%eax
80100310:	89 45 10             	mov    %eax,0x10(%ebp)
80100313:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100317:	74 0a                	je     80100323 <printint+0x25>
    x = -xx;
80100319:	8b 45 08             	mov    0x8(%ebp),%eax
8010031c:	f7 d8                	neg    %eax
8010031e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100321:	eb 06                	jmp    80100329 <printint+0x2b>
  else
    x = xx;
80100323:	8b 45 08             	mov    0x8(%ebp),%eax
80100326:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100329:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100330:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100333:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100336:	ba 00 00 00 00       	mov    $0x0,%edx
8010033b:	f7 f1                	div    %ecx
8010033d:	89 d0                	mov    %edx,%eax
8010033f:	0f b6 90 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%edx
80100346:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100349:	03 45 f4             	add    -0xc(%ebp),%eax
8010034c:	88 10                	mov    %dl,(%eax)
8010034e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  }while((x /= base) != 0);
80100352:	8b 55 0c             	mov    0xc(%ebp),%edx
80100355:	89 55 d4             	mov    %edx,-0x2c(%ebp)
80100358:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010035b:	ba 00 00 00 00       	mov    $0x0,%edx
80100360:	f7 75 d4             	divl   -0x2c(%ebp)
80100363:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100366:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010036a:	75 c4                	jne    80100330 <printint+0x32>

  if(sign)
8010036c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100370:	74 23                	je     80100395 <printint+0x97>
    buf[i++] = '-';
80100372:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100375:	03 45 f4             	add    -0xc(%ebp),%eax
80100378:	c6 00 2d             	movb   $0x2d,(%eax)
8010037b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

  while(--i >= 0)
8010037f:	eb 14                	jmp    80100395 <printint+0x97>
    consputc(buf[i]);
80100381:	8d 45 e0             	lea    -0x20(%ebp),%eax
80100384:	03 45 f4             	add    -0xc(%ebp),%eax
80100387:	0f b6 00             	movzbl (%eax),%eax
8010038a:	0f be c0             	movsbl %al,%eax
8010038d:	89 04 24             	mov    %eax,(%esp)
80100390:	e8 bb 03 00 00       	call   80100750 <consputc>
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
80100395:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100399:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010039d:	79 e2                	jns    80100381 <printint+0x83>
    consputc(buf[i]);
}
8010039f:	c9                   	leave  
801003a0:	c3                   	ret    

801003a1 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
801003a1:	55                   	push   %ebp
801003a2:	89 e5                	mov    %esp,%ebp
801003a4:	83 ec 38             	sub    $0x38,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
801003a7:	a1 f4 b5 10 80       	mov    0x8010b5f4,%eax
801003ac:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
801003af:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801003b3:	74 0c                	je     801003c1 <cprintf+0x20>
    acquire(&cons.lock);
801003b5:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
801003bc:	e8 9a 48 00 00       	call   80104c5b <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 7e 82 10 80 	movl   $0x8010827e,(%esp)
801003cf:	e8 69 01 00 00       	call   8010053d <panic>

  argp = (uint*)(void*)(&fmt + 1);
801003d4:	8d 45 0c             	lea    0xc(%ebp),%eax
801003d7:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
801003da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801003e1:	e9 20 01 00 00       	jmp    80100506 <cprintf+0x165>
    if(c != '%'){
801003e6:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
801003ea:	74 10                	je     801003fc <cprintf+0x5b>
      consputc(c);
801003ec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801003ef:	89 04 24             	mov    %eax,(%esp)
801003f2:	e8 59 03 00 00       	call   80100750 <consputc>
      continue;
801003f7:	e9 06 01 00 00       	jmp    80100502 <cprintf+0x161>
    }
    c = fmt[++i] & 0xff;
801003fc:	8b 55 08             	mov    0x8(%ebp),%edx
801003ff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100406:	01 d0                	add    %edx,%eax
80100408:	0f b6 00             	movzbl (%eax),%eax
8010040b:	0f be c0             	movsbl %al,%eax
8010040e:	25 ff 00 00 00       	and    $0xff,%eax
80100413:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
80100416:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010041a:	0f 84 08 01 00 00    	je     80100528 <cprintf+0x187>
      break;
    switch(c){
80100420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100423:	83 f8 70             	cmp    $0x70,%eax
80100426:	74 4d                	je     80100475 <cprintf+0xd4>
80100428:	83 f8 70             	cmp    $0x70,%eax
8010042b:	7f 13                	jg     80100440 <cprintf+0x9f>
8010042d:	83 f8 25             	cmp    $0x25,%eax
80100430:	0f 84 a6 00 00 00    	je     801004dc <cprintf+0x13b>
80100436:	83 f8 64             	cmp    $0x64,%eax
80100439:	74 14                	je     8010044f <cprintf+0xae>
8010043b:	e9 aa 00 00 00       	jmp    801004ea <cprintf+0x149>
80100440:	83 f8 73             	cmp    $0x73,%eax
80100443:	74 53                	je     80100498 <cprintf+0xf7>
80100445:	83 f8 78             	cmp    $0x78,%eax
80100448:	74 2b                	je     80100475 <cprintf+0xd4>
8010044a:	e9 9b 00 00 00       	jmp    801004ea <cprintf+0x149>
    case 'd':
      printint(*argp++, 10, 1);
8010044f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100452:	8b 00                	mov    (%eax),%eax
80100454:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
80100458:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010045f:	00 
80100460:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80100467:	00 
80100468:	89 04 24             	mov    %eax,(%esp)
8010046b:	e8 8e fe ff ff       	call   801002fe <printint>
      break;
80100470:	e9 8d 00 00 00       	jmp    80100502 <cprintf+0x161>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
80100475:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100478:	8b 00                	mov    (%eax),%eax
8010047a:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
8010047e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100485:	00 
80100486:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
8010048d:	00 
8010048e:	89 04 24             	mov    %eax,(%esp)
80100491:	e8 68 fe ff ff       	call   801002fe <printint>
      break;
80100496:	eb 6a                	jmp    80100502 <cprintf+0x161>
    case 's':
      if((s = (char*)*argp++) == 0)
80100498:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010049b:	8b 00                	mov    (%eax),%eax
8010049d:	89 45 ec             	mov    %eax,-0x14(%ebp)
801004a0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801004a4:	0f 94 c0             	sete   %al
801004a7:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
801004ab:	84 c0                	test   %al,%al
801004ad:	74 20                	je     801004cf <cprintf+0x12e>
        s = "(null)";
801004af:	c7 45 ec 87 82 10 80 	movl   $0x80108287,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 87 02 00 00       	call   80100750 <consputc>
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
801004c9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801004cd:	eb 01                	jmp    801004d0 <cprintf+0x12f>
801004cf:	90                   	nop
801004d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004d3:	0f b6 00             	movzbl (%eax),%eax
801004d6:	84 c0                	test   %al,%al
801004d8:	75 de                	jne    801004b8 <cprintf+0x117>
        consputc(*s);
      break;
801004da:	eb 26                	jmp    80100502 <cprintf+0x161>
    case '%':
      consputc('%');
801004dc:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004e3:	e8 68 02 00 00       	call   80100750 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 5a 02 00 00       	call   80100750 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 4f 02 00 00       	call   80100750 <consputc>
      break;
80100501:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100502:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100506:	8b 55 08             	mov    0x8(%ebp),%edx
80100509:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010050c:	01 d0                	add    %edx,%eax
8010050e:	0f b6 00             	movzbl (%eax),%eax
80100511:	0f be c0             	movsbl %al,%eax
80100514:	25 ff 00 00 00       	and    $0xff,%eax
80100519:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010051c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100520:	0f 85 c0 fe ff ff    	jne    801003e6 <cprintf+0x45>
80100526:	eb 01                	jmp    80100529 <cprintf+0x188>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100528:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100529:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010052d:	74 0c                	je     8010053b <cprintf+0x19a>
    release(&cons.lock);
8010052f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100536:	e8 82 47 00 00       	call   80104cbd <release>
}
8010053b:	c9                   	leave  
8010053c:	c3                   	ret    

8010053d <panic>:

void
panic(char *s)
{
8010053d:	55                   	push   %ebp
8010053e:	89 e5                	mov    %esp,%ebp
80100540:	83 ec 48             	sub    $0x48,%esp
  int i;
  uint pcs[10];
  
  cli();
80100543:	e8 b0 fd ff ff       	call   801002f8 <cli>
  cons.locking = 0;
80100548:	c7 05 f4 b5 10 80 00 	movl   $0x0,0x8010b5f4
8010054f:	00 00 00 
  cprintf("cpu%d: panic: ", cpu->id);
80100552:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80100558:	0f b6 00             	movzbl (%eax),%eax
8010055b:	0f b6 c0             	movzbl %al,%eax
8010055e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100562:	c7 04 24 8e 82 10 80 	movl   $0x8010828e,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 9d 82 10 80 	movl   $0x8010829d,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 75 47 00 00       	call   80104d0c <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 9f 82 10 80 	movl   $0x8010829f,(%esp)
801005b2:	e8 ea fd ff ff       	call   801003a1 <cprintf>
  cons.locking = 0;
  cprintf("cpu%d: panic: ", cpu->id);
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
801005b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801005bb:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
801005bf:	7e df                	jle    801005a0 <panic+0x63>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
801005c1:	c7 05 a0 b5 10 80 01 	movl   $0x1,0x8010b5a0
801005c8:	00 00 00 
  for(;;)
    ;
801005cb:	eb fe                	jmp    801005cb <panic+0x8e>

801005cd <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
801005cd:	55                   	push   %ebp
801005ce:	89 e5                	mov    %esp,%ebp
801005d0:	83 ec 28             	sub    $0x28,%esp
  int pos;
  
  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
801005d3:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801005da:	00 
801005db:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801005e2:	e8 f3 fc ff ff       	call   801002da <outb>
  pos = inb(CRTPORT+1) << 8;
801005e7:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
801005ee:	e8 bd fc ff ff       	call   801002b0 <inb>
801005f3:	0f b6 c0             	movzbl %al,%eax
801005f6:	c1 e0 08             	shl    $0x8,%eax
801005f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
801005fc:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100603:	00 
80100604:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
8010060b:	e8 ca fc ff ff       	call   801002da <outb>
  pos |= inb(CRTPORT+1);
80100610:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100617:	e8 94 fc ff ff       	call   801002b0 <inb>
8010061c:	0f b6 c0             	movzbl %al,%eax
8010061f:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100622:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100626:	75 30                	jne    80100658 <cgaputc+0x8b>
    pos += 80 - pos%80;
80100628:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010062b:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100630:	89 c8                	mov    %ecx,%eax
80100632:	f7 ea                	imul   %edx
80100634:	c1 fa 05             	sar    $0x5,%edx
80100637:	89 c8                	mov    %ecx,%eax
80100639:	c1 f8 1f             	sar    $0x1f,%eax
8010063c:	29 c2                	sub    %eax,%edx
8010063e:	89 d0                	mov    %edx,%eax
80100640:	c1 e0 02             	shl    $0x2,%eax
80100643:	01 d0                	add    %edx,%eax
80100645:	c1 e0 04             	shl    $0x4,%eax
80100648:	89 ca                	mov    %ecx,%edx
8010064a:	29 c2                	sub    %eax,%edx
8010064c:	b8 50 00 00 00       	mov    $0x50,%eax
80100651:	29 d0                	sub    %edx,%eax
80100653:	01 45 f4             	add    %eax,-0xc(%ebp)
80100656:	eb 32                	jmp    8010068a <cgaputc+0xbd>
  else if(c == BACKSPACE){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	75 0c                	jne    8010066d <cgaputc+0xa0>
    if(pos > 0) --pos;
80100661:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100665:	7e 23                	jle    8010068a <cgaputc+0xbd>
80100667:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
8010066b:	eb 1d                	jmp    8010068a <cgaputc+0xbd>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010066d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100672:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100675:	01 d2                	add    %edx,%edx
80100677:	01 c2                	add    %eax,%edx
80100679:	8b 45 08             	mov    0x8(%ebp),%eax
8010067c:	66 25 ff 00          	and    $0xff,%ax
80100680:	80 cc 07             	or     $0x7,%ah
80100683:	66 89 02             	mov    %ax,(%edx)
80100686:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  if((pos/80) >= 24){  // Scroll up.
8010068a:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
80100691:	7e 53                	jle    801006e6 <cgaputc+0x119>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100693:	a1 00 90 10 80       	mov    0x80109000,%eax
80100698:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010069e:	a1 00 90 10 80       	mov    0x80109000,%eax
801006a3:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006aa:	00 
801006ab:	89 54 24 04          	mov    %edx,0x4(%esp)
801006af:	89 04 24             	mov    %eax,(%esp)
801006b2:	e8 c6 48 00 00       	call   80104f7d <memmove>
    pos -= 80;
801006b7:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006bb:	b8 80 07 00 00       	mov    $0x780,%eax
801006c0:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006c3:	01 c0                	add    %eax,%eax
801006c5:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006cb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ce:	01 c9                	add    %ecx,%ecx
801006d0:	01 ca                	add    %ecx,%edx
801006d2:	89 44 24 08          	mov    %eax,0x8(%esp)
801006d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006dd:	00 
801006de:	89 14 24             	mov    %edx,(%esp)
801006e1:	e8 c4 47 00 00       	call   80104eaa <memset>
  }
  
  outb(CRTPORT, 14);
801006e6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
801006ed:	00 
801006ee:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
801006f5:	e8 e0 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
801006fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006fd:	c1 f8 08             	sar    $0x8,%eax
80100700:	0f b6 c0             	movzbl %al,%eax
80100703:	89 44 24 04          	mov    %eax,0x4(%esp)
80100707:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010070e:	e8 c7 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100713:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010071a:	00 
8010071b:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100722:	e8 b3 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010072a:	0f b6 c0             	movzbl %al,%eax
8010072d:	89 44 24 04          	mov    %eax,0x4(%esp)
80100731:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100738:	e8 9d fb ff ff       	call   801002da <outb>
  crt[pos] = ' ' | 0x0700;
8010073d:	a1 00 90 10 80       	mov    0x80109000,%eax
80100742:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100745:	01 d2                	add    %edx,%edx
80100747:	01 d0                	add    %edx,%eax
80100749:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
8010074e:	c9                   	leave  
8010074f:	c3                   	ret    

80100750 <consputc>:

void
consputc(int c)
{
80100750:	55                   	push   %ebp
80100751:	89 e5                	mov    %esp,%ebp
80100753:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
80100756:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
8010075b:	85 c0                	test   %eax,%eax
8010075d:	74 07                	je     80100766 <consputc+0x16>
    cli();
8010075f:	e8 94 fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
80100764:	eb fe                	jmp    80100764 <consputc+0x14>
  }

  if(c == BACKSPACE){
80100766:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010076d:	75 26                	jne    80100795 <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
8010076f:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
80100776:	e8 42 61 00 00       	call   801068bd <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 36 61 00 00       	call   801068bd <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 2a 61 00 00       	call   801068bd <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 1d 61 00 00       	call   801068bd <uartputc>
  cgaputc(c);
801007a0:	8b 45 08             	mov    0x8(%ebp),%eax
801007a3:	89 04 24             	mov    %eax,(%esp)
801007a6:	e8 22 fe ff ff       	call   801005cd <cgaputc>
}
801007ab:	c9                   	leave  
801007ac:	c3                   	ret    

801007ad <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
801007ad:	55                   	push   %ebp
801007ae:	89 e5                	mov    %esp,%ebp
801007b0:	83 ec 28             	sub    $0x28,%esp
  int c;

  acquire(&input.lock);
801007b3:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
801007ba:	e8 9c 44 00 00       	call   80104c5b <acquire>
  while((c = getc()) >= 0){
801007bf:	e9 41 01 00 00       	jmp    80100905 <consoleintr+0x158>
    switch(c){
801007c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801007c7:	83 f8 10             	cmp    $0x10,%eax
801007ca:	74 1e                	je     801007ea <consoleintr+0x3d>
801007cc:	83 f8 10             	cmp    $0x10,%eax
801007cf:	7f 0a                	jg     801007db <consoleintr+0x2e>
801007d1:	83 f8 08             	cmp    $0x8,%eax
801007d4:	74 68                	je     8010083e <consoleintr+0x91>
801007d6:	e9 94 00 00 00       	jmp    8010086f <consoleintr+0xc2>
801007db:	83 f8 15             	cmp    $0x15,%eax
801007de:	74 2f                	je     8010080f <consoleintr+0x62>
801007e0:	83 f8 7f             	cmp    $0x7f,%eax
801007e3:	74 59                	je     8010083e <consoleintr+0x91>
801007e5:	e9 85 00 00 00       	jmp    8010086f <consoleintr+0xc2>
    case C('P'):  // Process listing.
      procdump();
801007ea:	e8 0a 43 00 00       	call   80104af9 <procdump>
      break;
801007ef:	e9 11 01 00 00       	jmp    80100905 <consoleintr+0x158>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
801007f4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801007f9:	83 e8 01             	sub    $0x1,%eax
801007fc:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
80100801:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100808:	e8 43 ff ff ff       	call   80100750 <consputc>
8010080d:	eb 01                	jmp    80100810 <consoleintr+0x63>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010080f:	90                   	nop
80100810:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100816:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010081b:	39 c2                	cmp    %eax,%edx
8010081d:	0f 84 db 00 00 00    	je     801008fe <consoleintr+0x151>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
80100823:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100828:	83 e8 01             	sub    $0x1,%eax
8010082b:	83 e0 7f             	and    $0x7f,%eax
8010082e:	0f b6 80 d4 dd 10 80 	movzbl -0x7fef222c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100835:	3c 0a                	cmp    $0xa,%al
80100837:	75 bb                	jne    801007f4 <consoleintr+0x47>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100839:	e9 c0 00 00 00       	jmp    801008fe <consoleintr+0x151>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
8010083e:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
80100844:	a1 58 de 10 80       	mov    0x8010de58,%eax
80100849:	39 c2                	cmp    %eax,%edx
8010084b:	0f 84 b0 00 00 00    	je     80100901 <consoleintr+0x154>
        input.e--;
80100851:	a1 5c de 10 80       	mov    0x8010de5c,%eax
80100856:	83 e8 01             	sub    $0x1,%eax
80100859:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(BACKSPACE);
8010085e:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100865:	e8 e6 fe ff ff       	call   80100750 <consputc>
      }
      break;
8010086a:	e9 92 00 00 00       	jmp    80100901 <consoleintr+0x154>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
8010086f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100873:	0f 84 8b 00 00 00    	je     80100904 <consoleintr+0x157>
80100879:	8b 15 5c de 10 80    	mov    0x8010de5c,%edx
8010087f:	a1 54 de 10 80       	mov    0x8010de54,%eax
80100884:	89 d1                	mov    %edx,%ecx
80100886:	29 c1                	sub    %eax,%ecx
80100888:	89 c8                	mov    %ecx,%eax
8010088a:	83 f8 7f             	cmp    $0x7f,%eax
8010088d:	77 75                	ja     80100904 <consoleintr+0x157>
        c = (c == '\r') ? '\n' : c;
8010088f:	83 7d f4 0d          	cmpl   $0xd,-0xc(%ebp)
80100893:	74 05                	je     8010089a <consoleintr+0xed>
80100895:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100898:	eb 05                	jmp    8010089f <consoleintr+0xf2>
8010089a:	b8 0a 00 00 00       	mov    $0xa,%eax
8010089f:	89 45 f4             	mov    %eax,-0xc(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
801008a2:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008a7:	89 c1                	mov    %eax,%ecx
801008a9:	83 e1 7f             	and    $0x7f,%ecx
801008ac:	8b 55 f4             	mov    -0xc(%ebp),%edx
801008af:	88 91 d4 dd 10 80    	mov    %dl,-0x7fef222c(%ecx)
801008b5:	83 c0 01             	add    $0x1,%eax
801008b8:	a3 5c de 10 80       	mov    %eax,0x8010de5c
        consputc(c);
801008bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801008c0:	89 04 24             	mov    %eax,(%esp)
801008c3:	e8 88 fe ff ff       	call   80100750 <consputc>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
801008c8:	83 7d f4 0a          	cmpl   $0xa,-0xc(%ebp)
801008cc:	74 18                	je     801008e6 <consoleintr+0x139>
801008ce:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
801008d2:	74 12                	je     801008e6 <consoleintr+0x139>
801008d4:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008d9:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
801008df:	83 ea 80             	sub    $0xffffff80,%edx
801008e2:	39 d0                	cmp    %edx,%eax
801008e4:	75 1e                	jne    80100904 <consoleintr+0x157>
          input.w = input.e;
801008e6:	a1 5c de 10 80       	mov    0x8010de5c,%eax
801008eb:	a3 58 de 10 80       	mov    %eax,0x8010de58
          wakeup(&input.r);
801008f0:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
801008f7:	e8 5a 41 00 00       	call   80104a56 <wakeup>
        }
      }
      break;
801008fc:	eb 06                	jmp    80100904 <consoleintr+0x157>
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008fe:	90                   	nop
801008ff:	eb 04                	jmp    80100905 <consoleintr+0x158>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
80100901:	90                   	nop
80100902:	eb 01                	jmp    80100905 <consoleintr+0x158>
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
          input.w = input.e;
          wakeup(&input.r);
        }
      }
      break;
80100904:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c;

  acquire(&input.lock);
  while((c = getc()) >= 0){
80100905:	8b 45 08             	mov    0x8(%ebp),%eax
80100908:	ff d0                	call   *%eax
8010090a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100911:	0f 89 ad fe ff ff    	jns    801007c4 <consoleintr+0x17>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100917:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
8010091e:	e8 9a 43 00 00       	call   80104cbd <release>
}
80100923:	c9                   	leave  
80100924:	c3                   	ret    

80100925 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100925:	55                   	push   %ebp
80100926:	89 e5                	mov    %esp,%ebp
80100928:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
8010092b:	8b 45 08             	mov    0x8(%ebp),%eax
8010092e:	89 04 24             	mov    %eax,(%esp)
80100931:	e8 38 11 00 00       	call   80101a6e <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100943:	e8 13 43 00 00       	call   80104c5b <acquire>
  while(n > 0){
80100948:	e9 a8 00 00 00       	jmp    801009f5 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
8010094d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100953:	8b 40 24             	mov    0x24(%eax),%eax
80100956:	85 c0                	test   %eax,%eax
80100958:	74 21                	je     8010097b <consoleread+0x56>
        release(&input.lock);
8010095a:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100961:	e8 57 43 00 00       	call   80104cbd <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 af 0f 00 00       	call   80101920 <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
8010098a:	e8 ee 3f 00 00       	call   8010497d <sleep>
8010098f:	eb 01                	jmp    80100992 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100991:	90                   	nop
80100992:	8b 15 54 de 10 80    	mov    0x8010de54,%edx
80100998:	a1 58 de 10 80       	mov    0x8010de58,%eax
8010099d:	39 c2                	cmp    %eax,%edx
8010099f:	74 ac                	je     8010094d <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
801009a1:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009a6:	89 c2                	mov    %eax,%edx
801009a8:	83 e2 7f             	and    $0x7f,%edx
801009ab:	0f b6 92 d4 dd 10 80 	movzbl -0x7fef222c(%edx),%edx
801009b2:	0f be d2             	movsbl %dl,%edx
801009b5:	89 55 f0             	mov    %edx,-0x10(%ebp)
801009b8:	83 c0 01             	add    $0x1,%eax
801009bb:	a3 54 de 10 80       	mov    %eax,0x8010de54
    if(c == C('D')){  // EOF
801009c0:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
801009c4:	75 17                	jne    801009dd <consoleread+0xb8>
      if(n < target){
801009c6:	8b 45 10             	mov    0x10(%ebp),%eax
801009c9:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801009cc:	73 2f                	jae    801009fd <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
801009ce:	a1 54 de 10 80       	mov    0x8010de54,%eax
801009d3:	83 e8 01             	sub    $0x1,%eax
801009d6:	a3 54 de 10 80       	mov    %eax,0x8010de54
      }
      break;
801009db:	eb 20                	jmp    801009fd <consoleread+0xd8>
    }
    *dst++ = c;
801009dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801009e0:	89 c2                	mov    %eax,%edx
801009e2:	8b 45 0c             	mov    0xc(%ebp),%eax
801009e5:	88 10                	mov    %dl,(%eax)
801009e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
801009eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
801009ef:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
801009f3:	74 0b                	je     80100a00 <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
801009f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801009f9:	7f 96                	jg     80100991 <consoleread+0x6c>
801009fb:	eb 04                	jmp    80100a01 <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
801009fd:	90                   	nop
801009fe:	eb 01                	jmp    80100a01 <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100a00:	90                   	nop
  }
  release(&input.lock);
80100a01:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100a08:	e8 b0 42 00 00       	call   80104cbd <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 08 0f 00 00       	call   80101920 <ilock>

  return target - n;
80100a18:	8b 45 10             	mov    0x10(%ebp),%eax
80100a1b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a1e:	89 d1                	mov    %edx,%ecx
80100a20:	29 c1                	sub    %eax,%ecx
80100a22:	89 c8                	mov    %ecx,%eax
}
80100a24:	c9                   	leave  
80100a25:	c3                   	ret    

80100a26 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100a26:	55                   	push   %ebp
80100a27:	89 e5                	mov    %esp,%ebp
80100a29:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
80100a2c:	8b 45 08             	mov    0x8(%ebp),%eax
80100a2f:	89 04 24             	mov    %eax,(%esp)
80100a32:	e8 37 10 00 00       	call   80101a6e <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a3e:	e8 18 42 00 00       	call   80104c5b <acquire>
  for(i = 0; i < n; i++)
80100a43:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100a4a:	eb 1d                	jmp    80100a69 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
80100a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a4f:	03 45 0c             	add    0xc(%ebp),%eax
80100a52:	0f b6 00             	movzbl (%eax),%eax
80100a55:	0f be c0             	movsbl %al,%eax
80100a58:	25 ff 00 00 00       	and    $0xff,%eax
80100a5d:	89 04 24             	mov    %eax,(%esp)
80100a60:	e8 eb fc ff ff       	call   80100750 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100a65:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100a6c:	3b 45 10             	cmp    0x10(%ebp),%eax
80100a6f:	7c db                	jl     80100a4c <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100a71:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a78:	e8 40 42 00 00       	call   80104cbd <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 98 0e 00 00       	call   80101920 <ilock>

  return n;
80100a88:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100a8b:	c9                   	leave  
80100a8c:	c3                   	ret    

80100a8d <consoleinit>:

void
consoleinit(void)
{
80100a8d:	55                   	push   %ebp
80100a8e:	89 e5                	mov    %esp,%ebp
80100a90:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80100a93:	c7 44 24 04 a3 82 10 	movl   $0x801082a3,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa2:	e8 93 41 00 00       	call   80104c3a <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 ab 82 10 	movl   $0x801082ab,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ab6:	e8 7f 41 00 00       	call   80104c3a <initlock>

  devsw[CONSOLE].write = consolewrite;
80100abb:	c7 05 0c ed 10 80 26 	movl   $0x80100a26,0x8010ed0c
80100ac2:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100ac5:	c7 05 08 ed 10 80 25 	movl   $0x80100925,0x8010ed08
80100acc:	09 10 80 
  cons.locking = 1;
80100acf:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
80100ad6:	00 00 00 

  picenable(IRQ_KBD);
80100ad9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100ae0:	e8 94 30 00 00       	call   80103b79 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 35 1f 00 00       	call   80102a2e <ioapicenable>
}
80100af9:	c9                   	leave  
80100afa:	c3                   	ret    
	...

80100afc <add_path>:
//--------------------- ROBERT: ------------------------//
char PATH[MAX_PATH_ENTRIES][INPUT_BUF] ;
int lastPath = 0;
// -----------------------------------------------------//
  
int add_path(char* path){
80100afc:	55                   	push   %ebp
80100afd:	89 e5                	mov    %esp,%ebp
80100aff:	83 ec 18             	sub    $0x18,%esp
  if (lastPath==9){
80100b02:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100b07:	83 f8 09             	cmp    $0x9,%eax
80100b0a:	75 13                	jne    80100b1f <add_path+0x23>
    cprintf("could not add path - all paths in use\n");
80100b0c:	c7 04 24 b4 82 10 80 	movl   $0x801082b4,(%esp)
80100b13:	e8 89 f8 ff ff       	call   801003a1 <cprintf>
    return -1;
80100b18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b1d:	eb 3f                	jmp    80100b5e <add_path+0x62>
  }
  strncpy(PATH[lastPath], path, strlen(path));
80100b1f:	8b 45 08             	mov    0x8(%ebp),%eax
80100b22:	89 04 24             	mov    %eax,(%esp)
80100b25:	e8 fe 45 00 00       	call   80105128 <strlen>
80100b2a:	8b 15 f8 b5 10 80    	mov    0x8010b5f8,%edx
80100b30:	c1 e2 07             	shl    $0x7,%edx
80100b33:	81 c2 60 de 10 80    	add    $0x8010de60,%edx
80100b39:	89 44 24 08          	mov    %eax,0x8(%esp)
80100b3d:	8b 45 08             	mov    0x8(%ebp),%eax
80100b40:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b44:	89 14 24             	mov    %edx,(%esp)
80100b47:	e8 2d 45 00 00       	call   80105079 <strncpy>
  lastPath++;
80100b4c:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100b51:	83 c0 01             	add    $0x1,%eax
80100b54:	a3 f8 b5 10 80       	mov    %eax,0x8010b5f8
  return 0;
80100b59:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100b5e:	c9                   	leave  
80100b5f:	c3                   	ret    

80100b60 <exec>:

int
exec(char *path, char **argv)
{
80100b60:	55                   	push   %ebp
80100b61:	89 e5                	mov    %esp,%ebp
80100b63:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  
  //--------- PATCHED -------------------------------//
  if((ip = namei(path)) == 0){
80100b69:	8b 45 08             	mov    0x8(%ebp),%eax
80100b6c:	89 04 24             	mov    %eax,(%esp)
80100b6f:	e8 4e 19 00 00       	call   801024c2 <namei>
80100b74:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b77:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b7b:	75 5e                	jne    80100bdb <exec+0x7b>
      for(i = 0; i<lastPath; i++){
80100b7d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b84:	eb 41                	jmp    80100bc7 <exec+0x67>
	  cprintf("%d\n", i);
80100b86:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100b89:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b8d:	c7 04 24 db 82 10 80 	movl   $0x801082db,(%esp)
80100b94:	e8 08 f8 ff ff       	call   801003a1 <cprintf>
 	  if ((ip = namei(PATH[i])) != 0){
80100b99:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100b9c:	c1 e0 07             	shl    $0x7,%eax
80100b9f:	05 60 de 10 80       	add    $0x8010de60,%eax
80100ba4:	89 04 24             	mov    %eax,(%esp)
80100ba7:	e8 16 19 00 00       	call   801024c2 <namei>
80100bac:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100baf:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100bb3:	74 0e                	je     80100bc3 <exec+0x63>
	     //cprintf("%d\n", ip);
	      cprintf("found him!!\n");
80100bb5:	c7 04 24 df 82 10 80 	movl   $0x801082df,(%esp)
80100bbc:	e8 e0 f7 ff ff       	call   801003a1 <cprintf>
	      goto cont;
80100bc1:	eb 18                	jmp    80100bdb <exec+0x7b>
  pde_t *pgdir, *oldpgdir;

  
  //--------- PATCHED -------------------------------//
  if((ip = namei(path)) == 0){
      for(i = 0; i<lastPath; i++){
80100bc3:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100bc7:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100bcc:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80100bcf:	7c b5                	jl     80100b86 <exec+0x26>
	     //cprintf("%d\n", ip);
	      cprintf("found him!!\n");
	      goto cont;
	  }
      }
      return -1;
80100bd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100bd6:	e9 da 03 00 00       	jmp    80100fb5 <exec+0x455>
  }
  cont:
  //cprintf("%d\n", ip);
  //----------------------------------------------------//
  ilock(ip);
80100bdb:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100bde:	89 04 24             	mov    %eax,(%esp)
80100be1:	e8 3a 0d 00 00       	call   80101920 <ilock>
  pgdir = 0;
80100be6:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100bed:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100bf4:	00 
80100bf5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100bfc:	00 
80100bfd:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100c03:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c07:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c0a:	89 04 24             	mov    %eax,(%esp)
80100c0d:	e8 04 12 00 00       	call   80101e16 <readi>
80100c12:	83 f8 33             	cmp    $0x33,%eax
80100c15:	0f 86 54 03 00 00    	jbe    80100f6f <exec+0x40f>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100c1b:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100c21:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100c26:	0f 85 46 03 00 00    	jne    80100f72 <exec+0x412>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100c2c:	c7 04 24 b7 2b 10 80 	movl   $0x80102bb7,(%esp)
80100c33:	e8 c9 6d 00 00       	call   80107a01 <setupkvm>
80100c38:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100c3b:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100c3f:	0f 84 30 03 00 00    	je     80100f75 <exec+0x415>
    goto bad;

  // Load program into memory.
  sz = 0;
80100c45:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c4c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100c53:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100c59:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c5c:	e9 c5 00 00 00       	jmp    80100d26 <exec+0x1c6>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100c61:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c64:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100c6b:	00 
80100c6c:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c70:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100c76:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c7a:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c7d:	89 04 24             	mov    %eax,(%esp)
80100c80:	e8 91 11 00 00       	call   80101e16 <readi>
80100c85:	83 f8 20             	cmp    $0x20,%eax
80100c88:	0f 85 ea 02 00 00    	jne    80100f78 <exec+0x418>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100c8e:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100c94:	83 f8 01             	cmp    $0x1,%eax
80100c97:	75 7f                	jne    80100d18 <exec+0x1b8>
      continue;
    if(ph.memsz < ph.filesz)
80100c99:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100c9f:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100ca5:	39 c2                	cmp    %eax,%edx
80100ca7:	0f 82 ce 02 00 00    	jb     80100f7b <exec+0x41b>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100cad:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100cb3:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100cb9:	01 d0                	add    %edx,%eax
80100cbb:	89 44 24 08          	mov    %eax,0x8(%esp)
80100cbf:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cc2:	89 44 24 04          	mov    %eax,0x4(%esp)
80100cc6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100cc9:	89 04 24             	mov    %eax,(%esp)
80100ccc:	e8 02 71 00 00       	call   80107dd3 <allocuvm>
80100cd1:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cd4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cd8:	0f 84 a0 02 00 00    	je     80100f7e <exec+0x41e>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100cde:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100ce4:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100cea:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100cf0:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100cf4:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100cf8:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100cfb:	89 54 24 08          	mov    %edx,0x8(%esp)
80100cff:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d03:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d06:	89 04 24             	mov    %eax,(%esp)
80100d09:	e8 d6 6f 00 00       	call   80107ce4 <loaduvm>
80100d0e:	85 c0                	test   %eax,%eax
80100d10:	0f 88 6b 02 00 00    	js     80100f81 <exec+0x421>
80100d16:	eb 01                	jmp    80100d19 <exec+0x1b9>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100d18:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d19:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d1d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d20:	83 c0 20             	add    $0x20,%eax
80100d23:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d26:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100d2d:	0f b7 c0             	movzwl %ax,%eax
80100d30:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100d33:	0f 8f 28 ff ff ff    	jg     80100c61 <exec+0x101>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100d39:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100d3c:	89 04 24             	mov    %eax,(%esp)
80100d3f:	e8 60 0e 00 00       	call   80101ba4 <iunlockput>
  ip = 0;
80100d44:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d4b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d4e:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100d58:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100d5b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d5e:	05 00 20 00 00       	add    $0x2000,%eax
80100d63:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d67:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d6a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d6e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d71:	89 04 24             	mov    %eax,(%esp)
80100d74:	e8 5a 70 00 00       	call   80107dd3 <allocuvm>
80100d79:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d7c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d80:	0f 84 fe 01 00 00    	je     80100f84 <exec+0x424>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d86:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d89:	2d 00 20 00 00       	sub    $0x2000,%eax
80100d8e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d92:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d95:	89 04 24             	mov    %eax,(%esp)
80100d98:	e8 5a 72 00 00       	call   80107ff7 <clearpteu>
  sp = sz;
80100d9d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100da0:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100da3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100daa:	e9 81 00 00 00       	jmp    80100e30 <exec+0x2d0>
    if(argc >= MAXARG)
80100daf:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100db3:	0f 87 ce 01 00 00    	ja     80100f87 <exec+0x427>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100db9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dbc:	c1 e0 02             	shl    $0x2,%eax
80100dbf:	03 45 0c             	add    0xc(%ebp),%eax
80100dc2:	8b 00                	mov    (%eax),%eax
80100dc4:	89 04 24             	mov    %eax,(%esp)
80100dc7:	e8 5c 43 00 00       	call   80105128 <strlen>
80100dcc:	f7 d0                	not    %eax
80100dce:	03 45 dc             	add    -0x24(%ebp),%eax
80100dd1:	83 e0 fc             	and    $0xfffffffc,%eax
80100dd4:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100dd7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dda:	c1 e0 02             	shl    $0x2,%eax
80100ddd:	03 45 0c             	add    0xc(%ebp),%eax
80100de0:	8b 00                	mov    (%eax),%eax
80100de2:	89 04 24             	mov    %eax,(%esp)
80100de5:	e8 3e 43 00 00       	call   80105128 <strlen>
80100dea:	83 c0 01             	add    $0x1,%eax
80100ded:	89 c2                	mov    %eax,%edx
80100def:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100df2:	c1 e0 02             	shl    $0x2,%eax
80100df5:	03 45 0c             	add    0xc(%ebp),%eax
80100df8:	8b 00                	mov    (%eax),%eax
80100dfa:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100dfe:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e02:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e05:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e09:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e0c:	89 04 24             	mov    %eax,(%esp)
80100e0f:	e8 97 73 00 00       	call   801081ab <copyout>
80100e14:	85 c0                	test   %eax,%eax
80100e16:	0f 88 6e 01 00 00    	js     80100f8a <exec+0x42a>
      goto bad;
    ustack[3+argc] = sp;
80100e1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e1f:	8d 50 03             	lea    0x3(%eax),%edx
80100e22:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e25:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e2c:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e33:	c1 e0 02             	shl    $0x2,%eax
80100e36:	03 45 0c             	add    0xc(%ebp),%eax
80100e39:	8b 00                	mov    (%eax),%eax
80100e3b:	85 c0                	test   %eax,%eax
80100e3d:	0f 85 6c ff ff ff    	jne    80100daf <exec+0x24f>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100e43:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e46:	83 c0 03             	add    $0x3,%eax
80100e49:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100e50:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e54:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100e5b:	ff ff ff 
  ustack[1] = argc;
80100e5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e61:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e6a:	83 c0 01             	add    $0x1,%eax
80100e6d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e74:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e77:	29 d0                	sub    %edx,%eax
80100e79:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100e7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e82:	83 c0 04             	add    $0x4,%eax
80100e85:	c1 e0 02             	shl    $0x2,%eax
80100e88:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e8b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e8e:	83 c0 04             	add    $0x4,%eax
80100e91:	c1 e0 02             	shl    $0x2,%eax
80100e94:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e98:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e9e:	89 44 24 08          	mov    %eax,0x8(%esp)
80100ea2:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ea5:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ea9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100eac:	89 04 24             	mov    %eax,(%esp)
80100eaf:	e8 f7 72 00 00       	call   801081ab <copyout>
80100eb4:	85 c0                	test   %eax,%eax
80100eb6:	0f 88 d1 00 00 00    	js     80100f8d <exec+0x42d>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100ebc:	8b 45 08             	mov    0x8(%ebp),%eax
80100ebf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ec2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ec5:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100ec8:	eb 17                	jmp    80100ee1 <exec+0x381>
    if(*s == '/')
80100eca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ecd:	0f b6 00             	movzbl (%eax),%eax
80100ed0:	3c 2f                	cmp    $0x2f,%al
80100ed2:	75 09                	jne    80100edd <exec+0x37d>
      last = s+1;
80100ed4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ed7:	83 c0 01             	add    $0x1,%eax
80100eda:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100edd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100ee1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ee4:	0f b6 00             	movzbl (%eax),%eax
80100ee7:	84 c0                	test   %al,%al
80100ee9:	75 df                	jne    80100eca <exec+0x36a>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100eeb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ef1:	8d 50 6c             	lea    0x6c(%eax),%edx
80100ef4:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100efb:	00 
80100efc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100eff:	89 44 24 04          	mov    %eax,0x4(%esp)
80100f03:	89 14 24             	mov    %edx,(%esp)
80100f06:	e8 cf 41 00 00       	call   801050da <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100f0b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f11:	8b 40 04             	mov    0x4(%eax),%eax
80100f14:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100f17:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f1d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f20:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100f23:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f29:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f2c:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100f2e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f34:	8b 40 18             	mov    0x18(%eax),%eax
80100f37:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100f3d:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100f40:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f46:	8b 40 18             	mov    0x18(%eax),%eax
80100f49:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100f4c:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100f4f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f55:	89 04 24             	mov    %eax,(%esp)
80100f58:	e8 95 6b 00 00       	call   80107af2 <switchuvm>
  freevm(oldpgdir);
80100f5d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f60:	89 04 24             	mov    %eax,(%esp)
80100f63:	e8 01 70 00 00       	call   80107f69 <freevm>
  return 0;
80100f68:	b8 00 00 00 00       	mov    $0x0,%eax
80100f6d:	eb 46                	jmp    80100fb5 <exec+0x455>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100f6f:	90                   	nop
80100f70:	eb 1c                	jmp    80100f8e <exec+0x42e>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100f72:	90                   	nop
80100f73:	eb 19                	jmp    80100f8e <exec+0x42e>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100f75:	90                   	nop
80100f76:	eb 16                	jmp    80100f8e <exec+0x42e>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100f78:	90                   	nop
80100f79:	eb 13                	jmp    80100f8e <exec+0x42e>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100f7b:	90                   	nop
80100f7c:	eb 10                	jmp    80100f8e <exec+0x42e>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100f7e:	90                   	nop
80100f7f:	eb 0d                	jmp    80100f8e <exec+0x42e>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100f81:	90                   	nop
80100f82:	eb 0a                	jmp    80100f8e <exec+0x42e>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100f84:	90                   	nop
80100f85:	eb 07                	jmp    80100f8e <exec+0x42e>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100f87:	90                   	nop
80100f88:	eb 04                	jmp    80100f8e <exec+0x42e>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100f8a:	90                   	nop
80100f8b:	eb 01                	jmp    80100f8e <exec+0x42e>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100f8d:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100f8e:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f92:	74 0b                	je     80100f9f <exec+0x43f>
    freevm(pgdir);
80100f94:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f97:	89 04 24             	mov    %eax,(%esp)
80100f9a:	e8 ca 6f 00 00       	call   80107f69 <freevm>
  if(ip)
80100f9f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fa3:	74 0b                	je     80100fb0 <exec+0x450>
    iunlockput(ip);
80100fa5:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100fa8:	89 04 24             	mov    %eax,(%esp)
80100fab:	e8 f4 0b 00 00       	call   80101ba4 <iunlockput>
  return -1;
80100fb0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100fb5:	c9                   	leave  
80100fb6:	c3                   	ret    
	...

80100fb8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100fb8:	55                   	push   %ebp
80100fb9:	89 e5                	mov    %esp,%ebp
80100fbb:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100fbe:	c7 44 24 04 ec 82 10 	movl   $0x801082ec,0x4(%esp)
80100fc5:	80 
80100fc6:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80100fcd:	e8 68 3c 00 00       	call   80104c3a <initlock>
}
80100fd2:	c9                   	leave  
80100fd3:	c3                   	ret    

80100fd4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100fd4:	55                   	push   %ebp
80100fd5:	89 e5                	mov    %esp,%ebp
80100fd7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100fda:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80100fe1:	e8 75 3c 00 00       	call   80104c5b <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100fe6:	c7 45 f4 94 e3 10 80 	movl   $0x8010e394,-0xc(%ebp)
80100fed:	eb 29                	jmp    80101018 <filealloc+0x44>
    if(f->ref == 0){
80100fef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ff2:	8b 40 04             	mov    0x4(%eax),%eax
80100ff5:	85 c0                	test   %eax,%eax
80100ff7:	75 1b                	jne    80101014 <filealloc+0x40>
      f->ref = 1;
80100ff9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ffc:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101003:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
8010100a:	e8 ae 3c 00 00       	call   80104cbd <release>
      return f;
8010100f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101012:	eb 1e                	jmp    80101032 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101014:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80101018:	81 7d f4 f4 ec 10 80 	cmpl   $0x8010ecf4,-0xc(%ebp)
8010101f:	72 ce                	jb     80100fef <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80101021:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80101028:	e8 90 3c 00 00       	call   80104cbd <release>
  return 0;
8010102d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80101032:	c9                   	leave  
80101033:	c3                   	ret    

80101034 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101034:	55                   	push   %ebp
80101035:	89 e5                	mov    %esp,%ebp
80101037:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
8010103a:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80101041:	e8 15 3c 00 00       	call   80104c5b <acquire>
  if(f->ref < 1)
80101046:	8b 45 08             	mov    0x8(%ebp),%eax
80101049:	8b 40 04             	mov    0x4(%eax),%eax
8010104c:	85 c0                	test   %eax,%eax
8010104e:	7f 0c                	jg     8010105c <filedup+0x28>
    panic("filedup");
80101050:	c7 04 24 f3 82 10 80 	movl   $0x801082f3,(%esp)
80101057:	e8 e1 f4 ff ff       	call   8010053d <panic>
  f->ref++;
8010105c:	8b 45 08             	mov    0x8(%ebp),%eax
8010105f:	8b 40 04             	mov    0x4(%eax),%eax
80101062:	8d 50 01             	lea    0x1(%eax),%edx
80101065:	8b 45 08             	mov    0x8(%ebp),%eax
80101068:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010106b:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80101072:	e8 46 3c 00 00       	call   80104cbd <release>
  return f;
80101077:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010107a:	c9                   	leave  
8010107b:	c3                   	ret    

8010107c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
8010107c:	55                   	push   %ebp
8010107d:	89 e5                	mov    %esp,%ebp
8010107f:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101082:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80101089:	e8 cd 3b 00 00       	call   80104c5b <acquire>
  if(f->ref < 1)
8010108e:	8b 45 08             	mov    0x8(%ebp),%eax
80101091:	8b 40 04             	mov    0x4(%eax),%eax
80101094:	85 c0                	test   %eax,%eax
80101096:	7f 0c                	jg     801010a4 <fileclose+0x28>
    panic("fileclose");
80101098:	c7 04 24 fb 82 10 80 	movl   $0x801082fb,(%esp)
8010109f:	e8 99 f4 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
801010a4:	8b 45 08             	mov    0x8(%ebp),%eax
801010a7:	8b 40 04             	mov    0x4(%eax),%eax
801010aa:	8d 50 ff             	lea    -0x1(%eax),%edx
801010ad:	8b 45 08             	mov    0x8(%ebp),%eax
801010b0:	89 50 04             	mov    %edx,0x4(%eax)
801010b3:	8b 45 08             	mov    0x8(%ebp),%eax
801010b6:	8b 40 04             	mov    0x4(%eax),%eax
801010b9:	85 c0                	test   %eax,%eax
801010bb:	7e 11                	jle    801010ce <fileclose+0x52>
    release(&ftable.lock);
801010bd:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
801010c4:	e8 f4 3b 00 00       	call   80104cbd <release>
    return;
801010c9:	e9 82 00 00 00       	jmp    80101150 <fileclose+0xd4>
  }
  ff = *f;
801010ce:	8b 45 08             	mov    0x8(%ebp),%eax
801010d1:	8b 10                	mov    (%eax),%edx
801010d3:	89 55 e0             	mov    %edx,-0x20(%ebp)
801010d6:	8b 50 04             	mov    0x4(%eax),%edx
801010d9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
801010dc:	8b 50 08             	mov    0x8(%eax),%edx
801010df:	89 55 e8             	mov    %edx,-0x18(%ebp)
801010e2:	8b 50 0c             	mov    0xc(%eax),%edx
801010e5:	89 55 ec             	mov    %edx,-0x14(%ebp)
801010e8:	8b 50 10             	mov    0x10(%eax),%edx
801010eb:	89 55 f0             	mov    %edx,-0x10(%ebp)
801010ee:	8b 40 14             	mov    0x14(%eax),%eax
801010f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
801010f4:	8b 45 08             	mov    0x8(%ebp),%eax
801010f7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
801010fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101101:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101107:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
8010110e:	e8 aa 3b 00 00       	call   80104cbd <release>
  
  if(ff.type == FD_PIPE)
80101113:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101116:	83 f8 01             	cmp    $0x1,%eax
80101119:	75 18                	jne    80101133 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
8010111b:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
8010111f:	0f be d0             	movsbl %al,%edx
80101122:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101125:	89 54 24 04          	mov    %edx,0x4(%esp)
80101129:	89 04 24             	mov    %eax,(%esp)
8010112c:	e8 02 2d 00 00       	call   80103e33 <pipeclose>
80101131:	eb 1d                	jmp    80101150 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
80101133:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101136:	83 f8 02             	cmp    $0x2,%eax
80101139:	75 15                	jne    80101150 <fileclose+0xd4>
    begin_trans();
8010113b:	e8 95 21 00 00       	call   801032d5 <begin_trans>
    iput(ff.ip);
80101140:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101143:	89 04 24             	mov    %eax,(%esp)
80101146:	e8 88 09 00 00       	call   80101ad3 <iput>
    commit_trans();
8010114b:	e8 ce 21 00 00       	call   8010331e <commit_trans>
  }
}
80101150:	c9                   	leave  
80101151:	c3                   	ret    

80101152 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101152:	55                   	push   %ebp
80101153:	89 e5                	mov    %esp,%ebp
80101155:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
80101158:	8b 45 08             	mov    0x8(%ebp),%eax
8010115b:	8b 00                	mov    (%eax),%eax
8010115d:	83 f8 02             	cmp    $0x2,%eax
80101160:	75 38                	jne    8010119a <filestat+0x48>
    ilock(f->ip);
80101162:	8b 45 08             	mov    0x8(%ebp),%eax
80101165:	8b 40 10             	mov    0x10(%eax),%eax
80101168:	89 04 24             	mov    %eax,(%esp)
8010116b:	e8 b0 07 00 00       	call   80101920 <ilock>
    stati(f->ip, st);
80101170:	8b 45 08             	mov    0x8(%ebp),%eax
80101173:	8b 40 10             	mov    0x10(%eax),%eax
80101176:	8b 55 0c             	mov    0xc(%ebp),%edx
80101179:	89 54 24 04          	mov    %edx,0x4(%esp)
8010117d:	89 04 24             	mov    %eax,(%esp)
80101180:	e8 4c 0c 00 00       	call   80101dd1 <stati>
    iunlock(f->ip);
80101185:	8b 45 08             	mov    0x8(%ebp),%eax
80101188:	8b 40 10             	mov    0x10(%eax),%eax
8010118b:	89 04 24             	mov    %eax,(%esp)
8010118e:	e8 db 08 00 00       	call   80101a6e <iunlock>
    return 0;
80101193:	b8 00 00 00 00       	mov    $0x0,%eax
80101198:	eb 05                	jmp    8010119f <filestat+0x4d>
  }
  return -1;
8010119a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010119f:	c9                   	leave  
801011a0:	c3                   	ret    

801011a1 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011a1:	55                   	push   %ebp
801011a2:	89 e5                	mov    %esp,%ebp
801011a4:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
801011a7:	8b 45 08             	mov    0x8(%ebp),%eax
801011aa:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801011ae:	84 c0                	test   %al,%al
801011b0:	75 0a                	jne    801011bc <fileread+0x1b>
    return -1;
801011b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801011b7:	e9 9f 00 00 00       	jmp    8010125b <fileread+0xba>
  if(f->type == FD_PIPE)
801011bc:	8b 45 08             	mov    0x8(%ebp),%eax
801011bf:	8b 00                	mov    (%eax),%eax
801011c1:	83 f8 01             	cmp    $0x1,%eax
801011c4:	75 1e                	jne    801011e4 <fileread+0x43>
    return piperead(f->pipe, addr, n);
801011c6:	8b 45 08             	mov    0x8(%ebp),%eax
801011c9:	8b 40 0c             	mov    0xc(%eax),%eax
801011cc:	8b 55 10             	mov    0x10(%ebp),%edx
801011cf:	89 54 24 08          	mov    %edx,0x8(%esp)
801011d3:	8b 55 0c             	mov    0xc(%ebp),%edx
801011d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801011da:	89 04 24             	mov    %eax,(%esp)
801011dd:	e8 d3 2d 00 00       	call   80103fb5 <piperead>
801011e2:	eb 77                	jmp    8010125b <fileread+0xba>
  if(f->type == FD_INODE){
801011e4:	8b 45 08             	mov    0x8(%ebp),%eax
801011e7:	8b 00                	mov    (%eax),%eax
801011e9:	83 f8 02             	cmp    $0x2,%eax
801011ec:	75 61                	jne    8010124f <fileread+0xae>
    ilock(f->ip);
801011ee:	8b 45 08             	mov    0x8(%ebp),%eax
801011f1:	8b 40 10             	mov    0x10(%eax),%eax
801011f4:	89 04 24             	mov    %eax,(%esp)
801011f7:	e8 24 07 00 00       	call   80101920 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
801011fc:	8b 4d 10             	mov    0x10(%ebp),%ecx
801011ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101202:	8b 50 14             	mov    0x14(%eax),%edx
80101205:	8b 45 08             	mov    0x8(%ebp),%eax
80101208:	8b 40 10             	mov    0x10(%eax),%eax
8010120b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
8010120f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101213:	8b 55 0c             	mov    0xc(%ebp),%edx
80101216:	89 54 24 04          	mov    %edx,0x4(%esp)
8010121a:	89 04 24             	mov    %eax,(%esp)
8010121d:	e8 f4 0b 00 00       	call   80101e16 <readi>
80101222:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101225:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101229:	7e 11                	jle    8010123c <fileread+0x9b>
      f->off += r;
8010122b:	8b 45 08             	mov    0x8(%ebp),%eax
8010122e:	8b 50 14             	mov    0x14(%eax),%edx
80101231:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101234:	01 c2                	add    %eax,%edx
80101236:	8b 45 08             	mov    0x8(%ebp),%eax
80101239:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
8010123c:	8b 45 08             	mov    0x8(%ebp),%eax
8010123f:	8b 40 10             	mov    0x10(%eax),%eax
80101242:	89 04 24             	mov    %eax,(%esp)
80101245:	e8 24 08 00 00       	call   80101a6e <iunlock>
    return r;
8010124a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010124d:	eb 0c                	jmp    8010125b <fileread+0xba>
  }
  panic("fileread");
8010124f:	c7 04 24 05 83 10 80 	movl   $0x80108305,(%esp)
80101256:	e8 e2 f2 ff ff       	call   8010053d <panic>
}
8010125b:	c9                   	leave  
8010125c:	c3                   	ret    

8010125d <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
8010125d:	55                   	push   %ebp
8010125e:	89 e5                	mov    %esp,%ebp
80101260:	53                   	push   %ebx
80101261:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
80101264:	8b 45 08             	mov    0x8(%ebp),%eax
80101267:	0f b6 40 09          	movzbl 0x9(%eax),%eax
8010126b:	84 c0                	test   %al,%al
8010126d:	75 0a                	jne    80101279 <filewrite+0x1c>
    return -1;
8010126f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101274:	e9 23 01 00 00       	jmp    8010139c <filewrite+0x13f>
  if(f->type == FD_PIPE)
80101279:	8b 45 08             	mov    0x8(%ebp),%eax
8010127c:	8b 00                	mov    (%eax),%eax
8010127e:	83 f8 01             	cmp    $0x1,%eax
80101281:	75 21                	jne    801012a4 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101283:	8b 45 08             	mov    0x8(%ebp),%eax
80101286:	8b 40 0c             	mov    0xc(%eax),%eax
80101289:	8b 55 10             	mov    0x10(%ebp),%edx
8010128c:	89 54 24 08          	mov    %edx,0x8(%esp)
80101290:	8b 55 0c             	mov    0xc(%ebp),%edx
80101293:	89 54 24 04          	mov    %edx,0x4(%esp)
80101297:	89 04 24             	mov    %eax,(%esp)
8010129a:	e8 26 2c 00 00       	call   80103ec5 <pipewrite>
8010129f:	e9 f8 00 00 00       	jmp    8010139c <filewrite+0x13f>
  if(f->type == FD_INODE){
801012a4:	8b 45 08             	mov    0x8(%ebp),%eax
801012a7:	8b 00                	mov    (%eax),%eax
801012a9:	83 f8 02             	cmp    $0x2,%eax
801012ac:	0f 85 de 00 00 00    	jne    80101390 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801012b2:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
801012b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
801012c0:	e9 a8 00 00 00       	jmp    8010136d <filewrite+0x110>
      int n1 = n - i;
801012c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801012c8:	8b 55 10             	mov    0x10(%ebp),%edx
801012cb:	89 d1                	mov    %edx,%ecx
801012cd:	29 c1                	sub    %eax,%ecx
801012cf:	89 c8                	mov    %ecx,%eax
801012d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
801012d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801012d7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801012da:	7e 06                	jle    801012e2 <filewrite+0x85>
        n1 = max;
801012dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801012df:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
801012e2:	e8 ee 1f 00 00       	call   801032d5 <begin_trans>
      ilock(f->ip);
801012e7:	8b 45 08             	mov    0x8(%ebp),%eax
801012ea:	8b 40 10             	mov    0x10(%eax),%eax
801012ed:	89 04 24             	mov    %eax,(%esp)
801012f0:	e8 2b 06 00 00       	call   80101920 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
801012f5:	8b 5d f0             	mov    -0x10(%ebp),%ebx
801012f8:	8b 45 08             	mov    0x8(%ebp),%eax
801012fb:	8b 48 14             	mov    0x14(%eax),%ecx
801012fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101301:	89 c2                	mov    %eax,%edx
80101303:	03 55 0c             	add    0xc(%ebp),%edx
80101306:	8b 45 08             	mov    0x8(%ebp),%eax
80101309:	8b 40 10             	mov    0x10(%eax),%eax
8010130c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80101310:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80101314:	89 54 24 04          	mov    %edx,0x4(%esp)
80101318:	89 04 24             	mov    %eax,(%esp)
8010131b:	e8 61 0c 00 00       	call   80101f81 <writei>
80101320:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101323:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101327:	7e 11                	jle    8010133a <filewrite+0xdd>
        f->off += r;
80101329:	8b 45 08             	mov    0x8(%ebp),%eax
8010132c:	8b 50 14             	mov    0x14(%eax),%edx
8010132f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101332:	01 c2                	add    %eax,%edx
80101334:	8b 45 08             	mov    0x8(%ebp),%eax
80101337:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
8010133a:	8b 45 08             	mov    0x8(%ebp),%eax
8010133d:	8b 40 10             	mov    0x10(%eax),%eax
80101340:	89 04 24             	mov    %eax,(%esp)
80101343:	e8 26 07 00 00       	call   80101a6e <iunlock>
      commit_trans();
80101348:	e8 d1 1f 00 00       	call   8010331e <commit_trans>

      if(r < 0)
8010134d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101351:	78 28                	js     8010137b <filewrite+0x11e>
        break;
      if(r != n1)
80101353:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101356:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80101359:	74 0c                	je     80101367 <filewrite+0x10a>
        panic("short filewrite");
8010135b:	c7 04 24 0e 83 10 80 	movl   $0x8010830e,(%esp)
80101362:	e8 d6 f1 ff ff       	call   8010053d <panic>
      i += r;
80101367:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010136a:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
8010136d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101370:	3b 45 10             	cmp    0x10(%ebp),%eax
80101373:	0f 8c 4c ff ff ff    	jl     801012c5 <filewrite+0x68>
80101379:	eb 01                	jmp    8010137c <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
8010137b:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
8010137c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137f:	3b 45 10             	cmp    0x10(%ebp),%eax
80101382:	75 05                	jne    80101389 <filewrite+0x12c>
80101384:	8b 45 10             	mov    0x10(%ebp),%eax
80101387:	eb 05                	jmp    8010138e <filewrite+0x131>
80101389:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010138e:	eb 0c                	jmp    8010139c <filewrite+0x13f>
  }
  panic("filewrite");
80101390:	c7 04 24 1e 83 10 80 	movl   $0x8010831e,(%esp)
80101397:	e8 a1 f1 ff ff       	call   8010053d <panic>
}
8010139c:	83 c4 24             	add    $0x24,%esp
8010139f:	5b                   	pop    %ebx
801013a0:	5d                   	pop    %ebp
801013a1:	c3                   	ret    
	...

801013a4 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013a4:	55                   	push   %ebp
801013a5:	89 e5                	mov    %esp,%ebp
801013a7:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
801013aa:	8b 45 08             	mov    0x8(%ebp),%eax
801013ad:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801013b4:	00 
801013b5:	89 04 24             	mov    %eax,(%esp)
801013b8:	e8 e9 ed ff ff       	call   801001a6 <bread>
801013bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
801013c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c3:	83 c0 18             	add    $0x18,%eax
801013c6:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801013cd:	00 
801013ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801013d2:	8b 45 0c             	mov    0xc(%ebp),%eax
801013d5:	89 04 24             	mov    %eax,(%esp)
801013d8:	e8 a0 3b 00 00       	call   80104f7d <memmove>
  brelse(bp);
801013dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013e0:	89 04 24             	mov    %eax,(%esp)
801013e3:	e8 2f ee ff ff       	call   80100217 <brelse>
}
801013e8:	c9                   	leave  
801013e9:	c3                   	ret    

801013ea <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
801013ea:	55                   	push   %ebp
801013eb:	89 e5                	mov    %esp,%ebp
801013ed:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
801013f0:	8b 55 0c             	mov    0xc(%ebp),%edx
801013f3:	8b 45 08             	mov    0x8(%ebp),%eax
801013f6:	89 54 24 04          	mov    %edx,0x4(%esp)
801013fa:	89 04 24             	mov    %eax,(%esp)
801013fd:	e8 a4 ed ff ff       	call   801001a6 <bread>
80101402:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101405:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101408:	83 c0 18             	add    $0x18,%eax
8010140b:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80101412:	00 
80101413:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010141a:	00 
8010141b:	89 04 24             	mov    %eax,(%esp)
8010141e:	e8 87 3a 00 00       	call   80104eaa <memset>
  log_write(bp);
80101423:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101426:	89 04 24             	mov    %eax,(%esp)
80101429:	e8 48 1f 00 00       	call   80103376 <log_write>
  brelse(bp);
8010142e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101431:	89 04 24             	mov    %eax,(%esp)
80101434:	e8 de ed ff ff       	call   80100217 <brelse>
}
80101439:	c9                   	leave  
8010143a:	c3                   	ret    

8010143b <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010143b:	55                   	push   %ebp
8010143c:	89 e5                	mov    %esp,%ebp
8010143e:	53                   	push   %ebx
8010143f:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101442:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101449:	8b 45 08             	mov    0x8(%ebp),%eax
8010144c:	8d 55 d8             	lea    -0x28(%ebp),%edx
8010144f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101453:	89 04 24             	mov    %eax,(%esp)
80101456:	e8 49 ff ff ff       	call   801013a4 <readsb>
  for(b = 0; b < sb.size; b += BPB){
8010145b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101462:	e9 11 01 00 00       	jmp    80101578 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80101467:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010146a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101470:	85 c0                	test   %eax,%eax
80101472:	0f 48 c2             	cmovs  %edx,%eax
80101475:	c1 f8 0c             	sar    $0xc,%eax
80101478:	8b 55 e0             	mov    -0x20(%ebp),%edx
8010147b:	c1 ea 03             	shr    $0x3,%edx
8010147e:	01 d0                	add    %edx,%eax
80101480:	83 c0 03             	add    $0x3,%eax
80101483:	89 44 24 04          	mov    %eax,0x4(%esp)
80101487:	8b 45 08             	mov    0x8(%ebp),%eax
8010148a:	89 04 24             	mov    %eax,(%esp)
8010148d:	e8 14 ed ff ff       	call   801001a6 <bread>
80101492:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101495:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010149c:	e9 a7 00 00 00       	jmp    80101548 <balloc+0x10d>
      m = 1 << (bi % 8);
801014a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014a4:	89 c2                	mov    %eax,%edx
801014a6:	c1 fa 1f             	sar    $0x1f,%edx
801014a9:	c1 ea 1d             	shr    $0x1d,%edx
801014ac:	01 d0                	add    %edx,%eax
801014ae:	83 e0 07             	and    $0x7,%eax
801014b1:	29 d0                	sub    %edx,%eax
801014b3:	ba 01 00 00 00       	mov    $0x1,%edx
801014b8:	89 d3                	mov    %edx,%ebx
801014ba:	89 c1                	mov    %eax,%ecx
801014bc:	d3 e3                	shl    %cl,%ebx
801014be:	89 d8                	mov    %ebx,%eax
801014c0:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801014c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014c6:	8d 50 07             	lea    0x7(%eax),%edx
801014c9:	85 c0                	test   %eax,%eax
801014cb:	0f 48 c2             	cmovs  %edx,%eax
801014ce:	c1 f8 03             	sar    $0x3,%eax
801014d1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801014d4:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801014d9:	0f b6 c0             	movzbl %al,%eax
801014dc:	23 45 e8             	and    -0x18(%ebp),%eax
801014df:	85 c0                	test   %eax,%eax
801014e1:	75 61                	jne    80101544 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
801014e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014e6:	8d 50 07             	lea    0x7(%eax),%edx
801014e9:	85 c0                	test   %eax,%eax
801014eb:	0f 48 c2             	cmovs  %edx,%eax
801014ee:	c1 f8 03             	sar    $0x3,%eax
801014f1:	8b 55 ec             	mov    -0x14(%ebp),%edx
801014f4:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801014f9:	89 d1                	mov    %edx,%ecx
801014fb:	8b 55 e8             	mov    -0x18(%ebp),%edx
801014fe:	09 ca                	or     %ecx,%edx
80101500:	89 d1                	mov    %edx,%ecx
80101502:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101505:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101509:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010150c:	89 04 24             	mov    %eax,(%esp)
8010150f:	e8 62 1e 00 00       	call   80103376 <log_write>
        brelse(bp);
80101514:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101517:	89 04 24             	mov    %eax,(%esp)
8010151a:	e8 f8 ec ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
8010151f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101522:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101525:	01 c2                	add    %eax,%edx
80101527:	8b 45 08             	mov    0x8(%ebp),%eax
8010152a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010152e:	89 04 24             	mov    %eax,(%esp)
80101531:	e8 b4 fe ff ff       	call   801013ea <bzero>
        return b + bi;
80101536:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101539:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010153c:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
8010153e:	83 c4 34             	add    $0x34,%esp
80101541:	5b                   	pop    %ebx
80101542:	5d                   	pop    %ebp
80101543:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101544:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101548:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
8010154f:	7f 15                	jg     80101566 <balloc+0x12b>
80101551:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101554:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101557:	01 d0                	add    %edx,%eax
80101559:	89 c2                	mov    %eax,%edx
8010155b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010155e:	39 c2                	cmp    %eax,%edx
80101560:	0f 82 3b ff ff ff    	jb     801014a1 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101566:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101569:	89 04 24             	mov    %eax,(%esp)
8010156c:	e8 a6 ec ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
80101571:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101578:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010157b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010157e:	39 c2                	cmp    %eax,%edx
80101580:	0f 82 e1 fe ff ff    	jb     80101467 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101586:	c7 04 24 28 83 10 80 	movl   $0x80108328,(%esp)
8010158d:	e8 ab ef ff ff       	call   8010053d <panic>

80101592 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101592:	55                   	push   %ebp
80101593:	89 e5                	mov    %esp,%ebp
80101595:	53                   	push   %ebx
80101596:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101599:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010159c:	89 44 24 04          	mov    %eax,0x4(%esp)
801015a0:	8b 45 08             	mov    0x8(%ebp),%eax
801015a3:	89 04 24             	mov    %eax,(%esp)
801015a6:	e8 f9 fd ff ff       	call   801013a4 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
801015ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801015ae:	89 c2                	mov    %eax,%edx
801015b0:	c1 ea 0c             	shr    $0xc,%edx
801015b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801015b6:	c1 e8 03             	shr    $0x3,%eax
801015b9:	01 d0                	add    %edx,%eax
801015bb:	8d 50 03             	lea    0x3(%eax),%edx
801015be:	8b 45 08             	mov    0x8(%ebp),%eax
801015c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801015c5:	89 04 24             	mov    %eax,(%esp)
801015c8:	e8 d9 eb ff ff       	call   801001a6 <bread>
801015cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
801015d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801015d3:	25 ff 0f 00 00       	and    $0xfff,%eax
801015d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
801015db:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015de:	89 c2                	mov    %eax,%edx
801015e0:	c1 fa 1f             	sar    $0x1f,%edx
801015e3:	c1 ea 1d             	shr    $0x1d,%edx
801015e6:	01 d0                	add    %edx,%eax
801015e8:	83 e0 07             	and    $0x7,%eax
801015eb:	29 d0                	sub    %edx,%eax
801015ed:	ba 01 00 00 00       	mov    $0x1,%edx
801015f2:	89 d3                	mov    %edx,%ebx
801015f4:	89 c1                	mov    %eax,%ecx
801015f6:	d3 e3                	shl    %cl,%ebx
801015f8:	89 d8                	mov    %ebx,%eax
801015fa:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
801015fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101600:	8d 50 07             	lea    0x7(%eax),%edx
80101603:	85 c0                	test   %eax,%eax
80101605:	0f 48 c2             	cmovs  %edx,%eax
80101608:	c1 f8 03             	sar    $0x3,%eax
8010160b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010160e:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101613:	0f b6 c0             	movzbl %al,%eax
80101616:	23 45 ec             	and    -0x14(%ebp),%eax
80101619:	85 c0                	test   %eax,%eax
8010161b:	75 0c                	jne    80101629 <bfree+0x97>
    panic("freeing free block");
8010161d:	c7 04 24 3e 83 10 80 	movl   $0x8010833e,(%esp)
80101624:	e8 14 ef ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101629:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010162c:	8d 50 07             	lea    0x7(%eax),%edx
8010162f:	85 c0                	test   %eax,%eax
80101631:	0f 48 c2             	cmovs  %edx,%eax
80101634:	c1 f8 03             	sar    $0x3,%eax
80101637:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010163a:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
8010163f:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101642:	f7 d1                	not    %ecx
80101644:	21 ca                	and    %ecx,%edx
80101646:	89 d1                	mov    %edx,%ecx
80101648:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010164b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
8010164f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101652:	89 04 24             	mov    %eax,(%esp)
80101655:	e8 1c 1d 00 00       	call   80103376 <log_write>
  brelse(bp);
8010165a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010165d:	89 04 24             	mov    %eax,(%esp)
80101660:	e8 b2 eb ff ff       	call   80100217 <brelse>
}
80101665:	83 c4 34             	add    $0x34,%esp
80101668:	5b                   	pop    %ebx
80101669:	5d                   	pop    %ebp
8010166a:	c3                   	ret    

8010166b <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
8010166b:	55                   	push   %ebp
8010166c:	89 e5                	mov    %esp,%ebp
8010166e:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80101671:	c7 44 24 04 51 83 10 	movl   $0x80108351,0x4(%esp)
80101678:	80 
80101679:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101680:	e8 b5 35 00 00       	call   80104c3a <initlock>
}
80101685:	c9                   	leave  
80101686:	c3                   	ret    

80101687 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101687:	55                   	push   %ebp
80101688:	89 e5                	mov    %esp,%ebp
8010168a:	83 ec 48             	sub    $0x48,%esp
8010168d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101690:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101694:	8b 45 08             	mov    0x8(%ebp),%eax
80101697:	8d 55 dc             	lea    -0x24(%ebp),%edx
8010169a:	89 54 24 04          	mov    %edx,0x4(%esp)
8010169e:	89 04 24             	mov    %eax,(%esp)
801016a1:	e8 fe fc ff ff       	call   801013a4 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
801016a6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
801016ad:	e9 98 00 00 00       	jmp    8010174a <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
801016b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016b5:	c1 e8 03             	shr    $0x3,%eax
801016b8:	83 c0 02             	add    $0x2,%eax
801016bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801016bf:	8b 45 08             	mov    0x8(%ebp),%eax
801016c2:	89 04 24             	mov    %eax,(%esp)
801016c5:	e8 dc ea ff ff       	call   801001a6 <bread>
801016ca:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
801016cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016d0:	8d 50 18             	lea    0x18(%eax),%edx
801016d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016d6:	83 e0 07             	and    $0x7,%eax
801016d9:	c1 e0 06             	shl    $0x6,%eax
801016dc:	01 d0                	add    %edx,%eax
801016de:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801016e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016e4:	0f b7 00             	movzwl (%eax),%eax
801016e7:	66 85 c0             	test   %ax,%ax
801016ea:	75 4f                	jne    8010173b <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
801016ec:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
801016f3:	00 
801016f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801016fb:	00 
801016fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016ff:	89 04 24             	mov    %eax,(%esp)
80101702:	e8 a3 37 00 00       	call   80104eaa <memset>
      dip->type = type;
80101707:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010170a:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
8010170e:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101711:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101714:	89 04 24             	mov    %eax,(%esp)
80101717:	e8 5a 1c 00 00       	call   80103376 <log_write>
      brelse(bp);
8010171c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010171f:	89 04 24             	mov    %eax,(%esp)
80101722:	e8 f0 ea ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101727:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010172a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010172e:	8b 45 08             	mov    0x8(%ebp),%eax
80101731:	89 04 24             	mov    %eax,(%esp)
80101734:	e8 e3 00 00 00       	call   8010181c <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80101739:	c9                   	leave  
8010173a:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
8010173b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010173e:	89 04 24             	mov    %eax,(%esp)
80101741:	e8 d1 ea ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80101746:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010174a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010174d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101750:	39 c2                	cmp    %eax,%edx
80101752:	0f 82 5a ff ff ff    	jb     801016b2 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101758:	c7 04 24 58 83 10 80 	movl   $0x80108358,(%esp)
8010175f:	e8 d9 ed ff ff       	call   8010053d <panic>

80101764 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101764:	55                   	push   %ebp
80101765:	89 e5                	mov    %esp,%ebp
80101767:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
8010176a:	8b 45 08             	mov    0x8(%ebp),%eax
8010176d:	8b 40 04             	mov    0x4(%eax),%eax
80101770:	c1 e8 03             	shr    $0x3,%eax
80101773:	8d 50 02             	lea    0x2(%eax),%edx
80101776:	8b 45 08             	mov    0x8(%ebp),%eax
80101779:	8b 00                	mov    (%eax),%eax
8010177b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010177f:	89 04 24             	mov    %eax,(%esp)
80101782:	e8 1f ea ff ff       	call   801001a6 <bread>
80101787:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
8010178a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010178d:	8d 50 18             	lea    0x18(%eax),%edx
80101790:	8b 45 08             	mov    0x8(%ebp),%eax
80101793:	8b 40 04             	mov    0x4(%eax),%eax
80101796:	83 e0 07             	and    $0x7,%eax
80101799:	c1 e0 06             	shl    $0x6,%eax
8010179c:	01 d0                	add    %edx,%eax
8010179e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
801017a1:	8b 45 08             	mov    0x8(%ebp),%eax
801017a4:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801017a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017ab:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
801017ae:	8b 45 08             	mov    0x8(%ebp),%eax
801017b1:	0f b7 50 12          	movzwl 0x12(%eax),%edx
801017b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017b8:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
801017bc:	8b 45 08             	mov    0x8(%ebp),%eax
801017bf:	0f b7 50 14          	movzwl 0x14(%eax),%edx
801017c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017c6:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801017ca:	8b 45 08             	mov    0x8(%ebp),%eax
801017cd:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801017d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017d4:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801017d8:	8b 45 08             	mov    0x8(%ebp),%eax
801017db:	8b 50 18             	mov    0x18(%eax),%edx
801017de:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017e1:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801017e4:	8b 45 08             	mov    0x8(%ebp),%eax
801017e7:	8d 50 1c             	lea    0x1c(%eax),%edx
801017ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801017ed:	83 c0 0c             	add    $0xc,%eax
801017f0:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801017f7:	00 
801017f8:	89 54 24 04          	mov    %edx,0x4(%esp)
801017fc:	89 04 24             	mov    %eax,(%esp)
801017ff:	e8 79 37 00 00       	call   80104f7d <memmove>
  log_write(bp);
80101804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101807:	89 04 24             	mov    %eax,(%esp)
8010180a:	e8 67 1b 00 00       	call   80103376 <log_write>
  brelse(bp);
8010180f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101812:	89 04 24             	mov    %eax,(%esp)
80101815:	e8 fd e9 ff ff       	call   80100217 <brelse>
}
8010181a:	c9                   	leave  
8010181b:	c3                   	ret    

8010181c <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
8010181c:	55                   	push   %ebp
8010181d:	89 e5                	mov    %esp,%ebp
8010181f:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101822:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101829:	e8 2d 34 00 00       	call   80104c5b <acquire>

  // Is the inode already cached?
  empty = 0;
8010182e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101835:	c7 45 f4 94 ed 10 80 	movl   $0x8010ed94,-0xc(%ebp)
8010183c:	eb 59                	jmp    80101897 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010183e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101841:	8b 40 08             	mov    0x8(%eax),%eax
80101844:	85 c0                	test   %eax,%eax
80101846:	7e 35                	jle    8010187d <iget+0x61>
80101848:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010184b:	8b 00                	mov    (%eax),%eax
8010184d:	3b 45 08             	cmp    0x8(%ebp),%eax
80101850:	75 2b                	jne    8010187d <iget+0x61>
80101852:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101855:	8b 40 04             	mov    0x4(%eax),%eax
80101858:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010185b:	75 20                	jne    8010187d <iget+0x61>
      ip->ref++;
8010185d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101860:	8b 40 08             	mov    0x8(%eax),%eax
80101863:	8d 50 01             	lea    0x1(%eax),%edx
80101866:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101869:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
8010186c:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101873:	e8 45 34 00 00       	call   80104cbd <release>
      return ip;
80101878:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010187b:	eb 6f                	jmp    801018ec <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010187d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101881:	75 10                	jne    80101893 <iget+0x77>
80101883:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101886:	8b 40 08             	mov    0x8(%eax),%eax
80101889:	85 c0                	test   %eax,%eax
8010188b:	75 06                	jne    80101893 <iget+0x77>
      empty = ip;
8010188d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101890:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101893:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101897:	81 7d f4 34 fd 10 80 	cmpl   $0x8010fd34,-0xc(%ebp)
8010189e:	72 9e                	jb     8010183e <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
801018a0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801018a4:	75 0c                	jne    801018b2 <iget+0x96>
    panic("iget: no inodes");
801018a6:	c7 04 24 6a 83 10 80 	movl   $0x8010836a,(%esp)
801018ad:	e8 8b ec ff ff       	call   8010053d <panic>

  ip = empty;
801018b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018b5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
801018b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018bb:	8b 55 08             	mov    0x8(%ebp),%edx
801018be:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801018c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c3:	8b 55 0c             	mov    0xc(%ebp),%edx
801018c6:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801018c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018cc:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
801018d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018d6:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
801018dd:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
801018e4:	e8 d4 33 00 00       	call   80104cbd <release>

  return ip;
801018e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801018ec:	c9                   	leave  
801018ed:	c3                   	ret    

801018ee <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801018ee:	55                   	push   %ebp
801018ef:	89 e5                	mov    %esp,%ebp
801018f1:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
801018f4:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
801018fb:	e8 5b 33 00 00       	call   80104c5b <acquire>
  ip->ref++;
80101900:	8b 45 08             	mov    0x8(%ebp),%eax
80101903:	8b 40 08             	mov    0x8(%eax),%eax
80101906:	8d 50 01             	lea    0x1(%eax),%edx
80101909:	8b 45 08             	mov    0x8(%ebp),%eax
8010190c:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
8010190f:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101916:	e8 a2 33 00 00       	call   80104cbd <release>
  return ip;
8010191b:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010191e:	c9                   	leave  
8010191f:	c3                   	ret    

80101920 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101920:	55                   	push   %ebp
80101921:	89 e5                	mov    %esp,%ebp
80101923:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101926:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010192a:	74 0a                	je     80101936 <ilock+0x16>
8010192c:	8b 45 08             	mov    0x8(%ebp),%eax
8010192f:	8b 40 08             	mov    0x8(%eax),%eax
80101932:	85 c0                	test   %eax,%eax
80101934:	7f 0c                	jg     80101942 <ilock+0x22>
    panic("ilock");
80101936:	c7 04 24 7a 83 10 80 	movl   $0x8010837a,(%esp)
8010193d:	e8 fb eb ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101942:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101949:	e8 0d 33 00 00       	call   80104c5b <acquire>
  while(ip->flags & I_BUSY)
8010194e:	eb 13                	jmp    80101963 <ilock+0x43>
    sleep(ip, &icache.lock);
80101950:	c7 44 24 04 60 ed 10 	movl   $0x8010ed60,0x4(%esp)
80101957:	80 
80101958:	8b 45 08             	mov    0x8(%ebp),%eax
8010195b:	89 04 24             	mov    %eax,(%esp)
8010195e:	e8 1a 30 00 00       	call   8010497d <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101963:	8b 45 08             	mov    0x8(%ebp),%eax
80101966:	8b 40 0c             	mov    0xc(%eax),%eax
80101969:	83 e0 01             	and    $0x1,%eax
8010196c:	84 c0                	test   %al,%al
8010196e:	75 e0                	jne    80101950 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101970:	8b 45 08             	mov    0x8(%ebp),%eax
80101973:	8b 40 0c             	mov    0xc(%eax),%eax
80101976:	89 c2                	mov    %eax,%edx
80101978:	83 ca 01             	or     $0x1,%edx
8010197b:	8b 45 08             	mov    0x8(%ebp),%eax
8010197e:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101981:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101988:	e8 30 33 00 00       	call   80104cbd <release>

  if(!(ip->flags & I_VALID)){
8010198d:	8b 45 08             	mov    0x8(%ebp),%eax
80101990:	8b 40 0c             	mov    0xc(%eax),%eax
80101993:	83 e0 02             	and    $0x2,%eax
80101996:	85 c0                	test   %eax,%eax
80101998:	0f 85 ce 00 00 00    	jne    80101a6c <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
8010199e:	8b 45 08             	mov    0x8(%ebp),%eax
801019a1:	8b 40 04             	mov    0x4(%eax),%eax
801019a4:	c1 e8 03             	shr    $0x3,%eax
801019a7:	8d 50 02             	lea    0x2(%eax),%edx
801019aa:	8b 45 08             	mov    0x8(%ebp),%eax
801019ad:	8b 00                	mov    (%eax),%eax
801019af:	89 54 24 04          	mov    %edx,0x4(%esp)
801019b3:	89 04 24             	mov    %eax,(%esp)
801019b6:	e8 eb e7 ff ff       	call   801001a6 <bread>
801019bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
801019be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c1:	8d 50 18             	lea    0x18(%eax),%edx
801019c4:	8b 45 08             	mov    0x8(%ebp),%eax
801019c7:	8b 40 04             	mov    0x4(%eax),%eax
801019ca:	83 e0 07             	and    $0x7,%eax
801019cd:	c1 e0 06             	shl    $0x6,%eax
801019d0:	01 d0                	add    %edx,%eax
801019d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
801019d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019d8:	0f b7 10             	movzwl (%eax),%edx
801019db:	8b 45 08             	mov    0x8(%ebp),%eax
801019de:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
801019e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019e5:	0f b7 50 02          	movzwl 0x2(%eax),%edx
801019e9:	8b 45 08             	mov    0x8(%ebp),%eax
801019ec:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
801019f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019f3:	0f b7 50 04          	movzwl 0x4(%eax),%edx
801019f7:	8b 45 08             	mov    0x8(%ebp),%eax
801019fa:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
801019fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a01:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101a05:	8b 45 08             	mov    0x8(%ebp),%eax
80101a08:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101a0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a0f:	8b 50 08             	mov    0x8(%eax),%edx
80101a12:	8b 45 08             	mov    0x8(%ebp),%eax
80101a15:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101a18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a1b:	8d 50 0c             	lea    0xc(%eax),%edx
80101a1e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a21:	83 c0 1c             	add    $0x1c,%eax
80101a24:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101a2b:	00 
80101a2c:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a30:	89 04 24             	mov    %eax,(%esp)
80101a33:	e8 45 35 00 00       	call   80104f7d <memmove>
    brelse(bp);
80101a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a3b:	89 04 24             	mov    %eax,(%esp)
80101a3e:	e8 d4 e7 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80101a43:	8b 45 08             	mov    0x8(%ebp),%eax
80101a46:	8b 40 0c             	mov    0xc(%eax),%eax
80101a49:	89 c2                	mov    %eax,%edx
80101a4b:	83 ca 02             	or     $0x2,%edx
80101a4e:	8b 45 08             	mov    0x8(%ebp),%eax
80101a51:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80101a54:	8b 45 08             	mov    0x8(%ebp),%eax
80101a57:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101a5b:	66 85 c0             	test   %ax,%ax
80101a5e:	75 0c                	jne    80101a6c <ilock+0x14c>
      panic("ilock: no type");
80101a60:	c7 04 24 80 83 10 80 	movl   $0x80108380,(%esp)
80101a67:	e8 d1 ea ff ff       	call   8010053d <panic>
  }
}
80101a6c:	c9                   	leave  
80101a6d:	c3                   	ret    

80101a6e <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101a6e:	55                   	push   %ebp
80101a6f:	89 e5                	mov    %esp,%ebp
80101a71:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101a74:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a78:	74 17                	je     80101a91 <iunlock+0x23>
80101a7a:	8b 45 08             	mov    0x8(%ebp),%eax
80101a7d:	8b 40 0c             	mov    0xc(%eax),%eax
80101a80:	83 e0 01             	and    $0x1,%eax
80101a83:	85 c0                	test   %eax,%eax
80101a85:	74 0a                	je     80101a91 <iunlock+0x23>
80101a87:	8b 45 08             	mov    0x8(%ebp),%eax
80101a8a:	8b 40 08             	mov    0x8(%eax),%eax
80101a8d:	85 c0                	test   %eax,%eax
80101a8f:	7f 0c                	jg     80101a9d <iunlock+0x2f>
    panic("iunlock");
80101a91:	c7 04 24 8f 83 10 80 	movl   $0x8010838f,(%esp)
80101a98:	e8 a0 ea ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101a9d:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101aa4:	e8 b2 31 00 00       	call   80104c5b <acquire>
  ip->flags &= ~I_BUSY;
80101aa9:	8b 45 08             	mov    0x8(%ebp),%eax
80101aac:	8b 40 0c             	mov    0xc(%eax),%eax
80101aaf:	89 c2                	mov    %eax,%edx
80101ab1:	83 e2 fe             	and    $0xfffffffe,%edx
80101ab4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab7:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101aba:	8b 45 08             	mov    0x8(%ebp),%eax
80101abd:	89 04 24             	mov    %eax,(%esp)
80101ac0:	e8 91 2f 00 00       	call   80104a56 <wakeup>
  release(&icache.lock);
80101ac5:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101acc:	e8 ec 31 00 00       	call   80104cbd <release>
}
80101ad1:	c9                   	leave  
80101ad2:	c3                   	ret    

80101ad3 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101ad3:	55                   	push   %ebp
80101ad4:	89 e5                	mov    %esp,%ebp
80101ad6:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101ad9:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101ae0:	e8 76 31 00 00       	call   80104c5b <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101ae5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae8:	8b 40 08             	mov    0x8(%eax),%eax
80101aeb:	83 f8 01             	cmp    $0x1,%eax
80101aee:	0f 85 93 00 00 00    	jne    80101b87 <iput+0xb4>
80101af4:	8b 45 08             	mov    0x8(%ebp),%eax
80101af7:	8b 40 0c             	mov    0xc(%eax),%eax
80101afa:	83 e0 02             	and    $0x2,%eax
80101afd:	85 c0                	test   %eax,%eax
80101aff:	0f 84 82 00 00 00    	je     80101b87 <iput+0xb4>
80101b05:	8b 45 08             	mov    0x8(%ebp),%eax
80101b08:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101b0c:	66 85 c0             	test   %ax,%ax
80101b0f:	75 76                	jne    80101b87 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101b11:	8b 45 08             	mov    0x8(%ebp),%eax
80101b14:	8b 40 0c             	mov    0xc(%eax),%eax
80101b17:	83 e0 01             	and    $0x1,%eax
80101b1a:	84 c0                	test   %al,%al
80101b1c:	74 0c                	je     80101b2a <iput+0x57>
      panic("iput busy");
80101b1e:	c7 04 24 97 83 10 80 	movl   $0x80108397,(%esp)
80101b25:	e8 13 ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101b2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2d:	8b 40 0c             	mov    0xc(%eax),%eax
80101b30:	89 c2                	mov    %eax,%edx
80101b32:	83 ca 01             	or     $0x1,%edx
80101b35:	8b 45 08             	mov    0x8(%ebp),%eax
80101b38:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101b3b:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101b42:	e8 76 31 00 00       	call   80104cbd <release>
    itrunc(ip);
80101b47:	8b 45 08             	mov    0x8(%ebp),%eax
80101b4a:	89 04 24             	mov    %eax,(%esp)
80101b4d:	e8 72 01 00 00       	call   80101cc4 <itrunc>
    ip->type = 0;
80101b52:	8b 45 08             	mov    0x8(%ebp),%eax
80101b55:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101b5b:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5e:	89 04 24             	mov    %eax,(%esp)
80101b61:	e8 fe fb ff ff       	call   80101764 <iupdate>
    acquire(&icache.lock);
80101b66:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101b6d:	e8 e9 30 00 00       	call   80104c5b <acquire>
    ip->flags = 0;
80101b72:	8b 45 08             	mov    0x8(%ebp),%eax
80101b75:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101b7c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7f:	89 04 24             	mov    %eax,(%esp)
80101b82:	e8 cf 2e 00 00       	call   80104a56 <wakeup>
  }
  ip->ref--;
80101b87:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8a:	8b 40 08             	mov    0x8(%eax),%eax
80101b8d:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b90:	8b 45 08             	mov    0x8(%ebp),%eax
80101b93:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b96:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101b9d:	e8 1b 31 00 00       	call   80104cbd <release>
}
80101ba2:	c9                   	leave  
80101ba3:	c3                   	ret    

80101ba4 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101ba4:	55                   	push   %ebp
80101ba5:	89 e5                	mov    %esp,%ebp
80101ba7:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101baa:	8b 45 08             	mov    0x8(%ebp),%eax
80101bad:	89 04 24             	mov    %eax,(%esp)
80101bb0:	e8 b9 fe ff ff       	call   80101a6e <iunlock>
  iput(ip);
80101bb5:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb8:	89 04 24             	mov    %eax,(%esp)
80101bbb:	e8 13 ff ff ff       	call   80101ad3 <iput>
}
80101bc0:	c9                   	leave  
80101bc1:	c3                   	ret    

80101bc2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101bc2:	55                   	push   %ebp
80101bc3:	89 e5                	mov    %esp,%ebp
80101bc5:	53                   	push   %ebx
80101bc6:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101bc9:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101bcd:	77 3e                	ja     80101c0d <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101bcf:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd2:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bd5:	83 c2 04             	add    $0x4,%edx
80101bd8:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101bdc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bdf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101be3:	75 20                	jne    80101c05 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101be5:	8b 45 08             	mov    0x8(%ebp),%eax
80101be8:	8b 00                	mov    (%eax),%eax
80101bea:	89 04 24             	mov    %eax,(%esp)
80101bed:	e8 49 f8 ff ff       	call   8010143b <balloc>
80101bf2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bf5:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf8:	8b 55 0c             	mov    0xc(%ebp),%edx
80101bfb:	8d 4a 04             	lea    0x4(%edx),%ecx
80101bfe:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c01:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101c05:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c08:	e9 b1 00 00 00       	jmp    80101cbe <bmap+0xfc>
  }
  bn -= NDIRECT;
80101c0d:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101c11:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101c15:	0f 87 97 00 00 00    	ja     80101cb2 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101c1b:	8b 45 08             	mov    0x8(%ebp),%eax
80101c1e:	8b 40 4c             	mov    0x4c(%eax),%eax
80101c21:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c24:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c28:	75 19                	jne    80101c43 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101c2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2d:	8b 00                	mov    (%eax),%eax
80101c2f:	89 04 24             	mov    %eax,(%esp)
80101c32:	e8 04 f8 ff ff       	call   8010143b <balloc>
80101c37:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c3a:	8b 45 08             	mov    0x8(%ebp),%eax
80101c3d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c40:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101c43:	8b 45 08             	mov    0x8(%ebp),%eax
80101c46:	8b 00                	mov    (%eax),%eax
80101c48:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c4b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c4f:	89 04 24             	mov    %eax,(%esp)
80101c52:	e8 4f e5 ff ff       	call   801001a6 <bread>
80101c57:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101c5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c5d:	83 c0 18             	add    $0x18,%eax
80101c60:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101c63:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c66:	c1 e0 02             	shl    $0x2,%eax
80101c69:	03 45 ec             	add    -0x14(%ebp),%eax
80101c6c:	8b 00                	mov    (%eax),%eax
80101c6e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c71:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c75:	75 2b                	jne    80101ca2 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101c77:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c7a:	c1 e0 02             	shl    $0x2,%eax
80101c7d:	89 c3                	mov    %eax,%ebx
80101c7f:	03 5d ec             	add    -0x14(%ebp),%ebx
80101c82:	8b 45 08             	mov    0x8(%ebp),%eax
80101c85:	8b 00                	mov    (%eax),%eax
80101c87:	89 04 24             	mov    %eax,(%esp)
80101c8a:	e8 ac f7 ff ff       	call   8010143b <balloc>
80101c8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c92:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c95:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c97:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c9a:	89 04 24             	mov    %eax,(%esp)
80101c9d:	e8 d4 16 00 00       	call   80103376 <log_write>
    }
    brelse(bp);
80101ca2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ca5:	89 04 24             	mov    %eax,(%esp)
80101ca8:	e8 6a e5 ff ff       	call   80100217 <brelse>
    return addr;
80101cad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cb0:	eb 0c                	jmp    80101cbe <bmap+0xfc>
  }

  panic("bmap: out of range");
80101cb2:	c7 04 24 a1 83 10 80 	movl   $0x801083a1,(%esp)
80101cb9:	e8 7f e8 ff ff       	call   8010053d <panic>
}
80101cbe:	83 c4 24             	add    $0x24,%esp
80101cc1:	5b                   	pop    %ebx
80101cc2:	5d                   	pop    %ebp
80101cc3:	c3                   	ret    

80101cc4 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101cc4:	55                   	push   %ebp
80101cc5:	89 e5                	mov    %esp,%ebp
80101cc7:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101cca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101cd1:	eb 44                	jmp    80101d17 <itrunc+0x53>
    if(ip->addrs[i]){
80101cd3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cd9:	83 c2 04             	add    $0x4,%edx
80101cdc:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101ce0:	85 c0                	test   %eax,%eax
80101ce2:	74 2f                	je     80101d13 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101ce4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ce7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cea:	83 c2 04             	add    $0x4,%edx
80101ced:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101cf1:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf4:	8b 00                	mov    (%eax),%eax
80101cf6:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cfa:	89 04 24             	mov    %eax,(%esp)
80101cfd:	e8 90 f8 ff ff       	call   80101592 <bfree>
      ip->addrs[i] = 0;
80101d02:	8b 45 08             	mov    0x8(%ebp),%eax
80101d05:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d08:	83 c2 04             	add    $0x4,%edx
80101d0b:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101d12:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d13:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d17:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101d1b:	7e b6                	jle    80101cd3 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101d1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d20:	8b 40 4c             	mov    0x4c(%eax),%eax
80101d23:	85 c0                	test   %eax,%eax
80101d25:	0f 84 8f 00 00 00    	je     80101dba <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101d2b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2e:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d31:	8b 45 08             	mov    0x8(%ebp),%eax
80101d34:	8b 00                	mov    (%eax),%eax
80101d36:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d3a:	89 04 24             	mov    %eax,(%esp)
80101d3d:	e8 64 e4 ff ff       	call   801001a6 <bread>
80101d42:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101d45:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d48:	83 c0 18             	add    $0x18,%eax
80101d4b:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101d4e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101d55:	eb 2f                	jmp    80101d86 <itrunc+0xc2>
      if(a[j])
80101d57:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d5a:	c1 e0 02             	shl    $0x2,%eax
80101d5d:	03 45 e8             	add    -0x18(%ebp),%eax
80101d60:	8b 00                	mov    (%eax),%eax
80101d62:	85 c0                	test   %eax,%eax
80101d64:	74 1c                	je     80101d82 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101d66:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d69:	c1 e0 02             	shl    $0x2,%eax
80101d6c:	03 45 e8             	add    -0x18(%ebp),%eax
80101d6f:	8b 10                	mov    (%eax),%edx
80101d71:	8b 45 08             	mov    0x8(%ebp),%eax
80101d74:	8b 00                	mov    (%eax),%eax
80101d76:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d7a:	89 04 24             	mov    %eax,(%esp)
80101d7d:	e8 10 f8 ff ff       	call   80101592 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d82:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d89:	83 f8 7f             	cmp    $0x7f,%eax
80101d8c:	76 c9                	jbe    80101d57 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d8e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d91:	89 04 24             	mov    %eax,(%esp)
80101d94:	e8 7e e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d99:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9c:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d9f:	8b 45 08             	mov    0x8(%ebp),%eax
80101da2:	8b 00                	mov    (%eax),%eax
80101da4:	89 54 24 04          	mov    %edx,0x4(%esp)
80101da8:	89 04 24             	mov    %eax,(%esp)
80101dab:	e8 e2 f7 ff ff       	call   80101592 <bfree>
    ip->addrs[NDIRECT] = 0;
80101db0:	8b 45 08             	mov    0x8(%ebp),%eax
80101db3:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101dba:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbd:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101dc4:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc7:	89 04 24             	mov    %eax,(%esp)
80101dca:	e8 95 f9 ff ff       	call   80101764 <iupdate>
}
80101dcf:	c9                   	leave  
80101dd0:	c3                   	ret    

80101dd1 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101dd1:	55                   	push   %ebp
80101dd2:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101dd4:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd7:	8b 00                	mov    (%eax),%eax
80101dd9:	89 c2                	mov    %eax,%edx
80101ddb:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dde:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101de1:	8b 45 08             	mov    0x8(%ebp),%eax
80101de4:	8b 50 04             	mov    0x4(%eax),%edx
80101de7:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dea:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ded:	8b 45 08             	mov    0x8(%ebp),%eax
80101df0:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101df4:	8b 45 0c             	mov    0xc(%ebp),%eax
80101df7:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101dfa:	8b 45 08             	mov    0x8(%ebp),%eax
80101dfd:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101e01:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e04:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101e08:	8b 45 08             	mov    0x8(%ebp),%eax
80101e0b:	8b 50 18             	mov    0x18(%eax),%edx
80101e0e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e11:	89 50 10             	mov    %edx,0x10(%eax)
}
80101e14:	5d                   	pop    %ebp
80101e15:	c3                   	ret    

80101e16 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101e16:	55                   	push   %ebp
80101e17:	89 e5                	mov    %esp,%ebp
80101e19:	53                   	push   %ebx
80101e1a:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101e1d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e20:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101e24:	66 83 f8 03          	cmp    $0x3,%ax
80101e28:	75 60                	jne    80101e8a <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101e2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e2d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e31:	66 85 c0             	test   %ax,%ax
80101e34:	78 20                	js     80101e56 <readi+0x40>
80101e36:	8b 45 08             	mov    0x8(%ebp),%eax
80101e39:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e3d:	66 83 f8 09          	cmp    $0x9,%ax
80101e41:	7f 13                	jg     80101e56 <readi+0x40>
80101e43:	8b 45 08             	mov    0x8(%ebp),%eax
80101e46:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e4a:	98                   	cwtl   
80101e4b:	8b 04 c5 00 ed 10 80 	mov    -0x7fef1300(,%eax,8),%eax
80101e52:	85 c0                	test   %eax,%eax
80101e54:	75 0a                	jne    80101e60 <readi+0x4a>
      return -1;
80101e56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e5b:	e9 1b 01 00 00       	jmp    80101f7b <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101e60:	8b 45 08             	mov    0x8(%ebp),%eax
80101e63:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e67:	98                   	cwtl   
80101e68:	8b 14 c5 00 ed 10 80 	mov    -0x7fef1300(,%eax,8),%edx
80101e6f:	8b 45 14             	mov    0x14(%ebp),%eax
80101e72:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e76:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e79:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101e80:	89 04 24             	mov    %eax,(%esp)
80101e83:	ff d2                	call   *%edx
80101e85:	e9 f1 00 00 00       	jmp    80101f7b <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101e8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e8d:	8b 40 18             	mov    0x18(%eax),%eax
80101e90:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e93:	72 0d                	jb     80101ea2 <readi+0x8c>
80101e95:	8b 45 14             	mov    0x14(%ebp),%eax
80101e98:	8b 55 10             	mov    0x10(%ebp),%edx
80101e9b:	01 d0                	add    %edx,%eax
80101e9d:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ea0:	73 0a                	jae    80101eac <readi+0x96>
    return -1;
80101ea2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101ea7:	e9 cf 00 00 00       	jmp    80101f7b <readi+0x165>
  if(off + n > ip->size)
80101eac:	8b 45 14             	mov    0x14(%ebp),%eax
80101eaf:	8b 55 10             	mov    0x10(%ebp),%edx
80101eb2:	01 c2                	add    %eax,%edx
80101eb4:	8b 45 08             	mov    0x8(%ebp),%eax
80101eb7:	8b 40 18             	mov    0x18(%eax),%eax
80101eba:	39 c2                	cmp    %eax,%edx
80101ebc:	76 0c                	jbe    80101eca <readi+0xb4>
    n = ip->size - off;
80101ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec1:	8b 40 18             	mov    0x18(%eax),%eax
80101ec4:	2b 45 10             	sub    0x10(%ebp),%eax
80101ec7:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101eca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101ed1:	e9 96 00 00 00       	jmp    80101f6c <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101ed6:	8b 45 10             	mov    0x10(%ebp),%eax
80101ed9:	c1 e8 09             	shr    $0x9,%eax
80101edc:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ee0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee3:	89 04 24             	mov    %eax,(%esp)
80101ee6:	e8 d7 fc ff ff       	call   80101bc2 <bmap>
80101eeb:	8b 55 08             	mov    0x8(%ebp),%edx
80101eee:	8b 12                	mov    (%edx),%edx
80101ef0:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ef4:	89 14 24             	mov    %edx,(%esp)
80101ef7:	e8 aa e2 ff ff       	call   801001a6 <bread>
80101efc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101eff:	8b 45 10             	mov    0x10(%ebp),%eax
80101f02:	89 c2                	mov    %eax,%edx
80101f04:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101f0a:	b8 00 02 00 00       	mov    $0x200,%eax
80101f0f:	89 c1                	mov    %eax,%ecx
80101f11:	29 d1                	sub    %edx,%ecx
80101f13:	89 ca                	mov    %ecx,%edx
80101f15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f18:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101f1b:	89 cb                	mov    %ecx,%ebx
80101f1d:	29 c3                	sub    %eax,%ebx
80101f1f:	89 d8                	mov    %ebx,%eax
80101f21:	39 c2                	cmp    %eax,%edx
80101f23:	0f 46 c2             	cmovbe %edx,%eax
80101f26:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101f29:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f2c:	8d 50 18             	lea    0x18(%eax),%edx
80101f2f:	8b 45 10             	mov    0x10(%ebp),%eax
80101f32:	25 ff 01 00 00       	and    $0x1ff,%eax
80101f37:	01 c2                	add    %eax,%edx
80101f39:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f3c:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f40:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f44:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f47:	89 04 24             	mov    %eax,(%esp)
80101f4a:	e8 2e 30 00 00       	call   80104f7d <memmove>
    brelse(bp);
80101f4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f52:	89 04 24             	mov    %eax,(%esp)
80101f55:	e8 bd e2 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101f5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f5d:	01 45 f4             	add    %eax,-0xc(%ebp)
80101f60:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f63:	01 45 10             	add    %eax,0x10(%ebp)
80101f66:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f69:	01 45 0c             	add    %eax,0xc(%ebp)
80101f6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f6f:	3b 45 14             	cmp    0x14(%ebp),%eax
80101f72:	0f 82 5e ff ff ff    	jb     80101ed6 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101f78:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f7b:	83 c4 24             	add    $0x24,%esp
80101f7e:	5b                   	pop    %ebx
80101f7f:	5d                   	pop    %ebp
80101f80:	c3                   	ret    

80101f81 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f81:	55                   	push   %ebp
80101f82:	89 e5                	mov    %esp,%ebp
80101f84:	53                   	push   %ebx
80101f85:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f88:	8b 45 08             	mov    0x8(%ebp),%eax
80101f8b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f8f:	66 83 f8 03          	cmp    $0x3,%ax
80101f93:	75 60                	jne    80101ff5 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f95:	8b 45 08             	mov    0x8(%ebp),%eax
80101f98:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f9c:	66 85 c0             	test   %ax,%ax
80101f9f:	78 20                	js     80101fc1 <writei+0x40>
80101fa1:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa4:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fa8:	66 83 f8 09          	cmp    $0x9,%ax
80101fac:	7f 13                	jg     80101fc1 <writei+0x40>
80101fae:	8b 45 08             	mov    0x8(%ebp),%eax
80101fb1:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fb5:	98                   	cwtl   
80101fb6:	8b 04 c5 04 ed 10 80 	mov    -0x7fef12fc(,%eax,8),%eax
80101fbd:	85 c0                	test   %eax,%eax
80101fbf:	75 0a                	jne    80101fcb <writei+0x4a>
      return -1;
80101fc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fc6:	e9 46 01 00 00       	jmp    80102111 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101fcb:	8b 45 08             	mov    0x8(%ebp),%eax
80101fce:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101fd2:	98                   	cwtl   
80101fd3:	8b 14 c5 04 ed 10 80 	mov    -0x7fef12fc(,%eax,8),%edx
80101fda:	8b 45 14             	mov    0x14(%ebp),%eax
80101fdd:	89 44 24 08          	mov    %eax,0x8(%esp)
80101fe1:	8b 45 0c             	mov    0xc(%ebp),%eax
80101fe4:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe8:	8b 45 08             	mov    0x8(%ebp),%eax
80101feb:	89 04 24             	mov    %eax,(%esp)
80101fee:	ff d2                	call   *%edx
80101ff0:	e9 1c 01 00 00       	jmp    80102111 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80101ff5:	8b 45 08             	mov    0x8(%ebp),%eax
80101ff8:	8b 40 18             	mov    0x18(%eax),%eax
80101ffb:	3b 45 10             	cmp    0x10(%ebp),%eax
80101ffe:	72 0d                	jb     8010200d <writei+0x8c>
80102000:	8b 45 14             	mov    0x14(%ebp),%eax
80102003:	8b 55 10             	mov    0x10(%ebp),%edx
80102006:	01 d0                	add    %edx,%eax
80102008:	3b 45 10             	cmp    0x10(%ebp),%eax
8010200b:	73 0a                	jae    80102017 <writei+0x96>
    return -1;
8010200d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102012:	e9 fa 00 00 00       	jmp    80102111 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80102017:	8b 45 14             	mov    0x14(%ebp),%eax
8010201a:	8b 55 10             	mov    0x10(%ebp),%edx
8010201d:	01 d0                	add    %edx,%eax
8010201f:	3d 00 18 01 00       	cmp    $0x11800,%eax
80102024:	76 0a                	jbe    80102030 <writei+0xaf>
    return -1;
80102026:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010202b:	e9 e1 00 00 00       	jmp    80102111 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102030:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102037:	e9 a1 00 00 00       	jmp    801020dd <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010203c:	8b 45 10             	mov    0x10(%ebp),%eax
8010203f:	c1 e8 09             	shr    $0x9,%eax
80102042:	89 44 24 04          	mov    %eax,0x4(%esp)
80102046:	8b 45 08             	mov    0x8(%ebp),%eax
80102049:	89 04 24             	mov    %eax,(%esp)
8010204c:	e8 71 fb ff ff       	call   80101bc2 <bmap>
80102051:	8b 55 08             	mov    0x8(%ebp),%edx
80102054:	8b 12                	mov    (%edx),%edx
80102056:	89 44 24 04          	mov    %eax,0x4(%esp)
8010205a:	89 14 24             	mov    %edx,(%esp)
8010205d:	e8 44 e1 ff ff       	call   801001a6 <bread>
80102062:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102065:	8b 45 10             	mov    0x10(%ebp),%eax
80102068:	89 c2                	mov    %eax,%edx
8010206a:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102070:	b8 00 02 00 00       	mov    $0x200,%eax
80102075:	89 c1                	mov    %eax,%ecx
80102077:	29 d1                	sub    %edx,%ecx
80102079:	89 ca                	mov    %ecx,%edx
8010207b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010207e:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102081:	89 cb                	mov    %ecx,%ebx
80102083:	29 c3                	sub    %eax,%ebx
80102085:	89 d8                	mov    %ebx,%eax
80102087:	39 c2                	cmp    %eax,%edx
80102089:	0f 46 c2             	cmovbe %edx,%eax
8010208c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010208f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102092:	8d 50 18             	lea    0x18(%eax),%edx
80102095:	8b 45 10             	mov    0x10(%ebp),%eax
80102098:	25 ff 01 00 00       	and    $0x1ff,%eax
8010209d:	01 c2                	add    %eax,%edx
8010209f:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020a2:	89 44 24 08          	mov    %eax,0x8(%esp)
801020a6:	8b 45 0c             	mov    0xc(%ebp),%eax
801020a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801020ad:	89 14 24             	mov    %edx,(%esp)
801020b0:	e8 c8 2e 00 00       	call   80104f7d <memmove>
    log_write(bp);
801020b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020b8:	89 04 24             	mov    %eax,(%esp)
801020bb:	e8 b6 12 00 00       	call   80103376 <log_write>
    brelse(bp);
801020c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801020c3:	89 04 24             	mov    %eax,(%esp)
801020c6:	e8 4c e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801020cb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020ce:	01 45 f4             	add    %eax,-0xc(%ebp)
801020d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020d4:	01 45 10             	add    %eax,0x10(%ebp)
801020d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801020da:	01 45 0c             	add    %eax,0xc(%ebp)
801020dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801020e0:	3b 45 14             	cmp    0x14(%ebp),%eax
801020e3:	0f 82 53 ff ff ff    	jb     8010203c <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801020e9:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801020ed:	74 1f                	je     8010210e <writei+0x18d>
801020ef:	8b 45 08             	mov    0x8(%ebp),%eax
801020f2:	8b 40 18             	mov    0x18(%eax),%eax
801020f5:	3b 45 10             	cmp    0x10(%ebp),%eax
801020f8:	73 14                	jae    8010210e <writei+0x18d>
    ip->size = off;
801020fa:	8b 45 08             	mov    0x8(%ebp),%eax
801020fd:	8b 55 10             	mov    0x10(%ebp),%edx
80102100:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
80102103:	8b 45 08             	mov    0x8(%ebp),%eax
80102106:	89 04 24             	mov    %eax,(%esp)
80102109:	e8 56 f6 ff ff       	call   80101764 <iupdate>
  }
  return n;
8010210e:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102111:	83 c4 24             	add    $0x24,%esp
80102114:	5b                   	pop    %ebx
80102115:	5d                   	pop    %ebp
80102116:	c3                   	ret    

80102117 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
80102117:	55                   	push   %ebp
80102118:	89 e5                	mov    %esp,%ebp
8010211a:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
8010211d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102124:	00 
80102125:	8b 45 0c             	mov    0xc(%ebp),%eax
80102128:	89 44 24 04          	mov    %eax,0x4(%esp)
8010212c:	8b 45 08             	mov    0x8(%ebp),%eax
8010212f:	89 04 24             	mov    %eax,(%esp)
80102132:	e8 ea 2e 00 00       	call   80105021 <strncmp>
}
80102137:	c9                   	leave  
80102138:	c3                   	ret    

80102139 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
80102139:	55                   	push   %ebp
8010213a:	89 e5                	mov    %esp,%ebp
8010213c:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
8010213f:	8b 45 08             	mov    0x8(%ebp),%eax
80102142:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102146:	66 83 f8 01          	cmp    $0x1,%ax
8010214a:	74 0c                	je     80102158 <dirlookup+0x1f>
    panic("dirlookup not DIR");
8010214c:	c7 04 24 b4 83 10 80 	movl   $0x801083b4,(%esp)
80102153:	e8 e5 e3 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102158:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010215f:	e9 87 00 00 00       	jmp    801021eb <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102164:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010216b:	00 
8010216c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010216f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102173:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102176:	89 44 24 04          	mov    %eax,0x4(%esp)
8010217a:	8b 45 08             	mov    0x8(%ebp),%eax
8010217d:	89 04 24             	mov    %eax,(%esp)
80102180:	e8 91 fc ff ff       	call   80101e16 <readi>
80102185:	83 f8 10             	cmp    $0x10,%eax
80102188:	74 0c                	je     80102196 <dirlookup+0x5d>
      panic("dirlink read");
8010218a:	c7 04 24 c6 83 10 80 	movl   $0x801083c6,(%esp)
80102191:	e8 a7 e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102196:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010219a:	66 85 c0             	test   %ax,%ax
8010219d:	74 47                	je     801021e6 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
8010219f:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021a2:	83 c0 02             	add    $0x2,%eax
801021a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801021a9:	8b 45 0c             	mov    0xc(%ebp),%eax
801021ac:	89 04 24             	mov    %eax,(%esp)
801021af:	e8 63 ff ff ff       	call   80102117 <namecmp>
801021b4:	85 c0                	test   %eax,%eax
801021b6:	75 2f                	jne    801021e7 <dirlookup+0xae>
      // entry matches path element
      if(poff)
801021b8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801021bc:	74 08                	je     801021c6 <dirlookup+0x8d>
        *poff = off;
801021be:	8b 45 10             	mov    0x10(%ebp),%eax
801021c1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021c4:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
801021c6:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
801021ca:	0f b7 c0             	movzwl %ax,%eax
801021cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
801021d0:	8b 45 08             	mov    0x8(%ebp),%eax
801021d3:	8b 00                	mov    (%eax),%eax
801021d5:	8b 55 f0             	mov    -0x10(%ebp),%edx
801021d8:	89 54 24 04          	mov    %edx,0x4(%esp)
801021dc:	89 04 24             	mov    %eax,(%esp)
801021df:	e8 38 f6 ff ff       	call   8010181c <iget>
801021e4:	eb 19                	jmp    801021ff <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
801021e6:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801021e7:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801021eb:	8b 45 08             	mov    0x8(%ebp),%eax
801021ee:	8b 40 18             	mov    0x18(%eax),%eax
801021f1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801021f4:	0f 87 6a ff ff ff    	ja     80102164 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801021fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801021ff:	c9                   	leave  
80102200:	c3                   	ret    

80102201 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
80102201:	55                   	push   %ebp
80102202:	89 e5                	mov    %esp,%ebp
80102204:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
80102207:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010220e:	00 
8010220f:	8b 45 0c             	mov    0xc(%ebp),%eax
80102212:	89 44 24 04          	mov    %eax,0x4(%esp)
80102216:	8b 45 08             	mov    0x8(%ebp),%eax
80102219:	89 04 24             	mov    %eax,(%esp)
8010221c:	e8 18 ff ff ff       	call   80102139 <dirlookup>
80102221:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102224:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102228:	74 15                	je     8010223f <dirlink+0x3e>
    iput(ip);
8010222a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010222d:	89 04 24             	mov    %eax,(%esp)
80102230:	e8 9e f8 ff ff       	call   80101ad3 <iput>
    return -1;
80102235:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010223a:	e9 b8 00 00 00       	jmp    801022f7 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010223f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102246:	eb 44                	jmp    8010228c <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102248:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010224b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102252:	00 
80102253:	89 44 24 08          	mov    %eax,0x8(%esp)
80102257:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010225a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010225e:	8b 45 08             	mov    0x8(%ebp),%eax
80102261:	89 04 24             	mov    %eax,(%esp)
80102264:	e8 ad fb ff ff       	call   80101e16 <readi>
80102269:	83 f8 10             	cmp    $0x10,%eax
8010226c:	74 0c                	je     8010227a <dirlink+0x79>
      panic("dirlink read");
8010226e:	c7 04 24 c6 83 10 80 	movl   $0x801083c6,(%esp)
80102275:	e8 c3 e2 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010227a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010227e:	66 85 c0             	test   %ax,%ax
80102281:	74 18                	je     8010229b <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102283:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102286:	83 c0 10             	add    $0x10,%eax
80102289:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010228c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010228f:	8b 45 08             	mov    0x8(%ebp),%eax
80102292:	8b 40 18             	mov    0x18(%eax),%eax
80102295:	39 c2                	cmp    %eax,%edx
80102297:	72 af                	jb     80102248 <dirlink+0x47>
80102299:	eb 01                	jmp    8010229c <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
8010229b:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
8010229c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022a3:	00 
801022a4:	8b 45 0c             	mov    0xc(%ebp),%eax
801022a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801022ab:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022ae:	83 c0 02             	add    $0x2,%eax
801022b1:	89 04 24             	mov    %eax,(%esp)
801022b4:	e8 c0 2d 00 00       	call   80105079 <strncpy>
  de.inum = inum;
801022b9:	8b 45 10             	mov    0x10(%ebp),%eax
801022bc:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801022c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022c3:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801022ca:	00 
801022cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801022cf:	8d 45 e0             	lea    -0x20(%ebp),%eax
801022d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801022d6:	8b 45 08             	mov    0x8(%ebp),%eax
801022d9:	89 04 24             	mov    %eax,(%esp)
801022dc:	e8 a0 fc ff ff       	call   80101f81 <writei>
801022e1:	83 f8 10             	cmp    $0x10,%eax
801022e4:	74 0c                	je     801022f2 <dirlink+0xf1>
    panic("dirlink");
801022e6:	c7 04 24 d3 83 10 80 	movl   $0x801083d3,(%esp)
801022ed:	e8 4b e2 ff ff       	call   8010053d <panic>
  
  return 0;
801022f2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022f7:	c9                   	leave  
801022f8:	c3                   	ret    

801022f9 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801022f9:	55                   	push   %ebp
801022fa:	89 e5                	mov    %esp,%ebp
801022fc:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801022ff:	eb 04                	jmp    80102305 <skipelem+0xc>
    path++;
80102301:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102305:	8b 45 08             	mov    0x8(%ebp),%eax
80102308:	0f b6 00             	movzbl (%eax),%eax
8010230b:	3c 2f                	cmp    $0x2f,%al
8010230d:	74 f2                	je     80102301 <skipelem+0x8>
    path++;
  if(*path == 0)
8010230f:	8b 45 08             	mov    0x8(%ebp),%eax
80102312:	0f b6 00             	movzbl (%eax),%eax
80102315:	84 c0                	test   %al,%al
80102317:	75 0a                	jne    80102323 <skipelem+0x2a>
    return 0;
80102319:	b8 00 00 00 00       	mov    $0x0,%eax
8010231e:	e9 86 00 00 00       	jmp    801023a9 <skipelem+0xb0>
  s = path;
80102323:	8b 45 08             	mov    0x8(%ebp),%eax
80102326:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
80102329:	eb 04                	jmp    8010232f <skipelem+0x36>
    path++;
8010232b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
8010232f:	8b 45 08             	mov    0x8(%ebp),%eax
80102332:	0f b6 00             	movzbl (%eax),%eax
80102335:	3c 2f                	cmp    $0x2f,%al
80102337:	74 0a                	je     80102343 <skipelem+0x4a>
80102339:	8b 45 08             	mov    0x8(%ebp),%eax
8010233c:	0f b6 00             	movzbl (%eax),%eax
8010233f:	84 c0                	test   %al,%al
80102341:	75 e8                	jne    8010232b <skipelem+0x32>
    path++;
  len = path - s;
80102343:	8b 55 08             	mov    0x8(%ebp),%edx
80102346:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102349:	89 d1                	mov    %edx,%ecx
8010234b:	29 c1                	sub    %eax,%ecx
8010234d:	89 c8                	mov    %ecx,%eax
8010234f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102352:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102356:	7e 1c                	jle    80102374 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80102358:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010235f:	00 
80102360:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102363:	89 44 24 04          	mov    %eax,0x4(%esp)
80102367:	8b 45 0c             	mov    0xc(%ebp),%eax
8010236a:	89 04 24             	mov    %eax,(%esp)
8010236d:	e8 0b 2c 00 00       	call   80104f7d <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102372:	eb 28                	jmp    8010239c <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102374:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102377:	89 44 24 08          	mov    %eax,0x8(%esp)
8010237b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010237e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102382:	8b 45 0c             	mov    0xc(%ebp),%eax
80102385:	89 04 24             	mov    %eax,(%esp)
80102388:	e8 f0 2b 00 00       	call   80104f7d <memmove>
    name[len] = 0;
8010238d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102390:	03 45 0c             	add    0xc(%ebp),%eax
80102393:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102396:	eb 04                	jmp    8010239c <skipelem+0xa3>
    path++;
80102398:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010239c:	8b 45 08             	mov    0x8(%ebp),%eax
8010239f:	0f b6 00             	movzbl (%eax),%eax
801023a2:	3c 2f                	cmp    $0x2f,%al
801023a4:	74 f2                	je     80102398 <skipelem+0x9f>
    path++;
  return path;
801023a6:	8b 45 08             	mov    0x8(%ebp),%eax
}
801023a9:	c9                   	leave  
801023aa:	c3                   	ret    

801023ab <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
801023ab:	55                   	push   %ebp
801023ac:	89 e5                	mov    %esp,%ebp
801023ae:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
801023b1:	8b 45 08             	mov    0x8(%ebp),%eax
801023b4:	0f b6 00             	movzbl (%eax),%eax
801023b7:	3c 2f                	cmp    $0x2f,%al
801023b9:	75 1c                	jne    801023d7 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
801023bb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801023c2:	00 
801023c3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801023ca:	e8 4d f4 ff ff       	call   8010181c <iget>
801023cf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
801023d2:	e9 af 00 00 00       	jmp    80102486 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
801023d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801023dd:	8b 40 68             	mov    0x68(%eax),%eax
801023e0:	89 04 24             	mov    %eax,(%esp)
801023e3:	e8 06 f5 ff ff       	call   801018ee <idup>
801023e8:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801023eb:	e9 96 00 00 00       	jmp    80102486 <namex+0xdb>
    ilock(ip);
801023f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023f3:	89 04 24             	mov    %eax,(%esp)
801023f6:	e8 25 f5 ff ff       	call   80101920 <ilock>
    if(ip->type != T_DIR){
801023fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023fe:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102402:	66 83 f8 01          	cmp    $0x1,%ax
80102406:	74 15                	je     8010241d <namex+0x72>
      iunlockput(ip);
80102408:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010240b:	89 04 24             	mov    %eax,(%esp)
8010240e:	e8 91 f7 ff ff       	call   80101ba4 <iunlockput>
      return 0;
80102413:	b8 00 00 00 00       	mov    $0x0,%eax
80102418:	e9 a3 00 00 00       	jmp    801024c0 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
8010241d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102421:	74 1d                	je     80102440 <namex+0x95>
80102423:	8b 45 08             	mov    0x8(%ebp),%eax
80102426:	0f b6 00             	movzbl (%eax),%eax
80102429:	84 c0                	test   %al,%al
8010242b:	75 13                	jne    80102440 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
8010242d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102430:	89 04 24             	mov    %eax,(%esp)
80102433:	e8 36 f6 ff ff       	call   80101a6e <iunlock>
      return ip;
80102438:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010243b:	e9 80 00 00 00       	jmp    801024c0 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102440:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102447:	00 
80102448:	8b 45 10             	mov    0x10(%ebp),%eax
8010244b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010244f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102452:	89 04 24             	mov    %eax,(%esp)
80102455:	e8 df fc ff ff       	call   80102139 <dirlookup>
8010245a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010245d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102461:	75 12                	jne    80102475 <namex+0xca>
      iunlockput(ip);
80102463:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102466:	89 04 24             	mov    %eax,(%esp)
80102469:	e8 36 f7 ff ff       	call   80101ba4 <iunlockput>
      return 0;
8010246e:	b8 00 00 00 00       	mov    $0x0,%eax
80102473:	eb 4b                	jmp    801024c0 <namex+0x115>
    }
    iunlockput(ip);
80102475:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102478:	89 04 24             	mov    %eax,(%esp)
8010247b:	e8 24 f7 ff ff       	call   80101ba4 <iunlockput>
    ip = next;
80102480:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102483:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102486:	8b 45 10             	mov    0x10(%ebp),%eax
80102489:	89 44 24 04          	mov    %eax,0x4(%esp)
8010248d:	8b 45 08             	mov    0x8(%ebp),%eax
80102490:	89 04 24             	mov    %eax,(%esp)
80102493:	e8 61 fe ff ff       	call   801022f9 <skipelem>
80102498:	89 45 08             	mov    %eax,0x8(%ebp)
8010249b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010249f:	0f 85 4b ff ff ff    	jne    801023f0 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
801024a5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801024a9:	74 12                	je     801024bd <namex+0x112>
    iput(ip);
801024ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024ae:	89 04 24             	mov    %eax,(%esp)
801024b1:	e8 1d f6 ff ff       	call   80101ad3 <iput>
    return 0;
801024b6:	b8 00 00 00 00       	mov    $0x0,%eax
801024bb:	eb 03                	jmp    801024c0 <namex+0x115>
  }
  return ip;
801024bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801024c0:	c9                   	leave  
801024c1:	c3                   	ret    

801024c2 <namei>:

struct inode*
namei(char *path)
{
801024c2:	55                   	push   %ebp
801024c3:	89 e5                	mov    %esp,%ebp
801024c5:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
801024c8:	8d 45 ea             	lea    -0x16(%ebp),%eax
801024cb:	89 44 24 08          	mov    %eax,0x8(%esp)
801024cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801024d6:	00 
801024d7:	8b 45 08             	mov    0x8(%ebp),%eax
801024da:	89 04 24             	mov    %eax,(%esp)
801024dd:	e8 c9 fe ff ff       	call   801023ab <namex>
}
801024e2:	c9                   	leave  
801024e3:	c3                   	ret    

801024e4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
801024e4:	55                   	push   %ebp
801024e5:	89 e5                	mov    %esp,%ebp
801024e7:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
801024ea:	8b 45 0c             	mov    0xc(%ebp),%eax
801024ed:	89 44 24 08          	mov    %eax,0x8(%esp)
801024f1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801024f8:	00 
801024f9:	8b 45 08             	mov    0x8(%ebp),%eax
801024fc:	89 04 24             	mov    %eax,(%esp)
801024ff:	e8 a7 fe ff ff       	call   801023ab <namex>
}
80102504:	c9                   	leave  
80102505:	c3                   	ret    
	...

80102508 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102508:	55                   	push   %ebp
80102509:	89 e5                	mov    %esp,%ebp
8010250b:	53                   	push   %ebx
8010250c:	83 ec 14             	sub    $0x14,%esp
8010250f:	8b 45 08             	mov    0x8(%ebp),%eax
80102512:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102516:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010251a:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010251e:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102522:	ec                   	in     (%dx),%al
80102523:	89 c3                	mov    %eax,%ebx
80102525:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102528:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
8010252c:	83 c4 14             	add    $0x14,%esp
8010252f:	5b                   	pop    %ebx
80102530:	5d                   	pop    %ebp
80102531:	c3                   	ret    

80102532 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102532:	55                   	push   %ebp
80102533:	89 e5                	mov    %esp,%ebp
80102535:	57                   	push   %edi
80102536:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102537:	8b 55 08             	mov    0x8(%ebp),%edx
8010253a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010253d:	8b 45 10             	mov    0x10(%ebp),%eax
80102540:	89 cb                	mov    %ecx,%ebx
80102542:	89 df                	mov    %ebx,%edi
80102544:	89 c1                	mov    %eax,%ecx
80102546:	fc                   	cld    
80102547:	f3 6d                	rep insl (%dx),%es:(%edi)
80102549:	89 c8                	mov    %ecx,%eax
8010254b:	89 fb                	mov    %edi,%ebx
8010254d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102550:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102553:	5b                   	pop    %ebx
80102554:	5f                   	pop    %edi
80102555:	5d                   	pop    %ebp
80102556:	c3                   	ret    

80102557 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102557:	55                   	push   %ebp
80102558:	89 e5                	mov    %esp,%ebp
8010255a:	83 ec 08             	sub    $0x8,%esp
8010255d:	8b 55 08             	mov    0x8(%ebp),%edx
80102560:	8b 45 0c             	mov    0xc(%ebp),%eax
80102563:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102567:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010256a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010256e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102572:	ee                   	out    %al,(%dx)
}
80102573:	c9                   	leave  
80102574:	c3                   	ret    

80102575 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102575:	55                   	push   %ebp
80102576:	89 e5                	mov    %esp,%ebp
80102578:	56                   	push   %esi
80102579:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
8010257a:	8b 55 08             	mov    0x8(%ebp),%edx
8010257d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102580:	8b 45 10             	mov    0x10(%ebp),%eax
80102583:	89 cb                	mov    %ecx,%ebx
80102585:	89 de                	mov    %ebx,%esi
80102587:	89 c1                	mov    %eax,%ecx
80102589:	fc                   	cld    
8010258a:	f3 6f                	rep outsl %ds:(%esi),(%dx)
8010258c:	89 c8                	mov    %ecx,%eax
8010258e:	89 f3                	mov    %esi,%ebx
80102590:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102593:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102596:	5b                   	pop    %ebx
80102597:	5e                   	pop    %esi
80102598:	5d                   	pop    %ebp
80102599:	c3                   	ret    

8010259a <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010259a:	55                   	push   %ebp
8010259b:	89 e5                	mov    %esp,%ebp
8010259d:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
801025a0:	90                   	nop
801025a1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801025a8:	e8 5b ff ff ff       	call   80102508 <inb>
801025ad:	0f b6 c0             	movzbl %al,%eax
801025b0:	89 45 fc             	mov    %eax,-0x4(%ebp)
801025b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
801025b6:	25 c0 00 00 00       	and    $0xc0,%eax
801025bb:	83 f8 40             	cmp    $0x40,%eax
801025be:	75 e1                	jne    801025a1 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
801025c0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801025c4:	74 11                	je     801025d7 <idewait+0x3d>
801025c6:	8b 45 fc             	mov    -0x4(%ebp),%eax
801025c9:	83 e0 21             	and    $0x21,%eax
801025cc:	85 c0                	test   %eax,%eax
801025ce:	74 07                	je     801025d7 <idewait+0x3d>
    return -1;
801025d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025d5:	eb 05                	jmp    801025dc <idewait+0x42>
  return 0;
801025d7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801025dc:	c9                   	leave  
801025dd:	c3                   	ret    

801025de <ideinit>:

void
ideinit(void)
{
801025de:	55                   	push   %ebp
801025df:	89 e5                	mov    %esp,%ebp
801025e1:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
801025e4:	c7 44 24 04 db 83 10 	movl   $0x801083db,0x4(%esp)
801025eb:	80 
801025ec:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801025f3:	e8 42 26 00 00       	call   80104c3a <initlock>
  picenable(IRQ_IDE);
801025f8:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801025ff:	e8 75 15 00 00       	call   80103b79 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102604:	a1 00 04 11 80       	mov    0x80110400,%eax
80102609:	83 e8 01             	sub    $0x1,%eax
8010260c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102610:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102617:	e8 12 04 00 00       	call   80102a2e <ioapicenable>
  idewait(0);
8010261c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102623:	e8 72 ff ff ff       	call   8010259a <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102628:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
8010262f:	00 
80102630:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102637:	e8 1b ff ff ff       	call   80102557 <outb>
  for(i=0; i<1000; i++){
8010263c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102643:	eb 20                	jmp    80102665 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102645:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010264c:	e8 b7 fe ff ff       	call   80102508 <inb>
80102651:	84 c0                	test   %al,%al
80102653:	74 0c                	je     80102661 <ideinit+0x83>
      havedisk1 = 1;
80102655:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
8010265c:	00 00 00 
      break;
8010265f:	eb 0d                	jmp    8010266e <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102661:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102665:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
8010266c:	7e d7                	jle    80102645 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
8010266e:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102675:	00 
80102676:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010267d:	e8 d5 fe ff ff       	call   80102557 <outb>
}
80102682:	c9                   	leave  
80102683:	c3                   	ret    

80102684 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102684:	55                   	push   %ebp
80102685:	89 e5                	mov    %esp,%ebp
80102687:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
8010268a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010268e:	75 0c                	jne    8010269c <idestart+0x18>
    panic("idestart");
80102690:	c7 04 24 df 83 10 80 	movl   $0x801083df,(%esp)
80102697:	e8 a1 de ff ff       	call   8010053d <panic>

  idewait(0);
8010269c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801026a3:	e8 f2 fe ff ff       	call   8010259a <idewait>
  outb(0x3f6, 0);  // generate interrupt
801026a8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801026af:	00 
801026b0:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
801026b7:	e8 9b fe ff ff       	call   80102557 <outb>
  outb(0x1f2, 1);  // number of sectors
801026bc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801026c3:	00 
801026c4:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
801026cb:	e8 87 fe ff ff       	call   80102557 <outb>
  outb(0x1f3, b->sector & 0xff);
801026d0:	8b 45 08             	mov    0x8(%ebp),%eax
801026d3:	8b 40 08             	mov    0x8(%eax),%eax
801026d6:	0f b6 c0             	movzbl %al,%eax
801026d9:	89 44 24 04          	mov    %eax,0x4(%esp)
801026dd:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
801026e4:	e8 6e fe ff ff       	call   80102557 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
801026e9:	8b 45 08             	mov    0x8(%ebp),%eax
801026ec:	8b 40 08             	mov    0x8(%eax),%eax
801026ef:	c1 e8 08             	shr    $0x8,%eax
801026f2:	0f b6 c0             	movzbl %al,%eax
801026f5:	89 44 24 04          	mov    %eax,0x4(%esp)
801026f9:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102700:	e8 52 fe ff ff       	call   80102557 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102705:	8b 45 08             	mov    0x8(%ebp),%eax
80102708:	8b 40 08             	mov    0x8(%eax),%eax
8010270b:	c1 e8 10             	shr    $0x10,%eax
8010270e:	0f b6 c0             	movzbl %al,%eax
80102711:	89 44 24 04          	mov    %eax,0x4(%esp)
80102715:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
8010271c:	e8 36 fe ff ff       	call   80102557 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102721:	8b 45 08             	mov    0x8(%ebp),%eax
80102724:	8b 40 04             	mov    0x4(%eax),%eax
80102727:	83 e0 01             	and    $0x1,%eax
8010272a:	89 c2                	mov    %eax,%edx
8010272c:	c1 e2 04             	shl    $0x4,%edx
8010272f:	8b 45 08             	mov    0x8(%ebp),%eax
80102732:	8b 40 08             	mov    0x8(%eax),%eax
80102735:	c1 e8 18             	shr    $0x18,%eax
80102738:	83 e0 0f             	and    $0xf,%eax
8010273b:	09 d0                	or     %edx,%eax
8010273d:	83 c8 e0             	or     $0xffffffe0,%eax
80102740:	0f b6 c0             	movzbl %al,%eax
80102743:	89 44 24 04          	mov    %eax,0x4(%esp)
80102747:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
8010274e:	e8 04 fe ff ff       	call   80102557 <outb>
  if(b->flags & B_DIRTY){
80102753:	8b 45 08             	mov    0x8(%ebp),%eax
80102756:	8b 00                	mov    (%eax),%eax
80102758:	83 e0 04             	and    $0x4,%eax
8010275b:	85 c0                	test   %eax,%eax
8010275d:	74 34                	je     80102793 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
8010275f:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102766:	00 
80102767:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010276e:	e8 e4 fd ff ff       	call   80102557 <outb>
    outsl(0x1f0, b->data, 512/4);
80102773:	8b 45 08             	mov    0x8(%ebp),%eax
80102776:	83 c0 18             	add    $0x18,%eax
80102779:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102780:	00 
80102781:	89 44 24 04          	mov    %eax,0x4(%esp)
80102785:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010278c:	e8 e4 fd ff ff       	call   80102575 <outsl>
80102791:	eb 14                	jmp    801027a7 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102793:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
8010279a:	00 
8010279b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801027a2:	e8 b0 fd ff ff       	call   80102557 <outb>
  }
}
801027a7:	c9                   	leave  
801027a8:	c3                   	ret    

801027a9 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
801027a9:	55                   	push   %ebp
801027aa:	89 e5                	mov    %esp,%ebp
801027ac:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
801027af:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027b6:	e8 a0 24 00 00       	call   80104c5b <acquire>
  if((b = idequeue) == 0){
801027bb:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027c0:	89 45 f4             	mov    %eax,-0xc(%ebp)
801027c3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801027c7:	75 11                	jne    801027da <ideintr+0x31>
    release(&idelock);
801027c9:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801027d0:	e8 e8 24 00 00       	call   80104cbd <release>
    // cprintf("spurious IDE interrupt\n");
    return;
801027d5:	e9 90 00 00 00       	jmp    8010286a <ideintr+0xc1>
  }
  idequeue = b->qnext;
801027da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027dd:	8b 40 14             	mov    0x14(%eax),%eax
801027e0:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801027e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027e8:	8b 00                	mov    (%eax),%eax
801027ea:	83 e0 04             	and    $0x4,%eax
801027ed:	85 c0                	test   %eax,%eax
801027ef:	75 2e                	jne    8010281f <ideintr+0x76>
801027f1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801027f8:	e8 9d fd ff ff       	call   8010259a <idewait>
801027fd:	85 c0                	test   %eax,%eax
801027ff:	78 1e                	js     8010281f <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102801:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102804:	83 c0 18             	add    $0x18,%eax
80102807:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010280e:	00 
8010280f:	89 44 24 04          	mov    %eax,0x4(%esp)
80102813:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
8010281a:	e8 13 fd ff ff       	call   80102532 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
8010281f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102822:	8b 00                	mov    (%eax),%eax
80102824:	89 c2                	mov    %eax,%edx
80102826:	83 ca 02             	or     $0x2,%edx
80102829:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010282c:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
8010282e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102831:	8b 00                	mov    (%eax),%eax
80102833:	89 c2                	mov    %eax,%edx
80102835:	83 e2 fb             	and    $0xfffffffb,%edx
80102838:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010283b:	89 10                	mov    %edx,(%eax)
  wakeup(b);
8010283d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102840:	89 04 24             	mov    %eax,(%esp)
80102843:	e8 0e 22 00 00       	call   80104a56 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102848:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010284d:	85 c0                	test   %eax,%eax
8010284f:	74 0d                	je     8010285e <ideintr+0xb5>
    idestart(idequeue);
80102851:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102856:	89 04 24             	mov    %eax,(%esp)
80102859:	e8 26 fe ff ff       	call   80102684 <idestart>

  release(&idelock);
8010285e:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102865:	e8 53 24 00 00       	call   80104cbd <release>
}
8010286a:	c9                   	leave  
8010286b:	c3                   	ret    

8010286c <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
8010286c:	55                   	push   %ebp
8010286d:	89 e5                	mov    %esp,%ebp
8010286f:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102872:	8b 45 08             	mov    0x8(%ebp),%eax
80102875:	8b 00                	mov    (%eax),%eax
80102877:	83 e0 01             	and    $0x1,%eax
8010287a:	85 c0                	test   %eax,%eax
8010287c:	75 0c                	jne    8010288a <iderw+0x1e>
    panic("iderw: buf not busy");
8010287e:	c7 04 24 e8 83 10 80 	movl   $0x801083e8,(%esp)
80102885:	e8 b3 dc ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
8010288a:	8b 45 08             	mov    0x8(%ebp),%eax
8010288d:	8b 00                	mov    (%eax),%eax
8010288f:	83 e0 06             	and    $0x6,%eax
80102892:	83 f8 02             	cmp    $0x2,%eax
80102895:	75 0c                	jne    801028a3 <iderw+0x37>
    panic("iderw: nothing to do");
80102897:	c7 04 24 fc 83 10 80 	movl   $0x801083fc,(%esp)
8010289e:	e8 9a dc ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
801028a3:	8b 45 08             	mov    0x8(%ebp),%eax
801028a6:	8b 40 04             	mov    0x4(%eax),%eax
801028a9:	85 c0                	test   %eax,%eax
801028ab:	74 15                	je     801028c2 <iderw+0x56>
801028ad:	a1 38 b6 10 80       	mov    0x8010b638,%eax
801028b2:	85 c0                	test   %eax,%eax
801028b4:	75 0c                	jne    801028c2 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
801028b6:	c7 04 24 11 84 10 80 	movl   $0x80108411,(%esp)
801028bd:	e8 7b dc ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
801028c2:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028c9:	e8 8d 23 00 00       	call   80104c5b <acquire>

  // Append b to idequeue.
  b->qnext = 0;
801028ce:	8b 45 08             	mov    0x8(%ebp),%eax
801028d1:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
801028d8:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
801028df:	eb 0b                	jmp    801028ec <iderw+0x80>
801028e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028e4:	8b 00                	mov    (%eax),%eax
801028e6:	83 c0 14             	add    $0x14,%eax
801028e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ef:	8b 00                	mov    (%eax),%eax
801028f1:	85 c0                	test   %eax,%eax
801028f3:	75 ec                	jne    801028e1 <iderw+0x75>
    ;
  *pp = b;
801028f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028f8:	8b 55 08             	mov    0x8(%ebp),%edx
801028fb:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
801028fd:	a1 34 b6 10 80       	mov    0x8010b634,%eax
80102902:	3b 45 08             	cmp    0x8(%ebp),%eax
80102905:	75 22                	jne    80102929 <iderw+0xbd>
    idestart(b);
80102907:	8b 45 08             	mov    0x8(%ebp),%eax
8010290a:	89 04 24             	mov    %eax,(%esp)
8010290d:	e8 72 fd ff ff       	call   80102684 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102912:	eb 15                	jmp    80102929 <iderw+0xbd>
    sleep(b, &idelock);
80102914:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
8010291b:	80 
8010291c:	8b 45 08             	mov    0x8(%ebp),%eax
8010291f:	89 04 24             	mov    %eax,(%esp)
80102922:	e8 56 20 00 00       	call   8010497d <sleep>
80102927:	eb 01                	jmp    8010292a <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102929:	90                   	nop
8010292a:	8b 45 08             	mov    0x8(%ebp),%eax
8010292d:	8b 00                	mov    (%eax),%eax
8010292f:	83 e0 06             	and    $0x6,%eax
80102932:	83 f8 02             	cmp    $0x2,%eax
80102935:	75 dd                	jne    80102914 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80102937:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010293e:	e8 7a 23 00 00       	call   80104cbd <release>
}
80102943:	c9                   	leave  
80102944:	c3                   	ret    
80102945:	00 00                	add    %al,(%eax)
	...

80102948 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102948:	55                   	push   %ebp
80102949:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
8010294b:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
80102950:	8b 55 08             	mov    0x8(%ebp),%edx
80102953:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102955:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
8010295a:	8b 40 10             	mov    0x10(%eax),%eax
}
8010295d:	5d                   	pop    %ebp
8010295e:	c3                   	ret    

8010295f <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
8010295f:	55                   	push   %ebp
80102960:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102962:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
80102967:	8b 55 08             	mov    0x8(%ebp),%edx
8010296a:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
8010296c:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
80102971:	8b 55 0c             	mov    0xc(%ebp),%edx
80102974:	89 50 10             	mov    %edx,0x10(%eax)
}
80102977:	5d                   	pop    %ebp
80102978:	c3                   	ret    

80102979 <ioapicinit>:

void
ioapicinit(void)
{
80102979:	55                   	push   %ebp
8010297a:	89 e5                	mov    %esp,%ebp
8010297c:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
8010297f:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
80102984:	85 c0                	test   %eax,%eax
80102986:	0f 84 9f 00 00 00    	je     80102a2b <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
8010298c:	c7 05 34 fd 10 80 00 	movl   $0xfec00000,0x8010fd34
80102993:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102996:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010299d:	e8 a6 ff ff ff       	call   80102948 <ioapicread>
801029a2:	c1 e8 10             	shr    $0x10,%eax
801029a5:	25 ff 00 00 00       	and    $0xff,%eax
801029aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
801029ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801029b4:	e8 8f ff ff ff       	call   80102948 <ioapicread>
801029b9:	c1 e8 18             	shr    $0x18,%eax
801029bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
801029bf:	0f b6 05 00 fe 10 80 	movzbl 0x8010fe00,%eax
801029c6:	0f b6 c0             	movzbl %al,%eax
801029c9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801029cc:	74 0c                	je     801029da <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
801029ce:	c7 04 24 30 84 10 80 	movl   $0x80108430,(%esp)
801029d5:	e8 c7 d9 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801029da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801029e1:	eb 3e                	jmp    80102a21 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
801029e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e6:	83 c0 20             	add    $0x20,%eax
801029e9:	0d 00 00 01 00       	or     $0x10000,%eax
801029ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
801029f1:	83 c2 08             	add    $0x8,%edx
801029f4:	01 d2                	add    %edx,%edx
801029f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801029fa:	89 14 24             	mov    %edx,(%esp)
801029fd:	e8 5d ff ff ff       	call   8010295f <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a05:	83 c0 08             	add    $0x8,%eax
80102a08:	01 c0                	add    %eax,%eax
80102a0a:	83 c0 01             	add    $0x1,%eax
80102a0d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a14:	00 
80102a15:	89 04 24             	mov    %eax,(%esp)
80102a18:	e8 42 ff ff ff       	call   8010295f <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102a1d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102a21:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a24:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102a27:	7e ba                	jle    801029e3 <ioapicinit+0x6a>
80102a29:	eb 01                	jmp    80102a2c <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80102a2b:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102a2c:	c9                   	leave  
80102a2d:	c3                   	ret    

80102a2e <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102a2e:	55                   	push   %ebp
80102a2f:	89 e5                	mov    %esp,%ebp
80102a31:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102a34:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
80102a39:	85 c0                	test   %eax,%eax
80102a3b:	74 39                	je     80102a76 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102a3d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a40:	83 c0 20             	add    $0x20,%eax
80102a43:	8b 55 08             	mov    0x8(%ebp),%edx
80102a46:	83 c2 08             	add    $0x8,%edx
80102a49:	01 d2                	add    %edx,%edx
80102a4b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a4f:	89 14 24             	mov    %edx,(%esp)
80102a52:	e8 08 ff ff ff       	call   8010295f <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102a57:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a5a:	c1 e0 18             	shl    $0x18,%eax
80102a5d:	8b 55 08             	mov    0x8(%ebp),%edx
80102a60:	83 c2 08             	add    $0x8,%edx
80102a63:	01 d2                	add    %edx,%edx
80102a65:	83 c2 01             	add    $0x1,%edx
80102a68:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a6c:	89 14 24             	mov    %edx,(%esp)
80102a6f:	e8 eb fe ff ff       	call   8010295f <ioapicwrite>
80102a74:	eb 01                	jmp    80102a77 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80102a76:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80102a77:	c9                   	leave  
80102a78:	c3                   	ret    
80102a79:	00 00                	add    %al,(%eax)
	...

80102a7c <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102a7c:	55                   	push   %ebp
80102a7d:	89 e5                	mov    %esp,%ebp
80102a7f:	8b 45 08             	mov    0x8(%ebp),%eax
80102a82:	05 00 00 00 80       	add    $0x80000000,%eax
80102a87:	5d                   	pop    %ebp
80102a88:	c3                   	ret    

80102a89 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102a89:	55                   	push   %ebp
80102a8a:	89 e5                	mov    %esp,%ebp
80102a8c:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102a8f:	c7 44 24 04 62 84 10 	movl   $0x80108462,0x4(%esp)
80102a96:	80 
80102a97:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102a9e:	e8 97 21 00 00       	call   80104c3a <initlock>
  kmem.use_lock = 0;
80102aa3:	c7 05 74 fd 10 80 00 	movl   $0x0,0x8010fd74
80102aaa:	00 00 00 
  freerange(vstart, vend);
80102aad:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ab0:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ab4:	8b 45 08             	mov    0x8(%ebp),%eax
80102ab7:	89 04 24             	mov    %eax,(%esp)
80102aba:	e8 26 00 00 00       	call   80102ae5 <freerange>
}
80102abf:	c9                   	leave  
80102ac0:	c3                   	ret    

80102ac1 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102ac1:	55                   	push   %ebp
80102ac2:	89 e5                	mov    %esp,%ebp
80102ac4:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102ac7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102aca:	89 44 24 04          	mov    %eax,0x4(%esp)
80102ace:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad1:	89 04 24             	mov    %eax,(%esp)
80102ad4:	e8 0c 00 00 00       	call   80102ae5 <freerange>
  kmem.use_lock = 1;
80102ad9:	c7 05 74 fd 10 80 01 	movl   $0x1,0x8010fd74
80102ae0:	00 00 00 
}
80102ae3:	c9                   	leave  
80102ae4:	c3                   	ret    

80102ae5 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102ae5:	55                   	push   %ebp
80102ae6:	89 e5                	mov    %esp,%ebp
80102ae8:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102aeb:	8b 45 08             	mov    0x8(%ebp),%eax
80102aee:	05 ff 0f 00 00       	add    $0xfff,%eax
80102af3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102af8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102afb:	eb 12                	jmp    80102b0f <freerange+0x2a>
    kfree(p);
80102afd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b00:	89 04 24             	mov    %eax,(%esp)
80102b03:	e8 16 00 00 00       	call   80102b1e <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102b08:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102b0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b12:	05 00 10 00 00       	add    $0x1000,%eax
80102b17:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102b1a:	76 e1                	jbe    80102afd <freerange+0x18>
    kfree(p);
}
80102b1c:	c9                   	leave  
80102b1d:	c3                   	ret    

80102b1e <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102b1e:	55                   	push   %ebp
80102b1f:	89 e5                	mov    %esp,%ebp
80102b21:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102b24:	8b 45 08             	mov    0x8(%ebp),%eax
80102b27:	25 ff 0f 00 00       	and    $0xfff,%eax
80102b2c:	85 c0                	test   %eax,%eax
80102b2e:	75 1b                	jne    80102b4b <kfree+0x2d>
80102b30:	81 7d 08 fc 2b 11 80 	cmpl   $0x80112bfc,0x8(%ebp)
80102b37:	72 12                	jb     80102b4b <kfree+0x2d>
80102b39:	8b 45 08             	mov    0x8(%ebp),%eax
80102b3c:	89 04 24             	mov    %eax,(%esp)
80102b3f:	e8 38 ff ff ff       	call   80102a7c <v2p>
80102b44:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102b49:	76 0c                	jbe    80102b57 <kfree+0x39>
    panic("kfree");
80102b4b:	c7 04 24 67 84 10 80 	movl   $0x80108467,(%esp)
80102b52:	e8 e6 d9 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102b57:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102b5e:	00 
80102b5f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102b66:	00 
80102b67:	8b 45 08             	mov    0x8(%ebp),%eax
80102b6a:	89 04 24             	mov    %eax,(%esp)
80102b6d:	e8 38 23 00 00       	call   80104eaa <memset>

  if(kmem.use_lock)
80102b72:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102b77:	85 c0                	test   %eax,%eax
80102b79:	74 0c                	je     80102b87 <kfree+0x69>
    acquire(&kmem.lock);
80102b7b:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102b82:	e8 d4 20 00 00       	call   80104c5b <acquire>
  r = (struct run*)v;
80102b87:	8b 45 08             	mov    0x8(%ebp),%eax
80102b8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102b8d:	8b 15 78 fd 10 80    	mov    0x8010fd78,%edx
80102b93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b96:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102b98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b9b:	a3 78 fd 10 80       	mov    %eax,0x8010fd78
  if(kmem.use_lock)
80102ba0:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102ba5:	85 c0                	test   %eax,%eax
80102ba7:	74 0c                	je     80102bb5 <kfree+0x97>
    release(&kmem.lock);
80102ba9:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102bb0:	e8 08 21 00 00       	call   80104cbd <release>
}
80102bb5:	c9                   	leave  
80102bb6:	c3                   	ret    

80102bb7 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102bb7:	55                   	push   %ebp
80102bb8:	89 e5                	mov    %esp,%ebp
80102bba:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102bbd:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102bc2:	85 c0                	test   %eax,%eax
80102bc4:	74 0c                	je     80102bd2 <kalloc+0x1b>
    acquire(&kmem.lock);
80102bc6:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102bcd:	e8 89 20 00 00       	call   80104c5b <acquire>
  r = kmem.freelist;
80102bd2:	a1 78 fd 10 80       	mov    0x8010fd78,%eax
80102bd7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102bda:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102bde:	74 0a                	je     80102bea <kalloc+0x33>
    kmem.freelist = r->next;
80102be0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102be3:	8b 00                	mov    (%eax),%eax
80102be5:	a3 78 fd 10 80       	mov    %eax,0x8010fd78
  if(kmem.use_lock)
80102bea:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102bef:	85 c0                	test   %eax,%eax
80102bf1:	74 0c                	je     80102bff <kalloc+0x48>
    release(&kmem.lock);
80102bf3:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102bfa:	e8 be 20 00 00       	call   80104cbd <release>
  return (char*)r;
80102bff:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102c02:	c9                   	leave  
80102c03:	c3                   	ret    

80102c04 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102c04:	55                   	push   %ebp
80102c05:	89 e5                	mov    %esp,%ebp
80102c07:	53                   	push   %ebx
80102c08:	83 ec 14             	sub    $0x14,%esp
80102c0b:	8b 45 08             	mov    0x8(%ebp),%eax
80102c0e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102c12:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102c16:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102c1a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102c1e:	ec                   	in     (%dx),%al
80102c1f:	89 c3                	mov    %eax,%ebx
80102c21:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102c24:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102c28:	83 c4 14             	add    $0x14,%esp
80102c2b:	5b                   	pop    %ebx
80102c2c:	5d                   	pop    %ebp
80102c2d:	c3                   	ret    

80102c2e <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102c2e:	55                   	push   %ebp
80102c2f:	89 e5                	mov    %esp,%ebp
80102c31:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102c34:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102c3b:	e8 c4 ff ff ff       	call   80102c04 <inb>
80102c40:	0f b6 c0             	movzbl %al,%eax
80102c43:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102c46:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c49:	83 e0 01             	and    $0x1,%eax
80102c4c:	85 c0                	test   %eax,%eax
80102c4e:	75 0a                	jne    80102c5a <kbdgetc+0x2c>
    return -1;
80102c50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102c55:	e9 23 01 00 00       	jmp    80102d7d <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102c5a:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102c61:	e8 9e ff ff ff       	call   80102c04 <inb>
80102c66:	0f b6 c0             	movzbl %al,%eax
80102c69:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102c6c:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102c73:	75 17                	jne    80102c8c <kbdgetc+0x5e>
    shift |= E0ESC;
80102c75:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c7a:	83 c8 40             	or     $0x40,%eax
80102c7d:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c82:	b8 00 00 00 00       	mov    $0x0,%eax
80102c87:	e9 f1 00 00 00       	jmp    80102d7d <kbdgetc+0x14f>
  } else if(data & 0x80){
80102c8c:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c8f:	25 80 00 00 00       	and    $0x80,%eax
80102c94:	85 c0                	test   %eax,%eax
80102c96:	74 45                	je     80102cdd <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102c98:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c9d:	83 e0 40             	and    $0x40,%eax
80102ca0:	85 c0                	test   %eax,%eax
80102ca2:	75 08                	jne    80102cac <kbdgetc+0x7e>
80102ca4:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102ca7:	83 e0 7f             	and    $0x7f,%eax
80102caa:	eb 03                	jmp    80102caf <kbdgetc+0x81>
80102cac:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102caf:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102cb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cb5:	05 20 90 10 80       	add    $0x80109020,%eax
80102cba:	0f b6 00             	movzbl (%eax),%eax
80102cbd:	83 c8 40             	or     $0x40,%eax
80102cc0:	0f b6 c0             	movzbl %al,%eax
80102cc3:	f7 d0                	not    %eax
80102cc5:	89 c2                	mov    %eax,%edx
80102cc7:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ccc:	21 d0                	and    %edx,%eax
80102cce:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102cd3:	b8 00 00 00 00       	mov    $0x0,%eax
80102cd8:	e9 a0 00 00 00       	jmp    80102d7d <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102cdd:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ce2:	83 e0 40             	and    $0x40,%eax
80102ce5:	85 c0                	test   %eax,%eax
80102ce7:	74 14                	je     80102cfd <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102ce9:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102cf0:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cf5:	83 e0 bf             	and    $0xffffffbf,%eax
80102cf8:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102cfd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d00:	05 20 90 10 80       	add    $0x80109020,%eax
80102d05:	0f b6 00             	movzbl (%eax),%eax
80102d08:	0f b6 d0             	movzbl %al,%edx
80102d0b:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d10:	09 d0                	or     %edx,%eax
80102d12:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102d17:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d1a:	05 20 91 10 80       	add    $0x80109120,%eax
80102d1f:	0f b6 00             	movzbl (%eax),%eax
80102d22:	0f b6 d0             	movzbl %al,%edx
80102d25:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d2a:	31 d0                	xor    %edx,%eax
80102d2c:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102d31:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d36:	83 e0 03             	and    $0x3,%eax
80102d39:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102d40:	03 45 fc             	add    -0x4(%ebp),%eax
80102d43:	0f b6 00             	movzbl (%eax),%eax
80102d46:	0f b6 c0             	movzbl %al,%eax
80102d49:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102d4c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102d51:	83 e0 08             	and    $0x8,%eax
80102d54:	85 c0                	test   %eax,%eax
80102d56:	74 22                	je     80102d7a <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102d58:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102d5c:	76 0c                	jbe    80102d6a <kbdgetc+0x13c>
80102d5e:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102d62:	77 06                	ja     80102d6a <kbdgetc+0x13c>
      c += 'A' - 'a';
80102d64:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102d68:	eb 10                	jmp    80102d7a <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102d6a:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102d6e:	76 0a                	jbe    80102d7a <kbdgetc+0x14c>
80102d70:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102d74:	77 04                	ja     80102d7a <kbdgetc+0x14c>
      c += 'a' - 'A';
80102d76:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102d7a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d7d:	c9                   	leave  
80102d7e:	c3                   	ret    

80102d7f <kbdintr>:

void
kbdintr(void)
{
80102d7f:	55                   	push   %ebp
80102d80:	89 e5                	mov    %esp,%ebp
80102d82:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102d85:	c7 04 24 2e 2c 10 80 	movl   $0x80102c2e,(%esp)
80102d8c:	e8 1c da ff ff       	call   801007ad <consoleintr>
}
80102d91:	c9                   	leave  
80102d92:	c3                   	ret    
	...

80102d94 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102d94:	55                   	push   %ebp
80102d95:	89 e5                	mov    %esp,%ebp
80102d97:	83 ec 08             	sub    $0x8,%esp
80102d9a:	8b 55 08             	mov    0x8(%ebp),%edx
80102d9d:	8b 45 0c             	mov    0xc(%ebp),%eax
80102da0:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102da4:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102da7:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102dab:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102daf:	ee                   	out    %al,(%dx)
}
80102db0:	c9                   	leave  
80102db1:	c3                   	ret    

80102db2 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102db2:	55                   	push   %ebp
80102db3:	89 e5                	mov    %esp,%ebp
80102db5:	53                   	push   %ebx
80102db6:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102db9:	9c                   	pushf  
80102dba:	5b                   	pop    %ebx
80102dbb:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102dbe:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102dc1:	83 c4 10             	add    $0x10,%esp
80102dc4:	5b                   	pop    %ebx
80102dc5:	5d                   	pop    %ebp
80102dc6:	c3                   	ret    

80102dc7 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102dc7:	55                   	push   %ebp
80102dc8:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102dca:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102dcf:	8b 55 08             	mov    0x8(%ebp),%edx
80102dd2:	c1 e2 02             	shl    $0x2,%edx
80102dd5:	01 c2                	add    %eax,%edx
80102dd7:	8b 45 0c             	mov    0xc(%ebp),%eax
80102dda:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102ddc:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102de1:	83 c0 20             	add    $0x20,%eax
80102de4:	8b 00                	mov    (%eax),%eax
}
80102de6:	5d                   	pop    %ebp
80102de7:	c3                   	ret    

80102de8 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102de8:	55                   	push   %ebp
80102de9:	89 e5                	mov    %esp,%ebp
80102deb:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102dee:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102df3:	85 c0                	test   %eax,%eax
80102df5:	0f 84 47 01 00 00    	je     80102f42 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102dfb:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102e02:	00 
80102e03:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102e0a:	e8 b8 ff ff ff       	call   80102dc7 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102e0f:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102e16:	00 
80102e17:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102e1e:	e8 a4 ff ff ff       	call   80102dc7 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102e23:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102e2a:	00 
80102e2b:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102e32:	e8 90 ff ff ff       	call   80102dc7 <lapicw>
  lapicw(TICR, 10000000); 
80102e37:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102e3e:	00 
80102e3f:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102e46:	e8 7c ff ff ff       	call   80102dc7 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102e4b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e52:	00 
80102e53:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102e5a:	e8 68 ff ff ff       	call   80102dc7 <lapicw>
  lapicw(LINT1, MASKED);
80102e5f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e66:	00 
80102e67:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102e6e:	e8 54 ff ff ff       	call   80102dc7 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102e73:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102e78:	83 c0 30             	add    $0x30,%eax
80102e7b:	8b 00                	mov    (%eax),%eax
80102e7d:	c1 e8 10             	shr    $0x10,%eax
80102e80:	25 ff 00 00 00       	and    $0xff,%eax
80102e85:	83 f8 03             	cmp    $0x3,%eax
80102e88:	76 14                	jbe    80102e9e <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102e8a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e91:	00 
80102e92:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102e99:	e8 29 ff ff ff       	call   80102dc7 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102e9e:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102ea5:	00 
80102ea6:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102ead:	e8 15 ff ff ff       	call   80102dc7 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102eb2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102eb9:	00 
80102eba:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102ec1:	e8 01 ff ff ff       	call   80102dc7 <lapicw>
  lapicw(ESR, 0);
80102ec6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ecd:	00 
80102ece:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102ed5:	e8 ed fe ff ff       	call   80102dc7 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102eda:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ee1:	00 
80102ee2:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102ee9:	e8 d9 fe ff ff       	call   80102dc7 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102eee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ef5:	00 
80102ef6:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102efd:	e8 c5 fe ff ff       	call   80102dc7 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102f02:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102f09:	00 
80102f0a:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102f11:	e8 b1 fe ff ff       	call   80102dc7 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102f16:	90                   	nop
80102f17:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102f1c:	05 00 03 00 00       	add    $0x300,%eax
80102f21:	8b 00                	mov    (%eax),%eax
80102f23:	25 00 10 00 00       	and    $0x1000,%eax
80102f28:	85 c0                	test   %eax,%eax
80102f2a:	75 eb                	jne    80102f17 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102f2c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f33:	00 
80102f34:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102f3b:	e8 87 fe ff ff       	call   80102dc7 <lapicw>
80102f40:	eb 01                	jmp    80102f43 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80102f42:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102f43:	c9                   	leave  
80102f44:	c3                   	ret    

80102f45 <cpunum>:

int
cpunum(void)
{
80102f45:	55                   	push   %ebp
80102f46:	89 e5                	mov    %esp,%ebp
80102f48:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102f4b:	e8 62 fe ff ff       	call   80102db2 <readeflags>
80102f50:	25 00 02 00 00       	and    $0x200,%eax
80102f55:	85 c0                	test   %eax,%eax
80102f57:	74 29                	je     80102f82 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102f59:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102f5e:	85 c0                	test   %eax,%eax
80102f60:	0f 94 c2             	sete   %dl
80102f63:	83 c0 01             	add    $0x1,%eax
80102f66:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102f6b:	84 d2                	test   %dl,%dl
80102f6d:	74 13                	je     80102f82 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102f6f:	8b 45 04             	mov    0x4(%ebp),%eax
80102f72:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f76:	c7 04 24 70 84 10 80 	movl   $0x80108470,(%esp)
80102f7d:	e8 1f d4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102f82:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102f87:	85 c0                	test   %eax,%eax
80102f89:	74 0f                	je     80102f9a <cpunum+0x55>
    return lapic[ID]>>24;
80102f8b:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102f90:	83 c0 20             	add    $0x20,%eax
80102f93:	8b 00                	mov    (%eax),%eax
80102f95:	c1 e8 18             	shr    $0x18,%eax
80102f98:	eb 05                	jmp    80102f9f <cpunum+0x5a>
  return 0;
80102f9a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102f9f:	c9                   	leave  
80102fa0:	c3                   	ret    

80102fa1 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102fa1:	55                   	push   %ebp
80102fa2:	89 e5                	mov    %esp,%ebp
80102fa4:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102fa7:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102fac:	85 c0                	test   %eax,%eax
80102fae:	74 14                	je     80102fc4 <lapiceoi+0x23>
    lapicw(EOI, 0);
80102fb0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fb7:	00 
80102fb8:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102fbf:	e8 03 fe ff ff       	call   80102dc7 <lapicw>
}
80102fc4:	c9                   	leave  
80102fc5:	c3                   	ret    

80102fc6 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102fc6:	55                   	push   %ebp
80102fc7:	89 e5                	mov    %esp,%ebp
}
80102fc9:	5d                   	pop    %ebp
80102fca:	c3                   	ret    

80102fcb <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102fcb:	55                   	push   %ebp
80102fcc:	89 e5                	mov    %esp,%ebp
80102fce:	83 ec 1c             	sub    $0x1c,%esp
80102fd1:	8b 45 08             	mov    0x8(%ebp),%eax
80102fd4:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80102fd7:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102fde:	00 
80102fdf:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102fe6:	e8 a9 fd ff ff       	call   80102d94 <outb>
  outb(IO_RTC+1, 0x0A);
80102feb:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102ff2:	00 
80102ff3:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102ffa:	e8 95 fd ff ff       	call   80102d94 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102fff:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103006:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103009:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
8010300e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103011:	8d 50 02             	lea    0x2(%eax),%edx
80103014:	8b 45 0c             	mov    0xc(%ebp),%eax
80103017:	c1 e8 04             	shr    $0x4,%eax
8010301a:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
8010301d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103021:	c1 e0 18             	shl    $0x18,%eax
80103024:	89 44 24 04          	mov    %eax,0x4(%esp)
80103028:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010302f:	e8 93 fd ff ff       	call   80102dc7 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103034:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
8010303b:	00 
8010303c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103043:	e8 7f fd ff ff       	call   80102dc7 <lapicw>
  microdelay(200);
80103048:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010304f:	e8 72 ff ff ff       	call   80102fc6 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103054:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010305b:	00 
8010305c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103063:	e8 5f fd ff ff       	call   80102dc7 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103068:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010306f:	e8 52 ff ff ff       	call   80102fc6 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103074:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010307b:	eb 40                	jmp    801030bd <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
8010307d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103081:	c1 e0 18             	shl    $0x18,%eax
80103084:	89 44 24 04          	mov    %eax,0x4(%esp)
80103088:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010308f:	e8 33 fd ff ff       	call   80102dc7 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103094:	8b 45 0c             	mov    0xc(%ebp),%eax
80103097:	c1 e8 0c             	shr    $0xc,%eax
8010309a:	80 cc 06             	or     $0x6,%ah
8010309d:	89 44 24 04          	mov    %eax,0x4(%esp)
801030a1:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801030a8:	e8 1a fd ff ff       	call   80102dc7 <lapicw>
    microdelay(200);
801030ad:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801030b4:	e8 0d ff ff ff       	call   80102fc6 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030b9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801030bd:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
801030c1:	7e ba                	jle    8010307d <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
801030c3:	c9                   	leave  
801030c4:	c3                   	ret    
801030c5:	00 00                	add    %al,(%eax)
	...

801030c8 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
801030c8:	55                   	push   %ebp
801030c9:	89 e5                	mov    %esp,%ebp
801030cb:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
801030ce:	c7 44 24 04 9c 84 10 	movl   $0x8010849c,0x4(%esp)
801030d5:	80 
801030d6:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
801030dd:	e8 58 1b 00 00       	call   80104c3a <initlock>
  readsb(ROOTDEV, &sb);
801030e2:	8d 45 e8             	lea    -0x18(%ebp),%eax
801030e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801030e9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801030f0:	e8 af e2 ff ff       	call   801013a4 <readsb>
  log.start = sb.size - sb.nlog;
801030f5:	8b 55 e8             	mov    -0x18(%ebp),%edx
801030f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030fb:	89 d1                	mov    %edx,%ecx
801030fd:	29 c1                	sub    %eax,%ecx
801030ff:	89 c8                	mov    %ecx,%eax
80103101:	a3 b4 fd 10 80       	mov    %eax,0x8010fdb4
  log.size = sb.nlog;
80103106:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103109:	a3 b8 fd 10 80       	mov    %eax,0x8010fdb8
  log.dev = ROOTDEV;
8010310e:	c7 05 c0 fd 10 80 01 	movl   $0x1,0x8010fdc0
80103115:	00 00 00 
  recover_from_log();
80103118:	e8 97 01 00 00       	call   801032b4 <recover_from_log>
}
8010311d:	c9                   	leave  
8010311e:	c3                   	ret    

8010311f <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
8010311f:	55                   	push   %ebp
80103120:	89 e5                	mov    %esp,%ebp
80103122:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103125:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010312c:	e9 89 00 00 00       	jmp    801031ba <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103131:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
80103136:	03 45 f4             	add    -0xc(%ebp),%eax
80103139:	83 c0 01             	add    $0x1,%eax
8010313c:	89 c2                	mov    %eax,%edx
8010313e:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
80103143:	89 54 24 04          	mov    %edx,0x4(%esp)
80103147:	89 04 24             	mov    %eax,(%esp)
8010314a:	e8 57 d0 ff ff       	call   801001a6 <bread>
8010314f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103152:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103155:	83 c0 10             	add    $0x10,%eax
80103158:	8b 04 85 88 fd 10 80 	mov    -0x7fef0278(,%eax,4),%eax
8010315f:	89 c2                	mov    %eax,%edx
80103161:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
80103166:	89 54 24 04          	mov    %edx,0x4(%esp)
8010316a:	89 04 24             	mov    %eax,(%esp)
8010316d:	e8 34 d0 ff ff       	call   801001a6 <bread>
80103172:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103175:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103178:	8d 50 18             	lea    0x18(%eax),%edx
8010317b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010317e:	83 c0 18             	add    $0x18,%eax
80103181:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103188:	00 
80103189:	89 54 24 04          	mov    %edx,0x4(%esp)
8010318d:	89 04 24             	mov    %eax,(%esp)
80103190:	e8 e8 1d 00 00       	call   80104f7d <memmove>
    bwrite(dbuf);  // write dst to disk
80103195:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103198:	89 04 24             	mov    %eax,(%esp)
8010319b:	e8 3d d0 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
801031a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031a3:	89 04 24             	mov    %eax,(%esp)
801031a6:	e8 6c d0 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
801031ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031ae:	89 04 24             	mov    %eax,(%esp)
801031b1:	e8 61 d0 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801031b6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801031ba:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
801031bf:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801031c2:	0f 8f 69 ff ff ff    	jg     80103131 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
801031c8:	c9                   	leave  
801031c9:	c3                   	ret    

801031ca <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
801031ca:	55                   	push   %ebp
801031cb:	89 e5                	mov    %esp,%ebp
801031cd:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801031d0:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
801031d5:	89 c2                	mov    %eax,%edx
801031d7:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
801031dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801031e0:	89 04 24             	mov    %eax,(%esp)
801031e3:	e8 be cf ff ff       	call   801001a6 <bread>
801031e8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801031eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031ee:	83 c0 18             	add    $0x18,%eax
801031f1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801031f4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031f7:	8b 00                	mov    (%eax),%eax
801031f9:	a3 c4 fd 10 80       	mov    %eax,0x8010fdc4
  for (i = 0; i < log.lh.n; i++) {
801031fe:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103205:	eb 1b                	jmp    80103222 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
80103207:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010320a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010320d:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103211:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103214:	83 c2 10             	add    $0x10,%edx
80103217:	89 04 95 88 fd 10 80 	mov    %eax,-0x7fef0278(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
8010321e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103222:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103227:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010322a:	7f db                	jg     80103207 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
8010322c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010322f:	89 04 24             	mov    %eax,(%esp)
80103232:	e8 e0 cf ff ff       	call   80100217 <brelse>
}
80103237:	c9                   	leave  
80103238:	c3                   	ret    

80103239 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103239:	55                   	push   %ebp
8010323a:	89 e5                	mov    %esp,%ebp
8010323c:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010323f:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
80103244:	89 c2                	mov    %eax,%edx
80103246:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
8010324b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010324f:	89 04 24             	mov    %eax,(%esp)
80103252:	e8 4f cf ff ff       	call   801001a6 <bread>
80103257:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
8010325a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010325d:	83 c0 18             	add    $0x18,%eax
80103260:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103263:	8b 15 c4 fd 10 80    	mov    0x8010fdc4,%edx
80103269:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010326c:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010326e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103275:	eb 1b                	jmp    80103292 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103277:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010327a:	83 c0 10             	add    $0x10,%eax
8010327d:	8b 0c 85 88 fd 10 80 	mov    -0x7fef0278(,%eax,4),%ecx
80103284:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103287:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010328a:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010328e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103292:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103297:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010329a:	7f db                	jg     80103277 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
8010329c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010329f:	89 04 24             	mov    %eax,(%esp)
801032a2:	e8 36 cf ff ff       	call   801001dd <bwrite>
  brelse(buf);
801032a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801032aa:	89 04 24             	mov    %eax,(%esp)
801032ad:	e8 65 cf ff ff       	call   80100217 <brelse>
}
801032b2:	c9                   	leave  
801032b3:	c3                   	ret    

801032b4 <recover_from_log>:

static void
recover_from_log(void)
{
801032b4:	55                   	push   %ebp
801032b5:	89 e5                	mov    %esp,%ebp
801032b7:	83 ec 08             	sub    $0x8,%esp
  read_head();      
801032ba:	e8 0b ff ff ff       	call   801031ca <read_head>
  install_trans(); // if committed, copy from log to disk
801032bf:	e8 5b fe ff ff       	call   8010311f <install_trans>
  log.lh.n = 0;
801032c4:	c7 05 c4 fd 10 80 00 	movl   $0x0,0x8010fdc4
801032cb:	00 00 00 
  write_head(); // clear the log
801032ce:	e8 66 ff ff ff       	call   80103239 <write_head>
}
801032d3:	c9                   	leave  
801032d4:	c3                   	ret    

801032d5 <begin_trans>:

void
begin_trans(void)
{
801032d5:	55                   	push   %ebp
801032d6:	89 e5                	mov    %esp,%ebp
801032d8:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
801032db:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
801032e2:	e8 74 19 00 00       	call   80104c5b <acquire>
  while (log.busy) {
801032e7:	eb 14                	jmp    801032fd <begin_trans+0x28>
    sleep(&log, &log.lock);
801032e9:	c7 44 24 04 80 fd 10 	movl   $0x8010fd80,0x4(%esp)
801032f0:	80 
801032f1:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
801032f8:	e8 80 16 00 00       	call   8010497d <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801032fd:	a1 bc fd 10 80       	mov    0x8010fdbc,%eax
80103302:	85 c0                	test   %eax,%eax
80103304:	75 e3                	jne    801032e9 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
80103306:	c7 05 bc fd 10 80 01 	movl   $0x1,0x8010fdbc
8010330d:	00 00 00 
  release(&log.lock);
80103310:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
80103317:	e8 a1 19 00 00       	call   80104cbd <release>
}
8010331c:	c9                   	leave  
8010331d:	c3                   	ret    

8010331e <commit_trans>:

void
commit_trans(void)
{
8010331e:	55                   	push   %ebp
8010331f:	89 e5                	mov    %esp,%ebp
80103321:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
80103324:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103329:	85 c0                	test   %eax,%eax
8010332b:	7e 19                	jle    80103346 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
8010332d:	e8 07 ff ff ff       	call   80103239 <write_head>
    install_trans(); // Now install writes to home locations
80103332:	e8 e8 fd ff ff       	call   8010311f <install_trans>
    log.lh.n = 0; 
80103337:	c7 05 c4 fd 10 80 00 	movl   $0x0,0x8010fdc4
8010333e:	00 00 00 
    write_head();    // Erase the transaction from the log
80103341:	e8 f3 fe ff ff       	call   80103239 <write_head>
  }
  
  acquire(&log.lock);
80103346:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
8010334d:	e8 09 19 00 00       	call   80104c5b <acquire>
  log.busy = 0;
80103352:	c7 05 bc fd 10 80 00 	movl   $0x0,0x8010fdbc
80103359:	00 00 00 
  wakeup(&log);
8010335c:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
80103363:	e8 ee 16 00 00       	call   80104a56 <wakeup>
  release(&log.lock);
80103368:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
8010336f:	e8 49 19 00 00       	call   80104cbd <release>
}
80103374:	c9                   	leave  
80103375:	c3                   	ret    

80103376 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103376:	55                   	push   %ebp
80103377:	89 e5                	mov    %esp,%ebp
80103379:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010337c:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103381:	83 f8 09             	cmp    $0x9,%eax
80103384:	7f 12                	jg     80103398 <log_write+0x22>
80103386:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
8010338b:	8b 15 b8 fd 10 80    	mov    0x8010fdb8,%edx
80103391:	83 ea 01             	sub    $0x1,%edx
80103394:	39 d0                	cmp    %edx,%eax
80103396:	7c 0c                	jl     801033a4 <log_write+0x2e>
    panic("too big a transaction");
80103398:	c7 04 24 a0 84 10 80 	movl   $0x801084a0,(%esp)
8010339f:	e8 99 d1 ff ff       	call   8010053d <panic>
  if (!log.busy)
801033a4:	a1 bc fd 10 80       	mov    0x8010fdbc,%eax
801033a9:	85 c0                	test   %eax,%eax
801033ab:	75 0c                	jne    801033b9 <log_write+0x43>
    panic("write outside of trans");
801033ad:	c7 04 24 b6 84 10 80 	movl   $0x801084b6,(%esp)
801033b4:	e8 84 d1 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
801033b9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801033c0:	eb 1d                	jmp    801033df <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
801033c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801033c5:	83 c0 10             	add    $0x10,%eax
801033c8:	8b 04 85 88 fd 10 80 	mov    -0x7fef0278(,%eax,4),%eax
801033cf:	89 c2                	mov    %eax,%edx
801033d1:	8b 45 08             	mov    0x8(%ebp),%eax
801033d4:	8b 40 08             	mov    0x8(%eax),%eax
801033d7:	39 c2                	cmp    %eax,%edx
801033d9:	74 10                	je     801033eb <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
801033db:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801033df:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
801033e4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033e7:	7f d9                	jg     801033c2 <log_write+0x4c>
801033e9:	eb 01                	jmp    801033ec <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
801033eb:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801033ec:	8b 45 08             	mov    0x8(%ebp),%eax
801033ef:	8b 40 08             	mov    0x8(%eax),%eax
801033f2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801033f5:	83 c2 10             	add    $0x10,%edx
801033f8:	89 04 95 88 fd 10 80 	mov    %eax,-0x7fef0278(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801033ff:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
80103404:	03 45 f4             	add    -0xc(%ebp),%eax
80103407:	83 c0 01             	add    $0x1,%eax
8010340a:	89 c2                	mov    %eax,%edx
8010340c:	8b 45 08             	mov    0x8(%ebp),%eax
8010340f:	8b 40 04             	mov    0x4(%eax),%eax
80103412:	89 54 24 04          	mov    %edx,0x4(%esp)
80103416:	89 04 24             	mov    %eax,(%esp)
80103419:	e8 88 cd ff ff       	call   801001a6 <bread>
8010341e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
80103421:	8b 45 08             	mov    0x8(%ebp),%eax
80103424:	8d 50 18             	lea    0x18(%eax),%edx
80103427:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010342a:	83 c0 18             	add    $0x18,%eax
8010342d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103434:	00 
80103435:	89 54 24 04          	mov    %edx,0x4(%esp)
80103439:	89 04 24             	mov    %eax,(%esp)
8010343c:	e8 3c 1b 00 00       	call   80104f7d <memmove>
  bwrite(lbuf);
80103441:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103444:	89 04 24             	mov    %eax,(%esp)
80103447:	e8 91 cd ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
8010344c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010344f:	89 04 24             	mov    %eax,(%esp)
80103452:	e8 c0 cd ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103457:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
8010345c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010345f:	75 0d                	jne    8010346e <log_write+0xf8>
    log.lh.n++;
80103461:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103466:	83 c0 01             	add    $0x1,%eax
80103469:	a3 c4 fd 10 80       	mov    %eax,0x8010fdc4
  b->flags |= B_DIRTY; // XXX prevent eviction
8010346e:	8b 45 08             	mov    0x8(%ebp),%eax
80103471:	8b 00                	mov    (%eax),%eax
80103473:	89 c2                	mov    %eax,%edx
80103475:	83 ca 04             	or     $0x4,%edx
80103478:	8b 45 08             	mov    0x8(%ebp),%eax
8010347b:	89 10                	mov    %edx,(%eax)
}
8010347d:	c9                   	leave  
8010347e:	c3                   	ret    
	...

80103480 <v2p>:
80103480:	55                   	push   %ebp
80103481:	89 e5                	mov    %esp,%ebp
80103483:	8b 45 08             	mov    0x8(%ebp),%eax
80103486:	05 00 00 00 80       	add    $0x80000000,%eax
8010348b:	5d                   	pop    %ebp
8010348c:	c3                   	ret    

8010348d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
8010348d:	55                   	push   %ebp
8010348e:	89 e5                	mov    %esp,%ebp
80103490:	8b 45 08             	mov    0x8(%ebp),%eax
80103493:	05 00 00 00 80       	add    $0x80000000,%eax
80103498:	5d                   	pop    %ebp
80103499:	c3                   	ret    

8010349a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
8010349a:	55                   	push   %ebp
8010349b:	89 e5                	mov    %esp,%ebp
8010349d:	53                   	push   %ebx
8010349e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801034a1:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801034a4:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801034a7:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801034aa:	89 c3                	mov    %eax,%ebx
801034ac:	89 d8                	mov    %ebx,%eax
801034ae:	f0 87 02             	lock xchg %eax,(%edx)
801034b1:	89 c3                	mov    %eax,%ebx
801034b3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801034b6:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801034b9:	83 c4 10             	add    $0x10,%esp
801034bc:	5b                   	pop    %ebx
801034bd:	5d                   	pop    %ebp
801034be:	c3                   	ret    

801034bf <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
801034bf:	55                   	push   %ebp
801034c0:	89 e5                	mov    %esp,%ebp
801034c2:	83 e4 f0             	and    $0xfffffff0,%esp
801034c5:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
801034c8:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
801034cf:	80 
801034d0:	c7 04 24 fc 2b 11 80 	movl   $0x80112bfc,(%esp)
801034d7:	e8 ad f5 ff ff       	call   80102a89 <kinit1>
  kvmalloc();      // kernel page table
801034dc:	e8 dd 45 00 00       	call   80107abe <kvmalloc>
  mpinit();        // collect info about this machine
801034e1:	e8 63 04 00 00       	call   80103949 <mpinit>
  lapicinit(mpbcpu());
801034e6:	e8 2e 02 00 00       	call   80103719 <mpbcpu>
801034eb:	89 04 24             	mov    %eax,(%esp)
801034ee:	e8 f5 f8 ff ff       	call   80102de8 <lapicinit>
  seginit();       // set up segments
801034f3:	e8 69 3f 00 00       	call   80107461 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
801034f8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801034fe:	0f b6 00             	movzbl (%eax),%eax
80103501:	0f b6 c0             	movzbl %al,%eax
80103504:	89 44 24 04          	mov    %eax,0x4(%esp)
80103508:	c7 04 24 cd 84 10 80 	movl   $0x801084cd,(%esp)
8010350f:	e8 8d ce ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103514:	e8 95 06 00 00       	call   80103bae <picinit>
  ioapicinit();    // another interrupt controller
80103519:	e8 5b f4 ff ff       	call   80102979 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
8010351e:	e8 6a d5 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
80103523:	e8 84 32 00 00       	call   801067ac <uartinit>
  pinit();         // process table
80103528:	e8 96 0b 00 00       	call   801040c3 <pinit>
  tvinit();        // trap vectors
8010352d:	e8 1d 2e 00 00       	call   8010634f <tvinit>
  binit();         // buffer cache
80103532:	e8 fd ca ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103537:	e8 7c da ff ff       	call   80100fb8 <fileinit>
  iinit();         // inode cache
8010353c:	e8 2a e1 ff ff       	call   8010166b <iinit>
  ideinit();       // disk
80103541:	e8 98 f0 ff ff       	call   801025de <ideinit>
  if(!ismp)
80103546:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
8010354b:	85 c0                	test   %eax,%eax
8010354d:	75 05                	jne    80103554 <main+0x95>
    timerinit();   // uniprocessor timer
8010354f:	e8 3e 2d 00 00       	call   80106292 <timerinit>
  startothers();   // start other processors
80103554:	e8 87 00 00 00       	call   801035e0 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103559:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103560:	8e 
80103561:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103568:	e8 54 f5 ff ff       	call   80102ac1 <kinit2>
  userinit();      // first user process
8010356d:	e8 6c 0c 00 00       	call   801041de <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103572:	e8 22 00 00 00       	call   80103599 <mpmain>

80103577 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103577:	55                   	push   %ebp
80103578:	89 e5                	mov    %esp,%ebp
8010357a:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
8010357d:	e8 53 45 00 00       	call   80107ad5 <switchkvm>
  seginit();
80103582:	e8 da 3e 00 00       	call   80107461 <seginit>
  lapicinit(cpunum());
80103587:	e8 b9 f9 ff ff       	call   80102f45 <cpunum>
8010358c:	89 04 24             	mov    %eax,(%esp)
8010358f:	e8 54 f8 ff ff       	call   80102de8 <lapicinit>
  mpmain();
80103594:	e8 00 00 00 00       	call   80103599 <mpmain>

80103599 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103599:	55                   	push   %ebp
8010359a:	89 e5                	mov    %esp,%ebp
8010359c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010359f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801035a5:	0f b6 00             	movzbl (%eax),%eax
801035a8:	0f b6 c0             	movzbl %al,%eax
801035ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801035af:	c7 04 24 e4 84 10 80 	movl   $0x801084e4,(%esp)
801035b6:	e8 e6 cd ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
801035bb:	e8 03 2f 00 00       	call   801064c3 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
801035c0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801035c6:	05 a8 00 00 00       	add    $0xa8,%eax
801035cb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
801035d2:	00 
801035d3:	89 04 24             	mov    %eax,(%esp)
801035d6:	e8 bf fe ff ff       	call   8010349a <xchg>
  scheduler();     // start running processes
801035db:	e8 f4 11 00 00       	call   801047d4 <scheduler>

801035e0 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
801035e0:	55                   	push   %ebp
801035e1:	89 e5                	mov    %esp,%ebp
801035e3:	53                   	push   %ebx
801035e4:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
801035e7:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
801035ee:	e8 9a fe ff ff       	call   8010348d <p2v>
801035f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
801035f6:	b8 8a 00 00 00       	mov    $0x8a,%eax
801035fb:	89 44 24 08          	mov    %eax,0x8(%esp)
801035ff:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
80103606:	80 
80103607:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010360a:	89 04 24             	mov    %eax,(%esp)
8010360d:	e8 6b 19 00 00       	call   80104f7d <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103612:	c7 45 f4 20 fe 10 80 	movl   $0x8010fe20,-0xc(%ebp)
80103619:	e9 86 00 00 00       	jmp    801036a4 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
8010361e:	e8 22 f9 ff ff       	call   80102f45 <cpunum>
80103623:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103629:	05 20 fe 10 80       	add    $0x8010fe20,%eax
8010362e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103631:	74 69                	je     8010369c <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103633:	e8 7f f5 ff ff       	call   80102bb7 <kalloc>
80103638:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010363b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010363e:	83 e8 04             	sub    $0x4,%eax
80103641:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103644:	81 c2 00 10 00 00    	add    $0x1000,%edx
8010364a:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010364c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010364f:	83 e8 08             	sub    $0x8,%eax
80103652:	c7 00 77 35 10 80    	movl   $0x80103577,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103658:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010365b:	8d 58 f4             	lea    -0xc(%eax),%ebx
8010365e:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103665:	e8 16 fe ff ff       	call   80103480 <v2p>
8010366a:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
8010366c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010366f:	89 04 24             	mov    %eax,(%esp)
80103672:	e8 09 fe ff ff       	call   80103480 <v2p>
80103677:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010367a:	0f b6 12             	movzbl (%edx),%edx
8010367d:	0f b6 d2             	movzbl %dl,%edx
80103680:	89 44 24 04          	mov    %eax,0x4(%esp)
80103684:	89 14 24             	mov    %edx,(%esp)
80103687:	e8 3f f9 ff ff       	call   80102fcb <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
8010368c:	90                   	nop
8010368d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103690:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103696:	85 c0                	test   %eax,%eax
80103698:	74 f3                	je     8010368d <startothers+0xad>
8010369a:	eb 01                	jmp    8010369d <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
8010369c:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
8010369d:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
801036a4:	a1 00 04 11 80       	mov    0x80110400,%eax
801036a9:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801036af:	05 20 fe 10 80       	add    $0x8010fe20,%eax
801036b4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801036b7:	0f 87 61 ff ff ff    	ja     8010361e <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
801036bd:	83 c4 24             	add    $0x24,%esp
801036c0:	5b                   	pop    %ebx
801036c1:	5d                   	pop    %ebp
801036c2:	c3                   	ret    
	...

801036c4 <p2v>:
801036c4:	55                   	push   %ebp
801036c5:	89 e5                	mov    %esp,%ebp
801036c7:	8b 45 08             	mov    0x8(%ebp),%eax
801036ca:	05 00 00 00 80       	add    $0x80000000,%eax
801036cf:	5d                   	pop    %ebp
801036d0:	c3                   	ret    

801036d1 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801036d1:	55                   	push   %ebp
801036d2:	89 e5                	mov    %esp,%ebp
801036d4:	53                   	push   %ebx
801036d5:	83 ec 14             	sub    $0x14,%esp
801036d8:	8b 45 08             	mov    0x8(%ebp),%eax
801036db:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801036df:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801036e3:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801036e7:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801036eb:	ec                   	in     (%dx),%al
801036ec:	89 c3                	mov    %eax,%ebx
801036ee:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801036f1:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801036f5:	83 c4 14             	add    $0x14,%esp
801036f8:	5b                   	pop    %ebx
801036f9:	5d                   	pop    %ebp
801036fa:	c3                   	ret    

801036fb <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801036fb:	55                   	push   %ebp
801036fc:	89 e5                	mov    %esp,%ebp
801036fe:	83 ec 08             	sub    $0x8,%esp
80103701:	8b 55 08             	mov    0x8(%ebp),%edx
80103704:	8b 45 0c             	mov    0xc(%ebp),%eax
80103707:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010370b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010370e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103712:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103716:	ee                   	out    %al,(%dx)
}
80103717:	c9                   	leave  
80103718:	c3                   	ret    

80103719 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103719:	55                   	push   %ebp
8010371a:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
8010371c:	a1 44 b6 10 80       	mov    0x8010b644,%eax
80103721:	89 c2                	mov    %eax,%edx
80103723:	b8 20 fe 10 80       	mov    $0x8010fe20,%eax
80103728:	89 d1                	mov    %edx,%ecx
8010372a:	29 c1                	sub    %eax,%ecx
8010372c:	89 c8                	mov    %ecx,%eax
8010372e:	c1 f8 02             	sar    $0x2,%eax
80103731:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103737:	5d                   	pop    %ebp
80103738:	c3                   	ret    

80103739 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103739:	55                   	push   %ebp
8010373a:	89 e5                	mov    %esp,%ebp
8010373c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
8010373f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103746:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010374d:	eb 13                	jmp    80103762 <sum+0x29>
    sum += addr[i];
8010374f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103752:	03 45 08             	add    0x8(%ebp),%eax
80103755:	0f b6 00             	movzbl (%eax),%eax
80103758:	0f b6 c0             	movzbl %al,%eax
8010375b:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
8010375e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103762:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103765:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103768:	7c e5                	jl     8010374f <sum+0x16>
    sum += addr[i];
  return sum;
8010376a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010376d:	c9                   	leave  
8010376e:	c3                   	ret    

8010376f <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010376f:	55                   	push   %ebp
80103770:	89 e5                	mov    %esp,%ebp
80103772:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103775:	8b 45 08             	mov    0x8(%ebp),%eax
80103778:	89 04 24             	mov    %eax,(%esp)
8010377b:	e8 44 ff ff ff       	call   801036c4 <p2v>
80103780:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103783:	8b 45 0c             	mov    0xc(%ebp),%eax
80103786:	03 45 f0             	add    -0x10(%ebp),%eax
80103789:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
8010378c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010378f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103792:	eb 3f                	jmp    801037d3 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103794:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
8010379b:	00 
8010379c:	c7 44 24 04 f8 84 10 	movl   $0x801084f8,0x4(%esp)
801037a3:	80 
801037a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037a7:	89 04 24             	mov    %eax,(%esp)
801037aa:	e8 72 17 00 00       	call   80104f21 <memcmp>
801037af:	85 c0                	test   %eax,%eax
801037b1:	75 1c                	jne    801037cf <mpsearch1+0x60>
801037b3:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
801037ba:	00 
801037bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037be:	89 04 24             	mov    %eax,(%esp)
801037c1:	e8 73 ff ff ff       	call   80103739 <sum>
801037c6:	84 c0                	test   %al,%al
801037c8:	75 05                	jne    801037cf <mpsearch1+0x60>
      return (struct mp*)p;
801037ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037cd:	eb 11                	jmp    801037e0 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
801037cf:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801037d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037d6:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801037d9:	72 b9                	jb     80103794 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
801037db:	b8 00 00 00 00       	mov    $0x0,%eax
}
801037e0:	c9                   	leave  
801037e1:	c3                   	ret    

801037e2 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
801037e2:	55                   	push   %ebp
801037e3:	89 e5                	mov    %esp,%ebp
801037e5:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
801037e8:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
801037ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037f2:	83 c0 0f             	add    $0xf,%eax
801037f5:	0f b6 00             	movzbl (%eax),%eax
801037f8:	0f b6 c0             	movzbl %al,%eax
801037fb:	89 c2                	mov    %eax,%edx
801037fd:	c1 e2 08             	shl    $0x8,%edx
80103800:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103803:	83 c0 0e             	add    $0xe,%eax
80103806:	0f b6 00             	movzbl (%eax),%eax
80103809:	0f b6 c0             	movzbl %al,%eax
8010380c:	09 d0                	or     %edx,%eax
8010380e:	c1 e0 04             	shl    $0x4,%eax
80103811:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103814:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103818:	74 21                	je     8010383b <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
8010381a:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103821:	00 
80103822:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103825:	89 04 24             	mov    %eax,(%esp)
80103828:	e8 42 ff ff ff       	call   8010376f <mpsearch1>
8010382d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103830:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103834:	74 50                	je     80103886 <mpsearch+0xa4>
      return mp;
80103836:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103839:	eb 5f                	jmp    8010389a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
8010383b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010383e:	83 c0 14             	add    $0x14,%eax
80103841:	0f b6 00             	movzbl (%eax),%eax
80103844:	0f b6 c0             	movzbl %al,%eax
80103847:	89 c2                	mov    %eax,%edx
80103849:	c1 e2 08             	shl    $0x8,%edx
8010384c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010384f:	83 c0 13             	add    $0x13,%eax
80103852:	0f b6 00             	movzbl (%eax),%eax
80103855:	0f b6 c0             	movzbl %al,%eax
80103858:	09 d0                	or     %edx,%eax
8010385a:	c1 e0 0a             	shl    $0xa,%eax
8010385d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103860:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103863:	2d 00 04 00 00       	sub    $0x400,%eax
80103868:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010386f:	00 
80103870:	89 04 24             	mov    %eax,(%esp)
80103873:	e8 f7 fe ff ff       	call   8010376f <mpsearch1>
80103878:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010387b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010387f:	74 05                	je     80103886 <mpsearch+0xa4>
      return mp;
80103881:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103884:	eb 14                	jmp    8010389a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103886:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
8010388d:	00 
8010388e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103895:	e8 d5 fe ff ff       	call   8010376f <mpsearch1>
}
8010389a:	c9                   	leave  
8010389b:	c3                   	ret    

8010389c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
8010389c:	55                   	push   %ebp
8010389d:	89 e5                	mov    %esp,%ebp
8010389f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
801038a2:	e8 3b ff ff ff       	call   801037e2 <mpsearch>
801038a7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801038aa:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801038ae:	74 0a                	je     801038ba <mpconfig+0x1e>
801038b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038b3:	8b 40 04             	mov    0x4(%eax),%eax
801038b6:	85 c0                	test   %eax,%eax
801038b8:	75 0a                	jne    801038c4 <mpconfig+0x28>
    return 0;
801038ba:	b8 00 00 00 00       	mov    $0x0,%eax
801038bf:	e9 83 00 00 00       	jmp    80103947 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
801038c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801038c7:	8b 40 04             	mov    0x4(%eax),%eax
801038ca:	89 04 24             	mov    %eax,(%esp)
801038cd:	e8 f2 fd ff ff       	call   801036c4 <p2v>
801038d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
801038d5:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
801038dc:	00 
801038dd:	c7 44 24 04 fd 84 10 	movl   $0x801084fd,0x4(%esp)
801038e4:	80 
801038e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038e8:	89 04 24             	mov    %eax,(%esp)
801038eb:	e8 31 16 00 00       	call   80104f21 <memcmp>
801038f0:	85 c0                	test   %eax,%eax
801038f2:	74 07                	je     801038fb <mpconfig+0x5f>
    return 0;
801038f4:	b8 00 00 00 00       	mov    $0x0,%eax
801038f9:	eb 4c                	jmp    80103947 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
801038fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038fe:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103902:	3c 01                	cmp    $0x1,%al
80103904:	74 12                	je     80103918 <mpconfig+0x7c>
80103906:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103909:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010390d:	3c 04                	cmp    $0x4,%al
8010390f:	74 07                	je     80103918 <mpconfig+0x7c>
    return 0;
80103911:	b8 00 00 00 00       	mov    $0x0,%eax
80103916:	eb 2f                	jmp    80103947 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103918:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010391b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
8010391f:	0f b7 c0             	movzwl %ax,%eax
80103922:	89 44 24 04          	mov    %eax,0x4(%esp)
80103926:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103929:	89 04 24             	mov    %eax,(%esp)
8010392c:	e8 08 fe ff ff       	call   80103739 <sum>
80103931:	84 c0                	test   %al,%al
80103933:	74 07                	je     8010393c <mpconfig+0xa0>
    return 0;
80103935:	b8 00 00 00 00       	mov    $0x0,%eax
8010393a:	eb 0b                	jmp    80103947 <mpconfig+0xab>
  *pmp = mp;
8010393c:	8b 45 08             	mov    0x8(%ebp),%eax
8010393f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103942:	89 10                	mov    %edx,(%eax)
  return conf;
80103944:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103947:	c9                   	leave  
80103948:	c3                   	ret    

80103949 <mpinit>:

void
mpinit(void)
{
80103949:	55                   	push   %ebp
8010394a:	89 e5                	mov    %esp,%ebp
8010394c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
8010394f:	c7 05 44 b6 10 80 20 	movl   $0x8010fe20,0x8010b644
80103956:	fe 10 80 
  if((conf = mpconfig(&mp)) == 0)
80103959:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010395c:	89 04 24             	mov    %eax,(%esp)
8010395f:	e8 38 ff ff ff       	call   8010389c <mpconfig>
80103964:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103967:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010396b:	0f 84 9c 01 00 00    	je     80103b0d <mpinit+0x1c4>
    return;
  ismp = 1;
80103971:	c7 05 04 fe 10 80 01 	movl   $0x1,0x8010fe04
80103978:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
8010397b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010397e:	8b 40 24             	mov    0x24(%eax),%eax
80103981:	a3 7c fd 10 80       	mov    %eax,0x8010fd7c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103986:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103989:	83 c0 2c             	add    $0x2c,%eax
8010398c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010398f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103992:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103996:	0f b7 c0             	movzwl %ax,%eax
80103999:	03 45 f0             	add    -0x10(%ebp),%eax
8010399c:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010399f:	e9 f4 00 00 00       	jmp    80103a98 <mpinit+0x14f>
    switch(*p){
801039a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039a7:	0f b6 00             	movzbl (%eax),%eax
801039aa:	0f b6 c0             	movzbl %al,%eax
801039ad:	83 f8 04             	cmp    $0x4,%eax
801039b0:	0f 87 bf 00 00 00    	ja     80103a75 <mpinit+0x12c>
801039b6:	8b 04 85 40 85 10 80 	mov    -0x7fef7ac0(,%eax,4),%eax
801039bd:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
801039bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039c2:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
801039c5:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039c8:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801039cc:	0f b6 d0             	movzbl %al,%edx
801039cf:	a1 00 04 11 80       	mov    0x80110400,%eax
801039d4:	39 c2                	cmp    %eax,%edx
801039d6:	74 2d                	je     80103a05 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
801039d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039db:	0f b6 40 01          	movzbl 0x1(%eax),%eax
801039df:	0f b6 d0             	movzbl %al,%edx
801039e2:	a1 00 04 11 80       	mov    0x80110400,%eax
801039e7:	89 54 24 08          	mov    %edx,0x8(%esp)
801039eb:	89 44 24 04          	mov    %eax,0x4(%esp)
801039ef:	c7 04 24 02 85 10 80 	movl   $0x80108502,(%esp)
801039f6:	e8 a6 c9 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
801039fb:	c7 05 04 fe 10 80 00 	movl   $0x0,0x8010fe04
80103a02:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103a05:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103a08:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103a0c:	0f b6 c0             	movzbl %al,%eax
80103a0f:	83 e0 02             	and    $0x2,%eax
80103a12:	85 c0                	test   %eax,%eax
80103a14:	74 15                	je     80103a2b <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103a16:	a1 00 04 11 80       	mov    0x80110400,%eax
80103a1b:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103a21:	05 20 fe 10 80       	add    $0x8010fe20,%eax
80103a26:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
80103a2b:	8b 15 00 04 11 80    	mov    0x80110400,%edx
80103a31:	a1 00 04 11 80       	mov    0x80110400,%eax
80103a36:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103a3c:	81 c2 20 fe 10 80    	add    $0x8010fe20,%edx
80103a42:	88 02                	mov    %al,(%edx)
      ncpu++;
80103a44:	a1 00 04 11 80       	mov    0x80110400,%eax
80103a49:	83 c0 01             	add    $0x1,%eax
80103a4c:	a3 00 04 11 80       	mov    %eax,0x80110400
      p += sizeof(struct mpproc);
80103a51:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103a55:	eb 41                	jmp    80103a98 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103a57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a5a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
80103a5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103a60:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103a64:	a2 00 fe 10 80       	mov    %al,0x8010fe00
      p += sizeof(struct mpioapic);
80103a69:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103a6d:	eb 29                	jmp    80103a98 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103a6f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103a73:	eb 23                	jmp    80103a98 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103a75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a78:	0f b6 00             	movzbl (%eax),%eax
80103a7b:	0f b6 c0             	movzbl %al,%eax
80103a7e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a82:	c7 04 24 20 85 10 80 	movl   $0x80108520,(%esp)
80103a89:	e8 13 c9 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103a8e:	c7 05 04 fe 10 80 00 	movl   $0x0,0x8010fe04
80103a95:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103a98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a9b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103a9e:	0f 82 00 ff ff ff    	jb     801039a4 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103aa4:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
80103aa9:	85 c0                	test   %eax,%eax
80103aab:	75 1d                	jne    80103aca <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103aad:	c7 05 00 04 11 80 01 	movl   $0x1,0x80110400
80103ab4:	00 00 00 
    lapic = 0;
80103ab7:	c7 05 7c fd 10 80 00 	movl   $0x0,0x8010fd7c
80103abe:	00 00 00 
    ioapicid = 0;
80103ac1:	c6 05 00 fe 10 80 00 	movb   $0x0,0x8010fe00
    return;
80103ac8:	eb 44                	jmp    80103b0e <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103aca:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103acd:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103ad1:	84 c0                	test   %al,%al
80103ad3:	74 39                	je     80103b0e <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103ad5:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103adc:	00 
80103add:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103ae4:	e8 12 fc ff ff       	call   801036fb <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103ae9:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103af0:	e8 dc fb ff ff       	call   801036d1 <inb>
80103af5:	83 c8 01             	or     $0x1,%eax
80103af8:	0f b6 c0             	movzbl %al,%eax
80103afb:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aff:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103b06:	e8 f0 fb ff ff       	call   801036fb <outb>
80103b0b:	eb 01                	jmp    80103b0e <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103b0d:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103b0e:	c9                   	leave  
80103b0f:	c3                   	ret    

80103b10 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103b10:	55                   	push   %ebp
80103b11:	89 e5                	mov    %esp,%ebp
80103b13:	83 ec 08             	sub    $0x8,%esp
80103b16:	8b 55 08             	mov    0x8(%ebp),%edx
80103b19:	8b 45 0c             	mov    0xc(%ebp),%eax
80103b1c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103b20:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103b23:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103b27:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103b2b:	ee                   	out    %al,(%dx)
}
80103b2c:	c9                   	leave  
80103b2d:	c3                   	ret    

80103b2e <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103b2e:	55                   	push   %ebp
80103b2f:	89 e5                	mov    %esp,%ebp
80103b31:	83 ec 0c             	sub    $0xc,%esp
80103b34:	8b 45 08             	mov    0x8(%ebp),%eax
80103b37:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103b3b:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103b3f:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103b45:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103b49:	0f b6 c0             	movzbl %al,%eax
80103b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b50:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b57:	e8 b4 ff ff ff       	call   80103b10 <outb>
  outb(IO_PIC2+1, mask >> 8);
80103b5c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103b60:	66 c1 e8 08          	shr    $0x8,%ax
80103b64:	0f b6 c0             	movzbl %al,%eax
80103b67:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b6b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b72:	e8 99 ff ff ff       	call   80103b10 <outb>
}
80103b77:	c9                   	leave  
80103b78:	c3                   	ret    

80103b79 <picenable>:

void
picenable(int irq)
{
80103b79:	55                   	push   %ebp
80103b7a:	89 e5                	mov    %esp,%ebp
80103b7c:	53                   	push   %ebx
80103b7d:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103b80:	8b 45 08             	mov    0x8(%ebp),%eax
80103b83:	ba 01 00 00 00       	mov    $0x1,%edx
80103b88:	89 d3                	mov    %edx,%ebx
80103b8a:	89 c1                	mov    %eax,%ecx
80103b8c:	d3 e3                	shl    %cl,%ebx
80103b8e:	89 d8                	mov    %ebx,%eax
80103b90:	89 c2                	mov    %eax,%edx
80103b92:	f7 d2                	not    %edx
80103b94:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103b9b:	21 d0                	and    %edx,%eax
80103b9d:	0f b7 c0             	movzwl %ax,%eax
80103ba0:	89 04 24             	mov    %eax,(%esp)
80103ba3:	e8 86 ff ff ff       	call   80103b2e <picsetmask>
}
80103ba8:	83 c4 04             	add    $0x4,%esp
80103bab:	5b                   	pop    %ebx
80103bac:	5d                   	pop    %ebp
80103bad:	c3                   	ret    

80103bae <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103bae:	55                   	push   %ebp
80103baf:	89 e5                	mov    %esp,%ebp
80103bb1:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103bb4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103bbb:	00 
80103bbc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103bc3:	e8 48 ff ff ff       	call   80103b10 <outb>
  outb(IO_PIC2+1, 0xFF);
80103bc8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103bcf:	00 
80103bd0:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bd7:	e8 34 ff ff ff       	call   80103b10 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103bdc:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103be3:	00 
80103be4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103beb:	e8 20 ff ff ff       	call   80103b10 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103bf0:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103bf7:	00 
80103bf8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103bff:	e8 0c ff ff ff       	call   80103b10 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103c04:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103c0b:	00 
80103c0c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c13:	e8 f8 fe ff ff       	call   80103b10 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103c18:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103c1f:	00 
80103c20:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103c27:	e8 e4 fe ff ff       	call   80103b10 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103c2c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103c33:	00 
80103c34:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c3b:	e8 d0 fe ff ff       	call   80103b10 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103c40:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103c47:	00 
80103c48:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c4f:	e8 bc fe ff ff       	call   80103b10 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103c54:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103c5b:	00 
80103c5c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c63:	e8 a8 fe ff ff       	call   80103b10 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103c68:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103c6f:	00 
80103c70:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c77:	e8 94 fe ff ff       	call   80103b10 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103c7c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103c83:	00 
80103c84:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c8b:	e8 80 fe ff ff       	call   80103b10 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103c90:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c97:	00 
80103c98:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c9f:	e8 6c fe ff ff       	call   80103b10 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103ca4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103cab:	00 
80103cac:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103cb3:	e8 58 fe ff ff       	call   80103b10 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103cb8:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103cbf:	00 
80103cc0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103cc7:	e8 44 fe ff ff       	call   80103b10 <outb>

  if(irqmask != 0xFFFF)
80103ccc:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103cd3:	66 83 f8 ff          	cmp    $0xffff,%ax
80103cd7:	74 12                	je     80103ceb <picinit+0x13d>
    picsetmask(irqmask);
80103cd9:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103ce0:	0f b7 c0             	movzwl %ax,%eax
80103ce3:	89 04 24             	mov    %eax,(%esp)
80103ce6:	e8 43 fe ff ff       	call   80103b2e <picsetmask>
}
80103ceb:	c9                   	leave  
80103cec:	c3                   	ret    
80103ced:	00 00                	add    %al,(%eax)
	...

80103cf0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103cf0:	55                   	push   %ebp
80103cf1:	89 e5                	mov    %esp,%ebp
80103cf3:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103cf6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103cfd:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d00:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103d06:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d09:	8b 10                	mov    (%eax),%edx
80103d0b:	8b 45 08             	mov    0x8(%ebp),%eax
80103d0e:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103d10:	e8 bf d2 ff ff       	call   80100fd4 <filealloc>
80103d15:	8b 55 08             	mov    0x8(%ebp),%edx
80103d18:	89 02                	mov    %eax,(%edx)
80103d1a:	8b 45 08             	mov    0x8(%ebp),%eax
80103d1d:	8b 00                	mov    (%eax),%eax
80103d1f:	85 c0                	test   %eax,%eax
80103d21:	0f 84 c8 00 00 00    	je     80103def <pipealloc+0xff>
80103d27:	e8 a8 d2 ff ff       	call   80100fd4 <filealloc>
80103d2c:	8b 55 0c             	mov    0xc(%ebp),%edx
80103d2f:	89 02                	mov    %eax,(%edx)
80103d31:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d34:	8b 00                	mov    (%eax),%eax
80103d36:	85 c0                	test   %eax,%eax
80103d38:	0f 84 b1 00 00 00    	je     80103def <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103d3e:	e8 74 ee ff ff       	call   80102bb7 <kalloc>
80103d43:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103d46:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d4a:	0f 84 9e 00 00 00    	je     80103dee <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103d50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d53:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103d5a:	00 00 00 
  p->writeopen = 1;
80103d5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d60:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103d67:	00 00 00 
  p->nwrite = 0;
80103d6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d6d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103d74:	00 00 00 
  p->nread = 0;
80103d77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d7a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103d81:	00 00 00 
  initlock(&p->lock, "pipe");
80103d84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d87:	c7 44 24 04 54 85 10 	movl   $0x80108554,0x4(%esp)
80103d8e:	80 
80103d8f:	89 04 24             	mov    %eax,(%esp)
80103d92:	e8 a3 0e 00 00       	call   80104c3a <initlock>
  (*f0)->type = FD_PIPE;
80103d97:	8b 45 08             	mov    0x8(%ebp),%eax
80103d9a:	8b 00                	mov    (%eax),%eax
80103d9c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103da2:	8b 45 08             	mov    0x8(%ebp),%eax
80103da5:	8b 00                	mov    (%eax),%eax
80103da7:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103dab:	8b 45 08             	mov    0x8(%ebp),%eax
80103dae:	8b 00                	mov    (%eax),%eax
80103db0:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103db4:	8b 45 08             	mov    0x8(%ebp),%eax
80103db7:	8b 00                	mov    (%eax),%eax
80103db9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103dbc:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103dbf:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dc2:	8b 00                	mov    (%eax),%eax
80103dc4:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103dca:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dcd:	8b 00                	mov    (%eax),%eax
80103dcf:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103dd3:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dd6:	8b 00                	mov    (%eax),%eax
80103dd8:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103ddc:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ddf:	8b 00                	mov    (%eax),%eax
80103de1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103de4:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103de7:	b8 00 00 00 00       	mov    $0x0,%eax
80103dec:	eb 43                	jmp    80103e31 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103dee:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103def:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103df3:	74 0b                	je     80103e00 <pipealloc+0x110>
    kfree((char*)p);
80103df5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103df8:	89 04 24             	mov    %eax,(%esp)
80103dfb:	e8 1e ed ff ff       	call   80102b1e <kfree>
  if(*f0)
80103e00:	8b 45 08             	mov    0x8(%ebp),%eax
80103e03:	8b 00                	mov    (%eax),%eax
80103e05:	85 c0                	test   %eax,%eax
80103e07:	74 0d                	je     80103e16 <pipealloc+0x126>
    fileclose(*f0);
80103e09:	8b 45 08             	mov    0x8(%ebp),%eax
80103e0c:	8b 00                	mov    (%eax),%eax
80103e0e:	89 04 24             	mov    %eax,(%esp)
80103e11:	e8 66 d2 ff ff       	call   8010107c <fileclose>
  if(*f1)
80103e16:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e19:	8b 00                	mov    (%eax),%eax
80103e1b:	85 c0                	test   %eax,%eax
80103e1d:	74 0d                	je     80103e2c <pipealloc+0x13c>
    fileclose(*f1);
80103e1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e22:	8b 00                	mov    (%eax),%eax
80103e24:	89 04 24             	mov    %eax,(%esp)
80103e27:	e8 50 d2 ff ff       	call   8010107c <fileclose>
  return -1;
80103e2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103e31:	c9                   	leave  
80103e32:	c3                   	ret    

80103e33 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103e33:	55                   	push   %ebp
80103e34:	89 e5                	mov    %esp,%ebp
80103e36:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103e39:	8b 45 08             	mov    0x8(%ebp),%eax
80103e3c:	89 04 24             	mov    %eax,(%esp)
80103e3f:	e8 17 0e 00 00       	call   80104c5b <acquire>
  if(writable){
80103e44:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103e48:	74 1f                	je     80103e69 <pipeclose+0x36>
    p->writeopen = 0;
80103e4a:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4d:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103e54:	00 00 00 
    wakeup(&p->nread);
80103e57:	8b 45 08             	mov    0x8(%ebp),%eax
80103e5a:	05 34 02 00 00       	add    $0x234,%eax
80103e5f:	89 04 24             	mov    %eax,(%esp)
80103e62:	e8 ef 0b 00 00       	call   80104a56 <wakeup>
80103e67:	eb 1d                	jmp    80103e86 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103e69:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6c:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103e73:	00 00 00 
    wakeup(&p->nwrite);
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	05 38 02 00 00       	add    $0x238,%eax
80103e7e:	89 04 24             	mov    %eax,(%esp)
80103e81:	e8 d0 0b 00 00       	call   80104a56 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103e86:	8b 45 08             	mov    0x8(%ebp),%eax
80103e89:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e8f:	85 c0                	test   %eax,%eax
80103e91:	75 25                	jne    80103eb8 <pipeclose+0x85>
80103e93:	8b 45 08             	mov    0x8(%ebp),%eax
80103e96:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103e9c:	85 c0                	test   %eax,%eax
80103e9e:	75 18                	jne    80103eb8 <pipeclose+0x85>
    release(&p->lock);
80103ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ea3:	89 04 24             	mov    %eax,(%esp)
80103ea6:	e8 12 0e 00 00       	call   80104cbd <release>
    kfree((char*)p);
80103eab:	8b 45 08             	mov    0x8(%ebp),%eax
80103eae:	89 04 24             	mov    %eax,(%esp)
80103eb1:	e8 68 ec ff ff       	call   80102b1e <kfree>
80103eb6:	eb 0b                	jmp    80103ec3 <pipeclose+0x90>
  } else
    release(&p->lock);
80103eb8:	8b 45 08             	mov    0x8(%ebp),%eax
80103ebb:	89 04 24             	mov    %eax,(%esp)
80103ebe:	e8 fa 0d 00 00       	call   80104cbd <release>
}
80103ec3:	c9                   	leave  
80103ec4:	c3                   	ret    

80103ec5 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103ec5:	55                   	push   %ebp
80103ec6:	89 e5                	mov    %esp,%ebp
80103ec8:	53                   	push   %ebx
80103ec9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103ecc:	8b 45 08             	mov    0x8(%ebp),%eax
80103ecf:	89 04 24             	mov    %eax,(%esp)
80103ed2:	e8 84 0d 00 00       	call   80104c5b <acquire>
  for(i = 0; i < n; i++){
80103ed7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103ede:	e9 a6 00 00 00       	jmp    80103f89 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103ee3:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee6:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103eec:	85 c0                	test   %eax,%eax
80103eee:	74 0d                	je     80103efd <pipewrite+0x38>
80103ef0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103ef6:	8b 40 24             	mov    0x24(%eax),%eax
80103ef9:	85 c0                	test   %eax,%eax
80103efb:	74 15                	je     80103f12 <pipewrite+0x4d>
        release(&p->lock);
80103efd:	8b 45 08             	mov    0x8(%ebp),%eax
80103f00:	89 04 24             	mov    %eax,(%esp)
80103f03:	e8 b5 0d 00 00       	call   80104cbd <release>
        return -1;
80103f08:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f0d:	e9 9d 00 00 00       	jmp    80103faf <pipewrite+0xea>
      }
      wakeup(&p->nread);
80103f12:	8b 45 08             	mov    0x8(%ebp),%eax
80103f15:	05 34 02 00 00       	add    $0x234,%eax
80103f1a:	89 04 24             	mov    %eax,(%esp)
80103f1d:	e8 34 0b 00 00       	call   80104a56 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103f22:	8b 45 08             	mov    0x8(%ebp),%eax
80103f25:	8b 55 08             	mov    0x8(%ebp),%edx
80103f28:	81 c2 38 02 00 00    	add    $0x238,%edx
80103f2e:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f32:	89 14 24             	mov    %edx,(%esp)
80103f35:	e8 43 0a 00 00       	call   8010497d <sleep>
80103f3a:	eb 01                	jmp    80103f3d <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103f3c:	90                   	nop
80103f3d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f40:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103f46:	8b 45 08             	mov    0x8(%ebp),%eax
80103f49:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103f4f:	05 00 02 00 00       	add    $0x200,%eax
80103f54:	39 c2                	cmp    %eax,%edx
80103f56:	74 8b                	je     80103ee3 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103f58:	8b 45 08             	mov    0x8(%ebp),%eax
80103f5b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103f61:	89 c3                	mov    %eax,%ebx
80103f63:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103f69:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f6c:	03 55 0c             	add    0xc(%ebp),%edx
80103f6f:	0f b6 0a             	movzbl (%edx),%ecx
80103f72:	8b 55 08             	mov    0x8(%ebp),%edx
80103f75:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80103f79:	8d 50 01             	lea    0x1(%eax),%edx
80103f7c:	8b 45 08             	mov    0x8(%ebp),%eax
80103f7f:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80103f85:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103f89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f8c:	3b 45 10             	cmp    0x10(%ebp),%eax
80103f8f:	7c ab                	jl     80103f3c <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103f91:	8b 45 08             	mov    0x8(%ebp),%eax
80103f94:	05 34 02 00 00       	add    $0x234,%eax
80103f99:	89 04 24             	mov    %eax,(%esp)
80103f9c:	e8 b5 0a 00 00       	call   80104a56 <wakeup>
  release(&p->lock);
80103fa1:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa4:	89 04 24             	mov    %eax,(%esp)
80103fa7:	e8 11 0d 00 00       	call   80104cbd <release>
  return n;
80103fac:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103faf:	83 c4 24             	add    $0x24,%esp
80103fb2:	5b                   	pop    %ebx
80103fb3:	5d                   	pop    %ebp
80103fb4:	c3                   	ret    

80103fb5 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103fb5:	55                   	push   %ebp
80103fb6:	89 e5                	mov    %esp,%ebp
80103fb8:	53                   	push   %ebx
80103fb9:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103fbc:	8b 45 08             	mov    0x8(%ebp),%eax
80103fbf:	89 04 24             	mov    %eax,(%esp)
80103fc2:	e8 94 0c 00 00       	call   80104c5b <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103fc7:	eb 3a                	jmp    80104003 <piperead+0x4e>
    if(proc->killed){
80103fc9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103fcf:	8b 40 24             	mov    0x24(%eax),%eax
80103fd2:	85 c0                	test   %eax,%eax
80103fd4:	74 15                	je     80103feb <piperead+0x36>
      release(&p->lock);
80103fd6:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd9:	89 04 24             	mov    %eax,(%esp)
80103fdc:	e8 dc 0c 00 00       	call   80104cbd <release>
      return -1;
80103fe1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103fe6:	e9 b6 00 00 00       	jmp    801040a1 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103feb:	8b 45 08             	mov    0x8(%ebp),%eax
80103fee:	8b 55 08             	mov    0x8(%ebp),%edx
80103ff1:	81 c2 34 02 00 00    	add    $0x234,%edx
80103ff7:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ffb:	89 14 24             	mov    %edx,(%esp)
80103ffe:	e8 7a 09 00 00       	call   8010497d <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104003:	8b 45 08             	mov    0x8(%ebp),%eax
80104006:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
8010400c:	8b 45 08             	mov    0x8(%ebp),%eax
8010400f:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104015:	39 c2                	cmp    %eax,%edx
80104017:	75 0d                	jne    80104026 <piperead+0x71>
80104019:	8b 45 08             	mov    0x8(%ebp),%eax
8010401c:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80104022:	85 c0                	test   %eax,%eax
80104024:	75 a3                	jne    80103fc9 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104026:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010402d:	eb 49                	jmp    80104078 <piperead+0xc3>
    if(p->nread == p->nwrite)
8010402f:	8b 45 08             	mov    0x8(%ebp),%eax
80104032:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104038:	8b 45 08             	mov    0x8(%ebp),%eax
8010403b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104041:	39 c2                	cmp    %eax,%edx
80104043:	74 3d                	je     80104082 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104045:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104048:	89 c2                	mov    %eax,%edx
8010404a:	03 55 0c             	add    0xc(%ebp),%edx
8010404d:	8b 45 08             	mov    0x8(%ebp),%eax
80104050:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104056:	89 c3                	mov    %eax,%ebx
80104058:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010405e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104061:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104066:	88 0a                	mov    %cl,(%edx)
80104068:	8d 50 01             	lea    0x1(%eax),%edx
8010406b:	8b 45 08             	mov    0x8(%ebp),%eax
8010406e:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104074:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010407b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010407e:	7c af                	jl     8010402f <piperead+0x7a>
80104080:	eb 01                	jmp    80104083 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104082:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104083:	8b 45 08             	mov    0x8(%ebp),%eax
80104086:	05 38 02 00 00       	add    $0x238,%eax
8010408b:	89 04 24             	mov    %eax,(%esp)
8010408e:	e8 c3 09 00 00       	call   80104a56 <wakeup>
  release(&p->lock);
80104093:	8b 45 08             	mov    0x8(%ebp),%eax
80104096:	89 04 24             	mov    %eax,(%esp)
80104099:	e8 1f 0c 00 00       	call   80104cbd <release>
  return i;
8010409e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801040a1:	83 c4 24             	add    $0x24,%esp
801040a4:	5b                   	pop    %ebx
801040a5:	5d                   	pop    %ebp
801040a6:	c3                   	ret    
	...

801040a8 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801040a8:	55                   	push   %ebp
801040a9:	89 e5                	mov    %esp,%ebp
801040ab:	53                   	push   %ebx
801040ac:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801040af:	9c                   	pushf  
801040b0:	5b                   	pop    %ebx
801040b1:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801040b4:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801040b7:	83 c4 10             	add    $0x10,%esp
801040ba:	5b                   	pop    %ebx
801040bb:	5d                   	pop    %ebp
801040bc:	c3                   	ret    

801040bd <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801040bd:	55                   	push   %ebp
801040be:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801040c0:	fb                   	sti    
}
801040c1:	5d                   	pop    %ebp
801040c2:	c3                   	ret    

801040c3 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801040c3:	55                   	push   %ebp
801040c4:	89 e5                	mov    %esp,%ebp
801040c6:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801040c9:	c7 44 24 04 59 85 10 	movl   $0x80108559,0x4(%esp)
801040d0:	80 
801040d1:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801040d8:	e8 5d 0b 00 00       	call   80104c3a <initlock>
}
801040dd:	c9                   	leave  
801040de:	c3                   	ret    

801040df <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801040df:	55                   	push   %ebp
801040e0:	89 e5                	mov    %esp,%ebp
801040e2:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801040e5:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801040ec:	e8 6a 0b 00 00       	call   80104c5b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801040f1:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
801040f8:	eb 0e                	jmp    80104108 <allocproc+0x29>
    if(p->state == UNUSED)
801040fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801040fd:	8b 40 0c             	mov    0xc(%eax),%eax
80104100:	85 c0                	test   %eax,%eax
80104102:	74 23                	je     80104127 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104104:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104108:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
8010410f:	72 e9                	jb     801040fa <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104111:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104118:	e8 a0 0b 00 00       	call   80104cbd <release>
  return 0;
8010411d:	b8 00 00 00 00       	mov    $0x0,%eax
80104122:	e9 b5 00 00 00       	jmp    801041dc <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104127:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104128:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010412b:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104132:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104137:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010413a:	89 42 10             	mov    %eax,0x10(%edx)
8010413d:	83 c0 01             	add    $0x1,%eax
80104140:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
80104145:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010414c:	e8 6c 0b 00 00       	call   80104cbd <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104151:	e8 61 ea ff ff       	call   80102bb7 <kalloc>
80104156:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104159:	89 42 08             	mov    %eax,0x8(%edx)
8010415c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010415f:	8b 40 08             	mov    0x8(%eax),%eax
80104162:	85 c0                	test   %eax,%eax
80104164:	75 11                	jne    80104177 <allocproc+0x98>
    p->state = UNUSED;
80104166:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104169:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104170:	b8 00 00 00 00       	mov    $0x0,%eax
80104175:	eb 65                	jmp    801041dc <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104177:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417a:	8b 40 08             	mov    0x8(%eax),%eax
8010417d:	05 00 10 00 00       	add    $0x1000,%eax
80104182:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104185:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104189:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010418c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010418f:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104192:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104196:	ba 04 63 10 80       	mov    $0x80106304,%edx
8010419b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010419e:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801041a0:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801041a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041a7:	8b 55 f0             	mov    -0x10(%ebp),%edx
801041aa:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801041ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b0:	8b 40 1c             	mov    0x1c(%eax),%eax
801041b3:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801041ba:	00 
801041bb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801041c2:	00 
801041c3:	89 04 24             	mov    %eax,(%esp)
801041c6:	e8 df 0c 00 00       	call   80104eaa <memset>
  p->context->eip = (uint)forkret;
801041cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ce:	8b 40 1c             	mov    0x1c(%eax),%eax
801041d1:	ba 51 49 10 80       	mov    $0x80104951,%edx
801041d6:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801041d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801041dc:	c9                   	leave  
801041dd:	c3                   	ret    

801041de <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801041de:	55                   	push   %ebp
801041df:	89 e5                	mov    %esp,%ebp
801041e1:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801041e4:	e8 f6 fe ff ff       	call   801040df <allocproc>
801041e9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801041ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ef:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm(kalloc)) == 0)
801041f4:	c7 04 24 b7 2b 10 80 	movl   $0x80102bb7,(%esp)
801041fb:	e8 01 38 00 00       	call   80107a01 <setupkvm>
80104200:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104203:	89 42 04             	mov    %eax,0x4(%edx)
80104206:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104209:	8b 40 04             	mov    0x4(%eax),%eax
8010420c:	85 c0                	test   %eax,%eax
8010420e:	75 0c                	jne    8010421c <userinit+0x3e>
    panic("userinit: out of memory?");
80104210:	c7 04 24 60 85 10 80 	movl   $0x80108560,(%esp)
80104217:	e8 21 c3 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
8010421c:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104221:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104224:	8b 40 04             	mov    0x4(%eax),%eax
80104227:	89 54 24 08          	mov    %edx,0x8(%esp)
8010422b:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
80104232:	80 
80104233:	89 04 24             	mov    %eax,(%esp)
80104236:	e8 1e 3a 00 00       	call   80107c59 <inituvm>
  p->sz = PGSIZE;
8010423b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010423e:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104244:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104247:	8b 40 18             	mov    0x18(%eax),%eax
8010424a:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104251:	00 
80104252:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104259:	00 
8010425a:	89 04 24             	mov    %eax,(%esp)
8010425d:	e8 48 0c 00 00       	call   80104eaa <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104262:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104265:	8b 40 18             	mov    0x18(%eax),%eax
80104268:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010426e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104271:	8b 40 18             	mov    0x18(%eax),%eax
80104274:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010427a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010427d:	8b 40 18             	mov    0x18(%eax),%eax
80104280:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104283:	8b 52 18             	mov    0x18(%edx),%edx
80104286:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010428a:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010428e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104291:	8b 40 18             	mov    0x18(%eax),%eax
80104294:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104297:	8b 52 18             	mov    0x18(%edx),%edx
8010429a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010429e:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801042a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042a5:	8b 40 18             	mov    0x18(%eax),%eax
801042a8:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801042af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b2:	8b 40 18             	mov    0x18(%eax),%eax
801042b5:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801042bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042bf:	8b 40 18             	mov    0x18(%eax),%eax
801042c2:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801042c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042cc:	83 c0 6c             	add    $0x6c,%eax
801042cf:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801042d6:	00 
801042d7:	c7 44 24 04 79 85 10 	movl   $0x80108579,0x4(%esp)
801042de:	80 
801042df:	89 04 24             	mov    %eax,(%esp)
801042e2:	e8 f3 0d 00 00       	call   801050da <safestrcpy>
  p->cwd = namei("/");
801042e7:	c7 04 24 82 85 10 80 	movl   $0x80108582,(%esp)
801042ee:	e8 cf e1 ff ff       	call   801024c2 <namei>
801042f3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042f6:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801042f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042fc:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104303:	c9                   	leave  
80104304:	c3                   	ret    

80104305 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104305:	55                   	push   %ebp
80104306:	89 e5                	mov    %esp,%ebp
80104308:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010430b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104311:	8b 00                	mov    (%eax),%eax
80104313:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104316:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010431a:	7e 34                	jle    80104350 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
8010431c:	8b 45 08             	mov    0x8(%ebp),%eax
8010431f:	89 c2                	mov    %eax,%edx
80104321:	03 55 f4             	add    -0xc(%ebp),%edx
80104324:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010432a:	8b 40 04             	mov    0x4(%eax),%eax
8010432d:	89 54 24 08          	mov    %edx,0x8(%esp)
80104331:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104334:	89 54 24 04          	mov    %edx,0x4(%esp)
80104338:	89 04 24             	mov    %eax,(%esp)
8010433b:	e8 93 3a 00 00       	call   80107dd3 <allocuvm>
80104340:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104343:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104347:	75 41                	jne    8010438a <growproc+0x85>
      return -1;
80104349:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010434e:	eb 58                	jmp    801043a8 <growproc+0xa3>
  } else if(n < 0){
80104350:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104354:	79 34                	jns    8010438a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104356:	8b 45 08             	mov    0x8(%ebp),%eax
80104359:	89 c2                	mov    %eax,%edx
8010435b:	03 55 f4             	add    -0xc(%ebp),%edx
8010435e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104364:	8b 40 04             	mov    0x4(%eax),%eax
80104367:	89 54 24 08          	mov    %edx,0x8(%esp)
8010436b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010436e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104372:	89 04 24             	mov    %eax,(%esp)
80104375:	e8 33 3b 00 00       	call   80107ead <deallocuvm>
8010437a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010437d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104381:	75 07                	jne    8010438a <growproc+0x85>
      return -1;
80104383:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104388:	eb 1e                	jmp    801043a8 <growproc+0xa3>
  }
  proc->sz = sz;
8010438a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104390:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104393:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104395:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010439b:	89 04 24             	mov    %eax,(%esp)
8010439e:	e8 4f 37 00 00       	call   80107af2 <switchuvm>
  return 0;
801043a3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043a8:	c9                   	leave  
801043a9:	c3                   	ret    

801043aa <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801043aa:	55                   	push   %ebp
801043ab:	89 e5                	mov    %esp,%ebp
801043ad:	57                   	push   %edi
801043ae:	56                   	push   %esi
801043af:	53                   	push   %ebx
801043b0:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801043b3:	e8 27 fd ff ff       	call   801040df <allocproc>
801043b8:	89 45 e0             	mov    %eax,-0x20(%ebp)
801043bb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801043bf:	75 0a                	jne    801043cb <fork+0x21>
    return -1;
801043c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043c6:	e9 3a 01 00 00       	jmp    80104505 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801043cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d1:	8b 10                	mov    (%eax),%edx
801043d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d9:	8b 40 04             	mov    0x4(%eax),%eax
801043dc:	89 54 24 04          	mov    %edx,0x4(%esp)
801043e0:	89 04 24             	mov    %eax,(%esp)
801043e3:	e8 55 3c 00 00       	call   8010803d <copyuvm>
801043e8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801043eb:	89 42 04             	mov    %eax,0x4(%edx)
801043ee:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043f1:	8b 40 04             	mov    0x4(%eax),%eax
801043f4:	85 c0                	test   %eax,%eax
801043f6:	75 2c                	jne    80104424 <fork+0x7a>
    kfree(np->kstack);
801043f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043fb:	8b 40 08             	mov    0x8(%eax),%eax
801043fe:	89 04 24             	mov    %eax,(%esp)
80104401:	e8 18 e7 ff ff       	call   80102b1e <kfree>
    np->kstack = 0;
80104406:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104409:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104410:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104413:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010441a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010441f:	e9 e1 00 00 00       	jmp    80104505 <fork+0x15b>
  }
  np->sz = proc->sz;
80104424:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010442a:	8b 10                	mov    (%eax),%edx
8010442c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010442f:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104431:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104438:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010443b:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
8010443e:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104441:	8b 50 18             	mov    0x18(%eax),%edx
80104444:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010444a:	8b 40 18             	mov    0x18(%eax),%eax
8010444d:	89 c3                	mov    %eax,%ebx
8010444f:	b8 13 00 00 00       	mov    $0x13,%eax
80104454:	89 d7                	mov    %edx,%edi
80104456:	89 de                	mov    %ebx,%esi
80104458:	89 c1                	mov    %eax,%ecx
8010445a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
8010445c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010445f:	8b 40 18             	mov    0x18(%eax),%eax
80104462:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104469:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104470:	eb 3d                	jmp    801044af <fork+0x105>
    if(proc->ofile[i])
80104472:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104478:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010447b:	83 c2 08             	add    $0x8,%edx
8010447e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104482:	85 c0                	test   %eax,%eax
80104484:	74 25                	je     801044ab <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104486:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010448c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010448f:	83 c2 08             	add    $0x8,%edx
80104492:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104496:	89 04 24             	mov    %eax,(%esp)
80104499:	e8 96 cb ff ff       	call   80101034 <filedup>
8010449e:	8b 55 e0             	mov    -0x20(%ebp),%edx
801044a1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801044a4:	83 c1 08             	add    $0x8,%ecx
801044a7:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801044ab:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801044af:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801044b3:	7e bd                	jle    80104472 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801044b5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044bb:	8b 40 68             	mov    0x68(%eax),%eax
801044be:	89 04 24             	mov    %eax,(%esp)
801044c1:	e8 28 d4 ff ff       	call   801018ee <idup>
801044c6:	8b 55 e0             	mov    -0x20(%ebp),%edx
801044c9:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801044cc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044cf:	8b 40 10             	mov    0x10(%eax),%eax
801044d2:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801044d5:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044d8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801044df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044e5:	8d 50 6c             	lea    0x6c(%eax),%edx
801044e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044eb:	83 c0 6c             	add    $0x6c,%eax
801044ee:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801044f5:	00 
801044f6:	89 54 24 04          	mov    %edx,0x4(%esp)
801044fa:	89 04 24             	mov    %eax,(%esp)
801044fd:	e8 d8 0b 00 00       	call   801050da <safestrcpy>
  return pid;
80104502:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104505:	83 c4 2c             	add    $0x2c,%esp
80104508:	5b                   	pop    %ebx
80104509:	5e                   	pop    %esi
8010450a:	5f                   	pop    %edi
8010450b:	5d                   	pop    %ebp
8010450c:	c3                   	ret    

8010450d <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010450d:	55                   	push   %ebp
8010450e:	89 e5                	mov    %esp,%ebp
80104510:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104513:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010451a:	a1 48 b6 10 80       	mov    0x8010b648,%eax
8010451f:	39 c2                	cmp    %eax,%edx
80104521:	75 0c                	jne    8010452f <exit+0x22>
    panic("init exiting");
80104523:	c7 04 24 84 85 10 80 	movl   $0x80108584,(%esp)
8010452a:	e8 0e c0 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010452f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104536:	eb 44                	jmp    8010457c <exit+0x6f>
    if(proc->ofile[fd]){
80104538:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010453e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104541:	83 c2 08             	add    $0x8,%edx
80104544:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104548:	85 c0                	test   %eax,%eax
8010454a:	74 2c                	je     80104578 <exit+0x6b>
      fileclose(proc->ofile[fd]);
8010454c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104552:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104555:	83 c2 08             	add    $0x8,%edx
80104558:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010455c:	89 04 24             	mov    %eax,(%esp)
8010455f:	e8 18 cb ff ff       	call   8010107c <fileclose>
      proc->ofile[fd] = 0;
80104564:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010456a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010456d:	83 c2 08             	add    $0x8,%edx
80104570:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104577:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104578:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
8010457c:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104580:	7e b6                	jle    80104538 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104582:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104588:	8b 40 68             	mov    0x68(%eax),%eax
8010458b:	89 04 24             	mov    %eax,(%esp)
8010458e:	e8 40 d5 ff ff       	call   80101ad3 <iput>
  proc->cwd = 0;
80104593:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104599:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801045a0:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801045a7:	e8 af 06 00 00       	call   80104c5b <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801045ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045b2:	8b 40 14             	mov    0x14(%eax),%eax
801045b5:	89 04 24             	mov    %eax,(%esp)
801045b8:	e8 5b 04 00 00       	call   80104a18 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045bd:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
801045c4:	eb 38                	jmp    801045fe <exit+0xf1>
    if(p->parent == proc){
801045c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045c9:	8b 50 14             	mov    0x14(%eax),%edx
801045cc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045d2:	39 c2                	cmp    %eax,%edx
801045d4:	75 24                	jne    801045fa <exit+0xed>
      p->parent = initproc;
801045d6:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
801045dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045df:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801045e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e5:	8b 40 0c             	mov    0xc(%eax),%eax
801045e8:	83 f8 05             	cmp    $0x5,%eax
801045eb:	75 0d                	jne    801045fa <exit+0xed>
        wakeup1(initproc);
801045ed:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801045f2:	89 04 24             	mov    %eax,(%esp)
801045f5:	e8 1e 04 00 00       	call   80104a18 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045fa:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801045fe:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
80104605:	72 bf                	jb     801045c6 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104607:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010460d:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104614:	e8 54 02 00 00       	call   8010486d <sched>
  panic("zombie exit");
80104619:	c7 04 24 91 85 10 80 	movl   $0x80108591,(%esp)
80104620:	e8 18 bf ff ff       	call   8010053d <panic>

80104625 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104625:	55                   	push   %ebp
80104626:	89 e5                	mov    %esp,%ebp
80104628:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010462b:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104632:	e8 24 06 00 00       	call   80104c5b <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104637:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010463e:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
80104645:	e9 9a 00 00 00       	jmp    801046e4 <wait+0xbf>
      if(p->parent != proc)
8010464a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010464d:	8b 50 14             	mov    0x14(%eax),%edx
80104650:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104656:	39 c2                	cmp    %eax,%edx
80104658:	0f 85 81 00 00 00    	jne    801046df <wait+0xba>
        continue;
      havekids = 1;
8010465e:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104665:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104668:	8b 40 0c             	mov    0xc(%eax),%eax
8010466b:	83 f8 05             	cmp    $0x5,%eax
8010466e:	75 70                	jne    801046e0 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104670:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104673:	8b 40 10             	mov    0x10(%eax),%eax
80104676:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104679:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010467c:	8b 40 08             	mov    0x8(%eax),%eax
8010467f:	89 04 24             	mov    %eax,(%esp)
80104682:	e8 97 e4 ff ff       	call   80102b1e <kfree>
        p->kstack = 0;
80104687:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010468a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104691:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104694:	8b 40 04             	mov    0x4(%eax),%eax
80104697:	89 04 24             	mov    %eax,(%esp)
8010469a:	e8 ca 38 00 00       	call   80107f69 <freevm>
        p->state = UNUSED;
8010469f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046a2:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801046a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046ac:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801046b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046b6:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801046bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046c0:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801046c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046c7:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801046ce:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801046d5:	e8 e3 05 00 00       	call   80104cbd <release>
        return pid;
801046da:	8b 45 ec             	mov    -0x14(%ebp),%eax
801046dd:	eb 53                	jmp    80104732 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801046df:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801046e0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801046e4:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
801046eb:	0f 82 59 ff ff ff    	jb     8010464a <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801046f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801046f5:	74 0d                	je     80104704 <wait+0xdf>
801046f7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801046fd:	8b 40 24             	mov    0x24(%eax),%eax
80104700:	85 c0                	test   %eax,%eax
80104702:	74 13                	je     80104717 <wait+0xf2>
      release(&ptable.lock);
80104704:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010470b:	e8 ad 05 00 00       	call   80104cbd <release>
      return -1;
80104710:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104715:	eb 1b                	jmp    80104732 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104717:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010471d:	c7 44 24 04 20 04 11 	movl   $0x80110420,0x4(%esp)
80104724:	80 
80104725:	89 04 24             	mov    %eax,(%esp)
80104728:	e8 50 02 00 00       	call   8010497d <sleep>
  }
8010472d:	e9 05 ff ff ff       	jmp    80104637 <wait+0x12>
}
80104732:	c9                   	leave  
80104733:	c3                   	ret    

80104734 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80104734:	55                   	push   %ebp
80104735:	89 e5                	mov    %esp,%ebp
80104737:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
8010473a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104740:	8b 40 18             	mov    0x18(%eax),%eax
80104743:	8b 40 44             	mov    0x44(%eax),%eax
80104746:	89 c2                	mov    %eax,%edx
80104748:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010474e:	8b 40 04             	mov    0x4(%eax),%eax
80104751:	89 54 24 04          	mov    %edx,0x4(%esp)
80104755:	89 04 24             	mov    %eax,(%esp)
80104758:	e8 f1 39 00 00       	call   8010814e <uva2ka>
8010475d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104760:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104766:	8b 40 18             	mov    0x18(%eax),%eax
80104769:	8b 40 44             	mov    0x44(%eax),%eax
8010476c:	25 ff 0f 00 00       	and    $0xfff,%eax
80104771:	85 c0                	test   %eax,%eax
80104773:	75 0c                	jne    80104781 <register_handler+0x4d>
    panic("esp_offset == 0");
80104775:	c7 04 24 9d 85 10 80 	movl   $0x8010859d,(%esp)
8010477c:	e8 bc bd ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104781:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104787:	8b 40 18             	mov    0x18(%eax),%eax
8010478a:	8b 40 44             	mov    0x44(%eax),%eax
8010478d:	83 e8 04             	sub    $0x4,%eax
80104790:	25 ff 0f 00 00       	and    $0xfff,%eax
80104795:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80104798:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010479f:	8b 52 18             	mov    0x18(%edx),%edx
801047a2:	8b 52 38             	mov    0x38(%edx),%edx
801047a5:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
801047a7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047ad:	8b 40 18             	mov    0x18(%eax),%eax
801047b0:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047b7:	8b 52 18             	mov    0x18(%edx),%edx
801047ba:	8b 52 44             	mov    0x44(%edx),%edx
801047bd:	83 ea 04             	sub    $0x4,%edx
801047c0:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801047c3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047c9:	8b 40 18             	mov    0x18(%eax),%eax
801047cc:	8b 55 08             	mov    0x8(%ebp),%edx
801047cf:	89 50 38             	mov    %edx,0x38(%eax)
}
801047d2:	c9                   	leave  
801047d3:	c3                   	ret    

801047d4 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801047d4:	55                   	push   %ebp
801047d5:	89 e5                	mov    %esp,%ebp
801047d7:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801047da:	e8 de f8 ff ff       	call   801040bd <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801047df:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801047e6:	e8 70 04 00 00       	call   80104c5b <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047eb:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
801047f2:	eb 5f                	jmp    80104853 <scheduler+0x7f>
      if(p->state != RUNNABLE)
801047f4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047f7:	8b 40 0c             	mov    0xc(%eax),%eax
801047fa:	83 f8 03             	cmp    $0x3,%eax
801047fd:	75 4f                	jne    8010484e <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
801047ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104802:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104808:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010480b:	89 04 24             	mov    %eax,(%esp)
8010480e:	e8 df 32 00 00       	call   80107af2 <switchuvm>
      p->state = RUNNING;
80104813:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104816:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
8010481d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104823:	8b 40 1c             	mov    0x1c(%eax),%eax
80104826:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010482d:	83 c2 04             	add    $0x4,%edx
80104830:	89 44 24 04          	mov    %eax,0x4(%esp)
80104834:	89 14 24             	mov    %edx,(%esp)
80104837:	e8 14 09 00 00       	call   80105150 <swtch>
      switchkvm();
8010483c:	e8 94 32 00 00       	call   80107ad5 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104841:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104848:	00 00 00 00 
8010484c:	eb 01                	jmp    8010484f <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
8010484e:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010484f:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104853:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
8010485a:	72 98                	jb     801047f4 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
8010485c:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104863:	e8 55 04 00 00       	call   80104cbd <release>

  }
80104868:	e9 6d ff ff ff       	jmp    801047da <scheduler+0x6>

8010486d <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
8010486d:	55                   	push   %ebp
8010486e:	89 e5                	mov    %esp,%ebp
80104870:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104873:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010487a:	e8 fa 04 00 00       	call   80104d79 <holding>
8010487f:	85 c0                	test   %eax,%eax
80104881:	75 0c                	jne    8010488f <sched+0x22>
    panic("sched ptable.lock");
80104883:	c7 04 24 ad 85 10 80 	movl   $0x801085ad,(%esp)
8010488a:	e8 ae bc ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
8010488f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104895:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010489b:	83 f8 01             	cmp    $0x1,%eax
8010489e:	74 0c                	je     801048ac <sched+0x3f>
    panic("sched locks");
801048a0:	c7 04 24 bf 85 10 80 	movl   $0x801085bf,(%esp)
801048a7:	e8 91 bc ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
801048ac:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048b2:	8b 40 0c             	mov    0xc(%eax),%eax
801048b5:	83 f8 04             	cmp    $0x4,%eax
801048b8:	75 0c                	jne    801048c6 <sched+0x59>
    panic("sched running");
801048ba:	c7 04 24 cb 85 10 80 	movl   $0x801085cb,(%esp)
801048c1:	e8 77 bc ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
801048c6:	e8 dd f7 ff ff       	call   801040a8 <readeflags>
801048cb:	25 00 02 00 00       	and    $0x200,%eax
801048d0:	85 c0                	test   %eax,%eax
801048d2:	74 0c                	je     801048e0 <sched+0x73>
    panic("sched interruptible");
801048d4:	c7 04 24 d9 85 10 80 	movl   $0x801085d9,(%esp)
801048db:	e8 5d bc ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801048e0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801048e6:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801048ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801048ef:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801048f5:	8b 40 04             	mov    0x4(%eax),%eax
801048f8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801048ff:	83 c2 1c             	add    $0x1c,%edx
80104902:	89 44 24 04          	mov    %eax,0x4(%esp)
80104906:	89 14 24             	mov    %edx,(%esp)
80104909:	e8 42 08 00 00       	call   80105150 <swtch>
  cpu->intena = intena;
8010490e:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104914:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104917:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
8010491d:	c9                   	leave  
8010491e:	c3                   	ret    

8010491f <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
8010491f:	55                   	push   %ebp
80104920:	89 e5                	mov    %esp,%ebp
80104922:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104925:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010492c:	e8 2a 03 00 00       	call   80104c5b <acquire>
  proc->state = RUNNABLE;
80104931:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104937:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
8010493e:	e8 2a ff ff ff       	call   8010486d <sched>
  release(&ptable.lock);
80104943:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010494a:	e8 6e 03 00 00       	call   80104cbd <release>
}
8010494f:	c9                   	leave  
80104950:	c3                   	ret    

80104951 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104951:	55                   	push   %ebp
80104952:	89 e5                	mov    %esp,%ebp
80104954:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104957:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010495e:	e8 5a 03 00 00       	call   80104cbd <release>

  if (first) {
80104963:	a1 20 b0 10 80       	mov    0x8010b020,%eax
80104968:	85 c0                	test   %eax,%eax
8010496a:	74 0f                	je     8010497b <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
8010496c:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
80104973:	00 00 00 
    initlog();
80104976:	e8 4d e7 ff ff       	call   801030c8 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010497b:	c9                   	leave  
8010497c:	c3                   	ret    

8010497d <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
8010497d:	55                   	push   %ebp
8010497e:	89 e5                	mov    %esp,%ebp
80104980:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104983:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104989:	85 c0                	test   %eax,%eax
8010498b:	75 0c                	jne    80104999 <sleep+0x1c>
    panic("sleep");
8010498d:	c7 04 24 ed 85 10 80 	movl   $0x801085ed,(%esp)
80104994:	e8 a4 bb ff ff       	call   8010053d <panic>

  if(lk == 0)
80104999:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010499d:	75 0c                	jne    801049ab <sleep+0x2e>
    panic("sleep without lk");
8010499f:	c7 04 24 f3 85 10 80 	movl   $0x801085f3,(%esp)
801049a6:	e8 92 bb ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801049ab:	81 7d 0c 20 04 11 80 	cmpl   $0x80110420,0xc(%ebp)
801049b2:	74 17                	je     801049cb <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801049b4:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801049bb:	e8 9b 02 00 00       	call   80104c5b <acquire>
    release(lk);
801049c0:	8b 45 0c             	mov    0xc(%ebp),%eax
801049c3:	89 04 24             	mov    %eax,(%esp)
801049c6:	e8 f2 02 00 00       	call   80104cbd <release>
  }

  // Go to sleep.
  proc->chan = chan;
801049cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049d1:	8b 55 08             	mov    0x8(%ebp),%edx
801049d4:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801049d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049dd:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801049e4:	e8 84 fe ff ff       	call   8010486d <sched>

  // Tidy up.
  proc->chan = 0;
801049e9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ef:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801049f6:	81 7d 0c 20 04 11 80 	cmpl   $0x80110420,0xc(%ebp)
801049fd:	74 17                	je     80104a16 <sleep+0x99>
    release(&ptable.lock);
801049ff:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a06:	e8 b2 02 00 00       	call   80104cbd <release>
    acquire(lk);
80104a0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a0e:	89 04 24             	mov    %eax,(%esp)
80104a11:	e8 45 02 00 00       	call   80104c5b <acquire>
  }
}
80104a16:	c9                   	leave  
80104a17:	c3                   	ret    

80104a18 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104a18:	55                   	push   %ebp
80104a19:	89 e5                	mov    %esp,%ebp
80104a1b:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a1e:	c7 45 fc 54 04 11 80 	movl   $0x80110454,-0x4(%ebp)
80104a25:	eb 24                	jmp    80104a4b <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104a27:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a2a:	8b 40 0c             	mov    0xc(%eax),%eax
80104a2d:	83 f8 02             	cmp    $0x2,%eax
80104a30:	75 15                	jne    80104a47 <wakeup1+0x2f>
80104a32:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a35:	8b 40 20             	mov    0x20(%eax),%eax
80104a38:	3b 45 08             	cmp    0x8(%ebp),%eax
80104a3b:	75 0a                	jne    80104a47 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104a3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a40:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a47:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104a4b:	81 7d fc 54 23 11 80 	cmpl   $0x80112354,-0x4(%ebp)
80104a52:	72 d3                	jb     80104a27 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104a54:	c9                   	leave  
80104a55:	c3                   	ret    

80104a56 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104a56:	55                   	push   %ebp
80104a57:	89 e5                	mov    %esp,%ebp
80104a59:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104a5c:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a63:	e8 f3 01 00 00       	call   80104c5b <acquire>
  wakeup1(chan);
80104a68:	8b 45 08             	mov    0x8(%ebp),%eax
80104a6b:	89 04 24             	mov    %eax,(%esp)
80104a6e:	e8 a5 ff ff ff       	call   80104a18 <wakeup1>
  release(&ptable.lock);
80104a73:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a7a:	e8 3e 02 00 00       	call   80104cbd <release>
}
80104a7f:	c9                   	leave  
80104a80:	c3                   	ret    

80104a81 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104a81:	55                   	push   %ebp
80104a82:	89 e5                	mov    %esp,%ebp
80104a84:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104a87:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a8e:	e8 c8 01 00 00       	call   80104c5b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a93:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
80104a9a:	eb 41                	jmp    80104add <kill+0x5c>
    if(p->pid == pid){
80104a9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a9f:	8b 40 10             	mov    0x10(%eax),%eax
80104aa2:	3b 45 08             	cmp    0x8(%ebp),%eax
80104aa5:	75 32                	jne    80104ad9 <kill+0x58>
      p->killed = 1;
80104aa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aaa:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab4:	8b 40 0c             	mov    0xc(%eax),%eax
80104ab7:	83 f8 02             	cmp    $0x2,%eax
80104aba:	75 0a                	jne    80104ac6 <kill+0x45>
        p->state = RUNNABLE;
80104abc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104abf:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104ac6:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104acd:	e8 eb 01 00 00       	call   80104cbd <release>
      return 0;
80104ad2:	b8 00 00 00 00       	mov    $0x0,%eax
80104ad7:	eb 1e                	jmp    80104af7 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ad9:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104add:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
80104ae4:	72 b6                	jb     80104a9c <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104ae6:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104aed:	e8 cb 01 00 00       	call   80104cbd <release>
  return -1;
80104af2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104af7:	c9                   	leave  
80104af8:	c3                   	ret    

80104af9 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104af9:	55                   	push   %ebp
80104afa:	89 e5                	mov    %esp,%ebp
80104afc:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104aff:	c7 45 f0 54 04 11 80 	movl   $0x80110454,-0x10(%ebp)
80104b06:	e9 d8 00 00 00       	jmp    80104be3 <procdump+0xea>
    if(p->state == UNUSED)
80104b0b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b0e:	8b 40 0c             	mov    0xc(%eax),%eax
80104b11:	85 c0                	test   %eax,%eax
80104b13:	0f 84 c5 00 00 00    	je     80104bde <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104b19:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b1c:	8b 40 0c             	mov    0xc(%eax),%eax
80104b1f:	83 f8 05             	cmp    $0x5,%eax
80104b22:	77 23                	ja     80104b47 <procdump+0x4e>
80104b24:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b27:	8b 40 0c             	mov    0xc(%eax),%eax
80104b2a:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104b31:	85 c0                	test   %eax,%eax
80104b33:	74 12                	je     80104b47 <procdump+0x4e>
      state = states[p->state];
80104b35:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b38:	8b 40 0c             	mov    0xc(%eax),%eax
80104b3b:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104b42:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104b45:	eb 07                	jmp    80104b4e <procdump+0x55>
    else
      state = "???";
80104b47:	c7 45 ec 04 86 10 80 	movl   $0x80108604,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104b4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b51:	8d 50 6c             	lea    0x6c(%eax),%edx
80104b54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b57:	8b 40 10             	mov    0x10(%eax),%eax
80104b5a:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104b5e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104b61:	89 54 24 08          	mov    %edx,0x8(%esp)
80104b65:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b69:	c7 04 24 08 86 10 80 	movl   $0x80108608,(%esp)
80104b70:	e8 2c b8 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104b75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b78:	8b 40 0c             	mov    0xc(%eax),%eax
80104b7b:	83 f8 02             	cmp    $0x2,%eax
80104b7e:	75 50                	jne    80104bd0 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104b80:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b83:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b86:	8b 40 0c             	mov    0xc(%eax),%eax
80104b89:	83 c0 08             	add    $0x8,%eax
80104b8c:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104b8f:	89 54 24 04          	mov    %edx,0x4(%esp)
80104b93:	89 04 24             	mov    %eax,(%esp)
80104b96:	e8 71 01 00 00       	call   80104d0c <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104b9b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104ba2:	eb 1b                	jmp    80104bbf <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104ba4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba7:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104bab:	89 44 24 04          	mov    %eax,0x4(%esp)
80104baf:	c7 04 24 11 86 10 80 	movl   $0x80108611,(%esp)
80104bb6:	e8 e6 b7 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104bbb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104bbf:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104bc3:	7f 0b                	jg     80104bd0 <procdump+0xd7>
80104bc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bc8:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104bcc:	85 c0                	test   %eax,%eax
80104bce:	75 d4                	jne    80104ba4 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104bd0:	c7 04 24 15 86 10 80 	movl   $0x80108615,(%esp)
80104bd7:	e8 c5 b7 ff ff       	call   801003a1 <cprintf>
80104bdc:	eb 01                	jmp    80104bdf <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104bde:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bdf:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104be3:	81 7d f0 54 23 11 80 	cmpl   $0x80112354,-0x10(%ebp)
80104bea:	0f 82 1b ff ff ff    	jb     80104b0b <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104bf0:	c9                   	leave  
80104bf1:	c3                   	ret    
	...

80104bf4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104bf4:	55                   	push   %ebp
80104bf5:	89 e5                	mov    %esp,%ebp
80104bf7:	53                   	push   %ebx
80104bf8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104bfb:	9c                   	pushf  
80104bfc:	5b                   	pop    %ebx
80104bfd:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104c00:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104c03:	83 c4 10             	add    $0x10,%esp
80104c06:	5b                   	pop    %ebx
80104c07:	5d                   	pop    %ebp
80104c08:	c3                   	ret    

80104c09 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104c09:	55                   	push   %ebp
80104c0a:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104c0c:	fa                   	cli    
}
80104c0d:	5d                   	pop    %ebp
80104c0e:	c3                   	ret    

80104c0f <sti>:

static inline void
sti(void)
{
80104c0f:	55                   	push   %ebp
80104c10:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104c12:	fb                   	sti    
}
80104c13:	5d                   	pop    %ebp
80104c14:	c3                   	ret    

80104c15 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104c15:	55                   	push   %ebp
80104c16:	89 e5                	mov    %esp,%ebp
80104c18:	53                   	push   %ebx
80104c19:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104c1c:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104c1f:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104c22:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104c25:	89 c3                	mov    %eax,%ebx
80104c27:	89 d8                	mov    %ebx,%eax
80104c29:	f0 87 02             	lock xchg %eax,(%edx)
80104c2c:	89 c3                	mov    %eax,%ebx
80104c2e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104c31:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104c34:	83 c4 10             	add    $0x10,%esp
80104c37:	5b                   	pop    %ebx
80104c38:	5d                   	pop    %ebp
80104c39:	c3                   	ret    

80104c3a <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104c3a:	55                   	push   %ebp
80104c3b:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104c3d:	8b 45 08             	mov    0x8(%ebp),%eax
80104c40:	8b 55 0c             	mov    0xc(%ebp),%edx
80104c43:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104c46:	8b 45 08             	mov    0x8(%ebp),%eax
80104c49:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104c4f:	8b 45 08             	mov    0x8(%ebp),%eax
80104c52:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104c59:	5d                   	pop    %ebp
80104c5a:	c3                   	ret    

80104c5b <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104c5b:	55                   	push   %ebp
80104c5c:	89 e5                	mov    %esp,%ebp
80104c5e:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104c61:	e8 3d 01 00 00       	call   80104da3 <pushcli>
  if(holding(lk))
80104c66:	8b 45 08             	mov    0x8(%ebp),%eax
80104c69:	89 04 24             	mov    %eax,(%esp)
80104c6c:	e8 08 01 00 00       	call   80104d79 <holding>
80104c71:	85 c0                	test   %eax,%eax
80104c73:	74 0c                	je     80104c81 <acquire+0x26>
    panic("acquire");
80104c75:	c7 04 24 41 86 10 80 	movl   $0x80108641,(%esp)
80104c7c:	e8 bc b8 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104c81:	90                   	nop
80104c82:	8b 45 08             	mov    0x8(%ebp),%eax
80104c85:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104c8c:	00 
80104c8d:	89 04 24             	mov    %eax,(%esp)
80104c90:	e8 80 ff ff ff       	call   80104c15 <xchg>
80104c95:	85 c0                	test   %eax,%eax
80104c97:	75 e9                	jne    80104c82 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104c99:	8b 45 08             	mov    0x8(%ebp),%eax
80104c9c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104ca3:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104ca6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ca9:	83 c0 0c             	add    $0xc,%eax
80104cac:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cb0:	8d 45 08             	lea    0x8(%ebp),%eax
80104cb3:	89 04 24             	mov    %eax,(%esp)
80104cb6:	e8 51 00 00 00       	call   80104d0c <getcallerpcs>
}
80104cbb:	c9                   	leave  
80104cbc:	c3                   	ret    

80104cbd <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104cbd:	55                   	push   %ebp
80104cbe:	89 e5                	mov    %esp,%ebp
80104cc0:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80104cc6:	89 04 24             	mov    %eax,(%esp)
80104cc9:	e8 ab 00 00 00       	call   80104d79 <holding>
80104cce:	85 c0                	test   %eax,%eax
80104cd0:	75 0c                	jne    80104cde <release+0x21>
    panic("release");
80104cd2:	c7 04 24 49 86 10 80 	movl   $0x80108649,(%esp)
80104cd9:	e8 5f b8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80104cde:	8b 45 08             	mov    0x8(%ebp),%eax
80104ce1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104ce8:	8b 45 08             	mov    0x8(%ebp),%eax
80104ceb:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104cf2:	8b 45 08             	mov    0x8(%ebp),%eax
80104cf5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104cfc:	00 
80104cfd:	89 04 24             	mov    %eax,(%esp)
80104d00:	e8 10 ff ff ff       	call   80104c15 <xchg>

  popcli();
80104d05:	e8 e1 00 00 00       	call   80104deb <popcli>
}
80104d0a:	c9                   	leave  
80104d0b:	c3                   	ret    

80104d0c <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104d0c:	55                   	push   %ebp
80104d0d:	89 e5                	mov    %esp,%ebp
80104d0f:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104d12:	8b 45 08             	mov    0x8(%ebp),%eax
80104d15:	83 e8 08             	sub    $0x8,%eax
80104d18:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104d1b:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104d22:	eb 32                	jmp    80104d56 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104d24:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104d28:	74 47                	je     80104d71 <getcallerpcs+0x65>
80104d2a:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104d31:	76 3e                	jbe    80104d71 <getcallerpcs+0x65>
80104d33:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104d37:	74 38                	je     80104d71 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104d39:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104d3c:	c1 e0 02             	shl    $0x2,%eax
80104d3f:	03 45 0c             	add    0xc(%ebp),%eax
80104d42:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104d45:	8b 52 04             	mov    0x4(%edx),%edx
80104d48:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80104d4a:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d4d:	8b 00                	mov    (%eax),%eax
80104d4f:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104d52:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104d56:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104d5a:	7e c8                	jle    80104d24 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104d5c:	eb 13                	jmp    80104d71 <getcallerpcs+0x65>
    pcs[i] = 0;
80104d5e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104d61:	c1 e0 02             	shl    $0x2,%eax
80104d64:	03 45 0c             	add    0xc(%ebp),%eax
80104d67:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104d6d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104d71:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104d75:	7e e7                	jle    80104d5e <getcallerpcs+0x52>
    pcs[i] = 0;
}
80104d77:	c9                   	leave  
80104d78:	c3                   	ret    

80104d79 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104d79:	55                   	push   %ebp
80104d7a:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104d7c:	8b 45 08             	mov    0x8(%ebp),%eax
80104d7f:	8b 00                	mov    (%eax),%eax
80104d81:	85 c0                	test   %eax,%eax
80104d83:	74 17                	je     80104d9c <holding+0x23>
80104d85:	8b 45 08             	mov    0x8(%ebp),%eax
80104d88:	8b 50 08             	mov    0x8(%eax),%edx
80104d8b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d91:	39 c2                	cmp    %eax,%edx
80104d93:	75 07                	jne    80104d9c <holding+0x23>
80104d95:	b8 01 00 00 00       	mov    $0x1,%eax
80104d9a:	eb 05                	jmp    80104da1 <holding+0x28>
80104d9c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104da1:	5d                   	pop    %ebp
80104da2:	c3                   	ret    

80104da3 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104da3:	55                   	push   %ebp
80104da4:	89 e5                	mov    %esp,%ebp
80104da6:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104da9:	e8 46 fe ff ff       	call   80104bf4 <readeflags>
80104dae:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104db1:	e8 53 fe ff ff       	call   80104c09 <cli>
  if(cpu->ncli++ == 0)
80104db6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dbc:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104dc2:	85 d2                	test   %edx,%edx
80104dc4:	0f 94 c1             	sete   %cl
80104dc7:	83 c2 01             	add    $0x1,%edx
80104dca:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104dd0:	84 c9                	test   %cl,%cl
80104dd2:	74 15                	je     80104de9 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104dd4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dda:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104ddd:	81 e2 00 02 00 00    	and    $0x200,%edx
80104de3:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104de9:	c9                   	leave  
80104dea:	c3                   	ret    

80104deb <popcli>:

void
popcli(void)
{
80104deb:	55                   	push   %ebp
80104dec:	89 e5                	mov    %esp,%ebp
80104dee:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104df1:	e8 fe fd ff ff       	call   80104bf4 <readeflags>
80104df6:	25 00 02 00 00       	and    $0x200,%eax
80104dfb:	85 c0                	test   %eax,%eax
80104dfd:	74 0c                	je     80104e0b <popcli+0x20>
    panic("popcli - interruptible");
80104dff:	c7 04 24 51 86 10 80 	movl   $0x80108651,(%esp)
80104e06:	e8 32 b7 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80104e0b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e11:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104e17:	83 ea 01             	sub    $0x1,%edx
80104e1a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104e20:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104e26:	85 c0                	test   %eax,%eax
80104e28:	79 0c                	jns    80104e36 <popcli+0x4b>
    panic("popcli");
80104e2a:	c7 04 24 68 86 10 80 	movl   $0x80108668,(%esp)
80104e31:	e8 07 b7 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104e36:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e3c:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104e42:	85 c0                	test   %eax,%eax
80104e44:	75 15                	jne    80104e5b <popcli+0x70>
80104e46:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e4c:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104e52:	85 c0                	test   %eax,%eax
80104e54:	74 05                	je     80104e5b <popcli+0x70>
    sti();
80104e56:	e8 b4 fd ff ff       	call   80104c0f <sti>
}
80104e5b:	c9                   	leave  
80104e5c:	c3                   	ret    
80104e5d:	00 00                	add    %al,(%eax)
	...

80104e60 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104e60:	55                   	push   %ebp
80104e61:	89 e5                	mov    %esp,%ebp
80104e63:	57                   	push   %edi
80104e64:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104e65:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e68:	8b 55 10             	mov    0x10(%ebp),%edx
80104e6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e6e:	89 cb                	mov    %ecx,%ebx
80104e70:	89 df                	mov    %ebx,%edi
80104e72:	89 d1                	mov    %edx,%ecx
80104e74:	fc                   	cld    
80104e75:	f3 aa                	rep stos %al,%es:(%edi)
80104e77:	89 ca                	mov    %ecx,%edx
80104e79:	89 fb                	mov    %edi,%ebx
80104e7b:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104e7e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104e81:	5b                   	pop    %ebx
80104e82:	5f                   	pop    %edi
80104e83:	5d                   	pop    %ebp
80104e84:	c3                   	ret    

80104e85 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104e85:	55                   	push   %ebp
80104e86:	89 e5                	mov    %esp,%ebp
80104e88:	57                   	push   %edi
80104e89:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104e8a:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e8d:	8b 55 10             	mov    0x10(%ebp),%edx
80104e90:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e93:	89 cb                	mov    %ecx,%ebx
80104e95:	89 df                	mov    %ebx,%edi
80104e97:	89 d1                	mov    %edx,%ecx
80104e99:	fc                   	cld    
80104e9a:	f3 ab                	rep stos %eax,%es:(%edi)
80104e9c:	89 ca                	mov    %ecx,%edx
80104e9e:	89 fb                	mov    %edi,%ebx
80104ea0:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104ea3:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104ea6:	5b                   	pop    %ebx
80104ea7:	5f                   	pop    %edi
80104ea8:	5d                   	pop    %ebp
80104ea9:	c3                   	ret    

80104eaa <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104eaa:	55                   	push   %ebp
80104eab:	89 e5                	mov    %esp,%ebp
80104ead:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104eb0:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb3:	83 e0 03             	and    $0x3,%eax
80104eb6:	85 c0                	test   %eax,%eax
80104eb8:	75 49                	jne    80104f03 <memset+0x59>
80104eba:	8b 45 10             	mov    0x10(%ebp),%eax
80104ebd:	83 e0 03             	and    $0x3,%eax
80104ec0:	85 c0                	test   %eax,%eax
80104ec2:	75 3f                	jne    80104f03 <memset+0x59>
    c &= 0xFF;
80104ec4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104ecb:	8b 45 10             	mov    0x10(%ebp),%eax
80104ece:	c1 e8 02             	shr    $0x2,%eax
80104ed1:	89 c2                	mov    %eax,%edx
80104ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ed6:	89 c1                	mov    %eax,%ecx
80104ed8:	c1 e1 18             	shl    $0x18,%ecx
80104edb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ede:	c1 e0 10             	shl    $0x10,%eax
80104ee1:	09 c1                	or     %eax,%ecx
80104ee3:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ee6:	c1 e0 08             	shl    $0x8,%eax
80104ee9:	09 c8                	or     %ecx,%eax
80104eeb:	0b 45 0c             	or     0xc(%ebp),%eax
80104eee:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ef2:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ef6:	8b 45 08             	mov    0x8(%ebp),%eax
80104ef9:	89 04 24             	mov    %eax,(%esp)
80104efc:	e8 84 ff ff ff       	call   80104e85 <stosl>
80104f01:	eb 19                	jmp    80104f1c <memset+0x72>
  } else
    stosb(dst, c, n);
80104f03:	8b 45 10             	mov    0x10(%ebp),%eax
80104f06:	89 44 24 08          	mov    %eax,0x8(%esp)
80104f0a:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f0d:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f11:	8b 45 08             	mov    0x8(%ebp),%eax
80104f14:	89 04 24             	mov    %eax,(%esp)
80104f17:	e8 44 ff ff ff       	call   80104e60 <stosb>
  return dst;
80104f1c:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104f1f:	c9                   	leave  
80104f20:	c3                   	ret    

80104f21 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104f21:	55                   	push   %ebp
80104f22:	89 e5                	mov    %esp,%ebp
80104f24:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104f27:	8b 45 08             	mov    0x8(%ebp),%eax
80104f2a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80104f2d:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f30:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80104f33:	eb 32                	jmp    80104f67 <memcmp+0x46>
    if(*s1 != *s2)
80104f35:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f38:	0f b6 10             	movzbl (%eax),%edx
80104f3b:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f3e:	0f b6 00             	movzbl (%eax),%eax
80104f41:	38 c2                	cmp    %al,%dl
80104f43:	74 1a                	je     80104f5f <memcmp+0x3e>
      return *s1 - *s2;
80104f45:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f48:	0f b6 00             	movzbl (%eax),%eax
80104f4b:	0f b6 d0             	movzbl %al,%edx
80104f4e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f51:	0f b6 00             	movzbl (%eax),%eax
80104f54:	0f b6 c0             	movzbl %al,%eax
80104f57:	89 d1                	mov    %edx,%ecx
80104f59:	29 c1                	sub    %eax,%ecx
80104f5b:	89 c8                	mov    %ecx,%eax
80104f5d:	eb 1c                	jmp    80104f7b <memcmp+0x5a>
    s1++, s2++;
80104f5f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104f63:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104f67:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f6b:	0f 95 c0             	setne  %al
80104f6e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f72:	84 c0                	test   %al,%al
80104f74:	75 bf                	jne    80104f35 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80104f76:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f7b:	c9                   	leave  
80104f7c:	c3                   	ret    

80104f7d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104f7d:	55                   	push   %ebp
80104f7e:	89 e5                	mov    %esp,%ebp
80104f80:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80104f83:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f86:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80104f89:	8b 45 08             	mov    0x8(%ebp),%eax
80104f8c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80104f8f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f92:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104f95:	73 54                	jae    80104feb <memmove+0x6e>
80104f97:	8b 45 10             	mov    0x10(%ebp),%eax
80104f9a:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104f9d:	01 d0                	add    %edx,%eax
80104f9f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104fa2:	76 47                	jbe    80104feb <memmove+0x6e>
    s += n;
80104fa4:	8b 45 10             	mov    0x10(%ebp),%eax
80104fa7:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80104faa:	8b 45 10             	mov    0x10(%ebp),%eax
80104fad:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80104fb0:	eb 13                	jmp    80104fc5 <memmove+0x48>
      *--d = *--s;
80104fb2:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80104fb6:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80104fba:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fbd:	0f b6 10             	movzbl (%eax),%edx
80104fc0:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104fc3:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80104fc5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104fc9:	0f 95 c0             	setne  %al
80104fcc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104fd0:	84 c0                	test   %al,%al
80104fd2:	75 de                	jne    80104fb2 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104fd4:	eb 25                	jmp    80104ffb <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80104fd6:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fd9:	0f b6 10             	movzbl (%eax),%edx
80104fdc:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104fdf:	88 10                	mov    %dl,(%eax)
80104fe1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104fe5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104fe9:	eb 01                	jmp    80104fec <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80104feb:	90                   	nop
80104fec:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104ff0:	0f 95 c0             	setne  %al
80104ff3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104ff7:	84 c0                	test   %al,%al
80104ff9:	75 db                	jne    80104fd6 <memmove+0x59>
      *d++ = *s++;

  return dst;
80104ffb:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104ffe:	c9                   	leave  
80104fff:	c3                   	ret    

80105000 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105000:	55                   	push   %ebp
80105001:	89 e5                	mov    %esp,%ebp
80105003:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80105006:	8b 45 10             	mov    0x10(%ebp),%eax
80105009:	89 44 24 08          	mov    %eax,0x8(%esp)
8010500d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105010:	89 44 24 04          	mov    %eax,0x4(%esp)
80105014:	8b 45 08             	mov    0x8(%ebp),%eax
80105017:	89 04 24             	mov    %eax,(%esp)
8010501a:	e8 5e ff ff ff       	call   80104f7d <memmove>
}
8010501f:	c9                   	leave  
80105020:	c3                   	ret    

80105021 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105021:	55                   	push   %ebp
80105022:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105024:	eb 0c                	jmp    80105032 <strncmp+0x11>
    n--, p++, q++;
80105026:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010502a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010502e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105032:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105036:	74 1a                	je     80105052 <strncmp+0x31>
80105038:	8b 45 08             	mov    0x8(%ebp),%eax
8010503b:	0f b6 00             	movzbl (%eax),%eax
8010503e:	84 c0                	test   %al,%al
80105040:	74 10                	je     80105052 <strncmp+0x31>
80105042:	8b 45 08             	mov    0x8(%ebp),%eax
80105045:	0f b6 10             	movzbl (%eax),%edx
80105048:	8b 45 0c             	mov    0xc(%ebp),%eax
8010504b:	0f b6 00             	movzbl (%eax),%eax
8010504e:	38 c2                	cmp    %al,%dl
80105050:	74 d4                	je     80105026 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105052:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105056:	75 07                	jne    8010505f <strncmp+0x3e>
    return 0;
80105058:	b8 00 00 00 00       	mov    $0x0,%eax
8010505d:	eb 18                	jmp    80105077 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010505f:	8b 45 08             	mov    0x8(%ebp),%eax
80105062:	0f b6 00             	movzbl (%eax),%eax
80105065:	0f b6 d0             	movzbl %al,%edx
80105068:	8b 45 0c             	mov    0xc(%ebp),%eax
8010506b:	0f b6 00             	movzbl (%eax),%eax
8010506e:	0f b6 c0             	movzbl %al,%eax
80105071:	89 d1                	mov    %edx,%ecx
80105073:	29 c1                	sub    %eax,%ecx
80105075:	89 c8                	mov    %ecx,%eax
}
80105077:	5d                   	pop    %ebp
80105078:	c3                   	ret    

80105079 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105079:	55                   	push   %ebp
8010507a:	89 e5                	mov    %esp,%ebp
8010507c:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010507f:	8b 45 08             	mov    0x8(%ebp),%eax
80105082:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105085:	90                   	nop
80105086:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010508a:	0f 9f c0             	setg   %al
8010508d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105091:	84 c0                	test   %al,%al
80105093:	74 30                	je     801050c5 <strncpy+0x4c>
80105095:	8b 45 0c             	mov    0xc(%ebp),%eax
80105098:	0f b6 10             	movzbl (%eax),%edx
8010509b:	8b 45 08             	mov    0x8(%ebp),%eax
8010509e:	88 10                	mov    %dl,(%eax)
801050a0:	8b 45 08             	mov    0x8(%ebp),%eax
801050a3:	0f b6 00             	movzbl (%eax),%eax
801050a6:	84 c0                	test   %al,%al
801050a8:	0f 95 c0             	setne  %al
801050ab:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050af:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801050b3:	84 c0                	test   %al,%al
801050b5:	75 cf                	jne    80105086 <strncpy+0xd>
    ;
  while(n-- > 0)
801050b7:	eb 0c                	jmp    801050c5 <strncpy+0x4c>
    *s++ = 0;
801050b9:	8b 45 08             	mov    0x8(%ebp),%eax
801050bc:	c6 00 00             	movb   $0x0,(%eax)
801050bf:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050c3:	eb 01                	jmp    801050c6 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801050c5:	90                   	nop
801050c6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050ca:	0f 9f c0             	setg   %al
801050cd:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050d1:	84 c0                	test   %al,%al
801050d3:	75 e4                	jne    801050b9 <strncpy+0x40>
    *s++ = 0;
  return os;
801050d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801050d8:	c9                   	leave  
801050d9:	c3                   	ret    

801050da <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801050da:	55                   	push   %ebp
801050db:	89 e5                	mov    %esp,%ebp
801050dd:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801050e0:	8b 45 08             	mov    0x8(%ebp),%eax
801050e3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801050e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050ea:	7f 05                	jg     801050f1 <safestrcpy+0x17>
    return os;
801050ec:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050ef:	eb 35                	jmp    80105126 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801050f1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050f9:	7e 22                	jle    8010511d <safestrcpy+0x43>
801050fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801050fe:	0f b6 10             	movzbl (%eax),%edx
80105101:	8b 45 08             	mov    0x8(%ebp),%eax
80105104:	88 10                	mov    %dl,(%eax)
80105106:	8b 45 08             	mov    0x8(%ebp),%eax
80105109:	0f b6 00             	movzbl (%eax),%eax
8010510c:	84 c0                	test   %al,%al
8010510e:	0f 95 c0             	setne  %al
80105111:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105115:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105119:	84 c0                	test   %al,%al
8010511b:	75 d4                	jne    801050f1 <safestrcpy+0x17>
    ;
  *s = 0;
8010511d:	8b 45 08             	mov    0x8(%ebp),%eax
80105120:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105123:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105126:	c9                   	leave  
80105127:	c3                   	ret    

80105128 <strlen>:

int
strlen(const char *s)
{
80105128:	55                   	push   %ebp
80105129:	89 e5                	mov    %esp,%ebp
8010512b:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
8010512e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105135:	eb 04                	jmp    8010513b <strlen+0x13>
80105137:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010513b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010513e:	03 45 08             	add    0x8(%ebp),%eax
80105141:	0f b6 00             	movzbl (%eax),%eax
80105144:	84 c0                	test   %al,%al
80105146:	75 ef                	jne    80105137 <strlen+0xf>
    ;
  return n;
80105148:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010514b:	c9                   	leave  
8010514c:	c3                   	ret    
8010514d:	00 00                	add    %al,(%eax)
	...

80105150 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105150:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105154:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105158:	55                   	push   %ebp
  pushl %ebx
80105159:	53                   	push   %ebx
  pushl %esi
8010515a:	56                   	push   %esi
  pushl %edi
8010515b:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010515c:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010515e:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105160:	5f                   	pop    %edi
  popl %esi
80105161:	5e                   	pop    %esi
  popl %ebx
80105162:	5b                   	pop    %ebx
  popl %ebp
80105163:	5d                   	pop    %ebp
  ret
80105164:	c3                   	ret    
80105165:	00 00                	add    %al,(%eax)
	...

80105168 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105168:	55                   	push   %ebp
80105169:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
8010516b:	8b 45 08             	mov    0x8(%ebp),%eax
8010516e:	8b 00                	mov    (%eax),%eax
80105170:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105173:	76 0f                	jbe    80105184 <fetchint+0x1c>
80105175:	8b 45 0c             	mov    0xc(%ebp),%eax
80105178:	8d 50 04             	lea    0x4(%eax),%edx
8010517b:	8b 45 08             	mov    0x8(%ebp),%eax
8010517e:	8b 00                	mov    (%eax),%eax
80105180:	39 c2                	cmp    %eax,%edx
80105182:	76 07                	jbe    8010518b <fetchint+0x23>
    return -1;
80105184:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105189:	eb 0f                	jmp    8010519a <fetchint+0x32>
  *ip = *(int*)(addr);
8010518b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010518e:	8b 10                	mov    (%eax),%edx
80105190:	8b 45 10             	mov    0x10(%ebp),%eax
80105193:	89 10                	mov    %edx,(%eax)
  return 0;
80105195:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010519a:	5d                   	pop    %ebp
8010519b:	c3                   	ret    

8010519c <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
8010519c:	55                   	push   %ebp
8010519d:	89 e5                	mov    %esp,%ebp
8010519f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
801051a2:	8b 45 08             	mov    0x8(%ebp),%eax
801051a5:	8b 00                	mov    (%eax),%eax
801051a7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801051aa:	77 07                	ja     801051b3 <fetchstr+0x17>
    return -1;
801051ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051b1:	eb 45                	jmp    801051f8 <fetchstr+0x5c>
  *pp = (char*)addr;
801051b3:	8b 55 0c             	mov    0xc(%ebp),%edx
801051b6:	8b 45 10             	mov    0x10(%ebp),%eax
801051b9:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
801051bb:	8b 45 08             	mov    0x8(%ebp),%eax
801051be:	8b 00                	mov    (%eax),%eax
801051c0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801051c3:	8b 45 10             	mov    0x10(%ebp),%eax
801051c6:	8b 00                	mov    (%eax),%eax
801051c8:	89 45 fc             	mov    %eax,-0x4(%ebp)
801051cb:	eb 1e                	jmp    801051eb <fetchstr+0x4f>
    if(*s == 0)
801051cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051d0:	0f b6 00             	movzbl (%eax),%eax
801051d3:	84 c0                	test   %al,%al
801051d5:	75 10                	jne    801051e7 <fetchstr+0x4b>
      return s - *pp;
801051d7:	8b 55 fc             	mov    -0x4(%ebp),%edx
801051da:	8b 45 10             	mov    0x10(%ebp),%eax
801051dd:	8b 00                	mov    (%eax),%eax
801051df:	89 d1                	mov    %edx,%ecx
801051e1:	29 c1                	sub    %eax,%ecx
801051e3:	89 c8                	mov    %ecx,%eax
801051e5:	eb 11                	jmp    801051f8 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
801051e7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801051eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051ee:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801051f1:	72 da                	jb     801051cd <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801051f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801051f8:	c9                   	leave  
801051f9:	c3                   	ret    

801051fa <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801051fa:	55                   	push   %ebp
801051fb:	89 e5                	mov    %esp,%ebp
801051fd:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105200:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105206:	8b 40 18             	mov    0x18(%eax),%eax
80105209:	8b 50 44             	mov    0x44(%eax),%edx
8010520c:	8b 45 08             	mov    0x8(%ebp),%eax
8010520f:	c1 e0 02             	shl    $0x2,%eax
80105212:	01 d0                	add    %edx,%eax
80105214:	8d 48 04             	lea    0x4(%eax),%ecx
80105217:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010521d:	8b 55 0c             	mov    0xc(%ebp),%edx
80105220:	89 54 24 08          	mov    %edx,0x8(%esp)
80105224:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105228:	89 04 24             	mov    %eax,(%esp)
8010522b:	e8 38 ff ff ff       	call   80105168 <fetchint>
}
80105230:	c9                   	leave  
80105231:	c3                   	ret    

80105232 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105232:	55                   	push   %ebp
80105233:	89 e5                	mov    %esp,%ebp
80105235:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
80105238:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010523b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010523f:	8b 45 08             	mov    0x8(%ebp),%eax
80105242:	89 04 24             	mov    %eax,(%esp)
80105245:	e8 b0 ff ff ff       	call   801051fa <argint>
8010524a:	85 c0                	test   %eax,%eax
8010524c:	79 07                	jns    80105255 <argptr+0x23>
    return -1;
8010524e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105253:	eb 3d                	jmp    80105292 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105255:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105258:	89 c2                	mov    %eax,%edx
8010525a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105260:	8b 00                	mov    (%eax),%eax
80105262:	39 c2                	cmp    %eax,%edx
80105264:	73 16                	jae    8010527c <argptr+0x4a>
80105266:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105269:	89 c2                	mov    %eax,%edx
8010526b:	8b 45 10             	mov    0x10(%ebp),%eax
8010526e:	01 c2                	add    %eax,%edx
80105270:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105276:	8b 00                	mov    (%eax),%eax
80105278:	39 c2                	cmp    %eax,%edx
8010527a:	76 07                	jbe    80105283 <argptr+0x51>
    return -1;
8010527c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105281:	eb 0f                	jmp    80105292 <argptr+0x60>
  *pp = (char*)i;
80105283:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105286:	89 c2                	mov    %eax,%edx
80105288:	8b 45 0c             	mov    0xc(%ebp),%eax
8010528b:	89 10                	mov    %edx,(%eax)
  return 0;
8010528d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105292:	c9                   	leave  
80105293:	c3                   	ret    

80105294 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105294:	55                   	push   %ebp
80105295:	89 e5                	mov    %esp,%ebp
80105297:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010529a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010529d:	89 44 24 04          	mov    %eax,0x4(%esp)
801052a1:	8b 45 08             	mov    0x8(%ebp),%eax
801052a4:	89 04 24             	mov    %eax,(%esp)
801052a7:	e8 4e ff ff ff       	call   801051fa <argint>
801052ac:	85 c0                	test   %eax,%eax
801052ae:	79 07                	jns    801052b7 <argstr+0x23>
    return -1;
801052b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052b5:	eb 1e                	jmp    801052d5 <argstr+0x41>
  return fetchstr(proc, addr, pp);
801052b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052ba:	89 c2                	mov    %eax,%edx
801052bc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801052c5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801052c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801052cd:	89 04 24             	mov    %eax,(%esp)
801052d0:	e8 c7 fe ff ff       	call   8010519c <fetchstr>
}
801052d5:	c9                   	leave  
801052d6:	c3                   	ret    

801052d7 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
801052d7:	55                   	push   %ebp
801052d8:	89 e5                	mov    %esp,%ebp
801052da:	53                   	push   %ebx
801052db:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801052de:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052e4:	8b 40 18             	mov    0x18(%eax),%eax
801052e7:	8b 40 1c             	mov    0x1c(%eax),%eax
801052ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801052ed:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801052f1:	78 2e                	js     80105321 <syscall+0x4a>
801052f3:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801052f7:	7f 28                	jg     80105321 <syscall+0x4a>
801052f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801052fc:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105303:	85 c0                	test   %eax,%eax
80105305:	74 1a                	je     80105321 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
80105307:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010530d:	8b 58 18             	mov    0x18(%eax),%ebx
80105310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105313:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010531a:	ff d0                	call   *%eax
8010531c:	89 43 1c             	mov    %eax,0x1c(%ebx)
8010531f:	eb 73                	jmp    80105394 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80105321:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105325:	7e 30                	jle    80105357 <syscall+0x80>
80105327:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010532a:	83 f8 15             	cmp    $0x15,%eax
8010532d:	77 28                	ja     80105357 <syscall+0x80>
8010532f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105332:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105339:	85 c0                	test   %eax,%eax
8010533b:	74 1a                	je     80105357 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
8010533d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105343:	8b 58 18             	mov    0x18(%eax),%ebx
80105346:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105349:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105350:	ff d0                	call   *%eax
80105352:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105355:	eb 3d                	jmp    80105394 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105357:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010535d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105360:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105366:	8b 40 10             	mov    0x10(%eax),%eax
80105369:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010536c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105370:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105374:	89 44 24 04          	mov    %eax,0x4(%esp)
80105378:	c7 04 24 6f 86 10 80 	movl   $0x8010866f,(%esp)
8010537f:	e8 1d b0 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105384:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010538a:	8b 40 18             	mov    0x18(%eax),%eax
8010538d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105394:	83 c4 24             	add    $0x24,%esp
80105397:	5b                   	pop    %ebx
80105398:	5d                   	pop    %ebp
80105399:	c3                   	ret    
	...

8010539c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010539c:	55                   	push   %ebp
8010539d:	89 e5                	mov    %esp,%ebp
8010539f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801053a2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801053a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801053a9:	8b 45 08             	mov    0x8(%ebp),%eax
801053ac:	89 04 24             	mov    %eax,(%esp)
801053af:	e8 46 fe ff ff       	call   801051fa <argint>
801053b4:	85 c0                	test   %eax,%eax
801053b6:	79 07                	jns    801053bf <argfd+0x23>
    return -1;
801053b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053bd:	eb 50                	jmp    8010540f <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801053bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053c2:	85 c0                	test   %eax,%eax
801053c4:	78 21                	js     801053e7 <argfd+0x4b>
801053c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053c9:	83 f8 0f             	cmp    $0xf,%eax
801053cc:	7f 19                	jg     801053e7 <argfd+0x4b>
801053ce:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053d4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801053d7:	83 c2 08             	add    $0x8,%edx
801053da:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801053de:	89 45 f4             	mov    %eax,-0xc(%ebp)
801053e1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801053e5:	75 07                	jne    801053ee <argfd+0x52>
    return -1;
801053e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053ec:	eb 21                	jmp    8010540f <argfd+0x73>
  if(pfd)
801053ee:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801053f2:	74 08                	je     801053fc <argfd+0x60>
    *pfd = fd;
801053f4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801053f7:	8b 45 0c             	mov    0xc(%ebp),%eax
801053fa:	89 10                	mov    %edx,(%eax)
  if(pf)
801053fc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105400:	74 08                	je     8010540a <argfd+0x6e>
    *pf = f;
80105402:	8b 45 10             	mov    0x10(%ebp),%eax
80105405:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105408:	89 10                	mov    %edx,(%eax)
  return 0;
8010540a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010540f:	c9                   	leave  
80105410:	c3                   	ret    

80105411 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105411:	55                   	push   %ebp
80105412:	89 e5                	mov    %esp,%ebp
80105414:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105417:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010541e:	eb 30                	jmp    80105450 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105420:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105426:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105429:	83 c2 08             	add    $0x8,%edx
8010542c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105430:	85 c0                	test   %eax,%eax
80105432:	75 18                	jne    8010544c <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105434:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010543a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010543d:	8d 4a 08             	lea    0x8(%edx),%ecx
80105440:	8b 55 08             	mov    0x8(%ebp),%edx
80105443:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105447:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010544a:	eb 0f                	jmp    8010545b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010544c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105450:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105454:	7e ca                	jle    80105420 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105456:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010545b:	c9                   	leave  
8010545c:	c3                   	ret    

8010545d <sys_dup>:

int
sys_dup(void)
{
8010545d:	55                   	push   %ebp
8010545e:	89 e5                	mov    %esp,%ebp
80105460:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105463:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105466:	89 44 24 08          	mov    %eax,0x8(%esp)
8010546a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105471:	00 
80105472:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105479:	e8 1e ff ff ff       	call   8010539c <argfd>
8010547e:	85 c0                	test   %eax,%eax
80105480:	79 07                	jns    80105489 <sys_dup+0x2c>
    return -1;
80105482:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105487:	eb 29                	jmp    801054b2 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105489:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010548c:	89 04 24             	mov    %eax,(%esp)
8010548f:	e8 7d ff ff ff       	call   80105411 <fdalloc>
80105494:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105497:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010549b:	79 07                	jns    801054a4 <sys_dup+0x47>
    return -1;
8010549d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054a2:	eb 0e                	jmp    801054b2 <sys_dup+0x55>
  filedup(f);
801054a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054a7:	89 04 24             	mov    %eax,(%esp)
801054aa:	e8 85 bb ff ff       	call   80101034 <filedup>
  return fd;
801054af:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801054b2:	c9                   	leave  
801054b3:	c3                   	ret    

801054b4 <sys_read>:

int
sys_read(void)
{
801054b4:	55                   	push   %ebp
801054b5:	89 e5                	mov    %esp,%ebp
801054b7:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801054ba:	8d 45 f4             	lea    -0xc(%ebp),%eax
801054bd:	89 44 24 08          	mov    %eax,0x8(%esp)
801054c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801054c8:	00 
801054c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801054d0:	e8 c7 fe ff ff       	call   8010539c <argfd>
801054d5:	85 c0                	test   %eax,%eax
801054d7:	78 35                	js     8010550e <sys_read+0x5a>
801054d9:	8d 45 f0             	lea    -0x10(%ebp),%eax
801054dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801054e0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801054e7:	e8 0e fd ff ff       	call   801051fa <argint>
801054ec:	85 c0                	test   %eax,%eax
801054ee:	78 1e                	js     8010550e <sys_read+0x5a>
801054f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054f3:	89 44 24 08          	mov    %eax,0x8(%esp)
801054f7:	8d 45 ec             	lea    -0x14(%ebp),%eax
801054fa:	89 44 24 04          	mov    %eax,0x4(%esp)
801054fe:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105505:	e8 28 fd ff ff       	call   80105232 <argptr>
8010550a:	85 c0                	test   %eax,%eax
8010550c:	79 07                	jns    80105515 <sys_read+0x61>
    return -1;
8010550e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105513:	eb 19                	jmp    8010552e <sys_read+0x7a>
  return fileread(f, p, n);
80105515:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105518:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010551b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010551e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105522:	89 54 24 04          	mov    %edx,0x4(%esp)
80105526:	89 04 24             	mov    %eax,(%esp)
80105529:	e8 73 bc ff ff       	call   801011a1 <fileread>
}
8010552e:	c9                   	leave  
8010552f:	c3                   	ret    

80105530 <sys_write>:

int
sys_write(void)
{
80105530:	55                   	push   %ebp
80105531:	89 e5                	mov    %esp,%ebp
80105533:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105536:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105539:	89 44 24 08          	mov    %eax,0x8(%esp)
8010553d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105544:	00 
80105545:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010554c:	e8 4b fe ff ff       	call   8010539c <argfd>
80105551:	85 c0                	test   %eax,%eax
80105553:	78 35                	js     8010558a <sys_write+0x5a>
80105555:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105558:	89 44 24 04          	mov    %eax,0x4(%esp)
8010555c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105563:	e8 92 fc ff ff       	call   801051fa <argint>
80105568:	85 c0                	test   %eax,%eax
8010556a:	78 1e                	js     8010558a <sys_write+0x5a>
8010556c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010556f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105573:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105576:	89 44 24 04          	mov    %eax,0x4(%esp)
8010557a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105581:	e8 ac fc ff ff       	call   80105232 <argptr>
80105586:	85 c0                	test   %eax,%eax
80105588:	79 07                	jns    80105591 <sys_write+0x61>
    return -1;
8010558a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010558f:	eb 19                	jmp    801055aa <sys_write+0x7a>
  return filewrite(f, p, n);
80105591:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105594:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010559e:	89 54 24 04          	mov    %edx,0x4(%esp)
801055a2:	89 04 24             	mov    %eax,(%esp)
801055a5:	e8 b3 bc ff ff       	call   8010125d <filewrite>
}
801055aa:	c9                   	leave  
801055ab:	c3                   	ret    

801055ac <sys_close>:

int
sys_close(void)
{
801055ac:	55                   	push   %ebp
801055ad:	89 e5                	mov    %esp,%ebp
801055af:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801055b2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801055b5:	89 44 24 08          	mov    %eax,0x8(%esp)
801055b9:	8d 45 f4             	lea    -0xc(%ebp),%eax
801055bc:	89 44 24 04          	mov    %eax,0x4(%esp)
801055c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801055c7:	e8 d0 fd ff ff       	call   8010539c <argfd>
801055cc:	85 c0                	test   %eax,%eax
801055ce:	79 07                	jns    801055d7 <sys_close+0x2b>
    return -1;
801055d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055d5:	eb 24                	jmp    801055fb <sys_close+0x4f>
  proc->ofile[fd] = 0;
801055d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
801055e0:	83 c2 08             	add    $0x8,%edx
801055e3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801055ea:	00 
  fileclose(f);
801055eb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055ee:	89 04 24             	mov    %eax,(%esp)
801055f1:	e8 86 ba ff ff       	call   8010107c <fileclose>
  return 0;
801055f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055fb:	c9                   	leave  
801055fc:	c3                   	ret    

801055fd <sys_fstat>:

int
sys_fstat(void)
{
801055fd:	55                   	push   %ebp
801055fe:	89 e5                	mov    %esp,%ebp
80105600:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105603:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105606:	89 44 24 08          	mov    %eax,0x8(%esp)
8010560a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105611:	00 
80105612:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105619:	e8 7e fd ff ff       	call   8010539c <argfd>
8010561e:	85 c0                	test   %eax,%eax
80105620:	78 1f                	js     80105641 <sys_fstat+0x44>
80105622:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105629:	00 
8010562a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010562d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105631:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105638:	e8 f5 fb ff ff       	call   80105232 <argptr>
8010563d:	85 c0                	test   %eax,%eax
8010563f:	79 07                	jns    80105648 <sys_fstat+0x4b>
    return -1;
80105641:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105646:	eb 12                	jmp    8010565a <sys_fstat+0x5d>
  return filestat(f, st);
80105648:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010564b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010564e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105652:	89 04 24             	mov    %eax,(%esp)
80105655:	e8 f8 ba ff ff       	call   80101152 <filestat>
}
8010565a:	c9                   	leave  
8010565b:	c3                   	ret    

8010565c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
8010565c:	55                   	push   %ebp
8010565d:	89 e5                	mov    %esp,%ebp
8010565f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105662:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105665:	89 44 24 04          	mov    %eax,0x4(%esp)
80105669:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105670:	e8 1f fc ff ff       	call   80105294 <argstr>
80105675:	85 c0                	test   %eax,%eax
80105677:	78 17                	js     80105690 <sys_link+0x34>
80105679:	8d 45 dc             	lea    -0x24(%ebp),%eax
8010567c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105680:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105687:	e8 08 fc ff ff       	call   80105294 <argstr>
8010568c:	85 c0                	test   %eax,%eax
8010568e:	79 0a                	jns    8010569a <sys_link+0x3e>
    return -1;
80105690:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105695:	e9 3c 01 00 00       	jmp    801057d6 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010569a:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010569d:	89 04 24             	mov    %eax,(%esp)
801056a0:	e8 1d ce ff ff       	call   801024c2 <namei>
801056a5:	89 45 f4             	mov    %eax,-0xc(%ebp)
801056a8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801056ac:	75 0a                	jne    801056b8 <sys_link+0x5c>
    return -1;
801056ae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056b3:	e9 1e 01 00 00       	jmp    801057d6 <sys_link+0x17a>

  begin_trans();
801056b8:	e8 18 dc ff ff       	call   801032d5 <begin_trans>

  ilock(ip);
801056bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056c0:	89 04 24             	mov    %eax,(%esp)
801056c3:	e8 58 c2 ff ff       	call   80101920 <ilock>
  if(ip->type == T_DIR){
801056c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056cb:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801056cf:	66 83 f8 01          	cmp    $0x1,%ax
801056d3:	75 1a                	jne    801056ef <sys_link+0x93>
    iunlockput(ip);
801056d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056d8:	89 04 24             	mov    %eax,(%esp)
801056db:	e8 c4 c4 ff ff       	call   80101ba4 <iunlockput>
    commit_trans();
801056e0:	e8 39 dc ff ff       	call   8010331e <commit_trans>
    return -1;
801056e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056ea:	e9 e7 00 00 00       	jmp    801057d6 <sys_link+0x17a>
  }

  ip->nlink++;
801056ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056f2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801056f6:	8d 50 01             	lea    0x1(%eax),%edx
801056f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056fc:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105700:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105703:	89 04 24             	mov    %eax,(%esp)
80105706:	e8 59 c0 ff ff       	call   80101764 <iupdate>
  iunlock(ip);
8010570b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010570e:	89 04 24             	mov    %eax,(%esp)
80105711:	e8 58 c3 ff ff       	call   80101a6e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105716:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105719:	8d 55 e2             	lea    -0x1e(%ebp),%edx
8010571c:	89 54 24 04          	mov    %edx,0x4(%esp)
80105720:	89 04 24             	mov    %eax,(%esp)
80105723:	e8 bc cd ff ff       	call   801024e4 <nameiparent>
80105728:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010572b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010572f:	74 68                	je     80105799 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80105731:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105734:	89 04 24             	mov    %eax,(%esp)
80105737:	e8 e4 c1 ff ff       	call   80101920 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
8010573c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010573f:	8b 10                	mov    (%eax),%edx
80105741:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105744:	8b 00                	mov    (%eax),%eax
80105746:	39 c2                	cmp    %eax,%edx
80105748:	75 20                	jne    8010576a <sys_link+0x10e>
8010574a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010574d:	8b 40 04             	mov    0x4(%eax),%eax
80105750:	89 44 24 08          	mov    %eax,0x8(%esp)
80105754:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105757:	89 44 24 04          	mov    %eax,0x4(%esp)
8010575b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010575e:	89 04 24             	mov    %eax,(%esp)
80105761:	e8 9b ca ff ff       	call   80102201 <dirlink>
80105766:	85 c0                	test   %eax,%eax
80105768:	79 0d                	jns    80105777 <sys_link+0x11b>
    iunlockput(dp);
8010576a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010576d:	89 04 24             	mov    %eax,(%esp)
80105770:	e8 2f c4 ff ff       	call   80101ba4 <iunlockput>
    goto bad;
80105775:	eb 23                	jmp    8010579a <sys_link+0x13e>
  }
  iunlockput(dp);
80105777:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010577a:	89 04 24             	mov    %eax,(%esp)
8010577d:	e8 22 c4 ff ff       	call   80101ba4 <iunlockput>
  iput(ip);
80105782:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105785:	89 04 24             	mov    %eax,(%esp)
80105788:	e8 46 c3 ff ff       	call   80101ad3 <iput>

  commit_trans();
8010578d:	e8 8c db ff ff       	call   8010331e <commit_trans>

  return 0;
80105792:	b8 00 00 00 00       	mov    $0x0,%eax
80105797:	eb 3d                	jmp    801057d6 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105799:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010579a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010579d:	89 04 24             	mov    %eax,(%esp)
801057a0:	e8 7b c1 ff ff       	call   80101920 <ilock>
  ip->nlink--;
801057a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801057ac:	8d 50 ff             	lea    -0x1(%eax),%edx
801057af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b2:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801057b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b9:	89 04 24             	mov    %eax,(%esp)
801057bc:	e8 a3 bf ff ff       	call   80101764 <iupdate>
  iunlockput(ip);
801057c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c4:	89 04 24             	mov    %eax,(%esp)
801057c7:	e8 d8 c3 ff ff       	call   80101ba4 <iunlockput>
  commit_trans();
801057cc:	e8 4d db ff ff       	call   8010331e <commit_trans>
  return -1;
801057d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801057d6:	c9                   	leave  
801057d7:	c3                   	ret    

801057d8 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801057d8:	55                   	push   %ebp
801057d9:	89 e5                	mov    %esp,%ebp
801057db:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801057de:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801057e5:	eb 4b                	jmp    80105832 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801057e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ea:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801057f1:	00 
801057f2:	89 44 24 08          	mov    %eax,0x8(%esp)
801057f6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801057f9:	89 44 24 04          	mov    %eax,0x4(%esp)
801057fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105800:	89 04 24             	mov    %eax,(%esp)
80105803:	e8 0e c6 ff ff       	call   80101e16 <readi>
80105808:	83 f8 10             	cmp    $0x10,%eax
8010580b:	74 0c                	je     80105819 <isdirempty+0x41>
      panic("isdirempty: readi");
8010580d:	c7 04 24 8b 86 10 80 	movl   $0x8010868b,(%esp)
80105814:	e8 24 ad ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105819:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
8010581d:	66 85 c0             	test   %ax,%ax
80105820:	74 07                	je     80105829 <isdirempty+0x51>
      return 0;
80105822:	b8 00 00 00 00       	mov    $0x0,%eax
80105827:	eb 1b                	jmp    80105844 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105829:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010582c:	83 c0 10             	add    $0x10,%eax
8010582f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105832:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105835:	8b 45 08             	mov    0x8(%ebp),%eax
80105838:	8b 40 18             	mov    0x18(%eax),%eax
8010583b:	39 c2                	cmp    %eax,%edx
8010583d:	72 a8                	jb     801057e7 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
8010583f:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105844:	c9                   	leave  
80105845:	c3                   	ret    

80105846 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105846:	55                   	push   %ebp
80105847:	89 e5                	mov    %esp,%ebp
80105849:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
8010584c:	8d 45 cc             	lea    -0x34(%ebp),%eax
8010584f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105853:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010585a:	e8 35 fa ff ff       	call   80105294 <argstr>
8010585f:	85 c0                	test   %eax,%eax
80105861:	79 0a                	jns    8010586d <sys_unlink+0x27>
    return -1;
80105863:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105868:	e9 aa 01 00 00       	jmp    80105a17 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
8010586d:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105870:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105873:	89 54 24 04          	mov    %edx,0x4(%esp)
80105877:	89 04 24             	mov    %eax,(%esp)
8010587a:	e8 65 cc ff ff       	call   801024e4 <nameiparent>
8010587f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105882:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105886:	75 0a                	jne    80105892 <sys_unlink+0x4c>
    return -1;
80105888:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010588d:	e9 85 01 00 00       	jmp    80105a17 <sys_unlink+0x1d1>

  begin_trans();
80105892:	e8 3e da ff ff       	call   801032d5 <begin_trans>

  ilock(dp);
80105897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010589a:	89 04 24             	mov    %eax,(%esp)
8010589d:	e8 7e c0 ff ff       	call   80101920 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801058a2:	c7 44 24 04 9d 86 10 	movl   $0x8010869d,0x4(%esp)
801058a9:	80 
801058aa:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801058ad:	89 04 24             	mov    %eax,(%esp)
801058b0:	e8 62 c8 ff ff       	call   80102117 <namecmp>
801058b5:	85 c0                	test   %eax,%eax
801058b7:	0f 84 45 01 00 00    	je     80105a02 <sys_unlink+0x1bc>
801058bd:	c7 44 24 04 9f 86 10 	movl   $0x8010869f,0x4(%esp)
801058c4:	80 
801058c5:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801058c8:	89 04 24             	mov    %eax,(%esp)
801058cb:	e8 47 c8 ff ff       	call   80102117 <namecmp>
801058d0:	85 c0                	test   %eax,%eax
801058d2:	0f 84 2a 01 00 00    	je     80105a02 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801058d8:	8d 45 c8             	lea    -0x38(%ebp),%eax
801058db:	89 44 24 08          	mov    %eax,0x8(%esp)
801058df:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801058e2:	89 44 24 04          	mov    %eax,0x4(%esp)
801058e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058e9:	89 04 24             	mov    %eax,(%esp)
801058ec:	e8 48 c8 ff ff       	call   80102139 <dirlookup>
801058f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801058f4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058f8:	0f 84 03 01 00 00    	je     80105a01 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
801058fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105901:	89 04 24             	mov    %eax,(%esp)
80105904:	e8 17 c0 ff ff       	call   80101920 <ilock>

  if(ip->nlink < 1)
80105909:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010590c:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105910:	66 85 c0             	test   %ax,%ax
80105913:	7f 0c                	jg     80105921 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80105915:	c7 04 24 a2 86 10 80 	movl   $0x801086a2,(%esp)
8010591c:	e8 1c ac ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105921:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105924:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105928:	66 83 f8 01          	cmp    $0x1,%ax
8010592c:	75 1f                	jne    8010594d <sys_unlink+0x107>
8010592e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105931:	89 04 24             	mov    %eax,(%esp)
80105934:	e8 9f fe ff ff       	call   801057d8 <isdirempty>
80105939:	85 c0                	test   %eax,%eax
8010593b:	75 10                	jne    8010594d <sys_unlink+0x107>
    iunlockput(ip);
8010593d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105940:	89 04 24             	mov    %eax,(%esp)
80105943:	e8 5c c2 ff ff       	call   80101ba4 <iunlockput>
    goto bad;
80105948:	e9 b5 00 00 00       	jmp    80105a02 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
8010594d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105954:	00 
80105955:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010595c:	00 
8010595d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105960:	89 04 24             	mov    %eax,(%esp)
80105963:	e8 42 f5 ff ff       	call   80104eaa <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105968:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010596b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105972:	00 
80105973:	89 44 24 08          	mov    %eax,0x8(%esp)
80105977:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010597a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010597e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105981:	89 04 24             	mov    %eax,(%esp)
80105984:	e8 f8 c5 ff ff       	call   80101f81 <writei>
80105989:	83 f8 10             	cmp    $0x10,%eax
8010598c:	74 0c                	je     8010599a <sys_unlink+0x154>
    panic("unlink: writei");
8010598e:	c7 04 24 b4 86 10 80 	movl   $0x801086b4,(%esp)
80105995:	e8 a3 ab ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
8010599a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010599d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801059a1:	66 83 f8 01          	cmp    $0x1,%ax
801059a5:	75 1c                	jne    801059c3 <sys_unlink+0x17d>
    dp->nlink--;
801059a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059aa:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059ae:	8d 50 ff             	lea    -0x1(%eax),%edx
801059b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b4:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801059b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059bb:	89 04 24             	mov    %eax,(%esp)
801059be:	e8 a1 bd ff ff       	call   80101764 <iupdate>
  }
  iunlockput(dp);
801059c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059c6:	89 04 24             	mov    %eax,(%esp)
801059c9:	e8 d6 c1 ff ff       	call   80101ba4 <iunlockput>

  ip->nlink--;
801059ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059d1:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059d5:	8d 50 ff             	lea    -0x1(%eax),%edx
801059d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059db:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801059df:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059e2:	89 04 24             	mov    %eax,(%esp)
801059e5:	e8 7a bd ff ff       	call   80101764 <iupdate>
  iunlockput(ip);
801059ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059ed:	89 04 24             	mov    %eax,(%esp)
801059f0:	e8 af c1 ff ff       	call   80101ba4 <iunlockput>

  commit_trans();
801059f5:	e8 24 d9 ff ff       	call   8010331e <commit_trans>

  return 0;
801059fa:	b8 00 00 00 00       	mov    $0x0,%eax
801059ff:	eb 16                	jmp    80105a17 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105a01:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105a02:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a05:	89 04 24             	mov    %eax,(%esp)
80105a08:	e8 97 c1 ff ff       	call   80101ba4 <iunlockput>
  commit_trans();
80105a0d:	e8 0c d9 ff ff       	call   8010331e <commit_trans>
  return -1;
80105a12:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a17:	c9                   	leave  
80105a18:	c3                   	ret    

80105a19 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105a19:	55                   	push   %ebp
80105a1a:	89 e5                	mov    %esp,%ebp
80105a1c:	83 ec 48             	sub    $0x48,%esp
80105a1f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105a22:	8b 55 10             	mov    0x10(%ebp),%edx
80105a25:	8b 45 14             	mov    0x14(%ebp),%eax
80105a28:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105a2c:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105a30:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105a34:	8d 45 de             	lea    -0x22(%ebp),%eax
80105a37:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a3b:	8b 45 08             	mov    0x8(%ebp),%eax
80105a3e:	89 04 24             	mov    %eax,(%esp)
80105a41:	e8 9e ca ff ff       	call   801024e4 <nameiparent>
80105a46:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a49:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a4d:	75 0a                	jne    80105a59 <create+0x40>
    return 0;
80105a4f:	b8 00 00 00 00       	mov    $0x0,%eax
80105a54:	e9 7e 01 00 00       	jmp    80105bd7 <create+0x1be>
  ilock(dp);
80105a59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a5c:	89 04 24             	mov    %eax,(%esp)
80105a5f:	e8 bc be ff ff       	call   80101920 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105a64:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105a67:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a6b:	8d 45 de             	lea    -0x22(%ebp),%eax
80105a6e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a75:	89 04 24             	mov    %eax,(%esp)
80105a78:	e8 bc c6 ff ff       	call   80102139 <dirlookup>
80105a7d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a84:	74 47                	je     80105acd <create+0xb4>
    iunlockput(dp);
80105a86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a89:	89 04 24             	mov    %eax,(%esp)
80105a8c:	e8 13 c1 ff ff       	call   80101ba4 <iunlockput>
    ilock(ip);
80105a91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a94:	89 04 24             	mov    %eax,(%esp)
80105a97:	e8 84 be ff ff       	call   80101920 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105a9c:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105aa1:	75 15                	jne    80105ab8 <create+0x9f>
80105aa3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aa6:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105aaa:	66 83 f8 02          	cmp    $0x2,%ax
80105aae:	75 08                	jne    80105ab8 <create+0x9f>
      return ip;
80105ab0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ab3:	e9 1f 01 00 00       	jmp    80105bd7 <create+0x1be>
    iunlockput(ip);
80105ab8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105abb:	89 04 24             	mov    %eax,(%esp)
80105abe:	e8 e1 c0 ff ff       	call   80101ba4 <iunlockput>
    return 0;
80105ac3:	b8 00 00 00 00       	mov    $0x0,%eax
80105ac8:	e9 0a 01 00 00       	jmp    80105bd7 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105acd:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105ad1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad4:	8b 00                	mov    (%eax),%eax
80105ad6:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ada:	89 04 24             	mov    %eax,(%esp)
80105add:	e8 a5 bb ff ff       	call   80101687 <ialloc>
80105ae2:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ae5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105ae9:	75 0c                	jne    80105af7 <create+0xde>
    panic("create: ialloc");
80105aeb:	c7 04 24 c3 86 10 80 	movl   $0x801086c3,(%esp)
80105af2:	e8 46 aa ff ff       	call   8010053d <panic>

  ilock(ip);
80105af7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105afa:	89 04 24             	mov    %eax,(%esp)
80105afd:	e8 1e be ff ff       	call   80101920 <ilock>
  ip->major = major;
80105b02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b05:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105b09:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105b0d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b10:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105b14:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105b18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b1b:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105b21:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b24:	89 04 24             	mov    %eax,(%esp)
80105b27:	e8 38 bc ff ff       	call   80101764 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105b2c:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105b31:	75 6a                	jne    80105b9d <create+0x184>
    dp->nlink++;  // for ".."
80105b33:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b36:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b3a:	8d 50 01             	lea    0x1(%eax),%edx
80105b3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b40:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105b44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b47:	89 04 24             	mov    %eax,(%esp)
80105b4a:	e8 15 bc ff ff       	call   80101764 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105b4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b52:	8b 40 04             	mov    0x4(%eax),%eax
80105b55:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b59:	c7 44 24 04 9d 86 10 	movl   $0x8010869d,0x4(%esp)
80105b60:	80 
80105b61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b64:	89 04 24             	mov    %eax,(%esp)
80105b67:	e8 95 c6 ff ff       	call   80102201 <dirlink>
80105b6c:	85 c0                	test   %eax,%eax
80105b6e:	78 21                	js     80105b91 <create+0x178>
80105b70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b73:	8b 40 04             	mov    0x4(%eax),%eax
80105b76:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b7a:	c7 44 24 04 9f 86 10 	movl   $0x8010869f,0x4(%esp)
80105b81:	80 
80105b82:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b85:	89 04 24             	mov    %eax,(%esp)
80105b88:	e8 74 c6 ff ff       	call   80102201 <dirlink>
80105b8d:	85 c0                	test   %eax,%eax
80105b8f:	79 0c                	jns    80105b9d <create+0x184>
      panic("create dots");
80105b91:	c7 04 24 d2 86 10 80 	movl   $0x801086d2,(%esp)
80105b98:	e8 a0 a9 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105b9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ba0:	8b 40 04             	mov    0x4(%eax),%eax
80105ba3:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ba7:	8d 45 de             	lea    -0x22(%ebp),%eax
80105baa:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bb1:	89 04 24             	mov    %eax,(%esp)
80105bb4:	e8 48 c6 ff ff       	call   80102201 <dirlink>
80105bb9:	85 c0                	test   %eax,%eax
80105bbb:	79 0c                	jns    80105bc9 <create+0x1b0>
    panic("create: dirlink");
80105bbd:	c7 04 24 de 86 10 80 	movl   $0x801086de,(%esp)
80105bc4:	e8 74 a9 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80105bc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bcc:	89 04 24             	mov    %eax,(%esp)
80105bcf:	e8 d0 bf ff ff       	call   80101ba4 <iunlockput>

  return ip;
80105bd4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105bd7:	c9                   	leave  
80105bd8:	c3                   	ret    

80105bd9 <sys_open>:

int
sys_open(void)
{
80105bd9:	55                   	push   %ebp
80105bda:	89 e5                	mov    %esp,%ebp
80105bdc:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105bdf:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105be2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105be6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105bed:	e8 a2 f6 ff ff       	call   80105294 <argstr>
80105bf2:	85 c0                	test   %eax,%eax
80105bf4:	78 17                	js     80105c0d <sys_open+0x34>
80105bf6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105bf9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bfd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105c04:	e8 f1 f5 ff ff       	call   801051fa <argint>
80105c09:	85 c0                	test   %eax,%eax
80105c0b:	79 0a                	jns    80105c17 <sys_open+0x3e>
    return -1;
80105c0d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c12:	e9 46 01 00 00       	jmp    80105d5d <sys_open+0x184>
  if(omode & O_CREATE){
80105c17:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c1a:	25 00 02 00 00       	and    $0x200,%eax
80105c1f:	85 c0                	test   %eax,%eax
80105c21:	74 40                	je     80105c63 <sys_open+0x8a>
    begin_trans();
80105c23:	e8 ad d6 ff ff       	call   801032d5 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105c28:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c2b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105c32:	00 
80105c33:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105c3a:	00 
80105c3b:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105c42:	00 
80105c43:	89 04 24             	mov    %eax,(%esp)
80105c46:	e8 ce fd ff ff       	call   80105a19 <create>
80105c4b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105c4e:	e8 cb d6 ff ff       	call   8010331e <commit_trans>
    if(ip == 0)
80105c53:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c57:	75 5c                	jne    80105cb5 <sys_open+0xdc>
      return -1;
80105c59:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c5e:	e9 fa 00 00 00       	jmp    80105d5d <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80105c63:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c66:	89 04 24             	mov    %eax,(%esp)
80105c69:	e8 54 c8 ff ff       	call   801024c2 <namei>
80105c6e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c71:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c75:	75 0a                	jne    80105c81 <sys_open+0xa8>
      return -1;
80105c77:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c7c:	e9 dc 00 00 00       	jmp    80105d5d <sys_open+0x184>
    ilock(ip);
80105c81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c84:	89 04 24             	mov    %eax,(%esp)
80105c87:	e8 94 bc ff ff       	call   80101920 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105c8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c8f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c93:	66 83 f8 01          	cmp    $0x1,%ax
80105c97:	75 1c                	jne    80105cb5 <sys_open+0xdc>
80105c99:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c9c:	85 c0                	test   %eax,%eax
80105c9e:	74 15                	je     80105cb5 <sys_open+0xdc>
      iunlockput(ip);
80105ca0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ca3:	89 04 24             	mov    %eax,(%esp)
80105ca6:	e8 f9 be ff ff       	call   80101ba4 <iunlockput>
      return -1;
80105cab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cb0:	e9 a8 00 00 00       	jmp    80105d5d <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105cb5:	e8 1a b3 ff ff       	call   80100fd4 <filealloc>
80105cba:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105cbd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105cc1:	74 14                	je     80105cd7 <sys_open+0xfe>
80105cc3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cc6:	89 04 24             	mov    %eax,(%esp)
80105cc9:	e8 43 f7 ff ff       	call   80105411 <fdalloc>
80105cce:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105cd1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105cd5:	79 23                	jns    80105cfa <sys_open+0x121>
    if(f)
80105cd7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105cdb:	74 0b                	je     80105ce8 <sys_open+0x10f>
      fileclose(f);
80105cdd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ce0:	89 04 24             	mov    %eax,(%esp)
80105ce3:	e8 94 b3 ff ff       	call   8010107c <fileclose>
    iunlockput(ip);
80105ce8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ceb:	89 04 24             	mov    %eax,(%esp)
80105cee:	e8 b1 be ff ff       	call   80101ba4 <iunlockput>
    return -1;
80105cf3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cf8:	eb 63                	jmp    80105d5d <sys_open+0x184>
  }
  iunlock(ip);
80105cfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cfd:	89 04 24             	mov    %eax,(%esp)
80105d00:	e8 69 bd ff ff       	call   80101a6e <iunlock>

  f->type = FD_INODE;
80105d05:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d08:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105d0e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d11:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105d14:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105d17:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d1a:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105d21:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d24:	83 e0 01             	and    $0x1,%eax
80105d27:	85 c0                	test   %eax,%eax
80105d29:	0f 94 c2             	sete   %dl
80105d2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d2f:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105d32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d35:	83 e0 01             	and    $0x1,%eax
80105d38:	84 c0                	test   %al,%al
80105d3a:	75 0a                	jne    80105d46 <sys_open+0x16d>
80105d3c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d3f:	83 e0 02             	and    $0x2,%eax
80105d42:	85 c0                	test   %eax,%eax
80105d44:	74 07                	je     80105d4d <sys_open+0x174>
80105d46:	b8 01 00 00 00       	mov    $0x1,%eax
80105d4b:	eb 05                	jmp    80105d52 <sys_open+0x179>
80105d4d:	b8 00 00 00 00       	mov    $0x0,%eax
80105d52:	89 c2                	mov    %eax,%edx
80105d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d57:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105d5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105d5d:	c9                   	leave  
80105d5e:	c3                   	ret    

80105d5f <sys_mkdir>:

int
sys_mkdir(void)
{
80105d5f:	55                   	push   %ebp
80105d60:	89 e5                	mov    %esp,%ebp
80105d62:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105d65:	e8 6b d5 ff ff       	call   801032d5 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105d6a:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d6d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d71:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d78:	e8 17 f5 ff ff       	call   80105294 <argstr>
80105d7d:	85 c0                	test   %eax,%eax
80105d7f:	78 2c                	js     80105dad <sys_mkdir+0x4e>
80105d81:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d84:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105d8b:	00 
80105d8c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105d93:	00 
80105d94:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105d9b:	00 
80105d9c:	89 04 24             	mov    %eax,(%esp)
80105d9f:	e8 75 fc ff ff       	call   80105a19 <create>
80105da4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105da7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105dab:	75 0c                	jne    80105db9 <sys_mkdir+0x5a>
    commit_trans();
80105dad:	e8 6c d5 ff ff       	call   8010331e <commit_trans>
    return -1;
80105db2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105db7:	eb 15                	jmp    80105dce <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105db9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dbc:	89 04 24             	mov    %eax,(%esp)
80105dbf:	e8 e0 bd ff ff       	call   80101ba4 <iunlockput>
  commit_trans();
80105dc4:	e8 55 d5 ff ff       	call   8010331e <commit_trans>
  return 0;
80105dc9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dce:	c9                   	leave  
80105dcf:	c3                   	ret    

80105dd0 <sys_mknod>:

int
sys_mknod(void)
{
80105dd0:	55                   	push   %ebp
80105dd1:	89 e5                	mov    %esp,%ebp
80105dd3:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105dd6:	e8 fa d4 ff ff       	call   801032d5 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105ddb:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105dde:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105de9:	e8 a6 f4 ff ff       	call   80105294 <argstr>
80105dee:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105df1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105df5:	78 5e                	js     80105e55 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105df7:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105dfa:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dfe:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e05:	e8 f0 f3 ff ff       	call   801051fa <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105e0a:	85 c0                	test   %eax,%eax
80105e0c:	78 47                	js     80105e55 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105e0e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105e11:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e15:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105e1c:	e8 d9 f3 ff ff       	call   801051fa <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105e21:	85 c0                	test   %eax,%eax
80105e23:	78 30                	js     80105e55 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105e25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e28:	0f bf c8             	movswl %ax,%ecx
80105e2b:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105e2e:	0f bf d0             	movswl %ax,%edx
80105e31:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105e34:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105e38:	89 54 24 08          	mov    %edx,0x8(%esp)
80105e3c:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105e43:	00 
80105e44:	89 04 24             	mov    %eax,(%esp)
80105e47:	e8 cd fb ff ff       	call   80105a19 <create>
80105e4c:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e4f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e53:	75 0c                	jne    80105e61 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105e55:	e8 c4 d4 ff ff       	call   8010331e <commit_trans>
    return -1;
80105e5a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e5f:	eb 15                	jmp    80105e76 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105e61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e64:	89 04 24             	mov    %eax,(%esp)
80105e67:	e8 38 bd ff ff       	call   80101ba4 <iunlockput>
  commit_trans();
80105e6c:	e8 ad d4 ff ff       	call   8010331e <commit_trans>
  return 0;
80105e71:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e76:	c9                   	leave  
80105e77:	c3                   	ret    

80105e78 <sys_chdir>:

int
sys_chdir(void)
{
80105e78:	55                   	push   %ebp
80105e79:	89 e5                	mov    %esp,%ebp
80105e7b:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105e7e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e81:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e85:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e8c:	e8 03 f4 ff ff       	call   80105294 <argstr>
80105e91:	85 c0                	test   %eax,%eax
80105e93:	78 14                	js     80105ea9 <sys_chdir+0x31>
80105e95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e98:	89 04 24             	mov    %eax,(%esp)
80105e9b:	e8 22 c6 ff ff       	call   801024c2 <namei>
80105ea0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ea3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ea7:	75 07                	jne    80105eb0 <sys_chdir+0x38>
    return -1;
80105ea9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eae:	eb 57                	jmp    80105f07 <sys_chdir+0x8f>
  ilock(ip);
80105eb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105eb3:	89 04 24             	mov    %eax,(%esp)
80105eb6:	e8 65 ba ff ff       	call   80101920 <ilock>
  if(ip->type != T_DIR){
80105ebb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ebe:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105ec2:	66 83 f8 01          	cmp    $0x1,%ax
80105ec6:	74 12                	je     80105eda <sys_chdir+0x62>
    iunlockput(ip);
80105ec8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ecb:	89 04 24             	mov    %eax,(%esp)
80105ece:	e8 d1 bc ff ff       	call   80101ba4 <iunlockput>
    return -1;
80105ed3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ed8:	eb 2d                	jmp    80105f07 <sys_chdir+0x8f>
  }
  iunlock(ip);
80105eda:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105edd:	89 04 24             	mov    %eax,(%esp)
80105ee0:	e8 89 bb ff ff       	call   80101a6e <iunlock>
  iput(proc->cwd);
80105ee5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105eeb:	8b 40 68             	mov    0x68(%eax),%eax
80105eee:	89 04 24             	mov    %eax,(%esp)
80105ef1:	e8 dd bb ff ff       	call   80101ad3 <iput>
  proc->cwd = ip;
80105ef6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105efc:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105eff:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105f02:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f07:	c9                   	leave  
80105f08:	c3                   	ret    

80105f09 <sys_exec>:

int
sys_exec(void)
{
80105f09:	55                   	push   %ebp
80105f0a:	89 e5                	mov    %esp,%ebp
80105f0c:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105f12:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f15:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f20:	e8 6f f3 ff ff       	call   80105294 <argstr>
80105f25:	85 c0                	test   %eax,%eax
80105f27:	78 1a                	js     80105f43 <sys_exec+0x3a>
80105f29:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105f2f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f33:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f3a:	e8 bb f2 ff ff       	call   801051fa <argint>
80105f3f:	85 c0                	test   %eax,%eax
80105f41:	79 0a                	jns    80105f4d <sys_exec+0x44>
    return -1;
80105f43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f48:	e9 e2 00 00 00       	jmp    8010602f <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80105f4d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80105f54:	00 
80105f55:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f5c:	00 
80105f5d:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105f63:	89 04 24             	mov    %eax,(%esp)
80105f66:	e8 3f ef ff ff       	call   80104eaa <memset>
  for(i=0;; i++){
80105f6b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80105f72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f75:	83 f8 1f             	cmp    $0x1f,%eax
80105f78:	76 0a                	jbe    80105f84 <sys_exec+0x7b>
      return -1;
80105f7a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f7f:	e9 ab 00 00 00       	jmp    8010602f <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80105f84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f87:	c1 e0 02             	shl    $0x2,%eax
80105f8a:	89 c2                	mov    %eax,%edx
80105f8c:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80105f92:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80105f95:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f9b:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80105fa1:	89 54 24 08          	mov    %edx,0x8(%esp)
80105fa5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105fa9:	89 04 24             	mov    %eax,(%esp)
80105fac:	e8 b7 f1 ff ff       	call   80105168 <fetchint>
80105fb1:	85 c0                	test   %eax,%eax
80105fb3:	79 07                	jns    80105fbc <sys_exec+0xb3>
      return -1;
80105fb5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fba:	eb 73                	jmp    8010602f <sys_exec+0x126>
    if(uarg == 0){
80105fbc:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80105fc2:	85 c0                	test   %eax,%eax
80105fc4:	75 26                	jne    80105fec <sys_exec+0xe3>
      argv[i] = 0;
80105fc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fc9:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80105fd0:	00 00 00 00 
      break;
80105fd4:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80105fd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fd8:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80105fde:	89 54 24 04          	mov    %edx,0x4(%esp)
80105fe2:	89 04 24             	mov    %eax,(%esp)
80105fe5:	e8 76 ab ff ff       	call   80100b60 <exec>
80105fea:	eb 43                	jmp    8010602f <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80105fec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fef:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105ff6:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105ffc:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80105fff:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106005:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010600b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
8010600f:	89 54 24 04          	mov    %edx,0x4(%esp)
80106013:	89 04 24             	mov    %eax,(%esp)
80106016:	e8 81 f1 ff ff       	call   8010519c <fetchstr>
8010601b:	85 c0                	test   %eax,%eax
8010601d:	79 07                	jns    80106026 <sys_exec+0x11d>
      return -1;
8010601f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106024:	eb 09                	jmp    8010602f <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
80106026:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
8010602a:	e9 43 ff ff ff       	jmp    80105f72 <sys_exec+0x69>
  return exec(path, argv);
}
8010602f:	c9                   	leave  
80106030:	c3                   	ret    

80106031 <sys_pipe>:

int
sys_pipe(void)
{
80106031:	55                   	push   %ebp
80106032:	89 e5                	mov    %esp,%ebp
80106034:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
80106037:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
8010603e:	00 
8010603f:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106042:	89 44 24 04          	mov    %eax,0x4(%esp)
80106046:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010604d:	e8 e0 f1 ff ff       	call   80105232 <argptr>
80106052:	85 c0                	test   %eax,%eax
80106054:	79 0a                	jns    80106060 <sys_pipe+0x2f>
    return -1;
80106056:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010605b:	e9 9b 00 00 00       	jmp    801060fb <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106060:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106063:	89 44 24 04          	mov    %eax,0x4(%esp)
80106067:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010606a:	89 04 24             	mov    %eax,(%esp)
8010606d:	e8 7e dc ff ff       	call   80103cf0 <pipealloc>
80106072:	85 c0                	test   %eax,%eax
80106074:	79 07                	jns    8010607d <sys_pipe+0x4c>
    return -1;
80106076:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010607b:	eb 7e                	jmp    801060fb <sys_pipe+0xca>
  fd0 = -1;
8010607d:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106084:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106087:	89 04 24             	mov    %eax,(%esp)
8010608a:	e8 82 f3 ff ff       	call   80105411 <fdalloc>
8010608f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106092:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106096:	78 14                	js     801060ac <sys_pipe+0x7b>
80106098:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010609b:	89 04 24             	mov    %eax,(%esp)
8010609e:	e8 6e f3 ff ff       	call   80105411 <fdalloc>
801060a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060a6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060aa:	79 37                	jns    801060e3 <sys_pipe+0xb2>
    if(fd0 >= 0)
801060ac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060b0:	78 14                	js     801060c6 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801060b2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060b8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060bb:	83 c2 08             	add    $0x8,%edx
801060be:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060c5:	00 
    fileclose(rf);
801060c6:	8b 45 e8             	mov    -0x18(%ebp),%eax
801060c9:	89 04 24             	mov    %eax,(%esp)
801060cc:	e8 ab af ff ff       	call   8010107c <fileclose>
    fileclose(wf);
801060d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060d4:	89 04 24             	mov    %eax,(%esp)
801060d7:	e8 a0 af ff ff       	call   8010107c <fileclose>
    return -1;
801060dc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060e1:	eb 18                	jmp    801060fb <sys_pipe+0xca>
  }
  fd[0] = fd0;
801060e3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801060e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060e9:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801060eb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801060ee:	8d 50 04             	lea    0x4(%eax),%edx
801060f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060f4:	89 02                	mov    %eax,(%edx)
  return 0;
801060f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060fb:	c9                   	leave  
801060fc:	c3                   	ret    
801060fd:	00 00                	add    %al,(%eax)
	...

80106100 <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
80106100:	55                   	push   %ebp
80106101:	89 e5                	mov    %esp,%ebp
80106103:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106106:	e8 9f e2 ff ff       	call   801043aa <fork>
}
8010610b:	c9                   	leave  
8010610c:	c3                   	ret    

8010610d <sys_exit>:

int
sys_exit(void)
{
8010610d:	55                   	push   %ebp
8010610e:	89 e5                	mov    %esp,%ebp
80106110:	83 ec 08             	sub    $0x8,%esp
  exit();
80106113:	e8 f5 e3 ff ff       	call   8010450d <exit>
  return 0;  // not reached
80106118:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010611d:	c9                   	leave  
8010611e:	c3                   	ret    

8010611f <sys_wait>:

int
sys_wait(void)
{
8010611f:	55                   	push   %ebp
80106120:	89 e5                	mov    %esp,%ebp
80106122:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106125:	e8 fb e4 ff ff       	call   80104625 <wait>
}
8010612a:	c9                   	leave  
8010612b:	c3                   	ret    

8010612c <sys_kill>:

int
sys_kill(void)
{
8010612c:	55                   	push   %ebp
8010612d:	89 e5                	mov    %esp,%ebp
8010612f:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106132:	8d 45 f4             	lea    -0xc(%ebp),%eax
80106135:	89 44 24 04          	mov    %eax,0x4(%esp)
80106139:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106140:	e8 b5 f0 ff ff       	call   801051fa <argint>
80106145:	85 c0                	test   %eax,%eax
80106147:	79 07                	jns    80106150 <sys_kill+0x24>
    return -1;
80106149:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010614e:	eb 0b                	jmp    8010615b <sys_kill+0x2f>
  return kill(pid);
80106150:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106153:	89 04 24             	mov    %eax,(%esp)
80106156:	e8 26 e9 ff ff       	call   80104a81 <kill>
}
8010615b:	c9                   	leave  
8010615c:	c3                   	ret    

8010615d <sys_getpid>:

int
sys_getpid(void)
{
8010615d:	55                   	push   %ebp
8010615e:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106160:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106166:	8b 40 10             	mov    0x10(%eax),%eax
}
80106169:	5d                   	pop    %ebp
8010616a:	c3                   	ret    

8010616b <sys_sbrk>:

int
sys_sbrk(void)
{
8010616b:	55                   	push   %ebp
8010616c:	89 e5                	mov    %esp,%ebp
8010616e:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106171:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106174:	89 44 24 04          	mov    %eax,0x4(%esp)
80106178:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010617f:	e8 76 f0 ff ff       	call   801051fa <argint>
80106184:	85 c0                	test   %eax,%eax
80106186:	79 07                	jns    8010618f <sys_sbrk+0x24>
    return -1;
80106188:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010618d:	eb 24                	jmp    801061b3 <sys_sbrk+0x48>
  addr = proc->sz;
8010618f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106195:	8b 00                	mov    (%eax),%eax
80106197:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010619a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010619d:	89 04 24             	mov    %eax,(%esp)
801061a0:	e8 60 e1 ff ff       	call   80104305 <growproc>
801061a5:	85 c0                	test   %eax,%eax
801061a7:	79 07                	jns    801061b0 <sys_sbrk+0x45>
    return -1;
801061a9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061ae:	eb 03                	jmp    801061b3 <sys_sbrk+0x48>
  return addr;
801061b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801061b3:	c9                   	leave  
801061b4:	c3                   	ret    

801061b5 <sys_sleep>:

int
sys_sleep(void)
{
801061b5:	55                   	push   %ebp
801061b6:	89 e5                	mov    %esp,%ebp
801061b8:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801061bb:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061be:	89 44 24 04          	mov    %eax,0x4(%esp)
801061c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061c9:	e8 2c f0 ff ff       	call   801051fa <argint>
801061ce:	85 c0                	test   %eax,%eax
801061d0:	79 07                	jns    801061d9 <sys_sleep+0x24>
    return -1;
801061d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d7:	eb 6c                	jmp    80106245 <sys_sleep+0x90>
  acquire(&tickslock);
801061d9:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
801061e0:	e8 76 ea ff ff       	call   80104c5b <acquire>
  ticks0 = ticks;
801061e5:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
801061ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801061ed:	eb 34                	jmp    80106223 <sys_sleep+0x6e>
    if(proc->killed){
801061ef:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061f5:	8b 40 24             	mov    0x24(%eax),%eax
801061f8:	85 c0                	test   %eax,%eax
801061fa:	74 13                	je     8010620f <sys_sleep+0x5a>
      release(&tickslock);
801061fc:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106203:	e8 b5 ea ff ff       	call   80104cbd <release>
      return -1;
80106208:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010620d:	eb 36                	jmp    80106245 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
8010620f:	c7 44 24 04 60 23 11 	movl   $0x80112360,0x4(%esp)
80106216:	80 
80106217:	c7 04 24 a0 2b 11 80 	movl   $0x80112ba0,(%esp)
8010621e:	e8 5a e7 ff ff       	call   8010497d <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106223:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
80106228:	89 c2                	mov    %eax,%edx
8010622a:	2b 55 f4             	sub    -0xc(%ebp),%edx
8010622d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106230:	39 c2                	cmp    %eax,%edx
80106232:	72 bb                	jb     801061ef <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106234:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
8010623b:	e8 7d ea ff ff       	call   80104cbd <release>
  return 0;
80106240:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106245:	c9                   	leave  
80106246:	c3                   	ret    

80106247 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106247:	55                   	push   %ebp
80106248:	89 e5                	mov    %esp,%ebp
8010624a:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
8010624d:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106254:	e8 02 ea ff ff       	call   80104c5b <acquire>
  xticks = ticks;
80106259:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
8010625e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106261:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106268:	e8 50 ea ff ff       	call   80104cbd <release>
  return xticks;
8010626d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106270:	c9                   	leave  
80106271:	c3                   	ret    
	...

80106274 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106274:	55                   	push   %ebp
80106275:	89 e5                	mov    %esp,%ebp
80106277:	83 ec 08             	sub    $0x8,%esp
8010627a:	8b 55 08             	mov    0x8(%ebp),%edx
8010627d:	8b 45 0c             	mov    0xc(%ebp),%eax
80106280:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106284:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106287:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010628b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010628f:	ee                   	out    %al,(%dx)
}
80106290:	c9                   	leave  
80106291:	c3                   	ret    

80106292 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106292:	55                   	push   %ebp
80106293:	89 e5                	mov    %esp,%ebp
80106295:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
80106298:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
8010629f:	00 
801062a0:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801062a7:	e8 c8 ff ff ff       	call   80106274 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801062ac:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801062b3:	00 
801062b4:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801062bb:	e8 b4 ff ff ff       	call   80106274 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801062c0:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801062c7:	00 
801062c8:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801062cf:	e8 a0 ff ff ff       	call   80106274 <outb>
  picenable(IRQ_TIMER);
801062d4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801062db:	e8 99 d8 ff ff       	call   80103b79 <picenable>
}
801062e0:	c9                   	leave  
801062e1:	c3                   	ret    
	...

801062e4 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
801062e4:	1e                   	push   %ds
  pushl %es
801062e5:	06                   	push   %es
  pushl %fs
801062e6:	0f a0                	push   %fs
  pushl %gs
801062e8:	0f a8                	push   %gs
  pushal
801062ea:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
801062eb:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
801062ef:	8e d8                	mov    %eax,%ds
  movw %ax, %es
801062f1:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
801062f3:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
801062f7:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
801062f9:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
801062fb:	54                   	push   %esp
  call trap
801062fc:	e8 de 01 00 00       	call   801064df <trap>
  addl $4, %esp
80106301:	83 c4 04             	add    $0x4,%esp

80106304 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106304:	61                   	popa   
  popl %gs
80106305:	0f a9                	pop    %gs
  popl %fs
80106307:	0f a1                	pop    %fs
  popl %es
80106309:	07                   	pop    %es
  popl %ds
8010630a:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010630b:	83 c4 08             	add    $0x8,%esp
  iret
8010630e:	cf                   	iret   
	...

80106310 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106310:	55                   	push   %ebp
80106311:	89 e5                	mov    %esp,%ebp
80106313:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106316:	8b 45 0c             	mov    0xc(%ebp),%eax
80106319:	83 e8 01             	sub    $0x1,%eax
8010631c:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106320:	8b 45 08             	mov    0x8(%ebp),%eax
80106323:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106327:	8b 45 08             	mov    0x8(%ebp),%eax
8010632a:	c1 e8 10             	shr    $0x10,%eax
8010632d:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106331:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106334:	0f 01 18             	lidtl  (%eax)
}
80106337:	c9                   	leave  
80106338:	c3                   	ret    

80106339 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106339:	55                   	push   %ebp
8010633a:	89 e5                	mov    %esp,%ebp
8010633c:	53                   	push   %ebx
8010633d:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106340:	0f 20 d3             	mov    %cr2,%ebx
80106343:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
80106346:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80106349:	83 c4 10             	add    $0x10,%esp
8010634c:	5b                   	pop    %ebx
8010634d:	5d                   	pop    %ebp
8010634e:	c3                   	ret    

8010634f <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
8010634f:	55                   	push   %ebp
80106350:	89 e5                	mov    %esp,%ebp
80106352:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106355:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010635c:	e9 c3 00 00 00       	jmp    80106424 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106361:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106364:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
8010636b:	89 c2                	mov    %eax,%edx
8010636d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106370:	66 89 14 c5 a0 23 11 	mov    %dx,-0x7feedc60(,%eax,8)
80106377:	80 
80106378:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637b:	66 c7 04 c5 a2 23 11 	movw   $0x8,-0x7feedc5e(,%eax,8)
80106382:	80 08 00 
80106385:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106388:	0f b6 14 c5 a4 23 11 	movzbl -0x7feedc5c(,%eax,8),%edx
8010638f:	80 
80106390:	83 e2 e0             	and    $0xffffffe0,%edx
80106393:	88 14 c5 a4 23 11 80 	mov    %dl,-0x7feedc5c(,%eax,8)
8010639a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010639d:	0f b6 14 c5 a4 23 11 	movzbl -0x7feedc5c(,%eax,8),%edx
801063a4:	80 
801063a5:	83 e2 1f             	and    $0x1f,%edx
801063a8:	88 14 c5 a4 23 11 80 	mov    %dl,-0x7feedc5c(,%eax,8)
801063af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063b2:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
801063b9:	80 
801063ba:	83 e2 f0             	and    $0xfffffff0,%edx
801063bd:	83 ca 0e             	or     $0xe,%edx
801063c0:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
801063c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063ca:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
801063d1:	80 
801063d2:	83 e2 ef             	and    $0xffffffef,%edx
801063d5:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
801063dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063df:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
801063e6:	80 
801063e7:	83 e2 9f             	and    $0xffffff9f,%edx
801063ea:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
801063f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063f4:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
801063fb:	80 
801063fc:	83 ca 80             	or     $0xffffff80,%edx
801063ff:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
80106406:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106409:	8b 04 85 98 b0 10 80 	mov    -0x7fef4f68(,%eax,4),%eax
80106410:	c1 e8 10             	shr    $0x10,%eax
80106413:	89 c2                	mov    %eax,%edx
80106415:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106418:	66 89 14 c5 a6 23 11 	mov    %dx,-0x7feedc5a(,%eax,8)
8010641f:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106420:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106424:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010642b:	0f 8e 30 ff ff ff    	jle    80106361 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106431:	a1 98 b1 10 80       	mov    0x8010b198,%eax
80106436:	66 a3 a0 25 11 80    	mov    %ax,0x801125a0
8010643c:	66 c7 05 a2 25 11 80 	movw   $0x8,0x801125a2
80106443:	08 00 
80106445:	0f b6 05 a4 25 11 80 	movzbl 0x801125a4,%eax
8010644c:	83 e0 e0             	and    $0xffffffe0,%eax
8010644f:	a2 a4 25 11 80       	mov    %al,0x801125a4
80106454:	0f b6 05 a4 25 11 80 	movzbl 0x801125a4,%eax
8010645b:	83 e0 1f             	and    $0x1f,%eax
8010645e:	a2 a4 25 11 80       	mov    %al,0x801125a4
80106463:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
8010646a:	83 c8 0f             	or     $0xf,%eax
8010646d:	a2 a5 25 11 80       	mov    %al,0x801125a5
80106472:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
80106479:	83 e0 ef             	and    $0xffffffef,%eax
8010647c:	a2 a5 25 11 80       	mov    %al,0x801125a5
80106481:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
80106488:	83 c8 60             	or     $0x60,%eax
8010648b:	a2 a5 25 11 80       	mov    %al,0x801125a5
80106490:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
80106497:	83 c8 80             	or     $0xffffff80,%eax
8010649a:	a2 a5 25 11 80       	mov    %al,0x801125a5
8010649f:	a1 98 b1 10 80       	mov    0x8010b198,%eax
801064a4:	c1 e8 10             	shr    $0x10,%eax
801064a7:	66 a3 a6 25 11 80    	mov    %ax,0x801125a6
  
  initlock(&tickslock, "time");
801064ad:	c7 44 24 04 f0 86 10 	movl   $0x801086f0,0x4(%esp)
801064b4:	80 
801064b5:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
801064bc:	e8 79 e7 ff ff       	call   80104c3a <initlock>
}
801064c1:	c9                   	leave  
801064c2:	c3                   	ret    

801064c3 <idtinit>:

void
idtinit(void)
{
801064c3:	55                   	push   %ebp
801064c4:	89 e5                	mov    %esp,%ebp
801064c6:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801064c9:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
801064d0:	00 
801064d1:	c7 04 24 a0 23 11 80 	movl   $0x801123a0,(%esp)
801064d8:	e8 33 fe ff ff       	call   80106310 <lidt>
}
801064dd:	c9                   	leave  
801064de:	c3                   	ret    

801064df <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
801064df:	55                   	push   %ebp
801064e0:	89 e5                	mov    %esp,%ebp
801064e2:	57                   	push   %edi
801064e3:	56                   	push   %esi
801064e4:	53                   	push   %ebx
801064e5:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
801064e8:	8b 45 08             	mov    0x8(%ebp),%eax
801064eb:	8b 40 30             	mov    0x30(%eax),%eax
801064ee:	83 f8 40             	cmp    $0x40,%eax
801064f1:	75 3e                	jne    80106531 <trap+0x52>
    if(proc->killed)
801064f3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064f9:	8b 40 24             	mov    0x24(%eax),%eax
801064fc:	85 c0                	test   %eax,%eax
801064fe:	74 05                	je     80106505 <trap+0x26>
      exit();
80106500:	e8 08 e0 ff ff       	call   8010450d <exit>
    proc->tf = tf;
80106505:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010650b:	8b 55 08             	mov    0x8(%ebp),%edx
8010650e:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106511:	e8 c1 ed ff ff       	call   801052d7 <syscall>
    if(proc->killed)
80106516:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010651c:	8b 40 24             	mov    0x24(%eax),%eax
8010651f:	85 c0                	test   %eax,%eax
80106521:	0f 84 34 02 00 00    	je     8010675b <trap+0x27c>
      exit();
80106527:	e8 e1 df ff ff       	call   8010450d <exit>
    return;
8010652c:	e9 2a 02 00 00       	jmp    8010675b <trap+0x27c>
  }

  switch(tf->trapno){
80106531:	8b 45 08             	mov    0x8(%ebp),%eax
80106534:	8b 40 30             	mov    0x30(%eax),%eax
80106537:	83 e8 20             	sub    $0x20,%eax
8010653a:	83 f8 1f             	cmp    $0x1f,%eax
8010653d:	0f 87 bc 00 00 00    	ja     801065ff <trap+0x120>
80106543:	8b 04 85 98 87 10 80 	mov    -0x7fef7868(,%eax,4),%eax
8010654a:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
8010654c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106552:	0f b6 00             	movzbl (%eax),%eax
80106555:	84 c0                	test   %al,%al
80106557:	75 31                	jne    8010658a <trap+0xab>
      acquire(&tickslock);
80106559:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106560:	e8 f6 e6 ff ff       	call   80104c5b <acquire>
      ticks++;
80106565:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
8010656a:	83 c0 01             	add    $0x1,%eax
8010656d:	a3 a0 2b 11 80       	mov    %eax,0x80112ba0
      wakeup(&ticks);
80106572:	c7 04 24 a0 2b 11 80 	movl   $0x80112ba0,(%esp)
80106579:	e8 d8 e4 ff ff       	call   80104a56 <wakeup>
      release(&tickslock);
8010657e:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106585:	e8 33 e7 ff ff       	call   80104cbd <release>
    }
    lapiceoi();
8010658a:	e8 12 ca ff ff       	call   80102fa1 <lapiceoi>
    break;
8010658f:	e9 41 01 00 00       	jmp    801066d5 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106594:	e8 10 c2 ff ff       	call   801027a9 <ideintr>
    lapiceoi();
80106599:	e8 03 ca ff ff       	call   80102fa1 <lapiceoi>
    break;
8010659e:	e9 32 01 00 00       	jmp    801066d5 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801065a3:	e8 d7 c7 ff ff       	call   80102d7f <kbdintr>
    lapiceoi();
801065a8:	e8 f4 c9 ff ff       	call   80102fa1 <lapiceoi>
    break;
801065ad:	e9 23 01 00 00       	jmp    801066d5 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801065b2:	e8 a9 03 00 00       	call   80106960 <uartintr>
    lapiceoi();
801065b7:	e8 e5 c9 ff ff       	call   80102fa1 <lapiceoi>
    break;
801065bc:	e9 14 01 00 00       	jmp    801066d5 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
801065c1:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801065c4:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801065c7:	8b 45 08             	mov    0x8(%ebp),%eax
801065ca:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801065ce:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
801065d1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801065d7:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801065da:	0f b6 c0             	movzbl %al,%eax
801065dd:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801065e1:	89 54 24 08          	mov    %edx,0x8(%esp)
801065e5:	89 44 24 04          	mov    %eax,0x4(%esp)
801065e9:	c7 04 24 f8 86 10 80 	movl   $0x801086f8,(%esp)
801065f0:	e8 ac 9d ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
801065f5:	e8 a7 c9 ff ff       	call   80102fa1 <lapiceoi>
    break;
801065fa:	e9 d6 00 00 00       	jmp    801066d5 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
801065ff:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106605:	85 c0                	test   %eax,%eax
80106607:	74 11                	je     8010661a <trap+0x13b>
80106609:	8b 45 08             	mov    0x8(%ebp),%eax
8010660c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106610:	0f b7 c0             	movzwl %ax,%eax
80106613:	83 e0 03             	and    $0x3,%eax
80106616:	85 c0                	test   %eax,%eax
80106618:	75 46                	jne    80106660 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010661a:	e8 1a fd ff ff       	call   80106339 <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
8010661f:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106622:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106625:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010662c:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010662f:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106632:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106635:	8b 52 30             	mov    0x30(%edx),%edx
80106638:	89 44 24 10          	mov    %eax,0x10(%esp)
8010663c:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106640:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106644:	89 54 24 04          	mov    %edx,0x4(%esp)
80106648:	c7 04 24 1c 87 10 80 	movl   $0x8010871c,(%esp)
8010664f:	e8 4d 9d ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106654:	c7 04 24 4e 87 10 80 	movl   $0x8010874e,(%esp)
8010665b:	e8 dd 9e ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106660:	e8 d4 fc ff ff       	call   80106339 <rcr2>
80106665:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106667:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010666a:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010666d:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106673:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106676:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106679:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010667c:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010667f:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106682:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106685:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010668b:	83 c0 6c             	add    $0x6c,%eax
8010668e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106691:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106697:	8b 40 10             	mov    0x10(%eax),%eax
8010669a:	89 54 24 1c          	mov    %edx,0x1c(%esp)
8010669e:	89 7c 24 18          	mov    %edi,0x18(%esp)
801066a2:	89 74 24 14          	mov    %esi,0x14(%esp)
801066a6:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801066aa:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801066ae:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801066b1:	89 54 24 08          	mov    %edx,0x8(%esp)
801066b5:	89 44 24 04          	mov    %eax,0x4(%esp)
801066b9:	c7 04 24 54 87 10 80 	movl   $0x80108754,(%esp)
801066c0:	e8 dc 9c ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801066c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066cb:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
801066d2:	eb 01                	jmp    801066d5 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
801066d4:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
801066d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066db:	85 c0                	test   %eax,%eax
801066dd:	74 24                	je     80106703 <trap+0x224>
801066df:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066e5:	8b 40 24             	mov    0x24(%eax),%eax
801066e8:	85 c0                	test   %eax,%eax
801066ea:	74 17                	je     80106703 <trap+0x224>
801066ec:	8b 45 08             	mov    0x8(%ebp),%eax
801066ef:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801066f3:	0f b7 c0             	movzwl %ax,%eax
801066f6:	83 e0 03             	and    $0x3,%eax
801066f9:	83 f8 03             	cmp    $0x3,%eax
801066fc:	75 05                	jne    80106703 <trap+0x224>
    exit();
801066fe:	e8 0a de ff ff       	call   8010450d <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106703:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106709:	85 c0                	test   %eax,%eax
8010670b:	74 1e                	je     8010672b <trap+0x24c>
8010670d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106713:	8b 40 0c             	mov    0xc(%eax),%eax
80106716:	83 f8 04             	cmp    $0x4,%eax
80106719:	75 10                	jne    8010672b <trap+0x24c>
8010671b:	8b 45 08             	mov    0x8(%ebp),%eax
8010671e:	8b 40 30             	mov    0x30(%eax),%eax
80106721:	83 f8 20             	cmp    $0x20,%eax
80106724:	75 05                	jne    8010672b <trap+0x24c>
    yield();
80106726:	e8 f4 e1 ff ff       	call   8010491f <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010672b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106731:	85 c0                	test   %eax,%eax
80106733:	74 27                	je     8010675c <trap+0x27d>
80106735:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010673b:	8b 40 24             	mov    0x24(%eax),%eax
8010673e:	85 c0                	test   %eax,%eax
80106740:	74 1a                	je     8010675c <trap+0x27d>
80106742:	8b 45 08             	mov    0x8(%ebp),%eax
80106745:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106749:	0f b7 c0             	movzwl %ax,%eax
8010674c:	83 e0 03             	and    $0x3,%eax
8010674f:	83 f8 03             	cmp    $0x3,%eax
80106752:	75 08                	jne    8010675c <trap+0x27d>
    exit();
80106754:	e8 b4 dd ff ff       	call   8010450d <exit>
80106759:	eb 01                	jmp    8010675c <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
8010675b:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
8010675c:	83 c4 3c             	add    $0x3c,%esp
8010675f:	5b                   	pop    %ebx
80106760:	5e                   	pop    %esi
80106761:	5f                   	pop    %edi
80106762:	5d                   	pop    %ebp
80106763:	c3                   	ret    

80106764 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106764:	55                   	push   %ebp
80106765:	89 e5                	mov    %esp,%ebp
80106767:	53                   	push   %ebx
80106768:	83 ec 14             	sub    $0x14,%esp
8010676b:	8b 45 08             	mov    0x8(%ebp),%eax
8010676e:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106772:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106776:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
8010677a:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
8010677e:	ec                   	in     (%dx),%al
8010677f:	89 c3                	mov    %eax,%ebx
80106781:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106784:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106788:	83 c4 14             	add    $0x14,%esp
8010678b:	5b                   	pop    %ebx
8010678c:	5d                   	pop    %ebp
8010678d:	c3                   	ret    

8010678e <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010678e:	55                   	push   %ebp
8010678f:	89 e5                	mov    %esp,%ebp
80106791:	83 ec 08             	sub    $0x8,%esp
80106794:	8b 55 08             	mov    0x8(%ebp),%edx
80106797:	8b 45 0c             	mov    0xc(%ebp),%eax
8010679a:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010679e:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801067a1:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801067a5:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801067a9:	ee                   	out    %al,(%dx)
}
801067aa:	c9                   	leave  
801067ab:	c3                   	ret    

801067ac <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801067ac:	55                   	push   %ebp
801067ad:	89 e5                	mov    %esp,%ebp
801067af:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801067b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067b9:	00 
801067ba:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801067c1:	e8 c8 ff ff ff       	call   8010678e <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801067c6:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
801067cd:	00 
801067ce:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
801067d5:	e8 b4 ff ff ff       	call   8010678e <outb>
  outb(COM1+0, 115200/9600);
801067da:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
801067e1:	00 
801067e2:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
801067e9:	e8 a0 ff ff ff       	call   8010678e <outb>
  outb(COM1+1, 0);
801067ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067f5:	00 
801067f6:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
801067fd:	e8 8c ff ff ff       	call   8010678e <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106802:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106809:	00 
8010680a:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106811:	e8 78 ff ff ff       	call   8010678e <outb>
  outb(COM1+4, 0);
80106816:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010681d:	00 
8010681e:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106825:	e8 64 ff ff ff       	call   8010678e <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010682a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106831:	00 
80106832:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106839:	e8 50 ff ff ff       	call   8010678e <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
8010683e:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106845:	e8 1a ff ff ff       	call   80106764 <inb>
8010684a:	3c ff                	cmp    $0xff,%al
8010684c:	74 6c                	je     801068ba <uartinit+0x10e>
    return;
  uart = 1;
8010684e:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106855:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106858:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
8010685f:	e8 00 ff ff ff       	call   80106764 <inb>
  inb(COM1+0);
80106864:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010686b:	e8 f4 fe ff ff       	call   80106764 <inb>
  picenable(IRQ_COM1);
80106870:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106877:	e8 fd d2 ff ff       	call   80103b79 <picenable>
  ioapicenable(IRQ_COM1, 0);
8010687c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106883:	00 
80106884:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
8010688b:	e8 9e c1 ff ff       	call   80102a2e <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106890:	c7 45 f4 18 88 10 80 	movl   $0x80108818,-0xc(%ebp)
80106897:	eb 15                	jmp    801068ae <uartinit+0x102>
    uartputc(*p);
80106899:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010689c:	0f b6 00             	movzbl (%eax),%eax
8010689f:	0f be c0             	movsbl %al,%eax
801068a2:	89 04 24             	mov    %eax,(%esp)
801068a5:	e8 13 00 00 00       	call   801068bd <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801068aa:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801068ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068b1:	0f b6 00             	movzbl (%eax),%eax
801068b4:	84 c0                	test   %al,%al
801068b6:	75 e1                	jne    80106899 <uartinit+0xed>
801068b8:	eb 01                	jmp    801068bb <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
801068ba:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
801068bb:	c9                   	leave  
801068bc:	c3                   	ret    

801068bd <uartputc>:

void
uartputc(int c)
{
801068bd:	55                   	push   %ebp
801068be:	89 e5                	mov    %esp,%ebp
801068c0:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
801068c3:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
801068c8:	85 c0                	test   %eax,%eax
801068ca:	74 4d                	je     80106919 <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801068cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801068d3:	eb 10                	jmp    801068e5 <uartputc+0x28>
    microdelay(10);
801068d5:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
801068dc:	e8 e5 c6 ff ff       	call   80102fc6 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
801068e1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801068e5:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
801068e9:	7f 16                	jg     80106901 <uartputc+0x44>
801068eb:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
801068f2:	e8 6d fe ff ff       	call   80106764 <inb>
801068f7:	0f b6 c0             	movzbl %al,%eax
801068fa:	83 e0 20             	and    $0x20,%eax
801068fd:	85 c0                	test   %eax,%eax
801068ff:	74 d4                	je     801068d5 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106901:	8b 45 08             	mov    0x8(%ebp),%eax
80106904:	0f b6 c0             	movzbl %al,%eax
80106907:	89 44 24 04          	mov    %eax,0x4(%esp)
8010690b:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106912:	e8 77 fe ff ff       	call   8010678e <outb>
80106917:	eb 01                	jmp    8010691a <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106919:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
8010691a:	c9                   	leave  
8010691b:	c3                   	ret    

8010691c <uartgetc>:

static int
uartgetc(void)
{
8010691c:	55                   	push   %ebp
8010691d:	89 e5                	mov    %esp,%ebp
8010691f:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106922:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
80106927:	85 c0                	test   %eax,%eax
80106929:	75 07                	jne    80106932 <uartgetc+0x16>
    return -1;
8010692b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106930:	eb 2c                	jmp    8010695e <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106932:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106939:	e8 26 fe ff ff       	call   80106764 <inb>
8010693e:	0f b6 c0             	movzbl %al,%eax
80106941:	83 e0 01             	and    $0x1,%eax
80106944:	85 c0                	test   %eax,%eax
80106946:	75 07                	jne    8010694f <uartgetc+0x33>
    return -1;
80106948:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010694d:	eb 0f                	jmp    8010695e <uartgetc+0x42>
  return inb(COM1+0);
8010694f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106956:	e8 09 fe ff ff       	call   80106764 <inb>
8010695b:	0f b6 c0             	movzbl %al,%eax
}
8010695e:	c9                   	leave  
8010695f:	c3                   	ret    

80106960 <uartintr>:

void
uartintr(void)
{
80106960:	55                   	push   %ebp
80106961:	89 e5                	mov    %esp,%ebp
80106963:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106966:	c7 04 24 1c 69 10 80 	movl   $0x8010691c,(%esp)
8010696d:	e8 3b 9e ff ff       	call   801007ad <consoleintr>
}
80106972:	c9                   	leave  
80106973:	c3                   	ret    

80106974 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106974:	6a 00                	push   $0x0
  pushl $0
80106976:	6a 00                	push   $0x0
  jmp alltraps
80106978:	e9 67 f9 ff ff       	jmp    801062e4 <alltraps>

8010697d <vector1>:
.globl vector1
vector1:
  pushl $0
8010697d:	6a 00                	push   $0x0
  pushl $1
8010697f:	6a 01                	push   $0x1
  jmp alltraps
80106981:	e9 5e f9 ff ff       	jmp    801062e4 <alltraps>

80106986 <vector2>:
.globl vector2
vector2:
  pushl $0
80106986:	6a 00                	push   $0x0
  pushl $2
80106988:	6a 02                	push   $0x2
  jmp alltraps
8010698a:	e9 55 f9 ff ff       	jmp    801062e4 <alltraps>

8010698f <vector3>:
.globl vector3
vector3:
  pushl $0
8010698f:	6a 00                	push   $0x0
  pushl $3
80106991:	6a 03                	push   $0x3
  jmp alltraps
80106993:	e9 4c f9 ff ff       	jmp    801062e4 <alltraps>

80106998 <vector4>:
.globl vector4
vector4:
  pushl $0
80106998:	6a 00                	push   $0x0
  pushl $4
8010699a:	6a 04                	push   $0x4
  jmp alltraps
8010699c:	e9 43 f9 ff ff       	jmp    801062e4 <alltraps>

801069a1 <vector5>:
.globl vector5
vector5:
  pushl $0
801069a1:	6a 00                	push   $0x0
  pushl $5
801069a3:	6a 05                	push   $0x5
  jmp alltraps
801069a5:	e9 3a f9 ff ff       	jmp    801062e4 <alltraps>

801069aa <vector6>:
.globl vector6
vector6:
  pushl $0
801069aa:	6a 00                	push   $0x0
  pushl $6
801069ac:	6a 06                	push   $0x6
  jmp alltraps
801069ae:	e9 31 f9 ff ff       	jmp    801062e4 <alltraps>

801069b3 <vector7>:
.globl vector7
vector7:
  pushl $0
801069b3:	6a 00                	push   $0x0
  pushl $7
801069b5:	6a 07                	push   $0x7
  jmp alltraps
801069b7:	e9 28 f9 ff ff       	jmp    801062e4 <alltraps>

801069bc <vector8>:
.globl vector8
vector8:
  pushl $8
801069bc:	6a 08                	push   $0x8
  jmp alltraps
801069be:	e9 21 f9 ff ff       	jmp    801062e4 <alltraps>

801069c3 <vector9>:
.globl vector9
vector9:
  pushl $0
801069c3:	6a 00                	push   $0x0
  pushl $9
801069c5:	6a 09                	push   $0x9
  jmp alltraps
801069c7:	e9 18 f9 ff ff       	jmp    801062e4 <alltraps>

801069cc <vector10>:
.globl vector10
vector10:
  pushl $10
801069cc:	6a 0a                	push   $0xa
  jmp alltraps
801069ce:	e9 11 f9 ff ff       	jmp    801062e4 <alltraps>

801069d3 <vector11>:
.globl vector11
vector11:
  pushl $11
801069d3:	6a 0b                	push   $0xb
  jmp alltraps
801069d5:	e9 0a f9 ff ff       	jmp    801062e4 <alltraps>

801069da <vector12>:
.globl vector12
vector12:
  pushl $12
801069da:	6a 0c                	push   $0xc
  jmp alltraps
801069dc:	e9 03 f9 ff ff       	jmp    801062e4 <alltraps>

801069e1 <vector13>:
.globl vector13
vector13:
  pushl $13
801069e1:	6a 0d                	push   $0xd
  jmp alltraps
801069e3:	e9 fc f8 ff ff       	jmp    801062e4 <alltraps>

801069e8 <vector14>:
.globl vector14
vector14:
  pushl $14
801069e8:	6a 0e                	push   $0xe
  jmp alltraps
801069ea:	e9 f5 f8 ff ff       	jmp    801062e4 <alltraps>

801069ef <vector15>:
.globl vector15
vector15:
  pushl $0
801069ef:	6a 00                	push   $0x0
  pushl $15
801069f1:	6a 0f                	push   $0xf
  jmp alltraps
801069f3:	e9 ec f8 ff ff       	jmp    801062e4 <alltraps>

801069f8 <vector16>:
.globl vector16
vector16:
  pushl $0
801069f8:	6a 00                	push   $0x0
  pushl $16
801069fa:	6a 10                	push   $0x10
  jmp alltraps
801069fc:	e9 e3 f8 ff ff       	jmp    801062e4 <alltraps>

80106a01 <vector17>:
.globl vector17
vector17:
  pushl $17
80106a01:	6a 11                	push   $0x11
  jmp alltraps
80106a03:	e9 dc f8 ff ff       	jmp    801062e4 <alltraps>

80106a08 <vector18>:
.globl vector18
vector18:
  pushl $0
80106a08:	6a 00                	push   $0x0
  pushl $18
80106a0a:	6a 12                	push   $0x12
  jmp alltraps
80106a0c:	e9 d3 f8 ff ff       	jmp    801062e4 <alltraps>

80106a11 <vector19>:
.globl vector19
vector19:
  pushl $0
80106a11:	6a 00                	push   $0x0
  pushl $19
80106a13:	6a 13                	push   $0x13
  jmp alltraps
80106a15:	e9 ca f8 ff ff       	jmp    801062e4 <alltraps>

80106a1a <vector20>:
.globl vector20
vector20:
  pushl $0
80106a1a:	6a 00                	push   $0x0
  pushl $20
80106a1c:	6a 14                	push   $0x14
  jmp alltraps
80106a1e:	e9 c1 f8 ff ff       	jmp    801062e4 <alltraps>

80106a23 <vector21>:
.globl vector21
vector21:
  pushl $0
80106a23:	6a 00                	push   $0x0
  pushl $21
80106a25:	6a 15                	push   $0x15
  jmp alltraps
80106a27:	e9 b8 f8 ff ff       	jmp    801062e4 <alltraps>

80106a2c <vector22>:
.globl vector22
vector22:
  pushl $0
80106a2c:	6a 00                	push   $0x0
  pushl $22
80106a2e:	6a 16                	push   $0x16
  jmp alltraps
80106a30:	e9 af f8 ff ff       	jmp    801062e4 <alltraps>

80106a35 <vector23>:
.globl vector23
vector23:
  pushl $0
80106a35:	6a 00                	push   $0x0
  pushl $23
80106a37:	6a 17                	push   $0x17
  jmp alltraps
80106a39:	e9 a6 f8 ff ff       	jmp    801062e4 <alltraps>

80106a3e <vector24>:
.globl vector24
vector24:
  pushl $0
80106a3e:	6a 00                	push   $0x0
  pushl $24
80106a40:	6a 18                	push   $0x18
  jmp alltraps
80106a42:	e9 9d f8 ff ff       	jmp    801062e4 <alltraps>

80106a47 <vector25>:
.globl vector25
vector25:
  pushl $0
80106a47:	6a 00                	push   $0x0
  pushl $25
80106a49:	6a 19                	push   $0x19
  jmp alltraps
80106a4b:	e9 94 f8 ff ff       	jmp    801062e4 <alltraps>

80106a50 <vector26>:
.globl vector26
vector26:
  pushl $0
80106a50:	6a 00                	push   $0x0
  pushl $26
80106a52:	6a 1a                	push   $0x1a
  jmp alltraps
80106a54:	e9 8b f8 ff ff       	jmp    801062e4 <alltraps>

80106a59 <vector27>:
.globl vector27
vector27:
  pushl $0
80106a59:	6a 00                	push   $0x0
  pushl $27
80106a5b:	6a 1b                	push   $0x1b
  jmp alltraps
80106a5d:	e9 82 f8 ff ff       	jmp    801062e4 <alltraps>

80106a62 <vector28>:
.globl vector28
vector28:
  pushl $0
80106a62:	6a 00                	push   $0x0
  pushl $28
80106a64:	6a 1c                	push   $0x1c
  jmp alltraps
80106a66:	e9 79 f8 ff ff       	jmp    801062e4 <alltraps>

80106a6b <vector29>:
.globl vector29
vector29:
  pushl $0
80106a6b:	6a 00                	push   $0x0
  pushl $29
80106a6d:	6a 1d                	push   $0x1d
  jmp alltraps
80106a6f:	e9 70 f8 ff ff       	jmp    801062e4 <alltraps>

80106a74 <vector30>:
.globl vector30
vector30:
  pushl $0
80106a74:	6a 00                	push   $0x0
  pushl $30
80106a76:	6a 1e                	push   $0x1e
  jmp alltraps
80106a78:	e9 67 f8 ff ff       	jmp    801062e4 <alltraps>

80106a7d <vector31>:
.globl vector31
vector31:
  pushl $0
80106a7d:	6a 00                	push   $0x0
  pushl $31
80106a7f:	6a 1f                	push   $0x1f
  jmp alltraps
80106a81:	e9 5e f8 ff ff       	jmp    801062e4 <alltraps>

80106a86 <vector32>:
.globl vector32
vector32:
  pushl $0
80106a86:	6a 00                	push   $0x0
  pushl $32
80106a88:	6a 20                	push   $0x20
  jmp alltraps
80106a8a:	e9 55 f8 ff ff       	jmp    801062e4 <alltraps>

80106a8f <vector33>:
.globl vector33
vector33:
  pushl $0
80106a8f:	6a 00                	push   $0x0
  pushl $33
80106a91:	6a 21                	push   $0x21
  jmp alltraps
80106a93:	e9 4c f8 ff ff       	jmp    801062e4 <alltraps>

80106a98 <vector34>:
.globl vector34
vector34:
  pushl $0
80106a98:	6a 00                	push   $0x0
  pushl $34
80106a9a:	6a 22                	push   $0x22
  jmp alltraps
80106a9c:	e9 43 f8 ff ff       	jmp    801062e4 <alltraps>

80106aa1 <vector35>:
.globl vector35
vector35:
  pushl $0
80106aa1:	6a 00                	push   $0x0
  pushl $35
80106aa3:	6a 23                	push   $0x23
  jmp alltraps
80106aa5:	e9 3a f8 ff ff       	jmp    801062e4 <alltraps>

80106aaa <vector36>:
.globl vector36
vector36:
  pushl $0
80106aaa:	6a 00                	push   $0x0
  pushl $36
80106aac:	6a 24                	push   $0x24
  jmp alltraps
80106aae:	e9 31 f8 ff ff       	jmp    801062e4 <alltraps>

80106ab3 <vector37>:
.globl vector37
vector37:
  pushl $0
80106ab3:	6a 00                	push   $0x0
  pushl $37
80106ab5:	6a 25                	push   $0x25
  jmp alltraps
80106ab7:	e9 28 f8 ff ff       	jmp    801062e4 <alltraps>

80106abc <vector38>:
.globl vector38
vector38:
  pushl $0
80106abc:	6a 00                	push   $0x0
  pushl $38
80106abe:	6a 26                	push   $0x26
  jmp alltraps
80106ac0:	e9 1f f8 ff ff       	jmp    801062e4 <alltraps>

80106ac5 <vector39>:
.globl vector39
vector39:
  pushl $0
80106ac5:	6a 00                	push   $0x0
  pushl $39
80106ac7:	6a 27                	push   $0x27
  jmp alltraps
80106ac9:	e9 16 f8 ff ff       	jmp    801062e4 <alltraps>

80106ace <vector40>:
.globl vector40
vector40:
  pushl $0
80106ace:	6a 00                	push   $0x0
  pushl $40
80106ad0:	6a 28                	push   $0x28
  jmp alltraps
80106ad2:	e9 0d f8 ff ff       	jmp    801062e4 <alltraps>

80106ad7 <vector41>:
.globl vector41
vector41:
  pushl $0
80106ad7:	6a 00                	push   $0x0
  pushl $41
80106ad9:	6a 29                	push   $0x29
  jmp alltraps
80106adb:	e9 04 f8 ff ff       	jmp    801062e4 <alltraps>

80106ae0 <vector42>:
.globl vector42
vector42:
  pushl $0
80106ae0:	6a 00                	push   $0x0
  pushl $42
80106ae2:	6a 2a                	push   $0x2a
  jmp alltraps
80106ae4:	e9 fb f7 ff ff       	jmp    801062e4 <alltraps>

80106ae9 <vector43>:
.globl vector43
vector43:
  pushl $0
80106ae9:	6a 00                	push   $0x0
  pushl $43
80106aeb:	6a 2b                	push   $0x2b
  jmp alltraps
80106aed:	e9 f2 f7 ff ff       	jmp    801062e4 <alltraps>

80106af2 <vector44>:
.globl vector44
vector44:
  pushl $0
80106af2:	6a 00                	push   $0x0
  pushl $44
80106af4:	6a 2c                	push   $0x2c
  jmp alltraps
80106af6:	e9 e9 f7 ff ff       	jmp    801062e4 <alltraps>

80106afb <vector45>:
.globl vector45
vector45:
  pushl $0
80106afb:	6a 00                	push   $0x0
  pushl $45
80106afd:	6a 2d                	push   $0x2d
  jmp alltraps
80106aff:	e9 e0 f7 ff ff       	jmp    801062e4 <alltraps>

80106b04 <vector46>:
.globl vector46
vector46:
  pushl $0
80106b04:	6a 00                	push   $0x0
  pushl $46
80106b06:	6a 2e                	push   $0x2e
  jmp alltraps
80106b08:	e9 d7 f7 ff ff       	jmp    801062e4 <alltraps>

80106b0d <vector47>:
.globl vector47
vector47:
  pushl $0
80106b0d:	6a 00                	push   $0x0
  pushl $47
80106b0f:	6a 2f                	push   $0x2f
  jmp alltraps
80106b11:	e9 ce f7 ff ff       	jmp    801062e4 <alltraps>

80106b16 <vector48>:
.globl vector48
vector48:
  pushl $0
80106b16:	6a 00                	push   $0x0
  pushl $48
80106b18:	6a 30                	push   $0x30
  jmp alltraps
80106b1a:	e9 c5 f7 ff ff       	jmp    801062e4 <alltraps>

80106b1f <vector49>:
.globl vector49
vector49:
  pushl $0
80106b1f:	6a 00                	push   $0x0
  pushl $49
80106b21:	6a 31                	push   $0x31
  jmp alltraps
80106b23:	e9 bc f7 ff ff       	jmp    801062e4 <alltraps>

80106b28 <vector50>:
.globl vector50
vector50:
  pushl $0
80106b28:	6a 00                	push   $0x0
  pushl $50
80106b2a:	6a 32                	push   $0x32
  jmp alltraps
80106b2c:	e9 b3 f7 ff ff       	jmp    801062e4 <alltraps>

80106b31 <vector51>:
.globl vector51
vector51:
  pushl $0
80106b31:	6a 00                	push   $0x0
  pushl $51
80106b33:	6a 33                	push   $0x33
  jmp alltraps
80106b35:	e9 aa f7 ff ff       	jmp    801062e4 <alltraps>

80106b3a <vector52>:
.globl vector52
vector52:
  pushl $0
80106b3a:	6a 00                	push   $0x0
  pushl $52
80106b3c:	6a 34                	push   $0x34
  jmp alltraps
80106b3e:	e9 a1 f7 ff ff       	jmp    801062e4 <alltraps>

80106b43 <vector53>:
.globl vector53
vector53:
  pushl $0
80106b43:	6a 00                	push   $0x0
  pushl $53
80106b45:	6a 35                	push   $0x35
  jmp alltraps
80106b47:	e9 98 f7 ff ff       	jmp    801062e4 <alltraps>

80106b4c <vector54>:
.globl vector54
vector54:
  pushl $0
80106b4c:	6a 00                	push   $0x0
  pushl $54
80106b4e:	6a 36                	push   $0x36
  jmp alltraps
80106b50:	e9 8f f7 ff ff       	jmp    801062e4 <alltraps>

80106b55 <vector55>:
.globl vector55
vector55:
  pushl $0
80106b55:	6a 00                	push   $0x0
  pushl $55
80106b57:	6a 37                	push   $0x37
  jmp alltraps
80106b59:	e9 86 f7 ff ff       	jmp    801062e4 <alltraps>

80106b5e <vector56>:
.globl vector56
vector56:
  pushl $0
80106b5e:	6a 00                	push   $0x0
  pushl $56
80106b60:	6a 38                	push   $0x38
  jmp alltraps
80106b62:	e9 7d f7 ff ff       	jmp    801062e4 <alltraps>

80106b67 <vector57>:
.globl vector57
vector57:
  pushl $0
80106b67:	6a 00                	push   $0x0
  pushl $57
80106b69:	6a 39                	push   $0x39
  jmp alltraps
80106b6b:	e9 74 f7 ff ff       	jmp    801062e4 <alltraps>

80106b70 <vector58>:
.globl vector58
vector58:
  pushl $0
80106b70:	6a 00                	push   $0x0
  pushl $58
80106b72:	6a 3a                	push   $0x3a
  jmp alltraps
80106b74:	e9 6b f7 ff ff       	jmp    801062e4 <alltraps>

80106b79 <vector59>:
.globl vector59
vector59:
  pushl $0
80106b79:	6a 00                	push   $0x0
  pushl $59
80106b7b:	6a 3b                	push   $0x3b
  jmp alltraps
80106b7d:	e9 62 f7 ff ff       	jmp    801062e4 <alltraps>

80106b82 <vector60>:
.globl vector60
vector60:
  pushl $0
80106b82:	6a 00                	push   $0x0
  pushl $60
80106b84:	6a 3c                	push   $0x3c
  jmp alltraps
80106b86:	e9 59 f7 ff ff       	jmp    801062e4 <alltraps>

80106b8b <vector61>:
.globl vector61
vector61:
  pushl $0
80106b8b:	6a 00                	push   $0x0
  pushl $61
80106b8d:	6a 3d                	push   $0x3d
  jmp alltraps
80106b8f:	e9 50 f7 ff ff       	jmp    801062e4 <alltraps>

80106b94 <vector62>:
.globl vector62
vector62:
  pushl $0
80106b94:	6a 00                	push   $0x0
  pushl $62
80106b96:	6a 3e                	push   $0x3e
  jmp alltraps
80106b98:	e9 47 f7 ff ff       	jmp    801062e4 <alltraps>

80106b9d <vector63>:
.globl vector63
vector63:
  pushl $0
80106b9d:	6a 00                	push   $0x0
  pushl $63
80106b9f:	6a 3f                	push   $0x3f
  jmp alltraps
80106ba1:	e9 3e f7 ff ff       	jmp    801062e4 <alltraps>

80106ba6 <vector64>:
.globl vector64
vector64:
  pushl $0
80106ba6:	6a 00                	push   $0x0
  pushl $64
80106ba8:	6a 40                	push   $0x40
  jmp alltraps
80106baa:	e9 35 f7 ff ff       	jmp    801062e4 <alltraps>

80106baf <vector65>:
.globl vector65
vector65:
  pushl $0
80106baf:	6a 00                	push   $0x0
  pushl $65
80106bb1:	6a 41                	push   $0x41
  jmp alltraps
80106bb3:	e9 2c f7 ff ff       	jmp    801062e4 <alltraps>

80106bb8 <vector66>:
.globl vector66
vector66:
  pushl $0
80106bb8:	6a 00                	push   $0x0
  pushl $66
80106bba:	6a 42                	push   $0x42
  jmp alltraps
80106bbc:	e9 23 f7 ff ff       	jmp    801062e4 <alltraps>

80106bc1 <vector67>:
.globl vector67
vector67:
  pushl $0
80106bc1:	6a 00                	push   $0x0
  pushl $67
80106bc3:	6a 43                	push   $0x43
  jmp alltraps
80106bc5:	e9 1a f7 ff ff       	jmp    801062e4 <alltraps>

80106bca <vector68>:
.globl vector68
vector68:
  pushl $0
80106bca:	6a 00                	push   $0x0
  pushl $68
80106bcc:	6a 44                	push   $0x44
  jmp alltraps
80106bce:	e9 11 f7 ff ff       	jmp    801062e4 <alltraps>

80106bd3 <vector69>:
.globl vector69
vector69:
  pushl $0
80106bd3:	6a 00                	push   $0x0
  pushl $69
80106bd5:	6a 45                	push   $0x45
  jmp alltraps
80106bd7:	e9 08 f7 ff ff       	jmp    801062e4 <alltraps>

80106bdc <vector70>:
.globl vector70
vector70:
  pushl $0
80106bdc:	6a 00                	push   $0x0
  pushl $70
80106bde:	6a 46                	push   $0x46
  jmp alltraps
80106be0:	e9 ff f6 ff ff       	jmp    801062e4 <alltraps>

80106be5 <vector71>:
.globl vector71
vector71:
  pushl $0
80106be5:	6a 00                	push   $0x0
  pushl $71
80106be7:	6a 47                	push   $0x47
  jmp alltraps
80106be9:	e9 f6 f6 ff ff       	jmp    801062e4 <alltraps>

80106bee <vector72>:
.globl vector72
vector72:
  pushl $0
80106bee:	6a 00                	push   $0x0
  pushl $72
80106bf0:	6a 48                	push   $0x48
  jmp alltraps
80106bf2:	e9 ed f6 ff ff       	jmp    801062e4 <alltraps>

80106bf7 <vector73>:
.globl vector73
vector73:
  pushl $0
80106bf7:	6a 00                	push   $0x0
  pushl $73
80106bf9:	6a 49                	push   $0x49
  jmp alltraps
80106bfb:	e9 e4 f6 ff ff       	jmp    801062e4 <alltraps>

80106c00 <vector74>:
.globl vector74
vector74:
  pushl $0
80106c00:	6a 00                	push   $0x0
  pushl $74
80106c02:	6a 4a                	push   $0x4a
  jmp alltraps
80106c04:	e9 db f6 ff ff       	jmp    801062e4 <alltraps>

80106c09 <vector75>:
.globl vector75
vector75:
  pushl $0
80106c09:	6a 00                	push   $0x0
  pushl $75
80106c0b:	6a 4b                	push   $0x4b
  jmp alltraps
80106c0d:	e9 d2 f6 ff ff       	jmp    801062e4 <alltraps>

80106c12 <vector76>:
.globl vector76
vector76:
  pushl $0
80106c12:	6a 00                	push   $0x0
  pushl $76
80106c14:	6a 4c                	push   $0x4c
  jmp alltraps
80106c16:	e9 c9 f6 ff ff       	jmp    801062e4 <alltraps>

80106c1b <vector77>:
.globl vector77
vector77:
  pushl $0
80106c1b:	6a 00                	push   $0x0
  pushl $77
80106c1d:	6a 4d                	push   $0x4d
  jmp alltraps
80106c1f:	e9 c0 f6 ff ff       	jmp    801062e4 <alltraps>

80106c24 <vector78>:
.globl vector78
vector78:
  pushl $0
80106c24:	6a 00                	push   $0x0
  pushl $78
80106c26:	6a 4e                	push   $0x4e
  jmp alltraps
80106c28:	e9 b7 f6 ff ff       	jmp    801062e4 <alltraps>

80106c2d <vector79>:
.globl vector79
vector79:
  pushl $0
80106c2d:	6a 00                	push   $0x0
  pushl $79
80106c2f:	6a 4f                	push   $0x4f
  jmp alltraps
80106c31:	e9 ae f6 ff ff       	jmp    801062e4 <alltraps>

80106c36 <vector80>:
.globl vector80
vector80:
  pushl $0
80106c36:	6a 00                	push   $0x0
  pushl $80
80106c38:	6a 50                	push   $0x50
  jmp alltraps
80106c3a:	e9 a5 f6 ff ff       	jmp    801062e4 <alltraps>

80106c3f <vector81>:
.globl vector81
vector81:
  pushl $0
80106c3f:	6a 00                	push   $0x0
  pushl $81
80106c41:	6a 51                	push   $0x51
  jmp alltraps
80106c43:	e9 9c f6 ff ff       	jmp    801062e4 <alltraps>

80106c48 <vector82>:
.globl vector82
vector82:
  pushl $0
80106c48:	6a 00                	push   $0x0
  pushl $82
80106c4a:	6a 52                	push   $0x52
  jmp alltraps
80106c4c:	e9 93 f6 ff ff       	jmp    801062e4 <alltraps>

80106c51 <vector83>:
.globl vector83
vector83:
  pushl $0
80106c51:	6a 00                	push   $0x0
  pushl $83
80106c53:	6a 53                	push   $0x53
  jmp alltraps
80106c55:	e9 8a f6 ff ff       	jmp    801062e4 <alltraps>

80106c5a <vector84>:
.globl vector84
vector84:
  pushl $0
80106c5a:	6a 00                	push   $0x0
  pushl $84
80106c5c:	6a 54                	push   $0x54
  jmp alltraps
80106c5e:	e9 81 f6 ff ff       	jmp    801062e4 <alltraps>

80106c63 <vector85>:
.globl vector85
vector85:
  pushl $0
80106c63:	6a 00                	push   $0x0
  pushl $85
80106c65:	6a 55                	push   $0x55
  jmp alltraps
80106c67:	e9 78 f6 ff ff       	jmp    801062e4 <alltraps>

80106c6c <vector86>:
.globl vector86
vector86:
  pushl $0
80106c6c:	6a 00                	push   $0x0
  pushl $86
80106c6e:	6a 56                	push   $0x56
  jmp alltraps
80106c70:	e9 6f f6 ff ff       	jmp    801062e4 <alltraps>

80106c75 <vector87>:
.globl vector87
vector87:
  pushl $0
80106c75:	6a 00                	push   $0x0
  pushl $87
80106c77:	6a 57                	push   $0x57
  jmp alltraps
80106c79:	e9 66 f6 ff ff       	jmp    801062e4 <alltraps>

80106c7e <vector88>:
.globl vector88
vector88:
  pushl $0
80106c7e:	6a 00                	push   $0x0
  pushl $88
80106c80:	6a 58                	push   $0x58
  jmp alltraps
80106c82:	e9 5d f6 ff ff       	jmp    801062e4 <alltraps>

80106c87 <vector89>:
.globl vector89
vector89:
  pushl $0
80106c87:	6a 00                	push   $0x0
  pushl $89
80106c89:	6a 59                	push   $0x59
  jmp alltraps
80106c8b:	e9 54 f6 ff ff       	jmp    801062e4 <alltraps>

80106c90 <vector90>:
.globl vector90
vector90:
  pushl $0
80106c90:	6a 00                	push   $0x0
  pushl $90
80106c92:	6a 5a                	push   $0x5a
  jmp alltraps
80106c94:	e9 4b f6 ff ff       	jmp    801062e4 <alltraps>

80106c99 <vector91>:
.globl vector91
vector91:
  pushl $0
80106c99:	6a 00                	push   $0x0
  pushl $91
80106c9b:	6a 5b                	push   $0x5b
  jmp alltraps
80106c9d:	e9 42 f6 ff ff       	jmp    801062e4 <alltraps>

80106ca2 <vector92>:
.globl vector92
vector92:
  pushl $0
80106ca2:	6a 00                	push   $0x0
  pushl $92
80106ca4:	6a 5c                	push   $0x5c
  jmp alltraps
80106ca6:	e9 39 f6 ff ff       	jmp    801062e4 <alltraps>

80106cab <vector93>:
.globl vector93
vector93:
  pushl $0
80106cab:	6a 00                	push   $0x0
  pushl $93
80106cad:	6a 5d                	push   $0x5d
  jmp alltraps
80106caf:	e9 30 f6 ff ff       	jmp    801062e4 <alltraps>

80106cb4 <vector94>:
.globl vector94
vector94:
  pushl $0
80106cb4:	6a 00                	push   $0x0
  pushl $94
80106cb6:	6a 5e                	push   $0x5e
  jmp alltraps
80106cb8:	e9 27 f6 ff ff       	jmp    801062e4 <alltraps>

80106cbd <vector95>:
.globl vector95
vector95:
  pushl $0
80106cbd:	6a 00                	push   $0x0
  pushl $95
80106cbf:	6a 5f                	push   $0x5f
  jmp alltraps
80106cc1:	e9 1e f6 ff ff       	jmp    801062e4 <alltraps>

80106cc6 <vector96>:
.globl vector96
vector96:
  pushl $0
80106cc6:	6a 00                	push   $0x0
  pushl $96
80106cc8:	6a 60                	push   $0x60
  jmp alltraps
80106cca:	e9 15 f6 ff ff       	jmp    801062e4 <alltraps>

80106ccf <vector97>:
.globl vector97
vector97:
  pushl $0
80106ccf:	6a 00                	push   $0x0
  pushl $97
80106cd1:	6a 61                	push   $0x61
  jmp alltraps
80106cd3:	e9 0c f6 ff ff       	jmp    801062e4 <alltraps>

80106cd8 <vector98>:
.globl vector98
vector98:
  pushl $0
80106cd8:	6a 00                	push   $0x0
  pushl $98
80106cda:	6a 62                	push   $0x62
  jmp alltraps
80106cdc:	e9 03 f6 ff ff       	jmp    801062e4 <alltraps>

80106ce1 <vector99>:
.globl vector99
vector99:
  pushl $0
80106ce1:	6a 00                	push   $0x0
  pushl $99
80106ce3:	6a 63                	push   $0x63
  jmp alltraps
80106ce5:	e9 fa f5 ff ff       	jmp    801062e4 <alltraps>

80106cea <vector100>:
.globl vector100
vector100:
  pushl $0
80106cea:	6a 00                	push   $0x0
  pushl $100
80106cec:	6a 64                	push   $0x64
  jmp alltraps
80106cee:	e9 f1 f5 ff ff       	jmp    801062e4 <alltraps>

80106cf3 <vector101>:
.globl vector101
vector101:
  pushl $0
80106cf3:	6a 00                	push   $0x0
  pushl $101
80106cf5:	6a 65                	push   $0x65
  jmp alltraps
80106cf7:	e9 e8 f5 ff ff       	jmp    801062e4 <alltraps>

80106cfc <vector102>:
.globl vector102
vector102:
  pushl $0
80106cfc:	6a 00                	push   $0x0
  pushl $102
80106cfe:	6a 66                	push   $0x66
  jmp alltraps
80106d00:	e9 df f5 ff ff       	jmp    801062e4 <alltraps>

80106d05 <vector103>:
.globl vector103
vector103:
  pushl $0
80106d05:	6a 00                	push   $0x0
  pushl $103
80106d07:	6a 67                	push   $0x67
  jmp alltraps
80106d09:	e9 d6 f5 ff ff       	jmp    801062e4 <alltraps>

80106d0e <vector104>:
.globl vector104
vector104:
  pushl $0
80106d0e:	6a 00                	push   $0x0
  pushl $104
80106d10:	6a 68                	push   $0x68
  jmp alltraps
80106d12:	e9 cd f5 ff ff       	jmp    801062e4 <alltraps>

80106d17 <vector105>:
.globl vector105
vector105:
  pushl $0
80106d17:	6a 00                	push   $0x0
  pushl $105
80106d19:	6a 69                	push   $0x69
  jmp alltraps
80106d1b:	e9 c4 f5 ff ff       	jmp    801062e4 <alltraps>

80106d20 <vector106>:
.globl vector106
vector106:
  pushl $0
80106d20:	6a 00                	push   $0x0
  pushl $106
80106d22:	6a 6a                	push   $0x6a
  jmp alltraps
80106d24:	e9 bb f5 ff ff       	jmp    801062e4 <alltraps>

80106d29 <vector107>:
.globl vector107
vector107:
  pushl $0
80106d29:	6a 00                	push   $0x0
  pushl $107
80106d2b:	6a 6b                	push   $0x6b
  jmp alltraps
80106d2d:	e9 b2 f5 ff ff       	jmp    801062e4 <alltraps>

80106d32 <vector108>:
.globl vector108
vector108:
  pushl $0
80106d32:	6a 00                	push   $0x0
  pushl $108
80106d34:	6a 6c                	push   $0x6c
  jmp alltraps
80106d36:	e9 a9 f5 ff ff       	jmp    801062e4 <alltraps>

80106d3b <vector109>:
.globl vector109
vector109:
  pushl $0
80106d3b:	6a 00                	push   $0x0
  pushl $109
80106d3d:	6a 6d                	push   $0x6d
  jmp alltraps
80106d3f:	e9 a0 f5 ff ff       	jmp    801062e4 <alltraps>

80106d44 <vector110>:
.globl vector110
vector110:
  pushl $0
80106d44:	6a 00                	push   $0x0
  pushl $110
80106d46:	6a 6e                	push   $0x6e
  jmp alltraps
80106d48:	e9 97 f5 ff ff       	jmp    801062e4 <alltraps>

80106d4d <vector111>:
.globl vector111
vector111:
  pushl $0
80106d4d:	6a 00                	push   $0x0
  pushl $111
80106d4f:	6a 6f                	push   $0x6f
  jmp alltraps
80106d51:	e9 8e f5 ff ff       	jmp    801062e4 <alltraps>

80106d56 <vector112>:
.globl vector112
vector112:
  pushl $0
80106d56:	6a 00                	push   $0x0
  pushl $112
80106d58:	6a 70                	push   $0x70
  jmp alltraps
80106d5a:	e9 85 f5 ff ff       	jmp    801062e4 <alltraps>

80106d5f <vector113>:
.globl vector113
vector113:
  pushl $0
80106d5f:	6a 00                	push   $0x0
  pushl $113
80106d61:	6a 71                	push   $0x71
  jmp alltraps
80106d63:	e9 7c f5 ff ff       	jmp    801062e4 <alltraps>

80106d68 <vector114>:
.globl vector114
vector114:
  pushl $0
80106d68:	6a 00                	push   $0x0
  pushl $114
80106d6a:	6a 72                	push   $0x72
  jmp alltraps
80106d6c:	e9 73 f5 ff ff       	jmp    801062e4 <alltraps>

80106d71 <vector115>:
.globl vector115
vector115:
  pushl $0
80106d71:	6a 00                	push   $0x0
  pushl $115
80106d73:	6a 73                	push   $0x73
  jmp alltraps
80106d75:	e9 6a f5 ff ff       	jmp    801062e4 <alltraps>

80106d7a <vector116>:
.globl vector116
vector116:
  pushl $0
80106d7a:	6a 00                	push   $0x0
  pushl $116
80106d7c:	6a 74                	push   $0x74
  jmp alltraps
80106d7e:	e9 61 f5 ff ff       	jmp    801062e4 <alltraps>

80106d83 <vector117>:
.globl vector117
vector117:
  pushl $0
80106d83:	6a 00                	push   $0x0
  pushl $117
80106d85:	6a 75                	push   $0x75
  jmp alltraps
80106d87:	e9 58 f5 ff ff       	jmp    801062e4 <alltraps>

80106d8c <vector118>:
.globl vector118
vector118:
  pushl $0
80106d8c:	6a 00                	push   $0x0
  pushl $118
80106d8e:	6a 76                	push   $0x76
  jmp alltraps
80106d90:	e9 4f f5 ff ff       	jmp    801062e4 <alltraps>

80106d95 <vector119>:
.globl vector119
vector119:
  pushl $0
80106d95:	6a 00                	push   $0x0
  pushl $119
80106d97:	6a 77                	push   $0x77
  jmp alltraps
80106d99:	e9 46 f5 ff ff       	jmp    801062e4 <alltraps>

80106d9e <vector120>:
.globl vector120
vector120:
  pushl $0
80106d9e:	6a 00                	push   $0x0
  pushl $120
80106da0:	6a 78                	push   $0x78
  jmp alltraps
80106da2:	e9 3d f5 ff ff       	jmp    801062e4 <alltraps>

80106da7 <vector121>:
.globl vector121
vector121:
  pushl $0
80106da7:	6a 00                	push   $0x0
  pushl $121
80106da9:	6a 79                	push   $0x79
  jmp alltraps
80106dab:	e9 34 f5 ff ff       	jmp    801062e4 <alltraps>

80106db0 <vector122>:
.globl vector122
vector122:
  pushl $0
80106db0:	6a 00                	push   $0x0
  pushl $122
80106db2:	6a 7a                	push   $0x7a
  jmp alltraps
80106db4:	e9 2b f5 ff ff       	jmp    801062e4 <alltraps>

80106db9 <vector123>:
.globl vector123
vector123:
  pushl $0
80106db9:	6a 00                	push   $0x0
  pushl $123
80106dbb:	6a 7b                	push   $0x7b
  jmp alltraps
80106dbd:	e9 22 f5 ff ff       	jmp    801062e4 <alltraps>

80106dc2 <vector124>:
.globl vector124
vector124:
  pushl $0
80106dc2:	6a 00                	push   $0x0
  pushl $124
80106dc4:	6a 7c                	push   $0x7c
  jmp alltraps
80106dc6:	e9 19 f5 ff ff       	jmp    801062e4 <alltraps>

80106dcb <vector125>:
.globl vector125
vector125:
  pushl $0
80106dcb:	6a 00                	push   $0x0
  pushl $125
80106dcd:	6a 7d                	push   $0x7d
  jmp alltraps
80106dcf:	e9 10 f5 ff ff       	jmp    801062e4 <alltraps>

80106dd4 <vector126>:
.globl vector126
vector126:
  pushl $0
80106dd4:	6a 00                	push   $0x0
  pushl $126
80106dd6:	6a 7e                	push   $0x7e
  jmp alltraps
80106dd8:	e9 07 f5 ff ff       	jmp    801062e4 <alltraps>

80106ddd <vector127>:
.globl vector127
vector127:
  pushl $0
80106ddd:	6a 00                	push   $0x0
  pushl $127
80106ddf:	6a 7f                	push   $0x7f
  jmp alltraps
80106de1:	e9 fe f4 ff ff       	jmp    801062e4 <alltraps>

80106de6 <vector128>:
.globl vector128
vector128:
  pushl $0
80106de6:	6a 00                	push   $0x0
  pushl $128
80106de8:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106ded:	e9 f2 f4 ff ff       	jmp    801062e4 <alltraps>

80106df2 <vector129>:
.globl vector129
vector129:
  pushl $0
80106df2:	6a 00                	push   $0x0
  pushl $129
80106df4:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106df9:	e9 e6 f4 ff ff       	jmp    801062e4 <alltraps>

80106dfe <vector130>:
.globl vector130
vector130:
  pushl $0
80106dfe:	6a 00                	push   $0x0
  pushl $130
80106e00:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106e05:	e9 da f4 ff ff       	jmp    801062e4 <alltraps>

80106e0a <vector131>:
.globl vector131
vector131:
  pushl $0
80106e0a:	6a 00                	push   $0x0
  pushl $131
80106e0c:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106e11:	e9 ce f4 ff ff       	jmp    801062e4 <alltraps>

80106e16 <vector132>:
.globl vector132
vector132:
  pushl $0
80106e16:	6a 00                	push   $0x0
  pushl $132
80106e18:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106e1d:	e9 c2 f4 ff ff       	jmp    801062e4 <alltraps>

80106e22 <vector133>:
.globl vector133
vector133:
  pushl $0
80106e22:	6a 00                	push   $0x0
  pushl $133
80106e24:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106e29:	e9 b6 f4 ff ff       	jmp    801062e4 <alltraps>

80106e2e <vector134>:
.globl vector134
vector134:
  pushl $0
80106e2e:	6a 00                	push   $0x0
  pushl $134
80106e30:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106e35:	e9 aa f4 ff ff       	jmp    801062e4 <alltraps>

80106e3a <vector135>:
.globl vector135
vector135:
  pushl $0
80106e3a:	6a 00                	push   $0x0
  pushl $135
80106e3c:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106e41:	e9 9e f4 ff ff       	jmp    801062e4 <alltraps>

80106e46 <vector136>:
.globl vector136
vector136:
  pushl $0
80106e46:	6a 00                	push   $0x0
  pushl $136
80106e48:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106e4d:	e9 92 f4 ff ff       	jmp    801062e4 <alltraps>

80106e52 <vector137>:
.globl vector137
vector137:
  pushl $0
80106e52:	6a 00                	push   $0x0
  pushl $137
80106e54:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106e59:	e9 86 f4 ff ff       	jmp    801062e4 <alltraps>

80106e5e <vector138>:
.globl vector138
vector138:
  pushl $0
80106e5e:	6a 00                	push   $0x0
  pushl $138
80106e60:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106e65:	e9 7a f4 ff ff       	jmp    801062e4 <alltraps>

80106e6a <vector139>:
.globl vector139
vector139:
  pushl $0
80106e6a:	6a 00                	push   $0x0
  pushl $139
80106e6c:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106e71:	e9 6e f4 ff ff       	jmp    801062e4 <alltraps>

80106e76 <vector140>:
.globl vector140
vector140:
  pushl $0
80106e76:	6a 00                	push   $0x0
  pushl $140
80106e78:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106e7d:	e9 62 f4 ff ff       	jmp    801062e4 <alltraps>

80106e82 <vector141>:
.globl vector141
vector141:
  pushl $0
80106e82:	6a 00                	push   $0x0
  pushl $141
80106e84:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106e89:	e9 56 f4 ff ff       	jmp    801062e4 <alltraps>

80106e8e <vector142>:
.globl vector142
vector142:
  pushl $0
80106e8e:	6a 00                	push   $0x0
  pushl $142
80106e90:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106e95:	e9 4a f4 ff ff       	jmp    801062e4 <alltraps>

80106e9a <vector143>:
.globl vector143
vector143:
  pushl $0
80106e9a:	6a 00                	push   $0x0
  pushl $143
80106e9c:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106ea1:	e9 3e f4 ff ff       	jmp    801062e4 <alltraps>

80106ea6 <vector144>:
.globl vector144
vector144:
  pushl $0
80106ea6:	6a 00                	push   $0x0
  pushl $144
80106ea8:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106ead:	e9 32 f4 ff ff       	jmp    801062e4 <alltraps>

80106eb2 <vector145>:
.globl vector145
vector145:
  pushl $0
80106eb2:	6a 00                	push   $0x0
  pushl $145
80106eb4:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106eb9:	e9 26 f4 ff ff       	jmp    801062e4 <alltraps>

80106ebe <vector146>:
.globl vector146
vector146:
  pushl $0
80106ebe:	6a 00                	push   $0x0
  pushl $146
80106ec0:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106ec5:	e9 1a f4 ff ff       	jmp    801062e4 <alltraps>

80106eca <vector147>:
.globl vector147
vector147:
  pushl $0
80106eca:	6a 00                	push   $0x0
  pushl $147
80106ecc:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106ed1:	e9 0e f4 ff ff       	jmp    801062e4 <alltraps>

80106ed6 <vector148>:
.globl vector148
vector148:
  pushl $0
80106ed6:	6a 00                	push   $0x0
  pushl $148
80106ed8:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106edd:	e9 02 f4 ff ff       	jmp    801062e4 <alltraps>

80106ee2 <vector149>:
.globl vector149
vector149:
  pushl $0
80106ee2:	6a 00                	push   $0x0
  pushl $149
80106ee4:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106ee9:	e9 f6 f3 ff ff       	jmp    801062e4 <alltraps>

80106eee <vector150>:
.globl vector150
vector150:
  pushl $0
80106eee:	6a 00                	push   $0x0
  pushl $150
80106ef0:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106ef5:	e9 ea f3 ff ff       	jmp    801062e4 <alltraps>

80106efa <vector151>:
.globl vector151
vector151:
  pushl $0
80106efa:	6a 00                	push   $0x0
  pushl $151
80106efc:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106f01:	e9 de f3 ff ff       	jmp    801062e4 <alltraps>

80106f06 <vector152>:
.globl vector152
vector152:
  pushl $0
80106f06:	6a 00                	push   $0x0
  pushl $152
80106f08:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106f0d:	e9 d2 f3 ff ff       	jmp    801062e4 <alltraps>

80106f12 <vector153>:
.globl vector153
vector153:
  pushl $0
80106f12:	6a 00                	push   $0x0
  pushl $153
80106f14:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106f19:	e9 c6 f3 ff ff       	jmp    801062e4 <alltraps>

80106f1e <vector154>:
.globl vector154
vector154:
  pushl $0
80106f1e:	6a 00                	push   $0x0
  pushl $154
80106f20:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106f25:	e9 ba f3 ff ff       	jmp    801062e4 <alltraps>

80106f2a <vector155>:
.globl vector155
vector155:
  pushl $0
80106f2a:	6a 00                	push   $0x0
  pushl $155
80106f2c:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106f31:	e9 ae f3 ff ff       	jmp    801062e4 <alltraps>

80106f36 <vector156>:
.globl vector156
vector156:
  pushl $0
80106f36:	6a 00                	push   $0x0
  pushl $156
80106f38:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106f3d:	e9 a2 f3 ff ff       	jmp    801062e4 <alltraps>

80106f42 <vector157>:
.globl vector157
vector157:
  pushl $0
80106f42:	6a 00                	push   $0x0
  pushl $157
80106f44:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106f49:	e9 96 f3 ff ff       	jmp    801062e4 <alltraps>

80106f4e <vector158>:
.globl vector158
vector158:
  pushl $0
80106f4e:	6a 00                	push   $0x0
  pushl $158
80106f50:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80106f55:	e9 8a f3 ff ff       	jmp    801062e4 <alltraps>

80106f5a <vector159>:
.globl vector159
vector159:
  pushl $0
80106f5a:	6a 00                	push   $0x0
  pushl $159
80106f5c:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80106f61:	e9 7e f3 ff ff       	jmp    801062e4 <alltraps>

80106f66 <vector160>:
.globl vector160
vector160:
  pushl $0
80106f66:	6a 00                	push   $0x0
  pushl $160
80106f68:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80106f6d:	e9 72 f3 ff ff       	jmp    801062e4 <alltraps>

80106f72 <vector161>:
.globl vector161
vector161:
  pushl $0
80106f72:	6a 00                	push   $0x0
  pushl $161
80106f74:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80106f79:	e9 66 f3 ff ff       	jmp    801062e4 <alltraps>

80106f7e <vector162>:
.globl vector162
vector162:
  pushl $0
80106f7e:	6a 00                	push   $0x0
  pushl $162
80106f80:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80106f85:	e9 5a f3 ff ff       	jmp    801062e4 <alltraps>

80106f8a <vector163>:
.globl vector163
vector163:
  pushl $0
80106f8a:	6a 00                	push   $0x0
  pushl $163
80106f8c:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80106f91:	e9 4e f3 ff ff       	jmp    801062e4 <alltraps>

80106f96 <vector164>:
.globl vector164
vector164:
  pushl $0
80106f96:	6a 00                	push   $0x0
  pushl $164
80106f98:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80106f9d:	e9 42 f3 ff ff       	jmp    801062e4 <alltraps>

80106fa2 <vector165>:
.globl vector165
vector165:
  pushl $0
80106fa2:	6a 00                	push   $0x0
  pushl $165
80106fa4:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80106fa9:	e9 36 f3 ff ff       	jmp    801062e4 <alltraps>

80106fae <vector166>:
.globl vector166
vector166:
  pushl $0
80106fae:	6a 00                	push   $0x0
  pushl $166
80106fb0:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80106fb5:	e9 2a f3 ff ff       	jmp    801062e4 <alltraps>

80106fba <vector167>:
.globl vector167
vector167:
  pushl $0
80106fba:	6a 00                	push   $0x0
  pushl $167
80106fbc:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80106fc1:	e9 1e f3 ff ff       	jmp    801062e4 <alltraps>

80106fc6 <vector168>:
.globl vector168
vector168:
  pushl $0
80106fc6:	6a 00                	push   $0x0
  pushl $168
80106fc8:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80106fcd:	e9 12 f3 ff ff       	jmp    801062e4 <alltraps>

80106fd2 <vector169>:
.globl vector169
vector169:
  pushl $0
80106fd2:	6a 00                	push   $0x0
  pushl $169
80106fd4:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80106fd9:	e9 06 f3 ff ff       	jmp    801062e4 <alltraps>

80106fde <vector170>:
.globl vector170
vector170:
  pushl $0
80106fde:	6a 00                	push   $0x0
  pushl $170
80106fe0:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80106fe5:	e9 fa f2 ff ff       	jmp    801062e4 <alltraps>

80106fea <vector171>:
.globl vector171
vector171:
  pushl $0
80106fea:	6a 00                	push   $0x0
  pushl $171
80106fec:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80106ff1:	e9 ee f2 ff ff       	jmp    801062e4 <alltraps>

80106ff6 <vector172>:
.globl vector172
vector172:
  pushl $0
80106ff6:	6a 00                	push   $0x0
  pushl $172
80106ff8:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80106ffd:	e9 e2 f2 ff ff       	jmp    801062e4 <alltraps>

80107002 <vector173>:
.globl vector173
vector173:
  pushl $0
80107002:	6a 00                	push   $0x0
  pushl $173
80107004:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107009:	e9 d6 f2 ff ff       	jmp    801062e4 <alltraps>

8010700e <vector174>:
.globl vector174
vector174:
  pushl $0
8010700e:	6a 00                	push   $0x0
  pushl $174
80107010:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107015:	e9 ca f2 ff ff       	jmp    801062e4 <alltraps>

8010701a <vector175>:
.globl vector175
vector175:
  pushl $0
8010701a:	6a 00                	push   $0x0
  pushl $175
8010701c:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107021:	e9 be f2 ff ff       	jmp    801062e4 <alltraps>

80107026 <vector176>:
.globl vector176
vector176:
  pushl $0
80107026:	6a 00                	push   $0x0
  pushl $176
80107028:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
8010702d:	e9 b2 f2 ff ff       	jmp    801062e4 <alltraps>

80107032 <vector177>:
.globl vector177
vector177:
  pushl $0
80107032:	6a 00                	push   $0x0
  pushl $177
80107034:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
80107039:	e9 a6 f2 ff ff       	jmp    801062e4 <alltraps>

8010703e <vector178>:
.globl vector178
vector178:
  pushl $0
8010703e:	6a 00                	push   $0x0
  pushl $178
80107040:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107045:	e9 9a f2 ff ff       	jmp    801062e4 <alltraps>

8010704a <vector179>:
.globl vector179
vector179:
  pushl $0
8010704a:	6a 00                	push   $0x0
  pushl $179
8010704c:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107051:	e9 8e f2 ff ff       	jmp    801062e4 <alltraps>

80107056 <vector180>:
.globl vector180
vector180:
  pushl $0
80107056:	6a 00                	push   $0x0
  pushl $180
80107058:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
8010705d:	e9 82 f2 ff ff       	jmp    801062e4 <alltraps>

80107062 <vector181>:
.globl vector181
vector181:
  pushl $0
80107062:	6a 00                	push   $0x0
  pushl $181
80107064:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
80107069:	e9 76 f2 ff ff       	jmp    801062e4 <alltraps>

8010706e <vector182>:
.globl vector182
vector182:
  pushl $0
8010706e:	6a 00                	push   $0x0
  pushl $182
80107070:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107075:	e9 6a f2 ff ff       	jmp    801062e4 <alltraps>

8010707a <vector183>:
.globl vector183
vector183:
  pushl $0
8010707a:	6a 00                	push   $0x0
  pushl $183
8010707c:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
80107081:	e9 5e f2 ff ff       	jmp    801062e4 <alltraps>

80107086 <vector184>:
.globl vector184
vector184:
  pushl $0
80107086:	6a 00                	push   $0x0
  pushl $184
80107088:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010708d:	e9 52 f2 ff ff       	jmp    801062e4 <alltraps>

80107092 <vector185>:
.globl vector185
vector185:
  pushl $0
80107092:	6a 00                	push   $0x0
  pushl $185
80107094:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107099:	e9 46 f2 ff ff       	jmp    801062e4 <alltraps>

8010709e <vector186>:
.globl vector186
vector186:
  pushl $0
8010709e:	6a 00                	push   $0x0
  pushl $186
801070a0:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801070a5:	e9 3a f2 ff ff       	jmp    801062e4 <alltraps>

801070aa <vector187>:
.globl vector187
vector187:
  pushl $0
801070aa:	6a 00                	push   $0x0
  pushl $187
801070ac:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801070b1:	e9 2e f2 ff ff       	jmp    801062e4 <alltraps>

801070b6 <vector188>:
.globl vector188
vector188:
  pushl $0
801070b6:	6a 00                	push   $0x0
  pushl $188
801070b8:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801070bd:	e9 22 f2 ff ff       	jmp    801062e4 <alltraps>

801070c2 <vector189>:
.globl vector189
vector189:
  pushl $0
801070c2:	6a 00                	push   $0x0
  pushl $189
801070c4:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801070c9:	e9 16 f2 ff ff       	jmp    801062e4 <alltraps>

801070ce <vector190>:
.globl vector190
vector190:
  pushl $0
801070ce:	6a 00                	push   $0x0
  pushl $190
801070d0:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
801070d5:	e9 0a f2 ff ff       	jmp    801062e4 <alltraps>

801070da <vector191>:
.globl vector191
vector191:
  pushl $0
801070da:	6a 00                	push   $0x0
  pushl $191
801070dc:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
801070e1:	e9 fe f1 ff ff       	jmp    801062e4 <alltraps>

801070e6 <vector192>:
.globl vector192
vector192:
  pushl $0
801070e6:	6a 00                	push   $0x0
  pushl $192
801070e8:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
801070ed:	e9 f2 f1 ff ff       	jmp    801062e4 <alltraps>

801070f2 <vector193>:
.globl vector193
vector193:
  pushl $0
801070f2:	6a 00                	push   $0x0
  pushl $193
801070f4:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
801070f9:	e9 e6 f1 ff ff       	jmp    801062e4 <alltraps>

801070fe <vector194>:
.globl vector194
vector194:
  pushl $0
801070fe:	6a 00                	push   $0x0
  pushl $194
80107100:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107105:	e9 da f1 ff ff       	jmp    801062e4 <alltraps>

8010710a <vector195>:
.globl vector195
vector195:
  pushl $0
8010710a:	6a 00                	push   $0x0
  pushl $195
8010710c:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107111:	e9 ce f1 ff ff       	jmp    801062e4 <alltraps>

80107116 <vector196>:
.globl vector196
vector196:
  pushl $0
80107116:	6a 00                	push   $0x0
  pushl $196
80107118:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
8010711d:	e9 c2 f1 ff ff       	jmp    801062e4 <alltraps>

80107122 <vector197>:
.globl vector197
vector197:
  pushl $0
80107122:	6a 00                	push   $0x0
  pushl $197
80107124:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
80107129:	e9 b6 f1 ff ff       	jmp    801062e4 <alltraps>

8010712e <vector198>:
.globl vector198
vector198:
  pushl $0
8010712e:	6a 00                	push   $0x0
  pushl $198
80107130:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107135:	e9 aa f1 ff ff       	jmp    801062e4 <alltraps>

8010713a <vector199>:
.globl vector199
vector199:
  pushl $0
8010713a:	6a 00                	push   $0x0
  pushl $199
8010713c:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107141:	e9 9e f1 ff ff       	jmp    801062e4 <alltraps>

80107146 <vector200>:
.globl vector200
vector200:
  pushl $0
80107146:	6a 00                	push   $0x0
  pushl $200
80107148:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
8010714d:	e9 92 f1 ff ff       	jmp    801062e4 <alltraps>

80107152 <vector201>:
.globl vector201
vector201:
  pushl $0
80107152:	6a 00                	push   $0x0
  pushl $201
80107154:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
80107159:	e9 86 f1 ff ff       	jmp    801062e4 <alltraps>

8010715e <vector202>:
.globl vector202
vector202:
  pushl $0
8010715e:	6a 00                	push   $0x0
  pushl $202
80107160:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107165:	e9 7a f1 ff ff       	jmp    801062e4 <alltraps>

8010716a <vector203>:
.globl vector203
vector203:
  pushl $0
8010716a:	6a 00                	push   $0x0
  pushl $203
8010716c:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
80107171:	e9 6e f1 ff ff       	jmp    801062e4 <alltraps>

80107176 <vector204>:
.globl vector204
vector204:
  pushl $0
80107176:	6a 00                	push   $0x0
  pushl $204
80107178:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
8010717d:	e9 62 f1 ff ff       	jmp    801062e4 <alltraps>

80107182 <vector205>:
.globl vector205
vector205:
  pushl $0
80107182:	6a 00                	push   $0x0
  pushl $205
80107184:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107189:	e9 56 f1 ff ff       	jmp    801062e4 <alltraps>

8010718e <vector206>:
.globl vector206
vector206:
  pushl $0
8010718e:	6a 00                	push   $0x0
  pushl $206
80107190:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107195:	e9 4a f1 ff ff       	jmp    801062e4 <alltraps>

8010719a <vector207>:
.globl vector207
vector207:
  pushl $0
8010719a:	6a 00                	push   $0x0
  pushl $207
8010719c:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801071a1:	e9 3e f1 ff ff       	jmp    801062e4 <alltraps>

801071a6 <vector208>:
.globl vector208
vector208:
  pushl $0
801071a6:	6a 00                	push   $0x0
  pushl $208
801071a8:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801071ad:	e9 32 f1 ff ff       	jmp    801062e4 <alltraps>

801071b2 <vector209>:
.globl vector209
vector209:
  pushl $0
801071b2:	6a 00                	push   $0x0
  pushl $209
801071b4:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801071b9:	e9 26 f1 ff ff       	jmp    801062e4 <alltraps>

801071be <vector210>:
.globl vector210
vector210:
  pushl $0
801071be:	6a 00                	push   $0x0
  pushl $210
801071c0:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801071c5:	e9 1a f1 ff ff       	jmp    801062e4 <alltraps>

801071ca <vector211>:
.globl vector211
vector211:
  pushl $0
801071ca:	6a 00                	push   $0x0
  pushl $211
801071cc:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
801071d1:	e9 0e f1 ff ff       	jmp    801062e4 <alltraps>

801071d6 <vector212>:
.globl vector212
vector212:
  pushl $0
801071d6:	6a 00                	push   $0x0
  pushl $212
801071d8:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
801071dd:	e9 02 f1 ff ff       	jmp    801062e4 <alltraps>

801071e2 <vector213>:
.globl vector213
vector213:
  pushl $0
801071e2:	6a 00                	push   $0x0
  pushl $213
801071e4:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
801071e9:	e9 f6 f0 ff ff       	jmp    801062e4 <alltraps>

801071ee <vector214>:
.globl vector214
vector214:
  pushl $0
801071ee:	6a 00                	push   $0x0
  pushl $214
801071f0:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
801071f5:	e9 ea f0 ff ff       	jmp    801062e4 <alltraps>

801071fa <vector215>:
.globl vector215
vector215:
  pushl $0
801071fa:	6a 00                	push   $0x0
  pushl $215
801071fc:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107201:	e9 de f0 ff ff       	jmp    801062e4 <alltraps>

80107206 <vector216>:
.globl vector216
vector216:
  pushl $0
80107206:	6a 00                	push   $0x0
  pushl $216
80107208:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010720d:	e9 d2 f0 ff ff       	jmp    801062e4 <alltraps>

80107212 <vector217>:
.globl vector217
vector217:
  pushl $0
80107212:	6a 00                	push   $0x0
  pushl $217
80107214:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
80107219:	e9 c6 f0 ff ff       	jmp    801062e4 <alltraps>

8010721e <vector218>:
.globl vector218
vector218:
  pushl $0
8010721e:	6a 00                	push   $0x0
  pushl $218
80107220:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107225:	e9 ba f0 ff ff       	jmp    801062e4 <alltraps>

8010722a <vector219>:
.globl vector219
vector219:
  pushl $0
8010722a:	6a 00                	push   $0x0
  pushl $219
8010722c:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107231:	e9 ae f0 ff ff       	jmp    801062e4 <alltraps>

80107236 <vector220>:
.globl vector220
vector220:
  pushl $0
80107236:	6a 00                	push   $0x0
  pushl $220
80107238:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
8010723d:	e9 a2 f0 ff ff       	jmp    801062e4 <alltraps>

80107242 <vector221>:
.globl vector221
vector221:
  pushl $0
80107242:	6a 00                	push   $0x0
  pushl $221
80107244:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
80107249:	e9 96 f0 ff ff       	jmp    801062e4 <alltraps>

8010724e <vector222>:
.globl vector222
vector222:
  pushl $0
8010724e:	6a 00                	push   $0x0
  pushl $222
80107250:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107255:	e9 8a f0 ff ff       	jmp    801062e4 <alltraps>

8010725a <vector223>:
.globl vector223
vector223:
  pushl $0
8010725a:	6a 00                	push   $0x0
  pushl $223
8010725c:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107261:	e9 7e f0 ff ff       	jmp    801062e4 <alltraps>

80107266 <vector224>:
.globl vector224
vector224:
  pushl $0
80107266:	6a 00                	push   $0x0
  pushl $224
80107268:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
8010726d:	e9 72 f0 ff ff       	jmp    801062e4 <alltraps>

80107272 <vector225>:
.globl vector225
vector225:
  pushl $0
80107272:	6a 00                	push   $0x0
  pushl $225
80107274:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107279:	e9 66 f0 ff ff       	jmp    801062e4 <alltraps>

8010727e <vector226>:
.globl vector226
vector226:
  pushl $0
8010727e:	6a 00                	push   $0x0
  pushl $226
80107280:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107285:	e9 5a f0 ff ff       	jmp    801062e4 <alltraps>

8010728a <vector227>:
.globl vector227
vector227:
  pushl $0
8010728a:	6a 00                	push   $0x0
  pushl $227
8010728c:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107291:	e9 4e f0 ff ff       	jmp    801062e4 <alltraps>

80107296 <vector228>:
.globl vector228
vector228:
  pushl $0
80107296:	6a 00                	push   $0x0
  pushl $228
80107298:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010729d:	e9 42 f0 ff ff       	jmp    801062e4 <alltraps>

801072a2 <vector229>:
.globl vector229
vector229:
  pushl $0
801072a2:	6a 00                	push   $0x0
  pushl $229
801072a4:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801072a9:	e9 36 f0 ff ff       	jmp    801062e4 <alltraps>

801072ae <vector230>:
.globl vector230
vector230:
  pushl $0
801072ae:	6a 00                	push   $0x0
  pushl $230
801072b0:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801072b5:	e9 2a f0 ff ff       	jmp    801062e4 <alltraps>

801072ba <vector231>:
.globl vector231
vector231:
  pushl $0
801072ba:	6a 00                	push   $0x0
  pushl $231
801072bc:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801072c1:	e9 1e f0 ff ff       	jmp    801062e4 <alltraps>

801072c6 <vector232>:
.globl vector232
vector232:
  pushl $0
801072c6:	6a 00                	push   $0x0
  pushl $232
801072c8:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
801072cd:	e9 12 f0 ff ff       	jmp    801062e4 <alltraps>

801072d2 <vector233>:
.globl vector233
vector233:
  pushl $0
801072d2:	6a 00                	push   $0x0
  pushl $233
801072d4:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
801072d9:	e9 06 f0 ff ff       	jmp    801062e4 <alltraps>

801072de <vector234>:
.globl vector234
vector234:
  pushl $0
801072de:	6a 00                	push   $0x0
  pushl $234
801072e0:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
801072e5:	e9 fa ef ff ff       	jmp    801062e4 <alltraps>

801072ea <vector235>:
.globl vector235
vector235:
  pushl $0
801072ea:	6a 00                	push   $0x0
  pushl $235
801072ec:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
801072f1:	e9 ee ef ff ff       	jmp    801062e4 <alltraps>

801072f6 <vector236>:
.globl vector236
vector236:
  pushl $0
801072f6:	6a 00                	push   $0x0
  pushl $236
801072f8:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
801072fd:	e9 e2 ef ff ff       	jmp    801062e4 <alltraps>

80107302 <vector237>:
.globl vector237
vector237:
  pushl $0
80107302:	6a 00                	push   $0x0
  pushl $237
80107304:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107309:	e9 d6 ef ff ff       	jmp    801062e4 <alltraps>

8010730e <vector238>:
.globl vector238
vector238:
  pushl $0
8010730e:	6a 00                	push   $0x0
  pushl $238
80107310:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107315:	e9 ca ef ff ff       	jmp    801062e4 <alltraps>

8010731a <vector239>:
.globl vector239
vector239:
  pushl $0
8010731a:	6a 00                	push   $0x0
  pushl $239
8010731c:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107321:	e9 be ef ff ff       	jmp    801062e4 <alltraps>

80107326 <vector240>:
.globl vector240
vector240:
  pushl $0
80107326:	6a 00                	push   $0x0
  pushl $240
80107328:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
8010732d:	e9 b2 ef ff ff       	jmp    801062e4 <alltraps>

80107332 <vector241>:
.globl vector241
vector241:
  pushl $0
80107332:	6a 00                	push   $0x0
  pushl $241
80107334:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
80107339:	e9 a6 ef ff ff       	jmp    801062e4 <alltraps>

8010733e <vector242>:
.globl vector242
vector242:
  pushl $0
8010733e:	6a 00                	push   $0x0
  pushl $242
80107340:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107345:	e9 9a ef ff ff       	jmp    801062e4 <alltraps>

8010734a <vector243>:
.globl vector243
vector243:
  pushl $0
8010734a:	6a 00                	push   $0x0
  pushl $243
8010734c:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107351:	e9 8e ef ff ff       	jmp    801062e4 <alltraps>

80107356 <vector244>:
.globl vector244
vector244:
  pushl $0
80107356:	6a 00                	push   $0x0
  pushl $244
80107358:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
8010735d:	e9 82 ef ff ff       	jmp    801062e4 <alltraps>

80107362 <vector245>:
.globl vector245
vector245:
  pushl $0
80107362:	6a 00                	push   $0x0
  pushl $245
80107364:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
80107369:	e9 76 ef ff ff       	jmp    801062e4 <alltraps>

8010736e <vector246>:
.globl vector246
vector246:
  pushl $0
8010736e:	6a 00                	push   $0x0
  pushl $246
80107370:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107375:	e9 6a ef ff ff       	jmp    801062e4 <alltraps>

8010737a <vector247>:
.globl vector247
vector247:
  pushl $0
8010737a:	6a 00                	push   $0x0
  pushl $247
8010737c:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
80107381:	e9 5e ef ff ff       	jmp    801062e4 <alltraps>

80107386 <vector248>:
.globl vector248
vector248:
  pushl $0
80107386:	6a 00                	push   $0x0
  pushl $248
80107388:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010738d:	e9 52 ef ff ff       	jmp    801062e4 <alltraps>

80107392 <vector249>:
.globl vector249
vector249:
  pushl $0
80107392:	6a 00                	push   $0x0
  pushl $249
80107394:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107399:	e9 46 ef ff ff       	jmp    801062e4 <alltraps>

8010739e <vector250>:
.globl vector250
vector250:
  pushl $0
8010739e:	6a 00                	push   $0x0
  pushl $250
801073a0:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801073a5:	e9 3a ef ff ff       	jmp    801062e4 <alltraps>

801073aa <vector251>:
.globl vector251
vector251:
  pushl $0
801073aa:	6a 00                	push   $0x0
  pushl $251
801073ac:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801073b1:	e9 2e ef ff ff       	jmp    801062e4 <alltraps>

801073b6 <vector252>:
.globl vector252
vector252:
  pushl $0
801073b6:	6a 00                	push   $0x0
  pushl $252
801073b8:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801073bd:	e9 22 ef ff ff       	jmp    801062e4 <alltraps>

801073c2 <vector253>:
.globl vector253
vector253:
  pushl $0
801073c2:	6a 00                	push   $0x0
  pushl $253
801073c4:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801073c9:	e9 16 ef ff ff       	jmp    801062e4 <alltraps>

801073ce <vector254>:
.globl vector254
vector254:
  pushl $0
801073ce:	6a 00                	push   $0x0
  pushl $254
801073d0:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
801073d5:	e9 0a ef ff ff       	jmp    801062e4 <alltraps>

801073da <vector255>:
.globl vector255
vector255:
  pushl $0
801073da:	6a 00                	push   $0x0
  pushl $255
801073dc:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
801073e1:	e9 fe ee ff ff       	jmp    801062e4 <alltraps>
	...

801073e8 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
801073e8:	55                   	push   %ebp
801073e9:	89 e5                	mov    %esp,%ebp
801073eb:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
801073ee:	8b 45 0c             	mov    0xc(%ebp),%eax
801073f1:	83 e8 01             	sub    $0x1,%eax
801073f4:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
801073f8:	8b 45 08             	mov    0x8(%ebp),%eax
801073fb:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
801073ff:	8b 45 08             	mov    0x8(%ebp),%eax
80107402:	c1 e8 10             	shr    $0x10,%eax
80107405:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107409:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010740c:	0f 01 10             	lgdtl  (%eax)
}
8010740f:	c9                   	leave  
80107410:	c3                   	ret    

80107411 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107411:	55                   	push   %ebp
80107412:	89 e5                	mov    %esp,%ebp
80107414:	83 ec 04             	sub    $0x4,%esp
80107417:	8b 45 08             	mov    0x8(%ebp),%eax
8010741a:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
8010741e:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107422:	0f 00 d8             	ltr    %ax
}
80107425:	c9                   	leave  
80107426:	c3                   	ret    

80107427 <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107427:	55                   	push   %ebp
80107428:	89 e5                	mov    %esp,%ebp
8010742a:	83 ec 04             	sub    $0x4,%esp
8010742d:	8b 45 08             	mov    0x8(%ebp),%eax
80107430:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107434:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107438:	8e e8                	mov    %eax,%gs
}
8010743a:	c9                   	leave  
8010743b:	c3                   	ret    

8010743c <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
8010743c:	55                   	push   %ebp
8010743d:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
8010743f:	8b 45 08             	mov    0x8(%ebp),%eax
80107442:	0f 22 d8             	mov    %eax,%cr3
}
80107445:	5d                   	pop    %ebp
80107446:	c3                   	ret    

80107447 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107447:	55                   	push   %ebp
80107448:	89 e5                	mov    %esp,%ebp
8010744a:	8b 45 08             	mov    0x8(%ebp),%eax
8010744d:	05 00 00 00 80       	add    $0x80000000,%eax
80107452:	5d                   	pop    %ebp
80107453:	c3                   	ret    

80107454 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107454:	55                   	push   %ebp
80107455:	89 e5                	mov    %esp,%ebp
80107457:	8b 45 08             	mov    0x8(%ebp),%eax
8010745a:	05 00 00 00 80       	add    $0x80000000,%eax
8010745f:	5d                   	pop    %ebp
80107460:	c3                   	ret    

80107461 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107461:	55                   	push   %ebp
80107462:	89 e5                	mov    %esp,%ebp
80107464:	53                   	push   %ebx
80107465:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107468:	e8 d8 ba ff ff       	call   80102f45 <cpunum>
8010746d:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107473:	05 20 fe 10 80       	add    $0x8010fe20,%eax
80107478:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
8010747b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010747e:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107484:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107487:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
8010748d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107490:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107494:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107497:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010749b:	83 e2 f0             	and    $0xfffffff0,%edx
8010749e:	83 ca 0a             	or     $0xa,%edx
801074a1:	88 50 7d             	mov    %dl,0x7d(%eax)
801074a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074a7:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074ab:	83 ca 10             	or     $0x10,%edx
801074ae:	88 50 7d             	mov    %dl,0x7d(%eax)
801074b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074b4:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074b8:	83 e2 9f             	and    $0xffffff9f,%edx
801074bb:	88 50 7d             	mov    %dl,0x7d(%eax)
801074be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074c1:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074c5:	83 ca 80             	or     $0xffffff80,%edx
801074c8:	88 50 7d             	mov    %dl,0x7d(%eax)
801074cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074ce:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801074d2:	83 ca 0f             	or     $0xf,%edx
801074d5:	88 50 7e             	mov    %dl,0x7e(%eax)
801074d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074db:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801074df:	83 e2 ef             	and    $0xffffffef,%edx
801074e2:	88 50 7e             	mov    %dl,0x7e(%eax)
801074e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074e8:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801074ec:	83 e2 df             	and    $0xffffffdf,%edx
801074ef:	88 50 7e             	mov    %dl,0x7e(%eax)
801074f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074f5:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
801074f9:	83 ca 40             	or     $0x40,%edx
801074fc:	88 50 7e             	mov    %dl,0x7e(%eax)
801074ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107502:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107506:	83 ca 80             	or     $0xffffff80,%edx
80107509:	88 50 7e             	mov    %dl,0x7e(%eax)
8010750c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010750f:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107513:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107516:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010751d:	ff ff 
8010751f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107522:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107529:	00 00 
8010752b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010752e:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107535:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107538:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010753f:	83 e2 f0             	and    $0xfffffff0,%edx
80107542:	83 ca 02             	or     $0x2,%edx
80107545:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010754b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010754e:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107555:	83 ca 10             	or     $0x10,%edx
80107558:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010755e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107561:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107568:	83 e2 9f             	and    $0xffffff9f,%edx
8010756b:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107571:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107574:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010757b:	83 ca 80             	or     $0xffffff80,%edx
8010757e:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107584:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107587:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010758e:	83 ca 0f             	or     $0xf,%edx
80107591:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107597:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010759a:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075a1:	83 e2 ef             	and    $0xffffffef,%edx
801075a4:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075ad:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075b4:	83 e2 df             	and    $0xffffffdf,%edx
801075b7:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075c0:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075c7:	83 ca 40             	or     $0x40,%edx
801075ca:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075d3:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075da:	83 ca 80             	or     $0xffffff80,%edx
801075dd:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075e6:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
801075ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075f0:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
801075f7:	ff ff 
801075f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075fc:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107603:	00 00 
80107605:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107608:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
8010760f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107612:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107619:	83 e2 f0             	and    $0xfffffff0,%edx
8010761c:	83 ca 0a             	or     $0xa,%edx
8010761f:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107625:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107628:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010762f:	83 ca 10             	or     $0x10,%edx
80107632:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010763b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107642:	83 ca 60             	or     $0x60,%edx
80107645:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010764b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010764e:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107655:	83 ca 80             	or     $0xffffff80,%edx
80107658:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010765e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107661:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107668:	83 ca 0f             	or     $0xf,%edx
8010766b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107671:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107674:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010767b:	83 e2 ef             	and    $0xffffffef,%edx
8010767e:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107684:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107687:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010768e:	83 e2 df             	and    $0xffffffdf,%edx
80107691:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107697:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010769a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076a1:	83 ca 40             	or     $0x40,%edx
801076a4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ad:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076b4:	83 ca 80             	or     $0xffffff80,%edx
801076b7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076c0:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801076c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ca:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
801076d1:	ff ff 
801076d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076d6:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
801076dd:	00 00 
801076df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e2:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
801076e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ec:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
801076f3:	83 e2 f0             	and    $0xfffffff0,%edx
801076f6:	83 ca 02             	or     $0x2,%edx
801076f9:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
801076ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107702:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107709:	83 ca 10             	or     $0x10,%edx
8010770c:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107712:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107715:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010771c:	83 ca 60             	or     $0x60,%edx
8010771f:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107725:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107728:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010772f:	83 ca 80             	or     $0xffffff80,%edx
80107732:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107738:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010773b:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107742:	83 ca 0f             	or     $0xf,%edx
80107745:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010774b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010774e:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107755:	83 e2 ef             	and    $0xffffffef,%edx
80107758:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010775e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107761:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107768:	83 e2 df             	and    $0xffffffdf,%edx
8010776b:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107771:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107774:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010777b:	83 ca 40             	or     $0x40,%edx
8010777e:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107784:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107787:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010778e:	83 ca 80             	or     $0xffffff80,%edx
80107791:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107797:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010779a:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801077a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a4:	05 b4 00 00 00       	add    $0xb4,%eax
801077a9:	89 c3                	mov    %eax,%ebx
801077ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ae:	05 b4 00 00 00       	add    $0xb4,%eax
801077b3:	c1 e8 10             	shr    $0x10,%eax
801077b6:	89 c1                	mov    %eax,%ecx
801077b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077bb:	05 b4 00 00 00       	add    $0xb4,%eax
801077c0:	c1 e8 18             	shr    $0x18,%eax
801077c3:	89 c2                	mov    %eax,%edx
801077c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077c8:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
801077cf:	00 00 
801077d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d4:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
801077db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077de:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
801077e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e7:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
801077ee:	83 e1 f0             	and    $0xfffffff0,%ecx
801077f1:	83 c9 02             	or     $0x2,%ecx
801077f4:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
801077fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077fd:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107804:	83 c9 10             	or     $0x10,%ecx
80107807:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010780d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107810:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107817:	83 e1 9f             	and    $0xffffff9f,%ecx
8010781a:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107820:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107823:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010782a:	83 c9 80             	or     $0xffffff80,%ecx
8010782d:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107833:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107836:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
8010783d:	83 e1 f0             	and    $0xfffffff0,%ecx
80107840:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107846:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107849:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107850:	83 e1 ef             	and    $0xffffffef,%ecx
80107853:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107859:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010785c:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107863:	83 e1 df             	and    $0xffffffdf,%ecx
80107866:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010786c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786f:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107876:	83 c9 40             	or     $0x40,%ecx
80107879:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010787f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107882:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107889:	83 c9 80             	or     $0xffffff80,%ecx
8010788c:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107892:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107895:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
8010789b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010789e:	83 c0 70             	add    $0x70,%eax
801078a1:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801078a8:	00 
801078a9:	89 04 24             	mov    %eax,(%esp)
801078ac:	e8 37 fb ff ff       	call   801073e8 <lgdt>
  loadgs(SEG_KCPU << 3);
801078b1:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801078b8:	e8 6a fb ff ff       	call   80107427 <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
801078bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c0:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
801078c6:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
801078cd:	00 00 00 00 
}
801078d1:	83 c4 24             	add    $0x24,%esp
801078d4:	5b                   	pop    %ebx
801078d5:	5d                   	pop    %ebp
801078d6:	c3                   	ret    

801078d7 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
801078d7:	55                   	push   %ebp
801078d8:	89 e5                	mov    %esp,%ebp
801078da:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
801078dd:	8b 45 0c             	mov    0xc(%ebp),%eax
801078e0:	c1 e8 16             	shr    $0x16,%eax
801078e3:	c1 e0 02             	shl    $0x2,%eax
801078e6:	03 45 08             	add    0x8(%ebp),%eax
801078e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
801078ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801078ef:	8b 00                	mov    (%eax),%eax
801078f1:	83 e0 01             	and    $0x1,%eax
801078f4:	84 c0                	test   %al,%al
801078f6:	74 17                	je     8010790f <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
801078f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801078fb:	8b 00                	mov    (%eax),%eax
801078fd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107902:	89 04 24             	mov    %eax,(%esp)
80107905:	e8 4a fb ff ff       	call   80107454 <p2v>
8010790a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010790d:	eb 4b                	jmp    8010795a <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
8010790f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107913:	74 0e                	je     80107923 <walkpgdir+0x4c>
80107915:	e8 9d b2 ff ff       	call   80102bb7 <kalloc>
8010791a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010791d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107921:	75 07                	jne    8010792a <walkpgdir+0x53>
      return 0;
80107923:	b8 00 00 00 00       	mov    $0x0,%eax
80107928:	eb 41                	jmp    8010796b <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010792a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107931:	00 
80107932:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107939:	00 
8010793a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010793d:	89 04 24             	mov    %eax,(%esp)
80107940:	e8 65 d5 ff ff       	call   80104eaa <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107945:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107948:	89 04 24             	mov    %eax,(%esp)
8010794b:	e8 f7 fa ff ff       	call   80107447 <v2p>
80107950:	89 c2                	mov    %eax,%edx
80107952:	83 ca 07             	or     $0x7,%edx
80107955:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107958:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
8010795a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010795d:	c1 e8 0c             	shr    $0xc,%eax
80107960:	25 ff 03 00 00       	and    $0x3ff,%eax
80107965:	c1 e0 02             	shl    $0x2,%eax
80107968:	03 45 f4             	add    -0xc(%ebp),%eax
}
8010796b:	c9                   	leave  
8010796c:	c3                   	ret    

8010796d <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
8010796d:	55                   	push   %ebp
8010796e:	89 e5                	mov    %esp,%ebp
80107970:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107973:	8b 45 0c             	mov    0xc(%ebp),%eax
80107976:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010797b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
8010797e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107981:	03 45 10             	add    0x10(%ebp),%eax
80107984:	83 e8 01             	sub    $0x1,%eax
80107987:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010798c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
8010798f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
80107996:	00 
80107997:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010799a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010799e:	8b 45 08             	mov    0x8(%ebp),%eax
801079a1:	89 04 24             	mov    %eax,(%esp)
801079a4:	e8 2e ff ff ff       	call   801078d7 <walkpgdir>
801079a9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801079ac:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801079b0:	75 07                	jne    801079b9 <mappages+0x4c>
      return -1;
801079b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801079b7:	eb 46                	jmp    801079ff <mappages+0x92>
    if(*pte & PTE_P)
801079b9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801079bc:	8b 00                	mov    (%eax),%eax
801079be:	83 e0 01             	and    $0x1,%eax
801079c1:	84 c0                	test   %al,%al
801079c3:	74 0c                	je     801079d1 <mappages+0x64>
      panic("remap");
801079c5:	c7 04 24 20 88 10 80 	movl   $0x80108820,(%esp)
801079cc:	e8 6c 8b ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
801079d1:	8b 45 18             	mov    0x18(%ebp),%eax
801079d4:	0b 45 14             	or     0x14(%ebp),%eax
801079d7:	89 c2                	mov    %eax,%edx
801079d9:	83 ca 01             	or     $0x1,%edx
801079dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801079df:	89 10                	mov    %edx,(%eax)
    if(a == last)
801079e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801079e7:	74 10                	je     801079f9 <mappages+0x8c>
      break;
    a += PGSIZE;
801079e9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
801079f0:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
801079f7:	eb 96                	jmp    8010798f <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
801079f9:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
801079fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801079ff:	c9                   	leave  
80107a00:	c3                   	ret    

80107a01 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107a01:	55                   	push   %ebp
80107a02:	89 e5                	mov    %esp,%ebp
80107a04:	53                   	push   %ebx
80107a05:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107a08:	e8 aa b1 ff ff       	call   80102bb7 <kalloc>
80107a0d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107a10:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107a14:	75 0a                	jne    80107a20 <setupkvm+0x1f>
    return 0;
80107a16:	b8 00 00 00 00       	mov    $0x0,%eax
80107a1b:	e9 98 00 00 00       	jmp    80107ab8 <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107a20:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107a27:	00 
80107a28:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a2f:	00 
80107a30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a33:	89 04 24             	mov    %eax,(%esp)
80107a36:	e8 6f d4 ff ff       	call   80104eaa <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107a3b:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107a42:	e8 0d fa ff ff       	call   80107454 <p2v>
80107a47:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107a4c:	76 0c                	jbe    80107a5a <setupkvm+0x59>
    panic("PHYSTOP too high");
80107a4e:	c7 04 24 26 88 10 80 	movl   $0x80108826,(%esp)
80107a55:	e8 e3 8a ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107a5a:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107a61:	eb 49                	jmp    80107aac <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107a66:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107a69:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107a6c:	8b 50 04             	mov    0x4(%eax),%edx
80107a6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a72:	8b 58 08             	mov    0x8(%eax),%ebx
80107a75:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a78:	8b 40 04             	mov    0x4(%eax),%eax
80107a7b:	29 c3                	sub    %eax,%ebx
80107a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a80:	8b 00                	mov    (%eax),%eax
80107a82:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107a86:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107a8a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107a8e:	89 44 24 04          	mov    %eax,0x4(%esp)
80107a92:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a95:	89 04 24             	mov    %eax,(%esp)
80107a98:	e8 d0 fe ff ff       	call   8010796d <mappages>
80107a9d:	85 c0                	test   %eax,%eax
80107a9f:	79 07                	jns    80107aa8 <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107aa1:	b8 00 00 00 00       	mov    $0x0,%eax
80107aa6:	eb 10                	jmp    80107ab8 <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107aa8:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107aac:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107ab3:	72 ae                	jb     80107a63 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107ab5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107ab8:	83 c4 34             	add    $0x34,%esp
80107abb:	5b                   	pop    %ebx
80107abc:	5d                   	pop    %ebp
80107abd:	c3                   	ret    

80107abe <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107abe:	55                   	push   %ebp
80107abf:	89 e5                	mov    %esp,%ebp
80107ac1:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107ac4:	e8 38 ff ff ff       	call   80107a01 <setupkvm>
80107ac9:	a3 f8 2b 11 80       	mov    %eax,0x80112bf8
  switchkvm();
80107ace:	e8 02 00 00 00       	call   80107ad5 <switchkvm>
}
80107ad3:	c9                   	leave  
80107ad4:	c3                   	ret    

80107ad5 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107ad5:	55                   	push   %ebp
80107ad6:	89 e5                	mov    %esp,%ebp
80107ad8:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107adb:	a1 f8 2b 11 80       	mov    0x80112bf8,%eax
80107ae0:	89 04 24             	mov    %eax,(%esp)
80107ae3:	e8 5f f9 ff ff       	call   80107447 <v2p>
80107ae8:	89 04 24             	mov    %eax,(%esp)
80107aeb:	e8 4c f9 ff ff       	call   8010743c <lcr3>
}
80107af0:	c9                   	leave  
80107af1:	c3                   	ret    

80107af2 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107af2:	55                   	push   %ebp
80107af3:	89 e5                	mov    %esp,%ebp
80107af5:	53                   	push   %ebx
80107af6:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107af9:	e8 a5 d2 ff ff       	call   80104da3 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107afe:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b04:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b0b:	83 c2 08             	add    $0x8,%edx
80107b0e:	89 d3                	mov    %edx,%ebx
80107b10:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b17:	83 c2 08             	add    $0x8,%edx
80107b1a:	c1 ea 10             	shr    $0x10,%edx
80107b1d:	89 d1                	mov    %edx,%ecx
80107b1f:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b26:	83 c2 08             	add    $0x8,%edx
80107b29:	c1 ea 18             	shr    $0x18,%edx
80107b2c:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107b33:	67 00 
80107b35:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107b3c:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107b42:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b49:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b4c:	83 c9 09             	or     $0x9,%ecx
80107b4f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b55:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b5c:	83 c9 10             	or     $0x10,%ecx
80107b5f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b65:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b6c:	83 e1 9f             	and    $0xffffff9f,%ecx
80107b6f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b75:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b7c:	83 c9 80             	or     $0xffffff80,%ecx
80107b7f:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b85:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b8c:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b8f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107b95:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107b9c:	83 e1 ef             	and    $0xffffffef,%ecx
80107b9f:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107ba5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bac:	83 e1 df             	and    $0xffffffdf,%ecx
80107baf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bb5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bbc:	83 c9 40             	or     $0x40,%ecx
80107bbf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bc5:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bcc:	83 e1 7f             	and    $0x7f,%ecx
80107bcf:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bd5:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107bdb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107be1:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107be8:	83 e2 ef             	and    $0xffffffef,%edx
80107beb:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107bf1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107bf7:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107bfd:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c03:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107c0a:	8b 52 08             	mov    0x8(%edx),%edx
80107c0d:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107c13:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107c16:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107c1d:	e8 ef f7 ff ff       	call   80107411 <ltr>
  if(p->pgdir == 0)
80107c22:	8b 45 08             	mov    0x8(%ebp),%eax
80107c25:	8b 40 04             	mov    0x4(%eax),%eax
80107c28:	85 c0                	test   %eax,%eax
80107c2a:	75 0c                	jne    80107c38 <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107c2c:	c7 04 24 37 88 10 80 	movl   $0x80108837,(%esp)
80107c33:	e8 05 89 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107c38:	8b 45 08             	mov    0x8(%ebp),%eax
80107c3b:	8b 40 04             	mov    0x4(%eax),%eax
80107c3e:	89 04 24             	mov    %eax,(%esp)
80107c41:	e8 01 f8 ff ff       	call   80107447 <v2p>
80107c46:	89 04 24             	mov    %eax,(%esp)
80107c49:	e8 ee f7 ff ff       	call   8010743c <lcr3>
  popcli();
80107c4e:	e8 98 d1 ff ff       	call   80104deb <popcli>
}
80107c53:	83 c4 14             	add    $0x14,%esp
80107c56:	5b                   	pop    %ebx
80107c57:	5d                   	pop    %ebp
80107c58:	c3                   	ret    

80107c59 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107c59:	55                   	push   %ebp
80107c5a:	89 e5                	mov    %esp,%ebp
80107c5c:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107c5f:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107c66:	76 0c                	jbe    80107c74 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107c68:	c7 04 24 4b 88 10 80 	movl   $0x8010884b,(%esp)
80107c6f:	e8 c9 88 ff ff       	call   8010053d <panic>
  mem = kalloc();
80107c74:	e8 3e af ff ff       	call   80102bb7 <kalloc>
80107c79:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107c7c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107c83:	00 
80107c84:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107c8b:	00 
80107c8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c8f:	89 04 24             	mov    %eax,(%esp)
80107c92:	e8 13 d2 ff ff       	call   80104eaa <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107c97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c9a:	89 04 24             	mov    %eax,(%esp)
80107c9d:	e8 a5 f7 ff ff       	call   80107447 <v2p>
80107ca2:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107ca9:	00 
80107caa:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107cae:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107cb5:	00 
80107cb6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cbd:	00 
80107cbe:	8b 45 08             	mov    0x8(%ebp),%eax
80107cc1:	89 04 24             	mov    %eax,(%esp)
80107cc4:	e8 a4 fc ff ff       	call   8010796d <mappages>
  memmove(mem, init, sz);
80107cc9:	8b 45 10             	mov    0x10(%ebp),%eax
80107ccc:	89 44 24 08          	mov    %eax,0x8(%esp)
80107cd0:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cd3:	89 44 24 04          	mov    %eax,0x4(%esp)
80107cd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cda:	89 04 24             	mov    %eax,(%esp)
80107cdd:	e8 9b d2 ff ff       	call   80104f7d <memmove>
}
80107ce2:	c9                   	leave  
80107ce3:	c3                   	ret    

80107ce4 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107ce4:	55                   	push   %ebp
80107ce5:	89 e5                	mov    %esp,%ebp
80107ce7:	53                   	push   %ebx
80107ce8:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107ceb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107cee:	25 ff 0f 00 00       	and    $0xfff,%eax
80107cf3:	85 c0                	test   %eax,%eax
80107cf5:	74 0c                	je     80107d03 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107cf7:	c7 04 24 68 88 10 80 	movl   $0x80108868,(%esp)
80107cfe:	e8 3a 88 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107d03:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107d0a:	e9 ad 00 00 00       	jmp    80107dbc <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107d0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d12:	8b 55 0c             	mov    0xc(%ebp),%edx
80107d15:	01 d0                	add    %edx,%eax
80107d17:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107d1e:	00 
80107d1f:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d23:	8b 45 08             	mov    0x8(%ebp),%eax
80107d26:	89 04 24             	mov    %eax,(%esp)
80107d29:	e8 a9 fb ff ff       	call   801078d7 <walkpgdir>
80107d2e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107d31:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107d35:	75 0c                	jne    80107d43 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107d37:	c7 04 24 8b 88 10 80 	movl   $0x8010888b,(%esp)
80107d3e:	e8 fa 87 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80107d43:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d46:	8b 00                	mov    (%eax),%eax
80107d48:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d4d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107d50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d53:	8b 55 18             	mov    0x18(%ebp),%edx
80107d56:	89 d1                	mov    %edx,%ecx
80107d58:	29 c1                	sub    %eax,%ecx
80107d5a:	89 c8                	mov    %ecx,%eax
80107d5c:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107d61:	77 11                	ja     80107d74 <loaduvm+0x90>
      n = sz - i;
80107d63:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d66:	8b 55 18             	mov    0x18(%ebp),%edx
80107d69:	89 d1                	mov    %edx,%ecx
80107d6b:	29 c1                	sub    %eax,%ecx
80107d6d:	89 c8                	mov    %ecx,%eax
80107d6f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107d72:	eb 07                	jmp    80107d7b <loaduvm+0x97>
    else
      n = PGSIZE;
80107d74:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107d7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d7e:	8b 55 14             	mov    0x14(%ebp),%edx
80107d81:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107d84:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107d87:	89 04 24             	mov    %eax,(%esp)
80107d8a:	e8 c5 f6 ff ff       	call   80107454 <p2v>
80107d8f:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107d92:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107d96:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107d9a:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d9e:	8b 45 10             	mov    0x10(%ebp),%eax
80107da1:	89 04 24             	mov    %eax,(%esp)
80107da4:	e8 6d a0 ff ff       	call   80101e16 <readi>
80107da9:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107dac:	74 07                	je     80107db5 <loaduvm+0xd1>
      return -1;
80107dae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107db3:	eb 18                	jmp    80107dcd <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107db5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107dbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dbf:	3b 45 18             	cmp    0x18(%ebp),%eax
80107dc2:	0f 82 47 ff ff ff    	jb     80107d0f <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107dc8:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107dcd:	83 c4 24             	add    $0x24,%esp
80107dd0:	5b                   	pop    %ebx
80107dd1:	5d                   	pop    %ebp
80107dd2:	c3                   	ret    

80107dd3 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107dd3:	55                   	push   %ebp
80107dd4:	89 e5                	mov    %esp,%ebp
80107dd6:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107dd9:	8b 45 10             	mov    0x10(%ebp),%eax
80107ddc:	85 c0                	test   %eax,%eax
80107dde:	79 0a                	jns    80107dea <allocuvm+0x17>
    return 0;
80107de0:	b8 00 00 00 00       	mov    $0x0,%eax
80107de5:	e9 c1 00 00 00       	jmp    80107eab <allocuvm+0xd8>
  if(newsz < oldsz)
80107dea:	8b 45 10             	mov    0x10(%ebp),%eax
80107ded:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107df0:	73 08                	jae    80107dfa <allocuvm+0x27>
    return oldsz;
80107df2:	8b 45 0c             	mov    0xc(%ebp),%eax
80107df5:	e9 b1 00 00 00       	jmp    80107eab <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107dfa:	8b 45 0c             	mov    0xc(%ebp),%eax
80107dfd:	05 ff 0f 00 00       	add    $0xfff,%eax
80107e02:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e07:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107e0a:	e9 8d 00 00 00       	jmp    80107e9c <allocuvm+0xc9>
    mem = kalloc();
80107e0f:	e8 a3 ad ff ff       	call   80102bb7 <kalloc>
80107e14:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107e17:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107e1b:	75 2c                	jne    80107e49 <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107e1d:	c7 04 24 a9 88 10 80 	movl   $0x801088a9,(%esp)
80107e24:	e8 78 85 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107e29:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e2c:	89 44 24 08          	mov    %eax,0x8(%esp)
80107e30:	8b 45 10             	mov    0x10(%ebp),%eax
80107e33:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e37:	8b 45 08             	mov    0x8(%ebp),%eax
80107e3a:	89 04 24             	mov    %eax,(%esp)
80107e3d:	e8 6b 00 00 00       	call   80107ead <deallocuvm>
      return 0;
80107e42:	b8 00 00 00 00       	mov    $0x0,%eax
80107e47:	eb 62                	jmp    80107eab <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107e49:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e50:	00 
80107e51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e58:	00 
80107e59:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e5c:	89 04 24             	mov    %eax,(%esp)
80107e5f:	e8 46 d0 ff ff       	call   80104eaa <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107e64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e67:	89 04 24             	mov    %eax,(%esp)
80107e6a:	e8 d8 f5 ff ff       	call   80107447 <v2p>
80107e6f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107e72:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107e79:	00 
80107e7a:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107e7e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e85:	00 
80107e86:	89 54 24 04          	mov    %edx,0x4(%esp)
80107e8a:	8b 45 08             	mov    0x8(%ebp),%eax
80107e8d:	89 04 24             	mov    %eax,(%esp)
80107e90:	e8 d8 fa ff ff       	call   8010796d <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107e95:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107e9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e9f:	3b 45 10             	cmp    0x10(%ebp),%eax
80107ea2:	0f 82 67 ff ff ff    	jb     80107e0f <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107ea8:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107eab:	c9                   	leave  
80107eac:	c3                   	ret    

80107ead <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107ead:	55                   	push   %ebp
80107eae:	89 e5                	mov    %esp,%ebp
80107eb0:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107eb3:	8b 45 10             	mov    0x10(%ebp),%eax
80107eb6:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107eb9:	72 08                	jb     80107ec3 <deallocuvm+0x16>
    return oldsz;
80107ebb:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ebe:	e9 a4 00 00 00       	jmp    80107f67 <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107ec3:	8b 45 10             	mov    0x10(%ebp),%eax
80107ec6:	05 ff 0f 00 00       	add    $0xfff,%eax
80107ecb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ed0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107ed3:	e9 80 00 00 00       	jmp    80107f58 <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107ed8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107edb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107ee2:	00 
80107ee3:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ee7:	8b 45 08             	mov    0x8(%ebp),%eax
80107eea:	89 04 24             	mov    %eax,(%esp)
80107eed:	e8 e5 f9 ff ff       	call   801078d7 <walkpgdir>
80107ef2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107ef5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107ef9:	75 09                	jne    80107f04 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107efb:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107f02:	eb 4d                	jmp    80107f51 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107f04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f07:	8b 00                	mov    (%eax),%eax
80107f09:	83 e0 01             	and    $0x1,%eax
80107f0c:	84 c0                	test   %al,%al
80107f0e:	74 41                	je     80107f51 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107f10:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f13:	8b 00                	mov    (%eax),%eax
80107f15:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f1a:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107f1d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107f21:	75 0c                	jne    80107f2f <deallocuvm+0x82>
        panic("kfree");
80107f23:	c7 04 24 c1 88 10 80 	movl   $0x801088c1,(%esp)
80107f2a:	e8 0e 86 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80107f2f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107f32:	89 04 24             	mov    %eax,(%esp)
80107f35:	e8 1a f5 ff ff       	call   80107454 <p2v>
80107f3a:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107f3d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107f40:	89 04 24             	mov    %eax,(%esp)
80107f43:	e8 d6 ab ff ff       	call   80102b1e <kfree>
      *pte = 0;
80107f48:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f4b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80107f51:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107f58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f5b:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f5e:	0f 82 74 ff ff ff    	jb     80107ed8 <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80107f64:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107f67:	c9                   	leave  
80107f68:	c3                   	ret    

80107f69 <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80107f69:	55                   	push   %ebp
80107f6a:	89 e5                	mov    %esp,%ebp
80107f6c:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80107f6f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107f73:	75 0c                	jne    80107f81 <freevm+0x18>
    panic("freevm: no pgdir");
80107f75:	c7 04 24 c7 88 10 80 	movl   $0x801088c7,(%esp)
80107f7c:	e8 bc 85 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80107f81:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f88:	00 
80107f89:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80107f90:	80 
80107f91:	8b 45 08             	mov    0x8(%ebp),%eax
80107f94:	89 04 24             	mov    %eax,(%esp)
80107f97:	e8 11 ff ff ff       	call   80107ead <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80107f9c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107fa3:	eb 3c                	jmp    80107fe1 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80107fa5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fa8:	c1 e0 02             	shl    $0x2,%eax
80107fab:	03 45 08             	add    0x8(%ebp),%eax
80107fae:	8b 00                	mov    (%eax),%eax
80107fb0:	83 e0 01             	and    $0x1,%eax
80107fb3:	84 c0                	test   %al,%al
80107fb5:	74 26                	je     80107fdd <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80107fb7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fba:	c1 e0 02             	shl    $0x2,%eax
80107fbd:	03 45 08             	add    0x8(%ebp),%eax
80107fc0:	8b 00                	mov    (%eax),%eax
80107fc2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fc7:	89 04 24             	mov    %eax,(%esp)
80107fca:	e8 85 f4 ff ff       	call   80107454 <p2v>
80107fcf:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80107fd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fd5:	89 04 24             	mov    %eax,(%esp)
80107fd8:	e8 41 ab ff ff       	call   80102b1e <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80107fdd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80107fe1:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80107fe8:	76 bb                	jbe    80107fa5 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80107fea:	8b 45 08             	mov    0x8(%ebp),%eax
80107fed:	89 04 24             	mov    %eax,(%esp)
80107ff0:	e8 29 ab ff ff       	call   80102b1e <kfree>
}
80107ff5:	c9                   	leave  
80107ff6:	c3                   	ret    

80107ff7 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80107ff7:	55                   	push   %ebp
80107ff8:	89 e5                	mov    %esp,%ebp
80107ffa:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80107ffd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108004:	00 
80108005:	8b 45 0c             	mov    0xc(%ebp),%eax
80108008:	89 44 24 04          	mov    %eax,0x4(%esp)
8010800c:	8b 45 08             	mov    0x8(%ebp),%eax
8010800f:	89 04 24             	mov    %eax,(%esp)
80108012:	e8 c0 f8 ff ff       	call   801078d7 <walkpgdir>
80108017:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010801a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010801e:	75 0c                	jne    8010802c <clearpteu+0x35>
    panic("clearpteu");
80108020:	c7 04 24 d8 88 10 80 	movl   $0x801088d8,(%esp)
80108027:	e8 11 85 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
8010802c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010802f:	8b 00                	mov    (%eax),%eax
80108031:	89 c2                	mov    %eax,%edx
80108033:	83 e2 fb             	and    $0xfffffffb,%edx
80108036:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108039:	89 10                	mov    %edx,(%eax)
}
8010803b:	c9                   	leave  
8010803c:	c3                   	ret    

8010803d <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
8010803d:	55                   	push   %ebp
8010803e:	89 e5                	mov    %esp,%ebp
80108040:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108043:	e8 b9 f9 ff ff       	call   80107a01 <setupkvm>
80108048:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010804b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010804f:	75 0a                	jne    8010805b <copyuvm+0x1e>
    return 0;
80108051:	b8 00 00 00 00       	mov    $0x0,%eax
80108056:	e9 f1 00 00 00       	jmp    8010814c <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
8010805b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108062:	e9 c0 00 00 00       	jmp    80108127 <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
80108067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108071:	00 
80108072:	89 44 24 04          	mov    %eax,0x4(%esp)
80108076:	8b 45 08             	mov    0x8(%ebp),%eax
80108079:	89 04 24             	mov    %eax,(%esp)
8010807c:	e8 56 f8 ff ff       	call   801078d7 <walkpgdir>
80108081:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108084:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108088:	75 0c                	jne    80108096 <copyuvm+0x59>
      panic("copyuvm: pte should exist");
8010808a:	c7 04 24 e2 88 10 80 	movl   $0x801088e2,(%esp)
80108091:	e8 a7 84 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
80108096:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108099:	8b 00                	mov    (%eax),%eax
8010809b:	83 e0 01             	and    $0x1,%eax
8010809e:	85 c0                	test   %eax,%eax
801080a0:	75 0c                	jne    801080ae <copyuvm+0x71>
      panic("copyuvm: page not present");
801080a2:	c7 04 24 fc 88 10 80 	movl   $0x801088fc,(%esp)
801080a9:	e8 8f 84 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801080ae:	8b 45 ec             	mov    -0x14(%ebp),%eax
801080b1:	8b 00                	mov    (%eax),%eax
801080b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080b8:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
801080bb:	e8 f7 aa ff ff       	call   80102bb7 <kalloc>
801080c0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801080c3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801080c7:	74 6f                	je     80108138 <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
801080c9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801080cc:	89 04 24             	mov    %eax,(%esp)
801080cf:	e8 80 f3 ff ff       	call   80107454 <p2v>
801080d4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801080db:	00 
801080dc:	89 44 24 04          	mov    %eax,0x4(%esp)
801080e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801080e3:	89 04 24             	mov    %eax,(%esp)
801080e6:	e8 92 ce ff ff       	call   80104f7d <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
801080eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801080ee:	89 04 24             	mov    %eax,(%esp)
801080f1:	e8 51 f3 ff ff       	call   80107447 <v2p>
801080f6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801080f9:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108100:	00 
80108101:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108105:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010810c:	00 
8010810d:	89 54 24 04          	mov    %edx,0x4(%esp)
80108111:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108114:	89 04 24             	mov    %eax,(%esp)
80108117:	e8 51 f8 ff ff       	call   8010796d <mappages>
8010811c:	85 c0                	test   %eax,%eax
8010811e:	78 1b                	js     8010813b <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108120:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010812a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010812d:	0f 82 34 ff ff ff    	jb     80108067 <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108133:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108136:	eb 14                	jmp    8010814c <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108138:	90                   	nop
80108139:	eb 01                	jmp    8010813c <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
8010813b:	90                   	nop
  }
  return d;

bad:
  freevm(d);
8010813c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010813f:	89 04 24             	mov    %eax,(%esp)
80108142:	e8 22 fe ff ff       	call   80107f69 <freevm>
  return 0;
80108147:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010814c:	c9                   	leave  
8010814d:	c3                   	ret    

8010814e <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
8010814e:	55                   	push   %ebp
8010814f:	89 e5                	mov    %esp,%ebp
80108151:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108154:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010815b:	00 
8010815c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010815f:	89 44 24 04          	mov    %eax,0x4(%esp)
80108163:	8b 45 08             	mov    0x8(%ebp),%eax
80108166:	89 04 24             	mov    %eax,(%esp)
80108169:	e8 69 f7 ff ff       	call   801078d7 <walkpgdir>
8010816e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
80108171:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108174:	8b 00                	mov    (%eax),%eax
80108176:	83 e0 01             	and    $0x1,%eax
80108179:	85 c0                	test   %eax,%eax
8010817b:	75 07                	jne    80108184 <uva2ka+0x36>
    return 0;
8010817d:	b8 00 00 00 00       	mov    $0x0,%eax
80108182:	eb 25                	jmp    801081a9 <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
80108184:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108187:	8b 00                	mov    (%eax),%eax
80108189:	83 e0 04             	and    $0x4,%eax
8010818c:	85 c0                	test   %eax,%eax
8010818e:	75 07                	jne    80108197 <uva2ka+0x49>
    return 0;
80108190:	b8 00 00 00 00       	mov    $0x0,%eax
80108195:	eb 12                	jmp    801081a9 <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
80108197:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819a:	8b 00                	mov    (%eax),%eax
8010819c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081a1:	89 04 24             	mov    %eax,(%esp)
801081a4:	e8 ab f2 ff ff       	call   80107454 <p2v>
}
801081a9:	c9                   	leave  
801081aa:	c3                   	ret    

801081ab <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801081ab:	55                   	push   %ebp
801081ac:	89 e5                	mov    %esp,%ebp
801081ae:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801081b1:	8b 45 10             	mov    0x10(%ebp),%eax
801081b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801081b7:	e9 8b 00 00 00       	jmp    80108247 <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
801081bc:	8b 45 0c             	mov    0xc(%ebp),%eax
801081bf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801081c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081ca:	89 44 24 04          	mov    %eax,0x4(%esp)
801081ce:	8b 45 08             	mov    0x8(%ebp),%eax
801081d1:	89 04 24             	mov    %eax,(%esp)
801081d4:	e8 75 ff ff ff       	call   8010814e <uva2ka>
801081d9:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
801081dc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801081e0:	75 07                	jne    801081e9 <copyout+0x3e>
      return -1;
801081e2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801081e7:	eb 6d                	jmp    80108256 <copyout+0xab>
    n = PGSIZE - (va - va0);
801081e9:	8b 45 0c             	mov    0xc(%ebp),%eax
801081ec:	8b 55 ec             	mov    -0x14(%ebp),%edx
801081ef:	89 d1                	mov    %edx,%ecx
801081f1:	29 c1                	sub    %eax,%ecx
801081f3:	89 c8                	mov    %ecx,%eax
801081f5:	05 00 10 00 00       	add    $0x1000,%eax
801081fa:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
801081fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108200:	3b 45 14             	cmp    0x14(%ebp),%eax
80108203:	76 06                	jbe    8010820b <copyout+0x60>
      n = len;
80108205:	8b 45 14             	mov    0x14(%ebp),%eax
80108208:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010820b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010820e:	8b 55 0c             	mov    0xc(%ebp),%edx
80108211:	89 d1                	mov    %edx,%ecx
80108213:	29 c1                	sub    %eax,%ecx
80108215:	89 c8                	mov    %ecx,%eax
80108217:	03 45 e8             	add    -0x18(%ebp),%eax
8010821a:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010821d:	89 54 24 08          	mov    %edx,0x8(%esp)
80108221:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108224:	89 54 24 04          	mov    %edx,0x4(%esp)
80108228:	89 04 24             	mov    %eax,(%esp)
8010822b:	e8 4d cd ff ff       	call   80104f7d <memmove>
    len -= n;
80108230:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108233:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
80108236:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108239:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
8010823c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010823f:	05 00 10 00 00       	add    $0x1000,%eax
80108244:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108247:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010824b:	0f 85 6b ff ff ff    	jne    801081bc <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108251:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108256:	c9                   	leave  
80108257:	c3                   	ret    
