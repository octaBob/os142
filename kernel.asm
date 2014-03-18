
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
8010002d:	b8 5b 34 10 80       	mov    $0x8010345b,%eax
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
8010003a:	c7 44 24 04 8c 82 10 	movl   $0x8010828c,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
80100049:	e8 f0 4b 00 00       	call   80104c3e <initlock>

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
801000bd:	e8 9d 4b 00 00       	call   80104c5f <acquire>

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
80100104:	e8 b8 4b 00 00       	call   80104cc1 <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 60 c6 10 	movl   $0x8010c660,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 5d 48 00 00       	call   80104981 <sleep>
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
8010017c:	e8 40 4b 00 00       	call   80104cc1 <release>
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
80100198:	c7 04 24 93 82 10 80 	movl   $0x80108293,(%esp)
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
801001d3:	e8 30 26 00 00       	call   80102808 <iderw>
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
801001ef:	c7 04 24 a4 82 10 80 	movl   $0x801082a4,(%esp)
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
80100210:	e8 f3 25 00 00       	call   80102808 <iderw>
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
80100229:	c7 04 24 ab 82 10 80 	movl   $0x801082ab,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
8010023c:	e8 1e 4a 00 00       	call   80104c5f <acquire>

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
8010029d:	e8 b8 47 00 00       	call   80104a5a <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 60 c6 10 80 	movl   $0x8010c660,(%esp)
801002a9:	e8 13 4a 00 00       	call   80104cc1 <release>
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
801003bc:	e8 9e 48 00 00       	call   80104c5f <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 b2 82 10 80 	movl   $0x801082b2,(%esp)
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
801004af:	c7 45 ec bb 82 10 80 	movl   $0x801082bb,-0x14(%ebp)
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
80100536:	e8 86 47 00 00       	call   80104cc1 <release>
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
80100562:	c7 04 24 c2 82 10 80 	movl   $0x801082c2,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 d1 82 10 80 	movl   $0x801082d1,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 79 47 00 00       	call   80104d10 <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 d3 82 10 80 	movl   $0x801082d3,(%esp)
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
801006b2:	e8 ca 48 00 00       	call   80104f81 <memmove>
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
801006e1:	e8 c8 47 00 00       	call   80104eae <memset>
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
80100776:	e8 76 61 00 00       	call   801068f1 <uartputc>
8010077b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80100782:	e8 6a 61 00 00       	call   801068f1 <uartputc>
80100787:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010078e:	e8 5e 61 00 00       	call   801068f1 <uartputc>
80100793:	eb 0b                	jmp    801007a0 <consputc+0x50>
  } else
    uartputc(c);
80100795:	8b 45 08             	mov    0x8(%ebp),%eax
80100798:	89 04 24             	mov    %eax,(%esp)
8010079b:	e8 51 61 00 00       	call   801068f1 <uartputc>
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
801007ba:	e8 a0 44 00 00       	call   80104c5f <acquire>
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
801007ea:	e8 0e 43 00 00       	call   80104afd <procdump>
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
801008f7:	e8 5e 41 00 00       	call   80104a5a <wakeup>
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
8010091e:	e8 9e 43 00 00       	call   80104cc1 <release>
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
80100931:	e8 d4 10 00 00       	call   80101a0a <iunlock>
  target = n;
80100936:	8b 45 10             	mov    0x10(%ebp),%eax
80100939:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
8010093c:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100943:	e8 17 43 00 00       	call   80104c5f <acquire>
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
80100961:	e8 5b 43 00 00       	call   80104cc1 <release>
        ilock(ip);
80100966:	8b 45 08             	mov    0x8(%ebp),%eax
80100969:	89 04 24             	mov    %eax,(%esp)
8010096c:	e8 4b 0f 00 00       	call   801018bc <ilock>
        return -1;
80100971:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100976:	e9 a9 00 00 00       	jmp    80100a24 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
8010097b:	c7 44 24 04 a0 dd 10 	movl   $0x8010dda0,0x4(%esp)
80100982:	80 
80100983:	c7 04 24 54 de 10 80 	movl   $0x8010de54,(%esp)
8010098a:	e8 f2 3f 00 00       	call   80104981 <sleep>
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
80100a08:	e8 b4 42 00 00       	call   80104cc1 <release>
  ilock(ip);
80100a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a10:	89 04 24             	mov    %eax,(%esp)
80100a13:	e8 a4 0e 00 00       	call   801018bc <ilock>

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
80100a32:	e8 d3 0f 00 00       	call   80101a0a <iunlock>
  acquire(&cons.lock);
80100a37:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100a3e:	e8 1c 42 00 00       	call   80104c5f <acquire>
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
80100a78:	e8 44 42 00 00       	call   80104cc1 <release>
  ilock(ip);
80100a7d:	8b 45 08             	mov    0x8(%ebp),%eax
80100a80:	89 04 24             	mov    %eax,(%esp)
80100a83:	e8 34 0e 00 00       	call   801018bc <ilock>

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
80100a93:	c7 44 24 04 d7 82 10 	movl   $0x801082d7,0x4(%esp)
80100a9a:	80 
80100a9b:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80100aa2:	e8 97 41 00 00       	call   80104c3e <initlock>
  initlock(&input.lock, "input");
80100aa7:	c7 44 24 04 df 82 10 	movl   $0x801082df,0x4(%esp)
80100aae:	80 
80100aaf:	c7 04 24 a0 dd 10 80 	movl   $0x8010dda0,(%esp)
80100ab6:	e8 83 41 00 00       	call   80104c3e <initlock>

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
80100ae0:	e8 30 30 00 00       	call   80103b15 <picenable>
  ioapicenable(IRQ_KBD, 0);
80100ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100aec:	00 
80100aed:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80100af4:	e8 d1 1e 00 00       	call   801029ca <ioapicenable>
}
80100af9:	c9                   	leave  
80100afa:	c3                   	ret    
	...

80100afc <exec>:
  


int
exec(char *path, char **argv)
{
80100afc:	55                   	push   %ebp
80100afd:	89 e5                	mov    %esp,%ebp
80100aff:	81 ec 38 01 00 00    	sub    $0x138,%esp
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  
  //----------------------- PATCH -------------------//
  if((ip = namei(path)) == 0){
80100b05:	8b 45 08             	mov    0x8(%ebp),%eax
80100b08:	89 04 24             	mov    %eax,(%esp)
80100b0b:	e8 4e 19 00 00       	call   8010245e <namei>
80100b10:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b13:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b17:	75 5e                	jne    80100b77 <exec+0x7b>
      for(i = 0; i<lastPath; i++){
80100b19:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100b20:	eb 41                	jmp    80100b63 <exec+0x67>
	  cprintf("%d\n", i);
80100b22:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100b25:	89 44 24 04          	mov    %eax,0x4(%esp)
80100b29:	c7 04 24 e5 82 10 80 	movl   $0x801082e5,(%esp)
80100b30:	e8 6c f8 ff ff       	call   801003a1 <cprintf>
 	  if ((ip = namei(PATH[i])) != 0){
80100b35:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100b38:	c1 e0 07             	shl    $0x7,%eax
80100b3b:	05 60 de 10 80       	add    $0x8010de60,%eax
80100b40:	89 04 24             	mov    %eax,(%esp)
80100b43:	e8 16 19 00 00       	call   8010245e <namei>
80100b48:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100b4b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100b4f:	74 0e                	je     80100b5f <exec+0x63>
	     //cprintf("%d\n", ip);
	      cprintf("found him!!\n");
80100b51:	c7 04 24 e9 82 10 80 	movl   $0x801082e9,(%esp)
80100b58:	e8 44 f8 ff ff       	call   801003a1 <cprintf>
	      goto cont;
80100b5d:	eb 18                	jmp    80100b77 <exec+0x7b>
  pde_t *pgdir, *oldpgdir;

  
  //----------------------- PATCH -------------------//
  if((ip = namei(path)) == 0){
      for(i = 0; i<lastPath; i++){
80100b5f:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100b63:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
80100b68:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80100b6b:	7c b5                	jl     80100b22 <exec+0x26>
	     //cprintf("%d\n", ip);
	      cprintf("found him!!\n");
	      goto cont;
	  }
      }
      return -1;
80100b6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100b72:	e9 da 03 00 00       	jmp    80100f51 <exec+0x455>
  }
  cont:
  //cprintf("%d\n", ip);
//----------------------- PATCH -------------------//
  ilock(ip);
80100b77:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100b7a:	89 04 24             	mov    %eax,(%esp)
80100b7d:	e8 3a 0d 00 00       	call   801018bc <ilock>
  pgdir = 0;
80100b82:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
80100b89:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
80100b90:	00 
80100b91:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80100b98:	00 
80100b99:	8d 85 0c ff ff ff    	lea    -0xf4(%ebp),%eax
80100b9f:	89 44 24 04          	mov    %eax,0x4(%esp)
80100ba3:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100ba6:	89 04 24             	mov    %eax,(%esp)
80100ba9:	e8 04 12 00 00       	call   80101db2 <readi>
80100bae:	83 f8 33             	cmp    $0x33,%eax
80100bb1:	0f 86 54 03 00 00    	jbe    80100f0b <exec+0x40f>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100bb7:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
80100bbd:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100bc2:	0f 85 46 03 00 00    	jne    80100f0e <exec+0x412>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
80100bc8:	c7 04 24 53 2b 10 80 	movl   $0x80102b53,(%esp)
80100bcf:	e8 61 6e 00 00       	call   80107a35 <setupkvm>
80100bd4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100bd7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100bdb:	0f 84 30 03 00 00    	je     80100f11 <exec+0x415>
    goto bad;

  // Load program into memory.
  sz = 0;
80100be1:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100be8:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100bef:	8b 85 28 ff ff ff    	mov    -0xd8(%ebp),%eax
80100bf5:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100bf8:	e9 c5 00 00 00       	jmp    80100cc2 <exec+0x1c6>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100bfd:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c00:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80100c07:	00 
80100c08:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c0c:	8d 85 ec fe ff ff    	lea    -0x114(%ebp),%eax
80100c12:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c16:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100c19:	89 04 24             	mov    %eax,(%esp)
80100c1c:	e8 91 11 00 00       	call   80101db2 <readi>
80100c21:	83 f8 20             	cmp    $0x20,%eax
80100c24:	0f 85 ea 02 00 00    	jne    80100f14 <exec+0x418>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100c2a:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100c30:	83 f8 01             	cmp    $0x1,%eax
80100c33:	75 7f                	jne    80100cb4 <exec+0x1b8>
      continue;
    if(ph.memsz < ph.filesz)
80100c35:	8b 95 00 ff ff ff    	mov    -0x100(%ebp),%edx
80100c3b:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100c41:	39 c2                	cmp    %eax,%edx
80100c43:	0f 82 ce 02 00 00    	jb     80100f17 <exec+0x41b>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100c49:	8b 95 f4 fe ff ff    	mov    -0x10c(%ebp),%edx
80100c4f:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
80100c55:	01 d0                	add    %edx,%eax
80100c57:	89 44 24 08          	mov    %eax,0x8(%esp)
80100c5b:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100c5e:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c62:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100c65:	89 04 24             	mov    %eax,(%esp)
80100c68:	e8 9a 71 00 00       	call   80107e07 <allocuvm>
80100c6d:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100c70:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100c74:	0f 84 a0 02 00 00    	je     80100f1a <exec+0x41e>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100c7a:	8b 8d fc fe ff ff    	mov    -0x104(%ebp),%ecx
80100c80:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c86:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
80100c8c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80100c90:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100c94:	8b 55 d8             	mov    -0x28(%ebp),%edx
80100c97:	89 54 24 08          	mov    %edx,0x8(%esp)
80100c9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100c9f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100ca2:	89 04 24             	mov    %eax,(%esp)
80100ca5:	e8 6e 70 00 00       	call   80107d18 <loaduvm>
80100caa:	85 c0                	test   %eax,%eax
80100cac:	0f 88 6b 02 00 00    	js     80100f1d <exec+0x421>
80100cb2:	eb 01                	jmp    80100cb5 <exec+0x1b9>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100cb4:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100cb5:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100cb9:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100cbc:	83 c0 20             	add    $0x20,%eax
80100cbf:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100cc2:	0f b7 85 38 ff ff ff 	movzwl -0xc8(%ebp),%eax
80100cc9:	0f b7 c0             	movzwl %ax,%eax
80100ccc:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100ccf:	0f 8f 28 ff ff ff    	jg     80100bfd <exec+0x101>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100cd5:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100cd8:	89 04 24             	mov    %eax,(%esp)
80100cdb:	e8 60 0e 00 00       	call   80101b40 <iunlockput>
  ip = 0;
80100ce0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100ce7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cea:	05 ff 0f 00 00       	add    $0xfff,%eax
80100cef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100cf4:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100cf7:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100cfa:	05 00 20 00 00       	add    $0x2000,%eax
80100cff:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d03:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d06:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d0a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d0d:	89 04 24             	mov    %eax,(%esp)
80100d10:	e8 f2 70 00 00       	call   80107e07 <allocuvm>
80100d15:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d18:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d1c:	0f 84 fe 01 00 00    	je     80100f20 <exec+0x424>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d22:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d25:	2d 00 20 00 00       	sub    $0x2000,%eax
80100d2a:	89 44 24 04          	mov    %eax,0x4(%esp)
80100d2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100d31:	89 04 24             	mov    %eax,(%esp)
80100d34:	e8 f2 72 00 00       	call   8010802b <clearpteu>
  sp = sz;
80100d39:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d3c:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100d3f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100d46:	e9 81 00 00 00       	jmp    80100dcc <exec+0x2d0>
    if(argc >= MAXARG)
80100d4b:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100d4f:	0f 87 ce 01 00 00    	ja     80100f23 <exec+0x427>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100d55:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d58:	c1 e0 02             	shl    $0x2,%eax
80100d5b:	03 45 0c             	add    0xc(%ebp),%eax
80100d5e:	8b 00                	mov    (%eax),%eax
80100d60:	89 04 24             	mov    %eax,(%esp)
80100d63:	e8 c4 43 00 00       	call   8010512c <strlen>
80100d68:	f7 d0                	not    %eax
80100d6a:	03 45 dc             	add    -0x24(%ebp),%eax
80100d6d:	83 e0 fc             	and    $0xfffffffc,%eax
80100d70:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100d73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d76:	c1 e0 02             	shl    $0x2,%eax
80100d79:	03 45 0c             	add    0xc(%ebp),%eax
80100d7c:	8b 00                	mov    (%eax),%eax
80100d7e:	89 04 24             	mov    %eax,(%esp)
80100d81:	e8 a6 43 00 00       	call   8010512c <strlen>
80100d86:	83 c0 01             	add    $0x1,%eax
80100d89:	89 c2                	mov    %eax,%edx
80100d8b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100d8e:	c1 e0 02             	shl    $0x2,%eax
80100d91:	03 45 0c             	add    0xc(%ebp),%eax
80100d94:	8b 00                	mov    (%eax),%eax
80100d96:	89 54 24 0c          	mov    %edx,0xc(%esp)
80100d9a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100d9e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100da1:	89 44 24 04          	mov    %eax,0x4(%esp)
80100da5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100da8:	89 04 24             	mov    %eax,(%esp)
80100dab:	e8 2f 74 00 00       	call   801081df <copyout>
80100db0:	85 c0                	test   %eax,%eax
80100db2:	0f 88 6e 01 00 00    	js     80100f26 <exec+0x42a>
      goto bad;
    ustack[3+argc] = sp;
80100db8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dbb:	8d 50 03             	lea    0x3(%eax),%edx
80100dbe:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dc1:	89 84 95 40 ff ff ff 	mov    %eax,-0xc0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100dc8:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100dcc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcf:	c1 e0 02             	shl    $0x2,%eax
80100dd2:	03 45 0c             	add    0xc(%ebp),%eax
80100dd5:	8b 00                	mov    (%eax),%eax
80100dd7:	85 c0                	test   %eax,%eax
80100dd9:	0f 85 6c ff ff ff    	jne    80100d4b <exec+0x24f>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100ddf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100de2:	83 c0 03             	add    $0x3,%eax
80100de5:	c7 84 85 40 ff ff ff 	movl   $0x0,-0xc0(%ebp,%eax,4)
80100dec:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100df0:	c7 85 40 ff ff ff ff 	movl   $0xffffffff,-0xc0(%ebp)
80100df7:	ff ff ff 
  ustack[1] = argc;
80100dfa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfd:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e03:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e06:	83 c0 01             	add    $0x1,%eax
80100e09:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e10:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e13:	29 d0                	sub    %edx,%eax
80100e15:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)

  sp -= (3+argc+1) * 4;
80100e1b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e1e:	83 c0 04             	add    $0x4,%eax
80100e21:	c1 e0 02             	shl    $0x2,%eax
80100e24:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100e27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e2a:	83 c0 04             	add    $0x4,%eax
80100e2d:	c1 e0 02             	shl    $0x2,%eax
80100e30:	89 44 24 0c          	mov    %eax,0xc(%esp)
80100e34:	8d 85 40 ff ff ff    	lea    -0xc0(%ebp),%eax
80100e3a:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e3e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e41:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100e48:	89 04 24             	mov    %eax,(%esp)
80100e4b:	e8 8f 73 00 00       	call   801081df <copyout>
80100e50:	85 c0                	test   %eax,%eax
80100e52:	0f 88 d1 00 00 00    	js     80100f29 <exec+0x42d>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e58:	8b 45 08             	mov    0x8(%ebp),%eax
80100e5b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e61:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100e64:	eb 17                	jmp    80100e7d <exec+0x381>
    if(*s == '/')
80100e66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e69:	0f b6 00             	movzbl (%eax),%eax
80100e6c:	3c 2f                	cmp    $0x2f,%al
80100e6e:	75 09                	jne    80100e79 <exec+0x37d>
      last = s+1;
80100e70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e73:	83 c0 01             	add    $0x1,%eax
80100e76:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100e79:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e80:	0f b6 00             	movzbl (%eax),%eax
80100e83:	84 c0                	test   %al,%al
80100e85:	75 df                	jne    80100e66 <exec+0x36a>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
80100e87:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100e8d:	8d 50 6c             	lea    0x6c(%eax),%edx
80100e90:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80100e97:	00 
80100e98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100e9b:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e9f:	89 14 24             	mov    %edx,(%esp)
80100ea2:	e8 37 42 00 00       	call   801050de <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
80100ea7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ead:	8b 40 04             	mov    0x4(%eax),%eax
80100eb0:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
80100eb3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100eb9:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100ebc:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
80100ebf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ec5:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100ec8:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
80100eca:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ed0:	8b 40 18             	mov    0x18(%eax),%eax
80100ed3:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
80100ed9:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
80100edc:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ee2:	8b 40 18             	mov    0x18(%eax),%eax
80100ee5:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100ee8:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
80100eeb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100ef1:	89 04 24             	mov    %eax,(%esp)
80100ef4:	e8 2d 6c 00 00       	call   80107b26 <switchuvm>
  freevm(oldpgdir);
80100ef9:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100efc:	89 04 24             	mov    %eax,(%esp)
80100eff:	e8 99 70 00 00       	call   80107f9d <freevm>
  return 0;
80100f04:	b8 00 00 00 00       	mov    $0x0,%eax
80100f09:	eb 46                	jmp    80100f51 <exec+0x455>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
80100f0b:	90                   	nop
80100f0c:	eb 1c                	jmp    80100f2a <exec+0x42e>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100f0e:	90                   	nop
80100f0f:	eb 19                	jmp    80100f2a <exec+0x42e>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80100f11:	90                   	nop
80100f12:	eb 16                	jmp    80100f2a <exec+0x42e>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100f14:	90                   	nop
80100f15:	eb 13                	jmp    80100f2a <exec+0x42e>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100f17:	90                   	nop
80100f18:	eb 10                	jmp    80100f2a <exec+0x42e>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100f1a:	90                   	nop
80100f1b:	eb 0d                	jmp    80100f2a <exec+0x42e>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100f1d:	90                   	nop
80100f1e:	eb 0a                	jmp    80100f2a <exec+0x42e>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100f20:	90                   	nop
80100f21:	eb 07                	jmp    80100f2a <exec+0x42e>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100f23:	90                   	nop
80100f24:	eb 04                	jmp    80100f2a <exec+0x42e>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100f26:	90                   	nop
80100f27:	eb 01                	jmp    80100f2a <exec+0x42e>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100f29:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100f2a:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100f2e:	74 0b                	je     80100f3b <exec+0x43f>
    freevm(pgdir);
80100f30:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80100f33:	89 04 24             	mov    %eax,(%esp)
80100f36:	e8 62 70 00 00       	call   80107f9d <freevm>
  if(ip)
80100f3b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100f3f:	74 0b                	je     80100f4c <exec+0x450>
    iunlockput(ip);
80100f41:	8b 45 d8             	mov    -0x28(%ebp),%eax
80100f44:	89 04 24             	mov    %eax,(%esp)
80100f47:	e8 f4 0b 00 00       	call   80101b40 <iunlockput>
  return -1;
80100f4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100f51:	c9                   	leave  
80100f52:	c3                   	ret    
	...

80100f54 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100f54:	55                   	push   %ebp
80100f55:	89 e5                	mov    %esp,%ebp
80100f57:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
80100f5a:	c7 44 24 04 f6 82 10 	movl   $0x801082f6,0x4(%esp)
80100f61:	80 
80100f62:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80100f69:	e8 d0 3c 00 00       	call   80104c3e <initlock>
}
80100f6e:	c9                   	leave  
80100f6f:	c3                   	ret    

80100f70 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100f70:	55                   	push   %ebp
80100f71:	89 e5                	mov    %esp,%ebp
80100f73:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
80100f76:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80100f7d:	e8 dd 3c 00 00       	call   80104c5f <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100f82:	c7 45 f4 94 e3 10 80 	movl   $0x8010e394,-0xc(%ebp)
80100f89:	eb 29                	jmp    80100fb4 <filealloc+0x44>
    if(f->ref == 0){
80100f8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f8e:	8b 40 04             	mov    0x4(%eax),%eax
80100f91:	85 c0                	test   %eax,%eax
80100f93:	75 1b                	jne    80100fb0 <filealloc+0x40>
      f->ref = 1;
80100f95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f98:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80100f9f:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80100fa6:	e8 16 3d 00 00       	call   80104cc1 <release>
      return f;
80100fab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100fae:	eb 1e                	jmp    80100fce <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80100fb0:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
80100fb4:	81 7d f4 f4 ec 10 80 	cmpl   $0x8010ecf4,-0xc(%ebp)
80100fbb:	72 ce                	jb     80100f8b <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80100fbd:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80100fc4:	e8 f8 3c 00 00       	call   80104cc1 <release>
  return 0;
80100fc9:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100fce:	c9                   	leave  
80100fcf:	c3                   	ret    

80100fd0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80100fd0:	55                   	push   %ebp
80100fd1:	89 e5                	mov    %esp,%ebp
80100fd3:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
80100fd6:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80100fdd:	e8 7d 3c 00 00       	call   80104c5f <acquire>
  if(f->ref < 1)
80100fe2:	8b 45 08             	mov    0x8(%ebp),%eax
80100fe5:	8b 40 04             	mov    0x4(%eax),%eax
80100fe8:	85 c0                	test   %eax,%eax
80100fea:	7f 0c                	jg     80100ff8 <filedup+0x28>
    panic("filedup");
80100fec:	c7 04 24 fd 82 10 80 	movl   $0x801082fd,(%esp)
80100ff3:	e8 45 f5 ff ff       	call   8010053d <panic>
  f->ref++;
80100ff8:	8b 45 08             	mov    0x8(%ebp),%eax
80100ffb:	8b 40 04             	mov    0x4(%eax),%eax
80100ffe:	8d 50 01             	lea    0x1(%eax),%edx
80101001:	8b 45 08             	mov    0x8(%ebp),%eax
80101004:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
80101007:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
8010100e:	e8 ae 3c 00 00       	call   80104cc1 <release>
  return f;
80101013:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101016:	c9                   	leave  
80101017:	c3                   	ret    

80101018 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
80101018:	55                   	push   %ebp
80101019:	89 e5                	mov    %esp,%ebp
8010101b:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
8010101e:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80101025:	e8 35 3c 00 00       	call   80104c5f <acquire>
  if(f->ref < 1)
8010102a:	8b 45 08             	mov    0x8(%ebp),%eax
8010102d:	8b 40 04             	mov    0x4(%eax),%eax
80101030:	85 c0                	test   %eax,%eax
80101032:	7f 0c                	jg     80101040 <fileclose+0x28>
    panic("fileclose");
80101034:	c7 04 24 05 83 10 80 	movl   $0x80108305,(%esp)
8010103b:	e8 fd f4 ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
80101040:	8b 45 08             	mov    0x8(%ebp),%eax
80101043:	8b 40 04             	mov    0x4(%eax),%eax
80101046:	8d 50 ff             	lea    -0x1(%eax),%edx
80101049:	8b 45 08             	mov    0x8(%ebp),%eax
8010104c:	89 50 04             	mov    %edx,0x4(%eax)
8010104f:	8b 45 08             	mov    0x8(%ebp),%eax
80101052:	8b 40 04             	mov    0x4(%eax),%eax
80101055:	85 c0                	test   %eax,%eax
80101057:	7e 11                	jle    8010106a <fileclose+0x52>
    release(&ftable.lock);
80101059:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
80101060:	e8 5c 3c 00 00       	call   80104cc1 <release>
    return;
80101065:	e9 82 00 00 00       	jmp    801010ec <fileclose+0xd4>
  }
  ff = *f;
8010106a:	8b 45 08             	mov    0x8(%ebp),%eax
8010106d:	8b 10                	mov    (%eax),%edx
8010106f:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101072:	8b 50 04             	mov    0x4(%eax),%edx
80101075:	89 55 e4             	mov    %edx,-0x1c(%ebp)
80101078:	8b 50 08             	mov    0x8(%eax),%edx
8010107b:	89 55 e8             	mov    %edx,-0x18(%ebp)
8010107e:	8b 50 0c             	mov    0xc(%eax),%edx
80101081:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101084:	8b 50 10             	mov    0x10(%eax),%edx
80101087:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010108a:	8b 40 14             	mov    0x14(%eax),%eax
8010108d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101090:	8b 45 08             	mov    0x8(%ebp),%eax
80101093:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010109a:	8b 45 08             	mov    0x8(%ebp),%eax
8010109d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
801010a3:	c7 04 24 60 e3 10 80 	movl   $0x8010e360,(%esp)
801010aa:	e8 12 3c 00 00       	call   80104cc1 <release>
  
  if(ff.type == FD_PIPE)
801010af:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010b2:	83 f8 01             	cmp    $0x1,%eax
801010b5:	75 18                	jne    801010cf <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
801010b7:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801010bb:	0f be d0             	movsbl %al,%edx
801010be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801010c1:	89 54 24 04          	mov    %edx,0x4(%esp)
801010c5:	89 04 24             	mov    %eax,(%esp)
801010c8:	e8 02 2d 00 00       	call   80103dcf <pipeclose>
801010cd:	eb 1d                	jmp    801010ec <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801010cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
801010d2:	83 f8 02             	cmp    $0x2,%eax
801010d5:	75 15                	jne    801010ec <fileclose+0xd4>
    begin_trans();
801010d7:	e8 95 21 00 00       	call   80103271 <begin_trans>
    iput(ff.ip);
801010dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801010df:	89 04 24             	mov    %eax,(%esp)
801010e2:	e8 88 09 00 00       	call   80101a6f <iput>
    commit_trans();
801010e7:	e8 ce 21 00 00       	call   801032ba <commit_trans>
  }
}
801010ec:	c9                   	leave  
801010ed:	c3                   	ret    

801010ee <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
801010ee:	55                   	push   %ebp
801010ef:	89 e5                	mov    %esp,%ebp
801010f1:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
801010f4:	8b 45 08             	mov    0x8(%ebp),%eax
801010f7:	8b 00                	mov    (%eax),%eax
801010f9:	83 f8 02             	cmp    $0x2,%eax
801010fc:	75 38                	jne    80101136 <filestat+0x48>
    ilock(f->ip);
801010fe:	8b 45 08             	mov    0x8(%ebp),%eax
80101101:	8b 40 10             	mov    0x10(%eax),%eax
80101104:	89 04 24             	mov    %eax,(%esp)
80101107:	e8 b0 07 00 00       	call   801018bc <ilock>
    stati(f->ip, st);
8010110c:	8b 45 08             	mov    0x8(%ebp),%eax
8010110f:	8b 40 10             	mov    0x10(%eax),%eax
80101112:	8b 55 0c             	mov    0xc(%ebp),%edx
80101115:	89 54 24 04          	mov    %edx,0x4(%esp)
80101119:	89 04 24             	mov    %eax,(%esp)
8010111c:	e8 4c 0c 00 00       	call   80101d6d <stati>
    iunlock(f->ip);
80101121:	8b 45 08             	mov    0x8(%ebp),%eax
80101124:	8b 40 10             	mov    0x10(%eax),%eax
80101127:	89 04 24             	mov    %eax,(%esp)
8010112a:	e8 db 08 00 00       	call   80101a0a <iunlock>
    return 0;
8010112f:	b8 00 00 00 00       	mov    $0x0,%eax
80101134:	eb 05                	jmp    8010113b <filestat+0x4d>
  }
  return -1;
80101136:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010113b:	c9                   	leave  
8010113c:	c3                   	ret    

8010113d <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
8010113d:	55                   	push   %ebp
8010113e:	89 e5                	mov    %esp,%ebp
80101140:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101143:	8b 45 08             	mov    0x8(%ebp),%eax
80101146:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010114a:	84 c0                	test   %al,%al
8010114c:	75 0a                	jne    80101158 <fileread+0x1b>
    return -1;
8010114e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101153:	e9 9f 00 00 00       	jmp    801011f7 <fileread+0xba>
  if(f->type == FD_PIPE)
80101158:	8b 45 08             	mov    0x8(%ebp),%eax
8010115b:	8b 00                	mov    (%eax),%eax
8010115d:	83 f8 01             	cmp    $0x1,%eax
80101160:	75 1e                	jne    80101180 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101162:	8b 45 08             	mov    0x8(%ebp),%eax
80101165:	8b 40 0c             	mov    0xc(%eax),%eax
80101168:	8b 55 10             	mov    0x10(%ebp),%edx
8010116b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010116f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101172:	89 54 24 04          	mov    %edx,0x4(%esp)
80101176:	89 04 24             	mov    %eax,(%esp)
80101179:	e8 d3 2d 00 00       	call   80103f51 <piperead>
8010117e:	eb 77                	jmp    801011f7 <fileread+0xba>
  if(f->type == FD_INODE){
80101180:	8b 45 08             	mov    0x8(%ebp),%eax
80101183:	8b 00                	mov    (%eax),%eax
80101185:	83 f8 02             	cmp    $0x2,%eax
80101188:	75 61                	jne    801011eb <fileread+0xae>
    ilock(f->ip);
8010118a:	8b 45 08             	mov    0x8(%ebp),%eax
8010118d:	8b 40 10             	mov    0x10(%eax),%eax
80101190:	89 04 24             	mov    %eax,(%esp)
80101193:	e8 24 07 00 00       	call   801018bc <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
80101198:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010119b:	8b 45 08             	mov    0x8(%ebp),%eax
8010119e:	8b 50 14             	mov    0x14(%eax),%edx
801011a1:	8b 45 08             	mov    0x8(%ebp),%eax
801011a4:	8b 40 10             	mov    0x10(%eax),%eax
801011a7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801011ab:	89 54 24 08          	mov    %edx,0x8(%esp)
801011af:	8b 55 0c             	mov    0xc(%ebp),%edx
801011b2:	89 54 24 04          	mov    %edx,0x4(%esp)
801011b6:	89 04 24             	mov    %eax,(%esp)
801011b9:	e8 f4 0b 00 00       	call   80101db2 <readi>
801011be:	89 45 f4             	mov    %eax,-0xc(%ebp)
801011c1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801011c5:	7e 11                	jle    801011d8 <fileread+0x9b>
      f->off += r;
801011c7:	8b 45 08             	mov    0x8(%ebp),%eax
801011ca:	8b 50 14             	mov    0x14(%eax),%edx
801011cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011d0:	01 c2                	add    %eax,%edx
801011d2:	8b 45 08             	mov    0x8(%ebp),%eax
801011d5:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801011d8:	8b 45 08             	mov    0x8(%ebp),%eax
801011db:	8b 40 10             	mov    0x10(%eax),%eax
801011de:	89 04 24             	mov    %eax,(%esp)
801011e1:	e8 24 08 00 00       	call   80101a0a <iunlock>
    return r;
801011e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801011e9:	eb 0c                	jmp    801011f7 <fileread+0xba>
  }
  panic("fileread");
801011eb:	c7 04 24 0f 83 10 80 	movl   $0x8010830f,(%esp)
801011f2:	e8 46 f3 ff ff       	call   8010053d <panic>
}
801011f7:	c9                   	leave  
801011f8:	c3                   	ret    

801011f9 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801011f9:	55                   	push   %ebp
801011fa:	89 e5                	mov    %esp,%ebp
801011fc:	53                   	push   %ebx
801011fd:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
80101200:	8b 45 08             	mov    0x8(%ebp),%eax
80101203:	0f b6 40 09          	movzbl 0x9(%eax),%eax
80101207:	84 c0                	test   %al,%al
80101209:	75 0a                	jne    80101215 <filewrite+0x1c>
    return -1;
8010120b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101210:	e9 23 01 00 00       	jmp    80101338 <filewrite+0x13f>
  if(f->type == FD_PIPE)
80101215:	8b 45 08             	mov    0x8(%ebp),%eax
80101218:	8b 00                	mov    (%eax),%eax
8010121a:	83 f8 01             	cmp    $0x1,%eax
8010121d:	75 21                	jne    80101240 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
8010121f:	8b 45 08             	mov    0x8(%ebp),%eax
80101222:	8b 40 0c             	mov    0xc(%eax),%eax
80101225:	8b 55 10             	mov    0x10(%ebp),%edx
80101228:	89 54 24 08          	mov    %edx,0x8(%esp)
8010122c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010122f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101233:	89 04 24             	mov    %eax,(%esp)
80101236:	e8 26 2c 00 00       	call   80103e61 <pipewrite>
8010123b:	e9 f8 00 00 00       	jmp    80101338 <filewrite+0x13f>
  if(f->type == FD_INODE){
80101240:	8b 45 08             	mov    0x8(%ebp),%eax
80101243:	8b 00                	mov    (%eax),%eax
80101245:	83 f8 02             	cmp    $0x2,%eax
80101248:	0f 85 de 00 00 00    	jne    8010132c <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
8010124e:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101255:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
8010125c:	e9 a8 00 00 00       	jmp    80101309 <filewrite+0x110>
      int n1 = n - i;
80101261:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101264:	8b 55 10             	mov    0x10(%ebp),%edx
80101267:	89 d1                	mov    %edx,%ecx
80101269:	29 c1                	sub    %eax,%ecx
8010126b:	89 c8                	mov    %ecx,%eax
8010126d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101270:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101273:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80101276:	7e 06                	jle    8010127e <filewrite+0x85>
        n1 = max;
80101278:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010127b:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
8010127e:	e8 ee 1f 00 00       	call   80103271 <begin_trans>
      ilock(f->ip);
80101283:	8b 45 08             	mov    0x8(%ebp),%eax
80101286:	8b 40 10             	mov    0x10(%eax),%eax
80101289:	89 04 24             	mov    %eax,(%esp)
8010128c:	e8 2b 06 00 00       	call   801018bc <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
80101291:	8b 5d f0             	mov    -0x10(%ebp),%ebx
80101294:	8b 45 08             	mov    0x8(%ebp),%eax
80101297:	8b 48 14             	mov    0x14(%eax),%ecx
8010129a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010129d:	89 c2                	mov    %eax,%edx
8010129f:	03 55 0c             	add    0xc(%ebp),%edx
801012a2:	8b 45 08             	mov    0x8(%ebp),%eax
801012a5:	8b 40 10             	mov    0x10(%eax),%eax
801012a8:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801012ac:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801012b0:	89 54 24 04          	mov    %edx,0x4(%esp)
801012b4:	89 04 24             	mov    %eax,(%esp)
801012b7:	e8 61 0c 00 00       	call   80101f1d <writei>
801012bc:	89 45 e8             	mov    %eax,-0x18(%ebp)
801012bf:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012c3:	7e 11                	jle    801012d6 <filewrite+0xdd>
        f->off += r;
801012c5:	8b 45 08             	mov    0x8(%ebp),%eax
801012c8:	8b 50 14             	mov    0x14(%eax),%edx
801012cb:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012ce:	01 c2                	add    %eax,%edx
801012d0:	8b 45 08             	mov    0x8(%ebp),%eax
801012d3:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801012d6:	8b 45 08             	mov    0x8(%ebp),%eax
801012d9:	8b 40 10             	mov    0x10(%eax),%eax
801012dc:	89 04 24             	mov    %eax,(%esp)
801012df:	e8 26 07 00 00       	call   80101a0a <iunlock>
      commit_trans();
801012e4:	e8 d1 1f 00 00       	call   801032ba <commit_trans>

      if(r < 0)
801012e9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801012ed:	78 28                	js     80101317 <filewrite+0x11e>
        break;
      if(r != n1)
801012ef:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012f2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801012f5:	74 0c                	je     80101303 <filewrite+0x10a>
        panic("short filewrite");
801012f7:	c7 04 24 18 83 10 80 	movl   $0x80108318,(%esp)
801012fe:	e8 3a f2 ff ff       	call   8010053d <panic>
      i += r;
80101303:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101306:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
80101309:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010130c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010130f:	0f 8c 4c ff ff ff    	jl     80101261 <filewrite+0x68>
80101315:	eb 01                	jmp    80101318 <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
80101317:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
80101318:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010131b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010131e:	75 05                	jne    80101325 <filewrite+0x12c>
80101320:	8b 45 10             	mov    0x10(%ebp),%eax
80101323:	eb 05                	jmp    8010132a <filewrite+0x131>
80101325:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010132a:	eb 0c                	jmp    80101338 <filewrite+0x13f>
  }
  panic("filewrite");
8010132c:	c7 04 24 28 83 10 80 	movl   $0x80108328,(%esp)
80101333:	e8 05 f2 ff ff       	call   8010053d <panic>
}
80101338:	83 c4 24             	add    $0x24,%esp
8010133b:	5b                   	pop    %ebx
8010133c:	5d                   	pop    %ebp
8010133d:	c3                   	ret    
	...

80101340 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101340:	55                   	push   %ebp
80101341:	89 e5                	mov    %esp,%ebp
80101343:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
80101346:	8b 45 08             	mov    0x8(%ebp),%eax
80101349:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101350:	00 
80101351:	89 04 24             	mov    %eax,(%esp)
80101354:	e8 4d ee ff ff       	call   801001a6 <bread>
80101359:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
8010135c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010135f:	83 c0 18             	add    $0x18,%eax
80101362:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80101369:	00 
8010136a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010136e:	8b 45 0c             	mov    0xc(%ebp),%eax
80101371:	89 04 24             	mov    %eax,(%esp)
80101374:	e8 08 3c 00 00       	call   80104f81 <memmove>
  brelse(bp);
80101379:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010137c:	89 04 24             	mov    %eax,(%esp)
8010137f:	e8 93 ee ff ff       	call   80100217 <brelse>
}
80101384:	c9                   	leave  
80101385:	c3                   	ret    

80101386 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101386:	55                   	push   %ebp
80101387:	89 e5                	mov    %esp,%ebp
80101389:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
8010138c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010138f:	8b 45 08             	mov    0x8(%ebp),%eax
80101392:	89 54 24 04          	mov    %edx,0x4(%esp)
80101396:	89 04 24             	mov    %eax,(%esp)
80101399:	e8 08 ee ff ff       	call   801001a6 <bread>
8010139e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801013a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013a4:	83 c0 18             	add    $0x18,%eax
801013a7:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801013ae:	00 
801013af:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801013b6:	00 
801013b7:	89 04 24             	mov    %eax,(%esp)
801013ba:	e8 ef 3a 00 00       	call   80104eae <memset>
  log_write(bp);
801013bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c2:	89 04 24             	mov    %eax,(%esp)
801013c5:	e8 48 1f 00 00       	call   80103312 <log_write>
  brelse(bp);
801013ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013cd:	89 04 24             	mov    %eax,(%esp)
801013d0:	e8 42 ee ff ff       	call   80100217 <brelse>
}
801013d5:	c9                   	leave  
801013d6:	c3                   	ret    

801013d7 <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801013d7:	55                   	push   %ebp
801013d8:	89 e5                	mov    %esp,%ebp
801013da:	53                   	push   %ebx
801013db:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
801013de:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
801013e5:	8b 45 08             	mov    0x8(%ebp),%eax
801013e8:	8d 55 d8             	lea    -0x28(%ebp),%edx
801013eb:	89 54 24 04          	mov    %edx,0x4(%esp)
801013ef:	89 04 24             	mov    %eax,(%esp)
801013f2:	e8 49 ff ff ff       	call   80101340 <readsb>
  for(b = 0; b < sb.size; b += BPB){
801013f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801013fe:	e9 11 01 00 00       	jmp    80101514 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80101403:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101406:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
8010140c:	85 c0                	test   %eax,%eax
8010140e:	0f 48 c2             	cmovs  %edx,%eax
80101411:	c1 f8 0c             	sar    $0xc,%eax
80101414:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101417:	c1 ea 03             	shr    $0x3,%edx
8010141a:	01 d0                	add    %edx,%eax
8010141c:	83 c0 03             	add    $0x3,%eax
8010141f:	89 44 24 04          	mov    %eax,0x4(%esp)
80101423:	8b 45 08             	mov    0x8(%ebp),%eax
80101426:	89 04 24             	mov    %eax,(%esp)
80101429:	e8 78 ed ff ff       	call   801001a6 <bread>
8010142e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101431:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101438:	e9 a7 00 00 00       	jmp    801014e4 <balloc+0x10d>
      m = 1 << (bi % 8);
8010143d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101440:	89 c2                	mov    %eax,%edx
80101442:	c1 fa 1f             	sar    $0x1f,%edx
80101445:	c1 ea 1d             	shr    $0x1d,%edx
80101448:	01 d0                	add    %edx,%eax
8010144a:	83 e0 07             	and    $0x7,%eax
8010144d:	29 d0                	sub    %edx,%eax
8010144f:	ba 01 00 00 00       	mov    $0x1,%edx
80101454:	89 d3                	mov    %edx,%ebx
80101456:	89 c1                	mov    %eax,%ecx
80101458:	d3 e3                	shl    %cl,%ebx
8010145a:	89 d8                	mov    %ebx,%eax
8010145c:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
8010145f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101462:	8d 50 07             	lea    0x7(%eax),%edx
80101465:	85 c0                	test   %eax,%eax
80101467:	0f 48 c2             	cmovs  %edx,%eax
8010146a:	c1 f8 03             	sar    $0x3,%eax
8010146d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101470:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101475:	0f b6 c0             	movzbl %al,%eax
80101478:	23 45 e8             	and    -0x18(%ebp),%eax
8010147b:	85 c0                	test   %eax,%eax
8010147d:	75 61                	jne    801014e0 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
8010147f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101482:	8d 50 07             	lea    0x7(%eax),%edx
80101485:	85 c0                	test   %eax,%eax
80101487:	0f 48 c2             	cmovs  %edx,%eax
8010148a:	c1 f8 03             	sar    $0x3,%eax
8010148d:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101490:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101495:	89 d1                	mov    %edx,%ecx
80101497:	8b 55 e8             	mov    -0x18(%ebp),%edx
8010149a:	09 ca                	or     %ecx,%edx
8010149c:	89 d1                	mov    %edx,%ecx
8010149e:	8b 55 ec             	mov    -0x14(%ebp),%edx
801014a1:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
801014a5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014a8:	89 04 24             	mov    %eax,(%esp)
801014ab:	e8 62 1e 00 00       	call   80103312 <log_write>
        brelse(bp);
801014b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014b3:	89 04 24             	mov    %eax,(%esp)
801014b6:	e8 5c ed ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
801014bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014c1:	01 c2                	add    %eax,%edx
801014c3:	8b 45 08             	mov    0x8(%ebp),%eax
801014c6:	89 54 24 04          	mov    %edx,0x4(%esp)
801014ca:	89 04 24             	mov    %eax,(%esp)
801014cd:	e8 b4 fe ff ff       	call   80101386 <bzero>
        return b + bi;
801014d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014d5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014d8:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
801014da:	83 c4 34             	add    $0x34,%esp
801014dd:	5b                   	pop    %ebx
801014de:	5d                   	pop    %ebp
801014df:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014e0:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
801014e4:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
801014eb:	7f 15                	jg     80101502 <balloc+0x12b>
801014ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014f0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801014f3:	01 d0                	add    %edx,%eax
801014f5:	89 c2                	mov    %eax,%edx
801014f7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801014fa:	39 c2                	cmp    %eax,%edx
801014fc:	0f 82 3b ff ff ff    	jb     8010143d <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101502:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101505:	89 04 24             	mov    %eax,(%esp)
80101508:	e8 0a ed ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
8010150d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101514:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101517:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010151a:	39 c2                	cmp    %eax,%edx
8010151c:	0f 82 e1 fe ff ff    	jb     80101403 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101522:	c7 04 24 32 83 10 80 	movl   $0x80108332,(%esp)
80101529:	e8 0f f0 ff ff       	call   8010053d <panic>

8010152e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
8010152e:	55                   	push   %ebp
8010152f:	89 e5                	mov    %esp,%ebp
80101531:	53                   	push   %ebx
80101532:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101535:	8d 45 dc             	lea    -0x24(%ebp),%eax
80101538:	89 44 24 04          	mov    %eax,0x4(%esp)
8010153c:	8b 45 08             	mov    0x8(%ebp),%eax
8010153f:	89 04 24             	mov    %eax,(%esp)
80101542:	e8 f9 fd ff ff       	call   80101340 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80101547:	8b 45 0c             	mov    0xc(%ebp),%eax
8010154a:	89 c2                	mov    %eax,%edx
8010154c:	c1 ea 0c             	shr    $0xc,%edx
8010154f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101552:	c1 e8 03             	shr    $0x3,%eax
80101555:	01 d0                	add    %edx,%eax
80101557:	8d 50 03             	lea    0x3(%eax),%edx
8010155a:	8b 45 08             	mov    0x8(%ebp),%eax
8010155d:	89 54 24 04          	mov    %edx,0x4(%esp)
80101561:	89 04 24             	mov    %eax,(%esp)
80101564:	e8 3d ec ff ff       	call   801001a6 <bread>
80101569:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
8010156c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010156f:	25 ff 0f 00 00       	and    $0xfff,%eax
80101574:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101577:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010157a:	89 c2                	mov    %eax,%edx
8010157c:	c1 fa 1f             	sar    $0x1f,%edx
8010157f:	c1 ea 1d             	shr    $0x1d,%edx
80101582:	01 d0                	add    %edx,%eax
80101584:	83 e0 07             	and    $0x7,%eax
80101587:	29 d0                	sub    %edx,%eax
80101589:	ba 01 00 00 00       	mov    $0x1,%edx
8010158e:	89 d3                	mov    %edx,%ebx
80101590:	89 c1                	mov    %eax,%ecx
80101592:	d3 e3                	shl    %cl,%ebx
80101594:	89 d8                	mov    %ebx,%eax
80101596:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101599:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010159c:	8d 50 07             	lea    0x7(%eax),%edx
8010159f:	85 c0                	test   %eax,%eax
801015a1:	0f 48 c2             	cmovs  %edx,%eax
801015a4:	c1 f8 03             	sar    $0x3,%eax
801015a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015aa:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
801015af:	0f b6 c0             	movzbl %al,%eax
801015b2:	23 45 ec             	and    -0x14(%ebp),%eax
801015b5:	85 c0                	test   %eax,%eax
801015b7:	75 0c                	jne    801015c5 <bfree+0x97>
    panic("freeing free block");
801015b9:	c7 04 24 48 83 10 80 	movl   $0x80108348,(%esp)
801015c0:	e8 78 ef ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
801015c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801015c8:	8d 50 07             	lea    0x7(%eax),%edx
801015cb:	85 c0                	test   %eax,%eax
801015cd:	0f 48 c2             	cmovs  %edx,%eax
801015d0:	c1 f8 03             	sar    $0x3,%eax
801015d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015d6:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
801015db:	8b 4d ec             	mov    -0x14(%ebp),%ecx
801015de:	f7 d1                	not    %ecx
801015e0:	21 ca                	and    %ecx,%edx
801015e2:	89 d1                	mov    %edx,%ecx
801015e4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801015e7:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
801015eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015ee:	89 04 24             	mov    %eax,(%esp)
801015f1:	e8 1c 1d 00 00       	call   80103312 <log_write>
  brelse(bp);
801015f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015f9:	89 04 24             	mov    %eax,(%esp)
801015fc:	e8 16 ec ff ff       	call   80100217 <brelse>
}
80101601:	83 c4 34             	add    $0x34,%esp
80101604:	5b                   	pop    %ebx
80101605:	5d                   	pop    %ebp
80101606:	c3                   	ret    

80101607 <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
80101607:	55                   	push   %ebp
80101608:	89 e5                	mov    %esp,%ebp
8010160a:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
8010160d:	c7 44 24 04 5b 83 10 	movl   $0x8010835b,0x4(%esp)
80101614:	80 
80101615:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
8010161c:	e8 1d 36 00 00       	call   80104c3e <initlock>
}
80101621:	c9                   	leave  
80101622:	c3                   	ret    

80101623 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101623:	55                   	push   %ebp
80101624:	89 e5                	mov    %esp,%ebp
80101626:	83 ec 48             	sub    $0x48,%esp
80101629:	8b 45 0c             	mov    0xc(%ebp),%eax
8010162c:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101630:	8b 45 08             	mov    0x8(%ebp),%eax
80101633:	8d 55 dc             	lea    -0x24(%ebp),%edx
80101636:	89 54 24 04          	mov    %edx,0x4(%esp)
8010163a:	89 04 24             	mov    %eax,(%esp)
8010163d:	e8 fe fc ff ff       	call   80101340 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80101642:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101649:	e9 98 00 00 00       	jmp    801016e6 <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
8010164e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101651:	c1 e8 03             	shr    $0x3,%eax
80101654:	83 c0 02             	add    $0x2,%eax
80101657:	89 44 24 04          	mov    %eax,0x4(%esp)
8010165b:	8b 45 08             	mov    0x8(%ebp),%eax
8010165e:	89 04 24             	mov    %eax,(%esp)
80101661:	e8 40 eb ff ff       	call   801001a6 <bread>
80101666:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101669:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010166c:	8d 50 18             	lea    0x18(%eax),%edx
8010166f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101672:	83 e0 07             	and    $0x7,%eax
80101675:	c1 e0 06             	shl    $0x6,%eax
80101678:	01 d0                	add    %edx,%eax
8010167a:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
8010167d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101680:	0f b7 00             	movzwl (%eax),%eax
80101683:	66 85 c0             	test   %ax,%ax
80101686:	75 4f                	jne    801016d7 <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101688:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
8010168f:	00 
80101690:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101697:	00 
80101698:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010169b:	89 04 24             	mov    %eax,(%esp)
8010169e:	e8 0b 38 00 00       	call   80104eae <memset>
      dip->type = type;
801016a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016a6:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
801016aa:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801016ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016b0:	89 04 24             	mov    %eax,(%esp)
801016b3:	e8 5a 1c 00 00       	call   80103312 <log_write>
      brelse(bp);
801016b8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016bb:	89 04 24             	mov    %eax,(%esp)
801016be:	e8 54 eb ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
801016c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801016c6:	89 44 24 04          	mov    %eax,0x4(%esp)
801016ca:	8b 45 08             	mov    0x8(%ebp),%eax
801016cd:	89 04 24             	mov    %eax,(%esp)
801016d0:	e8 e3 00 00 00       	call   801017b8 <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
801016d5:	c9                   	leave  
801016d6:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
801016d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801016da:	89 04 24             	mov    %eax,(%esp)
801016dd:	e8 35 eb ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
801016e2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801016e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801016e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801016ec:	39 c2                	cmp    %eax,%edx
801016ee:	0f 82 5a ff ff ff    	jb     8010164e <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
801016f4:	c7 04 24 62 83 10 80 	movl   $0x80108362,(%esp)
801016fb:	e8 3d ee ff ff       	call   8010053d <panic>

80101700 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101700:	55                   	push   %ebp
80101701:	89 e5                	mov    %esp,%ebp
80101703:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
80101706:	8b 45 08             	mov    0x8(%ebp),%eax
80101709:	8b 40 04             	mov    0x4(%eax),%eax
8010170c:	c1 e8 03             	shr    $0x3,%eax
8010170f:	8d 50 02             	lea    0x2(%eax),%edx
80101712:	8b 45 08             	mov    0x8(%ebp),%eax
80101715:	8b 00                	mov    (%eax),%eax
80101717:	89 54 24 04          	mov    %edx,0x4(%esp)
8010171b:	89 04 24             	mov    %eax,(%esp)
8010171e:	e8 83 ea ff ff       	call   801001a6 <bread>
80101723:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101726:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101729:	8d 50 18             	lea    0x18(%eax),%edx
8010172c:	8b 45 08             	mov    0x8(%ebp),%eax
8010172f:	8b 40 04             	mov    0x4(%eax),%eax
80101732:	83 e0 07             	and    $0x7,%eax
80101735:	c1 e0 06             	shl    $0x6,%eax
80101738:	01 d0                	add    %edx,%eax
8010173a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
8010173d:	8b 45 08             	mov    0x8(%ebp),%eax
80101740:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101744:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101747:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
8010174a:	8b 45 08             	mov    0x8(%ebp),%eax
8010174d:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101751:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101754:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101758:	8b 45 08             	mov    0x8(%ebp),%eax
8010175b:	0f b7 50 14          	movzwl 0x14(%eax),%edx
8010175f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101762:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101766:	8b 45 08             	mov    0x8(%ebp),%eax
80101769:	0f b7 50 16          	movzwl 0x16(%eax),%edx
8010176d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101770:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101774:	8b 45 08             	mov    0x8(%ebp),%eax
80101777:	8b 50 18             	mov    0x18(%eax),%edx
8010177a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010177d:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101780:	8b 45 08             	mov    0x8(%ebp),%eax
80101783:	8d 50 1c             	lea    0x1c(%eax),%edx
80101786:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101789:	83 c0 0c             	add    $0xc,%eax
8010178c:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101793:	00 
80101794:	89 54 24 04          	mov    %edx,0x4(%esp)
80101798:	89 04 24             	mov    %eax,(%esp)
8010179b:	e8 e1 37 00 00       	call   80104f81 <memmove>
  log_write(bp);
801017a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017a3:	89 04 24             	mov    %eax,(%esp)
801017a6:	e8 67 1b 00 00       	call   80103312 <log_write>
  brelse(bp);
801017ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017ae:	89 04 24             	mov    %eax,(%esp)
801017b1:	e8 61 ea ff ff       	call   80100217 <brelse>
}
801017b6:	c9                   	leave  
801017b7:	c3                   	ret    

801017b8 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801017b8:	55                   	push   %ebp
801017b9:	89 e5                	mov    %esp,%ebp
801017bb:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801017be:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
801017c5:	e8 95 34 00 00       	call   80104c5f <acquire>

  // Is the inode already cached?
  empty = 0;
801017ca:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
801017d1:	c7 45 f4 94 ed 10 80 	movl   $0x8010ed94,-0xc(%ebp)
801017d8:	eb 59                	jmp    80101833 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
801017da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017dd:	8b 40 08             	mov    0x8(%eax),%eax
801017e0:	85 c0                	test   %eax,%eax
801017e2:	7e 35                	jle    80101819 <iget+0x61>
801017e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017e7:	8b 00                	mov    (%eax),%eax
801017e9:	3b 45 08             	cmp    0x8(%ebp),%eax
801017ec:	75 2b                	jne    80101819 <iget+0x61>
801017ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f1:	8b 40 04             	mov    0x4(%eax),%eax
801017f4:	3b 45 0c             	cmp    0xc(%ebp),%eax
801017f7:	75 20                	jne    80101819 <iget+0x61>
      ip->ref++;
801017f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017fc:	8b 40 08             	mov    0x8(%eax),%eax
801017ff:	8d 50 01             	lea    0x1(%eax),%edx
80101802:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101805:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101808:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
8010180f:	e8 ad 34 00 00       	call   80104cc1 <release>
      return ip;
80101814:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101817:	eb 6f                	jmp    80101888 <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101819:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010181d:	75 10                	jne    8010182f <iget+0x77>
8010181f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101822:	8b 40 08             	mov    0x8(%eax),%eax
80101825:	85 c0                	test   %eax,%eax
80101827:	75 06                	jne    8010182f <iget+0x77>
      empty = ip;
80101829:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010182c:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
8010182f:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101833:	81 7d f4 34 fd 10 80 	cmpl   $0x8010fd34,-0xc(%ebp)
8010183a:	72 9e                	jb     801017da <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
8010183c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101840:	75 0c                	jne    8010184e <iget+0x96>
    panic("iget: no inodes");
80101842:	c7 04 24 74 83 10 80 	movl   $0x80108374,(%esp)
80101849:	e8 ef ec ff ff       	call   8010053d <panic>

  ip = empty;
8010184e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101851:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101857:	8b 55 08             	mov    0x8(%ebp),%edx
8010185a:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
8010185c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010185f:	8b 55 0c             	mov    0xc(%ebp),%edx
80101862:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101865:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101868:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
8010186f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101872:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101879:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101880:	e8 3c 34 00 00       	call   80104cc1 <release>

  return ip;
80101885:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101888:	c9                   	leave  
80101889:	c3                   	ret    

8010188a <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
8010188a:	55                   	push   %ebp
8010188b:	89 e5                	mov    %esp,%ebp
8010188d:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101890:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101897:	e8 c3 33 00 00       	call   80104c5f <acquire>
  ip->ref++;
8010189c:	8b 45 08             	mov    0x8(%ebp),%eax
8010189f:	8b 40 08             	mov    0x8(%eax),%eax
801018a2:	8d 50 01             	lea    0x1(%eax),%edx
801018a5:	8b 45 08             	mov    0x8(%ebp),%eax
801018a8:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801018ab:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
801018b2:	e8 0a 34 00 00       	call   80104cc1 <release>
  return ip;
801018b7:	8b 45 08             	mov    0x8(%ebp),%eax
}
801018ba:	c9                   	leave  
801018bb:	c3                   	ret    

801018bc <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
801018bc:	55                   	push   %ebp
801018bd:	89 e5                	mov    %esp,%ebp
801018bf:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
801018c2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801018c6:	74 0a                	je     801018d2 <ilock+0x16>
801018c8:	8b 45 08             	mov    0x8(%ebp),%eax
801018cb:	8b 40 08             	mov    0x8(%eax),%eax
801018ce:	85 c0                	test   %eax,%eax
801018d0:	7f 0c                	jg     801018de <ilock+0x22>
    panic("ilock");
801018d2:	c7 04 24 84 83 10 80 	movl   $0x80108384,(%esp)
801018d9:	e8 5f ec ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
801018de:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
801018e5:	e8 75 33 00 00       	call   80104c5f <acquire>
  while(ip->flags & I_BUSY)
801018ea:	eb 13                	jmp    801018ff <ilock+0x43>
    sleep(ip, &icache.lock);
801018ec:	c7 44 24 04 60 ed 10 	movl   $0x8010ed60,0x4(%esp)
801018f3:	80 
801018f4:	8b 45 08             	mov    0x8(%ebp),%eax
801018f7:	89 04 24             	mov    %eax,(%esp)
801018fa:	e8 82 30 00 00       	call   80104981 <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
801018ff:	8b 45 08             	mov    0x8(%ebp),%eax
80101902:	8b 40 0c             	mov    0xc(%eax),%eax
80101905:	83 e0 01             	and    $0x1,%eax
80101908:	84 c0                	test   %al,%al
8010190a:	75 e0                	jne    801018ec <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
8010190c:	8b 45 08             	mov    0x8(%ebp),%eax
8010190f:	8b 40 0c             	mov    0xc(%eax),%eax
80101912:	89 c2                	mov    %eax,%edx
80101914:	83 ca 01             	or     $0x1,%edx
80101917:	8b 45 08             	mov    0x8(%ebp),%eax
8010191a:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
8010191d:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101924:	e8 98 33 00 00       	call   80104cc1 <release>

  if(!(ip->flags & I_VALID)){
80101929:	8b 45 08             	mov    0x8(%ebp),%eax
8010192c:	8b 40 0c             	mov    0xc(%eax),%eax
8010192f:	83 e0 02             	and    $0x2,%eax
80101932:	85 c0                	test   %eax,%eax
80101934:	0f 85 ce 00 00 00    	jne    80101a08 <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
8010193a:	8b 45 08             	mov    0x8(%ebp),%eax
8010193d:	8b 40 04             	mov    0x4(%eax),%eax
80101940:	c1 e8 03             	shr    $0x3,%eax
80101943:	8d 50 02             	lea    0x2(%eax),%edx
80101946:	8b 45 08             	mov    0x8(%ebp),%eax
80101949:	8b 00                	mov    (%eax),%eax
8010194b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010194f:	89 04 24             	mov    %eax,(%esp)
80101952:	e8 4f e8 ff ff       	call   801001a6 <bread>
80101957:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
8010195a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010195d:	8d 50 18             	lea    0x18(%eax),%edx
80101960:	8b 45 08             	mov    0x8(%ebp),%eax
80101963:	8b 40 04             	mov    0x4(%eax),%eax
80101966:	83 e0 07             	and    $0x7,%eax
80101969:	c1 e0 06             	shl    $0x6,%eax
8010196c:	01 d0                	add    %edx,%eax
8010196e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101971:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101974:	0f b7 10             	movzwl (%eax),%edx
80101977:	8b 45 08             	mov    0x8(%ebp),%eax
8010197a:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
8010197e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101981:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101985:	8b 45 08             	mov    0x8(%ebp),%eax
80101988:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
8010198c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010198f:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101993:	8b 45 08             	mov    0x8(%ebp),%eax
80101996:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
8010199a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010199d:	0f b7 50 06          	movzwl 0x6(%eax),%edx
801019a1:	8b 45 08             	mov    0x8(%ebp),%eax
801019a4:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
801019a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019ab:	8b 50 08             	mov    0x8(%eax),%edx
801019ae:	8b 45 08             	mov    0x8(%ebp),%eax
801019b1:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
801019b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801019b7:	8d 50 0c             	lea    0xc(%eax),%edx
801019ba:	8b 45 08             	mov    0x8(%ebp),%eax
801019bd:	83 c0 1c             	add    $0x1c,%eax
801019c0:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
801019c7:	00 
801019c8:	89 54 24 04          	mov    %edx,0x4(%esp)
801019cc:	89 04 24             	mov    %eax,(%esp)
801019cf:	e8 ad 35 00 00       	call   80104f81 <memmove>
    brelse(bp);
801019d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019d7:	89 04 24             	mov    %eax,(%esp)
801019da:	e8 38 e8 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
801019df:	8b 45 08             	mov    0x8(%ebp),%eax
801019e2:	8b 40 0c             	mov    0xc(%eax),%eax
801019e5:	89 c2                	mov    %eax,%edx
801019e7:	83 ca 02             	or     $0x2,%edx
801019ea:	8b 45 08             	mov    0x8(%ebp),%eax
801019ed:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
801019f0:	8b 45 08             	mov    0x8(%ebp),%eax
801019f3:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801019f7:	66 85 c0             	test   %ax,%ax
801019fa:	75 0c                	jne    80101a08 <ilock+0x14c>
      panic("ilock: no type");
801019fc:	c7 04 24 8a 83 10 80 	movl   $0x8010838a,(%esp)
80101a03:	e8 35 eb ff ff       	call   8010053d <panic>
  }
}
80101a08:	c9                   	leave  
80101a09:	c3                   	ret    

80101a0a <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101a0a:	55                   	push   %ebp
80101a0b:	89 e5                	mov    %esp,%ebp
80101a0d:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80101a10:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a14:	74 17                	je     80101a2d <iunlock+0x23>
80101a16:	8b 45 08             	mov    0x8(%ebp),%eax
80101a19:	8b 40 0c             	mov    0xc(%eax),%eax
80101a1c:	83 e0 01             	and    $0x1,%eax
80101a1f:	85 c0                	test   %eax,%eax
80101a21:	74 0a                	je     80101a2d <iunlock+0x23>
80101a23:	8b 45 08             	mov    0x8(%ebp),%eax
80101a26:	8b 40 08             	mov    0x8(%eax),%eax
80101a29:	85 c0                	test   %eax,%eax
80101a2b:	7f 0c                	jg     80101a39 <iunlock+0x2f>
    panic("iunlock");
80101a2d:	c7 04 24 99 83 10 80 	movl   $0x80108399,(%esp)
80101a34:	e8 04 eb ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101a39:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101a40:	e8 1a 32 00 00       	call   80104c5f <acquire>
  ip->flags &= ~I_BUSY;
80101a45:	8b 45 08             	mov    0x8(%ebp),%eax
80101a48:	8b 40 0c             	mov    0xc(%eax),%eax
80101a4b:	89 c2                	mov    %eax,%edx
80101a4d:	83 e2 fe             	and    $0xfffffffe,%edx
80101a50:	8b 45 08             	mov    0x8(%ebp),%eax
80101a53:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
80101a56:	8b 45 08             	mov    0x8(%ebp),%eax
80101a59:	89 04 24             	mov    %eax,(%esp)
80101a5c:	e8 f9 2f 00 00       	call   80104a5a <wakeup>
  release(&icache.lock);
80101a61:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101a68:	e8 54 32 00 00       	call   80104cc1 <release>
}
80101a6d:	c9                   	leave  
80101a6e:	c3                   	ret    

80101a6f <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80101a6f:	55                   	push   %ebp
80101a70:	89 e5                	mov    %esp,%ebp
80101a72:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101a75:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101a7c:	e8 de 31 00 00       	call   80104c5f <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
80101a81:	8b 45 08             	mov    0x8(%ebp),%eax
80101a84:	8b 40 08             	mov    0x8(%eax),%eax
80101a87:	83 f8 01             	cmp    $0x1,%eax
80101a8a:	0f 85 93 00 00 00    	jne    80101b23 <iput+0xb4>
80101a90:	8b 45 08             	mov    0x8(%ebp),%eax
80101a93:	8b 40 0c             	mov    0xc(%eax),%eax
80101a96:	83 e0 02             	and    $0x2,%eax
80101a99:	85 c0                	test   %eax,%eax
80101a9b:	0f 84 82 00 00 00    	je     80101b23 <iput+0xb4>
80101aa1:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa4:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80101aa8:	66 85 c0             	test   %ax,%ax
80101aab:	75 76                	jne    80101b23 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
80101aad:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab0:	8b 40 0c             	mov    0xc(%eax),%eax
80101ab3:	83 e0 01             	and    $0x1,%eax
80101ab6:	84 c0                	test   %al,%al
80101ab8:	74 0c                	je     80101ac6 <iput+0x57>
      panic("iput busy");
80101aba:	c7 04 24 a1 83 10 80 	movl   $0x801083a1,(%esp)
80101ac1:	e8 77 ea ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
80101ac6:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac9:	8b 40 0c             	mov    0xc(%eax),%eax
80101acc:	89 c2                	mov    %eax,%edx
80101ace:	83 ca 01             	or     $0x1,%edx
80101ad1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad4:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
80101ad7:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101ade:	e8 de 31 00 00       	call   80104cc1 <release>
    itrunc(ip);
80101ae3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ae6:	89 04 24             	mov    %eax,(%esp)
80101ae9:	e8 72 01 00 00       	call   80101c60 <itrunc>
    ip->type = 0;
80101aee:	8b 45 08             	mov    0x8(%ebp),%eax
80101af1:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
80101af7:	8b 45 08             	mov    0x8(%ebp),%eax
80101afa:	89 04 24             	mov    %eax,(%esp)
80101afd:	e8 fe fb ff ff       	call   80101700 <iupdate>
    acquire(&icache.lock);
80101b02:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101b09:	e8 51 31 00 00       	call   80104c5f <acquire>
    ip->flags = 0;
80101b0e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b11:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
80101b18:	8b 45 08             	mov    0x8(%ebp),%eax
80101b1b:	89 04 24             	mov    %eax,(%esp)
80101b1e:	e8 37 2f 00 00       	call   80104a5a <wakeup>
  }
  ip->ref--;
80101b23:	8b 45 08             	mov    0x8(%ebp),%eax
80101b26:	8b 40 08             	mov    0x8(%eax),%eax
80101b29:	8d 50 ff             	lea    -0x1(%eax),%edx
80101b2c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b2f:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101b32:	c7 04 24 60 ed 10 80 	movl   $0x8010ed60,(%esp)
80101b39:	e8 83 31 00 00       	call   80104cc1 <release>
}
80101b3e:	c9                   	leave  
80101b3f:	c3                   	ret    

80101b40 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101b40:	55                   	push   %ebp
80101b41:	89 e5                	mov    %esp,%ebp
80101b43:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
80101b46:	8b 45 08             	mov    0x8(%ebp),%eax
80101b49:	89 04 24             	mov    %eax,(%esp)
80101b4c:	e8 b9 fe ff ff       	call   80101a0a <iunlock>
  iput(ip);
80101b51:	8b 45 08             	mov    0x8(%ebp),%eax
80101b54:	89 04 24             	mov    %eax,(%esp)
80101b57:	e8 13 ff ff ff       	call   80101a6f <iput>
}
80101b5c:	c9                   	leave  
80101b5d:	c3                   	ret    

80101b5e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101b5e:	55                   	push   %ebp
80101b5f:	89 e5                	mov    %esp,%ebp
80101b61:	53                   	push   %ebx
80101b62:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101b65:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101b69:	77 3e                	ja     80101ba9 <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
80101b6b:	8b 45 08             	mov    0x8(%ebp),%eax
80101b6e:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b71:	83 c2 04             	add    $0x4,%edx
80101b74:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101b78:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b7b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101b7f:	75 20                	jne    80101ba1 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101b81:	8b 45 08             	mov    0x8(%ebp),%eax
80101b84:	8b 00                	mov    (%eax),%eax
80101b86:	89 04 24             	mov    %eax,(%esp)
80101b89:	e8 49 f8 ff ff       	call   801013d7 <balloc>
80101b8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101b91:	8b 45 08             	mov    0x8(%ebp),%eax
80101b94:	8b 55 0c             	mov    0xc(%ebp),%edx
80101b97:	8d 4a 04             	lea    0x4(%edx),%ecx
80101b9a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b9d:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101ba1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ba4:	e9 b1 00 00 00       	jmp    80101c5a <bmap+0xfc>
  }
  bn -= NDIRECT;
80101ba9:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101bad:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101bb1:	0f 87 97 00 00 00    	ja     80101c4e <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101bb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101bba:	8b 40 4c             	mov    0x4c(%eax),%eax
80101bbd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bc0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101bc4:	75 19                	jne    80101bdf <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101bc6:	8b 45 08             	mov    0x8(%ebp),%eax
80101bc9:	8b 00                	mov    (%eax),%eax
80101bcb:	89 04 24             	mov    %eax,(%esp)
80101bce:	e8 04 f8 ff ff       	call   801013d7 <balloc>
80101bd3:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101bd6:	8b 45 08             	mov    0x8(%ebp),%eax
80101bd9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bdc:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80101bdf:	8b 45 08             	mov    0x8(%ebp),%eax
80101be2:	8b 00                	mov    (%eax),%eax
80101be4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101be7:	89 54 24 04          	mov    %edx,0x4(%esp)
80101beb:	89 04 24             	mov    %eax,(%esp)
80101bee:	e8 b3 e5 ff ff       	call   801001a6 <bread>
80101bf3:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101bf6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bf9:	83 c0 18             	add    $0x18,%eax
80101bfc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101bff:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c02:	c1 e0 02             	shl    $0x2,%eax
80101c05:	03 45 ec             	add    -0x14(%ebp),%eax
80101c08:	8b 00                	mov    (%eax),%eax
80101c0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c0d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c11:	75 2b                	jne    80101c3e <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80101c13:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c16:	c1 e0 02             	shl    $0x2,%eax
80101c19:	89 c3                	mov    %eax,%ebx
80101c1b:	03 5d ec             	add    -0x14(%ebp),%ebx
80101c1e:	8b 45 08             	mov    0x8(%ebp),%eax
80101c21:	8b 00                	mov    (%eax),%eax
80101c23:	89 04 24             	mov    %eax,(%esp)
80101c26:	e8 ac f7 ff ff       	call   801013d7 <balloc>
80101c2b:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c31:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101c33:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c36:	89 04 24             	mov    %eax,(%esp)
80101c39:	e8 d4 16 00 00       	call   80103312 <log_write>
    }
    brelse(bp);
80101c3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c41:	89 04 24             	mov    %eax,(%esp)
80101c44:	e8 ce e5 ff ff       	call   80100217 <brelse>
    return addr;
80101c49:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c4c:	eb 0c                	jmp    80101c5a <bmap+0xfc>
  }

  panic("bmap: out of range");
80101c4e:	c7 04 24 ab 83 10 80 	movl   $0x801083ab,(%esp)
80101c55:	e8 e3 e8 ff ff       	call   8010053d <panic>
}
80101c5a:	83 c4 24             	add    $0x24,%esp
80101c5d:	5b                   	pop    %ebx
80101c5e:	5d                   	pop    %ebp
80101c5f:	c3                   	ret    

80101c60 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101c60:	55                   	push   %ebp
80101c61:	89 e5                	mov    %esp,%ebp
80101c63:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101c66:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101c6d:	eb 44                	jmp    80101cb3 <itrunc+0x53>
    if(ip->addrs[i]){
80101c6f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c72:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c75:	83 c2 04             	add    $0x4,%edx
80101c78:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c7c:	85 c0                	test   %eax,%eax
80101c7e:	74 2f                	je     80101caf <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
80101c80:	8b 45 08             	mov    0x8(%ebp),%eax
80101c83:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c86:	83 c2 04             	add    $0x4,%edx
80101c89:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
80101c8d:	8b 45 08             	mov    0x8(%ebp),%eax
80101c90:	8b 00                	mov    (%eax),%eax
80101c92:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c96:	89 04 24             	mov    %eax,(%esp)
80101c99:	e8 90 f8 ff ff       	call   8010152e <bfree>
      ip->addrs[i] = 0;
80101c9e:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca1:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ca4:	83 c2 04             	add    $0x4,%edx
80101ca7:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101cae:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101caf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101cb3:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101cb7:	7e b6                	jle    80101c6f <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
80101cb9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cbc:	8b 40 4c             	mov    0x4c(%eax),%eax
80101cbf:	85 c0                	test   %eax,%eax
80101cc1:	0f 84 8f 00 00 00    	je     80101d56 <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101cc7:	8b 45 08             	mov    0x8(%ebp),%eax
80101cca:	8b 50 4c             	mov    0x4c(%eax),%edx
80101ccd:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd0:	8b 00                	mov    (%eax),%eax
80101cd2:	89 54 24 04          	mov    %edx,0x4(%esp)
80101cd6:	89 04 24             	mov    %eax,(%esp)
80101cd9:	e8 c8 e4 ff ff       	call   801001a6 <bread>
80101cde:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101ce1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ce4:	83 c0 18             	add    $0x18,%eax
80101ce7:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101cea:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101cf1:	eb 2f                	jmp    80101d22 <itrunc+0xc2>
      if(a[j])
80101cf3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cf6:	c1 e0 02             	shl    $0x2,%eax
80101cf9:	03 45 e8             	add    -0x18(%ebp),%eax
80101cfc:	8b 00                	mov    (%eax),%eax
80101cfe:	85 c0                	test   %eax,%eax
80101d00:	74 1c                	je     80101d1e <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80101d02:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d05:	c1 e0 02             	shl    $0x2,%eax
80101d08:	03 45 e8             	add    -0x18(%ebp),%eax
80101d0b:	8b 10                	mov    (%eax),%edx
80101d0d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d10:	8b 00                	mov    (%eax),%eax
80101d12:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d16:	89 04 24             	mov    %eax,(%esp)
80101d19:	e8 10 f8 ff ff       	call   8010152e <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101d1e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101d22:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d25:	83 f8 7f             	cmp    $0x7f,%eax
80101d28:	76 c9                	jbe    80101cf3 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101d2a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d2d:	89 04 24             	mov    %eax,(%esp)
80101d30:	e8 e2 e4 ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101d35:	8b 45 08             	mov    0x8(%ebp),%eax
80101d38:	8b 50 4c             	mov    0x4c(%eax),%edx
80101d3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101d3e:	8b 00                	mov    (%eax),%eax
80101d40:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d44:	89 04 24             	mov    %eax,(%esp)
80101d47:	e8 e2 f7 ff ff       	call   8010152e <bfree>
    ip->addrs[NDIRECT] = 0;
80101d4c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d4f:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
80101d56:	8b 45 08             	mov    0x8(%ebp),%eax
80101d59:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80101d60:	8b 45 08             	mov    0x8(%ebp),%eax
80101d63:	89 04 24             	mov    %eax,(%esp)
80101d66:	e8 95 f9 ff ff       	call   80101700 <iupdate>
}
80101d6b:	c9                   	leave  
80101d6c:	c3                   	ret    

80101d6d <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80101d6d:	55                   	push   %ebp
80101d6e:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101d70:	8b 45 08             	mov    0x8(%ebp),%eax
80101d73:	8b 00                	mov    (%eax),%eax
80101d75:	89 c2                	mov    %eax,%edx
80101d77:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d7a:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101d7d:	8b 45 08             	mov    0x8(%ebp),%eax
80101d80:	8b 50 04             	mov    0x4(%eax),%edx
80101d83:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d86:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101d89:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8c:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d90:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d93:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101d96:	8b 45 08             	mov    0x8(%ebp),%eax
80101d99:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d9d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101da0:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101da4:	8b 45 08             	mov    0x8(%ebp),%eax
80101da7:	8b 50 18             	mov    0x18(%eax),%edx
80101daa:	8b 45 0c             	mov    0xc(%ebp),%eax
80101dad:	89 50 10             	mov    %edx,0x10(%eax)
}
80101db0:	5d                   	pop    %ebp
80101db1:	c3                   	ret    

80101db2 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101db2:	55                   	push   %ebp
80101db3:	89 e5                	mov    %esp,%ebp
80101db5:	53                   	push   %ebx
80101db6:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101db9:	8b 45 08             	mov    0x8(%ebp),%eax
80101dbc:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101dc0:	66 83 f8 03          	cmp    $0x3,%ax
80101dc4:	75 60                	jne    80101e26 <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101dc6:	8b 45 08             	mov    0x8(%ebp),%eax
80101dc9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dcd:	66 85 c0             	test   %ax,%ax
80101dd0:	78 20                	js     80101df2 <readi+0x40>
80101dd2:	8b 45 08             	mov    0x8(%ebp),%eax
80101dd5:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101dd9:	66 83 f8 09          	cmp    $0x9,%ax
80101ddd:	7f 13                	jg     80101df2 <readi+0x40>
80101ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80101de2:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101de6:	98                   	cwtl   
80101de7:	8b 04 c5 00 ed 10 80 	mov    -0x7fef1300(,%eax,8),%eax
80101dee:	85 c0                	test   %eax,%eax
80101df0:	75 0a                	jne    80101dfc <readi+0x4a>
      return -1;
80101df2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101df7:	e9 1b 01 00 00       	jmp    80101f17 <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80101dfc:	8b 45 08             	mov    0x8(%ebp),%eax
80101dff:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101e03:	98                   	cwtl   
80101e04:	8b 14 c5 00 ed 10 80 	mov    -0x7fef1300(,%eax,8),%edx
80101e0b:	8b 45 14             	mov    0x14(%ebp),%eax
80101e0e:	89 44 24 08          	mov    %eax,0x8(%esp)
80101e12:	8b 45 0c             	mov    0xc(%ebp),%eax
80101e15:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e19:	8b 45 08             	mov    0x8(%ebp),%eax
80101e1c:	89 04 24             	mov    %eax,(%esp)
80101e1f:	ff d2                	call   *%edx
80101e21:	e9 f1 00 00 00       	jmp    80101f17 <readi+0x165>
  }

  if(off > ip->size || off + n < off)
80101e26:	8b 45 08             	mov    0x8(%ebp),%eax
80101e29:	8b 40 18             	mov    0x18(%eax),%eax
80101e2c:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e2f:	72 0d                	jb     80101e3e <readi+0x8c>
80101e31:	8b 45 14             	mov    0x14(%ebp),%eax
80101e34:	8b 55 10             	mov    0x10(%ebp),%edx
80101e37:	01 d0                	add    %edx,%eax
80101e39:	3b 45 10             	cmp    0x10(%ebp),%eax
80101e3c:	73 0a                	jae    80101e48 <readi+0x96>
    return -1;
80101e3e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101e43:	e9 cf 00 00 00       	jmp    80101f17 <readi+0x165>
  if(off + n > ip->size)
80101e48:	8b 45 14             	mov    0x14(%ebp),%eax
80101e4b:	8b 55 10             	mov    0x10(%ebp),%edx
80101e4e:	01 c2                	add    %eax,%edx
80101e50:	8b 45 08             	mov    0x8(%ebp),%eax
80101e53:	8b 40 18             	mov    0x18(%eax),%eax
80101e56:	39 c2                	cmp    %eax,%edx
80101e58:	76 0c                	jbe    80101e66 <readi+0xb4>
    n = ip->size - off;
80101e5a:	8b 45 08             	mov    0x8(%ebp),%eax
80101e5d:	8b 40 18             	mov    0x18(%eax),%eax
80101e60:	2b 45 10             	sub    0x10(%ebp),%eax
80101e63:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101e66:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101e6d:	e9 96 00 00 00       	jmp    80101f08 <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101e72:	8b 45 10             	mov    0x10(%ebp),%eax
80101e75:	c1 e8 09             	shr    $0x9,%eax
80101e78:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e7c:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7f:	89 04 24             	mov    %eax,(%esp)
80101e82:	e8 d7 fc ff ff       	call   80101b5e <bmap>
80101e87:	8b 55 08             	mov    0x8(%ebp),%edx
80101e8a:	8b 12                	mov    (%edx),%edx
80101e8c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101e90:	89 14 24             	mov    %edx,(%esp)
80101e93:	e8 0e e3 ff ff       	call   801001a6 <bread>
80101e98:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101e9b:	8b 45 10             	mov    0x10(%ebp),%eax
80101e9e:	89 c2                	mov    %eax,%edx
80101ea0:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80101ea6:	b8 00 02 00 00       	mov    $0x200,%eax
80101eab:	89 c1                	mov    %eax,%ecx
80101ead:	29 d1                	sub    %edx,%ecx
80101eaf:	89 ca                	mov    %ecx,%edx
80101eb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101eb4:	8b 4d 14             	mov    0x14(%ebp),%ecx
80101eb7:	89 cb                	mov    %ecx,%ebx
80101eb9:	29 c3                	sub    %eax,%ebx
80101ebb:	89 d8                	mov    %ebx,%eax
80101ebd:	39 c2                	cmp    %eax,%edx
80101ebf:	0f 46 c2             	cmovbe %edx,%eax
80101ec2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80101ec5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ec8:	8d 50 18             	lea    0x18(%eax),%edx
80101ecb:	8b 45 10             	mov    0x10(%ebp),%eax
80101ece:	25 ff 01 00 00       	and    $0x1ff,%eax
80101ed3:	01 c2                	add    %eax,%edx
80101ed5:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ed8:	89 44 24 08          	mov    %eax,0x8(%esp)
80101edc:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ee0:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ee3:	89 04 24             	mov    %eax,(%esp)
80101ee6:	e8 96 30 00 00       	call   80104f81 <memmove>
    brelse(bp);
80101eeb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101eee:	89 04 24             	mov    %eax,(%esp)
80101ef1:	e8 21 e3 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101ef6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ef9:	01 45 f4             	add    %eax,-0xc(%ebp)
80101efc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101eff:	01 45 10             	add    %eax,0x10(%ebp)
80101f02:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101f05:	01 45 0c             	add    %eax,0xc(%ebp)
80101f08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f0b:	3b 45 14             	cmp    0x14(%ebp),%eax
80101f0e:	0f 82 5e ff ff ff    	jb     80101e72 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80101f14:	8b 45 14             	mov    0x14(%ebp),%eax
}
80101f17:	83 c4 24             	add    $0x24,%esp
80101f1a:	5b                   	pop    %ebx
80101f1b:	5d                   	pop    %ebp
80101f1c:	c3                   	ret    

80101f1d <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80101f1d:	55                   	push   %ebp
80101f1e:	89 e5                	mov    %esp,%ebp
80101f20:	53                   	push   %ebx
80101f21:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f24:	8b 45 08             	mov    0x8(%ebp),%eax
80101f27:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80101f2b:	66 83 f8 03          	cmp    $0x3,%ax
80101f2f:	75 60                	jne    80101f91 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80101f31:	8b 45 08             	mov    0x8(%ebp),%eax
80101f34:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f38:	66 85 c0             	test   %ax,%ax
80101f3b:	78 20                	js     80101f5d <writei+0x40>
80101f3d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f40:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f44:	66 83 f8 09          	cmp    $0x9,%ax
80101f48:	7f 13                	jg     80101f5d <writei+0x40>
80101f4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4d:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f51:	98                   	cwtl   
80101f52:	8b 04 c5 04 ed 10 80 	mov    -0x7fef12fc(,%eax,8),%eax
80101f59:	85 c0                	test   %eax,%eax
80101f5b:	75 0a                	jne    80101f67 <writei+0x4a>
      return -1;
80101f5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f62:	e9 46 01 00 00       	jmp    801020ad <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
80101f67:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6a:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80101f6e:	98                   	cwtl   
80101f6f:	8b 14 c5 04 ed 10 80 	mov    -0x7fef12fc(,%eax,8),%edx
80101f76:	8b 45 14             	mov    0x14(%ebp),%eax
80101f79:	89 44 24 08          	mov    %eax,0x8(%esp)
80101f7d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101f80:	89 44 24 04          	mov    %eax,0x4(%esp)
80101f84:	8b 45 08             	mov    0x8(%ebp),%eax
80101f87:	89 04 24             	mov    %eax,(%esp)
80101f8a:	ff d2                	call   *%edx
80101f8c:	e9 1c 01 00 00       	jmp    801020ad <writei+0x190>
  }

  if(off > ip->size || off + n < off)
80101f91:	8b 45 08             	mov    0x8(%ebp),%eax
80101f94:	8b 40 18             	mov    0x18(%eax),%eax
80101f97:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f9a:	72 0d                	jb     80101fa9 <writei+0x8c>
80101f9c:	8b 45 14             	mov    0x14(%ebp),%eax
80101f9f:	8b 55 10             	mov    0x10(%ebp),%edx
80101fa2:	01 d0                	add    %edx,%eax
80101fa4:	3b 45 10             	cmp    0x10(%ebp),%eax
80101fa7:	73 0a                	jae    80101fb3 <writei+0x96>
    return -1;
80101fa9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fae:	e9 fa 00 00 00       	jmp    801020ad <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
80101fb3:	8b 45 14             	mov    0x14(%ebp),%eax
80101fb6:	8b 55 10             	mov    0x10(%ebp),%edx
80101fb9:	01 d0                	add    %edx,%eax
80101fbb:	3d 00 18 01 00       	cmp    $0x11800,%eax
80101fc0:	76 0a                	jbe    80101fcc <writei+0xaf>
    return -1;
80101fc2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101fc7:	e9 e1 00 00 00       	jmp    801020ad <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80101fcc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fd3:	e9 a1 00 00 00       	jmp    80102079 <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fd8:	8b 45 10             	mov    0x10(%ebp),%eax
80101fdb:	c1 e8 09             	shr    $0x9,%eax
80101fde:	89 44 24 04          	mov    %eax,0x4(%esp)
80101fe2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe5:	89 04 24             	mov    %eax,(%esp)
80101fe8:	e8 71 fb ff ff       	call   80101b5e <bmap>
80101fed:	8b 55 08             	mov    0x8(%ebp),%edx
80101ff0:	8b 12                	mov    (%edx),%edx
80101ff2:	89 44 24 04          	mov    %eax,0x4(%esp)
80101ff6:	89 14 24             	mov    %edx,(%esp)
80101ff9:	e8 a8 e1 ff ff       	call   801001a6 <bread>
80101ffe:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102001:	8b 45 10             	mov    0x10(%ebp),%eax
80102004:	89 c2                	mov    %eax,%edx
80102006:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
8010200c:	b8 00 02 00 00       	mov    $0x200,%eax
80102011:	89 c1                	mov    %eax,%ecx
80102013:	29 d1                	sub    %edx,%ecx
80102015:	89 ca                	mov    %ecx,%edx
80102017:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010201a:	8b 4d 14             	mov    0x14(%ebp),%ecx
8010201d:	89 cb                	mov    %ecx,%ebx
8010201f:	29 c3                	sub    %eax,%ebx
80102021:	89 d8                	mov    %ebx,%eax
80102023:	39 c2                	cmp    %eax,%edx
80102025:	0f 46 c2             	cmovbe %edx,%eax
80102028:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010202b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010202e:	8d 50 18             	lea    0x18(%eax),%edx
80102031:	8b 45 10             	mov    0x10(%ebp),%eax
80102034:	25 ff 01 00 00       	and    $0x1ff,%eax
80102039:	01 c2                	add    %eax,%edx
8010203b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010203e:	89 44 24 08          	mov    %eax,0x8(%esp)
80102042:	8b 45 0c             	mov    0xc(%ebp),%eax
80102045:	89 44 24 04          	mov    %eax,0x4(%esp)
80102049:	89 14 24             	mov    %edx,(%esp)
8010204c:	e8 30 2f 00 00       	call   80104f81 <memmove>
    log_write(bp);
80102051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102054:	89 04 24             	mov    %eax,(%esp)
80102057:	e8 b6 12 00 00       	call   80103312 <log_write>
    brelse(bp);
8010205c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010205f:	89 04 24             	mov    %eax,(%esp)
80102062:	e8 b0 e1 ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102067:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010206a:	01 45 f4             	add    %eax,-0xc(%ebp)
8010206d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102070:	01 45 10             	add    %eax,0x10(%ebp)
80102073:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102076:	01 45 0c             	add    %eax,0xc(%ebp)
80102079:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010207c:	3b 45 14             	cmp    0x14(%ebp),%eax
8010207f:	0f 82 53 ff ff ff    	jb     80101fd8 <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
80102085:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80102089:	74 1f                	je     801020aa <writei+0x18d>
8010208b:	8b 45 08             	mov    0x8(%ebp),%eax
8010208e:	8b 40 18             	mov    0x18(%eax),%eax
80102091:	3b 45 10             	cmp    0x10(%ebp),%eax
80102094:	73 14                	jae    801020aa <writei+0x18d>
    ip->size = off;
80102096:	8b 45 08             	mov    0x8(%ebp),%eax
80102099:	8b 55 10             	mov    0x10(%ebp),%edx
8010209c:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
8010209f:	8b 45 08             	mov    0x8(%ebp),%eax
801020a2:	89 04 24             	mov    %eax,(%esp)
801020a5:	e8 56 f6 ff ff       	call   80101700 <iupdate>
  }
  return n;
801020aa:	8b 45 14             	mov    0x14(%ebp),%eax
}
801020ad:	83 c4 24             	add    $0x24,%esp
801020b0:	5b                   	pop    %ebx
801020b1:	5d                   	pop    %ebp
801020b2:	c3                   	ret    

801020b3 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801020b3:	55                   	push   %ebp
801020b4:	89 e5                	mov    %esp,%ebp
801020b6:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801020b9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801020c0:	00 
801020c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801020c4:	89 44 24 04          	mov    %eax,0x4(%esp)
801020c8:	8b 45 08             	mov    0x8(%ebp),%eax
801020cb:	89 04 24             	mov    %eax,(%esp)
801020ce:	e8 52 2f 00 00       	call   80105025 <strncmp>
}
801020d3:	c9                   	leave  
801020d4:	c3                   	ret    

801020d5 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801020d5:	55                   	push   %ebp
801020d6:	89 e5                	mov    %esp,%ebp
801020d8:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801020db:	8b 45 08             	mov    0x8(%ebp),%eax
801020de:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801020e2:	66 83 f8 01          	cmp    $0x1,%ax
801020e6:	74 0c                	je     801020f4 <dirlookup+0x1f>
    panic("dirlookup not DIR");
801020e8:	c7 04 24 be 83 10 80 	movl   $0x801083be,(%esp)
801020ef:	e8 49 e4 ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
801020f4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801020fb:	e9 87 00 00 00       	jmp    80102187 <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102100:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102107:	00 
80102108:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010210b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010210f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102112:	89 44 24 04          	mov    %eax,0x4(%esp)
80102116:	8b 45 08             	mov    0x8(%ebp),%eax
80102119:	89 04 24             	mov    %eax,(%esp)
8010211c:	e8 91 fc ff ff       	call   80101db2 <readi>
80102121:	83 f8 10             	cmp    $0x10,%eax
80102124:	74 0c                	je     80102132 <dirlookup+0x5d>
      panic("dirlink read");
80102126:	c7 04 24 d0 83 10 80 	movl   $0x801083d0,(%esp)
8010212d:	e8 0b e4 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102132:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102136:	66 85 c0             	test   %ax,%ax
80102139:	74 47                	je     80102182 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
8010213b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010213e:	83 c0 02             	add    $0x2,%eax
80102141:	89 44 24 04          	mov    %eax,0x4(%esp)
80102145:	8b 45 0c             	mov    0xc(%ebp),%eax
80102148:	89 04 24             	mov    %eax,(%esp)
8010214b:	e8 63 ff ff ff       	call   801020b3 <namecmp>
80102150:	85 c0                	test   %eax,%eax
80102152:	75 2f                	jne    80102183 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102154:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102158:	74 08                	je     80102162 <dirlookup+0x8d>
        *poff = off;
8010215a:	8b 45 10             	mov    0x10(%ebp),%eax
8010215d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102160:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102162:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102166:	0f b7 c0             	movzwl %ax,%eax
80102169:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
8010216c:	8b 45 08             	mov    0x8(%ebp),%eax
8010216f:	8b 00                	mov    (%eax),%eax
80102171:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102174:	89 54 24 04          	mov    %edx,0x4(%esp)
80102178:	89 04 24             	mov    %eax,(%esp)
8010217b:	e8 38 f6 ff ff       	call   801017b8 <iget>
80102180:	eb 19                	jmp    8010219b <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
80102182:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
80102183:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80102187:	8b 45 08             	mov    0x8(%ebp),%eax
8010218a:	8b 40 18             	mov    0x18(%eax),%eax
8010218d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80102190:	0f 87 6a ff ff ff    	ja     80102100 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
80102196:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010219b:	c9                   	leave  
8010219c:	c3                   	ret    

8010219d <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
8010219d:	55                   	push   %ebp
8010219e:	89 e5                	mov    %esp,%ebp
801021a0:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801021a3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801021aa:	00 
801021ab:	8b 45 0c             	mov    0xc(%ebp),%eax
801021ae:	89 44 24 04          	mov    %eax,0x4(%esp)
801021b2:	8b 45 08             	mov    0x8(%ebp),%eax
801021b5:	89 04 24             	mov    %eax,(%esp)
801021b8:	e8 18 ff ff ff       	call   801020d5 <dirlookup>
801021bd:	89 45 f0             	mov    %eax,-0x10(%ebp)
801021c0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801021c4:	74 15                	je     801021db <dirlink+0x3e>
    iput(ip);
801021c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801021c9:	89 04 24             	mov    %eax,(%esp)
801021cc:	e8 9e f8 ff ff       	call   80101a6f <iput>
    return -1;
801021d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801021d6:	e9 b8 00 00 00       	jmp    80102293 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801021db:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801021e2:	eb 44                	jmp    80102228 <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801021e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021e7:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801021ee:	00 
801021ef:	89 44 24 08          	mov    %eax,0x8(%esp)
801021f3:	8d 45 e0             	lea    -0x20(%ebp),%eax
801021f6:	89 44 24 04          	mov    %eax,0x4(%esp)
801021fa:	8b 45 08             	mov    0x8(%ebp),%eax
801021fd:	89 04 24             	mov    %eax,(%esp)
80102200:	e8 ad fb ff ff       	call   80101db2 <readi>
80102205:	83 f8 10             	cmp    $0x10,%eax
80102208:	74 0c                	je     80102216 <dirlink+0x79>
      panic("dirlink read");
8010220a:	c7 04 24 d0 83 10 80 	movl   $0x801083d0,(%esp)
80102211:	e8 27 e3 ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102216:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010221a:	66 85 c0             	test   %ax,%ax
8010221d:	74 18                	je     80102237 <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
8010221f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102222:	83 c0 10             	add    $0x10,%eax
80102225:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102228:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010222b:	8b 45 08             	mov    0x8(%ebp),%eax
8010222e:	8b 40 18             	mov    0x18(%eax),%eax
80102231:	39 c2                	cmp    %eax,%edx
80102233:	72 af                	jb     801021e4 <dirlink+0x47>
80102235:	eb 01                	jmp    80102238 <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102237:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102238:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010223f:	00 
80102240:	8b 45 0c             	mov    0xc(%ebp),%eax
80102243:	89 44 24 04          	mov    %eax,0x4(%esp)
80102247:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010224a:	83 c0 02             	add    $0x2,%eax
8010224d:	89 04 24             	mov    %eax,(%esp)
80102250:	e8 28 2e 00 00       	call   8010507d <strncpy>
  de.inum = inum;
80102255:	8b 45 10             	mov    0x10(%ebp),%eax
80102258:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010225c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010225f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102266:	00 
80102267:	89 44 24 08          	mov    %eax,0x8(%esp)
8010226b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010226e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102272:	8b 45 08             	mov    0x8(%ebp),%eax
80102275:	89 04 24             	mov    %eax,(%esp)
80102278:	e8 a0 fc ff ff       	call   80101f1d <writei>
8010227d:	83 f8 10             	cmp    $0x10,%eax
80102280:	74 0c                	je     8010228e <dirlink+0xf1>
    panic("dirlink");
80102282:	c7 04 24 dd 83 10 80 	movl   $0x801083dd,(%esp)
80102289:	e8 af e2 ff ff       	call   8010053d <panic>
  
  return 0;
8010228e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102293:	c9                   	leave  
80102294:	c3                   	ret    

80102295 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
80102295:	55                   	push   %ebp
80102296:	89 e5                	mov    %esp,%ebp
80102298:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
8010229b:	eb 04                	jmp    801022a1 <skipelem+0xc>
    path++;
8010229d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801022a1:	8b 45 08             	mov    0x8(%ebp),%eax
801022a4:	0f b6 00             	movzbl (%eax),%eax
801022a7:	3c 2f                	cmp    $0x2f,%al
801022a9:	74 f2                	je     8010229d <skipelem+0x8>
    path++;
  if(*path == 0)
801022ab:	8b 45 08             	mov    0x8(%ebp),%eax
801022ae:	0f b6 00             	movzbl (%eax),%eax
801022b1:	84 c0                	test   %al,%al
801022b3:	75 0a                	jne    801022bf <skipelem+0x2a>
    return 0;
801022b5:	b8 00 00 00 00       	mov    $0x0,%eax
801022ba:	e9 86 00 00 00       	jmp    80102345 <skipelem+0xb0>
  s = path;
801022bf:	8b 45 08             	mov    0x8(%ebp),%eax
801022c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801022c5:	eb 04                	jmp    801022cb <skipelem+0x36>
    path++;
801022c7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801022cb:	8b 45 08             	mov    0x8(%ebp),%eax
801022ce:	0f b6 00             	movzbl (%eax),%eax
801022d1:	3c 2f                	cmp    $0x2f,%al
801022d3:	74 0a                	je     801022df <skipelem+0x4a>
801022d5:	8b 45 08             	mov    0x8(%ebp),%eax
801022d8:	0f b6 00             	movzbl (%eax),%eax
801022db:	84 c0                	test   %al,%al
801022dd:	75 e8                	jne    801022c7 <skipelem+0x32>
    path++;
  len = path - s;
801022df:	8b 55 08             	mov    0x8(%ebp),%edx
801022e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022e5:	89 d1                	mov    %edx,%ecx
801022e7:	29 c1                	sub    %eax,%ecx
801022e9:	89 c8                	mov    %ecx,%eax
801022eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801022ee:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801022f2:	7e 1c                	jle    80102310 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
801022f4:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801022fb:	00 
801022fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022ff:	89 44 24 04          	mov    %eax,0x4(%esp)
80102303:	8b 45 0c             	mov    0xc(%ebp),%eax
80102306:	89 04 24             	mov    %eax,(%esp)
80102309:	e8 73 2c 00 00       	call   80104f81 <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010230e:	eb 28                	jmp    80102338 <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102310:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102313:	89 44 24 08          	mov    %eax,0x8(%esp)
80102317:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010231a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010231e:	8b 45 0c             	mov    0xc(%ebp),%eax
80102321:	89 04 24             	mov    %eax,(%esp)
80102324:	e8 58 2c 00 00       	call   80104f81 <memmove>
    name[len] = 0;
80102329:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010232c:	03 45 0c             	add    0xc(%ebp),%eax
8010232f:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102332:	eb 04                	jmp    80102338 <skipelem+0xa3>
    path++;
80102334:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102338:	8b 45 08             	mov    0x8(%ebp),%eax
8010233b:	0f b6 00             	movzbl (%eax),%eax
8010233e:	3c 2f                	cmp    $0x2f,%al
80102340:	74 f2                	je     80102334 <skipelem+0x9f>
    path++;
  return path;
80102342:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102345:	c9                   	leave  
80102346:	c3                   	ret    

80102347 <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102347:	55                   	push   %ebp
80102348:	89 e5                	mov    %esp,%ebp
8010234a:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
8010234d:	8b 45 08             	mov    0x8(%ebp),%eax
80102350:	0f b6 00             	movzbl (%eax),%eax
80102353:	3c 2f                	cmp    $0x2f,%al
80102355:	75 1c                	jne    80102373 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
80102357:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010235e:	00 
8010235f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102366:	e8 4d f4 ff ff       	call   801017b8 <iget>
8010236b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
8010236e:	e9 af 00 00 00       	jmp    80102422 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102373:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80102379:	8b 40 68             	mov    0x68(%eax),%eax
8010237c:	89 04 24             	mov    %eax,(%esp)
8010237f:	e8 06 f5 ff ff       	call   8010188a <idup>
80102384:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
80102387:	e9 96 00 00 00       	jmp    80102422 <namex+0xdb>
    ilock(ip);
8010238c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010238f:	89 04 24             	mov    %eax,(%esp)
80102392:	e8 25 f5 ff ff       	call   801018bc <ilock>
    if(ip->type != T_DIR){
80102397:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010239a:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010239e:	66 83 f8 01          	cmp    $0x1,%ax
801023a2:	74 15                	je     801023b9 <namex+0x72>
      iunlockput(ip);
801023a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023a7:	89 04 24             	mov    %eax,(%esp)
801023aa:	e8 91 f7 ff ff       	call   80101b40 <iunlockput>
      return 0;
801023af:	b8 00 00 00 00       	mov    $0x0,%eax
801023b4:	e9 a3 00 00 00       	jmp    8010245c <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801023b9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801023bd:	74 1d                	je     801023dc <namex+0x95>
801023bf:	8b 45 08             	mov    0x8(%ebp),%eax
801023c2:	0f b6 00             	movzbl (%eax),%eax
801023c5:	84 c0                	test   %al,%al
801023c7:	75 13                	jne    801023dc <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801023c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023cc:	89 04 24             	mov    %eax,(%esp)
801023cf:	e8 36 f6 ff ff       	call   80101a0a <iunlock>
      return ip;
801023d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023d7:	e9 80 00 00 00       	jmp    8010245c <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801023dc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801023e3:	00 
801023e4:	8b 45 10             	mov    0x10(%ebp),%eax
801023e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801023eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023ee:	89 04 24             	mov    %eax,(%esp)
801023f1:	e8 df fc ff ff       	call   801020d5 <dirlookup>
801023f6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801023f9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801023fd:	75 12                	jne    80102411 <namex+0xca>
      iunlockput(ip);
801023ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102402:	89 04 24             	mov    %eax,(%esp)
80102405:	e8 36 f7 ff ff       	call   80101b40 <iunlockput>
      return 0;
8010240a:	b8 00 00 00 00       	mov    $0x0,%eax
8010240f:	eb 4b                	jmp    8010245c <namex+0x115>
    }
    iunlockput(ip);
80102411:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102414:	89 04 24             	mov    %eax,(%esp)
80102417:	e8 24 f7 ff ff       	call   80101b40 <iunlockput>
    ip = next;
8010241c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010241f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102422:	8b 45 10             	mov    0x10(%ebp),%eax
80102425:	89 44 24 04          	mov    %eax,0x4(%esp)
80102429:	8b 45 08             	mov    0x8(%ebp),%eax
8010242c:	89 04 24             	mov    %eax,(%esp)
8010242f:	e8 61 fe ff ff       	call   80102295 <skipelem>
80102434:	89 45 08             	mov    %eax,0x8(%ebp)
80102437:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010243b:	0f 85 4b ff ff ff    	jne    8010238c <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102441:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102445:	74 12                	je     80102459 <namex+0x112>
    iput(ip);
80102447:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010244a:	89 04 24             	mov    %eax,(%esp)
8010244d:	e8 1d f6 ff ff       	call   80101a6f <iput>
    return 0;
80102452:	b8 00 00 00 00       	mov    $0x0,%eax
80102457:	eb 03                	jmp    8010245c <namex+0x115>
  }
  return ip;
80102459:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010245c:	c9                   	leave  
8010245d:	c3                   	ret    

8010245e <namei>:

struct inode*
namei(char *path)
{
8010245e:	55                   	push   %ebp
8010245f:	89 e5                	mov    %esp,%ebp
80102461:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102464:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102467:	89 44 24 08          	mov    %eax,0x8(%esp)
8010246b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102472:	00 
80102473:	8b 45 08             	mov    0x8(%ebp),%eax
80102476:	89 04 24             	mov    %eax,(%esp)
80102479:	e8 c9 fe ff ff       	call   80102347 <namex>
}
8010247e:	c9                   	leave  
8010247f:	c3                   	ret    

80102480 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102480:	55                   	push   %ebp
80102481:	89 e5                	mov    %esp,%ebp
80102483:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102486:	8b 45 0c             	mov    0xc(%ebp),%eax
80102489:	89 44 24 08          	mov    %eax,0x8(%esp)
8010248d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102494:	00 
80102495:	8b 45 08             	mov    0x8(%ebp),%eax
80102498:	89 04 24             	mov    %eax,(%esp)
8010249b:	e8 a7 fe ff ff       	call   80102347 <namex>
}
801024a0:	c9                   	leave  
801024a1:	c3                   	ret    
	...

801024a4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801024a4:	55                   	push   %ebp
801024a5:	89 e5                	mov    %esp,%ebp
801024a7:	53                   	push   %ebx
801024a8:	83 ec 14             	sub    $0x14,%esp
801024ab:	8b 45 08             	mov    0x8(%ebp),%eax
801024ae:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801024b2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801024b6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801024ba:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801024be:	ec                   	in     (%dx),%al
801024bf:	89 c3                	mov    %eax,%ebx
801024c1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801024c4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801024c8:	83 c4 14             	add    $0x14,%esp
801024cb:	5b                   	pop    %ebx
801024cc:	5d                   	pop    %ebp
801024cd:	c3                   	ret    

801024ce <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801024ce:	55                   	push   %ebp
801024cf:	89 e5                	mov    %esp,%ebp
801024d1:	57                   	push   %edi
801024d2:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801024d3:	8b 55 08             	mov    0x8(%ebp),%edx
801024d6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801024d9:	8b 45 10             	mov    0x10(%ebp),%eax
801024dc:	89 cb                	mov    %ecx,%ebx
801024de:	89 df                	mov    %ebx,%edi
801024e0:	89 c1                	mov    %eax,%ecx
801024e2:	fc                   	cld    
801024e3:	f3 6d                	rep insl (%dx),%es:(%edi)
801024e5:	89 c8                	mov    %ecx,%eax
801024e7:	89 fb                	mov    %edi,%ebx
801024e9:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801024ec:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801024ef:	5b                   	pop    %ebx
801024f0:	5f                   	pop    %edi
801024f1:	5d                   	pop    %ebp
801024f2:	c3                   	ret    

801024f3 <outb>:

static inline void
outb(ushort port, uchar data)
{
801024f3:	55                   	push   %ebp
801024f4:	89 e5                	mov    %esp,%ebp
801024f6:	83 ec 08             	sub    $0x8,%esp
801024f9:	8b 55 08             	mov    0x8(%ebp),%edx
801024fc:	8b 45 0c             	mov    0xc(%ebp),%eax
801024ff:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102503:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102506:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010250a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010250e:	ee                   	out    %al,(%dx)
}
8010250f:	c9                   	leave  
80102510:	c3                   	ret    

80102511 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102511:	55                   	push   %ebp
80102512:	89 e5                	mov    %esp,%ebp
80102514:	56                   	push   %esi
80102515:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102516:	8b 55 08             	mov    0x8(%ebp),%edx
80102519:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010251c:	8b 45 10             	mov    0x10(%ebp),%eax
8010251f:	89 cb                	mov    %ecx,%ebx
80102521:	89 de                	mov    %ebx,%esi
80102523:	89 c1                	mov    %eax,%ecx
80102525:	fc                   	cld    
80102526:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102528:	89 c8                	mov    %ecx,%eax
8010252a:	89 f3                	mov    %esi,%ebx
8010252c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
8010252f:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102532:	5b                   	pop    %ebx
80102533:	5e                   	pop    %esi
80102534:	5d                   	pop    %ebp
80102535:	c3                   	ret    

80102536 <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102536:	55                   	push   %ebp
80102537:	89 e5                	mov    %esp,%ebp
80102539:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
8010253c:	90                   	nop
8010253d:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102544:	e8 5b ff ff ff       	call   801024a4 <inb>
80102549:	0f b6 c0             	movzbl %al,%eax
8010254c:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010254f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102552:	25 c0 00 00 00       	and    $0xc0,%eax
80102557:	83 f8 40             	cmp    $0x40,%eax
8010255a:	75 e1                	jne    8010253d <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
8010255c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102560:	74 11                	je     80102573 <idewait+0x3d>
80102562:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102565:	83 e0 21             	and    $0x21,%eax
80102568:	85 c0                	test   %eax,%eax
8010256a:	74 07                	je     80102573 <idewait+0x3d>
    return -1;
8010256c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102571:	eb 05                	jmp    80102578 <idewait+0x42>
  return 0;
80102573:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102578:	c9                   	leave  
80102579:	c3                   	ret    

8010257a <ideinit>:

void
ideinit(void)
{
8010257a:	55                   	push   %ebp
8010257b:	89 e5                	mov    %esp,%ebp
8010257d:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102580:	c7 44 24 04 e5 83 10 	movl   $0x801083e5,0x4(%esp)
80102587:	80 
80102588:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010258f:	e8 aa 26 00 00       	call   80104c3e <initlock>
  picenable(IRQ_IDE);
80102594:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
8010259b:	e8 75 15 00 00       	call   80103b15 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
801025a0:	a1 00 04 11 80       	mov    0x80110400,%eax
801025a5:	83 e8 01             	sub    $0x1,%eax
801025a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801025ac:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
801025b3:	e8 12 04 00 00       	call   801029ca <ioapicenable>
  idewait(0);
801025b8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801025bf:	e8 72 ff ff ff       	call   80102536 <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
801025c4:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
801025cb:	00 
801025cc:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801025d3:	e8 1b ff ff ff       	call   801024f3 <outb>
  for(i=0; i<1000; i++){
801025d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025df:	eb 20                	jmp    80102601 <ideinit+0x87>
    if(inb(0x1f7) != 0){
801025e1:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
801025e8:	e8 b7 fe ff ff       	call   801024a4 <inb>
801025ed:	84 c0                	test   %al,%al
801025ef:	74 0c                	je     801025fd <ideinit+0x83>
      havedisk1 = 1;
801025f1:	c7 05 38 b6 10 80 01 	movl   $0x1,0x8010b638
801025f8:	00 00 00 
      break;
801025fb:	eb 0d                	jmp    8010260a <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801025fd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102601:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102608:	7e d7                	jle    801025e1 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
8010260a:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102611:	00 
80102612:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102619:	e8 d5 fe ff ff       	call   801024f3 <outb>
}
8010261e:	c9                   	leave  
8010261f:	c3                   	ret    

80102620 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102620:	55                   	push   %ebp
80102621:	89 e5                	mov    %esp,%ebp
80102623:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80102626:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010262a:	75 0c                	jne    80102638 <idestart+0x18>
    panic("idestart");
8010262c:	c7 04 24 e9 83 10 80 	movl   $0x801083e9,(%esp)
80102633:	e8 05 df ff ff       	call   8010053d <panic>

  idewait(0);
80102638:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010263f:	e8 f2 fe ff ff       	call   80102536 <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102644:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010264b:	00 
8010264c:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102653:	e8 9b fe ff ff       	call   801024f3 <outb>
  outb(0x1f2, 1);  // number of sectors
80102658:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010265f:	00 
80102660:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102667:	e8 87 fe ff ff       	call   801024f3 <outb>
  outb(0x1f3, b->sector & 0xff);
8010266c:	8b 45 08             	mov    0x8(%ebp),%eax
8010266f:	8b 40 08             	mov    0x8(%eax),%eax
80102672:	0f b6 c0             	movzbl %al,%eax
80102675:	89 44 24 04          	mov    %eax,0x4(%esp)
80102679:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102680:	e8 6e fe ff ff       	call   801024f3 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102685:	8b 45 08             	mov    0x8(%ebp),%eax
80102688:	8b 40 08             	mov    0x8(%eax),%eax
8010268b:	c1 e8 08             	shr    $0x8,%eax
8010268e:	0f b6 c0             	movzbl %al,%eax
80102691:	89 44 24 04          	mov    %eax,0x4(%esp)
80102695:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
8010269c:	e8 52 fe ff ff       	call   801024f3 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
801026a1:	8b 45 08             	mov    0x8(%ebp),%eax
801026a4:	8b 40 08             	mov    0x8(%eax),%eax
801026a7:	c1 e8 10             	shr    $0x10,%eax
801026aa:	0f b6 c0             	movzbl %al,%eax
801026ad:	89 44 24 04          	mov    %eax,0x4(%esp)
801026b1:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
801026b8:	e8 36 fe ff ff       	call   801024f3 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
801026bd:	8b 45 08             	mov    0x8(%ebp),%eax
801026c0:	8b 40 04             	mov    0x4(%eax),%eax
801026c3:	83 e0 01             	and    $0x1,%eax
801026c6:	89 c2                	mov    %eax,%edx
801026c8:	c1 e2 04             	shl    $0x4,%edx
801026cb:	8b 45 08             	mov    0x8(%ebp),%eax
801026ce:	8b 40 08             	mov    0x8(%eax),%eax
801026d1:	c1 e8 18             	shr    $0x18,%eax
801026d4:	83 e0 0f             	and    $0xf,%eax
801026d7:	09 d0                	or     %edx,%eax
801026d9:	83 c8 e0             	or     $0xffffffe0,%eax
801026dc:	0f b6 c0             	movzbl %al,%eax
801026df:	89 44 24 04          	mov    %eax,0x4(%esp)
801026e3:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
801026ea:	e8 04 fe ff ff       	call   801024f3 <outb>
  if(b->flags & B_DIRTY){
801026ef:	8b 45 08             	mov    0x8(%ebp),%eax
801026f2:	8b 00                	mov    (%eax),%eax
801026f4:	83 e0 04             	and    $0x4,%eax
801026f7:	85 c0                	test   %eax,%eax
801026f9:	74 34                	je     8010272f <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
801026fb:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102702:	00 
80102703:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010270a:	e8 e4 fd ff ff       	call   801024f3 <outb>
    outsl(0x1f0, b->data, 512/4);
8010270f:	8b 45 08             	mov    0x8(%ebp),%eax
80102712:	83 c0 18             	add    $0x18,%eax
80102715:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
8010271c:	00 
8010271d:	89 44 24 04          	mov    %eax,0x4(%esp)
80102721:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102728:	e8 e4 fd ff ff       	call   80102511 <outsl>
8010272d:	eb 14                	jmp    80102743 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
8010272f:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102736:	00 
80102737:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
8010273e:	e8 b0 fd ff ff       	call   801024f3 <outb>
  }
}
80102743:	c9                   	leave  
80102744:	c3                   	ret    

80102745 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102745:	55                   	push   %ebp
80102746:	89 e5                	mov    %esp,%ebp
80102748:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010274b:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102752:	e8 08 25 00 00       	call   80104c5f <acquire>
  if((b = idequeue) == 0){
80102757:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010275c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010275f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102763:	75 11                	jne    80102776 <ideintr+0x31>
    release(&idelock);
80102765:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
8010276c:	e8 50 25 00 00       	call   80104cc1 <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102771:	e9 90 00 00 00       	jmp    80102806 <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102776:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102779:	8b 40 14             	mov    0x14(%eax),%eax
8010277c:	a3 34 b6 10 80       	mov    %eax,0x8010b634

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102781:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102784:	8b 00                	mov    (%eax),%eax
80102786:	83 e0 04             	and    $0x4,%eax
80102789:	85 c0                	test   %eax,%eax
8010278b:	75 2e                	jne    801027bb <ideintr+0x76>
8010278d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102794:	e8 9d fd ff ff       	call   80102536 <idewait>
80102799:	85 c0                	test   %eax,%eax
8010279b:	78 1e                	js     801027bb <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
8010279d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027a0:	83 c0 18             	add    $0x18,%eax
801027a3:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
801027aa:	00 
801027ab:	89 44 24 04          	mov    %eax,0x4(%esp)
801027af:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
801027b6:	e8 13 fd ff ff       	call   801024ce <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
801027bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027be:	8b 00                	mov    (%eax),%eax
801027c0:	89 c2                	mov    %eax,%edx
801027c2:	83 ca 02             	or     $0x2,%edx
801027c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027c8:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
801027ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027cd:	8b 00                	mov    (%eax),%eax
801027cf:	89 c2                	mov    %eax,%edx
801027d1:	83 e2 fb             	and    $0xfffffffb,%edx
801027d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027d7:	89 10                	mov    %edx,(%eax)
  wakeup(b);
801027d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801027dc:	89 04 24             	mov    %eax,(%esp)
801027df:	e8 76 22 00 00       	call   80104a5a <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
801027e4:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027e9:	85 c0                	test   %eax,%eax
801027eb:	74 0d                	je     801027fa <ideintr+0xb5>
    idestart(idequeue);
801027ed:	a1 34 b6 10 80       	mov    0x8010b634,%eax
801027f2:	89 04 24             	mov    %eax,(%esp)
801027f5:	e8 26 fe ff ff       	call   80102620 <idestart>

  release(&idelock);
801027fa:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102801:	e8 bb 24 00 00       	call   80104cc1 <release>
}
80102806:	c9                   	leave  
80102807:	c3                   	ret    

80102808 <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102808:	55                   	push   %ebp
80102809:	89 e5                	mov    %esp,%ebp
8010280b:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
8010280e:	8b 45 08             	mov    0x8(%ebp),%eax
80102811:	8b 00                	mov    (%eax),%eax
80102813:	83 e0 01             	and    $0x1,%eax
80102816:	85 c0                	test   %eax,%eax
80102818:	75 0c                	jne    80102826 <iderw+0x1e>
    panic("iderw: buf not busy");
8010281a:	c7 04 24 f2 83 10 80 	movl   $0x801083f2,(%esp)
80102821:	e8 17 dd ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102826:	8b 45 08             	mov    0x8(%ebp),%eax
80102829:	8b 00                	mov    (%eax),%eax
8010282b:	83 e0 06             	and    $0x6,%eax
8010282e:	83 f8 02             	cmp    $0x2,%eax
80102831:	75 0c                	jne    8010283f <iderw+0x37>
    panic("iderw: nothing to do");
80102833:	c7 04 24 06 84 10 80 	movl   $0x80108406,(%esp)
8010283a:	e8 fe dc ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
8010283f:	8b 45 08             	mov    0x8(%ebp),%eax
80102842:	8b 40 04             	mov    0x4(%eax),%eax
80102845:	85 c0                	test   %eax,%eax
80102847:	74 15                	je     8010285e <iderw+0x56>
80102849:	a1 38 b6 10 80       	mov    0x8010b638,%eax
8010284e:	85 c0                	test   %eax,%eax
80102850:	75 0c                	jne    8010285e <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102852:	c7 04 24 1b 84 10 80 	movl   $0x8010841b,(%esp)
80102859:	e8 df dc ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
8010285e:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
80102865:	e8 f5 23 00 00       	call   80104c5f <acquire>

  // Append b to idequeue.
  b->qnext = 0;
8010286a:	8b 45 08             	mov    0x8(%ebp),%eax
8010286d:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102874:	c7 45 f4 34 b6 10 80 	movl   $0x8010b634,-0xc(%ebp)
8010287b:	eb 0b                	jmp    80102888 <iderw+0x80>
8010287d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102880:	8b 00                	mov    (%eax),%eax
80102882:	83 c0 14             	add    $0x14,%eax
80102885:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102888:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010288b:	8b 00                	mov    (%eax),%eax
8010288d:	85 c0                	test   %eax,%eax
8010288f:	75 ec                	jne    8010287d <iderw+0x75>
    ;
  *pp = b;
80102891:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102894:	8b 55 08             	mov    0x8(%ebp),%edx
80102897:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102899:	a1 34 b6 10 80       	mov    0x8010b634,%eax
8010289e:	3b 45 08             	cmp    0x8(%ebp),%eax
801028a1:	75 22                	jne    801028c5 <iderw+0xbd>
    idestart(b);
801028a3:	8b 45 08             	mov    0x8(%ebp),%eax
801028a6:	89 04 24             	mov    %eax,(%esp)
801028a9:	e8 72 fd ff ff       	call   80102620 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801028ae:	eb 15                	jmp    801028c5 <iderw+0xbd>
    sleep(b, &idelock);
801028b0:	c7 44 24 04 00 b6 10 	movl   $0x8010b600,0x4(%esp)
801028b7:	80 
801028b8:	8b 45 08             	mov    0x8(%ebp),%eax
801028bb:	89 04 24             	mov    %eax,(%esp)
801028be:	e8 be 20 00 00       	call   80104981 <sleep>
801028c3:	eb 01                	jmp    801028c6 <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
801028c5:	90                   	nop
801028c6:	8b 45 08             	mov    0x8(%ebp),%eax
801028c9:	8b 00                	mov    (%eax),%eax
801028cb:	83 e0 06             	and    $0x6,%eax
801028ce:	83 f8 02             	cmp    $0x2,%eax
801028d1:	75 dd                	jne    801028b0 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
801028d3:	c7 04 24 00 b6 10 80 	movl   $0x8010b600,(%esp)
801028da:	e8 e2 23 00 00       	call   80104cc1 <release>
}
801028df:	c9                   	leave  
801028e0:	c3                   	ret    
801028e1:	00 00                	add    %al,(%eax)
	...

801028e4 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
801028e4:	55                   	push   %ebp
801028e5:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028e7:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
801028ec:	8b 55 08             	mov    0x8(%ebp),%edx
801028ef:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
801028f1:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
801028f6:	8b 40 10             	mov    0x10(%eax),%eax
}
801028f9:	5d                   	pop    %ebp
801028fa:	c3                   	ret    

801028fb <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
801028fb:	55                   	push   %ebp
801028fc:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
801028fe:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
80102903:	8b 55 08             	mov    0x8(%ebp),%edx
80102906:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102908:	a1 34 fd 10 80       	mov    0x8010fd34,%eax
8010290d:	8b 55 0c             	mov    0xc(%ebp),%edx
80102910:	89 50 10             	mov    %edx,0x10(%eax)
}
80102913:	5d                   	pop    %ebp
80102914:	c3                   	ret    

80102915 <ioapicinit>:

void
ioapicinit(void)
{
80102915:	55                   	push   %ebp
80102916:	89 e5                	mov    %esp,%ebp
80102918:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
8010291b:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
80102920:	85 c0                	test   %eax,%eax
80102922:	0f 84 9f 00 00 00    	je     801029c7 <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102928:	c7 05 34 fd 10 80 00 	movl   $0xfec00000,0x8010fd34
8010292f:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102932:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102939:	e8 a6 ff ff ff       	call   801028e4 <ioapicread>
8010293e:	c1 e8 10             	shr    $0x10,%eax
80102941:	25 ff 00 00 00       	and    $0xff,%eax
80102946:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102949:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102950:	e8 8f ff ff ff       	call   801028e4 <ioapicread>
80102955:	c1 e8 18             	shr    $0x18,%eax
80102958:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
8010295b:	0f b6 05 00 fe 10 80 	movzbl 0x8010fe00,%eax
80102962:	0f b6 c0             	movzbl %al,%eax
80102965:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102968:	74 0c                	je     80102976 <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
8010296a:	c7 04 24 3c 84 10 80 	movl   $0x8010843c,(%esp)
80102971:	e8 2b da ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102976:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010297d:	eb 3e                	jmp    801029bd <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
8010297f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102982:	83 c0 20             	add    $0x20,%eax
80102985:	0d 00 00 01 00       	or     $0x10000,%eax
8010298a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010298d:	83 c2 08             	add    $0x8,%edx
80102990:	01 d2                	add    %edx,%edx
80102992:	89 44 24 04          	mov    %eax,0x4(%esp)
80102996:	89 14 24             	mov    %edx,(%esp)
80102999:	e8 5d ff ff ff       	call   801028fb <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
8010299e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029a1:	83 c0 08             	add    $0x8,%eax
801029a4:	01 c0                	add    %eax,%eax
801029a6:	83 c0 01             	add    $0x1,%eax
801029a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801029b0:	00 
801029b1:	89 04 24             	mov    %eax,(%esp)
801029b4:	e8 42 ff ff ff       	call   801028fb <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
801029b9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801029bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029c0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
801029c3:	7e ba                	jle    8010297f <ioapicinit+0x6a>
801029c5:	eb 01                	jmp    801029c8 <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
801029c7:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
801029c8:	c9                   	leave  
801029c9:	c3                   	ret    

801029ca <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
801029ca:	55                   	push   %ebp
801029cb:	89 e5                	mov    %esp,%ebp
801029cd:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
801029d0:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
801029d5:	85 c0                	test   %eax,%eax
801029d7:	74 39                	je     80102a12 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
801029d9:	8b 45 08             	mov    0x8(%ebp),%eax
801029dc:	83 c0 20             	add    $0x20,%eax
801029df:	8b 55 08             	mov    0x8(%ebp),%edx
801029e2:	83 c2 08             	add    $0x8,%edx
801029e5:	01 d2                	add    %edx,%edx
801029e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801029eb:	89 14 24             	mov    %edx,(%esp)
801029ee:	e8 08 ff ff ff       	call   801028fb <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
801029f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801029f6:	c1 e0 18             	shl    $0x18,%eax
801029f9:	8b 55 08             	mov    0x8(%ebp),%edx
801029fc:	83 c2 08             	add    $0x8,%edx
801029ff:	01 d2                	add    %edx,%edx
80102a01:	83 c2 01             	add    $0x1,%edx
80102a04:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a08:	89 14 24             	mov    %edx,(%esp)
80102a0b:	e8 eb fe ff ff       	call   801028fb <ioapicwrite>
80102a10:	eb 01                	jmp    80102a13 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80102a12:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80102a13:	c9                   	leave  
80102a14:	c3                   	ret    
80102a15:	00 00                	add    %al,(%eax)
	...

80102a18 <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80102a18:	55                   	push   %ebp
80102a19:	89 e5                	mov    %esp,%ebp
80102a1b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a1e:	05 00 00 00 80       	add    $0x80000000,%eax
80102a23:	5d                   	pop    %ebp
80102a24:	c3                   	ret    

80102a25 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102a25:	55                   	push   %ebp
80102a26:	89 e5                	mov    %esp,%ebp
80102a28:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
80102a2b:	c7 44 24 04 6e 84 10 	movl   $0x8010846e,0x4(%esp)
80102a32:	80 
80102a33:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102a3a:	e8 ff 21 00 00       	call   80104c3e <initlock>
  kmem.use_lock = 0;
80102a3f:	c7 05 74 fd 10 80 00 	movl   $0x0,0x8010fd74
80102a46:	00 00 00 
  freerange(vstart, vend);
80102a49:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a4c:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a50:	8b 45 08             	mov    0x8(%ebp),%eax
80102a53:	89 04 24             	mov    %eax,(%esp)
80102a56:	e8 26 00 00 00       	call   80102a81 <freerange>
}
80102a5b:	c9                   	leave  
80102a5c:	c3                   	ret    

80102a5d <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102a5d:	55                   	push   %ebp
80102a5e:	89 e5                	mov    %esp,%ebp
80102a60:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80102a63:	8b 45 0c             	mov    0xc(%ebp),%eax
80102a66:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a6a:	8b 45 08             	mov    0x8(%ebp),%eax
80102a6d:	89 04 24             	mov    %eax,(%esp)
80102a70:	e8 0c 00 00 00       	call   80102a81 <freerange>
  kmem.use_lock = 1;
80102a75:	c7 05 74 fd 10 80 01 	movl   $0x1,0x8010fd74
80102a7c:	00 00 00 
}
80102a7f:	c9                   	leave  
80102a80:	c3                   	ret    

80102a81 <freerange>:

void
freerange(void *vstart, void *vend)
{
80102a81:	55                   	push   %ebp
80102a82:	89 e5                	mov    %esp,%ebp
80102a84:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102a87:	8b 45 08             	mov    0x8(%ebp),%eax
80102a8a:	05 ff 0f 00 00       	add    $0xfff,%eax
80102a8f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102a94:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102a97:	eb 12                	jmp    80102aab <freerange+0x2a>
    kfree(p);
80102a99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a9c:	89 04 24             	mov    %eax,(%esp)
80102a9f:	e8 16 00 00 00       	call   80102aba <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102aa4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aae:	05 00 10 00 00       	add    $0x1000,%eax
80102ab3:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102ab6:	76 e1                	jbe    80102a99 <freerange+0x18>
    kfree(p);
}
80102ab8:	c9                   	leave  
80102ab9:	c3                   	ret    

80102aba <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102aba:	55                   	push   %ebp
80102abb:	89 e5                	mov    %esp,%ebp
80102abd:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
80102ac0:	8b 45 08             	mov    0x8(%ebp),%eax
80102ac3:	25 ff 0f 00 00       	and    $0xfff,%eax
80102ac8:	85 c0                	test   %eax,%eax
80102aca:	75 1b                	jne    80102ae7 <kfree+0x2d>
80102acc:	81 7d 08 fc 2b 11 80 	cmpl   $0x80112bfc,0x8(%ebp)
80102ad3:	72 12                	jb     80102ae7 <kfree+0x2d>
80102ad5:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad8:	89 04 24             	mov    %eax,(%esp)
80102adb:	e8 38 ff ff ff       	call   80102a18 <v2p>
80102ae0:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102ae5:	76 0c                	jbe    80102af3 <kfree+0x39>
    panic("kfree");
80102ae7:	c7 04 24 73 84 10 80 	movl   $0x80108473,(%esp)
80102aee:	e8 4a da ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102af3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80102afa:	00 
80102afb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102b02:	00 
80102b03:	8b 45 08             	mov    0x8(%ebp),%eax
80102b06:	89 04 24             	mov    %eax,(%esp)
80102b09:	e8 a0 23 00 00       	call   80104eae <memset>

  if(kmem.use_lock)
80102b0e:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102b13:	85 c0                	test   %eax,%eax
80102b15:	74 0c                	je     80102b23 <kfree+0x69>
    acquire(&kmem.lock);
80102b17:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102b1e:	e8 3c 21 00 00       	call   80104c5f <acquire>
  r = (struct run*)v;
80102b23:	8b 45 08             	mov    0x8(%ebp),%eax
80102b26:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102b29:	8b 15 78 fd 10 80    	mov    0x8010fd78,%edx
80102b2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b32:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102b34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b37:	a3 78 fd 10 80       	mov    %eax,0x8010fd78
  if(kmem.use_lock)
80102b3c:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102b41:	85 c0                	test   %eax,%eax
80102b43:	74 0c                	je     80102b51 <kfree+0x97>
    release(&kmem.lock);
80102b45:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102b4c:	e8 70 21 00 00       	call   80104cc1 <release>
}
80102b51:	c9                   	leave  
80102b52:	c3                   	ret    

80102b53 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102b53:	55                   	push   %ebp
80102b54:	89 e5                	mov    %esp,%ebp
80102b56:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
80102b59:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102b5e:	85 c0                	test   %eax,%eax
80102b60:	74 0c                	je     80102b6e <kalloc+0x1b>
    acquire(&kmem.lock);
80102b62:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102b69:	e8 f1 20 00 00       	call   80104c5f <acquire>
  r = kmem.freelist;
80102b6e:	a1 78 fd 10 80       	mov    0x8010fd78,%eax
80102b73:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102b76:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102b7a:	74 0a                	je     80102b86 <kalloc+0x33>
    kmem.freelist = r->next;
80102b7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b7f:	8b 00                	mov    (%eax),%eax
80102b81:	a3 78 fd 10 80       	mov    %eax,0x8010fd78
  if(kmem.use_lock)
80102b86:	a1 74 fd 10 80       	mov    0x8010fd74,%eax
80102b8b:	85 c0                	test   %eax,%eax
80102b8d:	74 0c                	je     80102b9b <kalloc+0x48>
    release(&kmem.lock);
80102b8f:	c7 04 24 40 fd 10 80 	movl   $0x8010fd40,(%esp)
80102b96:	e8 26 21 00 00       	call   80104cc1 <release>
  return (char*)r;
80102b9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102b9e:	c9                   	leave  
80102b9f:	c3                   	ret    

80102ba0 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102ba0:	55                   	push   %ebp
80102ba1:	89 e5                	mov    %esp,%ebp
80102ba3:	53                   	push   %ebx
80102ba4:	83 ec 14             	sub    $0x14,%esp
80102ba7:	8b 45 08             	mov    0x8(%ebp),%eax
80102baa:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102bae:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102bb2:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102bb6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102bba:	ec                   	in     (%dx),%al
80102bbb:	89 c3                	mov    %eax,%ebx
80102bbd:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102bc0:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102bc4:	83 c4 14             	add    $0x14,%esp
80102bc7:	5b                   	pop    %ebx
80102bc8:	5d                   	pop    %ebp
80102bc9:	c3                   	ret    

80102bca <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102bca:	55                   	push   %ebp
80102bcb:	89 e5                	mov    %esp,%ebp
80102bcd:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102bd0:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
80102bd7:	e8 c4 ff ff ff       	call   80102ba0 <inb>
80102bdc:	0f b6 c0             	movzbl %al,%eax
80102bdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102be2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102be5:	83 e0 01             	and    $0x1,%eax
80102be8:	85 c0                	test   %eax,%eax
80102bea:	75 0a                	jne    80102bf6 <kbdgetc+0x2c>
    return -1;
80102bec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102bf1:	e9 23 01 00 00       	jmp    80102d19 <kbdgetc+0x14f>
  data = inb(KBDATAP);
80102bf6:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80102bfd:	e8 9e ff ff ff       	call   80102ba0 <inb>
80102c02:	0f b6 c0             	movzbl %al,%eax
80102c05:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102c08:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102c0f:	75 17                	jne    80102c28 <kbdgetc+0x5e>
    shift |= E0ESC;
80102c11:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c16:	83 c8 40             	or     $0x40,%eax
80102c19:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c1e:	b8 00 00 00 00       	mov    $0x0,%eax
80102c23:	e9 f1 00 00 00       	jmp    80102d19 <kbdgetc+0x14f>
  } else if(data & 0x80){
80102c28:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c2b:	25 80 00 00 00       	and    $0x80,%eax
80102c30:	85 c0                	test   %eax,%eax
80102c32:	74 45                	je     80102c79 <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102c34:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c39:	83 e0 40             	and    $0x40,%eax
80102c3c:	85 c0                	test   %eax,%eax
80102c3e:	75 08                	jne    80102c48 <kbdgetc+0x7e>
80102c40:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c43:	83 e0 7f             	and    $0x7f,%eax
80102c46:	eb 03                	jmp    80102c4b <kbdgetc+0x81>
80102c48:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c4b:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102c4e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c51:	05 20 90 10 80       	add    $0x80109020,%eax
80102c56:	0f b6 00             	movzbl (%eax),%eax
80102c59:	83 c8 40             	or     $0x40,%eax
80102c5c:	0f b6 c0             	movzbl %al,%eax
80102c5f:	f7 d0                	not    %eax
80102c61:	89 c2                	mov    %eax,%edx
80102c63:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c68:	21 d0                	and    %edx,%eax
80102c6a:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
    return 0;
80102c6f:	b8 00 00 00 00       	mov    $0x0,%eax
80102c74:	e9 a0 00 00 00       	jmp    80102d19 <kbdgetc+0x14f>
  } else if(shift & E0ESC){
80102c79:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c7e:	83 e0 40             	and    $0x40,%eax
80102c81:	85 c0                	test   %eax,%eax
80102c83:	74 14                	je     80102c99 <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102c85:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102c8c:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102c91:	83 e0 bf             	and    $0xffffffbf,%eax
80102c94:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  }

  shift |= shiftcode[data];
80102c99:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102c9c:	05 20 90 10 80       	add    $0x80109020,%eax
80102ca1:	0f b6 00             	movzbl (%eax),%eax
80102ca4:	0f b6 d0             	movzbl %al,%edx
80102ca7:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cac:	09 d0                	or     %edx,%eax
80102cae:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  shift ^= togglecode[data];
80102cb3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102cb6:	05 20 91 10 80       	add    $0x80109120,%eax
80102cbb:	0f b6 00             	movzbl (%eax),%eax
80102cbe:	0f b6 d0             	movzbl %al,%edx
80102cc1:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cc6:	31 d0                	xor    %edx,%eax
80102cc8:	a3 3c b6 10 80       	mov    %eax,0x8010b63c
  c = charcode[shift & (CTL | SHIFT)][data];
80102ccd:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102cd2:	83 e0 03             	and    $0x3,%eax
80102cd5:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80102cdc:	03 45 fc             	add    -0x4(%ebp),%eax
80102cdf:	0f b6 00             	movzbl (%eax),%eax
80102ce2:	0f b6 c0             	movzbl %al,%eax
80102ce5:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102ce8:	a1 3c b6 10 80       	mov    0x8010b63c,%eax
80102ced:	83 e0 08             	and    $0x8,%eax
80102cf0:	85 c0                	test   %eax,%eax
80102cf2:	74 22                	je     80102d16 <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80102cf4:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102cf8:	76 0c                	jbe    80102d06 <kbdgetc+0x13c>
80102cfa:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102cfe:	77 06                	ja     80102d06 <kbdgetc+0x13c>
      c += 'A' - 'a';
80102d00:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102d04:	eb 10                	jmp    80102d16 <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
80102d06:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102d0a:	76 0a                	jbe    80102d16 <kbdgetc+0x14c>
80102d0c:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102d10:	77 04                	ja     80102d16 <kbdgetc+0x14c>
      c += 'a' - 'A';
80102d12:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102d16:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d19:	c9                   	leave  
80102d1a:	c3                   	ret    

80102d1b <kbdintr>:

void
kbdintr(void)
{
80102d1b:	55                   	push   %ebp
80102d1c:	89 e5                	mov    %esp,%ebp
80102d1e:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80102d21:	c7 04 24 ca 2b 10 80 	movl   $0x80102bca,(%esp)
80102d28:	e8 80 da ff ff       	call   801007ad <consoleintr>
}
80102d2d:	c9                   	leave  
80102d2e:	c3                   	ret    
	...

80102d30 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102d30:	55                   	push   %ebp
80102d31:	89 e5                	mov    %esp,%ebp
80102d33:	83 ec 08             	sub    $0x8,%esp
80102d36:	8b 55 08             	mov    0x8(%ebp),%edx
80102d39:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d3c:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102d40:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102d43:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102d47:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102d4b:	ee                   	out    %al,(%dx)
}
80102d4c:	c9                   	leave  
80102d4d:	c3                   	ret    

80102d4e <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80102d4e:	55                   	push   %ebp
80102d4f:	89 e5                	mov    %esp,%ebp
80102d51:	53                   	push   %ebx
80102d52:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80102d55:	9c                   	pushf  
80102d56:	5b                   	pop    %ebx
80102d57:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80102d5a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102d5d:	83 c4 10             	add    $0x10,%esp
80102d60:	5b                   	pop    %ebx
80102d61:	5d                   	pop    %ebp
80102d62:	c3                   	ret    

80102d63 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80102d63:	55                   	push   %ebp
80102d64:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102d66:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102d6b:	8b 55 08             	mov    0x8(%ebp),%edx
80102d6e:	c1 e2 02             	shl    $0x2,%edx
80102d71:	01 c2                	add    %eax,%edx
80102d73:	8b 45 0c             	mov    0xc(%ebp),%eax
80102d76:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102d78:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102d7d:	83 c0 20             	add    $0x20,%eax
80102d80:	8b 00                	mov    (%eax),%eax
}
80102d82:	5d                   	pop    %ebp
80102d83:	c3                   	ret    

80102d84 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
80102d84:	55                   	push   %ebp
80102d85:	89 e5                	mov    %esp,%ebp
80102d87:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
80102d8a:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102d8f:	85 c0                	test   %eax,%eax
80102d91:	0f 84 47 01 00 00    	je     80102ede <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102d97:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
80102d9e:	00 
80102d9f:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
80102da6:	e8 b8 ff ff ff       	call   80102d63 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102dab:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
80102db2:	00 
80102db3:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
80102dba:	e8 a4 ff ff ff       	call   80102d63 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102dbf:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
80102dc6:	00 
80102dc7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102dce:	e8 90 ff ff ff       	call   80102d63 <lapicw>
  lapicw(TICR, 10000000); 
80102dd3:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
80102dda:	00 
80102ddb:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80102de2:	e8 7c ff ff ff       	call   80102d63 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102de7:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102dee:	00 
80102def:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
80102df6:	e8 68 ff ff ff       	call   80102d63 <lapicw>
  lapicw(LINT1, MASKED);
80102dfb:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e02:	00 
80102e03:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
80102e0a:	e8 54 ff ff ff       	call   80102d63 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102e0f:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102e14:	83 c0 30             	add    $0x30,%eax
80102e17:	8b 00                	mov    (%eax),%eax
80102e19:	c1 e8 10             	shr    $0x10,%eax
80102e1c:	25 ff 00 00 00       	and    $0xff,%eax
80102e21:	83 f8 03             	cmp    $0x3,%eax
80102e24:	76 14                	jbe    80102e3a <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
80102e26:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80102e2d:	00 
80102e2e:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80102e35:	e8 29 ff ff ff       	call   80102d63 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102e3a:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80102e41:	00 
80102e42:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
80102e49:	e8 15 ff ff ff       	call   80102d63 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102e4e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e55:	00 
80102e56:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e5d:	e8 01 ff ff ff       	call   80102d63 <lapicw>
  lapicw(ESR, 0);
80102e62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e69:	00 
80102e6a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80102e71:	e8 ed fe ff ff       	call   80102d63 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102e76:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e7d:	00 
80102e7e:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102e85:	e8 d9 fe ff ff       	call   80102d63 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102e8a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102e91:	00 
80102e92:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102e99:	e8 c5 fe ff ff       	call   80102d63 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102e9e:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
80102ea5:	00 
80102ea6:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102ead:	e8 b1 fe ff ff       	call   80102d63 <lapicw>
  while(lapic[ICRLO] & DELIVS)
80102eb2:	90                   	nop
80102eb3:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102eb8:	05 00 03 00 00       	add    $0x300,%eax
80102ebd:	8b 00                	mov    (%eax),%eax
80102ebf:	25 00 10 00 00       	and    $0x1000,%eax
80102ec4:	85 c0                	test   %eax,%eax
80102ec6:	75 eb                	jne    80102eb3 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102ec8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102ecf:	00 
80102ed0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80102ed7:	e8 87 fe ff ff       	call   80102d63 <lapicw>
80102edc:	eb 01                	jmp    80102edf <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80102ede:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102edf:	c9                   	leave  
80102ee0:	c3                   	ret    

80102ee1 <cpunum>:

int
cpunum(void)
{
80102ee1:	55                   	push   %ebp
80102ee2:	89 e5                	mov    %esp,%ebp
80102ee4:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
80102ee7:	e8 62 fe ff ff       	call   80102d4e <readeflags>
80102eec:	25 00 02 00 00       	and    $0x200,%eax
80102ef1:	85 c0                	test   %eax,%eax
80102ef3:	74 29                	je     80102f1e <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80102ef5:	a1 40 b6 10 80       	mov    0x8010b640,%eax
80102efa:	85 c0                	test   %eax,%eax
80102efc:	0f 94 c2             	sete   %dl
80102eff:	83 c0 01             	add    $0x1,%eax
80102f02:	a3 40 b6 10 80       	mov    %eax,0x8010b640
80102f07:	84 d2                	test   %dl,%dl
80102f09:	74 13                	je     80102f1e <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
80102f0b:	8b 45 04             	mov    0x4(%ebp),%eax
80102f0e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102f12:	c7 04 24 7c 84 10 80 	movl   $0x8010847c,(%esp)
80102f19:	e8 83 d4 ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80102f1e:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102f23:	85 c0                	test   %eax,%eax
80102f25:	74 0f                	je     80102f36 <cpunum+0x55>
    return lapic[ID]>>24;
80102f27:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102f2c:	83 c0 20             	add    $0x20,%eax
80102f2f:	8b 00                	mov    (%eax),%eax
80102f31:	c1 e8 18             	shr    $0x18,%eax
80102f34:	eb 05                	jmp    80102f3b <cpunum+0x5a>
  return 0;
80102f36:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102f3b:	c9                   	leave  
80102f3c:	c3                   	ret    

80102f3d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80102f3d:	55                   	push   %ebp
80102f3e:	89 e5                	mov    %esp,%ebp
80102f40:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80102f43:	a1 7c fd 10 80       	mov    0x8010fd7c,%eax
80102f48:	85 c0                	test   %eax,%eax
80102f4a:	74 14                	je     80102f60 <lapiceoi+0x23>
    lapicw(EOI, 0);
80102f4c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102f53:	00 
80102f54:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
80102f5b:	e8 03 fe ff ff       	call   80102d63 <lapicw>
}
80102f60:	c9                   	leave  
80102f61:	c3                   	ret    

80102f62 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80102f62:	55                   	push   %ebp
80102f63:	89 e5                	mov    %esp,%ebp
}
80102f65:	5d                   	pop    %ebp
80102f66:	c3                   	ret    

80102f67 <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
80102f67:	55                   	push   %ebp
80102f68:	89 e5                	mov    %esp,%ebp
80102f6a:	83 ec 1c             	sub    $0x1c,%esp
80102f6d:	8b 45 08             	mov    0x8(%ebp),%eax
80102f70:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80102f73:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80102f7a:	00 
80102f7b:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
80102f82:	e8 a9 fd ff ff       	call   80102d30 <outb>
  outb(IO_RTC+1, 0x0A);
80102f87:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80102f8e:	00 
80102f8f:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
80102f96:	e8 95 fd ff ff       	call   80102d30 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80102f9b:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80102fa2:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fa5:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80102faa:	8b 45 f8             	mov    -0x8(%ebp),%eax
80102fad:	8d 50 02             	lea    0x2(%eax),%edx
80102fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
80102fb3:	c1 e8 04             	shr    $0x4,%eax
80102fb6:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80102fb9:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80102fbd:	c1 e0 18             	shl    $0x18,%eax
80102fc0:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fc4:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
80102fcb:	e8 93 fd ff ff       	call   80102d63 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80102fd0:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
80102fd7:	00 
80102fd8:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fdf:	e8 7f fd ff ff       	call   80102d63 <lapicw>
  microdelay(200);
80102fe4:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80102feb:	e8 72 ff ff ff       	call   80102f62 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80102ff0:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
80102ff7:	00 
80102ff8:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80102fff:	e8 5f fd ff ff       	call   80102d63 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103004:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010300b:	e8 52 ff ff ff       	call   80102f62 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103010:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103017:	eb 40                	jmp    80103059 <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
80103019:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
8010301d:	c1 e0 18             	shl    $0x18,%eax
80103020:	89 44 24 04          	mov    %eax,0x4(%esp)
80103024:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010302b:	e8 33 fd ff ff       	call   80102d63 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103030:	8b 45 0c             	mov    0xc(%ebp),%eax
80103033:	c1 e8 0c             	shr    $0xc,%eax
80103036:	80 cc 06             	or     $0x6,%ah
80103039:	89 44 24 04          	mov    %eax,0x4(%esp)
8010303d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103044:	e8 1a fd ff ff       	call   80102d63 <lapicw>
    microdelay(200);
80103049:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103050:	e8 0d ff ff ff       	call   80102f62 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103055:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103059:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010305d:	7e ba                	jle    80103019 <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010305f:	c9                   	leave  
80103060:	c3                   	ret    
80103061:	00 00                	add    %al,(%eax)
	...

80103064 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103064:	55                   	push   %ebp
80103065:	89 e5                	mov    %esp,%ebp
80103067:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010306a:	c7 44 24 04 a8 84 10 	movl   $0x801084a8,0x4(%esp)
80103071:	80 
80103072:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
80103079:	e8 c0 1b 00 00       	call   80104c3e <initlock>
  readsb(ROOTDEV, &sb);
8010307e:	8d 45 e8             	lea    -0x18(%ebp),%eax
80103081:	89 44 24 04          	mov    %eax,0x4(%esp)
80103085:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010308c:	e8 af e2 ff ff       	call   80101340 <readsb>
  log.start = sb.size - sb.nlog;
80103091:	8b 55 e8             	mov    -0x18(%ebp),%edx
80103094:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103097:	89 d1                	mov    %edx,%ecx
80103099:	29 c1                	sub    %eax,%ecx
8010309b:	89 c8                	mov    %ecx,%eax
8010309d:	a3 b4 fd 10 80       	mov    %eax,0x8010fdb4
  log.size = sb.nlog;
801030a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030a5:	a3 b8 fd 10 80       	mov    %eax,0x8010fdb8
  log.dev = ROOTDEV;
801030aa:	c7 05 c0 fd 10 80 01 	movl   $0x1,0x8010fdc0
801030b1:	00 00 00 
  recover_from_log();
801030b4:	e8 97 01 00 00       	call   80103250 <recover_from_log>
}
801030b9:	c9                   	leave  
801030ba:	c3                   	ret    

801030bb <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801030bb:	55                   	push   %ebp
801030bc:	89 e5                	mov    %esp,%ebp
801030be:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801030c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801030c8:	e9 89 00 00 00       	jmp    80103156 <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801030cd:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
801030d2:	03 45 f4             	add    -0xc(%ebp),%eax
801030d5:	83 c0 01             	add    $0x1,%eax
801030d8:	89 c2                	mov    %eax,%edx
801030da:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
801030df:	89 54 24 04          	mov    %edx,0x4(%esp)
801030e3:	89 04 24             	mov    %eax,(%esp)
801030e6:	e8 bb d0 ff ff       	call   801001a6 <bread>
801030eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
801030ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030f1:	83 c0 10             	add    $0x10,%eax
801030f4:	8b 04 85 88 fd 10 80 	mov    -0x7fef0278(,%eax,4),%eax
801030fb:	89 c2                	mov    %eax,%edx
801030fd:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
80103102:	89 54 24 04          	mov    %edx,0x4(%esp)
80103106:	89 04 24             	mov    %eax,(%esp)
80103109:	e8 98 d0 ff ff       	call   801001a6 <bread>
8010310e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103111:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103114:	8d 50 18             	lea    0x18(%eax),%edx
80103117:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010311a:	83 c0 18             	add    $0x18,%eax
8010311d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103124:	00 
80103125:	89 54 24 04          	mov    %edx,0x4(%esp)
80103129:	89 04 24             	mov    %eax,(%esp)
8010312c:	e8 50 1e 00 00       	call   80104f81 <memmove>
    bwrite(dbuf);  // write dst to disk
80103131:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103134:	89 04 24             	mov    %eax,(%esp)
80103137:	e8 a1 d0 ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
8010313c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010313f:	89 04 24             	mov    %eax,(%esp)
80103142:	e8 d0 d0 ff ff       	call   80100217 <brelse>
    brelse(dbuf);
80103147:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010314a:	89 04 24             	mov    %eax,(%esp)
8010314d:	e8 c5 d0 ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103152:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103156:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
8010315b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010315e:	0f 8f 69 ff ff ff    	jg     801030cd <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103164:	c9                   	leave  
80103165:	c3                   	ret    

80103166 <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
80103166:	55                   	push   %ebp
80103167:	89 e5                	mov    %esp,%ebp
80103169:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
8010316c:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
80103171:	89 c2                	mov    %eax,%edx
80103173:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
80103178:	89 54 24 04          	mov    %edx,0x4(%esp)
8010317c:	89 04 24             	mov    %eax,(%esp)
8010317f:	e8 22 d0 ff ff       	call   801001a6 <bread>
80103184:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
80103187:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010318a:	83 c0 18             	add    $0x18,%eax
8010318d:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103190:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103193:	8b 00                	mov    (%eax),%eax
80103195:	a3 c4 fd 10 80       	mov    %eax,0x8010fdc4
  for (i = 0; i < log.lh.n; i++) {
8010319a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801031a1:	eb 1b                	jmp    801031be <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801031a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801031a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801031a9:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801031ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
801031b0:	83 c2 10             	add    $0x10,%edx
801031b3:	89 04 95 88 fd 10 80 	mov    %eax,-0x7fef0278(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801031ba:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801031be:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
801031c3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801031c6:	7f db                	jg     801031a3 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801031c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031cb:	89 04 24             	mov    %eax,(%esp)
801031ce:	e8 44 d0 ff ff       	call   80100217 <brelse>
}
801031d3:	c9                   	leave  
801031d4:	c3                   	ret    

801031d5 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801031d5:	55                   	push   %ebp
801031d6:	89 e5                	mov    %esp,%ebp
801031d8:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801031db:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
801031e0:	89 c2                	mov    %eax,%edx
801031e2:	a1 c0 fd 10 80       	mov    0x8010fdc0,%eax
801031e7:	89 54 24 04          	mov    %edx,0x4(%esp)
801031eb:	89 04 24             	mov    %eax,(%esp)
801031ee:	e8 b3 cf ff ff       	call   801001a6 <bread>
801031f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801031f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801031f9:	83 c0 18             	add    $0x18,%eax
801031fc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801031ff:	8b 15 c4 fd 10 80    	mov    0x8010fdc4,%edx
80103205:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103208:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010320a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103211:	eb 1b                	jmp    8010322e <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103213:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103216:	83 c0 10             	add    $0x10,%eax
80103219:	8b 0c 85 88 fd 10 80 	mov    -0x7fef0278(,%eax,4),%ecx
80103220:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103223:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103226:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010322a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010322e:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103233:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103236:	7f db                	jg     80103213 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
80103238:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010323b:	89 04 24             	mov    %eax,(%esp)
8010323e:	e8 9a cf ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103243:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103246:	89 04 24             	mov    %eax,(%esp)
80103249:	e8 c9 cf ff ff       	call   80100217 <brelse>
}
8010324e:	c9                   	leave  
8010324f:	c3                   	ret    

80103250 <recover_from_log>:

static void
recover_from_log(void)
{
80103250:	55                   	push   %ebp
80103251:	89 e5                	mov    %esp,%ebp
80103253:	83 ec 08             	sub    $0x8,%esp
  read_head();      
80103256:	e8 0b ff ff ff       	call   80103166 <read_head>
  install_trans(); // if committed, copy from log to disk
8010325b:	e8 5b fe ff ff       	call   801030bb <install_trans>
  log.lh.n = 0;
80103260:	c7 05 c4 fd 10 80 00 	movl   $0x0,0x8010fdc4
80103267:	00 00 00 
  write_head(); // clear the log
8010326a:	e8 66 ff ff ff       	call   801031d5 <write_head>
}
8010326f:	c9                   	leave  
80103270:	c3                   	ret    

80103271 <begin_trans>:

void
begin_trans(void)
{
80103271:	55                   	push   %ebp
80103272:	89 e5                	mov    %esp,%ebp
80103274:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
80103277:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
8010327e:	e8 dc 19 00 00       	call   80104c5f <acquire>
  while (log.busy) {
80103283:	eb 14                	jmp    80103299 <begin_trans+0x28>
    sleep(&log, &log.lock);
80103285:	c7 44 24 04 80 fd 10 	movl   $0x8010fd80,0x4(%esp)
8010328c:	80 
8010328d:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
80103294:	e8 e8 16 00 00       	call   80104981 <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
80103299:	a1 bc fd 10 80       	mov    0x8010fdbc,%eax
8010329e:	85 c0                	test   %eax,%eax
801032a0:	75 e3                	jne    80103285 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801032a2:	c7 05 bc fd 10 80 01 	movl   $0x1,0x8010fdbc
801032a9:	00 00 00 
  release(&log.lock);
801032ac:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
801032b3:	e8 09 1a 00 00       	call   80104cc1 <release>
}
801032b8:	c9                   	leave  
801032b9:	c3                   	ret    

801032ba <commit_trans>:

void
commit_trans(void)
{
801032ba:	55                   	push   %ebp
801032bb:	89 e5                	mov    %esp,%ebp
801032bd:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801032c0:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
801032c5:	85 c0                	test   %eax,%eax
801032c7:	7e 19                	jle    801032e2 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801032c9:	e8 07 ff ff ff       	call   801031d5 <write_head>
    install_trans(); // Now install writes to home locations
801032ce:	e8 e8 fd ff ff       	call   801030bb <install_trans>
    log.lh.n = 0; 
801032d3:	c7 05 c4 fd 10 80 00 	movl   $0x0,0x8010fdc4
801032da:	00 00 00 
    write_head();    // Erase the transaction from the log
801032dd:	e8 f3 fe ff ff       	call   801031d5 <write_head>
  }
  
  acquire(&log.lock);
801032e2:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
801032e9:	e8 71 19 00 00       	call   80104c5f <acquire>
  log.busy = 0;
801032ee:	c7 05 bc fd 10 80 00 	movl   $0x0,0x8010fdbc
801032f5:	00 00 00 
  wakeup(&log);
801032f8:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
801032ff:	e8 56 17 00 00       	call   80104a5a <wakeup>
  release(&log.lock);
80103304:	c7 04 24 80 fd 10 80 	movl   $0x8010fd80,(%esp)
8010330b:	e8 b1 19 00 00       	call   80104cc1 <release>
}
80103310:	c9                   	leave  
80103311:	c3                   	ret    

80103312 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103312:	55                   	push   %ebp
80103313:	89 e5                	mov    %esp,%ebp
80103315:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103318:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
8010331d:	83 f8 09             	cmp    $0x9,%eax
80103320:	7f 12                	jg     80103334 <log_write+0x22>
80103322:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103327:	8b 15 b8 fd 10 80    	mov    0x8010fdb8,%edx
8010332d:	83 ea 01             	sub    $0x1,%edx
80103330:	39 d0                	cmp    %edx,%eax
80103332:	7c 0c                	jl     80103340 <log_write+0x2e>
    panic("too big a transaction");
80103334:	c7 04 24 ac 84 10 80 	movl   $0x801084ac,(%esp)
8010333b:	e8 fd d1 ff ff       	call   8010053d <panic>
  if (!log.busy)
80103340:	a1 bc fd 10 80       	mov    0x8010fdbc,%eax
80103345:	85 c0                	test   %eax,%eax
80103347:	75 0c                	jne    80103355 <log_write+0x43>
    panic("write outside of trans");
80103349:	c7 04 24 c2 84 10 80 	movl   $0x801084c2,(%esp)
80103350:	e8 e8 d1 ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103355:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010335c:	eb 1d                	jmp    8010337b <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
8010335e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103361:	83 c0 10             	add    $0x10,%eax
80103364:	8b 04 85 88 fd 10 80 	mov    -0x7fef0278(,%eax,4),%eax
8010336b:	89 c2                	mov    %eax,%edx
8010336d:	8b 45 08             	mov    0x8(%ebp),%eax
80103370:	8b 40 08             	mov    0x8(%eax),%eax
80103373:	39 c2                	cmp    %eax,%edx
80103375:	74 10                	je     80103387 <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
80103377:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010337b:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103380:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103383:	7f d9                	jg     8010335e <log_write+0x4c>
80103385:	eb 01                	jmp    80103388 <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
80103387:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
80103388:	8b 45 08             	mov    0x8(%ebp),%eax
8010338b:	8b 40 08             	mov    0x8(%eax),%eax
8010338e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103391:	83 c2 10             	add    $0x10,%edx
80103394:	89 04 95 88 fd 10 80 	mov    %eax,-0x7fef0278(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
8010339b:	a1 b4 fd 10 80       	mov    0x8010fdb4,%eax
801033a0:	03 45 f4             	add    -0xc(%ebp),%eax
801033a3:	83 c0 01             	add    $0x1,%eax
801033a6:	89 c2                	mov    %eax,%edx
801033a8:	8b 45 08             	mov    0x8(%ebp),%eax
801033ab:	8b 40 04             	mov    0x4(%eax),%eax
801033ae:	89 54 24 04          	mov    %edx,0x4(%esp)
801033b2:	89 04 24             	mov    %eax,(%esp)
801033b5:	e8 ec cd ff ff       	call   801001a6 <bread>
801033ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801033bd:	8b 45 08             	mov    0x8(%ebp),%eax
801033c0:	8d 50 18             	lea    0x18(%eax),%edx
801033c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033c6:	83 c0 18             	add    $0x18,%eax
801033c9:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801033d0:	00 
801033d1:	89 54 24 04          	mov    %edx,0x4(%esp)
801033d5:	89 04 24             	mov    %eax,(%esp)
801033d8:	e8 a4 1b 00 00       	call   80104f81 <memmove>
  bwrite(lbuf);
801033dd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033e0:	89 04 24             	mov    %eax,(%esp)
801033e3:	e8 f5 cd ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
801033e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033eb:	89 04 24             	mov    %eax,(%esp)
801033ee:	e8 24 ce ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
801033f3:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
801033f8:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801033fb:	75 0d                	jne    8010340a <log_write+0xf8>
    log.lh.n++;
801033fd:	a1 c4 fd 10 80       	mov    0x8010fdc4,%eax
80103402:	83 c0 01             	add    $0x1,%eax
80103405:	a3 c4 fd 10 80       	mov    %eax,0x8010fdc4
  b->flags |= B_DIRTY; // XXX prevent eviction
8010340a:	8b 45 08             	mov    0x8(%ebp),%eax
8010340d:	8b 00                	mov    (%eax),%eax
8010340f:	89 c2                	mov    %eax,%edx
80103411:	83 ca 04             	or     $0x4,%edx
80103414:	8b 45 08             	mov    0x8(%ebp),%eax
80103417:	89 10                	mov    %edx,(%eax)
}
80103419:	c9                   	leave  
8010341a:	c3                   	ret    
	...

8010341c <v2p>:
8010341c:	55                   	push   %ebp
8010341d:	89 e5                	mov    %esp,%ebp
8010341f:	8b 45 08             	mov    0x8(%ebp),%eax
80103422:	05 00 00 00 80       	add    $0x80000000,%eax
80103427:	5d                   	pop    %ebp
80103428:	c3                   	ret    

80103429 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103429:	55                   	push   %ebp
8010342a:	89 e5                	mov    %esp,%ebp
8010342c:	8b 45 08             	mov    0x8(%ebp),%eax
8010342f:	05 00 00 00 80       	add    $0x80000000,%eax
80103434:	5d                   	pop    %ebp
80103435:	c3                   	ret    

80103436 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103436:	55                   	push   %ebp
80103437:	89 e5                	mov    %esp,%ebp
80103439:	53                   	push   %ebx
8010343a:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
8010343d:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103440:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103443:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103446:	89 c3                	mov    %eax,%ebx
80103448:	89 d8                	mov    %ebx,%eax
8010344a:	f0 87 02             	lock xchg %eax,(%edx)
8010344d:	89 c3                	mov    %eax,%ebx
8010344f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103452:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103455:	83 c4 10             	add    $0x10,%esp
80103458:	5b                   	pop    %ebx
80103459:	5d                   	pop    %ebp
8010345a:	c3                   	ret    

8010345b <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010345b:	55                   	push   %ebp
8010345c:	89 e5                	mov    %esp,%ebp
8010345e:	83 e4 f0             	and    $0xfffffff0,%esp
80103461:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103464:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
8010346b:	80 
8010346c:	c7 04 24 fc 2b 11 80 	movl   $0x80112bfc,(%esp)
80103473:	e8 ad f5 ff ff       	call   80102a25 <kinit1>
  kvmalloc();      // kernel page table
80103478:	e8 75 46 00 00       	call   80107af2 <kvmalloc>
  mpinit();        // collect info about this machine
8010347d:	e8 63 04 00 00       	call   801038e5 <mpinit>
  lapicinit(mpbcpu());
80103482:	e8 2e 02 00 00       	call   801036b5 <mpbcpu>
80103487:	89 04 24             	mov    %eax,(%esp)
8010348a:	e8 f5 f8 ff ff       	call   80102d84 <lapicinit>
  seginit();       // set up segments
8010348f:	e8 01 40 00 00       	call   80107495 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103494:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010349a:	0f b6 00             	movzbl (%eax),%eax
8010349d:	0f b6 c0             	movzbl %al,%eax
801034a0:	89 44 24 04          	mov    %eax,0x4(%esp)
801034a4:	c7 04 24 d9 84 10 80 	movl   $0x801084d9,(%esp)
801034ab:	e8 f1 ce ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
801034b0:	e8 95 06 00 00       	call   80103b4a <picinit>
  ioapicinit();    // another interrupt controller
801034b5:	e8 5b f4 ff ff       	call   80102915 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
801034ba:	e8 ce d5 ff ff       	call   80100a8d <consoleinit>
  uartinit();      // serial port
801034bf:	e8 1c 33 00 00       	call   801067e0 <uartinit>
  pinit();         // process table
801034c4:	e8 fe 0b 00 00       	call   801040c7 <pinit>
  tvinit();        // trap vectors
801034c9:	e8 b5 2e 00 00       	call   80106383 <tvinit>
  binit();         // buffer cache
801034ce:	e8 61 cb ff ff       	call   80100034 <binit>
  fileinit();      // file table
801034d3:	e8 7c da ff ff       	call   80100f54 <fileinit>
  iinit();         // inode cache
801034d8:	e8 2a e1 ff ff       	call   80101607 <iinit>
  ideinit();       // disk
801034dd:	e8 98 f0 ff ff       	call   8010257a <ideinit>
  if(!ismp)
801034e2:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
801034e7:	85 c0                	test   %eax,%eax
801034e9:	75 05                	jne    801034f0 <main+0x95>
    timerinit();   // uniprocessor timer
801034eb:	e8 d6 2d 00 00       	call   801062c6 <timerinit>
  startothers();   // start other processors
801034f0:	e8 87 00 00 00       	call   8010357c <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801034f5:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
801034fc:	8e 
801034fd:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103504:	e8 54 f5 ff ff       	call   80102a5d <kinit2>
  userinit();      // first user process
80103509:	e8 d4 0c 00 00       	call   801041e2 <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
8010350e:	e8 22 00 00 00       	call   80103535 <mpmain>

80103513 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103513:	55                   	push   %ebp
80103514:	89 e5                	mov    %esp,%ebp
80103516:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103519:	e8 eb 45 00 00       	call   80107b09 <switchkvm>
  seginit();
8010351e:	e8 72 3f 00 00       	call   80107495 <seginit>
  lapicinit(cpunum());
80103523:	e8 b9 f9 ff ff       	call   80102ee1 <cpunum>
80103528:	89 04 24             	mov    %eax,(%esp)
8010352b:	e8 54 f8 ff ff       	call   80102d84 <lapicinit>
  mpmain();
80103530:	e8 00 00 00 00       	call   80103535 <mpmain>

80103535 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103535:	55                   	push   %ebp
80103536:	89 e5                	mov    %esp,%ebp
80103538:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
8010353b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103541:	0f b6 00             	movzbl (%eax),%eax
80103544:	0f b6 c0             	movzbl %al,%eax
80103547:	89 44 24 04          	mov    %eax,0x4(%esp)
8010354b:	c7 04 24 f0 84 10 80 	movl   $0x801084f0,(%esp)
80103552:	e8 4a ce ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103557:	e8 9b 2f 00 00       	call   801064f7 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
8010355c:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103562:	05 a8 00 00 00       	add    $0xa8,%eax
80103567:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010356e:	00 
8010356f:	89 04 24             	mov    %eax,(%esp)
80103572:	e8 bf fe ff ff       	call   80103436 <xchg>
  scheduler();     // start running processes
80103577:	e8 5c 12 00 00       	call   801047d8 <scheduler>

8010357c <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
8010357c:	55                   	push   %ebp
8010357d:	89 e5                	mov    %esp,%ebp
8010357f:	53                   	push   %ebx
80103580:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103583:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
8010358a:	e8 9a fe ff ff       	call   80103429 <p2v>
8010358f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103592:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103597:	89 44 24 08          	mov    %eax,0x8(%esp)
8010359b:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
801035a2:	80 
801035a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035a6:	89 04 24             	mov    %eax,(%esp)
801035a9:	e8 d3 19 00 00       	call   80104f81 <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
801035ae:	c7 45 f4 20 fe 10 80 	movl   $0x8010fe20,-0xc(%ebp)
801035b5:	e9 86 00 00 00       	jmp    80103640 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
801035ba:	e8 22 f9 ff ff       	call   80102ee1 <cpunum>
801035bf:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801035c5:	05 20 fe 10 80       	add    $0x8010fe20,%eax
801035ca:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801035cd:	74 69                	je     80103638 <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
801035cf:	e8 7f f5 ff ff       	call   80102b53 <kalloc>
801035d4:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
801035d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035da:	83 e8 04             	sub    $0x4,%eax
801035dd:	8b 55 ec             	mov    -0x14(%ebp),%edx
801035e0:	81 c2 00 10 00 00    	add    $0x1000,%edx
801035e6:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
801035e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035eb:	83 e8 08             	sub    $0x8,%eax
801035ee:	c7 00 13 35 10 80    	movl   $0x80103513,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
801035f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801035f7:	8d 58 f4             	lea    -0xc(%eax),%ebx
801035fa:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103601:	e8 16 fe ff ff       	call   8010341c <v2p>
80103606:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103608:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010360b:	89 04 24             	mov    %eax,(%esp)
8010360e:	e8 09 fe ff ff       	call   8010341c <v2p>
80103613:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103616:	0f b6 12             	movzbl (%edx),%edx
80103619:	0f b6 d2             	movzbl %dl,%edx
8010361c:	89 44 24 04          	mov    %eax,0x4(%esp)
80103620:	89 14 24             	mov    %edx,(%esp)
80103623:	e8 3f f9 ff ff       	call   80102f67 <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103628:	90                   	nop
80103629:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010362c:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103632:	85 c0                	test   %eax,%eax
80103634:	74 f3                	je     80103629 <startothers+0xad>
80103636:	eb 01                	jmp    80103639 <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103638:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103639:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103640:	a1 00 04 11 80       	mov    0x80110400,%eax
80103645:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
8010364b:	05 20 fe 10 80       	add    $0x8010fe20,%eax
80103650:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103653:	0f 87 61 ff ff ff    	ja     801035ba <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103659:	83 c4 24             	add    $0x24,%esp
8010365c:	5b                   	pop    %ebx
8010365d:	5d                   	pop    %ebp
8010365e:	c3                   	ret    
	...

80103660 <p2v>:
80103660:	55                   	push   %ebp
80103661:	89 e5                	mov    %esp,%ebp
80103663:	8b 45 08             	mov    0x8(%ebp),%eax
80103666:	05 00 00 00 80       	add    $0x80000000,%eax
8010366b:	5d                   	pop    %ebp
8010366c:	c3                   	ret    

8010366d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010366d:	55                   	push   %ebp
8010366e:	89 e5                	mov    %esp,%ebp
80103670:	53                   	push   %ebx
80103671:	83 ec 14             	sub    $0x14,%esp
80103674:	8b 45 08             	mov    0x8(%ebp),%eax
80103677:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010367b:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
8010367f:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103683:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103687:	ec                   	in     (%dx),%al
80103688:	89 c3                	mov    %eax,%ebx
8010368a:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
8010368d:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103691:	83 c4 14             	add    $0x14,%esp
80103694:	5b                   	pop    %ebx
80103695:	5d                   	pop    %ebp
80103696:	c3                   	ret    

80103697 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103697:	55                   	push   %ebp
80103698:	89 e5                	mov    %esp,%ebp
8010369a:	83 ec 08             	sub    $0x8,%esp
8010369d:	8b 55 08             	mov    0x8(%ebp),%edx
801036a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801036a3:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801036a7:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801036aa:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801036ae:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801036b2:	ee                   	out    %al,(%dx)
}
801036b3:	c9                   	leave  
801036b4:	c3                   	ret    

801036b5 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
801036b5:	55                   	push   %ebp
801036b6:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
801036b8:	a1 44 b6 10 80       	mov    0x8010b644,%eax
801036bd:	89 c2                	mov    %eax,%edx
801036bf:	b8 20 fe 10 80       	mov    $0x8010fe20,%eax
801036c4:	89 d1                	mov    %edx,%ecx
801036c6:	29 c1                	sub    %eax,%ecx
801036c8:	89 c8                	mov    %ecx,%eax
801036ca:	c1 f8 02             	sar    $0x2,%eax
801036cd:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
801036d3:	5d                   	pop    %ebp
801036d4:	c3                   	ret    

801036d5 <sum>:

static uchar
sum(uchar *addr, int len)
{
801036d5:	55                   	push   %ebp
801036d6:	89 e5                	mov    %esp,%ebp
801036d8:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
801036db:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
801036e2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801036e9:	eb 13                	jmp    801036fe <sum+0x29>
    sum += addr[i];
801036eb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801036ee:	03 45 08             	add    0x8(%ebp),%eax
801036f1:	0f b6 00             	movzbl (%eax),%eax
801036f4:	0f b6 c0             	movzbl %al,%eax
801036f7:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
801036fa:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801036fe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103701:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103704:	7c e5                	jl     801036eb <sum+0x16>
    sum += addr[i];
  return sum;
80103706:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103709:	c9                   	leave  
8010370a:	c3                   	ret    

8010370b <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
8010370b:	55                   	push   %ebp
8010370c:	89 e5                	mov    %esp,%ebp
8010370e:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103711:	8b 45 08             	mov    0x8(%ebp),%eax
80103714:	89 04 24             	mov    %eax,(%esp)
80103717:	e8 44 ff ff ff       	call   80103660 <p2v>
8010371c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
8010371f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103722:	03 45 f0             	add    -0x10(%ebp),%eax
80103725:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103728:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010372b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010372e:	eb 3f                	jmp    8010376f <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103730:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103737:	00 
80103738:	c7 44 24 04 04 85 10 	movl   $0x80108504,0x4(%esp)
8010373f:	80 
80103740:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103743:	89 04 24             	mov    %eax,(%esp)
80103746:	e8 da 17 00 00       	call   80104f25 <memcmp>
8010374b:	85 c0                	test   %eax,%eax
8010374d:	75 1c                	jne    8010376b <mpsearch1+0x60>
8010374f:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103756:	00 
80103757:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010375a:	89 04 24             	mov    %eax,(%esp)
8010375d:	e8 73 ff ff ff       	call   801036d5 <sum>
80103762:	84 c0                	test   %al,%al
80103764:	75 05                	jne    8010376b <mpsearch1+0x60>
      return (struct mp*)p;
80103766:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103769:	eb 11                	jmp    8010377c <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
8010376b:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010376f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103772:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103775:	72 b9                	jb     80103730 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103777:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010377c:	c9                   	leave  
8010377d:	c3                   	ret    

8010377e <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
8010377e:	55                   	push   %ebp
8010377f:	89 e5                	mov    %esp,%ebp
80103781:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103784:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
8010378b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010378e:	83 c0 0f             	add    $0xf,%eax
80103791:	0f b6 00             	movzbl (%eax),%eax
80103794:	0f b6 c0             	movzbl %al,%eax
80103797:	89 c2                	mov    %eax,%edx
80103799:	c1 e2 08             	shl    $0x8,%edx
8010379c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010379f:	83 c0 0e             	add    $0xe,%eax
801037a2:	0f b6 00             	movzbl (%eax),%eax
801037a5:	0f b6 c0             	movzbl %al,%eax
801037a8:	09 d0                	or     %edx,%eax
801037aa:	c1 e0 04             	shl    $0x4,%eax
801037ad:	89 45 f0             	mov    %eax,-0x10(%ebp)
801037b0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801037b4:	74 21                	je     801037d7 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
801037b6:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
801037bd:	00 
801037be:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037c1:	89 04 24             	mov    %eax,(%esp)
801037c4:	e8 42 ff ff ff       	call   8010370b <mpsearch1>
801037c9:	89 45 ec             	mov    %eax,-0x14(%ebp)
801037cc:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801037d0:	74 50                	je     80103822 <mpsearch+0xa4>
      return mp;
801037d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037d5:	eb 5f                	jmp    80103836 <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
801037d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037da:	83 c0 14             	add    $0x14,%eax
801037dd:	0f b6 00             	movzbl (%eax),%eax
801037e0:	0f b6 c0             	movzbl %al,%eax
801037e3:	89 c2                	mov    %eax,%edx
801037e5:	c1 e2 08             	shl    $0x8,%edx
801037e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037eb:	83 c0 13             	add    $0x13,%eax
801037ee:	0f b6 00             	movzbl (%eax),%eax
801037f1:	0f b6 c0             	movzbl %al,%eax
801037f4:	09 d0                	or     %edx,%eax
801037f6:	c1 e0 0a             	shl    $0xa,%eax
801037f9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
801037fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037ff:	2d 00 04 00 00       	sub    $0x400,%eax
80103804:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
8010380b:	00 
8010380c:	89 04 24             	mov    %eax,(%esp)
8010380f:	e8 f7 fe ff ff       	call   8010370b <mpsearch1>
80103814:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103817:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
8010381b:	74 05                	je     80103822 <mpsearch+0xa4>
      return mp;
8010381d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103820:	eb 14                	jmp    80103836 <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103822:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103829:	00 
8010382a:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103831:	e8 d5 fe ff ff       	call   8010370b <mpsearch1>
}
80103836:	c9                   	leave  
80103837:	c3                   	ret    

80103838 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103838:	55                   	push   %ebp
80103839:	89 e5                	mov    %esp,%ebp
8010383b:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
8010383e:	e8 3b ff ff ff       	call   8010377e <mpsearch>
80103843:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103846:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010384a:	74 0a                	je     80103856 <mpconfig+0x1e>
8010384c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010384f:	8b 40 04             	mov    0x4(%eax),%eax
80103852:	85 c0                	test   %eax,%eax
80103854:	75 0a                	jne    80103860 <mpconfig+0x28>
    return 0;
80103856:	b8 00 00 00 00       	mov    $0x0,%eax
8010385b:	e9 83 00 00 00       	jmp    801038e3 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103860:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103863:	8b 40 04             	mov    0x4(%eax),%eax
80103866:	89 04 24             	mov    %eax,(%esp)
80103869:	e8 f2 fd ff ff       	call   80103660 <p2v>
8010386e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103871:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103878:	00 
80103879:	c7 44 24 04 09 85 10 	movl   $0x80108509,0x4(%esp)
80103880:	80 
80103881:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103884:	89 04 24             	mov    %eax,(%esp)
80103887:	e8 99 16 00 00       	call   80104f25 <memcmp>
8010388c:	85 c0                	test   %eax,%eax
8010388e:	74 07                	je     80103897 <mpconfig+0x5f>
    return 0;
80103890:	b8 00 00 00 00       	mov    $0x0,%eax
80103895:	eb 4c                	jmp    801038e3 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103897:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010389a:	0f b6 40 06          	movzbl 0x6(%eax),%eax
8010389e:	3c 01                	cmp    $0x1,%al
801038a0:	74 12                	je     801038b4 <mpconfig+0x7c>
801038a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038a5:	0f b6 40 06          	movzbl 0x6(%eax),%eax
801038a9:	3c 04                	cmp    $0x4,%al
801038ab:	74 07                	je     801038b4 <mpconfig+0x7c>
    return 0;
801038ad:	b8 00 00 00 00       	mov    $0x0,%eax
801038b2:	eb 2f                	jmp    801038e3 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
801038b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038b7:	0f b7 40 04          	movzwl 0x4(%eax),%eax
801038bb:	0f b7 c0             	movzwl %ax,%eax
801038be:	89 44 24 04          	mov    %eax,0x4(%esp)
801038c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801038c5:	89 04 24             	mov    %eax,(%esp)
801038c8:	e8 08 fe ff ff       	call   801036d5 <sum>
801038cd:	84 c0                	test   %al,%al
801038cf:	74 07                	je     801038d8 <mpconfig+0xa0>
    return 0;
801038d1:	b8 00 00 00 00       	mov    $0x0,%eax
801038d6:	eb 0b                	jmp    801038e3 <mpconfig+0xab>
  *pmp = mp;
801038d8:	8b 45 08             	mov    0x8(%ebp),%eax
801038db:	8b 55 f4             	mov    -0xc(%ebp),%edx
801038de:	89 10                	mov    %edx,(%eax)
  return conf;
801038e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801038e3:	c9                   	leave  
801038e4:	c3                   	ret    

801038e5 <mpinit>:

void
mpinit(void)
{
801038e5:	55                   	push   %ebp
801038e6:	89 e5                	mov    %esp,%ebp
801038e8:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
801038eb:	c7 05 44 b6 10 80 20 	movl   $0x8010fe20,0x8010b644
801038f2:	fe 10 80 
  if((conf = mpconfig(&mp)) == 0)
801038f5:	8d 45 e0             	lea    -0x20(%ebp),%eax
801038f8:	89 04 24             	mov    %eax,(%esp)
801038fb:	e8 38 ff ff ff       	call   80103838 <mpconfig>
80103900:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103903:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103907:	0f 84 9c 01 00 00    	je     80103aa9 <mpinit+0x1c4>
    return;
  ismp = 1;
8010390d:	c7 05 04 fe 10 80 01 	movl   $0x1,0x8010fe04
80103914:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103917:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010391a:	8b 40 24             	mov    0x24(%eax),%eax
8010391d:	a3 7c fd 10 80       	mov    %eax,0x8010fd7c
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103922:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103925:	83 c0 2c             	add    $0x2c,%eax
80103928:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010392b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010392e:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103932:	0f b7 c0             	movzwl %ax,%eax
80103935:	03 45 f0             	add    -0x10(%ebp),%eax
80103938:	89 45 ec             	mov    %eax,-0x14(%ebp)
8010393b:	e9 f4 00 00 00       	jmp    80103a34 <mpinit+0x14f>
    switch(*p){
80103940:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103943:	0f b6 00             	movzbl (%eax),%eax
80103946:	0f b6 c0             	movzbl %al,%eax
80103949:	83 f8 04             	cmp    $0x4,%eax
8010394c:	0f 87 bf 00 00 00    	ja     80103a11 <mpinit+0x12c>
80103952:	8b 04 85 4c 85 10 80 	mov    -0x7fef7ab4(,%eax,4),%eax
80103959:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
8010395b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010395e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103961:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103964:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103968:	0f b6 d0             	movzbl %al,%edx
8010396b:	a1 00 04 11 80       	mov    0x80110400,%eax
80103970:	39 c2                	cmp    %eax,%edx
80103972:	74 2d                	je     801039a1 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103974:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103977:	0f b6 40 01          	movzbl 0x1(%eax),%eax
8010397b:	0f b6 d0             	movzbl %al,%edx
8010397e:	a1 00 04 11 80       	mov    0x80110400,%eax
80103983:	89 54 24 08          	mov    %edx,0x8(%esp)
80103987:	89 44 24 04          	mov    %eax,0x4(%esp)
8010398b:	c7 04 24 0e 85 10 80 	movl   $0x8010850e,(%esp)
80103992:	e8 0a ca ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103997:	c7 05 04 fe 10 80 00 	movl   $0x0,0x8010fe04
8010399e:	00 00 00 
      }
      if(proc->flags & MPBOOT)
801039a1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801039a4:	0f b6 40 03          	movzbl 0x3(%eax),%eax
801039a8:	0f b6 c0             	movzbl %al,%eax
801039ab:	83 e0 02             	and    $0x2,%eax
801039ae:	85 c0                	test   %eax,%eax
801039b0:	74 15                	je     801039c7 <mpinit+0xe2>
        bcpu = &cpus[ncpu];
801039b2:	a1 00 04 11 80       	mov    0x80110400,%eax
801039b7:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801039bd:	05 20 fe 10 80       	add    $0x8010fe20,%eax
801039c2:	a3 44 b6 10 80       	mov    %eax,0x8010b644
      cpus[ncpu].id = ncpu;
801039c7:	8b 15 00 04 11 80    	mov    0x80110400,%edx
801039cd:	a1 00 04 11 80       	mov    0x80110400,%eax
801039d2:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
801039d8:	81 c2 20 fe 10 80    	add    $0x8010fe20,%edx
801039de:	88 02                	mov    %al,(%edx)
      ncpu++;
801039e0:	a1 00 04 11 80       	mov    0x80110400,%eax
801039e5:	83 c0 01             	add    $0x1,%eax
801039e8:	a3 00 04 11 80       	mov    %eax,0x80110400
      p += sizeof(struct mpproc);
801039ed:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
801039f1:	eb 41                	jmp    80103a34 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
801039f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039f6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
801039f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801039fc:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103a00:	a2 00 fe 10 80       	mov    %al,0x8010fe00
      p += sizeof(struct mpioapic);
80103a05:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103a09:	eb 29                	jmp    80103a34 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103a0b:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103a0f:	eb 23                	jmp    80103a34 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80103a11:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a14:	0f b6 00             	movzbl (%eax),%eax
80103a17:	0f b6 c0             	movzbl %al,%eax
80103a1a:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a1e:	c7 04 24 2c 85 10 80 	movl   $0x8010852c,(%esp)
80103a25:	e8 77 c9 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
80103a2a:	c7 05 04 fe 10 80 00 	movl   $0x0,0x8010fe04
80103a31:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103a34:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103a37:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103a3a:	0f 82 00 ff ff ff    	jb     80103940 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80103a40:	a1 04 fe 10 80       	mov    0x8010fe04,%eax
80103a45:	85 c0                	test   %eax,%eax
80103a47:	75 1d                	jne    80103a66 <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
80103a49:	c7 05 00 04 11 80 01 	movl   $0x1,0x80110400
80103a50:	00 00 00 
    lapic = 0;
80103a53:	c7 05 7c fd 10 80 00 	movl   $0x0,0x8010fd7c
80103a5a:	00 00 00 
    ioapicid = 0;
80103a5d:	c6 05 00 fe 10 80 00 	movb   $0x0,0x8010fe00
    return;
80103a64:	eb 44                	jmp    80103aaa <mpinit+0x1c5>
  }

  if(mp->imcrp){
80103a66:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103a69:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103a6d:	84 c0                	test   %al,%al
80103a6f:	74 39                	je     80103aaa <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103a71:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
80103a78:	00 
80103a79:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
80103a80:	e8 12 fc ff ff       	call   80103697 <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103a85:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103a8c:	e8 dc fb ff ff       	call   8010366d <inb>
80103a91:	83 c8 01             	or     $0x1,%eax
80103a94:	0f b6 c0             	movzbl %al,%eax
80103a97:	89 44 24 04          	mov    %eax,0x4(%esp)
80103a9b:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
80103aa2:	e8 f0 fb ff ff       	call   80103697 <outb>
80103aa7:	eb 01                	jmp    80103aaa <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
80103aa9:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
80103aaa:	c9                   	leave  
80103aab:	c3                   	ret    

80103aac <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103aac:	55                   	push   %ebp
80103aad:	89 e5                	mov    %esp,%ebp
80103aaf:	83 ec 08             	sub    $0x8,%esp
80103ab2:	8b 55 08             	mov    0x8(%ebp),%edx
80103ab5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ab8:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103abc:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103abf:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103ac3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103ac7:	ee                   	out    %al,(%dx)
}
80103ac8:	c9                   	leave  
80103ac9:	c3                   	ret    

80103aca <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
80103aca:	55                   	push   %ebp
80103acb:	89 e5                	mov    %esp,%ebp
80103acd:	83 ec 0c             	sub    $0xc,%esp
80103ad0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ad3:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
80103ad7:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103adb:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80103ae1:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103ae5:	0f b6 c0             	movzbl %al,%eax
80103ae8:	89 44 24 04          	mov    %eax,0x4(%esp)
80103aec:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103af3:	e8 b4 ff ff ff       	call   80103aac <outb>
  outb(IO_PIC2+1, mask >> 8);
80103af8:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80103afc:	66 c1 e8 08          	shr    $0x8,%ax
80103b00:	0f b6 c0             	movzbl %al,%eax
80103b03:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b07:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b0e:	e8 99 ff ff ff       	call   80103aac <outb>
}
80103b13:	c9                   	leave  
80103b14:	c3                   	ret    

80103b15 <picenable>:

void
picenable(int irq)
{
80103b15:	55                   	push   %ebp
80103b16:	89 e5                	mov    %esp,%ebp
80103b18:	53                   	push   %ebx
80103b19:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80103b1c:	8b 45 08             	mov    0x8(%ebp),%eax
80103b1f:	ba 01 00 00 00       	mov    $0x1,%edx
80103b24:	89 d3                	mov    %edx,%ebx
80103b26:	89 c1                	mov    %eax,%ecx
80103b28:	d3 e3                	shl    %cl,%ebx
80103b2a:	89 d8                	mov    %ebx,%eax
80103b2c:	89 c2                	mov    %eax,%edx
80103b2e:	f7 d2                	not    %edx
80103b30:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103b37:	21 d0                	and    %edx,%eax
80103b39:	0f b7 c0             	movzwl %ax,%eax
80103b3c:	89 04 24             	mov    %eax,(%esp)
80103b3f:	e8 86 ff ff ff       	call   80103aca <picsetmask>
}
80103b44:	83 c4 04             	add    $0x4,%esp
80103b47:	5b                   	pop    %ebx
80103b48:	5d                   	pop    %ebp
80103b49:	c3                   	ret    

80103b4a <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
80103b4a:	55                   	push   %ebp
80103b4b:	89 e5                	mov    %esp,%ebp
80103b4d:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103b50:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b57:	00 
80103b58:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b5f:	e8 48 ff ff ff       	call   80103aac <outb>
  outb(IO_PIC2+1, 0xFF);
80103b64:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
80103b6b:	00 
80103b6c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103b73:	e8 34 ff ff ff       	call   80103aac <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
80103b78:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103b7f:	00 
80103b80:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103b87:	e8 20 ff ff ff       	call   80103aac <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
80103b8c:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80103b93:	00 
80103b94:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103b9b:	e8 0c ff ff ff       	call   80103aac <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
80103ba0:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
80103ba7:	00 
80103ba8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103baf:	e8 f8 fe ff ff       	call   80103aac <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
80103bb4:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103bbb:	00 
80103bbc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80103bc3:	e8 e4 fe ff ff       	call   80103aac <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
80103bc8:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
80103bcf:	00 
80103bd0:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103bd7:	e8 d0 fe ff ff       	call   80103aac <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80103bdc:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80103be3:	00 
80103be4:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103beb:	e8 bc fe ff ff       	call   80103aac <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80103bf0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80103bf7:	00 
80103bf8:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103bff:	e8 a8 fe ff ff       	call   80103aac <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80103c04:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80103c0b:	00 
80103c0c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80103c13:	e8 94 fe ff ff       	call   80103aac <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
80103c18:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103c1f:	00 
80103c20:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c27:	e8 80 fe ff ff       	call   80103aac <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80103c2c:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c33:	00 
80103c34:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
80103c3b:	e8 6c fe ff ff       	call   80103aac <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80103c40:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80103c47:	00 
80103c48:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c4f:	e8 58 fe ff ff       	call   80103aac <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80103c54:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80103c5b:	00 
80103c5c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103c63:	e8 44 fe ff ff       	call   80103aac <outb>

  if(irqmask != 0xFFFF)
80103c68:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c6f:	66 83 f8 ff          	cmp    $0xffff,%ax
80103c73:	74 12                	je     80103c87 <picinit+0x13d>
    picsetmask(irqmask);
80103c75:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80103c7c:	0f b7 c0             	movzwl %ax,%eax
80103c7f:	89 04 24             	mov    %eax,(%esp)
80103c82:	e8 43 fe ff ff       	call   80103aca <picsetmask>
}
80103c87:	c9                   	leave  
80103c88:	c3                   	ret    
80103c89:	00 00                	add    %al,(%eax)
	...

80103c8c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103c8c:	55                   	push   %ebp
80103c8d:	89 e5                	mov    %esp,%ebp
80103c8f:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
80103c92:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103c99:	8b 45 0c             	mov    0xc(%ebp),%eax
80103c9c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103ca2:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ca5:	8b 10                	mov    (%eax),%edx
80103ca7:	8b 45 08             	mov    0x8(%ebp),%eax
80103caa:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103cac:	e8 bf d2 ff ff       	call   80100f70 <filealloc>
80103cb1:	8b 55 08             	mov    0x8(%ebp),%edx
80103cb4:	89 02                	mov    %eax,(%edx)
80103cb6:	8b 45 08             	mov    0x8(%ebp),%eax
80103cb9:	8b 00                	mov    (%eax),%eax
80103cbb:	85 c0                	test   %eax,%eax
80103cbd:	0f 84 c8 00 00 00    	je     80103d8b <pipealloc+0xff>
80103cc3:	e8 a8 d2 ff ff       	call   80100f70 <filealloc>
80103cc8:	8b 55 0c             	mov    0xc(%ebp),%edx
80103ccb:	89 02                	mov    %eax,(%edx)
80103ccd:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cd0:	8b 00                	mov    (%eax),%eax
80103cd2:	85 c0                	test   %eax,%eax
80103cd4:	0f 84 b1 00 00 00    	je     80103d8b <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103cda:	e8 74 ee ff ff       	call   80102b53 <kalloc>
80103cdf:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103ce2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ce6:	0f 84 9e 00 00 00    	je     80103d8a <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80103cec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cef:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103cf6:	00 00 00 
  p->writeopen = 1;
80103cf9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cfc:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103d03:	00 00 00 
  p->nwrite = 0;
80103d06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d09:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103d10:	00 00 00 
  p->nread = 0;
80103d13:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d16:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103d1d:	00 00 00 
  initlock(&p->lock, "pipe");
80103d20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d23:	c7 44 24 04 60 85 10 	movl   $0x80108560,0x4(%esp)
80103d2a:	80 
80103d2b:	89 04 24             	mov    %eax,(%esp)
80103d2e:	e8 0b 0f 00 00       	call   80104c3e <initlock>
  (*f0)->type = FD_PIPE;
80103d33:	8b 45 08             	mov    0x8(%ebp),%eax
80103d36:	8b 00                	mov    (%eax),%eax
80103d38:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103d3e:	8b 45 08             	mov    0x8(%ebp),%eax
80103d41:	8b 00                	mov    (%eax),%eax
80103d43:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103d47:	8b 45 08             	mov    0x8(%ebp),%eax
80103d4a:	8b 00                	mov    (%eax),%eax
80103d4c:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103d50:	8b 45 08             	mov    0x8(%ebp),%eax
80103d53:	8b 00                	mov    (%eax),%eax
80103d55:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d58:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103d5b:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d5e:	8b 00                	mov    (%eax),%eax
80103d60:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103d66:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d69:	8b 00                	mov    (%eax),%eax
80103d6b:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103d6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d72:	8b 00                	mov    (%eax),%eax
80103d74:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103d78:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d7b:	8b 00                	mov    (%eax),%eax
80103d7d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103d80:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103d83:	b8 00 00 00 00       	mov    $0x0,%eax
80103d88:	eb 43                	jmp    80103dcd <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103d8a:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103d8b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103d8f:	74 0b                	je     80103d9c <pipealloc+0x110>
    kfree((char*)p);
80103d91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d94:	89 04 24             	mov    %eax,(%esp)
80103d97:	e8 1e ed ff ff       	call   80102aba <kfree>
  if(*f0)
80103d9c:	8b 45 08             	mov    0x8(%ebp),%eax
80103d9f:	8b 00                	mov    (%eax),%eax
80103da1:	85 c0                	test   %eax,%eax
80103da3:	74 0d                	je     80103db2 <pipealloc+0x126>
    fileclose(*f0);
80103da5:	8b 45 08             	mov    0x8(%ebp),%eax
80103da8:	8b 00                	mov    (%eax),%eax
80103daa:	89 04 24             	mov    %eax,(%esp)
80103dad:	e8 66 d2 ff ff       	call   80101018 <fileclose>
  if(*f1)
80103db2:	8b 45 0c             	mov    0xc(%ebp),%eax
80103db5:	8b 00                	mov    (%eax),%eax
80103db7:	85 c0                	test   %eax,%eax
80103db9:	74 0d                	je     80103dc8 <pipealloc+0x13c>
    fileclose(*f1);
80103dbb:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dbe:	8b 00                	mov    (%eax),%eax
80103dc0:	89 04 24             	mov    %eax,(%esp)
80103dc3:	e8 50 d2 ff ff       	call   80101018 <fileclose>
  return -1;
80103dc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103dcd:	c9                   	leave  
80103dce:	c3                   	ret    

80103dcf <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103dcf:	55                   	push   %ebp
80103dd0:	89 e5                	mov    %esp,%ebp
80103dd2:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
80103dd5:	8b 45 08             	mov    0x8(%ebp),%eax
80103dd8:	89 04 24             	mov    %eax,(%esp)
80103ddb:	e8 7f 0e 00 00       	call   80104c5f <acquire>
  if(writable){
80103de0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103de4:	74 1f                	je     80103e05 <pipeclose+0x36>
    p->writeopen = 0;
80103de6:	8b 45 08             	mov    0x8(%ebp),%eax
80103de9:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103df0:	00 00 00 
    wakeup(&p->nread);
80103df3:	8b 45 08             	mov    0x8(%ebp),%eax
80103df6:	05 34 02 00 00       	add    $0x234,%eax
80103dfb:	89 04 24             	mov    %eax,(%esp)
80103dfe:	e8 57 0c 00 00       	call   80104a5a <wakeup>
80103e03:	eb 1d                	jmp    80103e22 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80103e05:	8b 45 08             	mov    0x8(%ebp),%eax
80103e08:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103e0f:	00 00 00 
    wakeup(&p->nwrite);
80103e12:	8b 45 08             	mov    0x8(%ebp),%eax
80103e15:	05 38 02 00 00       	add    $0x238,%eax
80103e1a:	89 04 24             	mov    %eax,(%esp)
80103e1d:	e8 38 0c 00 00       	call   80104a5a <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103e22:	8b 45 08             	mov    0x8(%ebp),%eax
80103e25:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e2b:	85 c0                	test   %eax,%eax
80103e2d:	75 25                	jne    80103e54 <pipeclose+0x85>
80103e2f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e32:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103e38:	85 c0                	test   %eax,%eax
80103e3a:	75 18                	jne    80103e54 <pipeclose+0x85>
    release(&p->lock);
80103e3c:	8b 45 08             	mov    0x8(%ebp),%eax
80103e3f:	89 04 24             	mov    %eax,(%esp)
80103e42:	e8 7a 0e 00 00       	call   80104cc1 <release>
    kfree((char*)p);
80103e47:	8b 45 08             	mov    0x8(%ebp),%eax
80103e4a:	89 04 24             	mov    %eax,(%esp)
80103e4d:	e8 68 ec ff ff       	call   80102aba <kfree>
80103e52:	eb 0b                	jmp    80103e5f <pipeclose+0x90>
  } else
    release(&p->lock);
80103e54:	8b 45 08             	mov    0x8(%ebp),%eax
80103e57:	89 04 24             	mov    %eax,(%esp)
80103e5a:	e8 62 0e 00 00       	call   80104cc1 <release>
}
80103e5f:	c9                   	leave  
80103e60:	c3                   	ret    

80103e61 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103e61:	55                   	push   %ebp
80103e62:	89 e5                	mov    %esp,%ebp
80103e64:	53                   	push   %ebx
80103e65:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103e68:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6b:	89 04 24             	mov    %eax,(%esp)
80103e6e:	e8 ec 0d 00 00       	call   80104c5f <acquire>
  for(i = 0; i < n; i++){
80103e73:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103e7a:	e9 a6 00 00 00       	jmp    80103f25 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
80103e7f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e82:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103e88:	85 c0                	test   %eax,%eax
80103e8a:	74 0d                	je     80103e99 <pipewrite+0x38>
80103e8c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103e92:	8b 40 24             	mov    0x24(%eax),%eax
80103e95:	85 c0                	test   %eax,%eax
80103e97:	74 15                	je     80103eae <pipewrite+0x4d>
        release(&p->lock);
80103e99:	8b 45 08             	mov    0x8(%ebp),%eax
80103e9c:	89 04 24             	mov    %eax,(%esp)
80103e9f:	e8 1d 0e 00 00       	call   80104cc1 <release>
        return -1;
80103ea4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103ea9:	e9 9d 00 00 00       	jmp    80103f4b <pipewrite+0xea>
      }
      wakeup(&p->nread);
80103eae:	8b 45 08             	mov    0x8(%ebp),%eax
80103eb1:	05 34 02 00 00       	add    $0x234,%eax
80103eb6:	89 04 24             	mov    %eax,(%esp)
80103eb9:	e8 9c 0b 00 00       	call   80104a5a <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80103ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80103ec1:	8b 55 08             	mov    0x8(%ebp),%edx
80103ec4:	81 c2 38 02 00 00    	add    $0x238,%edx
80103eca:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ece:	89 14 24             	mov    %edx,(%esp)
80103ed1:	e8 ab 0a 00 00       	call   80104981 <sleep>
80103ed6:	eb 01                	jmp    80103ed9 <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
80103ed8:	90                   	nop
80103ed9:	8b 45 08             	mov    0x8(%ebp),%eax
80103edc:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80103ee2:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee5:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103eeb:	05 00 02 00 00       	add    $0x200,%eax
80103ef0:	39 c2                	cmp    %eax,%edx
80103ef2:	74 8b                	je     80103e7f <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80103ef4:	8b 45 08             	mov    0x8(%ebp),%eax
80103ef7:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103efd:	89 c3                	mov    %eax,%ebx
80103eff:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103f05:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f08:	03 55 0c             	add    0xc(%ebp),%edx
80103f0b:	0f b6 0a             	movzbl (%edx),%ecx
80103f0e:	8b 55 08             	mov    0x8(%ebp),%edx
80103f11:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80103f15:	8d 50 01             	lea    0x1(%eax),%edx
80103f18:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1b:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80103f21:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103f25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f28:	3b 45 10             	cmp    0x10(%ebp),%eax
80103f2b:	7c ab                	jl     80103ed8 <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80103f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f30:	05 34 02 00 00       	add    $0x234,%eax
80103f35:	89 04 24             	mov    %eax,(%esp)
80103f38:	e8 1d 0b 00 00       	call   80104a5a <wakeup>
  release(&p->lock);
80103f3d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f40:	89 04 24             	mov    %eax,(%esp)
80103f43:	e8 79 0d 00 00       	call   80104cc1 <release>
  return n;
80103f48:	8b 45 10             	mov    0x10(%ebp),%eax
}
80103f4b:	83 c4 24             	add    $0x24,%esp
80103f4e:	5b                   	pop    %ebx
80103f4f:	5d                   	pop    %ebp
80103f50:	c3                   	ret    

80103f51 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80103f51:	55                   	push   %ebp
80103f52:	89 e5                	mov    %esp,%ebp
80103f54:	53                   	push   %ebx
80103f55:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
80103f58:	8b 45 08             	mov    0x8(%ebp),%eax
80103f5b:	89 04 24             	mov    %eax,(%esp)
80103f5e:	e8 fc 0c 00 00       	call   80104c5f <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f63:	eb 3a                	jmp    80103f9f <piperead+0x4e>
    if(proc->killed){
80103f65:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80103f6b:	8b 40 24             	mov    0x24(%eax),%eax
80103f6e:	85 c0                	test   %eax,%eax
80103f70:	74 15                	je     80103f87 <piperead+0x36>
      release(&p->lock);
80103f72:	8b 45 08             	mov    0x8(%ebp),%eax
80103f75:	89 04 24             	mov    %eax,(%esp)
80103f78:	e8 44 0d 00 00       	call   80104cc1 <release>
      return -1;
80103f7d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103f82:	e9 b6 00 00 00       	jmp    8010403d <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
80103f87:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8a:	8b 55 08             	mov    0x8(%ebp),%edx
80103f8d:	81 c2 34 02 00 00    	add    $0x234,%edx
80103f93:	89 44 24 04          	mov    %eax,0x4(%esp)
80103f97:	89 14 24             	mov    %edx,(%esp)
80103f9a:	e8 e2 09 00 00       	call   80104981 <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80103f9f:	8b 45 08             	mov    0x8(%ebp),%eax
80103fa2:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103fa8:	8b 45 08             	mov    0x8(%ebp),%eax
80103fab:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103fb1:	39 c2                	cmp    %eax,%edx
80103fb3:	75 0d                	jne    80103fc2 <piperead+0x71>
80103fb5:	8b 45 08             	mov    0x8(%ebp),%eax
80103fb8:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103fbe:	85 c0                	test   %eax,%eax
80103fc0:	75 a3                	jne    80103f65 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80103fc2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103fc9:	eb 49                	jmp    80104014 <piperead+0xc3>
    if(p->nread == p->nwrite)
80103fcb:	8b 45 08             	mov    0x8(%ebp),%eax
80103fce:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80103fd4:	8b 45 08             	mov    0x8(%ebp),%eax
80103fd7:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80103fdd:	39 c2                	cmp    %eax,%edx
80103fdf:	74 3d                	je     8010401e <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80103fe1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103fe4:	89 c2                	mov    %eax,%edx
80103fe6:	03 55 0c             	add    0xc(%ebp),%edx
80103fe9:	8b 45 08             	mov    0x8(%ebp),%eax
80103fec:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80103ff2:	89 c3                	mov    %eax,%ebx
80103ff4:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80103ffa:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103ffd:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104002:	88 0a                	mov    %cl,(%edx)
80104004:	8d 50 01             	lea    0x1(%eax),%edx
80104007:	8b 45 08             	mov    0x8(%ebp),%eax
8010400a:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104010:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104014:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104017:	3b 45 10             	cmp    0x10(%ebp),%eax
8010401a:	7c af                	jl     80103fcb <piperead+0x7a>
8010401c:	eb 01                	jmp    8010401f <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
8010401e:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010401f:	8b 45 08             	mov    0x8(%ebp),%eax
80104022:	05 38 02 00 00       	add    $0x238,%eax
80104027:	89 04 24             	mov    %eax,(%esp)
8010402a:	e8 2b 0a 00 00       	call   80104a5a <wakeup>
  release(&p->lock);
8010402f:	8b 45 08             	mov    0x8(%ebp),%eax
80104032:	89 04 24             	mov    %eax,(%esp)
80104035:	e8 87 0c 00 00       	call   80104cc1 <release>
  return i;
8010403a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010403d:	83 c4 24             	add    $0x24,%esp
80104040:	5b                   	pop    %ebx
80104041:	5d                   	pop    %ebp
80104042:	c3                   	ret    
	...

80104044 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104044:	55                   	push   %ebp
80104045:	89 e5                	mov    %esp,%ebp
80104047:	53                   	push   %ebx
80104048:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010404b:	9c                   	pushf  
8010404c:	5b                   	pop    %ebx
8010404d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104050:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104053:	83 c4 10             	add    $0x10,%esp
80104056:	5b                   	pop    %ebx
80104057:	5d                   	pop    %ebp
80104058:	c3                   	ret    

80104059 <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
80104059:	55                   	push   %ebp
8010405a:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
8010405c:	fb                   	sti    
}
8010405d:	5d                   	pop    %ebp
8010405e:	c3                   	ret    

8010405f <add_path>:

//----------------------- PATCH -------------------//
extern int lastPath;
extern char** PATH;

int add_path(char* path){
8010405f:	55                   	push   %ebp
80104060:	89 e5                	mov    %esp,%ebp
80104062:	83 ec 18             	sub    $0x18,%esp
  if (lastPath==9){
80104065:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
8010406a:	83 f8 09             	cmp    $0x9,%eax
8010406d:	75 13                	jne    80104082 <add_path+0x23>
    cprintf("could not add path - all paths in use\n");
8010406f:	c7 04 24 68 85 10 80 	movl   $0x80108568,(%esp)
80104076:	e8 26 c3 ff ff       	call   801003a1 <cprintf>
    return -1;
8010407b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104080:	eb 43                	jmp    801040c5 <add_path+0x66>
  }
  strncpy(PATH[lastPath], path, strlen(path));
80104082:	8b 45 08             	mov    0x8(%ebp),%eax
80104085:	89 04 24             	mov    %eax,(%esp)
80104088:	e8 9f 10 00 00       	call   8010512c <strlen>
8010408d:	8b 15 60 de 10 80    	mov    0x8010de60,%edx
80104093:	8b 0d f8 b5 10 80    	mov    0x8010b5f8,%ecx
80104099:	c1 e1 02             	shl    $0x2,%ecx
8010409c:	01 ca                	add    %ecx,%edx
8010409e:	8b 12                	mov    (%edx),%edx
801040a0:	89 44 24 08          	mov    %eax,0x8(%esp)
801040a4:	8b 45 08             	mov    0x8(%ebp),%eax
801040a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801040ab:	89 14 24             	mov    %edx,(%esp)
801040ae:	e8 ca 0f 00 00       	call   8010507d <strncpy>
  lastPath++;
801040b3:	a1 f8 b5 10 80       	mov    0x8010b5f8,%eax
801040b8:	83 c0 01             	add    $0x1,%eax
801040bb:	a3 f8 b5 10 80       	mov    %eax,0x8010b5f8
  return 0;
801040c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
801040c5:	c9                   	leave  
801040c6:	c3                   	ret    

801040c7 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801040c7:	55                   	push   %ebp
801040c8:	89 e5                	mov    %esp,%ebp
801040ca:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
801040cd:	c7 44 24 04 8f 85 10 	movl   $0x8010858f,0x4(%esp)
801040d4:	80 
801040d5:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801040dc:	e8 5d 0b 00 00       	call   80104c3e <initlock>
}
801040e1:	c9                   	leave  
801040e2:	c3                   	ret    

801040e3 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801040e3:	55                   	push   %ebp
801040e4:	89 e5                	mov    %esp,%ebp
801040e6:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801040e9:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801040f0:	e8 6a 0b 00 00       	call   80104c5f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801040f5:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
801040fc:	eb 0e                	jmp    8010410c <allocproc+0x29>
    if(p->state == UNUSED)
801040fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104101:	8b 40 0c             	mov    0xc(%eax),%eax
80104104:	85 c0                	test   %eax,%eax
80104106:	74 23                	je     8010412b <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104108:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010410c:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
80104113:	72 e9                	jb     801040fe <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
80104115:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010411c:	e8 a0 0b 00 00       	call   80104cc1 <release>
  return 0;
80104121:	b8 00 00 00 00       	mov    $0x0,%eax
80104126:	e9 b5 00 00 00       	jmp    801041e0 <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
8010412b:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
8010412c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010412f:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
80104136:	a1 04 b0 10 80       	mov    0x8010b004,%eax
8010413b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010413e:	89 42 10             	mov    %eax,0x10(%edx)
80104141:	83 c0 01             	add    $0x1,%eax
80104144:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
80104149:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104150:	e8 6c 0b 00 00       	call   80104cc1 <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104155:	e8 f9 e9 ff ff       	call   80102b53 <kalloc>
8010415a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010415d:	89 42 08             	mov    %eax,0x8(%edx)
80104160:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104163:	8b 40 08             	mov    0x8(%eax),%eax
80104166:	85 c0                	test   %eax,%eax
80104168:	75 11                	jne    8010417b <allocproc+0x98>
    p->state = UNUSED;
8010416a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010416d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104174:	b8 00 00 00 00       	mov    $0x0,%eax
80104179:	eb 65                	jmp    801041e0 <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
8010417b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010417e:	8b 40 08             	mov    0x8(%eax),%eax
80104181:	05 00 10 00 00       	add    $0x1000,%eax
80104186:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104189:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010418d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104190:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104193:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104196:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
8010419a:	ba 38 63 10 80       	mov    $0x80106338,%edx
8010419f:	8b 45 f0             	mov    -0x10(%ebp),%eax
801041a2:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
801041a4:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
801041a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041ab:	8b 55 f0             	mov    -0x10(%ebp),%edx
801041ae:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
801041b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041b4:	8b 40 1c             	mov    0x1c(%eax),%eax
801041b7:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
801041be:	00 
801041bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801041c6:	00 
801041c7:	89 04 24             	mov    %eax,(%esp)
801041ca:	e8 df 0c 00 00       	call   80104eae <memset>
  p->context->eip = (uint)forkret;
801041cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041d2:	8b 40 1c             	mov    0x1c(%eax),%eax
801041d5:	ba 55 49 10 80       	mov    $0x80104955,%edx
801041da:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801041dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801041e0:	c9                   	leave  
801041e1:	c3                   	ret    

801041e2 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801041e2:	55                   	push   %ebp
801041e3:	89 e5                	mov    %esp,%ebp
801041e5:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801041e8:	e8 f6 fe ff ff       	call   801040e3 <allocproc>
801041ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801041f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801041f3:	a3 48 b6 10 80       	mov    %eax,0x8010b648
  if((p->pgdir = setupkvm(kalloc)) == 0)
801041f8:	c7 04 24 53 2b 10 80 	movl   $0x80102b53,(%esp)
801041ff:	e8 31 38 00 00       	call   80107a35 <setupkvm>
80104204:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104207:	89 42 04             	mov    %eax,0x4(%edx)
8010420a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010420d:	8b 40 04             	mov    0x4(%eax),%eax
80104210:	85 c0                	test   %eax,%eax
80104212:	75 0c                	jne    80104220 <userinit+0x3e>
    panic("userinit: out of memory?");
80104214:	c7 04 24 96 85 10 80 	movl   $0x80108596,(%esp)
8010421b:	e8 1d c3 ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
80104220:	ba 2c 00 00 00       	mov    $0x2c,%edx
80104225:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104228:	8b 40 04             	mov    0x4(%eax),%eax
8010422b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010422f:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
80104236:	80 
80104237:	89 04 24             	mov    %eax,(%esp)
8010423a:	e8 4e 3a 00 00       	call   80107c8d <inituvm>
  p->sz = PGSIZE;
8010423f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104242:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104248:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010424b:	8b 40 18             	mov    0x18(%eax),%eax
8010424e:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104255:	00 
80104256:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010425d:	00 
8010425e:	89 04 24             	mov    %eax,(%esp)
80104261:	e8 48 0c 00 00       	call   80104eae <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104266:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104269:	8b 40 18             	mov    0x18(%eax),%eax
8010426c:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104272:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104275:	8b 40 18             	mov    0x18(%eax),%eax
80104278:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010427e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104281:	8b 40 18             	mov    0x18(%eax),%eax
80104284:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104287:	8b 52 18             	mov    0x18(%edx),%edx
8010428a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010428e:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104292:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104295:	8b 40 18             	mov    0x18(%eax),%eax
80104298:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010429b:	8b 52 18             	mov    0x18(%edx),%edx
8010429e:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
801042a2:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
801042a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042a9:	8b 40 18             	mov    0x18(%eax),%eax
801042ac:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
801042b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042b6:	8b 40 18             	mov    0x18(%eax),%eax
801042b9:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
801042c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042c3:	8b 40 18             	mov    0x18(%eax),%eax
801042c6:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
801042cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042d0:	83 c0 6c             	add    $0x6c,%eax
801042d3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801042da:	00 
801042db:	c7 44 24 04 af 85 10 	movl   $0x801085af,0x4(%esp)
801042e2:	80 
801042e3:	89 04 24             	mov    %eax,(%esp)
801042e6:	e8 f3 0d 00 00       	call   801050de <safestrcpy>
  p->cwd = namei("/");
801042eb:	c7 04 24 b8 85 10 80 	movl   $0x801085b8,(%esp)
801042f2:	e8 67 e1 ff ff       	call   8010245e <namei>
801042f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801042fa:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801042fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104300:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
80104307:	c9                   	leave  
80104308:	c3                   	ret    

80104309 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
80104309:	55                   	push   %ebp
8010430a:	89 e5                	mov    %esp,%ebp
8010430c:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
8010430f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104315:	8b 00                	mov    (%eax),%eax
80104317:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
8010431a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010431e:	7e 34                	jle    80104354 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
80104320:	8b 45 08             	mov    0x8(%ebp),%eax
80104323:	89 c2                	mov    %eax,%edx
80104325:	03 55 f4             	add    -0xc(%ebp),%edx
80104328:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010432e:	8b 40 04             	mov    0x4(%eax),%eax
80104331:	89 54 24 08          	mov    %edx,0x8(%esp)
80104335:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104338:	89 54 24 04          	mov    %edx,0x4(%esp)
8010433c:	89 04 24             	mov    %eax,(%esp)
8010433f:	e8 c3 3a 00 00       	call   80107e07 <allocuvm>
80104344:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104347:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010434b:	75 41                	jne    8010438e <growproc+0x85>
      return -1;
8010434d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104352:	eb 58                	jmp    801043ac <growproc+0xa3>
  } else if(n < 0){
80104354:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104358:	79 34                	jns    8010438e <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
8010435a:	8b 45 08             	mov    0x8(%ebp),%eax
8010435d:	89 c2                	mov    %eax,%edx
8010435f:	03 55 f4             	add    -0xc(%ebp),%edx
80104362:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104368:	8b 40 04             	mov    0x4(%eax),%eax
8010436b:	89 54 24 08          	mov    %edx,0x8(%esp)
8010436f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104372:	89 54 24 04          	mov    %edx,0x4(%esp)
80104376:	89 04 24             	mov    %eax,(%esp)
80104379:	e8 63 3b 00 00       	call   80107ee1 <deallocuvm>
8010437e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104381:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104385:	75 07                	jne    8010438e <growproc+0x85>
      return -1;
80104387:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010438c:	eb 1e                	jmp    801043ac <growproc+0xa3>
  }
  proc->sz = sz;
8010438e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104394:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104397:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104399:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010439f:	89 04 24             	mov    %eax,(%esp)
801043a2:	e8 7f 37 00 00       	call   80107b26 <switchuvm>
  return 0;
801043a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
801043ac:	c9                   	leave  
801043ad:	c3                   	ret    

801043ae <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
801043ae:	55                   	push   %ebp
801043af:	89 e5                	mov    %esp,%ebp
801043b1:	57                   	push   %edi
801043b2:	56                   	push   %esi
801043b3:	53                   	push   %ebx
801043b4:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
801043b7:	e8 27 fd ff ff       	call   801040e3 <allocproc>
801043bc:	89 45 e0             	mov    %eax,-0x20(%ebp)
801043bf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
801043c3:	75 0a                	jne    801043cf <fork+0x21>
    return -1;
801043c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801043ca:	e9 3a 01 00 00       	jmp    80104509 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
801043cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043d5:	8b 10                	mov    (%eax),%edx
801043d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801043dd:	8b 40 04             	mov    0x4(%eax),%eax
801043e0:	89 54 24 04          	mov    %edx,0x4(%esp)
801043e4:	89 04 24             	mov    %eax,(%esp)
801043e7:	e8 85 3c 00 00       	call   80108071 <copyuvm>
801043ec:	8b 55 e0             	mov    -0x20(%ebp),%edx
801043ef:	89 42 04             	mov    %eax,0x4(%edx)
801043f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043f5:	8b 40 04             	mov    0x4(%eax),%eax
801043f8:	85 c0                	test   %eax,%eax
801043fa:	75 2c                	jne    80104428 <fork+0x7a>
    kfree(np->kstack);
801043fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
801043ff:	8b 40 08             	mov    0x8(%eax),%eax
80104402:	89 04 24             	mov    %eax,(%esp)
80104405:	e8 b0 e6 ff ff       	call   80102aba <kfree>
    np->kstack = 0;
8010440a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010440d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
80104414:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104417:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
8010441e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104423:	e9 e1 00 00 00       	jmp    80104509 <fork+0x15b>
  }
  np->sz = proc->sz;
80104428:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010442e:	8b 10                	mov    (%eax),%edx
80104430:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104433:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
80104435:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010443c:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010443f:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
80104442:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104445:	8b 50 18             	mov    0x18(%eax),%edx
80104448:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010444e:	8b 40 18             	mov    0x18(%eax),%eax
80104451:	89 c3                	mov    %eax,%ebx
80104453:	b8 13 00 00 00       	mov    $0x13,%eax
80104458:	89 d7                	mov    %edx,%edi
8010445a:	89 de                	mov    %ebx,%esi
8010445c:	89 c1                	mov    %eax,%ecx
8010445e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104460:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104463:	8b 40 18             	mov    0x18(%eax),%eax
80104466:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
8010446d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104474:	eb 3d                	jmp    801044b3 <fork+0x105>
    if(proc->ofile[i])
80104476:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010447c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010447f:	83 c2 08             	add    $0x8,%edx
80104482:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104486:	85 c0                	test   %eax,%eax
80104488:	74 25                	je     801044af <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
8010448a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104490:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104493:	83 c2 08             	add    $0x8,%edx
80104496:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010449a:	89 04 24             	mov    %eax,(%esp)
8010449d:	e8 2e cb ff ff       	call   80100fd0 <filedup>
801044a2:	8b 55 e0             	mov    -0x20(%ebp),%edx
801044a5:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
801044a8:	83 c1 08             	add    $0x8,%ecx
801044ab:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
801044af:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801044b3:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
801044b7:	7e bd                	jle    80104476 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
801044b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044bf:	8b 40 68             	mov    0x68(%eax),%eax
801044c2:	89 04 24             	mov    %eax,(%esp)
801044c5:	e8 c0 d3 ff ff       	call   8010188a <idup>
801044ca:	8b 55 e0             	mov    -0x20(%ebp),%edx
801044cd:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
801044d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044d3:	8b 40 10             	mov    0x10(%eax),%eax
801044d6:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
801044d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044dc:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
801044e3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044e9:	8d 50 6c             	lea    0x6c(%eax),%edx
801044ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
801044ef:	83 c0 6c             	add    $0x6c,%eax
801044f2:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801044f9:	00 
801044fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801044fe:	89 04 24             	mov    %eax,(%esp)
80104501:	e8 d8 0b 00 00       	call   801050de <safestrcpy>
  return pid;
80104506:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104509:	83 c4 2c             	add    $0x2c,%esp
8010450c:	5b                   	pop    %ebx
8010450d:	5e                   	pop    %esi
8010450e:	5f                   	pop    %edi
8010450f:	5d                   	pop    %ebp
80104510:	c3                   	ret    

80104511 <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104511:	55                   	push   %ebp
80104512:	89 e5                	mov    %esp,%ebp
80104514:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104517:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010451e:	a1 48 b6 10 80       	mov    0x8010b648,%eax
80104523:	39 c2                	cmp    %eax,%edx
80104525:	75 0c                	jne    80104533 <exit+0x22>
    panic("init exiting");
80104527:	c7 04 24 ba 85 10 80 	movl   $0x801085ba,(%esp)
8010452e:	e8 0a c0 ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104533:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
8010453a:	eb 44                	jmp    80104580 <exit+0x6f>
    if(proc->ofile[fd]){
8010453c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104542:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104545:	83 c2 08             	add    $0x8,%edx
80104548:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010454c:	85 c0                	test   %eax,%eax
8010454e:	74 2c                	je     8010457c <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104550:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104556:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104559:	83 c2 08             	add    $0x8,%edx
8010455c:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104560:	89 04 24             	mov    %eax,(%esp)
80104563:	e8 b0 ca ff ff       	call   80101018 <fileclose>
      proc->ofile[fd] = 0;
80104568:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010456e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104571:	83 c2 08             	add    $0x8,%edx
80104574:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
8010457b:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010457c:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104580:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104584:	7e b6                	jle    8010453c <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104586:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010458c:	8b 40 68             	mov    0x68(%eax),%eax
8010458f:	89 04 24             	mov    %eax,(%esp)
80104592:	e8 d8 d4 ff ff       	call   80101a6f <iput>
  proc->cwd = 0;
80104597:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010459d:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801045a4:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801045ab:	e8 af 06 00 00       	call   80104c5f <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
801045b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045b6:	8b 40 14             	mov    0x14(%eax),%eax
801045b9:	89 04 24             	mov    %eax,(%esp)
801045bc:	e8 5b 04 00 00       	call   80104a1c <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045c1:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
801045c8:	eb 38                	jmp    80104602 <exit+0xf1>
    if(p->parent == proc){
801045ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045cd:	8b 50 14             	mov    0x14(%eax),%edx
801045d0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801045d6:	39 c2                	cmp    %eax,%edx
801045d8:	75 24                	jne    801045fe <exit+0xed>
      p->parent = initproc;
801045da:	8b 15 48 b6 10 80    	mov    0x8010b648,%edx
801045e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e3:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801045e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801045e9:	8b 40 0c             	mov    0xc(%eax),%eax
801045ec:	83 f8 05             	cmp    $0x5,%eax
801045ef:	75 0d                	jne    801045fe <exit+0xed>
        wakeup1(initproc);
801045f1:	a1 48 b6 10 80       	mov    0x8010b648,%eax
801045f6:	89 04 24             	mov    %eax,(%esp)
801045f9:	e8 1e 04 00 00       	call   80104a1c <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801045fe:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104602:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
80104609:	72 bf                	jb     801045ca <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
8010460b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104611:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104618:	e8 54 02 00 00       	call   80104871 <sched>
  panic("zombie exit");
8010461d:	c7 04 24 c7 85 10 80 	movl   $0x801085c7,(%esp)
80104624:	e8 14 bf ff ff       	call   8010053d <panic>

80104629 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104629:	55                   	push   %ebp
8010462a:	89 e5                	mov    %esp,%ebp
8010462c:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
8010462f:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104636:	e8 24 06 00 00       	call   80104c5f <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
8010463b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104642:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
80104649:	e9 9a 00 00 00       	jmp    801046e8 <wait+0xbf>
      if(p->parent != proc)
8010464e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104651:	8b 50 14             	mov    0x14(%eax),%edx
80104654:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010465a:	39 c2                	cmp    %eax,%edx
8010465c:	0f 85 81 00 00 00    	jne    801046e3 <wait+0xba>
        continue;
      havekids = 1;
80104662:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104669:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010466c:	8b 40 0c             	mov    0xc(%eax),%eax
8010466f:	83 f8 05             	cmp    $0x5,%eax
80104672:	75 70                	jne    801046e4 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104674:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104677:	8b 40 10             	mov    0x10(%eax),%eax
8010467a:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
8010467d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104680:	8b 40 08             	mov    0x8(%eax),%eax
80104683:	89 04 24             	mov    %eax,(%esp)
80104686:	e8 2f e4 ff ff       	call   80102aba <kfree>
        p->kstack = 0;
8010468b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010468e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104695:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104698:	8b 40 04             	mov    0x4(%eax),%eax
8010469b:	89 04 24             	mov    %eax,(%esp)
8010469e:	e8 fa 38 00 00       	call   80107f9d <freevm>
        p->state = UNUSED;
801046a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046a6:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
801046ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046b0:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801046b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046ba:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801046c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046c4:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801046c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046cb:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
801046d2:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801046d9:	e8 e3 05 00 00       	call   80104cc1 <release>
        return pid;
801046de:	8b 45 ec             	mov    -0x14(%ebp),%eax
801046e1:	eb 53                	jmp    80104736 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
801046e3:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801046e4:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801046e8:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
801046ef:	0f 82 59 ff ff ff    	jb     8010464e <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
801046f5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801046f9:	74 0d                	je     80104708 <wait+0xdf>
801046fb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104701:	8b 40 24             	mov    0x24(%eax),%eax
80104704:	85 c0                	test   %eax,%eax
80104706:	74 13                	je     8010471b <wait+0xf2>
      release(&ptable.lock);
80104708:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010470f:	e8 ad 05 00 00       	call   80104cc1 <release>
      return -1;
80104714:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104719:	eb 1b                	jmp    80104736 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
8010471b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104721:	c7 44 24 04 20 04 11 	movl   $0x80110420,0x4(%esp)
80104728:	80 
80104729:	89 04 24             	mov    %eax,(%esp)
8010472c:	e8 50 02 00 00       	call   80104981 <sleep>
  }
80104731:	e9 05 ff ff ff       	jmp    8010463b <wait+0x12>
}
80104736:	c9                   	leave  
80104737:	c3                   	ret    

80104738 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80104738:	55                   	push   %ebp
80104739:	89 e5                	mov    %esp,%ebp
8010473b:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
8010473e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104744:	8b 40 18             	mov    0x18(%eax),%eax
80104747:	8b 40 44             	mov    0x44(%eax),%eax
8010474a:	89 c2                	mov    %eax,%edx
8010474c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104752:	8b 40 04             	mov    0x4(%eax),%eax
80104755:	89 54 24 04          	mov    %edx,0x4(%esp)
80104759:	89 04 24             	mov    %eax,(%esp)
8010475c:	e8 21 3a 00 00       	call   80108182 <uva2ka>
80104761:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104764:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010476a:	8b 40 18             	mov    0x18(%eax),%eax
8010476d:	8b 40 44             	mov    0x44(%eax),%eax
80104770:	25 ff 0f 00 00       	and    $0xfff,%eax
80104775:	85 c0                	test   %eax,%eax
80104777:	75 0c                	jne    80104785 <register_handler+0x4d>
    panic("esp_offset == 0");
80104779:	c7 04 24 d3 85 10 80 	movl   $0x801085d3,(%esp)
80104780:	e8 b8 bd ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104785:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010478b:	8b 40 18             	mov    0x18(%eax),%eax
8010478e:	8b 40 44             	mov    0x44(%eax),%eax
80104791:	83 e8 04             	sub    $0x4,%eax
80104794:	25 ff 0f 00 00       	and    $0xfff,%eax
80104799:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
8010479c:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047a3:	8b 52 18             	mov    0x18(%edx),%edx
801047a6:	8b 52 38             	mov    0x38(%edx),%edx
801047a9:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
801047ab:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047b1:	8b 40 18             	mov    0x18(%eax),%eax
801047b4:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801047bb:	8b 52 18             	mov    0x18(%edx),%edx
801047be:	8b 52 44             	mov    0x44(%edx),%edx
801047c1:	83 ea 04             	sub    $0x4,%edx
801047c4:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
801047c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801047cd:	8b 40 18             	mov    0x18(%eax),%eax
801047d0:	8b 55 08             	mov    0x8(%ebp),%edx
801047d3:	89 50 38             	mov    %edx,0x38(%eax)
}
801047d6:	c9                   	leave  
801047d7:	c3                   	ret    

801047d8 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
801047d8:	55                   	push   %ebp
801047d9:	89 e5                	mov    %esp,%ebp
801047db:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
801047de:	e8 76 f8 ff ff       	call   80104059 <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
801047e3:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801047ea:	e8 70 04 00 00       	call   80104c5f <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047ef:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
801047f6:	eb 5f                	jmp    80104857 <scheduler+0x7f>
      if(p->state != RUNNABLE)
801047f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047fb:	8b 40 0c             	mov    0xc(%eax),%eax
801047fe:	83 f8 03             	cmp    $0x3,%eax
80104801:	75 4f                	jne    80104852 <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104803:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104806:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
8010480c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010480f:	89 04 24             	mov    %eax,(%esp)
80104812:	e8 0f 33 00 00       	call   80107b26 <switchuvm>
      p->state = RUNNING;
80104817:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010481a:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104821:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104827:	8b 40 1c             	mov    0x1c(%eax),%eax
8010482a:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104831:	83 c2 04             	add    $0x4,%edx
80104834:	89 44 24 04          	mov    %eax,0x4(%esp)
80104838:	89 14 24             	mov    %edx,(%esp)
8010483b:	e8 14 09 00 00       	call   80105154 <swtch>
      switchkvm();
80104840:	e8 c4 32 00 00       	call   80107b09 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104845:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
8010484c:	00 00 00 00 
80104850:	eb 01                	jmp    80104853 <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104852:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104853:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104857:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
8010485e:	72 98                	jb     801047f8 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104860:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104867:	e8 55 04 00 00       	call   80104cc1 <release>

  }
8010486c:	e9 6d ff ff ff       	jmp    801047de <scheduler+0x6>

80104871 <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104871:	55                   	push   %ebp
80104872:	89 e5                	mov    %esp,%ebp
80104874:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104877:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010487e:	e8 fa 04 00 00       	call   80104d7d <holding>
80104883:	85 c0                	test   %eax,%eax
80104885:	75 0c                	jne    80104893 <sched+0x22>
    panic("sched ptable.lock");
80104887:	c7 04 24 e3 85 10 80 	movl   $0x801085e3,(%esp)
8010488e:	e8 aa bc ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104893:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104899:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
8010489f:	83 f8 01             	cmp    $0x1,%eax
801048a2:	74 0c                	je     801048b0 <sched+0x3f>
    panic("sched locks");
801048a4:	c7 04 24 f5 85 10 80 	movl   $0x801085f5,(%esp)
801048ab:	e8 8d bc ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
801048b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048b6:	8b 40 0c             	mov    0xc(%eax),%eax
801048b9:	83 f8 04             	cmp    $0x4,%eax
801048bc:	75 0c                	jne    801048ca <sched+0x59>
    panic("sched running");
801048be:	c7 04 24 01 86 10 80 	movl   $0x80108601,(%esp)
801048c5:	e8 73 bc ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
801048ca:	e8 75 f7 ff ff       	call   80104044 <readeflags>
801048cf:	25 00 02 00 00       	and    $0x200,%eax
801048d4:	85 c0                	test   %eax,%eax
801048d6:	74 0c                	je     801048e4 <sched+0x73>
    panic("sched interruptible");
801048d8:	c7 04 24 0f 86 10 80 	movl   $0x8010860f,(%esp)
801048df:	e8 59 bc ff ff       	call   8010053d <panic>
  intena = cpu->intena;
801048e4:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801048ea:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
801048f0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
801048f3:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801048f9:	8b 40 04             	mov    0x4(%eax),%eax
801048fc:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104903:	83 c2 1c             	add    $0x1c,%edx
80104906:	89 44 24 04          	mov    %eax,0x4(%esp)
8010490a:	89 14 24             	mov    %edx,(%esp)
8010490d:	e8 42 08 00 00       	call   80105154 <swtch>
  cpu->intena = intena;
80104912:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104918:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010491b:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104921:	c9                   	leave  
80104922:	c3                   	ret    

80104923 <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104923:	55                   	push   %ebp
80104924:	89 e5                	mov    %esp,%ebp
80104926:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104929:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104930:	e8 2a 03 00 00       	call   80104c5f <acquire>
  proc->state = RUNNABLE;
80104935:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010493b:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104942:	e8 2a ff ff ff       	call   80104871 <sched>
  release(&ptable.lock);
80104947:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
8010494e:	e8 6e 03 00 00       	call   80104cc1 <release>
}
80104953:	c9                   	leave  
80104954:	c3                   	ret    

80104955 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104955:	55                   	push   %ebp
80104956:	89 e5                	mov    %esp,%ebp
80104958:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
8010495b:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104962:	e8 5a 03 00 00       	call   80104cc1 <release>

  if (first) {
80104967:	a1 20 b0 10 80       	mov    0x8010b020,%eax
8010496c:	85 c0                	test   %eax,%eax
8010496e:	74 0f                	je     8010497f <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104970:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
80104977:	00 00 00 
    initlog();
8010497a:	e8 e5 e6 ff ff       	call   80103064 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
8010497f:	c9                   	leave  
80104980:	c3                   	ret    

80104981 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104981:	55                   	push   %ebp
80104982:	89 e5                	mov    %esp,%ebp
80104984:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104987:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010498d:	85 c0                	test   %eax,%eax
8010498f:	75 0c                	jne    8010499d <sleep+0x1c>
    panic("sleep");
80104991:	c7 04 24 23 86 10 80 	movl   $0x80108623,(%esp)
80104998:	e8 a0 bb ff ff       	call   8010053d <panic>

  if(lk == 0)
8010499d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801049a1:	75 0c                	jne    801049af <sleep+0x2e>
    panic("sleep without lk");
801049a3:	c7 04 24 29 86 10 80 	movl   $0x80108629,(%esp)
801049aa:	e8 8e bb ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
801049af:	81 7d 0c 20 04 11 80 	cmpl   $0x80110420,0xc(%ebp)
801049b6:	74 17                	je     801049cf <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
801049b8:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
801049bf:	e8 9b 02 00 00       	call   80104c5f <acquire>
    release(lk);
801049c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801049c7:	89 04 24             	mov    %eax,(%esp)
801049ca:	e8 f2 02 00 00       	call   80104cc1 <release>
  }

  // Go to sleep.
  proc->chan = chan;
801049cf:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049d5:	8b 55 08             	mov    0x8(%ebp),%edx
801049d8:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
801049db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049e1:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
801049e8:	e8 84 fe ff ff       	call   80104871 <sched>

  // Tidy up.
  proc->chan = 0;
801049ed:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049f3:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
801049fa:	81 7d 0c 20 04 11 80 	cmpl   $0x80110420,0xc(%ebp)
80104a01:	74 17                	je     80104a1a <sleep+0x99>
    release(&ptable.lock);
80104a03:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a0a:	e8 b2 02 00 00       	call   80104cc1 <release>
    acquire(lk);
80104a0f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104a12:	89 04 24             	mov    %eax,(%esp)
80104a15:	e8 45 02 00 00       	call   80104c5f <acquire>
  }
}
80104a1a:	c9                   	leave  
80104a1b:	c3                   	ret    

80104a1c <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104a1c:	55                   	push   %ebp
80104a1d:	89 e5                	mov    %esp,%ebp
80104a1f:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a22:	c7 45 fc 54 04 11 80 	movl   $0x80110454,-0x4(%ebp)
80104a29:	eb 24                	jmp    80104a4f <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104a2b:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a2e:	8b 40 0c             	mov    0xc(%eax),%eax
80104a31:	83 f8 02             	cmp    $0x2,%eax
80104a34:	75 15                	jne    80104a4b <wakeup1+0x2f>
80104a36:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a39:	8b 40 20             	mov    0x20(%eax),%eax
80104a3c:	3b 45 08             	cmp    0x8(%ebp),%eax
80104a3f:	75 0a                	jne    80104a4b <wakeup1+0x2f>
      p->state = RUNNABLE;
80104a41:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104a44:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104a4b:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104a4f:	81 7d fc 54 23 11 80 	cmpl   $0x80112354,-0x4(%ebp)
80104a56:	72 d3                	jb     80104a2b <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104a58:	c9                   	leave  
80104a59:	c3                   	ret    

80104a5a <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104a5a:	55                   	push   %ebp
80104a5b:	89 e5                	mov    %esp,%ebp
80104a5d:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
80104a60:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a67:	e8 f3 01 00 00       	call   80104c5f <acquire>
  wakeup1(chan);
80104a6c:	8b 45 08             	mov    0x8(%ebp),%eax
80104a6f:	89 04 24             	mov    %eax,(%esp)
80104a72:	e8 a5 ff ff ff       	call   80104a1c <wakeup1>
  release(&ptable.lock);
80104a77:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a7e:	e8 3e 02 00 00       	call   80104cc1 <release>
}
80104a83:	c9                   	leave  
80104a84:	c3                   	ret    

80104a85 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104a85:	55                   	push   %ebp
80104a86:	89 e5                	mov    %esp,%ebp
80104a88:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104a8b:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104a92:	e8 c8 01 00 00       	call   80104c5f <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104a97:	c7 45 f4 54 04 11 80 	movl   $0x80110454,-0xc(%ebp)
80104a9e:	eb 41                	jmp    80104ae1 <kill+0x5c>
    if(p->pid == pid){
80104aa0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aa3:	8b 40 10             	mov    0x10(%eax),%eax
80104aa6:	3b 45 08             	cmp    0x8(%ebp),%eax
80104aa9:	75 32                	jne    80104add <kill+0x58>
      p->killed = 1;
80104aab:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104aae:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ab8:	8b 40 0c             	mov    0xc(%eax),%eax
80104abb:	83 f8 02             	cmp    $0x2,%eax
80104abe:	75 0a                	jne    80104aca <kill+0x45>
        p->state = RUNNABLE;
80104ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ac3:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104aca:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104ad1:	e8 eb 01 00 00       	call   80104cc1 <release>
      return 0;
80104ad6:	b8 00 00 00 00       	mov    $0x0,%eax
80104adb:	eb 1e                	jmp    80104afb <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104add:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104ae1:	81 7d f4 54 23 11 80 	cmpl   $0x80112354,-0xc(%ebp)
80104ae8:	72 b6                	jb     80104aa0 <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104aea:	c7 04 24 20 04 11 80 	movl   $0x80110420,(%esp)
80104af1:	e8 cb 01 00 00       	call   80104cc1 <release>
  return -1;
80104af6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104afb:	c9                   	leave  
80104afc:	c3                   	ret    

80104afd <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104afd:	55                   	push   %ebp
80104afe:	89 e5                	mov    %esp,%ebp
80104b00:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b03:	c7 45 f0 54 04 11 80 	movl   $0x80110454,-0x10(%ebp)
80104b0a:	e9 d8 00 00 00       	jmp    80104be7 <procdump+0xea>
    if(p->state == UNUSED)
80104b0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b12:	8b 40 0c             	mov    0xc(%eax),%eax
80104b15:	85 c0                	test   %eax,%eax
80104b17:	0f 84 c5 00 00 00    	je     80104be2 <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104b1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b20:	8b 40 0c             	mov    0xc(%eax),%eax
80104b23:	83 f8 05             	cmp    $0x5,%eax
80104b26:	77 23                	ja     80104b4b <procdump+0x4e>
80104b28:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b2b:	8b 40 0c             	mov    0xc(%eax),%eax
80104b2e:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104b35:	85 c0                	test   %eax,%eax
80104b37:	74 12                	je     80104b4b <procdump+0x4e>
      state = states[p->state];
80104b39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b3c:	8b 40 0c             	mov    0xc(%eax),%eax
80104b3f:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104b46:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104b49:	eb 07                	jmp    80104b52 <procdump+0x55>
    else
      state = "???";
80104b4b:	c7 45 ec 3a 86 10 80 	movl   $0x8010863a,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104b52:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b55:	8d 50 6c             	lea    0x6c(%eax),%edx
80104b58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b5b:	8b 40 10             	mov    0x10(%eax),%eax
80104b5e:	89 54 24 0c          	mov    %edx,0xc(%esp)
80104b62:	8b 55 ec             	mov    -0x14(%ebp),%edx
80104b65:	89 54 24 08          	mov    %edx,0x8(%esp)
80104b69:	89 44 24 04          	mov    %eax,0x4(%esp)
80104b6d:	c7 04 24 3e 86 10 80 	movl   $0x8010863e,(%esp)
80104b74:	e8 28 b8 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80104b79:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b7c:	8b 40 0c             	mov    0xc(%eax),%eax
80104b7f:	83 f8 02             	cmp    $0x2,%eax
80104b82:	75 50                	jne    80104bd4 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104b84:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104b87:	8b 40 1c             	mov    0x1c(%eax),%eax
80104b8a:	8b 40 0c             	mov    0xc(%eax),%eax
80104b8d:	83 c0 08             	add    $0x8,%eax
80104b90:	8d 55 c4             	lea    -0x3c(%ebp),%edx
80104b93:	89 54 24 04          	mov    %edx,0x4(%esp)
80104b97:	89 04 24             	mov    %eax,(%esp)
80104b9a:	e8 71 01 00 00       	call   80104d10 <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
80104b9f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104ba6:	eb 1b                	jmp    80104bc3 <procdump+0xc6>
        cprintf(" %p", pc[i]);
80104ba8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bab:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104baf:	89 44 24 04          	mov    %eax,0x4(%esp)
80104bb3:	c7 04 24 47 86 10 80 	movl   $0x80108647,(%esp)
80104bba:	e8 e2 b7 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104bbf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104bc3:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104bc7:	7f 0b                	jg     80104bd4 <procdump+0xd7>
80104bc9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bcc:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104bd0:	85 c0                	test   %eax,%eax
80104bd2:	75 d4                	jne    80104ba8 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104bd4:	c7 04 24 4b 86 10 80 	movl   $0x8010864b,(%esp)
80104bdb:	e8 c1 b7 ff ff       	call   801003a1 <cprintf>
80104be0:	eb 01                	jmp    80104be3 <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104be2:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104be3:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104be7:	81 7d f0 54 23 11 80 	cmpl   $0x80112354,-0x10(%ebp)
80104bee:	0f 82 1b ff ff ff    	jb     80104b0f <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104bf4:	c9                   	leave  
80104bf5:	c3                   	ret    
	...

80104bf8 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104bf8:	55                   	push   %ebp
80104bf9:	89 e5                	mov    %esp,%ebp
80104bfb:	53                   	push   %ebx
80104bfc:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104bff:	9c                   	pushf  
80104c00:	5b                   	pop    %ebx
80104c01:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104c04:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104c07:	83 c4 10             	add    $0x10,%esp
80104c0a:	5b                   	pop    %ebx
80104c0b:	5d                   	pop    %ebp
80104c0c:	c3                   	ret    

80104c0d <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104c0d:	55                   	push   %ebp
80104c0e:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104c10:	fa                   	cli    
}
80104c11:	5d                   	pop    %ebp
80104c12:	c3                   	ret    

80104c13 <sti>:

static inline void
sti(void)
{
80104c13:	55                   	push   %ebp
80104c14:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104c16:	fb                   	sti    
}
80104c17:	5d                   	pop    %ebp
80104c18:	c3                   	ret    

80104c19 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104c19:	55                   	push   %ebp
80104c1a:	89 e5                	mov    %esp,%ebp
80104c1c:	53                   	push   %ebx
80104c1d:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80104c20:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104c23:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80104c26:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104c29:	89 c3                	mov    %eax,%ebx
80104c2b:	89 d8                	mov    %ebx,%eax
80104c2d:	f0 87 02             	lock xchg %eax,(%edx)
80104c30:	89 c3                	mov    %eax,%ebx
80104c32:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104c35:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104c38:	83 c4 10             	add    $0x10,%esp
80104c3b:	5b                   	pop    %ebx
80104c3c:	5d                   	pop    %ebp
80104c3d:	c3                   	ret    

80104c3e <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104c3e:	55                   	push   %ebp
80104c3f:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104c41:	8b 45 08             	mov    0x8(%ebp),%eax
80104c44:	8b 55 0c             	mov    0xc(%ebp),%edx
80104c47:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104c4a:	8b 45 08             	mov    0x8(%ebp),%eax
80104c4d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104c53:	8b 45 08             	mov    0x8(%ebp),%eax
80104c56:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104c5d:	5d                   	pop    %ebp
80104c5e:	c3                   	ret    

80104c5f <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104c5f:	55                   	push   %ebp
80104c60:	89 e5                	mov    %esp,%ebp
80104c62:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104c65:	e8 3d 01 00 00       	call   80104da7 <pushcli>
  if(holding(lk))
80104c6a:	8b 45 08             	mov    0x8(%ebp),%eax
80104c6d:	89 04 24             	mov    %eax,(%esp)
80104c70:	e8 08 01 00 00       	call   80104d7d <holding>
80104c75:	85 c0                	test   %eax,%eax
80104c77:	74 0c                	je     80104c85 <acquire+0x26>
    panic("acquire");
80104c79:	c7 04 24 77 86 10 80 	movl   $0x80108677,(%esp)
80104c80:	e8 b8 b8 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80104c85:	90                   	nop
80104c86:	8b 45 08             	mov    0x8(%ebp),%eax
80104c89:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80104c90:	00 
80104c91:	89 04 24             	mov    %eax,(%esp)
80104c94:	e8 80 ff ff ff       	call   80104c19 <xchg>
80104c99:	85 c0                	test   %eax,%eax
80104c9b:	75 e9                	jne    80104c86 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80104c9d:	8b 45 08             	mov    0x8(%ebp),%eax
80104ca0:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104ca7:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80104caa:	8b 45 08             	mov    0x8(%ebp),%eax
80104cad:	83 c0 0c             	add    $0xc,%eax
80104cb0:	89 44 24 04          	mov    %eax,0x4(%esp)
80104cb4:	8d 45 08             	lea    0x8(%ebp),%eax
80104cb7:	89 04 24             	mov    %eax,(%esp)
80104cba:	e8 51 00 00 00       	call   80104d10 <getcallerpcs>
}
80104cbf:	c9                   	leave  
80104cc0:	c3                   	ret    

80104cc1 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104cc1:	55                   	push   %ebp
80104cc2:	89 e5                	mov    %esp,%ebp
80104cc4:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80104cc7:	8b 45 08             	mov    0x8(%ebp),%eax
80104cca:	89 04 24             	mov    %eax,(%esp)
80104ccd:	e8 ab 00 00 00       	call   80104d7d <holding>
80104cd2:	85 c0                	test   %eax,%eax
80104cd4:	75 0c                	jne    80104ce2 <release+0x21>
    panic("release");
80104cd6:	c7 04 24 7f 86 10 80 	movl   $0x8010867f,(%esp)
80104cdd:	e8 5b b8 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
80104ce2:	8b 45 08             	mov    0x8(%ebp),%eax
80104ce5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104cec:	8b 45 08             	mov    0x8(%ebp),%eax
80104cef:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
80104cf6:	8b 45 08             	mov    0x8(%ebp),%eax
80104cf9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104d00:	00 
80104d01:	89 04 24             	mov    %eax,(%esp)
80104d04:	e8 10 ff ff ff       	call   80104c19 <xchg>

  popcli();
80104d09:	e8 e1 00 00 00       	call   80104def <popcli>
}
80104d0e:	c9                   	leave  
80104d0f:	c3                   	ret    

80104d10 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80104d10:	55                   	push   %ebp
80104d11:	89 e5                	mov    %esp,%ebp
80104d13:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
80104d16:	8b 45 08             	mov    0x8(%ebp),%eax
80104d19:	83 e8 08             	sub    $0x8,%eax
80104d1c:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80104d1f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
80104d26:	eb 32                	jmp    80104d5a <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
80104d28:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80104d2c:	74 47                	je     80104d75 <getcallerpcs+0x65>
80104d2e:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
80104d35:	76 3e                	jbe    80104d75 <getcallerpcs+0x65>
80104d37:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80104d3b:	74 38                	je     80104d75 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
80104d3d:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104d40:	c1 e0 02             	shl    $0x2,%eax
80104d43:	03 45 0c             	add    0xc(%ebp),%eax
80104d46:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104d49:	8b 52 04             	mov    0x4(%edx),%edx
80104d4c:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
80104d4e:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104d51:	8b 00                	mov    (%eax),%eax
80104d53:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80104d56:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104d5a:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104d5e:	7e c8                	jle    80104d28 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104d60:	eb 13                	jmp    80104d75 <getcallerpcs+0x65>
    pcs[i] = 0;
80104d62:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104d65:	c1 e0 02             	shl    $0x2,%eax
80104d68:	03 45 0c             	add    0xc(%ebp),%eax
80104d6b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80104d71:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104d75:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80104d79:	7e e7                	jle    80104d62 <getcallerpcs+0x52>
    pcs[i] = 0;
}
80104d7b:	c9                   	leave  
80104d7c:	c3                   	ret    

80104d7d <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80104d7d:	55                   	push   %ebp
80104d7e:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
80104d80:	8b 45 08             	mov    0x8(%ebp),%eax
80104d83:	8b 00                	mov    (%eax),%eax
80104d85:	85 c0                	test   %eax,%eax
80104d87:	74 17                	je     80104da0 <holding+0x23>
80104d89:	8b 45 08             	mov    0x8(%ebp),%eax
80104d8c:	8b 50 08             	mov    0x8(%eax),%edx
80104d8f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104d95:	39 c2                	cmp    %eax,%edx
80104d97:	75 07                	jne    80104da0 <holding+0x23>
80104d99:	b8 01 00 00 00       	mov    $0x1,%eax
80104d9e:	eb 05                	jmp    80104da5 <holding+0x28>
80104da0:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104da5:	5d                   	pop    %ebp
80104da6:	c3                   	ret    

80104da7 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80104da7:	55                   	push   %ebp
80104da8:	89 e5                	mov    %esp,%ebp
80104daa:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80104dad:	e8 46 fe ff ff       	call   80104bf8 <readeflags>
80104db2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80104db5:	e8 53 fe ff ff       	call   80104c0d <cli>
  if(cpu->ncli++ == 0)
80104dba:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dc0:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104dc6:	85 d2                	test   %edx,%edx
80104dc8:	0f 94 c1             	sete   %cl
80104dcb:	83 c2 01             	add    $0x1,%edx
80104dce:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104dd4:	84 c9                	test   %cl,%cl
80104dd6:	74 15                	je     80104ded <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80104dd8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104dde:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104de1:	81 e2 00 02 00 00    	and    $0x200,%edx
80104de7:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104ded:	c9                   	leave  
80104dee:	c3                   	ret    

80104def <popcli>:

void
popcli(void)
{
80104def:	55                   	push   %ebp
80104df0:	89 e5                	mov    %esp,%ebp
80104df2:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
80104df5:	e8 fe fd ff ff       	call   80104bf8 <readeflags>
80104dfa:	25 00 02 00 00       	and    $0x200,%eax
80104dff:	85 c0                	test   %eax,%eax
80104e01:	74 0c                	je     80104e0f <popcli+0x20>
    panic("popcli - interruptible");
80104e03:	c7 04 24 87 86 10 80 	movl   $0x80108687,(%esp)
80104e0a:	e8 2e b7 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
80104e0f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e15:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80104e1b:	83 ea 01             	sub    $0x1,%edx
80104e1e:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80104e24:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104e2a:	85 c0                	test   %eax,%eax
80104e2c:	79 0c                	jns    80104e3a <popcli+0x4b>
    panic("popcli");
80104e2e:	c7 04 24 9e 86 10 80 	movl   $0x8010869e,(%esp)
80104e35:	e8 03 b7 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
80104e3a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e40:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104e46:	85 c0                	test   %eax,%eax
80104e48:	75 15                	jne    80104e5f <popcli+0x70>
80104e4a:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e50:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104e56:	85 c0                	test   %eax,%eax
80104e58:	74 05                	je     80104e5f <popcli+0x70>
    sti();
80104e5a:	e8 b4 fd ff ff       	call   80104c13 <sti>
}
80104e5f:	c9                   	leave  
80104e60:	c3                   	ret    
80104e61:	00 00                	add    %al,(%eax)
	...

80104e64 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80104e64:	55                   	push   %ebp
80104e65:	89 e5                	mov    %esp,%ebp
80104e67:	57                   	push   %edi
80104e68:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80104e69:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e6c:	8b 55 10             	mov    0x10(%ebp),%edx
80104e6f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e72:	89 cb                	mov    %ecx,%ebx
80104e74:	89 df                	mov    %ebx,%edi
80104e76:	89 d1                	mov    %edx,%ecx
80104e78:	fc                   	cld    
80104e79:	f3 aa                	rep stos %al,%es:(%edi)
80104e7b:	89 ca                	mov    %ecx,%edx
80104e7d:	89 fb                	mov    %edi,%ebx
80104e7f:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104e82:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104e85:	5b                   	pop    %ebx
80104e86:	5f                   	pop    %edi
80104e87:	5d                   	pop    %ebp
80104e88:	c3                   	ret    

80104e89 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80104e89:	55                   	push   %ebp
80104e8a:	89 e5                	mov    %esp,%ebp
80104e8c:	57                   	push   %edi
80104e8d:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
80104e8e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104e91:	8b 55 10             	mov    0x10(%ebp),%edx
80104e94:	8b 45 0c             	mov    0xc(%ebp),%eax
80104e97:	89 cb                	mov    %ecx,%ebx
80104e99:	89 df                	mov    %ebx,%edi
80104e9b:	89 d1                	mov    %edx,%ecx
80104e9d:	fc                   	cld    
80104e9e:	f3 ab                	rep stos %eax,%es:(%edi)
80104ea0:	89 ca                	mov    %ecx,%edx
80104ea2:	89 fb                	mov    %edi,%ebx
80104ea4:	89 5d 08             	mov    %ebx,0x8(%ebp)
80104ea7:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80104eaa:	5b                   	pop    %ebx
80104eab:	5f                   	pop    %edi
80104eac:	5d                   	pop    %ebp
80104ead:	c3                   	ret    

80104eae <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80104eae:	55                   	push   %ebp
80104eaf:	89 e5                	mov    %esp,%ebp
80104eb1:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80104eb4:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb7:	83 e0 03             	and    $0x3,%eax
80104eba:	85 c0                	test   %eax,%eax
80104ebc:	75 49                	jne    80104f07 <memset+0x59>
80104ebe:	8b 45 10             	mov    0x10(%ebp),%eax
80104ec1:	83 e0 03             	and    $0x3,%eax
80104ec4:	85 c0                	test   %eax,%eax
80104ec6:	75 3f                	jne    80104f07 <memset+0x59>
    c &= 0xFF;
80104ec8:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
80104ecf:	8b 45 10             	mov    0x10(%ebp),%eax
80104ed2:	c1 e8 02             	shr    $0x2,%eax
80104ed5:	89 c2                	mov    %eax,%edx
80104ed7:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eda:	89 c1                	mov    %eax,%ecx
80104edc:	c1 e1 18             	shl    $0x18,%ecx
80104edf:	8b 45 0c             	mov    0xc(%ebp),%eax
80104ee2:	c1 e0 10             	shl    $0x10,%eax
80104ee5:	09 c1                	or     %eax,%ecx
80104ee7:	8b 45 0c             	mov    0xc(%ebp),%eax
80104eea:	c1 e0 08             	shl    $0x8,%eax
80104eed:	09 c8                	or     %ecx,%eax
80104eef:	0b 45 0c             	or     0xc(%ebp),%eax
80104ef2:	89 54 24 08          	mov    %edx,0x8(%esp)
80104ef6:	89 44 24 04          	mov    %eax,0x4(%esp)
80104efa:	8b 45 08             	mov    0x8(%ebp),%eax
80104efd:	89 04 24             	mov    %eax,(%esp)
80104f00:	e8 84 ff ff ff       	call   80104e89 <stosl>
80104f05:	eb 19                	jmp    80104f20 <memset+0x72>
  } else
    stosb(dst, c, n);
80104f07:	8b 45 10             	mov    0x10(%ebp),%eax
80104f0a:	89 44 24 08          	mov    %eax,0x8(%esp)
80104f0e:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f11:	89 44 24 04          	mov    %eax,0x4(%esp)
80104f15:	8b 45 08             	mov    0x8(%ebp),%eax
80104f18:	89 04 24             	mov    %eax,(%esp)
80104f1b:	e8 44 ff ff ff       	call   80104e64 <stosb>
  return dst;
80104f20:	8b 45 08             	mov    0x8(%ebp),%eax
}
80104f23:	c9                   	leave  
80104f24:	c3                   	ret    

80104f25 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80104f25:	55                   	push   %ebp
80104f26:	89 e5                	mov    %esp,%ebp
80104f28:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
80104f2b:	8b 45 08             	mov    0x8(%ebp),%eax
80104f2e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80104f31:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f34:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80104f37:	eb 32                	jmp    80104f6b <memcmp+0x46>
    if(*s1 != *s2)
80104f39:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f3c:	0f b6 10             	movzbl (%eax),%edx
80104f3f:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f42:	0f b6 00             	movzbl (%eax),%eax
80104f45:	38 c2                	cmp    %al,%dl
80104f47:	74 1a                	je     80104f63 <memcmp+0x3e>
      return *s1 - *s2;
80104f49:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f4c:	0f b6 00             	movzbl (%eax),%eax
80104f4f:	0f b6 d0             	movzbl %al,%edx
80104f52:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104f55:	0f b6 00             	movzbl (%eax),%eax
80104f58:	0f b6 c0             	movzbl %al,%eax
80104f5b:	89 d1                	mov    %edx,%ecx
80104f5d:	29 c1                	sub    %eax,%ecx
80104f5f:	89 c8                	mov    %ecx,%eax
80104f61:	eb 1c                	jmp    80104f7f <memcmp+0x5a>
    s1++, s2++;
80104f63:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104f67:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80104f6b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104f6f:	0f 95 c0             	setne  %al
80104f72:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104f76:	84 c0                	test   %al,%al
80104f78:	75 bf                	jne    80104f39 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80104f7a:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104f7f:	c9                   	leave  
80104f80:	c3                   	ret    

80104f81 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80104f81:	55                   	push   %ebp
80104f82:	89 e5                	mov    %esp,%ebp
80104f84:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80104f87:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f8a:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80104f8d:	8b 45 08             	mov    0x8(%ebp),%eax
80104f90:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
80104f93:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104f96:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104f99:	73 54                	jae    80104fef <memmove+0x6e>
80104f9b:	8b 45 10             	mov    0x10(%ebp),%eax
80104f9e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80104fa1:	01 d0                	add    %edx,%eax
80104fa3:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80104fa6:	76 47                	jbe    80104fef <memmove+0x6e>
    s += n;
80104fa8:	8b 45 10             	mov    0x10(%ebp),%eax
80104fab:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
80104fae:	8b 45 10             	mov    0x10(%ebp),%eax
80104fb1:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80104fb4:	eb 13                	jmp    80104fc9 <memmove+0x48>
      *--d = *--s;
80104fb6:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80104fba:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
80104fbe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fc1:	0f b6 10             	movzbl (%eax),%edx
80104fc4:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104fc7:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80104fc9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104fcd:	0f 95 c0             	setne  %al
80104fd0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104fd4:	84 c0                	test   %al,%al
80104fd6:	75 de                	jne    80104fb6 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80104fd8:	eb 25                	jmp    80104fff <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80104fda:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fdd:	0f b6 10             	movzbl (%eax),%edx
80104fe0:	8b 45 f8             	mov    -0x8(%ebp),%eax
80104fe3:	88 10                	mov    %dl,(%eax)
80104fe5:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80104fe9:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80104fed:	eb 01                	jmp    80104ff0 <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
80104fef:	90                   	nop
80104ff0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80104ff4:	0f 95 c0             	setne  %al
80104ff7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80104ffb:	84 c0                	test   %al,%al
80104ffd:	75 db                	jne    80104fda <memmove+0x59>
      *d++ = *s++;

  return dst;
80104fff:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105002:	c9                   	leave  
80105003:	c3                   	ret    

80105004 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80105004:	55                   	push   %ebp
80105005:	89 e5                	mov    %esp,%ebp
80105007:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
8010500a:	8b 45 10             	mov    0x10(%ebp),%eax
8010500d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105011:	8b 45 0c             	mov    0xc(%ebp),%eax
80105014:	89 44 24 04          	mov    %eax,0x4(%esp)
80105018:	8b 45 08             	mov    0x8(%ebp),%eax
8010501b:	89 04 24             	mov    %eax,(%esp)
8010501e:	e8 5e ff ff ff       	call   80104f81 <memmove>
}
80105023:	c9                   	leave  
80105024:	c3                   	ret    

80105025 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105025:	55                   	push   %ebp
80105026:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105028:	eb 0c                	jmp    80105036 <strncmp+0x11>
    n--, p++, q++;
8010502a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010502e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105032:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105036:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010503a:	74 1a                	je     80105056 <strncmp+0x31>
8010503c:	8b 45 08             	mov    0x8(%ebp),%eax
8010503f:	0f b6 00             	movzbl (%eax),%eax
80105042:	84 c0                	test   %al,%al
80105044:	74 10                	je     80105056 <strncmp+0x31>
80105046:	8b 45 08             	mov    0x8(%ebp),%eax
80105049:	0f b6 10             	movzbl (%eax),%edx
8010504c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010504f:	0f b6 00             	movzbl (%eax),%eax
80105052:	38 c2                	cmp    %al,%dl
80105054:	74 d4                	je     8010502a <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105056:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010505a:	75 07                	jne    80105063 <strncmp+0x3e>
    return 0;
8010505c:	b8 00 00 00 00       	mov    $0x0,%eax
80105061:	eb 18                	jmp    8010507b <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
80105063:	8b 45 08             	mov    0x8(%ebp),%eax
80105066:	0f b6 00             	movzbl (%eax),%eax
80105069:	0f b6 d0             	movzbl %al,%edx
8010506c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010506f:	0f b6 00             	movzbl (%eax),%eax
80105072:	0f b6 c0             	movzbl %al,%eax
80105075:	89 d1                	mov    %edx,%ecx
80105077:	29 c1                	sub    %eax,%ecx
80105079:	89 c8                	mov    %ecx,%eax
}
8010507b:	5d                   	pop    %ebp
8010507c:	c3                   	ret    

8010507d <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
8010507d:	55                   	push   %ebp
8010507e:	89 e5                	mov    %esp,%ebp
80105080:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
80105083:	8b 45 08             	mov    0x8(%ebp),%eax
80105086:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105089:	90                   	nop
8010508a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010508e:	0f 9f c0             	setg   %al
80105091:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105095:	84 c0                	test   %al,%al
80105097:	74 30                	je     801050c9 <strncpy+0x4c>
80105099:	8b 45 0c             	mov    0xc(%ebp),%eax
8010509c:	0f b6 10             	movzbl (%eax),%edx
8010509f:	8b 45 08             	mov    0x8(%ebp),%eax
801050a2:	88 10                	mov    %dl,(%eax)
801050a4:	8b 45 08             	mov    0x8(%ebp),%eax
801050a7:	0f b6 00             	movzbl (%eax),%eax
801050aa:	84 c0                	test   %al,%al
801050ac:	0f 95 c0             	setne  %al
801050af:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050b3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801050b7:	84 c0                	test   %al,%al
801050b9:	75 cf                	jne    8010508a <strncpy+0xd>
    ;
  while(n-- > 0)
801050bb:	eb 0c                	jmp    801050c9 <strncpy+0x4c>
    *s++ = 0;
801050bd:	8b 45 08             	mov    0x8(%ebp),%eax
801050c0:	c6 00 00             	movb   $0x0,(%eax)
801050c3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801050c7:	eb 01                	jmp    801050ca <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801050c9:	90                   	nop
801050ca:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050ce:	0f 9f c0             	setg   %al
801050d1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050d5:	84 c0                	test   %al,%al
801050d7:	75 e4                	jne    801050bd <strncpy+0x40>
    *s++ = 0;
  return os;
801050d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801050dc:	c9                   	leave  
801050dd:	c3                   	ret    

801050de <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801050de:	55                   	push   %ebp
801050df:	89 e5                	mov    %esp,%ebp
801050e1:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801050e4:	8b 45 08             	mov    0x8(%ebp),%eax
801050e7:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801050ea:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050ee:	7f 05                	jg     801050f5 <safestrcpy+0x17>
    return os;
801050f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
801050f3:	eb 35                	jmp    8010512a <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801050f5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801050f9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801050fd:	7e 22                	jle    80105121 <safestrcpy+0x43>
801050ff:	8b 45 0c             	mov    0xc(%ebp),%eax
80105102:	0f b6 10             	movzbl (%eax),%edx
80105105:	8b 45 08             	mov    0x8(%ebp),%eax
80105108:	88 10                	mov    %dl,(%eax)
8010510a:	8b 45 08             	mov    0x8(%ebp),%eax
8010510d:	0f b6 00             	movzbl (%eax),%eax
80105110:	84 c0                	test   %al,%al
80105112:	0f 95 c0             	setne  %al
80105115:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105119:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
8010511d:	84 c0                	test   %al,%al
8010511f:	75 d4                	jne    801050f5 <safestrcpy+0x17>
    ;
  *s = 0;
80105121:	8b 45 08             	mov    0x8(%ebp),%eax
80105124:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105127:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010512a:	c9                   	leave  
8010512b:	c3                   	ret    

8010512c <strlen>:

int
strlen(const char *s)
{
8010512c:	55                   	push   %ebp
8010512d:	89 e5                	mov    %esp,%ebp
8010512f:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105132:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105139:	eb 04                	jmp    8010513f <strlen+0x13>
8010513b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010513f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105142:	03 45 08             	add    0x8(%ebp),%eax
80105145:	0f b6 00             	movzbl (%eax),%eax
80105148:	84 c0                	test   %al,%al
8010514a:	75 ef                	jne    8010513b <strlen+0xf>
    ;
  return n;
8010514c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010514f:	c9                   	leave  
80105150:	c3                   	ret    
80105151:	00 00                	add    %al,(%eax)
	...

80105154 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105154:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105158:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
8010515c:	55                   	push   %ebp
  pushl %ebx
8010515d:	53                   	push   %ebx
  pushl %esi
8010515e:	56                   	push   %esi
  pushl %edi
8010515f:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
80105160:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
80105162:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105164:	5f                   	pop    %edi
  popl %esi
80105165:	5e                   	pop    %esi
  popl %ebx
80105166:	5b                   	pop    %ebx
  popl %ebp
80105167:	5d                   	pop    %ebp
  ret
80105168:	c3                   	ret    
80105169:	00 00                	add    %al,(%eax)
	...

8010516c <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
8010516c:	55                   	push   %ebp
8010516d:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
8010516f:	8b 45 08             	mov    0x8(%ebp),%eax
80105172:	8b 00                	mov    (%eax),%eax
80105174:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105177:	76 0f                	jbe    80105188 <fetchint+0x1c>
80105179:	8b 45 0c             	mov    0xc(%ebp),%eax
8010517c:	8d 50 04             	lea    0x4(%eax),%edx
8010517f:	8b 45 08             	mov    0x8(%ebp),%eax
80105182:	8b 00                	mov    (%eax),%eax
80105184:	39 c2                	cmp    %eax,%edx
80105186:	76 07                	jbe    8010518f <fetchint+0x23>
    return -1;
80105188:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010518d:	eb 0f                	jmp    8010519e <fetchint+0x32>
  *ip = *(int*)(addr);
8010518f:	8b 45 0c             	mov    0xc(%ebp),%eax
80105192:	8b 10                	mov    (%eax),%edx
80105194:	8b 45 10             	mov    0x10(%ebp),%eax
80105197:	89 10                	mov    %edx,(%eax)
  return 0;
80105199:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010519e:	5d                   	pop    %ebp
8010519f:	c3                   	ret    

801051a0 <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
801051a0:	55                   	push   %ebp
801051a1:	89 e5                	mov    %esp,%ebp
801051a3:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
801051a6:	8b 45 08             	mov    0x8(%ebp),%eax
801051a9:	8b 00                	mov    (%eax),%eax
801051ab:	3b 45 0c             	cmp    0xc(%ebp),%eax
801051ae:	77 07                	ja     801051b7 <fetchstr+0x17>
    return -1;
801051b0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801051b5:	eb 45                	jmp    801051fc <fetchstr+0x5c>
  *pp = (char*)addr;
801051b7:	8b 55 0c             	mov    0xc(%ebp),%edx
801051ba:	8b 45 10             	mov    0x10(%ebp),%eax
801051bd:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
801051bf:	8b 45 08             	mov    0x8(%ebp),%eax
801051c2:	8b 00                	mov    (%eax),%eax
801051c4:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
801051c7:	8b 45 10             	mov    0x10(%ebp),%eax
801051ca:	8b 00                	mov    (%eax),%eax
801051cc:	89 45 fc             	mov    %eax,-0x4(%ebp)
801051cf:	eb 1e                	jmp    801051ef <fetchstr+0x4f>
    if(*s == 0)
801051d1:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051d4:	0f b6 00             	movzbl (%eax),%eax
801051d7:	84 c0                	test   %al,%al
801051d9:	75 10                	jne    801051eb <fetchstr+0x4b>
      return s - *pp;
801051db:	8b 55 fc             	mov    -0x4(%ebp),%edx
801051de:	8b 45 10             	mov    0x10(%ebp),%eax
801051e1:	8b 00                	mov    (%eax),%eax
801051e3:	89 d1                	mov    %edx,%ecx
801051e5:	29 c1                	sub    %eax,%ecx
801051e7:	89 c8                	mov    %ecx,%eax
801051e9:	eb 11                	jmp    801051fc <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
801051eb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801051ef:	8b 45 fc             	mov    -0x4(%ebp),%eax
801051f2:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801051f5:	72 da                	jb     801051d1 <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801051f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801051fc:	c9                   	leave  
801051fd:	c3                   	ret    

801051fe <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801051fe:	55                   	push   %ebp
801051ff:	89 e5                	mov    %esp,%ebp
80105201:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
80105204:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010520a:	8b 40 18             	mov    0x18(%eax),%eax
8010520d:	8b 50 44             	mov    0x44(%eax),%edx
80105210:	8b 45 08             	mov    0x8(%ebp),%eax
80105213:	c1 e0 02             	shl    $0x2,%eax
80105216:	01 d0                	add    %edx,%eax
80105218:	8d 48 04             	lea    0x4(%eax),%ecx
8010521b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105221:	8b 55 0c             	mov    0xc(%ebp),%edx
80105224:	89 54 24 08          	mov    %edx,0x8(%esp)
80105228:	89 4c 24 04          	mov    %ecx,0x4(%esp)
8010522c:	89 04 24             	mov    %eax,(%esp)
8010522f:	e8 38 ff ff ff       	call   8010516c <fetchint>
}
80105234:	c9                   	leave  
80105235:	c3                   	ret    

80105236 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105236:	55                   	push   %ebp
80105237:	89 e5                	mov    %esp,%ebp
80105239:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
8010523c:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010523f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105243:	8b 45 08             	mov    0x8(%ebp),%eax
80105246:	89 04 24             	mov    %eax,(%esp)
80105249:	e8 b0 ff ff ff       	call   801051fe <argint>
8010524e:	85 c0                	test   %eax,%eax
80105250:	79 07                	jns    80105259 <argptr+0x23>
    return -1;
80105252:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105257:	eb 3d                	jmp    80105296 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105259:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010525c:	89 c2                	mov    %eax,%edx
8010525e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105264:	8b 00                	mov    (%eax),%eax
80105266:	39 c2                	cmp    %eax,%edx
80105268:	73 16                	jae    80105280 <argptr+0x4a>
8010526a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010526d:	89 c2                	mov    %eax,%edx
8010526f:	8b 45 10             	mov    0x10(%ebp),%eax
80105272:	01 c2                	add    %eax,%edx
80105274:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010527a:	8b 00                	mov    (%eax),%eax
8010527c:	39 c2                	cmp    %eax,%edx
8010527e:	76 07                	jbe    80105287 <argptr+0x51>
    return -1;
80105280:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105285:	eb 0f                	jmp    80105296 <argptr+0x60>
  *pp = (char*)i;
80105287:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010528a:	89 c2                	mov    %eax,%edx
8010528c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010528f:	89 10                	mov    %edx,(%eax)
  return 0;
80105291:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105296:	c9                   	leave  
80105297:	c3                   	ret    

80105298 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105298:	55                   	push   %ebp
80105299:	89 e5                	mov    %esp,%ebp
8010529b:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010529e:	8d 45 fc             	lea    -0x4(%ebp),%eax
801052a1:	89 44 24 04          	mov    %eax,0x4(%esp)
801052a5:	8b 45 08             	mov    0x8(%ebp),%eax
801052a8:	89 04 24             	mov    %eax,(%esp)
801052ab:	e8 4e ff ff ff       	call   801051fe <argint>
801052b0:	85 c0                	test   %eax,%eax
801052b2:	79 07                	jns    801052bb <argstr+0x23>
    return -1;
801052b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801052b9:	eb 1e                	jmp    801052d9 <argstr+0x41>
  return fetchstr(proc, addr, pp);
801052bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052be:	89 c2                	mov    %eax,%edx
801052c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801052c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801052cd:	89 54 24 04          	mov    %edx,0x4(%esp)
801052d1:	89 04 24             	mov    %eax,(%esp)
801052d4:	e8 c7 fe ff ff       	call   801051a0 <fetchstr>
}
801052d9:	c9                   	leave  
801052da:	c3                   	ret    

801052db <syscall>:
  
};

void
syscall(void)
{
801052db:	55                   	push   %ebp
801052dc:	89 e5                	mov    %esp,%ebp
801052de:	53                   	push   %ebx
801052df:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
801052e2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801052e8:	8b 40 18             	mov    0x18(%eax),%eax
801052eb:	8b 40 1c             	mov    0x1c(%eax),%eax
801052ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801052f1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801052f5:	78 2e                	js     80105325 <syscall+0x4a>
801052f7:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801052fb:	7f 28                	jg     80105325 <syscall+0x4a>
801052fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105300:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105307:	85 c0                	test   %eax,%eax
80105309:	74 1a                	je     80105325 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
8010530b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105311:	8b 58 18             	mov    0x18(%eax),%ebx
80105314:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105317:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010531e:	ff d0                	call   *%eax
80105320:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105323:	eb 73                	jmp    80105398 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
80105325:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
80105329:	7e 30                	jle    8010535b <syscall+0x80>
8010532b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010532e:	83 f8 16             	cmp    $0x16,%eax
80105331:	77 28                	ja     8010535b <syscall+0x80>
80105333:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105336:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
8010533d:	85 c0                	test   %eax,%eax
8010533f:	74 1a                	je     8010535b <syscall+0x80>
    proc->tf->eax = syscalls[num]();
80105341:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105347:	8b 58 18             	mov    0x18(%eax),%ebx
8010534a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010534d:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105354:	ff d0                	call   *%eax
80105356:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105359:	eb 3d                	jmp    80105398 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
8010535b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105361:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105364:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
8010536a:	8b 40 10             	mov    0x10(%eax),%eax
8010536d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105370:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105374:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105378:	89 44 24 04          	mov    %eax,0x4(%esp)
8010537c:	c7 04 24 a5 86 10 80 	movl   $0x801086a5,(%esp)
80105383:	e8 19 b0 ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105388:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010538e:	8b 40 18             	mov    0x18(%eax),%eax
80105391:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105398:	83 c4 24             	add    $0x24,%esp
8010539b:	5b                   	pop    %ebx
8010539c:	5d                   	pop    %ebp
8010539d:	c3                   	ret    
	...

801053a0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
801053a0:	55                   	push   %ebp
801053a1:	89 e5                	mov    %esp,%ebp
801053a3:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
801053a6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801053a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801053ad:	8b 45 08             	mov    0x8(%ebp),%eax
801053b0:	89 04 24             	mov    %eax,(%esp)
801053b3:	e8 46 fe ff ff       	call   801051fe <argint>
801053b8:	85 c0                	test   %eax,%eax
801053ba:	79 07                	jns    801053c3 <argfd+0x23>
    return -1;
801053bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053c1:	eb 50                	jmp    80105413 <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
801053c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053c6:	85 c0                	test   %eax,%eax
801053c8:	78 21                	js     801053eb <argfd+0x4b>
801053ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
801053cd:	83 f8 0f             	cmp    $0xf,%eax
801053d0:	7f 19                	jg     801053eb <argfd+0x4b>
801053d2:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801053d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801053db:	83 c2 08             	add    $0x8,%edx
801053de:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801053e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801053e5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801053e9:	75 07                	jne    801053f2 <argfd+0x52>
    return -1;
801053eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801053f0:	eb 21                	jmp    80105413 <argfd+0x73>
  if(pfd)
801053f2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801053f6:	74 08                	je     80105400 <argfd+0x60>
    *pfd = fd;
801053f8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801053fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801053fe:	89 10                	mov    %edx,(%eax)
  if(pf)
80105400:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105404:	74 08                	je     8010540e <argfd+0x6e>
    *pf = f;
80105406:	8b 45 10             	mov    0x10(%ebp),%eax
80105409:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010540c:	89 10                	mov    %edx,(%eax)
  return 0;
8010540e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105413:	c9                   	leave  
80105414:	c3                   	ret    

80105415 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
80105415:	55                   	push   %ebp
80105416:	89 e5                	mov    %esp,%ebp
80105418:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
8010541b:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105422:	eb 30                	jmp    80105454 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
80105424:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010542a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010542d:	83 c2 08             	add    $0x8,%edx
80105430:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80105434:	85 c0                	test   %eax,%eax
80105436:	75 18                	jne    80105450 <fdalloc+0x3b>
      proc->ofile[fd] = f;
80105438:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010543e:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105441:	8d 4a 08             	lea    0x8(%edx),%ecx
80105444:	8b 55 08             	mov    0x8(%ebp),%edx
80105447:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
8010544b:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010544e:	eb 0f                	jmp    8010545f <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105450:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105454:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105458:	7e ca                	jle    80105424 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
8010545a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010545f:	c9                   	leave  
80105460:	c3                   	ret    

80105461 <sys_dup>:

int
sys_dup(void)
{
80105461:	55                   	push   %ebp
80105462:	89 e5                	mov    %esp,%ebp
80105464:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105467:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010546a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010546e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105475:	00 
80105476:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010547d:	e8 1e ff ff ff       	call   801053a0 <argfd>
80105482:	85 c0                	test   %eax,%eax
80105484:	79 07                	jns    8010548d <sys_dup+0x2c>
    return -1;
80105486:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010548b:	eb 29                	jmp    801054b6 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010548d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105490:	89 04 24             	mov    %eax,(%esp)
80105493:	e8 7d ff ff ff       	call   80105415 <fdalloc>
80105498:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010549b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010549f:	79 07                	jns    801054a8 <sys_dup+0x47>
    return -1;
801054a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054a6:	eb 0e                	jmp    801054b6 <sys_dup+0x55>
  filedup(f);
801054a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054ab:	89 04 24             	mov    %eax,(%esp)
801054ae:	e8 1d bb ff ff       	call   80100fd0 <filedup>
  return fd;
801054b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801054b6:	c9                   	leave  
801054b7:	c3                   	ret    

801054b8 <sys_read>:

int
sys_read(void)
{
801054b8:	55                   	push   %ebp
801054b9:	89 e5                	mov    %esp,%ebp
801054bb:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801054be:	8d 45 f4             	lea    -0xc(%ebp),%eax
801054c1:	89 44 24 08          	mov    %eax,0x8(%esp)
801054c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801054cc:	00 
801054cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801054d4:	e8 c7 fe ff ff       	call   801053a0 <argfd>
801054d9:	85 c0                	test   %eax,%eax
801054db:	78 35                	js     80105512 <sys_read+0x5a>
801054dd:	8d 45 f0             	lea    -0x10(%ebp),%eax
801054e0:	89 44 24 04          	mov    %eax,0x4(%esp)
801054e4:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801054eb:	e8 0e fd ff ff       	call   801051fe <argint>
801054f0:	85 c0                	test   %eax,%eax
801054f2:	78 1e                	js     80105512 <sys_read+0x5a>
801054f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054f7:	89 44 24 08          	mov    %eax,0x8(%esp)
801054fb:	8d 45 ec             	lea    -0x14(%ebp),%eax
801054fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105502:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105509:	e8 28 fd ff ff       	call   80105236 <argptr>
8010550e:	85 c0                	test   %eax,%eax
80105510:	79 07                	jns    80105519 <sys_read+0x61>
    return -1;
80105512:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105517:	eb 19                	jmp    80105532 <sys_read+0x7a>
  return fileread(f, p, n);
80105519:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010551c:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010551f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105522:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105526:	89 54 24 04          	mov    %edx,0x4(%esp)
8010552a:	89 04 24             	mov    %eax,(%esp)
8010552d:	e8 0b bc ff ff       	call   8010113d <fileread>
}
80105532:	c9                   	leave  
80105533:	c3                   	ret    

80105534 <sys_write>:

int
sys_write(void)
{
80105534:	55                   	push   %ebp
80105535:	89 e5                	mov    %esp,%ebp
80105537:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
8010553a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010553d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105541:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105548:	00 
80105549:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105550:	e8 4b fe ff ff       	call   801053a0 <argfd>
80105555:	85 c0                	test   %eax,%eax
80105557:	78 35                	js     8010558e <sys_write+0x5a>
80105559:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010555c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105560:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105567:	e8 92 fc ff ff       	call   801051fe <argint>
8010556c:	85 c0                	test   %eax,%eax
8010556e:	78 1e                	js     8010558e <sys_write+0x5a>
80105570:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105573:	89 44 24 08          	mov    %eax,0x8(%esp)
80105577:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010557a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010557e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105585:	e8 ac fc ff ff       	call   80105236 <argptr>
8010558a:	85 c0                	test   %eax,%eax
8010558c:	79 07                	jns    80105595 <sys_write+0x61>
    return -1;
8010558e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105593:	eb 19                	jmp    801055ae <sys_write+0x7a>
  return filewrite(f, p, n);
80105595:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105598:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010559b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010559e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801055a2:	89 54 24 04          	mov    %edx,0x4(%esp)
801055a6:	89 04 24             	mov    %eax,(%esp)
801055a9:	e8 4b bc ff ff       	call   801011f9 <filewrite>
}
801055ae:	c9                   	leave  
801055af:	c3                   	ret    

801055b0 <sys_close>:

int
sys_close(void)
{
801055b0:	55                   	push   %ebp
801055b1:	89 e5                	mov    %esp,%ebp
801055b3:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
801055b6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801055b9:	89 44 24 08          	mov    %eax,0x8(%esp)
801055bd:	8d 45 f4             	lea    -0xc(%ebp),%eax
801055c0:	89 44 24 04          	mov    %eax,0x4(%esp)
801055c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801055cb:	e8 d0 fd ff ff       	call   801053a0 <argfd>
801055d0:	85 c0                	test   %eax,%eax
801055d2:	79 07                	jns    801055db <sys_close+0x2b>
    return -1;
801055d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055d9:	eb 24                	jmp    801055ff <sys_close+0x4f>
  proc->ofile[fd] = 0;
801055db:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801055e1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801055e4:	83 c2 08             	add    $0x8,%edx
801055e7:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801055ee:	00 
  fileclose(f);
801055ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055f2:	89 04 24             	mov    %eax,(%esp)
801055f5:	e8 1e ba ff ff       	call   80101018 <fileclose>
  return 0;
801055fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801055ff:	c9                   	leave  
80105600:	c3                   	ret    

80105601 <sys_fstat>:

int
sys_fstat(void)
{
80105601:	55                   	push   %ebp
80105602:	89 e5                	mov    %esp,%ebp
80105604:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105607:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010560a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010560e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105615:	00 
80105616:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010561d:	e8 7e fd ff ff       	call   801053a0 <argfd>
80105622:	85 c0                	test   %eax,%eax
80105624:	78 1f                	js     80105645 <sys_fstat+0x44>
80105626:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010562d:	00 
8010562e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105631:	89 44 24 04          	mov    %eax,0x4(%esp)
80105635:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010563c:	e8 f5 fb ff ff       	call   80105236 <argptr>
80105641:	85 c0                	test   %eax,%eax
80105643:	79 07                	jns    8010564c <sys_fstat+0x4b>
    return -1;
80105645:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010564a:	eb 12                	jmp    8010565e <sys_fstat+0x5d>
  return filestat(f, st);
8010564c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010564f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105652:	89 54 24 04          	mov    %edx,0x4(%esp)
80105656:	89 04 24             	mov    %eax,(%esp)
80105659:	e8 90 ba ff ff       	call   801010ee <filestat>
}
8010565e:	c9                   	leave  
8010565f:	c3                   	ret    

80105660 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105660:	55                   	push   %ebp
80105661:	89 e5                	mov    %esp,%ebp
80105663:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105666:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105669:	89 44 24 04          	mov    %eax,0x4(%esp)
8010566d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105674:	e8 1f fc ff ff       	call   80105298 <argstr>
80105679:	85 c0                	test   %eax,%eax
8010567b:	78 17                	js     80105694 <sys_link+0x34>
8010567d:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105680:	89 44 24 04          	mov    %eax,0x4(%esp)
80105684:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010568b:	e8 08 fc ff ff       	call   80105298 <argstr>
80105690:	85 c0                	test   %eax,%eax
80105692:	79 0a                	jns    8010569e <sys_link+0x3e>
    return -1;
80105694:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105699:	e9 3c 01 00 00       	jmp    801057da <sys_link+0x17a>
  if((ip = namei(old)) == 0)
8010569e:	8b 45 d8             	mov    -0x28(%ebp),%eax
801056a1:	89 04 24             	mov    %eax,(%esp)
801056a4:	e8 b5 cd ff ff       	call   8010245e <namei>
801056a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801056ac:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801056b0:	75 0a                	jne    801056bc <sys_link+0x5c>
    return -1;
801056b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056b7:	e9 1e 01 00 00       	jmp    801057da <sys_link+0x17a>

  begin_trans();
801056bc:	e8 b0 db ff ff       	call   80103271 <begin_trans>

  ilock(ip);
801056c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056c4:	89 04 24             	mov    %eax,(%esp)
801056c7:	e8 f0 c1 ff ff       	call   801018bc <ilock>
  if(ip->type == T_DIR){
801056cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056cf:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801056d3:	66 83 f8 01          	cmp    $0x1,%ax
801056d7:	75 1a                	jne    801056f3 <sys_link+0x93>
    iunlockput(ip);
801056d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056dc:	89 04 24             	mov    %eax,(%esp)
801056df:	e8 5c c4 ff ff       	call   80101b40 <iunlockput>
    commit_trans();
801056e4:	e8 d1 db ff ff       	call   801032ba <commit_trans>
    return -1;
801056e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801056ee:	e9 e7 00 00 00       	jmp    801057da <sys_link+0x17a>
  }

  ip->nlink++;
801056f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056f6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801056fa:	8d 50 01             	lea    0x1(%eax),%edx
801056fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105700:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105704:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105707:	89 04 24             	mov    %eax,(%esp)
8010570a:	e8 f1 bf ff ff       	call   80101700 <iupdate>
  iunlock(ip);
8010570f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105712:	89 04 24             	mov    %eax,(%esp)
80105715:	e8 f0 c2 ff ff       	call   80101a0a <iunlock>

  if((dp = nameiparent(new, name)) == 0)
8010571a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010571d:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105720:	89 54 24 04          	mov    %edx,0x4(%esp)
80105724:	89 04 24             	mov    %eax,(%esp)
80105727:	e8 54 cd ff ff       	call   80102480 <nameiparent>
8010572c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010572f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105733:	74 68                	je     8010579d <sys_link+0x13d>
    goto bad;
  ilock(dp);
80105735:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105738:	89 04 24             	mov    %eax,(%esp)
8010573b:	e8 7c c1 ff ff       	call   801018bc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105740:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105743:	8b 10                	mov    (%eax),%edx
80105745:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105748:	8b 00                	mov    (%eax),%eax
8010574a:	39 c2                	cmp    %eax,%edx
8010574c:	75 20                	jne    8010576e <sys_link+0x10e>
8010574e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105751:	8b 40 04             	mov    0x4(%eax),%eax
80105754:	89 44 24 08          	mov    %eax,0x8(%esp)
80105758:	8d 45 e2             	lea    -0x1e(%ebp),%eax
8010575b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010575f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105762:	89 04 24             	mov    %eax,(%esp)
80105765:	e8 33 ca ff ff       	call   8010219d <dirlink>
8010576a:	85 c0                	test   %eax,%eax
8010576c:	79 0d                	jns    8010577b <sys_link+0x11b>
    iunlockput(dp);
8010576e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105771:	89 04 24             	mov    %eax,(%esp)
80105774:	e8 c7 c3 ff ff       	call   80101b40 <iunlockput>
    goto bad;
80105779:	eb 23                	jmp    8010579e <sys_link+0x13e>
  }
  iunlockput(dp);
8010577b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010577e:	89 04 24             	mov    %eax,(%esp)
80105781:	e8 ba c3 ff ff       	call   80101b40 <iunlockput>
  iput(ip);
80105786:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105789:	89 04 24             	mov    %eax,(%esp)
8010578c:	e8 de c2 ff ff       	call   80101a6f <iput>

  commit_trans();
80105791:	e8 24 db ff ff       	call   801032ba <commit_trans>

  return 0;
80105796:	b8 00 00 00 00       	mov    $0x0,%eax
8010579b:	eb 3d                	jmp    801057da <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
8010579d:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
8010579e:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057a1:	89 04 24             	mov    %eax,(%esp)
801057a4:	e8 13 c1 ff ff       	call   801018bc <ilock>
  ip->nlink--;
801057a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ac:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801057b0:	8d 50 ff             	lea    -0x1(%eax),%edx
801057b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057b6:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801057ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057bd:	89 04 24             	mov    %eax,(%esp)
801057c0:	e8 3b bf ff ff       	call   80101700 <iupdate>
  iunlockput(ip);
801057c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057c8:	89 04 24             	mov    %eax,(%esp)
801057cb:	e8 70 c3 ff ff       	call   80101b40 <iunlockput>
  commit_trans();
801057d0:	e8 e5 da ff ff       	call   801032ba <commit_trans>
  return -1;
801057d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801057da:	c9                   	leave  
801057db:	c3                   	ret    

801057dc <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
801057dc:	55                   	push   %ebp
801057dd:	89 e5                	mov    %esp,%ebp
801057df:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
801057e2:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
801057e9:	eb 4b                	jmp    80105836 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801057eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ee:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
801057f5:	00 
801057f6:	89 44 24 08          	mov    %eax,0x8(%esp)
801057fa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801057fd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105801:	8b 45 08             	mov    0x8(%ebp),%eax
80105804:	89 04 24             	mov    %eax,(%esp)
80105807:	e8 a6 c5 ff ff       	call   80101db2 <readi>
8010580c:	83 f8 10             	cmp    $0x10,%eax
8010580f:	74 0c                	je     8010581d <isdirempty+0x41>
      panic("isdirempty: readi");
80105811:	c7 04 24 c1 86 10 80 	movl   $0x801086c1,(%esp)
80105818:	e8 20 ad ff ff       	call   8010053d <panic>
    if(de.inum != 0)
8010581d:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105821:	66 85 c0             	test   %ax,%ax
80105824:	74 07                	je     8010582d <isdirempty+0x51>
      return 0;
80105826:	b8 00 00 00 00       	mov    $0x0,%eax
8010582b:	eb 1b                	jmp    80105848 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
8010582d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105830:	83 c0 10             	add    $0x10,%eax
80105833:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105836:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105839:	8b 45 08             	mov    0x8(%ebp),%eax
8010583c:	8b 40 18             	mov    0x18(%eax),%eax
8010583f:	39 c2                	cmp    %eax,%edx
80105841:	72 a8                	jb     801057eb <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105843:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105848:	c9                   	leave  
80105849:	c3                   	ret    

8010584a <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
8010584a:	55                   	push   %ebp
8010584b:	89 e5                	mov    %esp,%ebp
8010584d:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105850:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105853:	89 44 24 04          	mov    %eax,0x4(%esp)
80105857:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010585e:	e8 35 fa ff ff       	call   80105298 <argstr>
80105863:	85 c0                	test   %eax,%eax
80105865:	79 0a                	jns    80105871 <sys_unlink+0x27>
    return -1;
80105867:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010586c:	e9 aa 01 00 00       	jmp    80105a1b <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105871:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105874:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105877:	89 54 24 04          	mov    %edx,0x4(%esp)
8010587b:	89 04 24             	mov    %eax,(%esp)
8010587e:	e8 fd cb ff ff       	call   80102480 <nameiparent>
80105883:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105886:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010588a:	75 0a                	jne    80105896 <sys_unlink+0x4c>
    return -1;
8010588c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105891:	e9 85 01 00 00       	jmp    80105a1b <sys_unlink+0x1d1>

  begin_trans();
80105896:	e8 d6 d9 ff ff       	call   80103271 <begin_trans>

  ilock(dp);
8010589b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010589e:	89 04 24             	mov    %eax,(%esp)
801058a1:	e8 16 c0 ff ff       	call   801018bc <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
801058a6:	c7 44 24 04 d3 86 10 	movl   $0x801086d3,0x4(%esp)
801058ad:	80 
801058ae:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801058b1:	89 04 24             	mov    %eax,(%esp)
801058b4:	e8 fa c7 ff ff       	call   801020b3 <namecmp>
801058b9:	85 c0                	test   %eax,%eax
801058bb:	0f 84 45 01 00 00    	je     80105a06 <sys_unlink+0x1bc>
801058c1:	c7 44 24 04 d5 86 10 	movl   $0x801086d5,0x4(%esp)
801058c8:	80 
801058c9:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801058cc:	89 04 24             	mov    %eax,(%esp)
801058cf:	e8 df c7 ff ff       	call   801020b3 <namecmp>
801058d4:	85 c0                	test   %eax,%eax
801058d6:	0f 84 2a 01 00 00    	je     80105a06 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
801058dc:	8d 45 c8             	lea    -0x38(%ebp),%eax
801058df:	89 44 24 08          	mov    %eax,0x8(%esp)
801058e3:	8d 45 d2             	lea    -0x2e(%ebp),%eax
801058e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801058ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058ed:	89 04 24             	mov    %eax,(%esp)
801058f0:	e8 e0 c7 ff ff       	call   801020d5 <dirlookup>
801058f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
801058f8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801058fc:	0f 84 03 01 00 00    	je     80105a05 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80105902:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105905:	89 04 24             	mov    %eax,(%esp)
80105908:	e8 af bf ff ff       	call   801018bc <ilock>

  if(ip->nlink < 1)
8010590d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105910:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105914:	66 85 c0             	test   %ax,%ax
80105917:	7f 0c                	jg     80105925 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80105919:	c7 04 24 d8 86 10 80 	movl   $0x801086d8,(%esp)
80105920:	e8 18 ac ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105925:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105928:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010592c:	66 83 f8 01          	cmp    $0x1,%ax
80105930:	75 1f                	jne    80105951 <sys_unlink+0x107>
80105932:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105935:	89 04 24             	mov    %eax,(%esp)
80105938:	e8 9f fe ff ff       	call   801057dc <isdirempty>
8010593d:	85 c0                	test   %eax,%eax
8010593f:	75 10                	jne    80105951 <sys_unlink+0x107>
    iunlockput(ip);
80105941:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105944:	89 04 24             	mov    %eax,(%esp)
80105947:	e8 f4 c1 ff ff       	call   80101b40 <iunlockput>
    goto bad;
8010594c:	e9 b5 00 00 00       	jmp    80105a06 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105951:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105958:	00 
80105959:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105960:	00 
80105961:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105964:	89 04 24             	mov    %eax,(%esp)
80105967:	e8 42 f5 ff ff       	call   80104eae <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010596c:	8b 45 c8             	mov    -0x38(%ebp),%eax
8010596f:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105976:	00 
80105977:	89 44 24 08          	mov    %eax,0x8(%esp)
8010597b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010597e:	89 44 24 04          	mov    %eax,0x4(%esp)
80105982:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105985:	89 04 24             	mov    %eax,(%esp)
80105988:	e8 90 c5 ff ff       	call   80101f1d <writei>
8010598d:	83 f8 10             	cmp    $0x10,%eax
80105990:	74 0c                	je     8010599e <sys_unlink+0x154>
    panic("unlink: writei");
80105992:	c7 04 24 ea 86 10 80 	movl   $0x801086ea,(%esp)
80105999:	e8 9f ab ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
8010599e:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059a1:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801059a5:	66 83 f8 01          	cmp    $0x1,%ax
801059a9:	75 1c                	jne    801059c7 <sys_unlink+0x17d>
    dp->nlink--;
801059ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ae:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059b2:	8d 50 ff             	lea    -0x1(%eax),%edx
801059b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059b8:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
801059bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059bf:	89 04 24             	mov    %eax,(%esp)
801059c2:	e8 39 bd ff ff       	call   80101700 <iupdate>
  }
  iunlockput(dp);
801059c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059ca:	89 04 24             	mov    %eax,(%esp)
801059cd:	e8 6e c1 ff ff       	call   80101b40 <iunlockput>

  ip->nlink--;
801059d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059d5:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801059d9:	8d 50 ff             	lea    -0x1(%eax),%edx
801059dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059df:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
801059e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059e6:	89 04 24             	mov    %eax,(%esp)
801059e9:	e8 12 bd ff ff       	call   80101700 <iupdate>
  iunlockput(ip);
801059ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059f1:	89 04 24             	mov    %eax,(%esp)
801059f4:	e8 47 c1 ff ff       	call   80101b40 <iunlockput>

  commit_trans();
801059f9:	e8 bc d8 ff ff       	call   801032ba <commit_trans>

  return 0;
801059fe:	b8 00 00 00 00       	mov    $0x0,%eax
80105a03:	eb 16                	jmp    80105a1b <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105a05:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105a06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a09:	89 04 24             	mov    %eax,(%esp)
80105a0c:	e8 2f c1 ff ff       	call   80101b40 <iunlockput>
  commit_trans();
80105a11:	e8 a4 d8 ff ff       	call   801032ba <commit_trans>
  return -1;
80105a16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a1b:	c9                   	leave  
80105a1c:	c3                   	ret    

80105a1d <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105a1d:	55                   	push   %ebp
80105a1e:	89 e5                	mov    %esp,%ebp
80105a20:	83 ec 48             	sub    $0x48,%esp
80105a23:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105a26:	8b 55 10             	mov    0x10(%ebp),%edx
80105a29:	8b 45 14             	mov    0x14(%ebp),%eax
80105a2c:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105a30:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105a34:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105a38:	8d 45 de             	lea    -0x22(%ebp),%eax
80105a3b:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a3f:	8b 45 08             	mov    0x8(%ebp),%eax
80105a42:	89 04 24             	mov    %eax,(%esp)
80105a45:	e8 36 ca ff ff       	call   80102480 <nameiparent>
80105a4a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a4d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a51:	75 0a                	jne    80105a5d <create+0x40>
    return 0;
80105a53:	b8 00 00 00 00       	mov    $0x0,%eax
80105a58:	e9 7e 01 00 00       	jmp    80105bdb <create+0x1be>
  ilock(dp);
80105a5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a60:	89 04 24             	mov    %eax,(%esp)
80105a63:	e8 54 be ff ff       	call   801018bc <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80105a68:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105a6b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a6f:	8d 45 de             	lea    -0x22(%ebp),%eax
80105a72:	89 44 24 04          	mov    %eax,0x4(%esp)
80105a76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a79:	89 04 24             	mov    %eax,(%esp)
80105a7c:	e8 54 c6 ff ff       	call   801020d5 <dirlookup>
80105a81:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105a84:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105a88:	74 47                	je     80105ad1 <create+0xb4>
    iunlockput(dp);
80105a8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a8d:	89 04 24             	mov    %eax,(%esp)
80105a90:	e8 ab c0 ff ff       	call   80101b40 <iunlockput>
    ilock(ip);
80105a95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a98:	89 04 24             	mov    %eax,(%esp)
80105a9b:	e8 1c be ff ff       	call   801018bc <ilock>
    if(type == T_FILE && ip->type == T_FILE)
80105aa0:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105aa5:	75 15                	jne    80105abc <create+0x9f>
80105aa7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105aaa:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105aae:	66 83 f8 02          	cmp    $0x2,%ax
80105ab2:	75 08                	jne    80105abc <create+0x9f>
      return ip;
80105ab4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ab7:	e9 1f 01 00 00       	jmp    80105bdb <create+0x1be>
    iunlockput(ip);
80105abc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105abf:	89 04 24             	mov    %eax,(%esp)
80105ac2:	e8 79 c0 ff ff       	call   80101b40 <iunlockput>
    return 0;
80105ac7:	b8 00 00 00 00       	mov    $0x0,%eax
80105acc:	e9 0a 01 00 00       	jmp    80105bdb <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105ad1:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105ad5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad8:	8b 00                	mov    (%eax),%eax
80105ada:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ade:	89 04 24             	mov    %eax,(%esp)
80105ae1:	e8 3d bb ff ff       	call   80101623 <ialloc>
80105ae6:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ae9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105aed:	75 0c                	jne    80105afb <create+0xde>
    panic("create: ialloc");
80105aef:	c7 04 24 f9 86 10 80 	movl   $0x801086f9,(%esp)
80105af6:	e8 42 aa ff ff       	call   8010053d <panic>

  ilock(ip);
80105afb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105afe:	89 04 24             	mov    %eax,(%esp)
80105b01:	e8 b6 bd ff ff       	call   801018bc <ilock>
  ip->major = major;
80105b06:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b09:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105b0d:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
80105b11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b14:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105b18:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
80105b1c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b1f:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
80105b25:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b28:	89 04 24             	mov    %eax,(%esp)
80105b2b:	e8 d0 bb ff ff       	call   80101700 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
80105b30:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105b35:	75 6a                	jne    80105ba1 <create+0x184>
    dp->nlink++;  // for ".."
80105b37:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b3a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105b3e:	8d 50 01             	lea    0x1(%eax),%edx
80105b41:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b44:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105b48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b4b:	89 04 24             	mov    %eax,(%esp)
80105b4e:	e8 ad bb ff ff       	call   80101700 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105b53:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b56:	8b 40 04             	mov    0x4(%eax),%eax
80105b59:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b5d:	c7 44 24 04 d3 86 10 	movl   $0x801086d3,0x4(%esp)
80105b64:	80 
80105b65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b68:	89 04 24             	mov    %eax,(%esp)
80105b6b:	e8 2d c6 ff ff       	call   8010219d <dirlink>
80105b70:	85 c0                	test   %eax,%eax
80105b72:	78 21                	js     80105b95 <create+0x178>
80105b74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b77:	8b 40 04             	mov    0x4(%eax),%eax
80105b7a:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b7e:	c7 44 24 04 d5 86 10 	movl   $0x801086d5,0x4(%esp)
80105b85:	80 
80105b86:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b89:	89 04 24             	mov    %eax,(%esp)
80105b8c:	e8 0c c6 ff ff       	call   8010219d <dirlink>
80105b91:	85 c0                	test   %eax,%eax
80105b93:	79 0c                	jns    80105ba1 <create+0x184>
      panic("create dots");
80105b95:	c7 04 24 08 87 10 80 	movl   $0x80108708,(%esp)
80105b9c:	e8 9c a9 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105ba1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ba4:	8b 40 04             	mov    0x4(%eax),%eax
80105ba7:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bab:	8d 45 de             	lea    -0x22(%ebp),%eax
80105bae:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bb2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bb5:	89 04 24             	mov    %eax,(%esp)
80105bb8:	e8 e0 c5 ff ff       	call   8010219d <dirlink>
80105bbd:	85 c0                	test   %eax,%eax
80105bbf:	79 0c                	jns    80105bcd <create+0x1b0>
    panic("create: dirlink");
80105bc1:	c7 04 24 14 87 10 80 	movl   $0x80108714,(%esp)
80105bc8:	e8 70 a9 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80105bcd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105bd0:	89 04 24             	mov    %eax,(%esp)
80105bd3:	e8 68 bf ff ff       	call   80101b40 <iunlockput>

  return ip;
80105bd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105bdb:	c9                   	leave  
80105bdc:	c3                   	ret    

80105bdd <sys_open>:

int
sys_open(void)
{
80105bdd:	55                   	push   %ebp
80105bde:	89 e5                	mov    %esp,%ebp
80105be0:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105be3:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105be6:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105bf1:	e8 a2 f6 ff ff       	call   80105298 <argstr>
80105bf6:	85 c0                	test   %eax,%eax
80105bf8:	78 17                	js     80105c11 <sys_open+0x34>
80105bfa:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105bfd:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c01:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105c08:	e8 f1 f5 ff ff       	call   801051fe <argint>
80105c0d:	85 c0                	test   %eax,%eax
80105c0f:	79 0a                	jns    80105c1b <sys_open+0x3e>
    return -1;
80105c11:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c16:	e9 46 01 00 00       	jmp    80105d61 <sys_open+0x184>
  if(omode & O_CREATE){
80105c1b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105c1e:	25 00 02 00 00       	and    $0x200,%eax
80105c23:	85 c0                	test   %eax,%eax
80105c25:	74 40                	je     80105c67 <sys_open+0x8a>
    begin_trans();
80105c27:	e8 45 d6 ff ff       	call   80103271 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
80105c2c:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c2f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105c36:	00 
80105c37:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105c3e:	00 
80105c3f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80105c46:	00 
80105c47:	89 04 24             	mov    %eax,(%esp)
80105c4a:	e8 ce fd ff ff       	call   80105a1d <create>
80105c4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
80105c52:	e8 63 d6 ff ff       	call   801032ba <commit_trans>
    if(ip == 0)
80105c57:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c5b:	75 5c                	jne    80105cb9 <sys_open+0xdc>
      return -1;
80105c5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c62:	e9 fa 00 00 00       	jmp    80105d61 <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80105c67:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105c6a:	89 04 24             	mov    %eax,(%esp)
80105c6d:	e8 ec c7 ff ff       	call   8010245e <namei>
80105c72:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c75:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c79:	75 0a                	jne    80105c85 <sys_open+0xa8>
      return -1;
80105c7b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c80:	e9 dc 00 00 00       	jmp    80105d61 <sys_open+0x184>
    ilock(ip);
80105c85:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c88:	89 04 24             	mov    %eax,(%esp)
80105c8b:	e8 2c bc ff ff       	call   801018bc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
80105c90:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c93:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c97:	66 83 f8 01          	cmp    $0x1,%ax
80105c9b:	75 1c                	jne    80105cb9 <sys_open+0xdc>
80105c9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ca0:	85 c0                	test   %eax,%eax
80105ca2:	74 15                	je     80105cb9 <sys_open+0xdc>
      iunlockput(ip);
80105ca4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ca7:	89 04 24             	mov    %eax,(%esp)
80105caa:	e8 91 be ff ff       	call   80101b40 <iunlockput>
      return -1;
80105caf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cb4:	e9 a8 00 00 00       	jmp    80105d61 <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105cb9:	e8 b2 b2 ff ff       	call   80100f70 <filealloc>
80105cbe:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105cc1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105cc5:	74 14                	je     80105cdb <sys_open+0xfe>
80105cc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cca:	89 04 24             	mov    %eax,(%esp)
80105ccd:	e8 43 f7 ff ff       	call   80105415 <fdalloc>
80105cd2:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105cd5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105cd9:	79 23                	jns    80105cfe <sys_open+0x121>
    if(f)
80105cdb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105cdf:	74 0b                	je     80105cec <sys_open+0x10f>
      fileclose(f);
80105ce1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ce4:	89 04 24             	mov    %eax,(%esp)
80105ce7:	e8 2c b3 ff ff       	call   80101018 <fileclose>
    iunlockput(ip);
80105cec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cef:	89 04 24             	mov    %eax,(%esp)
80105cf2:	e8 49 be ff ff       	call   80101b40 <iunlockput>
    return -1;
80105cf7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105cfc:	eb 63                	jmp    80105d61 <sys_open+0x184>
  }
  iunlock(ip);
80105cfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d01:	89 04 24             	mov    %eax,(%esp)
80105d04:	e8 01 bd ff ff       	call   80101a0a <iunlock>

  f->type = FD_INODE;
80105d09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d0c:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105d12:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d15:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105d18:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105d1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d1e:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105d25:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d28:	83 e0 01             	and    $0x1,%eax
80105d2b:	85 c0                	test   %eax,%eax
80105d2d:	0f 94 c2             	sete   %dl
80105d30:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d33:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80105d36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d39:	83 e0 01             	and    $0x1,%eax
80105d3c:	84 c0                	test   %al,%al
80105d3e:	75 0a                	jne    80105d4a <sys_open+0x16d>
80105d40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105d43:	83 e0 02             	and    $0x2,%eax
80105d46:	85 c0                	test   %eax,%eax
80105d48:	74 07                	je     80105d51 <sys_open+0x174>
80105d4a:	b8 01 00 00 00       	mov    $0x1,%eax
80105d4f:	eb 05                	jmp    80105d56 <sys_open+0x179>
80105d51:	b8 00 00 00 00       	mov    $0x0,%eax
80105d56:	89 c2                	mov    %eax,%edx
80105d58:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d5b:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
80105d5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
80105d61:	c9                   	leave  
80105d62:	c3                   	ret    

80105d63 <sys_mkdir>:

int
sys_mkdir(void)
{
80105d63:	55                   	push   %ebp
80105d64:	89 e5                	mov    %esp,%ebp
80105d66:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80105d69:	e8 03 d5 ff ff       	call   80103271 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
80105d6e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105d71:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d75:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105d7c:	e8 17 f5 ff ff       	call   80105298 <argstr>
80105d81:	85 c0                	test   %eax,%eax
80105d83:	78 2c                	js     80105db1 <sys_mkdir+0x4e>
80105d85:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d88:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
80105d8f:	00 
80105d90:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80105d97:	00 
80105d98:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80105d9f:	00 
80105da0:	89 04 24             	mov    %eax,(%esp)
80105da3:	e8 75 fc ff ff       	call   80105a1d <create>
80105da8:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105dab:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105daf:	75 0c                	jne    80105dbd <sys_mkdir+0x5a>
    commit_trans();
80105db1:	e8 04 d5 ff ff       	call   801032ba <commit_trans>
    return -1;
80105db6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105dbb:	eb 15                	jmp    80105dd2 <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80105dbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dc0:	89 04 24             	mov    %eax,(%esp)
80105dc3:	e8 78 bd ff ff       	call   80101b40 <iunlockput>
  commit_trans();
80105dc8:	e8 ed d4 ff ff       	call   801032ba <commit_trans>
  return 0;
80105dcd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105dd2:	c9                   	leave  
80105dd3:	c3                   	ret    

80105dd4 <sys_mknod>:

int
sys_mknod(void)
{
80105dd4:	55                   	push   %ebp
80105dd5:	89 e5                	mov    %esp,%ebp
80105dd7:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80105dda:	e8 92 d4 ff ff       	call   80103271 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
80105ddf:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105de2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105de6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105ded:	e8 a6 f4 ff ff       	call   80105298 <argstr>
80105df2:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105df5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105df9:	78 5e                	js     80105e59 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
80105dfb:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105dfe:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e02:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105e09:	e8 f0 f3 ff ff       	call   801051fe <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
80105e0e:	85 c0                	test   %eax,%eax
80105e10:	78 47                	js     80105e59 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105e12:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105e15:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e19:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105e20:	e8 d9 f3 ff ff       	call   801051fe <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
80105e25:	85 c0                	test   %eax,%eax
80105e27:	78 30                	js     80105e59 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
80105e29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105e2c:	0f bf c8             	movswl %ax,%ecx
80105e2f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105e32:	0f bf d0             	movswl %ax,%edx
80105e35:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
80105e38:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80105e3c:	89 54 24 08          	mov    %edx,0x8(%esp)
80105e40:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80105e47:	00 
80105e48:	89 04 24             	mov    %eax,(%esp)
80105e4b:	e8 cd fb ff ff       	call   80105a1d <create>
80105e50:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105e53:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105e57:	75 0c                	jne    80105e65 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80105e59:	e8 5c d4 ff ff       	call   801032ba <commit_trans>
    return -1;
80105e5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e63:	eb 15                	jmp    80105e7a <sys_mknod+0xa6>
  }
  iunlockput(ip);
80105e65:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e68:	89 04 24             	mov    %eax,(%esp)
80105e6b:	e8 d0 bc ff ff       	call   80101b40 <iunlockput>
  commit_trans();
80105e70:	e8 45 d4 ff ff       	call   801032ba <commit_trans>
  return 0;
80105e75:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105e7a:	c9                   	leave  
80105e7b:	c3                   	ret    

80105e7c <sys_chdir>:

int
sys_chdir(void)
{
80105e7c:	55                   	push   %ebp
80105e7d:	89 e5                	mov    %esp,%ebp
80105e7f:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
80105e82:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105e85:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e90:	e8 03 f4 ff ff       	call   80105298 <argstr>
80105e95:	85 c0                	test   %eax,%eax
80105e97:	78 14                	js     80105ead <sys_chdir+0x31>
80105e99:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e9c:	89 04 24             	mov    %eax,(%esp)
80105e9f:	e8 ba c5 ff ff       	call   8010245e <namei>
80105ea4:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ea7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105eab:	75 07                	jne    80105eb4 <sys_chdir+0x38>
    return -1;
80105ead:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105eb2:	eb 57                	jmp    80105f0b <sys_chdir+0x8f>
  ilock(ip);
80105eb4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105eb7:	89 04 24             	mov    %eax,(%esp)
80105eba:	e8 fd b9 ff ff       	call   801018bc <ilock>
  if(ip->type != T_DIR){
80105ebf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ec2:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105ec6:	66 83 f8 01          	cmp    $0x1,%ax
80105eca:	74 12                	je     80105ede <sys_chdir+0x62>
    iunlockput(ip);
80105ecc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ecf:	89 04 24             	mov    %eax,(%esp)
80105ed2:	e8 69 bc ff ff       	call   80101b40 <iunlockput>
    return -1;
80105ed7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105edc:	eb 2d                	jmp    80105f0b <sys_chdir+0x8f>
  }
  iunlock(ip);
80105ede:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ee1:	89 04 24             	mov    %eax,(%esp)
80105ee4:	e8 21 bb ff ff       	call   80101a0a <iunlock>
  iput(proc->cwd);
80105ee9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105eef:	8b 40 68             	mov    0x68(%eax),%eax
80105ef2:	89 04 24             	mov    %eax,(%esp)
80105ef5:	e8 75 bb ff ff       	call   80101a6f <iput>
  proc->cwd = ip;
80105efa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f00:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105f03:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
80105f06:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105f0b:	c9                   	leave  
80105f0c:	c3                   	ret    

80105f0d <sys_exec>:

int
sys_exec(void)
{
80105f0d:	55                   	push   %ebp
80105f0e:	89 e5                	mov    %esp,%ebp
80105f10:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
80105f16:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105f19:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f1d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105f24:	e8 6f f3 ff ff       	call   80105298 <argstr>
80105f29:	85 c0                	test   %eax,%eax
80105f2b:	78 1a                	js     80105f47 <sys_exec+0x3a>
80105f2d:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80105f33:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f37:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105f3e:	e8 bb f2 ff ff       	call   801051fe <argint>
80105f43:	85 c0                	test   %eax,%eax
80105f45:	79 0a                	jns    80105f51 <sys_exec+0x44>
    return -1;
80105f47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f4c:	e9 e2 00 00 00       	jmp    80106033 <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
80105f51:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80105f58:	00 
80105f59:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f60:	00 
80105f61:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80105f67:	89 04 24             	mov    %eax,(%esp)
80105f6a:	e8 3f ef ff ff       	call   80104eae <memset>
  for(i=0;; i++){
80105f6f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80105f76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f79:	83 f8 1f             	cmp    $0x1f,%eax
80105f7c:	76 0a                	jbe    80105f88 <sys_exec+0x7b>
      return -1;
80105f7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f83:	e9 ab 00 00 00       	jmp    80106033 <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80105f88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f8b:	c1 e0 02             	shl    $0x2,%eax
80105f8e:	89 c2                	mov    %eax,%edx
80105f90:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80105f96:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80105f99:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105f9f:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80105fa5:	89 54 24 08          	mov    %edx,0x8(%esp)
80105fa9:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80105fad:	89 04 24             	mov    %eax,(%esp)
80105fb0:	e8 b7 f1 ff ff       	call   8010516c <fetchint>
80105fb5:	85 c0                	test   %eax,%eax
80105fb7:	79 07                	jns    80105fc0 <sys_exec+0xb3>
      return -1;
80105fb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fbe:	eb 73                	jmp    80106033 <sys_exec+0x126>
    if(uarg == 0){
80105fc0:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80105fc6:	85 c0                	test   %eax,%eax
80105fc8:	75 26                	jne    80105ff0 <sys_exec+0xe3>
      argv[i] = 0;
80105fca:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fcd:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80105fd4:	00 00 00 00 
      break;
80105fd8:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80105fd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fdc:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
80105fe2:	89 54 24 04          	mov    %edx,0x4(%esp)
80105fe6:	89 04 24             	mov    %eax,(%esp)
80105fe9:	e8 0e ab ff ff       	call   80100afc <exec>
80105fee:	eb 43                	jmp    80106033 <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
80105ff0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ff3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105ffa:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106000:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
80106003:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
80106009:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010600f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106013:	89 54 24 04          	mov    %edx,0x4(%esp)
80106017:	89 04 24             	mov    %eax,(%esp)
8010601a:	e8 81 f1 ff ff       	call   801051a0 <fetchstr>
8010601f:	85 c0                	test   %eax,%eax
80106021:	79 07                	jns    8010602a <sys_exec+0x11d>
      return -1;
80106023:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106028:	eb 09                	jmp    80106033 <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
8010602a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
8010602e:	e9 43 ff ff ff       	jmp    80105f76 <sys_exec+0x69>
  return exec(path, argv);
}
80106033:	c9                   	leave  
80106034:	c3                   	ret    

80106035 <sys_pipe>:

int
sys_pipe(void)
{
80106035:	55                   	push   %ebp
80106036:	89 e5                	mov    %esp,%ebp
80106038:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
8010603b:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
80106042:	00 
80106043:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106046:	89 44 24 04          	mov    %eax,0x4(%esp)
8010604a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106051:	e8 e0 f1 ff ff       	call   80105236 <argptr>
80106056:	85 c0                	test   %eax,%eax
80106058:	79 0a                	jns    80106064 <sys_pipe+0x2f>
    return -1;
8010605a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010605f:	e9 9b 00 00 00       	jmp    801060ff <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106064:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106067:	89 44 24 04          	mov    %eax,0x4(%esp)
8010606b:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010606e:	89 04 24             	mov    %eax,(%esp)
80106071:	e8 16 dc ff ff       	call   80103c8c <pipealloc>
80106076:	85 c0                	test   %eax,%eax
80106078:	79 07                	jns    80106081 <sys_pipe+0x4c>
    return -1;
8010607a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010607f:	eb 7e                	jmp    801060ff <sys_pipe+0xca>
  fd0 = -1;
80106081:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106088:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010608b:	89 04 24             	mov    %eax,(%esp)
8010608e:	e8 82 f3 ff ff       	call   80105415 <fdalloc>
80106093:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106096:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010609a:	78 14                	js     801060b0 <sys_pipe+0x7b>
8010609c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010609f:	89 04 24             	mov    %eax,(%esp)
801060a2:	e8 6e f3 ff ff       	call   80105415 <fdalloc>
801060a7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060aa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060ae:	79 37                	jns    801060e7 <sys_pipe+0xb2>
    if(fd0 >= 0)
801060b0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060b4:	78 14                	js     801060ca <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
801060b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801060bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060bf:	83 c2 08             	add    $0x8,%edx
801060c2:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
801060c9:	00 
    fileclose(rf);
801060ca:	8b 45 e8             	mov    -0x18(%ebp),%eax
801060cd:	89 04 24             	mov    %eax,(%esp)
801060d0:	e8 43 af ff ff       	call   80101018 <fileclose>
    fileclose(wf);
801060d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801060d8:	89 04 24             	mov    %eax,(%esp)
801060db:	e8 38 af ff ff       	call   80101018 <fileclose>
    return -1;
801060e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801060e5:	eb 18                	jmp    801060ff <sys_pipe+0xca>
  }
  fd[0] = fd0;
801060e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801060ea:	8b 55 f4             	mov    -0xc(%ebp),%edx
801060ed:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801060ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
801060f2:	8d 50 04             	lea    0x4(%eax),%edx
801060f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060f8:	89 02                	mov    %eax,(%edx)
  return 0;
801060fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
801060ff:	c9                   	leave  
80106100:	c3                   	ret    
80106101:	00 00                	add    %al,(%eax)
	...

80106104 <sys_addPath>:

extern int add_path(char *);

int
sys_addPath(void)
{
80106104:	55                   	push   %ebp
80106105:	89 e5                	mov    %esp,%ebp
80106107:	83 ec 28             	sub    $0x28,%esp
  char *path;
  if(argstr(0, &path) < 0)
8010610a:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010610d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106111:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106118:	e8 7b f1 ff ff       	call   80105298 <argstr>
8010611d:	85 c0                	test   %eax,%eax
8010611f:	79 07                	jns    80106128 <sys_addPath+0x24>
    return -1;
80106121:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106126:	eb 0b                	jmp    80106133 <sys_addPath+0x2f>
  return add_path(path);
80106128:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010612b:	89 04 24             	mov    %eax,(%esp)
8010612e:	e8 2c df ff ff       	call   8010405f <add_path>
}
80106133:	c9                   	leave  
80106134:	c3                   	ret    

80106135 <sys_fork>:
//------------------- PATCH -------------------//


int
sys_fork(void)
{
80106135:	55                   	push   %ebp
80106136:	89 e5                	mov    %esp,%ebp
80106138:	83 ec 08             	sub    $0x8,%esp
  return fork();
8010613b:	e8 6e e2 ff ff       	call   801043ae <fork>
}
80106140:	c9                   	leave  
80106141:	c3                   	ret    

80106142 <sys_exit>:

int
sys_exit(void)
{
80106142:	55                   	push   %ebp
80106143:	89 e5                	mov    %esp,%ebp
80106145:	83 ec 08             	sub    $0x8,%esp
  exit();
80106148:	e8 c4 e3 ff ff       	call   80104511 <exit>
  return 0;  // not reached
8010614d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106152:	c9                   	leave  
80106153:	c3                   	ret    

80106154 <sys_wait>:

int
sys_wait(void)
{
80106154:	55                   	push   %ebp
80106155:	89 e5                	mov    %esp,%ebp
80106157:	83 ec 08             	sub    $0x8,%esp
  return wait();
8010615a:	e8 ca e4 ff ff       	call   80104629 <wait>
}
8010615f:	c9                   	leave  
80106160:	c3                   	ret    

80106161 <sys_kill>:

int
sys_kill(void)
{
80106161:	55                   	push   %ebp
80106162:	89 e5                	mov    %esp,%ebp
80106164:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
80106167:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010616a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010616e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106175:	e8 84 f0 ff ff       	call   801051fe <argint>
8010617a:	85 c0                	test   %eax,%eax
8010617c:	79 07                	jns    80106185 <sys_kill+0x24>
    return -1;
8010617e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106183:	eb 0b                	jmp    80106190 <sys_kill+0x2f>
  return kill(pid);
80106185:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106188:	89 04 24             	mov    %eax,(%esp)
8010618b:	e8 f5 e8 ff ff       	call   80104a85 <kill>
}
80106190:	c9                   	leave  
80106191:	c3                   	ret    

80106192 <sys_getpid>:

int
sys_getpid(void)
{
80106192:	55                   	push   %ebp
80106193:	89 e5                	mov    %esp,%ebp
  return proc->pid;
80106195:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010619b:	8b 40 10             	mov    0x10(%eax),%eax
}
8010619e:	5d                   	pop    %ebp
8010619f:	c3                   	ret    

801061a0 <sys_sbrk>:

int
sys_sbrk(void)
{
801061a0:	55                   	push   %ebp
801061a1:	89 e5                	mov    %esp,%ebp
801061a3:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801061a6:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061a9:	89 44 24 04          	mov    %eax,0x4(%esp)
801061ad:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061b4:	e8 45 f0 ff ff       	call   801051fe <argint>
801061b9:	85 c0                	test   %eax,%eax
801061bb:	79 07                	jns    801061c4 <sys_sbrk+0x24>
    return -1;
801061bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061c2:	eb 24                	jmp    801061e8 <sys_sbrk+0x48>
  addr = proc->sz;
801061c4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801061ca:	8b 00                	mov    (%eax),%eax
801061cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
801061cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801061d2:	89 04 24             	mov    %eax,(%esp)
801061d5:	e8 2f e1 ff ff       	call   80104309 <growproc>
801061da:	85 c0                	test   %eax,%eax
801061dc:	79 07                	jns    801061e5 <sys_sbrk+0x45>
    return -1;
801061de:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061e3:	eb 03                	jmp    801061e8 <sys_sbrk+0x48>
  return addr;
801061e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801061e8:	c9                   	leave  
801061e9:	c3                   	ret    

801061ea <sys_sleep>:

int
sys_sleep(void)
{
801061ea:	55                   	push   %ebp
801061eb:	89 e5                	mov    %esp,%ebp
801061ed:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
801061f0:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061f3:	89 44 24 04          	mov    %eax,0x4(%esp)
801061f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061fe:	e8 fb ef ff ff       	call   801051fe <argint>
80106203:	85 c0                	test   %eax,%eax
80106205:	79 07                	jns    8010620e <sys_sleep+0x24>
    return -1;
80106207:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010620c:	eb 6c                	jmp    8010627a <sys_sleep+0x90>
  acquire(&tickslock);
8010620e:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106215:	e8 45 ea ff ff       	call   80104c5f <acquire>
  ticks0 = ticks;
8010621a:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
8010621f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106222:	eb 34                	jmp    80106258 <sys_sleep+0x6e>
    if(proc->killed){
80106224:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010622a:	8b 40 24             	mov    0x24(%eax),%eax
8010622d:	85 c0                	test   %eax,%eax
8010622f:	74 13                	je     80106244 <sys_sleep+0x5a>
      release(&tickslock);
80106231:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106238:	e8 84 ea ff ff       	call   80104cc1 <release>
      return -1;
8010623d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106242:	eb 36                	jmp    8010627a <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106244:	c7 44 24 04 60 23 11 	movl   $0x80112360,0x4(%esp)
8010624b:	80 
8010624c:	c7 04 24 a0 2b 11 80 	movl   $0x80112ba0,(%esp)
80106253:	e8 29 e7 ff ff       	call   80104981 <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106258:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
8010625d:	89 c2                	mov    %eax,%edx
8010625f:	2b 55 f4             	sub    -0xc(%ebp),%edx
80106262:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106265:	39 c2                	cmp    %eax,%edx
80106267:	72 bb                	jb     80106224 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
80106269:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106270:	e8 4c ea ff ff       	call   80104cc1 <release>
  return 0;
80106275:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010627a:	c9                   	leave  
8010627b:	c3                   	ret    

8010627c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
8010627c:	55                   	push   %ebp
8010627d:	89 e5                	mov    %esp,%ebp
8010627f:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
80106282:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106289:	e8 d1 e9 ff ff       	call   80104c5f <acquire>
  xticks = ticks;
8010628e:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
80106293:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106296:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
8010629d:	e8 1f ea ff ff       	call   80104cc1 <release>
  return xticks;
801062a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801062a5:	c9                   	leave  
801062a6:	c3                   	ret    
	...

801062a8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801062a8:	55                   	push   %ebp
801062a9:	89 e5                	mov    %esp,%ebp
801062ab:	83 ec 08             	sub    $0x8,%esp
801062ae:	8b 55 08             	mov    0x8(%ebp),%edx
801062b1:	8b 45 0c             	mov    0xc(%ebp),%eax
801062b4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801062b8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801062bb:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801062bf:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801062c3:	ee                   	out    %al,(%dx)
}
801062c4:	c9                   	leave  
801062c5:	c3                   	ret    

801062c6 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
801062c6:	55                   	push   %ebp
801062c7:	89 e5                	mov    %esp,%ebp
801062c9:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
801062cc:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
801062d3:	00 
801062d4:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
801062db:	e8 c8 ff ff ff       	call   801062a8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
801062e0:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
801062e7:	00 
801062e8:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
801062ef:	e8 b4 ff ff ff       	call   801062a8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
801062f4:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
801062fb:	00 
801062fc:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106303:	e8 a0 ff ff ff       	call   801062a8 <outb>
  picenable(IRQ_TIMER);
80106308:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010630f:	e8 01 d8 ff ff       	call   80103b15 <picenable>
}
80106314:	c9                   	leave  
80106315:	c3                   	ret    
	...

80106318 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106318:	1e                   	push   %ds
  pushl %es
80106319:	06                   	push   %es
  pushl %fs
8010631a:	0f a0                	push   %fs
  pushl %gs
8010631c:	0f a8                	push   %gs
  pushal
8010631e:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010631f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106323:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106325:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106327:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010632b:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
8010632d:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010632f:	54                   	push   %esp
  call trap
80106330:	e8 de 01 00 00       	call   80106513 <trap>
  addl $4, %esp
80106335:	83 c4 04             	add    $0x4,%esp

80106338 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106338:	61                   	popa   
  popl %gs
80106339:	0f a9                	pop    %gs
  popl %fs
8010633b:	0f a1                	pop    %fs
  popl %es
8010633d:	07                   	pop    %es
  popl %ds
8010633e:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010633f:	83 c4 08             	add    $0x8,%esp
  iret
80106342:	cf                   	iret   
	...

80106344 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106344:	55                   	push   %ebp
80106345:	89 e5                	mov    %esp,%ebp
80106347:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010634a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010634d:	83 e8 01             	sub    $0x1,%eax
80106350:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106354:	8b 45 08             	mov    0x8(%ebp),%eax
80106357:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010635b:	8b 45 08             	mov    0x8(%ebp),%eax
8010635e:	c1 e8 10             	shr    $0x10,%eax
80106361:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
80106365:	8d 45 fa             	lea    -0x6(%ebp),%eax
80106368:	0f 01 18             	lidtl  (%eax)
}
8010636b:	c9                   	leave  
8010636c:	c3                   	ret    

8010636d <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
8010636d:	55                   	push   %ebp
8010636e:	89 e5                	mov    %esp,%ebp
80106370:	53                   	push   %ebx
80106371:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
80106374:	0f 20 d3             	mov    %cr2,%ebx
80106377:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
8010637a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010637d:	83 c4 10             	add    $0x10,%esp
80106380:	5b                   	pop    %ebx
80106381:	5d                   	pop    %ebp
80106382:	c3                   	ret    

80106383 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106383:	55                   	push   %ebp
80106384:	89 e5                	mov    %esp,%ebp
80106386:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
80106389:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106390:	e9 c3 00 00 00       	jmp    80106458 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
80106395:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106398:	8b 04 85 9c b0 10 80 	mov    -0x7fef4f64(,%eax,4),%eax
8010639f:	89 c2                	mov    %eax,%edx
801063a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063a4:	66 89 14 c5 a0 23 11 	mov    %dx,-0x7feedc60(,%eax,8)
801063ab:	80 
801063ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063af:	66 c7 04 c5 a2 23 11 	movw   $0x8,-0x7feedc5e(,%eax,8)
801063b6:	80 08 00 
801063b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063bc:	0f b6 14 c5 a4 23 11 	movzbl -0x7feedc5c(,%eax,8),%edx
801063c3:	80 
801063c4:	83 e2 e0             	and    $0xffffffe0,%edx
801063c7:	88 14 c5 a4 23 11 80 	mov    %dl,-0x7feedc5c(,%eax,8)
801063ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063d1:	0f b6 14 c5 a4 23 11 	movzbl -0x7feedc5c(,%eax,8),%edx
801063d8:	80 
801063d9:	83 e2 1f             	and    $0x1f,%edx
801063dc:	88 14 c5 a4 23 11 80 	mov    %dl,-0x7feedc5c(,%eax,8)
801063e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063e6:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
801063ed:	80 
801063ee:	83 e2 f0             	and    $0xfffffff0,%edx
801063f1:	83 ca 0e             	or     $0xe,%edx
801063f4:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
801063fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801063fe:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
80106405:	80 
80106406:	83 e2 ef             	and    $0xffffffef,%edx
80106409:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
80106410:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106413:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
8010641a:	80 
8010641b:	83 e2 9f             	and    $0xffffff9f,%edx
8010641e:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
80106425:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106428:	0f b6 14 c5 a5 23 11 	movzbl -0x7feedc5b(,%eax,8),%edx
8010642f:	80 
80106430:	83 ca 80             	or     $0xffffff80,%edx
80106433:	88 14 c5 a5 23 11 80 	mov    %dl,-0x7feedc5b(,%eax,8)
8010643a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010643d:	8b 04 85 9c b0 10 80 	mov    -0x7fef4f64(,%eax,4),%eax
80106444:	c1 e8 10             	shr    $0x10,%eax
80106447:	89 c2                	mov    %eax,%edx
80106449:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010644c:	66 89 14 c5 a6 23 11 	mov    %dx,-0x7feedc5a(,%eax,8)
80106453:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106454:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106458:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
8010645f:	0f 8e 30 ff ff ff    	jle    80106395 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106465:	a1 9c b1 10 80       	mov    0x8010b19c,%eax
8010646a:	66 a3 a0 25 11 80    	mov    %ax,0x801125a0
80106470:	66 c7 05 a2 25 11 80 	movw   $0x8,0x801125a2
80106477:	08 00 
80106479:	0f b6 05 a4 25 11 80 	movzbl 0x801125a4,%eax
80106480:	83 e0 e0             	and    $0xffffffe0,%eax
80106483:	a2 a4 25 11 80       	mov    %al,0x801125a4
80106488:	0f b6 05 a4 25 11 80 	movzbl 0x801125a4,%eax
8010648f:	83 e0 1f             	and    $0x1f,%eax
80106492:	a2 a4 25 11 80       	mov    %al,0x801125a4
80106497:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
8010649e:	83 c8 0f             	or     $0xf,%eax
801064a1:	a2 a5 25 11 80       	mov    %al,0x801125a5
801064a6:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
801064ad:	83 e0 ef             	and    $0xffffffef,%eax
801064b0:	a2 a5 25 11 80       	mov    %al,0x801125a5
801064b5:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
801064bc:	83 c8 60             	or     $0x60,%eax
801064bf:	a2 a5 25 11 80       	mov    %al,0x801125a5
801064c4:	0f b6 05 a5 25 11 80 	movzbl 0x801125a5,%eax
801064cb:	83 c8 80             	or     $0xffffff80,%eax
801064ce:	a2 a5 25 11 80       	mov    %al,0x801125a5
801064d3:	a1 9c b1 10 80       	mov    0x8010b19c,%eax
801064d8:	c1 e8 10             	shr    $0x10,%eax
801064db:	66 a3 a6 25 11 80    	mov    %ax,0x801125a6
  
  initlock(&tickslock, "time");
801064e1:	c7 44 24 04 24 87 10 	movl   $0x80108724,0x4(%esp)
801064e8:	80 
801064e9:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
801064f0:	e8 49 e7 ff ff       	call   80104c3e <initlock>
}
801064f5:	c9                   	leave  
801064f6:	c3                   	ret    

801064f7 <idtinit>:

void
idtinit(void)
{
801064f7:	55                   	push   %ebp
801064f8:	89 e5                	mov    %esp,%ebp
801064fa:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
801064fd:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106504:	00 
80106505:	c7 04 24 a0 23 11 80 	movl   $0x801123a0,(%esp)
8010650c:	e8 33 fe ff ff       	call   80106344 <lidt>
}
80106511:	c9                   	leave  
80106512:	c3                   	ret    

80106513 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106513:	55                   	push   %ebp
80106514:	89 e5                	mov    %esp,%ebp
80106516:	57                   	push   %edi
80106517:	56                   	push   %esi
80106518:	53                   	push   %ebx
80106519:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
8010651c:	8b 45 08             	mov    0x8(%ebp),%eax
8010651f:	8b 40 30             	mov    0x30(%eax),%eax
80106522:	83 f8 40             	cmp    $0x40,%eax
80106525:	75 3e                	jne    80106565 <trap+0x52>
    if(proc->killed)
80106527:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010652d:	8b 40 24             	mov    0x24(%eax),%eax
80106530:	85 c0                	test   %eax,%eax
80106532:	74 05                	je     80106539 <trap+0x26>
      exit();
80106534:	e8 d8 df ff ff       	call   80104511 <exit>
    proc->tf = tf;
80106539:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010653f:	8b 55 08             	mov    0x8(%ebp),%edx
80106542:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106545:	e8 91 ed ff ff       	call   801052db <syscall>
    if(proc->killed)
8010654a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106550:	8b 40 24             	mov    0x24(%eax),%eax
80106553:	85 c0                	test   %eax,%eax
80106555:	0f 84 34 02 00 00    	je     8010678f <trap+0x27c>
      exit();
8010655b:	e8 b1 df ff ff       	call   80104511 <exit>
    return;
80106560:	e9 2a 02 00 00       	jmp    8010678f <trap+0x27c>
  }

  switch(tf->trapno){
80106565:	8b 45 08             	mov    0x8(%ebp),%eax
80106568:	8b 40 30             	mov    0x30(%eax),%eax
8010656b:	83 e8 20             	sub    $0x20,%eax
8010656e:	83 f8 1f             	cmp    $0x1f,%eax
80106571:	0f 87 bc 00 00 00    	ja     80106633 <trap+0x120>
80106577:	8b 04 85 cc 87 10 80 	mov    -0x7fef7834(,%eax,4),%eax
8010657e:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106580:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106586:	0f b6 00             	movzbl (%eax),%eax
80106589:	84 c0                	test   %al,%al
8010658b:	75 31                	jne    801065be <trap+0xab>
      acquire(&tickslock);
8010658d:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
80106594:	e8 c6 e6 ff ff       	call   80104c5f <acquire>
      ticks++;
80106599:	a1 a0 2b 11 80       	mov    0x80112ba0,%eax
8010659e:	83 c0 01             	add    $0x1,%eax
801065a1:	a3 a0 2b 11 80       	mov    %eax,0x80112ba0
      wakeup(&ticks);
801065a6:	c7 04 24 a0 2b 11 80 	movl   $0x80112ba0,(%esp)
801065ad:	e8 a8 e4 ff ff       	call   80104a5a <wakeup>
      release(&tickslock);
801065b2:	c7 04 24 60 23 11 80 	movl   $0x80112360,(%esp)
801065b9:	e8 03 e7 ff ff       	call   80104cc1 <release>
    }
    lapiceoi();
801065be:	e8 7a c9 ff ff       	call   80102f3d <lapiceoi>
    break;
801065c3:	e9 41 01 00 00       	jmp    80106709 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801065c8:	e8 78 c1 ff ff       	call   80102745 <ideintr>
    lapiceoi();
801065cd:	e8 6b c9 ff ff       	call   80102f3d <lapiceoi>
    break;
801065d2:	e9 32 01 00 00       	jmp    80106709 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801065d7:	e8 3f c7 ff ff       	call   80102d1b <kbdintr>
    lapiceoi();
801065dc:	e8 5c c9 ff ff       	call   80102f3d <lapiceoi>
    break;
801065e1:	e9 23 01 00 00       	jmp    80106709 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801065e6:	e8 a9 03 00 00       	call   80106994 <uartintr>
    lapiceoi();
801065eb:	e8 4d c9 ff ff       	call   80102f3d <lapiceoi>
    break;
801065f0:	e9 14 01 00 00       	jmp    80106709 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
801065f5:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
801065f8:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
801065fb:	8b 45 08             	mov    0x8(%ebp),%eax
801065fe:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106602:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106605:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010660b:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010660e:	0f b6 c0             	movzbl %al,%eax
80106611:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106615:	89 54 24 08          	mov    %edx,0x8(%esp)
80106619:	89 44 24 04          	mov    %eax,0x4(%esp)
8010661d:	c7 04 24 2c 87 10 80 	movl   $0x8010872c,(%esp)
80106624:	e8 78 9d ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106629:	e8 0f c9 ff ff       	call   80102f3d <lapiceoi>
    break;
8010662e:	e9 d6 00 00 00       	jmp    80106709 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106633:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106639:	85 c0                	test   %eax,%eax
8010663b:	74 11                	je     8010664e <trap+0x13b>
8010663d:	8b 45 08             	mov    0x8(%ebp),%eax
80106640:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106644:	0f b7 c0             	movzwl %ax,%eax
80106647:	83 e0 03             	and    $0x3,%eax
8010664a:	85 c0                	test   %eax,%eax
8010664c:	75 46                	jne    80106694 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
8010664e:	e8 1a fd ff ff       	call   8010636d <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80106653:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106656:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106659:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106660:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106663:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106666:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106669:	8b 52 30             	mov    0x30(%edx),%edx
8010666c:	89 44 24 10          	mov    %eax,0x10(%esp)
80106670:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106674:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106678:	89 54 24 04          	mov    %edx,0x4(%esp)
8010667c:	c7 04 24 50 87 10 80 	movl   $0x80108750,(%esp)
80106683:	e8 19 9d ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106688:	c7 04 24 82 87 10 80 	movl   $0x80108782,(%esp)
8010668f:	e8 a9 9e ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106694:	e8 d4 fc ff ff       	call   8010636d <rcr2>
80106699:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
8010669b:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
8010669e:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066a1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801066a7:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066aa:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066ad:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066b0:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066b3:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066b6:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
801066b9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066bf:	83 c0 6c             	add    $0x6c,%eax
801066c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801066c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
801066cb:	8b 40 10             	mov    0x10(%eax),%eax
801066ce:	89 54 24 1c          	mov    %edx,0x1c(%esp)
801066d2:	89 7c 24 18          	mov    %edi,0x18(%esp)
801066d6:	89 74 24 14          	mov    %esi,0x14(%esp)
801066da:	89 5c 24 10          	mov    %ebx,0x10(%esp)
801066de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801066e2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801066e5:	89 54 24 08          	mov    %edx,0x8(%esp)
801066e9:	89 44 24 04          	mov    %eax,0x4(%esp)
801066ed:	c7 04 24 88 87 10 80 	movl   $0x80108788,(%esp)
801066f4:	e8 a8 9c ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
801066f9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801066ff:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106706:	eb 01                	jmp    80106709 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106708:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106709:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010670f:	85 c0                	test   %eax,%eax
80106711:	74 24                	je     80106737 <trap+0x224>
80106713:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106719:	8b 40 24             	mov    0x24(%eax),%eax
8010671c:	85 c0                	test   %eax,%eax
8010671e:	74 17                	je     80106737 <trap+0x224>
80106720:	8b 45 08             	mov    0x8(%ebp),%eax
80106723:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106727:	0f b7 c0             	movzwl %ax,%eax
8010672a:	83 e0 03             	and    $0x3,%eax
8010672d:	83 f8 03             	cmp    $0x3,%eax
80106730:	75 05                	jne    80106737 <trap+0x224>
    exit();
80106732:	e8 da dd ff ff       	call   80104511 <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106737:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010673d:	85 c0                	test   %eax,%eax
8010673f:	74 1e                	je     8010675f <trap+0x24c>
80106741:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106747:	8b 40 0c             	mov    0xc(%eax),%eax
8010674a:	83 f8 04             	cmp    $0x4,%eax
8010674d:	75 10                	jne    8010675f <trap+0x24c>
8010674f:	8b 45 08             	mov    0x8(%ebp),%eax
80106752:	8b 40 30             	mov    0x30(%eax),%eax
80106755:	83 f8 20             	cmp    $0x20,%eax
80106758:	75 05                	jne    8010675f <trap+0x24c>
    yield();
8010675a:	e8 c4 e1 ff ff       	call   80104923 <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
8010675f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106765:	85 c0                	test   %eax,%eax
80106767:	74 27                	je     80106790 <trap+0x27d>
80106769:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010676f:	8b 40 24             	mov    0x24(%eax),%eax
80106772:	85 c0                	test   %eax,%eax
80106774:	74 1a                	je     80106790 <trap+0x27d>
80106776:	8b 45 08             	mov    0x8(%ebp),%eax
80106779:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010677d:	0f b7 c0             	movzwl %ax,%eax
80106780:	83 e0 03             	and    $0x3,%eax
80106783:	83 f8 03             	cmp    $0x3,%eax
80106786:	75 08                	jne    80106790 <trap+0x27d>
    exit();
80106788:	e8 84 dd ff ff       	call   80104511 <exit>
8010678d:	eb 01                	jmp    80106790 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
8010678f:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106790:	83 c4 3c             	add    $0x3c,%esp
80106793:	5b                   	pop    %ebx
80106794:	5e                   	pop    %esi
80106795:	5f                   	pop    %edi
80106796:	5d                   	pop    %ebp
80106797:	c3                   	ret    

80106798 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106798:	55                   	push   %ebp
80106799:	89 e5                	mov    %esp,%ebp
8010679b:	53                   	push   %ebx
8010679c:	83 ec 14             	sub    $0x14,%esp
8010679f:	8b 45 08             	mov    0x8(%ebp),%eax
801067a2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801067a6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801067aa:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801067ae:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801067b2:	ec                   	in     (%dx),%al
801067b3:	89 c3                	mov    %eax,%ebx
801067b5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801067b8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801067bc:	83 c4 14             	add    $0x14,%esp
801067bf:	5b                   	pop    %ebx
801067c0:	5d                   	pop    %ebp
801067c1:	c3                   	ret    

801067c2 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801067c2:	55                   	push   %ebp
801067c3:	89 e5                	mov    %esp,%ebp
801067c5:	83 ec 08             	sub    $0x8,%esp
801067c8:	8b 55 08             	mov    0x8(%ebp),%edx
801067cb:	8b 45 0c             	mov    0xc(%ebp),%eax
801067ce:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801067d2:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801067d5:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801067d9:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801067dd:	ee                   	out    %al,(%dx)
}
801067de:	c9                   	leave  
801067df:	c3                   	ret    

801067e0 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
801067e0:	55                   	push   %ebp
801067e1:	89 e5                	mov    %esp,%ebp
801067e3:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
801067e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801067ed:	00 
801067ee:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
801067f5:	e8 c8 ff ff ff       	call   801067c2 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
801067fa:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106801:	00 
80106802:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106809:	e8 b4 ff ff ff       	call   801067c2 <outb>
  outb(COM1+0, 115200/9600);
8010680e:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106815:	00 
80106816:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010681d:	e8 a0 ff ff ff       	call   801067c2 <outb>
  outb(COM1+1, 0);
80106822:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106829:	00 
8010682a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106831:	e8 8c ff ff ff       	call   801067c2 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106836:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010683d:	00 
8010683e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106845:	e8 78 ff ff ff       	call   801067c2 <outb>
  outb(COM1+4, 0);
8010684a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106851:	00 
80106852:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106859:	e8 64 ff ff ff       	call   801067c2 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
8010685e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106865:	00 
80106866:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
8010686d:	e8 50 ff ff ff       	call   801067c2 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106872:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106879:	e8 1a ff ff ff       	call   80106798 <inb>
8010687e:	3c ff                	cmp    $0xff,%al
80106880:	74 6c                	je     801068ee <uartinit+0x10e>
    return;
  uart = 1;
80106882:	c7 05 4c b6 10 80 01 	movl   $0x1,0x8010b64c
80106889:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
8010688c:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106893:	e8 00 ff ff ff       	call   80106798 <inb>
  inb(COM1+0);
80106898:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010689f:	e8 f4 fe ff ff       	call   80106798 <inb>
  picenable(IRQ_COM1);
801068a4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801068ab:	e8 65 d2 ff ff       	call   80103b15 <picenable>
  ioapicenable(IRQ_COM1, 0);
801068b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801068b7:	00 
801068b8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
801068bf:	e8 06 c1 ff ff       	call   801029ca <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801068c4:	c7 45 f4 4c 88 10 80 	movl   $0x8010884c,-0xc(%ebp)
801068cb:	eb 15                	jmp    801068e2 <uartinit+0x102>
    uartputc(*p);
801068cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068d0:	0f b6 00             	movzbl (%eax),%eax
801068d3:	0f be c0             	movsbl %al,%eax
801068d6:	89 04 24             	mov    %eax,(%esp)
801068d9:	e8 13 00 00 00       	call   801068f1 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
801068de:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801068e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801068e5:	0f b6 00             	movzbl (%eax),%eax
801068e8:	84 c0                	test   %al,%al
801068ea:	75 e1                	jne    801068cd <uartinit+0xed>
801068ec:	eb 01                	jmp    801068ef <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
801068ee:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
801068ef:	c9                   	leave  
801068f0:	c3                   	ret    

801068f1 <uartputc>:

void
uartputc(int c)
{
801068f1:	55                   	push   %ebp
801068f2:	89 e5                	mov    %esp,%ebp
801068f4:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
801068f7:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
801068fc:	85 c0                	test   %eax,%eax
801068fe:	74 4d                	je     8010694d <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106900:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106907:	eb 10                	jmp    80106919 <uartputc+0x28>
    microdelay(10);
80106909:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106910:	e8 4d c6 ff ff       	call   80102f62 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106915:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106919:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
8010691d:	7f 16                	jg     80106935 <uartputc+0x44>
8010691f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106926:	e8 6d fe ff ff       	call   80106798 <inb>
8010692b:	0f b6 c0             	movzbl %al,%eax
8010692e:	83 e0 20             	and    $0x20,%eax
80106931:	85 c0                	test   %eax,%eax
80106933:	74 d4                	je     80106909 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106935:	8b 45 08             	mov    0x8(%ebp),%eax
80106938:	0f b6 c0             	movzbl %al,%eax
8010693b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010693f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106946:	e8 77 fe ff ff       	call   801067c2 <outb>
8010694b:	eb 01                	jmp    8010694e <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
8010694d:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
8010694e:	c9                   	leave  
8010694f:	c3                   	ret    

80106950 <uartgetc>:

static int
uartgetc(void)
{
80106950:	55                   	push   %ebp
80106951:	89 e5                	mov    %esp,%ebp
80106953:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106956:	a1 4c b6 10 80       	mov    0x8010b64c,%eax
8010695b:	85 c0                	test   %eax,%eax
8010695d:	75 07                	jne    80106966 <uartgetc+0x16>
    return -1;
8010695f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106964:	eb 2c                	jmp    80106992 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106966:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
8010696d:	e8 26 fe ff ff       	call   80106798 <inb>
80106972:	0f b6 c0             	movzbl %al,%eax
80106975:	83 e0 01             	and    $0x1,%eax
80106978:	85 c0                	test   %eax,%eax
8010697a:	75 07                	jne    80106983 <uartgetc+0x33>
    return -1;
8010697c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106981:	eb 0f                	jmp    80106992 <uartgetc+0x42>
  return inb(COM1+0);
80106983:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
8010698a:	e8 09 fe ff ff       	call   80106798 <inb>
8010698f:	0f b6 c0             	movzbl %al,%eax
}
80106992:	c9                   	leave  
80106993:	c3                   	ret    

80106994 <uartintr>:

void
uartintr(void)
{
80106994:	55                   	push   %ebp
80106995:	89 e5                	mov    %esp,%ebp
80106997:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
8010699a:	c7 04 24 50 69 10 80 	movl   $0x80106950,(%esp)
801069a1:	e8 07 9e ff ff       	call   801007ad <consoleintr>
}
801069a6:	c9                   	leave  
801069a7:	c3                   	ret    

801069a8 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
801069a8:	6a 00                	push   $0x0
  pushl $0
801069aa:	6a 00                	push   $0x0
  jmp alltraps
801069ac:	e9 67 f9 ff ff       	jmp    80106318 <alltraps>

801069b1 <vector1>:
.globl vector1
vector1:
  pushl $0
801069b1:	6a 00                	push   $0x0
  pushl $1
801069b3:	6a 01                	push   $0x1
  jmp alltraps
801069b5:	e9 5e f9 ff ff       	jmp    80106318 <alltraps>

801069ba <vector2>:
.globl vector2
vector2:
  pushl $0
801069ba:	6a 00                	push   $0x0
  pushl $2
801069bc:	6a 02                	push   $0x2
  jmp alltraps
801069be:	e9 55 f9 ff ff       	jmp    80106318 <alltraps>

801069c3 <vector3>:
.globl vector3
vector3:
  pushl $0
801069c3:	6a 00                	push   $0x0
  pushl $3
801069c5:	6a 03                	push   $0x3
  jmp alltraps
801069c7:	e9 4c f9 ff ff       	jmp    80106318 <alltraps>

801069cc <vector4>:
.globl vector4
vector4:
  pushl $0
801069cc:	6a 00                	push   $0x0
  pushl $4
801069ce:	6a 04                	push   $0x4
  jmp alltraps
801069d0:	e9 43 f9 ff ff       	jmp    80106318 <alltraps>

801069d5 <vector5>:
.globl vector5
vector5:
  pushl $0
801069d5:	6a 00                	push   $0x0
  pushl $5
801069d7:	6a 05                	push   $0x5
  jmp alltraps
801069d9:	e9 3a f9 ff ff       	jmp    80106318 <alltraps>

801069de <vector6>:
.globl vector6
vector6:
  pushl $0
801069de:	6a 00                	push   $0x0
  pushl $6
801069e0:	6a 06                	push   $0x6
  jmp alltraps
801069e2:	e9 31 f9 ff ff       	jmp    80106318 <alltraps>

801069e7 <vector7>:
.globl vector7
vector7:
  pushl $0
801069e7:	6a 00                	push   $0x0
  pushl $7
801069e9:	6a 07                	push   $0x7
  jmp alltraps
801069eb:	e9 28 f9 ff ff       	jmp    80106318 <alltraps>

801069f0 <vector8>:
.globl vector8
vector8:
  pushl $8
801069f0:	6a 08                	push   $0x8
  jmp alltraps
801069f2:	e9 21 f9 ff ff       	jmp    80106318 <alltraps>

801069f7 <vector9>:
.globl vector9
vector9:
  pushl $0
801069f7:	6a 00                	push   $0x0
  pushl $9
801069f9:	6a 09                	push   $0x9
  jmp alltraps
801069fb:	e9 18 f9 ff ff       	jmp    80106318 <alltraps>

80106a00 <vector10>:
.globl vector10
vector10:
  pushl $10
80106a00:	6a 0a                	push   $0xa
  jmp alltraps
80106a02:	e9 11 f9 ff ff       	jmp    80106318 <alltraps>

80106a07 <vector11>:
.globl vector11
vector11:
  pushl $11
80106a07:	6a 0b                	push   $0xb
  jmp alltraps
80106a09:	e9 0a f9 ff ff       	jmp    80106318 <alltraps>

80106a0e <vector12>:
.globl vector12
vector12:
  pushl $12
80106a0e:	6a 0c                	push   $0xc
  jmp alltraps
80106a10:	e9 03 f9 ff ff       	jmp    80106318 <alltraps>

80106a15 <vector13>:
.globl vector13
vector13:
  pushl $13
80106a15:	6a 0d                	push   $0xd
  jmp alltraps
80106a17:	e9 fc f8 ff ff       	jmp    80106318 <alltraps>

80106a1c <vector14>:
.globl vector14
vector14:
  pushl $14
80106a1c:	6a 0e                	push   $0xe
  jmp alltraps
80106a1e:	e9 f5 f8 ff ff       	jmp    80106318 <alltraps>

80106a23 <vector15>:
.globl vector15
vector15:
  pushl $0
80106a23:	6a 00                	push   $0x0
  pushl $15
80106a25:	6a 0f                	push   $0xf
  jmp alltraps
80106a27:	e9 ec f8 ff ff       	jmp    80106318 <alltraps>

80106a2c <vector16>:
.globl vector16
vector16:
  pushl $0
80106a2c:	6a 00                	push   $0x0
  pushl $16
80106a2e:	6a 10                	push   $0x10
  jmp alltraps
80106a30:	e9 e3 f8 ff ff       	jmp    80106318 <alltraps>

80106a35 <vector17>:
.globl vector17
vector17:
  pushl $17
80106a35:	6a 11                	push   $0x11
  jmp alltraps
80106a37:	e9 dc f8 ff ff       	jmp    80106318 <alltraps>

80106a3c <vector18>:
.globl vector18
vector18:
  pushl $0
80106a3c:	6a 00                	push   $0x0
  pushl $18
80106a3e:	6a 12                	push   $0x12
  jmp alltraps
80106a40:	e9 d3 f8 ff ff       	jmp    80106318 <alltraps>

80106a45 <vector19>:
.globl vector19
vector19:
  pushl $0
80106a45:	6a 00                	push   $0x0
  pushl $19
80106a47:	6a 13                	push   $0x13
  jmp alltraps
80106a49:	e9 ca f8 ff ff       	jmp    80106318 <alltraps>

80106a4e <vector20>:
.globl vector20
vector20:
  pushl $0
80106a4e:	6a 00                	push   $0x0
  pushl $20
80106a50:	6a 14                	push   $0x14
  jmp alltraps
80106a52:	e9 c1 f8 ff ff       	jmp    80106318 <alltraps>

80106a57 <vector21>:
.globl vector21
vector21:
  pushl $0
80106a57:	6a 00                	push   $0x0
  pushl $21
80106a59:	6a 15                	push   $0x15
  jmp alltraps
80106a5b:	e9 b8 f8 ff ff       	jmp    80106318 <alltraps>

80106a60 <vector22>:
.globl vector22
vector22:
  pushl $0
80106a60:	6a 00                	push   $0x0
  pushl $22
80106a62:	6a 16                	push   $0x16
  jmp alltraps
80106a64:	e9 af f8 ff ff       	jmp    80106318 <alltraps>

80106a69 <vector23>:
.globl vector23
vector23:
  pushl $0
80106a69:	6a 00                	push   $0x0
  pushl $23
80106a6b:	6a 17                	push   $0x17
  jmp alltraps
80106a6d:	e9 a6 f8 ff ff       	jmp    80106318 <alltraps>

80106a72 <vector24>:
.globl vector24
vector24:
  pushl $0
80106a72:	6a 00                	push   $0x0
  pushl $24
80106a74:	6a 18                	push   $0x18
  jmp alltraps
80106a76:	e9 9d f8 ff ff       	jmp    80106318 <alltraps>

80106a7b <vector25>:
.globl vector25
vector25:
  pushl $0
80106a7b:	6a 00                	push   $0x0
  pushl $25
80106a7d:	6a 19                	push   $0x19
  jmp alltraps
80106a7f:	e9 94 f8 ff ff       	jmp    80106318 <alltraps>

80106a84 <vector26>:
.globl vector26
vector26:
  pushl $0
80106a84:	6a 00                	push   $0x0
  pushl $26
80106a86:	6a 1a                	push   $0x1a
  jmp alltraps
80106a88:	e9 8b f8 ff ff       	jmp    80106318 <alltraps>

80106a8d <vector27>:
.globl vector27
vector27:
  pushl $0
80106a8d:	6a 00                	push   $0x0
  pushl $27
80106a8f:	6a 1b                	push   $0x1b
  jmp alltraps
80106a91:	e9 82 f8 ff ff       	jmp    80106318 <alltraps>

80106a96 <vector28>:
.globl vector28
vector28:
  pushl $0
80106a96:	6a 00                	push   $0x0
  pushl $28
80106a98:	6a 1c                	push   $0x1c
  jmp alltraps
80106a9a:	e9 79 f8 ff ff       	jmp    80106318 <alltraps>

80106a9f <vector29>:
.globl vector29
vector29:
  pushl $0
80106a9f:	6a 00                	push   $0x0
  pushl $29
80106aa1:	6a 1d                	push   $0x1d
  jmp alltraps
80106aa3:	e9 70 f8 ff ff       	jmp    80106318 <alltraps>

80106aa8 <vector30>:
.globl vector30
vector30:
  pushl $0
80106aa8:	6a 00                	push   $0x0
  pushl $30
80106aaa:	6a 1e                	push   $0x1e
  jmp alltraps
80106aac:	e9 67 f8 ff ff       	jmp    80106318 <alltraps>

80106ab1 <vector31>:
.globl vector31
vector31:
  pushl $0
80106ab1:	6a 00                	push   $0x0
  pushl $31
80106ab3:	6a 1f                	push   $0x1f
  jmp alltraps
80106ab5:	e9 5e f8 ff ff       	jmp    80106318 <alltraps>

80106aba <vector32>:
.globl vector32
vector32:
  pushl $0
80106aba:	6a 00                	push   $0x0
  pushl $32
80106abc:	6a 20                	push   $0x20
  jmp alltraps
80106abe:	e9 55 f8 ff ff       	jmp    80106318 <alltraps>

80106ac3 <vector33>:
.globl vector33
vector33:
  pushl $0
80106ac3:	6a 00                	push   $0x0
  pushl $33
80106ac5:	6a 21                	push   $0x21
  jmp alltraps
80106ac7:	e9 4c f8 ff ff       	jmp    80106318 <alltraps>

80106acc <vector34>:
.globl vector34
vector34:
  pushl $0
80106acc:	6a 00                	push   $0x0
  pushl $34
80106ace:	6a 22                	push   $0x22
  jmp alltraps
80106ad0:	e9 43 f8 ff ff       	jmp    80106318 <alltraps>

80106ad5 <vector35>:
.globl vector35
vector35:
  pushl $0
80106ad5:	6a 00                	push   $0x0
  pushl $35
80106ad7:	6a 23                	push   $0x23
  jmp alltraps
80106ad9:	e9 3a f8 ff ff       	jmp    80106318 <alltraps>

80106ade <vector36>:
.globl vector36
vector36:
  pushl $0
80106ade:	6a 00                	push   $0x0
  pushl $36
80106ae0:	6a 24                	push   $0x24
  jmp alltraps
80106ae2:	e9 31 f8 ff ff       	jmp    80106318 <alltraps>

80106ae7 <vector37>:
.globl vector37
vector37:
  pushl $0
80106ae7:	6a 00                	push   $0x0
  pushl $37
80106ae9:	6a 25                	push   $0x25
  jmp alltraps
80106aeb:	e9 28 f8 ff ff       	jmp    80106318 <alltraps>

80106af0 <vector38>:
.globl vector38
vector38:
  pushl $0
80106af0:	6a 00                	push   $0x0
  pushl $38
80106af2:	6a 26                	push   $0x26
  jmp alltraps
80106af4:	e9 1f f8 ff ff       	jmp    80106318 <alltraps>

80106af9 <vector39>:
.globl vector39
vector39:
  pushl $0
80106af9:	6a 00                	push   $0x0
  pushl $39
80106afb:	6a 27                	push   $0x27
  jmp alltraps
80106afd:	e9 16 f8 ff ff       	jmp    80106318 <alltraps>

80106b02 <vector40>:
.globl vector40
vector40:
  pushl $0
80106b02:	6a 00                	push   $0x0
  pushl $40
80106b04:	6a 28                	push   $0x28
  jmp alltraps
80106b06:	e9 0d f8 ff ff       	jmp    80106318 <alltraps>

80106b0b <vector41>:
.globl vector41
vector41:
  pushl $0
80106b0b:	6a 00                	push   $0x0
  pushl $41
80106b0d:	6a 29                	push   $0x29
  jmp alltraps
80106b0f:	e9 04 f8 ff ff       	jmp    80106318 <alltraps>

80106b14 <vector42>:
.globl vector42
vector42:
  pushl $0
80106b14:	6a 00                	push   $0x0
  pushl $42
80106b16:	6a 2a                	push   $0x2a
  jmp alltraps
80106b18:	e9 fb f7 ff ff       	jmp    80106318 <alltraps>

80106b1d <vector43>:
.globl vector43
vector43:
  pushl $0
80106b1d:	6a 00                	push   $0x0
  pushl $43
80106b1f:	6a 2b                	push   $0x2b
  jmp alltraps
80106b21:	e9 f2 f7 ff ff       	jmp    80106318 <alltraps>

80106b26 <vector44>:
.globl vector44
vector44:
  pushl $0
80106b26:	6a 00                	push   $0x0
  pushl $44
80106b28:	6a 2c                	push   $0x2c
  jmp alltraps
80106b2a:	e9 e9 f7 ff ff       	jmp    80106318 <alltraps>

80106b2f <vector45>:
.globl vector45
vector45:
  pushl $0
80106b2f:	6a 00                	push   $0x0
  pushl $45
80106b31:	6a 2d                	push   $0x2d
  jmp alltraps
80106b33:	e9 e0 f7 ff ff       	jmp    80106318 <alltraps>

80106b38 <vector46>:
.globl vector46
vector46:
  pushl $0
80106b38:	6a 00                	push   $0x0
  pushl $46
80106b3a:	6a 2e                	push   $0x2e
  jmp alltraps
80106b3c:	e9 d7 f7 ff ff       	jmp    80106318 <alltraps>

80106b41 <vector47>:
.globl vector47
vector47:
  pushl $0
80106b41:	6a 00                	push   $0x0
  pushl $47
80106b43:	6a 2f                	push   $0x2f
  jmp alltraps
80106b45:	e9 ce f7 ff ff       	jmp    80106318 <alltraps>

80106b4a <vector48>:
.globl vector48
vector48:
  pushl $0
80106b4a:	6a 00                	push   $0x0
  pushl $48
80106b4c:	6a 30                	push   $0x30
  jmp alltraps
80106b4e:	e9 c5 f7 ff ff       	jmp    80106318 <alltraps>

80106b53 <vector49>:
.globl vector49
vector49:
  pushl $0
80106b53:	6a 00                	push   $0x0
  pushl $49
80106b55:	6a 31                	push   $0x31
  jmp alltraps
80106b57:	e9 bc f7 ff ff       	jmp    80106318 <alltraps>

80106b5c <vector50>:
.globl vector50
vector50:
  pushl $0
80106b5c:	6a 00                	push   $0x0
  pushl $50
80106b5e:	6a 32                	push   $0x32
  jmp alltraps
80106b60:	e9 b3 f7 ff ff       	jmp    80106318 <alltraps>

80106b65 <vector51>:
.globl vector51
vector51:
  pushl $0
80106b65:	6a 00                	push   $0x0
  pushl $51
80106b67:	6a 33                	push   $0x33
  jmp alltraps
80106b69:	e9 aa f7 ff ff       	jmp    80106318 <alltraps>

80106b6e <vector52>:
.globl vector52
vector52:
  pushl $0
80106b6e:	6a 00                	push   $0x0
  pushl $52
80106b70:	6a 34                	push   $0x34
  jmp alltraps
80106b72:	e9 a1 f7 ff ff       	jmp    80106318 <alltraps>

80106b77 <vector53>:
.globl vector53
vector53:
  pushl $0
80106b77:	6a 00                	push   $0x0
  pushl $53
80106b79:	6a 35                	push   $0x35
  jmp alltraps
80106b7b:	e9 98 f7 ff ff       	jmp    80106318 <alltraps>

80106b80 <vector54>:
.globl vector54
vector54:
  pushl $0
80106b80:	6a 00                	push   $0x0
  pushl $54
80106b82:	6a 36                	push   $0x36
  jmp alltraps
80106b84:	e9 8f f7 ff ff       	jmp    80106318 <alltraps>

80106b89 <vector55>:
.globl vector55
vector55:
  pushl $0
80106b89:	6a 00                	push   $0x0
  pushl $55
80106b8b:	6a 37                	push   $0x37
  jmp alltraps
80106b8d:	e9 86 f7 ff ff       	jmp    80106318 <alltraps>

80106b92 <vector56>:
.globl vector56
vector56:
  pushl $0
80106b92:	6a 00                	push   $0x0
  pushl $56
80106b94:	6a 38                	push   $0x38
  jmp alltraps
80106b96:	e9 7d f7 ff ff       	jmp    80106318 <alltraps>

80106b9b <vector57>:
.globl vector57
vector57:
  pushl $0
80106b9b:	6a 00                	push   $0x0
  pushl $57
80106b9d:	6a 39                	push   $0x39
  jmp alltraps
80106b9f:	e9 74 f7 ff ff       	jmp    80106318 <alltraps>

80106ba4 <vector58>:
.globl vector58
vector58:
  pushl $0
80106ba4:	6a 00                	push   $0x0
  pushl $58
80106ba6:	6a 3a                	push   $0x3a
  jmp alltraps
80106ba8:	e9 6b f7 ff ff       	jmp    80106318 <alltraps>

80106bad <vector59>:
.globl vector59
vector59:
  pushl $0
80106bad:	6a 00                	push   $0x0
  pushl $59
80106baf:	6a 3b                	push   $0x3b
  jmp alltraps
80106bb1:	e9 62 f7 ff ff       	jmp    80106318 <alltraps>

80106bb6 <vector60>:
.globl vector60
vector60:
  pushl $0
80106bb6:	6a 00                	push   $0x0
  pushl $60
80106bb8:	6a 3c                	push   $0x3c
  jmp alltraps
80106bba:	e9 59 f7 ff ff       	jmp    80106318 <alltraps>

80106bbf <vector61>:
.globl vector61
vector61:
  pushl $0
80106bbf:	6a 00                	push   $0x0
  pushl $61
80106bc1:	6a 3d                	push   $0x3d
  jmp alltraps
80106bc3:	e9 50 f7 ff ff       	jmp    80106318 <alltraps>

80106bc8 <vector62>:
.globl vector62
vector62:
  pushl $0
80106bc8:	6a 00                	push   $0x0
  pushl $62
80106bca:	6a 3e                	push   $0x3e
  jmp alltraps
80106bcc:	e9 47 f7 ff ff       	jmp    80106318 <alltraps>

80106bd1 <vector63>:
.globl vector63
vector63:
  pushl $0
80106bd1:	6a 00                	push   $0x0
  pushl $63
80106bd3:	6a 3f                	push   $0x3f
  jmp alltraps
80106bd5:	e9 3e f7 ff ff       	jmp    80106318 <alltraps>

80106bda <vector64>:
.globl vector64
vector64:
  pushl $0
80106bda:	6a 00                	push   $0x0
  pushl $64
80106bdc:	6a 40                	push   $0x40
  jmp alltraps
80106bde:	e9 35 f7 ff ff       	jmp    80106318 <alltraps>

80106be3 <vector65>:
.globl vector65
vector65:
  pushl $0
80106be3:	6a 00                	push   $0x0
  pushl $65
80106be5:	6a 41                	push   $0x41
  jmp alltraps
80106be7:	e9 2c f7 ff ff       	jmp    80106318 <alltraps>

80106bec <vector66>:
.globl vector66
vector66:
  pushl $0
80106bec:	6a 00                	push   $0x0
  pushl $66
80106bee:	6a 42                	push   $0x42
  jmp alltraps
80106bf0:	e9 23 f7 ff ff       	jmp    80106318 <alltraps>

80106bf5 <vector67>:
.globl vector67
vector67:
  pushl $0
80106bf5:	6a 00                	push   $0x0
  pushl $67
80106bf7:	6a 43                	push   $0x43
  jmp alltraps
80106bf9:	e9 1a f7 ff ff       	jmp    80106318 <alltraps>

80106bfe <vector68>:
.globl vector68
vector68:
  pushl $0
80106bfe:	6a 00                	push   $0x0
  pushl $68
80106c00:	6a 44                	push   $0x44
  jmp alltraps
80106c02:	e9 11 f7 ff ff       	jmp    80106318 <alltraps>

80106c07 <vector69>:
.globl vector69
vector69:
  pushl $0
80106c07:	6a 00                	push   $0x0
  pushl $69
80106c09:	6a 45                	push   $0x45
  jmp alltraps
80106c0b:	e9 08 f7 ff ff       	jmp    80106318 <alltraps>

80106c10 <vector70>:
.globl vector70
vector70:
  pushl $0
80106c10:	6a 00                	push   $0x0
  pushl $70
80106c12:	6a 46                	push   $0x46
  jmp alltraps
80106c14:	e9 ff f6 ff ff       	jmp    80106318 <alltraps>

80106c19 <vector71>:
.globl vector71
vector71:
  pushl $0
80106c19:	6a 00                	push   $0x0
  pushl $71
80106c1b:	6a 47                	push   $0x47
  jmp alltraps
80106c1d:	e9 f6 f6 ff ff       	jmp    80106318 <alltraps>

80106c22 <vector72>:
.globl vector72
vector72:
  pushl $0
80106c22:	6a 00                	push   $0x0
  pushl $72
80106c24:	6a 48                	push   $0x48
  jmp alltraps
80106c26:	e9 ed f6 ff ff       	jmp    80106318 <alltraps>

80106c2b <vector73>:
.globl vector73
vector73:
  pushl $0
80106c2b:	6a 00                	push   $0x0
  pushl $73
80106c2d:	6a 49                	push   $0x49
  jmp alltraps
80106c2f:	e9 e4 f6 ff ff       	jmp    80106318 <alltraps>

80106c34 <vector74>:
.globl vector74
vector74:
  pushl $0
80106c34:	6a 00                	push   $0x0
  pushl $74
80106c36:	6a 4a                	push   $0x4a
  jmp alltraps
80106c38:	e9 db f6 ff ff       	jmp    80106318 <alltraps>

80106c3d <vector75>:
.globl vector75
vector75:
  pushl $0
80106c3d:	6a 00                	push   $0x0
  pushl $75
80106c3f:	6a 4b                	push   $0x4b
  jmp alltraps
80106c41:	e9 d2 f6 ff ff       	jmp    80106318 <alltraps>

80106c46 <vector76>:
.globl vector76
vector76:
  pushl $0
80106c46:	6a 00                	push   $0x0
  pushl $76
80106c48:	6a 4c                	push   $0x4c
  jmp alltraps
80106c4a:	e9 c9 f6 ff ff       	jmp    80106318 <alltraps>

80106c4f <vector77>:
.globl vector77
vector77:
  pushl $0
80106c4f:	6a 00                	push   $0x0
  pushl $77
80106c51:	6a 4d                	push   $0x4d
  jmp alltraps
80106c53:	e9 c0 f6 ff ff       	jmp    80106318 <alltraps>

80106c58 <vector78>:
.globl vector78
vector78:
  pushl $0
80106c58:	6a 00                	push   $0x0
  pushl $78
80106c5a:	6a 4e                	push   $0x4e
  jmp alltraps
80106c5c:	e9 b7 f6 ff ff       	jmp    80106318 <alltraps>

80106c61 <vector79>:
.globl vector79
vector79:
  pushl $0
80106c61:	6a 00                	push   $0x0
  pushl $79
80106c63:	6a 4f                	push   $0x4f
  jmp alltraps
80106c65:	e9 ae f6 ff ff       	jmp    80106318 <alltraps>

80106c6a <vector80>:
.globl vector80
vector80:
  pushl $0
80106c6a:	6a 00                	push   $0x0
  pushl $80
80106c6c:	6a 50                	push   $0x50
  jmp alltraps
80106c6e:	e9 a5 f6 ff ff       	jmp    80106318 <alltraps>

80106c73 <vector81>:
.globl vector81
vector81:
  pushl $0
80106c73:	6a 00                	push   $0x0
  pushl $81
80106c75:	6a 51                	push   $0x51
  jmp alltraps
80106c77:	e9 9c f6 ff ff       	jmp    80106318 <alltraps>

80106c7c <vector82>:
.globl vector82
vector82:
  pushl $0
80106c7c:	6a 00                	push   $0x0
  pushl $82
80106c7e:	6a 52                	push   $0x52
  jmp alltraps
80106c80:	e9 93 f6 ff ff       	jmp    80106318 <alltraps>

80106c85 <vector83>:
.globl vector83
vector83:
  pushl $0
80106c85:	6a 00                	push   $0x0
  pushl $83
80106c87:	6a 53                	push   $0x53
  jmp alltraps
80106c89:	e9 8a f6 ff ff       	jmp    80106318 <alltraps>

80106c8e <vector84>:
.globl vector84
vector84:
  pushl $0
80106c8e:	6a 00                	push   $0x0
  pushl $84
80106c90:	6a 54                	push   $0x54
  jmp alltraps
80106c92:	e9 81 f6 ff ff       	jmp    80106318 <alltraps>

80106c97 <vector85>:
.globl vector85
vector85:
  pushl $0
80106c97:	6a 00                	push   $0x0
  pushl $85
80106c99:	6a 55                	push   $0x55
  jmp alltraps
80106c9b:	e9 78 f6 ff ff       	jmp    80106318 <alltraps>

80106ca0 <vector86>:
.globl vector86
vector86:
  pushl $0
80106ca0:	6a 00                	push   $0x0
  pushl $86
80106ca2:	6a 56                	push   $0x56
  jmp alltraps
80106ca4:	e9 6f f6 ff ff       	jmp    80106318 <alltraps>

80106ca9 <vector87>:
.globl vector87
vector87:
  pushl $0
80106ca9:	6a 00                	push   $0x0
  pushl $87
80106cab:	6a 57                	push   $0x57
  jmp alltraps
80106cad:	e9 66 f6 ff ff       	jmp    80106318 <alltraps>

80106cb2 <vector88>:
.globl vector88
vector88:
  pushl $0
80106cb2:	6a 00                	push   $0x0
  pushl $88
80106cb4:	6a 58                	push   $0x58
  jmp alltraps
80106cb6:	e9 5d f6 ff ff       	jmp    80106318 <alltraps>

80106cbb <vector89>:
.globl vector89
vector89:
  pushl $0
80106cbb:	6a 00                	push   $0x0
  pushl $89
80106cbd:	6a 59                	push   $0x59
  jmp alltraps
80106cbf:	e9 54 f6 ff ff       	jmp    80106318 <alltraps>

80106cc4 <vector90>:
.globl vector90
vector90:
  pushl $0
80106cc4:	6a 00                	push   $0x0
  pushl $90
80106cc6:	6a 5a                	push   $0x5a
  jmp alltraps
80106cc8:	e9 4b f6 ff ff       	jmp    80106318 <alltraps>

80106ccd <vector91>:
.globl vector91
vector91:
  pushl $0
80106ccd:	6a 00                	push   $0x0
  pushl $91
80106ccf:	6a 5b                	push   $0x5b
  jmp alltraps
80106cd1:	e9 42 f6 ff ff       	jmp    80106318 <alltraps>

80106cd6 <vector92>:
.globl vector92
vector92:
  pushl $0
80106cd6:	6a 00                	push   $0x0
  pushl $92
80106cd8:	6a 5c                	push   $0x5c
  jmp alltraps
80106cda:	e9 39 f6 ff ff       	jmp    80106318 <alltraps>

80106cdf <vector93>:
.globl vector93
vector93:
  pushl $0
80106cdf:	6a 00                	push   $0x0
  pushl $93
80106ce1:	6a 5d                	push   $0x5d
  jmp alltraps
80106ce3:	e9 30 f6 ff ff       	jmp    80106318 <alltraps>

80106ce8 <vector94>:
.globl vector94
vector94:
  pushl $0
80106ce8:	6a 00                	push   $0x0
  pushl $94
80106cea:	6a 5e                	push   $0x5e
  jmp alltraps
80106cec:	e9 27 f6 ff ff       	jmp    80106318 <alltraps>

80106cf1 <vector95>:
.globl vector95
vector95:
  pushl $0
80106cf1:	6a 00                	push   $0x0
  pushl $95
80106cf3:	6a 5f                	push   $0x5f
  jmp alltraps
80106cf5:	e9 1e f6 ff ff       	jmp    80106318 <alltraps>

80106cfa <vector96>:
.globl vector96
vector96:
  pushl $0
80106cfa:	6a 00                	push   $0x0
  pushl $96
80106cfc:	6a 60                	push   $0x60
  jmp alltraps
80106cfe:	e9 15 f6 ff ff       	jmp    80106318 <alltraps>

80106d03 <vector97>:
.globl vector97
vector97:
  pushl $0
80106d03:	6a 00                	push   $0x0
  pushl $97
80106d05:	6a 61                	push   $0x61
  jmp alltraps
80106d07:	e9 0c f6 ff ff       	jmp    80106318 <alltraps>

80106d0c <vector98>:
.globl vector98
vector98:
  pushl $0
80106d0c:	6a 00                	push   $0x0
  pushl $98
80106d0e:	6a 62                	push   $0x62
  jmp alltraps
80106d10:	e9 03 f6 ff ff       	jmp    80106318 <alltraps>

80106d15 <vector99>:
.globl vector99
vector99:
  pushl $0
80106d15:	6a 00                	push   $0x0
  pushl $99
80106d17:	6a 63                	push   $0x63
  jmp alltraps
80106d19:	e9 fa f5 ff ff       	jmp    80106318 <alltraps>

80106d1e <vector100>:
.globl vector100
vector100:
  pushl $0
80106d1e:	6a 00                	push   $0x0
  pushl $100
80106d20:	6a 64                	push   $0x64
  jmp alltraps
80106d22:	e9 f1 f5 ff ff       	jmp    80106318 <alltraps>

80106d27 <vector101>:
.globl vector101
vector101:
  pushl $0
80106d27:	6a 00                	push   $0x0
  pushl $101
80106d29:	6a 65                	push   $0x65
  jmp alltraps
80106d2b:	e9 e8 f5 ff ff       	jmp    80106318 <alltraps>

80106d30 <vector102>:
.globl vector102
vector102:
  pushl $0
80106d30:	6a 00                	push   $0x0
  pushl $102
80106d32:	6a 66                	push   $0x66
  jmp alltraps
80106d34:	e9 df f5 ff ff       	jmp    80106318 <alltraps>

80106d39 <vector103>:
.globl vector103
vector103:
  pushl $0
80106d39:	6a 00                	push   $0x0
  pushl $103
80106d3b:	6a 67                	push   $0x67
  jmp alltraps
80106d3d:	e9 d6 f5 ff ff       	jmp    80106318 <alltraps>

80106d42 <vector104>:
.globl vector104
vector104:
  pushl $0
80106d42:	6a 00                	push   $0x0
  pushl $104
80106d44:	6a 68                	push   $0x68
  jmp alltraps
80106d46:	e9 cd f5 ff ff       	jmp    80106318 <alltraps>

80106d4b <vector105>:
.globl vector105
vector105:
  pushl $0
80106d4b:	6a 00                	push   $0x0
  pushl $105
80106d4d:	6a 69                	push   $0x69
  jmp alltraps
80106d4f:	e9 c4 f5 ff ff       	jmp    80106318 <alltraps>

80106d54 <vector106>:
.globl vector106
vector106:
  pushl $0
80106d54:	6a 00                	push   $0x0
  pushl $106
80106d56:	6a 6a                	push   $0x6a
  jmp alltraps
80106d58:	e9 bb f5 ff ff       	jmp    80106318 <alltraps>

80106d5d <vector107>:
.globl vector107
vector107:
  pushl $0
80106d5d:	6a 00                	push   $0x0
  pushl $107
80106d5f:	6a 6b                	push   $0x6b
  jmp alltraps
80106d61:	e9 b2 f5 ff ff       	jmp    80106318 <alltraps>

80106d66 <vector108>:
.globl vector108
vector108:
  pushl $0
80106d66:	6a 00                	push   $0x0
  pushl $108
80106d68:	6a 6c                	push   $0x6c
  jmp alltraps
80106d6a:	e9 a9 f5 ff ff       	jmp    80106318 <alltraps>

80106d6f <vector109>:
.globl vector109
vector109:
  pushl $0
80106d6f:	6a 00                	push   $0x0
  pushl $109
80106d71:	6a 6d                	push   $0x6d
  jmp alltraps
80106d73:	e9 a0 f5 ff ff       	jmp    80106318 <alltraps>

80106d78 <vector110>:
.globl vector110
vector110:
  pushl $0
80106d78:	6a 00                	push   $0x0
  pushl $110
80106d7a:	6a 6e                	push   $0x6e
  jmp alltraps
80106d7c:	e9 97 f5 ff ff       	jmp    80106318 <alltraps>

80106d81 <vector111>:
.globl vector111
vector111:
  pushl $0
80106d81:	6a 00                	push   $0x0
  pushl $111
80106d83:	6a 6f                	push   $0x6f
  jmp alltraps
80106d85:	e9 8e f5 ff ff       	jmp    80106318 <alltraps>

80106d8a <vector112>:
.globl vector112
vector112:
  pushl $0
80106d8a:	6a 00                	push   $0x0
  pushl $112
80106d8c:	6a 70                	push   $0x70
  jmp alltraps
80106d8e:	e9 85 f5 ff ff       	jmp    80106318 <alltraps>

80106d93 <vector113>:
.globl vector113
vector113:
  pushl $0
80106d93:	6a 00                	push   $0x0
  pushl $113
80106d95:	6a 71                	push   $0x71
  jmp alltraps
80106d97:	e9 7c f5 ff ff       	jmp    80106318 <alltraps>

80106d9c <vector114>:
.globl vector114
vector114:
  pushl $0
80106d9c:	6a 00                	push   $0x0
  pushl $114
80106d9e:	6a 72                	push   $0x72
  jmp alltraps
80106da0:	e9 73 f5 ff ff       	jmp    80106318 <alltraps>

80106da5 <vector115>:
.globl vector115
vector115:
  pushl $0
80106da5:	6a 00                	push   $0x0
  pushl $115
80106da7:	6a 73                	push   $0x73
  jmp alltraps
80106da9:	e9 6a f5 ff ff       	jmp    80106318 <alltraps>

80106dae <vector116>:
.globl vector116
vector116:
  pushl $0
80106dae:	6a 00                	push   $0x0
  pushl $116
80106db0:	6a 74                	push   $0x74
  jmp alltraps
80106db2:	e9 61 f5 ff ff       	jmp    80106318 <alltraps>

80106db7 <vector117>:
.globl vector117
vector117:
  pushl $0
80106db7:	6a 00                	push   $0x0
  pushl $117
80106db9:	6a 75                	push   $0x75
  jmp alltraps
80106dbb:	e9 58 f5 ff ff       	jmp    80106318 <alltraps>

80106dc0 <vector118>:
.globl vector118
vector118:
  pushl $0
80106dc0:	6a 00                	push   $0x0
  pushl $118
80106dc2:	6a 76                	push   $0x76
  jmp alltraps
80106dc4:	e9 4f f5 ff ff       	jmp    80106318 <alltraps>

80106dc9 <vector119>:
.globl vector119
vector119:
  pushl $0
80106dc9:	6a 00                	push   $0x0
  pushl $119
80106dcb:	6a 77                	push   $0x77
  jmp alltraps
80106dcd:	e9 46 f5 ff ff       	jmp    80106318 <alltraps>

80106dd2 <vector120>:
.globl vector120
vector120:
  pushl $0
80106dd2:	6a 00                	push   $0x0
  pushl $120
80106dd4:	6a 78                	push   $0x78
  jmp alltraps
80106dd6:	e9 3d f5 ff ff       	jmp    80106318 <alltraps>

80106ddb <vector121>:
.globl vector121
vector121:
  pushl $0
80106ddb:	6a 00                	push   $0x0
  pushl $121
80106ddd:	6a 79                	push   $0x79
  jmp alltraps
80106ddf:	e9 34 f5 ff ff       	jmp    80106318 <alltraps>

80106de4 <vector122>:
.globl vector122
vector122:
  pushl $0
80106de4:	6a 00                	push   $0x0
  pushl $122
80106de6:	6a 7a                	push   $0x7a
  jmp alltraps
80106de8:	e9 2b f5 ff ff       	jmp    80106318 <alltraps>

80106ded <vector123>:
.globl vector123
vector123:
  pushl $0
80106ded:	6a 00                	push   $0x0
  pushl $123
80106def:	6a 7b                	push   $0x7b
  jmp alltraps
80106df1:	e9 22 f5 ff ff       	jmp    80106318 <alltraps>

80106df6 <vector124>:
.globl vector124
vector124:
  pushl $0
80106df6:	6a 00                	push   $0x0
  pushl $124
80106df8:	6a 7c                	push   $0x7c
  jmp alltraps
80106dfa:	e9 19 f5 ff ff       	jmp    80106318 <alltraps>

80106dff <vector125>:
.globl vector125
vector125:
  pushl $0
80106dff:	6a 00                	push   $0x0
  pushl $125
80106e01:	6a 7d                	push   $0x7d
  jmp alltraps
80106e03:	e9 10 f5 ff ff       	jmp    80106318 <alltraps>

80106e08 <vector126>:
.globl vector126
vector126:
  pushl $0
80106e08:	6a 00                	push   $0x0
  pushl $126
80106e0a:	6a 7e                	push   $0x7e
  jmp alltraps
80106e0c:	e9 07 f5 ff ff       	jmp    80106318 <alltraps>

80106e11 <vector127>:
.globl vector127
vector127:
  pushl $0
80106e11:	6a 00                	push   $0x0
  pushl $127
80106e13:	6a 7f                	push   $0x7f
  jmp alltraps
80106e15:	e9 fe f4 ff ff       	jmp    80106318 <alltraps>

80106e1a <vector128>:
.globl vector128
vector128:
  pushl $0
80106e1a:	6a 00                	push   $0x0
  pushl $128
80106e1c:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80106e21:	e9 f2 f4 ff ff       	jmp    80106318 <alltraps>

80106e26 <vector129>:
.globl vector129
vector129:
  pushl $0
80106e26:	6a 00                	push   $0x0
  pushl $129
80106e28:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80106e2d:	e9 e6 f4 ff ff       	jmp    80106318 <alltraps>

80106e32 <vector130>:
.globl vector130
vector130:
  pushl $0
80106e32:	6a 00                	push   $0x0
  pushl $130
80106e34:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80106e39:	e9 da f4 ff ff       	jmp    80106318 <alltraps>

80106e3e <vector131>:
.globl vector131
vector131:
  pushl $0
80106e3e:	6a 00                	push   $0x0
  pushl $131
80106e40:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80106e45:	e9 ce f4 ff ff       	jmp    80106318 <alltraps>

80106e4a <vector132>:
.globl vector132
vector132:
  pushl $0
80106e4a:	6a 00                	push   $0x0
  pushl $132
80106e4c:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80106e51:	e9 c2 f4 ff ff       	jmp    80106318 <alltraps>

80106e56 <vector133>:
.globl vector133
vector133:
  pushl $0
80106e56:	6a 00                	push   $0x0
  pushl $133
80106e58:	68 85 00 00 00       	push   $0x85
  jmp alltraps
80106e5d:	e9 b6 f4 ff ff       	jmp    80106318 <alltraps>

80106e62 <vector134>:
.globl vector134
vector134:
  pushl $0
80106e62:	6a 00                	push   $0x0
  pushl $134
80106e64:	68 86 00 00 00       	push   $0x86
  jmp alltraps
80106e69:	e9 aa f4 ff ff       	jmp    80106318 <alltraps>

80106e6e <vector135>:
.globl vector135
vector135:
  pushl $0
80106e6e:	6a 00                	push   $0x0
  pushl $135
80106e70:	68 87 00 00 00       	push   $0x87
  jmp alltraps
80106e75:	e9 9e f4 ff ff       	jmp    80106318 <alltraps>

80106e7a <vector136>:
.globl vector136
vector136:
  pushl $0
80106e7a:	6a 00                	push   $0x0
  pushl $136
80106e7c:	68 88 00 00 00       	push   $0x88
  jmp alltraps
80106e81:	e9 92 f4 ff ff       	jmp    80106318 <alltraps>

80106e86 <vector137>:
.globl vector137
vector137:
  pushl $0
80106e86:	6a 00                	push   $0x0
  pushl $137
80106e88:	68 89 00 00 00       	push   $0x89
  jmp alltraps
80106e8d:	e9 86 f4 ff ff       	jmp    80106318 <alltraps>

80106e92 <vector138>:
.globl vector138
vector138:
  pushl $0
80106e92:	6a 00                	push   $0x0
  pushl $138
80106e94:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
80106e99:	e9 7a f4 ff ff       	jmp    80106318 <alltraps>

80106e9e <vector139>:
.globl vector139
vector139:
  pushl $0
80106e9e:	6a 00                	push   $0x0
  pushl $139
80106ea0:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
80106ea5:	e9 6e f4 ff ff       	jmp    80106318 <alltraps>

80106eaa <vector140>:
.globl vector140
vector140:
  pushl $0
80106eaa:	6a 00                	push   $0x0
  pushl $140
80106eac:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
80106eb1:	e9 62 f4 ff ff       	jmp    80106318 <alltraps>

80106eb6 <vector141>:
.globl vector141
vector141:
  pushl $0
80106eb6:	6a 00                	push   $0x0
  pushl $141
80106eb8:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80106ebd:	e9 56 f4 ff ff       	jmp    80106318 <alltraps>

80106ec2 <vector142>:
.globl vector142
vector142:
  pushl $0
80106ec2:	6a 00                	push   $0x0
  pushl $142
80106ec4:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80106ec9:	e9 4a f4 ff ff       	jmp    80106318 <alltraps>

80106ece <vector143>:
.globl vector143
vector143:
  pushl $0
80106ece:	6a 00                	push   $0x0
  pushl $143
80106ed0:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80106ed5:	e9 3e f4 ff ff       	jmp    80106318 <alltraps>

80106eda <vector144>:
.globl vector144
vector144:
  pushl $0
80106eda:	6a 00                	push   $0x0
  pushl $144
80106edc:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80106ee1:	e9 32 f4 ff ff       	jmp    80106318 <alltraps>

80106ee6 <vector145>:
.globl vector145
vector145:
  pushl $0
80106ee6:	6a 00                	push   $0x0
  pushl $145
80106ee8:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80106eed:	e9 26 f4 ff ff       	jmp    80106318 <alltraps>

80106ef2 <vector146>:
.globl vector146
vector146:
  pushl $0
80106ef2:	6a 00                	push   $0x0
  pushl $146
80106ef4:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80106ef9:	e9 1a f4 ff ff       	jmp    80106318 <alltraps>

80106efe <vector147>:
.globl vector147
vector147:
  pushl $0
80106efe:	6a 00                	push   $0x0
  pushl $147
80106f00:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80106f05:	e9 0e f4 ff ff       	jmp    80106318 <alltraps>

80106f0a <vector148>:
.globl vector148
vector148:
  pushl $0
80106f0a:	6a 00                	push   $0x0
  pushl $148
80106f0c:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80106f11:	e9 02 f4 ff ff       	jmp    80106318 <alltraps>

80106f16 <vector149>:
.globl vector149
vector149:
  pushl $0
80106f16:	6a 00                	push   $0x0
  pushl $149
80106f18:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80106f1d:	e9 f6 f3 ff ff       	jmp    80106318 <alltraps>

80106f22 <vector150>:
.globl vector150
vector150:
  pushl $0
80106f22:	6a 00                	push   $0x0
  pushl $150
80106f24:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80106f29:	e9 ea f3 ff ff       	jmp    80106318 <alltraps>

80106f2e <vector151>:
.globl vector151
vector151:
  pushl $0
80106f2e:	6a 00                	push   $0x0
  pushl $151
80106f30:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80106f35:	e9 de f3 ff ff       	jmp    80106318 <alltraps>

80106f3a <vector152>:
.globl vector152
vector152:
  pushl $0
80106f3a:	6a 00                	push   $0x0
  pushl $152
80106f3c:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80106f41:	e9 d2 f3 ff ff       	jmp    80106318 <alltraps>

80106f46 <vector153>:
.globl vector153
vector153:
  pushl $0
80106f46:	6a 00                	push   $0x0
  pushl $153
80106f48:	68 99 00 00 00       	push   $0x99
  jmp alltraps
80106f4d:	e9 c6 f3 ff ff       	jmp    80106318 <alltraps>

80106f52 <vector154>:
.globl vector154
vector154:
  pushl $0
80106f52:	6a 00                	push   $0x0
  pushl $154
80106f54:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80106f59:	e9 ba f3 ff ff       	jmp    80106318 <alltraps>

80106f5e <vector155>:
.globl vector155
vector155:
  pushl $0
80106f5e:	6a 00                	push   $0x0
  pushl $155
80106f60:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
80106f65:	e9 ae f3 ff ff       	jmp    80106318 <alltraps>

80106f6a <vector156>:
.globl vector156
vector156:
  pushl $0
80106f6a:	6a 00                	push   $0x0
  pushl $156
80106f6c:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
80106f71:	e9 a2 f3 ff ff       	jmp    80106318 <alltraps>

80106f76 <vector157>:
.globl vector157
vector157:
  pushl $0
80106f76:	6a 00                	push   $0x0
  pushl $157
80106f78:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
80106f7d:	e9 96 f3 ff ff       	jmp    80106318 <alltraps>

80106f82 <vector158>:
.globl vector158
vector158:
  pushl $0
80106f82:	6a 00                	push   $0x0
  pushl $158
80106f84:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
80106f89:	e9 8a f3 ff ff       	jmp    80106318 <alltraps>

80106f8e <vector159>:
.globl vector159
vector159:
  pushl $0
80106f8e:	6a 00                	push   $0x0
  pushl $159
80106f90:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
80106f95:	e9 7e f3 ff ff       	jmp    80106318 <alltraps>

80106f9a <vector160>:
.globl vector160
vector160:
  pushl $0
80106f9a:	6a 00                	push   $0x0
  pushl $160
80106f9c:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
80106fa1:	e9 72 f3 ff ff       	jmp    80106318 <alltraps>

80106fa6 <vector161>:
.globl vector161
vector161:
  pushl $0
80106fa6:	6a 00                	push   $0x0
  pushl $161
80106fa8:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80106fad:	e9 66 f3 ff ff       	jmp    80106318 <alltraps>

80106fb2 <vector162>:
.globl vector162
vector162:
  pushl $0
80106fb2:	6a 00                	push   $0x0
  pushl $162
80106fb4:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80106fb9:	e9 5a f3 ff ff       	jmp    80106318 <alltraps>

80106fbe <vector163>:
.globl vector163
vector163:
  pushl $0
80106fbe:	6a 00                	push   $0x0
  pushl $163
80106fc0:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80106fc5:	e9 4e f3 ff ff       	jmp    80106318 <alltraps>

80106fca <vector164>:
.globl vector164
vector164:
  pushl $0
80106fca:	6a 00                	push   $0x0
  pushl $164
80106fcc:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80106fd1:	e9 42 f3 ff ff       	jmp    80106318 <alltraps>

80106fd6 <vector165>:
.globl vector165
vector165:
  pushl $0
80106fd6:	6a 00                	push   $0x0
  pushl $165
80106fd8:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80106fdd:	e9 36 f3 ff ff       	jmp    80106318 <alltraps>

80106fe2 <vector166>:
.globl vector166
vector166:
  pushl $0
80106fe2:	6a 00                	push   $0x0
  pushl $166
80106fe4:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80106fe9:	e9 2a f3 ff ff       	jmp    80106318 <alltraps>

80106fee <vector167>:
.globl vector167
vector167:
  pushl $0
80106fee:	6a 00                	push   $0x0
  pushl $167
80106ff0:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80106ff5:	e9 1e f3 ff ff       	jmp    80106318 <alltraps>

80106ffa <vector168>:
.globl vector168
vector168:
  pushl $0
80106ffa:	6a 00                	push   $0x0
  pushl $168
80106ffc:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107001:	e9 12 f3 ff ff       	jmp    80106318 <alltraps>

80107006 <vector169>:
.globl vector169
vector169:
  pushl $0
80107006:	6a 00                	push   $0x0
  pushl $169
80107008:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010700d:	e9 06 f3 ff ff       	jmp    80106318 <alltraps>

80107012 <vector170>:
.globl vector170
vector170:
  pushl $0
80107012:	6a 00                	push   $0x0
  pushl $170
80107014:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107019:	e9 fa f2 ff ff       	jmp    80106318 <alltraps>

8010701e <vector171>:
.globl vector171
vector171:
  pushl $0
8010701e:	6a 00                	push   $0x0
  pushl $171
80107020:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107025:	e9 ee f2 ff ff       	jmp    80106318 <alltraps>

8010702a <vector172>:
.globl vector172
vector172:
  pushl $0
8010702a:	6a 00                	push   $0x0
  pushl $172
8010702c:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107031:	e9 e2 f2 ff ff       	jmp    80106318 <alltraps>

80107036 <vector173>:
.globl vector173
vector173:
  pushl $0
80107036:	6a 00                	push   $0x0
  pushl $173
80107038:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010703d:	e9 d6 f2 ff ff       	jmp    80106318 <alltraps>

80107042 <vector174>:
.globl vector174
vector174:
  pushl $0
80107042:	6a 00                	push   $0x0
  pushl $174
80107044:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107049:	e9 ca f2 ff ff       	jmp    80106318 <alltraps>

8010704e <vector175>:
.globl vector175
vector175:
  pushl $0
8010704e:	6a 00                	push   $0x0
  pushl $175
80107050:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107055:	e9 be f2 ff ff       	jmp    80106318 <alltraps>

8010705a <vector176>:
.globl vector176
vector176:
  pushl $0
8010705a:	6a 00                	push   $0x0
  pushl $176
8010705c:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
80107061:	e9 b2 f2 ff ff       	jmp    80106318 <alltraps>

80107066 <vector177>:
.globl vector177
vector177:
  pushl $0
80107066:	6a 00                	push   $0x0
  pushl $177
80107068:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
8010706d:	e9 a6 f2 ff ff       	jmp    80106318 <alltraps>

80107072 <vector178>:
.globl vector178
vector178:
  pushl $0
80107072:	6a 00                	push   $0x0
  pushl $178
80107074:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
80107079:	e9 9a f2 ff ff       	jmp    80106318 <alltraps>

8010707e <vector179>:
.globl vector179
vector179:
  pushl $0
8010707e:	6a 00                	push   $0x0
  pushl $179
80107080:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
80107085:	e9 8e f2 ff ff       	jmp    80106318 <alltraps>

8010708a <vector180>:
.globl vector180
vector180:
  pushl $0
8010708a:	6a 00                	push   $0x0
  pushl $180
8010708c:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
80107091:	e9 82 f2 ff ff       	jmp    80106318 <alltraps>

80107096 <vector181>:
.globl vector181
vector181:
  pushl $0
80107096:	6a 00                	push   $0x0
  pushl $181
80107098:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
8010709d:	e9 76 f2 ff ff       	jmp    80106318 <alltraps>

801070a2 <vector182>:
.globl vector182
vector182:
  pushl $0
801070a2:	6a 00                	push   $0x0
  pushl $182
801070a4:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801070a9:	e9 6a f2 ff ff       	jmp    80106318 <alltraps>

801070ae <vector183>:
.globl vector183
vector183:
  pushl $0
801070ae:	6a 00                	push   $0x0
  pushl $183
801070b0:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801070b5:	e9 5e f2 ff ff       	jmp    80106318 <alltraps>

801070ba <vector184>:
.globl vector184
vector184:
  pushl $0
801070ba:	6a 00                	push   $0x0
  pushl $184
801070bc:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
801070c1:	e9 52 f2 ff ff       	jmp    80106318 <alltraps>

801070c6 <vector185>:
.globl vector185
vector185:
  pushl $0
801070c6:	6a 00                	push   $0x0
  pushl $185
801070c8:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
801070cd:	e9 46 f2 ff ff       	jmp    80106318 <alltraps>

801070d2 <vector186>:
.globl vector186
vector186:
  pushl $0
801070d2:	6a 00                	push   $0x0
  pushl $186
801070d4:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
801070d9:	e9 3a f2 ff ff       	jmp    80106318 <alltraps>

801070de <vector187>:
.globl vector187
vector187:
  pushl $0
801070de:	6a 00                	push   $0x0
  pushl $187
801070e0:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
801070e5:	e9 2e f2 ff ff       	jmp    80106318 <alltraps>

801070ea <vector188>:
.globl vector188
vector188:
  pushl $0
801070ea:	6a 00                	push   $0x0
  pushl $188
801070ec:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
801070f1:	e9 22 f2 ff ff       	jmp    80106318 <alltraps>

801070f6 <vector189>:
.globl vector189
vector189:
  pushl $0
801070f6:	6a 00                	push   $0x0
  pushl $189
801070f8:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
801070fd:	e9 16 f2 ff ff       	jmp    80106318 <alltraps>

80107102 <vector190>:
.globl vector190
vector190:
  pushl $0
80107102:	6a 00                	push   $0x0
  pushl $190
80107104:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107109:	e9 0a f2 ff ff       	jmp    80106318 <alltraps>

8010710e <vector191>:
.globl vector191
vector191:
  pushl $0
8010710e:	6a 00                	push   $0x0
  pushl $191
80107110:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107115:	e9 fe f1 ff ff       	jmp    80106318 <alltraps>

8010711a <vector192>:
.globl vector192
vector192:
  pushl $0
8010711a:	6a 00                	push   $0x0
  pushl $192
8010711c:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107121:	e9 f2 f1 ff ff       	jmp    80106318 <alltraps>

80107126 <vector193>:
.globl vector193
vector193:
  pushl $0
80107126:	6a 00                	push   $0x0
  pushl $193
80107128:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
8010712d:	e9 e6 f1 ff ff       	jmp    80106318 <alltraps>

80107132 <vector194>:
.globl vector194
vector194:
  pushl $0
80107132:	6a 00                	push   $0x0
  pushl $194
80107134:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107139:	e9 da f1 ff ff       	jmp    80106318 <alltraps>

8010713e <vector195>:
.globl vector195
vector195:
  pushl $0
8010713e:	6a 00                	push   $0x0
  pushl $195
80107140:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107145:	e9 ce f1 ff ff       	jmp    80106318 <alltraps>

8010714a <vector196>:
.globl vector196
vector196:
  pushl $0
8010714a:	6a 00                	push   $0x0
  pushl $196
8010714c:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107151:	e9 c2 f1 ff ff       	jmp    80106318 <alltraps>

80107156 <vector197>:
.globl vector197
vector197:
  pushl $0
80107156:	6a 00                	push   $0x0
  pushl $197
80107158:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
8010715d:	e9 b6 f1 ff ff       	jmp    80106318 <alltraps>

80107162 <vector198>:
.globl vector198
vector198:
  pushl $0
80107162:	6a 00                	push   $0x0
  pushl $198
80107164:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
80107169:	e9 aa f1 ff ff       	jmp    80106318 <alltraps>

8010716e <vector199>:
.globl vector199
vector199:
  pushl $0
8010716e:	6a 00                	push   $0x0
  pushl $199
80107170:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
80107175:	e9 9e f1 ff ff       	jmp    80106318 <alltraps>

8010717a <vector200>:
.globl vector200
vector200:
  pushl $0
8010717a:	6a 00                	push   $0x0
  pushl $200
8010717c:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
80107181:	e9 92 f1 ff ff       	jmp    80106318 <alltraps>

80107186 <vector201>:
.globl vector201
vector201:
  pushl $0
80107186:	6a 00                	push   $0x0
  pushl $201
80107188:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
8010718d:	e9 86 f1 ff ff       	jmp    80106318 <alltraps>

80107192 <vector202>:
.globl vector202
vector202:
  pushl $0
80107192:	6a 00                	push   $0x0
  pushl $202
80107194:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
80107199:	e9 7a f1 ff ff       	jmp    80106318 <alltraps>

8010719e <vector203>:
.globl vector203
vector203:
  pushl $0
8010719e:	6a 00                	push   $0x0
  pushl $203
801071a0:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801071a5:	e9 6e f1 ff ff       	jmp    80106318 <alltraps>

801071aa <vector204>:
.globl vector204
vector204:
  pushl $0
801071aa:	6a 00                	push   $0x0
  pushl $204
801071ac:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801071b1:	e9 62 f1 ff ff       	jmp    80106318 <alltraps>

801071b6 <vector205>:
.globl vector205
vector205:
  pushl $0
801071b6:	6a 00                	push   $0x0
  pushl $205
801071b8:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801071bd:	e9 56 f1 ff ff       	jmp    80106318 <alltraps>

801071c2 <vector206>:
.globl vector206
vector206:
  pushl $0
801071c2:	6a 00                	push   $0x0
  pushl $206
801071c4:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
801071c9:	e9 4a f1 ff ff       	jmp    80106318 <alltraps>

801071ce <vector207>:
.globl vector207
vector207:
  pushl $0
801071ce:	6a 00                	push   $0x0
  pushl $207
801071d0:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
801071d5:	e9 3e f1 ff ff       	jmp    80106318 <alltraps>

801071da <vector208>:
.globl vector208
vector208:
  pushl $0
801071da:	6a 00                	push   $0x0
  pushl $208
801071dc:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
801071e1:	e9 32 f1 ff ff       	jmp    80106318 <alltraps>

801071e6 <vector209>:
.globl vector209
vector209:
  pushl $0
801071e6:	6a 00                	push   $0x0
  pushl $209
801071e8:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
801071ed:	e9 26 f1 ff ff       	jmp    80106318 <alltraps>

801071f2 <vector210>:
.globl vector210
vector210:
  pushl $0
801071f2:	6a 00                	push   $0x0
  pushl $210
801071f4:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
801071f9:	e9 1a f1 ff ff       	jmp    80106318 <alltraps>

801071fe <vector211>:
.globl vector211
vector211:
  pushl $0
801071fe:	6a 00                	push   $0x0
  pushl $211
80107200:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107205:	e9 0e f1 ff ff       	jmp    80106318 <alltraps>

8010720a <vector212>:
.globl vector212
vector212:
  pushl $0
8010720a:	6a 00                	push   $0x0
  pushl $212
8010720c:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107211:	e9 02 f1 ff ff       	jmp    80106318 <alltraps>

80107216 <vector213>:
.globl vector213
vector213:
  pushl $0
80107216:	6a 00                	push   $0x0
  pushl $213
80107218:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010721d:	e9 f6 f0 ff ff       	jmp    80106318 <alltraps>

80107222 <vector214>:
.globl vector214
vector214:
  pushl $0
80107222:	6a 00                	push   $0x0
  pushl $214
80107224:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107229:	e9 ea f0 ff ff       	jmp    80106318 <alltraps>

8010722e <vector215>:
.globl vector215
vector215:
  pushl $0
8010722e:	6a 00                	push   $0x0
  pushl $215
80107230:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107235:	e9 de f0 ff ff       	jmp    80106318 <alltraps>

8010723a <vector216>:
.globl vector216
vector216:
  pushl $0
8010723a:	6a 00                	push   $0x0
  pushl $216
8010723c:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107241:	e9 d2 f0 ff ff       	jmp    80106318 <alltraps>

80107246 <vector217>:
.globl vector217
vector217:
  pushl $0
80107246:	6a 00                	push   $0x0
  pushl $217
80107248:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010724d:	e9 c6 f0 ff ff       	jmp    80106318 <alltraps>

80107252 <vector218>:
.globl vector218
vector218:
  pushl $0
80107252:	6a 00                	push   $0x0
  pushl $218
80107254:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107259:	e9 ba f0 ff ff       	jmp    80106318 <alltraps>

8010725e <vector219>:
.globl vector219
vector219:
  pushl $0
8010725e:	6a 00                	push   $0x0
  pushl $219
80107260:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
80107265:	e9 ae f0 ff ff       	jmp    80106318 <alltraps>

8010726a <vector220>:
.globl vector220
vector220:
  pushl $0
8010726a:	6a 00                	push   $0x0
  pushl $220
8010726c:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
80107271:	e9 a2 f0 ff ff       	jmp    80106318 <alltraps>

80107276 <vector221>:
.globl vector221
vector221:
  pushl $0
80107276:	6a 00                	push   $0x0
  pushl $221
80107278:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
8010727d:	e9 96 f0 ff ff       	jmp    80106318 <alltraps>

80107282 <vector222>:
.globl vector222
vector222:
  pushl $0
80107282:	6a 00                	push   $0x0
  pushl $222
80107284:	68 de 00 00 00       	push   $0xde
  jmp alltraps
80107289:	e9 8a f0 ff ff       	jmp    80106318 <alltraps>

8010728e <vector223>:
.globl vector223
vector223:
  pushl $0
8010728e:	6a 00                	push   $0x0
  pushl $223
80107290:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
80107295:	e9 7e f0 ff ff       	jmp    80106318 <alltraps>

8010729a <vector224>:
.globl vector224
vector224:
  pushl $0
8010729a:	6a 00                	push   $0x0
  pushl $224
8010729c:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801072a1:	e9 72 f0 ff ff       	jmp    80106318 <alltraps>

801072a6 <vector225>:
.globl vector225
vector225:
  pushl $0
801072a6:	6a 00                	push   $0x0
  pushl $225
801072a8:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801072ad:	e9 66 f0 ff ff       	jmp    80106318 <alltraps>

801072b2 <vector226>:
.globl vector226
vector226:
  pushl $0
801072b2:	6a 00                	push   $0x0
  pushl $226
801072b4:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801072b9:	e9 5a f0 ff ff       	jmp    80106318 <alltraps>

801072be <vector227>:
.globl vector227
vector227:
  pushl $0
801072be:	6a 00                	push   $0x0
  pushl $227
801072c0:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
801072c5:	e9 4e f0 ff ff       	jmp    80106318 <alltraps>

801072ca <vector228>:
.globl vector228
vector228:
  pushl $0
801072ca:	6a 00                	push   $0x0
  pushl $228
801072cc:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
801072d1:	e9 42 f0 ff ff       	jmp    80106318 <alltraps>

801072d6 <vector229>:
.globl vector229
vector229:
  pushl $0
801072d6:	6a 00                	push   $0x0
  pushl $229
801072d8:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
801072dd:	e9 36 f0 ff ff       	jmp    80106318 <alltraps>

801072e2 <vector230>:
.globl vector230
vector230:
  pushl $0
801072e2:	6a 00                	push   $0x0
  pushl $230
801072e4:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
801072e9:	e9 2a f0 ff ff       	jmp    80106318 <alltraps>

801072ee <vector231>:
.globl vector231
vector231:
  pushl $0
801072ee:	6a 00                	push   $0x0
  pushl $231
801072f0:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
801072f5:	e9 1e f0 ff ff       	jmp    80106318 <alltraps>

801072fa <vector232>:
.globl vector232
vector232:
  pushl $0
801072fa:	6a 00                	push   $0x0
  pushl $232
801072fc:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107301:	e9 12 f0 ff ff       	jmp    80106318 <alltraps>

80107306 <vector233>:
.globl vector233
vector233:
  pushl $0
80107306:	6a 00                	push   $0x0
  pushl $233
80107308:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010730d:	e9 06 f0 ff ff       	jmp    80106318 <alltraps>

80107312 <vector234>:
.globl vector234
vector234:
  pushl $0
80107312:	6a 00                	push   $0x0
  pushl $234
80107314:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107319:	e9 fa ef ff ff       	jmp    80106318 <alltraps>

8010731e <vector235>:
.globl vector235
vector235:
  pushl $0
8010731e:	6a 00                	push   $0x0
  pushl $235
80107320:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107325:	e9 ee ef ff ff       	jmp    80106318 <alltraps>

8010732a <vector236>:
.globl vector236
vector236:
  pushl $0
8010732a:	6a 00                	push   $0x0
  pushl $236
8010732c:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107331:	e9 e2 ef ff ff       	jmp    80106318 <alltraps>

80107336 <vector237>:
.globl vector237
vector237:
  pushl $0
80107336:	6a 00                	push   $0x0
  pushl $237
80107338:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010733d:	e9 d6 ef ff ff       	jmp    80106318 <alltraps>

80107342 <vector238>:
.globl vector238
vector238:
  pushl $0
80107342:	6a 00                	push   $0x0
  pushl $238
80107344:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107349:	e9 ca ef ff ff       	jmp    80106318 <alltraps>

8010734e <vector239>:
.globl vector239
vector239:
  pushl $0
8010734e:	6a 00                	push   $0x0
  pushl $239
80107350:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107355:	e9 be ef ff ff       	jmp    80106318 <alltraps>

8010735a <vector240>:
.globl vector240
vector240:
  pushl $0
8010735a:	6a 00                	push   $0x0
  pushl $240
8010735c:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
80107361:	e9 b2 ef ff ff       	jmp    80106318 <alltraps>

80107366 <vector241>:
.globl vector241
vector241:
  pushl $0
80107366:	6a 00                	push   $0x0
  pushl $241
80107368:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
8010736d:	e9 a6 ef ff ff       	jmp    80106318 <alltraps>

80107372 <vector242>:
.globl vector242
vector242:
  pushl $0
80107372:	6a 00                	push   $0x0
  pushl $242
80107374:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
80107379:	e9 9a ef ff ff       	jmp    80106318 <alltraps>

8010737e <vector243>:
.globl vector243
vector243:
  pushl $0
8010737e:	6a 00                	push   $0x0
  pushl $243
80107380:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
80107385:	e9 8e ef ff ff       	jmp    80106318 <alltraps>

8010738a <vector244>:
.globl vector244
vector244:
  pushl $0
8010738a:	6a 00                	push   $0x0
  pushl $244
8010738c:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
80107391:	e9 82 ef ff ff       	jmp    80106318 <alltraps>

80107396 <vector245>:
.globl vector245
vector245:
  pushl $0
80107396:	6a 00                	push   $0x0
  pushl $245
80107398:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
8010739d:	e9 76 ef ff ff       	jmp    80106318 <alltraps>

801073a2 <vector246>:
.globl vector246
vector246:
  pushl $0
801073a2:	6a 00                	push   $0x0
  pushl $246
801073a4:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801073a9:	e9 6a ef ff ff       	jmp    80106318 <alltraps>

801073ae <vector247>:
.globl vector247
vector247:
  pushl $0
801073ae:	6a 00                	push   $0x0
  pushl $247
801073b0:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801073b5:	e9 5e ef ff ff       	jmp    80106318 <alltraps>

801073ba <vector248>:
.globl vector248
vector248:
  pushl $0
801073ba:	6a 00                	push   $0x0
  pushl $248
801073bc:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
801073c1:	e9 52 ef ff ff       	jmp    80106318 <alltraps>

801073c6 <vector249>:
.globl vector249
vector249:
  pushl $0
801073c6:	6a 00                	push   $0x0
  pushl $249
801073c8:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
801073cd:	e9 46 ef ff ff       	jmp    80106318 <alltraps>

801073d2 <vector250>:
.globl vector250
vector250:
  pushl $0
801073d2:	6a 00                	push   $0x0
  pushl $250
801073d4:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
801073d9:	e9 3a ef ff ff       	jmp    80106318 <alltraps>

801073de <vector251>:
.globl vector251
vector251:
  pushl $0
801073de:	6a 00                	push   $0x0
  pushl $251
801073e0:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
801073e5:	e9 2e ef ff ff       	jmp    80106318 <alltraps>

801073ea <vector252>:
.globl vector252
vector252:
  pushl $0
801073ea:	6a 00                	push   $0x0
  pushl $252
801073ec:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
801073f1:	e9 22 ef ff ff       	jmp    80106318 <alltraps>

801073f6 <vector253>:
.globl vector253
vector253:
  pushl $0
801073f6:	6a 00                	push   $0x0
  pushl $253
801073f8:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
801073fd:	e9 16 ef ff ff       	jmp    80106318 <alltraps>

80107402 <vector254>:
.globl vector254
vector254:
  pushl $0
80107402:	6a 00                	push   $0x0
  pushl $254
80107404:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107409:	e9 0a ef ff ff       	jmp    80106318 <alltraps>

8010740e <vector255>:
.globl vector255
vector255:
  pushl $0
8010740e:	6a 00                	push   $0x0
  pushl $255
80107410:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107415:	e9 fe ee ff ff       	jmp    80106318 <alltraps>
	...

8010741c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
8010741c:	55                   	push   %ebp
8010741d:	89 e5                	mov    %esp,%ebp
8010741f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107422:	8b 45 0c             	mov    0xc(%ebp),%eax
80107425:	83 e8 01             	sub    $0x1,%eax
80107428:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010742c:	8b 45 08             	mov    0x8(%ebp),%eax
8010742f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107433:	8b 45 08             	mov    0x8(%ebp),%eax
80107436:	c1 e8 10             	shr    $0x10,%eax
80107439:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
8010743d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107440:	0f 01 10             	lgdtl  (%eax)
}
80107443:	c9                   	leave  
80107444:	c3                   	ret    

80107445 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107445:	55                   	push   %ebp
80107446:	89 e5                	mov    %esp,%ebp
80107448:	83 ec 04             	sub    $0x4,%esp
8010744b:	8b 45 08             	mov    0x8(%ebp),%eax
8010744e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107452:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107456:	0f 00 d8             	ltr    %ax
}
80107459:	c9                   	leave  
8010745a:	c3                   	ret    

8010745b <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
8010745b:	55                   	push   %ebp
8010745c:	89 e5                	mov    %esp,%ebp
8010745e:	83 ec 04             	sub    $0x4,%esp
80107461:	8b 45 08             	mov    0x8(%ebp),%eax
80107464:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107468:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
8010746c:	8e e8                	mov    %eax,%gs
}
8010746e:	c9                   	leave  
8010746f:	c3                   	ret    

80107470 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107470:	55                   	push   %ebp
80107471:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107473:	8b 45 08             	mov    0x8(%ebp),%eax
80107476:	0f 22 d8             	mov    %eax,%cr3
}
80107479:	5d                   	pop    %ebp
8010747a:	c3                   	ret    

8010747b <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010747b:	55                   	push   %ebp
8010747c:	89 e5                	mov    %esp,%ebp
8010747e:	8b 45 08             	mov    0x8(%ebp),%eax
80107481:	05 00 00 00 80       	add    $0x80000000,%eax
80107486:	5d                   	pop    %ebp
80107487:	c3                   	ret    

80107488 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107488:	55                   	push   %ebp
80107489:	89 e5                	mov    %esp,%ebp
8010748b:	8b 45 08             	mov    0x8(%ebp),%eax
8010748e:	05 00 00 00 80       	add    $0x80000000,%eax
80107493:	5d                   	pop    %ebp
80107494:	c3                   	ret    

80107495 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107495:	55                   	push   %ebp
80107496:	89 e5                	mov    %esp,%ebp
80107498:	53                   	push   %ebx
80107499:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
8010749c:	e8 40 ba ff ff       	call   80102ee1 <cpunum>
801074a1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
801074a7:	05 20 fe 10 80       	add    $0x8010fe20,%eax
801074ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801074af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074b2:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801074b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074bb:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801074c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074c4:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801074c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074cb:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074cf:	83 e2 f0             	and    $0xfffffff0,%edx
801074d2:	83 ca 0a             	or     $0xa,%edx
801074d5:	88 50 7d             	mov    %dl,0x7d(%eax)
801074d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074db:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074df:	83 ca 10             	or     $0x10,%edx
801074e2:	88 50 7d             	mov    %dl,0x7d(%eax)
801074e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074e8:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074ec:	83 e2 9f             	and    $0xffffff9f,%edx
801074ef:	88 50 7d             	mov    %dl,0x7d(%eax)
801074f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801074f5:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801074f9:	83 ca 80             	or     $0xffffff80,%edx
801074fc:	88 50 7d             	mov    %dl,0x7d(%eax)
801074ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107502:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107506:	83 ca 0f             	or     $0xf,%edx
80107509:	88 50 7e             	mov    %dl,0x7e(%eax)
8010750c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010750f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107513:	83 e2 ef             	and    $0xffffffef,%edx
80107516:	88 50 7e             	mov    %dl,0x7e(%eax)
80107519:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010751c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107520:	83 e2 df             	and    $0xffffffdf,%edx
80107523:	88 50 7e             	mov    %dl,0x7e(%eax)
80107526:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107529:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010752d:	83 ca 40             	or     $0x40,%edx
80107530:	88 50 7e             	mov    %dl,0x7e(%eax)
80107533:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107536:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010753a:	83 ca 80             	or     $0xffffff80,%edx
8010753d:	88 50 7e             	mov    %dl,0x7e(%eax)
80107540:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107543:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107547:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010754a:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107551:	ff ff 
80107553:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107556:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
8010755d:	00 00 
8010755f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107562:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107569:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010756c:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107573:	83 e2 f0             	and    $0xfffffff0,%edx
80107576:	83 ca 02             	or     $0x2,%edx
80107579:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
8010757f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107582:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107589:	83 ca 10             	or     $0x10,%edx
8010758c:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107592:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107595:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010759c:	83 e2 9f             	and    $0xffffff9f,%edx
8010759f:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075a8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801075af:	83 ca 80             	or     $0xffffff80,%edx
801075b2:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801075b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075bb:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075c2:	83 ca 0f             	or     $0xf,%edx
801075c5:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075ce:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075d5:	83 e2 ef             	and    $0xffffffef,%edx
801075d8:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075e1:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075e8:	83 e2 df             	and    $0xffffffdf,%edx
801075eb:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801075f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801075f4:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801075fb:	83 ca 40             	or     $0x40,%edx
801075fe:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107604:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107607:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
8010760e:	83 ca 80             	or     $0xffffff80,%edx
80107611:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107617:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010761a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107621:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107624:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
8010762b:	ff ff 
8010762d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107630:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107637:	00 00 
80107639:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010763c:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107643:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107646:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
8010764d:	83 e2 f0             	and    $0xfffffff0,%edx
80107650:	83 ca 0a             	or     $0xa,%edx
80107653:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107659:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010765c:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107663:	83 ca 10             	or     $0x10,%edx
80107666:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010766c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010766f:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107676:	83 ca 60             	or     $0x60,%edx
80107679:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
8010767f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107682:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107689:	83 ca 80             	or     $0xffffff80,%edx
8010768c:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107692:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107695:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
8010769c:	83 ca 0f             	or     $0xf,%edx
8010769f:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076a8:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076af:	83 e2 ef             	and    $0xffffffef,%edx
801076b2:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076bb:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076c2:	83 e2 df             	and    $0xffffffdf,%edx
801076c5:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076ce:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076d5:	83 ca 40             	or     $0x40,%edx
801076d8:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076de:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076e1:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
801076e8:	83 ca 80             	or     $0xffffff80,%edx
801076eb:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
801076f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076f4:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
801076fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801076fe:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107705:	ff ff 
80107707:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010770a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107711:	00 00 
80107713:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107716:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
8010771d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107720:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107727:	83 e2 f0             	and    $0xfffffff0,%edx
8010772a:	83 ca 02             	or     $0x2,%edx
8010772d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107733:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107736:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
8010773d:	83 ca 10             	or     $0x10,%edx
80107740:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107746:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107749:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107750:	83 ca 60             	or     $0x60,%edx
80107753:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107759:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010775c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107763:	83 ca 80             	or     $0xffffff80,%edx
80107766:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
8010776c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010776f:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107776:	83 ca 0f             	or     $0xf,%edx
80107779:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
8010777f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107782:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107789:	83 e2 ef             	and    $0xffffffef,%edx
8010778c:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107792:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107795:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
8010779c:	83 e2 df             	and    $0xffffffdf,%edx
8010779f:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077a8:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077af:	83 ca 40             	or     $0x40,%edx
801077b2:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077bb:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
801077c2:	83 ca 80             	or     $0xffffff80,%edx
801077c5:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
801077cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ce:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
801077d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077d8:	05 b4 00 00 00       	add    $0xb4,%eax
801077dd:	89 c3                	mov    %eax,%ebx
801077df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e2:	05 b4 00 00 00       	add    $0xb4,%eax
801077e7:	c1 e8 10             	shr    $0x10,%eax
801077ea:	89 c1                	mov    %eax,%ecx
801077ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ef:	05 b4 00 00 00       	add    $0xb4,%eax
801077f4:	c1 e8 18             	shr    $0x18,%eax
801077f7:	89 c2                	mov    %eax,%edx
801077f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077fc:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107803:	00 00 
80107805:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107808:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
8010780f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107812:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107818:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010781b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107822:	83 e1 f0             	and    $0xfffffff0,%ecx
80107825:	83 c9 02             	or     $0x2,%ecx
80107828:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
8010782e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107831:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107838:	83 c9 10             	or     $0x10,%ecx
8010783b:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107841:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107844:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010784b:	83 e1 9f             	and    $0xffffff9f,%ecx
8010784e:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107854:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107857:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
8010785e:	83 c9 80             	or     $0xffffff80,%ecx
80107861:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107867:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786a:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107871:	83 e1 f0             	and    $0xfffffff0,%ecx
80107874:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010787a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010787d:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107884:	83 e1 ef             	and    $0xffffffef,%ecx
80107887:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
8010788d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107890:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107897:	83 e1 df             	and    $0xffffffdf,%ecx
8010789a:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078a3:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078aa:	83 c9 40             	or     $0x40,%ecx
801078ad:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078b6:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
801078bd:	83 c9 80             	or     $0xffffff80,%ecx
801078c0:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
801078c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c9:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
801078cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d2:	83 c0 70             	add    $0x70,%eax
801078d5:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
801078dc:	00 
801078dd:	89 04 24             	mov    %eax,(%esp)
801078e0:	e8 37 fb ff ff       	call   8010741c <lgdt>
  loadgs(SEG_KCPU << 3);
801078e5:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
801078ec:	e8 6a fb ff ff       	call   8010745b <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
801078f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f4:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
801078fa:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107901:	00 00 00 00 
}
80107905:	83 c4 24             	add    $0x24,%esp
80107908:	5b                   	pop    %ebx
80107909:	5d                   	pop    %ebp
8010790a:	c3                   	ret    

8010790b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
8010790b:	55                   	push   %ebp
8010790c:	89 e5                	mov    %esp,%ebp
8010790e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107911:	8b 45 0c             	mov    0xc(%ebp),%eax
80107914:	c1 e8 16             	shr    $0x16,%eax
80107917:	c1 e0 02             	shl    $0x2,%eax
8010791a:	03 45 08             	add    0x8(%ebp),%eax
8010791d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107920:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107923:	8b 00                	mov    (%eax),%eax
80107925:	83 e0 01             	and    $0x1,%eax
80107928:	84 c0                	test   %al,%al
8010792a:	74 17                	je     80107943 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
8010792c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010792f:	8b 00                	mov    (%eax),%eax
80107931:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107936:	89 04 24             	mov    %eax,(%esp)
80107939:	e8 4a fb ff ff       	call   80107488 <p2v>
8010793e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107941:	eb 4b                	jmp    8010798e <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107943:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107947:	74 0e                	je     80107957 <walkpgdir+0x4c>
80107949:	e8 05 b2 ff ff       	call   80102b53 <kalloc>
8010794e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107951:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107955:	75 07                	jne    8010795e <walkpgdir+0x53>
      return 0;
80107957:	b8 00 00 00 00       	mov    $0x0,%eax
8010795c:	eb 41                	jmp    8010799f <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
8010795e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107965:	00 
80107966:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010796d:	00 
8010796e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107971:	89 04 24             	mov    %eax,(%esp)
80107974:	e8 35 d5 ff ff       	call   80104eae <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107979:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010797c:	89 04 24             	mov    %eax,(%esp)
8010797f:	e8 f7 fa ff ff       	call   8010747b <v2p>
80107984:	89 c2                	mov    %eax,%edx
80107986:	83 ca 07             	or     $0x7,%edx
80107989:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010798c:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
8010798e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107991:	c1 e8 0c             	shr    $0xc,%eax
80107994:	25 ff 03 00 00       	and    $0x3ff,%eax
80107999:	c1 e0 02             	shl    $0x2,%eax
8010799c:	03 45 f4             	add    -0xc(%ebp),%eax
}
8010799f:	c9                   	leave  
801079a0:	c3                   	ret    

801079a1 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
801079a1:	55                   	push   %ebp
801079a2:	89 e5                	mov    %esp,%ebp
801079a4:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
801079a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801079aa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079af:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
801079b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801079b5:	03 45 10             	add    0x10(%ebp),%eax
801079b8:	83 e8 01             	sub    $0x1,%eax
801079bb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801079c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
801079c3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
801079ca:	00 
801079cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ce:	89 44 24 04          	mov    %eax,0x4(%esp)
801079d2:	8b 45 08             	mov    0x8(%ebp),%eax
801079d5:	89 04 24             	mov    %eax,(%esp)
801079d8:	e8 2e ff ff ff       	call   8010790b <walkpgdir>
801079dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
801079e0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801079e4:	75 07                	jne    801079ed <mappages+0x4c>
      return -1;
801079e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801079eb:	eb 46                	jmp    80107a33 <mappages+0x92>
    if(*pte & PTE_P)
801079ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
801079f0:	8b 00                	mov    (%eax),%eax
801079f2:	83 e0 01             	and    $0x1,%eax
801079f5:	84 c0                	test   %al,%al
801079f7:	74 0c                	je     80107a05 <mappages+0x64>
      panic("remap");
801079f9:	c7 04 24 54 88 10 80 	movl   $0x80108854,(%esp)
80107a00:	e8 38 8b ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80107a05:	8b 45 18             	mov    0x18(%ebp),%eax
80107a08:	0b 45 14             	or     0x14(%ebp),%eax
80107a0b:	89 c2                	mov    %eax,%edx
80107a0d:	83 ca 01             	or     $0x1,%edx
80107a10:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107a13:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107a15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a18:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107a1b:	74 10                	je     80107a2d <mappages+0x8c>
      break;
    a += PGSIZE;
80107a1d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107a24:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107a2b:	eb 96                	jmp    801079c3 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107a2d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107a2e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107a33:	c9                   	leave  
80107a34:	c3                   	ret    

80107a35 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80107a35:	55                   	push   %ebp
80107a36:	89 e5                	mov    %esp,%ebp
80107a38:	53                   	push   %ebx
80107a39:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107a3c:	e8 12 b1 ff ff       	call   80102b53 <kalloc>
80107a41:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107a44:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107a48:	75 0a                	jne    80107a54 <setupkvm+0x1f>
    return 0;
80107a4a:	b8 00 00 00 00       	mov    $0x0,%eax
80107a4f:	e9 98 00 00 00       	jmp    80107aec <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80107a54:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107a5b:	00 
80107a5c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107a63:	00 
80107a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107a67:	89 04 24             	mov    %eax,(%esp)
80107a6a:	e8 3f d4 ff ff       	call   80104eae <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
80107a6f:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
80107a76:	e8 0d fa ff ff       	call   80107488 <p2v>
80107a7b:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
80107a80:	76 0c                	jbe    80107a8e <setupkvm+0x59>
    panic("PHYSTOP too high");
80107a82:	c7 04 24 5a 88 10 80 	movl   $0x8010885a,(%esp)
80107a89:	e8 af 8a ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107a8e:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
80107a95:	eb 49                	jmp    80107ae0 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
80107a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107a9a:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
80107a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
80107aa0:	8b 50 04             	mov    0x4(%eax),%edx
80107aa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aa6:	8b 58 08             	mov    0x8(%eax),%ebx
80107aa9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aac:	8b 40 04             	mov    0x4(%eax),%eax
80107aaf:	29 c3                	sub    %eax,%ebx
80107ab1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ab4:	8b 00                	mov    (%eax),%eax
80107ab6:	89 4c 24 10          	mov    %ecx,0x10(%esp)
80107aba:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107abe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107ac2:	89 44 24 04          	mov    %eax,0x4(%esp)
80107ac6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107ac9:	89 04 24             	mov    %eax,(%esp)
80107acc:	e8 d0 fe ff ff       	call   801079a1 <mappages>
80107ad1:	85 c0                	test   %eax,%eax
80107ad3:	79 07                	jns    80107adc <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80107ad5:	b8 00 00 00 00       	mov    $0x0,%eax
80107ada:	eb 10                	jmp    80107aec <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107adc:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107ae0:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80107ae7:	72 ae                	jb     80107a97 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80107ae9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107aec:	83 c4 34             	add    $0x34,%esp
80107aef:	5b                   	pop    %ebx
80107af0:	5d                   	pop    %ebp
80107af1:	c3                   	ret    

80107af2 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107af2:	55                   	push   %ebp
80107af3:	89 e5                	mov    %esp,%ebp
80107af5:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107af8:	e8 38 ff ff ff       	call   80107a35 <setupkvm>
80107afd:	a3 f8 2b 11 80       	mov    %eax,0x80112bf8
  switchkvm();
80107b02:	e8 02 00 00 00       	call   80107b09 <switchkvm>
}
80107b07:	c9                   	leave  
80107b08:	c3                   	ret    

80107b09 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107b09:	55                   	push   %ebp
80107b0a:	89 e5                	mov    %esp,%ebp
80107b0c:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
80107b0f:	a1 f8 2b 11 80       	mov    0x80112bf8,%eax
80107b14:	89 04 24             	mov    %eax,(%esp)
80107b17:	e8 5f f9 ff ff       	call   8010747b <v2p>
80107b1c:	89 04 24             	mov    %eax,(%esp)
80107b1f:	e8 4c f9 ff ff       	call   80107470 <lcr3>
}
80107b24:	c9                   	leave  
80107b25:	c3                   	ret    

80107b26 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107b26:	55                   	push   %ebp
80107b27:	89 e5                	mov    %esp,%ebp
80107b29:	53                   	push   %ebx
80107b2a:	83 ec 14             	sub    $0x14,%esp
  pushcli();
80107b2d:	e8 75 d2 ff ff       	call   80104da7 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80107b32:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107b38:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b3f:	83 c2 08             	add    $0x8,%edx
80107b42:	89 d3                	mov    %edx,%ebx
80107b44:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b4b:	83 c2 08             	add    $0x8,%edx
80107b4e:	c1 ea 10             	shr    $0x10,%edx
80107b51:	89 d1                	mov    %edx,%ecx
80107b53:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80107b5a:	83 c2 08             	add    $0x8,%edx
80107b5d:	c1 ea 18             	shr    $0x18,%edx
80107b60:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
80107b67:	67 00 
80107b69:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
80107b70:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
80107b76:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b7d:	83 e1 f0             	and    $0xfffffff0,%ecx
80107b80:	83 c9 09             	or     $0x9,%ecx
80107b83:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b89:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107b90:	83 c9 10             	or     $0x10,%ecx
80107b93:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107b99:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107ba0:	83 e1 9f             	and    $0xffffff9f,%ecx
80107ba3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107ba9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
80107bb0:	83 c9 80             	or     $0xffffff80,%ecx
80107bb3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
80107bb9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bc0:	83 e1 f0             	and    $0xfffffff0,%ecx
80107bc3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bc9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bd0:	83 e1 ef             	and    $0xffffffef,%ecx
80107bd3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bd9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107be0:	83 e1 df             	and    $0xffffffdf,%ecx
80107be3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107be9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107bf0:	83 c9 40             	or     $0x40,%ecx
80107bf3:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107bf9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80107c00:	83 e1 7f             	and    $0x7f,%ecx
80107c03:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80107c09:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
80107c0f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c15:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
80107c1c:	83 e2 ef             	and    $0xffffffef,%edx
80107c1f:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80107c25:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c2b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80107c31:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80107c37:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80107c3e:	8b 52 08             	mov    0x8(%edx),%edx
80107c41:	81 c2 00 10 00 00    	add    $0x1000,%edx
80107c47:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
80107c4a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80107c51:	e8 ef f7 ff ff       	call   80107445 <ltr>
  if(p->pgdir == 0)
80107c56:	8b 45 08             	mov    0x8(%ebp),%eax
80107c59:	8b 40 04             	mov    0x4(%eax),%eax
80107c5c:	85 c0                	test   %eax,%eax
80107c5e:	75 0c                	jne    80107c6c <switchuvm+0x146>
    panic("switchuvm: no pgdir");
80107c60:	c7 04 24 6b 88 10 80 	movl   $0x8010886b,(%esp)
80107c67:	e8 d1 88 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
80107c6c:	8b 45 08             	mov    0x8(%ebp),%eax
80107c6f:	8b 40 04             	mov    0x4(%eax),%eax
80107c72:	89 04 24             	mov    %eax,(%esp)
80107c75:	e8 01 f8 ff ff       	call   8010747b <v2p>
80107c7a:	89 04 24             	mov    %eax,(%esp)
80107c7d:	e8 ee f7 ff ff       	call   80107470 <lcr3>
  popcli();
80107c82:	e8 68 d1 ff ff       	call   80104def <popcli>
}
80107c87:	83 c4 14             	add    $0x14,%esp
80107c8a:	5b                   	pop    %ebx
80107c8b:	5d                   	pop    %ebp
80107c8c:	c3                   	ret    

80107c8d <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107c8d:	55                   	push   %ebp
80107c8e:	89 e5                	mov    %esp,%ebp
80107c90:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
80107c93:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107c9a:	76 0c                	jbe    80107ca8 <inituvm+0x1b>
    panic("inituvm: more than a page");
80107c9c:	c7 04 24 7f 88 10 80 	movl   $0x8010887f,(%esp)
80107ca3:	e8 95 88 ff ff       	call   8010053d <panic>
  mem = kalloc();
80107ca8:	e8 a6 ae ff ff       	call   80102b53 <kalloc>
80107cad:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107cb0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107cb7:	00 
80107cb8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cbf:	00 
80107cc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cc3:	89 04 24             	mov    %eax,(%esp)
80107cc6:	e8 e3 d1 ff ff       	call   80104eae <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107ccb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cce:	89 04 24             	mov    %eax,(%esp)
80107cd1:	e8 a5 f7 ff ff       	call   8010747b <v2p>
80107cd6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107cdd:	00 
80107cde:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107ce2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107ce9:	00 
80107cea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107cf1:	00 
80107cf2:	8b 45 08             	mov    0x8(%ebp),%eax
80107cf5:	89 04 24             	mov    %eax,(%esp)
80107cf8:	e8 a4 fc ff ff       	call   801079a1 <mappages>
  memmove(mem, init, sz);
80107cfd:	8b 45 10             	mov    0x10(%ebp),%eax
80107d00:	89 44 24 08          	mov    %eax,0x8(%esp)
80107d04:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d07:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d0e:	89 04 24             	mov    %eax,(%esp)
80107d11:	e8 6b d2 ff ff       	call   80104f81 <memmove>
}
80107d16:	c9                   	leave  
80107d17:	c3                   	ret    

80107d18 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107d18:	55                   	push   %ebp
80107d19:	89 e5                	mov    %esp,%ebp
80107d1b:	53                   	push   %ebx
80107d1c:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107d1f:	8b 45 0c             	mov    0xc(%ebp),%eax
80107d22:	25 ff 0f 00 00       	and    $0xfff,%eax
80107d27:	85 c0                	test   %eax,%eax
80107d29:	74 0c                	je     80107d37 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107d2b:	c7 04 24 9c 88 10 80 	movl   $0x8010889c,(%esp)
80107d32:	e8 06 88 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107d37:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107d3e:	e9 ad 00 00 00       	jmp    80107df0 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107d43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d46:	8b 55 0c             	mov    0xc(%ebp),%edx
80107d49:	01 d0                	add    %edx,%eax
80107d4b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107d52:	00 
80107d53:	89 44 24 04          	mov    %eax,0x4(%esp)
80107d57:	8b 45 08             	mov    0x8(%ebp),%eax
80107d5a:	89 04 24             	mov    %eax,(%esp)
80107d5d:	e8 a9 fb ff ff       	call   8010790b <walkpgdir>
80107d62:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107d65:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107d69:	75 0c                	jne    80107d77 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
80107d6b:	c7 04 24 bf 88 10 80 	movl   $0x801088bf,(%esp)
80107d72:	e8 c6 87 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80107d77:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107d7a:	8b 00                	mov    (%eax),%eax
80107d7c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107d81:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107d84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d87:	8b 55 18             	mov    0x18(%ebp),%edx
80107d8a:	89 d1                	mov    %edx,%ecx
80107d8c:	29 c1                	sub    %eax,%ecx
80107d8e:	89 c8                	mov    %ecx,%eax
80107d90:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107d95:	77 11                	ja     80107da8 <loaduvm+0x90>
      n = sz - i;
80107d97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d9a:	8b 55 18             	mov    0x18(%ebp),%edx
80107d9d:	89 d1                	mov    %edx,%ecx
80107d9f:	29 c1                	sub    %eax,%ecx
80107da1:	89 c8                	mov    %ecx,%eax
80107da3:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107da6:	eb 07                	jmp    80107daf <loaduvm+0x97>
    else
      n = PGSIZE;
80107da8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
80107daf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107db2:	8b 55 14             	mov    0x14(%ebp),%edx
80107db5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80107db8:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107dbb:	89 04 24             	mov    %eax,(%esp)
80107dbe:	e8 c5 f6 ff ff       	call   80107488 <p2v>
80107dc3:	8b 55 f0             	mov    -0x10(%ebp),%edx
80107dc6:	89 54 24 0c          	mov    %edx,0xc(%esp)
80107dca:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80107dce:	89 44 24 04          	mov    %eax,0x4(%esp)
80107dd2:	8b 45 10             	mov    0x10(%ebp),%eax
80107dd5:	89 04 24             	mov    %eax,(%esp)
80107dd8:	e8 d5 9f ff ff       	call   80101db2 <readi>
80107ddd:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107de0:	74 07                	je     80107de9 <loaduvm+0xd1>
      return -1;
80107de2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107de7:	eb 18                	jmp    80107e01 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107de9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107df0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107df3:	3b 45 18             	cmp    0x18(%ebp),%eax
80107df6:	0f 82 47 ff ff ff    	jb     80107d43 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107dfc:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107e01:	83 c4 24             	add    $0x24,%esp
80107e04:	5b                   	pop    %ebx
80107e05:	5d                   	pop    %ebp
80107e06:	c3                   	ret    

80107e07 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107e07:	55                   	push   %ebp
80107e08:	89 e5                	mov    %esp,%ebp
80107e0a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107e0d:	8b 45 10             	mov    0x10(%ebp),%eax
80107e10:	85 c0                	test   %eax,%eax
80107e12:	79 0a                	jns    80107e1e <allocuvm+0x17>
    return 0;
80107e14:	b8 00 00 00 00       	mov    $0x0,%eax
80107e19:	e9 c1 00 00 00       	jmp    80107edf <allocuvm+0xd8>
  if(newsz < oldsz)
80107e1e:	8b 45 10             	mov    0x10(%ebp),%eax
80107e21:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107e24:	73 08                	jae    80107e2e <allocuvm+0x27>
    return oldsz;
80107e26:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e29:	e9 b1 00 00 00       	jmp    80107edf <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
80107e2e:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e31:	05 ff 0f 00 00       	add    $0xfff,%eax
80107e36:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107e3b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80107e3e:	e9 8d 00 00 00       	jmp    80107ed0 <allocuvm+0xc9>
    mem = kalloc();
80107e43:	e8 0b ad ff ff       	call   80102b53 <kalloc>
80107e48:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80107e4b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107e4f:	75 2c                	jne    80107e7d <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80107e51:	c7 04 24 dd 88 10 80 	movl   $0x801088dd,(%esp)
80107e58:	e8 44 85 ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
80107e5d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107e60:	89 44 24 08          	mov    %eax,0x8(%esp)
80107e64:	8b 45 10             	mov    0x10(%ebp),%eax
80107e67:	89 44 24 04          	mov    %eax,0x4(%esp)
80107e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80107e6e:	89 04 24             	mov    %eax,(%esp)
80107e71:	e8 6b 00 00 00       	call   80107ee1 <deallocuvm>
      return 0;
80107e76:	b8 00 00 00 00       	mov    $0x0,%eax
80107e7b:	eb 62                	jmp    80107edf <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
80107e7d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107e84:	00 
80107e85:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107e8c:	00 
80107e8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e90:	89 04 24             	mov    %eax,(%esp)
80107e93:	e8 16 d0 ff ff       	call   80104eae <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
80107e98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107e9b:	89 04 24             	mov    %eax,(%esp)
80107e9e:	e8 d8 f5 ff ff       	call   8010747b <v2p>
80107ea3:	8b 55 f4             	mov    -0xc(%ebp),%edx
80107ea6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80107ead:	00 
80107eae:	89 44 24 0c          	mov    %eax,0xc(%esp)
80107eb2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107eb9:	00 
80107eba:	89 54 24 04          	mov    %edx,0x4(%esp)
80107ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80107ec1:	89 04 24             	mov    %eax,(%esp)
80107ec4:	e8 d8 fa ff ff       	call   801079a1 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80107ec9:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107ed0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed3:	3b 45 10             	cmp    0x10(%ebp),%eax
80107ed6:	0f 82 67 ff ff ff    	jb     80107e43 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
80107edc:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107edf:	c9                   	leave  
80107ee0:	c3                   	ret    

80107ee1 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107ee1:	55                   	push   %ebp
80107ee2:	89 e5                	mov    %esp,%ebp
80107ee4:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80107ee7:	8b 45 10             	mov    0x10(%ebp),%eax
80107eea:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107eed:	72 08                	jb     80107ef7 <deallocuvm+0x16>
    return oldsz;
80107eef:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ef2:	e9 a4 00 00 00       	jmp    80107f9b <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80107ef7:	8b 45 10             	mov    0x10(%ebp),%eax
80107efa:	05 ff 0f 00 00       	add    $0xfff,%eax
80107eff:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f04:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80107f07:	e9 80 00 00 00       	jmp    80107f8c <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
80107f0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f0f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107f16:	00 
80107f17:	89 44 24 04          	mov    %eax,0x4(%esp)
80107f1b:	8b 45 08             	mov    0x8(%ebp),%eax
80107f1e:	89 04 24             	mov    %eax,(%esp)
80107f21:	e8 e5 f9 ff ff       	call   8010790b <walkpgdir>
80107f26:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80107f29:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107f2d:	75 09                	jne    80107f38 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
80107f2f:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80107f36:	eb 4d                	jmp    80107f85 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80107f38:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f3b:	8b 00                	mov    (%eax),%eax
80107f3d:	83 e0 01             	and    $0x1,%eax
80107f40:	84 c0                	test   %al,%al
80107f42:	74 41                	je     80107f85 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80107f44:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f47:	8b 00                	mov    (%eax),%eax
80107f49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f4e:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80107f51:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107f55:	75 0c                	jne    80107f63 <deallocuvm+0x82>
        panic("kfree");
80107f57:	c7 04 24 f5 88 10 80 	movl   $0x801088f5,(%esp)
80107f5e:	e8 da 85 ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
80107f63:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107f66:	89 04 24             	mov    %eax,(%esp)
80107f69:	e8 1a f5 ff ff       	call   80107488 <p2v>
80107f6e:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
80107f71:	8b 45 e8             	mov    -0x18(%ebp),%eax
80107f74:	89 04 24             	mov    %eax,(%esp)
80107f77:	e8 3e ab ff ff       	call   80102aba <kfree>
      *pte = 0;
80107f7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f7f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80107f85:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107f8c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f8f:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107f92:	0f 82 74 ff ff ff    	jb     80107f0c <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
80107f98:	8b 45 10             	mov    0x10(%ebp),%eax
}
80107f9b:	c9                   	leave  
80107f9c:	c3                   	ret    

80107f9d <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
80107f9d:	55                   	push   %ebp
80107f9e:	89 e5                	mov    %esp,%ebp
80107fa0:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
80107fa3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107fa7:	75 0c                	jne    80107fb5 <freevm+0x18>
    panic("freevm: no pgdir");
80107fa9:	c7 04 24 fb 88 10 80 	movl   $0x801088fb,(%esp)
80107fb0:	e8 88 85 ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
80107fb5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80107fbc:	00 
80107fbd:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80107fc4:	80 
80107fc5:	8b 45 08             	mov    0x8(%ebp),%eax
80107fc8:	89 04 24             	mov    %eax,(%esp)
80107fcb:	e8 11 ff ff ff       	call   80107ee1 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80107fd0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107fd7:	eb 3c                	jmp    80108015 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80107fd9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fdc:	c1 e0 02             	shl    $0x2,%eax
80107fdf:	03 45 08             	add    0x8(%ebp),%eax
80107fe2:	8b 00                	mov    (%eax),%eax
80107fe4:	83 e0 01             	and    $0x1,%eax
80107fe7:	84 c0                	test   %al,%al
80107fe9:	74 26                	je     80108011 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
80107feb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fee:	c1 e0 02             	shl    $0x2,%eax
80107ff1:	03 45 08             	add    0x8(%ebp),%eax
80107ff4:	8b 00                	mov    (%eax),%eax
80107ff6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107ffb:	89 04 24             	mov    %eax,(%esp)
80107ffe:	e8 85 f4 ff ff       	call   80107488 <p2v>
80108003:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108006:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108009:	89 04 24             	mov    %eax,(%esp)
8010800c:	e8 a9 aa ff ff       	call   80102aba <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108011:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108015:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
8010801c:	76 bb                	jbe    80107fd9 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010801e:	8b 45 08             	mov    0x8(%ebp),%eax
80108021:	89 04 24             	mov    %eax,(%esp)
80108024:	e8 91 aa ff ff       	call   80102aba <kfree>
}
80108029:	c9                   	leave  
8010802a:	c3                   	ret    

8010802b <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010802b:	55                   	push   %ebp
8010802c:	89 e5                	mov    %esp,%ebp
8010802e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108031:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108038:	00 
80108039:	8b 45 0c             	mov    0xc(%ebp),%eax
8010803c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108040:	8b 45 08             	mov    0x8(%ebp),%eax
80108043:	89 04 24             	mov    %eax,(%esp)
80108046:	e8 c0 f8 ff ff       	call   8010790b <walkpgdir>
8010804b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010804e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108052:	75 0c                	jne    80108060 <clearpteu+0x35>
    panic("clearpteu");
80108054:	c7 04 24 0c 89 10 80 	movl   $0x8010890c,(%esp)
8010805b:	e8 dd 84 ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
80108060:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108063:	8b 00                	mov    (%eax),%eax
80108065:	89 c2                	mov    %eax,%edx
80108067:	83 e2 fb             	and    $0xfffffffb,%edx
8010806a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010806d:	89 10                	mov    %edx,(%eax)
}
8010806f:	c9                   	leave  
80108070:	c3                   	ret    

80108071 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108071:	55                   	push   %ebp
80108072:	89 e5                	mov    %esp,%ebp
80108074:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
80108077:	e8 b9 f9 ff ff       	call   80107a35 <setupkvm>
8010807c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010807f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108083:	75 0a                	jne    8010808f <copyuvm+0x1e>
    return 0;
80108085:	b8 00 00 00 00       	mov    $0x0,%eax
8010808a:	e9 f1 00 00 00       	jmp    80108180 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
8010808f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108096:	e9 c0 00 00 00       	jmp    8010815b <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
8010809b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010809e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801080a5:	00 
801080a6:	89 44 24 04          	mov    %eax,0x4(%esp)
801080aa:	8b 45 08             	mov    0x8(%ebp),%eax
801080ad:	89 04 24             	mov    %eax,(%esp)
801080b0:	e8 56 f8 ff ff       	call   8010790b <walkpgdir>
801080b5:	89 45 ec             	mov    %eax,-0x14(%ebp)
801080b8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801080bc:	75 0c                	jne    801080ca <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801080be:	c7 04 24 16 89 10 80 	movl   $0x80108916,(%esp)
801080c5:	e8 73 84 ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
801080ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
801080cd:	8b 00                	mov    (%eax),%eax
801080cf:	83 e0 01             	and    $0x1,%eax
801080d2:	85 c0                	test   %eax,%eax
801080d4:	75 0c                	jne    801080e2 <copyuvm+0x71>
      panic("copyuvm: page not present");
801080d6:	c7 04 24 30 89 10 80 	movl   $0x80108930,(%esp)
801080dd:	e8 5b 84 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801080e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801080e5:	8b 00                	mov    (%eax),%eax
801080e7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801080ec:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
801080ef:	e8 5f aa ff ff       	call   80102b53 <kalloc>
801080f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
801080f7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
801080fb:	74 6f                	je     8010816c <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
801080fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108100:	89 04 24             	mov    %eax,(%esp)
80108103:	e8 80 f3 ff ff       	call   80107488 <p2v>
80108108:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010810f:	00 
80108110:	89 44 24 04          	mov    %eax,0x4(%esp)
80108114:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108117:	89 04 24             	mov    %eax,(%esp)
8010811a:	e8 62 ce ff ff       	call   80104f81 <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
8010811f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108122:	89 04 24             	mov    %eax,(%esp)
80108125:	e8 51 f3 ff ff       	call   8010747b <v2p>
8010812a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010812d:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108134:	00 
80108135:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108139:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108140:	00 
80108141:	89 54 24 04          	mov    %edx,0x4(%esp)
80108145:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108148:	89 04 24             	mov    %eax,(%esp)
8010814b:	e8 51 f8 ff ff       	call   801079a1 <mappages>
80108150:	85 c0                	test   %eax,%eax
80108152:	78 1b                	js     8010816f <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108154:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010815b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010815e:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108161:	0f 82 34 ff ff ff    	jb     8010809b <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
80108167:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010816a:	eb 14                	jmp    80108180 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
8010816c:	90                   	nop
8010816d:	eb 01                	jmp    80108170 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
8010816f:	90                   	nop
  }
  return d;

bad:
  freevm(d);
80108170:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108173:	89 04 24             	mov    %eax,(%esp)
80108176:	e8 22 fe ff ff       	call   80107f9d <freevm>
  return 0;
8010817b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108180:	c9                   	leave  
80108181:	c3                   	ret    

80108182 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108182:	55                   	push   %ebp
80108183:	89 e5                	mov    %esp,%ebp
80108185:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108188:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
8010818f:	00 
80108190:	8b 45 0c             	mov    0xc(%ebp),%eax
80108193:	89 44 24 04          	mov    %eax,0x4(%esp)
80108197:	8b 45 08             	mov    0x8(%ebp),%eax
8010819a:	89 04 24             	mov    %eax,(%esp)
8010819d:	e8 69 f7 ff ff       	call   8010790b <walkpgdir>
801081a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801081a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081a8:	8b 00                	mov    (%eax),%eax
801081aa:	83 e0 01             	and    $0x1,%eax
801081ad:	85 c0                	test   %eax,%eax
801081af:	75 07                	jne    801081b8 <uva2ka+0x36>
    return 0;
801081b1:	b8 00 00 00 00       	mov    $0x0,%eax
801081b6:	eb 25                	jmp    801081dd <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801081b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081bb:	8b 00                	mov    (%eax),%eax
801081bd:	83 e0 04             	and    $0x4,%eax
801081c0:	85 c0                	test   %eax,%eax
801081c2:	75 07                	jne    801081cb <uva2ka+0x49>
    return 0;
801081c4:	b8 00 00 00 00       	mov    $0x0,%eax
801081c9:	eb 12                	jmp    801081dd <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
801081cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081ce:	8b 00                	mov    (%eax),%eax
801081d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081d5:	89 04 24             	mov    %eax,(%esp)
801081d8:	e8 ab f2 ff ff       	call   80107488 <p2v>
}
801081dd:	c9                   	leave  
801081de:	c3                   	ret    

801081df <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801081df:	55                   	push   %ebp
801081e0:	89 e5                	mov    %esp,%ebp
801081e2:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801081e5:	8b 45 10             	mov    0x10(%ebp),%eax
801081e8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801081eb:	e9 8b 00 00 00       	jmp    8010827b <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
801081f0:	8b 45 0c             	mov    0xc(%ebp),%eax
801081f3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801081f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801081fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
801081fe:	89 44 24 04          	mov    %eax,0x4(%esp)
80108202:	8b 45 08             	mov    0x8(%ebp),%eax
80108205:	89 04 24             	mov    %eax,(%esp)
80108208:	e8 75 ff ff ff       	call   80108182 <uva2ka>
8010820d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108210:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108214:	75 07                	jne    8010821d <copyout+0x3e>
      return -1;
80108216:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010821b:	eb 6d                	jmp    8010828a <copyout+0xab>
    n = PGSIZE - (va - va0);
8010821d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108220:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108223:	89 d1                	mov    %edx,%ecx
80108225:	29 c1                	sub    %eax,%ecx
80108227:	89 c8                	mov    %ecx,%eax
80108229:	05 00 10 00 00       	add    $0x1000,%eax
8010822e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108231:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108234:	3b 45 14             	cmp    0x14(%ebp),%eax
80108237:	76 06                	jbe    8010823f <copyout+0x60>
      n = len;
80108239:	8b 45 14             	mov    0x14(%ebp),%eax
8010823c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010823f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108242:	8b 55 0c             	mov    0xc(%ebp),%edx
80108245:	89 d1                	mov    %edx,%ecx
80108247:	29 c1                	sub    %eax,%ecx
80108249:	89 c8                	mov    %ecx,%eax
8010824b:	03 45 e8             	add    -0x18(%ebp),%eax
8010824e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108251:	89 54 24 08          	mov    %edx,0x8(%esp)
80108255:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108258:	89 54 24 04          	mov    %edx,0x4(%esp)
8010825c:	89 04 24             	mov    %eax,(%esp)
8010825f:	e8 1d cd ff ff       	call   80104f81 <memmove>
    len -= n;
80108264:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108267:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010826a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010826d:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108270:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108273:	05 00 10 00 00       	add    $0x1000,%eax
80108278:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
8010827b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
8010827f:	0f 85 6b ff ff ff    	jne    801081f0 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
80108285:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010828a:	c9                   	leave  
8010828b:	c3                   	ret    
