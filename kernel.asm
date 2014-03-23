
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
80100028:	bc 70 d0 10 80       	mov    $0x8010d070,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 7f 3a 10 80       	mov    $0x80103a7f,%eax
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
8010003a:	c7 44 24 04 cc 88 10 	movl   $0x801088cc,0x4(%esp)
80100041:	80 
80100042:	c7 04 24 80 d0 10 80 	movl   $0x8010d080,(%esp)
80100049:	e8 ac 51 00 00       	call   801051fa <initlock>

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004e:	c7 05 b0 e5 10 80 a4 	movl   $0x8010e5a4,0x8010e5b0
80100055:	e5 10 80 
  bcache.head.next = &bcache.head;
80100058:	c7 05 b4 e5 10 80 a4 	movl   $0x8010e5a4,0x8010e5b4
8010005f:	e5 10 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100062:	c7 45 f4 b4 d0 10 80 	movl   $0x8010d0b4,-0xc(%ebp)
80100069:	eb 3a                	jmp    801000a5 <binit+0x71>
    b->next = bcache.head.next;
8010006b:	8b 15 b4 e5 10 80    	mov    0x8010e5b4,%edx
80100071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100074:	89 50 10             	mov    %edx,0x10(%eax)
    b->prev = &bcache.head;
80100077:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007a:	c7 40 0c a4 e5 10 80 	movl   $0x8010e5a4,0xc(%eax)
    b->dev = -1;
80100081:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100084:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
    bcache.head.next->prev = b;
8010008b:	a1 b4 e5 10 80       	mov    0x8010e5b4,%eax
80100090:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100093:	89 50 0c             	mov    %edx,0xc(%eax)
    bcache.head.next = b;
80100096:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100099:	a3 b4 e5 10 80       	mov    %eax,0x8010e5b4

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
8010009e:	81 45 f4 18 02 00 00 	addl   $0x218,-0xc(%ebp)
801000a5:	81 7d f4 a4 e5 10 80 	cmpl   $0x8010e5a4,-0xc(%ebp)
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
801000b6:	c7 04 24 80 d0 10 80 	movl   $0x8010d080,(%esp)
801000bd:	e8 59 51 00 00       	call   8010521b <acquire>

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000c2:	a1 b4 e5 10 80       	mov    0x8010e5b4,%eax
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
801000fd:	c7 04 24 80 d0 10 80 	movl   $0x8010d080,(%esp)
80100104:	e8 74 51 00 00       	call   8010527d <release>
        return b;
80100109:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010010c:	e9 93 00 00 00       	jmp    801001a4 <bget+0xf4>
      }
      sleep(b, &bcache.lock);
80100111:	c7 44 24 04 80 d0 10 	movl   $0x8010d080,0x4(%esp)
80100118:	80 
80100119:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010011c:	89 04 24             	mov    %eax,(%esp)
8010011f:	e8 19 4e 00 00       	call   80104f3d <sleep>
      goto loop;
80100124:	eb 9c                	jmp    801000c2 <bget+0x12>

  acquire(&bcache.lock);

 loop:
  // Is the sector already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
80100126:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100129:	8b 40 10             	mov    0x10(%eax),%eax
8010012c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010012f:	81 7d f4 a4 e5 10 80 	cmpl   $0x8010e5a4,-0xc(%ebp)
80100136:	75 94                	jne    801000cc <bget+0x1c>
      goto loop;
    }
  }

  // Not cached; recycle some non-busy and clean buffer.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100138:	a1 b0 e5 10 80       	mov    0x8010e5b0,%eax
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
80100175:	c7 04 24 80 d0 10 80 	movl   $0x8010d080,(%esp)
8010017c:	e8 fc 50 00 00       	call   8010527d <release>
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
8010018f:	81 7d f4 a4 e5 10 80 	cmpl   $0x8010e5a4,-0xc(%ebp)
80100196:	75 aa                	jne    80100142 <bget+0x92>
      b->flags = B_BUSY;
      release(&bcache.lock);
      return b;
    }
  }
  panic("bget: no buffers");
80100198:	c7 04 24 d3 88 10 80 	movl   $0x801088d3,(%esp)
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
801001d3:	e8 54 2c 00 00       	call   80102e2c <iderw>
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
801001ef:	c7 04 24 e4 88 10 80 	movl   $0x801088e4,(%esp)
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
80100210:	e8 17 2c 00 00       	call   80102e2c <iderw>
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
80100229:	c7 04 24 eb 88 10 80 	movl   $0x801088eb,(%esp)
80100230:	e8 08 03 00 00       	call   8010053d <panic>

  acquire(&bcache.lock);
80100235:	c7 04 24 80 d0 10 80 	movl   $0x8010d080,(%esp)
8010023c:	e8 da 4f 00 00       	call   8010521b <acquire>

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
8010025f:	8b 15 b4 e5 10 80    	mov    0x8010e5b4,%edx
80100265:	8b 45 08             	mov    0x8(%ebp),%eax
80100268:	89 50 10             	mov    %edx,0x10(%eax)
  b->prev = &bcache.head;
8010026b:	8b 45 08             	mov    0x8(%ebp),%eax
8010026e:	c7 40 0c a4 e5 10 80 	movl   $0x8010e5a4,0xc(%eax)
  bcache.head.next->prev = b;
80100275:	a1 b4 e5 10 80       	mov    0x8010e5b4,%eax
8010027a:	8b 55 08             	mov    0x8(%ebp),%edx
8010027d:	89 50 0c             	mov    %edx,0xc(%eax)
  bcache.head.next = b;
80100280:	8b 45 08             	mov    0x8(%ebp),%eax
80100283:	a3 b4 e5 10 80       	mov    %eax,0x8010e5b4

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
8010029d:	e8 74 4d 00 00       	call   80105016 <wakeup>

  release(&bcache.lock);
801002a2:	c7 04 24 80 d0 10 80 	movl   $0x8010d080,(%esp)
801002a9:	e8 cf 4f 00 00       	call   8010527d <release>
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
80100390:	e8 e2 03 00 00       	call   80100777 <consputc>
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
801003bc:	e8 5a 4e 00 00       	call   8010521b <acquire>

  if (fmt == 0)
801003c1:	8b 45 08             	mov    0x8(%ebp),%eax
801003c4:	85 c0                	test   %eax,%eax
801003c6:	75 0c                	jne    801003d4 <cprintf+0x33>
    panic("null fmt");
801003c8:	c7 04 24 f2 88 10 80 	movl   $0x801088f2,(%esp)
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
801003f2:	e8 80 03 00 00       	call   80100777 <consputc>
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
801004af:	c7 45 ec fb 88 10 80 	movl   $0x801088fb,-0x14(%ebp)
      for(; *s; s++)
801004b6:	eb 17                	jmp    801004cf <cprintf+0x12e>
        consputc(*s);
801004b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
801004bb:	0f b6 00             	movzbl (%eax),%eax
801004be:	0f be c0             	movsbl %al,%eax
801004c1:	89 04 24             	mov    %eax,(%esp)
801004c4:	e8 ae 02 00 00       	call   80100777 <consputc>
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
801004e3:	e8 8f 02 00 00       	call   80100777 <consputc>
      break;
801004e8:	eb 18                	jmp    80100502 <cprintf+0x161>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
801004ea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
801004f1:	e8 81 02 00 00       	call   80100777 <consputc>
      consputc(c);
801004f6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801004f9:	89 04 24             	mov    %eax,(%esp)
801004fc:	e8 76 02 00 00       	call   80100777 <consputc>
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
80100536:	e8 42 4d 00 00       	call   8010527d <release>
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
80100562:	c7 04 24 02 89 10 80 	movl   $0x80108902,(%esp)
80100569:	e8 33 fe ff ff       	call   801003a1 <cprintf>
  cprintf(s);
8010056e:	8b 45 08             	mov    0x8(%ebp),%eax
80100571:	89 04 24             	mov    %eax,(%esp)
80100574:	e8 28 fe ff ff       	call   801003a1 <cprintf>
  cprintf("\n");
80100579:	c7 04 24 11 89 10 80 	movl   $0x80108911,(%esp)
80100580:	e8 1c fe ff ff       	call   801003a1 <cprintf>
  getcallerpcs(&s, pcs);
80100585:	8d 45 cc             	lea    -0x34(%ebp),%eax
80100588:	89 44 24 04          	mov    %eax,0x4(%esp)
8010058c:	8d 45 08             	lea    0x8(%ebp),%eax
8010058f:	89 04 24             	mov    %eax,(%esp)
80100592:	e8 35 4d 00 00       	call   801052cc <getcallerpcs>
  for(i=0; i<10; i++)
80100597:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010059e:	eb 1b                	jmp    801005bb <panic+0x7e>
    cprintf(" %p", pcs[i]);
801005a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801005a3:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
801005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801005ab:	c7 04 24 13 89 10 80 	movl   $0x80108913,(%esp)
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
80100656:	eb 50                	jmp    801006a8 <cgaputc+0xdb>
  
  else if((c == BACKSPACE)||(c == LEFTARROW)){
80100658:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
8010065f:	74 09                	je     8010066a <cgaputc+0x9d>
80100661:	81 7d 08 e4 00 00 00 	cmpl   $0xe4,0x8(%ebp)
80100668:	75 0c                	jne    80100676 <cgaputc+0xa9>
    if(pos > 0)
8010066a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010066e:	7e 38                	jle    801006a8 <cgaputc+0xdb>
      --pos;
80100670:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
  
  if(c == '\n')
    pos += 80 - pos%80;
  
  else if((c == BACKSPACE)||(c == LEFTARROW)){
    if(pos > 0)
80100674:	eb 32                	jmp    801006a8 <cgaputc+0xdb>
      --pos;
  }
  
  else if(c== RIGHTARROW){
80100676:	81 7d 08 e5 00 00 00 	cmpl   $0xe5,0x8(%ebp)
8010067d:	75 0c                	jne    8010068b <cgaputc+0xbe>
     if(pos > 0)
8010067f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80100683:	7e 23                	jle    801006a8 <cgaputc+0xdb>
	++pos;
80100685:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100689:	eb 1d                	jmp    801006a8 <cgaputc+0xdb>

  }else 
  crt[pos++] = (c&0xff) | 0x0700;  // black on white
8010068b:	a1 00 90 10 80       	mov    0x80109000,%eax
80100690:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100693:	01 d2                	add    %edx,%edx
80100695:	01 c2                	add    %eax,%edx
80100697:	8b 45 08             	mov    0x8(%ebp),%eax
8010069a:	66 25 ff 00          	and    $0xff,%ax
8010069e:	80 cc 07             	or     $0x7,%ah
801006a1:	66 89 02             	mov    %ax,(%edx)
801006a4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  
  
  if((pos/80) >= 24){  // Scroll up.
801006a8:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
801006af:	7e 53                	jle    80100704 <cgaputc+0x137>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
801006b1:	a1 00 90 10 80       	mov    0x80109000,%eax
801006b6:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
801006bc:	a1 00 90 10 80       	mov    0x80109000,%eax
801006c1:	c7 44 24 08 60 0e 00 	movl   $0xe60,0x8(%esp)
801006c8:	00 
801006c9:	89 54 24 04          	mov    %edx,0x4(%esp)
801006cd:	89 04 24             	mov    %eax,(%esp)
801006d0:	e8 68 4e 00 00       	call   8010553d <memmove>
    pos -= 80;
801006d5:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
801006d9:	b8 80 07 00 00       	mov    $0x780,%eax
801006de:	2b 45 f4             	sub    -0xc(%ebp),%eax
801006e1:	01 c0                	add    %eax,%eax
801006e3:	8b 15 00 90 10 80    	mov    0x80109000,%edx
801006e9:	8b 4d f4             	mov    -0xc(%ebp),%ecx
801006ec:	01 c9                	add    %ecx,%ecx
801006ee:	01 ca                	add    %ecx,%edx
801006f0:	89 44 24 08          	mov    %eax,0x8(%esp)
801006f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801006fb:	00 
801006fc:	89 14 24             	mov    %edx,(%esp)
801006ff:	e8 66 4d 00 00       	call   8010546a <memset>
  }
  
  outb(CRTPORT, 14);
80100704:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
8010070b:	00 
8010070c:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100713:	e8 c2 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos>>8);
80100718:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010071b:	c1 f8 08             	sar    $0x8,%eax
8010071e:	0f b6 c0             	movzbl %al,%eax
80100721:	89 44 24 04          	mov    %eax,0x4(%esp)
80100725:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
8010072c:	e8 a9 fb ff ff       	call   801002da <outb>
  outb(CRTPORT, 15);
80100731:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
80100738:	00 
80100739:	c7 04 24 d4 03 00 00 	movl   $0x3d4,(%esp)
80100740:	e8 95 fb ff ff       	call   801002da <outb>
  outb(CRTPORT+1, pos);
80100745:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100748:	0f b6 c0             	movzbl %al,%eax
8010074b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010074f:	c7 04 24 d5 03 00 00 	movl   $0x3d5,(%esp)
80100756:	e8 7f fb ff ff       	call   801002da <outb>
  if(c==BACKSPACE)
8010075b:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100762:	75 11                	jne    80100775 <cgaputc+0x1a8>
      crt[pos] = ' ' | 0x0700;
80100764:	a1 00 90 10 80       	mov    0x80109000,%eax
80100769:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010076c:	01 d2                	add    %edx,%edx
8010076e:	01 d0                	add    %edx,%eax
80100770:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
80100775:	c9                   	leave  
80100776:	c3                   	ret    

80100777 <consputc>:

void
consputc(int c)
{
80100777:	55                   	push   %ebp
80100778:	89 e5                	mov    %esp,%ebp
8010077a:	83 ec 18             	sub    $0x18,%esp
  if(panicked){
8010077d:	a1 a0 b5 10 80       	mov    0x8010b5a0,%eax
80100782:	85 c0                	test   %eax,%eax
80100784:	74 07                	je     8010078d <consputc+0x16>
    cli();
80100786:	e8 6d fb ff ff       	call   801002f8 <cli>
    for(;;)
      ;
8010078b:	eb fe                	jmp    8010078b <consputc+0x14>
  }

  if(c == BACKSPACE){
8010078d:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
80100794:	75 26                	jne    801007bc <consputc+0x45>
    uartputc('\b'); uartputc(' '); uartputc('\b');
80100796:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
8010079d:	e8 8f 67 00 00       	call   80106f31 <uartputc>
801007a2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801007a9:	e8 83 67 00 00       	call   80106f31 <uartputc>
801007ae:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
801007b5:	e8 77 67 00 00       	call   80106f31 <uartputc>
801007ba:	eb 0b                	jmp    801007c7 <consputc+0x50>
  } else
    uartputc(c);
801007bc:	8b 45 08             	mov    0x8(%ebp),%eax
801007bf:	89 04 24             	mov    %eax,(%esp)
801007c2:	e8 6a 67 00 00       	call   80106f31 <uartputc>
  cgaputc(c);
801007c7:	8b 45 08             	mov    0x8(%ebp),%eax
801007ca:	89 04 24             	mov    %eax,(%esp)
801007cd:	e8 fb fd ff ff       	call   801005cd <cgaputc>
}
801007d2:	c9                   	leave  
801007d3:	c3                   	ret    

801007d4 <consoleintr>:
//-----------------PATCH--------------------//


void
consoleintr(int (*getc)(void))
{
801007d4:	55                   	push   %ebp
801007d5:	89 e5                	mov    %esp,%ebp
801007d7:	53                   	push   %ebx
801007d8:	81 ec a4 00 00 00    	sub    $0xa4,%esp
  int i,j;
  int c;
  acquire(&input.lock);
801007de:	c7 04 24 c0 e7 10 80 	movl   $0x8010e7c0,(%esp)
801007e5:	e8 31 4a 00 00       	call   8010521b <acquire>
  while((c = getc()) >= 0){
801007ea:	e9 ed 06 00 00       	jmp    80100edc <consoleintr+0x708>
    switch(c){
801007ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
801007f2:	83 f8 7f             	cmp    $0x7f,%eax
801007f5:	0f 84 bb 00 00 00    	je     801008b6 <consoleintr+0xe2>
801007fb:	83 f8 7f             	cmp    $0x7f,%eax
801007fe:	7f 18                	jg     80100818 <consoleintr+0x44>
80100800:	83 f8 10             	cmp    $0x10,%eax
80100803:	74 50                	je     80100855 <consoleintr+0x81>
80100805:	83 f8 15             	cmp    $0x15,%eax
80100808:	74 7d                	je     80100887 <consoleintr+0xb3>
8010080a:	83 f8 08             	cmp    $0x8,%eax
8010080d:	0f 84 a3 00 00 00    	je     801008b6 <consoleintr+0xe2>
80100813:	e9 3f 04 00 00       	jmp    80100c57 <consoleintr+0x483>
80100818:	3d e3 00 00 00       	cmp    $0xe3,%eax
8010081d:	0f 84 93 03 00 00    	je     80100bb6 <consoleintr+0x3e2>
80100823:	3d e3 00 00 00       	cmp    $0xe3,%eax
80100828:	7f 10                	jg     8010083a <consoleintr+0x66>
8010082a:	3d e2 00 00 00       	cmp    $0xe2,%eax
8010082f:	0f 84 75 01 00 00    	je     801009aa <consoleintr+0x1d6>
80100835:	e9 1d 04 00 00       	jmp    80100c57 <consoleintr+0x483>
8010083a:	3d e4 00 00 00       	cmp    $0xe4,%eax
8010083f:	0f 84 e1 03 00 00    	je     80100c26 <consoleintr+0x452>
80100845:	3d e5 00 00 00       	cmp    $0xe5,%eax
8010084a:	0f 84 a5 03 00 00    	je     80100bf5 <consoleintr+0x421>
80100850:	e9 02 04 00 00       	jmp    80100c57 <consoleintr+0x483>
    case C('P'):  // Process listing.
      procdump();
80100855:	e8 5f 48 00 00       	call   801050b9 <procdump>
      break;
8010085a:	e9 7d 06 00 00       	jmp    80100edc <consoleintr+0x708>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
8010085f:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100864:	83 e8 01             	sub    $0x1,%eax
80100867:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	input.rm--;
8010086c:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100871:	83 e8 01             	sub    $0x1,%eax
80100874:	a3 80 e8 10 80       	mov    %eax,0x8010e880
        consputc(BACKSPACE);
80100879:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100880:	e8 f2 fe ff ff       	call   80100777 <consputc>
80100885:	eb 01                	jmp    80100888 <consoleintr+0xb4>
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
80100887:	90                   	nop
80100888:	8b 15 7c e8 10 80    	mov    0x8010e87c,%edx
8010088e:	a1 78 e8 10 80       	mov    0x8010e878,%eax
80100893:	39 c2                	cmp    %eax,%edx
80100895:	0f 84 2e 06 00 00    	je     80100ec9 <consoleintr+0x6f5>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
8010089b:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
801008a0:	83 e8 01             	sub    $0x1,%eax
801008a3:	83 e0 7f             	and    $0x7f,%eax
801008a6:	0f b6 80 f4 e7 10 80 	movzbl -0x7fef180c(%eax),%eax
    switch(c){
    case C('P'):  // Process listing.
      procdump();
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
801008ad:	3c 0a                	cmp    $0xa,%al
801008af:	75 ae                	jne    8010085f <consoleintr+0x8b>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
	input.rm--;
        consputc(BACKSPACE);
      }
      break;
801008b1:	e9 13 06 00 00       	jmp    80100ec9 <consoleintr+0x6f5>
       //------------------- PATCH ------------------//
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
801008b6:	8b 15 7c e8 10 80    	mov    0x8010e87c,%edx
801008bc:	a1 78 e8 10 80       	mov    0x8010e878,%eax
801008c1:	39 c2                	cmp    %eax,%edx
801008c3:	0f 84 03 06 00 00    	je     80100ecc <consoleintr+0x6f8>
	consputc(BACKSPACE);
801008c9:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
801008d0:	e8 a2 fe ff ff       	call   80100777 <consputc>
	input.e--;
801008d5:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
801008da:	83 e8 01             	sub    $0x1,%eax
801008dd:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	input.rm--;
801008e2:	a1 80 e8 10 80       	mov    0x8010e880,%eax
801008e7:	83 e8 01             	sub    $0x1,%eax
801008ea:	a3 80 e8 10 80       	mov    %eax,0x8010e880
	if(input.e < input.rm){ //if cursor is not at end of sentance
801008ef:	8b 15 7c e8 10 80    	mov    0x8010e87c,%edx
801008f5:	a1 80 e8 10 80       	mov    0x8010e880,%eax
801008fa:	39 c2                	cmp    %eax,%edx
801008fc:	0f 83 ca 05 00 00    	jae    80100ecc <consoleintr+0x6f8>
	  for (i=input.e; i<=input.rm; i++){
80100902:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100907:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010090a:	eb 29                	jmp    80100935 <consoleintr+0x161>
	      input.buf[i % INPUT_BUF] = input.buf[i+1 %INPUT_BUF];
8010090c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010090f:	89 c2                	mov    %eax,%edx
80100911:	c1 fa 1f             	sar    $0x1f,%edx
80100914:	c1 ea 19             	shr    $0x19,%edx
80100917:	01 d0                	add    %edx,%eax
80100919:	83 e0 7f             	and    $0x7f,%eax
8010091c:	29 d0                	sub    %edx,%eax
8010091e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100921:	83 c2 01             	add    $0x1,%edx
80100924:	0f b6 92 f4 e7 10 80 	movzbl -0x7fef180c(%edx),%edx
8010092b:	88 90 f4 e7 10 80    	mov    %dl,-0x7fef180c(%eax)
      if(input.e != input.w){
	consputc(BACKSPACE);
	input.e--;
	input.rm--;
	if(input.e < input.rm){ //if cursor is not at end of sentance
	  for (i=input.e; i<=input.rm; i++){
80100931:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100935:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100938:	a1 80 e8 10 80       	mov    0x8010e880,%eax
8010093d:	39 c2                	cmp    %eax,%edx
8010093f:	76 cb                	jbe    8010090c <consoleintr+0x138>
	      input.buf[i % INPUT_BUF] = input.buf[i+1 %INPUT_BUF];
	  }
	  for(i = input.e; i <=input.rm; i++)
80100941:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100946:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100949:	eb 28                	jmp    80100973 <consoleintr+0x19f>
	      consputc(input.buf[i %INPUT_BUF]);
8010094b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010094e:	89 c2                	mov    %eax,%edx
80100950:	c1 fa 1f             	sar    $0x1f,%edx
80100953:	c1 ea 19             	shr    $0x19,%edx
80100956:	01 d0                	add    %edx,%eax
80100958:	83 e0 7f             	and    $0x7f,%eax
8010095b:	29 d0                	sub    %edx,%eax
8010095d:	0f b6 80 f4 e7 10 80 	movzbl -0x7fef180c(%eax),%eax
80100964:	0f be c0             	movsbl %al,%eax
80100967:	89 04 24             	mov    %eax,(%esp)
8010096a:	e8 08 fe ff ff       	call   80100777 <consputc>
	input.rm--;
	if(input.e < input.rm){ //if cursor is not at end of sentance
	  for (i=input.e; i<=input.rm; i++){
	      input.buf[i % INPUT_BUF] = input.buf[i+1 %INPUT_BUF];
	  }
	  for(i = input.e; i <=input.rm; i++)
8010096f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100973:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100976:	a1 80 e8 10 80       	mov    0x8010e880,%eax
8010097b:	39 c2                	cmp    %eax,%edx
8010097d:	76 cc                	jbe    8010094b <consoleintr+0x177>
	      consputc(input.buf[i %INPUT_BUF]);
	  
	  for(i = input.e; i <=input.rm; ++i)
8010097f:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100984:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100987:	eb 10                	jmp    80100999 <consoleintr+0x1c5>
	      consputc(LEFTARROW);
80100989:	c7 04 24 e4 00 00 00 	movl   $0xe4,(%esp)
80100990:	e8 e2 fd ff ff       	call   80100777 <consputc>
	      input.buf[i % INPUT_BUF] = input.buf[i+1 %INPUT_BUF];
	  }
	  for(i = input.e; i <=input.rm; i++)
	      consputc(input.buf[i %INPUT_BUF]);
	  
	  for(i = input.e; i <=input.rm; ++i)
80100995:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100999:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010099c:	a1 80 e8 10 80       	mov    0x8010e880,%eax
801009a1:	39 c2                	cmp    %eax,%edx
801009a3:	76 e4                	jbe    80100989 <consoleintr+0x1b5>
	      consputc(LEFTARROW);
	}
	
      }
      break;
801009a5:	e9 22 05 00 00       	jmp    80100ecc <consoleintr+0x6f8>
    case UPARROW:
	if(numOentries >=  MAX_HISTORY_LENGTH){
801009aa:	a1 08 c0 10 80       	mov    0x8010c008,%eax
801009af:	83 f8 13             	cmp    $0x13,%eax
801009b2:	0f 8e 26 01 00 00    	jle    80100ade <consoleintr+0x30a>
	  if(!((hstryPos %  MAX_HISTORY_LENGTH) ==  (hstryNext+1 %  MAX_HISTORY_LENGTH))){
801009b8:	8b 0d 04 c0 10 80    	mov    0x8010c004,%ecx
801009be:	ba 67 66 66 66       	mov    $0x66666667,%edx
801009c3:	89 c8                	mov    %ecx,%eax
801009c5:	f7 ea                	imul   %edx
801009c7:	c1 fa 03             	sar    $0x3,%edx
801009ca:	89 c8                	mov    %ecx,%eax
801009cc:	c1 f8 1f             	sar    $0x1f,%eax
801009cf:	29 c2                	sub    %eax,%edx
801009d1:	89 d0                	mov    %edx,%eax
801009d3:	c1 e0 02             	shl    $0x2,%eax
801009d6:	01 d0                	add    %edx,%eax
801009d8:	c1 e0 02             	shl    $0x2,%eax
801009db:	89 ca                	mov    %ecx,%edx
801009dd:	29 c2                	sub    %eax,%edx
801009df:	a1 00 c0 10 80       	mov    0x8010c000,%eax
801009e4:	83 c0 01             	add    $0x1,%eax
801009e7:	39 c2                	cmp    %eax,%edx
801009e9:	0f 84 e0 04 00 00    	je     80100ecf <consoleintr+0x6fb>
	      for(i=input.w ; i<input.rm; i++){
801009ef:	a1 78 e8 10 80       	mov    0x8010e878,%eax
801009f4:	89 45 f4             	mov    %eax,-0xc(%ebp)
801009f7:	eb 1d                	jmp    80100a16 <consoleintr+0x242>
	      consputc(BACKSPACE);
801009f9:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100a00:	e8 72 fd ff ff       	call   80100777 <consputc>
	      input.e--;
80100a05:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100a0a:	83 e8 01             	sub    $0x1,%eax
80100a0d:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
      }
      break;
    case UPARROW:
	if(numOentries >=  MAX_HISTORY_LENGTH){
	  if(!((hstryPos %  MAX_HISTORY_LENGTH) ==  (hstryNext+1 %  MAX_HISTORY_LENGTH))){
	      for(i=input.w ; i<input.rm; i++){
80100a12:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a16:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a19:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100a1e:	39 c2                	cmp    %eax,%edx
80100a20:	72 d7                	jb     801009f9 <consoleintr+0x225>
	      consputc(BACKSPACE);
	      input.e--;
	      }
	      
	      hstryPos--;
80100a22:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80100a27:	83 e8 01             	sub    $0x1,%eax
80100a2a:	a3 04 c0 10 80       	mov    %eax,0x8010c004
	      for(i = input.w; i<input.rm; i++){
80100a2f:	a1 78 e8 10 80       	mov    0x8010e878,%eax
80100a34:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100a37:	eb 23                	jmp    80100a5c <consoleintr+0x288>
		input.buf[i] = history[hstryPos][i];
80100a39:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80100a3e:	c1 e0 07             	shl    $0x7,%eax
80100a41:	03 45 f4             	add    -0xc(%ebp),%eax
80100a44:	05 00 b6 10 80       	add    $0x8010b600,%eax
80100a49:	0f b6 00             	movzbl (%eax),%eax
80100a4c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a4f:	81 c2 f0 e7 10 80    	add    $0x8010e7f0,%edx
80100a55:	88 42 04             	mov    %al,0x4(%edx)
	      consputc(BACKSPACE);
	      input.e--;
	      }
	      
	      hstryPos--;
	      for(i = input.w; i<input.rm; i++){
80100a58:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100a5c:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100a5f:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100a64:	39 c2                	cmp    %eax,%edx
80100a66:	72 d1                	jb     80100a39 <consoleintr+0x265>
		input.buf[i] = history[hstryPos][i];
	      }
	      cprintf("buf:%s\n",input.buf);
80100a68:	c7 44 24 04 f4 e7 10 	movl   $0x8010e7f4,0x4(%esp)
80100a6f:	80 
80100a70:	c7 04 24 17 89 10 80 	movl   $0x80108917,(%esp)
80100a77:	e8 25 f9 ff ff       	call   801003a1 <cprintf>
	      input.e += strlen(history[hstryPos]);
80100a7c:	8b 1d 7c e8 10 80    	mov    0x8010e87c,%ebx
80100a82:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80100a87:	c1 e0 07             	shl    $0x7,%eax
80100a8a:	05 00 b6 10 80       	add    $0x8010b600,%eax
80100a8f:	89 04 24             	mov    %eax,(%esp)
80100a92:	e8 51 4c 00 00       	call   801056e8 <strlen>
80100a97:	01 d8                	add    %ebx,%eax
80100a99:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	      input.rm = input.e;
80100a9e:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100aa3:	a3 80 e8 10 80       	mov    %eax,0x8010e880
	      for(i = input.w; i<input.rm; i++){
80100aa8:	a1 78 e8 10 80       	mov    0x8010e878,%eax
80100aad:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ab0:	eb 1b                	jmp    80100acd <consoleintr+0x2f9>
		  consputc(input.buf[i]);
80100ab2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ab5:	05 f0 e7 10 80       	add    $0x8010e7f0,%eax
80100aba:	0f b6 40 04          	movzbl 0x4(%eax),%eax
80100abe:	0f be c0             	movsbl %al,%eax
80100ac1:	89 04 24             	mov    %eax,(%esp)
80100ac4:	e8 ae fc ff ff       	call   80100777 <consputc>
		input.buf[i] = history[hstryPos][i];
	      }
	      cprintf("buf:%s\n",input.buf);
	      input.e += strlen(history[hstryPos]);
	      input.rm = input.e;
	      for(i = input.w; i<input.rm; i++){
80100ac9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100acd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100ad0:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100ad5:	39 c2                	cmp    %eax,%edx
80100ad7:	72 d9                	jb     80100ab2 <consoleintr+0x2de>
80100ad9:	e9 d3 00 00 00       	jmp    80100bb1 <consoleintr+0x3dd>
	      
	    
	  }
	}
	else{
	  if((hstryPos %  MAX_HISTORY_LENGTH) > 0){
80100ade:	8b 0d 04 c0 10 80    	mov    0x8010c004,%ecx
80100ae4:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100ae9:	89 c8                	mov    %ecx,%eax
80100aeb:	f7 ea                	imul   %edx
80100aed:	c1 fa 03             	sar    $0x3,%edx
80100af0:	89 c8                	mov    %ecx,%eax
80100af2:	c1 f8 1f             	sar    $0x1f,%eax
80100af5:	29 c2                	sub    %eax,%edx
80100af7:	89 d0                	mov    %edx,%eax
80100af9:	c1 e0 02             	shl    $0x2,%eax
80100afc:	01 d0                	add    %edx,%eax
80100afe:	c1 e0 02             	shl    $0x2,%eax
80100b01:	89 ca                	mov    %ecx,%edx
80100b03:	29 c2                	sub    %eax,%edx
80100b05:	85 d2                	test   %edx,%edx
80100b07:	0f 8e c2 03 00 00    	jle    80100ecf <consoleintr+0x6fb>
	      for(i=input.rm ; i>input.w; i--){
80100b0d:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100b12:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100b15:	eb 2a                	jmp    80100b41 <consoleintr+0x36d>
		  consputc(BACKSPACE);
80100b17:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
80100b1e:	e8 54 fc ff ff       	call   80100777 <consputc>
		  input.rm--;
80100b23:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100b28:	83 e8 01             	sub    $0x1,%eax
80100b2b:	a3 80 e8 10 80       	mov    %eax,0x8010e880
		  input.e--;
80100b30:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100b35:	83 e8 01             	sub    $0x1,%eax
80100b38:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	    
	  }
	}
	else{
	  if((hstryPos %  MAX_HISTORY_LENGTH) > 0){
	      for(i=input.rm ; i>input.w; i--){
80100b3d:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100b41:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100b44:	a1 78 e8 10 80       	mov    0x8010e878,%eax
80100b49:	39 c2                	cmp    %eax,%edx
80100b4b:	77 ca                	ja     80100b17 <consoleintr+0x343>
		  consputc(BACKSPACE);
		  input.rm--;
		  input.e--;
	      }	
	      hstryPos--;
80100b4d:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80100b52:	83 e8 01             	sub    $0x1,%eax
80100b55:	a3 04 c0 10 80       	mov    %eax,0x8010c004
	      for(i = input.w,j=0; j<(strlen(history[hstryPos])); i++,j++){
80100b5a:	a1 78 e8 10 80       	mov    0x8010e878,%eax
80100b5f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100b62:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80100b69:	eb 27                	jmp    80100b92 <consoleintr+0x3be>
		  input.buf[i] = history[hstryPos][j];
80100b6b:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80100b70:	c1 e0 07             	shl    $0x7,%eax
80100b73:	03 45 f0             	add    -0x10(%ebp),%eax
80100b76:	05 00 b6 10 80       	add    $0x8010b600,%eax
80100b7b:	0f b6 00             	movzbl (%eax),%eax
80100b7e:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100b81:	81 c2 f0 e7 10 80    	add    $0x8010e7f0,%edx
80100b87:	88 42 04             	mov    %al,0x4(%edx)
		  consputc(BACKSPACE);
		  input.rm--;
		  input.e--;
	      }	
	      hstryPos--;
	      for(i = input.w,j=0; j<(strlen(history[hstryPos])); i++,j++){
80100b8a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100b8e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80100b92:	a1 04 c0 10 80       	mov    0x8010c004,%eax
80100b97:	c1 e0 07             	shl    $0x7,%eax
80100b9a:	05 00 b6 10 80       	add    $0x8010b600,%eax
80100b9f:	89 04 24             	mov    %eax,(%esp)
80100ba2:	e8 41 4b 00 00       	call   801056e8 <strlen>
80100ba7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80100baa:	7f bf                	jg     80100b6b <consoleintr+0x397>
// 	      }
	      
	  }
	      
	    }
	break;
80100bac:	e9 1e 03 00 00       	jmp    80100ecf <consoleintr+0x6fb>
80100bb1:	e9 19 03 00 00       	jmp    80100ecf <consoleintr+0x6fb>
	
    case DOWNARROW:
	if(hstryPos<=hstryNext){
80100bb6:	8b 15 04 c0 10 80    	mov    0x8010c004,%edx
80100bbc:	a1 00 c0 10 80       	mov    0x8010c000,%eax
80100bc1:	39 c2                	cmp    %eax,%edx
80100bc3:	0f 8f 09 03 00 00    	jg     80100ed2 <consoleintr+0x6fe>
	    if(numOentries >  MAX_HISTORY_LENGTH){
80100bc9:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80100bce:	83 f8 14             	cmp    $0x14,%eax
80100bd1:	0f 8e fb 02 00 00    	jle    80100ed2 <consoleintr+0x6fe>
	      input.e++;
80100bd7:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100bdc:	83 c0 01             	add    $0x1,%eax
80100bdf:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	      consputc(RIGHTARROW);
80100be4:	c7 04 24 e5 00 00 00 	movl   $0xe5,(%esp)
80100beb:	e8 87 fb ff ff       	call   80100777 <consputc>
	    }
	}
	break;
80100bf0:	e9 dd 02 00 00       	jmp    80100ed2 <consoleintr+0x6fe>
      
      
    case RIGHTARROW:
	if(input.e < input.rm){
80100bf5:	8b 15 7c e8 10 80    	mov    0x8010e87c,%edx
80100bfb:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100c00:	39 c2                	cmp    %eax,%edx
80100c02:	0f 83 cd 02 00 00    	jae    80100ed5 <consoleintr+0x701>
	  input.e++;
80100c08:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100c0d:	83 c0 01             	add    $0x1,%eax
80100c10:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	  consputc(RIGHTARROW);
80100c15:	c7 04 24 e5 00 00 00 	movl   $0xe5,(%esp)
80100c1c:	e8 56 fb ff ff       	call   80100777 <consputc>
	}
	break;
80100c21:	e9 af 02 00 00       	jmp    80100ed5 <consoleintr+0x701>
    case LEFTARROW:
	if(input.e != input.w){
80100c26:	8b 15 7c e8 10 80    	mov    0x8010e87c,%edx
80100c2c:	a1 78 e8 10 80       	mov    0x8010e878,%eax
80100c31:	39 c2                	cmp    %eax,%edx
80100c33:	0f 84 9f 02 00 00    	je     80100ed8 <consoleintr+0x704>
	  input.e--;
80100c39:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100c3e:	83 e8 01             	sub    $0x1,%eax
80100c41:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	  consputc(LEFTARROW);
80100c46:	c7 04 24 e4 00 00 00 	movl   $0xe4,(%esp)
80100c4d:	e8 25 fb ff ff       	call   80100777 <consputc>
	}
	break;
80100c52:	e9 81 02 00 00       	jmp    80100ed8 <consoleintr+0x704>
    //------------------- PATCH ------------------//
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100c57:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80100c5b:	0f 84 7a 02 00 00    	je     80100edb <consoleintr+0x707>
80100c61:	8b 15 7c e8 10 80    	mov    0x8010e87c,%edx
80100c67:	a1 74 e8 10 80       	mov    0x8010e874,%eax
80100c6c:	89 d1                	mov    %edx,%ecx
80100c6e:	29 c1                	sub    %eax,%ecx
80100c70:	89 c8                	mov    %ecx,%eax
80100c72:	83 f8 7f             	cmp    $0x7f,%eax
80100c75:	0f 87 60 02 00 00    	ja     80100edb <consoleintr+0x707>
        c = (c == '\r') ? '\n' : c;
80100c7b:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
80100c7f:	74 05                	je     80100c86 <consoleintr+0x4b2>
80100c81:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100c84:	eb 05                	jmp    80100c8b <consoleintr+0x4b7>
80100c86:	b8 0a 00 00 00       	mov    $0xa,%eax
80100c8b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	if((c == '\n')&&(input.e<input.rm)){ // case of enter in mid of sentance
80100c8e:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
80100c92:	75 44                	jne    80100cd8 <consoleintr+0x504>
80100c94:	8b 15 7c e8 10 80    	mov    0x8010e87c,%edx
80100c9a:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100c9f:	39 c2                	cmp    %eax,%edx
80100ca1:	73 35                	jae    80100cd8 <consoleintr+0x504>
	  
	  input.e = input.rm;
80100ca3:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100ca8:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	  input.buf[input.e++ % INPUT_BUF] = c;
80100cad:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100cb2:	89 c1                	mov    %eax,%ecx
80100cb4:	83 e1 7f             	and    $0x7f,%ecx
80100cb7:	8b 55 ec             	mov    -0x14(%ebp),%edx
80100cba:	88 91 f4 e7 10 80    	mov    %dl,-0x7fef180c(%ecx)
80100cc0:	83 c0 01             	add    $0x1,%eax
80100cc3:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	  consputc(c);
80100cc8:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100ccb:	89 04 24             	mov    %eax,(%esp)
80100cce:	e8 a4 fa ff ff       	call   80100777 <consputc>
80100cd3:	e9 c9 00 00 00       	jmp    80100da1 <consoleintr+0x5cd>
	  //cprintf("buf enter after left:%s\n",input.buf);
	}else{
	 for (i=input.rm; i>input.e; i--){ //put letter in middle of sentance
80100cd8:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100cdd:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ce0:	eb 29                	jmp    80100d0b <consoleintr+0x537>
 	    input.buf[i % INPUT_BUF] = input.buf[i-1 %INPUT_BUF];
80100ce2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ce5:	89 c2                	mov    %eax,%edx
80100ce7:	c1 fa 1f             	sar    $0x1f,%edx
80100cea:	c1 ea 19             	shr    $0x19,%edx
80100ced:	01 d0                	add    %edx,%eax
80100cef:	83 e0 7f             	and    $0x7f,%eax
80100cf2:	29 d0                	sub    %edx,%eax
80100cf4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100cf7:	83 ea 01             	sub    $0x1,%edx
80100cfa:	0f b6 92 f4 e7 10 80 	movzbl -0x7fef180c(%edx),%edx
80100d01:	88 90 f4 e7 10 80    	mov    %dl,-0x7fef180c(%eax)
	  input.e = input.rm;
	  input.buf[input.e++ % INPUT_BUF] = c;
	  consputc(c);
	  //cprintf("buf enter after left:%s\n",input.buf);
	}else{
	 for (i=input.rm; i>input.e; i--){ //put letter in middle of sentance
80100d07:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
80100d0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100d0e:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100d13:	39 c2                	cmp    %eax,%edx
80100d15:	77 cb                	ja     80100ce2 <consoleintr+0x50e>
 	    input.buf[i % INPUT_BUF] = input.buf[i-1 %INPUT_BUF];
	 }
	  input.buf[input.e++ % INPUT_BUF] = c;
80100d17:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100d1c:	89 c1                	mov    %eax,%ecx
80100d1e:	83 e1 7f             	and    $0x7f,%ecx
80100d21:	8b 55 ec             	mov    -0x14(%ebp),%edx
80100d24:	88 91 f4 e7 10 80    	mov    %dl,-0x7fef180c(%ecx)
80100d2a:	83 c0 01             	add    $0x1,%eax
80100d2d:	a3 7c e8 10 80       	mov    %eax,0x8010e87c
	  consputc(c);
80100d32:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100d35:	89 04 24             	mov    %eax,(%esp)
80100d38:	e8 3a fa ff ff       	call   80100777 <consputc>

	  for(i = input.e; i <= input.rm; ++i)
80100d3d:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100d42:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100d45:	eb 1b                	jmp    80100d62 <consoleintr+0x58e>
	    consputc(input.buf[i]);
80100d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100d4a:	05 f0 e7 10 80       	add    $0x8010e7f0,%eax
80100d4f:	0f b6 40 04          	movzbl 0x4(%eax),%eax
80100d53:	0f be c0             	movsbl %al,%eax
80100d56:	89 04 24             	mov    %eax,(%esp)
80100d59:	e8 19 fa ff ff       	call   80100777 <consputc>
 	    input.buf[i % INPUT_BUF] = input.buf[i-1 %INPUT_BUF];
	 }
	  input.buf[input.e++ % INPUT_BUF] = c;
	  consputc(c);

	  for(i = input.e; i <= input.rm; ++i)
80100d5e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100d62:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100d65:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100d6a:	39 c2                	cmp    %eax,%edx
80100d6c:	76 d9                	jbe    80100d47 <consoleintr+0x573>
	    consputc(input.buf[i]);
	  input.rm++;
80100d6e:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100d73:	83 c0 01             	add    $0x1,%eax
80100d76:	a3 80 e8 10 80       	mov    %eax,0x8010e880
	  for(i = input.e; i < input.rm; ++i)
80100d7b:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100d80:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100d83:	eb 10                	jmp    80100d95 <consoleintr+0x5c1>
	    consputc(LEFTARROW);
80100d85:	c7 04 24 e4 00 00 00 	movl   $0xe4,(%esp)
80100d8c:	e8 e6 f9 ff ff       	call   80100777 <consputc>
	  consputc(c);

	  for(i = input.e; i <= input.rm; ++i)
	    consputc(input.buf[i]);
	  input.rm++;
	  for(i = input.e; i < input.rm; ++i)
80100d91:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100d95:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100d98:	a1 80 e8 10 80       	mov    0x8010e880,%eax
80100d9d:	39 c2                	cmp    %eax,%edx
80100d9f:	72 e4                	jb     80100d85 <consoleintr+0x5b1>
	    consputc(LEFTARROW);
	}

        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
80100da1:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
80100da5:	74 1c                	je     80100dc3 <consoleintr+0x5ef>
80100da7:	83 7d ec 04          	cmpl   $0x4,-0x14(%ebp)
80100dab:	74 16                	je     80100dc3 <consoleintr+0x5ef>
80100dad:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100db2:	8b 15 74 e8 10 80    	mov    0x8010e874,%edx
80100db8:	83 ea 80             	sub    $0xffffff80,%edx
80100dbb:	39 d0                	cmp    %edx,%eax
80100dbd:	0f 85 18 01 00 00    	jne    80100edb <consoleintr+0x707>
	  //cprintf("buf:%s\n",input.buf);
          input.w = input.e;
80100dc3:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100dc8:	a3 78 e8 10 80       	mov    %eax,0x8010e878
	  input.rm = input.e;
80100dcd:	a1 7c e8 10 80       	mov    0x8010e87c,%eax
80100dd2:	a3 80 e8 10 80       	mov    %eax,0x8010e880
	  
	  //
	  j =0;
80100dd7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	  char command[INPUT_BUF];
	  memset(&command[0], 0, sizeof(command));
80100dde:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80100de5:	00 
80100de6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80100ded:	00 
80100dee:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80100df4:	89 04 24             	mov    %eax,(%esp)
80100df7:	e8 6e 46 00 00       	call   8010546a <memset>
	  for (i=input.r; i < input.rm-1; i++) {
80100dfc:	a1 74 e8 10 80       	mov    0x8010e874,%eax
80100e01:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100e04:	eb 2c                	jmp    80100e32 <consoleintr+0x65e>
	    command[j] = input.buf[i %INPUT_BUF];
80100e06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e09:	89 c2                	mov    %eax,%edx
80100e0b:	c1 fa 1f             	sar    $0x1f,%edx
80100e0e:	c1 ea 19             	shr    $0x19,%edx
80100e11:	01 d0                	add    %edx,%eax
80100e13:	83 e0 7f             	and    $0x7f,%eax
80100e16:	29 d0                	sub    %edx,%eax
80100e18:	0f b6 90 f4 e7 10 80 	movzbl -0x7fef180c(%eax),%edx
80100e1f:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80100e25:	03 45 f0             	add    -0x10(%ebp),%eax
80100e28:	88 10                	mov    %dl,(%eax)
	    j++;
80100e2a:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	  
	  //
	  j =0;
	  char command[INPUT_BUF];
	  memset(&command[0], 0, sizeof(command));
	  for (i=input.r; i < input.rm-1; i++) {
80100e2e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100e35:	8b 15 80 e8 10 80    	mov    0x8010e880,%edx
80100e3b:	83 ea 01             	sub    $0x1,%edx
80100e3e:	39 d0                	cmp    %edx,%eax
80100e40:	72 c4                	jb     80100e06 <consoleintr+0x632>
	    j++;
	    //cprintf("buf:%s\n",input.buf);
	  }
//  	  cprintf("command is:%s",command);
	  //command[j-1] = '\n'; 
	  strncpy(history[hstryNext],command,strlen(command));
80100e42:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80100e48:	89 04 24             	mov    %eax,(%esp)
80100e4b:	e8 98 48 00 00       	call   801056e8 <strlen>
80100e50:	8b 15 00 c0 10 80    	mov    0x8010c000,%edx
80100e56:	c1 e2 07             	shl    $0x7,%edx
80100e59:	81 c2 00 b6 10 80    	add    $0x8010b600,%edx
80100e5f:	89 44 24 08          	mov    %eax,0x8(%esp)
80100e63:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80100e69:	89 44 24 04          	mov    %eax,0x4(%esp)
80100e6d:	89 14 24             	mov    %edx,(%esp)
80100e70:	e8 c4 47 00 00       	call   80105639 <strncpy>
	  hstryNext = ((hstryNext+1) %  MAX_HISTORY_LENGTH);
80100e75:	a1 00 c0 10 80       	mov    0x8010c000,%eax
80100e7a:	8d 48 01             	lea    0x1(%eax),%ecx
80100e7d:	ba 67 66 66 66       	mov    $0x66666667,%edx
80100e82:	89 c8                	mov    %ecx,%eax
80100e84:	f7 ea                	imul   %edx
80100e86:	c1 fa 03             	sar    $0x3,%edx
80100e89:	89 c8                	mov    %ecx,%eax
80100e8b:	c1 f8 1f             	sar    $0x1f,%eax
80100e8e:	29 c2                	sub    %eax,%edx
80100e90:	89 d0                	mov    %edx,%eax
80100e92:	c1 e0 02             	shl    $0x2,%eax
80100e95:	01 d0                	add    %edx,%eax
80100e97:	c1 e0 02             	shl    $0x2,%eax
80100e9a:	89 ca                	mov    %ecx,%edx
80100e9c:	29 c2                	sub    %eax,%edx
80100e9e:	89 15 00 c0 10 80    	mov    %edx,0x8010c000
	  hstryPos = hstryNext;
80100ea4:	a1 00 c0 10 80       	mov    0x8010c000,%eax
80100ea9:	a3 04 c0 10 80       	mov    %eax,0x8010c004
	  numOentries++;
80100eae:	a1 08 c0 10 80       	mov    0x8010c008,%eax
80100eb3:	83 c0 01             	add    $0x1,%eax
80100eb6:	a3 08 c0 10 80       	mov    %eax,0x8010c008
	  //cprintf("next:%d\n",hstryNext);
// 	  for (i=0; i < hstryNext; i++) {
// 	      cprintf("history:%s\n",history[i]);
// 	  }

          wakeup(&input.r);
80100ebb:	c7 04 24 74 e8 10 80 	movl   $0x8010e874,(%esp)
80100ec2:	e8 4f 41 00 00       	call   80105016 <wakeup>
        }
      }
      break;
80100ec7:	eb 12                	jmp    80100edb <consoleintr+0x707>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
	input.rm--;
        consputc(BACKSPACE);
      }
      break;
80100ec9:	90                   	nop
80100eca:	eb 10                	jmp    80100edc <consoleintr+0x708>
	  for(i = input.e; i <=input.rm; ++i)
	      consputc(LEFTARROW);
	}
	
      }
      break;
80100ecc:	90                   	nop
80100ecd:	eb 0d                	jmp    80100edc <consoleintr+0x708>
// 	      }
	      
	  }
	      
	    }
	break;
80100ecf:	90                   	nop
80100ed0:	eb 0a                	jmp    80100edc <consoleintr+0x708>
	    if(numOentries >  MAX_HISTORY_LENGTH){
	      input.e++;
	      consputc(RIGHTARROW);
	    }
	}
	break;
80100ed2:	90                   	nop
80100ed3:	eb 07                	jmp    80100edc <consoleintr+0x708>
    case RIGHTARROW:
	if(input.e < input.rm){
	  input.e++;
	  consputc(RIGHTARROW);
	}
	break;
80100ed5:	90                   	nop
80100ed6:	eb 04                	jmp    80100edc <consoleintr+0x708>
    case LEFTARROW:
	if(input.e != input.w){
	  input.e--;
	  consputc(LEFTARROW);
	}
	break;
80100ed8:	90                   	nop
80100ed9:	eb 01                	jmp    80100edc <consoleintr+0x708>
// 	  }

          wakeup(&input.r);
        }
      }
      break;
80100edb:	90                   	nop
consoleintr(int (*getc)(void))
{
  int i,j;
  int c;
  acquire(&input.lock);
  while((c = getc()) >= 0){
80100edc:	8b 45 08             	mov    0x8(%ebp),%eax
80100edf:	ff d0                	call   *%eax
80100ee1:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100ee4:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80100ee8:	0f 89 01 f9 ff ff    	jns    801007ef <consoleintr+0x1b>
        }
      }
      break;
    }
  }
  release(&input.lock);
80100eee:	c7 04 24 c0 e7 10 80 	movl   $0x8010e7c0,(%esp)
80100ef5:	e8 83 43 00 00       	call   8010527d <release>
}
80100efa:	81 c4 a4 00 00 00    	add    $0xa4,%esp
80100f00:	5b                   	pop    %ebx
80100f01:	5d                   	pop    %ebp
80100f02:	c3                   	ret    

80100f03 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
80100f03:	55                   	push   %ebp
80100f04:	89 e5                	mov    %esp,%ebp
80100f06:	83 ec 28             	sub    $0x28,%esp
  uint target;
  int c;

  iunlock(ip);
80100f09:	8b 45 08             	mov    0x8(%ebp),%eax
80100f0c:	89 04 24             	mov    %eax,(%esp)
80100f0f:	e8 1a 11 00 00       	call   8010202e <iunlock>
  target = n;
80100f14:	8b 45 10             	mov    0x10(%ebp),%eax
80100f17:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&input.lock);
80100f1a:	c7 04 24 c0 e7 10 80 	movl   $0x8010e7c0,(%esp)
80100f21:	e8 f5 42 00 00       	call   8010521b <acquire>
  while(n > 0){
80100f26:	e9 a8 00 00 00       	jmp    80100fd3 <consoleread+0xd0>
    while(input.r == input.w){
      if(proc->killed){
80100f2b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80100f31:	8b 40 24             	mov    0x24(%eax),%eax
80100f34:	85 c0                	test   %eax,%eax
80100f36:	74 21                	je     80100f59 <consoleread+0x56>
        release(&input.lock);
80100f38:	c7 04 24 c0 e7 10 80 	movl   $0x8010e7c0,(%esp)
80100f3f:	e8 39 43 00 00       	call   8010527d <release>
        ilock(ip);
80100f44:	8b 45 08             	mov    0x8(%ebp),%eax
80100f47:	89 04 24             	mov    %eax,(%esp)
80100f4a:	e8 91 0f 00 00       	call   80101ee0 <ilock>
        return -1;
80100f4f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100f54:	e9 a9 00 00 00       	jmp    80101002 <consoleread+0xff>
      }
      sleep(&input.r, &input.lock);
80100f59:	c7 44 24 04 c0 e7 10 	movl   $0x8010e7c0,0x4(%esp)
80100f60:	80 
80100f61:	c7 04 24 74 e8 10 80 	movl   $0x8010e874,(%esp)
80100f68:	e8 d0 3f 00 00       	call   80104f3d <sleep>
80100f6d:	eb 01                	jmp    80100f70 <consoleread+0x6d>

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
    while(input.r == input.w){
80100f6f:	90                   	nop
80100f70:	8b 15 74 e8 10 80    	mov    0x8010e874,%edx
80100f76:	a1 78 e8 10 80       	mov    0x8010e878,%eax
80100f7b:	39 c2                	cmp    %eax,%edx
80100f7d:	74 ac                	je     80100f2b <consoleread+0x28>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &input.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100f7f:	a1 74 e8 10 80       	mov    0x8010e874,%eax
80100f84:	89 c2                	mov    %eax,%edx
80100f86:	83 e2 7f             	and    $0x7f,%edx
80100f89:	0f b6 92 f4 e7 10 80 	movzbl -0x7fef180c(%edx),%edx
80100f90:	0f be d2             	movsbl %dl,%edx
80100f93:	89 55 f0             	mov    %edx,-0x10(%ebp)
80100f96:	83 c0 01             	add    $0x1,%eax
80100f99:	a3 74 e8 10 80       	mov    %eax,0x8010e874
    if(c == C('D')){  // EOF
80100f9e:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100fa2:	75 17                	jne    80100fbb <consoleread+0xb8>
      if(n < target){
80100fa4:	8b 45 10             	mov    0x10(%ebp),%eax
80100fa7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80100faa:	73 2f                	jae    80100fdb <consoleread+0xd8>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100fac:	a1 74 e8 10 80       	mov    0x8010e874,%eax
80100fb1:	83 e8 01             	sub    $0x1,%eax
80100fb4:	a3 74 e8 10 80       	mov    %eax,0x8010e874
      }
      break;
80100fb9:	eb 20                	jmp    80100fdb <consoleread+0xd8>
    }
    *dst++ = c;
80100fbb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100fbe:	89 c2                	mov    %eax,%edx
80100fc0:	8b 45 0c             	mov    0xc(%ebp),%eax
80100fc3:	88 10                	mov    %dl,(%eax)
80100fc5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
    --n;
80100fc9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100fcd:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100fd1:	74 0b                	je     80100fde <consoleread+0xdb>
  int c;

  iunlock(ip);
  target = n;
  acquire(&input.lock);
  while(n > 0){
80100fd3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100fd7:	7f 96                	jg     80100f6f <consoleread+0x6c>
80100fd9:	eb 04                	jmp    80100fdf <consoleread+0xdc>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
80100fdb:	90                   	nop
80100fdc:	eb 01                	jmp    80100fdf <consoleread+0xdc>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100fde:	90                   	nop
  }
  release(&input.lock);
80100fdf:	c7 04 24 c0 e7 10 80 	movl   $0x8010e7c0,(%esp)
80100fe6:	e8 92 42 00 00       	call   8010527d <release>
  ilock(ip);
80100feb:	8b 45 08             	mov    0x8(%ebp),%eax
80100fee:	89 04 24             	mov    %eax,(%esp)
80100ff1:	e8 ea 0e 00 00       	call   80101ee0 <ilock>

  return target - n;
80100ff6:	8b 45 10             	mov    0x10(%ebp),%eax
80100ff9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100ffc:	89 d1                	mov    %edx,%ecx
80100ffe:	29 c1                	sub    %eax,%ecx
80101000:	89 c8                	mov    %ecx,%eax
}
80101002:	c9                   	leave  
80101003:	c3                   	ret    

80101004 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80101004:	55                   	push   %ebp
80101005:	89 e5                	mov    %esp,%ebp
80101007:	83 ec 28             	sub    $0x28,%esp
  int i;

  iunlock(ip);
8010100a:	8b 45 08             	mov    0x8(%ebp),%eax
8010100d:	89 04 24             	mov    %eax,(%esp)
80101010:	e8 19 10 00 00       	call   8010202e <iunlock>
  acquire(&cons.lock);
80101015:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
8010101c:	e8 fa 41 00 00       	call   8010521b <acquire>
  for(i = 0; i < n; i++)
80101021:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101028:	eb 1d                	jmp    80101047 <consolewrite+0x43>
    consputc(buf[i] & 0xff);
8010102a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010102d:	03 45 0c             	add    0xc(%ebp),%eax
80101030:	0f b6 00             	movzbl (%eax),%eax
80101033:	0f be c0             	movsbl %al,%eax
80101036:	25 ff 00 00 00       	and    $0xff,%eax
8010103b:	89 04 24             	mov    %eax,(%esp)
8010103e:	e8 34 f7 ff ff       	call   80100777 <consputc>
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80101043:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101047:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010104a:	3b 45 10             	cmp    0x10(%ebp),%eax
8010104d:	7c db                	jl     8010102a <consolewrite+0x26>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
8010104f:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80101056:	e8 22 42 00 00       	call   8010527d <release>
  ilock(ip);
8010105b:	8b 45 08             	mov    0x8(%ebp),%eax
8010105e:	89 04 24             	mov    %eax,(%esp)
80101061:	e8 7a 0e 00 00       	call   80101ee0 <ilock>

  return n;
80101066:	8b 45 10             	mov    0x10(%ebp),%eax
}
80101069:	c9                   	leave  
8010106a:	c3                   	ret    

8010106b <consoleinit>:

void
consoleinit(void)
{
8010106b:	55                   	push   %ebp
8010106c:	89 e5                	mov    %esp,%ebp
8010106e:	83 ec 18             	sub    $0x18,%esp
  initlock(&cons.lock, "console");
80101071:	c7 44 24 04 1f 89 10 	movl   $0x8010891f,0x4(%esp)
80101078:	80 
80101079:	c7 04 24 c0 b5 10 80 	movl   $0x8010b5c0,(%esp)
80101080:	e8 75 41 00 00       	call   801051fa <initlock>
  initlock(&input.lock, "input");
80101085:	c7 44 24 04 27 89 10 	movl   $0x80108927,0x4(%esp)
8010108c:	80 
8010108d:	c7 04 24 c0 e7 10 80 	movl   $0x8010e7c0,(%esp)
80101094:	e8 61 41 00 00       	call   801051fa <initlock>

  devsw[CONSOLE].write = consolewrite;
80101099:	c7 05 6c f7 10 80 04 	movl   $0x80101004,0x8010f76c
801010a0:	10 10 80 
  devsw[CONSOLE].read = consoleread;
801010a3:	c7 05 68 f7 10 80 03 	movl   $0x80100f03,0x8010f768
801010aa:	0f 10 80 
  cons.locking = 1;
801010ad:	c7 05 f4 b5 10 80 01 	movl   $0x1,0x8010b5f4
801010b4:	00 00 00 

  picenable(IRQ_KBD);
801010b7:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801010be:	e8 76 30 00 00       	call   80104139 <picenable>
  ioapicenable(IRQ_KBD, 0);
801010c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801010ca:	00 
801010cb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801010d2:	e8 17 1f 00 00       	call   80102fee <ioapicenable>
}
801010d7:	c9                   	leave  
801010d8:	c3                   	ret    
801010d9:	00 00                	add    %al,(%eax)
	...

801010dc <exec>:
//----------------------- PATCH -------------------//


int
exec(char *path, char **argv)
{
801010dc:	55                   	push   %ebp
801010dd:	89 e5                	mov    %esp,%ebp
801010df:	81 ec 38 02 00 00    	sub    $0x238,%esp
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;

  
  //----------------------- PATCH -------------------//
  if((ip = namei(path)) == 0){
801010e5:	8b 45 08             	mov    0x8(%ebp),%eax
801010e8:	89 04 24             	mov    %eax,(%esp)
801010eb:	e8 92 19 00 00       	call   80102a82 <namei>
801010f0:	89 45 d8             	mov    %eax,-0x28(%ebp)
801010f3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
801010f7:	0f 85 9c 00 00 00    	jne    80101199 <exec+0xbd>
      for(i = 0; i<lastPath; i++){
801010fd:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101104:	eb 7b                	jmp    80101181 <exec+0xa5>
	  strncpy(newPath, PATH[i], 128);
80101106:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101109:	c1 e0 07             	shl    $0x7,%eax
8010110c:	05 c0 e8 10 80       	add    $0x8010e8c0,%eax
80101111:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80101118:	00 
80101119:	89 44 24 04          	mov    %eax,0x4(%esp)
8010111d:	8d 85 d0 fe ff ff    	lea    -0x130(%ebp),%eax
80101123:	89 04 24             	mov    %eax,(%esp)
80101126:	e8 0e 45 00 00       	call   80105639 <strncpy>
	  strncpy(newPath + strlen(newPath), path, 128);
8010112b:	8d 85 d0 fe ff ff    	lea    -0x130(%ebp),%eax
80101131:	89 04 24             	mov    %eax,(%esp)
80101134:	e8 af 45 00 00       	call   801056e8 <strlen>
80101139:	8d 95 d0 fe ff ff    	lea    -0x130(%ebp),%edx
8010113f:	01 c2                	add    %eax,%edx
80101141:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80101148:	00 
80101149:	8b 45 08             	mov    0x8(%ebp),%eax
8010114c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101150:	89 14 24             	mov    %edx,(%esp)
80101153:	e8 e1 44 00 00       	call   80105639 <strncpy>
 	  if ((ip = namei(newPath)) != 0){
80101158:	8d 85 d0 fe ff ff    	lea    -0x130(%ebp),%eax
8010115e:	89 04 24             	mov    %eax,(%esp)
80101161:	e8 1c 19 00 00       	call   80102a82 <namei>
80101166:	89 45 d8             	mov    %eax,-0x28(%ebp)
80101169:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
8010116d:	74 0e                	je     8010117d <exec+0xa1>
	      cprintf("found it!!\n");
8010116f:	c7 04 24 2d 89 10 80 	movl   $0x8010892d,(%esp)
80101176:	e8 26 f2 ff ff       	call   801003a1 <cprintf>
	      goto cont;
8010117b:	eb 1c                	jmp    80101199 <exec+0xbd>
  pde_t *pgdir, *oldpgdir;

  
  //----------------------- PATCH -------------------//
  if((ip = namei(path)) == 0){
      for(i = 0; i<lastPath; i++){
8010117d:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80101181:	a1 a0 e8 10 80       	mov    0x8010e8a0,%eax
80101186:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80101189:	0f 8c 77 ff ff ff    	jl     80101106 <exec+0x2a>
 	  if ((ip = namei(newPath)) != 0){
	      cprintf("found it!!\n");
	      goto cont;
	  }
      }
      return -1;
8010118f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101194:	e9 da 03 00 00       	jmp    80101573 <exec+0x497>
  }
  cont:
  //cprintf("%d\n", ip);
//----------------------- PATCH -------------------//
  ilock(ip);
80101199:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010119c:	89 04 24             	mov    %eax,(%esp)
8010119f:	e8 3c 0d 00 00       	call   80101ee0 <ilock>
  pgdir = 0;
801011a4:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
801011ab:	c7 44 24 0c 34 00 00 	movl   $0x34,0xc(%esp)
801011b2:	00 
801011b3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801011ba:	00 
801011bb:	8d 85 0c fe ff ff    	lea    -0x1f4(%ebp),%eax
801011c1:	89 44 24 04          	mov    %eax,0x4(%esp)
801011c5:	8b 45 d8             	mov    -0x28(%ebp),%eax
801011c8:	89 04 24             	mov    %eax,(%esp)
801011cb:	e8 06 12 00 00       	call   801023d6 <readi>
801011d0:	83 f8 33             	cmp    $0x33,%eax
801011d3:	0f 86 54 03 00 00    	jbe    8010152d <exec+0x451>
    goto bad;
  if(elf.magic != ELF_MAGIC)
801011d9:	8b 85 0c fe ff ff    	mov    -0x1f4(%ebp),%eax
801011df:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
801011e4:	0f 85 46 03 00 00    	jne    80101530 <exec+0x454>
    goto bad;

  if((pgdir = setupkvm(kalloc)) == 0)
801011ea:	c7 04 24 77 31 10 80 	movl   $0x80103177,(%esp)
801011f1:	e8 7f 6e 00 00       	call   80108075 <setupkvm>
801011f6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
801011f9:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
801011fd:	0f 84 30 03 00 00    	je     80101533 <exec+0x457>
    goto bad;

  // Load program into memory.
  sz = 0;
80101203:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
8010120a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80101211:	8b 85 28 fe ff ff    	mov    -0x1d8(%ebp),%eax
80101217:	89 45 e8             	mov    %eax,-0x18(%ebp)
8010121a:	e9 c5 00 00 00       	jmp    801012e4 <exec+0x208>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
8010121f:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101222:	c7 44 24 0c 20 00 00 	movl   $0x20,0xc(%esp)
80101229:	00 
8010122a:	89 44 24 08          	mov    %eax,0x8(%esp)
8010122e:	8d 85 ec fd ff ff    	lea    -0x214(%ebp),%eax
80101234:	89 44 24 04          	mov    %eax,0x4(%esp)
80101238:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010123b:	89 04 24             	mov    %eax,(%esp)
8010123e:	e8 93 11 00 00       	call   801023d6 <readi>
80101243:	83 f8 20             	cmp    $0x20,%eax
80101246:	0f 85 ea 02 00 00    	jne    80101536 <exec+0x45a>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
8010124c:	8b 85 ec fd ff ff    	mov    -0x214(%ebp),%eax
80101252:	83 f8 01             	cmp    $0x1,%eax
80101255:	75 7f                	jne    801012d6 <exec+0x1fa>
      continue;
    if(ph.memsz < ph.filesz)
80101257:	8b 95 00 fe ff ff    	mov    -0x200(%ebp),%edx
8010125d:	8b 85 fc fd ff ff    	mov    -0x204(%ebp),%eax
80101263:	39 c2                	cmp    %eax,%edx
80101265:	0f 82 ce 02 00 00    	jb     80101539 <exec+0x45d>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
8010126b:	8b 95 f4 fd ff ff    	mov    -0x20c(%ebp),%edx
80101271:	8b 85 00 fe ff ff    	mov    -0x200(%ebp),%eax
80101277:	01 d0                	add    %edx,%eax
80101279:	89 44 24 08          	mov    %eax,0x8(%esp)
8010127d:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101280:	89 44 24 04          	mov    %eax,0x4(%esp)
80101284:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101287:	89 04 24             	mov    %eax,(%esp)
8010128a:	e8 b8 71 00 00       	call   80108447 <allocuvm>
8010128f:	89 45 e0             	mov    %eax,-0x20(%ebp)
80101292:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80101296:	0f 84 a0 02 00 00    	je     8010153c <exec+0x460>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
8010129c:	8b 8d fc fd ff ff    	mov    -0x204(%ebp),%ecx
801012a2:	8b 95 f0 fd ff ff    	mov    -0x210(%ebp),%edx
801012a8:	8b 85 f4 fd ff ff    	mov    -0x20c(%ebp),%eax
801012ae:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801012b2:	89 54 24 0c          	mov    %edx,0xc(%esp)
801012b6:	8b 55 d8             	mov    -0x28(%ebp),%edx
801012b9:	89 54 24 08          	mov    %edx,0x8(%esp)
801012bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801012c1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801012c4:	89 04 24             	mov    %eax,(%esp)
801012c7:	e8 8c 70 00 00       	call   80108358 <loaduvm>
801012cc:	85 c0                	test   %eax,%eax
801012ce:	0f 88 6b 02 00 00    	js     8010153f <exec+0x463>
801012d4:	eb 01                	jmp    801012d7 <exec+0x1fb>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
801012d6:	90                   	nop
  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
801012d7:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
801012db:	8b 45 e8             	mov    -0x18(%ebp),%eax
801012de:	83 c0 20             	add    $0x20,%eax
801012e1:	89 45 e8             	mov    %eax,-0x18(%ebp)
801012e4:	0f b7 85 38 fe ff ff 	movzwl -0x1c8(%ebp),%eax
801012eb:	0f b7 c0             	movzwl %ax,%eax
801012ee:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801012f1:	0f 8f 28 ff ff ff    	jg     8010121f <exec+0x143>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
801012f7:	8b 45 d8             	mov    -0x28(%ebp),%eax
801012fa:	89 04 24             	mov    %eax,(%esp)
801012fd:	e8 62 0e 00 00       	call   80102164 <iunlockput>
  ip = 0;
80101302:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80101309:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010130c:	05 ff 0f 00 00       	add    $0xfff,%eax
80101311:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80101316:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80101319:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010131c:	05 00 20 00 00       	add    $0x2000,%eax
80101321:	89 44 24 08          	mov    %eax,0x8(%esp)
80101325:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101328:	89 44 24 04          	mov    %eax,0x4(%esp)
8010132c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010132f:	89 04 24             	mov    %eax,(%esp)
80101332:	e8 10 71 00 00       	call   80108447 <allocuvm>
80101337:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010133a:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010133e:	0f 84 fe 01 00 00    	je     80101542 <exec+0x466>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80101344:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101347:	2d 00 20 00 00       	sub    $0x2000,%eax
8010134c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101350:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101353:	89 04 24             	mov    %eax,(%esp)
80101356:	e8 10 73 00 00       	call   8010866b <clearpteu>
  sp = sz;
8010135b:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010135e:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80101361:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80101368:	e9 81 00 00 00       	jmp    801013ee <exec+0x312>
    if(argc >= MAXARG)
8010136d:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80101371:	0f 87 ce 01 00 00    	ja     80101545 <exec+0x469>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80101377:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010137a:	c1 e0 02             	shl    $0x2,%eax
8010137d:	03 45 0c             	add    0xc(%ebp),%eax
80101380:	8b 00                	mov    (%eax),%eax
80101382:	89 04 24             	mov    %eax,(%esp)
80101385:	e8 5e 43 00 00       	call   801056e8 <strlen>
8010138a:	f7 d0                	not    %eax
8010138c:	03 45 dc             	add    -0x24(%ebp),%eax
8010138f:	83 e0 fc             	and    $0xfffffffc,%eax
80101392:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80101395:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101398:	c1 e0 02             	shl    $0x2,%eax
8010139b:	03 45 0c             	add    0xc(%ebp),%eax
8010139e:	8b 00                	mov    (%eax),%eax
801013a0:	89 04 24             	mov    %eax,(%esp)
801013a3:	e8 40 43 00 00       	call   801056e8 <strlen>
801013a8:	83 c0 01             	add    $0x1,%eax
801013ab:	89 c2                	mov    %eax,%edx
801013ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013b0:	c1 e0 02             	shl    $0x2,%eax
801013b3:	03 45 0c             	add    0xc(%ebp),%eax
801013b6:	8b 00                	mov    (%eax),%eax
801013b8:	89 54 24 0c          	mov    %edx,0xc(%esp)
801013bc:	89 44 24 08          	mov    %eax,0x8(%esp)
801013c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801013c3:	89 44 24 04          	mov    %eax,0x4(%esp)
801013c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
801013ca:	89 04 24             	mov    %eax,(%esp)
801013cd:	e8 4d 74 00 00       	call   8010881f <copyout>
801013d2:	85 c0                	test   %eax,%eax
801013d4:	0f 88 6e 01 00 00    	js     80101548 <exec+0x46c>
      goto bad;
    ustack[3+argc] = sp;
801013da:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013dd:	8d 50 03             	lea    0x3(%eax),%edx
801013e0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801013e3:	89 84 95 40 fe ff ff 	mov    %eax,-0x1c0(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
801013ea:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801013ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801013f1:	c1 e0 02             	shl    $0x2,%eax
801013f4:	03 45 0c             	add    0xc(%ebp),%eax
801013f7:	8b 00                	mov    (%eax),%eax
801013f9:	85 c0                	test   %eax,%eax
801013fb:	0f 85 6c ff ff ff    	jne    8010136d <exec+0x291>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80101401:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101404:	83 c0 03             	add    $0x3,%eax
80101407:	c7 84 85 40 fe ff ff 	movl   $0x0,-0x1c0(%ebp,%eax,4)
8010140e:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80101412:	c7 85 40 fe ff ff ff 	movl   $0xffffffff,-0x1c0(%ebp)
80101419:	ff ff ff 
  ustack[1] = argc;
8010141c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010141f:	89 85 44 fe ff ff    	mov    %eax,-0x1bc(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80101425:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101428:	83 c0 01             	add    $0x1,%eax
8010142b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101432:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101435:	29 d0                	sub    %edx,%eax
80101437:	89 85 48 fe ff ff    	mov    %eax,-0x1b8(%ebp)

  sp -= (3+argc+1) * 4;
8010143d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101440:	83 c0 04             	add    $0x4,%eax
80101443:	c1 e0 02             	shl    $0x2,%eax
80101446:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80101449:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010144c:	83 c0 04             	add    $0x4,%eax
8010144f:	c1 e0 02             	shl    $0x2,%eax
80101452:	89 44 24 0c          	mov    %eax,0xc(%esp)
80101456:	8d 85 40 fe ff ff    	lea    -0x1c0(%ebp),%eax
8010145c:	89 44 24 08          	mov    %eax,0x8(%esp)
80101460:	8b 45 dc             	mov    -0x24(%ebp),%eax
80101463:	89 44 24 04          	mov    %eax,0x4(%esp)
80101467:	8b 45 d4             	mov    -0x2c(%ebp),%eax
8010146a:	89 04 24             	mov    %eax,(%esp)
8010146d:	e8 ad 73 00 00       	call   8010881f <copyout>
80101472:	85 c0                	test   %eax,%eax
80101474:	0f 88 d1 00 00 00    	js     8010154b <exec+0x46f>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
8010147a:	8b 45 08             	mov    0x8(%ebp),%eax
8010147d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101480:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101483:	89 45 f0             	mov    %eax,-0x10(%ebp)
80101486:	eb 17                	jmp    8010149f <exec+0x3c3>
    if(*s == '/')
80101488:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010148b:	0f b6 00             	movzbl (%eax),%eax
8010148e:	3c 2f                	cmp    $0x2f,%al
80101490:	75 09                	jne    8010149b <exec+0x3bf>
      last = s+1;
80101492:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101495:	83 c0 01             	add    $0x1,%eax
80101498:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
8010149b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010149f:	8b 45 f4             	mov    -0xc(%ebp),%eax
801014a2:	0f b6 00             	movzbl (%eax),%eax
801014a5:	84 c0                	test   %al,%al
801014a7:	75 df                	jne    80101488 <exec+0x3ac>
    if(*s == '/')
      last = s+1;
  safestrcpy(proc->name, last, sizeof(proc->name));
801014a9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014af:	8d 50 6c             	lea    0x6c(%eax),%edx
801014b2:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
801014b9:	00 
801014ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014bd:	89 44 24 04          	mov    %eax,0x4(%esp)
801014c1:	89 14 24             	mov    %edx,(%esp)
801014c4:	e8 d1 41 00 00       	call   8010569a <safestrcpy>

  // Commit to the user image.
  oldpgdir = proc->pgdir;
801014c9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014cf:	8b 40 04             	mov    0x4(%eax),%eax
801014d2:	89 45 d0             	mov    %eax,-0x30(%ebp)
  proc->pgdir = pgdir;
801014d5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014db:	8b 55 d4             	mov    -0x2c(%ebp),%edx
801014de:	89 50 04             	mov    %edx,0x4(%eax)
  proc->sz = sz;
801014e1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014e7:	8b 55 e0             	mov    -0x20(%ebp),%edx
801014ea:	89 10                	mov    %edx,(%eax)
  proc->tf->eip = elf.entry;  // main
801014ec:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801014f2:	8b 40 18             	mov    0x18(%eax),%eax
801014f5:	8b 95 24 fe ff ff    	mov    -0x1dc(%ebp),%edx
801014fb:	89 50 38             	mov    %edx,0x38(%eax)
  proc->tf->esp = sp;
801014fe:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101504:	8b 40 18             	mov    0x18(%eax),%eax
80101507:	8b 55 dc             	mov    -0x24(%ebp),%edx
8010150a:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(proc);
8010150d:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80101513:	89 04 24             	mov    %eax,(%esp)
80101516:	e8 4b 6c 00 00       	call   80108166 <switchuvm>
  freevm(oldpgdir);
8010151b:	8b 45 d0             	mov    -0x30(%ebp),%eax
8010151e:	89 04 24             	mov    %eax,(%esp)
80101521:	e8 b7 70 00 00       	call   801085dd <freevm>
  return 0;
80101526:	b8 00 00 00 00       	mov    $0x0,%eax
8010152b:	eb 46                	jmp    80101573 <exec+0x497>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) < sizeof(elf))
    goto bad;
8010152d:	90                   	nop
8010152e:	eb 1c                	jmp    8010154c <exec+0x470>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80101530:	90                   	nop
80101531:	eb 19                	jmp    8010154c <exec+0x470>

  if((pgdir = setupkvm(kalloc)) == 0)
    goto bad;
80101533:	90                   	nop
80101534:	eb 16                	jmp    8010154c <exec+0x470>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80101536:	90                   	nop
80101537:	eb 13                	jmp    8010154c <exec+0x470>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80101539:	90                   	nop
8010153a:	eb 10                	jmp    8010154c <exec+0x470>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
8010153c:	90                   	nop
8010153d:	eb 0d                	jmp    8010154c <exec+0x470>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
8010153f:	90                   	nop
80101540:	eb 0a                	jmp    8010154c <exec+0x470>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80101542:	90                   	nop
80101543:	eb 07                	jmp    8010154c <exec+0x470>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80101545:	90                   	nop
80101546:	eb 04                	jmp    8010154c <exec+0x470>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80101548:	90                   	nop
80101549:	eb 01                	jmp    8010154c <exec+0x470>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
8010154b:	90                   	nop
  switchuvm(proc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
8010154c:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80101550:	74 0b                	je     8010155d <exec+0x481>
    freevm(pgdir);
80101552:	8b 45 d4             	mov    -0x2c(%ebp),%eax
80101555:	89 04 24             	mov    %eax,(%esp)
80101558:	e8 80 70 00 00       	call   801085dd <freevm>
  if(ip)
8010155d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80101561:	74 0b                	je     8010156e <exec+0x492>
    iunlockput(ip);
80101563:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101566:	89 04 24             	mov    %eax,(%esp)
80101569:	e8 f6 0b 00 00       	call   80102164 <iunlockput>
  return -1;
8010156e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80101573:	c9                   	leave  
80101574:	c3                   	ret    
80101575:	00 00                	add    %al,(%eax)
	...

80101578 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80101578:	55                   	push   %ebp
80101579:	89 e5                	mov    %esp,%ebp
8010157b:	83 ec 18             	sub    $0x18,%esp
  initlock(&ftable.lock, "ftable");
8010157e:	c7 44 24 04 39 89 10 	movl   $0x80108939,0x4(%esp)
80101585:	80 
80101586:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
8010158d:	e8 68 3c 00 00       	call   801051fa <initlock>
}
80101592:	c9                   	leave  
80101593:	c3                   	ret    

80101594 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80101594:	55                   	push   %ebp
80101595:	89 e5                	mov    %esp,%ebp
80101597:	83 ec 28             	sub    $0x28,%esp
  struct file *f;

  acquire(&ftable.lock);
8010159a:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
801015a1:	e8 75 3c 00 00       	call   8010521b <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
801015a6:	c7 45 f4 f4 ed 10 80 	movl   $0x8010edf4,-0xc(%ebp)
801015ad:	eb 29                	jmp    801015d8 <filealloc+0x44>
    if(f->ref == 0){
801015af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015b2:	8b 40 04             	mov    0x4(%eax),%eax
801015b5:	85 c0                	test   %eax,%eax
801015b7:	75 1b                	jne    801015d4 <filealloc+0x40>
      f->ref = 1;
801015b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015bc:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
801015c3:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
801015ca:	e8 ae 3c 00 00       	call   8010527d <release>
      return f;
801015cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015d2:	eb 1e                	jmp    801015f2 <filealloc+0x5e>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
801015d4:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
801015d8:	81 7d f4 54 f7 10 80 	cmpl   $0x8010f754,-0xc(%ebp)
801015df:	72 ce                	jb     801015af <filealloc+0x1b>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
801015e1:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
801015e8:	e8 90 3c 00 00       	call   8010527d <release>
  return 0;
801015ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
801015f2:	c9                   	leave  
801015f3:	c3                   	ret    

801015f4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
801015f4:	55                   	push   %ebp
801015f5:	89 e5                	mov    %esp,%ebp
801015f7:	83 ec 18             	sub    $0x18,%esp
  acquire(&ftable.lock);
801015fa:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80101601:	e8 15 3c 00 00       	call   8010521b <acquire>
  if(f->ref < 1)
80101606:	8b 45 08             	mov    0x8(%ebp),%eax
80101609:	8b 40 04             	mov    0x4(%eax),%eax
8010160c:	85 c0                	test   %eax,%eax
8010160e:	7f 0c                	jg     8010161c <filedup+0x28>
    panic("filedup");
80101610:	c7 04 24 40 89 10 80 	movl   $0x80108940,(%esp)
80101617:	e8 21 ef ff ff       	call   8010053d <panic>
  f->ref++;
8010161c:	8b 45 08             	mov    0x8(%ebp),%eax
8010161f:	8b 40 04             	mov    0x4(%eax),%eax
80101622:	8d 50 01             	lea    0x1(%eax),%edx
80101625:	8b 45 08             	mov    0x8(%ebp),%eax
80101628:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010162b:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80101632:	e8 46 3c 00 00       	call   8010527d <release>
  return f;
80101637:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010163a:	c9                   	leave  
8010163b:	c3                   	ret    

8010163c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
8010163c:	55                   	push   %ebp
8010163d:	89 e5                	mov    %esp,%ebp
8010163f:	83 ec 38             	sub    $0x38,%esp
  struct file ff;

  acquire(&ftable.lock);
80101642:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80101649:	e8 cd 3b 00 00       	call   8010521b <acquire>
  if(f->ref < 1)
8010164e:	8b 45 08             	mov    0x8(%ebp),%eax
80101651:	8b 40 04             	mov    0x4(%eax),%eax
80101654:	85 c0                	test   %eax,%eax
80101656:	7f 0c                	jg     80101664 <fileclose+0x28>
    panic("fileclose");
80101658:	c7 04 24 48 89 10 80 	movl   $0x80108948,(%esp)
8010165f:	e8 d9 ee ff ff       	call   8010053d <panic>
  if(--f->ref > 0){
80101664:	8b 45 08             	mov    0x8(%ebp),%eax
80101667:	8b 40 04             	mov    0x4(%eax),%eax
8010166a:	8d 50 ff             	lea    -0x1(%eax),%edx
8010166d:	8b 45 08             	mov    0x8(%ebp),%eax
80101670:	89 50 04             	mov    %edx,0x4(%eax)
80101673:	8b 45 08             	mov    0x8(%ebp),%eax
80101676:	8b 40 04             	mov    0x4(%eax),%eax
80101679:	85 c0                	test   %eax,%eax
8010167b:	7e 11                	jle    8010168e <fileclose+0x52>
    release(&ftable.lock);
8010167d:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
80101684:	e8 f4 3b 00 00       	call   8010527d <release>
    return;
80101689:	e9 82 00 00 00       	jmp    80101710 <fileclose+0xd4>
  }
  ff = *f;
8010168e:	8b 45 08             	mov    0x8(%ebp),%eax
80101691:	8b 10                	mov    (%eax),%edx
80101693:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101696:	8b 50 04             	mov    0x4(%eax),%edx
80101699:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010169c:	8b 50 08             	mov    0x8(%eax),%edx
8010169f:	89 55 e8             	mov    %edx,-0x18(%ebp)
801016a2:	8b 50 0c             	mov    0xc(%eax),%edx
801016a5:	89 55 ec             	mov    %edx,-0x14(%ebp)
801016a8:	8b 50 10             	mov    0x10(%eax),%edx
801016ab:	89 55 f0             	mov    %edx,-0x10(%ebp)
801016ae:	8b 40 14             	mov    0x14(%eax),%eax
801016b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
801016b4:	8b 45 08             	mov    0x8(%ebp),%eax
801016b7:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
801016be:	8b 45 08             	mov    0x8(%ebp),%eax
801016c1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
801016c7:	c7 04 24 c0 ed 10 80 	movl   $0x8010edc0,(%esp)
801016ce:	e8 aa 3b 00 00       	call   8010527d <release>
  
  if(ff.type == FD_PIPE)
801016d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801016d6:	83 f8 01             	cmp    $0x1,%eax
801016d9:	75 18                	jne    801016f3 <fileclose+0xb7>
    pipeclose(ff.pipe, ff.writable);
801016db:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
801016df:	0f be d0             	movsbl %al,%edx
801016e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801016e5:	89 54 24 04          	mov    %edx,0x4(%esp)
801016e9:	89 04 24             	mov    %eax,(%esp)
801016ec:	e8 02 2d 00 00       	call   801043f3 <pipeclose>
801016f1:	eb 1d                	jmp    80101710 <fileclose+0xd4>
  else if(ff.type == FD_INODE){
801016f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
801016f6:	83 f8 02             	cmp    $0x2,%eax
801016f9:	75 15                	jne    80101710 <fileclose+0xd4>
    begin_trans();
801016fb:	e8 95 21 00 00       	call   80103895 <begin_trans>
    iput(ff.ip);
80101700:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101703:	89 04 24             	mov    %eax,(%esp)
80101706:	e8 88 09 00 00       	call   80102093 <iput>
    commit_trans();
8010170b:	e8 ce 21 00 00       	call   801038de <commit_trans>
  }
}
80101710:	c9                   	leave  
80101711:	c3                   	ret    

80101712 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101712:	55                   	push   %ebp
80101713:	89 e5                	mov    %esp,%ebp
80101715:	83 ec 18             	sub    $0x18,%esp
  if(f->type == FD_INODE){
80101718:	8b 45 08             	mov    0x8(%ebp),%eax
8010171b:	8b 00                	mov    (%eax),%eax
8010171d:	83 f8 02             	cmp    $0x2,%eax
80101720:	75 38                	jne    8010175a <filestat+0x48>
    ilock(f->ip);
80101722:	8b 45 08             	mov    0x8(%ebp),%eax
80101725:	8b 40 10             	mov    0x10(%eax),%eax
80101728:	89 04 24             	mov    %eax,(%esp)
8010172b:	e8 b0 07 00 00       	call   80101ee0 <ilock>
    stati(f->ip, st);
80101730:	8b 45 08             	mov    0x8(%ebp),%eax
80101733:	8b 40 10             	mov    0x10(%eax),%eax
80101736:	8b 55 0c             	mov    0xc(%ebp),%edx
80101739:	89 54 24 04          	mov    %edx,0x4(%esp)
8010173d:	89 04 24             	mov    %eax,(%esp)
80101740:	e8 4c 0c 00 00       	call   80102391 <stati>
    iunlock(f->ip);
80101745:	8b 45 08             	mov    0x8(%ebp),%eax
80101748:	8b 40 10             	mov    0x10(%eax),%eax
8010174b:	89 04 24             	mov    %eax,(%esp)
8010174e:	e8 db 08 00 00       	call   8010202e <iunlock>
    return 0;
80101753:	b8 00 00 00 00       	mov    $0x0,%eax
80101758:	eb 05                	jmp    8010175f <filestat+0x4d>
  }
  return -1;
8010175a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
8010175f:	c9                   	leave  
80101760:	c3                   	ret    

80101761 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
80101761:	55                   	push   %ebp
80101762:	89 e5                	mov    %esp,%ebp
80101764:	83 ec 28             	sub    $0x28,%esp
  int r;

  if(f->readable == 0)
80101767:	8b 45 08             	mov    0x8(%ebp),%eax
8010176a:	0f b6 40 08          	movzbl 0x8(%eax),%eax
8010176e:	84 c0                	test   %al,%al
80101770:	75 0a                	jne    8010177c <fileread+0x1b>
    return -1;
80101772:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101777:	e9 9f 00 00 00       	jmp    8010181b <fileread+0xba>
  if(f->type == FD_PIPE)
8010177c:	8b 45 08             	mov    0x8(%ebp),%eax
8010177f:	8b 00                	mov    (%eax),%eax
80101781:	83 f8 01             	cmp    $0x1,%eax
80101784:	75 1e                	jne    801017a4 <fileread+0x43>
    return piperead(f->pipe, addr, n);
80101786:	8b 45 08             	mov    0x8(%ebp),%eax
80101789:	8b 40 0c             	mov    0xc(%eax),%eax
8010178c:	8b 55 10             	mov    0x10(%ebp),%edx
8010178f:	89 54 24 08          	mov    %edx,0x8(%esp)
80101793:	8b 55 0c             	mov    0xc(%ebp),%edx
80101796:	89 54 24 04          	mov    %edx,0x4(%esp)
8010179a:	89 04 24             	mov    %eax,(%esp)
8010179d:	e8 d3 2d 00 00       	call   80104575 <piperead>
801017a2:	eb 77                	jmp    8010181b <fileread+0xba>
  if(f->type == FD_INODE){
801017a4:	8b 45 08             	mov    0x8(%ebp),%eax
801017a7:	8b 00                	mov    (%eax),%eax
801017a9:	83 f8 02             	cmp    $0x2,%eax
801017ac:	75 61                	jne    8010180f <fileread+0xae>
    ilock(f->ip);
801017ae:	8b 45 08             	mov    0x8(%ebp),%eax
801017b1:	8b 40 10             	mov    0x10(%eax),%eax
801017b4:	89 04 24             	mov    %eax,(%esp)
801017b7:	e8 24 07 00 00       	call   80101ee0 <ilock>
    if((r = readi(f->ip, addr, f->off, n)) > 0)
801017bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
801017bf:	8b 45 08             	mov    0x8(%ebp),%eax
801017c2:	8b 50 14             	mov    0x14(%eax),%edx
801017c5:	8b 45 08             	mov    0x8(%ebp),%eax
801017c8:	8b 40 10             	mov    0x10(%eax),%eax
801017cb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801017cf:	89 54 24 08          	mov    %edx,0x8(%esp)
801017d3:	8b 55 0c             	mov    0xc(%ebp),%edx
801017d6:	89 54 24 04          	mov    %edx,0x4(%esp)
801017da:	89 04 24             	mov    %eax,(%esp)
801017dd:	e8 f4 0b 00 00       	call   801023d6 <readi>
801017e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801017e5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801017e9:	7e 11                	jle    801017fc <fileread+0x9b>
      f->off += r;
801017eb:	8b 45 08             	mov    0x8(%ebp),%eax
801017ee:	8b 50 14             	mov    0x14(%eax),%edx
801017f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f4:	01 c2                	add    %eax,%edx
801017f6:	8b 45 08             	mov    0x8(%ebp),%eax
801017f9:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
801017fc:	8b 45 08             	mov    0x8(%ebp),%eax
801017ff:	8b 40 10             	mov    0x10(%eax),%eax
80101802:	89 04 24             	mov    %eax,(%esp)
80101805:	e8 24 08 00 00       	call   8010202e <iunlock>
    return r;
8010180a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010180d:	eb 0c                	jmp    8010181b <fileread+0xba>
  }
  panic("fileread");
8010180f:	c7 04 24 52 89 10 80 	movl   $0x80108952,(%esp)
80101816:	e8 22 ed ff ff       	call   8010053d <panic>
}
8010181b:	c9                   	leave  
8010181c:	c3                   	ret    

8010181d <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
8010181d:	55                   	push   %ebp
8010181e:	89 e5                	mov    %esp,%ebp
80101820:	53                   	push   %ebx
80101821:	83 ec 24             	sub    $0x24,%esp
  int r;

  if(f->writable == 0)
80101824:	8b 45 08             	mov    0x8(%ebp),%eax
80101827:	0f b6 40 09          	movzbl 0x9(%eax),%eax
8010182b:	84 c0                	test   %al,%al
8010182d:	75 0a                	jne    80101839 <filewrite+0x1c>
    return -1;
8010182f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101834:	e9 23 01 00 00       	jmp    8010195c <filewrite+0x13f>
  if(f->type == FD_PIPE)
80101839:	8b 45 08             	mov    0x8(%ebp),%eax
8010183c:	8b 00                	mov    (%eax),%eax
8010183e:	83 f8 01             	cmp    $0x1,%eax
80101841:	75 21                	jne    80101864 <filewrite+0x47>
    return pipewrite(f->pipe, addr, n);
80101843:	8b 45 08             	mov    0x8(%ebp),%eax
80101846:	8b 40 0c             	mov    0xc(%eax),%eax
80101849:	8b 55 10             	mov    0x10(%ebp),%edx
8010184c:	89 54 24 08          	mov    %edx,0x8(%esp)
80101850:	8b 55 0c             	mov    0xc(%ebp),%edx
80101853:	89 54 24 04          	mov    %edx,0x4(%esp)
80101857:	89 04 24             	mov    %eax,(%esp)
8010185a:	e8 26 2c 00 00       	call   80104485 <pipewrite>
8010185f:	e9 f8 00 00 00       	jmp    8010195c <filewrite+0x13f>
  if(f->type == FD_INODE){
80101864:	8b 45 08             	mov    0x8(%ebp),%eax
80101867:	8b 00                	mov    (%eax),%eax
80101869:	83 f8 02             	cmp    $0x2,%eax
8010186c:	0f 85 de 00 00 00    	jne    80101950 <filewrite+0x133>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
80101872:	c7 45 ec 00 06 00 00 	movl   $0x600,-0x14(%ebp)
    int i = 0;
80101879:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101880:	e9 a8 00 00 00       	jmp    8010192d <filewrite+0x110>
      int n1 = n - i;
80101885:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101888:	8b 55 10             	mov    0x10(%ebp),%edx
8010188b:	89 d1                	mov    %edx,%ecx
8010188d:	29 c1                	sub    %eax,%ecx
8010188f:	89 c8                	mov    %ecx,%eax
80101891:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101894:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101897:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010189a:	7e 06                	jle    801018a2 <filewrite+0x85>
        n1 = max;
8010189c:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010189f:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_trans();
801018a2:	e8 ee 1f 00 00       	call   80103895 <begin_trans>
      ilock(f->ip);
801018a7:	8b 45 08             	mov    0x8(%ebp),%eax
801018aa:	8b 40 10             	mov    0x10(%eax),%eax
801018ad:	89 04 24             	mov    %eax,(%esp)
801018b0:	e8 2b 06 00 00       	call   80101ee0 <ilock>
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
801018b5:	8b 5d f0             	mov    -0x10(%ebp),%ebx
801018b8:	8b 45 08             	mov    0x8(%ebp),%eax
801018bb:	8b 48 14             	mov    0x14(%eax),%ecx
801018be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801018c1:	89 c2                	mov    %eax,%edx
801018c3:	03 55 0c             	add    0xc(%ebp),%edx
801018c6:	8b 45 08             	mov    0x8(%ebp),%eax
801018c9:	8b 40 10             	mov    0x10(%eax),%eax
801018cc:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
801018d0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801018d4:	89 54 24 04          	mov    %edx,0x4(%esp)
801018d8:	89 04 24             	mov    %eax,(%esp)
801018db:	e8 61 0c 00 00       	call   80102541 <writei>
801018e0:	89 45 e8             	mov    %eax,-0x18(%ebp)
801018e3:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
801018e7:	7e 11                	jle    801018fa <filewrite+0xdd>
        f->off += r;
801018e9:	8b 45 08             	mov    0x8(%ebp),%eax
801018ec:	8b 50 14             	mov    0x14(%eax),%edx
801018ef:	8b 45 e8             	mov    -0x18(%ebp),%eax
801018f2:	01 c2                	add    %eax,%edx
801018f4:	8b 45 08             	mov    0x8(%ebp),%eax
801018f7:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
801018fa:	8b 45 08             	mov    0x8(%ebp),%eax
801018fd:	8b 40 10             	mov    0x10(%eax),%eax
80101900:	89 04 24             	mov    %eax,(%esp)
80101903:	e8 26 07 00 00       	call   8010202e <iunlock>
      commit_trans();
80101908:	e8 d1 1f 00 00       	call   801038de <commit_trans>

      if(r < 0)
8010190d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101911:	78 28                	js     8010193b <filewrite+0x11e>
        break;
      if(r != n1)
80101913:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101916:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80101919:	74 0c                	je     80101927 <filewrite+0x10a>
        panic("short filewrite");
8010191b:	c7 04 24 5b 89 10 80 	movl   $0x8010895b,(%esp)
80101922:	e8 16 ec ff ff       	call   8010053d <panic>
      i += r;
80101927:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010192a:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
8010192d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101930:	3b 45 10             	cmp    0x10(%ebp),%eax
80101933:	0f 8c 4c ff ff ff    	jl     80101885 <filewrite+0x68>
80101939:	eb 01                	jmp    8010193c <filewrite+0x11f>
        f->off += r;
      iunlock(f->ip);
      commit_trans();

      if(r < 0)
        break;
8010193b:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
8010193c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010193f:	3b 45 10             	cmp    0x10(%ebp),%eax
80101942:	75 05                	jne    80101949 <filewrite+0x12c>
80101944:	8b 45 10             	mov    0x10(%ebp),%eax
80101947:	eb 05                	jmp    8010194e <filewrite+0x131>
80101949:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010194e:	eb 0c                	jmp    8010195c <filewrite+0x13f>
  }
  panic("filewrite");
80101950:	c7 04 24 6b 89 10 80 	movl   $0x8010896b,(%esp)
80101957:	e8 e1 eb ff ff       	call   8010053d <panic>
}
8010195c:	83 c4 24             	add    $0x24,%esp
8010195f:	5b                   	pop    %ebx
80101960:	5d                   	pop    %ebp
80101961:	c3                   	ret    
	...

80101964 <readsb>:
static void itrunc(struct inode*);

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
80101964:	55                   	push   %ebp
80101965:	89 e5                	mov    %esp,%ebp
80101967:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, 1);
8010196a:	8b 45 08             	mov    0x8(%ebp),%eax
8010196d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80101974:	00 
80101975:	89 04 24             	mov    %eax,(%esp)
80101978:	e8 29 e8 ff ff       	call   801001a6 <bread>
8010197d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
80101980:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101983:	83 c0 18             	add    $0x18,%eax
80101986:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
8010198d:	00 
8010198e:	89 44 24 04          	mov    %eax,0x4(%esp)
80101992:	8b 45 0c             	mov    0xc(%ebp),%eax
80101995:	89 04 24             	mov    %eax,(%esp)
80101998:	e8 a0 3b 00 00       	call   8010553d <memmove>
  brelse(bp);
8010199d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019a0:	89 04 24             	mov    %eax,(%esp)
801019a3:	e8 6f e8 ff ff       	call   80100217 <brelse>
}
801019a8:	c9                   	leave  
801019a9:	c3                   	ret    

801019aa <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
801019aa:	55                   	push   %ebp
801019ab:	89 e5                	mov    %esp,%ebp
801019ad:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  
  bp = bread(dev, bno);
801019b0:	8b 55 0c             	mov    0xc(%ebp),%edx
801019b3:	8b 45 08             	mov    0x8(%ebp),%eax
801019b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801019ba:	89 04 24             	mov    %eax,(%esp)
801019bd:	e8 e4 e7 ff ff       	call   801001a6 <bread>
801019c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
801019c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019c8:	83 c0 18             	add    $0x18,%eax
801019cb:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801019d2:	00 
801019d3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801019da:	00 
801019db:	89 04 24             	mov    %eax,(%esp)
801019de:	e8 87 3a 00 00       	call   8010546a <memset>
  log_write(bp);
801019e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019e6:	89 04 24             	mov    %eax,(%esp)
801019e9:	e8 48 1f 00 00       	call   80103936 <log_write>
  brelse(bp);
801019ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019f1:	89 04 24             	mov    %eax,(%esp)
801019f4:	e8 1e e8 ff ff       	call   80100217 <brelse>
}
801019f9:	c9                   	leave  
801019fa:	c3                   	ret    

801019fb <balloc>:
// Blocks. 

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
801019fb:	55                   	push   %ebp
801019fc:	89 e5                	mov    %esp,%ebp
801019fe:	53                   	push   %ebx
801019ff:	83 ec 34             	sub    $0x34,%esp
  int b, bi, m;
  struct buf *bp;
  struct superblock sb;

  bp = 0;
80101a02:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  readsb(dev, &sb);
80101a09:	8b 45 08             	mov    0x8(%ebp),%eax
80101a0c:	8d 55 d8             	lea    -0x28(%ebp),%edx
80101a0f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101a13:	89 04 24             	mov    %eax,(%esp)
80101a16:	e8 49 ff ff ff       	call   80101964 <readsb>
  for(b = 0; b < sb.size; b += BPB){
80101a1b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101a22:	e9 11 01 00 00       	jmp    80101b38 <balloc+0x13d>
    bp = bread(dev, BBLOCK(b, sb.ninodes));
80101a27:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a2a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
80101a30:	85 c0                	test   %eax,%eax
80101a32:	0f 48 c2             	cmovs  %edx,%eax
80101a35:	c1 f8 0c             	sar    $0xc,%eax
80101a38:	8b 55 e0             	mov    -0x20(%ebp),%edx
80101a3b:	c1 ea 03             	shr    $0x3,%edx
80101a3e:	01 d0                	add    %edx,%eax
80101a40:	83 c0 03             	add    $0x3,%eax
80101a43:	89 44 24 04          	mov    %eax,0x4(%esp)
80101a47:	8b 45 08             	mov    0x8(%ebp),%eax
80101a4a:	89 04 24             	mov    %eax,(%esp)
80101a4d:	e8 54 e7 ff ff       	call   801001a6 <bread>
80101a52:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101a55:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101a5c:	e9 a7 00 00 00       	jmp    80101b08 <balloc+0x10d>
      m = 1 << (bi % 8);
80101a61:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a64:	89 c2                	mov    %eax,%edx
80101a66:	c1 fa 1f             	sar    $0x1f,%edx
80101a69:	c1 ea 1d             	shr    $0x1d,%edx
80101a6c:	01 d0                	add    %edx,%eax
80101a6e:	83 e0 07             	and    $0x7,%eax
80101a71:	29 d0                	sub    %edx,%eax
80101a73:	ba 01 00 00 00       	mov    $0x1,%edx
80101a78:	89 d3                	mov    %edx,%ebx
80101a7a:	89 c1                	mov    %eax,%ecx
80101a7c:	d3 e3                	shl    %cl,%ebx
80101a7e:	89 d8                	mov    %ebx,%eax
80101a80:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
80101a83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a86:	8d 50 07             	lea    0x7(%eax),%edx
80101a89:	85 c0                	test   %eax,%eax
80101a8b:	0f 48 c2             	cmovs  %edx,%eax
80101a8e:	c1 f8 03             	sar    $0x3,%eax
80101a91:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101a94:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101a99:	0f b6 c0             	movzbl %al,%eax
80101a9c:	23 45 e8             	and    -0x18(%ebp),%eax
80101a9f:	85 c0                	test   %eax,%eax
80101aa1:	75 61                	jne    80101b04 <balloc+0x109>
        bp->data[bi/8] |= m;  // Mark block in use.
80101aa3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aa6:	8d 50 07             	lea    0x7(%eax),%edx
80101aa9:	85 c0                	test   %eax,%eax
80101aab:	0f 48 c2             	cmovs  %edx,%eax
80101aae:	c1 f8 03             	sar    $0x3,%eax
80101ab1:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101ab4:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101ab9:	89 d1                	mov    %edx,%ecx
80101abb:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101abe:	09 ca                	or     %ecx,%edx
80101ac0:	89 d1                	mov    %edx,%ecx
80101ac2:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101ac5:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
        log_write(bp);
80101ac9:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101acc:	89 04 24             	mov    %eax,(%esp)
80101acf:	e8 62 1e 00 00       	call   80103936 <log_write>
        brelse(bp);
80101ad4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ad7:	89 04 24             	mov    %eax,(%esp)
80101ada:	e8 38 e7 ff ff       	call   80100217 <brelse>
        bzero(dev, b + bi);
80101adf:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ae2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ae5:	01 c2                	add    %eax,%edx
80101ae7:	8b 45 08             	mov    0x8(%ebp),%eax
80101aea:	89 54 24 04          	mov    %edx,0x4(%esp)
80101aee:	89 04 24             	mov    %eax,(%esp)
80101af1:	e8 b4 fe ff ff       	call   801019aa <bzero>
        return b + bi;
80101af6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101af9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101afc:	01 d0                	add    %edx,%eax
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
}
80101afe:	83 c4 34             	add    $0x34,%esp
80101b01:	5b                   	pop    %ebx
80101b02:	5d                   	pop    %ebp
80101b03:	c3                   	ret    

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb.ninodes));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
80101b04:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101b08:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101b0f:	7f 15                	jg     80101b26 <balloc+0x12b>
80101b11:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b14:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b17:	01 d0                	add    %edx,%eax
80101b19:	89 c2                	mov    %eax,%edx
80101b1b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101b1e:	39 c2                	cmp    %eax,%edx
80101b20:	0f 82 3b ff ff ff    	jb     80101a61 <balloc+0x66>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101b26:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101b29:	89 04 24             	mov    %eax,(%esp)
80101b2c:	e8 e6 e6 ff ff       	call   80100217 <brelse>
  struct buf *bp;
  struct superblock sb;

  bp = 0;
  readsb(dev, &sb);
  for(b = 0; b < sb.size; b += BPB){
80101b31:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80101b38:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101b3b:	8b 45 d8             	mov    -0x28(%ebp),%eax
80101b3e:	39 c2                	cmp    %eax,%edx
80101b40:	0f 82 e1 fe ff ff    	jb     80101a27 <balloc+0x2c>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
80101b46:	c7 04 24 75 89 10 80 	movl   $0x80108975,(%esp)
80101b4d:	e8 eb e9 ff ff       	call   8010053d <panic>

80101b52 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
80101b52:	55                   	push   %ebp
80101b53:	89 e5                	mov    %esp,%ebp
80101b55:	53                   	push   %ebx
80101b56:	83 ec 34             	sub    $0x34,%esp
  struct buf *bp;
  struct superblock sb;
  int bi, m;

  readsb(dev, &sb);
80101b59:	8d 45 dc             	lea    -0x24(%ebp),%eax
80101b5c:	89 44 24 04          	mov    %eax,0x4(%esp)
80101b60:	8b 45 08             	mov    0x8(%ebp),%eax
80101b63:	89 04 24             	mov    %eax,(%esp)
80101b66:	e8 f9 fd ff ff       	call   80101964 <readsb>
  bp = bread(dev, BBLOCK(b, sb.ninodes));
80101b6b:	8b 45 0c             	mov    0xc(%ebp),%eax
80101b6e:	89 c2                	mov    %eax,%edx
80101b70:	c1 ea 0c             	shr    $0xc,%edx
80101b73:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101b76:	c1 e8 03             	shr    $0x3,%eax
80101b79:	01 d0                	add    %edx,%eax
80101b7b:	8d 50 03             	lea    0x3(%eax),%edx
80101b7e:	8b 45 08             	mov    0x8(%ebp),%eax
80101b81:	89 54 24 04          	mov    %edx,0x4(%esp)
80101b85:	89 04 24             	mov    %eax,(%esp)
80101b88:	e8 19 e6 ff ff       	call   801001a6 <bread>
80101b8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101b90:	8b 45 0c             	mov    0xc(%ebp),%eax
80101b93:	25 ff 0f 00 00       	and    $0xfff,%eax
80101b98:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
80101b9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101b9e:	89 c2                	mov    %eax,%edx
80101ba0:	c1 fa 1f             	sar    $0x1f,%edx
80101ba3:	c1 ea 1d             	shr    $0x1d,%edx
80101ba6:	01 d0                	add    %edx,%eax
80101ba8:	83 e0 07             	and    $0x7,%eax
80101bab:	29 d0                	sub    %edx,%eax
80101bad:	ba 01 00 00 00       	mov    $0x1,%edx
80101bb2:	89 d3                	mov    %edx,%ebx
80101bb4:	89 c1                	mov    %eax,%ecx
80101bb6:	d3 e3                	shl    %cl,%ebx
80101bb8:	89 d8                	mov    %ebx,%eax
80101bba:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101bbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bc0:	8d 50 07             	lea    0x7(%eax),%edx
80101bc3:	85 c0                	test   %eax,%eax
80101bc5:	0f 48 c2             	cmovs  %edx,%eax
80101bc8:	c1 f8 03             	sar    $0x3,%eax
80101bcb:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bce:	0f b6 44 02 18       	movzbl 0x18(%edx,%eax,1),%eax
80101bd3:	0f b6 c0             	movzbl %al,%eax
80101bd6:	23 45 ec             	and    -0x14(%ebp),%eax
80101bd9:	85 c0                	test   %eax,%eax
80101bdb:	75 0c                	jne    80101be9 <bfree+0x97>
    panic("freeing free block");
80101bdd:	c7 04 24 8b 89 10 80 	movl   $0x8010898b,(%esp)
80101be4:	e8 54 e9 ff ff       	call   8010053d <panic>
  bp->data[bi/8] &= ~m;
80101be9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101bec:	8d 50 07             	lea    0x7(%eax),%edx
80101bef:	85 c0                	test   %eax,%eax
80101bf1:	0f 48 c2             	cmovs  %edx,%eax
80101bf4:	c1 f8 03             	sar    $0x3,%eax
80101bf7:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101bfa:	0f b6 54 02 18       	movzbl 0x18(%edx,%eax,1),%edx
80101bff:	8b 4d ec             	mov    -0x14(%ebp),%ecx
80101c02:	f7 d1                	not    %ecx
80101c04:	21 ca                	and    %ecx,%edx
80101c06:	89 d1                	mov    %edx,%ecx
80101c08:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101c0b:	88 4c 02 18          	mov    %cl,0x18(%edx,%eax,1)
  log_write(bp);
80101c0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c12:	89 04 24             	mov    %eax,(%esp)
80101c15:	e8 1c 1d 00 00       	call   80103936 <log_write>
  brelse(bp);
80101c1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c1d:	89 04 24             	mov    %eax,(%esp)
80101c20:	e8 f2 e5 ff ff       	call   80100217 <brelse>
}
80101c25:	83 c4 34             	add    $0x34,%esp
80101c28:	5b                   	pop    %ebx
80101c29:	5d                   	pop    %ebp
80101c2a:	c3                   	ret    

80101c2b <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(void)
{
80101c2b:	55                   	push   %ebp
80101c2c:	89 e5                	mov    %esp,%ebp
80101c2e:	83 ec 18             	sub    $0x18,%esp
  initlock(&icache.lock, "icache");
80101c31:	c7 44 24 04 9e 89 10 	movl   $0x8010899e,0x4(%esp)
80101c38:	80 
80101c39:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101c40:	e8 b5 35 00 00       	call   801051fa <initlock>
}
80101c45:	c9                   	leave  
80101c46:	c3                   	ret    

80101c47 <ialloc>:
//PAGEBREAK!
// Allocate a new inode with the given type on device dev.
// A free inode has a type of zero.
struct inode*
ialloc(uint dev, short type)
{
80101c47:	55                   	push   %ebp
80101c48:	89 e5                	mov    %esp,%ebp
80101c4a:	83 ec 48             	sub    $0x48,%esp
80101c4d:	8b 45 0c             	mov    0xc(%ebp),%eax
80101c50:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);
80101c54:	8b 45 08             	mov    0x8(%ebp),%eax
80101c57:	8d 55 dc             	lea    -0x24(%ebp),%edx
80101c5a:	89 54 24 04          	mov    %edx,0x4(%esp)
80101c5e:	89 04 24             	mov    %eax,(%esp)
80101c61:	e8 fe fc ff ff       	call   80101964 <readsb>

  for(inum = 1; inum < sb.ninodes; inum++){
80101c66:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101c6d:	e9 98 00 00 00       	jmp    80101d0a <ialloc+0xc3>
    bp = bread(dev, IBLOCK(inum));
80101c72:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c75:	c1 e8 03             	shr    $0x3,%eax
80101c78:	83 c0 02             	add    $0x2,%eax
80101c7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80101c7f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c82:	89 04 24             	mov    %eax,(%esp)
80101c85:	e8 1c e5 ff ff       	call   801001a6 <bread>
80101c8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101c8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101c90:	8d 50 18             	lea    0x18(%eax),%edx
80101c93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101c96:	83 e0 07             	and    $0x7,%eax
80101c99:	c1 e0 06             	shl    $0x6,%eax
80101c9c:	01 d0                	add    %edx,%eax
80101c9e:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
80101ca1:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101ca4:	0f b7 00             	movzwl (%eax),%eax
80101ca7:	66 85 c0             	test   %ax,%ax
80101caa:	75 4f                	jne    80101cfb <ialloc+0xb4>
      memset(dip, 0, sizeof(*dip));
80101cac:	c7 44 24 08 40 00 00 	movl   $0x40,0x8(%esp)
80101cb3:	00 
80101cb4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80101cbb:	00 
80101cbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cbf:	89 04 24             	mov    %eax,(%esp)
80101cc2:	e8 a3 37 00 00       	call   8010546a <memset>
      dip->type = type;
80101cc7:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101cca:	0f b7 55 d4          	movzwl -0x2c(%ebp),%edx
80101cce:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
80101cd1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cd4:	89 04 24             	mov    %eax,(%esp)
80101cd7:	e8 5a 1c 00 00       	call   80103936 <log_write>
      brelse(bp);
80101cdc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cdf:	89 04 24             	mov    %eax,(%esp)
80101ce2:	e8 30 e5 ff ff       	call   80100217 <brelse>
      return iget(dev, inum);
80101ce7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cea:	89 44 24 04          	mov    %eax,0x4(%esp)
80101cee:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf1:	89 04 24             	mov    %eax,(%esp)
80101cf4:	e8 e3 00 00 00       	call   80101ddc <iget>
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
}
80101cf9:	c9                   	leave  
80101cfa:	c3                   	ret    
      dip->type = type;
      log_write(bp);   // mark it allocated on the disk
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
80101cfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101cfe:	89 04 24             	mov    %eax,(%esp)
80101d01:	e8 11 e5 ff ff       	call   80100217 <brelse>
  struct dinode *dip;
  struct superblock sb;

  readsb(dev, &sb);

  for(inum = 1; inum < sb.ninodes; inum++){
80101d06:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101d0a:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101d0d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80101d10:	39 c2                	cmp    %eax,%edx
80101d12:	0f 82 5a ff ff ff    	jb     80101c72 <ialloc+0x2b>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101d18:	c7 04 24 a5 89 10 80 	movl   $0x801089a5,(%esp)
80101d1f:	e8 19 e8 ff ff       	call   8010053d <panic>

80101d24 <iupdate>:
}

// Copy a modified in-memory inode to disk.
void
iupdate(struct inode *ip)
{
80101d24:	55                   	push   %ebp
80101d25:	89 e5                	mov    %esp,%ebp
80101d27:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum));
80101d2a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d2d:	8b 40 04             	mov    0x4(%eax),%eax
80101d30:	c1 e8 03             	shr    $0x3,%eax
80101d33:	8d 50 02             	lea    0x2(%eax),%edx
80101d36:	8b 45 08             	mov    0x8(%ebp),%eax
80101d39:	8b 00                	mov    (%eax),%eax
80101d3b:	89 54 24 04          	mov    %edx,0x4(%esp)
80101d3f:	89 04 24             	mov    %eax,(%esp)
80101d42:	e8 5f e4 ff ff       	call   801001a6 <bread>
80101d47:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101d4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d4d:	8d 50 18             	lea    0x18(%eax),%edx
80101d50:	8b 45 08             	mov    0x8(%ebp),%eax
80101d53:	8b 40 04             	mov    0x4(%eax),%eax
80101d56:	83 e0 07             	and    $0x7,%eax
80101d59:	c1 e0 06             	shl    $0x6,%eax
80101d5c:	01 d0                	add    %edx,%eax
80101d5e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101d61:	8b 45 08             	mov    0x8(%ebp),%eax
80101d64:	0f b7 50 10          	movzwl 0x10(%eax),%edx
80101d68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d6b:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101d6e:	8b 45 08             	mov    0x8(%ebp),%eax
80101d71:	0f b7 50 12          	movzwl 0x12(%eax),%edx
80101d75:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d78:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101d7c:	8b 45 08             	mov    0x8(%ebp),%eax
80101d7f:	0f b7 50 14          	movzwl 0x14(%eax),%edx
80101d83:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d86:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
80101d8a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d8d:	0f b7 50 16          	movzwl 0x16(%eax),%edx
80101d91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d94:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
80101d98:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9b:	8b 50 18             	mov    0x18(%eax),%edx
80101d9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101da1:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
80101da4:	8b 45 08             	mov    0x8(%ebp),%eax
80101da7:	8d 50 1c             	lea    0x1c(%eax),%edx
80101daa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101dad:	83 c0 0c             	add    $0xc,%eax
80101db0:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101db7:	00 
80101db8:	89 54 24 04          	mov    %edx,0x4(%esp)
80101dbc:	89 04 24             	mov    %eax,(%esp)
80101dbf:	e8 79 37 00 00       	call   8010553d <memmove>
  log_write(bp);
80101dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dc7:	89 04 24             	mov    %eax,(%esp)
80101dca:	e8 67 1b 00 00       	call   80103936 <log_write>
  brelse(bp);
80101dcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101dd2:	89 04 24             	mov    %eax,(%esp)
80101dd5:	e8 3d e4 ff ff       	call   80100217 <brelse>
}
80101dda:	c9                   	leave  
80101ddb:	c3                   	ret    

80101ddc <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
80101ddc:	55                   	push   %ebp
80101ddd:	89 e5                	mov    %esp,%ebp
80101ddf:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
80101de2:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101de9:	e8 2d 34 00 00       	call   8010521b <acquire>

  // Is the inode already cached?
  empty = 0;
80101dee:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101df5:	c7 45 f4 f4 f7 10 80 	movl   $0x8010f7f4,-0xc(%ebp)
80101dfc:	eb 59                	jmp    80101e57 <iget+0x7b>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
80101dfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e01:	8b 40 08             	mov    0x8(%eax),%eax
80101e04:	85 c0                	test   %eax,%eax
80101e06:	7e 35                	jle    80101e3d <iget+0x61>
80101e08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e0b:	8b 00                	mov    (%eax),%eax
80101e0d:	3b 45 08             	cmp    0x8(%ebp),%eax
80101e10:	75 2b                	jne    80101e3d <iget+0x61>
80101e12:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e15:	8b 40 04             	mov    0x4(%eax),%eax
80101e18:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101e1b:	75 20                	jne    80101e3d <iget+0x61>
      ip->ref++;
80101e1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e20:	8b 40 08             	mov    0x8(%eax),%eax
80101e23:	8d 50 01             	lea    0x1(%eax),%edx
80101e26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e29:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101e2c:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101e33:	e8 45 34 00 00       	call   8010527d <release>
      return ip;
80101e38:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e3b:	eb 6f                	jmp    80101eac <iget+0xd0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
80101e3d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e41:	75 10                	jne    80101e53 <iget+0x77>
80101e43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e46:	8b 40 08             	mov    0x8(%eax),%eax
80101e49:	85 c0                	test   %eax,%eax
80101e4b:	75 06                	jne    80101e53 <iget+0x77>
      empty = ip;
80101e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e50:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101e53:	83 45 f4 50          	addl   $0x50,-0xc(%ebp)
80101e57:	81 7d f4 94 07 11 80 	cmpl   $0x80110794,-0xc(%ebp)
80101e5e:	72 9e                	jb     80101dfe <iget+0x22>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101e60:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101e64:	75 0c                	jne    80101e72 <iget+0x96>
    panic("iget: no inodes");
80101e66:	c7 04 24 b7 89 10 80 	movl   $0x801089b7,(%esp)
80101e6d:	e8 cb e6 ff ff       	call   8010053d <panic>

  ip = empty;
80101e72:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e75:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
80101e78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e7b:	8b 55 08             	mov    0x8(%ebp),%edx
80101e7e:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
80101e80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e83:	8b 55 0c             	mov    0xc(%ebp),%edx
80101e86:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
80101e89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e8c:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->flags = 0;
80101e93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101e96:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  release(&icache.lock);
80101e9d:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101ea4:	e8 d4 33 00 00       	call   8010527d <release>

  return ip;
80101ea9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80101eac:	c9                   	leave  
80101ead:	c3                   	ret    

80101eae <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
80101eae:	55                   	push   %ebp
80101eaf:	89 e5                	mov    %esp,%ebp
80101eb1:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80101eb4:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101ebb:	e8 5b 33 00 00       	call   8010521b <acquire>
  ip->ref++;
80101ec0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec3:	8b 40 08             	mov    0x8(%eax),%eax
80101ec6:	8d 50 01             	lea    0x1(%eax),%edx
80101ec9:	8b 45 08             	mov    0x8(%ebp),%eax
80101ecc:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101ecf:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101ed6:	e8 a2 33 00 00       	call   8010527d <release>
  return ip;
80101edb:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101ede:	c9                   	leave  
80101edf:	c3                   	ret    

80101ee0 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101ee0:	55                   	push   %ebp
80101ee1:	89 e5                	mov    %esp,%ebp
80101ee3:	83 ec 28             	sub    $0x28,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101ee6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101eea:	74 0a                	je     80101ef6 <ilock+0x16>
80101eec:	8b 45 08             	mov    0x8(%ebp),%eax
80101eef:	8b 40 08             	mov    0x8(%eax),%eax
80101ef2:	85 c0                	test   %eax,%eax
80101ef4:	7f 0c                	jg     80101f02 <ilock+0x22>
    panic("ilock");
80101ef6:	c7 04 24 c7 89 10 80 	movl   $0x801089c7,(%esp)
80101efd:	e8 3b e6 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
80101f02:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101f09:	e8 0d 33 00 00       	call   8010521b <acquire>
  while(ip->flags & I_BUSY)
80101f0e:	eb 13                	jmp    80101f23 <ilock+0x43>
    sleep(ip, &icache.lock);
80101f10:	c7 44 24 04 c0 f7 10 	movl   $0x8010f7c0,0x4(%esp)
80101f17:	80 
80101f18:	8b 45 08             	mov    0x8(%ebp),%eax
80101f1b:	89 04 24             	mov    %eax,(%esp)
80101f1e:	e8 1a 30 00 00       	call   80104f3d <sleep>

  if(ip == 0 || ip->ref < 1)
    panic("ilock");

  acquire(&icache.lock);
  while(ip->flags & I_BUSY)
80101f23:	8b 45 08             	mov    0x8(%ebp),%eax
80101f26:	8b 40 0c             	mov    0xc(%eax),%eax
80101f29:	83 e0 01             	and    $0x1,%eax
80101f2c:	84 c0                	test   %al,%al
80101f2e:	75 e0                	jne    80101f10 <ilock+0x30>
    sleep(ip, &icache.lock);
  ip->flags |= I_BUSY;
80101f30:	8b 45 08             	mov    0x8(%ebp),%eax
80101f33:	8b 40 0c             	mov    0xc(%eax),%eax
80101f36:	89 c2                	mov    %eax,%edx
80101f38:	83 ca 01             	or     $0x1,%edx
80101f3b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f3e:	89 50 0c             	mov    %edx,0xc(%eax)
  release(&icache.lock);
80101f41:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80101f48:	e8 30 33 00 00       	call   8010527d <release>

  if(!(ip->flags & I_VALID)){
80101f4d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f50:	8b 40 0c             	mov    0xc(%eax),%eax
80101f53:	83 e0 02             	and    $0x2,%eax
80101f56:	85 c0                	test   %eax,%eax
80101f58:	0f 85 ce 00 00 00    	jne    8010202c <ilock+0x14c>
    bp = bread(ip->dev, IBLOCK(ip->inum));
80101f5e:	8b 45 08             	mov    0x8(%ebp),%eax
80101f61:	8b 40 04             	mov    0x4(%eax),%eax
80101f64:	c1 e8 03             	shr    $0x3,%eax
80101f67:	8d 50 02             	lea    0x2(%eax),%edx
80101f6a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f6d:	8b 00                	mov    (%eax),%eax
80101f6f:	89 54 24 04          	mov    %edx,0x4(%esp)
80101f73:	89 04 24             	mov    %eax,(%esp)
80101f76:	e8 2b e2 ff ff       	call   801001a6 <bread>
80101f7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101f7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101f81:	8d 50 18             	lea    0x18(%eax),%edx
80101f84:	8b 45 08             	mov    0x8(%ebp),%eax
80101f87:	8b 40 04             	mov    0x4(%eax),%eax
80101f8a:	83 e0 07             	and    $0x7,%eax
80101f8d:	c1 e0 06             	shl    $0x6,%eax
80101f90:	01 d0                	add    %edx,%eax
80101f92:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101f95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101f98:	0f b7 10             	movzwl (%eax),%edx
80101f9b:	8b 45 08             	mov    0x8(%ebp),%eax
80101f9e:	66 89 50 10          	mov    %dx,0x10(%eax)
    ip->major = dip->major;
80101fa2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fa5:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101fa9:	8b 45 08             	mov    0x8(%ebp),%eax
80101fac:	66 89 50 12          	mov    %dx,0x12(%eax)
    ip->minor = dip->minor;
80101fb0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fb3:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101fb7:	8b 45 08             	mov    0x8(%ebp),%eax
80101fba:	66 89 50 14          	mov    %dx,0x14(%eax)
    ip->nlink = dip->nlink;
80101fbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fc1:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101fc5:	8b 45 08             	mov    0x8(%ebp),%eax
80101fc8:	66 89 50 16          	mov    %dx,0x16(%eax)
    ip->size = dip->size;
80101fcc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fcf:	8b 50 08             	mov    0x8(%eax),%edx
80101fd2:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd5:	89 50 18             	mov    %edx,0x18(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101fd8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101fdb:	8d 50 0c             	lea    0xc(%eax),%edx
80101fde:	8b 45 08             	mov    0x8(%ebp),%eax
80101fe1:	83 c0 1c             	add    $0x1c,%eax
80101fe4:	c7 44 24 08 34 00 00 	movl   $0x34,0x8(%esp)
80101feb:	00 
80101fec:	89 54 24 04          	mov    %edx,0x4(%esp)
80101ff0:	89 04 24             	mov    %eax,(%esp)
80101ff3:	e8 45 35 00 00       	call   8010553d <memmove>
    brelse(bp);
80101ff8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101ffb:	89 04 24             	mov    %eax,(%esp)
80101ffe:	e8 14 e2 ff ff       	call   80100217 <brelse>
    ip->flags |= I_VALID;
80102003:	8b 45 08             	mov    0x8(%ebp),%eax
80102006:	8b 40 0c             	mov    0xc(%eax),%eax
80102009:	89 c2                	mov    %eax,%edx
8010200b:	83 ca 02             	or     $0x2,%edx
8010200e:	8b 45 08             	mov    0x8(%ebp),%eax
80102011:	89 50 0c             	mov    %edx,0xc(%eax)
    if(ip->type == 0)
80102014:	8b 45 08             	mov    0x8(%ebp),%eax
80102017:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010201b:	66 85 c0             	test   %ax,%ax
8010201e:	75 0c                	jne    8010202c <ilock+0x14c>
      panic("ilock: no type");
80102020:	c7 04 24 cd 89 10 80 	movl   $0x801089cd,(%esp)
80102027:	e8 11 e5 ff ff       	call   8010053d <panic>
  }
}
8010202c:	c9                   	leave  
8010202d:	c3                   	ret    

8010202e <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
8010202e:	55                   	push   %ebp
8010202f:	89 e5                	mov    %esp,%ebp
80102031:	83 ec 18             	sub    $0x18,%esp
  if(ip == 0 || !(ip->flags & I_BUSY) || ip->ref < 1)
80102034:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102038:	74 17                	je     80102051 <iunlock+0x23>
8010203a:	8b 45 08             	mov    0x8(%ebp),%eax
8010203d:	8b 40 0c             	mov    0xc(%eax),%eax
80102040:	83 e0 01             	and    $0x1,%eax
80102043:	85 c0                	test   %eax,%eax
80102045:	74 0a                	je     80102051 <iunlock+0x23>
80102047:	8b 45 08             	mov    0x8(%ebp),%eax
8010204a:	8b 40 08             	mov    0x8(%eax),%eax
8010204d:	85 c0                	test   %eax,%eax
8010204f:	7f 0c                	jg     8010205d <iunlock+0x2f>
    panic("iunlock");
80102051:	c7 04 24 dc 89 10 80 	movl   $0x801089dc,(%esp)
80102058:	e8 e0 e4 ff ff       	call   8010053d <panic>

  acquire(&icache.lock);
8010205d:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80102064:	e8 b2 31 00 00       	call   8010521b <acquire>
  ip->flags &= ~I_BUSY;
80102069:	8b 45 08             	mov    0x8(%ebp),%eax
8010206c:	8b 40 0c             	mov    0xc(%eax),%eax
8010206f:	89 c2                	mov    %eax,%edx
80102071:	83 e2 fe             	and    $0xfffffffe,%edx
80102074:	8b 45 08             	mov    0x8(%ebp),%eax
80102077:	89 50 0c             	mov    %edx,0xc(%eax)
  wakeup(ip);
8010207a:	8b 45 08             	mov    0x8(%ebp),%eax
8010207d:	89 04 24             	mov    %eax,(%esp)
80102080:	e8 91 2f 00 00       	call   80105016 <wakeup>
  release(&icache.lock);
80102085:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
8010208c:	e8 ec 31 00 00       	call   8010527d <release>
}
80102091:	c9                   	leave  
80102092:	c3                   	ret    

80102093 <iput>:
// be recycled.
// If that was the last reference and the inode has no links
// to it, free the inode (and its content) on disk.
void
iput(struct inode *ip)
{
80102093:	55                   	push   %ebp
80102094:	89 e5                	mov    %esp,%ebp
80102096:	83 ec 18             	sub    $0x18,%esp
  acquire(&icache.lock);
80102099:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
801020a0:	e8 76 31 00 00       	call   8010521b <acquire>
  if(ip->ref == 1 && (ip->flags & I_VALID) && ip->nlink == 0){
801020a5:	8b 45 08             	mov    0x8(%ebp),%eax
801020a8:	8b 40 08             	mov    0x8(%eax),%eax
801020ab:	83 f8 01             	cmp    $0x1,%eax
801020ae:	0f 85 93 00 00 00    	jne    80102147 <iput+0xb4>
801020b4:	8b 45 08             	mov    0x8(%ebp),%eax
801020b7:	8b 40 0c             	mov    0xc(%eax),%eax
801020ba:	83 e0 02             	and    $0x2,%eax
801020bd:	85 c0                	test   %eax,%eax
801020bf:	0f 84 82 00 00 00    	je     80102147 <iput+0xb4>
801020c5:	8b 45 08             	mov    0x8(%ebp),%eax
801020c8:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801020cc:	66 85 c0             	test   %ax,%ax
801020cf:	75 76                	jne    80102147 <iput+0xb4>
    // inode has no links: truncate and free inode.
    if(ip->flags & I_BUSY)
801020d1:	8b 45 08             	mov    0x8(%ebp),%eax
801020d4:	8b 40 0c             	mov    0xc(%eax),%eax
801020d7:	83 e0 01             	and    $0x1,%eax
801020da:	84 c0                	test   %al,%al
801020dc:	74 0c                	je     801020ea <iput+0x57>
      panic("iput busy");
801020de:	c7 04 24 e4 89 10 80 	movl   $0x801089e4,(%esp)
801020e5:	e8 53 e4 ff ff       	call   8010053d <panic>
    ip->flags |= I_BUSY;
801020ea:	8b 45 08             	mov    0x8(%ebp),%eax
801020ed:	8b 40 0c             	mov    0xc(%eax),%eax
801020f0:	89 c2                	mov    %eax,%edx
801020f2:	83 ca 01             	or     $0x1,%edx
801020f5:	8b 45 08             	mov    0x8(%ebp),%eax
801020f8:	89 50 0c             	mov    %edx,0xc(%eax)
    release(&icache.lock);
801020fb:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
80102102:	e8 76 31 00 00       	call   8010527d <release>
    itrunc(ip);
80102107:	8b 45 08             	mov    0x8(%ebp),%eax
8010210a:	89 04 24             	mov    %eax,(%esp)
8010210d:	e8 72 01 00 00       	call   80102284 <itrunc>
    ip->type = 0;
80102112:	8b 45 08             	mov    0x8(%ebp),%eax
80102115:	66 c7 40 10 00 00    	movw   $0x0,0x10(%eax)
    iupdate(ip);
8010211b:	8b 45 08             	mov    0x8(%ebp),%eax
8010211e:	89 04 24             	mov    %eax,(%esp)
80102121:	e8 fe fb ff ff       	call   80101d24 <iupdate>
    acquire(&icache.lock);
80102126:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
8010212d:	e8 e9 30 00 00       	call   8010521b <acquire>
    ip->flags = 0;
80102132:	8b 45 08             	mov    0x8(%ebp),%eax
80102135:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    wakeup(ip);
8010213c:	8b 45 08             	mov    0x8(%ebp),%eax
8010213f:	89 04 24             	mov    %eax,(%esp)
80102142:	e8 cf 2e 00 00       	call   80105016 <wakeup>
  }
  ip->ref--;
80102147:	8b 45 08             	mov    0x8(%ebp),%eax
8010214a:	8b 40 08             	mov    0x8(%eax),%eax
8010214d:	8d 50 ff             	lea    -0x1(%eax),%edx
80102150:	8b 45 08             	mov    0x8(%ebp),%eax
80102153:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80102156:	c7 04 24 c0 f7 10 80 	movl   $0x8010f7c0,(%esp)
8010215d:	e8 1b 31 00 00       	call   8010527d <release>
}
80102162:	c9                   	leave  
80102163:	c3                   	ret    

80102164 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80102164:	55                   	push   %ebp
80102165:	89 e5                	mov    %esp,%ebp
80102167:	83 ec 18             	sub    $0x18,%esp
  iunlock(ip);
8010216a:	8b 45 08             	mov    0x8(%ebp),%eax
8010216d:	89 04 24             	mov    %eax,(%esp)
80102170:	e8 b9 fe ff ff       	call   8010202e <iunlock>
  iput(ip);
80102175:	8b 45 08             	mov    0x8(%ebp),%eax
80102178:	89 04 24             	mov    %eax,(%esp)
8010217b:	e8 13 ff ff ff       	call   80102093 <iput>
}
80102180:	c9                   	leave  
80102181:	c3                   	ret    

80102182 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80102182:	55                   	push   %ebp
80102183:	89 e5                	mov    %esp,%ebp
80102185:	53                   	push   %ebx
80102186:	83 ec 24             	sub    $0x24,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80102189:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
8010218d:	77 3e                	ja     801021cd <bmap+0x4b>
    if((addr = ip->addrs[bn]) == 0)
8010218f:	8b 45 08             	mov    0x8(%ebp),%eax
80102192:	8b 55 0c             	mov    0xc(%ebp),%edx
80102195:	83 c2 04             	add    $0x4,%edx
80102198:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
8010219c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010219f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801021a3:	75 20                	jne    801021c5 <bmap+0x43>
      ip->addrs[bn] = addr = balloc(ip->dev);
801021a5:	8b 45 08             	mov    0x8(%ebp),%eax
801021a8:	8b 00                	mov    (%eax),%eax
801021aa:	89 04 24             	mov    %eax,(%esp)
801021ad:	e8 49 f8 ff ff       	call   801019fb <balloc>
801021b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021b5:	8b 45 08             	mov    0x8(%ebp),%eax
801021b8:	8b 55 0c             	mov    0xc(%ebp),%edx
801021bb:	8d 4a 04             	lea    0x4(%edx),%ecx
801021be:	8b 55 f4             	mov    -0xc(%ebp),%edx
801021c1:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
801021c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021c8:	e9 b1 00 00 00       	jmp    8010227e <bmap+0xfc>
  }
  bn -= NDIRECT;
801021cd:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
801021d1:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
801021d5:	0f 87 97 00 00 00    	ja     80102272 <bmap+0xf0>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
801021db:	8b 45 08             	mov    0x8(%ebp),%eax
801021de:	8b 40 4c             	mov    0x4c(%eax),%eax
801021e1:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021e4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801021e8:	75 19                	jne    80102203 <bmap+0x81>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
801021ea:	8b 45 08             	mov    0x8(%ebp),%eax
801021ed:	8b 00                	mov    (%eax),%eax
801021ef:	89 04 24             	mov    %eax,(%esp)
801021f2:	e8 04 f8 ff ff       	call   801019fb <balloc>
801021f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
801021fa:	8b 45 08             	mov    0x8(%ebp),%eax
801021fd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102200:	89 50 4c             	mov    %edx,0x4c(%eax)
    bp = bread(ip->dev, addr);
80102203:	8b 45 08             	mov    0x8(%ebp),%eax
80102206:	8b 00                	mov    (%eax),%eax
80102208:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010220b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010220f:	89 04 24             	mov    %eax,(%esp)
80102212:	e8 8f df ff ff       	call   801001a6 <bread>
80102217:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
8010221a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010221d:	83 c0 18             	add    $0x18,%eax
80102220:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80102223:	8b 45 0c             	mov    0xc(%ebp),%eax
80102226:	c1 e0 02             	shl    $0x2,%eax
80102229:	03 45 ec             	add    -0x14(%ebp),%eax
8010222c:	8b 00                	mov    (%eax),%eax
8010222e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102231:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102235:	75 2b                	jne    80102262 <bmap+0xe0>
      a[bn] = addr = balloc(ip->dev);
80102237:	8b 45 0c             	mov    0xc(%ebp),%eax
8010223a:	c1 e0 02             	shl    $0x2,%eax
8010223d:	89 c3                	mov    %eax,%ebx
8010223f:	03 5d ec             	add    -0x14(%ebp),%ebx
80102242:	8b 45 08             	mov    0x8(%ebp),%eax
80102245:	8b 00                	mov    (%eax),%eax
80102247:	89 04 24             	mov    %eax,(%esp)
8010224a:	e8 ac f7 ff ff       	call   801019fb <balloc>
8010224f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102252:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102255:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80102257:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010225a:	89 04 24             	mov    %eax,(%esp)
8010225d:	e8 d4 16 00 00       	call   80103936 <log_write>
    }
    brelse(bp);
80102262:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102265:	89 04 24             	mov    %eax,(%esp)
80102268:	e8 aa df ff ff       	call   80100217 <brelse>
    return addr;
8010226d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102270:	eb 0c                	jmp    8010227e <bmap+0xfc>
  }

  panic("bmap: out of range");
80102272:	c7 04 24 ee 89 10 80 	movl   $0x801089ee,(%esp)
80102279:	e8 bf e2 ff ff       	call   8010053d <panic>
}
8010227e:	83 c4 24             	add    $0x24,%esp
80102281:	5b                   	pop    %ebx
80102282:	5d                   	pop    %ebp
80102283:	c3                   	ret    

80102284 <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80102284:	55                   	push   %ebp
80102285:	89 e5                	mov    %esp,%ebp
80102287:	83 ec 28             	sub    $0x28,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
8010228a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102291:	eb 44                	jmp    801022d7 <itrunc+0x53>
    if(ip->addrs[i]){
80102293:	8b 45 08             	mov    0x8(%ebp),%eax
80102296:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102299:	83 c2 04             	add    $0x4,%edx
8010229c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
801022a0:	85 c0                	test   %eax,%eax
801022a2:	74 2f                	je     801022d3 <itrunc+0x4f>
      bfree(ip->dev, ip->addrs[i]);
801022a4:	8b 45 08             	mov    0x8(%ebp),%eax
801022a7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022aa:	83 c2 04             	add    $0x4,%edx
801022ad:	8b 54 90 0c          	mov    0xc(%eax,%edx,4),%edx
801022b1:	8b 45 08             	mov    0x8(%ebp),%eax
801022b4:	8b 00                	mov    (%eax),%eax
801022b6:	89 54 24 04          	mov    %edx,0x4(%esp)
801022ba:	89 04 24             	mov    %eax,(%esp)
801022bd:	e8 90 f8 ff ff       	call   80101b52 <bfree>
      ip->addrs[i] = 0;
801022c2:	8b 45 08             	mov    0x8(%ebp),%eax
801022c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801022c8:	83 c2 04             	add    $0x4,%edx
801022cb:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
801022d2:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
801022d3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801022d7:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
801022db:	7e b6                	jle    80102293 <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }
  
  if(ip->addrs[NDIRECT]){
801022dd:	8b 45 08             	mov    0x8(%ebp),%eax
801022e0:	8b 40 4c             	mov    0x4c(%eax),%eax
801022e3:	85 c0                	test   %eax,%eax
801022e5:	0f 84 8f 00 00 00    	je     8010237a <itrunc+0xf6>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
801022eb:	8b 45 08             	mov    0x8(%ebp),%eax
801022ee:	8b 50 4c             	mov    0x4c(%eax),%edx
801022f1:	8b 45 08             	mov    0x8(%ebp),%eax
801022f4:	8b 00                	mov    (%eax),%eax
801022f6:	89 54 24 04          	mov    %edx,0x4(%esp)
801022fa:	89 04 24             	mov    %eax,(%esp)
801022fd:	e8 a4 de ff ff       	call   801001a6 <bread>
80102302:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80102305:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102308:	83 c0 18             	add    $0x18,%eax
8010230b:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
8010230e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80102315:	eb 2f                	jmp    80102346 <itrunc+0xc2>
      if(a[j])
80102317:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010231a:	c1 e0 02             	shl    $0x2,%eax
8010231d:	03 45 e8             	add    -0x18(%ebp),%eax
80102320:	8b 00                	mov    (%eax),%eax
80102322:	85 c0                	test   %eax,%eax
80102324:	74 1c                	je     80102342 <itrunc+0xbe>
        bfree(ip->dev, a[j]);
80102326:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102329:	c1 e0 02             	shl    $0x2,%eax
8010232c:	03 45 e8             	add    -0x18(%ebp),%eax
8010232f:	8b 10                	mov    (%eax),%edx
80102331:	8b 45 08             	mov    0x8(%ebp),%eax
80102334:	8b 00                	mov    (%eax),%eax
80102336:	89 54 24 04          	mov    %edx,0x4(%esp)
8010233a:	89 04 24             	mov    %eax,(%esp)
8010233d:	e8 10 f8 ff ff       	call   80101b52 <bfree>
  }
  
  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80102342:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80102346:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102349:	83 f8 7f             	cmp    $0x7f,%eax
8010234c:	76 c9                	jbe    80102317 <itrunc+0x93>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
8010234e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102351:	89 04 24             	mov    %eax,(%esp)
80102354:	e8 be de ff ff       	call   80100217 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
80102359:	8b 45 08             	mov    0x8(%ebp),%eax
8010235c:	8b 50 4c             	mov    0x4c(%eax),%edx
8010235f:	8b 45 08             	mov    0x8(%ebp),%eax
80102362:	8b 00                	mov    (%eax),%eax
80102364:	89 54 24 04          	mov    %edx,0x4(%esp)
80102368:	89 04 24             	mov    %eax,(%esp)
8010236b:	e8 e2 f7 ff ff       	call   80101b52 <bfree>
    ip->addrs[NDIRECT] = 0;
80102370:	8b 45 08             	mov    0x8(%ebp),%eax
80102373:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  }

  ip->size = 0;
8010237a:	8b 45 08             	mov    0x8(%ebp),%eax
8010237d:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
  iupdate(ip);
80102384:	8b 45 08             	mov    0x8(%ebp),%eax
80102387:	89 04 24             	mov    %eax,(%esp)
8010238a:	e8 95 f9 ff ff       	call   80101d24 <iupdate>
}
8010238f:	c9                   	leave  
80102390:	c3                   	ret    

80102391 <stati>:

// Copy stat information from inode.
void
stati(struct inode *ip, struct stat *st)
{
80102391:	55                   	push   %ebp
80102392:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80102394:	8b 45 08             	mov    0x8(%ebp),%eax
80102397:	8b 00                	mov    (%eax),%eax
80102399:	89 c2                	mov    %eax,%edx
8010239b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010239e:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
801023a1:	8b 45 08             	mov    0x8(%ebp),%eax
801023a4:	8b 50 04             	mov    0x4(%eax),%edx
801023a7:	8b 45 0c             	mov    0xc(%ebp),%eax
801023aa:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
801023ad:	8b 45 08             	mov    0x8(%ebp),%eax
801023b0:	0f b7 50 10          	movzwl 0x10(%eax),%edx
801023b4:	8b 45 0c             	mov    0xc(%ebp),%eax
801023b7:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
801023ba:	8b 45 08             	mov    0x8(%ebp),%eax
801023bd:	0f b7 50 16          	movzwl 0x16(%eax),%edx
801023c1:	8b 45 0c             	mov    0xc(%ebp),%eax
801023c4:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
801023c8:	8b 45 08             	mov    0x8(%ebp),%eax
801023cb:	8b 50 18             	mov    0x18(%eax),%edx
801023ce:	8b 45 0c             	mov    0xc(%ebp),%eax
801023d1:	89 50 10             	mov    %edx,0x10(%eax)
}
801023d4:	5d                   	pop    %ebp
801023d5:	c3                   	ret    

801023d6 <readi>:

//PAGEBREAK!
// Read data from inode.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
801023d6:	55                   	push   %ebp
801023d7:	89 e5                	mov    %esp,%ebp
801023d9:	53                   	push   %ebx
801023da:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
801023dd:	8b 45 08             	mov    0x8(%ebp),%eax
801023e0:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801023e4:	66 83 f8 03          	cmp    $0x3,%ax
801023e8:	75 60                	jne    8010244a <readi+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
801023ea:	8b 45 08             	mov    0x8(%ebp),%eax
801023ed:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801023f1:	66 85 c0             	test   %ax,%ax
801023f4:	78 20                	js     80102416 <readi+0x40>
801023f6:	8b 45 08             	mov    0x8(%ebp),%eax
801023f9:	0f b7 40 12          	movzwl 0x12(%eax),%eax
801023fd:	66 83 f8 09          	cmp    $0x9,%ax
80102401:	7f 13                	jg     80102416 <readi+0x40>
80102403:	8b 45 08             	mov    0x8(%ebp),%eax
80102406:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010240a:	98                   	cwtl   
8010240b:	8b 04 c5 60 f7 10 80 	mov    -0x7fef08a0(,%eax,8),%eax
80102412:	85 c0                	test   %eax,%eax
80102414:	75 0a                	jne    80102420 <readi+0x4a>
      return -1;
80102416:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010241b:	e9 1b 01 00 00       	jmp    8010253b <readi+0x165>
    return devsw[ip->major].read(ip, dst, n);
80102420:	8b 45 08             	mov    0x8(%ebp),%eax
80102423:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102427:	98                   	cwtl   
80102428:	8b 14 c5 60 f7 10 80 	mov    -0x7fef08a0(,%eax,8),%edx
8010242f:	8b 45 14             	mov    0x14(%ebp),%eax
80102432:	89 44 24 08          	mov    %eax,0x8(%esp)
80102436:	8b 45 0c             	mov    0xc(%ebp),%eax
80102439:	89 44 24 04          	mov    %eax,0x4(%esp)
8010243d:	8b 45 08             	mov    0x8(%ebp),%eax
80102440:	89 04 24             	mov    %eax,(%esp)
80102443:	ff d2                	call   *%edx
80102445:	e9 f1 00 00 00       	jmp    8010253b <readi+0x165>
  }

  if(off > ip->size || off + n < off)
8010244a:	8b 45 08             	mov    0x8(%ebp),%eax
8010244d:	8b 40 18             	mov    0x18(%eax),%eax
80102450:	3b 45 10             	cmp    0x10(%ebp),%eax
80102453:	72 0d                	jb     80102462 <readi+0x8c>
80102455:	8b 45 14             	mov    0x14(%ebp),%eax
80102458:	8b 55 10             	mov    0x10(%ebp),%edx
8010245b:	01 d0                	add    %edx,%eax
8010245d:	3b 45 10             	cmp    0x10(%ebp),%eax
80102460:	73 0a                	jae    8010246c <readi+0x96>
    return -1;
80102462:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102467:	e9 cf 00 00 00       	jmp    8010253b <readi+0x165>
  if(off + n > ip->size)
8010246c:	8b 45 14             	mov    0x14(%ebp),%eax
8010246f:	8b 55 10             	mov    0x10(%ebp),%edx
80102472:	01 c2                	add    %eax,%edx
80102474:	8b 45 08             	mov    0x8(%ebp),%eax
80102477:	8b 40 18             	mov    0x18(%eax),%eax
8010247a:	39 c2                	cmp    %eax,%edx
8010247c:	76 0c                	jbe    8010248a <readi+0xb4>
    n = ip->size - off;
8010247e:	8b 45 08             	mov    0x8(%ebp),%eax
80102481:	8b 40 18             	mov    0x18(%eax),%eax
80102484:	2b 45 10             	sub    0x10(%ebp),%eax
80102487:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010248a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102491:	e9 96 00 00 00       	jmp    8010252c <readi+0x156>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80102496:	8b 45 10             	mov    0x10(%ebp),%eax
80102499:	c1 e8 09             	shr    $0x9,%eax
8010249c:	89 44 24 04          	mov    %eax,0x4(%esp)
801024a0:	8b 45 08             	mov    0x8(%ebp),%eax
801024a3:	89 04 24             	mov    %eax,(%esp)
801024a6:	e8 d7 fc ff ff       	call   80102182 <bmap>
801024ab:	8b 55 08             	mov    0x8(%ebp),%edx
801024ae:	8b 12                	mov    (%edx),%edx
801024b0:	89 44 24 04          	mov    %eax,0x4(%esp)
801024b4:	89 14 24             	mov    %edx,(%esp)
801024b7:	e8 ea dc ff ff       	call   801001a6 <bread>
801024bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
801024bf:	8b 45 10             	mov    0x10(%ebp),%eax
801024c2:	89 c2                	mov    %eax,%edx
801024c4:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
801024ca:	b8 00 02 00 00       	mov    $0x200,%eax
801024cf:	89 c1                	mov    %eax,%ecx
801024d1:	29 d1                	sub    %edx,%ecx
801024d3:	89 ca                	mov    %ecx,%edx
801024d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024d8:	8b 4d 14             	mov    0x14(%ebp),%ecx
801024db:	89 cb                	mov    %ecx,%ebx
801024dd:	29 c3                	sub    %eax,%ebx
801024df:	89 d8                	mov    %ebx,%eax
801024e1:	39 c2                	cmp    %eax,%edx
801024e3:	0f 46 c2             	cmovbe %edx,%eax
801024e6:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
801024e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801024ec:	8d 50 18             	lea    0x18(%eax),%edx
801024ef:	8b 45 10             	mov    0x10(%ebp),%eax
801024f2:	25 ff 01 00 00       	and    $0x1ff,%eax
801024f7:	01 c2                	add    %eax,%edx
801024f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801024fc:	89 44 24 08          	mov    %eax,0x8(%esp)
80102500:	89 54 24 04          	mov    %edx,0x4(%esp)
80102504:	8b 45 0c             	mov    0xc(%ebp),%eax
80102507:	89 04 24             	mov    %eax,(%esp)
8010250a:	e8 2e 30 00 00       	call   8010553d <memmove>
    brelse(bp);
8010250f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102512:	89 04 24             	mov    %eax,(%esp)
80102515:	e8 fd dc ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
8010251a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010251d:	01 45 f4             	add    %eax,-0xc(%ebp)
80102520:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102523:	01 45 10             	add    %eax,0x10(%ebp)
80102526:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102529:	01 45 0c             	add    %eax,0xc(%ebp)
8010252c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010252f:	3b 45 14             	cmp    0x14(%ebp),%eax
80102532:	0f 82 5e ff ff ff    	jb     80102496 <readi+0xc0>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102538:	8b 45 14             	mov    0x14(%ebp),%eax
}
8010253b:	83 c4 24             	add    $0x24,%esp
8010253e:	5b                   	pop    %ebx
8010253f:	5d                   	pop    %ebp
80102540:	c3                   	ret    

80102541 <writei>:

// PAGEBREAK!
// Write data to inode.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102541:	55                   	push   %ebp
80102542:	89 e5                	mov    %esp,%ebp
80102544:	53                   	push   %ebx
80102545:	83 ec 24             	sub    $0x24,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80102548:	8b 45 08             	mov    0x8(%ebp),%eax
8010254b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010254f:	66 83 f8 03          	cmp    $0x3,%ax
80102553:	75 60                	jne    801025b5 <writei+0x74>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
80102555:	8b 45 08             	mov    0x8(%ebp),%eax
80102558:	0f b7 40 12          	movzwl 0x12(%eax),%eax
8010255c:	66 85 c0             	test   %ax,%ax
8010255f:	78 20                	js     80102581 <writei+0x40>
80102561:	8b 45 08             	mov    0x8(%ebp),%eax
80102564:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102568:	66 83 f8 09          	cmp    $0x9,%ax
8010256c:	7f 13                	jg     80102581 <writei+0x40>
8010256e:	8b 45 08             	mov    0x8(%ebp),%eax
80102571:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102575:	98                   	cwtl   
80102576:	8b 04 c5 64 f7 10 80 	mov    -0x7fef089c(,%eax,8),%eax
8010257d:	85 c0                	test   %eax,%eax
8010257f:	75 0a                	jne    8010258b <writei+0x4a>
      return -1;
80102581:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102586:	e9 46 01 00 00       	jmp    801026d1 <writei+0x190>
    return devsw[ip->major].write(ip, src, n);
8010258b:	8b 45 08             	mov    0x8(%ebp),%eax
8010258e:	0f b7 40 12          	movzwl 0x12(%eax),%eax
80102592:	98                   	cwtl   
80102593:	8b 14 c5 64 f7 10 80 	mov    -0x7fef089c(,%eax,8),%edx
8010259a:	8b 45 14             	mov    0x14(%ebp),%eax
8010259d:	89 44 24 08          	mov    %eax,0x8(%esp)
801025a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801025a4:	89 44 24 04          	mov    %eax,0x4(%esp)
801025a8:	8b 45 08             	mov    0x8(%ebp),%eax
801025ab:	89 04 24             	mov    %eax,(%esp)
801025ae:	ff d2                	call   *%edx
801025b0:	e9 1c 01 00 00       	jmp    801026d1 <writei+0x190>
  }

  if(off > ip->size || off + n < off)
801025b5:	8b 45 08             	mov    0x8(%ebp),%eax
801025b8:	8b 40 18             	mov    0x18(%eax),%eax
801025bb:	3b 45 10             	cmp    0x10(%ebp),%eax
801025be:	72 0d                	jb     801025cd <writei+0x8c>
801025c0:	8b 45 14             	mov    0x14(%ebp),%eax
801025c3:	8b 55 10             	mov    0x10(%ebp),%edx
801025c6:	01 d0                	add    %edx,%eax
801025c8:	3b 45 10             	cmp    0x10(%ebp),%eax
801025cb:	73 0a                	jae    801025d7 <writei+0x96>
    return -1;
801025cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025d2:	e9 fa 00 00 00       	jmp    801026d1 <writei+0x190>
  if(off + n > MAXFILE*BSIZE)
801025d7:	8b 45 14             	mov    0x14(%ebp),%eax
801025da:	8b 55 10             	mov    0x10(%ebp),%edx
801025dd:	01 d0                	add    %edx,%eax
801025df:	3d 00 18 01 00       	cmp    $0x11800,%eax
801025e4:	76 0a                	jbe    801025f0 <writei+0xaf>
    return -1;
801025e6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801025eb:	e9 e1 00 00 00       	jmp    801026d1 <writei+0x190>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
801025f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801025f7:	e9 a1 00 00 00       	jmp    8010269d <writei+0x15c>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
801025fc:	8b 45 10             	mov    0x10(%ebp),%eax
801025ff:	c1 e8 09             	shr    $0x9,%eax
80102602:	89 44 24 04          	mov    %eax,0x4(%esp)
80102606:	8b 45 08             	mov    0x8(%ebp),%eax
80102609:	89 04 24             	mov    %eax,(%esp)
8010260c:	e8 71 fb ff ff       	call   80102182 <bmap>
80102611:	8b 55 08             	mov    0x8(%ebp),%edx
80102614:	8b 12                	mov    (%edx),%edx
80102616:	89 44 24 04          	mov    %eax,0x4(%esp)
8010261a:	89 14 24             	mov    %edx,(%esp)
8010261d:	e8 84 db ff ff       	call   801001a6 <bread>
80102622:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80102625:	8b 45 10             	mov    0x10(%ebp),%eax
80102628:	89 c2                	mov    %eax,%edx
8010262a:	81 e2 ff 01 00 00    	and    $0x1ff,%edx
80102630:	b8 00 02 00 00       	mov    $0x200,%eax
80102635:	89 c1                	mov    %eax,%ecx
80102637:	29 d1                	sub    %edx,%ecx
80102639:	89 ca                	mov    %ecx,%edx
8010263b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010263e:	8b 4d 14             	mov    0x14(%ebp),%ecx
80102641:	89 cb                	mov    %ecx,%ebx
80102643:	29 c3                	sub    %eax,%ebx
80102645:	89 d8                	mov    %ebx,%eax
80102647:	39 c2                	cmp    %eax,%edx
80102649:	0f 46 c2             	cmovbe %edx,%eax
8010264c:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
8010264f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102652:	8d 50 18             	lea    0x18(%eax),%edx
80102655:	8b 45 10             	mov    0x10(%ebp),%eax
80102658:	25 ff 01 00 00       	and    $0x1ff,%eax
8010265d:	01 c2                	add    %eax,%edx
8010265f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102662:	89 44 24 08          	mov    %eax,0x8(%esp)
80102666:	8b 45 0c             	mov    0xc(%ebp),%eax
80102669:	89 44 24 04          	mov    %eax,0x4(%esp)
8010266d:	89 14 24             	mov    %edx,(%esp)
80102670:	e8 c8 2e 00 00       	call   8010553d <memmove>
    log_write(bp);
80102675:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102678:	89 04 24             	mov    %eax,(%esp)
8010267b:	e8 b6 12 00 00       	call   80103936 <log_write>
    brelse(bp);
80102680:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102683:	89 04 24             	mov    %eax,(%esp)
80102686:	e8 8c db ff ff       	call   80100217 <brelse>
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
8010268b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010268e:	01 45 f4             	add    %eax,-0xc(%ebp)
80102691:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102694:	01 45 10             	add    %eax,0x10(%ebp)
80102697:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010269a:	01 45 0c             	add    %eax,0xc(%ebp)
8010269d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801026a0:	3b 45 14             	cmp    0x14(%ebp),%eax
801026a3:	0f 82 53 ff ff ff    	jb     801025fc <writei+0xbb>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801026a9:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801026ad:	74 1f                	je     801026ce <writei+0x18d>
801026af:	8b 45 08             	mov    0x8(%ebp),%eax
801026b2:	8b 40 18             	mov    0x18(%eax),%eax
801026b5:	3b 45 10             	cmp    0x10(%ebp),%eax
801026b8:	73 14                	jae    801026ce <writei+0x18d>
    ip->size = off;
801026ba:	8b 45 08             	mov    0x8(%ebp),%eax
801026bd:	8b 55 10             	mov    0x10(%ebp),%edx
801026c0:	89 50 18             	mov    %edx,0x18(%eax)
    iupdate(ip);
801026c3:	8b 45 08             	mov    0x8(%ebp),%eax
801026c6:	89 04 24             	mov    %eax,(%esp)
801026c9:	e8 56 f6 ff ff       	call   80101d24 <iupdate>
  }
  return n;
801026ce:	8b 45 14             	mov    0x14(%ebp),%eax
}
801026d1:	83 c4 24             	add    $0x24,%esp
801026d4:	5b                   	pop    %ebx
801026d5:	5d                   	pop    %ebp
801026d6:	c3                   	ret    

801026d7 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801026d7:	55                   	push   %ebp
801026d8:	89 e5                	mov    %esp,%ebp
801026da:	83 ec 18             	sub    $0x18,%esp
  return strncmp(s, t, DIRSIZ);
801026dd:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
801026e4:	00 
801026e5:	8b 45 0c             	mov    0xc(%ebp),%eax
801026e8:	89 44 24 04          	mov    %eax,0x4(%esp)
801026ec:	8b 45 08             	mov    0x8(%ebp),%eax
801026ef:	89 04 24             	mov    %eax,(%esp)
801026f2:	e8 ea 2e 00 00       	call   801055e1 <strncmp>
}
801026f7:	c9                   	leave  
801026f8:	c3                   	ret    

801026f9 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801026f9:	55                   	push   %ebp
801026fa:	89 e5                	mov    %esp,%ebp
801026fc:	83 ec 38             	sub    $0x38,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
801026ff:	8b 45 08             	mov    0x8(%ebp),%eax
80102702:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80102706:	66 83 f8 01          	cmp    $0x1,%ax
8010270a:	74 0c                	je     80102718 <dirlookup+0x1f>
    panic("dirlookup not DIR");
8010270c:	c7 04 24 01 8a 10 80 	movl   $0x80108a01,(%esp)
80102713:	e8 25 de ff ff       	call   8010053d <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
80102718:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010271f:	e9 87 00 00 00       	jmp    801027ab <dirlookup+0xb2>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102724:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010272b:	00 
8010272c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010272f:	89 44 24 08          	mov    %eax,0x8(%esp)
80102733:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102736:	89 44 24 04          	mov    %eax,0x4(%esp)
8010273a:	8b 45 08             	mov    0x8(%ebp),%eax
8010273d:	89 04 24             	mov    %eax,(%esp)
80102740:	e8 91 fc ff ff       	call   801023d6 <readi>
80102745:	83 f8 10             	cmp    $0x10,%eax
80102748:	74 0c                	je     80102756 <dirlookup+0x5d>
      panic("dirlink read");
8010274a:	c7 04 24 13 8a 10 80 	movl   $0x80108a13,(%esp)
80102751:	e8 e7 dd ff ff       	call   8010053d <panic>
    if(de.inum == 0)
80102756:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010275a:	66 85 c0             	test   %ax,%ax
8010275d:	74 47                	je     801027a6 <dirlookup+0xad>
      continue;
    if(namecmp(name, de.name) == 0){
8010275f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102762:	83 c0 02             	add    $0x2,%eax
80102765:	89 44 24 04          	mov    %eax,0x4(%esp)
80102769:	8b 45 0c             	mov    0xc(%ebp),%eax
8010276c:	89 04 24             	mov    %eax,(%esp)
8010276f:	e8 63 ff ff ff       	call   801026d7 <namecmp>
80102774:	85 c0                	test   %eax,%eax
80102776:	75 2f                	jne    801027a7 <dirlookup+0xae>
      // entry matches path element
      if(poff)
80102778:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010277c:	74 08                	je     80102786 <dirlookup+0x8d>
        *poff = off;
8010277e:	8b 45 10             	mov    0x10(%ebp),%eax
80102781:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102784:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
80102786:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010278a:	0f b7 c0             	movzwl %ax,%eax
8010278d:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102790:	8b 45 08             	mov    0x8(%ebp),%eax
80102793:	8b 00                	mov    (%eax),%eax
80102795:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102798:	89 54 24 04          	mov    %edx,0x4(%esp)
8010279c:	89 04 24             	mov    %eax,(%esp)
8010279f:	e8 38 f6 ff ff       	call   80101ddc <iget>
801027a4:	eb 19                	jmp    801027bf <dirlookup+0xc6>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      continue;
801027a6:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
801027a7:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
801027ab:	8b 45 08             	mov    0x8(%ebp),%eax
801027ae:	8b 40 18             	mov    0x18(%eax),%eax
801027b1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801027b4:	0f 87 6a ff ff ff    	ja     80102724 <dirlookup+0x2b>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801027ba:	b8 00 00 00 00       	mov    $0x0,%eax
}
801027bf:	c9                   	leave  
801027c0:	c3                   	ret    

801027c1 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801027c1:	55                   	push   %ebp
801027c2:	89 e5                	mov    %esp,%ebp
801027c4:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801027c7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801027ce:	00 
801027cf:	8b 45 0c             	mov    0xc(%ebp),%eax
801027d2:	89 44 24 04          	mov    %eax,0x4(%esp)
801027d6:	8b 45 08             	mov    0x8(%ebp),%eax
801027d9:	89 04 24             	mov    %eax,(%esp)
801027dc:	e8 18 ff ff ff       	call   801026f9 <dirlookup>
801027e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
801027e4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801027e8:	74 15                	je     801027ff <dirlink+0x3e>
    iput(ip);
801027ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027ed:	89 04 24             	mov    %eax,(%esp)
801027f0:	e8 9e f8 ff ff       	call   80102093 <iput>
    return -1;
801027f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801027fa:	e9 b8 00 00 00       	jmp    801028b7 <dirlink+0xf6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801027ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102806:	eb 44                	jmp    8010284c <dirlink+0x8b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102808:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010280b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80102812:	00 
80102813:	89 44 24 08          	mov    %eax,0x8(%esp)
80102817:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010281a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010281e:	8b 45 08             	mov    0x8(%ebp),%eax
80102821:	89 04 24             	mov    %eax,(%esp)
80102824:	e8 ad fb ff ff       	call   801023d6 <readi>
80102829:	83 f8 10             	cmp    $0x10,%eax
8010282c:	74 0c                	je     8010283a <dirlink+0x79>
      panic("dirlink read");
8010282e:	c7 04 24 13 8a 10 80 	movl   $0x80108a13,(%esp)
80102835:	e8 03 dd ff ff       	call   8010053d <panic>
    if(de.inum == 0)
8010283a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010283e:	66 85 c0             	test   %ax,%ax
80102841:	74 18                	je     8010285b <dirlink+0x9a>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102843:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102846:	83 c0 10             	add    $0x10,%eax
80102849:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010284c:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010284f:	8b 45 08             	mov    0x8(%ebp),%eax
80102852:	8b 40 18             	mov    0x18(%eax),%eax
80102855:	39 c2                	cmp    %eax,%edx
80102857:	72 af                	jb     80102808 <dirlink+0x47>
80102859:	eb 01                	jmp    8010285c <dirlink+0x9b>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
8010285b:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
8010285c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
80102863:	00 
80102864:	8b 45 0c             	mov    0xc(%ebp),%eax
80102867:	89 44 24 04          	mov    %eax,0x4(%esp)
8010286b:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010286e:	83 c0 02             	add    $0x2,%eax
80102871:	89 04 24             	mov    %eax,(%esp)
80102874:	e8 c0 2d 00 00       	call   80105639 <strncpy>
  de.inum = inum;
80102879:	8b 45 10             	mov    0x10(%ebp),%eax
8010287c:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102880:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102883:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
8010288a:	00 
8010288b:	89 44 24 08          	mov    %eax,0x8(%esp)
8010288f:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102892:	89 44 24 04          	mov    %eax,0x4(%esp)
80102896:	8b 45 08             	mov    0x8(%ebp),%eax
80102899:	89 04 24             	mov    %eax,(%esp)
8010289c:	e8 a0 fc ff ff       	call   80102541 <writei>
801028a1:	83 f8 10             	cmp    $0x10,%eax
801028a4:	74 0c                	je     801028b2 <dirlink+0xf1>
    panic("dirlink");
801028a6:	c7 04 24 20 8a 10 80 	movl   $0x80108a20,(%esp)
801028ad:	e8 8b dc ff ff       	call   8010053d <panic>
  
  return 0;
801028b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801028b7:	c9                   	leave  
801028b8:	c3                   	ret    

801028b9 <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
801028b9:	55                   	push   %ebp
801028ba:	89 e5                	mov    %esp,%ebp
801028bc:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int len;

  while(*path == '/')
801028bf:	eb 04                	jmp    801028c5 <skipelem+0xc>
    path++;
801028c1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
801028c5:	8b 45 08             	mov    0x8(%ebp),%eax
801028c8:	0f b6 00             	movzbl (%eax),%eax
801028cb:	3c 2f                	cmp    $0x2f,%al
801028cd:	74 f2                	je     801028c1 <skipelem+0x8>
    path++;
  if(*path == 0)
801028cf:	8b 45 08             	mov    0x8(%ebp),%eax
801028d2:	0f b6 00             	movzbl (%eax),%eax
801028d5:	84 c0                	test   %al,%al
801028d7:	75 0a                	jne    801028e3 <skipelem+0x2a>
    return 0;
801028d9:	b8 00 00 00 00       	mov    $0x0,%eax
801028de:	e9 86 00 00 00       	jmp    80102969 <skipelem+0xb0>
  s = path;
801028e3:	8b 45 08             	mov    0x8(%ebp),%eax
801028e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801028e9:	eb 04                	jmp    801028ef <skipelem+0x36>
    path++;
801028eb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801028ef:	8b 45 08             	mov    0x8(%ebp),%eax
801028f2:	0f b6 00             	movzbl (%eax),%eax
801028f5:	3c 2f                	cmp    $0x2f,%al
801028f7:	74 0a                	je     80102903 <skipelem+0x4a>
801028f9:	8b 45 08             	mov    0x8(%ebp),%eax
801028fc:	0f b6 00             	movzbl (%eax),%eax
801028ff:	84 c0                	test   %al,%al
80102901:	75 e8                	jne    801028eb <skipelem+0x32>
    path++;
  len = path - s;
80102903:	8b 55 08             	mov    0x8(%ebp),%edx
80102906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102909:	89 d1                	mov    %edx,%ecx
8010290b:	29 c1                	sub    %eax,%ecx
8010290d:	89 c8                	mov    %ecx,%eax
8010290f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
80102912:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80102916:	7e 1c                	jle    80102934 <skipelem+0x7b>
    memmove(name, s, DIRSIZ);
80102918:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
8010291f:	00 
80102920:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102923:	89 44 24 04          	mov    %eax,0x4(%esp)
80102927:	8b 45 0c             	mov    0xc(%ebp),%eax
8010292a:	89 04 24             	mov    %eax,(%esp)
8010292d:	e8 0b 2c 00 00       	call   8010553d <memmove>
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102932:	eb 28                	jmp    8010295c <skipelem+0xa3>
    path++;
  len = path - s;
  if(len >= DIRSIZ)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
80102934:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102937:	89 44 24 08          	mov    %eax,0x8(%esp)
8010293b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010293e:	89 44 24 04          	mov    %eax,0x4(%esp)
80102942:	8b 45 0c             	mov    0xc(%ebp),%eax
80102945:	89 04 24             	mov    %eax,(%esp)
80102948:	e8 f0 2b 00 00       	call   8010553d <memmove>
    name[len] = 0;
8010294d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102950:	03 45 0c             	add    0xc(%ebp),%eax
80102953:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
80102956:	eb 04                	jmp    8010295c <skipelem+0xa3>
    path++;
80102958:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
8010295c:	8b 45 08             	mov    0x8(%ebp),%eax
8010295f:	0f b6 00             	movzbl (%eax),%eax
80102962:	3c 2f                	cmp    $0x2f,%al
80102964:	74 f2                	je     80102958 <skipelem+0x9f>
    path++;
  return path;
80102966:	8b 45 08             	mov    0x8(%ebp),%eax
}
80102969:	c9                   	leave  
8010296a:	c3                   	ret    

8010296b <namex>:
// Look up and return the inode for a path name.
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
static struct inode*
namex(char *path, int nameiparent, char *name)
{
8010296b:	55                   	push   %ebp
8010296c:	89 e5                	mov    %esp,%ebp
8010296e:	83 ec 28             	sub    $0x28,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102971:	8b 45 08             	mov    0x8(%ebp),%eax
80102974:	0f b6 00             	movzbl (%eax),%eax
80102977:	3c 2f                	cmp    $0x2f,%al
80102979:	75 1c                	jne    80102997 <namex+0x2c>
    ip = iget(ROOTDEV, ROOTINO);
8010297b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102982:	00 
80102983:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
8010298a:	e8 4d f4 ff ff       	call   80101ddc <iget>
8010298f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102992:	e9 af 00 00 00       	jmp    80102a46 <namex+0xdb>
  struct inode *ip, *next;

  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);
80102997:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010299d:	8b 40 68             	mov    0x68(%eax),%eax
801029a0:	89 04 24             	mov    %eax,(%esp)
801029a3:	e8 06 f5 ff ff       	call   80101eae <idup>
801029a8:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
801029ab:	e9 96 00 00 00       	jmp    80102a46 <namex+0xdb>
    ilock(ip);
801029b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029b3:	89 04 24             	mov    %eax,(%esp)
801029b6:	e8 25 f5 ff ff       	call   80101ee0 <ilock>
    if(ip->type != T_DIR){
801029bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029be:	0f b7 40 10          	movzwl 0x10(%eax),%eax
801029c2:	66 83 f8 01          	cmp    $0x1,%ax
801029c6:	74 15                	je     801029dd <namex+0x72>
      iunlockput(ip);
801029c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029cb:	89 04 24             	mov    %eax,(%esp)
801029ce:	e8 91 f7 ff ff       	call   80102164 <iunlockput>
      return 0;
801029d3:	b8 00 00 00 00       	mov    $0x0,%eax
801029d8:	e9 a3 00 00 00       	jmp    80102a80 <namex+0x115>
    }
    if(nameiparent && *path == '\0'){
801029dd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801029e1:	74 1d                	je     80102a00 <namex+0x95>
801029e3:	8b 45 08             	mov    0x8(%ebp),%eax
801029e6:	0f b6 00             	movzbl (%eax),%eax
801029e9:	84 c0                	test   %al,%al
801029eb:	75 13                	jne    80102a00 <namex+0x95>
      // Stop one level early.
      iunlock(ip);
801029ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f0:	89 04 24             	mov    %eax,(%esp)
801029f3:	e8 36 f6 ff ff       	call   8010202e <iunlock>
      return ip;
801029f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029fb:	e9 80 00 00 00       	jmp    80102a80 <namex+0x115>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
80102a00:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80102a07:	00 
80102a08:	8b 45 10             	mov    0x10(%ebp),%eax
80102a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a12:	89 04 24             	mov    %eax,(%esp)
80102a15:	e8 df fc ff ff       	call   801026f9 <dirlookup>
80102a1a:	89 45 f0             	mov    %eax,-0x10(%ebp)
80102a1d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80102a21:	75 12                	jne    80102a35 <namex+0xca>
      iunlockput(ip);
80102a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a26:	89 04 24             	mov    %eax,(%esp)
80102a29:	e8 36 f7 ff ff       	call   80102164 <iunlockput>
      return 0;
80102a2e:	b8 00 00 00 00       	mov    $0x0,%eax
80102a33:	eb 4b                	jmp    80102a80 <namex+0x115>
    }
    iunlockput(ip);
80102a35:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a38:	89 04 24             	mov    %eax,(%esp)
80102a3b:	e8 24 f7 ff ff       	call   80102164 <iunlockput>
    ip = next;
80102a40:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102a43:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(proc->cwd);

  while((path = skipelem(path, name)) != 0){
80102a46:	8b 45 10             	mov    0x10(%ebp),%eax
80102a49:	89 44 24 04          	mov    %eax,0x4(%esp)
80102a4d:	8b 45 08             	mov    0x8(%ebp),%eax
80102a50:	89 04 24             	mov    %eax,(%esp)
80102a53:	e8 61 fe ff ff       	call   801028b9 <skipelem>
80102a58:	89 45 08             	mov    %eax,0x8(%ebp)
80102a5b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102a5f:	0f 85 4b ff ff ff    	jne    801029b0 <namex+0x45>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102a65:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102a69:	74 12                	je     80102a7d <namex+0x112>
    iput(ip);
80102a6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102a6e:	89 04 24             	mov    %eax,(%esp)
80102a71:	e8 1d f6 ff ff       	call   80102093 <iput>
    return 0;
80102a76:	b8 00 00 00 00       	mov    $0x0,%eax
80102a7b:	eb 03                	jmp    80102a80 <namex+0x115>
  }
  return ip;
80102a7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102a80:	c9                   	leave  
80102a81:	c3                   	ret    

80102a82 <namei>:

struct inode*
namei(char *path)
{
80102a82:	55                   	push   %ebp
80102a83:	89 e5                	mov    %esp,%ebp
80102a85:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102a88:	8d 45 ea             	lea    -0x16(%ebp),%eax
80102a8b:	89 44 24 08          	mov    %eax,0x8(%esp)
80102a8f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102a96:	00 
80102a97:	8b 45 08             	mov    0x8(%ebp),%eax
80102a9a:	89 04 24             	mov    %eax,(%esp)
80102a9d:	e8 c9 fe ff ff       	call   8010296b <namex>
}
80102aa2:	c9                   	leave  
80102aa3:	c3                   	ret    

80102aa4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
80102aa4:	55                   	push   %ebp
80102aa5:	89 e5                	mov    %esp,%ebp
80102aa7:	83 ec 18             	sub    $0x18,%esp
  return namex(path, 1, name);
80102aaa:	8b 45 0c             	mov    0xc(%ebp),%eax
80102aad:	89 44 24 08          	mov    %eax,0x8(%esp)
80102ab1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102ab8:	00 
80102ab9:	8b 45 08             	mov    0x8(%ebp),%eax
80102abc:	89 04 24             	mov    %eax,(%esp)
80102abf:	e8 a7 fe ff ff       	call   8010296b <namex>
}
80102ac4:	c9                   	leave  
80102ac5:	c3                   	ret    
	...

80102ac8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102ac8:	55                   	push   %ebp
80102ac9:	89 e5                	mov    %esp,%ebp
80102acb:	53                   	push   %ebx
80102acc:	83 ec 14             	sub    $0x14,%esp
80102acf:	8b 45 08             	mov    0x8(%ebp),%eax
80102ad2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102ad6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80102ada:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80102ade:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80102ae2:	ec                   	in     (%dx),%al
80102ae3:	89 c3                	mov    %eax,%ebx
80102ae5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80102ae8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80102aec:	83 c4 14             	add    $0x14,%esp
80102aef:	5b                   	pop    %ebx
80102af0:	5d                   	pop    %ebp
80102af1:	c3                   	ret    

80102af2 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
80102af2:	55                   	push   %ebp
80102af3:	89 e5                	mov    %esp,%ebp
80102af5:	57                   	push   %edi
80102af6:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
80102af7:	8b 55 08             	mov    0x8(%ebp),%edx
80102afa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102afd:	8b 45 10             	mov    0x10(%ebp),%eax
80102b00:	89 cb                	mov    %ecx,%ebx
80102b02:	89 df                	mov    %ebx,%edi
80102b04:	89 c1                	mov    %eax,%ecx
80102b06:	fc                   	cld    
80102b07:	f3 6d                	rep insl (%dx),%es:(%edi)
80102b09:	89 c8                	mov    %ecx,%eax
80102b0b:	89 fb                	mov    %edi,%ebx
80102b0d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b10:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
80102b13:	5b                   	pop    %ebx
80102b14:	5f                   	pop    %edi
80102b15:	5d                   	pop    %ebp
80102b16:	c3                   	ret    

80102b17 <outb>:

static inline void
outb(ushort port, uchar data)
{
80102b17:	55                   	push   %ebp
80102b18:	89 e5                	mov    %esp,%ebp
80102b1a:	83 ec 08             	sub    $0x8,%esp
80102b1d:	8b 55 08             	mov    0x8(%ebp),%edx
80102b20:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b23:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102b27:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102b2a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102b2e:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102b32:	ee                   	out    %al,(%dx)
}
80102b33:	c9                   	leave  
80102b34:	c3                   	ret    

80102b35 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
80102b35:	55                   	push   %ebp
80102b36:	89 e5                	mov    %esp,%ebp
80102b38:	56                   	push   %esi
80102b39:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
80102b3a:	8b 55 08             	mov    0x8(%ebp),%edx
80102b3d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80102b40:	8b 45 10             	mov    0x10(%ebp),%eax
80102b43:	89 cb                	mov    %ecx,%ebx
80102b45:	89 de                	mov    %ebx,%esi
80102b47:	89 c1                	mov    %eax,%ecx
80102b49:	fc                   	cld    
80102b4a:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102b4c:	89 c8                	mov    %ecx,%eax
80102b4e:	89 f3                	mov    %esi,%ebx
80102b50:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102b53:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
80102b56:	5b                   	pop    %ebx
80102b57:	5e                   	pop    %esi
80102b58:	5d                   	pop    %ebp
80102b59:	c3                   	ret    

80102b5a <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
80102b5a:	55                   	push   %ebp
80102b5b:	89 e5                	mov    %esp,%ebp
80102b5d:	83 ec 14             	sub    $0x14,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY) 
80102b60:	90                   	nop
80102b61:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102b68:	e8 5b ff ff ff       	call   80102ac8 <inb>
80102b6d:	0f b6 c0             	movzbl %al,%eax
80102b70:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102b73:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102b76:	25 c0 00 00 00       	and    $0xc0,%eax
80102b7b:	83 f8 40             	cmp    $0x40,%eax
80102b7e:	75 e1                	jne    80102b61 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102b80:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102b84:	74 11                	je     80102b97 <idewait+0x3d>
80102b86:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102b89:	83 e0 21             	and    $0x21,%eax
80102b8c:	85 c0                	test   %eax,%eax
80102b8e:	74 07                	je     80102b97 <idewait+0x3d>
    return -1;
80102b90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102b95:	eb 05                	jmp    80102b9c <idewait+0x42>
  return 0;
80102b97:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102b9c:	c9                   	leave  
80102b9d:	c3                   	ret    

80102b9e <ideinit>:

void
ideinit(void)
{
80102b9e:	55                   	push   %ebp
80102b9f:	89 e5                	mov    %esp,%ebp
80102ba1:	83 ec 28             	sub    $0x28,%esp
  int i;

  initlock(&idelock, "ide");
80102ba4:	c7 44 24 04 28 8a 10 	movl   $0x80108a28,0x4(%esp)
80102bab:	80 
80102bac:	c7 04 24 20 c0 10 80 	movl   $0x8010c020,(%esp)
80102bb3:	e8 42 26 00 00       	call   801051fa <initlock>
  picenable(IRQ_IDE);
80102bb8:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102bbf:	e8 75 15 00 00       	call   80104139 <picenable>
  ioapicenable(IRQ_IDE, ncpu - 1);
80102bc4:	a1 60 0e 11 80       	mov    0x80110e60,%eax
80102bc9:	83 e8 01             	sub    $0x1,%eax
80102bcc:	89 44 24 04          	mov    %eax,0x4(%esp)
80102bd0:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
80102bd7:	e8 12 04 00 00       	call   80102fee <ioapicenable>
  idewait(0);
80102bdc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102be3:	e8 72 ff ff ff       	call   80102b5a <idewait>
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102be8:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
80102bef:	00 
80102bf0:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102bf7:	e8 1b ff ff ff       	call   80102b17 <outb>
  for(i=0; i<1000; i++){
80102bfc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102c03:	eb 20                	jmp    80102c25 <ideinit+0x87>
    if(inb(0x1f7) != 0){
80102c05:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102c0c:	e8 b7 fe ff ff       	call   80102ac8 <inb>
80102c11:	84 c0                	test   %al,%al
80102c13:	74 0c                	je     80102c21 <ideinit+0x83>
      havedisk1 = 1;
80102c15:	c7 05 58 c0 10 80 01 	movl   $0x1,0x8010c058
80102c1c:	00 00 00 
      break;
80102c1f:	eb 0d                	jmp    80102c2e <ideinit+0x90>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);
  
  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
80102c21:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102c25:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
80102c2c:	7e d7                	jle    80102c05 <ideinit+0x67>
      break;
    }
  }
  
  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
80102c2e:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
80102c35:	00 
80102c36:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102c3d:	e8 d5 fe ff ff       	call   80102b17 <outb>
}
80102c42:	c9                   	leave  
80102c43:	c3                   	ret    

80102c44 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
80102c44:	55                   	push   %ebp
80102c45:	89 e5                	mov    %esp,%ebp
80102c47:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
80102c4a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80102c4e:	75 0c                	jne    80102c5c <idestart+0x18>
    panic("idestart");
80102c50:	c7 04 24 2c 8a 10 80 	movl   $0x80108a2c,(%esp)
80102c57:	e8 e1 d8 ff ff       	call   8010053d <panic>

  idewait(0);
80102c5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102c63:	e8 f2 fe ff ff       	call   80102b5a <idewait>
  outb(0x3f6, 0);  // generate interrupt
80102c68:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102c6f:	00 
80102c70:	c7 04 24 f6 03 00 00 	movl   $0x3f6,(%esp)
80102c77:	e8 9b fe ff ff       	call   80102b17 <outb>
  outb(0x1f2, 1);  // number of sectors
80102c7c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80102c83:	00 
80102c84:	c7 04 24 f2 01 00 00 	movl   $0x1f2,(%esp)
80102c8b:	e8 87 fe ff ff       	call   80102b17 <outb>
  outb(0x1f3, b->sector & 0xff);
80102c90:	8b 45 08             	mov    0x8(%ebp),%eax
80102c93:	8b 40 08             	mov    0x8(%eax),%eax
80102c96:	0f b6 c0             	movzbl %al,%eax
80102c99:	89 44 24 04          	mov    %eax,0x4(%esp)
80102c9d:	c7 04 24 f3 01 00 00 	movl   $0x1f3,(%esp)
80102ca4:	e8 6e fe ff ff       	call   80102b17 <outb>
  outb(0x1f4, (b->sector >> 8) & 0xff);
80102ca9:	8b 45 08             	mov    0x8(%ebp),%eax
80102cac:	8b 40 08             	mov    0x8(%eax),%eax
80102caf:	c1 e8 08             	shr    $0x8,%eax
80102cb2:	0f b6 c0             	movzbl %al,%eax
80102cb5:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cb9:	c7 04 24 f4 01 00 00 	movl   $0x1f4,(%esp)
80102cc0:	e8 52 fe ff ff       	call   80102b17 <outb>
  outb(0x1f5, (b->sector >> 16) & 0xff);
80102cc5:	8b 45 08             	mov    0x8(%ebp),%eax
80102cc8:	8b 40 08             	mov    0x8(%eax),%eax
80102ccb:	c1 e8 10             	shr    $0x10,%eax
80102cce:	0f b6 c0             	movzbl %al,%eax
80102cd1:	89 44 24 04          	mov    %eax,0x4(%esp)
80102cd5:	c7 04 24 f5 01 00 00 	movl   $0x1f5,(%esp)
80102cdc:	e8 36 fe ff ff       	call   80102b17 <outb>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((b->sector>>24)&0x0f));
80102ce1:	8b 45 08             	mov    0x8(%ebp),%eax
80102ce4:	8b 40 04             	mov    0x4(%eax),%eax
80102ce7:	83 e0 01             	and    $0x1,%eax
80102cea:	89 c2                	mov    %eax,%edx
80102cec:	c1 e2 04             	shl    $0x4,%edx
80102cef:	8b 45 08             	mov    0x8(%ebp),%eax
80102cf2:	8b 40 08             	mov    0x8(%eax),%eax
80102cf5:	c1 e8 18             	shr    $0x18,%eax
80102cf8:	83 e0 0f             	and    $0xf,%eax
80102cfb:	09 d0                	or     %edx,%eax
80102cfd:	83 c8 e0             	or     $0xffffffe0,%eax
80102d00:	0f b6 c0             	movzbl %al,%eax
80102d03:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d07:	c7 04 24 f6 01 00 00 	movl   $0x1f6,(%esp)
80102d0e:	e8 04 fe ff ff       	call   80102b17 <outb>
  if(b->flags & B_DIRTY){
80102d13:	8b 45 08             	mov    0x8(%ebp),%eax
80102d16:	8b 00                	mov    (%eax),%eax
80102d18:	83 e0 04             	and    $0x4,%eax
80102d1b:	85 c0                	test   %eax,%eax
80102d1d:	74 34                	je     80102d53 <idestart+0x10f>
    outb(0x1f7, IDE_CMD_WRITE);
80102d1f:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
80102d26:	00 
80102d27:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102d2e:	e8 e4 fd ff ff       	call   80102b17 <outb>
    outsl(0x1f0, b->data, 512/4);
80102d33:	8b 45 08             	mov    0x8(%ebp),%eax
80102d36:	83 c0 18             	add    $0x18,%eax
80102d39:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102d40:	00 
80102d41:	89 44 24 04          	mov    %eax,0x4(%esp)
80102d45:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102d4c:	e8 e4 fd ff ff       	call   80102b35 <outsl>
80102d51:	eb 14                	jmp    80102d67 <idestart+0x123>
  } else {
    outb(0x1f7, IDE_CMD_READ);
80102d53:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
80102d5a:	00 
80102d5b:	c7 04 24 f7 01 00 00 	movl   $0x1f7,(%esp)
80102d62:	e8 b0 fd ff ff       	call   80102b17 <outb>
  }
}
80102d67:	c9                   	leave  
80102d68:	c3                   	ret    

80102d69 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102d69:	55                   	push   %ebp
80102d6a:	89 e5                	mov    %esp,%ebp
80102d6c:	83 ec 28             	sub    $0x28,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
80102d6f:	c7 04 24 20 c0 10 80 	movl   $0x8010c020,(%esp)
80102d76:	e8 a0 24 00 00       	call   8010521b <acquire>
  if((b = idequeue) == 0){
80102d7b:	a1 54 c0 10 80       	mov    0x8010c054,%eax
80102d80:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102d83:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102d87:	75 11                	jne    80102d9a <ideintr+0x31>
    release(&idelock);
80102d89:	c7 04 24 20 c0 10 80 	movl   $0x8010c020,(%esp)
80102d90:	e8 e8 24 00 00       	call   8010527d <release>
    // cprintf("spurious IDE interrupt\n");
    return;
80102d95:	e9 90 00 00 00       	jmp    80102e2a <ideintr+0xc1>
  }
  idequeue = b->qnext;
80102d9a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d9d:	8b 40 14             	mov    0x14(%eax),%eax
80102da0:	a3 54 c0 10 80       	mov    %eax,0x8010c054

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
80102da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102da8:	8b 00                	mov    (%eax),%eax
80102daa:	83 e0 04             	and    $0x4,%eax
80102dad:	85 c0                	test   %eax,%eax
80102daf:	75 2e                	jne    80102ddf <ideintr+0x76>
80102db1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102db8:	e8 9d fd ff ff       	call   80102b5a <idewait>
80102dbd:	85 c0                	test   %eax,%eax
80102dbf:	78 1e                	js     80102ddf <ideintr+0x76>
    insl(0x1f0, b->data, 512/4);
80102dc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dc4:	83 c0 18             	add    $0x18,%eax
80102dc7:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80102dce:	00 
80102dcf:	89 44 24 04          	mov    %eax,0x4(%esp)
80102dd3:	c7 04 24 f0 01 00 00 	movl   $0x1f0,(%esp)
80102dda:	e8 13 fd ff ff       	call   80102af2 <insl>
  
  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102ddf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102de2:	8b 00                	mov    (%eax),%eax
80102de4:	89 c2                	mov    %eax,%edx
80102de6:	83 ca 02             	or     $0x2,%edx
80102de9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dec:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102dee:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102df1:	8b 00                	mov    (%eax),%eax
80102df3:	89 c2                	mov    %eax,%edx
80102df5:	83 e2 fb             	and    $0xfffffffb,%edx
80102df8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102dfb:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102dfd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102e00:	89 04 24             	mov    %eax,(%esp)
80102e03:	e8 0e 22 00 00       	call   80105016 <wakeup>
  
  // Start disk on next buf in queue.
  if(idequeue != 0)
80102e08:	a1 54 c0 10 80       	mov    0x8010c054,%eax
80102e0d:	85 c0                	test   %eax,%eax
80102e0f:	74 0d                	je     80102e1e <ideintr+0xb5>
    idestart(idequeue);
80102e11:	a1 54 c0 10 80       	mov    0x8010c054,%eax
80102e16:	89 04 24             	mov    %eax,(%esp)
80102e19:	e8 26 fe ff ff       	call   80102c44 <idestart>

  release(&idelock);
80102e1e:	c7 04 24 20 c0 10 80 	movl   $0x8010c020,(%esp)
80102e25:	e8 53 24 00 00       	call   8010527d <release>
}
80102e2a:	c9                   	leave  
80102e2b:	c3                   	ret    

80102e2c <iderw>:
// Sync buf with disk. 
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
80102e2c:	55                   	push   %ebp
80102e2d:	89 e5                	mov    %esp,%ebp
80102e2f:	83 ec 28             	sub    $0x28,%esp
  struct buf **pp;

  if(!(b->flags & B_BUSY))
80102e32:	8b 45 08             	mov    0x8(%ebp),%eax
80102e35:	8b 00                	mov    (%eax),%eax
80102e37:	83 e0 01             	and    $0x1,%eax
80102e3a:	85 c0                	test   %eax,%eax
80102e3c:	75 0c                	jne    80102e4a <iderw+0x1e>
    panic("iderw: buf not busy");
80102e3e:	c7 04 24 35 8a 10 80 	movl   $0x80108a35,(%esp)
80102e45:	e8 f3 d6 ff ff       	call   8010053d <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102e4a:	8b 45 08             	mov    0x8(%ebp),%eax
80102e4d:	8b 00                	mov    (%eax),%eax
80102e4f:	83 e0 06             	and    $0x6,%eax
80102e52:	83 f8 02             	cmp    $0x2,%eax
80102e55:	75 0c                	jne    80102e63 <iderw+0x37>
    panic("iderw: nothing to do");
80102e57:	c7 04 24 49 8a 10 80 	movl   $0x80108a49,(%esp)
80102e5e:	e8 da d6 ff ff       	call   8010053d <panic>
  if(b->dev != 0 && !havedisk1)
80102e63:	8b 45 08             	mov    0x8(%ebp),%eax
80102e66:	8b 40 04             	mov    0x4(%eax),%eax
80102e69:	85 c0                	test   %eax,%eax
80102e6b:	74 15                	je     80102e82 <iderw+0x56>
80102e6d:	a1 58 c0 10 80       	mov    0x8010c058,%eax
80102e72:	85 c0                	test   %eax,%eax
80102e74:	75 0c                	jne    80102e82 <iderw+0x56>
    panic("iderw: ide disk 1 not present");
80102e76:	c7 04 24 5e 8a 10 80 	movl   $0x80108a5e,(%esp)
80102e7d:	e8 bb d6 ff ff       	call   8010053d <panic>

  acquire(&idelock);  //DOC: acquire-lock
80102e82:	c7 04 24 20 c0 10 80 	movl   $0x8010c020,(%esp)
80102e89:	e8 8d 23 00 00       	call   8010521b <acquire>

  // Append b to idequeue.
  b->qnext = 0;
80102e8e:	8b 45 08             	mov    0x8(%ebp),%eax
80102e91:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC: insert-queue
80102e98:	c7 45 f4 54 c0 10 80 	movl   $0x8010c054,-0xc(%ebp)
80102e9f:	eb 0b                	jmp    80102eac <iderw+0x80>
80102ea1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102ea4:	8b 00                	mov    (%eax),%eax
80102ea6:	83 c0 14             	add    $0x14,%eax
80102ea9:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102eac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eaf:	8b 00                	mov    (%eax),%eax
80102eb1:	85 c0                	test   %eax,%eax
80102eb3:	75 ec                	jne    80102ea1 <iderw+0x75>
    ;
  *pp = b;
80102eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102eb8:	8b 55 08             	mov    0x8(%ebp),%edx
80102ebb:	89 10                	mov    %edx,(%eax)
  
  // Start disk if necessary.
  if(idequeue == b)
80102ebd:	a1 54 c0 10 80       	mov    0x8010c054,%eax
80102ec2:	3b 45 08             	cmp    0x8(%ebp),%eax
80102ec5:	75 22                	jne    80102ee9 <iderw+0xbd>
    idestart(b);
80102ec7:	8b 45 08             	mov    0x8(%ebp),%eax
80102eca:	89 04 24             	mov    %eax,(%esp)
80102ecd:	e8 72 fd ff ff       	call   80102c44 <idestart>
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102ed2:	eb 15                	jmp    80102ee9 <iderw+0xbd>
    sleep(b, &idelock);
80102ed4:	c7 44 24 04 20 c0 10 	movl   $0x8010c020,0x4(%esp)
80102edb:	80 
80102edc:	8b 45 08             	mov    0x8(%ebp),%eax
80102edf:	89 04 24             	mov    %eax,(%esp)
80102ee2:	e8 56 20 00 00       	call   80104f3d <sleep>
80102ee7:	eb 01                	jmp    80102eea <iderw+0xbe>
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);
  
  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102ee9:	90                   	nop
80102eea:	8b 45 08             	mov    0x8(%ebp),%eax
80102eed:	8b 00                	mov    (%eax),%eax
80102eef:	83 e0 06             	and    $0x6,%eax
80102ef2:	83 f8 02             	cmp    $0x2,%eax
80102ef5:	75 dd                	jne    80102ed4 <iderw+0xa8>
    sleep(b, &idelock);
  }

  release(&idelock);
80102ef7:	c7 04 24 20 c0 10 80 	movl   $0x8010c020,(%esp)
80102efe:	e8 7a 23 00 00       	call   8010527d <release>
}
80102f03:	c9                   	leave  
80102f04:	c3                   	ret    
80102f05:	00 00                	add    %al,(%eax)
	...

80102f08 <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102f08:	55                   	push   %ebp
80102f09:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f0b:	a1 94 07 11 80       	mov    0x80110794,%eax
80102f10:	8b 55 08             	mov    0x8(%ebp),%edx
80102f13:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102f15:	a1 94 07 11 80       	mov    0x80110794,%eax
80102f1a:	8b 40 10             	mov    0x10(%eax),%eax
}
80102f1d:	5d                   	pop    %ebp
80102f1e:	c3                   	ret    

80102f1f <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102f1f:	55                   	push   %ebp
80102f20:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102f22:	a1 94 07 11 80       	mov    0x80110794,%eax
80102f27:	8b 55 08             	mov    0x8(%ebp),%edx
80102f2a:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102f2c:	a1 94 07 11 80       	mov    0x80110794,%eax
80102f31:	8b 55 0c             	mov    0xc(%ebp),%edx
80102f34:	89 50 10             	mov    %edx,0x10(%eax)
}
80102f37:	5d                   	pop    %ebp
80102f38:	c3                   	ret    

80102f39 <ioapicinit>:

void
ioapicinit(void)
{
80102f39:	55                   	push   %ebp
80102f3a:	89 e5                	mov    %esp,%ebp
80102f3c:	83 ec 28             	sub    $0x28,%esp
  int i, id, maxintr;

  if(!ismp)
80102f3f:	a1 64 08 11 80       	mov    0x80110864,%eax
80102f44:	85 c0                	test   %eax,%eax
80102f46:	0f 84 9f 00 00 00    	je     80102feb <ioapicinit+0xb2>
    return;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102f4c:	c7 05 94 07 11 80 00 	movl   $0xfec00000,0x80110794
80102f53:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102f56:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80102f5d:	e8 a6 ff ff ff       	call   80102f08 <ioapicread>
80102f62:	c1 e8 10             	shr    $0x10,%eax
80102f65:	25 ff 00 00 00       	and    $0xff,%eax
80102f6a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102f6d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80102f74:	e8 8f ff ff ff       	call   80102f08 <ioapicread>
80102f79:	c1 e8 18             	shr    $0x18,%eax
80102f7c:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102f7f:	0f b6 05 60 08 11 80 	movzbl 0x80110860,%eax
80102f86:	0f b6 c0             	movzbl %al,%eax
80102f89:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102f8c:	74 0c                	je     80102f9a <ioapicinit+0x61>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102f8e:	c7 04 24 7c 8a 10 80 	movl   $0x80108a7c,(%esp)
80102f95:	e8 07 d4 ff ff       	call   801003a1 <cprintf>

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102f9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102fa1:	eb 3e                	jmp    80102fe1 <ioapicinit+0xa8>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102fa3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fa6:	83 c0 20             	add    $0x20,%eax
80102fa9:	0d 00 00 01 00       	or     $0x10000,%eax
80102fae:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102fb1:	83 c2 08             	add    $0x8,%edx
80102fb4:	01 d2                	add    %edx,%edx
80102fb6:	89 44 24 04          	mov    %eax,0x4(%esp)
80102fba:	89 14 24             	mov    %edx,(%esp)
80102fbd:	e8 5d ff ff ff       	call   80102f1f <ioapicwrite>
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fc5:	83 c0 08             	add    $0x8,%eax
80102fc8:	01 c0                	add    %eax,%eax
80102fca:	83 c0 01             	add    $0x1,%eax
80102fcd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80102fd4:	00 
80102fd5:	89 04 24             	mov    %eax,(%esp)
80102fd8:	e8 42 ff ff ff       	call   80102f1f <ioapicwrite>
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102fdd:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102fe1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102fe4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102fe7:	7e ba                	jle    80102fa3 <ioapicinit+0x6a>
80102fe9:	eb 01                	jmp    80102fec <ioapicinit+0xb3>
ioapicinit(void)
{
  int i, id, maxintr;

  if(!ismp)
    return;
80102feb:	90                   	nop
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102fec:	c9                   	leave  
80102fed:	c3                   	ret    

80102fee <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102fee:	55                   	push   %ebp
80102fef:	89 e5                	mov    %esp,%ebp
80102ff1:	83 ec 08             	sub    $0x8,%esp
  if(!ismp)
80102ff4:	a1 64 08 11 80       	mov    0x80110864,%eax
80102ff9:	85 c0                	test   %eax,%eax
80102ffb:	74 39                	je     80103036 <ioapicenable+0x48>
    return;

  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102ffd:	8b 45 08             	mov    0x8(%ebp),%eax
80103000:	83 c0 20             	add    $0x20,%eax
80103003:	8b 55 08             	mov    0x8(%ebp),%edx
80103006:	83 c2 08             	add    $0x8,%edx
80103009:	01 d2                	add    %edx,%edx
8010300b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010300f:	89 14 24             	mov    %edx,(%esp)
80103012:	e8 08 ff ff ff       	call   80102f1f <ioapicwrite>
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80103017:	8b 45 0c             	mov    0xc(%ebp),%eax
8010301a:	c1 e0 18             	shl    $0x18,%eax
8010301d:	8b 55 08             	mov    0x8(%ebp),%edx
80103020:	83 c2 08             	add    $0x8,%edx
80103023:	01 d2                	add    %edx,%edx
80103025:	83 c2 01             	add    $0x1,%edx
80103028:	89 44 24 04          	mov    %eax,0x4(%esp)
8010302c:	89 14 24             	mov    %edx,(%esp)
8010302f:	e8 eb fe ff ff       	call   80102f1f <ioapicwrite>
80103034:	eb 01                	jmp    80103037 <ioapicenable+0x49>

void
ioapicenable(int irq, int cpunum)
{
  if(!ismp)
    return;
80103036:	90                   	nop
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
}
80103037:	c9                   	leave  
80103038:	c3                   	ret    
80103039:	00 00                	add    %al,(%eax)
	...

8010303c <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
8010303c:	55                   	push   %ebp
8010303d:	89 e5                	mov    %esp,%ebp
8010303f:	8b 45 08             	mov    0x8(%ebp),%eax
80103042:	05 00 00 00 80       	add    $0x80000000,%eax
80103047:	5d                   	pop    %ebp
80103048:	c3                   	ret    

80103049 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80103049:	55                   	push   %ebp
8010304a:	89 e5                	mov    %esp,%ebp
8010304c:	83 ec 18             	sub    $0x18,%esp
  initlock(&kmem.lock, "kmem");
8010304f:	c7 44 24 04 ae 8a 10 	movl   $0x80108aae,0x4(%esp)
80103056:	80 
80103057:	c7 04 24 a0 07 11 80 	movl   $0x801107a0,(%esp)
8010305e:	e8 97 21 00 00       	call   801051fa <initlock>
  kmem.use_lock = 0;
80103063:	c7 05 d4 07 11 80 00 	movl   $0x0,0x801107d4
8010306a:	00 00 00 
  freerange(vstart, vend);
8010306d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103070:	89 44 24 04          	mov    %eax,0x4(%esp)
80103074:	8b 45 08             	mov    0x8(%ebp),%eax
80103077:	89 04 24             	mov    %eax,(%esp)
8010307a:	e8 26 00 00 00       	call   801030a5 <freerange>
}
8010307f:	c9                   	leave  
80103080:	c3                   	ret    

80103081 <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80103081:	55                   	push   %ebp
80103082:	89 e5                	mov    %esp,%ebp
80103084:	83 ec 18             	sub    $0x18,%esp
  freerange(vstart, vend);
80103087:	8b 45 0c             	mov    0xc(%ebp),%eax
8010308a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010308e:	8b 45 08             	mov    0x8(%ebp),%eax
80103091:	89 04 24             	mov    %eax,(%esp)
80103094:	e8 0c 00 00 00       	call   801030a5 <freerange>
  kmem.use_lock = 1;
80103099:	c7 05 d4 07 11 80 01 	movl   $0x1,0x801107d4
801030a0:	00 00 00 
}
801030a3:	c9                   	leave  
801030a4:	c3                   	ret    

801030a5 <freerange>:

void
freerange(void *vstart, void *vend)
{
801030a5:	55                   	push   %ebp
801030a6:	89 e5                	mov    %esp,%ebp
801030a8:	83 ec 28             	sub    $0x28,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
801030ab:	8b 45 08             	mov    0x8(%ebp),%eax
801030ae:	05 ff 0f 00 00       	add    $0xfff,%eax
801030b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801030b8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801030bb:	eb 12                	jmp    801030cf <freerange+0x2a>
    kfree(p);
801030bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030c0:	89 04 24             	mov    %eax,(%esp)
801030c3:	e8 16 00 00 00       	call   801030de <kfree>
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
801030c8:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801030cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801030d2:	05 00 10 00 00       	add    $0x1000,%eax
801030d7:	3b 45 0c             	cmp    0xc(%ebp),%eax
801030da:	76 e1                	jbe    801030bd <freerange+0x18>
    kfree(p);
}
801030dc:	c9                   	leave  
801030dd:	c3                   	ret    

801030de <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
801030de:	55                   	push   %ebp
801030df:	89 e5                	mov    %esp,%ebp
801030e1:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || v2p(v) >= PHYSTOP)
801030e4:	8b 45 08             	mov    0x8(%ebp),%eax
801030e7:	25 ff 0f 00 00       	and    $0xfff,%eax
801030ec:	85 c0                	test   %eax,%eax
801030ee:	75 1b                	jne    8010310b <kfree+0x2d>
801030f0:	81 7d 08 5c 36 11 80 	cmpl   $0x8011365c,0x8(%ebp)
801030f7:	72 12                	jb     8010310b <kfree+0x2d>
801030f9:	8b 45 08             	mov    0x8(%ebp),%eax
801030fc:	89 04 24             	mov    %eax,(%esp)
801030ff:	e8 38 ff ff ff       	call   8010303c <v2p>
80103104:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80103109:	76 0c                	jbe    80103117 <kfree+0x39>
    panic("kfree");
8010310b:	c7 04 24 b3 8a 10 80 	movl   $0x80108ab3,(%esp)
80103112:	e8 26 d4 ff ff       	call   8010053d <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80103117:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010311e:	00 
8010311f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103126:	00 
80103127:	8b 45 08             	mov    0x8(%ebp),%eax
8010312a:	89 04 24             	mov    %eax,(%esp)
8010312d:	e8 38 23 00 00       	call   8010546a <memset>

  if(kmem.use_lock)
80103132:	a1 d4 07 11 80       	mov    0x801107d4,%eax
80103137:	85 c0                	test   %eax,%eax
80103139:	74 0c                	je     80103147 <kfree+0x69>
    acquire(&kmem.lock);
8010313b:	c7 04 24 a0 07 11 80 	movl   $0x801107a0,(%esp)
80103142:	e8 d4 20 00 00       	call   8010521b <acquire>
  r = (struct run*)v;
80103147:	8b 45 08             	mov    0x8(%ebp),%eax
8010314a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
8010314d:	8b 15 d8 07 11 80    	mov    0x801107d8,%edx
80103153:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103156:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80103158:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010315b:	a3 d8 07 11 80       	mov    %eax,0x801107d8
  if(kmem.use_lock)
80103160:	a1 d4 07 11 80       	mov    0x801107d4,%eax
80103165:	85 c0                	test   %eax,%eax
80103167:	74 0c                	je     80103175 <kfree+0x97>
    release(&kmem.lock);
80103169:	c7 04 24 a0 07 11 80 	movl   $0x801107a0,(%esp)
80103170:	e8 08 21 00 00       	call   8010527d <release>
}
80103175:	c9                   	leave  
80103176:	c3                   	ret    

80103177 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80103177:	55                   	push   %ebp
80103178:	89 e5                	mov    %esp,%ebp
8010317a:	83 ec 28             	sub    $0x28,%esp
  struct run *r;

  if(kmem.use_lock)
8010317d:	a1 d4 07 11 80       	mov    0x801107d4,%eax
80103182:	85 c0                	test   %eax,%eax
80103184:	74 0c                	je     80103192 <kalloc+0x1b>
    acquire(&kmem.lock);
80103186:	c7 04 24 a0 07 11 80 	movl   $0x801107a0,(%esp)
8010318d:	e8 89 20 00 00       	call   8010521b <acquire>
  r = kmem.freelist;
80103192:	a1 d8 07 11 80       	mov    0x801107d8,%eax
80103197:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
8010319a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010319e:	74 0a                	je     801031aa <kalloc+0x33>
    kmem.freelist = r->next;
801031a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031a3:	8b 00                	mov    (%eax),%eax
801031a5:	a3 d8 07 11 80       	mov    %eax,0x801107d8
  if(kmem.use_lock)
801031aa:	a1 d4 07 11 80       	mov    0x801107d4,%eax
801031af:	85 c0                	test   %eax,%eax
801031b1:	74 0c                	je     801031bf <kalloc+0x48>
    release(&kmem.lock);
801031b3:	c7 04 24 a0 07 11 80 	movl   $0x801107a0,(%esp)
801031ba:	e8 be 20 00 00       	call   8010527d <release>
  return (char*)r;
801031bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801031c2:	c9                   	leave  
801031c3:	c3                   	ret    

801031c4 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
801031c4:	55                   	push   %ebp
801031c5:	89 e5                	mov    %esp,%ebp
801031c7:	53                   	push   %ebx
801031c8:	83 ec 14             	sub    $0x14,%esp
801031cb:	8b 45 08             	mov    0x8(%ebp),%eax
801031ce:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801031d2:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
801031d6:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
801031da:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
801031de:	ec                   	in     (%dx),%al
801031df:	89 c3                	mov    %eax,%ebx
801031e1:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
801031e4:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
801031e8:	83 c4 14             	add    $0x14,%esp
801031eb:	5b                   	pop    %ebx
801031ec:	5d                   	pop    %ebp
801031ed:	c3                   	ret    

801031ee <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
801031ee:	55                   	push   %ebp
801031ef:	89 e5                	mov    %esp,%ebp
801031f1:	83 ec 14             	sub    $0x14,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
801031f4:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
801031fb:	e8 c4 ff ff ff       	call   801031c4 <inb>
80103200:	0f b6 c0             	movzbl %al,%eax
80103203:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80103206:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103209:	83 e0 01             	and    $0x1,%eax
8010320c:	85 c0                	test   %eax,%eax
8010320e:	75 0a                	jne    8010321a <kbdgetc+0x2c>
    return -1;
80103210:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80103215:	e9 23 01 00 00       	jmp    8010333d <kbdgetc+0x14f>
  data = inb(KBDATAP);
8010321a:	c7 04 24 60 00 00 00 	movl   $0x60,(%esp)
80103221:	e8 9e ff ff ff       	call   801031c4 <inb>
80103226:	0f b6 c0             	movzbl %al,%eax
80103229:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
8010322c:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80103233:	75 17                	jne    8010324c <kbdgetc+0x5e>
    shift |= E0ESC;
80103235:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
8010323a:	83 c8 40             	or     $0x40,%eax
8010323d:	a3 5c c0 10 80       	mov    %eax,0x8010c05c
    return 0;
80103242:	b8 00 00 00 00       	mov    $0x0,%eax
80103247:	e9 f1 00 00 00       	jmp    8010333d <kbdgetc+0x14f>
  } else if(data & 0x80){
8010324c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010324f:	25 80 00 00 00       	and    $0x80,%eax
80103254:	85 c0                	test   %eax,%eax
80103256:	74 45                	je     8010329d <kbdgetc+0xaf>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80103258:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
8010325d:	83 e0 40             	and    $0x40,%eax
80103260:	85 c0                	test   %eax,%eax
80103262:	75 08                	jne    8010326c <kbdgetc+0x7e>
80103264:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103267:	83 e0 7f             	and    $0x7f,%eax
8010326a:	eb 03                	jmp    8010326f <kbdgetc+0x81>
8010326c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010326f:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80103272:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103275:	05 20 90 10 80       	add    $0x80109020,%eax
8010327a:	0f b6 00             	movzbl (%eax),%eax
8010327d:	83 c8 40             	or     $0x40,%eax
80103280:	0f b6 c0             	movzbl %al,%eax
80103283:	f7 d0                	not    %eax
80103285:	89 c2                	mov    %eax,%edx
80103287:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
8010328c:	21 d0                	and    %edx,%eax
8010328e:	a3 5c c0 10 80       	mov    %eax,0x8010c05c
    return 0;
80103293:	b8 00 00 00 00       	mov    $0x0,%eax
80103298:	e9 a0 00 00 00       	jmp    8010333d <kbdgetc+0x14f>
  } else if(shift & E0ESC){
8010329d:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
801032a2:	83 e0 40             	and    $0x40,%eax
801032a5:	85 c0                	test   %eax,%eax
801032a7:	74 14                	je     801032bd <kbdgetc+0xcf>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
801032a9:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
801032b0:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
801032b5:	83 e0 bf             	and    $0xffffffbf,%eax
801032b8:	a3 5c c0 10 80       	mov    %eax,0x8010c05c
  }

  shift |= shiftcode[data];
801032bd:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032c0:	05 20 90 10 80       	add    $0x80109020,%eax
801032c5:	0f b6 00             	movzbl (%eax),%eax
801032c8:	0f b6 d0             	movzbl %al,%edx
801032cb:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
801032d0:	09 d0                	or     %edx,%eax
801032d2:	a3 5c c0 10 80       	mov    %eax,0x8010c05c
  shift ^= togglecode[data];
801032d7:	8b 45 fc             	mov    -0x4(%ebp),%eax
801032da:	05 20 91 10 80       	add    $0x80109120,%eax
801032df:	0f b6 00             	movzbl (%eax),%eax
801032e2:	0f b6 d0             	movzbl %al,%edx
801032e5:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
801032ea:	31 d0                	xor    %edx,%eax
801032ec:	a3 5c c0 10 80       	mov    %eax,0x8010c05c
  c = charcode[shift & (CTL | SHIFT)][data];
801032f1:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
801032f6:	83 e0 03             	and    $0x3,%eax
801032f9:	8b 04 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%eax
80103300:	03 45 fc             	add    -0x4(%ebp),%eax
80103303:	0f b6 00             	movzbl (%eax),%eax
80103306:	0f b6 c0             	movzbl %al,%eax
80103309:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
8010330c:	a1 5c c0 10 80       	mov    0x8010c05c,%eax
80103311:	83 e0 08             	and    $0x8,%eax
80103314:	85 c0                	test   %eax,%eax
80103316:	74 22                	je     8010333a <kbdgetc+0x14c>
    if('a' <= c && c <= 'z')
80103318:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
8010331c:	76 0c                	jbe    8010332a <kbdgetc+0x13c>
8010331e:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80103322:	77 06                	ja     8010332a <kbdgetc+0x13c>
      c += 'A' - 'a';
80103324:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80103328:	eb 10                	jmp    8010333a <kbdgetc+0x14c>
    else if('A' <= c && c <= 'Z')
8010332a:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
8010332e:	76 0a                	jbe    8010333a <kbdgetc+0x14c>
80103330:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80103334:	77 04                	ja     8010333a <kbdgetc+0x14c>
      c += 'a' - 'A';
80103336:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
8010333a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
8010333d:	c9                   	leave  
8010333e:	c3                   	ret    

8010333f <kbdintr>:

void
kbdintr(void)
{
8010333f:	55                   	push   %ebp
80103340:	89 e5                	mov    %esp,%ebp
80103342:	83 ec 18             	sub    $0x18,%esp
  consoleintr(kbdgetc);
80103345:	c7 04 24 ee 31 10 80 	movl   $0x801031ee,(%esp)
8010334c:	e8 83 d4 ff ff       	call   801007d4 <consoleintr>
}
80103351:	c9                   	leave  
80103352:	c3                   	ret    
	...

80103354 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103354:	55                   	push   %ebp
80103355:	89 e5                	mov    %esp,%ebp
80103357:	83 ec 08             	sub    $0x8,%esp
8010335a:	8b 55 08             	mov    0x8(%ebp),%edx
8010335d:	8b 45 0c             	mov    0xc(%ebp),%eax
80103360:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103364:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103367:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
8010336b:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
8010336f:	ee                   	out    %al,(%dx)
}
80103370:	c9                   	leave  
80103371:	c3                   	ret    

80103372 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80103372:	55                   	push   %ebp
80103373:	89 e5                	mov    %esp,%ebp
80103375:	53                   	push   %ebx
80103376:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80103379:	9c                   	pushf  
8010337a:	5b                   	pop    %ebx
8010337b:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
8010337e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103381:	83 c4 10             	add    $0x10,%esp
80103384:	5b                   	pop    %ebx
80103385:	5d                   	pop    %ebp
80103386:	c3                   	ret    

80103387 <lapicw>:

volatile uint *lapic;  // Initialized in mp.c

static void
lapicw(int index, int value)
{
80103387:	55                   	push   %ebp
80103388:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
8010338a:	a1 dc 07 11 80       	mov    0x801107dc,%eax
8010338f:	8b 55 08             	mov    0x8(%ebp),%edx
80103392:	c1 e2 02             	shl    $0x2,%edx
80103395:	01 c2                	add    %eax,%edx
80103397:	8b 45 0c             	mov    0xc(%ebp),%eax
8010339a:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
8010339c:	a1 dc 07 11 80       	mov    0x801107dc,%eax
801033a1:	83 c0 20             	add    $0x20,%eax
801033a4:	8b 00                	mov    (%eax),%eax
}
801033a6:	5d                   	pop    %ebp
801033a7:	c3                   	ret    

801033a8 <lapicinit>:
//PAGEBREAK!

void
lapicinit(int c)
{
801033a8:	55                   	push   %ebp
801033a9:	89 e5                	mov    %esp,%ebp
801033ab:	83 ec 08             	sub    $0x8,%esp
  if(!lapic) 
801033ae:	a1 dc 07 11 80       	mov    0x801107dc,%eax
801033b3:	85 c0                	test   %eax,%eax
801033b5:	0f 84 47 01 00 00    	je     80103502 <lapicinit+0x15a>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
801033bb:	c7 44 24 04 3f 01 00 	movl   $0x13f,0x4(%esp)
801033c2:	00 
801033c3:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
801033ca:	e8 b8 ff ff ff       	call   80103387 <lapicw>

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.  
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
801033cf:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
801033d6:	00 
801033d7:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
801033de:	e8 a4 ff ff ff       	call   80103387 <lapicw>
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
801033e3:	c7 44 24 04 20 00 02 	movl   $0x20020,0x4(%esp)
801033ea:	00 
801033eb:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
801033f2:	e8 90 ff ff ff       	call   80103387 <lapicw>
  lapicw(TICR, 10000000); 
801033f7:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
801033fe:	00 
801033ff:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
80103406:	e8 7c ff ff ff       	call   80103387 <lapicw>

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
8010340b:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103412:	00 
80103413:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
8010341a:	e8 68 ff ff ff       	call   80103387 <lapicw>
  lapicw(LINT1, MASKED);
8010341f:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103426:	00 
80103427:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
8010342e:	e8 54 ff ff ff       	call   80103387 <lapicw>

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80103433:	a1 dc 07 11 80       	mov    0x801107dc,%eax
80103438:	83 c0 30             	add    $0x30,%eax
8010343b:	8b 00                	mov    (%eax),%eax
8010343d:	c1 e8 10             	shr    $0x10,%eax
80103440:	25 ff 00 00 00       	and    $0xff,%eax
80103445:	83 f8 03             	cmp    $0x3,%eax
80103448:	76 14                	jbe    8010345e <lapicinit+0xb6>
    lapicw(PCINT, MASKED);
8010344a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103451:	00 
80103452:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
80103459:	e8 29 ff ff ff       	call   80103387 <lapicw>

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
8010345e:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
80103465:	00 
80103466:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
8010346d:	e8 15 ff ff ff       	call   80103387 <lapicw>

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80103472:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103479:	00 
8010347a:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103481:	e8 01 ff ff ff       	call   80103387 <lapicw>
  lapicw(ESR, 0);
80103486:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010348d:	00 
8010348e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80103495:	e8 ed fe ff ff       	call   80103387 <lapicw>

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
8010349a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034a1:	00 
801034a2:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
801034a9:	e8 d9 fe ff ff       	call   80103387 <lapicw>

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
801034ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034b5:	00 
801034b6:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801034bd:	e8 c5 fe ff ff       	call   80103387 <lapicw>
  lapicw(ICRLO, BCAST | INIT | LEVEL);
801034c2:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
801034c9:	00 
801034ca:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
801034d1:	e8 b1 fe ff ff       	call   80103387 <lapicw>
  while(lapic[ICRLO] & DELIVS)
801034d6:	90                   	nop
801034d7:	a1 dc 07 11 80       	mov    0x801107dc,%eax
801034dc:	05 00 03 00 00       	add    $0x300,%eax
801034e1:	8b 00                	mov    (%eax),%eax
801034e3:	25 00 10 00 00       	and    $0x1000,%eax
801034e8:	85 c0                	test   %eax,%eax
801034ea:	75 eb                	jne    801034d7 <lapicinit+0x12f>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
801034ec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801034f3:	00 
801034f4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801034fb:	e8 87 fe ff ff       	call   80103387 <lapicw>
80103500:	eb 01                	jmp    80103503 <lapicinit+0x15b>

void
lapicinit(int c)
{
  if(!lapic) 
    return;
80103502:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80103503:	c9                   	leave  
80103504:	c3                   	ret    

80103505 <cpunum>:

int
cpunum(void)
{
80103505:	55                   	push   %ebp
80103506:	89 e5                	mov    %esp,%ebp
80103508:	83 ec 18             	sub    $0x18,%esp
  // Cannot call cpu when interrupts are enabled:
  // result not guaranteed to last long enough to be used!
  // Would prefer to panic but even printing is chancy here:
  // almost everything, including cprintf and panic, calls cpu,
  // often indirectly through acquire and release.
  if(readeflags()&FL_IF){
8010350b:	e8 62 fe ff ff       	call   80103372 <readeflags>
80103510:	25 00 02 00 00       	and    $0x200,%eax
80103515:	85 c0                	test   %eax,%eax
80103517:	74 29                	je     80103542 <cpunum+0x3d>
    static int n;
    if(n++ == 0)
80103519:	a1 60 c0 10 80       	mov    0x8010c060,%eax
8010351e:	85 c0                	test   %eax,%eax
80103520:	0f 94 c2             	sete   %dl
80103523:	83 c0 01             	add    $0x1,%eax
80103526:	a3 60 c0 10 80       	mov    %eax,0x8010c060
8010352b:	84 d2                	test   %dl,%dl
8010352d:	74 13                	je     80103542 <cpunum+0x3d>
      cprintf("cpu called from %x with interrupts enabled\n",
8010352f:	8b 45 04             	mov    0x4(%ebp),%eax
80103532:	89 44 24 04          	mov    %eax,0x4(%esp)
80103536:	c7 04 24 bc 8a 10 80 	movl   $0x80108abc,(%esp)
8010353d:	e8 5f ce ff ff       	call   801003a1 <cprintf>
        __builtin_return_address(0));
  }

  if(lapic)
80103542:	a1 dc 07 11 80       	mov    0x801107dc,%eax
80103547:	85 c0                	test   %eax,%eax
80103549:	74 0f                	je     8010355a <cpunum+0x55>
    return lapic[ID]>>24;
8010354b:	a1 dc 07 11 80       	mov    0x801107dc,%eax
80103550:	83 c0 20             	add    $0x20,%eax
80103553:	8b 00                	mov    (%eax),%eax
80103555:	c1 e8 18             	shr    $0x18,%eax
80103558:	eb 05                	jmp    8010355f <cpunum+0x5a>
  return 0;
8010355a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010355f:	c9                   	leave  
80103560:	c3                   	ret    

80103561 <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
80103561:	55                   	push   %ebp
80103562:	89 e5                	mov    %esp,%ebp
80103564:	83 ec 08             	sub    $0x8,%esp
  if(lapic)
80103567:	a1 dc 07 11 80       	mov    0x801107dc,%eax
8010356c:	85 c0                	test   %eax,%eax
8010356e:	74 14                	je     80103584 <lapiceoi+0x23>
    lapicw(EOI, 0);
80103570:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80103577:	00 
80103578:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
8010357f:	e8 03 fe ff ff       	call   80103387 <lapicw>
}
80103584:	c9                   	leave  
80103585:	c3                   	ret    

80103586 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103586:	55                   	push   %ebp
80103587:	89 e5                	mov    %esp,%ebp
}
80103589:	5d                   	pop    %ebp
8010358a:	c3                   	ret    

8010358b <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010358b:	55                   	push   %ebp
8010358c:	89 e5                	mov    %esp,%ebp
8010358e:	83 ec 1c             	sub    $0x1c,%esp
80103591:	8b 45 08             	mov    0x8(%ebp),%eax
80103594:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;
  
  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
80103597:	c7 44 24 04 0f 00 00 	movl   $0xf,0x4(%esp)
8010359e:	00 
8010359f:	c7 04 24 70 00 00 00 	movl   $0x70,(%esp)
801035a6:	e8 a9 fd ff ff       	call   80103354 <outb>
  outb(IO_RTC+1, 0x0A);
801035ab:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
801035b2:	00 
801035b3:	c7 04 24 71 00 00 00 	movl   $0x71,(%esp)
801035ba:	e8 95 fd ff ff       	call   80103354 <outb>
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
801035bf:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
801035c6:	8b 45 f8             	mov    -0x8(%ebp),%eax
801035c9:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
801035ce:	8b 45 f8             	mov    -0x8(%ebp),%eax
801035d1:	8d 50 02             	lea    0x2(%eax),%edx
801035d4:	8b 45 0c             	mov    0xc(%ebp),%eax
801035d7:	c1 e8 04             	shr    $0x4,%eax
801035da:	66 89 02             	mov    %ax,(%edx)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
801035dd:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801035e1:	c1 e0 18             	shl    $0x18,%eax
801035e4:	89 44 24 04          	mov    %eax,0x4(%esp)
801035e8:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
801035ef:	e8 93 fd ff ff       	call   80103387 <lapicw>
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
801035f4:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
801035fb:	00 
801035fc:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103603:	e8 7f fd ff ff       	call   80103387 <lapicw>
  microdelay(200);
80103608:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
8010360f:	e8 72 ff ff ff       	call   80103586 <microdelay>
  lapicw(ICRLO, INIT | LEVEL);
80103614:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
8010361b:	00 
8010361c:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103623:	e8 5f fd ff ff       	call   80103387 <lapicw>
  microdelay(100);    // should be 10ms, but too slow in Bochs!
80103628:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
8010362f:	e8 52 ff ff ff       	call   80103586 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103634:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
8010363b:	eb 40                	jmp    8010367d <lapicstartap+0xf2>
    lapicw(ICRHI, apicid<<24);
8010363d:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103641:	c1 e0 18             	shl    $0x18,%eax
80103644:	89 44 24 04          	mov    %eax,0x4(%esp)
80103648:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
8010364f:	e8 33 fd ff ff       	call   80103387 <lapicw>
    lapicw(ICRLO, STARTUP | (addr>>12));
80103654:	8b 45 0c             	mov    0xc(%ebp),%eax
80103657:	c1 e8 0c             	shr    $0xc,%eax
8010365a:	80 cc 06             	or     $0x6,%ah
8010365d:	89 44 24 04          	mov    %eax,0x4(%esp)
80103661:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
80103668:	e8 1a fd ff ff       	call   80103387 <lapicw>
    microdelay(200);
8010366d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
80103674:	e8 0d ff ff ff       	call   80103586 <microdelay>
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103679:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010367d:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
80103681:	7e ba                	jle    8010363d <lapicstartap+0xb2>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
80103683:	c9                   	leave  
80103684:	c3                   	ret    
80103685:	00 00                	add    %al,(%eax)
	...

80103688 <initlog>:

static void recover_from_log(void);

void
initlog(void)
{
80103688:	55                   	push   %ebp
80103689:	89 e5                	mov    %esp,%ebp
8010368b:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010368e:	c7 44 24 04 e8 8a 10 	movl   $0x80108ae8,0x4(%esp)
80103695:	80 
80103696:	c7 04 24 e0 07 11 80 	movl   $0x801107e0,(%esp)
8010369d:	e8 58 1b 00 00       	call   801051fa <initlock>
  readsb(ROOTDEV, &sb);
801036a2:	8d 45 e8             	lea    -0x18(%ebp),%eax
801036a5:	89 44 24 04          	mov    %eax,0x4(%esp)
801036a9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801036b0:	e8 af e2 ff ff       	call   80101964 <readsb>
  log.start = sb.size - sb.nlog;
801036b5:	8b 55 e8             	mov    -0x18(%ebp),%edx
801036b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036bb:	89 d1                	mov    %edx,%ecx
801036bd:	29 c1                	sub    %eax,%ecx
801036bf:	89 c8                	mov    %ecx,%eax
801036c1:	a3 14 08 11 80       	mov    %eax,0x80110814
  log.size = sb.nlog;
801036c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036c9:	a3 18 08 11 80       	mov    %eax,0x80110818
  log.dev = ROOTDEV;
801036ce:	c7 05 20 08 11 80 01 	movl   $0x1,0x80110820
801036d5:	00 00 00 
  recover_from_log();
801036d8:	e8 97 01 00 00       	call   80103874 <recover_from_log>
}
801036dd:	c9                   	leave  
801036de:	c3                   	ret    

801036df <install_trans>:

// Copy committed blocks from log to their home location
static void 
install_trans(void)
{
801036df:	55                   	push   %ebp
801036e0:	89 e5                	mov    %esp,%ebp
801036e2:	83 ec 28             	sub    $0x28,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
801036e5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801036ec:	e9 89 00 00 00       	jmp    8010377a <install_trans+0x9b>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
801036f1:	a1 14 08 11 80       	mov    0x80110814,%eax
801036f6:	03 45 f4             	add    -0xc(%ebp),%eax
801036f9:	83 c0 01             	add    $0x1,%eax
801036fc:	89 c2                	mov    %eax,%edx
801036fe:	a1 20 08 11 80       	mov    0x80110820,%eax
80103703:	89 54 24 04          	mov    %edx,0x4(%esp)
80103707:	89 04 24             	mov    %eax,(%esp)
8010370a:	e8 97 ca ff ff       	call   801001a6 <bread>
8010370f:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.sector[tail]); // read dst
80103712:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103715:	83 c0 10             	add    $0x10,%eax
80103718:	8b 04 85 e8 07 11 80 	mov    -0x7feef818(,%eax,4),%eax
8010371f:	89 c2                	mov    %eax,%edx
80103721:	a1 20 08 11 80       	mov    0x80110820,%eax
80103726:	89 54 24 04          	mov    %edx,0x4(%esp)
8010372a:	89 04 24             	mov    %eax,(%esp)
8010372d:	e8 74 ca ff ff       	call   801001a6 <bread>
80103732:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
80103735:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103738:	8d 50 18             	lea    0x18(%eax),%edx
8010373b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010373e:	83 c0 18             	add    $0x18,%eax
80103741:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
80103748:	00 
80103749:	89 54 24 04          	mov    %edx,0x4(%esp)
8010374d:	89 04 24             	mov    %eax,(%esp)
80103750:	e8 e8 1d 00 00       	call   8010553d <memmove>
    bwrite(dbuf);  // write dst to disk
80103755:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103758:	89 04 24             	mov    %eax,(%esp)
8010375b:	e8 7d ca ff ff       	call   801001dd <bwrite>
    brelse(lbuf); 
80103760:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103763:	89 04 24             	mov    %eax,(%esp)
80103766:	e8 ac ca ff ff       	call   80100217 <brelse>
    brelse(dbuf);
8010376b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010376e:	89 04 24             	mov    %eax,(%esp)
80103771:	e8 a1 ca ff ff       	call   80100217 <brelse>
static void 
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103776:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010377a:	a1 24 08 11 80       	mov    0x80110824,%eax
8010377f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103782:	0f 8f 69 ff ff ff    	jg     801036f1 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf); 
    brelse(dbuf);
  }
}
80103788:	c9                   	leave  
80103789:	c3                   	ret    

8010378a <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010378a:	55                   	push   %ebp
8010378b:	89 e5                	mov    %esp,%ebp
8010378d:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
80103790:	a1 14 08 11 80       	mov    0x80110814,%eax
80103795:	89 c2                	mov    %eax,%edx
80103797:	a1 20 08 11 80       	mov    0x80110820,%eax
8010379c:	89 54 24 04          	mov    %edx,0x4(%esp)
801037a0:	89 04 24             	mov    %eax,(%esp)
801037a3:	e8 fe c9 ff ff       	call   801001a6 <bread>
801037a8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
801037ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037ae:	83 c0 18             	add    $0x18,%eax
801037b1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
801037b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037b7:	8b 00                	mov    (%eax),%eax
801037b9:	a3 24 08 11 80       	mov    %eax,0x80110824
  for (i = 0; i < log.lh.n; i++) {
801037be:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037c5:	eb 1b                	jmp    801037e2 <read_head+0x58>
    log.lh.sector[i] = lh->sector[i];
801037c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801037ca:	8b 55 f4             	mov    -0xc(%ebp),%edx
801037cd:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
801037d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801037d4:	83 c2 10             	add    $0x10,%edx
801037d7:	89 04 95 e8 07 11 80 	mov    %eax,-0x7feef818(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
801037de:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037e2:	a1 24 08 11 80       	mov    0x80110824,%eax
801037e7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037ea:	7f db                	jg     801037c7 <read_head+0x3d>
    log.lh.sector[i] = lh->sector[i];
  }
  brelse(buf);
801037ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801037ef:	89 04 24             	mov    %eax,(%esp)
801037f2:	e8 20 ca ff ff       	call   80100217 <brelse>
}
801037f7:	c9                   	leave  
801037f8:	c3                   	ret    

801037f9 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
801037f9:	55                   	push   %ebp
801037fa:	89 e5                	mov    %esp,%ebp
801037fc:	83 ec 28             	sub    $0x28,%esp
  struct buf *buf = bread(log.dev, log.start);
801037ff:	a1 14 08 11 80       	mov    0x80110814,%eax
80103804:	89 c2                	mov    %eax,%edx
80103806:	a1 20 08 11 80       	mov    0x80110820,%eax
8010380b:	89 54 24 04          	mov    %edx,0x4(%esp)
8010380f:	89 04 24             	mov    %eax,(%esp)
80103812:	e8 8f c9 ff ff       	call   801001a6 <bread>
80103817:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
8010381a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010381d:	83 c0 18             	add    $0x18,%eax
80103820:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
80103823:	8b 15 24 08 11 80    	mov    0x80110824,%edx
80103829:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010382c:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
8010382e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103835:	eb 1b                	jmp    80103852 <write_head+0x59>
    hb->sector[i] = log.lh.sector[i];
80103837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010383a:	83 c0 10             	add    $0x10,%eax
8010383d:	8b 0c 85 e8 07 11 80 	mov    -0x7feef818(,%eax,4),%ecx
80103844:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103847:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010384a:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
8010384e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103852:	a1 24 08 11 80       	mov    0x80110824,%eax
80103857:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010385a:	7f db                	jg     80103837 <write_head+0x3e>
    hb->sector[i] = log.lh.sector[i];
  }
  bwrite(buf);
8010385c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010385f:	89 04 24             	mov    %eax,(%esp)
80103862:	e8 76 c9 ff ff       	call   801001dd <bwrite>
  brelse(buf);
80103867:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010386a:	89 04 24             	mov    %eax,(%esp)
8010386d:	e8 a5 c9 ff ff       	call   80100217 <brelse>
}
80103872:	c9                   	leave  
80103873:	c3                   	ret    

80103874 <recover_from_log>:

static void
recover_from_log(void)
{
80103874:	55                   	push   %ebp
80103875:	89 e5                	mov    %esp,%ebp
80103877:	83 ec 08             	sub    $0x8,%esp
  read_head();      
8010387a:	e8 0b ff ff ff       	call   8010378a <read_head>
  install_trans(); // if committed, copy from log to disk
8010387f:	e8 5b fe ff ff       	call   801036df <install_trans>
  log.lh.n = 0;
80103884:	c7 05 24 08 11 80 00 	movl   $0x0,0x80110824
8010388b:	00 00 00 
  write_head(); // clear the log
8010388e:	e8 66 ff ff ff       	call   801037f9 <write_head>
}
80103893:	c9                   	leave  
80103894:	c3                   	ret    

80103895 <begin_trans>:

void
begin_trans(void)
{
80103895:	55                   	push   %ebp
80103896:	89 e5                	mov    %esp,%ebp
80103898:	83 ec 18             	sub    $0x18,%esp
  acquire(&log.lock);
8010389b:	c7 04 24 e0 07 11 80 	movl   $0x801107e0,(%esp)
801038a2:	e8 74 19 00 00       	call   8010521b <acquire>
  while (log.busy) {
801038a7:	eb 14                	jmp    801038bd <begin_trans+0x28>
    sleep(&log, &log.lock);
801038a9:	c7 44 24 04 e0 07 11 	movl   $0x801107e0,0x4(%esp)
801038b0:	80 
801038b1:	c7 04 24 e0 07 11 80 	movl   $0x801107e0,(%esp)
801038b8:	e8 80 16 00 00       	call   80104f3d <sleep>

void
begin_trans(void)
{
  acquire(&log.lock);
  while (log.busy) {
801038bd:	a1 1c 08 11 80       	mov    0x8011081c,%eax
801038c2:	85 c0                	test   %eax,%eax
801038c4:	75 e3                	jne    801038a9 <begin_trans+0x14>
    sleep(&log, &log.lock);
  }
  log.busy = 1;
801038c6:	c7 05 1c 08 11 80 01 	movl   $0x1,0x8011081c
801038cd:	00 00 00 
  release(&log.lock);
801038d0:	c7 04 24 e0 07 11 80 	movl   $0x801107e0,(%esp)
801038d7:	e8 a1 19 00 00       	call   8010527d <release>
}
801038dc:	c9                   	leave  
801038dd:	c3                   	ret    

801038de <commit_trans>:

void
commit_trans(void)
{
801038de:	55                   	push   %ebp
801038df:	89 e5                	mov    %esp,%ebp
801038e1:	83 ec 18             	sub    $0x18,%esp
  if (log.lh.n > 0) {
801038e4:	a1 24 08 11 80       	mov    0x80110824,%eax
801038e9:	85 c0                	test   %eax,%eax
801038eb:	7e 19                	jle    80103906 <commit_trans+0x28>
    write_head();    // Write header to disk -- the real commit
801038ed:	e8 07 ff ff ff       	call   801037f9 <write_head>
    install_trans(); // Now install writes to home locations
801038f2:	e8 e8 fd ff ff       	call   801036df <install_trans>
    log.lh.n = 0; 
801038f7:	c7 05 24 08 11 80 00 	movl   $0x0,0x80110824
801038fe:	00 00 00 
    write_head();    // Erase the transaction from the log
80103901:	e8 f3 fe ff ff       	call   801037f9 <write_head>
  }
  
  acquire(&log.lock);
80103906:	c7 04 24 e0 07 11 80 	movl   $0x801107e0,(%esp)
8010390d:	e8 09 19 00 00       	call   8010521b <acquire>
  log.busy = 0;
80103912:	c7 05 1c 08 11 80 00 	movl   $0x0,0x8011081c
80103919:	00 00 00 
  wakeup(&log);
8010391c:	c7 04 24 e0 07 11 80 	movl   $0x801107e0,(%esp)
80103923:	e8 ee 16 00 00       	call   80105016 <wakeup>
  release(&log.lock);
80103928:	c7 04 24 e0 07 11 80 	movl   $0x801107e0,(%esp)
8010392f:	e8 49 19 00 00       	call   8010527d <release>
}
80103934:	c9                   	leave  
80103935:	c3                   	ret    

80103936 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
80103936:	55                   	push   %ebp
80103937:	89 e5                	mov    %esp,%ebp
80103939:	83 ec 28             	sub    $0x28,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
8010393c:	a1 24 08 11 80       	mov    0x80110824,%eax
80103941:	83 f8 09             	cmp    $0x9,%eax
80103944:	7f 12                	jg     80103958 <log_write+0x22>
80103946:	a1 24 08 11 80       	mov    0x80110824,%eax
8010394b:	8b 15 18 08 11 80    	mov    0x80110818,%edx
80103951:	83 ea 01             	sub    $0x1,%edx
80103954:	39 d0                	cmp    %edx,%eax
80103956:	7c 0c                	jl     80103964 <log_write+0x2e>
    panic("too big a transaction");
80103958:	c7 04 24 ec 8a 10 80 	movl   $0x80108aec,(%esp)
8010395f:	e8 d9 cb ff ff       	call   8010053d <panic>
  if (!log.busy)
80103964:	a1 1c 08 11 80       	mov    0x8011081c,%eax
80103969:	85 c0                	test   %eax,%eax
8010396b:	75 0c                	jne    80103979 <log_write+0x43>
    panic("write outside of trans");
8010396d:	c7 04 24 02 8b 10 80 	movl   $0x80108b02,(%esp)
80103974:	e8 c4 cb ff ff       	call   8010053d <panic>

  for (i = 0; i < log.lh.n; i++) {
80103979:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103980:	eb 1d                	jmp    8010399f <log_write+0x69>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
80103982:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103985:	83 c0 10             	add    $0x10,%eax
80103988:	8b 04 85 e8 07 11 80 	mov    -0x7feef818(,%eax,4),%eax
8010398f:	89 c2                	mov    %eax,%edx
80103991:	8b 45 08             	mov    0x8(%ebp),%eax
80103994:	8b 40 08             	mov    0x8(%eax),%eax
80103997:	39 c2                	cmp    %eax,%edx
80103999:	74 10                	je     801039ab <log_write+0x75>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    panic("too big a transaction");
  if (!log.busy)
    panic("write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
8010399b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010399f:	a1 24 08 11 80       	mov    0x80110824,%eax
801039a4:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801039a7:	7f d9                	jg     80103982 <log_write+0x4c>
801039a9:	eb 01                	jmp    801039ac <log_write+0x76>
    if (log.lh.sector[i] == b->sector)   // log absorbtion?
      break;
801039ab:	90                   	nop
  }
  log.lh.sector[i] = b->sector;
801039ac:	8b 45 08             	mov    0x8(%ebp),%eax
801039af:	8b 40 08             	mov    0x8(%eax),%eax
801039b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801039b5:	83 c2 10             	add    $0x10,%edx
801039b8:	89 04 95 e8 07 11 80 	mov    %eax,-0x7feef818(,%edx,4)
  struct buf *lbuf = bread(b->dev, log.start+i+1);
801039bf:	a1 14 08 11 80       	mov    0x80110814,%eax
801039c4:	03 45 f4             	add    -0xc(%ebp),%eax
801039c7:	83 c0 01             	add    $0x1,%eax
801039ca:	89 c2                	mov    %eax,%edx
801039cc:	8b 45 08             	mov    0x8(%ebp),%eax
801039cf:	8b 40 04             	mov    0x4(%eax),%eax
801039d2:	89 54 24 04          	mov    %edx,0x4(%esp)
801039d6:	89 04 24             	mov    %eax,(%esp)
801039d9:	e8 c8 c7 ff ff       	call   801001a6 <bread>
801039de:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(lbuf->data, b->data, BSIZE);
801039e1:	8b 45 08             	mov    0x8(%ebp),%eax
801039e4:	8d 50 18             	lea    0x18(%eax),%edx
801039e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039ea:	83 c0 18             	add    $0x18,%eax
801039ed:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
801039f4:	00 
801039f5:	89 54 24 04          	mov    %edx,0x4(%esp)
801039f9:	89 04 24             	mov    %eax,(%esp)
801039fc:	e8 3c 1b 00 00       	call   8010553d <memmove>
  bwrite(lbuf);
80103a01:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a04:	89 04 24             	mov    %eax,(%esp)
80103a07:	e8 d1 c7 ff ff       	call   801001dd <bwrite>
  brelse(lbuf);
80103a0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a0f:	89 04 24             	mov    %eax,(%esp)
80103a12:	e8 00 c8 ff ff       	call   80100217 <brelse>
  if (i == log.lh.n)
80103a17:	a1 24 08 11 80       	mov    0x80110824,%eax
80103a1c:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a1f:	75 0d                	jne    80103a2e <log_write+0xf8>
    log.lh.n++;
80103a21:	a1 24 08 11 80       	mov    0x80110824,%eax
80103a26:	83 c0 01             	add    $0x1,%eax
80103a29:	a3 24 08 11 80       	mov    %eax,0x80110824
  b->flags |= B_DIRTY; // XXX prevent eviction
80103a2e:	8b 45 08             	mov    0x8(%ebp),%eax
80103a31:	8b 00                	mov    (%eax),%eax
80103a33:	89 c2                	mov    %eax,%edx
80103a35:	83 ca 04             	or     $0x4,%edx
80103a38:	8b 45 08             	mov    0x8(%ebp),%eax
80103a3b:	89 10                	mov    %edx,(%eax)
}
80103a3d:	c9                   	leave  
80103a3e:	c3                   	ret    
	...

80103a40 <v2p>:
80103a40:	55                   	push   %ebp
80103a41:	89 e5                	mov    %esp,%ebp
80103a43:	8b 45 08             	mov    0x8(%ebp),%eax
80103a46:	05 00 00 00 80       	add    $0x80000000,%eax
80103a4b:	5d                   	pop    %ebp
80103a4c:	c3                   	ret    

80103a4d <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80103a4d:	55                   	push   %ebp
80103a4e:	89 e5                	mov    %esp,%ebp
80103a50:	8b 45 08             	mov    0x8(%ebp),%eax
80103a53:	05 00 00 00 80       	add    $0x80000000,%eax
80103a58:	5d                   	pop    %ebp
80103a59:	c3                   	ret    

80103a5a <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103a5a:	55                   	push   %ebp
80103a5b:	89 e5                	mov    %esp,%ebp
80103a5d:	53                   	push   %ebx
80103a5e:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
80103a61:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103a64:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
80103a67:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103a6a:	89 c3                	mov    %eax,%ebx
80103a6c:	89 d8                	mov    %ebx,%eax
80103a6e:	f0 87 02             	lock xchg %eax,(%edx)
80103a71:	89 c3                	mov    %eax,%ebx
80103a73:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103a76:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103a79:	83 c4 10             	add    $0x10,%esp
80103a7c:	5b                   	pop    %ebx
80103a7d:	5d                   	pop    %ebp
80103a7e:	c3                   	ret    

80103a7f <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
80103a7f:	55                   	push   %ebp
80103a80:	89 e5                	mov    %esp,%ebp
80103a82:	83 e4 f0             	and    $0xfffffff0,%esp
80103a85:	83 ec 10             	sub    $0x10,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
80103a88:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
80103a8f:	80 
80103a90:	c7 04 24 5c 36 11 80 	movl   $0x8011365c,(%esp)
80103a97:	e8 ad f5 ff ff       	call   80103049 <kinit1>
  kvmalloc();      // kernel page table
80103a9c:	e8 91 46 00 00       	call   80108132 <kvmalloc>
  mpinit();        // collect info about this machine
80103aa1:	e8 63 04 00 00       	call   80103f09 <mpinit>
  lapicinit(mpbcpu());
80103aa6:	e8 2e 02 00 00       	call   80103cd9 <mpbcpu>
80103aab:	89 04 24             	mov    %eax,(%esp)
80103aae:	e8 f5 f8 ff ff       	call   801033a8 <lapicinit>
  seginit();       // set up segments
80103ab3:	e8 1d 40 00 00       	call   80107ad5 <seginit>
  cprintf("\ncpu%d: starting xv6\n\n", cpu->id);
80103ab8:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103abe:	0f b6 00             	movzbl (%eax),%eax
80103ac1:	0f b6 c0             	movzbl %al,%eax
80103ac4:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ac8:	c7 04 24 19 8b 10 80 	movl   $0x80108b19,(%esp)
80103acf:	e8 cd c8 ff ff       	call   801003a1 <cprintf>
  picinit();       // interrupt controller
80103ad4:	e8 95 06 00 00       	call   8010416e <picinit>
  ioapicinit();    // another interrupt controller
80103ad9:	e8 5b f4 ff ff       	call   80102f39 <ioapicinit>
  consoleinit();   // I/O devices & their interrupts
80103ade:	e8 88 d5 ff ff       	call   8010106b <consoleinit>
  uartinit();      // serial port
80103ae3:	e8 38 33 00 00       	call   80106e20 <uartinit>
  pinit();         // process table
80103ae8:	e8 96 0b 00 00       	call   80104683 <pinit>
  tvinit();        // trap vectors
80103aed:	e8 d1 2e 00 00       	call   801069c3 <tvinit>
  binit();         // buffer cache
80103af2:	e8 3d c5 ff ff       	call   80100034 <binit>
  fileinit();      // file table
80103af7:	e8 7c da ff ff       	call   80101578 <fileinit>
  iinit();         // inode cache
80103afc:	e8 2a e1 ff ff       	call   80101c2b <iinit>
  ideinit();       // disk
80103b01:	e8 98 f0 ff ff       	call   80102b9e <ideinit>
  if(!ismp)
80103b06:	a1 64 08 11 80       	mov    0x80110864,%eax
80103b0b:	85 c0                	test   %eax,%eax
80103b0d:	75 05                	jne    80103b14 <main+0x95>
    timerinit();   // uniprocessor timer
80103b0f:	e8 f2 2d 00 00       	call   80106906 <timerinit>
  startothers();   // start other processors
80103b14:	e8 87 00 00 00       	call   80103ba0 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
80103b19:	c7 44 24 04 00 00 00 	movl   $0x8e000000,0x4(%esp)
80103b20:	8e 
80103b21:	c7 04 24 00 00 40 80 	movl   $0x80400000,(%esp)
80103b28:	e8 54 f5 ff ff       	call   80103081 <kinit2>
  userinit();      // first user process
80103b2d:	e8 6c 0c 00 00       	call   8010479e <userinit>
  // Finish setting up this processor in mpmain.
  mpmain();
80103b32:	e8 22 00 00 00       	call   80103b59 <mpmain>

80103b37 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
80103b37:	55                   	push   %ebp
80103b38:	89 e5                	mov    %esp,%ebp
80103b3a:	83 ec 18             	sub    $0x18,%esp
  switchkvm(); 
80103b3d:	e8 07 46 00 00       	call   80108149 <switchkvm>
  seginit();
80103b42:	e8 8e 3f 00 00       	call   80107ad5 <seginit>
  lapicinit(cpunum());
80103b47:	e8 b9 f9 ff ff       	call   80103505 <cpunum>
80103b4c:	89 04 24             	mov    %eax,(%esp)
80103b4f:	e8 54 f8 ff ff       	call   801033a8 <lapicinit>
  mpmain();
80103b54:	e8 00 00 00 00       	call   80103b59 <mpmain>

80103b59 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103b59:	55                   	push   %ebp
80103b5a:	89 e5                	mov    %esp,%ebp
80103b5c:	83 ec 18             	sub    $0x18,%esp
  cprintf("cpu%d: starting\n", cpu->id);
80103b5f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103b65:	0f b6 00             	movzbl (%eax),%eax
80103b68:	0f b6 c0             	movzbl %al,%eax
80103b6b:	89 44 24 04          	mov    %eax,0x4(%esp)
80103b6f:	c7 04 24 30 8b 10 80 	movl   $0x80108b30,(%esp)
80103b76:	e8 26 c8 ff ff       	call   801003a1 <cprintf>
  idtinit();       // load idt register
80103b7b:	e8 b7 2f 00 00       	call   80106b37 <idtinit>
  xchg(&cpu->started, 1); // tell startothers() we're up
80103b80:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80103b86:	05 a8 00 00 00       	add    $0xa8,%eax
80103b8b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80103b92:	00 
80103b93:	89 04 24             	mov    %eax,(%esp)
80103b96:	e8 bf fe ff ff       	call   80103a5a <xchg>
  scheduler();     // start running processes
80103b9b:	e8 f4 11 00 00       	call   80104d94 <scheduler>

80103ba0 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103ba0:	55                   	push   %ebp
80103ba1:	89 e5                	mov    %esp,%ebp
80103ba3:	53                   	push   %ebx
80103ba4:	83 ec 24             	sub    $0x24,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
80103ba7:	c7 04 24 00 70 00 00 	movl   $0x7000,(%esp)
80103bae:	e8 9a fe ff ff       	call   80103a4d <p2v>
80103bb3:	89 45 f0             	mov    %eax,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103bb6:	b8 8a 00 00 00       	mov    $0x8a,%eax
80103bbb:	89 44 24 08          	mov    %eax,0x8(%esp)
80103bbf:	c7 44 24 04 0c b5 10 	movl   $0x8010b50c,0x4(%esp)
80103bc6:	80 
80103bc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bca:	89 04 24             	mov    %eax,(%esp)
80103bcd:	e8 6b 19 00 00       	call   8010553d <memmove>

  for(c = cpus; c < cpus+ncpu; c++){
80103bd2:	c7 45 f4 80 08 11 80 	movl   $0x80110880,-0xc(%ebp)
80103bd9:	e9 86 00 00 00       	jmp    80103c64 <startothers+0xc4>
    if(c == cpus+cpunum())  // We've started already.
80103bde:	e8 22 f9 ff ff       	call   80103505 <cpunum>
80103be3:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103be9:	05 80 08 11 80       	add    $0x80110880,%eax
80103bee:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103bf1:	74 69                	je     80103c5c <startothers+0xbc>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what 
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103bf3:	e8 7f f5 ff ff       	call   80103177 <kalloc>
80103bf8:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
80103bfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bfe:	83 e8 04             	sub    $0x4,%eax
80103c01:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103c04:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103c0a:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
80103c0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c0f:	83 e8 08             	sub    $0x8,%eax
80103c12:	c7 00 37 3b 10 80    	movl   $0x80103b37,(%eax)
    *(int**)(code-12) = (void *) v2p(entrypgdir);
80103c18:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c1b:	8d 58 f4             	lea    -0xc(%eax),%ebx
80103c1e:	c7 04 24 00 a0 10 80 	movl   $0x8010a000,(%esp)
80103c25:	e8 16 fe ff ff       	call   80103a40 <v2p>
80103c2a:	89 03                	mov    %eax,(%ebx)

    lapicstartap(c->id, v2p(code));
80103c2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c2f:	89 04 24             	mov    %eax,(%esp)
80103c32:	e8 09 fe ff ff       	call   80103a40 <v2p>
80103c37:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c3a:	0f b6 12             	movzbl (%edx),%edx
80103c3d:	0f b6 d2             	movzbl %dl,%edx
80103c40:	89 44 24 04          	mov    %eax,0x4(%esp)
80103c44:	89 14 24             	mov    %edx,(%esp)
80103c47:	e8 3f f9 ff ff       	call   8010358b <lapicstartap>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
80103c4c:	90                   	nop
80103c4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103c50:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80103c56:	85 c0                	test   %eax,%eax
80103c58:	74 f3                	je     80103c4d <startothers+0xad>
80103c5a:	eb 01                	jmp    80103c5d <startothers+0xbd>
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpunum())  // We've started already.
      continue;
80103c5c:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = p2v(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
80103c5d:	81 45 f4 bc 00 00 00 	addl   $0xbc,-0xc(%ebp)
80103c64:	a1 60 0e 11 80       	mov    0x80110e60,%eax
80103c69:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103c6f:	05 80 08 11 80       	add    $0x80110880,%eax
80103c74:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103c77:	0f 87 61 ff ff ff    	ja     80103bde <startothers+0x3e>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103c7d:	83 c4 24             	add    $0x24,%esp
80103c80:	5b                   	pop    %ebx
80103c81:	5d                   	pop    %ebp
80103c82:	c3                   	ret    
	...

80103c84 <p2v>:
80103c84:	55                   	push   %ebp
80103c85:	89 e5                	mov    %esp,%ebp
80103c87:	8b 45 08             	mov    0x8(%ebp),%eax
80103c8a:	05 00 00 00 80       	add    $0x80000000,%eax
80103c8f:	5d                   	pop    %ebp
80103c90:	c3                   	ret    

80103c91 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103c91:	55                   	push   %ebp
80103c92:	89 e5                	mov    %esp,%ebp
80103c94:	53                   	push   %ebx
80103c95:	83 ec 14             	sub    $0x14,%esp
80103c98:	8b 45 08             	mov    0x8(%ebp),%eax
80103c9b:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103c9f:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80103ca3:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80103ca7:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80103cab:	ec                   	in     (%dx),%al
80103cac:	89 c3                	mov    %eax,%ebx
80103cae:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80103cb1:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80103cb5:	83 c4 14             	add    $0x14,%esp
80103cb8:	5b                   	pop    %ebx
80103cb9:	5d                   	pop    %ebp
80103cba:	c3                   	ret    

80103cbb <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103cbb:	55                   	push   %ebp
80103cbc:	89 e5                	mov    %esp,%ebp
80103cbe:	83 ec 08             	sub    $0x8,%esp
80103cc1:	8b 55 08             	mov    0x8(%ebp),%edx
80103cc4:	8b 45 0c             	mov    0xc(%ebp),%eax
80103cc7:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103ccb:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103cce:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103cd2:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103cd6:	ee                   	out    %al,(%dx)
}
80103cd7:	c9                   	leave  
80103cd8:	c3                   	ret    

80103cd9 <mpbcpu>:
int ncpu;
uchar ioapicid;

int
mpbcpu(void)
{
80103cd9:	55                   	push   %ebp
80103cda:	89 e5                	mov    %esp,%ebp
  return bcpu-cpus;
80103cdc:	a1 64 c0 10 80       	mov    0x8010c064,%eax
80103ce1:	89 c2                	mov    %eax,%edx
80103ce3:	b8 80 08 11 80       	mov    $0x80110880,%eax
80103ce8:	89 d1                	mov    %edx,%ecx
80103cea:	29 c1                	sub    %eax,%ecx
80103cec:	89 c8                	mov    %ecx,%eax
80103cee:	c1 f8 02             	sar    $0x2,%eax
80103cf1:	69 c0 cf 46 7d 67    	imul   $0x677d46cf,%eax,%eax
}
80103cf7:	5d                   	pop    %ebp
80103cf8:	c3                   	ret    

80103cf9 <sum>:

static uchar
sum(uchar *addr, int len)
{
80103cf9:	55                   	push   %ebp
80103cfa:	89 e5                	mov    %esp,%ebp
80103cfc:	83 ec 10             	sub    $0x10,%esp
  int i, sum;
  
  sum = 0;
80103cff:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103d06:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103d0d:	eb 13                	jmp    80103d22 <sum+0x29>
    sum += addr[i];
80103d0f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103d12:	03 45 08             	add    0x8(%ebp),%eax
80103d15:	0f b6 00             	movzbl (%eax),%eax
80103d18:	0f b6 c0             	movzbl %al,%eax
80103d1b:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;
  
  sum = 0;
  for(i=0; i<len; i++)
80103d1e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103d22:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103d25:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103d28:	7c e5                	jl     80103d0f <sum+0x16>
    sum += addr[i];
  return sum;
80103d2a:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103d2d:	c9                   	leave  
80103d2e:	c3                   	ret    

80103d2f <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103d2f:	55                   	push   %ebp
80103d30:	89 e5                	mov    %esp,%ebp
80103d32:	83 ec 28             	sub    $0x28,%esp
  uchar *e, *p, *addr;

  addr = p2v(a);
80103d35:	8b 45 08             	mov    0x8(%ebp),%eax
80103d38:	89 04 24             	mov    %eax,(%esp)
80103d3b:	e8 44 ff ff ff       	call   80103c84 <p2v>
80103d40:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103d43:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d46:	03 45 f0             	add    -0x10(%ebp),%eax
80103d49:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103d4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103d4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103d52:	eb 3f                	jmp    80103d93 <mpsearch1+0x64>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103d54:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103d5b:	00 
80103d5c:	c7 44 24 04 44 8b 10 	movl   $0x80108b44,0x4(%esp)
80103d63:	80 
80103d64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d67:	89 04 24             	mov    %eax,(%esp)
80103d6a:	e8 72 17 00 00       	call   801054e1 <memcmp>
80103d6f:	85 c0                	test   %eax,%eax
80103d71:	75 1c                	jne    80103d8f <mpsearch1+0x60>
80103d73:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
80103d7a:	00 
80103d7b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d7e:	89 04 24             	mov    %eax,(%esp)
80103d81:	e8 73 ff ff ff       	call   80103cf9 <sum>
80103d86:	84 c0                	test   %al,%al
80103d88:	75 05                	jne    80103d8f <mpsearch1+0x60>
      return (struct mp*)p;
80103d8a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d8d:	eb 11                	jmp    80103da0 <mpsearch1+0x71>
{
  uchar *e, *p, *addr;

  addr = p2v(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103d8f:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103d93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d96:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103d99:	72 b9                	jb     80103d54 <mpsearch1+0x25>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103d9b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103da0:	c9                   	leave  
80103da1:	c3                   	ret    

80103da2 <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103da2:	55                   	push   %ebp
80103da3:	89 e5                	mov    %esp,%ebp
80103da5:	83 ec 28             	sub    $0x28,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103da8:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103daf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103db2:	83 c0 0f             	add    $0xf,%eax
80103db5:	0f b6 00             	movzbl (%eax),%eax
80103db8:	0f b6 c0             	movzbl %al,%eax
80103dbb:	89 c2                	mov    %eax,%edx
80103dbd:	c1 e2 08             	shl    $0x8,%edx
80103dc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dc3:	83 c0 0e             	add    $0xe,%eax
80103dc6:	0f b6 00             	movzbl (%eax),%eax
80103dc9:	0f b6 c0             	movzbl %al,%eax
80103dcc:	09 d0                	or     %edx,%eax
80103dce:	c1 e0 04             	shl    $0x4,%eax
80103dd1:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103dd4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103dd8:	74 21                	je     80103dfb <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103dda:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103de1:	00 
80103de2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103de5:	89 04 24             	mov    %eax,(%esp)
80103de8:	e8 42 ff ff ff       	call   80103d2f <mpsearch1>
80103ded:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103df0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103df4:	74 50                	je     80103e46 <mpsearch+0xa4>
      return mp;
80103df6:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103df9:	eb 5f                	jmp    80103e5a <mpsearch+0xb8>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103dfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103dfe:	83 c0 14             	add    $0x14,%eax
80103e01:	0f b6 00             	movzbl (%eax),%eax
80103e04:	0f b6 c0             	movzbl %al,%eax
80103e07:	89 c2                	mov    %eax,%edx
80103e09:	c1 e2 08             	shl    $0x8,%edx
80103e0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e0f:	83 c0 13             	add    $0x13,%eax
80103e12:	0f b6 00             	movzbl (%eax),%eax
80103e15:	0f b6 c0             	movzbl %al,%eax
80103e18:	09 d0                	or     %edx,%eax
80103e1a:	c1 e0 0a             	shl    $0xa,%eax
80103e1d:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103e20:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103e23:	2d 00 04 00 00       	sub    $0x400,%eax
80103e28:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
80103e2f:	00 
80103e30:	89 04 24             	mov    %eax,(%esp)
80103e33:	e8 f7 fe ff ff       	call   80103d2f <mpsearch1>
80103e38:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103e3b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103e3f:	74 05                	je     80103e46 <mpsearch+0xa4>
      return mp;
80103e41:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103e44:	eb 14                	jmp    80103e5a <mpsearch+0xb8>
  }
  return mpsearch1(0xF0000, 0x10000);
80103e46:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
80103e4d:	00 
80103e4e:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
80103e55:	e8 d5 fe ff ff       	call   80103d2f <mpsearch1>
}
80103e5a:	c9                   	leave  
80103e5b:	c3                   	ret    

80103e5c <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103e5c:	55                   	push   %ebp
80103e5d:	89 e5                	mov    %esp,%ebp
80103e5f:	83 ec 28             	sub    $0x28,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103e62:	e8 3b ff ff ff       	call   80103da2 <mpsearch>
80103e67:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103e6a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103e6e:	74 0a                	je     80103e7a <mpconfig+0x1e>
80103e70:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e73:	8b 40 04             	mov    0x4(%eax),%eax
80103e76:	85 c0                	test   %eax,%eax
80103e78:	75 0a                	jne    80103e84 <mpconfig+0x28>
    return 0;
80103e7a:	b8 00 00 00 00       	mov    $0x0,%eax
80103e7f:	e9 83 00 00 00       	jmp    80103f07 <mpconfig+0xab>
  conf = (struct mpconf*) p2v((uint) mp->physaddr);
80103e84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e87:	8b 40 04             	mov    0x4(%eax),%eax
80103e8a:	89 04 24             	mov    %eax,(%esp)
80103e8d:	e8 f2 fd ff ff       	call   80103c84 <p2v>
80103e92:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103e95:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
80103e9c:	00 
80103e9d:	c7 44 24 04 49 8b 10 	movl   $0x80108b49,0x4(%esp)
80103ea4:	80 
80103ea5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ea8:	89 04 24             	mov    %eax,(%esp)
80103eab:	e8 31 16 00 00       	call   801054e1 <memcmp>
80103eb0:	85 c0                	test   %eax,%eax
80103eb2:	74 07                	je     80103ebb <mpconfig+0x5f>
    return 0;
80103eb4:	b8 00 00 00 00       	mov    $0x0,%eax
80103eb9:	eb 4c                	jmp    80103f07 <mpconfig+0xab>
  if(conf->version != 1 && conf->version != 4)
80103ebb:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ebe:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103ec2:	3c 01                	cmp    $0x1,%al
80103ec4:	74 12                	je     80103ed8 <mpconfig+0x7c>
80103ec6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ec9:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103ecd:	3c 04                	cmp    $0x4,%al
80103ecf:	74 07                	je     80103ed8 <mpconfig+0x7c>
    return 0;
80103ed1:	b8 00 00 00 00       	mov    $0x0,%eax
80103ed6:	eb 2f                	jmp    80103f07 <mpconfig+0xab>
  if(sum((uchar*)conf, conf->length) != 0)
80103ed8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103edb:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103edf:	0f b7 c0             	movzwl %ax,%eax
80103ee2:	89 44 24 04          	mov    %eax,0x4(%esp)
80103ee6:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103ee9:	89 04 24             	mov    %eax,(%esp)
80103eec:	e8 08 fe ff ff       	call   80103cf9 <sum>
80103ef1:	84 c0                	test   %al,%al
80103ef3:	74 07                	je     80103efc <mpconfig+0xa0>
    return 0;
80103ef5:	b8 00 00 00 00       	mov    $0x0,%eax
80103efa:	eb 0b                	jmp    80103f07 <mpconfig+0xab>
  *pmp = mp;
80103efc:	8b 45 08             	mov    0x8(%ebp),%eax
80103eff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103f02:	89 10                	mov    %edx,(%eax)
  return conf;
80103f04:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103f07:	c9                   	leave  
80103f08:	c3                   	ret    

80103f09 <mpinit>:

void
mpinit(void)
{
80103f09:	55                   	push   %ebp
80103f0a:	89 e5                	mov    %esp,%ebp
80103f0c:	83 ec 38             	sub    $0x38,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
80103f0f:	c7 05 64 c0 10 80 80 	movl   $0x80110880,0x8010c064
80103f16:	08 11 80 
  if((conf = mpconfig(&mp)) == 0)
80103f19:	8d 45 e0             	lea    -0x20(%ebp),%eax
80103f1c:	89 04 24             	mov    %eax,(%esp)
80103f1f:	e8 38 ff ff ff       	call   80103e5c <mpconfig>
80103f24:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103f27:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103f2b:	0f 84 9c 01 00 00    	je     801040cd <mpinit+0x1c4>
    return;
  ismp = 1;
80103f31:	c7 05 64 08 11 80 01 	movl   $0x1,0x80110864
80103f38:	00 00 00 
  lapic = (uint*)conf->lapicaddr;
80103f3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f3e:	8b 40 24             	mov    0x24(%eax),%eax
80103f41:	a3 dc 07 11 80       	mov    %eax,0x801107dc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103f46:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f49:	83 c0 2c             	add    $0x2c,%eax
80103f4c:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103f4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103f52:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103f56:	0f b7 c0             	movzwl %ax,%eax
80103f59:	03 45 f0             	add    -0x10(%ebp),%eax
80103f5c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103f5f:	e9 f4 00 00 00       	jmp    80104058 <mpinit+0x14f>
    switch(*p){
80103f64:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f67:	0f b6 00             	movzbl (%eax),%eax
80103f6a:	0f b6 c0             	movzbl %al,%eax
80103f6d:	83 f8 04             	cmp    $0x4,%eax
80103f70:	0f 87 bf 00 00 00    	ja     80104035 <mpinit+0x12c>
80103f76:	8b 04 85 8c 8b 10 80 	mov    -0x7fef7474(,%eax,4),%eax
80103f7d:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103f7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103f82:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if(ncpu != proc->apicid){
80103f85:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103f88:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103f8c:	0f b6 d0             	movzbl %al,%edx
80103f8f:	a1 60 0e 11 80       	mov    0x80110e60,%eax
80103f94:	39 c2                	cmp    %eax,%edx
80103f96:	74 2d                	je     80103fc5 <mpinit+0xbc>
        cprintf("mpinit: ncpu=%d apicid=%d\n", ncpu, proc->apicid);
80103f98:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103f9b:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103f9f:	0f b6 d0             	movzbl %al,%edx
80103fa2:	a1 60 0e 11 80       	mov    0x80110e60,%eax
80103fa7:	89 54 24 08          	mov    %edx,0x8(%esp)
80103fab:	89 44 24 04          	mov    %eax,0x4(%esp)
80103faf:	c7 04 24 4e 8b 10 80 	movl   $0x80108b4e,(%esp)
80103fb6:	e8 e6 c3 ff ff       	call   801003a1 <cprintf>
        ismp = 0;
80103fbb:	c7 05 64 08 11 80 00 	movl   $0x0,0x80110864
80103fc2:	00 00 00 
      }
      if(proc->flags & MPBOOT)
80103fc5:	8b 45 e8             	mov    -0x18(%ebp),%eax
80103fc8:	0f b6 40 03          	movzbl 0x3(%eax),%eax
80103fcc:	0f b6 c0             	movzbl %al,%eax
80103fcf:	83 e0 02             	and    $0x2,%eax
80103fd2:	85 c0                	test   %eax,%eax
80103fd4:	74 15                	je     80103feb <mpinit+0xe2>
        bcpu = &cpus[ncpu];
80103fd6:	a1 60 0e 11 80       	mov    0x80110e60,%eax
80103fdb:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80103fe1:	05 80 08 11 80       	add    $0x80110880,%eax
80103fe6:	a3 64 c0 10 80       	mov    %eax,0x8010c064
      cpus[ncpu].id = ncpu;
80103feb:	8b 15 60 0e 11 80    	mov    0x80110e60,%edx
80103ff1:	a1 60 0e 11 80       	mov    0x80110e60,%eax
80103ff6:	69 d2 bc 00 00 00    	imul   $0xbc,%edx,%edx
80103ffc:	81 c2 80 08 11 80    	add    $0x80110880,%edx
80104002:	88 02                	mov    %al,(%edx)
      ncpu++;
80104004:	a1 60 0e 11 80       	mov    0x80110e60,%eax
80104009:	83 c0 01             	add    $0x1,%eax
8010400c:	a3 60 0e 11 80       	mov    %eax,0x80110e60
      p += sizeof(struct mpproc);
80104011:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80104015:	eb 41                	jmp    80104058 <mpinit+0x14f>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80104017:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010401a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      ioapicid = ioapic->apicno;
8010401d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80104020:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80104024:	a2 60 08 11 80       	mov    %al,0x80110860
      p += sizeof(struct mpioapic);
80104029:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
8010402d:	eb 29                	jmp    80104058 <mpinit+0x14f>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
8010402f:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80104033:	eb 23                	jmp    80104058 <mpinit+0x14f>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
80104035:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104038:	0f b6 00             	movzbl (%eax),%eax
8010403b:	0f b6 c0             	movzbl %al,%eax
8010403e:	89 44 24 04          	mov    %eax,0x4(%esp)
80104042:	c7 04 24 6c 8b 10 80 	movl   $0x80108b6c,(%esp)
80104049:	e8 53 c3 ff ff       	call   801003a1 <cprintf>
      ismp = 0;
8010404e:	c7 05 64 08 11 80 00 	movl   $0x0,0x80110864
80104055:	00 00 00 
  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80104058:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010405b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010405e:	0f 82 00 ff ff ff    	jb     80103f64 <mpinit+0x5b>
    default:
      cprintf("mpinit: unknown config type %x\n", *p);
      ismp = 0;
    }
  }
  if(!ismp){
80104064:	a1 64 08 11 80       	mov    0x80110864,%eax
80104069:	85 c0                	test   %eax,%eax
8010406b:	75 1d                	jne    8010408a <mpinit+0x181>
    // Didn't like what we found; fall back to no MP.
    ncpu = 1;
8010406d:	c7 05 60 0e 11 80 01 	movl   $0x1,0x80110e60
80104074:	00 00 00 
    lapic = 0;
80104077:	c7 05 dc 07 11 80 00 	movl   $0x0,0x801107dc
8010407e:	00 00 00 
    ioapicid = 0;
80104081:	c6 05 60 08 11 80 00 	movb   $0x0,0x80110860
    return;
80104088:	eb 44                	jmp    801040ce <mpinit+0x1c5>
  }

  if(mp->imcrp){
8010408a:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010408d:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80104091:	84 c0                	test   %al,%al
80104093:	74 39                	je     801040ce <mpinit+0x1c5>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80104095:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
8010409c:	00 
8010409d:	c7 04 24 22 00 00 00 	movl   $0x22,(%esp)
801040a4:	e8 12 fc ff ff       	call   80103cbb <outb>
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
801040a9:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801040b0:	e8 dc fb ff ff       	call   80103c91 <inb>
801040b5:	83 c8 01             	or     $0x1,%eax
801040b8:	0f b6 c0             	movzbl %al,%eax
801040bb:	89 44 24 04          	mov    %eax,0x4(%esp)
801040bf:	c7 04 24 23 00 00 00 	movl   $0x23,(%esp)
801040c6:	e8 f0 fb ff ff       	call   80103cbb <outb>
801040cb:	eb 01                	jmp    801040ce <mpinit+0x1c5>
  struct mpproc *proc;
  struct mpioapic *ioapic;

  bcpu = &cpus[0];
  if((conf = mpconfig(&mp)) == 0)
    return;
801040cd:	90                   	nop
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
  }
}
801040ce:	c9                   	leave  
801040cf:	c3                   	ret    

801040d0 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801040d0:	55                   	push   %ebp
801040d1:	89 e5                	mov    %esp,%ebp
801040d3:	83 ec 08             	sub    $0x8,%esp
801040d6:	8b 55 08             	mov    0x8(%ebp),%edx
801040d9:	8b 45 0c             	mov    0xc(%ebp),%eax
801040dc:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801040e0:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801040e3:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801040e7:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801040eb:	ee                   	out    %al,(%dx)
}
801040ec:	c9                   	leave  
801040ed:	c3                   	ret    

801040ee <picsetmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static ushort irqmask = 0xFFFF & ~(1<<IRQ_SLAVE);

static void
picsetmask(ushort mask)
{
801040ee:	55                   	push   %ebp
801040ef:	89 e5                	mov    %esp,%ebp
801040f1:	83 ec 0c             	sub    $0xc,%esp
801040f4:	8b 45 08             	mov    0x8(%ebp),%eax
801040f7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  irqmask = mask;
801040fb:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801040ff:	66 a3 00 b0 10 80    	mov    %ax,0x8010b000
  outb(IO_PIC1+1, mask);
80104105:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104109:	0f b6 c0             	movzbl %al,%eax
8010410c:	89 44 24 04          	mov    %eax,0x4(%esp)
80104110:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104117:	e8 b4 ff ff ff       	call   801040d0 <outb>
  outb(IO_PIC2+1, mask >> 8);
8010411c:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80104120:	66 c1 e8 08          	shr    $0x8,%ax
80104124:	0f b6 c0             	movzbl %al,%eax
80104127:	89 44 24 04          	mov    %eax,0x4(%esp)
8010412b:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104132:	e8 99 ff ff ff       	call   801040d0 <outb>
}
80104137:	c9                   	leave  
80104138:	c3                   	ret    

80104139 <picenable>:

void
picenable(int irq)
{
80104139:	55                   	push   %ebp
8010413a:	89 e5                	mov    %esp,%ebp
8010413c:	53                   	push   %ebx
8010413d:	83 ec 04             	sub    $0x4,%esp
  picsetmask(irqmask & ~(1<<irq));
80104140:	8b 45 08             	mov    0x8(%ebp),%eax
80104143:	ba 01 00 00 00       	mov    $0x1,%edx
80104148:	89 d3                	mov    %edx,%ebx
8010414a:	89 c1                	mov    %eax,%ecx
8010414c:	d3 e3                	shl    %cl,%ebx
8010414e:	89 d8                	mov    %ebx,%eax
80104150:	89 c2                	mov    %eax,%edx
80104152:	f7 d2                	not    %edx
80104154:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
8010415b:	21 d0                	and    %edx,%eax
8010415d:	0f b7 c0             	movzwl %ax,%eax
80104160:	89 04 24             	mov    %eax,(%esp)
80104163:	e8 86 ff ff ff       	call   801040ee <picsetmask>
}
80104168:	83 c4 04             	add    $0x4,%esp
8010416b:	5b                   	pop    %ebx
8010416c:	5d                   	pop    %ebp
8010416d:	c3                   	ret    

8010416e <picinit>:

// Initialize the 8259A interrupt controllers.
void
picinit(void)
{
8010416e:	55                   	push   %ebp
8010416f:	89 e5                	mov    %esp,%ebp
80104171:	83 ec 08             	sub    $0x8,%esp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80104174:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010417b:	00 
8010417c:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
80104183:	e8 48 ff ff ff       	call   801040d0 <outb>
  outb(IO_PIC2+1, 0xFF);
80104188:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
8010418f:	00 
80104190:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104197:	e8 34 ff ff ff       	call   801040d0 <outb>

  // ICW1:  0001g0hi
  //    g:  0 = edge triggering, 1 = level triggering
  //    h:  0 = cascaded PICs, 1 = master only
  //    i:  0 = no ICW4, 1 = ICW4 required
  outb(IO_PIC1, 0x11);
8010419c:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801041a3:	00 
801041a4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
801041ab:	e8 20 ff ff ff       	call   801040d0 <outb>

  // ICW2:  Vector offset
  outb(IO_PIC1+1, T_IRQ0);
801041b0:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
801041b7:	00 
801041b8:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801041bf:	e8 0c ff ff ff       	call   801040d0 <outb>

  // ICW3:  (master PIC) bit mask of IR lines connected to slaves
  //        (slave PIC) 3-bit # of slave's connection to master
  outb(IO_PIC1+1, 1<<IRQ_SLAVE);
801041c4:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
801041cb:	00 
801041cc:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801041d3:	e8 f8 fe ff ff       	call   801040d0 <outb>
  //    m:  0 = slave PIC, 1 = master PIC
  //      (ignored when b is 0, as the master/slave role
  //      can be hardwired).
  //    a:  1 = Automatic EOI mode
  //    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
  outb(IO_PIC1+1, 0x3);
801041d8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
801041df:	00 
801041e0:	c7 04 24 21 00 00 00 	movl   $0x21,(%esp)
801041e7:	e8 e4 fe ff ff       	call   801040d0 <outb>

  // Set up slave (8259A-2)
  outb(IO_PIC2, 0x11);                  // ICW1
801041ec:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
801041f3:	00 
801041f4:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
801041fb:	e8 d0 fe ff ff       	call   801040d0 <outb>
  outb(IO_PIC2+1, T_IRQ0 + 8);      // ICW2
80104200:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
80104207:	00 
80104208:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
8010420f:	e8 bc fe ff ff       	call   801040d0 <outb>
  outb(IO_PIC2+1, IRQ_SLAVE);           // ICW3
80104214:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
8010421b:	00 
8010421c:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104223:	e8 a8 fe ff ff       	call   801040d0 <outb>
  // NB Automatic EOI mode doesn't tend to work on the slave.
  // Linux source code says it's "to be investigated".
  outb(IO_PIC2+1, 0x3);                 // ICW4
80104228:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
8010422f:	00 
80104230:	c7 04 24 a1 00 00 00 	movl   $0xa1,(%esp)
80104237:	e8 94 fe ff ff       	call   801040d0 <outb>

  // OCW3:  0ef01prs
  //   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
  //    p:  0 = no polling, 1 = polling mode
  //   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
  outb(IO_PIC1, 0x68);             // clear specific mask
8010423c:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
80104243:	00 
80104244:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010424b:	e8 80 fe ff ff       	call   801040d0 <outb>
  outb(IO_PIC1, 0x0a);             // read IRR by default
80104250:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
80104257:	00 
80104258:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
8010425f:	e8 6c fe ff ff       	call   801040d0 <outb>

  outb(IO_PIC2, 0x68);             // OCW3
80104264:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
8010426b:	00 
8010426c:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104273:	e8 58 fe ff ff       	call   801040d0 <outb>
  outb(IO_PIC2, 0x0a);             // OCW3
80104278:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
8010427f:	00 
80104280:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
80104287:	e8 44 fe ff ff       	call   801040d0 <outb>

  if(irqmask != 0xFFFF)
8010428c:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
80104293:	66 83 f8 ff          	cmp    $0xffff,%ax
80104297:	74 12                	je     801042ab <picinit+0x13d>
    picsetmask(irqmask);
80104299:	0f b7 05 00 b0 10 80 	movzwl 0x8010b000,%eax
801042a0:	0f b7 c0             	movzwl %ax,%eax
801042a3:	89 04 24             	mov    %eax,(%esp)
801042a6:	e8 43 fe ff ff       	call   801040ee <picsetmask>
}
801042ab:	c9                   	leave  
801042ac:	c3                   	ret    
801042ad:	00 00                	add    %al,(%eax)
	...

801042b0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
801042b0:	55                   	push   %ebp
801042b1:	89 e5                	mov    %esp,%ebp
801042b3:	83 ec 28             	sub    $0x28,%esp
  struct pipe *p;

  p = 0;
801042b6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
801042bd:	8b 45 0c             	mov    0xc(%ebp),%eax
801042c0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
801042c6:	8b 45 0c             	mov    0xc(%ebp),%eax
801042c9:	8b 10                	mov    (%eax),%edx
801042cb:	8b 45 08             	mov    0x8(%ebp),%eax
801042ce:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
801042d0:	e8 bf d2 ff ff       	call   80101594 <filealloc>
801042d5:	8b 55 08             	mov    0x8(%ebp),%edx
801042d8:	89 02                	mov    %eax,(%edx)
801042da:	8b 45 08             	mov    0x8(%ebp),%eax
801042dd:	8b 00                	mov    (%eax),%eax
801042df:	85 c0                	test   %eax,%eax
801042e1:	0f 84 c8 00 00 00    	je     801043af <pipealloc+0xff>
801042e7:	e8 a8 d2 ff ff       	call   80101594 <filealloc>
801042ec:	8b 55 0c             	mov    0xc(%ebp),%edx
801042ef:	89 02                	mov    %eax,(%edx)
801042f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801042f4:	8b 00                	mov    (%eax),%eax
801042f6:	85 c0                	test   %eax,%eax
801042f8:	0f 84 b1 00 00 00    	je     801043af <pipealloc+0xff>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
801042fe:	e8 74 ee ff ff       	call   80103177 <kalloc>
80104303:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104306:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010430a:	0f 84 9e 00 00 00    	je     801043ae <pipealloc+0xfe>
    goto bad;
  p->readopen = 1;
80104310:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104313:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
8010431a:	00 00 00 
  p->writeopen = 1;
8010431d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104320:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80104327:	00 00 00 
  p->nwrite = 0;
8010432a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010432d:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80104334:	00 00 00 
  p->nread = 0;
80104337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010433a:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80104341:	00 00 00 
  initlock(&p->lock, "pipe");
80104344:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104347:	c7 44 24 04 a0 8b 10 	movl   $0x80108ba0,0x4(%esp)
8010434e:	80 
8010434f:	89 04 24             	mov    %eax,(%esp)
80104352:	e8 a3 0e 00 00       	call   801051fa <initlock>
  (*f0)->type = FD_PIPE;
80104357:	8b 45 08             	mov    0x8(%ebp),%eax
8010435a:	8b 00                	mov    (%eax),%eax
8010435c:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80104362:	8b 45 08             	mov    0x8(%ebp),%eax
80104365:	8b 00                	mov    (%eax),%eax
80104367:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
8010436b:	8b 45 08             	mov    0x8(%ebp),%eax
8010436e:	8b 00                	mov    (%eax),%eax
80104370:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80104374:	8b 45 08             	mov    0x8(%ebp),%eax
80104377:	8b 00                	mov    (%eax),%eax
80104379:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010437c:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
8010437f:	8b 45 0c             	mov    0xc(%ebp),%eax
80104382:	8b 00                	mov    (%eax),%eax
80104384:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
8010438a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010438d:	8b 00                	mov    (%eax),%eax
8010438f:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80104393:	8b 45 0c             	mov    0xc(%ebp),%eax
80104396:	8b 00                	mov    (%eax),%eax
80104398:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
8010439c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010439f:	8b 00                	mov    (%eax),%eax
801043a1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801043a4:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
801043a7:	b8 00 00 00 00       	mov    $0x0,%eax
801043ac:	eb 43                	jmp    801043f1 <pipealloc+0x141>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
801043ae:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
801043af:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801043b3:	74 0b                	je     801043c0 <pipealloc+0x110>
    kfree((char*)p);
801043b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043b8:	89 04 24             	mov    %eax,(%esp)
801043bb:	e8 1e ed ff ff       	call   801030de <kfree>
  if(*f0)
801043c0:	8b 45 08             	mov    0x8(%ebp),%eax
801043c3:	8b 00                	mov    (%eax),%eax
801043c5:	85 c0                	test   %eax,%eax
801043c7:	74 0d                	je     801043d6 <pipealloc+0x126>
    fileclose(*f0);
801043c9:	8b 45 08             	mov    0x8(%ebp),%eax
801043cc:	8b 00                	mov    (%eax),%eax
801043ce:	89 04 24             	mov    %eax,(%esp)
801043d1:	e8 66 d2 ff ff       	call   8010163c <fileclose>
  if(*f1)
801043d6:	8b 45 0c             	mov    0xc(%ebp),%eax
801043d9:	8b 00                	mov    (%eax),%eax
801043db:	85 c0                	test   %eax,%eax
801043dd:	74 0d                	je     801043ec <pipealloc+0x13c>
    fileclose(*f1);
801043df:	8b 45 0c             	mov    0xc(%ebp),%eax
801043e2:	8b 00                	mov    (%eax),%eax
801043e4:	89 04 24             	mov    %eax,(%esp)
801043e7:	e8 50 d2 ff ff       	call   8010163c <fileclose>
  return -1;
801043ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801043f1:	c9                   	leave  
801043f2:	c3                   	ret    

801043f3 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
801043f3:	55                   	push   %ebp
801043f4:	89 e5                	mov    %esp,%ebp
801043f6:	83 ec 18             	sub    $0x18,%esp
  acquire(&p->lock);
801043f9:	8b 45 08             	mov    0x8(%ebp),%eax
801043fc:	89 04 24             	mov    %eax,(%esp)
801043ff:	e8 17 0e 00 00       	call   8010521b <acquire>
  if(writable){
80104404:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104408:	74 1f                	je     80104429 <pipeclose+0x36>
    p->writeopen = 0;
8010440a:	8b 45 08             	mov    0x8(%ebp),%eax
8010440d:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80104414:	00 00 00 
    wakeup(&p->nread);
80104417:	8b 45 08             	mov    0x8(%ebp),%eax
8010441a:	05 34 02 00 00       	add    $0x234,%eax
8010441f:	89 04 24             	mov    %eax,(%esp)
80104422:	e8 ef 0b 00 00       	call   80105016 <wakeup>
80104427:	eb 1d                	jmp    80104446 <pipeclose+0x53>
  } else {
    p->readopen = 0;
80104429:	8b 45 08             	mov    0x8(%ebp),%eax
8010442c:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80104433:	00 00 00 
    wakeup(&p->nwrite);
80104436:	8b 45 08             	mov    0x8(%ebp),%eax
80104439:	05 38 02 00 00       	add    $0x238,%eax
8010443e:	89 04 24             	mov    %eax,(%esp)
80104441:	e8 d0 0b 00 00       	call   80105016 <wakeup>
  }
  if(p->readopen == 0 && p->writeopen == 0){
80104446:	8b 45 08             	mov    0x8(%ebp),%eax
80104449:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
8010444f:	85 c0                	test   %eax,%eax
80104451:	75 25                	jne    80104478 <pipeclose+0x85>
80104453:	8b 45 08             	mov    0x8(%ebp),%eax
80104456:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010445c:	85 c0                	test   %eax,%eax
8010445e:	75 18                	jne    80104478 <pipeclose+0x85>
    release(&p->lock);
80104460:	8b 45 08             	mov    0x8(%ebp),%eax
80104463:	89 04 24             	mov    %eax,(%esp)
80104466:	e8 12 0e 00 00       	call   8010527d <release>
    kfree((char*)p);
8010446b:	8b 45 08             	mov    0x8(%ebp),%eax
8010446e:	89 04 24             	mov    %eax,(%esp)
80104471:	e8 68 ec ff ff       	call   801030de <kfree>
80104476:	eb 0b                	jmp    80104483 <pipeclose+0x90>
  } else
    release(&p->lock);
80104478:	8b 45 08             	mov    0x8(%ebp),%eax
8010447b:	89 04 24             	mov    %eax,(%esp)
8010447e:	e8 fa 0d 00 00       	call   8010527d <release>
}
80104483:	c9                   	leave  
80104484:	c3                   	ret    

80104485 <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80104485:	55                   	push   %ebp
80104486:	89 e5                	mov    %esp,%ebp
80104488:	53                   	push   %ebx
80104489:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010448c:	8b 45 08             	mov    0x8(%ebp),%eax
8010448f:	89 04 24             	mov    %eax,(%esp)
80104492:	e8 84 0d 00 00       	call   8010521b <acquire>
  for(i = 0; i < n; i++){
80104497:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010449e:	e9 a6 00 00 00       	jmp    80104549 <pipewrite+0xc4>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || proc->killed){
801044a3:	8b 45 08             	mov    0x8(%ebp),%eax
801044a6:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
801044ac:	85 c0                	test   %eax,%eax
801044ae:	74 0d                	je     801044bd <pipewrite+0x38>
801044b0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801044b6:	8b 40 24             	mov    0x24(%eax),%eax
801044b9:	85 c0                	test   %eax,%eax
801044bb:	74 15                	je     801044d2 <pipewrite+0x4d>
        release(&p->lock);
801044bd:	8b 45 08             	mov    0x8(%ebp),%eax
801044c0:	89 04 24             	mov    %eax,(%esp)
801044c3:	e8 b5 0d 00 00       	call   8010527d <release>
        return -1;
801044c8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801044cd:	e9 9d 00 00 00       	jmp    8010456f <pipewrite+0xea>
      }
      wakeup(&p->nread);
801044d2:	8b 45 08             	mov    0x8(%ebp),%eax
801044d5:	05 34 02 00 00       	add    $0x234,%eax
801044da:	89 04 24             	mov    %eax,(%esp)
801044dd:	e8 34 0b 00 00       	call   80105016 <wakeup>
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
801044e2:	8b 45 08             	mov    0x8(%ebp),%eax
801044e5:	8b 55 08             	mov    0x8(%ebp),%edx
801044e8:	81 c2 38 02 00 00    	add    $0x238,%edx
801044ee:	89 44 24 04          	mov    %eax,0x4(%esp)
801044f2:	89 14 24             	mov    %edx,(%esp)
801044f5:	e8 43 0a 00 00       	call   80104f3d <sleep>
801044fa:	eb 01                	jmp    801044fd <pipewrite+0x78>
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
801044fc:	90                   	nop
801044fd:	8b 45 08             	mov    0x8(%ebp),%eax
80104500:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104506:	8b 45 08             	mov    0x8(%ebp),%eax
80104509:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010450f:	05 00 02 00 00       	add    $0x200,%eax
80104514:	39 c2                	cmp    %eax,%edx
80104516:	74 8b                	je     801044a3 <pipewrite+0x1e>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104518:	8b 45 08             	mov    0x8(%ebp),%eax
8010451b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104521:	89 c3                	mov    %eax,%ebx
80104523:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
80104529:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010452c:	03 55 0c             	add    0xc(%ebp),%edx
8010452f:	0f b6 0a             	movzbl (%edx),%ecx
80104532:	8b 55 08             	mov    0x8(%ebp),%edx
80104535:	88 4c 1a 34          	mov    %cl,0x34(%edx,%ebx,1)
80104539:	8d 50 01             	lea    0x1(%eax),%edx
8010453c:	8b 45 08             	mov    0x8(%ebp),%eax
8010453f:	89 90 38 02 00 00    	mov    %edx,0x238(%eax)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104545:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104549:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010454c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010454f:	7c ab                	jl     801044fc <pipewrite+0x77>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104551:	8b 45 08             	mov    0x8(%ebp),%eax
80104554:	05 34 02 00 00       	add    $0x234,%eax
80104559:	89 04 24             	mov    %eax,(%esp)
8010455c:	e8 b5 0a 00 00       	call   80105016 <wakeup>
  release(&p->lock);
80104561:	8b 45 08             	mov    0x8(%ebp),%eax
80104564:	89 04 24             	mov    %eax,(%esp)
80104567:	e8 11 0d 00 00       	call   8010527d <release>
  return n;
8010456c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010456f:	83 c4 24             	add    $0x24,%esp
80104572:	5b                   	pop    %ebx
80104573:	5d                   	pop    %ebp
80104574:	c3                   	ret    

80104575 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
80104575:	55                   	push   %ebp
80104576:	89 e5                	mov    %esp,%ebp
80104578:	53                   	push   %ebx
80104579:	83 ec 24             	sub    $0x24,%esp
  int i;

  acquire(&p->lock);
8010457c:	8b 45 08             	mov    0x8(%ebp),%eax
8010457f:	89 04 24             	mov    %eax,(%esp)
80104582:	e8 94 0c 00 00       	call   8010521b <acquire>
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
80104587:	eb 3a                	jmp    801045c3 <piperead+0x4e>
    if(proc->killed){
80104589:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010458f:	8b 40 24             	mov    0x24(%eax),%eax
80104592:	85 c0                	test   %eax,%eax
80104594:	74 15                	je     801045ab <piperead+0x36>
      release(&p->lock);
80104596:	8b 45 08             	mov    0x8(%ebp),%eax
80104599:	89 04 24             	mov    %eax,(%esp)
8010459c:	e8 dc 0c 00 00       	call   8010527d <release>
      return -1;
801045a1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045a6:	e9 b6 00 00 00       	jmp    80104661 <piperead+0xec>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801045ab:	8b 45 08             	mov    0x8(%ebp),%eax
801045ae:	8b 55 08             	mov    0x8(%ebp),%edx
801045b1:	81 c2 34 02 00 00    	add    $0x234,%edx
801045b7:	89 44 24 04          	mov    %eax,0x4(%esp)
801045bb:	89 14 24             	mov    %edx,(%esp)
801045be:	e8 7a 09 00 00       	call   80104f3d <sleep>
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801045c3:	8b 45 08             	mov    0x8(%ebp),%eax
801045c6:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801045cc:	8b 45 08             	mov    0x8(%ebp),%eax
801045cf:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
801045d5:	39 c2                	cmp    %eax,%edx
801045d7:	75 0d                	jne    801045e6 <piperead+0x71>
801045d9:	8b 45 08             	mov    0x8(%ebp),%eax
801045dc:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
801045e2:	85 c0                	test   %eax,%eax
801045e4:	75 a3                	jne    80104589 <piperead+0x14>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
801045e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801045ed:	eb 49                	jmp    80104638 <piperead+0xc3>
    if(p->nread == p->nwrite)
801045ef:	8b 45 08             	mov    0x8(%ebp),%eax
801045f2:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
801045f8:	8b 45 08             	mov    0x8(%ebp),%eax
801045fb:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104601:	39 c2                	cmp    %eax,%edx
80104603:	74 3d                	je     80104642 <piperead+0xcd>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104605:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104608:	89 c2                	mov    %eax,%edx
8010460a:	03 55 0c             	add    0xc(%ebp),%edx
8010460d:	8b 45 08             	mov    0x8(%ebp),%eax
80104610:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104616:	89 c3                	mov    %eax,%ebx
80104618:	81 e3 ff 01 00 00    	and    $0x1ff,%ebx
8010461e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104621:	0f b6 4c 19 34       	movzbl 0x34(%ecx,%ebx,1),%ecx
80104626:	88 0a                	mov    %cl,(%edx)
80104628:	8d 50 01             	lea    0x1(%eax),%edx
8010462b:	8b 45 08             	mov    0x8(%ebp),%eax
8010462e:	89 90 34 02 00 00    	mov    %edx,0x234(%eax)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104634:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010463b:	3b 45 10             	cmp    0x10(%ebp),%eax
8010463e:	7c af                	jl     801045ef <piperead+0x7a>
80104640:	eb 01                	jmp    80104643 <piperead+0xce>
    if(p->nread == p->nwrite)
      break;
80104642:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
80104643:	8b 45 08             	mov    0x8(%ebp),%eax
80104646:	05 38 02 00 00       	add    $0x238,%eax
8010464b:	89 04 24             	mov    %eax,(%esp)
8010464e:	e8 c3 09 00 00       	call   80105016 <wakeup>
  release(&p->lock);
80104653:	8b 45 08             	mov    0x8(%ebp),%eax
80104656:	89 04 24             	mov    %eax,(%esp)
80104659:	e8 1f 0c 00 00       	call   8010527d <release>
  return i;
8010465e:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104661:	83 c4 24             	add    $0x24,%esp
80104664:	5b                   	pop    %ebx
80104665:	5d                   	pop    %ebp
80104666:	c3                   	ret    
	...

80104668 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104668:	55                   	push   %ebp
80104669:	89 e5                	mov    %esp,%ebp
8010466b:	53                   	push   %ebx
8010466c:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
8010466f:	9c                   	pushf  
80104670:	5b                   	pop    %ebx
80104671:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
80104674:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80104677:	83 c4 10             	add    $0x10,%esp
8010467a:	5b                   	pop    %ebx
8010467b:	5d                   	pop    %ebp
8010467c:	c3                   	ret    

8010467d <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
8010467d:	55                   	push   %ebp
8010467e:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104680:	fb                   	sti    
}
80104681:	5d                   	pop    %ebp
80104682:	c3                   	ret    

80104683 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
80104683:	55                   	push   %ebp
80104684:	89 e5                	mov    %esp,%ebp
80104686:	83 ec 18             	sub    $0x18,%esp
  initlock(&ptable.lock, "ptable");
80104689:	c7 44 24 04 a5 8b 10 	movl   $0x80108ba5,0x4(%esp)
80104690:	80 
80104691:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104698:	e8 5d 0b 00 00       	call   801051fa <initlock>
}
8010469d:	c9                   	leave  
8010469e:	c3                   	ret    

8010469f <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
8010469f:	55                   	push   %ebp
801046a0:	89 e5                	mov    %esp,%ebp
801046a2:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801046a5:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
801046ac:	e8 6a 0b 00 00       	call   8010521b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801046b1:	c7 45 f4 b4 0e 11 80 	movl   $0x80110eb4,-0xc(%ebp)
801046b8:	eb 0e                	jmp    801046c8 <allocproc+0x29>
    if(p->state == UNUSED)
801046ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046bd:	8b 40 0c             	mov    0xc(%eax),%eax
801046c0:	85 c0                	test   %eax,%eax
801046c2:	74 23                	je     801046e7 <allocproc+0x48>
{
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801046c4:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801046c8:	81 7d f4 b4 2d 11 80 	cmpl   $0x80112db4,-0xc(%ebp)
801046cf:	72 e9                	jb     801046ba <allocproc+0x1b>
    if(p->state == UNUSED)
      goto found;
  release(&ptable.lock);
801046d1:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
801046d8:	e8 a0 0b 00 00       	call   8010527d <release>
  return 0;
801046dd:	b8 00 00 00 00       	mov    $0x0,%eax
801046e2:	e9 b5 00 00 00       	jmp    8010479c <allocproc+0xfd>
  char *sp;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
801046e7:	90                   	nop
  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
801046e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801046eb:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
801046f2:	a1 04 b0 10 80       	mov    0x8010b004,%eax
801046f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
801046fa:	89 42 10             	mov    %eax,0x10(%edx)
801046fd:	83 c0 01             	add    $0x1,%eax
80104700:	a3 04 b0 10 80       	mov    %eax,0x8010b004
  release(&ptable.lock);
80104705:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
8010470c:	e8 6c 0b 00 00       	call   8010527d <release>

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104711:	e8 61 ea ff ff       	call   80103177 <kalloc>
80104716:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104719:	89 42 08             	mov    %eax,0x8(%edx)
8010471c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010471f:	8b 40 08             	mov    0x8(%eax),%eax
80104722:	85 c0                	test   %eax,%eax
80104724:	75 11                	jne    80104737 <allocproc+0x98>
    p->state = UNUSED;
80104726:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104729:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104730:	b8 00 00 00 00       	mov    $0x0,%eax
80104735:	eb 65                	jmp    8010479c <allocproc+0xfd>
  }
  sp = p->kstack + KSTACKSIZE;
80104737:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010473a:	8b 40 08             	mov    0x8(%eax),%eax
8010473d:	05 00 10 00 00       	add    $0x1000,%eax
80104742:	89 45 f0             	mov    %eax,-0x10(%ebp)
  
  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104745:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
80104749:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010474c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010474f:	89 50 18             	mov    %edx,0x18(%eax)
  
  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104752:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104756:	ba 78 69 10 80       	mov    $0x80106978,%edx
8010475b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010475e:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104760:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104764:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104767:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010476a:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010476d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104770:	8b 40 1c             	mov    0x1c(%eax),%eax
80104773:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
8010477a:	00 
8010477b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104782:	00 
80104783:	89 04 24             	mov    %eax,(%esp)
80104786:	e8 df 0c 00 00       	call   8010546a <memset>
  p->context->eip = (uint)forkret;
8010478b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010478e:	8b 40 1c             	mov    0x1c(%eax),%eax
80104791:	ba 11 4f 10 80       	mov    $0x80104f11,%edx
80104796:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
80104799:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010479c:	c9                   	leave  
8010479d:	c3                   	ret    

8010479e <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
8010479e:	55                   	push   %ebp
8010479f:	89 e5                	mov    %esp,%ebp
801047a1:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];
  
  p = allocproc();
801047a4:	e8 f6 fe ff ff       	call   8010469f <allocproc>
801047a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  initproc = p;
801047ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047af:	a3 68 c0 10 80       	mov    %eax,0x8010c068
  if((p->pgdir = setupkvm(kalloc)) == 0)
801047b4:	c7 04 24 77 31 10 80 	movl   $0x80103177,(%esp)
801047bb:	e8 b5 38 00 00       	call   80108075 <setupkvm>
801047c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
801047c3:	89 42 04             	mov    %eax,0x4(%edx)
801047c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047c9:	8b 40 04             	mov    0x4(%eax),%eax
801047cc:	85 c0                	test   %eax,%eax
801047ce:	75 0c                	jne    801047dc <userinit+0x3e>
    panic("userinit: out of memory?");
801047d0:	c7 04 24 ac 8b 10 80 	movl   $0x80108bac,(%esp)
801047d7:	e8 61 bd ff ff       	call   8010053d <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801047dc:	ba 2c 00 00 00       	mov    $0x2c,%edx
801047e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047e4:	8b 40 04             	mov    0x4(%eax),%eax
801047e7:	89 54 24 08          	mov    %edx,0x8(%esp)
801047eb:	c7 44 24 04 e0 b4 10 	movl   $0x8010b4e0,0x4(%esp)
801047f2:	80 
801047f3:	89 04 24             	mov    %eax,(%esp)
801047f6:	e8 d2 3a 00 00       	call   801082cd <inituvm>
  p->sz = PGSIZE;
801047fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047fe:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104804:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104807:	8b 40 18             	mov    0x18(%eax),%eax
8010480a:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
80104811:	00 
80104812:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80104819:	00 
8010481a:	89 04 24             	mov    %eax,(%esp)
8010481d:	e8 48 0c 00 00       	call   8010546a <memset>
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
80104822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104825:	8b 40 18             	mov    0x18(%eax),%eax
80104828:	66 c7 40 3c 23 00    	movw   $0x23,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
8010482e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104831:	8b 40 18             	mov    0x18(%eax),%eax
80104834:	66 c7 40 2c 2b 00    	movw   $0x2b,0x2c(%eax)
  p->tf->es = p->tf->ds;
8010483a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010483d:	8b 40 18             	mov    0x18(%eax),%eax
80104840:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104843:	8b 52 18             	mov    0x18(%edx),%edx
80104846:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010484a:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
8010484e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104851:	8b 40 18             	mov    0x18(%eax),%eax
80104854:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104857:	8b 52 18             	mov    0x18(%edx),%edx
8010485a:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
8010485e:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
80104862:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104865:	8b 40 18             	mov    0x18(%eax),%eax
80104868:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010486f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104872:	8b 40 18             	mov    0x18(%eax),%eax
80104875:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
8010487c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010487f:	8b 40 18             	mov    0x18(%eax),%eax
80104882:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104889:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010488c:	83 c0 6c             	add    $0x6c,%eax
8010488f:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104896:	00 
80104897:	c7 44 24 04 c5 8b 10 	movl   $0x80108bc5,0x4(%esp)
8010489e:	80 
8010489f:	89 04 24             	mov    %eax,(%esp)
801048a2:	e8 f3 0d 00 00       	call   8010569a <safestrcpy>
  p->cwd = namei("/");
801048a7:	c7 04 24 ce 8b 10 80 	movl   $0x80108bce,(%esp)
801048ae:	e8 cf e1 ff ff       	call   80102a82 <namei>
801048b3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048b6:	89 42 68             	mov    %eax,0x68(%edx)

  p->state = RUNNABLE;
801048b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048bc:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
}
801048c3:	c9                   	leave  
801048c4:	c3                   	ret    

801048c5 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801048c5:	55                   	push   %ebp
801048c6:	89 e5                	mov    %esp,%ebp
801048c8:	83 ec 28             	sub    $0x28,%esp
  uint sz;
  
  sz = proc->sz;
801048cb:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048d1:	8b 00                	mov    (%eax),%eax
801048d3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
801048d6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801048da:	7e 34                	jle    80104910 <growproc+0x4b>
    if((sz = allocuvm(proc->pgdir, sz, sz + n)) == 0)
801048dc:	8b 45 08             	mov    0x8(%ebp),%eax
801048df:	89 c2                	mov    %eax,%edx
801048e1:	03 55 f4             	add    -0xc(%ebp),%edx
801048e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801048ea:	8b 40 04             	mov    0x4(%eax),%eax
801048ed:	89 54 24 08          	mov    %edx,0x8(%esp)
801048f1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801048f4:	89 54 24 04          	mov    %edx,0x4(%esp)
801048f8:	89 04 24             	mov    %eax,(%esp)
801048fb:	e8 47 3b 00 00       	call   80108447 <allocuvm>
80104900:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104903:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104907:	75 41                	jne    8010494a <growproc+0x85>
      return -1;
80104909:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010490e:	eb 58                	jmp    80104968 <growproc+0xa3>
  } else if(n < 0){
80104910:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104914:	79 34                	jns    8010494a <growproc+0x85>
    if((sz = deallocuvm(proc->pgdir, sz, sz + n)) == 0)
80104916:	8b 45 08             	mov    0x8(%ebp),%eax
80104919:	89 c2                	mov    %eax,%edx
8010491b:	03 55 f4             	add    -0xc(%ebp),%edx
8010491e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104924:	8b 40 04             	mov    0x4(%eax),%eax
80104927:	89 54 24 08          	mov    %edx,0x8(%esp)
8010492b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010492e:	89 54 24 04          	mov    %edx,0x4(%esp)
80104932:	89 04 24             	mov    %eax,(%esp)
80104935:	e8 e7 3b 00 00       	call   80108521 <deallocuvm>
8010493a:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010493d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104941:	75 07                	jne    8010494a <growproc+0x85>
      return -1;
80104943:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104948:	eb 1e                	jmp    80104968 <growproc+0xa3>
  }
  proc->sz = sz;
8010494a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104950:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104953:	89 10                	mov    %edx,(%eax)
  switchuvm(proc);
80104955:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010495b:	89 04 24             	mov    %eax,(%esp)
8010495e:	e8 03 38 00 00       	call   80108166 <switchuvm>
  return 0;
80104963:	b8 00 00 00 00       	mov    $0x0,%eax
}
80104968:	c9                   	leave  
80104969:	c3                   	ret    

8010496a <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010496a:	55                   	push   %ebp
8010496b:	89 e5                	mov    %esp,%ebp
8010496d:	57                   	push   %edi
8010496e:	56                   	push   %esi
8010496f:	53                   	push   %ebx
80104970:	83 ec 2c             	sub    $0x2c,%esp
  int i, pid;
  struct proc *np;

  // Allocate process.
  if((np = allocproc()) == 0)
80104973:	e8 27 fd ff ff       	call   8010469f <allocproc>
80104978:	89 45 e0             	mov    %eax,-0x20(%ebp)
8010497b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
8010497f:	75 0a                	jne    8010498b <fork+0x21>
    return -1;
80104981:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104986:	e9 3a 01 00 00       	jmp    80104ac5 <fork+0x15b>

  // Copy process state from p.
  if((np->pgdir = copyuvm(proc->pgdir, proc->sz)) == 0){
8010498b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104991:	8b 10                	mov    (%eax),%edx
80104993:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104999:	8b 40 04             	mov    0x4(%eax),%eax
8010499c:	89 54 24 04          	mov    %edx,0x4(%esp)
801049a0:	89 04 24             	mov    %eax,(%esp)
801049a3:	e8 09 3d 00 00       	call   801086b1 <copyuvm>
801049a8:	8b 55 e0             	mov    -0x20(%ebp),%edx
801049ab:	89 42 04             	mov    %eax,0x4(%edx)
801049ae:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049b1:	8b 40 04             	mov    0x4(%eax),%eax
801049b4:	85 c0                	test   %eax,%eax
801049b6:	75 2c                	jne    801049e4 <fork+0x7a>
    kfree(np->kstack);
801049b8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049bb:	8b 40 08             	mov    0x8(%eax),%eax
801049be:	89 04 24             	mov    %eax,(%esp)
801049c1:	e8 18 e7 ff ff       	call   801030de <kfree>
    np->kstack = 0;
801049c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049c9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801049d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049d3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
801049da:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801049df:	e9 e1 00 00 00       	jmp    80104ac5 <fork+0x15b>
  }
  np->sz = proc->sz;
801049e4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801049ea:	8b 10                	mov    (%eax),%edx
801049ec:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049ef:	89 10                	mov    %edx,(%eax)
  np->parent = proc;
801049f1:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
801049f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
801049fb:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *proc->tf;
801049fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a01:	8b 50 18             	mov    0x18(%eax),%edx
80104a04:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a0a:	8b 40 18             	mov    0x18(%eax),%eax
80104a0d:	89 c3                	mov    %eax,%ebx
80104a0f:	b8 13 00 00 00       	mov    $0x13,%eax
80104a14:	89 d7                	mov    %edx,%edi
80104a16:	89 de                	mov    %ebx,%esi
80104a18:	89 c1                	mov    %eax,%ecx
80104a1a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
80104a1c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a1f:	8b 40 18             	mov    0x18(%eax),%eax
80104a22:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
80104a29:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104a30:	eb 3d                	jmp    80104a6f <fork+0x105>
    if(proc->ofile[i])
80104a32:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a38:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104a3b:	83 c2 08             	add    $0x8,%edx
80104a3e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104a42:	85 c0                	test   %eax,%eax
80104a44:	74 25                	je     80104a6b <fork+0x101>
      np->ofile[i] = filedup(proc->ofile[i]);
80104a46:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a4c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104a4f:	83 c2 08             	add    $0x8,%edx
80104a52:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104a56:	89 04 24             	mov    %eax,(%esp)
80104a59:	e8 96 cb ff ff       	call   801015f4 <filedup>
80104a5e:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104a61:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
80104a64:	83 c1 08             	add    $0x8,%ecx
80104a67:	89 44 8a 08          	mov    %eax,0x8(%edx,%ecx,4)
  *np->tf = *proc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
80104a6b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104a6f:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104a73:	7e bd                	jle    80104a32 <fork+0xc8>
    if(proc->ofile[i])
      np->ofile[i] = filedup(proc->ofile[i]);
  np->cwd = idup(proc->cwd);
80104a75:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104a7b:	8b 40 68             	mov    0x68(%eax),%eax
80104a7e:	89 04 24             	mov    %eax,(%esp)
80104a81:	e8 28 d4 ff ff       	call   80101eae <idup>
80104a86:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104a89:	89 42 68             	mov    %eax,0x68(%edx)
 
  pid = np->pid;
80104a8c:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a8f:	8b 40 10             	mov    0x10(%eax),%eax
80104a92:	89 45 dc             	mov    %eax,-0x24(%ebp)
  np->state = RUNNABLE;
80104a95:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104a98:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  safestrcpy(np->name, proc->name, sizeof(proc->name));
80104a9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104aa5:	8d 50 6c             	lea    0x6c(%eax),%edx
80104aa8:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104aab:	83 c0 6c             	add    $0x6c,%eax
80104aae:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80104ab5:	00 
80104ab6:	89 54 24 04          	mov    %edx,0x4(%esp)
80104aba:	89 04 24             	mov    %eax,(%esp)
80104abd:	e8 d8 0b 00 00       	call   8010569a <safestrcpy>
  return pid;
80104ac2:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
80104ac5:	83 c4 2c             	add    $0x2c,%esp
80104ac8:	5b                   	pop    %ebx
80104ac9:	5e                   	pop    %esi
80104aca:	5f                   	pop    %edi
80104acb:	5d                   	pop    %ebp
80104acc:	c3                   	ret    

80104acd <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
80104acd:	55                   	push   %ebp
80104ace:	89 e5                	mov    %esp,%ebp
80104ad0:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int fd;

  if(proc == initproc)
80104ad3:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104ada:	a1 68 c0 10 80       	mov    0x8010c068,%eax
80104adf:	39 c2                	cmp    %eax,%edx
80104ae1:	75 0c                	jne    80104aef <exit+0x22>
    panic("init exiting");
80104ae3:	c7 04 24 d0 8b 10 80 	movl   $0x80108bd0,(%esp)
80104aea:	e8 4e ba ff ff       	call   8010053d <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104aef:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104af6:	eb 44                	jmp    80104b3c <exit+0x6f>
    if(proc->ofile[fd]){
80104af8:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104afe:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b01:	83 c2 08             	add    $0x8,%edx
80104b04:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104b08:	85 c0                	test   %eax,%eax
80104b0a:	74 2c                	je     80104b38 <exit+0x6b>
      fileclose(proc->ofile[fd]);
80104b0c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b12:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b15:	83 c2 08             	add    $0x8,%edx
80104b18:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104b1c:	89 04 24             	mov    %eax,(%esp)
80104b1f:	e8 18 cb ff ff       	call   8010163c <fileclose>
      proc->ofile[fd] = 0;
80104b24:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b2a:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104b2d:	83 c2 08             	add    $0x8,%edx
80104b30:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104b37:	00 

  if(proc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104b38:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104b3c:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
80104b40:	7e b6                	jle    80104af8 <exit+0x2b>
      fileclose(proc->ofile[fd]);
      proc->ofile[fd] = 0;
    }
  }

  iput(proc->cwd);
80104b42:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b48:	8b 40 68             	mov    0x68(%eax),%eax
80104b4b:	89 04 24             	mov    %eax,(%esp)
80104b4e:	e8 40 d5 ff ff       	call   80102093 <iput>
  proc->cwd = 0;
80104b53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b59:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
80104b60:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104b67:	e8 af 06 00 00       	call   8010521b <acquire>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);
80104b6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b72:	8b 40 14             	mov    0x14(%eax),%eax
80104b75:	89 04 24             	mov    %eax,(%esp)
80104b78:	e8 5b 04 00 00       	call   80104fd8 <wakeup1>

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104b7d:	c7 45 f4 b4 0e 11 80 	movl   $0x80110eb4,-0xc(%ebp)
80104b84:	eb 38                	jmp    80104bbe <exit+0xf1>
    if(p->parent == proc){
80104b86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b89:	8b 50 14             	mov    0x14(%eax),%edx
80104b8c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104b92:	39 c2                	cmp    %eax,%edx
80104b94:	75 24                	jne    80104bba <exit+0xed>
      p->parent = initproc;
80104b96:	8b 15 68 c0 10 80    	mov    0x8010c068,%edx
80104b9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9f:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
80104ba2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba5:	8b 40 0c             	mov    0xc(%eax),%eax
80104ba8:	83 f8 05             	cmp    $0x5,%eax
80104bab:	75 0d                	jne    80104bba <exit+0xed>
        wakeup1(initproc);
80104bad:	a1 68 c0 10 80       	mov    0x8010c068,%eax
80104bb2:	89 04 24             	mov    %eax,(%esp)
80104bb5:	e8 1e 04 00 00       	call   80104fd8 <wakeup1>

  // Parent might be sleeping in wait().
  wakeup1(proc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bba:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104bbe:	81 7d f4 b4 2d 11 80 	cmpl   $0x80112db4,-0xc(%ebp)
80104bc5:	72 bf                	jb     80104b86 <exit+0xb9>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  proc->state = ZOMBIE;
80104bc7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104bcd:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104bd4:	e8 54 02 00 00       	call   80104e2d <sched>
  panic("zombie exit");
80104bd9:	c7 04 24 dd 8b 10 80 	movl   $0x80108bdd,(%esp)
80104be0:	e8 58 b9 ff ff       	call   8010053d <panic>

80104be5 <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
80104be5:	55                   	push   %ebp
80104be6:	89 e5                	mov    %esp,%ebp
80104be8:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;
  int havekids, pid;

  acquire(&ptable.lock);
80104beb:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104bf2:	e8 24 06 00 00       	call   8010521b <acquire>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
80104bf7:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104bfe:	c7 45 f4 b4 0e 11 80 	movl   $0x80110eb4,-0xc(%ebp)
80104c05:	e9 9a 00 00 00       	jmp    80104ca4 <wait+0xbf>
      if(p->parent != proc)
80104c0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c0d:	8b 50 14             	mov    0x14(%eax),%edx
80104c10:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104c16:	39 c2                	cmp    %eax,%edx
80104c18:	0f 85 81 00 00 00    	jne    80104c9f <wait+0xba>
        continue;
      havekids = 1;
80104c1e:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104c25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c28:	8b 40 0c             	mov    0xc(%eax),%eax
80104c2b:	83 f8 05             	cmp    $0x5,%eax
80104c2e:	75 70                	jne    80104ca0 <wait+0xbb>
        // Found one.
        pid = p->pid;
80104c30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c33:	8b 40 10             	mov    0x10(%eax),%eax
80104c36:	89 45 ec             	mov    %eax,-0x14(%ebp)
        kfree(p->kstack);
80104c39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c3c:	8b 40 08             	mov    0x8(%eax),%eax
80104c3f:	89 04 24             	mov    %eax,(%esp)
80104c42:	e8 97 e4 ff ff       	call   801030de <kfree>
        p->kstack = 0;
80104c47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c4a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
80104c51:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c54:	8b 40 04             	mov    0x4(%eax),%eax
80104c57:	89 04 24             	mov    %eax,(%esp)
80104c5a:	e8 7e 39 00 00       	call   801085dd <freevm>
        p->state = UNUSED;
80104c5f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c62:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        p->pid = 0;
80104c69:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c6c:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
80104c73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c76:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
80104c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c80:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
80104c84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c87:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        release(&ptable.lock);
80104c8e:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104c95:	e8 e3 05 00 00       	call   8010527d <release>
        return pid;
80104c9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104c9d:	eb 53                	jmp    80104cf2 <wait+0x10d>
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != proc)
        continue;
80104c9f:	90                   	nop

  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for zombie children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ca0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104ca4:	81 7d f4 b4 2d 11 80 	cmpl   $0x80112db4,-0xc(%ebp)
80104cab:	0f 82 59 ff ff ff    	jb     80104c0a <wait+0x25>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || proc->killed){
80104cb1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80104cb5:	74 0d                	je     80104cc4 <wait+0xdf>
80104cb7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cbd:	8b 40 24             	mov    0x24(%eax),%eax
80104cc0:	85 c0                	test   %eax,%eax
80104cc2:	74 13                	je     80104cd7 <wait+0xf2>
      release(&ptable.lock);
80104cc4:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104ccb:	e8 ad 05 00 00       	call   8010527d <release>
      return -1;
80104cd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80104cd5:	eb 1b                	jmp    80104cf2 <wait+0x10d>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(proc, &ptable.lock);  //DOC: wait-sleep
80104cd7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104cdd:	c7 44 24 04 80 0e 11 	movl   $0x80110e80,0x4(%esp)
80104ce4:	80 
80104ce5:	89 04 24             	mov    %eax,(%esp)
80104ce8:	e8 50 02 00 00       	call   80104f3d <sleep>
  }
80104ced:	e9 05 ff ff ff       	jmp    80104bf7 <wait+0x12>
}
80104cf2:	c9                   	leave  
80104cf3:	c3                   	ret    

80104cf4 <register_handler>:

void
register_handler(sighandler_t sighandler)
{
80104cf4:	55                   	push   %ebp
80104cf5:	89 e5                	mov    %esp,%ebp
80104cf7:	83 ec 28             	sub    $0x28,%esp
  char* addr = uva2ka(proc->pgdir, (char*)proc->tf->esp);
80104cfa:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d00:	8b 40 18             	mov    0x18(%eax),%eax
80104d03:	8b 40 44             	mov    0x44(%eax),%eax
80104d06:	89 c2                	mov    %eax,%edx
80104d08:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d0e:	8b 40 04             	mov    0x4(%eax),%eax
80104d11:	89 54 24 04          	mov    %edx,0x4(%esp)
80104d15:	89 04 24             	mov    %eax,(%esp)
80104d18:	e8 a5 3a 00 00       	call   801087c2 <uva2ka>
80104d1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if ((proc->tf->esp & 0xFFF) == 0)
80104d20:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d26:	8b 40 18             	mov    0x18(%eax),%eax
80104d29:	8b 40 44             	mov    0x44(%eax),%eax
80104d2c:	25 ff 0f 00 00       	and    $0xfff,%eax
80104d31:	85 c0                	test   %eax,%eax
80104d33:	75 0c                	jne    80104d41 <register_handler+0x4d>
    panic("esp_offset == 0");
80104d35:	c7 04 24 e9 8b 10 80 	movl   $0x80108be9,(%esp)
80104d3c:	e8 fc b7 ff ff       	call   8010053d <panic>

    /* open a new frame */
  *(int*)(addr + ((proc->tf->esp - 4) & 0xFFF))
80104d41:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d47:	8b 40 18             	mov    0x18(%eax),%eax
80104d4a:	8b 40 44             	mov    0x44(%eax),%eax
80104d4d:	83 e8 04             	sub    $0x4,%eax
80104d50:	25 ff 0f 00 00       	and    $0xfff,%eax
80104d55:	03 45 f4             	add    -0xc(%ebp),%eax
          = proc->tf->eip;
80104d58:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104d5f:	8b 52 18             	mov    0x18(%edx),%edx
80104d62:	8b 52 38             	mov    0x38(%edx),%edx
80104d65:	89 10                	mov    %edx,(%eax)
  proc->tf->esp -= 4;
80104d67:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d6d:	8b 40 18             	mov    0x18(%eax),%eax
80104d70:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104d77:	8b 52 18             	mov    0x18(%edx),%edx
80104d7a:	8b 52 44             	mov    0x44(%edx),%edx
80104d7d:	83 ea 04             	sub    $0x4,%edx
80104d80:	89 50 44             	mov    %edx,0x44(%eax)

    /* update eip */
  proc->tf->eip = (uint)sighandler;
80104d83:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104d89:	8b 40 18             	mov    0x18(%eax),%eax
80104d8c:	8b 55 08             	mov    0x8(%ebp),%edx
80104d8f:	89 50 38             	mov    %edx,0x38(%eax)
}
80104d92:	c9                   	leave  
80104d93:	c3                   	ret    

80104d94 <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
80104d94:	55                   	push   %ebp
80104d95:	89 e5                	mov    %esp,%ebp
80104d97:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  for(;;){
    // Enable interrupts on this processor.
    sti();
80104d9a:	e8 de f8 ff ff       	call   8010467d <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
80104d9f:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104da6:	e8 70 04 00 00       	call   8010521b <acquire>
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104dab:	c7 45 f4 b4 0e 11 80 	movl   $0x80110eb4,-0xc(%ebp)
80104db2:	eb 5f                	jmp    80104e13 <scheduler+0x7f>
      if(p->state != RUNNABLE)
80104db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104db7:	8b 40 0c             	mov    0xc(%eax),%eax
80104dba:	83 f8 03             	cmp    $0x3,%eax
80104dbd:	75 4f                	jne    80104e0e <scheduler+0x7a>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      proc = p;
80104dbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dc2:	65 a3 04 00 00 00    	mov    %eax,%gs:0x4
      switchuvm(p);
80104dc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dcb:	89 04 24             	mov    %eax,(%esp)
80104dce:	e8 93 33 00 00       	call   80108166 <switchuvm>
      p->state = RUNNING;
80104dd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104dd6:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)
      swtch(&cpu->scheduler, proc->context);
80104ddd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104de3:	8b 40 1c             	mov    0x1c(%eax),%eax
80104de6:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80104ded:	83 c2 04             	add    $0x4,%edx
80104df0:	89 44 24 04          	mov    %eax,0x4(%esp)
80104df4:	89 14 24             	mov    %edx,(%esp)
80104df7:	e8 14 09 00 00       	call   80105710 <swtch>
      switchkvm();
80104dfc:	e8 48 33 00 00       	call   80108149 <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
80104e01:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80104e08:	00 00 00 00 
80104e0c:	eb 01                	jmp    80104e0f <scheduler+0x7b>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
80104e0e:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104e0f:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104e13:	81 7d f4 b4 2d 11 80 	cmpl   $0x80112db4,-0xc(%ebp)
80104e1a:	72 98                	jb     80104db4 <scheduler+0x20>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      proc = 0;
    }
    release(&ptable.lock);
80104e1c:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104e23:	e8 55 04 00 00       	call   8010527d <release>

  }
80104e28:	e9 6d ff ff ff       	jmp    80104d9a <scheduler+0x6>

80104e2d <sched>:

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void
sched(void)
{
80104e2d:	55                   	push   %ebp
80104e2e:	89 e5                	mov    %esp,%ebp
80104e30:	83 ec 28             	sub    $0x28,%esp
  int intena;

  if(!holding(&ptable.lock))
80104e33:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104e3a:	e8 fa 04 00 00       	call   80105339 <holding>
80104e3f:	85 c0                	test   %eax,%eax
80104e41:	75 0c                	jne    80104e4f <sched+0x22>
    panic("sched ptable.lock");
80104e43:	c7 04 24 f9 8b 10 80 	movl   $0x80108bf9,(%esp)
80104e4a:	e8 ee b6 ff ff       	call   8010053d <panic>
  if(cpu->ncli != 1)
80104e4f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104e55:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80104e5b:	83 f8 01             	cmp    $0x1,%eax
80104e5e:	74 0c                	je     80104e6c <sched+0x3f>
    panic("sched locks");
80104e60:	c7 04 24 0b 8c 10 80 	movl   $0x80108c0b,(%esp)
80104e67:	e8 d1 b6 ff ff       	call   8010053d <panic>
  if(proc->state == RUNNING)
80104e6c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104e72:	8b 40 0c             	mov    0xc(%eax),%eax
80104e75:	83 f8 04             	cmp    $0x4,%eax
80104e78:	75 0c                	jne    80104e86 <sched+0x59>
    panic("sched running");
80104e7a:	c7 04 24 17 8c 10 80 	movl   $0x80108c17,(%esp)
80104e81:	e8 b7 b6 ff ff       	call   8010053d <panic>
  if(readeflags()&FL_IF)
80104e86:	e8 dd f7 ff ff       	call   80104668 <readeflags>
80104e8b:	25 00 02 00 00       	and    $0x200,%eax
80104e90:	85 c0                	test   %eax,%eax
80104e92:	74 0c                	je     80104ea0 <sched+0x73>
    panic("sched interruptible");
80104e94:	c7 04 24 25 8c 10 80 	movl   $0x80108c25,(%esp)
80104e9b:	e8 9d b6 ff ff       	call   8010053d <panic>
  intena = cpu->intena;
80104ea0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ea6:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80104eac:	89 45 f4             	mov    %eax,-0xc(%ebp)
  swtch(&proc->context, cpu->scheduler);
80104eaf:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104eb5:	8b 40 04             	mov    0x4(%eax),%eax
80104eb8:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
80104ebf:	83 c2 1c             	add    $0x1c,%edx
80104ec2:	89 44 24 04          	mov    %eax,0x4(%esp)
80104ec6:	89 14 24             	mov    %edx,(%esp)
80104ec9:	e8 42 08 00 00       	call   80105710 <swtch>
  cpu->intena = intena;
80104ece:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80104ed4:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104ed7:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
80104edd:	c9                   	leave  
80104ede:	c3                   	ret    

80104edf <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104edf:	55                   	push   %ebp
80104ee0:	89 e5                	mov    %esp,%ebp
80104ee2:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104ee5:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104eec:	e8 2a 03 00 00       	call   8010521b <acquire>
  proc->state = RUNNABLE;
80104ef1:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104ef7:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104efe:	e8 2a ff ff ff       	call   80104e2d <sched>
  release(&ptable.lock);
80104f03:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104f0a:	e8 6e 03 00 00       	call   8010527d <release>
}
80104f0f:	c9                   	leave  
80104f10:	c3                   	ret    

80104f11 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104f11:	55                   	push   %ebp
80104f12:	89 e5                	mov    %esp,%ebp
80104f14:	83 ec 18             	sub    $0x18,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104f17:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104f1e:	e8 5a 03 00 00       	call   8010527d <release>

  if (first) {
80104f23:	a1 20 b0 10 80       	mov    0x8010b020,%eax
80104f28:	85 c0                	test   %eax,%eax
80104f2a:	74 0f                	je     80104f3b <forkret+0x2a>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot 
    // be run from main().
    first = 0;
80104f2c:	c7 05 20 b0 10 80 00 	movl   $0x0,0x8010b020
80104f33:	00 00 00 
    initlog();
80104f36:	e8 4d e7 ff ff       	call   80103688 <initlog>
  }
  
  // Return to "caller", actually trapret (see allocproc).
}
80104f3b:	c9                   	leave  
80104f3c:	c3                   	ret    

80104f3d <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104f3d:	55                   	push   %ebp
80104f3e:	89 e5                	mov    %esp,%ebp
80104f40:	83 ec 18             	sub    $0x18,%esp
  if(proc == 0)
80104f43:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f49:	85 c0                	test   %eax,%eax
80104f4b:	75 0c                	jne    80104f59 <sleep+0x1c>
    panic("sleep");
80104f4d:	c7 04 24 39 8c 10 80 	movl   $0x80108c39,(%esp)
80104f54:	e8 e4 b5 ff ff       	call   8010053d <panic>

  if(lk == 0)
80104f59:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104f5d:	75 0c                	jne    80104f6b <sleep+0x2e>
    panic("sleep without lk");
80104f5f:	c7 04 24 3f 8c 10 80 	movl   $0x80108c3f,(%esp)
80104f66:	e8 d2 b5 ff ff       	call   8010053d <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104f6b:	81 7d 0c 80 0e 11 80 	cmpl   $0x80110e80,0xc(%ebp)
80104f72:	74 17                	je     80104f8b <sleep+0x4e>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104f74:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104f7b:	e8 9b 02 00 00       	call   8010521b <acquire>
    release(lk);
80104f80:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f83:	89 04 24             	mov    %eax,(%esp)
80104f86:	e8 f2 02 00 00       	call   8010527d <release>
  }

  // Go to sleep.
  proc->chan = chan;
80104f8b:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f91:	8b 55 08             	mov    0x8(%ebp),%edx
80104f94:	89 50 20             	mov    %edx,0x20(%eax)
  proc->state = SLEEPING;
80104f97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104f9d:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)
  sched();
80104fa4:	e8 84 fe ff ff       	call   80104e2d <sched>

  // Tidy up.
  proc->chan = 0;
80104fa9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80104faf:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104fb6:	81 7d 0c 80 0e 11 80 	cmpl   $0x80110e80,0xc(%ebp)
80104fbd:	74 17                	je     80104fd6 <sleep+0x99>
    release(&ptable.lock);
80104fbf:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80104fc6:	e8 b2 02 00 00       	call   8010527d <release>
    acquire(lk);
80104fcb:	8b 45 0c             	mov    0xc(%ebp),%eax
80104fce:	89 04 24             	mov    %eax,(%esp)
80104fd1:	e8 45 02 00 00       	call   8010521b <acquire>
  }
}
80104fd6:	c9                   	leave  
80104fd7:	c3                   	ret    

80104fd8 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104fd8:	55                   	push   %ebp
80104fd9:	89 e5                	mov    %esp,%ebp
80104fdb:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104fde:	c7 45 fc b4 0e 11 80 	movl   $0x80110eb4,-0x4(%ebp)
80104fe5:	eb 24                	jmp    8010500b <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104fe7:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104fea:	8b 40 0c             	mov    0xc(%eax),%eax
80104fed:	83 f8 02             	cmp    $0x2,%eax
80104ff0:	75 15                	jne    80105007 <wakeup1+0x2f>
80104ff2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104ff5:	8b 40 20             	mov    0x20(%eax),%eax
80104ff8:	3b 45 08             	cmp    0x8(%ebp),%eax
80104ffb:	75 0a                	jne    80105007 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104ffd:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105000:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80105007:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
8010500b:	81 7d fc b4 2d 11 80 	cmpl   $0x80112db4,-0x4(%ebp)
80105012:	72 d3                	jb     80104fe7 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80105014:	c9                   	leave  
80105015:	c3                   	ret    

80105016 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80105016:	55                   	push   %ebp
80105017:	89 e5                	mov    %esp,%ebp
80105019:	83 ec 18             	sub    $0x18,%esp
  acquire(&ptable.lock);
8010501c:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
80105023:	e8 f3 01 00 00       	call   8010521b <acquire>
  wakeup1(chan);
80105028:	8b 45 08             	mov    0x8(%ebp),%eax
8010502b:	89 04 24             	mov    %eax,(%esp)
8010502e:	e8 a5 ff ff ff       	call   80104fd8 <wakeup1>
  release(&ptable.lock);
80105033:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
8010503a:	e8 3e 02 00 00       	call   8010527d <release>
}
8010503f:	c9                   	leave  
80105040:	c3                   	ret    

80105041 <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80105041:	55                   	push   %ebp
80105042:	89 e5                	mov    %esp,%ebp
80105044:	83 ec 28             	sub    $0x28,%esp
  struct proc *p;

  acquire(&ptable.lock);
80105047:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
8010504e:	e8 c8 01 00 00       	call   8010521b <acquire>
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105053:	c7 45 f4 b4 0e 11 80 	movl   $0x80110eb4,-0xc(%ebp)
8010505a:	eb 41                	jmp    8010509d <kill+0x5c>
    if(p->pid == pid){
8010505c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010505f:	8b 40 10             	mov    0x10(%eax),%eax
80105062:	3b 45 08             	cmp    0x8(%ebp),%eax
80105065:	75 32                	jne    80105099 <kill+0x58>
      p->killed = 1;
80105067:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010506a:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80105071:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105074:	8b 40 0c             	mov    0xc(%eax),%eax
80105077:	83 f8 02             	cmp    $0x2,%eax
8010507a:	75 0a                	jne    80105086 <kill+0x45>
        p->state = RUNNABLE;
8010507c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010507f:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80105086:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
8010508d:	e8 eb 01 00 00       	call   8010527d <release>
      return 0;
80105092:	b8 00 00 00 00       	mov    $0x0,%eax
80105097:	eb 1e                	jmp    801050b7 <kill+0x76>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80105099:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
8010509d:	81 7d f4 b4 2d 11 80 	cmpl   $0x80112db4,-0xc(%ebp)
801050a4:	72 b6                	jb     8010505c <kill+0x1b>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
801050a6:	c7 04 24 80 0e 11 80 	movl   $0x80110e80,(%esp)
801050ad:	e8 cb 01 00 00       	call   8010527d <release>
  return -1;
801050b2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801050b7:	c9                   	leave  
801050b8:	c3                   	ret    

801050b9 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
801050b9:	55                   	push   %ebp
801050ba:	89 e5                	mov    %esp,%ebp
801050bc:	83 ec 58             	sub    $0x58,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801050bf:	c7 45 f0 b4 0e 11 80 	movl   $0x80110eb4,-0x10(%ebp)
801050c6:	e9 d8 00 00 00       	jmp    801051a3 <procdump+0xea>
    if(p->state == UNUSED)
801050cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050ce:	8b 40 0c             	mov    0xc(%eax),%eax
801050d1:	85 c0                	test   %eax,%eax
801050d3:	0f 84 c5 00 00 00    	je     8010519e <procdump+0xe5>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
801050d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050dc:	8b 40 0c             	mov    0xc(%eax),%eax
801050df:	83 f8 05             	cmp    $0x5,%eax
801050e2:	77 23                	ja     80105107 <procdump+0x4e>
801050e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050e7:	8b 40 0c             	mov    0xc(%eax),%eax
801050ea:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
801050f1:	85 c0                	test   %eax,%eax
801050f3:	74 12                	je     80105107 <procdump+0x4e>
      state = states[p->state];
801050f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801050f8:	8b 40 0c             	mov    0xc(%eax),%eax
801050fb:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80105102:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105105:	eb 07                	jmp    8010510e <procdump+0x55>
    else
      state = "???";
80105107:	c7 45 ec 50 8c 10 80 	movl   $0x80108c50,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
8010510e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105111:	8d 50 6c             	lea    0x6c(%eax),%edx
80105114:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105117:	8b 40 10             	mov    0x10(%eax),%eax
8010511a:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010511e:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105121:	89 54 24 08          	mov    %edx,0x8(%esp)
80105125:	89 44 24 04          	mov    %eax,0x4(%esp)
80105129:	c7 04 24 54 8c 10 80 	movl   $0x80108c54,(%esp)
80105130:	e8 6c b2 ff ff       	call   801003a1 <cprintf>
    if(p->state == SLEEPING){
80105135:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105138:	8b 40 0c             	mov    0xc(%eax),%eax
8010513b:	83 f8 02             	cmp    $0x2,%eax
8010513e:	75 50                	jne    80105190 <procdump+0xd7>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80105140:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105143:	8b 40 1c             	mov    0x1c(%eax),%eax
80105146:	8b 40 0c             	mov    0xc(%eax),%eax
80105149:	83 c0 08             	add    $0x8,%eax
8010514c:	8d 55 c4             	lea    -0x3c(%ebp),%edx
8010514f:	89 54 24 04          	mov    %edx,0x4(%esp)
80105153:	89 04 24             	mov    %eax,(%esp)
80105156:	e8 71 01 00 00       	call   801052cc <getcallerpcs>
      for(i=0; i<10 && pc[i] != 0; i++)
8010515b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80105162:	eb 1b                	jmp    8010517f <procdump+0xc6>
        cprintf(" %p", pc[i]);
80105164:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105167:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
8010516b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010516f:	c7 04 24 5d 8c 10 80 	movl   $0x80108c5d,(%esp)
80105176:	e8 26 b2 ff ff       	call   801003a1 <cprintf>
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
8010517b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010517f:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80105183:	7f 0b                	jg     80105190 <procdump+0xd7>
80105185:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105188:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
8010518c:	85 c0                	test   %eax,%eax
8010518e:	75 d4                	jne    80105164 <procdump+0xab>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80105190:	c7 04 24 61 8c 10 80 	movl   $0x80108c61,(%esp)
80105197:	e8 05 b2 ff ff       	call   801003a1 <cprintf>
8010519c:	eb 01                	jmp    8010519f <procdump+0xe6>
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
8010519e:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];
  
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010519f:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
801051a3:	81 7d f0 b4 2d 11 80 	cmpl   $0x80112db4,-0x10(%ebp)
801051aa:	0f 82 1b ff ff ff    	jb     801050cb <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
801051b0:	c9                   	leave  
801051b1:	c3                   	ret    
	...

801051b4 <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801051b4:	55                   	push   %ebp
801051b5:	89 e5                	mov    %esp,%ebp
801051b7:	53                   	push   %ebx
801051b8:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801051bb:	9c                   	pushf  
801051bc:	5b                   	pop    %ebx
801051bd:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return eflags;
801051c0:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801051c3:	83 c4 10             	add    $0x10,%esp
801051c6:	5b                   	pop    %ebx
801051c7:	5d                   	pop    %ebp
801051c8:	c3                   	ret    

801051c9 <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
801051c9:	55                   	push   %ebp
801051ca:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
801051cc:	fa                   	cli    
}
801051cd:	5d                   	pop    %ebp
801051ce:	c3                   	ret    

801051cf <sti>:

static inline void
sti(void)
{
801051cf:	55                   	push   %ebp
801051d0:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801051d2:	fb                   	sti    
}
801051d3:	5d                   	pop    %ebp
801051d4:	c3                   	ret    

801051d5 <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
801051d5:	55                   	push   %ebp
801051d6:	89 e5                	mov    %esp,%ebp
801051d8:	53                   	push   %ebx
801051d9:	83 ec 10             	sub    $0x10,%esp
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
               "+m" (*addr), "=a" (result) :
801051dc:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801051df:	8b 45 0c             	mov    0xc(%ebp),%eax
               "+m" (*addr), "=a" (result) :
801051e2:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint *addr, uint newval)
{
  uint result;
  
  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
801051e5:	89 c3                	mov    %eax,%ebx
801051e7:	89 d8                	mov    %ebx,%eax
801051e9:	f0 87 02             	lock xchg %eax,(%edx)
801051ec:	89 c3                	mov    %eax,%ebx
801051ee:	89 5d f8             	mov    %ebx,-0x8(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
801051f1:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801051f4:	83 c4 10             	add    $0x10,%esp
801051f7:	5b                   	pop    %ebx
801051f8:	5d                   	pop    %ebp
801051f9:	c3                   	ret    

801051fa <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
801051fa:	55                   	push   %ebp
801051fb:	89 e5                	mov    %esp,%ebp
  lk->name = name;
801051fd:	8b 45 08             	mov    0x8(%ebp),%eax
80105200:	8b 55 0c             	mov    0xc(%ebp),%edx
80105203:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80105206:	8b 45 08             	mov    0x8(%ebp),%eax
80105209:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
8010520f:	8b 45 08             	mov    0x8(%ebp),%eax
80105212:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80105219:	5d                   	pop    %ebp
8010521a:	c3                   	ret    

8010521b <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
8010521b:	55                   	push   %ebp
8010521c:	89 e5                	mov    %esp,%ebp
8010521e:	83 ec 18             	sub    $0x18,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80105221:	e8 3d 01 00 00       	call   80105363 <pushcli>
  if(holding(lk))
80105226:	8b 45 08             	mov    0x8(%ebp),%eax
80105229:	89 04 24             	mov    %eax,(%esp)
8010522c:	e8 08 01 00 00       	call   80105339 <holding>
80105231:	85 c0                	test   %eax,%eax
80105233:	74 0c                	je     80105241 <acquire+0x26>
    panic("acquire");
80105235:	c7 04 24 8d 8c 10 80 	movl   $0x80108c8d,(%esp)
8010523c:	e8 fc b2 ff ff       	call   8010053d <panic>

  // The xchg is atomic.
  // It also serializes, so that reads after acquire are not
  // reordered before it. 
  while(xchg(&lk->locked, 1) != 0)
80105241:	90                   	nop
80105242:	8b 45 08             	mov    0x8(%ebp),%eax
80105245:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010524c:	00 
8010524d:	89 04 24             	mov    %eax,(%esp)
80105250:	e8 80 ff ff ff       	call   801051d5 <xchg>
80105255:	85 c0                	test   %eax,%eax
80105257:	75 e9                	jne    80105242 <acquire+0x27>
    ;

  // Record info about lock acquisition for debugging.
  lk->cpu = cpu;
80105259:	8b 45 08             	mov    0x8(%ebp),%eax
8010525c:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80105263:	89 50 08             	mov    %edx,0x8(%eax)
  getcallerpcs(&lk, lk->pcs);
80105266:	8b 45 08             	mov    0x8(%ebp),%eax
80105269:	83 c0 0c             	add    $0xc,%eax
8010526c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105270:	8d 45 08             	lea    0x8(%ebp),%eax
80105273:	89 04 24             	mov    %eax,(%esp)
80105276:	e8 51 00 00 00       	call   801052cc <getcallerpcs>
}
8010527b:	c9                   	leave  
8010527c:	c3                   	ret    

8010527d <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
8010527d:	55                   	push   %ebp
8010527e:	89 e5                	mov    %esp,%ebp
80105280:	83 ec 18             	sub    $0x18,%esp
  if(!holding(lk))
80105283:	8b 45 08             	mov    0x8(%ebp),%eax
80105286:	89 04 24             	mov    %eax,(%esp)
80105289:	e8 ab 00 00 00       	call   80105339 <holding>
8010528e:	85 c0                	test   %eax,%eax
80105290:	75 0c                	jne    8010529e <release+0x21>
    panic("release");
80105292:	c7 04 24 95 8c 10 80 	movl   $0x80108c95,(%esp)
80105299:	e8 9f b2 ff ff       	call   8010053d <panic>

  lk->pcs[0] = 0;
8010529e:	8b 45 08             	mov    0x8(%ebp),%eax
801052a1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
801052a8:	8b 45 08             	mov    0x8(%ebp),%eax
801052ab:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // But the 2007 Intel 64 Architecture Memory Ordering White
  // Paper says that Intel 64 and IA-32 will not move a load
  // after a store. So lock->locked = 0 would work here.
  // The xchg being asm volatile ensures gcc emits it after
  // the above assignments (and after the critical section).
  xchg(&lk->locked, 0);
801052b2:	8b 45 08             	mov    0x8(%ebp),%eax
801052b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801052bc:	00 
801052bd:	89 04 24             	mov    %eax,(%esp)
801052c0:	e8 10 ff ff ff       	call   801051d5 <xchg>

  popcli();
801052c5:	e8 e1 00 00 00       	call   801053ab <popcli>
}
801052ca:	c9                   	leave  
801052cb:	c3                   	ret    

801052cc <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
801052cc:	55                   	push   %ebp
801052cd:	89 e5                	mov    %esp,%ebp
801052cf:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
801052d2:	8b 45 08             	mov    0x8(%ebp),%eax
801052d5:	83 e8 08             	sub    $0x8,%eax
801052d8:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
801052db:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
801052e2:	eb 32                	jmp    80105316 <getcallerpcs+0x4a>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
801052e4:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
801052e8:	74 47                	je     80105331 <getcallerpcs+0x65>
801052ea:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
801052f1:	76 3e                	jbe    80105331 <getcallerpcs+0x65>
801052f3:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
801052f7:	74 38                	je     80105331 <getcallerpcs+0x65>
      break;
    pcs[i] = ebp[1];     // saved %eip
801052f9:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052fc:	c1 e0 02             	shl    $0x2,%eax
801052ff:	03 45 0c             	add    0xc(%ebp),%eax
80105302:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105305:	8b 52 04             	mov    0x4(%edx),%edx
80105308:	89 10                	mov    %edx,(%eax)
    ebp = (uint*)ebp[0]; // saved %ebp
8010530a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010530d:	8b 00                	mov    (%eax),%eax
8010530f:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;
  
  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105312:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105316:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010531a:	7e c8                	jle    801052e4 <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010531c:	eb 13                	jmp    80105331 <getcallerpcs+0x65>
    pcs[i] = 0;
8010531e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105321:	c1 e0 02             	shl    $0x2,%eax
80105324:	03 45 0c             	add    0xc(%ebp),%eax
80105327:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010532d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105331:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
80105335:	7e e7                	jle    8010531e <getcallerpcs+0x52>
    pcs[i] = 0;
}
80105337:	c9                   	leave  
80105338:	c3                   	ret    

80105339 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105339:	55                   	push   %ebp
8010533a:	89 e5                	mov    %esp,%ebp
  return lock->locked && lock->cpu == cpu;
8010533c:	8b 45 08             	mov    0x8(%ebp),%eax
8010533f:	8b 00                	mov    (%eax),%eax
80105341:	85 c0                	test   %eax,%eax
80105343:	74 17                	je     8010535c <holding+0x23>
80105345:	8b 45 08             	mov    0x8(%ebp),%eax
80105348:	8b 50 08             	mov    0x8(%eax),%edx
8010534b:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80105351:	39 c2                	cmp    %eax,%edx
80105353:	75 07                	jne    8010535c <holding+0x23>
80105355:	b8 01 00 00 00       	mov    $0x1,%eax
8010535a:	eb 05                	jmp    80105361 <holding+0x28>
8010535c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105361:	5d                   	pop    %ebp
80105362:	c3                   	ret    

80105363 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
80105363:	55                   	push   %ebp
80105364:	89 e5                	mov    %esp,%ebp
80105366:	83 ec 10             	sub    $0x10,%esp
  int eflags;
  
  eflags = readeflags();
80105369:	e8 46 fe ff ff       	call   801051b4 <readeflags>
8010536e:	89 45 fc             	mov    %eax,-0x4(%ebp)
  cli();
80105371:	e8 53 fe ff ff       	call   801051c9 <cli>
  if(cpu->ncli++ == 0)
80105376:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010537c:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
80105382:	85 d2                	test   %edx,%edx
80105384:	0f 94 c1             	sete   %cl
80105387:	83 c2 01             	add    $0x1,%edx
8010538a:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
80105390:	84 c9                	test   %cl,%cl
80105392:	74 15                	je     801053a9 <pushcli+0x46>
    cpu->intena = eflags & FL_IF;
80105394:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010539a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010539d:	81 e2 00 02 00 00    	and    $0x200,%edx
801053a3:	89 90 b0 00 00 00    	mov    %edx,0xb0(%eax)
}
801053a9:	c9                   	leave  
801053aa:	c3                   	ret    

801053ab <popcli>:

void
popcli(void)
{
801053ab:	55                   	push   %ebp
801053ac:	89 e5                	mov    %esp,%ebp
801053ae:	83 ec 18             	sub    $0x18,%esp
  if(readeflags()&FL_IF)
801053b1:	e8 fe fd ff ff       	call   801051b4 <readeflags>
801053b6:	25 00 02 00 00       	and    $0x200,%eax
801053bb:	85 c0                	test   %eax,%eax
801053bd:	74 0c                	je     801053cb <popcli+0x20>
    panic("popcli - interruptible");
801053bf:	c7 04 24 9d 8c 10 80 	movl   $0x80108c9d,(%esp)
801053c6:	e8 72 b1 ff ff       	call   8010053d <panic>
  if(--cpu->ncli < 0)
801053cb:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053d1:	8b 90 ac 00 00 00    	mov    0xac(%eax),%edx
801053d7:	83 ea 01             	sub    $0x1,%edx
801053da:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
801053e0:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801053e6:	85 c0                	test   %eax,%eax
801053e8:	79 0c                	jns    801053f6 <popcli+0x4b>
    panic("popcli");
801053ea:	c7 04 24 b4 8c 10 80 	movl   $0x80108cb4,(%esp)
801053f1:	e8 47 b1 ff ff       	call   8010053d <panic>
  if(cpu->ncli == 0 && cpu->intena)
801053f6:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
801053fc:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
80105402:	85 c0                	test   %eax,%eax
80105404:	75 15                	jne    8010541b <popcli+0x70>
80105406:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010540c:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
80105412:	85 c0                	test   %eax,%eax
80105414:	74 05                	je     8010541b <popcli+0x70>
    sti();
80105416:	e8 b4 fd ff ff       	call   801051cf <sti>
}
8010541b:	c9                   	leave  
8010541c:	c3                   	ret    
8010541d:	00 00                	add    %al,(%eax)
	...

80105420 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105420:	55                   	push   %ebp
80105421:	89 e5                	mov    %esp,%ebp
80105423:	57                   	push   %edi
80105424:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105425:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105428:	8b 55 10             	mov    0x10(%ebp),%edx
8010542b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010542e:	89 cb                	mov    %ecx,%ebx
80105430:	89 df                	mov    %ebx,%edi
80105432:	89 d1                	mov    %edx,%ecx
80105434:	fc                   	cld    
80105435:	f3 aa                	rep stos %al,%es:(%edi)
80105437:	89 ca                	mov    %ecx,%edx
80105439:	89 fb                	mov    %edi,%ebx
8010543b:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010543e:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105441:	5b                   	pop    %ebx
80105442:	5f                   	pop    %edi
80105443:	5d                   	pop    %ebp
80105444:	c3                   	ret    

80105445 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
80105445:	55                   	push   %ebp
80105446:	89 e5                	mov    %esp,%ebp
80105448:	57                   	push   %edi
80105449:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
8010544a:	8b 4d 08             	mov    0x8(%ebp),%ecx
8010544d:	8b 55 10             	mov    0x10(%ebp),%edx
80105450:	8b 45 0c             	mov    0xc(%ebp),%eax
80105453:	89 cb                	mov    %ecx,%ebx
80105455:	89 df                	mov    %ebx,%edi
80105457:	89 d1                	mov    %edx,%ecx
80105459:	fc                   	cld    
8010545a:	f3 ab                	rep stos %eax,%es:(%edi)
8010545c:	89 ca                	mov    %ecx,%edx
8010545e:	89 fb                	mov    %edi,%ebx
80105460:	89 5d 08             	mov    %ebx,0x8(%ebp)
80105463:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
80105466:	5b                   	pop    %ebx
80105467:	5f                   	pop    %edi
80105468:	5d                   	pop    %ebp
80105469:	c3                   	ret    

8010546a <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
8010546a:	55                   	push   %ebp
8010546b:	89 e5                	mov    %esp,%ebp
8010546d:	83 ec 0c             	sub    $0xc,%esp
  if ((int)dst%4 == 0 && n%4 == 0){
80105470:	8b 45 08             	mov    0x8(%ebp),%eax
80105473:	83 e0 03             	and    $0x3,%eax
80105476:	85 c0                	test   %eax,%eax
80105478:	75 49                	jne    801054c3 <memset+0x59>
8010547a:	8b 45 10             	mov    0x10(%ebp),%eax
8010547d:	83 e0 03             	and    $0x3,%eax
80105480:	85 c0                	test   %eax,%eax
80105482:	75 3f                	jne    801054c3 <memset+0x59>
    c &= 0xFF;
80105484:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
8010548b:	8b 45 10             	mov    0x10(%ebp),%eax
8010548e:	c1 e8 02             	shr    $0x2,%eax
80105491:	89 c2                	mov    %eax,%edx
80105493:	8b 45 0c             	mov    0xc(%ebp),%eax
80105496:	89 c1                	mov    %eax,%ecx
80105498:	c1 e1 18             	shl    $0x18,%ecx
8010549b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010549e:	c1 e0 10             	shl    $0x10,%eax
801054a1:	09 c1                	or     %eax,%ecx
801054a3:	8b 45 0c             	mov    0xc(%ebp),%eax
801054a6:	c1 e0 08             	shl    $0x8,%eax
801054a9:	09 c8                	or     %ecx,%eax
801054ab:	0b 45 0c             	or     0xc(%ebp),%eax
801054ae:	89 54 24 08          	mov    %edx,0x8(%esp)
801054b2:	89 44 24 04          	mov    %eax,0x4(%esp)
801054b6:	8b 45 08             	mov    0x8(%ebp),%eax
801054b9:	89 04 24             	mov    %eax,(%esp)
801054bc:	e8 84 ff ff ff       	call   80105445 <stosl>
801054c1:	eb 19                	jmp    801054dc <memset+0x72>
  } else
    stosb(dst, c, n);
801054c3:	8b 45 10             	mov    0x10(%ebp),%eax
801054c6:	89 44 24 08          	mov    %eax,0x8(%esp)
801054ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801054cd:	89 44 24 04          	mov    %eax,0x4(%esp)
801054d1:	8b 45 08             	mov    0x8(%ebp),%eax
801054d4:	89 04 24             	mov    %eax,(%esp)
801054d7:	e8 44 ff ff ff       	call   80105420 <stosb>
  return dst;
801054dc:	8b 45 08             	mov    0x8(%ebp),%eax
}
801054df:	c9                   	leave  
801054e0:	c3                   	ret    

801054e1 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801054e1:	55                   	push   %ebp
801054e2:	89 e5                	mov    %esp,%ebp
801054e4:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;
  
  s1 = v1;
801054e7:	8b 45 08             	mov    0x8(%ebp),%eax
801054ea:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
801054ed:	8b 45 0c             	mov    0xc(%ebp),%eax
801054f0:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
801054f3:	eb 32                	jmp    80105527 <memcmp+0x46>
    if(*s1 != *s2)
801054f5:	8b 45 fc             	mov    -0x4(%ebp),%eax
801054f8:	0f b6 10             	movzbl (%eax),%edx
801054fb:	8b 45 f8             	mov    -0x8(%ebp),%eax
801054fe:	0f b6 00             	movzbl (%eax),%eax
80105501:	38 c2                	cmp    %al,%dl
80105503:	74 1a                	je     8010551f <memcmp+0x3e>
      return *s1 - *s2;
80105505:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105508:	0f b6 00             	movzbl (%eax),%eax
8010550b:	0f b6 d0             	movzbl %al,%edx
8010550e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105511:	0f b6 00             	movzbl (%eax),%eax
80105514:	0f b6 c0             	movzbl %al,%eax
80105517:	89 d1                	mov    %edx,%ecx
80105519:	29 c1                	sub    %eax,%ecx
8010551b:	89 c8                	mov    %ecx,%eax
8010551d:	eb 1c                	jmp    8010553b <memcmp+0x5a>
    s1++, s2++;
8010551f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105523:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;
  
  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105527:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010552b:	0f 95 c0             	setne  %al
8010552e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105532:	84 c0                	test   %al,%al
80105534:	75 bf                	jne    801054f5 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105536:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010553b:	c9                   	leave  
8010553c:	c3                   	ret    

8010553d <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010553d:	55                   	push   %ebp
8010553e:	89 e5                	mov    %esp,%ebp
80105540:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105543:	8b 45 0c             	mov    0xc(%ebp),%eax
80105546:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105549:	8b 45 08             	mov    0x8(%ebp),%eax
8010554c:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010554f:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105552:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105555:	73 54                	jae    801055ab <memmove+0x6e>
80105557:	8b 45 10             	mov    0x10(%ebp),%eax
8010555a:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010555d:	01 d0                	add    %edx,%eax
8010555f:	3b 45 f8             	cmp    -0x8(%ebp),%eax
80105562:	76 47                	jbe    801055ab <memmove+0x6e>
    s += n;
80105564:	8b 45 10             	mov    0x10(%ebp),%eax
80105567:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
8010556a:	8b 45 10             	mov    0x10(%ebp),%eax
8010556d:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
80105570:	eb 13                	jmp    80105585 <memmove+0x48>
      *--d = *--s;
80105572:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
80105576:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
8010557a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010557d:	0f b6 10             	movzbl (%eax),%edx
80105580:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105583:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
80105585:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105589:	0f 95 c0             	setne  %al
8010558c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105590:	84 c0                	test   %al,%al
80105592:	75 de                	jne    80105572 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80105594:	eb 25                	jmp    801055bb <memmove+0x7e>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
80105596:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105599:	0f b6 10             	movzbl (%eax),%edx
8010559c:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010559f:	88 10                	mov    %dl,(%eax)
801055a1:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
801055a5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801055a9:	eb 01                	jmp    801055ac <memmove+0x6f>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801055ab:	90                   	nop
801055ac:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801055b0:	0f 95 c0             	setne  %al
801055b3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801055b7:	84 c0                	test   %al,%al
801055b9:	75 db                	jne    80105596 <memmove+0x59>
      *d++ = *s++;

  return dst;
801055bb:	8b 45 08             	mov    0x8(%ebp),%eax
}
801055be:	c9                   	leave  
801055bf:	c3                   	ret    

801055c0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
801055c0:	55                   	push   %ebp
801055c1:	89 e5                	mov    %esp,%ebp
801055c3:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801055c6:	8b 45 10             	mov    0x10(%ebp),%eax
801055c9:	89 44 24 08          	mov    %eax,0x8(%esp)
801055cd:	8b 45 0c             	mov    0xc(%ebp),%eax
801055d0:	89 44 24 04          	mov    %eax,0x4(%esp)
801055d4:	8b 45 08             	mov    0x8(%ebp),%eax
801055d7:	89 04 24             	mov    %eax,(%esp)
801055da:	e8 5e ff ff ff       	call   8010553d <memmove>
}
801055df:	c9                   	leave  
801055e0:	c3                   	ret    

801055e1 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801055e1:	55                   	push   %ebp
801055e2:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
801055e4:	eb 0c                	jmp    801055f2 <strncmp+0x11>
    n--, p++, q++;
801055e6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801055ea:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801055ee:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
801055f2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801055f6:	74 1a                	je     80105612 <strncmp+0x31>
801055f8:	8b 45 08             	mov    0x8(%ebp),%eax
801055fb:	0f b6 00             	movzbl (%eax),%eax
801055fe:	84 c0                	test   %al,%al
80105600:	74 10                	je     80105612 <strncmp+0x31>
80105602:	8b 45 08             	mov    0x8(%ebp),%eax
80105605:	0f b6 10             	movzbl (%eax),%edx
80105608:	8b 45 0c             	mov    0xc(%ebp),%eax
8010560b:	0f b6 00             	movzbl (%eax),%eax
8010560e:	38 c2                	cmp    %al,%dl
80105610:	74 d4                	je     801055e6 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105612:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105616:	75 07                	jne    8010561f <strncmp+0x3e>
    return 0;
80105618:	b8 00 00 00 00       	mov    $0x0,%eax
8010561d:	eb 18                	jmp    80105637 <strncmp+0x56>
  return (uchar)*p - (uchar)*q;
8010561f:	8b 45 08             	mov    0x8(%ebp),%eax
80105622:	0f b6 00             	movzbl (%eax),%eax
80105625:	0f b6 d0             	movzbl %al,%edx
80105628:	8b 45 0c             	mov    0xc(%ebp),%eax
8010562b:	0f b6 00             	movzbl (%eax),%eax
8010562e:	0f b6 c0             	movzbl %al,%eax
80105631:	89 d1                	mov    %edx,%ecx
80105633:	29 c1                	sub    %eax,%ecx
80105635:	89 c8                	mov    %ecx,%eax
}
80105637:	5d                   	pop    %ebp
80105638:	c3                   	ret    

80105639 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105639:	55                   	push   %ebp
8010563a:	89 e5                	mov    %esp,%ebp
8010563c:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
8010563f:	8b 45 08             	mov    0x8(%ebp),%eax
80105642:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105645:	90                   	nop
80105646:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010564a:	0f 9f c0             	setg   %al
8010564d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105651:	84 c0                	test   %al,%al
80105653:	74 30                	je     80105685 <strncpy+0x4c>
80105655:	8b 45 0c             	mov    0xc(%ebp),%eax
80105658:	0f b6 10             	movzbl (%eax),%edx
8010565b:	8b 45 08             	mov    0x8(%ebp),%eax
8010565e:	88 10                	mov    %dl,(%eax)
80105660:	8b 45 08             	mov    0x8(%ebp),%eax
80105663:	0f b6 00             	movzbl (%eax),%eax
80105666:	84 c0                	test   %al,%al
80105668:	0f 95 c0             	setne  %al
8010566b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010566f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
80105673:	84 c0                	test   %al,%al
80105675:	75 cf                	jne    80105646 <strncpy+0xd>
    ;
  while(n-- > 0)
80105677:	eb 0c                	jmp    80105685 <strncpy+0x4c>
    *s++ = 0;
80105679:	8b 45 08             	mov    0x8(%ebp),%eax
8010567c:	c6 00 00             	movb   $0x0,(%eax)
8010567f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
80105683:	eb 01                	jmp    80105686 <strncpy+0x4d>
  char *os;
  
  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
80105685:	90                   	nop
80105686:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010568a:	0f 9f c0             	setg   %al
8010568d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
80105691:	84 c0                	test   %al,%al
80105693:	75 e4                	jne    80105679 <strncpy+0x40>
    *s++ = 0;
  return os;
80105695:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105698:	c9                   	leave  
80105699:	c3                   	ret    

8010569a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010569a:	55                   	push   %ebp
8010569b:	89 e5                	mov    %esp,%ebp
8010569d:	83 ec 10             	sub    $0x10,%esp
  char *os;
  
  os = s;
801056a0:	8b 45 08             	mov    0x8(%ebp),%eax
801056a3:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801056a6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801056aa:	7f 05                	jg     801056b1 <safestrcpy+0x17>
    return os;
801056ac:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056af:	eb 35                	jmp    801056e6 <safestrcpy+0x4c>
  while(--n > 0 && (*s++ = *t++) != 0)
801056b1:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801056b5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801056b9:	7e 22                	jle    801056dd <safestrcpy+0x43>
801056bb:	8b 45 0c             	mov    0xc(%ebp),%eax
801056be:	0f b6 10             	movzbl (%eax),%edx
801056c1:	8b 45 08             	mov    0x8(%ebp),%eax
801056c4:	88 10                	mov    %dl,(%eax)
801056c6:	8b 45 08             	mov    0x8(%ebp),%eax
801056c9:	0f b6 00             	movzbl (%eax),%eax
801056cc:	84 c0                	test   %al,%al
801056ce:	0f 95 c0             	setne  %al
801056d1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
801056d5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
801056d9:	84 c0                	test   %al,%al
801056db:	75 d4                	jne    801056b1 <safestrcpy+0x17>
    ;
  *s = 0;
801056dd:	8b 45 08             	mov    0x8(%ebp),%eax
801056e0:	c6 00 00             	movb   $0x0,(%eax)
  return os;
801056e3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801056e6:	c9                   	leave  
801056e7:	c3                   	ret    

801056e8 <strlen>:

int
strlen(const char *s)
{
801056e8:	55                   	push   %ebp
801056e9:	89 e5                	mov    %esp,%ebp
801056eb:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
801056ee:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801056f5:	eb 04                	jmp    801056fb <strlen+0x13>
801056f7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801056fb:	8b 45 fc             	mov    -0x4(%ebp),%eax
801056fe:	03 45 08             	add    0x8(%ebp),%eax
80105701:	0f b6 00             	movzbl (%eax),%eax
80105704:	84 c0                	test   %al,%al
80105706:	75 ef                	jne    801056f7 <strlen+0xf>
    ;
  return n;
80105708:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010570b:	c9                   	leave  
8010570c:	c3                   	ret    
8010570d:	00 00                	add    %al,(%eax)
	...

80105710 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105710:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105714:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105718:	55                   	push   %ebp
  pushl %ebx
80105719:	53                   	push   %ebx
  pushl %esi
8010571a:	56                   	push   %esi
  pushl %edi
8010571b:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010571c:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010571e:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105720:	5f                   	pop    %edi
  popl %esi
80105721:	5e                   	pop    %esi
  popl %ebx
80105722:	5b                   	pop    %ebx
  popl %ebp
80105723:	5d                   	pop    %ebp
  ret
80105724:	c3                   	ret    
80105725:	00 00                	add    %al,(%eax)
	...

80105728 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from process p.
int
fetchint(struct proc *p, uint addr, int *ip)
{
80105728:	55                   	push   %ebp
80105729:	89 e5                	mov    %esp,%ebp
  if(addr >= p->sz || addr+4 > p->sz)
8010572b:	8b 45 08             	mov    0x8(%ebp),%eax
8010572e:	8b 00                	mov    (%eax),%eax
80105730:	3b 45 0c             	cmp    0xc(%ebp),%eax
80105733:	76 0f                	jbe    80105744 <fetchint+0x1c>
80105735:	8b 45 0c             	mov    0xc(%ebp),%eax
80105738:	8d 50 04             	lea    0x4(%eax),%edx
8010573b:	8b 45 08             	mov    0x8(%ebp),%eax
8010573e:	8b 00                	mov    (%eax),%eax
80105740:	39 c2                	cmp    %eax,%edx
80105742:	76 07                	jbe    8010574b <fetchint+0x23>
    return -1;
80105744:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105749:	eb 0f                	jmp    8010575a <fetchint+0x32>
  *ip = *(int*)(addr);
8010574b:	8b 45 0c             	mov    0xc(%ebp),%eax
8010574e:	8b 10                	mov    (%eax),%edx
80105750:	8b 45 10             	mov    0x10(%ebp),%eax
80105753:	89 10                	mov    %edx,(%eax)
  return 0;
80105755:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010575a:	5d                   	pop    %ebp
8010575b:	c3                   	ret    

8010575c <fetchstr>:
// Fetch the nul-terminated string at addr from process p.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(struct proc *p, uint addr, char **pp)
{
8010575c:	55                   	push   %ebp
8010575d:	89 e5                	mov    %esp,%ebp
8010575f:	83 ec 10             	sub    $0x10,%esp
  char *s, *ep;

  if(addr >= p->sz)
80105762:	8b 45 08             	mov    0x8(%ebp),%eax
80105765:	8b 00                	mov    (%eax),%eax
80105767:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010576a:	77 07                	ja     80105773 <fetchstr+0x17>
    return -1;
8010576c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105771:	eb 45                	jmp    801057b8 <fetchstr+0x5c>
  *pp = (char*)addr;
80105773:	8b 55 0c             	mov    0xc(%ebp),%edx
80105776:	8b 45 10             	mov    0x10(%ebp),%eax
80105779:	89 10                	mov    %edx,(%eax)
  ep = (char*)p->sz;
8010577b:	8b 45 08             	mov    0x8(%ebp),%eax
8010577e:	8b 00                	mov    (%eax),%eax
80105780:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(s = *pp; s < ep; s++)
80105783:	8b 45 10             	mov    0x10(%ebp),%eax
80105786:	8b 00                	mov    (%eax),%eax
80105788:	89 45 fc             	mov    %eax,-0x4(%ebp)
8010578b:	eb 1e                	jmp    801057ab <fetchstr+0x4f>
    if(*s == 0)
8010578d:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105790:	0f b6 00             	movzbl (%eax),%eax
80105793:	84 c0                	test   %al,%al
80105795:	75 10                	jne    801057a7 <fetchstr+0x4b>
      return s - *pp;
80105797:	8b 55 fc             	mov    -0x4(%ebp),%edx
8010579a:	8b 45 10             	mov    0x10(%ebp),%eax
8010579d:	8b 00                	mov    (%eax),%eax
8010579f:	89 d1                	mov    %edx,%ecx
801057a1:	29 c1                	sub    %eax,%ecx
801057a3:	89 c8                	mov    %ecx,%eax
801057a5:	eb 11                	jmp    801057b8 <fetchstr+0x5c>

  if(addr >= p->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)p->sz;
  for(s = *pp; s < ep; s++)
801057a7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
801057ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
801057ae:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801057b1:	72 da                	jb     8010578d <fetchstr+0x31>
    if(*s == 0)
      return s - *pp;
  return -1;
801057b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801057b8:	c9                   	leave  
801057b9:	c3                   	ret    

801057ba <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801057ba:	55                   	push   %ebp
801057bb:	89 e5                	mov    %esp,%ebp
801057bd:	83 ec 0c             	sub    $0xc,%esp
  return fetchint(proc, proc->tf->esp + 4 + 4*n, ip);
801057c0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057c6:	8b 40 18             	mov    0x18(%eax),%eax
801057c9:	8b 50 44             	mov    0x44(%eax),%edx
801057cc:	8b 45 08             	mov    0x8(%ebp),%eax
801057cf:	c1 e0 02             	shl    $0x2,%eax
801057d2:	01 d0                	add    %edx,%eax
801057d4:	8d 48 04             	lea    0x4(%eax),%ecx
801057d7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801057dd:	8b 55 0c             	mov    0xc(%ebp),%edx
801057e0:	89 54 24 08          	mov    %edx,0x8(%esp)
801057e4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
801057e8:	89 04 24             	mov    %eax,(%esp)
801057eb:	e8 38 ff ff ff       	call   80105728 <fetchint>
}
801057f0:	c9                   	leave  
801057f1:	c3                   	ret    

801057f2 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size n bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
801057f2:	55                   	push   %ebp
801057f3:	89 e5                	mov    %esp,%ebp
801057f5:	83 ec 18             	sub    $0x18,%esp
  int i;
  
  if(argint(n, &i) < 0)
801057f8:	8d 45 fc             	lea    -0x4(%ebp),%eax
801057fb:	89 44 24 04          	mov    %eax,0x4(%esp)
801057ff:	8b 45 08             	mov    0x8(%ebp),%eax
80105802:	89 04 24             	mov    %eax,(%esp)
80105805:	e8 b0 ff ff ff       	call   801057ba <argint>
8010580a:	85 c0                	test   %eax,%eax
8010580c:	79 07                	jns    80105815 <argptr+0x23>
    return -1;
8010580e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105813:	eb 3d                	jmp    80105852 <argptr+0x60>
  if((uint)i >= proc->sz || (uint)i+size > proc->sz)
80105815:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105818:	89 c2                	mov    %eax,%edx
8010581a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105820:	8b 00                	mov    (%eax),%eax
80105822:	39 c2                	cmp    %eax,%edx
80105824:	73 16                	jae    8010583c <argptr+0x4a>
80105826:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105829:	89 c2                	mov    %eax,%edx
8010582b:	8b 45 10             	mov    0x10(%ebp),%eax
8010582e:	01 c2                	add    %eax,%edx
80105830:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105836:	8b 00                	mov    (%eax),%eax
80105838:	39 c2                	cmp    %eax,%edx
8010583a:	76 07                	jbe    80105843 <argptr+0x51>
    return -1;
8010583c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105841:	eb 0f                	jmp    80105852 <argptr+0x60>
  *pp = (char*)i;
80105843:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105846:	89 c2                	mov    %eax,%edx
80105848:	8b 45 0c             	mov    0xc(%ebp),%eax
8010584b:	89 10                	mov    %edx,(%eax)
  return 0;
8010584d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105852:	c9                   	leave  
80105853:	c3                   	ret    

80105854 <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
80105854:	55                   	push   %ebp
80105855:	89 e5                	mov    %esp,%ebp
80105857:	83 ec 1c             	sub    $0x1c,%esp
  int addr;
  if(argint(n, &addr) < 0)
8010585a:	8d 45 fc             	lea    -0x4(%ebp),%eax
8010585d:	89 44 24 04          	mov    %eax,0x4(%esp)
80105861:	8b 45 08             	mov    0x8(%ebp),%eax
80105864:	89 04 24             	mov    %eax,(%esp)
80105867:	e8 4e ff ff ff       	call   801057ba <argint>
8010586c:	85 c0                	test   %eax,%eax
8010586e:	79 07                	jns    80105877 <argstr+0x23>
    return -1;
80105870:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105875:	eb 1e                	jmp    80105895 <argstr+0x41>
  return fetchstr(proc, addr, pp);
80105877:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010587a:	89 c2                	mov    %eax,%edx
8010587c:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105882:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105885:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105889:	89 54 24 04          	mov    %edx,0x4(%esp)
8010588d:	89 04 24             	mov    %eax,(%esp)
80105890:	e8 c7 fe ff ff       	call   8010575c <fetchstr>
}
80105895:	c9                   	leave  
80105896:	c3                   	ret    

80105897 <syscall>:
  
};

void
syscall(void)
{
80105897:	55                   	push   %ebp
80105898:	89 e5                	mov    %esp,%ebp
8010589a:	53                   	push   %ebx
8010589b:	83 ec 24             	sub    $0x24,%esp
  int num;

  num = proc->tf->eax;
8010589e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058a4:	8b 40 18             	mov    0x18(%eax),%eax
801058a7:	8b 40 1c             	mov    0x1c(%eax),%eax
801058aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(num >= 0 && num < SYS_open && syscalls[num]) {
801058ad:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801058b1:	78 2e                	js     801058e1 <syscall+0x4a>
801058b3:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801058b7:	7f 28                	jg     801058e1 <syscall+0x4a>
801058b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058bc:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801058c3:	85 c0                	test   %eax,%eax
801058c5:	74 1a                	je     801058e1 <syscall+0x4a>
    proc->tf->eax = syscalls[num]();
801058c7:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801058cd:	8b 58 18             	mov    0x18(%eax),%ebx
801058d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058d3:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801058da:	ff d0                	call   *%eax
801058dc:	89 43 1c             	mov    %eax,0x1c(%ebx)
801058df:	eb 73                	jmp    80105954 <syscall+0xbd>
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
801058e1:	83 7d f4 0e          	cmpl   $0xe,-0xc(%ebp)
801058e5:	7e 30                	jle    80105917 <syscall+0x80>
801058e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058ea:	83 f8 16             	cmp    $0x16,%eax
801058ed:	77 28                	ja     80105917 <syscall+0x80>
801058ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058f2:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
801058f9:	85 c0                	test   %eax,%eax
801058fb:	74 1a                	je     80105917 <syscall+0x80>
    proc->tf->eax = syscalls[num]();
801058fd:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105903:	8b 58 18             	mov    0x18(%eax),%ebx
80105906:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105909:	8b 04 85 40 b0 10 80 	mov    -0x7fef4fc0(,%eax,4),%eax
80105910:	ff d0                	call   *%eax
80105912:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105915:	eb 3d                	jmp    80105954 <syscall+0xbd>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            proc->pid, proc->name, num);
80105917:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010591d:	8d 48 6c             	lea    0x6c(%eax),%ecx
80105920:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
  if(num >= 0 && num < SYS_open && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else if (num >= SYS_open && num < NELEM(syscalls) && syscalls[num]) {
    proc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105926:	8b 40 10             	mov    0x10(%eax),%eax
80105929:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010592c:	89 54 24 0c          	mov    %edx,0xc(%esp)
80105930:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105934:	89 44 24 04          	mov    %eax,0x4(%esp)
80105938:	c7 04 24 bb 8c 10 80 	movl   $0x80108cbb,(%esp)
8010593f:	e8 5d aa ff ff       	call   801003a1 <cprintf>
            proc->pid, proc->name, num);
    proc->tf->eax = -1;
80105944:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010594a:	8b 40 18             	mov    0x18(%eax),%eax
8010594d:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
80105954:	83 c4 24             	add    $0x24,%esp
80105957:	5b                   	pop    %ebx
80105958:	5d                   	pop    %ebp
80105959:	c3                   	ret    
	...

8010595c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
8010595c:	55                   	push   %ebp
8010595d:	89 e5                	mov    %esp,%ebp
8010595f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
80105962:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105965:	89 44 24 04          	mov    %eax,0x4(%esp)
80105969:	8b 45 08             	mov    0x8(%ebp),%eax
8010596c:	89 04 24             	mov    %eax,(%esp)
8010596f:	e8 46 fe ff ff       	call   801057ba <argint>
80105974:	85 c0                	test   %eax,%eax
80105976:	79 07                	jns    8010597f <argfd+0x23>
    return -1;
80105978:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010597d:	eb 50                	jmp    801059cf <argfd+0x73>
  if(fd < 0 || fd >= NOFILE || (f=proc->ofile[fd]) == 0)
8010597f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105982:	85 c0                	test   %eax,%eax
80105984:	78 21                	js     801059a7 <argfd+0x4b>
80105986:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105989:	83 f8 0f             	cmp    $0xf,%eax
8010598c:	7f 19                	jg     801059a7 <argfd+0x4b>
8010598e:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105994:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105997:	83 c2 08             	add    $0x8,%edx
8010599a:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
8010599e:	89 45 f4             	mov    %eax,-0xc(%ebp)
801059a1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801059a5:	75 07                	jne    801059ae <argfd+0x52>
    return -1;
801059a7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801059ac:	eb 21                	jmp    801059cf <argfd+0x73>
  if(pfd)
801059ae:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801059b2:	74 08                	je     801059bc <argfd+0x60>
    *pfd = fd;
801059b4:	8b 55 f0             	mov    -0x10(%ebp),%edx
801059b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801059ba:	89 10                	mov    %edx,(%eax)
  if(pf)
801059bc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801059c0:	74 08                	je     801059ca <argfd+0x6e>
    *pf = f;
801059c2:	8b 45 10             	mov    0x10(%ebp),%eax
801059c5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801059c8:	89 10                	mov    %edx,(%eax)
  return 0;
801059ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
801059cf:	c9                   	leave  
801059d0:	c3                   	ret    

801059d1 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801059d1:	55                   	push   %ebp
801059d2:	89 e5                	mov    %esp,%ebp
801059d4:	83 ec 10             	sub    $0x10,%esp
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
801059d7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801059de:	eb 30                	jmp    80105a10 <fdalloc+0x3f>
    if(proc->ofile[fd] == 0){
801059e0:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059e6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801059e9:	83 c2 08             	add    $0x8,%edx
801059ec:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801059f0:	85 c0                	test   %eax,%eax
801059f2:	75 18                	jne    80105a0c <fdalloc+0x3b>
      proc->ofile[fd] = f;
801059f4:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801059fa:	8b 55 fc             	mov    -0x4(%ebp),%edx
801059fd:	8d 4a 08             	lea    0x8(%edx),%ecx
80105a00:	8b 55 08             	mov    0x8(%ebp),%edx
80105a03:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
80105a07:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105a0a:	eb 0f                	jmp    80105a1b <fdalloc+0x4a>
static int
fdalloc(struct file *f)
{
  int fd;

  for(fd = 0; fd < NOFILE; fd++){
80105a0c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105a10:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
80105a14:	7e ca                	jle    801059e0 <fdalloc+0xf>
    if(proc->ofile[fd] == 0){
      proc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105a16:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a1b:	c9                   	leave  
80105a1c:	c3                   	ret    

80105a1d <sys_dup>:

int
sys_dup(void)
{
80105a1d:	55                   	push   %ebp
80105a1e:	89 e5                	mov    %esp,%ebp
80105a20:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int fd;
  
  if(argfd(0, 0, &f) < 0)
80105a23:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105a26:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105a31:	00 
80105a32:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a39:	e8 1e ff ff ff       	call   8010595c <argfd>
80105a3e:	85 c0                	test   %eax,%eax
80105a40:	79 07                	jns    80105a49 <sys_dup+0x2c>
    return -1;
80105a42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a47:	eb 29                	jmp    80105a72 <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
80105a49:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a4c:	89 04 24             	mov    %eax,(%esp)
80105a4f:	e8 7d ff ff ff       	call   801059d1 <fdalloc>
80105a54:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105a57:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105a5b:	79 07                	jns    80105a64 <sys_dup+0x47>
    return -1;
80105a5d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105a62:	eb 0e                	jmp    80105a72 <sys_dup+0x55>
  filedup(f);
80105a64:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105a67:	89 04 24             	mov    %eax,(%esp)
80105a6a:	e8 85 bb ff ff       	call   801015f4 <filedup>
  return fd;
80105a6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80105a72:	c9                   	leave  
80105a73:	c3                   	ret    

80105a74 <sys_read>:

int
sys_read(void)
{
80105a74:	55                   	push   %ebp
80105a75:	89 e5                	mov    %esp,%ebp
80105a77:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105a7a:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105a7d:	89 44 24 08          	mov    %eax,0x8(%esp)
80105a81:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105a88:	00 
80105a89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105a90:	e8 c7 fe ff ff       	call   8010595c <argfd>
80105a95:	85 c0                	test   %eax,%eax
80105a97:	78 35                	js     80105ace <sys_read+0x5a>
80105a99:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105aa0:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105aa7:	e8 0e fd ff ff       	call   801057ba <argint>
80105aac:	85 c0                	test   %eax,%eax
80105aae:	78 1e                	js     80105ace <sys_read+0x5a>
80105ab0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ab3:	89 44 24 08          	mov    %eax,0x8(%esp)
80105ab7:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105aba:	89 44 24 04          	mov    %eax,0x4(%esp)
80105abe:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105ac5:	e8 28 fd ff ff       	call   801057f2 <argptr>
80105aca:	85 c0                	test   %eax,%eax
80105acc:	79 07                	jns    80105ad5 <sys_read+0x61>
    return -1;
80105ace:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ad3:	eb 19                	jmp    80105aee <sys_read+0x7a>
  return fileread(f, p, n);
80105ad5:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105ad8:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105adb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ade:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105ae2:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ae6:	89 04 24             	mov    %eax,(%esp)
80105ae9:	e8 73 bc ff ff       	call   80101761 <fileread>
}
80105aee:	c9                   	leave  
80105aef:	c3                   	ret    

80105af0 <sys_write>:

int
sys_write(void)
{
80105af0:	55                   	push   %ebp
80105af1:	89 e5                	mov    %esp,%ebp
80105af3:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105af6:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105af9:	89 44 24 08          	mov    %eax,0x8(%esp)
80105afd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105b04:	00 
80105b05:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b0c:	e8 4b fe ff ff       	call   8010595c <argfd>
80105b11:	85 c0                	test   %eax,%eax
80105b13:	78 35                	js     80105b4a <sys_write+0x5a>
80105b15:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105b18:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b1c:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
80105b23:	e8 92 fc ff ff       	call   801057ba <argint>
80105b28:	85 c0                	test   %eax,%eax
80105b2a:	78 1e                	js     80105b4a <sys_write+0x5a>
80105b2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105b2f:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b33:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105b36:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b3a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105b41:	e8 ac fc ff ff       	call   801057f2 <argptr>
80105b46:	85 c0                	test   %eax,%eax
80105b48:	79 07                	jns    80105b51 <sys_write+0x61>
    return -1;
80105b4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b4f:	eb 19                	jmp    80105b6a <sys_write+0x7a>
  return filewrite(f, p, n);
80105b51:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80105b54:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105b57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105b5a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80105b5e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105b62:	89 04 24             	mov    %eax,(%esp)
80105b65:	e8 b3 bc ff ff       	call   8010181d <filewrite>
}
80105b6a:	c9                   	leave  
80105b6b:	c3                   	ret    

80105b6c <sys_close>:

int
sys_close(void)
{
80105b6c:	55                   	push   %ebp
80105b6d:	89 e5                	mov    %esp,%ebp
80105b6f:	83 ec 28             	sub    $0x28,%esp
  int fd;
  struct file *f;
  
  if(argfd(0, &fd, &f) < 0)
80105b72:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105b75:	89 44 24 08          	mov    %eax,0x8(%esp)
80105b79:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105b7c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105b80:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105b87:	e8 d0 fd ff ff       	call   8010595c <argfd>
80105b8c:	85 c0                	test   %eax,%eax
80105b8e:	79 07                	jns    80105b97 <sys_close+0x2b>
    return -1;
80105b90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b95:	eb 24                	jmp    80105bbb <sys_close+0x4f>
  proc->ofile[fd] = 0;
80105b97:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80105b9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105ba0:	83 c2 08             	add    $0x8,%edx
80105ba3:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80105baa:	00 
  fileclose(f);
80105bab:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bae:	89 04 24             	mov    %eax,(%esp)
80105bb1:	e8 86 ba ff ff       	call   8010163c <fileclose>
  return 0;
80105bb6:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105bbb:	c9                   	leave  
80105bbc:	c3                   	ret    

80105bbd <sys_fstat>:

int
sys_fstat(void)
{
80105bbd:	55                   	push   %ebp
80105bbe:	89 e5                	mov    %esp,%ebp
80105bc0:	83 ec 28             	sub    $0x28,%esp
  struct file *f;
  struct stat *st;
  
  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
80105bc3:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105bc6:	89 44 24 08          	mov    %eax,0x8(%esp)
80105bca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105bd1:	00 
80105bd2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105bd9:	e8 7e fd ff ff       	call   8010595c <argfd>
80105bde:	85 c0                	test   %eax,%eax
80105be0:	78 1f                	js     80105c01 <sys_fstat+0x44>
80105be2:	c7 44 24 08 14 00 00 	movl   $0x14,0x8(%esp)
80105be9:	00 
80105bea:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105bed:	89 44 24 04          	mov    %eax,0x4(%esp)
80105bf1:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105bf8:	e8 f5 fb ff ff       	call   801057f2 <argptr>
80105bfd:	85 c0                	test   %eax,%eax
80105bff:	79 07                	jns    80105c08 <sys_fstat+0x4b>
    return -1;
80105c01:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c06:	eb 12                	jmp    80105c1a <sys_fstat+0x5d>
  return filestat(f, st);
80105c08:	8b 55 f0             	mov    -0x10(%ebp),%edx
80105c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c0e:	89 54 24 04          	mov    %edx,0x4(%esp)
80105c12:	89 04 24             	mov    %eax,(%esp)
80105c15:	e8 f8 ba ff ff       	call   80101712 <filestat>
}
80105c1a:	c9                   	leave  
80105c1b:	c3                   	ret    

80105c1c <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
80105c1c:	55                   	push   %ebp
80105c1d:	89 e5                	mov    %esp,%ebp
80105c1f:	83 ec 38             	sub    $0x38,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
80105c22:	8d 45 d8             	lea    -0x28(%ebp),%eax
80105c25:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c29:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105c30:	e8 1f fc ff ff       	call   80105854 <argstr>
80105c35:	85 c0                	test   %eax,%eax
80105c37:	78 17                	js     80105c50 <sys_link+0x34>
80105c39:	8d 45 dc             	lea    -0x24(%ebp),%eax
80105c3c:	89 44 24 04          	mov    %eax,0x4(%esp)
80105c40:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
80105c47:	e8 08 fc ff ff       	call   80105854 <argstr>
80105c4c:	85 c0                	test   %eax,%eax
80105c4e:	79 0a                	jns    80105c5a <sys_link+0x3e>
    return -1;
80105c50:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c55:	e9 3c 01 00 00       	jmp    80105d96 <sys_link+0x17a>
  if((ip = namei(old)) == 0)
80105c5a:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105c5d:	89 04 24             	mov    %eax,(%esp)
80105c60:	e8 1d ce ff ff       	call   80102a82 <namei>
80105c65:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105c68:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105c6c:	75 0a                	jne    80105c78 <sys_link+0x5c>
    return -1;
80105c6e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105c73:	e9 1e 01 00 00       	jmp    80105d96 <sys_link+0x17a>

  begin_trans();
80105c78:	e8 18 dc ff ff       	call   80103895 <begin_trans>

  ilock(ip);
80105c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c80:	89 04 24             	mov    %eax,(%esp)
80105c83:	e8 58 c2 ff ff       	call   80101ee0 <ilock>
  if(ip->type == T_DIR){
80105c88:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c8b:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105c8f:	66 83 f8 01          	cmp    $0x1,%ax
80105c93:	75 1a                	jne    80105caf <sys_link+0x93>
    iunlockput(ip);
80105c95:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c98:	89 04 24             	mov    %eax,(%esp)
80105c9b:	e8 c4 c4 ff ff       	call   80102164 <iunlockput>
    commit_trans();
80105ca0:	e8 39 dc ff ff       	call   801038de <commit_trans>
    return -1;
80105ca5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105caa:	e9 e7 00 00 00       	jmp    80105d96 <sys_link+0x17a>
  }

  ip->nlink++;
80105caf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cb2:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105cb6:	8d 50 01             	lea    0x1(%eax),%edx
80105cb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cbc:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105cc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cc3:	89 04 24             	mov    %eax,(%esp)
80105cc6:	e8 59 c0 ff ff       	call   80101d24 <iupdate>
  iunlock(ip);
80105ccb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105cce:	89 04 24             	mov    %eax,(%esp)
80105cd1:	e8 58 c3 ff ff       	call   8010202e <iunlock>

  if((dp = nameiparent(new, name)) == 0)
80105cd6:	8b 45 dc             	mov    -0x24(%ebp),%eax
80105cd9:	8d 55 e2             	lea    -0x1e(%ebp),%edx
80105cdc:	89 54 24 04          	mov    %edx,0x4(%esp)
80105ce0:	89 04 24             	mov    %eax,(%esp)
80105ce3:	e8 bc cd ff ff       	call   80102aa4 <nameiparent>
80105ce8:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105ceb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105cef:	74 68                	je     80105d59 <sys_link+0x13d>
    goto bad;
  ilock(dp);
80105cf1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cf4:	89 04 24             	mov    %eax,(%esp)
80105cf7:	e8 e4 c1 ff ff       	call   80101ee0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
80105cfc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105cff:	8b 10                	mov    (%eax),%edx
80105d01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d04:	8b 00                	mov    (%eax),%eax
80105d06:	39 c2                	cmp    %eax,%edx
80105d08:	75 20                	jne    80105d2a <sys_link+0x10e>
80105d0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d0d:	8b 40 04             	mov    0x4(%eax),%eax
80105d10:	89 44 24 08          	mov    %eax,0x8(%esp)
80105d14:	8d 45 e2             	lea    -0x1e(%ebp),%eax
80105d17:	89 44 24 04          	mov    %eax,0x4(%esp)
80105d1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d1e:	89 04 24             	mov    %eax,(%esp)
80105d21:	e8 9b ca ff ff       	call   801027c1 <dirlink>
80105d26:	85 c0                	test   %eax,%eax
80105d28:	79 0d                	jns    80105d37 <sys_link+0x11b>
    iunlockput(dp);
80105d2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d2d:	89 04 24             	mov    %eax,(%esp)
80105d30:	e8 2f c4 ff ff       	call   80102164 <iunlockput>
    goto bad;
80105d35:	eb 23                	jmp    80105d5a <sys_link+0x13e>
  }
  iunlockput(dp);
80105d37:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d3a:	89 04 24             	mov    %eax,(%esp)
80105d3d:	e8 22 c4 ff ff       	call   80102164 <iunlockput>
  iput(ip);
80105d42:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d45:	89 04 24             	mov    %eax,(%esp)
80105d48:	e8 46 c3 ff ff       	call   80102093 <iput>

  commit_trans();
80105d4d:	e8 8c db ff ff       	call   801038de <commit_trans>

  return 0;
80105d52:	b8 00 00 00 00       	mov    $0x0,%eax
80105d57:	eb 3d                	jmp    80105d96 <sys_link+0x17a>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105d59:	90                   	nop
  commit_trans();

  return 0;

bad:
  ilock(ip);
80105d5a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d5d:	89 04 24             	mov    %eax,(%esp)
80105d60:	e8 7b c1 ff ff       	call   80101ee0 <ilock>
  ip->nlink--;
80105d65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d68:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105d6c:	8d 50 ff             	lea    -0x1(%eax),%edx
80105d6f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d72:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105d76:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d79:	89 04 24             	mov    %eax,(%esp)
80105d7c:	e8 a3 bf ff ff       	call   80101d24 <iupdate>
  iunlockput(ip);
80105d81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d84:	89 04 24             	mov    %eax,(%esp)
80105d87:	e8 d8 c3 ff ff       	call   80102164 <iunlockput>
  commit_trans();
80105d8c:	e8 4d db ff ff       	call   801038de <commit_trans>
  return -1;
80105d91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105d96:	c9                   	leave  
80105d97:	c3                   	ret    

80105d98 <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105d98:	55                   	push   %ebp
80105d99:	89 e5                	mov    %esp,%ebp
80105d9b:	83 ec 38             	sub    $0x38,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105d9e:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105da5:	eb 4b                	jmp    80105df2 <isdirempty+0x5a>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105da7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105daa:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105db1:	00 
80105db2:	89 44 24 08          	mov    %eax,0x8(%esp)
80105db6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105db9:	89 44 24 04          	mov    %eax,0x4(%esp)
80105dbd:	8b 45 08             	mov    0x8(%ebp),%eax
80105dc0:	89 04 24             	mov    %eax,(%esp)
80105dc3:	e8 0e c6 ff ff       	call   801023d6 <readi>
80105dc8:	83 f8 10             	cmp    $0x10,%eax
80105dcb:	74 0c                	je     80105dd9 <isdirempty+0x41>
      panic("isdirempty: readi");
80105dcd:	c7 04 24 d7 8c 10 80 	movl   $0x80108cd7,(%esp)
80105dd4:	e8 64 a7 ff ff       	call   8010053d <panic>
    if(de.inum != 0)
80105dd9:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105ddd:	66 85 c0             	test   %ax,%ax
80105de0:	74 07                	je     80105de9 <isdirempty+0x51>
      return 0;
80105de2:	b8 00 00 00 00       	mov    $0x0,%eax
80105de7:	eb 1b                	jmp    80105e04 <isdirempty+0x6c>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105de9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dec:	83 c0 10             	add    $0x10,%eax
80105def:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105df2:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105df5:	8b 45 08             	mov    0x8(%ebp),%eax
80105df8:	8b 40 18             	mov    0x18(%eax),%eax
80105dfb:	39 c2                	cmp    %eax,%edx
80105dfd:	72 a8                	jb     80105da7 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105dff:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105e04:	c9                   	leave  
80105e05:	c3                   	ret    

80105e06 <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105e06:	55                   	push   %ebp
80105e07:	89 e5                	mov    %esp,%ebp
80105e09:	83 ec 48             	sub    $0x48,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105e0c:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105e0f:	89 44 24 04          	mov    %eax,0x4(%esp)
80105e13:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80105e1a:	e8 35 fa ff ff       	call   80105854 <argstr>
80105e1f:	85 c0                	test   %eax,%eax
80105e21:	79 0a                	jns    80105e2d <sys_unlink+0x27>
    return -1;
80105e23:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e28:	e9 aa 01 00 00       	jmp    80105fd7 <sys_unlink+0x1d1>
  if((dp = nameiparent(path, name)) == 0)
80105e2d:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105e30:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105e33:	89 54 24 04          	mov    %edx,0x4(%esp)
80105e37:	89 04 24             	mov    %eax,(%esp)
80105e3a:	e8 65 cc ff ff       	call   80102aa4 <nameiparent>
80105e3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105e42:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105e46:	75 0a                	jne    80105e52 <sys_unlink+0x4c>
    return -1;
80105e48:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105e4d:	e9 85 01 00 00       	jmp    80105fd7 <sys_unlink+0x1d1>

  begin_trans();
80105e52:	e8 3e da ff ff       	call   80103895 <begin_trans>

  ilock(dp);
80105e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e5a:	89 04 24             	mov    %eax,(%esp)
80105e5d:	e8 7e c0 ff ff       	call   80101ee0 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105e62:	c7 44 24 04 e9 8c 10 	movl   $0x80108ce9,0x4(%esp)
80105e69:	80 
80105e6a:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105e6d:	89 04 24             	mov    %eax,(%esp)
80105e70:	e8 62 c8 ff ff       	call   801026d7 <namecmp>
80105e75:	85 c0                	test   %eax,%eax
80105e77:	0f 84 45 01 00 00    	je     80105fc2 <sys_unlink+0x1bc>
80105e7d:	c7 44 24 04 eb 8c 10 	movl   $0x80108ceb,0x4(%esp)
80105e84:	80 
80105e85:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105e88:	89 04 24             	mov    %eax,(%esp)
80105e8b:	e8 47 c8 ff ff       	call   801026d7 <namecmp>
80105e90:	85 c0                	test   %eax,%eax
80105e92:	0f 84 2a 01 00 00    	je     80105fc2 <sys_unlink+0x1bc>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105e98:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105e9b:	89 44 24 08          	mov    %eax,0x8(%esp)
80105e9f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105ea2:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ea6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ea9:	89 04 24             	mov    %eax,(%esp)
80105eac:	e8 48 c8 ff ff       	call   801026f9 <dirlookup>
80105eb1:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105eb4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105eb8:	0f 84 03 01 00 00    	je     80105fc1 <sys_unlink+0x1bb>
    goto bad;
  ilock(ip);
80105ebe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ec1:	89 04 24             	mov    %eax,(%esp)
80105ec4:	e8 17 c0 ff ff       	call   80101ee0 <ilock>

  if(ip->nlink < 1)
80105ec9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ecc:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105ed0:	66 85 c0             	test   %ax,%ax
80105ed3:	7f 0c                	jg     80105ee1 <sys_unlink+0xdb>
    panic("unlink: nlink < 1");
80105ed5:	c7 04 24 ee 8c 10 80 	movl   $0x80108cee,(%esp)
80105edc:	e8 5c a6 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105ee1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ee4:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105ee8:	66 83 f8 01          	cmp    $0x1,%ax
80105eec:	75 1f                	jne    80105f0d <sys_unlink+0x107>
80105eee:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105ef1:	89 04 24             	mov    %eax,(%esp)
80105ef4:	e8 9f fe ff ff       	call   80105d98 <isdirempty>
80105ef9:	85 c0                	test   %eax,%eax
80105efb:	75 10                	jne    80105f0d <sys_unlink+0x107>
    iunlockput(ip);
80105efd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f00:	89 04 24             	mov    %eax,(%esp)
80105f03:	e8 5c c2 ff ff       	call   80102164 <iunlockput>
    goto bad;
80105f08:	e9 b5 00 00 00       	jmp    80105fc2 <sys_unlink+0x1bc>
  }

  memset(&de, 0, sizeof(de));
80105f0d:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
80105f14:	00 
80105f15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80105f1c:	00 
80105f1d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105f20:	89 04 24             	mov    %eax,(%esp)
80105f23:	e8 42 f5 ff ff       	call   8010546a <memset>
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105f28:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105f2b:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
80105f32:	00 
80105f33:	89 44 24 08          	mov    %eax,0x8(%esp)
80105f37:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105f3a:	89 44 24 04          	mov    %eax,0x4(%esp)
80105f3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f41:	89 04 24             	mov    %eax,(%esp)
80105f44:	e8 f8 c5 ff ff       	call   80102541 <writei>
80105f49:	83 f8 10             	cmp    $0x10,%eax
80105f4c:	74 0c                	je     80105f5a <sys_unlink+0x154>
    panic("unlink: writei");
80105f4e:	c7 04 24 00 8d 10 80 	movl   $0x80108d00,(%esp)
80105f55:	e8 e3 a5 ff ff       	call   8010053d <panic>
  if(ip->type == T_DIR){
80105f5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f5d:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80105f61:	66 83 f8 01          	cmp    $0x1,%ax
80105f65:	75 1c                	jne    80105f83 <sys_unlink+0x17d>
    dp->nlink--;
80105f67:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f6a:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105f6e:	8d 50 ff             	lea    -0x1(%eax),%edx
80105f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f74:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80105f78:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f7b:	89 04 24             	mov    %eax,(%esp)
80105f7e:	e8 a1 bd ff ff       	call   80101d24 <iupdate>
  }
  iunlockput(dp);
80105f83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f86:	89 04 24             	mov    %eax,(%esp)
80105f89:	e8 d6 c1 ff ff       	call   80102164 <iunlockput>

  ip->nlink--;
80105f8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f91:	0f b7 40 16          	movzwl 0x16(%eax),%eax
80105f95:	8d 50 ff             	lea    -0x1(%eax),%edx
80105f98:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105f9b:	66 89 50 16          	mov    %dx,0x16(%eax)
  iupdate(ip);
80105f9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fa2:	89 04 24             	mov    %eax,(%esp)
80105fa5:	e8 7a bd ff ff       	call   80101d24 <iupdate>
  iunlockput(ip);
80105faa:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fad:	89 04 24             	mov    %eax,(%esp)
80105fb0:	e8 af c1 ff ff       	call   80102164 <iunlockput>

  commit_trans();
80105fb5:	e8 24 d9 ff ff       	call   801038de <commit_trans>

  return 0;
80105fba:	b8 00 00 00 00       	mov    $0x0,%eax
80105fbf:	eb 16                	jmp    80105fd7 <sys_unlink+0x1d1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105fc1:	90                   	nop
  commit_trans();

  return 0;

bad:
  iunlockput(dp);
80105fc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105fc5:	89 04 24             	mov    %eax,(%esp)
80105fc8:	e8 97 c1 ff ff       	call   80102164 <iunlockput>
  commit_trans();
80105fcd:	e8 0c d9 ff ff       	call   801038de <commit_trans>
  return -1;
80105fd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105fd7:	c9                   	leave  
80105fd8:	c3                   	ret    

80105fd9 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105fd9:	55                   	push   %ebp
80105fda:	89 e5                	mov    %esp,%ebp
80105fdc:	83 ec 48             	sub    $0x48,%esp
80105fdf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105fe2:	8b 55 10             	mov    0x10(%ebp),%edx
80105fe5:	8b 45 14             	mov    0x14(%ebp),%eax
80105fe8:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105fec:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105ff0:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105ff4:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ff7:	89 44 24 04          	mov    %eax,0x4(%esp)
80105ffb:	8b 45 08             	mov    0x8(%ebp),%eax
80105ffe:	89 04 24             	mov    %eax,(%esp)
80106001:	e8 9e ca ff ff       	call   80102aa4 <nameiparent>
80106006:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106009:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010600d:	75 0a                	jne    80106019 <create+0x40>
    return 0;
8010600f:	b8 00 00 00 00       	mov    $0x0,%eax
80106014:	e9 7e 01 00 00       	jmp    80106197 <create+0x1be>
  ilock(dp);
80106019:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010601c:	89 04 24             	mov    %eax,(%esp)
8010601f:	e8 bc be ff ff       	call   80101ee0 <ilock>

  if((ip = dirlookup(dp, name, &off)) != 0){
80106024:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106027:	89 44 24 08          	mov    %eax,0x8(%esp)
8010602b:	8d 45 de             	lea    -0x22(%ebp),%eax
8010602e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106032:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106035:	89 04 24             	mov    %eax,(%esp)
80106038:	e8 bc c6 ff ff       	call   801026f9 <dirlookup>
8010603d:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106040:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106044:	74 47                	je     8010608d <create+0xb4>
    iunlockput(dp);
80106046:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106049:	89 04 24             	mov    %eax,(%esp)
8010604c:	e8 13 c1 ff ff       	call   80102164 <iunlockput>
    ilock(ip);
80106051:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106054:	89 04 24             	mov    %eax,(%esp)
80106057:	e8 84 be ff ff       	call   80101ee0 <ilock>
    if(type == T_FILE && ip->type == T_FILE)
8010605c:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80106061:	75 15                	jne    80106078 <create+0x9f>
80106063:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106066:	0f b7 40 10          	movzwl 0x10(%eax),%eax
8010606a:	66 83 f8 02          	cmp    $0x2,%ax
8010606e:	75 08                	jne    80106078 <create+0x9f>
      return ip;
80106070:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106073:	e9 1f 01 00 00       	jmp    80106197 <create+0x1be>
    iunlockput(ip);
80106078:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010607b:	89 04 24             	mov    %eax,(%esp)
8010607e:	e8 e1 c0 ff ff       	call   80102164 <iunlockput>
    return 0;
80106083:	b8 00 00 00 00       	mov    $0x0,%eax
80106088:	e9 0a 01 00 00       	jmp    80106197 <create+0x1be>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
8010608d:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80106091:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106094:	8b 00                	mov    (%eax),%eax
80106096:	89 54 24 04          	mov    %edx,0x4(%esp)
8010609a:	89 04 24             	mov    %eax,(%esp)
8010609d:	e8 a5 bb ff ff       	call   80101c47 <ialloc>
801060a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
801060a5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801060a9:	75 0c                	jne    801060b7 <create+0xde>
    panic("create: ialloc");
801060ab:	c7 04 24 0f 8d 10 80 	movl   $0x80108d0f,(%esp)
801060b2:	e8 86 a4 ff ff       	call   8010053d <panic>

  ilock(ip);
801060b7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060ba:	89 04 24             	mov    %eax,(%esp)
801060bd:	e8 1e be ff ff       	call   80101ee0 <ilock>
  ip->major = major;
801060c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060c5:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
801060c9:	66 89 50 12          	mov    %dx,0x12(%eax)
  ip->minor = minor;
801060cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060d0:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
801060d4:	66 89 50 14          	mov    %dx,0x14(%eax)
  ip->nlink = 1;
801060d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060db:	66 c7 40 16 01 00    	movw   $0x1,0x16(%eax)
  iupdate(ip);
801060e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801060e4:	89 04 24             	mov    %eax,(%esp)
801060e7:	e8 38 bc ff ff       	call   80101d24 <iupdate>

  if(type == T_DIR){  // Create . and .. entries.
801060ec:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
801060f1:	75 6a                	jne    8010615d <create+0x184>
    dp->nlink++;  // for ".."
801060f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801060f6:	0f b7 40 16          	movzwl 0x16(%eax),%eax
801060fa:	8d 50 01             	lea    0x1(%eax),%edx
801060fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106100:	66 89 50 16          	mov    %dx,0x16(%eax)
    iupdate(dp);
80106104:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106107:	89 04 24             	mov    %eax,(%esp)
8010610a:	e8 15 bc ff ff       	call   80101d24 <iupdate>
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
8010610f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106112:	8b 40 04             	mov    0x4(%eax),%eax
80106115:	89 44 24 08          	mov    %eax,0x8(%esp)
80106119:	c7 44 24 04 e9 8c 10 	movl   $0x80108ce9,0x4(%esp)
80106120:	80 
80106121:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106124:	89 04 24             	mov    %eax,(%esp)
80106127:	e8 95 c6 ff ff       	call   801027c1 <dirlink>
8010612c:	85 c0                	test   %eax,%eax
8010612e:	78 21                	js     80106151 <create+0x178>
80106130:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106133:	8b 40 04             	mov    0x4(%eax),%eax
80106136:	89 44 24 08          	mov    %eax,0x8(%esp)
8010613a:	c7 44 24 04 eb 8c 10 	movl   $0x80108ceb,0x4(%esp)
80106141:	80 
80106142:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106145:	89 04 24             	mov    %eax,(%esp)
80106148:	e8 74 c6 ff ff       	call   801027c1 <dirlink>
8010614d:	85 c0                	test   %eax,%eax
8010614f:	79 0c                	jns    8010615d <create+0x184>
      panic("create dots");
80106151:	c7 04 24 1e 8d 10 80 	movl   $0x80108d1e,(%esp)
80106158:	e8 e0 a3 ff ff       	call   8010053d <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
8010615d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106160:	8b 40 04             	mov    0x4(%eax),%eax
80106163:	89 44 24 08          	mov    %eax,0x8(%esp)
80106167:	8d 45 de             	lea    -0x22(%ebp),%eax
8010616a:	89 44 24 04          	mov    %eax,0x4(%esp)
8010616e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106171:	89 04 24             	mov    %eax,(%esp)
80106174:	e8 48 c6 ff ff       	call   801027c1 <dirlink>
80106179:	85 c0                	test   %eax,%eax
8010617b:	79 0c                	jns    80106189 <create+0x1b0>
    panic("create: dirlink");
8010617d:	c7 04 24 2a 8d 10 80 	movl   $0x80108d2a,(%esp)
80106184:	e8 b4 a3 ff ff       	call   8010053d <panic>

  iunlockput(dp);
80106189:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010618c:	89 04 24             	mov    %eax,(%esp)
8010618f:	e8 d0 bf ff ff       	call   80102164 <iunlockput>

  return ip;
80106194:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80106197:	c9                   	leave  
80106198:	c3                   	ret    

80106199 <sys_open>:

int
sys_open(void)
{
80106199:	55                   	push   %ebp
8010619a:	89 e5                	mov    %esp,%ebp
8010619c:	83 ec 38             	sub    $0x38,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
8010619f:	8d 45 e8             	lea    -0x18(%ebp),%eax
801061a2:	89 44 24 04          	mov    %eax,0x4(%esp)
801061a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801061ad:	e8 a2 f6 ff ff       	call   80105854 <argstr>
801061b2:	85 c0                	test   %eax,%eax
801061b4:	78 17                	js     801061cd <sys_open+0x34>
801061b6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801061b9:	89 44 24 04          	mov    %eax,0x4(%esp)
801061bd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801061c4:	e8 f1 f5 ff ff       	call   801057ba <argint>
801061c9:	85 c0                	test   %eax,%eax
801061cb:	79 0a                	jns    801061d7 <sys_open+0x3e>
    return -1;
801061cd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061d2:	e9 46 01 00 00       	jmp    8010631d <sys_open+0x184>
  if(omode & O_CREATE){
801061d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801061da:	25 00 02 00 00       	and    $0x200,%eax
801061df:	85 c0                	test   %eax,%eax
801061e1:	74 40                	je     80106223 <sys_open+0x8a>
    begin_trans();
801061e3:	e8 ad d6 ff ff       	call   80103895 <begin_trans>
    ip = create(path, T_FILE, 0, 0);
801061e8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801061eb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
801061f2:	00 
801061f3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801061fa:	00 
801061fb:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
80106202:	00 
80106203:	89 04 24             	mov    %eax,(%esp)
80106206:	e8 ce fd ff ff       	call   80105fd9 <create>
8010620b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    commit_trans();
8010620e:	e8 cb d6 ff ff       	call   801038de <commit_trans>
    if(ip == 0)
80106213:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106217:	75 5c                	jne    80106275 <sys_open+0xdc>
      return -1;
80106219:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010621e:	e9 fa 00 00 00       	jmp    8010631d <sys_open+0x184>
  } else {
    if((ip = namei(path)) == 0)
80106223:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106226:	89 04 24             	mov    %eax,(%esp)
80106229:	e8 54 c8 ff ff       	call   80102a82 <namei>
8010622e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106231:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106235:	75 0a                	jne    80106241 <sys_open+0xa8>
      return -1;
80106237:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010623c:	e9 dc 00 00 00       	jmp    8010631d <sys_open+0x184>
    ilock(ip);
80106241:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106244:	89 04 24             	mov    %eax,(%esp)
80106247:	e8 94 bc ff ff       	call   80101ee0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
8010624c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010624f:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106253:	66 83 f8 01          	cmp    $0x1,%ax
80106257:	75 1c                	jne    80106275 <sys_open+0xdc>
80106259:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010625c:	85 c0                	test   %eax,%eax
8010625e:	74 15                	je     80106275 <sys_open+0xdc>
      iunlockput(ip);
80106260:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106263:	89 04 24             	mov    %eax,(%esp)
80106266:	e8 f9 be ff ff       	call   80102164 <iunlockput>
      return -1;
8010626b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106270:	e9 a8 00 00 00       	jmp    8010631d <sys_open+0x184>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80106275:	e8 1a b3 ff ff       	call   80101594 <filealloc>
8010627a:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010627d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106281:	74 14                	je     80106297 <sys_open+0xfe>
80106283:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106286:	89 04 24             	mov    %eax,(%esp)
80106289:	e8 43 f7 ff ff       	call   801059d1 <fdalloc>
8010628e:	89 45 ec             	mov    %eax,-0x14(%ebp)
80106291:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80106295:	79 23                	jns    801062ba <sys_open+0x121>
    if(f)
80106297:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010629b:	74 0b                	je     801062a8 <sys_open+0x10f>
      fileclose(f);
8010629d:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062a0:	89 04 24             	mov    %eax,(%esp)
801062a3:	e8 94 b3 ff ff       	call   8010163c <fileclose>
    iunlockput(ip);
801062a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062ab:	89 04 24             	mov    %eax,(%esp)
801062ae:	e8 b1 be ff ff       	call   80102164 <iunlockput>
    return -1;
801062b3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062b8:	eb 63                	jmp    8010631d <sys_open+0x184>
  }
  iunlock(ip);
801062ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
801062bd:	89 04 24             	mov    %eax,(%esp)
801062c0:	e8 69 bd ff ff       	call   8010202e <iunlock>

  f->type = FD_INODE;
801062c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062c8:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
801062ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062d4:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
801062d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062da:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
801062e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062e4:	83 e0 01             	and    $0x1,%eax
801062e7:	85 c0                	test   %eax,%eax
801062e9:	0f 94 c2             	sete   %dl
801062ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
801062ef:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
801062f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062f5:	83 e0 01             	and    $0x1,%eax
801062f8:	84 c0                	test   %al,%al
801062fa:	75 0a                	jne    80106306 <sys_open+0x16d>
801062fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801062ff:	83 e0 02             	and    $0x2,%eax
80106302:	85 c0                	test   %eax,%eax
80106304:	74 07                	je     8010630d <sys_open+0x174>
80106306:	b8 01 00 00 00       	mov    $0x1,%eax
8010630b:	eb 05                	jmp    80106312 <sys_open+0x179>
8010630d:	b8 00 00 00 00       	mov    $0x0,%eax
80106312:	89 c2                	mov    %eax,%edx
80106314:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106317:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010631a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010631d:	c9                   	leave  
8010631e:	c3                   	ret    

8010631f <sys_mkdir>:

int
sys_mkdir(void)
{
8010631f:	55                   	push   %ebp
80106320:	89 e5                	mov    %esp,%ebp
80106322:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  begin_trans();
80106325:	e8 6b d5 ff ff       	call   80103895 <begin_trans>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010632a:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010632d:	89 44 24 04          	mov    %eax,0x4(%esp)
80106331:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106338:	e8 17 f5 ff ff       	call   80105854 <argstr>
8010633d:	85 c0                	test   %eax,%eax
8010633f:	78 2c                	js     8010636d <sys_mkdir+0x4e>
80106341:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106344:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
8010634b:	00 
8010634c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80106353:	00 
80106354:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
8010635b:	00 
8010635c:	89 04 24             	mov    %eax,(%esp)
8010635f:	e8 75 fc ff ff       	call   80105fd9 <create>
80106364:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106367:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010636b:	75 0c                	jne    80106379 <sys_mkdir+0x5a>
    commit_trans();
8010636d:	e8 6c d5 ff ff       	call   801038de <commit_trans>
    return -1;
80106372:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106377:	eb 15                	jmp    8010638e <sys_mkdir+0x6f>
  }
  iunlockput(ip);
80106379:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010637c:	89 04 24             	mov    %eax,(%esp)
8010637f:	e8 e0 bd ff ff       	call   80102164 <iunlockput>
  commit_trans();
80106384:	e8 55 d5 ff ff       	call   801038de <commit_trans>
  return 0;
80106389:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010638e:	c9                   	leave  
8010638f:	c3                   	ret    

80106390 <sys_mknod>:

int
sys_mknod(void)
{
80106390:	55                   	push   %ebp
80106391:	89 e5                	mov    %esp,%ebp
80106393:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip;
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
80106396:	e8 fa d4 ff ff       	call   80103895 <begin_trans>
  if((len=argstr(0, &path)) < 0 ||
8010639b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010639e:	89 44 24 04          	mov    %eax,0x4(%esp)
801063a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801063a9:	e8 a6 f4 ff ff       	call   80105854 <argstr>
801063ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
801063b1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801063b5:	78 5e                	js     80106415 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
801063b7:	8d 45 e8             	lea    -0x18(%ebp),%eax
801063ba:	89 44 24 04          	mov    %eax,0x4(%esp)
801063be:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801063c5:	e8 f0 f3 ff ff       	call   801057ba <argint>
  char *path;
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
801063ca:	85 c0                	test   %eax,%eax
801063cc:	78 47                	js     80106415 <sys_mknod+0x85>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801063ce:	8d 45 e4             	lea    -0x1c(%ebp),%eax
801063d1:	89 44 24 04          	mov    %eax,0x4(%esp)
801063d5:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
801063dc:	e8 d9 f3 ff ff       	call   801057ba <argint>
  int len;
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801063e1:	85 c0                	test   %eax,%eax
801063e3:	78 30                	js     80106415 <sys_mknod+0x85>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801063e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
801063e8:	0f bf c8             	movswl %ax,%ecx
801063eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
801063ee:	0f bf d0             	movswl %ax,%edx
801063f1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  int major, minor;
  
  begin_trans();
  if((len=argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801063f4:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
801063f8:	89 54 24 08          	mov    %edx,0x8(%esp)
801063fc:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106403:	00 
80106404:	89 04 24             	mov    %eax,(%esp)
80106407:	e8 cd fb ff ff       	call   80105fd9 <create>
8010640c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010640f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106413:	75 0c                	jne    80106421 <sys_mknod+0x91>
     (ip = create(path, T_DEV, major, minor)) == 0){
    commit_trans();
80106415:	e8 c4 d4 ff ff       	call   801038de <commit_trans>
    return -1;
8010641a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010641f:	eb 15                	jmp    80106436 <sys_mknod+0xa6>
  }
  iunlockput(ip);
80106421:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106424:	89 04 24             	mov    %eax,(%esp)
80106427:	e8 38 bd ff ff       	call   80102164 <iunlockput>
  commit_trans();
8010642c:	e8 ad d4 ff ff       	call   801038de <commit_trans>
  return 0;
80106431:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106436:	c9                   	leave  
80106437:	c3                   	ret    

80106438 <sys_chdir>:

int
sys_chdir(void)
{
80106438:	55                   	push   %ebp
80106439:	89 e5                	mov    %esp,%ebp
8010643b:	83 ec 28             	sub    $0x28,%esp
  char *path;
  struct inode *ip;

  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0)
8010643e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106441:	89 44 24 04          	mov    %eax,0x4(%esp)
80106445:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010644c:	e8 03 f4 ff ff       	call   80105854 <argstr>
80106451:	85 c0                	test   %eax,%eax
80106453:	78 14                	js     80106469 <sys_chdir+0x31>
80106455:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106458:	89 04 24             	mov    %eax,(%esp)
8010645b:	e8 22 c6 ff ff       	call   80102a82 <namei>
80106460:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106463:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106467:	75 07                	jne    80106470 <sys_chdir+0x38>
    return -1;
80106469:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010646e:	eb 57                	jmp    801064c7 <sys_chdir+0x8f>
  ilock(ip);
80106470:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106473:	89 04 24             	mov    %eax,(%esp)
80106476:	e8 65 ba ff ff       	call   80101ee0 <ilock>
  if(ip->type != T_DIR){
8010647b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010647e:	0f b7 40 10          	movzwl 0x10(%eax),%eax
80106482:	66 83 f8 01          	cmp    $0x1,%ax
80106486:	74 12                	je     8010649a <sys_chdir+0x62>
    iunlockput(ip);
80106488:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010648b:	89 04 24             	mov    %eax,(%esp)
8010648e:	e8 d1 bc ff ff       	call   80102164 <iunlockput>
    return -1;
80106493:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106498:	eb 2d                	jmp    801064c7 <sys_chdir+0x8f>
  }
  iunlock(ip);
8010649a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010649d:	89 04 24             	mov    %eax,(%esp)
801064a0:	e8 89 bb ff ff       	call   8010202e <iunlock>
  iput(proc->cwd);
801064a5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064ab:	8b 40 68             	mov    0x68(%eax),%eax
801064ae:	89 04 24             	mov    %eax,(%esp)
801064b1:	e8 dd bb ff ff       	call   80102093 <iput>
  proc->cwd = ip;
801064b6:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801064bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
801064bf:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801064c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
801064c7:	c9                   	leave  
801064c8:	c3                   	ret    

801064c9 <sys_exec>:

int
sys_exec(void)
{
801064c9:	55                   	push   %ebp
801064ca:	89 e5                	mov    %esp,%ebp
801064cc:	81 ec a8 00 00 00    	sub    $0xa8,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801064d2:	8d 45 f0             	lea    -0x10(%ebp),%eax
801064d5:	89 44 24 04          	mov    %eax,0x4(%esp)
801064d9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801064e0:	e8 6f f3 ff ff       	call   80105854 <argstr>
801064e5:	85 c0                	test   %eax,%eax
801064e7:	78 1a                	js     80106503 <sys_exec+0x3a>
801064e9:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
801064ef:	89 44 24 04          	mov    %eax,0x4(%esp)
801064f3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
801064fa:	e8 bb f2 ff ff       	call   801057ba <argint>
801064ff:	85 c0                	test   %eax,%eax
80106501:	79 0a                	jns    8010650d <sys_exec+0x44>
    return -1;
80106503:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106508:	e9 e2 00 00 00       	jmp    801065ef <sys_exec+0x126>
  }
  memset(argv, 0, sizeof(argv));
8010650d:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
80106514:	00 
80106515:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
8010651c:	00 
8010651d:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
80106523:	89 04 24             	mov    %eax,(%esp)
80106526:	e8 3f ef ff ff       	call   8010546a <memset>
  for(i=0;; i++){
8010652b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
80106532:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106535:	83 f8 1f             	cmp    $0x1f,%eax
80106538:	76 0a                	jbe    80106544 <sys_exec+0x7b>
      return -1;
8010653a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010653f:	e9 ab 00 00 00       	jmp    801065ef <sys_exec+0x126>
    if(fetchint(proc, uargv+4*i, (int*)&uarg) < 0)
80106544:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106547:	c1 e0 02             	shl    $0x2,%eax
8010654a:	89 c2                	mov    %eax,%edx
8010654c:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
80106552:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80106555:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
8010655b:	8d 95 68 ff ff ff    	lea    -0x98(%ebp),%edx
80106561:	89 54 24 08          	mov    %edx,0x8(%esp)
80106565:	89 4c 24 04          	mov    %ecx,0x4(%esp)
80106569:	89 04 24             	mov    %eax,(%esp)
8010656c:	e8 b7 f1 ff ff       	call   80105728 <fetchint>
80106571:	85 c0                	test   %eax,%eax
80106573:	79 07                	jns    8010657c <sys_exec+0xb3>
      return -1;
80106575:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010657a:	eb 73                	jmp    801065ef <sys_exec+0x126>
    if(uarg == 0){
8010657c:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106582:	85 c0                	test   %eax,%eax
80106584:	75 26                	jne    801065ac <sys_exec+0xe3>
      argv[i] = 0;
80106586:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106589:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
80106590:	00 00 00 00 
      break;
80106594:	90                   	nop
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106595:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106598:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
8010659e:	89 54 24 04          	mov    %edx,0x4(%esp)
801065a2:	89 04 24             	mov    %eax,(%esp)
801065a5:	e8 32 ab ff ff       	call   801010dc <exec>
801065aa:	eb 43                	jmp    801065ef <sys_exec+0x126>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
801065ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065af:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801065b6:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801065bc:	8d 0c 10             	lea    (%eax,%edx,1),%ecx
801065bf:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
801065c5:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801065cb:	89 4c 24 08          	mov    %ecx,0x8(%esp)
801065cf:	89 54 24 04          	mov    %edx,0x4(%esp)
801065d3:	89 04 24             	mov    %eax,(%esp)
801065d6:	e8 81 f1 ff ff       	call   8010575c <fetchstr>
801065db:	85 c0                	test   %eax,%eax
801065dd:	79 07                	jns    801065e6 <sys_exec+0x11d>
      return -1;
801065df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801065e4:	eb 09                	jmp    801065ef <sys_exec+0x126>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801065e6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(proc, uarg, &argv[i]) < 0)
      return -1;
  }
801065ea:	e9 43 ff ff ff       	jmp    80106532 <sys_exec+0x69>
  return exec(path, argv);
}
801065ef:	c9                   	leave  
801065f0:	c3                   	ret    

801065f1 <sys_pipe>:

int
sys_pipe(void)
{
801065f1:	55                   	push   %ebp
801065f2:	89 e5                	mov    %esp,%ebp
801065f4:	83 ec 38             	sub    $0x38,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801065f7:	c7 44 24 08 08 00 00 	movl   $0x8,0x8(%esp)
801065fe:	00 
801065ff:	8d 45 ec             	lea    -0x14(%ebp),%eax
80106602:	89 44 24 04          	mov    %eax,0x4(%esp)
80106606:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010660d:	e8 e0 f1 ff ff       	call   801057f2 <argptr>
80106612:	85 c0                	test   %eax,%eax
80106614:	79 0a                	jns    80106620 <sys_pipe+0x2f>
    return -1;
80106616:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010661b:	e9 9b 00 00 00       	jmp    801066bb <sys_pipe+0xca>
  if(pipealloc(&rf, &wf) < 0)
80106620:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106623:	89 44 24 04          	mov    %eax,0x4(%esp)
80106627:	8d 45 e8             	lea    -0x18(%ebp),%eax
8010662a:	89 04 24             	mov    %eax,(%esp)
8010662d:	e8 7e dc ff ff       	call   801042b0 <pipealloc>
80106632:	85 c0                	test   %eax,%eax
80106634:	79 07                	jns    8010663d <sys_pipe+0x4c>
    return -1;
80106636:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010663b:	eb 7e                	jmp    801066bb <sys_pipe+0xca>
  fd0 = -1;
8010663d:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106644:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106647:	89 04 24             	mov    %eax,(%esp)
8010664a:	e8 82 f3 ff ff       	call   801059d1 <fdalloc>
8010664f:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106652:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106656:	78 14                	js     8010666c <sys_pipe+0x7b>
80106658:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010665b:	89 04 24             	mov    %eax,(%esp)
8010665e:	e8 6e f3 ff ff       	call   801059d1 <fdalloc>
80106663:	89 45 f0             	mov    %eax,-0x10(%ebp)
80106666:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010666a:	79 37                	jns    801066a3 <sys_pipe+0xb2>
    if(fd0 >= 0)
8010666c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106670:	78 14                	js     80106686 <sys_pipe+0x95>
      proc->ofile[fd0] = 0;
80106672:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106678:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010667b:	83 c2 08             	add    $0x8,%edx
8010667e:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80106685:	00 
    fileclose(rf);
80106686:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106689:	89 04 24             	mov    %eax,(%esp)
8010668c:	e8 ab af ff ff       	call   8010163c <fileclose>
    fileclose(wf);
80106691:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106694:	89 04 24             	mov    %eax,(%esp)
80106697:	e8 a0 af ff ff       	call   8010163c <fileclose>
    return -1;
8010669c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801066a1:	eb 18                	jmp    801066bb <sys_pipe+0xca>
  }
  fd[0] = fd0;
801066a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801066a6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801066a9:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801066ab:	8b 45 ec             	mov    -0x14(%ebp),%eax
801066ae:	8d 50 04             	lea    0x4(%eax),%edx
801066b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801066b4:	89 02                	mov    %eax,(%edx)
  return 0;
801066b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801066bb:	c9                   	leave  
801066bc:	c3                   	ret    
801066bd:	00 00                	add    %al,(%eax)
	...

801066c0 <add_path>:
#include "mmu.h"
#include "proc.h"

//------------------- PATCH -------------------//

int add_path(char* path){
801066c0:	55                   	push   %ebp
801066c1:	89 e5                	mov    %esp,%ebp
801066c3:	83 ec 18             	sub    $0x18,%esp
  if (lastPath==10){
801066c6:	a1 a0 e8 10 80       	mov    0x8010e8a0,%eax
801066cb:	83 f8 0a             	cmp    $0xa,%eax
801066ce:	75 11                	jne    801066e1 <add_path+0x21>
    cprintf("could not add path - all paths in use\n");
801066d0:	c7 04 24 3c 8d 10 80 	movl   $0x80108d3c,(%esp)
801066d7:	e8 c5 9c ff ff       	call   801003a1 <cprintf>
    exit();
801066dc:	e8 ec e3 ff ff       	call   80104acd <exit>
  }
  strncpy(PATH[lastPath], path, strlen(path)+1);
801066e1:	8b 45 08             	mov    0x8(%ebp),%eax
801066e4:	89 04 24             	mov    %eax,(%esp)
801066e7:	e8 fc ef ff ff       	call   801056e8 <strlen>
801066ec:	83 c0 01             	add    $0x1,%eax
801066ef:	8b 15 a0 e8 10 80    	mov    0x8010e8a0,%edx
801066f5:	c1 e2 07             	shl    $0x7,%edx
801066f8:	81 c2 c0 e8 10 80    	add    $0x8010e8c0,%edx
801066fe:	89 44 24 08          	mov    %eax,0x8(%esp)
80106702:	8b 45 08             	mov    0x8(%ebp),%eax
80106705:	89 44 24 04          	mov    %eax,0x4(%esp)
80106709:	89 14 24             	mov    %edx,(%esp)
8010670c:	e8 28 ef ff ff       	call   80105639 <strncpy>
  cprintf("path added '%s'\n", PATH[lastPath]);
80106711:	a1 a0 e8 10 80       	mov    0x8010e8a0,%eax
80106716:	c1 e0 07             	shl    $0x7,%eax
80106719:	05 c0 e8 10 80       	add    $0x8010e8c0,%eax
8010671e:	89 44 24 04          	mov    %eax,0x4(%esp)
80106722:	c7 04 24 63 8d 10 80 	movl   $0x80108d63,(%esp)
80106729:	e8 73 9c ff ff       	call   801003a1 <cprintf>
  lastPath++;
8010672e:	a1 a0 e8 10 80       	mov    0x8010e8a0,%eax
80106733:	83 c0 01             	add    $0x1,%eax
80106736:	a3 a0 e8 10 80       	mov    %eax,0x8010e8a0
  return 0;
8010673b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106740:	c9                   	leave  
80106741:	c3                   	ret    

80106742 <sys_add_path>:

int
sys_add_path(void)
{
80106742:	55                   	push   %ebp
80106743:	89 e5                	mov    %esp,%ebp
80106745:	83 ec 28             	sub    $0x28,%esp
  char *path;
  if(argstr(0, &path) < 0)
80106748:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010674b:	89 44 24 04          	mov    %eax,0x4(%esp)
8010674f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
80106756:	e8 f9 f0 ff ff       	call   80105854 <argstr>
8010675b:	85 c0                	test   %eax,%eax
8010675d:	79 07                	jns    80106766 <sys_add_path+0x24>
    return -1;
8010675f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106764:	eb 0b                	jmp    80106771 <sys_add_path+0x2f>
  return add_path(path);
80106766:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106769:	89 04 24             	mov    %eax,(%esp)
8010676c:	e8 4f ff ff ff       	call   801066c0 <add_path>
}
80106771:	c9                   	leave  
80106772:	c3                   	ret    

80106773 <sys_fork>:
//------------------- PATCH -------------------//


int
sys_fork(void)
{
80106773:	55                   	push   %ebp
80106774:	89 e5                	mov    %esp,%ebp
80106776:	83 ec 08             	sub    $0x8,%esp
  return fork();
80106779:	e8 ec e1 ff ff       	call   8010496a <fork>
}
8010677e:	c9                   	leave  
8010677f:	c3                   	ret    

80106780 <sys_exit>:

int
sys_exit(void)
{
80106780:	55                   	push   %ebp
80106781:	89 e5                	mov    %esp,%ebp
80106783:	83 ec 08             	sub    $0x8,%esp
  exit();
80106786:	e8 42 e3 ff ff       	call   80104acd <exit>
  return 0;  // not reached
8010678b:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106790:	c9                   	leave  
80106791:	c3                   	ret    

80106792 <sys_wait>:

int
sys_wait(void)
{
80106792:	55                   	push   %ebp
80106793:	89 e5                	mov    %esp,%ebp
80106795:	83 ec 08             	sub    $0x8,%esp
  return wait();
80106798:	e8 48 e4 ff ff       	call   80104be5 <wait>
}
8010679d:	c9                   	leave  
8010679e:	c3                   	ret    

8010679f <sys_kill>:

int
sys_kill(void)
{
8010679f:	55                   	push   %ebp
801067a0:	89 e5                	mov    %esp,%ebp
801067a2:	83 ec 28             	sub    $0x28,%esp
  int pid;

  if(argint(0, &pid) < 0)
801067a5:	8d 45 f4             	lea    -0xc(%ebp),%eax
801067a8:	89 44 24 04          	mov    %eax,0x4(%esp)
801067ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067b3:	e8 02 f0 ff ff       	call   801057ba <argint>
801067b8:	85 c0                	test   %eax,%eax
801067ba:	79 07                	jns    801067c3 <sys_kill+0x24>
    return -1;
801067bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801067c1:	eb 0b                	jmp    801067ce <sys_kill+0x2f>
  return kill(pid);
801067c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801067c6:	89 04 24             	mov    %eax,(%esp)
801067c9:	e8 73 e8 ff ff       	call   80105041 <kill>
}
801067ce:	c9                   	leave  
801067cf:	c3                   	ret    

801067d0 <sys_getpid>:

int
sys_getpid(void)
{
801067d0:	55                   	push   %ebp
801067d1:	89 e5                	mov    %esp,%ebp
  return proc->pid;
801067d3:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
801067d9:	8b 40 10             	mov    0x10(%eax),%eax
}
801067dc:	5d                   	pop    %ebp
801067dd:	c3                   	ret    

801067de <sys_sbrk>:

int
sys_sbrk(void)
{
801067de:	55                   	push   %ebp
801067df:	89 e5                	mov    %esp,%ebp
801067e1:	83 ec 28             	sub    $0x28,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
801067e4:	8d 45 f0             	lea    -0x10(%ebp),%eax
801067e7:	89 44 24 04          	mov    %eax,0x4(%esp)
801067eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
801067f2:	e8 c3 ef ff ff       	call   801057ba <argint>
801067f7:	85 c0                	test   %eax,%eax
801067f9:	79 07                	jns    80106802 <sys_sbrk+0x24>
    return -1;
801067fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106800:	eb 24                	jmp    80106826 <sys_sbrk+0x48>
  addr = proc->sz;
80106802:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106808:	8b 00                	mov    (%eax),%eax
8010680a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(growproc(n) < 0)
8010680d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106810:	89 04 24             	mov    %eax,(%esp)
80106813:	e8 ad e0 ff ff       	call   801048c5 <growproc>
80106818:	85 c0                	test   %eax,%eax
8010681a:	79 07                	jns    80106823 <sys_sbrk+0x45>
    return -1;
8010681c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106821:	eb 03                	jmp    80106826 <sys_sbrk+0x48>
  return addr;
80106823:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106826:	c9                   	leave  
80106827:	c3                   	ret    

80106828 <sys_sleep>:

int
sys_sleep(void)
{
80106828:	55                   	push   %ebp
80106829:	89 e5                	mov    %esp,%ebp
8010682b:	83 ec 28             	sub    $0x28,%esp
  int n;
  uint ticks0;
  
  if(argint(0, &n) < 0)
8010682e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106831:	89 44 24 04          	mov    %eax,0x4(%esp)
80106835:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010683c:	e8 79 ef ff ff       	call   801057ba <argint>
80106841:	85 c0                	test   %eax,%eax
80106843:	79 07                	jns    8010684c <sys_sleep+0x24>
    return -1;
80106845:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010684a:	eb 6c                	jmp    801068b8 <sys_sleep+0x90>
  acquire(&tickslock);
8010684c:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
80106853:	e8 c3 e9 ff ff       	call   8010521b <acquire>
  ticks0 = ticks;
80106858:	a1 00 36 11 80       	mov    0x80113600,%eax
8010685d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
80106860:	eb 34                	jmp    80106896 <sys_sleep+0x6e>
    if(proc->killed){
80106862:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106868:	8b 40 24             	mov    0x24(%eax),%eax
8010686b:	85 c0                	test   %eax,%eax
8010686d:	74 13                	je     80106882 <sys_sleep+0x5a>
      release(&tickslock);
8010686f:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
80106876:	e8 02 ea ff ff       	call   8010527d <release>
      return -1;
8010687b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106880:	eb 36                	jmp    801068b8 <sys_sleep+0x90>
    }
    sleep(&ticks, &tickslock);
80106882:	c7 44 24 04 c0 2d 11 	movl   $0x80112dc0,0x4(%esp)
80106889:	80 
8010688a:	c7 04 24 00 36 11 80 	movl   $0x80113600,(%esp)
80106891:	e8 a7 e6 ff ff       	call   80104f3d <sleep>
  
  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
80106896:	a1 00 36 11 80       	mov    0x80113600,%eax
8010689b:	89 c2                	mov    %eax,%edx
8010689d:	2b 55 f4             	sub    -0xc(%ebp),%edx
801068a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801068a3:	39 c2                	cmp    %eax,%edx
801068a5:	72 bb                	jb     80106862 <sys_sleep+0x3a>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801068a7:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
801068ae:	e8 ca e9 ff ff       	call   8010527d <release>
  return 0;
801068b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801068b8:	c9                   	leave  
801068b9:	c3                   	ret    

801068ba <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
801068ba:	55                   	push   %ebp
801068bb:	89 e5                	mov    %esp,%ebp
801068bd:	83 ec 28             	sub    $0x28,%esp
  uint xticks;
  
  acquire(&tickslock);
801068c0:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
801068c7:	e8 4f e9 ff ff       	call   8010521b <acquire>
  xticks = ticks;
801068cc:	a1 00 36 11 80       	mov    0x80113600,%eax
801068d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
801068d4:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
801068db:	e8 9d e9 ff ff       	call   8010527d <release>
  return xticks;
801068e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801068e3:	c9                   	leave  
801068e4:	c3                   	ret    
801068e5:	00 00                	add    %al,(%eax)
	...

801068e8 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
801068e8:	55                   	push   %ebp
801068e9:	89 e5                	mov    %esp,%ebp
801068eb:	83 ec 08             	sub    $0x8,%esp
801068ee:	8b 55 08             	mov    0x8(%ebp),%edx
801068f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801068f4:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801068f8:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801068fb:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801068ff:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106903:	ee                   	out    %al,(%dx)
}
80106904:	c9                   	leave  
80106905:	c3                   	ret    

80106906 <timerinit>:
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

void
timerinit(void)
{
80106906:	55                   	push   %ebp
80106907:	89 e5                	mov    %esp,%ebp
80106909:	83 ec 18             	sub    $0x18,%esp
  // Interrupt 100 times/sec.
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
8010690c:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
80106913:	00 
80106914:	c7 04 24 43 00 00 00 	movl   $0x43,(%esp)
8010691b:	e8 c8 ff ff ff       	call   801068e8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) % 256);
80106920:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
80106927:	00 
80106928:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
8010692f:	e8 b4 ff ff ff       	call   801068e8 <outb>
  outb(IO_TIMER1, TIMER_DIV(100) / 256);
80106934:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
8010693b:	00 
8010693c:	c7 04 24 40 00 00 00 	movl   $0x40,(%esp)
80106943:	e8 a0 ff ff ff       	call   801068e8 <outb>
  picenable(IRQ_TIMER);
80106948:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
8010694f:	e8 e5 d7 ff ff       	call   80104139 <picenable>
}
80106954:	c9                   	leave  
80106955:	c3                   	ret    
	...

80106958 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106958:	1e                   	push   %ds
  pushl %es
80106959:	06                   	push   %es
  pushl %fs
8010695a:	0f a0                	push   %fs
  pushl %gs
8010695c:	0f a8                	push   %gs
  pushal
8010695e:	60                   	pusha  
  
  # Set up data and per-cpu segments.
  movw $(SEG_KDATA<<3), %ax
8010695f:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106963:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106965:	8e c0                	mov    %eax,%es
  movw $(SEG_KCPU<<3), %ax
80106967:	66 b8 18 00          	mov    $0x18,%ax
  movw %ax, %fs
8010696b:	8e e0                	mov    %eax,%fs
  movw %ax, %gs
8010696d:	8e e8                	mov    %eax,%gs

  # Call trap(tf), where tf=%esp
  pushl %esp
8010696f:	54                   	push   %esp
  call trap
80106970:	e8 de 01 00 00       	call   80106b53 <trap>
  addl $4, %esp
80106975:	83 c4 04             	add    $0x4,%esp

80106978 <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
80106978:	61                   	popa   
  popl %gs
80106979:	0f a9                	pop    %gs
  popl %fs
8010697b:	0f a1                	pop    %fs
  popl %es
8010697d:	07                   	pop    %es
  popl %ds
8010697e:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
8010697f:	83 c4 08             	add    $0x8,%esp
  iret
80106982:	cf                   	iret   
	...

80106984 <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
80106984:	55                   	push   %ebp
80106985:	89 e5                	mov    %esp,%ebp
80106987:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010698a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010698d:	83 e8 01             	sub    $0x1,%eax
80106990:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80106994:	8b 45 08             	mov    0x8(%ebp),%eax
80106997:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010699b:	8b 45 08             	mov    0x8(%ebp),%eax
8010699e:	c1 e8 10             	shr    $0x10,%eax
801069a1:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
801069a5:	8d 45 fa             	lea    -0x6(%ebp),%eax
801069a8:	0f 01 18             	lidtl  (%eax)
}
801069ab:	c9                   	leave  
801069ac:	c3                   	ret    

801069ad <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
801069ad:	55                   	push   %ebp
801069ae:	89 e5                	mov    %esp,%ebp
801069b0:	53                   	push   %ebx
801069b1:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
801069b4:	0f 20 d3             	mov    %cr2,%ebx
801069b7:	89 5d f8             	mov    %ebx,-0x8(%ebp)
  return val;
801069ba:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
801069bd:	83 c4 10             	add    $0x10,%esp
801069c0:	5b                   	pop    %ebx
801069c1:	5d                   	pop    %ebp
801069c2:	c3                   	ret    

801069c3 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
801069c3:	55                   	push   %ebp
801069c4:	89 e5                	mov    %esp,%ebp
801069c6:	83 ec 28             	sub    $0x28,%esp
  int i;

  for(i = 0; i < 256; i++)
801069c9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801069d0:	e9 c3 00 00 00       	jmp    80106a98 <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801069d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069d8:	8b 04 85 9c b0 10 80 	mov    -0x7fef4f64(,%eax,4),%eax
801069df:	89 c2                	mov    %eax,%edx
801069e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069e4:	66 89 14 c5 00 2e 11 	mov    %dx,-0x7feed200(,%eax,8)
801069eb:	80 
801069ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069ef:	66 c7 04 c5 02 2e 11 	movw   $0x8,-0x7feed1fe(,%eax,8)
801069f6:	80 08 00 
801069f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801069fc:	0f b6 14 c5 04 2e 11 	movzbl -0x7feed1fc(,%eax,8),%edx
80106a03:	80 
80106a04:	83 e2 e0             	and    $0xffffffe0,%edx
80106a07:	88 14 c5 04 2e 11 80 	mov    %dl,-0x7feed1fc(,%eax,8)
80106a0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a11:	0f b6 14 c5 04 2e 11 	movzbl -0x7feed1fc(,%eax,8),%edx
80106a18:	80 
80106a19:	83 e2 1f             	and    $0x1f,%edx
80106a1c:	88 14 c5 04 2e 11 80 	mov    %dl,-0x7feed1fc(,%eax,8)
80106a23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a26:	0f b6 14 c5 05 2e 11 	movzbl -0x7feed1fb(,%eax,8),%edx
80106a2d:	80 
80106a2e:	83 e2 f0             	and    $0xfffffff0,%edx
80106a31:	83 ca 0e             	or     $0xe,%edx
80106a34:	88 14 c5 05 2e 11 80 	mov    %dl,-0x7feed1fb(,%eax,8)
80106a3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a3e:	0f b6 14 c5 05 2e 11 	movzbl -0x7feed1fb(,%eax,8),%edx
80106a45:	80 
80106a46:	83 e2 ef             	and    $0xffffffef,%edx
80106a49:	88 14 c5 05 2e 11 80 	mov    %dl,-0x7feed1fb(,%eax,8)
80106a50:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a53:	0f b6 14 c5 05 2e 11 	movzbl -0x7feed1fb(,%eax,8),%edx
80106a5a:	80 
80106a5b:	83 e2 9f             	and    $0xffffff9f,%edx
80106a5e:	88 14 c5 05 2e 11 80 	mov    %dl,-0x7feed1fb(,%eax,8)
80106a65:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a68:	0f b6 14 c5 05 2e 11 	movzbl -0x7feed1fb(,%eax,8),%edx
80106a6f:	80 
80106a70:	83 ca 80             	or     $0xffffff80,%edx
80106a73:	88 14 c5 05 2e 11 80 	mov    %dl,-0x7feed1fb(,%eax,8)
80106a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a7d:	8b 04 85 9c b0 10 80 	mov    -0x7fef4f64(,%eax,4),%eax
80106a84:	c1 e8 10             	shr    $0x10,%eax
80106a87:	89 c2                	mov    %eax,%edx
80106a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106a8c:	66 89 14 c5 06 2e 11 	mov    %dx,-0x7feed1fa(,%eax,8)
80106a93:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106a94:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106a98:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106a9f:	0f 8e 30 ff ff ff    	jle    801069d5 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106aa5:	a1 9c b1 10 80       	mov    0x8010b19c,%eax
80106aaa:	66 a3 00 30 11 80    	mov    %ax,0x80113000
80106ab0:	66 c7 05 02 30 11 80 	movw   $0x8,0x80113002
80106ab7:	08 00 
80106ab9:	0f b6 05 04 30 11 80 	movzbl 0x80113004,%eax
80106ac0:	83 e0 e0             	and    $0xffffffe0,%eax
80106ac3:	a2 04 30 11 80       	mov    %al,0x80113004
80106ac8:	0f b6 05 04 30 11 80 	movzbl 0x80113004,%eax
80106acf:	83 e0 1f             	and    $0x1f,%eax
80106ad2:	a2 04 30 11 80       	mov    %al,0x80113004
80106ad7:	0f b6 05 05 30 11 80 	movzbl 0x80113005,%eax
80106ade:	83 c8 0f             	or     $0xf,%eax
80106ae1:	a2 05 30 11 80       	mov    %al,0x80113005
80106ae6:	0f b6 05 05 30 11 80 	movzbl 0x80113005,%eax
80106aed:	83 e0 ef             	and    $0xffffffef,%eax
80106af0:	a2 05 30 11 80       	mov    %al,0x80113005
80106af5:	0f b6 05 05 30 11 80 	movzbl 0x80113005,%eax
80106afc:	83 c8 60             	or     $0x60,%eax
80106aff:	a2 05 30 11 80       	mov    %al,0x80113005
80106b04:	0f b6 05 05 30 11 80 	movzbl 0x80113005,%eax
80106b0b:	83 c8 80             	or     $0xffffff80,%eax
80106b0e:	a2 05 30 11 80       	mov    %al,0x80113005
80106b13:	a1 9c b1 10 80       	mov    0x8010b19c,%eax
80106b18:	c1 e8 10             	shr    $0x10,%eax
80106b1b:	66 a3 06 30 11 80    	mov    %ax,0x80113006
  
  initlock(&tickslock, "time");
80106b21:	c7 44 24 04 74 8d 10 	movl   $0x80108d74,0x4(%esp)
80106b28:	80 
80106b29:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
80106b30:	e8 c5 e6 ff ff       	call   801051fa <initlock>
}
80106b35:	c9                   	leave  
80106b36:	c3                   	ret    

80106b37 <idtinit>:

void
idtinit(void)
{
80106b37:	55                   	push   %ebp
80106b38:	89 e5                	mov    %esp,%ebp
80106b3a:	83 ec 08             	sub    $0x8,%esp
  lidt(idt, sizeof(idt));
80106b3d:	c7 44 24 04 00 08 00 	movl   $0x800,0x4(%esp)
80106b44:	00 
80106b45:	c7 04 24 00 2e 11 80 	movl   $0x80112e00,(%esp)
80106b4c:	e8 33 fe ff ff       	call   80106984 <lidt>
}
80106b51:	c9                   	leave  
80106b52:	c3                   	ret    

80106b53 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106b53:	55                   	push   %ebp
80106b54:	89 e5                	mov    %esp,%ebp
80106b56:	57                   	push   %edi
80106b57:	56                   	push   %esi
80106b58:	53                   	push   %ebx
80106b59:	83 ec 3c             	sub    $0x3c,%esp
  if(tf->trapno == T_SYSCALL){
80106b5c:	8b 45 08             	mov    0x8(%ebp),%eax
80106b5f:	8b 40 30             	mov    0x30(%eax),%eax
80106b62:	83 f8 40             	cmp    $0x40,%eax
80106b65:	75 3e                	jne    80106ba5 <trap+0x52>
    if(proc->killed)
80106b67:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b6d:	8b 40 24             	mov    0x24(%eax),%eax
80106b70:	85 c0                	test   %eax,%eax
80106b72:	74 05                	je     80106b79 <trap+0x26>
      exit();
80106b74:	e8 54 df ff ff       	call   80104acd <exit>
    proc->tf = tf;
80106b79:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b7f:	8b 55 08             	mov    0x8(%ebp),%edx
80106b82:	89 50 18             	mov    %edx,0x18(%eax)
    syscall();
80106b85:	e8 0d ed ff ff       	call   80105897 <syscall>
    if(proc->killed)
80106b8a:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106b90:	8b 40 24             	mov    0x24(%eax),%eax
80106b93:	85 c0                	test   %eax,%eax
80106b95:	0f 84 34 02 00 00    	je     80106dcf <trap+0x27c>
      exit();
80106b9b:	e8 2d df ff ff       	call   80104acd <exit>
    return;
80106ba0:	e9 2a 02 00 00       	jmp    80106dcf <trap+0x27c>
  }

  switch(tf->trapno){
80106ba5:	8b 45 08             	mov    0x8(%ebp),%eax
80106ba8:	8b 40 30             	mov    0x30(%eax),%eax
80106bab:	83 e8 20             	sub    $0x20,%eax
80106bae:	83 f8 1f             	cmp    $0x1f,%eax
80106bb1:	0f 87 bc 00 00 00    	ja     80106c73 <trap+0x120>
80106bb7:	8b 04 85 1c 8e 10 80 	mov    -0x7fef71e4(,%eax,4),%eax
80106bbe:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpu->id == 0){
80106bc0:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106bc6:	0f b6 00             	movzbl (%eax),%eax
80106bc9:	84 c0                	test   %al,%al
80106bcb:	75 31                	jne    80106bfe <trap+0xab>
      acquire(&tickslock);
80106bcd:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
80106bd4:	e8 42 e6 ff ff       	call   8010521b <acquire>
      ticks++;
80106bd9:	a1 00 36 11 80       	mov    0x80113600,%eax
80106bde:	83 c0 01             	add    $0x1,%eax
80106be1:	a3 00 36 11 80       	mov    %eax,0x80113600
      wakeup(&ticks);
80106be6:	c7 04 24 00 36 11 80 	movl   $0x80113600,(%esp)
80106bed:	e8 24 e4 ff ff       	call   80105016 <wakeup>
      release(&tickslock);
80106bf2:	c7 04 24 c0 2d 11 80 	movl   $0x80112dc0,(%esp)
80106bf9:	e8 7f e6 ff ff       	call   8010527d <release>
    }
    lapiceoi();
80106bfe:	e8 5e c9 ff ff       	call   80103561 <lapiceoi>
    break;
80106c03:	e9 41 01 00 00       	jmp    80106d49 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
80106c08:	e8 5c c1 ff ff       	call   80102d69 <ideintr>
    lapiceoi();
80106c0d:	e8 4f c9 ff ff       	call   80103561 <lapiceoi>
    break;
80106c12:	e9 32 01 00 00       	jmp    80106d49 <trap+0x1f6>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
80106c17:	e8 23 c7 ff ff       	call   8010333f <kbdintr>
    lapiceoi();
80106c1c:	e8 40 c9 ff ff       	call   80103561 <lapiceoi>
    break;
80106c21:	e9 23 01 00 00       	jmp    80106d49 <trap+0x1f6>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
80106c26:	e8 a9 03 00 00       	call   80106fd4 <uartintr>
    lapiceoi();
80106c2b:	e8 31 c9 ff ff       	call   80103561 <lapiceoi>
    break;
80106c30:	e9 14 01 00 00       	jmp    80106d49 <trap+0x1f6>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
            cpu->id, tf->cs, tf->eip);
80106c35:	8b 45 08             	mov    0x8(%ebp),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106c38:	8b 48 38             	mov    0x38(%eax),%ecx
            cpu->id, tf->cs, tf->eip);
80106c3b:	8b 45 08             	mov    0x8(%ebp),%eax
80106c3e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106c42:	0f b7 d0             	movzwl %ax,%edx
            cpu->id, tf->cs, tf->eip);
80106c45:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106c4b:	0f b6 00             	movzbl (%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106c4e:	0f b6 c0             	movzbl %al,%eax
80106c51:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106c55:	89 54 24 08          	mov    %edx,0x8(%esp)
80106c59:	89 44 24 04          	mov    %eax,0x4(%esp)
80106c5d:	c7 04 24 7c 8d 10 80 	movl   $0x80108d7c,(%esp)
80106c64:	e8 38 97 ff ff       	call   801003a1 <cprintf>
            cpu->id, tf->cs, tf->eip);
    lapiceoi();
80106c69:	e8 f3 c8 ff ff       	call   80103561 <lapiceoi>
    break;
80106c6e:	e9 d6 00 00 00       	jmp    80106d49 <trap+0x1f6>
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
80106c73:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106c79:	85 c0                	test   %eax,%eax
80106c7b:	74 11                	je     80106c8e <trap+0x13b>
80106c7d:	8b 45 08             	mov    0x8(%ebp),%eax
80106c80:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106c84:	0f b7 c0             	movzwl %ax,%eax
80106c87:	83 e0 03             	and    $0x3,%eax
80106c8a:	85 c0                	test   %eax,%eax
80106c8c:	75 46                	jne    80106cd4 <trap+0x181>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c8e:	e8 1a fd ff ff       	call   801069ad <rcr2>
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c93:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106c96:	8b 5a 38             	mov    0x38(%edx),%ebx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106c99:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
80106ca0:	0f b6 12             	movzbl (%edx),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106ca3:	0f b6 ca             	movzbl %dl,%ecx
              tf->trapno, cpu->id, tf->eip, rcr2());
80106ca6:	8b 55 08             	mov    0x8(%ebp),%edx
   
  //PAGEBREAK: 13
  default:
    if(proc == 0 || (tf->cs&3) == 0){
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
80106ca9:	8b 52 30             	mov    0x30(%edx),%edx
80106cac:	89 44 24 10          	mov    %eax,0x10(%esp)
80106cb0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
80106cb4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
80106cb8:	89 54 24 04          	mov    %edx,0x4(%esp)
80106cbc:	c7 04 24 a0 8d 10 80 	movl   $0x80108da0,(%esp)
80106cc3:	e8 d9 96 ff ff       	call   801003a1 <cprintf>
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
80106cc8:	c7 04 24 d2 8d 10 80 	movl   $0x80108dd2,(%esp)
80106ccf:	e8 69 98 ff ff       	call   8010053d <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106cd4:	e8 d4 fc ff ff       	call   801069ad <rcr2>
80106cd9:	89 c2                	mov    %eax,%edx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106cdb:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106cde:	8b 78 38             	mov    0x38(%eax),%edi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106ce1:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80106ce7:	0f b6 00             	movzbl (%eax),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106cea:	0f b6 f0             	movzbl %al,%esi
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106ced:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106cf0:	8b 58 34             	mov    0x34(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106cf3:	8b 45 08             	mov    0x8(%ebp),%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106cf6:	8b 48 30             	mov    0x30(%eax),%ecx
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
80106cf9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106cff:	83 c0 6c             	add    $0x6c,%eax
80106d02:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80106d05:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpu->id, tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106d0b:	8b 40 10             	mov    0x10(%eax),%eax
80106d0e:	89 54 24 1c          	mov    %edx,0x1c(%esp)
80106d12:	89 7c 24 18          	mov    %edi,0x18(%esp)
80106d16:	89 74 24 14          	mov    %esi,0x14(%esp)
80106d1a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
80106d1e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
80106d22:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80106d25:	89 54 24 08          	mov    %edx,0x8(%esp)
80106d29:	89 44 24 04          	mov    %eax,0x4(%esp)
80106d2d:	c7 04 24 d8 8d 10 80 	movl   $0x80108dd8,(%esp)
80106d34:	e8 68 96 ff ff       	call   801003a1 <cprintf>
            "eip 0x%x addr 0x%x--kill proc\n",
            proc->pid, proc->name, tf->trapno, tf->err, cpu->id, tf->eip, 
            rcr2());
    proc->killed = 1;
80106d39:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d3f:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106d46:	eb 01                	jmp    80106d49 <trap+0x1f6>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106d48:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running 
  // until it gets to the regular system call return.)
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106d49:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d4f:	85 c0                	test   %eax,%eax
80106d51:	74 24                	je     80106d77 <trap+0x224>
80106d53:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d59:	8b 40 24             	mov    0x24(%eax),%eax
80106d5c:	85 c0                	test   %eax,%eax
80106d5e:	74 17                	je     80106d77 <trap+0x224>
80106d60:	8b 45 08             	mov    0x8(%ebp),%eax
80106d63:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106d67:	0f b7 c0             	movzwl %ax,%eax
80106d6a:	83 e0 03             	and    $0x3,%eax
80106d6d:	83 f8 03             	cmp    $0x3,%eax
80106d70:	75 05                	jne    80106d77 <trap+0x224>
    exit();
80106d72:	e8 56 dd ff ff       	call   80104acd <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(proc && proc->state == RUNNING && tf->trapno == T_IRQ0+IRQ_TIMER)
80106d77:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d7d:	85 c0                	test   %eax,%eax
80106d7f:	74 1e                	je     80106d9f <trap+0x24c>
80106d81:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106d87:	8b 40 0c             	mov    0xc(%eax),%eax
80106d8a:	83 f8 04             	cmp    $0x4,%eax
80106d8d:	75 10                	jne    80106d9f <trap+0x24c>
80106d8f:	8b 45 08             	mov    0x8(%ebp),%eax
80106d92:	8b 40 30             	mov    0x30(%eax),%eax
80106d95:	83 f8 20             	cmp    $0x20,%eax
80106d98:	75 05                	jne    80106d9f <trap+0x24c>
    yield();
80106d9a:	e8 40 e1 ff ff       	call   80104edf <yield>

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
80106d9f:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106da5:	85 c0                	test   %eax,%eax
80106da7:	74 27                	je     80106dd0 <trap+0x27d>
80106da9:	65 a1 04 00 00 00    	mov    %gs:0x4,%eax
80106daf:	8b 40 24             	mov    0x24(%eax),%eax
80106db2:	85 c0                	test   %eax,%eax
80106db4:	74 1a                	je     80106dd0 <trap+0x27d>
80106db6:	8b 45 08             	mov    0x8(%ebp),%eax
80106db9:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106dbd:	0f b7 c0             	movzwl %ax,%eax
80106dc0:	83 e0 03             	and    $0x3,%eax
80106dc3:	83 f8 03             	cmp    $0x3,%eax
80106dc6:	75 08                	jne    80106dd0 <trap+0x27d>
    exit();
80106dc8:	e8 00 dd ff ff       	call   80104acd <exit>
80106dcd:	eb 01                	jmp    80106dd0 <trap+0x27d>
      exit();
    proc->tf = tf;
    syscall();
    if(proc->killed)
      exit();
    return;
80106dcf:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(proc && proc->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106dd0:	83 c4 3c             	add    $0x3c,%esp
80106dd3:	5b                   	pop    %ebx
80106dd4:	5e                   	pop    %esi
80106dd5:	5f                   	pop    %edi
80106dd6:	5d                   	pop    %ebp
80106dd7:	c3                   	ret    

80106dd8 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106dd8:	55                   	push   %ebp
80106dd9:	89 e5                	mov    %esp,%ebp
80106ddb:	53                   	push   %ebx
80106ddc:	83 ec 14             	sub    $0x14,%esp
80106ddf:	8b 45 08             	mov    0x8(%ebp),%eax
80106de2:	66 89 45 e8          	mov    %ax,-0x18(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106de6:	0f b7 55 e8          	movzwl -0x18(%ebp),%edx
80106dea:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
80106dee:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
80106df2:	ec                   	in     (%dx),%al
80106df3:	89 c3                	mov    %eax,%ebx
80106df5:	88 5d fb             	mov    %bl,-0x5(%ebp)
  return data;
80106df8:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
80106dfc:	83 c4 14             	add    $0x14,%esp
80106dff:	5b                   	pop    %ebx
80106e00:	5d                   	pop    %ebp
80106e01:	c3                   	ret    

80106e02 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106e02:	55                   	push   %ebp
80106e03:	89 e5                	mov    %esp,%ebp
80106e05:	83 ec 08             	sub    $0x8,%esp
80106e08:	8b 55 08             	mov    0x8(%ebp),%edx
80106e0b:	8b 45 0c             	mov    0xc(%ebp),%eax
80106e0e:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106e12:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106e15:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106e19:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106e1d:	ee                   	out    %al,(%dx)
}
80106e1e:	c9                   	leave  
80106e1f:	c3                   	ret    

80106e20 <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106e20:	55                   	push   %ebp
80106e21:	89 e5                	mov    %esp,%ebp
80106e23:	83 ec 28             	sub    $0x28,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106e26:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e2d:	00 
80106e2e:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106e35:	e8 c8 ff ff ff       	call   80106e02 <outb>
  
  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106e3a:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
80106e41:	00 
80106e42:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106e49:	e8 b4 ff ff ff       	call   80106e02 <outb>
  outb(COM1+0, 115200/9600);
80106e4e:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
80106e55:	00 
80106e56:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106e5d:	e8 a0 ff ff ff       	call   80106e02 <outb>
  outb(COM1+1, 0);
80106e62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e69:	00 
80106e6a:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106e71:	e8 8c ff ff ff       	call   80106e02 <outb>
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106e76:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
80106e7d:	00 
80106e7e:	c7 04 24 fb 03 00 00 	movl   $0x3fb,(%esp)
80106e85:	e8 78 ff ff ff       	call   80106e02 <outb>
  outb(COM1+4, 0);
80106e8a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106e91:	00 
80106e92:	c7 04 24 fc 03 00 00 	movl   $0x3fc,(%esp)
80106e99:	e8 64 ff ff ff       	call   80106e02 <outb>
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106e9e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
80106ea5:	00 
80106ea6:	c7 04 24 f9 03 00 00 	movl   $0x3f9,(%esp)
80106ead:	e8 50 ff ff ff       	call   80106e02 <outb>

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106eb2:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106eb9:	e8 1a ff ff ff       	call   80106dd8 <inb>
80106ebe:	3c ff                	cmp    $0xff,%al
80106ec0:	74 6c                	je     80106f2e <uartinit+0x10e>
    return;
  uart = 1;
80106ec2:	c7 05 6c c0 10 80 01 	movl   $0x1,0x8010c06c
80106ec9:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106ecc:	c7 04 24 fa 03 00 00 	movl   $0x3fa,(%esp)
80106ed3:	e8 00 ff ff ff       	call   80106dd8 <inb>
  inb(COM1+0);
80106ed8:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106edf:	e8 f4 fe ff ff       	call   80106dd8 <inb>
  picenable(IRQ_COM1);
80106ee4:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106eeb:	e8 49 d2 ff ff       	call   80104139 <picenable>
  ioapicenable(IRQ_COM1, 0);
80106ef0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80106ef7:	00 
80106ef8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
80106eff:	e8 ea c0 ff ff       	call   80102fee <ioapicenable>
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106f04:	c7 45 f4 9c 8e 10 80 	movl   $0x80108e9c,-0xc(%ebp)
80106f0b:	eb 15                	jmp    80106f22 <uartinit+0x102>
    uartputc(*p);
80106f0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f10:	0f b6 00             	movzbl (%eax),%eax
80106f13:	0f be c0             	movsbl %al,%eax
80106f16:	89 04 24             	mov    %eax,(%esp)
80106f19:	e8 13 00 00 00       	call   80106f31 <uartputc>
  inb(COM1+0);
  picenable(IRQ_COM1);
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106f1e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f22:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106f25:	0f b6 00             	movzbl (%eax),%eax
80106f28:	84 c0                	test   %al,%al
80106f2a:	75 e1                	jne    80106f0d <uartinit+0xed>
80106f2c:	eb 01                	jmp    80106f2f <uartinit+0x10f>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106f2e:	90                   	nop
  ioapicenable(IRQ_COM1, 0);
  
  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106f2f:	c9                   	leave  
80106f30:	c3                   	ret    

80106f31 <uartputc>:

void
uartputc(int c)
{
80106f31:	55                   	push   %ebp
80106f32:	89 e5                	mov    %esp,%ebp
80106f34:	83 ec 28             	sub    $0x28,%esp
  int i;

  if(!uart)
80106f37:	a1 6c c0 10 80       	mov    0x8010c06c,%eax
80106f3c:	85 c0                	test   %eax,%eax
80106f3e:	74 4d                	je     80106f8d <uartputc+0x5c>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106f40:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106f47:	eb 10                	jmp    80106f59 <uartputc+0x28>
    microdelay(10);
80106f49:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
80106f50:	e8 31 c6 ff ff       	call   80103586 <microdelay>
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106f55:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106f59:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106f5d:	7f 16                	jg     80106f75 <uartputc+0x44>
80106f5f:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106f66:	e8 6d fe ff ff       	call   80106dd8 <inb>
80106f6b:	0f b6 c0             	movzbl %al,%eax
80106f6e:	83 e0 20             	and    $0x20,%eax
80106f71:	85 c0                	test   %eax,%eax
80106f73:	74 d4                	je     80106f49 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106f75:	8b 45 08             	mov    0x8(%ebp),%eax
80106f78:	0f b6 c0             	movzbl %al,%eax
80106f7b:	89 44 24 04          	mov    %eax,0x4(%esp)
80106f7f:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106f86:	e8 77 fe ff ff       	call   80106e02 <outb>
80106f8b:	eb 01                	jmp    80106f8e <uartputc+0x5d>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106f8d:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106f8e:	c9                   	leave  
80106f8f:	c3                   	ret    

80106f90 <uartgetc>:

static int
uartgetc(void)
{
80106f90:	55                   	push   %ebp
80106f91:	89 e5                	mov    %esp,%ebp
80106f93:	83 ec 04             	sub    $0x4,%esp
  if(!uart)
80106f96:	a1 6c c0 10 80       	mov    0x8010c06c,%eax
80106f9b:	85 c0                	test   %eax,%eax
80106f9d:	75 07                	jne    80106fa6 <uartgetc+0x16>
    return -1;
80106f9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fa4:	eb 2c                	jmp    80106fd2 <uartgetc+0x42>
  if(!(inb(COM1+5) & 0x01))
80106fa6:	c7 04 24 fd 03 00 00 	movl   $0x3fd,(%esp)
80106fad:	e8 26 fe ff ff       	call   80106dd8 <inb>
80106fb2:	0f b6 c0             	movzbl %al,%eax
80106fb5:	83 e0 01             	and    $0x1,%eax
80106fb8:	85 c0                	test   %eax,%eax
80106fba:	75 07                	jne    80106fc3 <uartgetc+0x33>
    return -1;
80106fbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106fc1:	eb 0f                	jmp    80106fd2 <uartgetc+0x42>
  return inb(COM1+0);
80106fc3:	c7 04 24 f8 03 00 00 	movl   $0x3f8,(%esp)
80106fca:	e8 09 fe ff ff       	call   80106dd8 <inb>
80106fcf:	0f b6 c0             	movzbl %al,%eax
}
80106fd2:	c9                   	leave  
80106fd3:	c3                   	ret    

80106fd4 <uartintr>:

void
uartintr(void)
{
80106fd4:	55                   	push   %ebp
80106fd5:	89 e5                	mov    %esp,%ebp
80106fd7:	83 ec 18             	sub    $0x18,%esp
  consoleintr(uartgetc);
80106fda:	c7 04 24 90 6f 10 80 	movl   $0x80106f90,(%esp)
80106fe1:	e8 ee 97 ff ff       	call   801007d4 <consoleintr>
}
80106fe6:	c9                   	leave  
80106fe7:	c3                   	ret    

80106fe8 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106fe8:	6a 00                	push   $0x0
  pushl $0
80106fea:	6a 00                	push   $0x0
  jmp alltraps
80106fec:	e9 67 f9 ff ff       	jmp    80106958 <alltraps>

80106ff1 <vector1>:
.globl vector1
vector1:
  pushl $0
80106ff1:	6a 00                	push   $0x0
  pushl $1
80106ff3:	6a 01                	push   $0x1
  jmp alltraps
80106ff5:	e9 5e f9 ff ff       	jmp    80106958 <alltraps>

80106ffa <vector2>:
.globl vector2
vector2:
  pushl $0
80106ffa:	6a 00                	push   $0x0
  pushl $2
80106ffc:	6a 02                	push   $0x2
  jmp alltraps
80106ffe:	e9 55 f9 ff ff       	jmp    80106958 <alltraps>

80107003 <vector3>:
.globl vector3
vector3:
  pushl $0
80107003:	6a 00                	push   $0x0
  pushl $3
80107005:	6a 03                	push   $0x3
  jmp alltraps
80107007:	e9 4c f9 ff ff       	jmp    80106958 <alltraps>

8010700c <vector4>:
.globl vector4
vector4:
  pushl $0
8010700c:	6a 00                	push   $0x0
  pushl $4
8010700e:	6a 04                	push   $0x4
  jmp alltraps
80107010:	e9 43 f9 ff ff       	jmp    80106958 <alltraps>

80107015 <vector5>:
.globl vector5
vector5:
  pushl $0
80107015:	6a 00                	push   $0x0
  pushl $5
80107017:	6a 05                	push   $0x5
  jmp alltraps
80107019:	e9 3a f9 ff ff       	jmp    80106958 <alltraps>

8010701e <vector6>:
.globl vector6
vector6:
  pushl $0
8010701e:	6a 00                	push   $0x0
  pushl $6
80107020:	6a 06                	push   $0x6
  jmp alltraps
80107022:	e9 31 f9 ff ff       	jmp    80106958 <alltraps>

80107027 <vector7>:
.globl vector7
vector7:
  pushl $0
80107027:	6a 00                	push   $0x0
  pushl $7
80107029:	6a 07                	push   $0x7
  jmp alltraps
8010702b:	e9 28 f9 ff ff       	jmp    80106958 <alltraps>

80107030 <vector8>:
.globl vector8
vector8:
  pushl $8
80107030:	6a 08                	push   $0x8
  jmp alltraps
80107032:	e9 21 f9 ff ff       	jmp    80106958 <alltraps>

80107037 <vector9>:
.globl vector9
vector9:
  pushl $0
80107037:	6a 00                	push   $0x0
  pushl $9
80107039:	6a 09                	push   $0x9
  jmp alltraps
8010703b:	e9 18 f9 ff ff       	jmp    80106958 <alltraps>

80107040 <vector10>:
.globl vector10
vector10:
  pushl $10
80107040:	6a 0a                	push   $0xa
  jmp alltraps
80107042:	e9 11 f9 ff ff       	jmp    80106958 <alltraps>

80107047 <vector11>:
.globl vector11
vector11:
  pushl $11
80107047:	6a 0b                	push   $0xb
  jmp alltraps
80107049:	e9 0a f9 ff ff       	jmp    80106958 <alltraps>

8010704e <vector12>:
.globl vector12
vector12:
  pushl $12
8010704e:	6a 0c                	push   $0xc
  jmp alltraps
80107050:	e9 03 f9 ff ff       	jmp    80106958 <alltraps>

80107055 <vector13>:
.globl vector13
vector13:
  pushl $13
80107055:	6a 0d                	push   $0xd
  jmp alltraps
80107057:	e9 fc f8 ff ff       	jmp    80106958 <alltraps>

8010705c <vector14>:
.globl vector14
vector14:
  pushl $14
8010705c:	6a 0e                	push   $0xe
  jmp alltraps
8010705e:	e9 f5 f8 ff ff       	jmp    80106958 <alltraps>

80107063 <vector15>:
.globl vector15
vector15:
  pushl $0
80107063:	6a 00                	push   $0x0
  pushl $15
80107065:	6a 0f                	push   $0xf
  jmp alltraps
80107067:	e9 ec f8 ff ff       	jmp    80106958 <alltraps>

8010706c <vector16>:
.globl vector16
vector16:
  pushl $0
8010706c:	6a 00                	push   $0x0
  pushl $16
8010706e:	6a 10                	push   $0x10
  jmp alltraps
80107070:	e9 e3 f8 ff ff       	jmp    80106958 <alltraps>

80107075 <vector17>:
.globl vector17
vector17:
  pushl $17
80107075:	6a 11                	push   $0x11
  jmp alltraps
80107077:	e9 dc f8 ff ff       	jmp    80106958 <alltraps>

8010707c <vector18>:
.globl vector18
vector18:
  pushl $0
8010707c:	6a 00                	push   $0x0
  pushl $18
8010707e:	6a 12                	push   $0x12
  jmp alltraps
80107080:	e9 d3 f8 ff ff       	jmp    80106958 <alltraps>

80107085 <vector19>:
.globl vector19
vector19:
  pushl $0
80107085:	6a 00                	push   $0x0
  pushl $19
80107087:	6a 13                	push   $0x13
  jmp alltraps
80107089:	e9 ca f8 ff ff       	jmp    80106958 <alltraps>

8010708e <vector20>:
.globl vector20
vector20:
  pushl $0
8010708e:	6a 00                	push   $0x0
  pushl $20
80107090:	6a 14                	push   $0x14
  jmp alltraps
80107092:	e9 c1 f8 ff ff       	jmp    80106958 <alltraps>

80107097 <vector21>:
.globl vector21
vector21:
  pushl $0
80107097:	6a 00                	push   $0x0
  pushl $21
80107099:	6a 15                	push   $0x15
  jmp alltraps
8010709b:	e9 b8 f8 ff ff       	jmp    80106958 <alltraps>

801070a0 <vector22>:
.globl vector22
vector22:
  pushl $0
801070a0:	6a 00                	push   $0x0
  pushl $22
801070a2:	6a 16                	push   $0x16
  jmp alltraps
801070a4:	e9 af f8 ff ff       	jmp    80106958 <alltraps>

801070a9 <vector23>:
.globl vector23
vector23:
  pushl $0
801070a9:	6a 00                	push   $0x0
  pushl $23
801070ab:	6a 17                	push   $0x17
  jmp alltraps
801070ad:	e9 a6 f8 ff ff       	jmp    80106958 <alltraps>

801070b2 <vector24>:
.globl vector24
vector24:
  pushl $0
801070b2:	6a 00                	push   $0x0
  pushl $24
801070b4:	6a 18                	push   $0x18
  jmp alltraps
801070b6:	e9 9d f8 ff ff       	jmp    80106958 <alltraps>

801070bb <vector25>:
.globl vector25
vector25:
  pushl $0
801070bb:	6a 00                	push   $0x0
  pushl $25
801070bd:	6a 19                	push   $0x19
  jmp alltraps
801070bf:	e9 94 f8 ff ff       	jmp    80106958 <alltraps>

801070c4 <vector26>:
.globl vector26
vector26:
  pushl $0
801070c4:	6a 00                	push   $0x0
  pushl $26
801070c6:	6a 1a                	push   $0x1a
  jmp alltraps
801070c8:	e9 8b f8 ff ff       	jmp    80106958 <alltraps>

801070cd <vector27>:
.globl vector27
vector27:
  pushl $0
801070cd:	6a 00                	push   $0x0
  pushl $27
801070cf:	6a 1b                	push   $0x1b
  jmp alltraps
801070d1:	e9 82 f8 ff ff       	jmp    80106958 <alltraps>

801070d6 <vector28>:
.globl vector28
vector28:
  pushl $0
801070d6:	6a 00                	push   $0x0
  pushl $28
801070d8:	6a 1c                	push   $0x1c
  jmp alltraps
801070da:	e9 79 f8 ff ff       	jmp    80106958 <alltraps>

801070df <vector29>:
.globl vector29
vector29:
  pushl $0
801070df:	6a 00                	push   $0x0
  pushl $29
801070e1:	6a 1d                	push   $0x1d
  jmp alltraps
801070e3:	e9 70 f8 ff ff       	jmp    80106958 <alltraps>

801070e8 <vector30>:
.globl vector30
vector30:
  pushl $0
801070e8:	6a 00                	push   $0x0
  pushl $30
801070ea:	6a 1e                	push   $0x1e
  jmp alltraps
801070ec:	e9 67 f8 ff ff       	jmp    80106958 <alltraps>

801070f1 <vector31>:
.globl vector31
vector31:
  pushl $0
801070f1:	6a 00                	push   $0x0
  pushl $31
801070f3:	6a 1f                	push   $0x1f
  jmp alltraps
801070f5:	e9 5e f8 ff ff       	jmp    80106958 <alltraps>

801070fa <vector32>:
.globl vector32
vector32:
  pushl $0
801070fa:	6a 00                	push   $0x0
  pushl $32
801070fc:	6a 20                	push   $0x20
  jmp alltraps
801070fe:	e9 55 f8 ff ff       	jmp    80106958 <alltraps>

80107103 <vector33>:
.globl vector33
vector33:
  pushl $0
80107103:	6a 00                	push   $0x0
  pushl $33
80107105:	6a 21                	push   $0x21
  jmp alltraps
80107107:	e9 4c f8 ff ff       	jmp    80106958 <alltraps>

8010710c <vector34>:
.globl vector34
vector34:
  pushl $0
8010710c:	6a 00                	push   $0x0
  pushl $34
8010710e:	6a 22                	push   $0x22
  jmp alltraps
80107110:	e9 43 f8 ff ff       	jmp    80106958 <alltraps>

80107115 <vector35>:
.globl vector35
vector35:
  pushl $0
80107115:	6a 00                	push   $0x0
  pushl $35
80107117:	6a 23                	push   $0x23
  jmp alltraps
80107119:	e9 3a f8 ff ff       	jmp    80106958 <alltraps>

8010711e <vector36>:
.globl vector36
vector36:
  pushl $0
8010711e:	6a 00                	push   $0x0
  pushl $36
80107120:	6a 24                	push   $0x24
  jmp alltraps
80107122:	e9 31 f8 ff ff       	jmp    80106958 <alltraps>

80107127 <vector37>:
.globl vector37
vector37:
  pushl $0
80107127:	6a 00                	push   $0x0
  pushl $37
80107129:	6a 25                	push   $0x25
  jmp alltraps
8010712b:	e9 28 f8 ff ff       	jmp    80106958 <alltraps>

80107130 <vector38>:
.globl vector38
vector38:
  pushl $0
80107130:	6a 00                	push   $0x0
  pushl $38
80107132:	6a 26                	push   $0x26
  jmp alltraps
80107134:	e9 1f f8 ff ff       	jmp    80106958 <alltraps>

80107139 <vector39>:
.globl vector39
vector39:
  pushl $0
80107139:	6a 00                	push   $0x0
  pushl $39
8010713b:	6a 27                	push   $0x27
  jmp alltraps
8010713d:	e9 16 f8 ff ff       	jmp    80106958 <alltraps>

80107142 <vector40>:
.globl vector40
vector40:
  pushl $0
80107142:	6a 00                	push   $0x0
  pushl $40
80107144:	6a 28                	push   $0x28
  jmp alltraps
80107146:	e9 0d f8 ff ff       	jmp    80106958 <alltraps>

8010714b <vector41>:
.globl vector41
vector41:
  pushl $0
8010714b:	6a 00                	push   $0x0
  pushl $41
8010714d:	6a 29                	push   $0x29
  jmp alltraps
8010714f:	e9 04 f8 ff ff       	jmp    80106958 <alltraps>

80107154 <vector42>:
.globl vector42
vector42:
  pushl $0
80107154:	6a 00                	push   $0x0
  pushl $42
80107156:	6a 2a                	push   $0x2a
  jmp alltraps
80107158:	e9 fb f7 ff ff       	jmp    80106958 <alltraps>

8010715d <vector43>:
.globl vector43
vector43:
  pushl $0
8010715d:	6a 00                	push   $0x0
  pushl $43
8010715f:	6a 2b                	push   $0x2b
  jmp alltraps
80107161:	e9 f2 f7 ff ff       	jmp    80106958 <alltraps>

80107166 <vector44>:
.globl vector44
vector44:
  pushl $0
80107166:	6a 00                	push   $0x0
  pushl $44
80107168:	6a 2c                	push   $0x2c
  jmp alltraps
8010716a:	e9 e9 f7 ff ff       	jmp    80106958 <alltraps>

8010716f <vector45>:
.globl vector45
vector45:
  pushl $0
8010716f:	6a 00                	push   $0x0
  pushl $45
80107171:	6a 2d                	push   $0x2d
  jmp alltraps
80107173:	e9 e0 f7 ff ff       	jmp    80106958 <alltraps>

80107178 <vector46>:
.globl vector46
vector46:
  pushl $0
80107178:	6a 00                	push   $0x0
  pushl $46
8010717a:	6a 2e                	push   $0x2e
  jmp alltraps
8010717c:	e9 d7 f7 ff ff       	jmp    80106958 <alltraps>

80107181 <vector47>:
.globl vector47
vector47:
  pushl $0
80107181:	6a 00                	push   $0x0
  pushl $47
80107183:	6a 2f                	push   $0x2f
  jmp alltraps
80107185:	e9 ce f7 ff ff       	jmp    80106958 <alltraps>

8010718a <vector48>:
.globl vector48
vector48:
  pushl $0
8010718a:	6a 00                	push   $0x0
  pushl $48
8010718c:	6a 30                	push   $0x30
  jmp alltraps
8010718e:	e9 c5 f7 ff ff       	jmp    80106958 <alltraps>

80107193 <vector49>:
.globl vector49
vector49:
  pushl $0
80107193:	6a 00                	push   $0x0
  pushl $49
80107195:	6a 31                	push   $0x31
  jmp alltraps
80107197:	e9 bc f7 ff ff       	jmp    80106958 <alltraps>

8010719c <vector50>:
.globl vector50
vector50:
  pushl $0
8010719c:	6a 00                	push   $0x0
  pushl $50
8010719e:	6a 32                	push   $0x32
  jmp alltraps
801071a0:	e9 b3 f7 ff ff       	jmp    80106958 <alltraps>

801071a5 <vector51>:
.globl vector51
vector51:
  pushl $0
801071a5:	6a 00                	push   $0x0
  pushl $51
801071a7:	6a 33                	push   $0x33
  jmp alltraps
801071a9:	e9 aa f7 ff ff       	jmp    80106958 <alltraps>

801071ae <vector52>:
.globl vector52
vector52:
  pushl $0
801071ae:	6a 00                	push   $0x0
  pushl $52
801071b0:	6a 34                	push   $0x34
  jmp alltraps
801071b2:	e9 a1 f7 ff ff       	jmp    80106958 <alltraps>

801071b7 <vector53>:
.globl vector53
vector53:
  pushl $0
801071b7:	6a 00                	push   $0x0
  pushl $53
801071b9:	6a 35                	push   $0x35
  jmp alltraps
801071bb:	e9 98 f7 ff ff       	jmp    80106958 <alltraps>

801071c0 <vector54>:
.globl vector54
vector54:
  pushl $0
801071c0:	6a 00                	push   $0x0
  pushl $54
801071c2:	6a 36                	push   $0x36
  jmp alltraps
801071c4:	e9 8f f7 ff ff       	jmp    80106958 <alltraps>

801071c9 <vector55>:
.globl vector55
vector55:
  pushl $0
801071c9:	6a 00                	push   $0x0
  pushl $55
801071cb:	6a 37                	push   $0x37
  jmp alltraps
801071cd:	e9 86 f7 ff ff       	jmp    80106958 <alltraps>

801071d2 <vector56>:
.globl vector56
vector56:
  pushl $0
801071d2:	6a 00                	push   $0x0
  pushl $56
801071d4:	6a 38                	push   $0x38
  jmp alltraps
801071d6:	e9 7d f7 ff ff       	jmp    80106958 <alltraps>

801071db <vector57>:
.globl vector57
vector57:
  pushl $0
801071db:	6a 00                	push   $0x0
  pushl $57
801071dd:	6a 39                	push   $0x39
  jmp alltraps
801071df:	e9 74 f7 ff ff       	jmp    80106958 <alltraps>

801071e4 <vector58>:
.globl vector58
vector58:
  pushl $0
801071e4:	6a 00                	push   $0x0
  pushl $58
801071e6:	6a 3a                	push   $0x3a
  jmp alltraps
801071e8:	e9 6b f7 ff ff       	jmp    80106958 <alltraps>

801071ed <vector59>:
.globl vector59
vector59:
  pushl $0
801071ed:	6a 00                	push   $0x0
  pushl $59
801071ef:	6a 3b                	push   $0x3b
  jmp alltraps
801071f1:	e9 62 f7 ff ff       	jmp    80106958 <alltraps>

801071f6 <vector60>:
.globl vector60
vector60:
  pushl $0
801071f6:	6a 00                	push   $0x0
  pushl $60
801071f8:	6a 3c                	push   $0x3c
  jmp alltraps
801071fa:	e9 59 f7 ff ff       	jmp    80106958 <alltraps>

801071ff <vector61>:
.globl vector61
vector61:
  pushl $0
801071ff:	6a 00                	push   $0x0
  pushl $61
80107201:	6a 3d                	push   $0x3d
  jmp alltraps
80107203:	e9 50 f7 ff ff       	jmp    80106958 <alltraps>

80107208 <vector62>:
.globl vector62
vector62:
  pushl $0
80107208:	6a 00                	push   $0x0
  pushl $62
8010720a:	6a 3e                	push   $0x3e
  jmp alltraps
8010720c:	e9 47 f7 ff ff       	jmp    80106958 <alltraps>

80107211 <vector63>:
.globl vector63
vector63:
  pushl $0
80107211:	6a 00                	push   $0x0
  pushl $63
80107213:	6a 3f                	push   $0x3f
  jmp alltraps
80107215:	e9 3e f7 ff ff       	jmp    80106958 <alltraps>

8010721a <vector64>:
.globl vector64
vector64:
  pushl $0
8010721a:	6a 00                	push   $0x0
  pushl $64
8010721c:	6a 40                	push   $0x40
  jmp alltraps
8010721e:	e9 35 f7 ff ff       	jmp    80106958 <alltraps>

80107223 <vector65>:
.globl vector65
vector65:
  pushl $0
80107223:	6a 00                	push   $0x0
  pushl $65
80107225:	6a 41                	push   $0x41
  jmp alltraps
80107227:	e9 2c f7 ff ff       	jmp    80106958 <alltraps>

8010722c <vector66>:
.globl vector66
vector66:
  pushl $0
8010722c:	6a 00                	push   $0x0
  pushl $66
8010722e:	6a 42                	push   $0x42
  jmp alltraps
80107230:	e9 23 f7 ff ff       	jmp    80106958 <alltraps>

80107235 <vector67>:
.globl vector67
vector67:
  pushl $0
80107235:	6a 00                	push   $0x0
  pushl $67
80107237:	6a 43                	push   $0x43
  jmp alltraps
80107239:	e9 1a f7 ff ff       	jmp    80106958 <alltraps>

8010723e <vector68>:
.globl vector68
vector68:
  pushl $0
8010723e:	6a 00                	push   $0x0
  pushl $68
80107240:	6a 44                	push   $0x44
  jmp alltraps
80107242:	e9 11 f7 ff ff       	jmp    80106958 <alltraps>

80107247 <vector69>:
.globl vector69
vector69:
  pushl $0
80107247:	6a 00                	push   $0x0
  pushl $69
80107249:	6a 45                	push   $0x45
  jmp alltraps
8010724b:	e9 08 f7 ff ff       	jmp    80106958 <alltraps>

80107250 <vector70>:
.globl vector70
vector70:
  pushl $0
80107250:	6a 00                	push   $0x0
  pushl $70
80107252:	6a 46                	push   $0x46
  jmp alltraps
80107254:	e9 ff f6 ff ff       	jmp    80106958 <alltraps>

80107259 <vector71>:
.globl vector71
vector71:
  pushl $0
80107259:	6a 00                	push   $0x0
  pushl $71
8010725b:	6a 47                	push   $0x47
  jmp alltraps
8010725d:	e9 f6 f6 ff ff       	jmp    80106958 <alltraps>

80107262 <vector72>:
.globl vector72
vector72:
  pushl $0
80107262:	6a 00                	push   $0x0
  pushl $72
80107264:	6a 48                	push   $0x48
  jmp alltraps
80107266:	e9 ed f6 ff ff       	jmp    80106958 <alltraps>

8010726b <vector73>:
.globl vector73
vector73:
  pushl $0
8010726b:	6a 00                	push   $0x0
  pushl $73
8010726d:	6a 49                	push   $0x49
  jmp alltraps
8010726f:	e9 e4 f6 ff ff       	jmp    80106958 <alltraps>

80107274 <vector74>:
.globl vector74
vector74:
  pushl $0
80107274:	6a 00                	push   $0x0
  pushl $74
80107276:	6a 4a                	push   $0x4a
  jmp alltraps
80107278:	e9 db f6 ff ff       	jmp    80106958 <alltraps>

8010727d <vector75>:
.globl vector75
vector75:
  pushl $0
8010727d:	6a 00                	push   $0x0
  pushl $75
8010727f:	6a 4b                	push   $0x4b
  jmp alltraps
80107281:	e9 d2 f6 ff ff       	jmp    80106958 <alltraps>

80107286 <vector76>:
.globl vector76
vector76:
  pushl $0
80107286:	6a 00                	push   $0x0
  pushl $76
80107288:	6a 4c                	push   $0x4c
  jmp alltraps
8010728a:	e9 c9 f6 ff ff       	jmp    80106958 <alltraps>

8010728f <vector77>:
.globl vector77
vector77:
  pushl $0
8010728f:	6a 00                	push   $0x0
  pushl $77
80107291:	6a 4d                	push   $0x4d
  jmp alltraps
80107293:	e9 c0 f6 ff ff       	jmp    80106958 <alltraps>

80107298 <vector78>:
.globl vector78
vector78:
  pushl $0
80107298:	6a 00                	push   $0x0
  pushl $78
8010729a:	6a 4e                	push   $0x4e
  jmp alltraps
8010729c:	e9 b7 f6 ff ff       	jmp    80106958 <alltraps>

801072a1 <vector79>:
.globl vector79
vector79:
  pushl $0
801072a1:	6a 00                	push   $0x0
  pushl $79
801072a3:	6a 4f                	push   $0x4f
  jmp alltraps
801072a5:	e9 ae f6 ff ff       	jmp    80106958 <alltraps>

801072aa <vector80>:
.globl vector80
vector80:
  pushl $0
801072aa:	6a 00                	push   $0x0
  pushl $80
801072ac:	6a 50                	push   $0x50
  jmp alltraps
801072ae:	e9 a5 f6 ff ff       	jmp    80106958 <alltraps>

801072b3 <vector81>:
.globl vector81
vector81:
  pushl $0
801072b3:	6a 00                	push   $0x0
  pushl $81
801072b5:	6a 51                	push   $0x51
  jmp alltraps
801072b7:	e9 9c f6 ff ff       	jmp    80106958 <alltraps>

801072bc <vector82>:
.globl vector82
vector82:
  pushl $0
801072bc:	6a 00                	push   $0x0
  pushl $82
801072be:	6a 52                	push   $0x52
  jmp alltraps
801072c0:	e9 93 f6 ff ff       	jmp    80106958 <alltraps>

801072c5 <vector83>:
.globl vector83
vector83:
  pushl $0
801072c5:	6a 00                	push   $0x0
  pushl $83
801072c7:	6a 53                	push   $0x53
  jmp alltraps
801072c9:	e9 8a f6 ff ff       	jmp    80106958 <alltraps>

801072ce <vector84>:
.globl vector84
vector84:
  pushl $0
801072ce:	6a 00                	push   $0x0
  pushl $84
801072d0:	6a 54                	push   $0x54
  jmp alltraps
801072d2:	e9 81 f6 ff ff       	jmp    80106958 <alltraps>

801072d7 <vector85>:
.globl vector85
vector85:
  pushl $0
801072d7:	6a 00                	push   $0x0
  pushl $85
801072d9:	6a 55                	push   $0x55
  jmp alltraps
801072db:	e9 78 f6 ff ff       	jmp    80106958 <alltraps>

801072e0 <vector86>:
.globl vector86
vector86:
  pushl $0
801072e0:	6a 00                	push   $0x0
  pushl $86
801072e2:	6a 56                	push   $0x56
  jmp alltraps
801072e4:	e9 6f f6 ff ff       	jmp    80106958 <alltraps>

801072e9 <vector87>:
.globl vector87
vector87:
  pushl $0
801072e9:	6a 00                	push   $0x0
  pushl $87
801072eb:	6a 57                	push   $0x57
  jmp alltraps
801072ed:	e9 66 f6 ff ff       	jmp    80106958 <alltraps>

801072f2 <vector88>:
.globl vector88
vector88:
  pushl $0
801072f2:	6a 00                	push   $0x0
  pushl $88
801072f4:	6a 58                	push   $0x58
  jmp alltraps
801072f6:	e9 5d f6 ff ff       	jmp    80106958 <alltraps>

801072fb <vector89>:
.globl vector89
vector89:
  pushl $0
801072fb:	6a 00                	push   $0x0
  pushl $89
801072fd:	6a 59                	push   $0x59
  jmp alltraps
801072ff:	e9 54 f6 ff ff       	jmp    80106958 <alltraps>

80107304 <vector90>:
.globl vector90
vector90:
  pushl $0
80107304:	6a 00                	push   $0x0
  pushl $90
80107306:	6a 5a                	push   $0x5a
  jmp alltraps
80107308:	e9 4b f6 ff ff       	jmp    80106958 <alltraps>

8010730d <vector91>:
.globl vector91
vector91:
  pushl $0
8010730d:	6a 00                	push   $0x0
  pushl $91
8010730f:	6a 5b                	push   $0x5b
  jmp alltraps
80107311:	e9 42 f6 ff ff       	jmp    80106958 <alltraps>

80107316 <vector92>:
.globl vector92
vector92:
  pushl $0
80107316:	6a 00                	push   $0x0
  pushl $92
80107318:	6a 5c                	push   $0x5c
  jmp alltraps
8010731a:	e9 39 f6 ff ff       	jmp    80106958 <alltraps>

8010731f <vector93>:
.globl vector93
vector93:
  pushl $0
8010731f:	6a 00                	push   $0x0
  pushl $93
80107321:	6a 5d                	push   $0x5d
  jmp alltraps
80107323:	e9 30 f6 ff ff       	jmp    80106958 <alltraps>

80107328 <vector94>:
.globl vector94
vector94:
  pushl $0
80107328:	6a 00                	push   $0x0
  pushl $94
8010732a:	6a 5e                	push   $0x5e
  jmp alltraps
8010732c:	e9 27 f6 ff ff       	jmp    80106958 <alltraps>

80107331 <vector95>:
.globl vector95
vector95:
  pushl $0
80107331:	6a 00                	push   $0x0
  pushl $95
80107333:	6a 5f                	push   $0x5f
  jmp alltraps
80107335:	e9 1e f6 ff ff       	jmp    80106958 <alltraps>

8010733a <vector96>:
.globl vector96
vector96:
  pushl $0
8010733a:	6a 00                	push   $0x0
  pushl $96
8010733c:	6a 60                	push   $0x60
  jmp alltraps
8010733e:	e9 15 f6 ff ff       	jmp    80106958 <alltraps>

80107343 <vector97>:
.globl vector97
vector97:
  pushl $0
80107343:	6a 00                	push   $0x0
  pushl $97
80107345:	6a 61                	push   $0x61
  jmp alltraps
80107347:	e9 0c f6 ff ff       	jmp    80106958 <alltraps>

8010734c <vector98>:
.globl vector98
vector98:
  pushl $0
8010734c:	6a 00                	push   $0x0
  pushl $98
8010734e:	6a 62                	push   $0x62
  jmp alltraps
80107350:	e9 03 f6 ff ff       	jmp    80106958 <alltraps>

80107355 <vector99>:
.globl vector99
vector99:
  pushl $0
80107355:	6a 00                	push   $0x0
  pushl $99
80107357:	6a 63                	push   $0x63
  jmp alltraps
80107359:	e9 fa f5 ff ff       	jmp    80106958 <alltraps>

8010735e <vector100>:
.globl vector100
vector100:
  pushl $0
8010735e:	6a 00                	push   $0x0
  pushl $100
80107360:	6a 64                	push   $0x64
  jmp alltraps
80107362:	e9 f1 f5 ff ff       	jmp    80106958 <alltraps>

80107367 <vector101>:
.globl vector101
vector101:
  pushl $0
80107367:	6a 00                	push   $0x0
  pushl $101
80107369:	6a 65                	push   $0x65
  jmp alltraps
8010736b:	e9 e8 f5 ff ff       	jmp    80106958 <alltraps>

80107370 <vector102>:
.globl vector102
vector102:
  pushl $0
80107370:	6a 00                	push   $0x0
  pushl $102
80107372:	6a 66                	push   $0x66
  jmp alltraps
80107374:	e9 df f5 ff ff       	jmp    80106958 <alltraps>

80107379 <vector103>:
.globl vector103
vector103:
  pushl $0
80107379:	6a 00                	push   $0x0
  pushl $103
8010737b:	6a 67                	push   $0x67
  jmp alltraps
8010737d:	e9 d6 f5 ff ff       	jmp    80106958 <alltraps>

80107382 <vector104>:
.globl vector104
vector104:
  pushl $0
80107382:	6a 00                	push   $0x0
  pushl $104
80107384:	6a 68                	push   $0x68
  jmp alltraps
80107386:	e9 cd f5 ff ff       	jmp    80106958 <alltraps>

8010738b <vector105>:
.globl vector105
vector105:
  pushl $0
8010738b:	6a 00                	push   $0x0
  pushl $105
8010738d:	6a 69                	push   $0x69
  jmp alltraps
8010738f:	e9 c4 f5 ff ff       	jmp    80106958 <alltraps>

80107394 <vector106>:
.globl vector106
vector106:
  pushl $0
80107394:	6a 00                	push   $0x0
  pushl $106
80107396:	6a 6a                	push   $0x6a
  jmp alltraps
80107398:	e9 bb f5 ff ff       	jmp    80106958 <alltraps>

8010739d <vector107>:
.globl vector107
vector107:
  pushl $0
8010739d:	6a 00                	push   $0x0
  pushl $107
8010739f:	6a 6b                	push   $0x6b
  jmp alltraps
801073a1:	e9 b2 f5 ff ff       	jmp    80106958 <alltraps>

801073a6 <vector108>:
.globl vector108
vector108:
  pushl $0
801073a6:	6a 00                	push   $0x0
  pushl $108
801073a8:	6a 6c                	push   $0x6c
  jmp alltraps
801073aa:	e9 a9 f5 ff ff       	jmp    80106958 <alltraps>

801073af <vector109>:
.globl vector109
vector109:
  pushl $0
801073af:	6a 00                	push   $0x0
  pushl $109
801073b1:	6a 6d                	push   $0x6d
  jmp alltraps
801073b3:	e9 a0 f5 ff ff       	jmp    80106958 <alltraps>

801073b8 <vector110>:
.globl vector110
vector110:
  pushl $0
801073b8:	6a 00                	push   $0x0
  pushl $110
801073ba:	6a 6e                	push   $0x6e
  jmp alltraps
801073bc:	e9 97 f5 ff ff       	jmp    80106958 <alltraps>

801073c1 <vector111>:
.globl vector111
vector111:
  pushl $0
801073c1:	6a 00                	push   $0x0
  pushl $111
801073c3:	6a 6f                	push   $0x6f
  jmp alltraps
801073c5:	e9 8e f5 ff ff       	jmp    80106958 <alltraps>

801073ca <vector112>:
.globl vector112
vector112:
  pushl $0
801073ca:	6a 00                	push   $0x0
  pushl $112
801073cc:	6a 70                	push   $0x70
  jmp alltraps
801073ce:	e9 85 f5 ff ff       	jmp    80106958 <alltraps>

801073d3 <vector113>:
.globl vector113
vector113:
  pushl $0
801073d3:	6a 00                	push   $0x0
  pushl $113
801073d5:	6a 71                	push   $0x71
  jmp alltraps
801073d7:	e9 7c f5 ff ff       	jmp    80106958 <alltraps>

801073dc <vector114>:
.globl vector114
vector114:
  pushl $0
801073dc:	6a 00                	push   $0x0
  pushl $114
801073de:	6a 72                	push   $0x72
  jmp alltraps
801073e0:	e9 73 f5 ff ff       	jmp    80106958 <alltraps>

801073e5 <vector115>:
.globl vector115
vector115:
  pushl $0
801073e5:	6a 00                	push   $0x0
  pushl $115
801073e7:	6a 73                	push   $0x73
  jmp alltraps
801073e9:	e9 6a f5 ff ff       	jmp    80106958 <alltraps>

801073ee <vector116>:
.globl vector116
vector116:
  pushl $0
801073ee:	6a 00                	push   $0x0
  pushl $116
801073f0:	6a 74                	push   $0x74
  jmp alltraps
801073f2:	e9 61 f5 ff ff       	jmp    80106958 <alltraps>

801073f7 <vector117>:
.globl vector117
vector117:
  pushl $0
801073f7:	6a 00                	push   $0x0
  pushl $117
801073f9:	6a 75                	push   $0x75
  jmp alltraps
801073fb:	e9 58 f5 ff ff       	jmp    80106958 <alltraps>

80107400 <vector118>:
.globl vector118
vector118:
  pushl $0
80107400:	6a 00                	push   $0x0
  pushl $118
80107402:	6a 76                	push   $0x76
  jmp alltraps
80107404:	e9 4f f5 ff ff       	jmp    80106958 <alltraps>

80107409 <vector119>:
.globl vector119
vector119:
  pushl $0
80107409:	6a 00                	push   $0x0
  pushl $119
8010740b:	6a 77                	push   $0x77
  jmp alltraps
8010740d:	e9 46 f5 ff ff       	jmp    80106958 <alltraps>

80107412 <vector120>:
.globl vector120
vector120:
  pushl $0
80107412:	6a 00                	push   $0x0
  pushl $120
80107414:	6a 78                	push   $0x78
  jmp alltraps
80107416:	e9 3d f5 ff ff       	jmp    80106958 <alltraps>

8010741b <vector121>:
.globl vector121
vector121:
  pushl $0
8010741b:	6a 00                	push   $0x0
  pushl $121
8010741d:	6a 79                	push   $0x79
  jmp alltraps
8010741f:	e9 34 f5 ff ff       	jmp    80106958 <alltraps>

80107424 <vector122>:
.globl vector122
vector122:
  pushl $0
80107424:	6a 00                	push   $0x0
  pushl $122
80107426:	6a 7a                	push   $0x7a
  jmp alltraps
80107428:	e9 2b f5 ff ff       	jmp    80106958 <alltraps>

8010742d <vector123>:
.globl vector123
vector123:
  pushl $0
8010742d:	6a 00                	push   $0x0
  pushl $123
8010742f:	6a 7b                	push   $0x7b
  jmp alltraps
80107431:	e9 22 f5 ff ff       	jmp    80106958 <alltraps>

80107436 <vector124>:
.globl vector124
vector124:
  pushl $0
80107436:	6a 00                	push   $0x0
  pushl $124
80107438:	6a 7c                	push   $0x7c
  jmp alltraps
8010743a:	e9 19 f5 ff ff       	jmp    80106958 <alltraps>

8010743f <vector125>:
.globl vector125
vector125:
  pushl $0
8010743f:	6a 00                	push   $0x0
  pushl $125
80107441:	6a 7d                	push   $0x7d
  jmp alltraps
80107443:	e9 10 f5 ff ff       	jmp    80106958 <alltraps>

80107448 <vector126>:
.globl vector126
vector126:
  pushl $0
80107448:	6a 00                	push   $0x0
  pushl $126
8010744a:	6a 7e                	push   $0x7e
  jmp alltraps
8010744c:	e9 07 f5 ff ff       	jmp    80106958 <alltraps>

80107451 <vector127>:
.globl vector127
vector127:
  pushl $0
80107451:	6a 00                	push   $0x0
  pushl $127
80107453:	6a 7f                	push   $0x7f
  jmp alltraps
80107455:	e9 fe f4 ff ff       	jmp    80106958 <alltraps>

8010745a <vector128>:
.globl vector128
vector128:
  pushl $0
8010745a:	6a 00                	push   $0x0
  pushl $128
8010745c:	68 80 00 00 00       	push   $0x80
  jmp alltraps
80107461:	e9 f2 f4 ff ff       	jmp    80106958 <alltraps>

80107466 <vector129>:
.globl vector129
vector129:
  pushl $0
80107466:	6a 00                	push   $0x0
  pushl $129
80107468:	68 81 00 00 00       	push   $0x81
  jmp alltraps
8010746d:	e9 e6 f4 ff ff       	jmp    80106958 <alltraps>

80107472 <vector130>:
.globl vector130
vector130:
  pushl $0
80107472:	6a 00                	push   $0x0
  pushl $130
80107474:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107479:	e9 da f4 ff ff       	jmp    80106958 <alltraps>

8010747e <vector131>:
.globl vector131
vector131:
  pushl $0
8010747e:	6a 00                	push   $0x0
  pushl $131
80107480:	68 83 00 00 00       	push   $0x83
  jmp alltraps
80107485:	e9 ce f4 ff ff       	jmp    80106958 <alltraps>

8010748a <vector132>:
.globl vector132
vector132:
  pushl $0
8010748a:	6a 00                	push   $0x0
  pushl $132
8010748c:	68 84 00 00 00       	push   $0x84
  jmp alltraps
80107491:	e9 c2 f4 ff ff       	jmp    80106958 <alltraps>

80107496 <vector133>:
.globl vector133
vector133:
  pushl $0
80107496:	6a 00                	push   $0x0
  pushl $133
80107498:	68 85 00 00 00       	push   $0x85
  jmp alltraps
8010749d:	e9 b6 f4 ff ff       	jmp    80106958 <alltraps>

801074a2 <vector134>:
.globl vector134
vector134:
  pushl $0
801074a2:	6a 00                	push   $0x0
  pushl $134
801074a4:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801074a9:	e9 aa f4 ff ff       	jmp    80106958 <alltraps>

801074ae <vector135>:
.globl vector135
vector135:
  pushl $0
801074ae:	6a 00                	push   $0x0
  pushl $135
801074b0:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801074b5:	e9 9e f4 ff ff       	jmp    80106958 <alltraps>

801074ba <vector136>:
.globl vector136
vector136:
  pushl $0
801074ba:	6a 00                	push   $0x0
  pushl $136
801074bc:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801074c1:	e9 92 f4 ff ff       	jmp    80106958 <alltraps>

801074c6 <vector137>:
.globl vector137
vector137:
  pushl $0
801074c6:	6a 00                	push   $0x0
  pushl $137
801074c8:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801074cd:	e9 86 f4 ff ff       	jmp    80106958 <alltraps>

801074d2 <vector138>:
.globl vector138
vector138:
  pushl $0
801074d2:	6a 00                	push   $0x0
  pushl $138
801074d4:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801074d9:	e9 7a f4 ff ff       	jmp    80106958 <alltraps>

801074de <vector139>:
.globl vector139
vector139:
  pushl $0
801074de:	6a 00                	push   $0x0
  pushl $139
801074e0:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801074e5:	e9 6e f4 ff ff       	jmp    80106958 <alltraps>

801074ea <vector140>:
.globl vector140
vector140:
  pushl $0
801074ea:	6a 00                	push   $0x0
  pushl $140
801074ec:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
801074f1:	e9 62 f4 ff ff       	jmp    80106958 <alltraps>

801074f6 <vector141>:
.globl vector141
vector141:
  pushl $0
801074f6:	6a 00                	push   $0x0
  pushl $141
801074f8:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
801074fd:	e9 56 f4 ff ff       	jmp    80106958 <alltraps>

80107502 <vector142>:
.globl vector142
vector142:
  pushl $0
80107502:	6a 00                	push   $0x0
  pushl $142
80107504:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107509:	e9 4a f4 ff ff       	jmp    80106958 <alltraps>

8010750e <vector143>:
.globl vector143
vector143:
  pushl $0
8010750e:	6a 00                	push   $0x0
  pushl $143
80107510:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
80107515:	e9 3e f4 ff ff       	jmp    80106958 <alltraps>

8010751a <vector144>:
.globl vector144
vector144:
  pushl $0
8010751a:	6a 00                	push   $0x0
  pushl $144
8010751c:	68 90 00 00 00       	push   $0x90
  jmp alltraps
80107521:	e9 32 f4 ff ff       	jmp    80106958 <alltraps>

80107526 <vector145>:
.globl vector145
vector145:
  pushl $0
80107526:	6a 00                	push   $0x0
  pushl $145
80107528:	68 91 00 00 00       	push   $0x91
  jmp alltraps
8010752d:	e9 26 f4 ff ff       	jmp    80106958 <alltraps>

80107532 <vector146>:
.globl vector146
vector146:
  pushl $0
80107532:	6a 00                	push   $0x0
  pushl $146
80107534:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107539:	e9 1a f4 ff ff       	jmp    80106958 <alltraps>

8010753e <vector147>:
.globl vector147
vector147:
  pushl $0
8010753e:	6a 00                	push   $0x0
  pushl $147
80107540:	68 93 00 00 00       	push   $0x93
  jmp alltraps
80107545:	e9 0e f4 ff ff       	jmp    80106958 <alltraps>

8010754a <vector148>:
.globl vector148
vector148:
  pushl $0
8010754a:	6a 00                	push   $0x0
  pushl $148
8010754c:	68 94 00 00 00       	push   $0x94
  jmp alltraps
80107551:	e9 02 f4 ff ff       	jmp    80106958 <alltraps>

80107556 <vector149>:
.globl vector149
vector149:
  pushl $0
80107556:	6a 00                	push   $0x0
  pushl $149
80107558:	68 95 00 00 00       	push   $0x95
  jmp alltraps
8010755d:	e9 f6 f3 ff ff       	jmp    80106958 <alltraps>

80107562 <vector150>:
.globl vector150
vector150:
  pushl $0
80107562:	6a 00                	push   $0x0
  pushl $150
80107564:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107569:	e9 ea f3 ff ff       	jmp    80106958 <alltraps>

8010756e <vector151>:
.globl vector151
vector151:
  pushl $0
8010756e:	6a 00                	push   $0x0
  pushl $151
80107570:	68 97 00 00 00       	push   $0x97
  jmp alltraps
80107575:	e9 de f3 ff ff       	jmp    80106958 <alltraps>

8010757a <vector152>:
.globl vector152
vector152:
  pushl $0
8010757a:	6a 00                	push   $0x0
  pushl $152
8010757c:	68 98 00 00 00       	push   $0x98
  jmp alltraps
80107581:	e9 d2 f3 ff ff       	jmp    80106958 <alltraps>

80107586 <vector153>:
.globl vector153
vector153:
  pushl $0
80107586:	6a 00                	push   $0x0
  pushl $153
80107588:	68 99 00 00 00       	push   $0x99
  jmp alltraps
8010758d:	e9 c6 f3 ff ff       	jmp    80106958 <alltraps>

80107592 <vector154>:
.globl vector154
vector154:
  pushl $0
80107592:	6a 00                	push   $0x0
  pushl $154
80107594:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
80107599:	e9 ba f3 ff ff       	jmp    80106958 <alltraps>

8010759e <vector155>:
.globl vector155
vector155:
  pushl $0
8010759e:	6a 00                	push   $0x0
  pushl $155
801075a0:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801075a5:	e9 ae f3 ff ff       	jmp    80106958 <alltraps>

801075aa <vector156>:
.globl vector156
vector156:
  pushl $0
801075aa:	6a 00                	push   $0x0
  pushl $156
801075ac:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801075b1:	e9 a2 f3 ff ff       	jmp    80106958 <alltraps>

801075b6 <vector157>:
.globl vector157
vector157:
  pushl $0
801075b6:	6a 00                	push   $0x0
  pushl $157
801075b8:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801075bd:	e9 96 f3 ff ff       	jmp    80106958 <alltraps>

801075c2 <vector158>:
.globl vector158
vector158:
  pushl $0
801075c2:	6a 00                	push   $0x0
  pushl $158
801075c4:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801075c9:	e9 8a f3 ff ff       	jmp    80106958 <alltraps>

801075ce <vector159>:
.globl vector159
vector159:
  pushl $0
801075ce:	6a 00                	push   $0x0
  pushl $159
801075d0:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801075d5:	e9 7e f3 ff ff       	jmp    80106958 <alltraps>

801075da <vector160>:
.globl vector160
vector160:
  pushl $0
801075da:	6a 00                	push   $0x0
  pushl $160
801075dc:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801075e1:	e9 72 f3 ff ff       	jmp    80106958 <alltraps>

801075e6 <vector161>:
.globl vector161
vector161:
  pushl $0
801075e6:	6a 00                	push   $0x0
  pushl $161
801075e8:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
801075ed:	e9 66 f3 ff ff       	jmp    80106958 <alltraps>

801075f2 <vector162>:
.globl vector162
vector162:
  pushl $0
801075f2:	6a 00                	push   $0x0
  pushl $162
801075f4:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
801075f9:	e9 5a f3 ff ff       	jmp    80106958 <alltraps>

801075fe <vector163>:
.globl vector163
vector163:
  pushl $0
801075fe:	6a 00                	push   $0x0
  pushl $163
80107600:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
80107605:	e9 4e f3 ff ff       	jmp    80106958 <alltraps>

8010760a <vector164>:
.globl vector164
vector164:
  pushl $0
8010760a:	6a 00                	push   $0x0
  pushl $164
8010760c:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
80107611:	e9 42 f3 ff ff       	jmp    80106958 <alltraps>

80107616 <vector165>:
.globl vector165
vector165:
  pushl $0
80107616:	6a 00                	push   $0x0
  pushl $165
80107618:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
8010761d:	e9 36 f3 ff ff       	jmp    80106958 <alltraps>

80107622 <vector166>:
.globl vector166
vector166:
  pushl $0
80107622:	6a 00                	push   $0x0
  pushl $166
80107624:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107629:	e9 2a f3 ff ff       	jmp    80106958 <alltraps>

8010762e <vector167>:
.globl vector167
vector167:
  pushl $0
8010762e:	6a 00                	push   $0x0
  pushl $167
80107630:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
80107635:	e9 1e f3 ff ff       	jmp    80106958 <alltraps>

8010763a <vector168>:
.globl vector168
vector168:
  pushl $0
8010763a:	6a 00                	push   $0x0
  pushl $168
8010763c:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
80107641:	e9 12 f3 ff ff       	jmp    80106958 <alltraps>

80107646 <vector169>:
.globl vector169
vector169:
  pushl $0
80107646:	6a 00                	push   $0x0
  pushl $169
80107648:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
8010764d:	e9 06 f3 ff ff       	jmp    80106958 <alltraps>

80107652 <vector170>:
.globl vector170
vector170:
  pushl $0
80107652:	6a 00                	push   $0x0
  pushl $170
80107654:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107659:	e9 fa f2 ff ff       	jmp    80106958 <alltraps>

8010765e <vector171>:
.globl vector171
vector171:
  pushl $0
8010765e:	6a 00                	push   $0x0
  pushl $171
80107660:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
80107665:	e9 ee f2 ff ff       	jmp    80106958 <alltraps>

8010766a <vector172>:
.globl vector172
vector172:
  pushl $0
8010766a:	6a 00                	push   $0x0
  pushl $172
8010766c:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
80107671:	e9 e2 f2 ff ff       	jmp    80106958 <alltraps>

80107676 <vector173>:
.globl vector173
vector173:
  pushl $0
80107676:	6a 00                	push   $0x0
  pushl $173
80107678:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
8010767d:	e9 d6 f2 ff ff       	jmp    80106958 <alltraps>

80107682 <vector174>:
.globl vector174
vector174:
  pushl $0
80107682:	6a 00                	push   $0x0
  pushl $174
80107684:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
80107689:	e9 ca f2 ff ff       	jmp    80106958 <alltraps>

8010768e <vector175>:
.globl vector175
vector175:
  pushl $0
8010768e:	6a 00                	push   $0x0
  pushl $175
80107690:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
80107695:	e9 be f2 ff ff       	jmp    80106958 <alltraps>

8010769a <vector176>:
.globl vector176
vector176:
  pushl $0
8010769a:	6a 00                	push   $0x0
  pushl $176
8010769c:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801076a1:	e9 b2 f2 ff ff       	jmp    80106958 <alltraps>

801076a6 <vector177>:
.globl vector177
vector177:
  pushl $0
801076a6:	6a 00                	push   $0x0
  pushl $177
801076a8:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801076ad:	e9 a6 f2 ff ff       	jmp    80106958 <alltraps>

801076b2 <vector178>:
.globl vector178
vector178:
  pushl $0
801076b2:	6a 00                	push   $0x0
  pushl $178
801076b4:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801076b9:	e9 9a f2 ff ff       	jmp    80106958 <alltraps>

801076be <vector179>:
.globl vector179
vector179:
  pushl $0
801076be:	6a 00                	push   $0x0
  pushl $179
801076c0:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801076c5:	e9 8e f2 ff ff       	jmp    80106958 <alltraps>

801076ca <vector180>:
.globl vector180
vector180:
  pushl $0
801076ca:	6a 00                	push   $0x0
  pushl $180
801076cc:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801076d1:	e9 82 f2 ff ff       	jmp    80106958 <alltraps>

801076d6 <vector181>:
.globl vector181
vector181:
  pushl $0
801076d6:	6a 00                	push   $0x0
  pushl $181
801076d8:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801076dd:	e9 76 f2 ff ff       	jmp    80106958 <alltraps>

801076e2 <vector182>:
.globl vector182
vector182:
  pushl $0
801076e2:	6a 00                	push   $0x0
  pushl $182
801076e4:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
801076e9:	e9 6a f2 ff ff       	jmp    80106958 <alltraps>

801076ee <vector183>:
.globl vector183
vector183:
  pushl $0
801076ee:	6a 00                	push   $0x0
  pushl $183
801076f0:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
801076f5:	e9 5e f2 ff ff       	jmp    80106958 <alltraps>

801076fa <vector184>:
.globl vector184
vector184:
  pushl $0
801076fa:	6a 00                	push   $0x0
  pushl $184
801076fc:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
80107701:	e9 52 f2 ff ff       	jmp    80106958 <alltraps>

80107706 <vector185>:
.globl vector185
vector185:
  pushl $0
80107706:	6a 00                	push   $0x0
  pushl $185
80107708:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
8010770d:	e9 46 f2 ff ff       	jmp    80106958 <alltraps>

80107712 <vector186>:
.globl vector186
vector186:
  pushl $0
80107712:	6a 00                	push   $0x0
  pushl $186
80107714:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107719:	e9 3a f2 ff ff       	jmp    80106958 <alltraps>

8010771e <vector187>:
.globl vector187
vector187:
  pushl $0
8010771e:	6a 00                	push   $0x0
  pushl $187
80107720:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
80107725:	e9 2e f2 ff ff       	jmp    80106958 <alltraps>

8010772a <vector188>:
.globl vector188
vector188:
  pushl $0
8010772a:	6a 00                	push   $0x0
  pushl $188
8010772c:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
80107731:	e9 22 f2 ff ff       	jmp    80106958 <alltraps>

80107736 <vector189>:
.globl vector189
vector189:
  pushl $0
80107736:	6a 00                	push   $0x0
  pushl $189
80107738:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
8010773d:	e9 16 f2 ff ff       	jmp    80106958 <alltraps>

80107742 <vector190>:
.globl vector190
vector190:
  pushl $0
80107742:	6a 00                	push   $0x0
  pushl $190
80107744:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107749:	e9 0a f2 ff ff       	jmp    80106958 <alltraps>

8010774e <vector191>:
.globl vector191
vector191:
  pushl $0
8010774e:	6a 00                	push   $0x0
  pushl $191
80107750:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
80107755:	e9 fe f1 ff ff       	jmp    80106958 <alltraps>

8010775a <vector192>:
.globl vector192
vector192:
  pushl $0
8010775a:	6a 00                	push   $0x0
  pushl $192
8010775c:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
80107761:	e9 f2 f1 ff ff       	jmp    80106958 <alltraps>

80107766 <vector193>:
.globl vector193
vector193:
  pushl $0
80107766:	6a 00                	push   $0x0
  pushl $193
80107768:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
8010776d:	e9 e6 f1 ff ff       	jmp    80106958 <alltraps>

80107772 <vector194>:
.globl vector194
vector194:
  pushl $0
80107772:	6a 00                	push   $0x0
  pushl $194
80107774:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107779:	e9 da f1 ff ff       	jmp    80106958 <alltraps>

8010777e <vector195>:
.globl vector195
vector195:
  pushl $0
8010777e:	6a 00                	push   $0x0
  pushl $195
80107780:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
80107785:	e9 ce f1 ff ff       	jmp    80106958 <alltraps>

8010778a <vector196>:
.globl vector196
vector196:
  pushl $0
8010778a:	6a 00                	push   $0x0
  pushl $196
8010778c:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
80107791:	e9 c2 f1 ff ff       	jmp    80106958 <alltraps>

80107796 <vector197>:
.globl vector197
vector197:
  pushl $0
80107796:	6a 00                	push   $0x0
  pushl $197
80107798:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
8010779d:	e9 b6 f1 ff ff       	jmp    80106958 <alltraps>

801077a2 <vector198>:
.globl vector198
vector198:
  pushl $0
801077a2:	6a 00                	push   $0x0
  pushl $198
801077a4:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801077a9:	e9 aa f1 ff ff       	jmp    80106958 <alltraps>

801077ae <vector199>:
.globl vector199
vector199:
  pushl $0
801077ae:	6a 00                	push   $0x0
  pushl $199
801077b0:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801077b5:	e9 9e f1 ff ff       	jmp    80106958 <alltraps>

801077ba <vector200>:
.globl vector200
vector200:
  pushl $0
801077ba:	6a 00                	push   $0x0
  pushl $200
801077bc:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801077c1:	e9 92 f1 ff ff       	jmp    80106958 <alltraps>

801077c6 <vector201>:
.globl vector201
vector201:
  pushl $0
801077c6:	6a 00                	push   $0x0
  pushl $201
801077c8:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801077cd:	e9 86 f1 ff ff       	jmp    80106958 <alltraps>

801077d2 <vector202>:
.globl vector202
vector202:
  pushl $0
801077d2:	6a 00                	push   $0x0
  pushl $202
801077d4:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801077d9:	e9 7a f1 ff ff       	jmp    80106958 <alltraps>

801077de <vector203>:
.globl vector203
vector203:
  pushl $0
801077de:	6a 00                	push   $0x0
  pushl $203
801077e0:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801077e5:	e9 6e f1 ff ff       	jmp    80106958 <alltraps>

801077ea <vector204>:
.globl vector204
vector204:
  pushl $0
801077ea:	6a 00                	push   $0x0
  pushl $204
801077ec:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
801077f1:	e9 62 f1 ff ff       	jmp    80106958 <alltraps>

801077f6 <vector205>:
.globl vector205
vector205:
  pushl $0
801077f6:	6a 00                	push   $0x0
  pushl $205
801077f8:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
801077fd:	e9 56 f1 ff ff       	jmp    80106958 <alltraps>

80107802 <vector206>:
.globl vector206
vector206:
  pushl $0
80107802:	6a 00                	push   $0x0
  pushl $206
80107804:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107809:	e9 4a f1 ff ff       	jmp    80106958 <alltraps>

8010780e <vector207>:
.globl vector207
vector207:
  pushl $0
8010780e:	6a 00                	push   $0x0
  pushl $207
80107810:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
80107815:	e9 3e f1 ff ff       	jmp    80106958 <alltraps>

8010781a <vector208>:
.globl vector208
vector208:
  pushl $0
8010781a:	6a 00                	push   $0x0
  pushl $208
8010781c:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
80107821:	e9 32 f1 ff ff       	jmp    80106958 <alltraps>

80107826 <vector209>:
.globl vector209
vector209:
  pushl $0
80107826:	6a 00                	push   $0x0
  pushl $209
80107828:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
8010782d:	e9 26 f1 ff ff       	jmp    80106958 <alltraps>

80107832 <vector210>:
.globl vector210
vector210:
  pushl $0
80107832:	6a 00                	push   $0x0
  pushl $210
80107834:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107839:	e9 1a f1 ff ff       	jmp    80106958 <alltraps>

8010783e <vector211>:
.globl vector211
vector211:
  pushl $0
8010783e:	6a 00                	push   $0x0
  pushl $211
80107840:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
80107845:	e9 0e f1 ff ff       	jmp    80106958 <alltraps>

8010784a <vector212>:
.globl vector212
vector212:
  pushl $0
8010784a:	6a 00                	push   $0x0
  pushl $212
8010784c:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
80107851:	e9 02 f1 ff ff       	jmp    80106958 <alltraps>

80107856 <vector213>:
.globl vector213
vector213:
  pushl $0
80107856:	6a 00                	push   $0x0
  pushl $213
80107858:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
8010785d:	e9 f6 f0 ff ff       	jmp    80106958 <alltraps>

80107862 <vector214>:
.globl vector214
vector214:
  pushl $0
80107862:	6a 00                	push   $0x0
  pushl $214
80107864:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107869:	e9 ea f0 ff ff       	jmp    80106958 <alltraps>

8010786e <vector215>:
.globl vector215
vector215:
  pushl $0
8010786e:	6a 00                	push   $0x0
  pushl $215
80107870:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
80107875:	e9 de f0 ff ff       	jmp    80106958 <alltraps>

8010787a <vector216>:
.globl vector216
vector216:
  pushl $0
8010787a:	6a 00                	push   $0x0
  pushl $216
8010787c:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
80107881:	e9 d2 f0 ff ff       	jmp    80106958 <alltraps>

80107886 <vector217>:
.globl vector217
vector217:
  pushl $0
80107886:	6a 00                	push   $0x0
  pushl $217
80107888:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
8010788d:	e9 c6 f0 ff ff       	jmp    80106958 <alltraps>

80107892 <vector218>:
.globl vector218
vector218:
  pushl $0
80107892:	6a 00                	push   $0x0
  pushl $218
80107894:	68 da 00 00 00       	push   $0xda
  jmp alltraps
80107899:	e9 ba f0 ff ff       	jmp    80106958 <alltraps>

8010789e <vector219>:
.globl vector219
vector219:
  pushl $0
8010789e:	6a 00                	push   $0x0
  pushl $219
801078a0:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801078a5:	e9 ae f0 ff ff       	jmp    80106958 <alltraps>

801078aa <vector220>:
.globl vector220
vector220:
  pushl $0
801078aa:	6a 00                	push   $0x0
  pushl $220
801078ac:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801078b1:	e9 a2 f0 ff ff       	jmp    80106958 <alltraps>

801078b6 <vector221>:
.globl vector221
vector221:
  pushl $0
801078b6:	6a 00                	push   $0x0
  pushl $221
801078b8:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801078bd:	e9 96 f0 ff ff       	jmp    80106958 <alltraps>

801078c2 <vector222>:
.globl vector222
vector222:
  pushl $0
801078c2:	6a 00                	push   $0x0
  pushl $222
801078c4:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801078c9:	e9 8a f0 ff ff       	jmp    80106958 <alltraps>

801078ce <vector223>:
.globl vector223
vector223:
  pushl $0
801078ce:	6a 00                	push   $0x0
  pushl $223
801078d0:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801078d5:	e9 7e f0 ff ff       	jmp    80106958 <alltraps>

801078da <vector224>:
.globl vector224
vector224:
  pushl $0
801078da:	6a 00                	push   $0x0
  pushl $224
801078dc:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801078e1:	e9 72 f0 ff ff       	jmp    80106958 <alltraps>

801078e6 <vector225>:
.globl vector225
vector225:
  pushl $0
801078e6:	6a 00                	push   $0x0
  pushl $225
801078e8:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
801078ed:	e9 66 f0 ff ff       	jmp    80106958 <alltraps>

801078f2 <vector226>:
.globl vector226
vector226:
  pushl $0
801078f2:	6a 00                	push   $0x0
  pushl $226
801078f4:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
801078f9:	e9 5a f0 ff ff       	jmp    80106958 <alltraps>

801078fe <vector227>:
.globl vector227
vector227:
  pushl $0
801078fe:	6a 00                	push   $0x0
  pushl $227
80107900:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
80107905:	e9 4e f0 ff ff       	jmp    80106958 <alltraps>

8010790a <vector228>:
.globl vector228
vector228:
  pushl $0
8010790a:	6a 00                	push   $0x0
  pushl $228
8010790c:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
80107911:	e9 42 f0 ff ff       	jmp    80106958 <alltraps>

80107916 <vector229>:
.globl vector229
vector229:
  pushl $0
80107916:	6a 00                	push   $0x0
  pushl $229
80107918:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
8010791d:	e9 36 f0 ff ff       	jmp    80106958 <alltraps>

80107922 <vector230>:
.globl vector230
vector230:
  pushl $0
80107922:	6a 00                	push   $0x0
  pushl $230
80107924:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107929:	e9 2a f0 ff ff       	jmp    80106958 <alltraps>

8010792e <vector231>:
.globl vector231
vector231:
  pushl $0
8010792e:	6a 00                	push   $0x0
  pushl $231
80107930:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
80107935:	e9 1e f0 ff ff       	jmp    80106958 <alltraps>

8010793a <vector232>:
.globl vector232
vector232:
  pushl $0
8010793a:	6a 00                	push   $0x0
  pushl $232
8010793c:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
80107941:	e9 12 f0 ff ff       	jmp    80106958 <alltraps>

80107946 <vector233>:
.globl vector233
vector233:
  pushl $0
80107946:	6a 00                	push   $0x0
  pushl $233
80107948:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
8010794d:	e9 06 f0 ff ff       	jmp    80106958 <alltraps>

80107952 <vector234>:
.globl vector234
vector234:
  pushl $0
80107952:	6a 00                	push   $0x0
  pushl $234
80107954:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107959:	e9 fa ef ff ff       	jmp    80106958 <alltraps>

8010795e <vector235>:
.globl vector235
vector235:
  pushl $0
8010795e:	6a 00                	push   $0x0
  pushl $235
80107960:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
80107965:	e9 ee ef ff ff       	jmp    80106958 <alltraps>

8010796a <vector236>:
.globl vector236
vector236:
  pushl $0
8010796a:	6a 00                	push   $0x0
  pushl $236
8010796c:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
80107971:	e9 e2 ef ff ff       	jmp    80106958 <alltraps>

80107976 <vector237>:
.globl vector237
vector237:
  pushl $0
80107976:	6a 00                	push   $0x0
  pushl $237
80107978:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
8010797d:	e9 d6 ef ff ff       	jmp    80106958 <alltraps>

80107982 <vector238>:
.globl vector238
vector238:
  pushl $0
80107982:	6a 00                	push   $0x0
  pushl $238
80107984:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
80107989:	e9 ca ef ff ff       	jmp    80106958 <alltraps>

8010798e <vector239>:
.globl vector239
vector239:
  pushl $0
8010798e:	6a 00                	push   $0x0
  pushl $239
80107990:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
80107995:	e9 be ef ff ff       	jmp    80106958 <alltraps>

8010799a <vector240>:
.globl vector240
vector240:
  pushl $0
8010799a:	6a 00                	push   $0x0
  pushl $240
8010799c:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801079a1:	e9 b2 ef ff ff       	jmp    80106958 <alltraps>

801079a6 <vector241>:
.globl vector241
vector241:
  pushl $0
801079a6:	6a 00                	push   $0x0
  pushl $241
801079a8:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801079ad:	e9 a6 ef ff ff       	jmp    80106958 <alltraps>

801079b2 <vector242>:
.globl vector242
vector242:
  pushl $0
801079b2:	6a 00                	push   $0x0
  pushl $242
801079b4:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801079b9:	e9 9a ef ff ff       	jmp    80106958 <alltraps>

801079be <vector243>:
.globl vector243
vector243:
  pushl $0
801079be:	6a 00                	push   $0x0
  pushl $243
801079c0:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801079c5:	e9 8e ef ff ff       	jmp    80106958 <alltraps>

801079ca <vector244>:
.globl vector244
vector244:
  pushl $0
801079ca:	6a 00                	push   $0x0
  pushl $244
801079cc:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801079d1:	e9 82 ef ff ff       	jmp    80106958 <alltraps>

801079d6 <vector245>:
.globl vector245
vector245:
  pushl $0
801079d6:	6a 00                	push   $0x0
  pushl $245
801079d8:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801079dd:	e9 76 ef ff ff       	jmp    80106958 <alltraps>

801079e2 <vector246>:
.globl vector246
vector246:
  pushl $0
801079e2:	6a 00                	push   $0x0
  pushl $246
801079e4:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
801079e9:	e9 6a ef ff ff       	jmp    80106958 <alltraps>

801079ee <vector247>:
.globl vector247
vector247:
  pushl $0
801079ee:	6a 00                	push   $0x0
  pushl $247
801079f0:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
801079f5:	e9 5e ef ff ff       	jmp    80106958 <alltraps>

801079fa <vector248>:
.globl vector248
vector248:
  pushl $0
801079fa:	6a 00                	push   $0x0
  pushl $248
801079fc:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
80107a01:	e9 52 ef ff ff       	jmp    80106958 <alltraps>

80107a06 <vector249>:
.globl vector249
vector249:
  pushl $0
80107a06:	6a 00                	push   $0x0
  pushl $249
80107a08:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107a0d:	e9 46 ef ff ff       	jmp    80106958 <alltraps>

80107a12 <vector250>:
.globl vector250
vector250:
  pushl $0
80107a12:	6a 00                	push   $0x0
  pushl $250
80107a14:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107a19:	e9 3a ef ff ff       	jmp    80106958 <alltraps>

80107a1e <vector251>:
.globl vector251
vector251:
  pushl $0
80107a1e:	6a 00                	push   $0x0
  pushl $251
80107a20:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
80107a25:	e9 2e ef ff ff       	jmp    80106958 <alltraps>

80107a2a <vector252>:
.globl vector252
vector252:
  pushl $0
80107a2a:	6a 00                	push   $0x0
  pushl $252
80107a2c:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
80107a31:	e9 22 ef ff ff       	jmp    80106958 <alltraps>

80107a36 <vector253>:
.globl vector253
vector253:
  pushl $0
80107a36:	6a 00                	push   $0x0
  pushl $253
80107a38:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107a3d:	e9 16 ef ff ff       	jmp    80106958 <alltraps>

80107a42 <vector254>:
.globl vector254
vector254:
  pushl $0
80107a42:	6a 00                	push   $0x0
  pushl $254
80107a44:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107a49:	e9 0a ef ff ff       	jmp    80106958 <alltraps>

80107a4e <vector255>:
.globl vector255
vector255:
  pushl $0
80107a4e:	6a 00                	push   $0x0
  pushl $255
80107a50:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
80107a55:	e9 fe ee ff ff       	jmp    80106958 <alltraps>
	...

80107a5c <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107a5c:	55                   	push   %ebp
80107a5d:	89 e5                	mov    %esp,%ebp
80107a5f:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80107a62:	8b 45 0c             	mov    0xc(%ebp),%eax
80107a65:	83 e8 01             	sub    $0x1,%eax
80107a68:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107a6c:	8b 45 08             	mov    0x8(%ebp),%eax
80107a6f:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80107a73:	8b 45 08             	mov    0x8(%ebp),%eax
80107a76:	c1 e8 10             	shr    $0x10,%eax
80107a79:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107a7d:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107a80:	0f 01 10             	lgdtl  (%eax)
}
80107a83:	c9                   	leave  
80107a84:	c3                   	ret    

80107a85 <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
80107a85:	55                   	push   %ebp
80107a86:	89 e5                	mov    %esp,%ebp
80107a88:	83 ec 04             	sub    $0x4,%esp
80107a8b:	8b 45 08             	mov    0x8(%ebp),%eax
80107a8e:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
80107a92:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107a96:	0f 00 d8             	ltr    %ax
}
80107a99:	c9                   	leave  
80107a9a:	c3                   	ret    

80107a9b <loadgs>:
  return eflags;
}

static inline void
loadgs(ushort v)
{
80107a9b:	55                   	push   %ebp
80107a9c:	89 e5                	mov    %esp,%ebp
80107a9e:	83 ec 04             	sub    $0x4,%esp
80107aa1:	8b 45 08             	mov    0x8(%ebp),%eax
80107aa4:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("movw %0, %%gs" : : "r" (v));
80107aa8:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
80107aac:	8e e8                	mov    %eax,%gs
}
80107aae:	c9                   	leave  
80107aaf:	c3                   	ret    

80107ab0 <lcr3>:
  return val;
}

static inline void
lcr3(uint val) 
{
80107ab0:	55                   	push   %ebp
80107ab1:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
80107ab3:	8b 45 08             	mov    0x8(%ebp),%eax
80107ab6:	0f 22 d8             	mov    %eax,%cr3
}
80107ab9:	5d                   	pop    %ebp
80107aba:	c3                   	ret    

80107abb <v2p>:
#define KERNBASE 0x80000000         // First kernel virtual address
#define KERNLINK (KERNBASE+EXTMEM)  // Address where kernel is linked

#ifndef __ASSEMBLER__

static inline uint v2p(void *a) { return ((uint) (a))  - KERNBASE; }
80107abb:	55                   	push   %ebp
80107abc:	89 e5                	mov    %esp,%ebp
80107abe:	8b 45 08             	mov    0x8(%ebp),%eax
80107ac1:	05 00 00 00 80       	add    $0x80000000,%eax
80107ac6:	5d                   	pop    %ebp
80107ac7:	c3                   	ret    

80107ac8 <p2v>:
static inline void *p2v(uint a) { return (void *) ((a) + KERNBASE); }
80107ac8:	55                   	push   %ebp
80107ac9:	89 e5                	mov    %esp,%ebp
80107acb:	8b 45 08             	mov    0x8(%ebp),%eax
80107ace:	05 00 00 00 80       	add    $0x80000000,%eax
80107ad3:	5d                   	pop    %ebp
80107ad4:	c3                   	ret    

80107ad5 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
80107ad5:	55                   	push   %ebp
80107ad6:	89 e5                	mov    %esp,%ebp
80107ad8:	53                   	push   %ebx
80107ad9:	83 ec 24             	sub    $0x24,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpunum()];
80107adc:	e8 24 ba ff ff       	call   80103505 <cpunum>
80107ae1:	69 c0 bc 00 00 00    	imul   $0xbc,%eax,%eax
80107ae7:	05 80 08 11 80       	add    $0x80110880,%eax
80107aec:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
80107aef:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107af2:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
80107af8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107afb:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
80107b01:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b04:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
80107b08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b0b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b0f:	83 e2 f0             	and    $0xfffffff0,%edx
80107b12:	83 ca 0a             	or     $0xa,%edx
80107b15:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b18:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b1b:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b1f:	83 ca 10             	or     $0x10,%edx
80107b22:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b25:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b28:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b2c:	83 e2 9f             	and    $0xffffff9f,%edx
80107b2f:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b35:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107b39:	83 ca 80             	or     $0xffffff80,%edx
80107b3c:	88 50 7d             	mov    %dl,0x7d(%eax)
80107b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b42:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b46:	83 ca 0f             	or     $0xf,%edx
80107b49:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b4f:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b53:	83 e2 ef             	and    $0xffffffef,%edx
80107b56:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b59:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b5c:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b60:	83 e2 df             	and    $0xffffffdf,%edx
80107b63:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b66:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b69:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b6d:	83 ca 40             	or     $0x40,%edx
80107b70:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b76:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107b7a:	83 ca 80             	or     $0xffffff80,%edx
80107b7d:	88 50 7e             	mov    %dl,0x7e(%eax)
80107b80:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b83:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107b87:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b8a:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
80107b91:	ff ff 
80107b93:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b96:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107b9d:	00 00 
80107b9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba2:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107ba9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bac:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107bb3:	83 e2 f0             	and    $0xfffffff0,%edx
80107bb6:	83 ca 02             	or     $0x2,%edx
80107bb9:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107bbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bc2:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107bc9:	83 ca 10             	or     $0x10,%edx
80107bcc:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107bd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bd5:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107bdc:	83 e2 9f             	and    $0xffffff9f,%edx
80107bdf:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107be8:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
80107bef:	83 ca 80             	or     $0xffffff80,%edx
80107bf2:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
80107bf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107bfb:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c02:	83 ca 0f             	or     $0xf,%edx
80107c05:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c0e:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c15:	83 e2 ef             	and    $0xffffffef,%edx
80107c18:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c21:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c28:	83 e2 df             	and    $0xffffffdf,%edx
80107c2b:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c34:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c3b:	83 ca 40             	or     $0x40,%edx
80107c3e:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c44:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c47:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107c4e:	83 ca 80             	or     $0xffffff80,%edx
80107c51:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107c57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c5a:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
80107c61:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c64:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107c6b:	ff ff 
80107c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c70:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107c77:	00 00 
80107c79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c7c:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107c83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c86:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107c8d:	83 e2 f0             	and    $0xfffffff0,%edx
80107c90:	83 ca 0a             	or     $0xa,%edx
80107c93:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107c99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c9c:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107ca3:	83 ca 10             	or     $0x10,%edx
80107ca6:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107cac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107caf:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107cb6:	83 ca 60             	or     $0x60,%edx
80107cb9:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107cbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cc2:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107cc9:	83 ca 80             	or     $0xffffff80,%edx
80107ccc:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107cd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cd5:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107cdc:	83 ca 0f             	or     $0xf,%edx
80107cdf:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ce8:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107cef:	83 e2 ef             	and    $0xffffffef,%edx
80107cf2:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107cf8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107cfb:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107d02:	83 e2 df             	and    $0xffffffdf,%edx
80107d05:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107d0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d0e:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107d15:	83 ca 40             	or     $0x40,%edx
80107d18:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107d1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d21:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107d28:	83 ca 80             	or     $0xffffff80,%edx
80107d2b:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107d31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d34:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107d3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d3e:	66 c7 80 98 00 00 00 	movw   $0xffff,0x98(%eax)
80107d45:	ff ff 
80107d47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d4a:	66 c7 80 9a 00 00 00 	movw   $0x0,0x9a(%eax)
80107d51:	00 00 
80107d53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d56:	c6 80 9c 00 00 00 00 	movb   $0x0,0x9c(%eax)
80107d5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d60:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d67:	83 e2 f0             	and    $0xfffffff0,%edx
80107d6a:	83 ca 02             	or     $0x2,%edx
80107d6d:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d73:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d76:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d7d:	83 ca 10             	or     $0x10,%edx
80107d80:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d86:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d89:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107d90:	83 ca 60             	or     $0x60,%edx
80107d93:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107d99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107d9c:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107da3:	83 ca 80             	or     $0xffffff80,%edx
80107da6:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
80107dac:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107daf:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107db6:	83 ca 0f             	or     $0xf,%edx
80107db9:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107dbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dc2:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107dc9:	83 e2 ef             	and    $0xffffffef,%edx
80107dcc:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107dd2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dd5:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107ddc:	83 e2 df             	and    $0xffffffdf,%edx
80107ddf:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107de5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107de8:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107def:	83 ca 40             	or     $0x40,%edx
80107df2:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107df8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107dfb:	0f b6 90 9e 00 00 00 	movzbl 0x9e(%eax),%edx
80107e02:	83 ca 80             	or     $0xffffff80,%edx
80107e05:	88 90 9e 00 00 00    	mov    %dl,0x9e(%eax)
80107e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e0e:	c6 80 9f 00 00 00 00 	movb   $0x0,0x9f(%eax)

  // Map cpu, and curproc
  c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);
80107e15:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e18:	05 b4 00 00 00       	add    $0xb4,%eax
80107e1d:	89 c3                	mov    %eax,%ebx
80107e1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e22:	05 b4 00 00 00       	add    $0xb4,%eax
80107e27:	c1 e8 10             	shr    $0x10,%eax
80107e2a:	89 c1                	mov    %eax,%ecx
80107e2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e2f:	05 b4 00 00 00       	add    $0xb4,%eax
80107e34:	c1 e8 18             	shr    $0x18,%eax
80107e37:	89 c2                	mov    %eax,%edx
80107e39:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e3c:	66 c7 80 88 00 00 00 	movw   $0x0,0x88(%eax)
80107e43:	00 00 
80107e45:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e48:	66 89 98 8a 00 00 00 	mov    %bx,0x8a(%eax)
80107e4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e52:	88 88 8c 00 00 00    	mov    %cl,0x8c(%eax)
80107e58:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e5b:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e62:	83 e1 f0             	and    $0xfffffff0,%ecx
80107e65:	83 c9 02             	or     $0x2,%ecx
80107e68:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e71:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e78:	83 c9 10             	or     $0x10,%ecx
80107e7b:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e84:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e8b:	83 e1 9f             	and    $0xffffff9f,%ecx
80107e8e:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107e94:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107e97:	0f b6 88 8d 00 00 00 	movzbl 0x8d(%eax),%ecx
80107e9e:	83 c9 80             	or     $0xffffff80,%ecx
80107ea1:	88 88 8d 00 00 00    	mov    %cl,0x8d(%eax)
80107ea7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107eaa:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107eb1:	83 e1 f0             	and    $0xfffffff0,%ecx
80107eb4:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107eba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ebd:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ec4:	83 e1 ef             	and    $0xffffffef,%ecx
80107ec7:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ecd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ed0:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107ed7:	83 e1 df             	and    $0xffffffdf,%ecx
80107eda:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ee0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ee3:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107eea:	83 c9 40             	or     $0x40,%ecx
80107eed:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107ef3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ef6:	0f b6 88 8e 00 00 00 	movzbl 0x8e(%eax),%ecx
80107efd:	83 c9 80             	or     $0xffffff80,%ecx
80107f00:	88 88 8e 00 00 00    	mov    %cl,0x8e(%eax)
80107f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f09:	88 90 8f 00 00 00    	mov    %dl,0x8f(%eax)

  lgdt(c->gdt, sizeof(c->gdt));
80107f0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f12:	83 c0 70             	add    $0x70,%eax
80107f15:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
80107f1c:	00 
80107f1d:	89 04 24             	mov    %eax,(%esp)
80107f20:	e8 37 fb ff ff       	call   80107a5c <lgdt>
  loadgs(SEG_KCPU << 3);
80107f25:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
80107f2c:	e8 6a fb ff ff       	call   80107a9b <loadgs>
  
  // Initialize cpu-local storage.
  cpu = c;
80107f31:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f34:	65 a3 00 00 00 00    	mov    %eax,%gs:0x0
  proc = 0;
80107f3a:	65 c7 05 04 00 00 00 	movl   $0x0,%gs:0x4
80107f41:	00 00 00 00 
}
80107f45:	83 c4 24             	add    $0x24,%esp
80107f48:	5b                   	pop    %ebx
80107f49:	5d                   	pop    %ebp
80107f4a:	c3                   	ret    

80107f4b <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107f4b:	55                   	push   %ebp
80107f4c:	89 e5                	mov    %esp,%ebp
80107f4e:	83 ec 28             	sub    $0x28,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107f51:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f54:	c1 e8 16             	shr    $0x16,%eax
80107f57:	c1 e0 02             	shl    $0x2,%eax
80107f5a:	03 45 08             	add    0x8(%ebp),%eax
80107f5d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107f60:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f63:	8b 00                	mov    (%eax),%eax
80107f65:	83 e0 01             	and    $0x1,%eax
80107f68:	84 c0                	test   %al,%al
80107f6a:	74 17                	je     80107f83 <walkpgdir+0x38>
    pgtab = (pte_t*)p2v(PTE_ADDR(*pde));
80107f6c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107f6f:	8b 00                	mov    (%eax),%eax
80107f71:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f76:	89 04 24             	mov    %eax,(%esp)
80107f79:	e8 4a fb ff ff       	call   80107ac8 <p2v>
80107f7e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f81:	eb 4b                	jmp    80107fce <walkpgdir+0x83>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107f83:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107f87:	74 0e                	je     80107f97 <walkpgdir+0x4c>
80107f89:	e8 e9 b1 ff ff       	call   80103177 <kalloc>
80107f8e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107f91:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107f95:	75 07                	jne    80107f9e <walkpgdir+0x53>
      return 0;
80107f97:	b8 00 00 00 00       	mov    $0x0,%eax
80107f9c:	eb 41                	jmp    80107fdf <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107f9e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80107fa5:	00 
80107fa6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80107fad:	00 
80107fae:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fb1:	89 04 24             	mov    %eax,(%esp)
80107fb4:	e8 b1 d4 ff ff       	call   8010546a <memset>
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table 
    // entries, if necessary.
    *pde = v2p(pgtab) | PTE_P | PTE_W | PTE_U;
80107fb9:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fbc:	89 04 24             	mov    %eax,(%esp)
80107fbf:	e8 f7 fa ff ff       	call   80107abb <v2p>
80107fc4:	89 c2                	mov    %eax,%edx
80107fc6:	83 ca 07             	or     $0x7,%edx
80107fc9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107fcc:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107fce:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fd1:	c1 e8 0c             	shr    $0xc,%eax
80107fd4:	25 ff 03 00 00       	and    $0x3ff,%eax
80107fd9:	c1 e0 02             	shl    $0x2,%eax
80107fdc:	03 45 f4             	add    -0xc(%ebp),%eax
}
80107fdf:	c9                   	leave  
80107fe0:	c3                   	ret    

80107fe1 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
static int
mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107fe1:	55                   	push   %ebp
80107fe2:	89 e5                	mov    %esp,%ebp
80107fe4:	83 ec 28             	sub    $0x28,%esp
  char *a, *last;
  pte_t *pte;
  
  a = (char*)PGROUNDDOWN((uint)va);
80107fe7:	8b 45 0c             	mov    0xc(%ebp),%eax
80107fea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107fef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107ff2:	8b 45 0c             	mov    0xc(%ebp),%eax
80107ff5:	03 45 10             	add    0x10(%ebp),%eax
80107ff8:	83 e8 01             	sub    $0x1,%eax
80107ffb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108000:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80108003:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
8010800a:	00 
8010800b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010800e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108012:	8b 45 08             	mov    0x8(%ebp),%eax
80108015:	89 04 24             	mov    %eax,(%esp)
80108018:	e8 2e ff ff ff       	call   80107f4b <walkpgdir>
8010801d:	89 45 ec             	mov    %eax,-0x14(%ebp)
80108020:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108024:	75 07                	jne    8010802d <mappages+0x4c>
      return -1;
80108026:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010802b:	eb 46                	jmp    80108073 <mappages+0x92>
    if(*pte & PTE_P)
8010802d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108030:	8b 00                	mov    (%eax),%eax
80108032:	83 e0 01             	and    $0x1,%eax
80108035:	84 c0                	test   %al,%al
80108037:	74 0c                	je     80108045 <mappages+0x64>
      panic("remap");
80108039:	c7 04 24 a4 8e 10 80 	movl   $0x80108ea4,(%esp)
80108040:	e8 f8 84 ff ff       	call   8010053d <panic>
    *pte = pa | perm | PTE_P;
80108045:	8b 45 18             	mov    0x18(%ebp),%eax
80108048:	0b 45 14             	or     0x14(%ebp),%eax
8010804b:	89 c2                	mov    %eax,%edx
8010804d:	83 ca 01             	or     $0x1,%edx
80108050:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108053:	89 10                	mov    %edx,(%eax)
    if(a == last)
80108055:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108058:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010805b:	74 10                	je     8010806d <mappages+0x8c>
      break;
    a += PGSIZE;
8010805d:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80108064:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
8010806b:	eb 96                	jmp    80108003 <mappages+0x22>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
8010806d:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
8010806e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108073:	c9                   	leave  
80108074:	c3                   	ret    

80108075 <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm()
{
80108075:	55                   	push   %ebp
80108076:	89 e5                	mov    %esp,%ebp
80108078:	53                   	push   %ebx
80108079:	83 ec 34             	sub    $0x34,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
8010807c:	e8 f6 b0 ff ff       	call   80103177 <kalloc>
80108081:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108084:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108088:	75 0a                	jne    80108094 <setupkvm+0x1f>
    return 0;
8010808a:	b8 00 00 00 00       	mov    $0x0,%eax
8010808f:	e9 98 00 00 00       	jmp    8010812c <setupkvm+0xb7>
  memset(pgdir, 0, PGSIZE);
80108094:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010809b:	00 
8010809c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801080a3:	00 
801080a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801080a7:	89 04 24             	mov    %eax,(%esp)
801080aa:	e8 bb d3 ff ff       	call   8010546a <memset>
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
801080af:	c7 04 24 00 00 00 0e 	movl   $0xe000000,(%esp)
801080b6:	e8 0d fa ff ff       	call   80107ac8 <p2v>
801080bb:	3d 00 00 00 fe       	cmp    $0xfe000000,%eax
801080c0:	76 0c                	jbe    801080ce <setupkvm+0x59>
    panic("PHYSTOP too high");
801080c2:	c7 04 24 aa 8e 10 80 	movl   $0x80108eaa,(%esp)
801080c9:	e8 6f 84 ff ff       	call   8010053d <panic>
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
801080ce:	c7 45 f4 a0 b4 10 80 	movl   $0x8010b4a0,-0xc(%ebp)
801080d5:	eb 49                	jmp    80108120 <setupkvm+0xab>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
801080d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801080da:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0)
801080dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
801080e0:	8b 50 04             	mov    0x4(%eax),%edx
801080e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080e6:	8b 58 08             	mov    0x8(%eax),%ebx
801080e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080ec:	8b 40 04             	mov    0x4(%eax),%eax
801080ef:	29 c3                	sub    %eax,%ebx
801080f1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080f4:	8b 00                	mov    (%eax),%eax
801080f6:	89 4c 24 10          	mov    %ecx,0x10(%esp)
801080fa:	89 54 24 0c          	mov    %edx,0xc(%esp)
801080fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
80108102:	89 44 24 04          	mov    %eax,0x4(%esp)
80108106:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108109:	89 04 24             	mov    %eax,(%esp)
8010810c:	e8 d0 fe ff ff       	call   80107fe1 <mappages>
80108111:	85 c0                	test   %eax,%eax
80108113:	79 07                	jns    8010811c <setupkvm+0xa7>
                (uint)k->phys_start, k->perm) < 0)
      return 0;
80108115:	b8 00 00 00 00       	mov    $0x0,%eax
8010811a:	eb 10                	jmp    8010812c <setupkvm+0xb7>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (p2v(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
8010811c:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80108120:	81 7d f4 e0 b4 10 80 	cmpl   $0x8010b4e0,-0xc(%ebp)
80108127:	72 ae                	jb     801080d7 <setupkvm+0x62>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start, 
                (uint)k->phys_start, k->perm) < 0)
      return 0;
  return pgdir;
80108129:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
8010812c:	83 c4 34             	add    $0x34,%esp
8010812f:	5b                   	pop    %ebx
80108130:	5d                   	pop    %ebp
80108131:	c3                   	ret    

80108132 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80108132:	55                   	push   %ebp
80108133:	89 e5                	mov    %esp,%ebp
80108135:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80108138:	e8 38 ff ff ff       	call   80108075 <setupkvm>
8010813d:	a3 58 36 11 80       	mov    %eax,0x80113658
  switchkvm();
80108142:	e8 02 00 00 00       	call   80108149 <switchkvm>
}
80108147:	c9                   	leave  
80108148:	c3                   	ret    

80108149 <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80108149:	55                   	push   %ebp
8010814a:	89 e5                	mov    %esp,%ebp
8010814c:	83 ec 04             	sub    $0x4,%esp
  lcr3(v2p(kpgdir));   // switch to the kernel page table
8010814f:	a1 58 36 11 80       	mov    0x80113658,%eax
80108154:	89 04 24             	mov    %eax,(%esp)
80108157:	e8 5f f9 ff ff       	call   80107abb <v2p>
8010815c:	89 04 24             	mov    %eax,(%esp)
8010815f:	e8 4c f9 ff ff       	call   80107ab0 <lcr3>
}
80108164:	c9                   	leave  
80108165:	c3                   	ret    

80108166 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80108166:	55                   	push   %ebp
80108167:	89 e5                	mov    %esp,%ebp
80108169:	53                   	push   %ebx
8010816a:	83 ec 14             	sub    $0x14,%esp
  pushcli();
8010816d:	e8 f1 d1 ff ff       	call   80105363 <pushcli>
  cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
80108172:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108178:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010817f:	83 c2 08             	add    $0x8,%edx
80108182:	89 d3                	mov    %edx,%ebx
80108184:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010818b:	83 c2 08             	add    $0x8,%edx
8010818e:	c1 ea 10             	shr    $0x10,%edx
80108191:	89 d1                	mov    %edx,%ecx
80108193:	65 8b 15 00 00 00 00 	mov    %gs:0x0,%edx
8010819a:	83 c2 08             	add    $0x8,%edx
8010819d:	c1 ea 18             	shr    $0x18,%edx
801081a0:	66 c7 80 a0 00 00 00 	movw   $0x67,0xa0(%eax)
801081a7:	67 00 
801081a9:	66 89 98 a2 00 00 00 	mov    %bx,0xa2(%eax)
801081b0:	88 88 a4 00 00 00    	mov    %cl,0xa4(%eax)
801081b6:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801081bd:	83 e1 f0             	and    $0xfffffff0,%ecx
801081c0:	83 c9 09             	or     $0x9,%ecx
801081c3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801081c9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801081d0:	83 c9 10             	or     $0x10,%ecx
801081d3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801081d9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801081e0:	83 e1 9f             	and    $0xffffff9f,%ecx
801081e3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801081e9:	0f b6 88 a5 00 00 00 	movzbl 0xa5(%eax),%ecx
801081f0:	83 c9 80             	or     $0xffffff80,%ecx
801081f3:	88 88 a5 00 00 00    	mov    %cl,0xa5(%eax)
801081f9:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108200:	83 e1 f0             	and    $0xfffffff0,%ecx
80108203:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108209:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108210:	83 e1 ef             	and    $0xffffffef,%ecx
80108213:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108219:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108220:	83 e1 df             	and    $0xffffffdf,%ecx
80108223:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108229:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108230:	83 c9 40             	or     $0x40,%ecx
80108233:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108239:	0f b6 88 a6 00 00 00 	movzbl 0xa6(%eax),%ecx
80108240:	83 e1 7f             	and    $0x7f,%ecx
80108243:	88 88 a6 00 00 00    	mov    %cl,0xa6(%eax)
80108249:	88 90 a7 00 00 00    	mov    %dl,0xa7(%eax)
  cpu->gdt[SEG_TSS].s = 0;
8010824f:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108255:	0f b6 90 a5 00 00 00 	movzbl 0xa5(%eax),%edx
8010825c:	83 e2 ef             	and    $0xffffffef,%edx
8010825f:	88 90 a5 00 00 00    	mov    %dl,0xa5(%eax)
  cpu->ts.ss0 = SEG_KDATA << 3;
80108265:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
8010826b:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  cpu->ts.esp0 = (uint)proc->kstack + KSTACKSIZE;
80108271:	65 a1 00 00 00 00    	mov    %gs:0x0,%eax
80108277:	65 8b 15 04 00 00 00 	mov    %gs:0x4,%edx
8010827e:	8b 52 08             	mov    0x8(%edx),%edx
80108281:	81 c2 00 10 00 00    	add    $0x1000,%edx
80108287:	89 50 0c             	mov    %edx,0xc(%eax)
  ltr(SEG_TSS << 3);
8010828a:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
80108291:	e8 ef f7 ff ff       	call   80107a85 <ltr>
  if(p->pgdir == 0)
80108296:	8b 45 08             	mov    0x8(%ebp),%eax
80108299:	8b 40 04             	mov    0x4(%eax),%eax
8010829c:	85 c0                	test   %eax,%eax
8010829e:	75 0c                	jne    801082ac <switchuvm+0x146>
    panic("switchuvm: no pgdir");
801082a0:	c7 04 24 bb 8e 10 80 	movl   $0x80108ebb,(%esp)
801082a7:	e8 91 82 ff ff       	call   8010053d <panic>
  lcr3(v2p(p->pgdir));  // switch to new address space
801082ac:	8b 45 08             	mov    0x8(%ebp),%eax
801082af:	8b 40 04             	mov    0x4(%eax),%eax
801082b2:	89 04 24             	mov    %eax,(%esp)
801082b5:	e8 01 f8 ff ff       	call   80107abb <v2p>
801082ba:	89 04 24             	mov    %eax,(%esp)
801082bd:	e8 ee f7 ff ff       	call   80107ab0 <lcr3>
  popcli();
801082c2:	e8 e4 d0 ff ff       	call   801053ab <popcli>
}
801082c7:	83 c4 14             	add    $0x14,%esp
801082ca:	5b                   	pop    %ebx
801082cb:	5d                   	pop    %ebp
801082cc:	c3                   	ret    

801082cd <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
801082cd:	55                   	push   %ebp
801082ce:	89 e5                	mov    %esp,%ebp
801082d0:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  
  if(sz >= PGSIZE)
801082d3:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
801082da:	76 0c                	jbe    801082e8 <inituvm+0x1b>
    panic("inituvm: more than a page");
801082dc:	c7 04 24 cf 8e 10 80 	movl   $0x80108ecf,(%esp)
801082e3:	e8 55 82 ff ff       	call   8010053d <panic>
  mem = kalloc();
801082e8:	e8 8a ae ff ff       	call   80103177 <kalloc>
801082ed:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
801082f0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801082f7:	00 
801082f8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801082ff:	00 
80108300:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108303:	89 04 24             	mov    %eax,(%esp)
80108306:	e8 5f d1 ff ff       	call   8010546a <memset>
  mappages(pgdir, 0, PGSIZE, v2p(mem), PTE_W|PTE_U);
8010830b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010830e:	89 04 24             	mov    %eax,(%esp)
80108311:	e8 a5 f7 ff ff       	call   80107abb <v2p>
80108316:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
8010831d:	00 
8010831e:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108322:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108329:	00 
8010832a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
80108331:	00 
80108332:	8b 45 08             	mov    0x8(%ebp),%eax
80108335:	89 04 24             	mov    %eax,(%esp)
80108338:	e8 a4 fc ff ff       	call   80107fe1 <mappages>
  memmove(mem, init, sz);
8010833d:	8b 45 10             	mov    0x10(%ebp),%eax
80108340:	89 44 24 08          	mov    %eax,0x8(%esp)
80108344:	8b 45 0c             	mov    0xc(%ebp),%eax
80108347:	89 44 24 04          	mov    %eax,0x4(%esp)
8010834b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010834e:	89 04 24             	mov    %eax,(%esp)
80108351:	e8 e7 d1 ff ff       	call   8010553d <memmove>
}
80108356:	c9                   	leave  
80108357:	c3                   	ret    

80108358 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80108358:	55                   	push   %ebp
80108359:	89 e5                	mov    %esp,%ebp
8010835b:	53                   	push   %ebx
8010835c:	83 ec 24             	sub    $0x24,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
8010835f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108362:	25 ff 0f 00 00       	and    $0xfff,%eax
80108367:	85 c0                	test   %eax,%eax
80108369:	74 0c                	je     80108377 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
8010836b:	c7 04 24 ec 8e 10 80 	movl   $0x80108eec,(%esp)
80108372:	e8 c6 81 ff ff       	call   8010053d <panic>
  for(i = 0; i < sz; i += PGSIZE){
80108377:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010837e:	e9 ad 00 00 00       	jmp    80108430 <loaduvm+0xd8>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80108383:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108386:	8b 55 0c             	mov    0xc(%ebp),%edx
80108389:	01 d0                	add    %edx,%eax
8010838b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108392:	00 
80108393:	89 44 24 04          	mov    %eax,0x4(%esp)
80108397:	8b 45 08             	mov    0x8(%ebp),%eax
8010839a:	89 04 24             	mov    %eax,(%esp)
8010839d:	e8 a9 fb ff ff       	call   80107f4b <walkpgdir>
801083a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
801083a5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801083a9:	75 0c                	jne    801083b7 <loaduvm+0x5f>
      panic("loaduvm: address should exist");
801083ab:	c7 04 24 0f 8f 10 80 	movl   $0x80108f0f,(%esp)
801083b2:	e8 86 81 ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
801083b7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083ba:	8b 00                	mov    (%eax),%eax
801083bc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083c1:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
801083c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c7:	8b 55 18             	mov    0x18(%ebp),%edx
801083ca:	89 d1                	mov    %edx,%ecx
801083cc:	29 c1                	sub    %eax,%ecx
801083ce:	89 c8                	mov    %ecx,%eax
801083d0:	3d ff 0f 00 00       	cmp    $0xfff,%eax
801083d5:	77 11                	ja     801083e8 <loaduvm+0x90>
      n = sz - i;
801083d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083da:	8b 55 18             	mov    0x18(%ebp),%edx
801083dd:	89 d1                	mov    %edx,%ecx
801083df:	29 c1                	sub    %eax,%ecx
801083e1:	89 c8                	mov    %ecx,%eax
801083e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
801083e6:	eb 07                	jmp    801083ef <loaduvm+0x97>
    else
      n = PGSIZE;
801083e8:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, p2v(pa), offset+i, n) != n)
801083ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083f2:	8b 55 14             	mov    0x14(%ebp),%edx
801083f5:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
801083f8:	8b 45 e8             	mov    -0x18(%ebp),%eax
801083fb:	89 04 24             	mov    %eax,(%esp)
801083fe:	e8 c5 f6 ff ff       	call   80107ac8 <p2v>
80108403:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108406:	89 54 24 0c          	mov    %edx,0xc(%esp)
8010840a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
8010840e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108412:	8b 45 10             	mov    0x10(%ebp),%eax
80108415:	89 04 24             	mov    %eax,(%esp)
80108418:	e8 b9 9f ff ff       	call   801023d6 <readi>
8010841d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80108420:	74 07                	je     80108429 <loaduvm+0xd1>
      return -1;
80108422:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80108427:	eb 18                	jmp    80108441 <loaduvm+0xe9>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80108429:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108430:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108433:	3b 45 18             	cmp    0x18(%ebp),%eax
80108436:	0f 82 47 ff ff ff    	jb     80108383 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, p2v(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
8010843c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80108441:	83 c4 24             	add    $0x24,%esp
80108444:	5b                   	pop    %ebx
80108445:	5d                   	pop    %ebp
80108446:	c3                   	ret    

80108447 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108447:	55                   	push   %ebp
80108448:	89 e5                	mov    %esp,%ebp
8010844a:	83 ec 38             	sub    $0x38,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
8010844d:	8b 45 10             	mov    0x10(%ebp),%eax
80108450:	85 c0                	test   %eax,%eax
80108452:	79 0a                	jns    8010845e <allocuvm+0x17>
    return 0;
80108454:	b8 00 00 00 00       	mov    $0x0,%eax
80108459:	e9 c1 00 00 00       	jmp    8010851f <allocuvm+0xd8>
  if(newsz < oldsz)
8010845e:	8b 45 10             	mov    0x10(%ebp),%eax
80108461:	3b 45 0c             	cmp    0xc(%ebp),%eax
80108464:	73 08                	jae    8010846e <allocuvm+0x27>
    return oldsz;
80108466:	8b 45 0c             	mov    0xc(%ebp),%eax
80108469:	e9 b1 00 00 00       	jmp    8010851f <allocuvm+0xd8>

  a = PGROUNDUP(oldsz);
8010846e:	8b 45 0c             	mov    0xc(%ebp),%eax
80108471:	05 ff 0f 00 00       	add    $0xfff,%eax
80108476:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010847b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
8010847e:	e9 8d 00 00 00       	jmp    80108510 <allocuvm+0xc9>
    mem = kalloc();
80108483:	e8 ef ac ff ff       	call   80103177 <kalloc>
80108488:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
8010848b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010848f:	75 2c                	jne    801084bd <allocuvm+0x76>
      cprintf("allocuvm out of memory\n");
80108491:	c7 04 24 2d 8f 10 80 	movl   $0x80108f2d,(%esp)
80108498:	e8 04 7f ff ff       	call   801003a1 <cprintf>
      deallocuvm(pgdir, newsz, oldsz);
8010849d:	8b 45 0c             	mov    0xc(%ebp),%eax
801084a0:	89 44 24 08          	mov    %eax,0x8(%esp)
801084a4:	8b 45 10             	mov    0x10(%ebp),%eax
801084a7:	89 44 24 04          	mov    %eax,0x4(%esp)
801084ab:	8b 45 08             	mov    0x8(%ebp),%eax
801084ae:	89 04 24             	mov    %eax,(%esp)
801084b1:	e8 6b 00 00 00       	call   80108521 <deallocuvm>
      return 0;
801084b6:	b8 00 00 00 00       	mov    $0x0,%eax
801084bb:	eb 62                	jmp    8010851f <allocuvm+0xd8>
    }
    memset(mem, 0, PGSIZE);
801084bd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084c4:	00 
801084c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
801084cc:	00 
801084cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084d0:	89 04 24             	mov    %eax,(%esp)
801084d3:	e8 92 cf ff ff       	call   8010546a <memset>
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
801084d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801084db:	89 04 24             	mov    %eax,(%esp)
801084de:	e8 d8 f5 ff ff       	call   80107abb <v2p>
801084e3:	8b 55 f4             	mov    -0xc(%ebp),%edx
801084e6:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
801084ed:	00 
801084ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
801084f2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
801084f9:	00 
801084fa:	89 54 24 04          	mov    %edx,0x4(%esp)
801084fe:	8b 45 08             	mov    0x8(%ebp),%eax
80108501:	89 04 24             	mov    %eax,(%esp)
80108504:	e8 d8 fa ff ff       	call   80107fe1 <mappages>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
80108509:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108510:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108513:	3b 45 10             	cmp    0x10(%ebp),%eax
80108516:	0f 82 67 ff ff ff    	jb     80108483 <allocuvm+0x3c>
      return 0;
    }
    memset(mem, 0, PGSIZE);
    mappages(pgdir, (char*)a, PGSIZE, v2p(mem), PTE_W|PTE_U);
  }
  return newsz;
8010851c:	8b 45 10             	mov    0x10(%ebp),%eax
}
8010851f:	c9                   	leave  
80108520:	c3                   	ret    

80108521 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80108521:	55                   	push   %ebp
80108522:	89 e5                	mov    %esp,%ebp
80108524:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
80108527:	8b 45 10             	mov    0x10(%ebp),%eax
8010852a:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010852d:	72 08                	jb     80108537 <deallocuvm+0x16>
    return oldsz;
8010852f:	8b 45 0c             	mov    0xc(%ebp),%eax
80108532:	e9 a4 00 00 00       	jmp    801085db <deallocuvm+0xba>

  a = PGROUNDUP(newsz);
80108537:	8b 45 10             	mov    0x10(%ebp),%eax
8010853a:	05 ff 0f 00 00       	add    $0xfff,%eax
8010853f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108544:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
80108547:	e9 80 00 00 00       	jmp    801085cc <deallocuvm+0xab>
    pte = walkpgdir(pgdir, (char*)a, 0);
8010854c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010854f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108556:	00 
80108557:	89 44 24 04          	mov    %eax,0x4(%esp)
8010855b:	8b 45 08             	mov    0x8(%ebp),%eax
8010855e:	89 04 24             	mov    %eax,(%esp)
80108561:	e8 e5 f9 ff ff       	call   80107f4b <walkpgdir>
80108566:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108569:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010856d:	75 09                	jne    80108578 <deallocuvm+0x57>
      a += (NPTENTRIES - 1) * PGSIZE;
8010856f:	81 45 f4 00 f0 3f 00 	addl   $0x3ff000,-0xc(%ebp)
80108576:	eb 4d                	jmp    801085c5 <deallocuvm+0xa4>
    else if((*pte & PTE_P) != 0){
80108578:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010857b:	8b 00                	mov    (%eax),%eax
8010857d:	83 e0 01             	and    $0x1,%eax
80108580:	84 c0                	test   %al,%al
80108582:	74 41                	je     801085c5 <deallocuvm+0xa4>
      pa = PTE_ADDR(*pte);
80108584:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108587:	8b 00                	mov    (%eax),%eax
80108589:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010858e:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
80108591:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108595:	75 0c                	jne    801085a3 <deallocuvm+0x82>
        panic("kfree");
80108597:	c7 04 24 45 8f 10 80 	movl   $0x80108f45,(%esp)
8010859e:	e8 9a 7f ff ff       	call   8010053d <panic>
      char *v = p2v(pa);
801085a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801085a6:	89 04 24             	mov    %eax,(%esp)
801085a9:	e8 1a f5 ff ff       	call   80107ac8 <p2v>
801085ae:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
801085b1:	8b 45 e8             	mov    -0x18(%ebp),%eax
801085b4:	89 04 24             	mov    %eax,(%esp)
801085b7:	e8 22 ab ff ff       	call   801030de <kfree>
      *pte = 0;
801085bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801085bf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
801085c5:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801085cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801085cf:	3b 45 0c             	cmp    0xc(%ebp),%eax
801085d2:	0f 82 74 ff ff ff    	jb     8010854c <deallocuvm+0x2b>
      char *v = p2v(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801085d8:	8b 45 10             	mov    0x10(%ebp),%eax
}
801085db:	c9                   	leave  
801085dc:	c3                   	ret    

801085dd <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801085dd:	55                   	push   %ebp
801085de:	89 e5                	mov    %esp,%ebp
801085e0:	83 ec 28             	sub    $0x28,%esp
  uint i;

  if(pgdir == 0)
801085e3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801085e7:	75 0c                	jne    801085f5 <freevm+0x18>
    panic("freevm: no pgdir");
801085e9:	c7 04 24 4b 8f 10 80 	movl   $0x80108f4b,(%esp)
801085f0:	e8 48 7f ff ff       	call   8010053d <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801085f5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801085fc:	00 
801085fd:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
80108604:	80 
80108605:	8b 45 08             	mov    0x8(%ebp),%eax
80108608:	89 04 24             	mov    %eax,(%esp)
8010860b:	e8 11 ff ff ff       	call   80108521 <deallocuvm>
  for(i = 0; i < NPDENTRIES; i++){
80108610:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80108617:	eb 3c                	jmp    80108655 <freevm+0x78>
    if(pgdir[i] & PTE_P){
80108619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010861c:	c1 e0 02             	shl    $0x2,%eax
8010861f:	03 45 08             	add    0x8(%ebp),%eax
80108622:	8b 00                	mov    (%eax),%eax
80108624:	83 e0 01             	and    $0x1,%eax
80108627:	84 c0                	test   %al,%al
80108629:	74 26                	je     80108651 <freevm+0x74>
      char * v = p2v(PTE_ADDR(pgdir[i]));
8010862b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010862e:	c1 e0 02             	shl    $0x2,%eax
80108631:	03 45 08             	add    0x8(%ebp),%eax
80108634:	8b 00                	mov    (%eax),%eax
80108636:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010863b:	89 04 24             	mov    %eax,(%esp)
8010863e:	e8 85 f4 ff ff       	call   80107ac8 <p2v>
80108643:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108646:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108649:	89 04 24             	mov    %eax,(%esp)
8010864c:	e8 8d aa ff ff       	call   801030de <kfree>
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108651:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80108655:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
8010865c:	76 bb                	jbe    80108619 <freevm+0x3c>
    if(pgdir[i] & PTE_P){
      char * v = p2v(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
8010865e:	8b 45 08             	mov    0x8(%ebp),%eax
80108661:	89 04 24             	mov    %eax,(%esp)
80108664:	e8 75 aa ff ff       	call   801030de <kfree>
}
80108669:	c9                   	leave  
8010866a:	c3                   	ret    

8010866b <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
8010866b:	55                   	push   %ebp
8010866c:	89 e5                	mov    %esp,%ebp
8010866e:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108671:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
80108678:	00 
80108679:	8b 45 0c             	mov    0xc(%ebp),%eax
8010867c:	89 44 24 04          	mov    %eax,0x4(%esp)
80108680:	8b 45 08             	mov    0x8(%ebp),%eax
80108683:	89 04 24             	mov    %eax,(%esp)
80108686:	e8 c0 f8 ff ff       	call   80107f4b <walkpgdir>
8010868b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
8010868e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108692:	75 0c                	jne    801086a0 <clearpteu+0x35>
    panic("clearpteu");
80108694:	c7 04 24 5c 8f 10 80 	movl   $0x80108f5c,(%esp)
8010869b:	e8 9d 7e ff ff       	call   8010053d <panic>
  *pte &= ~PTE_U;
801086a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086a3:	8b 00                	mov    (%eax),%eax
801086a5:	89 c2                	mov    %eax,%edx
801086a7:	83 e2 fb             	and    $0xfffffffb,%edx
801086aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086ad:	89 10                	mov    %edx,(%eax)
}
801086af:	c9                   	leave  
801086b0:	c3                   	ret    

801086b1 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
801086b1:	55                   	push   %ebp
801086b2:	89 e5                	mov    %esp,%ebp
801086b4:	83 ec 48             	sub    $0x48,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
801086b7:	e8 b9 f9 ff ff       	call   80108075 <setupkvm>
801086bc:	89 45 f0             	mov    %eax,-0x10(%ebp)
801086bf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801086c3:	75 0a                	jne    801086cf <copyuvm+0x1e>
    return 0;
801086c5:	b8 00 00 00 00       	mov    $0x0,%eax
801086ca:	e9 f1 00 00 00       	jmp    801087c0 <copyuvm+0x10f>
  for(i = 0; i < sz; i += PGSIZE){
801086cf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801086d6:	e9 c0 00 00 00       	jmp    8010879b <copyuvm+0xea>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801086db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801086de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801086e5:	00 
801086e6:	89 44 24 04          	mov    %eax,0x4(%esp)
801086ea:	8b 45 08             	mov    0x8(%ebp),%eax
801086ed:	89 04 24             	mov    %eax,(%esp)
801086f0:	e8 56 f8 ff ff       	call   80107f4b <walkpgdir>
801086f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
801086f8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801086fc:	75 0c                	jne    8010870a <copyuvm+0x59>
      panic("copyuvm: pte should exist");
801086fe:	c7 04 24 66 8f 10 80 	movl   $0x80108f66,(%esp)
80108705:	e8 33 7e ff ff       	call   8010053d <panic>
    if(!(*pte & PTE_P))
8010870a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010870d:	8b 00                	mov    (%eax),%eax
8010870f:	83 e0 01             	and    $0x1,%eax
80108712:	85 c0                	test   %eax,%eax
80108714:	75 0c                	jne    80108722 <copyuvm+0x71>
      panic("copyuvm: page not present");
80108716:	c7 04 24 80 8f 10 80 	movl   $0x80108f80,(%esp)
8010871d:	e8 1b 7e ff ff       	call   8010053d <panic>
    pa = PTE_ADDR(*pte);
80108722:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108725:	8b 00                	mov    (%eax),%eax
80108727:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010872c:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if((mem = kalloc()) == 0)
8010872f:	e8 43 aa ff ff       	call   80103177 <kalloc>
80108734:	89 45 e4             	mov    %eax,-0x1c(%ebp)
80108737:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010873b:	74 6f                	je     801087ac <copyuvm+0xfb>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
8010873d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108740:	89 04 24             	mov    %eax,(%esp)
80108743:	e8 80 f3 ff ff       	call   80107ac8 <p2v>
80108748:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
8010874f:	00 
80108750:	89 44 24 04          	mov    %eax,0x4(%esp)
80108754:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108757:	89 04 24             	mov    %eax,(%esp)
8010875a:	e8 de cd ff ff       	call   8010553d <memmove>
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
8010875f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80108762:	89 04 24             	mov    %eax,(%esp)
80108765:	e8 51 f3 ff ff       	call   80107abb <v2p>
8010876a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010876d:	c7 44 24 10 06 00 00 	movl   $0x6,0x10(%esp)
80108774:	00 
80108775:	89 44 24 0c          	mov    %eax,0xc(%esp)
80108779:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
80108780:	00 
80108781:	89 54 24 04          	mov    %edx,0x4(%esp)
80108785:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108788:	89 04 24             	mov    %eax,(%esp)
8010878b:	e8 51 f8 ff ff       	call   80107fe1 <mappages>
80108790:	85 c0                	test   %eax,%eax
80108792:	78 1b                	js     801087af <copyuvm+0xfe>
  uint pa, i;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
80108794:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010879b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010879e:	3b 45 0c             	cmp    0xc(%ebp),%eax
801087a1:	0f 82 34 ff ff ff    	jb     801086db <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
  }
  return d;
801087a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087aa:	eb 14                	jmp    801087c0 <copyuvm+0x10f>
      panic("copyuvm: pte should exist");
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
801087ac:	90                   	nop
801087ad:	eb 01                	jmp    801087b0 <copyuvm+0xff>
    memmove(mem, (char*)p2v(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, v2p(mem), PTE_W|PTE_U) < 0)
      goto bad;
801087af:	90                   	nop
  }
  return d;

bad:
  freevm(d);
801087b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801087b3:	89 04 24             	mov    %eax,(%esp)
801087b6:	e8 22 fe ff ff       	call   801085dd <freevm>
  return 0;
801087bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
801087c0:	c9                   	leave  
801087c1:	c3                   	ret    

801087c2 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
801087c2:	55                   	push   %ebp
801087c3:	89 e5                	mov    %esp,%ebp
801087c5:	83 ec 28             	sub    $0x28,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
801087c8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
801087cf:	00 
801087d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801087d3:	89 44 24 04          	mov    %eax,0x4(%esp)
801087d7:	8b 45 08             	mov    0x8(%ebp),%eax
801087da:	89 04 24             	mov    %eax,(%esp)
801087dd:	e8 69 f7 ff ff       	call   80107f4b <walkpgdir>
801087e2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801087e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087e8:	8b 00                	mov    (%eax),%eax
801087ea:	83 e0 01             	and    $0x1,%eax
801087ed:	85 c0                	test   %eax,%eax
801087ef:	75 07                	jne    801087f8 <uva2ka+0x36>
    return 0;
801087f1:	b8 00 00 00 00       	mov    $0x0,%eax
801087f6:	eb 25                	jmp    8010881d <uva2ka+0x5b>
  if((*pte & PTE_U) == 0)
801087f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801087fb:	8b 00                	mov    (%eax),%eax
801087fd:	83 e0 04             	and    $0x4,%eax
80108800:	85 c0                	test   %eax,%eax
80108802:	75 07                	jne    8010880b <uva2ka+0x49>
    return 0;
80108804:	b8 00 00 00 00       	mov    $0x0,%eax
80108809:	eb 12                	jmp    8010881d <uva2ka+0x5b>
  return (char*)p2v(PTE_ADDR(*pte));
8010880b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010880e:	8b 00                	mov    (%eax),%eax
80108810:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108815:	89 04 24             	mov    %eax,(%esp)
80108818:	e8 ab f2 ff ff       	call   80107ac8 <p2v>
}
8010881d:	c9                   	leave  
8010881e:	c3                   	ret    

8010881f <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
8010881f:	55                   	push   %ebp
80108820:	89 e5                	mov    %esp,%ebp
80108822:	83 ec 28             	sub    $0x28,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
80108825:	8b 45 10             	mov    0x10(%ebp),%eax
80108828:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
8010882b:	e9 8b 00 00 00       	jmp    801088bb <copyout+0x9c>
    va0 = (uint)PGROUNDDOWN(va);
80108830:	8b 45 0c             	mov    0xc(%ebp),%eax
80108833:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108838:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
8010883b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010883e:	89 44 24 04          	mov    %eax,0x4(%esp)
80108842:	8b 45 08             	mov    0x8(%ebp),%eax
80108845:	89 04 24             	mov    %eax,(%esp)
80108848:	e8 75 ff ff ff       	call   801087c2 <uva2ka>
8010884d:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108850:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108854:	75 07                	jne    8010885d <copyout+0x3e>
      return -1;
80108856:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010885b:	eb 6d                	jmp    801088ca <copyout+0xab>
    n = PGSIZE - (va - va0);
8010885d:	8b 45 0c             	mov    0xc(%ebp),%eax
80108860:	8b 55 ec             	mov    -0x14(%ebp),%edx
80108863:	89 d1                	mov    %edx,%ecx
80108865:	29 c1                	sub    %eax,%ecx
80108867:	89 c8                	mov    %ecx,%eax
80108869:	05 00 10 00 00       	add    $0x1000,%eax
8010886e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
80108871:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108874:	3b 45 14             	cmp    0x14(%ebp),%eax
80108877:	76 06                	jbe    8010887f <copyout+0x60>
      n = len;
80108879:	8b 45 14             	mov    0x14(%ebp),%eax
8010887c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010887f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108882:	8b 55 0c             	mov    0xc(%ebp),%edx
80108885:	89 d1                	mov    %edx,%ecx
80108887:	29 c1                	sub    %eax,%ecx
80108889:	89 c8                	mov    %ecx,%eax
8010888b:	03 45 e8             	add    -0x18(%ebp),%eax
8010888e:	8b 55 f0             	mov    -0x10(%ebp),%edx
80108891:	89 54 24 08          	mov    %edx,0x8(%esp)
80108895:	8b 55 f4             	mov    -0xc(%ebp),%edx
80108898:	89 54 24 04          	mov    %edx,0x4(%esp)
8010889c:	89 04 24             	mov    %eax,(%esp)
8010889f:	e8 99 cc ff ff       	call   8010553d <memmove>
    len -= n;
801088a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088a7:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
801088aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
801088ad:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
801088b0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801088b3:	05 00 10 00 00       	add    $0x1000,%eax
801088b8:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
801088bb:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801088bf:	0f 85 6b ff ff ff    	jne    80108830 <copyout+0x11>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
801088c5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801088ca:	c9                   	leave  
801088cb:	c3                   	ret    
