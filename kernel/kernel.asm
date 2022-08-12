
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	dc478793          	addi	a5,a5,-572 # 80005e20 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	59c080e7          	jalr	1436(ra) # 800026c2 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	914080e7          	jalr	-1772(ra) # 80001ae2 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	22c080e7          	jalr	556(ra) # 8000240a <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	452080e7          	jalr	1106(ra) # 8000266c <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	41c080e7          	jalr	1052(ra) # 80002718 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	140080e7          	jalr	320(ra) # 80002590 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	b9e58593          	addi	a1,a1,-1122 # 80008000 <etext>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b6c60613          	addi	a2,a2,-1172 # 80008030 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	aac50513          	addi	a0,a0,-1364 # 80008008 <etext+0x8>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b4250513          	addi	a0,a0,-1214 # 800080b8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a40b8b93          	addi	s7,s7,-1472 # 80008030 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a0450513          	addi	a0,a0,-1532 # 80008018 <etext+0x18>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	8fc90913          	addi	s2,s2,-1796 # 80008010 <etext+0x10>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	89e58593          	addi	a1,a1,-1890 # 80008028 <etext+0x28>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	86e58593          	addi	a1,a1,-1938 # 80008048 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	cda080e7          	jalr	-806(ra) # 80002590 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	aba080e7          	jalr	-1350(ra) # 8000240a <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5c650513          	addi	a0,a0,1478 # 80008050 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	56c58593          	addi	a1,a1,1388 # 80008058 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	f1c080e7          	jalr	-228(ra) # 80001ac6 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	eea080e7          	jalr	-278(ra) # 80001ac6 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	ede080e7          	jalr	-290(ra) # 80001ac6 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	ec6080e7          	jalr	-314(ra) # 80001ac6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e86080e7          	jalr	-378(ra) # 80001ac6 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	40c50513          	addi	a0,a0,1036 # 80008060 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	e5a080e7          	jalr	-422(ra) # 80001ac6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3c450513          	addi	a0,a0,964 # 80008068 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3cc50513          	addi	a0,a0,972 # 80008080 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	38c50513          	addi	a0,a0,908 # 80008088 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	bf0080e7          	jalr	-1040(ra) # 80001ab6 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	bd4080e7          	jalr	-1068(ra) # 80001ab6 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1bc50513          	addi	a0,a0,444 # 800080a8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	954080e7          	jalr	-1708(ra) # 80002858 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	f54080e7          	jalr	-172(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	1fe080e7          	jalr	510(ra) # 80002112 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00005097          	auipc	ra,0x5
    80000f28:	70a080e7          	jalr	1802(ra) # 8000662e <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	18450513          	addi	a0,a0,388 # 800080b8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	14c50513          	addi	a0,a0,332 # 80008090 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	16450513          	addi	a0,a0,356 # 800080b8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	35c080e7          	jalr	860(ra) # 800012c8 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	ad2080e7          	jalr	-1326(ra) # 80001a4e <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	8ac080e7          	jalr	-1876(ra) # 80002830 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	8cc080e7          	jalr	-1844(ra) # 80002858 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	eb6080e7          	jalr	-330(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	ec4080e7          	jalr	-316(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	ff6080e7          	jalr	-10(ra) # 80002f9a <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	686080e7          	jalr	1670(ra) # 80003632 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	620080e7          	jalr	1568(ra) # 800045d4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	fac080e7          	jalr	-84(ra) # 80005f68 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	e5a080e7          	jalr	-422(ra) # 80001e1e <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	09a50513          	addi	a0,a0,154 # 800080c0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(pagetable_t pgt, uint64 va)
{
    800010a6:	1101                	addi	sp,sp,-32
    800010a8:	ec06                	sd	ra,24(sp)
    800010aa:	e822                	sd	s0,16(sp)
    800010ac:	e426                	sd	s1,8(sp)
    800010ae:	1000                	addi	s0,sp,32
  uint64 off = va % PGSIZE;
    800010b0:	03459793          	slli	a5,a1,0x34
    800010b4:	0347d493          	srli	s1,a5,0x34
  pte_t *pte;
  uint64 pa;

  pte = walk(pgt, va, 0);
    800010b8:	4601                	li	a2,0
    800010ba:	00000097          	auipc	ra,0x0
    800010be:	f46080e7          	jalr	-186(ra) # 80001000 <walk>
  if(pte == 0)
    800010c2:	cd09                	beqz	a0,800010dc <kvmpa+0x36>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010c4:	6108                	ld	a0,0(a0)
    800010c6:	00157793          	andi	a5,a0,1
    800010ca:	c38d                	beqz	a5,800010ec <kvmpa+0x46>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010cc:	8129                	srli	a0,a0,0xa
    800010ce:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010d0:	9526                	add	a0,a0,s1
    800010d2:	60e2                	ld	ra,24(sp)
    800010d4:	6442                	ld	s0,16(sp)
    800010d6:	64a2                	ld	s1,8(sp)
    800010d8:	6105                	addi	sp,sp,32
    800010da:	8082                	ret
    panic("kvmpa");
    800010dc:	00007517          	auipc	a0,0x7
    800010e0:	fec50513          	addi	a0,a0,-20 # 800080c8 <digits+0x98>
    800010e4:	fffff097          	auipc	ra,0xfffff
    800010e8:	464080e7          	jalr	1124(ra) # 80000548 <panic>
    panic("kvmpa");
    800010ec:	00007517          	auipc	a0,0x7
    800010f0:	fdc50513          	addi	a0,a0,-36 # 800080c8 <digits+0x98>
    800010f4:	fffff097          	auipc	ra,0xfffff
    800010f8:	454080e7          	jalr	1108(ra) # 80000548 <panic>

00000000800010fc <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010fc:	57fd                	li	a5,-1
    800010fe:	83e9                	srli	a5,a5,0x1a
    80001100:	00b7f463          	bgeu	a5,a1,80001108 <walkaddr+0xc>
    return 0;
    80001104:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001106:	8082                	ret
{
    80001108:	1141                	addi	sp,sp,-16
    8000110a:	e406                	sd	ra,8(sp)
    8000110c:	e022                	sd	s0,0(sp)
    8000110e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001110:	4601                	li	a2,0
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eee080e7          	jalr	-274(ra) # 80001000 <walk>
  if(pte == 0)
    8000111a:	c105                	beqz	a0,8000113a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000111c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000111e:	0117f693          	andi	a3,a5,17
    80001122:	4745                	li	a4,17
    return 0;
    80001124:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001126:	00e68663          	beq	a3,a4,80001132 <walkaddr+0x36>
}
    8000112a:	60a2                	ld	ra,8(sp)
    8000112c:	6402                	ld	s0,0(sp)
    8000112e:	0141                	addi	sp,sp,16
    80001130:	8082                	ret
  pa = PTE2PA(*pte);
    80001132:	00a7d513          	srli	a0,a5,0xa
    80001136:	0532                	slli	a0,a0,0xc
  return pa;
    80001138:	bfcd                	j	8000112a <walkaddr+0x2e>
    return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7fd                	j	8000112a <walkaddr+0x2e>

000000008000113e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000113e:	715d                	addi	sp,sp,-80
    80001140:	e486                	sd	ra,72(sp)
    80001142:	e0a2                	sd	s0,64(sp)
    80001144:	fc26                	sd	s1,56(sp)
    80001146:	f84a                	sd	s2,48(sp)
    80001148:	f44e                	sd	s3,40(sp)
    8000114a:	f052                	sd	s4,32(sp)
    8000114c:	ec56                	sd	s5,24(sp)
    8000114e:	e85a                	sd	s6,16(sp)
    80001150:	e45e                	sd	s7,8(sp)
    80001152:	0880                	addi	s0,sp,80
    80001154:	8aaa                	mv	s5,a0
    80001156:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001158:	777d                	lui	a4,0xfffff
    8000115a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000115e:	167d                	addi	a2,a2,-1
    80001160:	00b609b3          	add	s3,a2,a1
    80001164:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001168:	893e                	mv	s2,a5
    8000116a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000116e:	6b85                	lui	s7,0x1
    80001170:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001174:	4605                	li	a2,1
    80001176:	85ca                	mv	a1,s2
    80001178:	8556                	mv	a0,s5
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	e86080e7          	jalr	-378(ra) # 80001000 <walk>
    80001182:	c51d                	beqz	a0,800011b0 <mappages+0x72>
    if(*pte & PTE_V)
    80001184:	611c                	ld	a5,0(a0)
    80001186:	8b85                	andi	a5,a5,1
    80001188:	ef81                	bnez	a5,800011a0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118a:	80b1                	srli	s1,s1,0xc
    8000118c:	04aa                	slli	s1,s1,0xa
    8000118e:	0164e4b3          	or	s1,s1,s6
    80001192:	0014e493          	ori	s1,s1,1
    80001196:	e104                	sd	s1,0(a0)
    if(a == last)
    80001198:	03390863          	beq	s2,s3,800011c8 <mappages+0x8a>
    a += PGSIZE;
    8000119c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	bfc9                	j	80001170 <mappages+0x32>
      panic("remap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f3050513          	addi	a0,a0,-208 # 800080d0 <digits+0xa0>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x74>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	87b6                	mv	a5,a3
  if(mappages(pgt, va, sz, pa, perm) != 0)//logic address to pyhsics 
    800011d6:	86b2                	mv	a3,a2
    800011d8:	863e                	mv	a2,a5
    800011da:	00000097          	auipc	ra,0x0
    800011de:	f64080e7          	jalr	-156(ra) # 8000113e <mappages>
    800011e2:	e509                	bnez	a0,800011ec <kvmmap+0x20>
}
    800011e4:	60a2                	ld	ra,8(sp)
    800011e6:	6402                	ld	s0,0(sp)
    800011e8:	0141                	addi	sp,sp,16
    800011ea:	8082                	ret
    panic("kvmmap");
    800011ec:	00007517          	auipc	a0,0x7
    800011f0:	eec50513          	addi	a0,a0,-276 # 800080d8 <digits+0xa8>
    800011f4:	fffff097          	auipc	ra,0xfffff
    800011f8:	354080e7          	jalr	852(ra) # 80000548 <panic>

00000000800011fc <kvminit_newpgt>:
{
    800011fc:	1101                	addi	sp,sp,-32
    800011fe:	ec06                	sd	ra,24(sp)
    80001200:	e822                	sd	s0,16(sp)
    80001202:	e426                	sd	s1,8(sp)
    80001204:	e04a                	sd	s2,0(sp)
    80001206:	1000                	addi	s0,sp,32
  pagetable_t pgt = (pagetable_t) kalloc();
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	918080e7          	jalr	-1768(ra) # 80000b20 <kalloc>
    80001210:	84aa                	mv	s1,a0
  memset(pgt, 0, PGSIZE);
    80001212:	6605                	lui	a2,0x1
    80001214:	4581                	li	a1,0
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	af6080e7          	jalr	-1290(ra) # 80000d0c <memset>
  kvmmap(pgt,UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10000637          	lui	a2,0x10000
    80001226:	100005b7          	lui	a1,0x10000
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	fa0080e7          	jalr	-96(ra) # 800011cc <kvmmap>
  kvmmap(pgt,VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	6685                	lui	a3,0x1
    80001238:	10001637          	lui	a2,0x10001
    8000123c:	100015b7          	lui	a1,0x10001
    80001240:	8526                	mv	a0,s1
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f8a080e7          	jalr	-118(ra) # 800011cc <kvmmap>
  kvmmap(pgt,PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000124a:	4719                	li	a4,6
    8000124c:	004006b7          	lui	a3,0x400
    80001250:	0c000637          	lui	a2,0xc000
    80001254:	0c0005b7          	lui	a1,0xc000
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f72080e7          	jalr	-142(ra) # 800011cc <kvmmap>
  kvmmap(pgt,KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001262:	00007917          	auipc	s2,0x7
    80001266:	d9e90913          	addi	s2,s2,-610 # 80008000 <etext>
    8000126a:	4729                	li	a4,10
    8000126c:	80007697          	auipc	a3,0x80007
    80001270:	d9468693          	addi	a3,a3,-620 # 8000 <_entry-0x7fff8000>
    80001274:	4605                	li	a2,1
    80001276:	067e                	slli	a2,a2,0x1f
    80001278:	85b2                	mv	a1,a2
    8000127a:	8526                	mv	a0,s1
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f50080e7          	jalr	-176(ra) # 800011cc <kvmmap>
  kvmmap(pgt,(uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001284:	4719                	li	a4,6
    80001286:	46c5                	li	a3,17
    80001288:	06ee                	slli	a3,a3,0x1b
    8000128a:	412686b3          	sub	a3,a3,s2
    8000128e:	864a                	mv	a2,s2
    80001290:	85ca                	mv	a1,s2
    80001292:	8526                	mv	a0,s1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f38080e7          	jalr	-200(ra) # 800011cc <kvmmap>
  kvmmap(pgt,TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000129c:	4729                	li	a4,10
    8000129e:	6685                	lui	a3,0x1
    800012a0:	00006617          	auipc	a2,0x6
    800012a4:	d6060613          	addi	a2,a2,-672 # 80007000 <_trampoline>
    800012a8:	040005b7          	lui	a1,0x4000
    800012ac:	15fd                	addi	a1,a1,-1
    800012ae:	05b2                	slli	a1,a1,0xc
    800012b0:	8526                	mv	a0,s1
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	f1a080e7          	jalr	-230(ra) # 800011cc <kvmmap>
}
    800012ba:	8526                	mv	a0,s1
    800012bc:	60e2                	ld	ra,24(sp)
    800012be:	6442                	ld	s0,16(sp)
    800012c0:	64a2                	ld	s1,8(sp)
    800012c2:	6902                	ld	s2,0(sp)
    800012c4:	6105                	addi	sp,sp,32
    800012c6:	8082                	ret

00000000800012c8 <kvminit>:
{
    800012c8:	1141                	addi	sp,sp,-16
    800012ca:	e406                	sd	ra,8(sp)
    800012cc:	e022                	sd	s0,0(sp)
    800012ce:	0800                	addi	s0,sp,16
  kernel_pagetable = kvminit_newpgt();
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f2c080e7          	jalr	-212(ra) # 800011fc <kvminit_newpgt>
    800012d8:	00008797          	auipc	a5,0x8
    800012dc:	d2a7bc23          	sd	a0,-712(a5) # 80009010 <kernel_pagetable>
  kvmmap(kernel_pagetable,CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012e0:	4719                	li	a4,6
    800012e2:	66c1                	lui	a3,0x10
    800012e4:	02000637          	lui	a2,0x2000
    800012e8:	020005b7          	lui	a1,0x2000
    800012ec:	00000097          	auipc	ra,0x0
    800012f0:	ee0080e7          	jalr	-288(ra) # 800011cc <kvmmap>
}
    800012f4:	60a2                	ld	ra,8(sp)
    800012f6:	6402                	ld	s0,0(sp)
    800012f8:	0141                	addi	sp,sp,16
    800012fa:	8082                	ret

00000000800012fc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012fc:	715d                	addi	sp,sp,-80
    800012fe:	e486                	sd	ra,72(sp)
    80001300:	e0a2                	sd	s0,64(sp)
    80001302:	fc26                	sd	s1,56(sp)
    80001304:	f84a                	sd	s2,48(sp)
    80001306:	f44e                	sd	s3,40(sp)
    80001308:	f052                	sd	s4,32(sp)
    8000130a:	ec56                	sd	s5,24(sp)
    8000130c:	e85a                	sd	s6,16(sp)
    8000130e:	e45e                	sd	s7,8(sp)
    80001310:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001312:	03459793          	slli	a5,a1,0x34
    80001316:	e795                	bnez	a5,80001342 <uvmunmap+0x46>
    80001318:	8a2a                	mv	s4,a0
    8000131a:	892e                	mv	s2,a1
    8000131c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131e:	0632                	slli	a2,a2,0xc
    80001320:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001324:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001326:	6b05                	lui	s6,0x1
    80001328:	0735e863          	bltu	a1,s3,80001398 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000132c:	60a6                	ld	ra,72(sp)
    8000132e:	6406                	ld	s0,64(sp)
    80001330:	74e2                	ld	s1,56(sp)
    80001332:	7942                	ld	s2,48(sp)
    80001334:	79a2                	ld	s3,40(sp)
    80001336:	7a02                	ld	s4,32(sp)
    80001338:	6ae2                	ld	s5,24(sp)
    8000133a:	6b42                	ld	s6,16(sp)
    8000133c:	6ba2                	ld	s7,8(sp)
    8000133e:	6161                	addi	sp,sp,80
    80001340:	8082                	ret
    panic("uvmunmap: not aligned");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	d9e50513          	addi	a0,a0,-610 # 800080e0 <digits+0xb0>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1fe080e7          	jalr	510(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	da650513          	addi	a0,a0,-602 # 800080f8 <digits+0xc8>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1ee080e7          	jalr	494(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001362:	00007517          	auipc	a0,0x7
    80001366:	da650513          	addi	a0,a0,-602 # 80008108 <digits+0xd8>
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	1de080e7          	jalr	478(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	dae50513          	addi	a0,a0,-594 # 80008120 <digits+0xf0>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1ce080e7          	jalr	462(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001382:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001384:	0532                	slli	a0,a0,0xc
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	69e080e7          	jalr	1694(ra) # 80000a24 <kfree>
    *pte = 0;
    8000138e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001392:	995a                	add	s2,s2,s6
    80001394:	f9397ce3          	bgeu	s2,s3,8000132c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001398:	4601                	li	a2,0
    8000139a:	85ca                	mv	a1,s2
    8000139c:	8552                	mv	a0,s4
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	c62080e7          	jalr	-926(ra) # 80001000 <walk>
    800013a6:	84aa                	mv	s1,a0
    800013a8:	d54d                	beqz	a0,80001352 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013aa:	6108                	ld	a0,0(a0)
    800013ac:	00157793          	andi	a5,a0,1
    800013b0:	dbcd                	beqz	a5,80001362 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013b2:	3ff57793          	andi	a5,a0,1023
    800013b6:	fb778ee3          	beq	a5,s7,80001372 <uvmunmap+0x76>
    if(do_free){
    800013ba:	fc0a8ae3          	beqz	s5,8000138e <uvmunmap+0x92>
    800013be:	b7d1                	j	80001382 <uvmunmap+0x86>

00000000800013c0 <kvmcopy>:



int
kvmcopy(pagetable_t old, pagetable_t new, uint64 start, uint64 sz)
{
    800013c0:	7139                	addi	sp,sp,-64
    800013c2:	fc06                	sd	ra,56(sp)
    800013c4:	f822                	sd	s0,48(sp)
    800013c6:	f426                	sd	s1,40(sp)
    800013c8:	f04a                	sd	s2,32(sp)
    800013ca:	ec4e                	sd	s3,24(sp)
    800013cc:	e852                	sd	s4,16(sp)
    800013ce:	e456                	sd	s5,8(sp)
    800013d0:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = PGROUNDUP(start); i < start + sz; i += PGSIZE)
    800013d2:	6a05                	lui	s4,0x1
    800013d4:	1a7d                	addi	s4,s4,-1
    800013d6:	9a32                	add	s4,s4,a2
    800013d8:	77fd                	lui	a5,0xfffff
    800013da:	00fa7a33          	and	s4,s4,a5
    800013de:	00d60933          	add	s2,a2,a3
    800013e2:	092a7763          	bgeu	s4,s2,80001470 <kvmcopy+0xb0>
    800013e6:	8aaa                	mv	s5,a0
    800013e8:	89ae                	mv	s3,a1
    800013ea:	84d2                	mv	s1,s4
  {
    if((pte = walk(old, i, 0)) == 0)
    800013ec:	4601                	li	a2,0
    800013ee:	85a6                	mv	a1,s1
    800013f0:	8556                	mv	a0,s5
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	c0e080e7          	jalr	-1010(ra) # 80001000 <walk>
    800013fa:	c51d                	beqz	a0,80001428 <kvmcopy+0x68>
      panic("kvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800013fc:	6118                	ld	a4,0(a0)
    800013fe:	00177793          	andi	a5,a4,1
    80001402:	cb9d                	beqz	a5,80001438 <kvmcopy+0x78>
      panic("kvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001404:	00a75693          	srli	a3,a4,0xa
    flags = PTE_FLAGS(*pte) & ~PTE_U;//set to no user 
   
    if(mappages(new, i, PGSIZE, pa, flags) != 0)
    80001408:	3ef77713          	andi	a4,a4,1007
    8000140c:	06b2                	slli	a3,a3,0xc
    8000140e:	6605                	lui	a2,0x1
    80001410:	85a6                	mv	a1,s1
    80001412:	854e                	mv	a0,s3
    80001414:	00000097          	auipc	ra,0x0
    80001418:	d2a080e7          	jalr	-726(ra) # 8000113e <mappages>
    8000141c:	e515                	bnez	a0,80001448 <kvmcopy+0x88>
  for(i = PGROUNDUP(start); i < start + sz; i += PGSIZE)
    8000141e:	6785                	lui	a5,0x1
    80001420:	94be                	add	s1,s1,a5
    80001422:	fd24e5e3          	bltu	s1,s2,800013ec <kvmcopy+0x2c>
    80001426:	a825                	j	8000145e <kvmcopy+0x9e>
      panic("kvmcopy: pte should exist");
    80001428:	00007517          	auipc	a0,0x7
    8000142c:	d1050513          	addi	a0,a0,-752 # 80008138 <digits+0x108>
    80001430:	fffff097          	auipc	ra,0xfffff
    80001434:	118080e7          	jalr	280(ra) # 80000548 <panic>
      panic("kvmcopy: page not present");
    80001438:	00007517          	auipc	a0,0x7
    8000143c:	d2050513          	addi	a0,a0,-736 # 80008158 <digits+0x128>
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	108080e7          	jalr	264(ra) # 80000548 <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, PGROUNDUP(start), (i - PGROUNDUP(start)) / PGSIZE, 0);
    80001448:	41448633          	sub	a2,s1,s4
    8000144c:	4681                	li	a3,0
    8000144e:	8231                	srli	a2,a2,0xc
    80001450:	85d2                	mv	a1,s4
    80001452:	854e                	mv	a0,s3
    80001454:	00000097          	auipc	ra,0x0
    80001458:	ea8080e7          	jalr	-344(ra) # 800012fc <uvmunmap>
  return -1;
    8000145c:	557d                	li	a0,-1
}
    8000145e:	70e2                	ld	ra,56(sp)
    80001460:	7442                	ld	s0,48(sp)
    80001462:	74a2                	ld	s1,40(sp)
    80001464:	7902                	ld	s2,32(sp)
    80001466:	69e2                	ld	s3,24(sp)
    80001468:	6a42                	ld	s4,16(sp)
    8000146a:	6aa2                	ld	s5,8(sp)
    8000146c:	6121                	addi	sp,sp,64
    8000146e:	8082                	ret
  return 0;
    80001470:	4501                	li	a0,0
    80001472:	b7f5                	j	8000145e <kvmcopy+0x9e>

0000000080001474 <kvmdealloc>:

uint64
kvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001474:	1101                	addi	sp,sp,-32
    80001476:	ec06                	sd	ra,24(sp)
    80001478:	e822                	sd	s0,16(sp)
    8000147a:	e426                	sd	s1,8(sp)
    8000147c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000147e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001480:	00b67d63          	bgeu	a2,a1,8000149a <kvmdealloc+0x26>
    80001484:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001486:	6785                	lui	a5,0x1
    80001488:	17fd                	addi	a5,a5,-1
    8000148a:	00f60733          	add	a4,a2,a5
    8000148e:	767d                	lui	a2,0xfffff
    80001490:	8f71                	and	a4,a4,a2
    80001492:	97ae                	add	a5,a5,a1
    80001494:	8ff1                	and	a5,a5,a2
    80001496:	00f76863          	bltu	a4,a5,800014a6 <kvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);//no release  memory
  }

  return newsz;
}
    8000149a:	8526                	mv	a0,s1
    8000149c:	60e2                	ld	ra,24(sp)
    8000149e:	6442                	ld	s0,16(sp)
    800014a0:	64a2                	ld	s1,8(sp)
    800014a2:	6105                	addi	sp,sp,32
    800014a4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014a6:	8f99                	sub	a5,a5,a4
    800014a8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);//no release  memory
    800014aa:	4681                	li	a3,0
    800014ac:	0007861b          	sext.w	a2,a5
    800014b0:	85ba                	mv	a1,a4
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	e4a080e7          	jalr	-438(ra) # 800012fc <uvmunmap>
    800014ba:	b7c5                	j	8000149a <kvmdealloc+0x26>

00000000800014bc <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014bc:	1101                	addi	sp,sp,-32
    800014be:	ec06                	sd	ra,24(sp)
    800014c0:	e822                	sd	s0,16(sp)
    800014c2:	e426                	sd	s1,8(sp)
    800014c4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014c6:	fffff097          	auipc	ra,0xfffff
    800014ca:	65a080e7          	jalr	1626(ra) # 80000b20 <kalloc>
    800014ce:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014d0:	c519                	beqz	a0,800014de <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014d2:	6605                	lui	a2,0x1
    800014d4:	4581                	li	a1,0
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	836080e7          	jalr	-1994(ra) # 80000d0c <memset>
  return pagetable;
}
    800014de:	8526                	mv	a0,s1
    800014e0:	60e2                	ld	ra,24(sp)
    800014e2:	6442                	ld	s0,16(sp)
    800014e4:	64a2                	ld	s1,8(sp)
    800014e6:	6105                	addi	sp,sp,32
    800014e8:	8082                	ret

00000000800014ea <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014ea:	7179                	addi	sp,sp,-48
    800014ec:	f406                	sd	ra,40(sp)
    800014ee:	f022                	sd	s0,32(sp)
    800014f0:	ec26                	sd	s1,24(sp)
    800014f2:	e84a                	sd	s2,16(sp)
    800014f4:	e44e                	sd	s3,8(sp)
    800014f6:	e052                	sd	s4,0(sp)
    800014f8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014fa:	6785                	lui	a5,0x1
    800014fc:	04f67863          	bgeu	a2,a5,8000154c <uvminit+0x62>
    80001500:	8a2a                	mv	s4,a0
    80001502:	89ae                	mv	s3,a1
    80001504:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	61a080e7          	jalr	1562(ra) # 80000b20 <kalloc>
    8000150e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001510:	6605                	lui	a2,0x1
    80001512:	4581                	li	a1,0
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	7f8080e7          	jalr	2040(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000151c:	4779                	li	a4,30
    8000151e:	86ca                	mv	a3,s2
    80001520:	6605                	lui	a2,0x1
    80001522:	4581                	li	a1,0
    80001524:	8552                	mv	a0,s4
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	c18080e7          	jalr	-1000(ra) # 8000113e <mappages>
  memmove(mem, src, sz);
    8000152e:	8626                	mv	a2,s1
    80001530:	85ce                	mv	a1,s3
    80001532:	854a                	mv	a0,s2
    80001534:	00000097          	auipc	ra,0x0
    80001538:	838080e7          	jalr	-1992(ra) # 80000d6c <memmove>
}
    8000153c:	70a2                	ld	ra,40(sp)
    8000153e:	7402                	ld	s0,32(sp)
    80001540:	64e2                	ld	s1,24(sp)
    80001542:	6942                	ld	s2,16(sp)
    80001544:	69a2                	ld	s3,8(sp)
    80001546:	6a02                	ld	s4,0(sp)
    80001548:	6145                	addi	sp,sp,48
    8000154a:	8082                	ret
    panic("inituvm: more than a page");
    8000154c:	00007517          	auipc	a0,0x7
    80001550:	c2c50513          	addi	a0,a0,-980 # 80008178 <digits+0x148>
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	ff4080e7          	jalr	-12(ra) # 80000548 <panic>

000000008000155c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000155c:	1101                	addi	sp,sp,-32
    8000155e:	ec06                	sd	ra,24(sp)
    80001560:	e822                	sd	s0,16(sp)
    80001562:	e426                	sd	s1,8(sp)
    80001564:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001566:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001568:	00b67d63          	bgeu	a2,a1,80001582 <uvmdealloc+0x26>
    8000156c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000156e:	6785                	lui	a5,0x1
    80001570:	17fd                	addi	a5,a5,-1
    80001572:	00f60733          	add	a4,a2,a5
    80001576:	767d                	lui	a2,0xfffff
    80001578:	8f71                	and	a4,a4,a2
    8000157a:	97ae                	add	a5,a5,a1
    8000157c:	8ff1                	and	a5,a5,a2
    8000157e:	00f76863          	bltu	a4,a5,8000158e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001582:	8526                	mv	a0,s1
    80001584:	60e2                	ld	ra,24(sp)
    80001586:	6442                	ld	s0,16(sp)
    80001588:	64a2                	ld	s1,8(sp)
    8000158a:	6105                	addi	sp,sp,32
    8000158c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000158e:	8f99                	sub	a5,a5,a4
    80001590:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001592:	4685                	li	a3,1
    80001594:	0007861b          	sext.w	a2,a5
    80001598:	85ba                	mv	a1,a4
    8000159a:	00000097          	auipc	ra,0x0
    8000159e:	d62080e7          	jalr	-670(ra) # 800012fc <uvmunmap>
    800015a2:	b7c5                	j	80001582 <uvmdealloc+0x26>

00000000800015a4 <uvmalloc>:
  if(newsz < oldsz)
    800015a4:	0ab66163          	bltu	a2,a1,80001646 <uvmalloc+0xa2>
{
    800015a8:	7139                	addi	sp,sp,-64
    800015aa:	fc06                	sd	ra,56(sp)
    800015ac:	f822                	sd	s0,48(sp)
    800015ae:	f426                	sd	s1,40(sp)
    800015b0:	f04a                	sd	s2,32(sp)
    800015b2:	ec4e                	sd	s3,24(sp)
    800015b4:	e852                	sd	s4,16(sp)
    800015b6:	e456                	sd	s5,8(sp)
    800015b8:	0080                	addi	s0,sp,64
    800015ba:	8aaa                	mv	s5,a0
    800015bc:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015be:	6985                	lui	s3,0x1
    800015c0:	19fd                	addi	s3,s3,-1
    800015c2:	95ce                	add	a1,a1,s3
    800015c4:	79fd                	lui	s3,0xfffff
    800015c6:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015ca:	08c9f063          	bgeu	s3,a2,8000164a <uvmalloc+0xa6>
    800015ce:	894e                	mv	s2,s3
    mem = kalloc();
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	550080e7          	jalr	1360(ra) # 80000b20 <kalloc>
    800015d8:	84aa                	mv	s1,a0
    if(mem == 0){
    800015da:	c51d                	beqz	a0,80001608 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015dc:	6605                	lui	a2,0x1
    800015de:	4581                	li	a1,0
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	72c080e7          	jalr	1836(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015e8:	4779                	li	a4,30
    800015ea:	86a6                	mv	a3,s1
    800015ec:	6605                	lui	a2,0x1
    800015ee:	85ca                	mv	a1,s2
    800015f0:	8556                	mv	a0,s5
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	b4c080e7          	jalr	-1204(ra) # 8000113e <mappages>
    800015fa:	e905                	bnez	a0,8000162a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015fc:	6785                	lui	a5,0x1
    800015fe:	993e                	add	s2,s2,a5
    80001600:	fd4968e3          	bltu	s2,s4,800015d0 <uvmalloc+0x2c>
  return newsz;
    80001604:	8552                	mv	a0,s4
    80001606:	a809                	j	80001618 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001608:	864e                	mv	a2,s3
    8000160a:	85ca                	mv	a1,s2
    8000160c:	8556                	mv	a0,s5
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	f4e080e7          	jalr	-178(ra) # 8000155c <uvmdealloc>
      return 0;
    80001616:	4501                	li	a0,0
}
    80001618:	70e2                	ld	ra,56(sp)
    8000161a:	7442                	ld	s0,48(sp)
    8000161c:	74a2                	ld	s1,40(sp)
    8000161e:	7902                	ld	s2,32(sp)
    80001620:	69e2                	ld	s3,24(sp)
    80001622:	6a42                	ld	s4,16(sp)
    80001624:	6aa2                	ld	s5,8(sp)
    80001626:	6121                	addi	sp,sp,64
    80001628:	8082                	ret
      kfree(mem);
    8000162a:	8526                	mv	a0,s1
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	3f8080e7          	jalr	1016(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001634:	864e                	mv	a2,s3
    80001636:	85ca                	mv	a1,s2
    80001638:	8556                	mv	a0,s5
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	f22080e7          	jalr	-222(ra) # 8000155c <uvmdealloc>
      return 0;
    80001642:	4501                	li	a0,0
    80001644:	bfd1                	j	80001618 <uvmalloc+0x74>
    return oldsz;
    80001646:	852e                	mv	a0,a1
}
    80001648:	8082                	ret
  return newsz;
    8000164a:	8532                	mv	a0,a2
    8000164c:	b7f1                	j	80001618 <uvmalloc+0x74>

000000008000164e <pgtprint>:



int
pgtprint(pagetable_t pagetable,int depth)
{
    8000164e:	7159                	addi	sp,sp,-112
    80001650:	f486                	sd	ra,104(sp)
    80001652:	f0a2                	sd	s0,96(sp)
    80001654:	eca6                	sd	s1,88(sp)
    80001656:	e8ca                	sd	s2,80(sp)
    80001658:	e4ce                	sd	s3,72(sp)
    8000165a:	e0d2                	sd	s4,64(sp)
    8000165c:	fc56                	sd	s5,56(sp)
    8000165e:	f85a                	sd	s6,48(sp)
    80001660:	f45e                	sd	s7,40(sp)
    80001662:	f062                	sd	s8,32(sp)
    80001664:	ec66                	sd	s9,24(sp)
    80001666:	e86a                	sd	s10,16(sp)
    80001668:	e46e                	sd	s11,8(sp)
    8000166a:	1880                	addi	s0,sp,112
    8000166c:	8aae                	mv	s5,a1
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++)
    8000166e:	89aa                	mv	s3,a0
    80001670:	4901                	li	s2,0
  {
    pte_t pte = pagetable[i];
    if((pte & PTE_V) )//pte-v valid
    {
      printf("..");
    80001672:	00007c97          	auipc	s9,0x7
    80001676:	b26c8c93          	addi	s9,s9,-1242 # 80008198 <digits+0x168>
      for(int j=0;j<depth;j++) 
      {
        printf(" ..");
      }
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    8000167a:	00007c17          	auipc	s8,0x7
    8000167e:	b2ec0c13          	addi	s8,s8,-1234 # 800081a8 <digits+0x178>

      if((pte & (PTE_R|PTE_W|PTE_X)) == 0)
      {
        // this PTE points to a lower-level page table.
        uint64 child = PTE2PA(pte);
        pgtprint((pagetable_t)child,depth+1);
    80001682:	00158d9b          	addiw	s11,a1,1
      for(int j=0;j<depth;j++) 
    80001686:	4d01                	li	s10,0
        printf(" ..");
    80001688:	00007b17          	auipc	s6,0x7
    8000168c:	b18b0b13          	addi	s6,s6,-1256 # 800081a0 <digits+0x170>
  for(int i = 0; i < 512; i++)
    80001690:	20000b93          	li	s7,512
    80001694:	a029                	j	8000169e <pgtprint+0x50>
    80001696:	2905                	addiw	s2,s2,1
    80001698:	09a1                	addi	s3,s3,8
    8000169a:	05790d63          	beq	s2,s7,800016f4 <pgtprint+0xa6>
    pte_t pte = pagetable[i];
    8000169e:	0009ba03          	ld	s4,0(s3) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if((pte & PTE_V) )//pte-v valid
    800016a2:	001a7793          	andi	a5,s4,1
    800016a6:	dbe5                	beqz	a5,80001696 <pgtprint+0x48>
      printf("..");
    800016a8:	8566                	mv	a0,s9
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	ee8080e7          	jalr	-280(ra) # 80000592 <printf>
      for(int j=0;j<depth;j++) 
    800016b2:	01505b63          	blez	s5,800016c8 <pgtprint+0x7a>
    800016b6:	84ea                	mv	s1,s10
        printf(" ..");
    800016b8:	855a                	mv	a0,s6
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	ed8080e7          	jalr	-296(ra) # 80000592 <printf>
      for(int j=0;j<depth;j++) 
    800016c2:	2485                	addiw	s1,s1,1
    800016c4:	fe9a9ae3          	bne	s5,s1,800016b8 <pgtprint+0x6a>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    800016c8:	00aa5493          	srli	s1,s4,0xa
    800016cc:	04b2                	slli	s1,s1,0xc
    800016ce:	86a6                	mv	a3,s1
    800016d0:	8652                	mv	a2,s4
    800016d2:	85ca                	mv	a1,s2
    800016d4:	8562                	mv	a0,s8
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	ebc080e7          	jalr	-324(ra) # 80000592 <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0)
    800016de:	00ea7a13          	andi	s4,s4,14
    800016e2:	fa0a1ae3          	bnez	s4,80001696 <pgtprint+0x48>
        pgtprint((pagetable_t)child,depth+1);
    800016e6:	85ee                	mv	a1,s11
    800016e8:	8526                	mv	a0,s1
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	f64080e7          	jalr	-156(ra) # 8000164e <pgtprint>
    800016f2:	b755                	j	80001696 <pgtprint+0x48>
      }
    }
  }
  return 0;
}
    800016f4:	4501                	li	a0,0
    800016f6:	70a6                	ld	ra,104(sp)
    800016f8:	7406                	ld	s0,96(sp)
    800016fa:	64e6                	ld	s1,88(sp)
    800016fc:	6946                	ld	s2,80(sp)
    800016fe:	69a6                	ld	s3,72(sp)
    80001700:	6a06                	ld	s4,64(sp)
    80001702:	7ae2                	ld	s5,56(sp)
    80001704:	7b42                	ld	s6,48(sp)
    80001706:	7ba2                	ld	s7,40(sp)
    80001708:	7c02                	ld	s8,32(sp)
    8000170a:	6ce2                	ld	s9,24(sp)
    8000170c:	6d42                	ld	s10,16(sp)
    8000170e:	6da2                	ld	s11,8(sp)
    80001710:	6165                	addi	sp,sp,112
    80001712:	8082                	ret

0000000080001714 <vmprint>:

int vmprint(pagetable_t pagetable) 
{
    80001714:	1101                	addi	sp,sp,-32
    80001716:	ec06                	sd	ra,24(sp)
    80001718:	e822                	sd	s0,16(sp)
    8000171a:	e426                	sd	s1,8(sp)
    8000171c:	1000                	addi	s0,sp,32
    8000171e:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001720:	85aa                	mv	a1,a0
    80001722:	00007517          	auipc	a0,0x7
    80001726:	a9e50513          	addi	a0,a0,-1378 # 800081c0 <digits+0x190>
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	e68080e7          	jalr	-408(ra) # 80000592 <printf>
  return pgtprint(pagetable, 0);
    80001732:	4581                	li	a1,0
    80001734:	8526                	mv	a0,s1
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	f18080e7          	jalr	-232(ra) # 8000164e <pgtprint>
}
    8000173e:	60e2                	ld	ra,24(sp)
    80001740:	6442                	ld	s0,16(sp)
    80001742:	64a2                	ld	s1,8(sp)
    80001744:	6105                	addi	sp,sp,32
    80001746:	8082                	ret

0000000080001748 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001748:	7179                	addi	sp,sp,-48
    8000174a:	f406                	sd	ra,40(sp)
    8000174c:	f022                	sd	s0,32(sp)
    8000174e:	ec26                	sd	s1,24(sp)
    80001750:	e84a                	sd	s2,16(sp)
    80001752:	e44e                	sd	s3,8(sp)
    80001754:	e052                	sd	s4,0(sp)
    80001756:	1800                	addi	s0,sp,48
    80001758:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000175a:	84aa                	mv	s1,a0
    8000175c:	6905                	lui	s2,0x1
    8000175e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001760:	4985                	li	s3,1
    80001762:	a821                	j	8000177a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001764:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001766:	0532                	slli	a0,a0,0xc
    80001768:	00000097          	auipc	ra,0x0
    8000176c:	fe0080e7          	jalr	-32(ra) # 80001748 <freewalk>
      pagetable[i] = 0;
    80001770:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001774:	04a1                	addi	s1,s1,8
    80001776:	03248163          	beq	s1,s2,80001798 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000177a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000177c:	00f57793          	andi	a5,a0,15
    80001780:	ff3782e3          	beq	a5,s3,80001764 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001784:	8905                	andi	a0,a0,1
    80001786:	d57d                	beqz	a0,80001774 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001788:	00007517          	auipc	a0,0x7
    8000178c:	a4850513          	addi	a0,a0,-1464 # 800081d0 <digits+0x1a0>
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	db8080e7          	jalr	-584(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80001798:	8552                	mv	a0,s4
    8000179a:	fffff097          	auipc	ra,0xfffff
    8000179e:	28a080e7          	jalr	650(ra) # 80000a24 <kfree>
}
    800017a2:	70a2                	ld	ra,40(sp)
    800017a4:	7402                	ld	s0,32(sp)
    800017a6:	64e2                	ld	s1,24(sp)
    800017a8:	6942                	ld	s2,16(sp)
    800017aa:	69a2                	ld	s3,8(sp)
    800017ac:	6a02                	ld	s4,0(sp)
    800017ae:	6145                	addi	sp,sp,48
    800017b0:	8082                	ret

00000000800017b2 <freekernel>:

void
freekernel(pagetable_t pagetable)
{
    800017b2:	7179                	addi	sp,sp,-48
    800017b4:	f406                	sd	ra,40(sp)
    800017b6:	f022                	sd	s0,32(sp)
    800017b8:	ec26                	sd	s1,24(sp)
    800017ba:	e84a                	sd	s2,16(sp)
    800017bc:	e44e                	sd	s3,8(sp)
    800017be:	e052                	sd	s4,0(sp)
    800017c0:	1800                	addi	s0,sp,48
    800017c2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800017c4:	84aa                	mv	s1,a0
    800017c6:	6905                	lui	s2,0x1
    800017c8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0)
    800017ca:	4985                	li	s3,1
    800017cc:	a821                	j	800017e4 <freekernel+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800017ce:	8129                	srli	a0,a0,0xa
      freekernel((pagetable_t)child);
    800017d0:	0532                	slli	a0,a0,0xc
    800017d2:	00000097          	auipc	ra,0x0
    800017d6:	fe0080e7          	jalr	-32(ra) # 800017b2 <freekernel>
      pagetable[i] = 0;
    800017da:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800017de:	04a1                	addi	s1,s1,8
    800017e0:	01248c63          	beq	s1,s2,800017f8 <freekernel+0x46>
    pte_t pte = pagetable[i];
    800017e4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0)
    800017e6:	00f57793          	andi	a5,a0,15
    800017ea:	ff3782e3          	beq	a5,s3,800017ce <freekernel+0x1c>
    } 
    else if(pte & PTE_V)
    800017ee:	8905                	andi	a0,a0,1
    800017f0:	d57d                	beqz	a0,800017de <freekernel+0x2c>
    {
     pagetable[i] = 0;
    800017f2:	0004b023          	sd	zero,0(s1)
    800017f6:	b7e5                	j	800017de <freekernel+0x2c>
    }
  }
  kfree((void*)pagetable);
    800017f8:	8552                	mv	a0,s4
    800017fa:	fffff097          	auipc	ra,0xfffff
    800017fe:	22a080e7          	jalr	554(ra) # 80000a24 <kfree>
}
    80001802:	70a2                	ld	ra,40(sp)
    80001804:	7402                	ld	s0,32(sp)
    80001806:	64e2                	ld	s1,24(sp)
    80001808:	6942                	ld	s2,16(sp)
    8000180a:	69a2                	ld	s3,8(sp)
    8000180c:	6a02                	ld	s4,0(sp)
    8000180e:	6145                	addi	sp,sp,48
    80001810:	8082                	ret

0000000080001812 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001812:	1101                	addi	sp,sp,-32
    80001814:	ec06                	sd	ra,24(sp)
    80001816:	e822                	sd	s0,16(sp)
    80001818:	e426                	sd	s1,8(sp)
    8000181a:	1000                	addi	s0,sp,32
    8000181c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000181e:	e999                	bnez	a1,80001834 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001820:	8526                	mv	a0,s1
    80001822:	00000097          	auipc	ra,0x0
    80001826:	f26080e7          	jalr	-218(ra) # 80001748 <freewalk>
}
    8000182a:	60e2                	ld	ra,24(sp)
    8000182c:	6442                	ld	s0,16(sp)
    8000182e:	64a2                	ld	s1,8(sp)
    80001830:	6105                	addi	sp,sp,32
    80001832:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001834:	6605                	lui	a2,0x1
    80001836:	167d                	addi	a2,a2,-1
    80001838:	962e                	add	a2,a2,a1
    8000183a:	4685                	li	a3,1
    8000183c:	8231                	srli	a2,a2,0xc
    8000183e:	4581                	li	a1,0
    80001840:	00000097          	auipc	ra,0x0
    80001844:	abc080e7          	jalr	-1348(ra) # 800012fc <uvmunmap>
    80001848:	bfe1                	j	80001820 <uvmfree+0xe>

000000008000184a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000184a:	c679                	beqz	a2,80001918 <uvmcopy+0xce>
{
    8000184c:	715d                	addi	sp,sp,-80
    8000184e:	e486                	sd	ra,72(sp)
    80001850:	e0a2                	sd	s0,64(sp)
    80001852:	fc26                	sd	s1,56(sp)
    80001854:	f84a                	sd	s2,48(sp)
    80001856:	f44e                	sd	s3,40(sp)
    80001858:	f052                	sd	s4,32(sp)
    8000185a:	ec56                	sd	s5,24(sp)
    8000185c:	e85a                	sd	s6,16(sp)
    8000185e:	e45e                	sd	s7,8(sp)
    80001860:	0880                	addi	s0,sp,80
    80001862:	8b2a                	mv	s6,a0
    80001864:	8aae                	mv	s5,a1
    80001866:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001868:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000186a:	4601                	li	a2,0
    8000186c:	85ce                	mv	a1,s3
    8000186e:	855a                	mv	a0,s6
    80001870:	fffff097          	auipc	ra,0xfffff
    80001874:	790080e7          	jalr	1936(ra) # 80001000 <walk>
    80001878:	c531                	beqz	a0,800018c4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000187a:	6118                	ld	a4,0(a0)
    8000187c:	00177793          	andi	a5,a4,1
    80001880:	cbb1                	beqz	a5,800018d4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001882:	00a75593          	srli	a1,a4,0xa
    80001886:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000188a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	292080e7          	jalr	658(ra) # 80000b20 <kalloc>
    80001896:	892a                	mv	s2,a0
    80001898:	c939                	beqz	a0,800018ee <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000189a:	6605                	lui	a2,0x1
    8000189c:	85de                	mv	a1,s7
    8000189e:	fffff097          	auipc	ra,0xfffff
    800018a2:	4ce080e7          	jalr	1230(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800018a6:	8726                	mv	a4,s1
    800018a8:	86ca                	mv	a3,s2
    800018aa:	6605                	lui	a2,0x1
    800018ac:	85ce                	mv	a1,s3
    800018ae:	8556                	mv	a0,s5
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	88e080e7          	jalr	-1906(ra) # 8000113e <mappages>
    800018b8:	e515                	bnez	a0,800018e4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800018ba:	6785                	lui	a5,0x1
    800018bc:	99be                	add	s3,s3,a5
    800018be:	fb49e6e3          	bltu	s3,s4,8000186a <uvmcopy+0x20>
    800018c2:	a081                	j	80001902 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91c50513          	addi	a0,a0,-1764 # 800081e0 <digits+0x1b0>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c7c080e7          	jalr	-900(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800018d4:	00007517          	auipc	a0,0x7
    800018d8:	92c50513          	addi	a0,a0,-1748 # 80008200 <digits+0x1d0>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	c6c080e7          	jalr	-916(ra) # 80000548 <panic>
      kfree(mem);
    800018e4:	854a                	mv	a0,s2
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	13e080e7          	jalr	318(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800018ee:	4685                	li	a3,1
    800018f0:	00c9d613          	srli	a2,s3,0xc
    800018f4:	4581                	li	a1,0
    800018f6:	8556                	mv	a0,s5
    800018f8:	00000097          	auipc	ra,0x0
    800018fc:	a04080e7          	jalr	-1532(ra) # 800012fc <uvmunmap>
  return -1;
    80001900:	557d                	li	a0,-1
}
    80001902:	60a6                	ld	ra,72(sp)
    80001904:	6406                	ld	s0,64(sp)
    80001906:	74e2                	ld	s1,56(sp)
    80001908:	7942                	ld	s2,48(sp)
    8000190a:	79a2                	ld	s3,40(sp)
    8000190c:	7a02                	ld	s4,32(sp)
    8000190e:	6ae2                	ld	s5,24(sp)
    80001910:	6b42                	ld	s6,16(sp)
    80001912:	6ba2                	ld	s7,8(sp)
    80001914:	6161                	addi	sp,sp,80
    80001916:	8082                	ret
  return 0;
    80001918:	4501                	li	a0,0
}
    8000191a:	8082                	ret

000000008000191c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000191c:	1141                	addi	sp,sp,-16
    8000191e:	e406                	sd	ra,8(sp)
    80001920:	e022                	sd	s0,0(sp)
    80001922:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001924:	4601                	li	a2,0
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	6da080e7          	jalr	1754(ra) # 80001000 <walk>
  if(pte == 0)
    8000192e:	c901                	beqz	a0,8000193e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001930:	611c                	ld	a5,0(a0)
    80001932:	9bbd                	andi	a5,a5,-17
    80001934:	e11c                	sd	a5,0(a0)
}
    80001936:	60a2                	ld	ra,8(sp)
    80001938:	6402                	ld	s0,0(sp)
    8000193a:	0141                	addi	sp,sp,16
    8000193c:	8082                	ret
    panic("uvmclear");
    8000193e:	00007517          	auipc	a0,0x7
    80001942:	8e250513          	addi	a0,a0,-1822 # 80008220 <digits+0x1f0>
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	c02080e7          	jalr	-1022(ra) # 80000548 <panic>

000000008000194e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000194e:	c6bd                	beqz	a3,800019bc <copyout+0x6e>
{
    80001950:	715d                	addi	sp,sp,-80
    80001952:	e486                	sd	ra,72(sp)
    80001954:	e0a2                	sd	s0,64(sp)
    80001956:	fc26                	sd	s1,56(sp)
    80001958:	f84a                	sd	s2,48(sp)
    8000195a:	f44e                	sd	s3,40(sp)
    8000195c:	f052                	sd	s4,32(sp)
    8000195e:	ec56                	sd	s5,24(sp)
    80001960:	e85a                	sd	s6,16(sp)
    80001962:	e45e                	sd	s7,8(sp)
    80001964:	e062                	sd	s8,0(sp)
    80001966:	0880                	addi	s0,sp,80
    80001968:	8b2a                	mv	s6,a0
    8000196a:	8c2e                	mv	s8,a1
    8000196c:	8a32                	mv	s4,a2
    8000196e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001970:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001972:	6a85                	lui	s5,0x1
    80001974:	a015                	j	80001998 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001976:	9562                	add	a0,a0,s8
    80001978:	0004861b          	sext.w	a2,s1
    8000197c:	85d2                	mv	a1,s4
    8000197e:	41250533          	sub	a0,a0,s2
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	3ea080e7          	jalr	1002(ra) # 80000d6c <memmove>

    len -= n;
    8000198a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000198e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001990:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001994:	02098263          	beqz	s3,800019b8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001998:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000199c:	85ca                	mv	a1,s2
    8000199e:	855a                	mv	a0,s6
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	75c080e7          	jalr	1884(ra) # 800010fc <walkaddr>
    if(pa0 == 0)
    800019a8:	cd01                	beqz	a0,800019c0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800019aa:	418904b3          	sub	s1,s2,s8
    800019ae:	94d6                	add	s1,s1,s5
    if(n > len)
    800019b0:	fc99f3e3          	bgeu	s3,s1,80001976 <copyout+0x28>
    800019b4:	84ce                	mv	s1,s3
    800019b6:	b7c1                	j	80001976 <copyout+0x28>
  }
  return 0;
    800019b8:	4501                	li	a0,0
    800019ba:	a021                	j	800019c2 <copyout+0x74>
    800019bc:	4501                	li	a0,0
}
    800019be:	8082                	ret
      return -1;
    800019c0:	557d                	li	a0,-1
}
    800019c2:	60a6                	ld	ra,72(sp)
    800019c4:	6406                	ld	s0,64(sp)
    800019c6:	74e2                	ld	s1,56(sp)
    800019c8:	7942                	ld	s2,48(sp)
    800019ca:	79a2                	ld	s3,40(sp)
    800019cc:	7a02                	ld	s4,32(sp)
    800019ce:	6ae2                	ld	s5,24(sp)
    800019d0:	6b42                	ld	s6,16(sp)
    800019d2:	6ba2                	ld	s7,8(sp)
    800019d4:	6c02                	ld	s8,0(sp)
    800019d6:	6161                	addi	sp,sp,80
    800019d8:	8082                	ret

00000000800019da <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800019da:	1141                	addi	sp,sp,-16
    800019dc:	e406                	sd	ra,8(sp)
    800019de:	e022                	sd	s0,0(sp)
    800019e0:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    800019e2:	00005097          	auipc	ra,0x5
    800019e6:	a9a080e7          	jalr	-1382(ra) # 8000647c <copyin_new>
  //   len -= n;
  //   dst += n;
  //   srcva = va0 + PGSIZE;
  // }
  // return 0;
}
    800019ea:	60a2                	ld	ra,8(sp)
    800019ec:	6402                	ld	s0,0(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e406                	sd	ra,8(sp)
    800019f6:	e022                	sd	s0,0(sp)
    800019f8:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    800019fa:	00005097          	auipc	ra,0x5
    800019fe:	aea080e7          	jalr	-1302(ra) # 800064e4 <copyinstr_new>
  // if(got_null){
  //   return 0;
  // } else {
  //   return -1;
  // }
}
    80001a02:	60a2                	ld	ra,8(sp)
    80001a04:	6402                	ld	s0,0(sp)
    80001a06:	0141                	addi	sp,sp,16
    80001a08:	8082                	ret

0000000080001a0a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a0a:	1101                	addi	sp,sp,-32
    80001a0c:	ec06                	sd	ra,24(sp)
    80001a0e:	e822                	sd	s0,16(sp)
    80001a10:	e426                	sd	s1,8(sp)
    80001a12:	1000                	addi	s0,sp,32
    80001a14:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	180080e7          	jalr	384(ra) # 80000b96 <holding>
    80001a1e:	c909                	beqz	a0,80001a30 <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    80001a20:	749c                	ld	a5,40(s1)
    80001a22:	00978f63          	beq	a5,s1,80001a40 <wakeup1+0x36>
  {
    p->state = RUNNABLE;
  }
}
    80001a26:	60e2                	ld	ra,24(sp)
    80001a28:	6442                	ld	s0,16(sp)
    80001a2a:	64a2                	ld	s1,8(sp)
    80001a2c:	6105                	addi	sp,sp,32
    80001a2e:	8082                	ret
    panic("wakeup1");
    80001a30:	00007517          	auipc	a0,0x7
    80001a34:	80050513          	addi	a0,a0,-2048 # 80008230 <digits+0x200>
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	b10080e7          	jalr	-1264(ra) # 80000548 <panic>
  if (p->chan == p && p->state == SLEEPING)
    80001a40:	4c98                	lw	a4,24(s1)
    80001a42:	4785                	li	a5,1
    80001a44:	fef711e3          	bne	a4,a5,80001a26 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a48:	4789                	li	a5,2
    80001a4a:	cc9c                	sw	a5,24(s1)
}
    80001a4c:	bfe9                	j	80001a26 <wakeup1+0x1c>

0000000080001a4e <procinit>:
{
    80001a4e:	7179                	addi	sp,sp,-48
    80001a50:	f406                	sd	ra,40(sp)
    80001a52:	f022                	sd	s0,32(sp)
    80001a54:	ec26                	sd	s1,24(sp)
    80001a56:	e84a                	sd	s2,16(sp)
    80001a58:	e44e                	sd	s3,8(sp)
    80001a5a:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001a5c:	00006597          	auipc	a1,0x6
    80001a60:	7dc58593          	addi	a1,a1,2012 # 80008238 <digits+0x208>
    80001a64:	00010517          	auipc	a0,0x10
    80001a68:	eec50513          	addi	a0,a0,-276 # 80011950 <pid_lock>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	114080e7          	jalr	276(ra) # 80000b80 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a74:	00010497          	auipc	s1,0x10
    80001a78:	2f448493          	addi	s1,s1,756 # 80011d68 <proc>
    initlock(&p->lock, "proc");
    80001a7c:	00006997          	auipc	s3,0x6
    80001a80:	7c498993          	addi	s3,s3,1988 # 80008240 <digits+0x210>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a84:	00016917          	auipc	s2,0x16
    80001a88:	ee490913          	addi	s2,s2,-284 # 80017968 <tickslock>
    initlock(&p->lock, "proc");
    80001a8c:	85ce                	mv	a1,s3
    80001a8e:	8526                	mv	a0,s1
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	0f0080e7          	jalr	240(ra) # 80000b80 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a98:	17048493          	addi	s1,s1,368
    80001a9c:	ff2498e3          	bne	s1,s2,80001a8c <procinit+0x3e>
  kvminithart();
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	53c080e7          	jalr	1340(ra) # 80000fdc <kvminithart>
}
    80001aa8:	70a2                	ld	ra,40(sp)
    80001aaa:	7402                	ld	s0,32(sp)
    80001aac:	64e2                	ld	s1,24(sp)
    80001aae:	6942                	ld	s2,16(sp)
    80001ab0:	69a2                	ld	s3,8(sp)
    80001ab2:	6145                	addi	sp,sp,48
    80001ab4:	8082                	ret

0000000080001ab6 <cpuid>:
{
    80001ab6:	1141                	addi	sp,sp,-16
    80001ab8:	e422                	sd	s0,8(sp)
    80001aba:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001abc:	8512                	mv	a0,tp
}
    80001abe:	2501                	sext.w	a0,a0
    80001ac0:	6422                	ld	s0,8(sp)
    80001ac2:	0141                	addi	sp,sp,16
    80001ac4:	8082                	ret

0000000080001ac6 <mycpu>:
{
    80001ac6:	1141                	addi	sp,sp,-16
    80001ac8:	e422                	sd	s0,8(sp)
    80001aca:	0800                	addi	s0,sp,16
    80001acc:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ace:	2781                	sext.w	a5,a5
    80001ad0:	079e                	slli	a5,a5,0x7
}
    80001ad2:	00010517          	auipc	a0,0x10
    80001ad6:	e9650513          	addi	a0,a0,-362 # 80011968 <cpus>
    80001ada:	953e                	add	a0,a0,a5
    80001adc:	6422                	ld	s0,8(sp)
    80001ade:	0141                	addi	sp,sp,16
    80001ae0:	8082                	ret

0000000080001ae2 <myproc>:
{
    80001ae2:	1101                	addi	sp,sp,-32
    80001ae4:	ec06                	sd	ra,24(sp)
    80001ae6:	e822                	sd	s0,16(sp)
    80001ae8:	e426                	sd	s1,8(sp)
    80001aea:	1000                	addi	s0,sp,32
  push_off();
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	0d8080e7          	jalr	216(ra) # 80000bc4 <push_off>
    80001af4:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001af6:	2781                	sext.w	a5,a5
    80001af8:	079e                	slli	a5,a5,0x7
    80001afa:	00010717          	auipc	a4,0x10
    80001afe:	e5670713          	addi	a4,a4,-426 # 80011950 <pid_lock>
    80001b02:	97ba                	add	a5,a5,a4
    80001b04:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	15e080e7          	jalr	350(ra) # 80000c64 <pop_off>
}
    80001b0e:	8526                	mv	a0,s1
    80001b10:	60e2                	ld	ra,24(sp)
    80001b12:	6442                	ld	s0,16(sp)
    80001b14:	64a2                	ld	s1,8(sp)
    80001b16:	6105                	addi	sp,sp,32
    80001b18:	8082                	ret

0000000080001b1a <forkret>:
{
    80001b1a:	1141                	addi	sp,sp,-16
    80001b1c:	e406                	sd	ra,8(sp)
    80001b1e:	e022                	sd	s0,0(sp)
    80001b20:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	fc0080e7          	jalr	-64(ra) # 80001ae2 <myproc>
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	19a080e7          	jalr	410(ra) # 80000cc4 <release>
  if (first)
    80001b32:	00007797          	auipc	a5,0x7
    80001b36:	d7e7a783          	lw	a5,-642(a5) # 800088b0 <first.1699>
    80001b3a:	eb89                	bnez	a5,80001b4c <forkret+0x32>
  usertrapret();
    80001b3c:	00001097          	auipc	ra,0x1
    80001b40:	d34080e7          	jalr	-716(ra) # 80002870 <usertrapret>
}
    80001b44:	60a2                	ld	ra,8(sp)
    80001b46:	6402                	ld	s0,0(sp)
    80001b48:	0141                	addi	sp,sp,16
    80001b4a:	8082                	ret
    first = 0;
    80001b4c:	00007797          	auipc	a5,0x7
    80001b50:	d607a223          	sw	zero,-668(a5) # 800088b0 <first.1699>
    fsinit(ROOTDEV);
    80001b54:	4505                	li	a0,1
    80001b56:	00002097          	auipc	ra,0x2
    80001b5a:	a5c080e7          	jalr	-1444(ra) # 800035b2 <fsinit>
    80001b5e:	bff9                	j	80001b3c <forkret+0x22>

0000000080001b60 <allocpid>:
{
    80001b60:	1101                	addi	sp,sp,-32
    80001b62:	ec06                	sd	ra,24(sp)
    80001b64:	e822                	sd	s0,16(sp)
    80001b66:	e426                	sd	s1,8(sp)
    80001b68:	e04a                	sd	s2,0(sp)
    80001b6a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b6c:	00010917          	auipc	s2,0x10
    80001b70:	de490913          	addi	s2,s2,-540 # 80011950 <pid_lock>
    80001b74:	854a                	mv	a0,s2
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	09a080e7          	jalr	154(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001b7e:	00007797          	auipc	a5,0x7
    80001b82:	d3678793          	addi	a5,a5,-714 # 800088b4 <nextpid>
    80001b86:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b88:	0014871b          	addiw	a4,s1,1
    80001b8c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b8e:	854a                	mv	a0,s2
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	134080e7          	jalr	308(ra) # 80000cc4 <release>
}
    80001b98:	8526                	mv	a0,s1
    80001b9a:	60e2                	ld	ra,24(sp)
    80001b9c:	6442                	ld	s0,16(sp)
    80001b9e:	64a2                	ld	s1,8(sp)
    80001ba0:	6902                	ld	s2,0(sp)
    80001ba2:	6105                	addi	sp,sp,32
    80001ba4:	8082                	ret

0000000080001ba6 <proc_pagetable>:
{
    80001ba6:	1101                	addi	sp,sp,-32
    80001ba8:	ec06                	sd	ra,24(sp)
    80001baa:	e822                	sd	s0,16(sp)
    80001bac:	e426                	sd	s1,8(sp)
    80001bae:	e04a                	sd	s2,0(sp)
    80001bb0:	1000                	addi	s0,sp,32
    80001bb2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bb4:	00000097          	auipc	ra,0x0
    80001bb8:	908080e7          	jalr	-1784(ra) # 800014bc <uvmcreate>
    80001bbc:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bbe:	c121                	beqz	a0,80001bfe <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bc0:	4729                	li	a4,10
    80001bc2:	00005697          	auipc	a3,0x5
    80001bc6:	43e68693          	addi	a3,a3,1086 # 80007000 <_trampoline>
    80001bca:	6605                	lui	a2,0x1
    80001bcc:	040005b7          	lui	a1,0x4000
    80001bd0:	15fd                	addi	a1,a1,-1
    80001bd2:	05b2                	slli	a1,a1,0xc
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	56a080e7          	jalr	1386(ra) # 8000113e <mappages>
    80001bdc:	02054863          	bltz	a0,80001c0c <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001be0:	4719                	li	a4,6
    80001be2:	05893683          	ld	a3,88(s2)
    80001be6:	6605                	lui	a2,0x1
    80001be8:	020005b7          	lui	a1,0x2000
    80001bec:	15fd                	addi	a1,a1,-1
    80001bee:	05b6                	slli	a1,a1,0xd
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	54c080e7          	jalr	1356(ra) # 8000113e <mappages>
    80001bfa:	02054163          	bltz	a0,80001c1c <proc_pagetable+0x76>
}
    80001bfe:	8526                	mv	a0,s1
    80001c00:	60e2                	ld	ra,24(sp)
    80001c02:	6442                	ld	s0,16(sp)
    80001c04:	64a2                	ld	s1,8(sp)
    80001c06:	6902                	ld	s2,0(sp)
    80001c08:	6105                	addi	sp,sp,32
    80001c0a:	8082                	ret
    uvmfree(pagetable, 0);
    80001c0c:	4581                	li	a1,0
    80001c0e:	8526                	mv	a0,s1
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	c02080e7          	jalr	-1022(ra) # 80001812 <uvmfree>
    return 0;
    80001c18:	4481                	li	s1,0
    80001c1a:	b7d5                	j	80001bfe <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c1c:	4681                	li	a3,0
    80001c1e:	4605                	li	a2,1
    80001c20:	040005b7          	lui	a1,0x4000
    80001c24:	15fd                	addi	a1,a1,-1
    80001c26:	05b2                	slli	a1,a1,0xc
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	6d2080e7          	jalr	1746(ra) # 800012fc <uvmunmap>
    uvmfree(pagetable, 0);
    80001c32:	4581                	li	a1,0
    80001c34:	8526                	mv	a0,s1
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	bdc080e7          	jalr	-1060(ra) # 80001812 <uvmfree>
    return 0;
    80001c3e:	4481                	li	s1,0
    80001c40:	bf7d                	j	80001bfe <proc_pagetable+0x58>

0000000080001c42 <proc_freepagetable>:
{
    80001c42:	1101                	addi	sp,sp,-32
    80001c44:	ec06                	sd	ra,24(sp)
    80001c46:	e822                	sd	s0,16(sp)
    80001c48:	e426                	sd	s1,8(sp)
    80001c4a:	e04a                	sd	s2,0(sp)
    80001c4c:	1000                	addi	s0,sp,32
    80001c4e:	84aa                	mv	s1,a0
    80001c50:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c52:	4681                	li	a3,0
    80001c54:	4605                	li	a2,1
    80001c56:	040005b7          	lui	a1,0x4000
    80001c5a:	15fd                	addi	a1,a1,-1
    80001c5c:	05b2                	slli	a1,a1,0xc
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	69e080e7          	jalr	1694(ra) # 800012fc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c66:	4681                	li	a3,0
    80001c68:	4605                	li	a2,1
    80001c6a:	020005b7          	lui	a1,0x2000
    80001c6e:	15fd                	addi	a1,a1,-1
    80001c70:	05b6                	slli	a1,a1,0xd
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	688080e7          	jalr	1672(ra) # 800012fc <uvmunmap>
  uvmfree(pagetable, sz);
    80001c7c:	85ca                	mv	a1,s2
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	b92080e7          	jalr	-1134(ra) # 80001812 <uvmfree>
}
    80001c88:	60e2                	ld	ra,24(sp)
    80001c8a:	6442                	ld	s0,16(sp)
    80001c8c:	64a2                	ld	s1,8(sp)
    80001c8e:	6902                	ld	s2,0(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret

0000000080001c94 <freeproc>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	1000                	addi	s0,sp,32
    80001c9e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001ca0:	6d28                	ld	a0,88(a0)
    80001ca2:	c509                	beqz	a0,80001cac <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	d80080e7          	jalr	-640(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001cac:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001cb0:	68a8                	ld	a0,80(s1)
    80001cb2:	c511                	beqz	a0,80001cbe <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cb4:	64ac                	ld	a1,72(s1)
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f8c080e7          	jalr	-116(ra) # 80001c42 <proc_freepagetable>
  p->pagetable = 0;
    80001cbe:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cc2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cc6:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cca:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cce:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cd2:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cd6:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cda:	0204aa23          	sw	zero,52(s1)
  void *kstack_pa = (void *)kvmpa(p->kernelpgt, p->kstack);
    80001cde:	60ac                	ld	a1,64(s1)
    80001ce0:	1684b503          	ld	a0,360(s1)
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	3c2080e7          	jalr	962(ra) # 800010a6 <kvmpa>
  kfree(kstack_pa);
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	d38080e7          	jalr	-712(ra) # 80000a24 <kfree>
  p->kstack = 0;
    80001cf4:	0404b023          	sd	zero,64(s1)
  freekernel(p->kernelpgt);
    80001cf8:	1684b503          	ld	a0,360(s1)
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	ab6080e7          	jalr	-1354(ra) # 800017b2 <freekernel>
  p->kernelpgt = 0;
    80001d04:	1604b423          	sd	zero,360(s1)
  p->state = UNUSED;
    80001d08:	0004ac23          	sw	zero,24(s1)
}
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6105                	addi	sp,sp,32
    80001d14:	8082                	ret

0000000080001d16 <allocproc>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d22:	00010497          	auipc	s1,0x10
    80001d26:	04648493          	addi	s1,s1,70 # 80011d68 <proc>
    80001d2a:	00016917          	auipc	s2,0x16
    80001d2e:	c3e90913          	addi	s2,s2,-962 # 80017968 <tickslock>
    acquire(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	edc080e7          	jalr	-292(ra) # 80000c10 <acquire>
    if (p->state == UNUSED)
    80001d3c:	4c9c                	lw	a5,24(s1)
    80001d3e:	cf81                	beqz	a5,80001d56 <allocproc+0x40>
      release(&p->lock);
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f82080e7          	jalr	-126(ra) # 80000cc4 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d4a:	17048493          	addi	s1,s1,368
    80001d4e:	ff2492e3          	bne	s1,s2,80001d32 <allocproc+0x1c>
  return 0;
    80001d52:	4481                	li	s1,0
    80001d54:	a059                	j	80001dda <allocproc+0xc4>
  p->pid = allocpid();
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	e0a080e7          	jalr	-502(ra) # 80001b60 <allocpid>
    80001d5e:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	dc0080e7          	jalr	-576(ra) # 80000b20 <kalloc>
    80001d68:	892a                	mv	s2,a0
    80001d6a:	eca8                	sd	a0,88(s1)
    80001d6c:	cd35                	beqz	a0,80001de8 <allocproc+0xd2>
  p->pagetable = proc_pagetable(p);
    80001d6e:	8526                	mv	a0,s1
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	e36080e7          	jalr	-458(ra) # 80001ba6 <proc_pagetable>
    80001d78:	892a                	mv	s2,a0
    80001d7a:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d7c:	cd2d                	beqz	a0,80001df6 <allocproc+0xe0>
  p->kernelpgt = kvminit_newpgt();
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	47e080e7          	jalr	1150(ra) # 800011fc <kvminit_newpgt>
    80001d86:	16a4b423          	sd	a0,360(s1)
  char *pa = kalloc();
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	d96080e7          	jalr	-618(ra) # 80000b20 <kalloc>
    80001d92:	862a                	mv	a2,a0
  if (pa == 0)
    80001d94:	cd2d                	beqz	a0,80001e0e <allocproc+0xf8>
  kvmmap(p->kernelpgt, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d96:	4719                	li	a4,6
    80001d98:	6685                	lui	a3,0x1
    80001d9a:	04000937          	lui	s2,0x4000
    80001d9e:	1975                	addi	s2,s2,-3
    80001da0:	00c91593          	slli	a1,s2,0xc
    80001da4:	1684b503          	ld	a0,360(s1)
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	424080e7          	jalr	1060(ra) # 800011cc <kvmmap>
  p->kstack = va;
    80001db0:	0932                	slli	s2,s2,0xc
    80001db2:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001db6:	07000613          	li	a2,112
    80001dba:	4581                	li	a1,0
    80001dbc:	06048513          	addi	a0,s1,96
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	f4c080e7          	jalr	-180(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001dc8:	00000797          	auipc	a5,0x0
    80001dcc:	d5278793          	addi	a5,a5,-686 # 80001b1a <forkret>
    80001dd0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dd2:	60bc                	ld	a5,64(s1)
    80001dd4:	6705                	lui	a4,0x1
    80001dd6:	97ba                	add	a5,a5,a4
    80001dd8:	f4bc                	sd	a5,104(s1)
}
    80001dda:	8526                	mv	a0,s1
    80001ddc:	60e2                	ld	ra,24(sp)
    80001dde:	6442                	ld	s0,16(sp)
    80001de0:	64a2                	ld	s1,8(sp)
    80001de2:	6902                	ld	s2,0(sp)
    80001de4:	6105                	addi	sp,sp,32
    80001de6:	8082                	ret
    release(&p->lock);
    80001de8:	8526                	mv	a0,s1
    80001dea:	fffff097          	auipc	ra,0xfffff
    80001dee:	eda080e7          	jalr	-294(ra) # 80000cc4 <release>
    return 0;
    80001df2:	84ca                	mv	s1,s2
    80001df4:	b7dd                	j	80001dda <allocproc+0xc4>
    freeproc(p);
    80001df6:	8526                	mv	a0,s1
    80001df8:	00000097          	auipc	ra,0x0
    80001dfc:	e9c080e7          	jalr	-356(ra) # 80001c94 <freeproc>
    release(&p->lock);
    80001e00:	8526                	mv	a0,s1
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	ec2080e7          	jalr	-318(ra) # 80000cc4 <release>
    return 0;
    80001e0a:	84ca                	mv	s1,s2
    80001e0c:	b7f9                	j	80001dda <allocproc+0xc4>
    panic("kalloc");
    80001e0e:	00006517          	auipc	a0,0x6
    80001e12:	43a50513          	addi	a0,a0,1082 # 80008248 <digits+0x218>
    80001e16:	ffffe097          	auipc	ra,0xffffe
    80001e1a:	732080e7          	jalr	1842(ra) # 80000548 <panic>

0000000080001e1e <userinit>:
{
    80001e1e:	1101                	addi	sp,sp,-32
    80001e20:	ec06                	sd	ra,24(sp)
    80001e22:	e822                	sd	s0,16(sp)
    80001e24:	e426                	sd	s1,8(sp)
    80001e26:	e04a                	sd	s2,0(sp)
    80001e28:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e2a:	00000097          	auipc	ra,0x0
    80001e2e:	eec080e7          	jalr	-276(ra) # 80001d16 <allocproc>
    80001e32:	84aa                	mv	s1,a0
  initproc = p;
    80001e34:	00007797          	auipc	a5,0x7
    80001e38:	1ea7b223          	sd	a0,484(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e3c:	03400613          	li	a2,52
    80001e40:	00007597          	auipc	a1,0x7
    80001e44:	a8058593          	addi	a1,a1,-1408 # 800088c0 <initcode>
    80001e48:	6928                	ld	a0,80(a0)
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	6a0080e7          	jalr	1696(ra) # 800014ea <uvminit>
  p->sz = PGSIZE;
    80001e52:	6905                	lui	s2,0x1
    80001e54:	0524b423          	sd	s2,72(s1)
  kvmcopy(p->pagetable, p->kernelpgt, 0, p->sz);
    80001e58:	6685                	lui	a3,0x1
    80001e5a:	4601                	li	a2,0
    80001e5c:	1684b583          	ld	a1,360(s1)
    80001e60:	68a8                	ld	a0,80(s1)
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	55e080e7          	jalr	1374(ra) # 800013c0 <kvmcopy>
  p->trapframe->epc = 0;     // user program counter
    80001e6a:	6cbc                	ld	a5,88(s1)
    80001e6c:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e70:	6cbc                	ld	a5,88(s1)
    80001e72:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e76:	4641                	li	a2,16
    80001e78:	00006597          	auipc	a1,0x6
    80001e7c:	3d858593          	addi	a1,a1,984 # 80008250 <digits+0x220>
    80001e80:	15848513          	addi	a0,s1,344
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	fde080e7          	jalr	-34(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001e8c:	00006517          	auipc	a0,0x6
    80001e90:	3d450513          	addi	a0,a0,980 # 80008260 <digits+0x230>
    80001e94:	00002097          	auipc	ra,0x2
    80001e98:	146080e7          	jalr	326(ra) # 80003fda <namei>
    80001e9c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ea0:	4789                	li	a5,2
    80001ea2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	e1e080e7          	jalr	-482(ra) # 80000cc4 <release>
}
    80001eae:	60e2                	ld	ra,24(sp)
    80001eb0:	6442                	ld	s0,16(sp)
    80001eb2:	64a2                	ld	s1,8(sp)
    80001eb4:	6902                	ld	s2,0(sp)
    80001eb6:	6105                	addi	sp,sp,32
    80001eb8:	8082                	ret

0000000080001eba <growproc>:
{
    80001eba:	7179                	addi	sp,sp,-48
    80001ebc:	f406                	sd	ra,40(sp)
    80001ebe:	f022                	sd	s0,32(sp)
    80001ec0:	ec26                	sd	s1,24(sp)
    80001ec2:	e84a                	sd	s2,16(sp)
    80001ec4:	e44e                	sd	s3,8(sp)
    80001ec6:	e052                	sd	s4,0(sp)
    80001ec8:	1800                	addi	s0,sp,48
    80001eca:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	c16080e7          	jalr	-1002(ra) # 80001ae2 <myproc>
    80001ed4:	84aa                	mv	s1,a0
  sz = p->sz;
    80001ed6:	652c                	ld	a1,72(a0)
    80001ed8:	0005861b          	sext.w	a2,a1
  if(n > 0)
    80001edc:	03204363          	bgtz	s2,80001f02 <growproc+0x48>
  else if(n < 0)
    80001ee0:	06094663          	bltz	s2,80001f4c <growproc+0x92>
  p->sz = sz;
    80001ee4:	02061913          	slli	s2,a2,0x20
    80001ee8:	02095913          	srli	s2,s2,0x20
    80001eec:	0524b423          	sd	s2,72(s1)
  return 0;
    80001ef0:	4501                	li	a0,0
}
    80001ef2:	70a2                	ld	ra,40(sp)
    80001ef4:	7402                	ld	s0,32(sp)
    80001ef6:	64e2                	ld	s1,24(sp)
    80001ef8:	6942                	ld	s2,16(sp)
    80001efa:	69a2                	ld	s3,8(sp)
    80001efc:	6a02                	ld	s4,0(sp)
    80001efe:	6145                	addi	sp,sp,48
    80001f00:	8082                	ret
    if((newsz = uvmalloc(p->pagetable, sz, sz + n)) == 0) 
    80001f02:	02059993          	slli	s3,a1,0x20
    80001f06:	0209d993          	srli	s3,s3,0x20
    80001f0a:	00c9063b          	addw	a2,s2,a2
    80001f0e:	1602                	slli	a2,a2,0x20
    80001f10:	9201                	srli	a2,a2,0x20
    80001f12:	85ce                	mv	a1,s3
    80001f14:	6928                	ld	a0,80(a0)
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	68e080e7          	jalr	1678(ra) # 800015a4 <uvmalloc>
    80001f1e:	8a2a                	mv	s4,a0
    80001f20:	c12d                	beqz	a0,80001f82 <growproc+0xc8>
    if(kvmcopy(p->pagetable, p->kernelpgt, sz, n) != 0) 
    80001f22:	86ca                	mv	a3,s2
    80001f24:	864e                	mv	a2,s3
    80001f26:	1684b583          	ld	a1,360(s1)
    80001f2a:	68a8                	ld	a0,80(s1)
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	494080e7          	jalr	1172(ra) # 800013c0 <kvmcopy>
    sz = newsz;
    80001f34:	000a061b          	sext.w	a2,s4
    if(kvmcopy(p->pagetable, p->kernelpgt, sz, n) != 0) 
    80001f38:	d555                	beqz	a0,80001ee4 <growproc+0x2a>
      uvmdealloc(p->pagetable, newsz, sz);
    80001f3a:	864e                	mv	a2,s3
    80001f3c:	85d2                	mv	a1,s4
    80001f3e:	68a8                	ld	a0,80(s1)
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	61c080e7          	jalr	1564(ra) # 8000155c <uvmdealloc>
      return -1;
    80001f48:	557d                	li	a0,-1
    80001f4a:	b765                	j	80001ef2 <growproc+0x38>
    uvmdealloc(p->pagetable, sz, sz + n);
    80001f4c:	02059993          	slli	s3,a1,0x20
    80001f50:	0209d993          	srli	s3,s3,0x20
    80001f54:	00c9093b          	addw	s2,s2,a2
    80001f58:	1902                	slli	s2,s2,0x20
    80001f5a:	02095913          	srli	s2,s2,0x20
    80001f5e:	864a                	mv	a2,s2
    80001f60:	85ce                	mv	a1,s3
    80001f62:	6928                	ld	a0,80(a0)
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	5f8080e7          	jalr	1528(ra) # 8000155c <uvmdealloc>
    sz = kvmdealloc(p->kernelpgt, sz, sz + n);
    80001f6c:	864a                	mv	a2,s2
    80001f6e:	85ce                	mv	a1,s3
    80001f70:	1684b503          	ld	a0,360(s1)
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	500080e7          	jalr	1280(ra) # 80001474 <kvmdealloc>
    80001f7c:	0005061b          	sext.w	a2,a0
    80001f80:	b795                	j	80001ee4 <growproc+0x2a>
      return -1;
    80001f82:	557d                	li	a0,-1
    80001f84:	b7bd                	j	80001ef2 <growproc+0x38>

0000000080001f86 <fork>:
{
    80001f86:	7179                	addi	sp,sp,-48
    80001f88:	f406                	sd	ra,40(sp)
    80001f8a:	f022                	sd	s0,32(sp)
    80001f8c:	ec26                	sd	s1,24(sp)
    80001f8e:	e84a                	sd	s2,16(sp)
    80001f90:	e44e                	sd	s3,8(sp)
    80001f92:	e052                	sd	s4,0(sp)
    80001f94:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f96:	00000097          	auipc	ra,0x0
    80001f9a:	b4c080e7          	jalr	-1204(ra) # 80001ae2 <myproc>
    80001f9e:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	d76080e7          	jalr	-650(ra) # 80001d16 <allocproc>
    80001fa8:	10050063          	beqz	a0,800020a8 <fork+0x122>
    80001fac:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    80001fae:	04893603          	ld	a2,72(s2) # 1048 <_entry-0x7fffefb8>
    80001fb2:	692c                	ld	a1,80(a0)
    80001fb4:	05093503          	ld	a0,80(s2)
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	892080e7          	jalr	-1902(ra) # 8000184a <uvmcopy>
    80001fc0:	06054563          	bltz	a0,8000202a <fork+0xa4>
  kvmcopy(np->pagetable, np->kernelpgt, 0, p->sz) < 0)
    80001fc4:	04893683          	ld	a3,72(s2)
    80001fc8:	4601                	li	a2,0
    80001fca:	1689b583          	ld	a1,360(s3)
    80001fce:	0509b503          	ld	a0,80(s3)
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	3ee080e7          	jalr	1006(ra) # 800013c0 <kvmcopy>
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    80001fda:	04054863          	bltz	a0,8000202a <fork+0xa4>
  np->sz = p->sz;
    80001fde:	04893783          	ld	a5,72(s2)
    80001fe2:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80001fe6:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001fea:	05893683          	ld	a3,88(s2)
    80001fee:	87b6                	mv	a5,a3
    80001ff0:	0589b703          	ld	a4,88(s3)
    80001ff4:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80001ff8:	0007b803          	ld	a6,0(a5)
    80001ffc:	6788                	ld	a0,8(a5)
    80001ffe:	6b8c                	ld	a1,16(a5)
    80002000:	6f90                	ld	a2,24(a5)
    80002002:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80002006:	e708                	sd	a0,8(a4)
    80002008:	eb0c                	sd	a1,16(a4)
    8000200a:	ef10                	sd	a2,24(a4)
    8000200c:	02078793          	addi	a5,a5,32
    80002010:	02070713          	addi	a4,a4,32
    80002014:	fed792e3          	bne	a5,a3,80001ff8 <fork+0x72>
  np->trapframe->a0 = 0;
    80002018:	0589b783          	ld	a5,88(s3)
    8000201c:	0607b823          	sd	zero,112(a5)
    80002020:	0d000493          	li	s1,208
  for (i = 0; i < NOFILE; i++)
    80002024:	15000a13          	li	s4,336
    80002028:	a03d                	j	80002056 <fork+0xd0>
    freeproc(np);
    8000202a:	854e                	mv	a0,s3
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	c68080e7          	jalr	-920(ra) # 80001c94 <freeproc>
    release(&np->lock);
    80002034:	854e                	mv	a0,s3
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	c8e080e7          	jalr	-882(ra) # 80000cc4 <release>
    return -1;
    8000203e:	54fd                	li	s1,-1
    80002040:	a899                	j	80002096 <fork+0x110>
      np->ofile[i] = filedup(p->ofile[i]);
    80002042:	00002097          	auipc	ra,0x2
    80002046:	624080e7          	jalr	1572(ra) # 80004666 <filedup>
    8000204a:	009987b3          	add	a5,s3,s1
    8000204e:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002050:	04a1                	addi	s1,s1,8
    80002052:	01448763          	beq	s1,s4,80002060 <fork+0xda>
    if (p->ofile[i])
    80002056:	009907b3          	add	a5,s2,s1
    8000205a:	6388                	ld	a0,0(a5)
    8000205c:	f17d                	bnez	a0,80002042 <fork+0xbc>
    8000205e:	bfcd                	j	80002050 <fork+0xca>
  np->cwd = idup(p->cwd);
    80002060:	15093503          	ld	a0,336(s2)
    80002064:	00001097          	auipc	ra,0x1
    80002068:	788080e7          	jalr	1928(ra) # 800037ec <idup>
    8000206c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002070:	4641                	li	a2,16
    80002072:	15890593          	addi	a1,s2,344
    80002076:	15898513          	addi	a0,s3,344
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	de8080e7          	jalr	-536(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80002082:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002086:	4789                	li	a5,2
    80002088:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000208c:	854e                	mv	a0,s3
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	c36080e7          	jalr	-970(ra) # 80000cc4 <release>
}
    80002096:	8526                	mv	a0,s1
    80002098:	70a2                	ld	ra,40(sp)
    8000209a:	7402                	ld	s0,32(sp)
    8000209c:	64e2                	ld	s1,24(sp)
    8000209e:	6942                	ld	s2,16(sp)
    800020a0:	69a2                	ld	s3,8(sp)
    800020a2:	6a02                	ld	s4,0(sp)
    800020a4:	6145                	addi	sp,sp,48
    800020a6:	8082                	ret
    return -1;
    800020a8:	54fd                	li	s1,-1
    800020aa:	b7f5                	j	80002096 <fork+0x110>

00000000800020ac <reparent>:
{
    800020ac:	7179                	addi	sp,sp,-48
    800020ae:	f406                	sd	ra,40(sp)
    800020b0:	f022                	sd	s0,32(sp)
    800020b2:	ec26                	sd	s1,24(sp)
    800020b4:	e84a                	sd	s2,16(sp)
    800020b6:	e44e                	sd	s3,8(sp)
    800020b8:	e052                	sd	s4,0(sp)
    800020ba:	1800                	addi	s0,sp,48
    800020bc:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800020be:	00010497          	auipc	s1,0x10
    800020c2:	caa48493          	addi	s1,s1,-854 # 80011d68 <proc>
      pp->parent = initproc;
    800020c6:	00007a17          	auipc	s4,0x7
    800020ca:	f52a0a13          	addi	s4,s4,-174 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800020ce:	00016997          	auipc	s3,0x16
    800020d2:	89a98993          	addi	s3,s3,-1894 # 80017968 <tickslock>
    800020d6:	a029                	j	800020e0 <reparent+0x34>
    800020d8:	17048493          	addi	s1,s1,368
    800020dc:	03348363          	beq	s1,s3,80002102 <reparent+0x56>
    if (pp->parent == p)
    800020e0:	709c                	ld	a5,32(s1)
    800020e2:	ff279be3          	bne	a5,s2,800020d8 <reparent+0x2c>
      acquire(&pp->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	b28080e7          	jalr	-1240(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    800020f0:	000a3783          	ld	a5,0(s4)
    800020f4:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	bcc080e7          	jalr	-1076(ra) # 80000cc4 <release>
    80002100:	bfe1                	j	800020d8 <reparent+0x2c>
}
    80002102:	70a2                	ld	ra,40(sp)
    80002104:	7402                	ld	s0,32(sp)
    80002106:	64e2                	ld	s1,24(sp)
    80002108:	6942                	ld	s2,16(sp)
    8000210a:	69a2                	ld	s3,8(sp)
    8000210c:	6a02                	ld	s4,0(sp)
    8000210e:	6145                	addi	sp,sp,48
    80002110:	8082                	ret

0000000080002112 <scheduler>:
{
    80002112:	715d                	addi	sp,sp,-80
    80002114:	e486                	sd	ra,72(sp)
    80002116:	e0a2                	sd	s0,64(sp)
    80002118:	fc26                	sd	s1,56(sp)
    8000211a:	f84a                	sd	s2,48(sp)
    8000211c:	f44e                	sd	s3,40(sp)
    8000211e:	f052                	sd	s4,32(sp)
    80002120:	ec56                	sd	s5,24(sp)
    80002122:	e85a                	sd	s6,16(sp)
    80002124:	e45e                	sd	s7,8(sp)
    80002126:	e062                	sd	s8,0(sp)
    80002128:	0880                	addi	s0,sp,80
    8000212a:	8792                	mv	a5,tp
  int id = r_tp();
    8000212c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000212e:	00779b13          	slli	s6,a5,0x7
    80002132:	00010717          	auipc	a4,0x10
    80002136:	81e70713          	addi	a4,a4,-2018 # 80011950 <pid_lock>
    8000213a:	975a                	add	a4,a4,s6
    8000213c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002140:	00010717          	auipc	a4,0x10
    80002144:	83070713          	addi	a4,a4,-2000 # 80011970 <cpus+0x8>
    80002148:	9b3a                	add	s6,s6,a4
        c->proc = p;
    8000214a:	079e                	slli	a5,a5,0x7
    8000214c:	00010a17          	auipc	s4,0x10
    80002150:	804a0a13          	addi	s4,s4,-2044 # 80011950 <pid_lock>
    80002154:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kernelpgt));
    80002156:	5bfd                	li	s7,-1
    80002158:	1bfe                	slli	s7,s7,0x3f
    for (p = proc; p < &proc[NPROC]; p++)
    8000215a:	00016997          	auipc	s3,0x16
    8000215e:	80e98993          	addi	s3,s3,-2034 # 80017968 <tickslock>
    80002162:	a885                	j	800021d2 <scheduler+0xc0>
        p->state = RUNNING;
    80002164:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002168:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kernelpgt));
    8000216c:	1684b783          	ld	a5,360(s1)
    80002170:	83b1                	srli	a5,a5,0xc
    80002172:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80002176:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000217a:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    8000217e:	06048593          	addi	a1,s1,96
    80002182:	855a                	mv	a0,s6
    80002184:	00000097          	auipc	ra,0x0
    80002188:	642080e7          	jalr	1602(ra) # 800027c6 <swtch>
        kvminithart();
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	e50080e7          	jalr	-432(ra) # 80000fdc <kvminithart>
        c->proc = 0;
    80002194:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002198:	4c05                	li	s8,1
      release(&p->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	b28080e7          	jalr	-1240(ra) # 80000cc4 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800021a4:	17048493          	addi	s1,s1,368
    800021a8:	01348b63          	beq	s1,s3,800021be <scheduler+0xac>
      acquire(&p->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	a62080e7          	jalr	-1438(ra) # 80000c10 <acquire>
      if (p->state == RUNNABLE)
    800021b6:	4c9c                	lw	a5,24(s1)
    800021b8:	ff2791e3          	bne	a5,s2,8000219a <scheduler+0x88>
    800021bc:	b765                	j	80002164 <scheduler+0x52>
    if (found == 0)
    800021be:	000c1a63          	bnez	s8,800021d2 <scheduler+0xc0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021c6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021ca:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800021ce:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021da:	10079073          	csrw	sstatus,a5
    int found = 0;
    800021de:	4c01                	li	s8,0
    for (p = proc; p < &proc[NPROC]; p++)
    800021e0:	00010497          	auipc	s1,0x10
    800021e4:	b8848493          	addi	s1,s1,-1144 # 80011d68 <proc>
      if (p->state == RUNNABLE)
    800021e8:	4909                	li	s2,2
        p->state = RUNNING;
    800021ea:	4a8d                	li	s5,3
    800021ec:	b7c1                	j	800021ac <scheduler+0x9a>

00000000800021ee <sched>:
{
    800021ee:	7179                	addi	sp,sp,-48
    800021f0:	f406                	sd	ra,40(sp)
    800021f2:	f022                	sd	s0,32(sp)
    800021f4:	ec26                	sd	s1,24(sp)
    800021f6:	e84a                	sd	s2,16(sp)
    800021f8:	e44e                	sd	s3,8(sp)
    800021fa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	8e6080e7          	jalr	-1818(ra) # 80001ae2 <myproc>
    80002204:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	990080e7          	jalr	-1648(ra) # 80000b96 <holding>
    8000220e:	c93d                	beqz	a0,80002284 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002210:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002212:	2781                	sext.w	a5,a5
    80002214:	079e                	slli	a5,a5,0x7
    80002216:	0000f717          	auipc	a4,0xf
    8000221a:	73a70713          	addi	a4,a4,1850 # 80011950 <pid_lock>
    8000221e:	97ba                	add	a5,a5,a4
    80002220:	0907a703          	lw	a4,144(a5)
    80002224:	4785                	li	a5,1
    80002226:	06f71763          	bne	a4,a5,80002294 <sched+0xa6>
  if (p->state == RUNNING)
    8000222a:	4c98                	lw	a4,24(s1)
    8000222c:	478d                	li	a5,3
    8000222e:	06f70b63          	beq	a4,a5,800022a4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002232:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002236:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002238:	efb5                	bnez	a5,800022b4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000223a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000223c:	0000f917          	auipc	s2,0xf
    80002240:	71490913          	addi	s2,s2,1812 # 80011950 <pid_lock>
    80002244:	2781                	sext.w	a5,a5
    80002246:	079e                	slli	a5,a5,0x7
    80002248:	97ca                	add	a5,a5,s2
    8000224a:	0947a983          	lw	s3,148(a5)
    8000224e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002250:	2781                	sext.w	a5,a5
    80002252:	079e                	slli	a5,a5,0x7
    80002254:	0000f597          	auipc	a1,0xf
    80002258:	71c58593          	addi	a1,a1,1820 # 80011970 <cpus+0x8>
    8000225c:	95be                	add	a1,a1,a5
    8000225e:	06048513          	addi	a0,s1,96
    80002262:	00000097          	auipc	ra,0x0
    80002266:	564080e7          	jalr	1380(ra) # 800027c6 <swtch>
    8000226a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000226c:	2781                	sext.w	a5,a5
    8000226e:	079e                	slli	a5,a5,0x7
    80002270:	97ca                	add	a5,a5,s2
    80002272:	0937aa23          	sw	s3,148(a5)
}
    80002276:	70a2                	ld	ra,40(sp)
    80002278:	7402                	ld	s0,32(sp)
    8000227a:	64e2                	ld	s1,24(sp)
    8000227c:	6942                	ld	s2,16(sp)
    8000227e:	69a2                	ld	s3,8(sp)
    80002280:	6145                	addi	sp,sp,48
    80002282:	8082                	ret
    panic("sched p->lock");
    80002284:	00006517          	auipc	a0,0x6
    80002288:	fe450513          	addi	a0,a0,-28 # 80008268 <digits+0x238>
    8000228c:	ffffe097          	auipc	ra,0xffffe
    80002290:	2bc080e7          	jalr	700(ra) # 80000548 <panic>
    panic("sched locks");
    80002294:	00006517          	auipc	a0,0x6
    80002298:	fe450513          	addi	a0,a0,-28 # 80008278 <digits+0x248>
    8000229c:	ffffe097          	auipc	ra,0xffffe
    800022a0:	2ac080e7          	jalr	684(ra) # 80000548 <panic>
    panic("sched running");
    800022a4:	00006517          	auipc	a0,0x6
    800022a8:	fe450513          	addi	a0,a0,-28 # 80008288 <digits+0x258>
    800022ac:	ffffe097          	auipc	ra,0xffffe
    800022b0:	29c080e7          	jalr	668(ra) # 80000548 <panic>
    panic("sched interruptible");
    800022b4:	00006517          	auipc	a0,0x6
    800022b8:	fe450513          	addi	a0,a0,-28 # 80008298 <digits+0x268>
    800022bc:	ffffe097          	auipc	ra,0xffffe
    800022c0:	28c080e7          	jalr	652(ra) # 80000548 <panic>

00000000800022c4 <exit>:
{
    800022c4:	7179                	addi	sp,sp,-48
    800022c6:	f406                	sd	ra,40(sp)
    800022c8:	f022                	sd	s0,32(sp)
    800022ca:	ec26                	sd	s1,24(sp)
    800022cc:	e84a                	sd	s2,16(sp)
    800022ce:	e44e                	sd	s3,8(sp)
    800022d0:	e052                	sd	s4,0(sp)
    800022d2:	1800                	addi	s0,sp,48
    800022d4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	80c080e7          	jalr	-2036(ra) # 80001ae2 <myproc>
    800022de:	89aa                	mv	s3,a0
  if (p == initproc)
    800022e0:	00007797          	auipc	a5,0x7
    800022e4:	d387b783          	ld	a5,-712(a5) # 80009018 <initproc>
    800022e8:	0d050493          	addi	s1,a0,208
    800022ec:	15050913          	addi	s2,a0,336
    800022f0:	02a79363          	bne	a5,a0,80002316 <exit+0x52>
    panic("init exiting");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	fbc50513          	addi	a0,a0,-68 # 800082b0 <digits+0x280>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	24c080e7          	jalr	588(ra) # 80000548 <panic>
      fileclose(f);
    80002304:	00002097          	auipc	ra,0x2
    80002308:	3b4080e7          	jalr	948(ra) # 800046b8 <fileclose>
      p->ofile[fd] = 0;
    8000230c:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002310:	04a1                	addi	s1,s1,8
    80002312:	01248563          	beq	s1,s2,8000231c <exit+0x58>
    if (p->ofile[fd])
    80002316:	6088                	ld	a0,0(s1)
    80002318:	f575                	bnez	a0,80002304 <exit+0x40>
    8000231a:	bfdd                	j	80002310 <exit+0x4c>
  begin_op();
    8000231c:	00002097          	auipc	ra,0x2
    80002320:	eca080e7          	jalr	-310(ra) # 800041e6 <begin_op>
  iput(p->cwd);
    80002324:	1509b503          	ld	a0,336(s3)
    80002328:	00001097          	auipc	ra,0x1
    8000232c:	6bc080e7          	jalr	1724(ra) # 800039e4 <iput>
  end_op();
    80002330:	00002097          	auipc	ra,0x2
    80002334:	f36080e7          	jalr	-202(ra) # 80004266 <end_op>
  p->cwd = 0;
    80002338:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000233c:	00007497          	auipc	s1,0x7
    80002340:	cdc48493          	addi	s1,s1,-804 # 80009018 <initproc>
    80002344:	6088                	ld	a0,0(s1)
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	8ca080e7          	jalr	-1846(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000234e:	6088                	ld	a0,0(s1)
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	6ba080e7          	jalr	1722(ra) # 80001a0a <wakeup1>
  release(&initproc->lock);
    80002358:	6088                	ld	a0,0(s1)
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	96a080e7          	jalr	-1686(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002362:	854e                	mv	a0,s3
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	8ac080e7          	jalr	-1876(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000236c:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002370:	854e                	mv	a0,s3
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	952080e7          	jalr	-1710(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	894080e7          	jalr	-1900(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002384:	854e                	mv	a0,s3
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	88a080e7          	jalr	-1910(ra) # 80000c10 <acquire>
  reparent(p);
    8000238e:	854e                	mv	a0,s3
    80002390:	00000097          	auipc	ra,0x0
    80002394:	d1c080e7          	jalr	-740(ra) # 800020ac <reparent>
  wakeup1(original_parent);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	670080e7          	jalr	1648(ra) # 80001a0a <wakeup1>
  p->xstate = status;
    800023a2:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800023a6:	4791                	li	a5,4
    800023a8:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	916080e7          	jalr	-1770(ra) # 80000cc4 <release>
  sched();
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	e38080e7          	jalr	-456(ra) # 800021ee <sched>
  panic("zombie exit");
    800023be:	00006517          	auipc	a0,0x6
    800023c2:	f0250513          	addi	a0,a0,-254 # 800082c0 <digits+0x290>
    800023c6:	ffffe097          	auipc	ra,0xffffe
    800023ca:	182080e7          	jalr	386(ra) # 80000548 <panic>

00000000800023ce <yield>:
{
    800023ce:	1101                	addi	sp,sp,-32
    800023d0:	ec06                	sd	ra,24(sp)
    800023d2:	e822                	sd	s0,16(sp)
    800023d4:	e426                	sd	s1,8(sp)
    800023d6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	70a080e7          	jalr	1802(ra) # 80001ae2 <myproc>
    800023e0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	82e080e7          	jalr	-2002(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800023ea:	4789                	li	a5,2
    800023ec:	cc9c                	sw	a5,24(s1)
  sched();
    800023ee:	00000097          	auipc	ra,0x0
    800023f2:	e00080e7          	jalr	-512(ra) # 800021ee <sched>
  release(&p->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	8cc080e7          	jalr	-1844(ra) # 80000cc4 <release>
}
    80002400:	60e2                	ld	ra,24(sp)
    80002402:	6442                	ld	s0,16(sp)
    80002404:	64a2                	ld	s1,8(sp)
    80002406:	6105                	addi	sp,sp,32
    80002408:	8082                	ret

000000008000240a <sleep>:
{
    8000240a:	7179                	addi	sp,sp,-48
    8000240c:	f406                	sd	ra,40(sp)
    8000240e:	f022                	sd	s0,32(sp)
    80002410:	ec26                	sd	s1,24(sp)
    80002412:	e84a                	sd	s2,16(sp)
    80002414:	e44e                	sd	s3,8(sp)
    80002416:	1800                	addi	s0,sp,48
    80002418:	89aa                	mv	s3,a0
    8000241a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	6c6080e7          	jalr	1734(ra) # 80001ae2 <myproc>
    80002424:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    80002426:	05250663          	beq	a0,s2,80002472 <sleep+0x68>
    acquire(&p->lock); // DOC: sleeplock1
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	7e6080e7          	jalr	2022(ra) # 80000c10 <acquire>
    release(lk);
    80002432:	854a                	mv	a0,s2
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	890080e7          	jalr	-1904(ra) # 80000cc4 <release>
  p->chan = chan;
    8000243c:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002440:	4785                	li	a5,1
    80002442:	cc9c                	sw	a5,24(s1)
  sched();
    80002444:	00000097          	auipc	ra,0x0
    80002448:	daa080e7          	jalr	-598(ra) # 800021ee <sched>
  p->chan = 0;
    8000244c:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	872080e7          	jalr	-1934(ra) # 80000cc4 <release>
    acquire(lk);
    8000245a:	854a                	mv	a0,s2
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	7b4080e7          	jalr	1972(ra) # 80000c10 <acquire>
}
    80002464:	70a2                	ld	ra,40(sp)
    80002466:	7402                	ld	s0,32(sp)
    80002468:	64e2                	ld	s1,24(sp)
    8000246a:	6942                	ld	s2,16(sp)
    8000246c:	69a2                	ld	s3,8(sp)
    8000246e:	6145                	addi	sp,sp,48
    80002470:	8082                	ret
  p->chan = chan;
    80002472:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002476:	4785                	li	a5,1
    80002478:	cd1c                	sw	a5,24(a0)
  sched();
    8000247a:	00000097          	auipc	ra,0x0
    8000247e:	d74080e7          	jalr	-652(ra) # 800021ee <sched>
  p->chan = 0;
    80002482:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    80002486:	bff9                	j	80002464 <sleep+0x5a>

0000000080002488 <wait>:
{
    80002488:	715d                	addi	sp,sp,-80
    8000248a:	e486                	sd	ra,72(sp)
    8000248c:	e0a2                	sd	s0,64(sp)
    8000248e:	fc26                	sd	s1,56(sp)
    80002490:	f84a                	sd	s2,48(sp)
    80002492:	f44e                	sd	s3,40(sp)
    80002494:	f052                	sd	s4,32(sp)
    80002496:	ec56                	sd	s5,24(sp)
    80002498:	e85a                	sd	s6,16(sp)
    8000249a:	e45e                	sd	s7,8(sp)
    8000249c:	e062                	sd	s8,0(sp)
    8000249e:	0880                	addi	s0,sp,80
    800024a0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	640080e7          	jalr	1600(ra) # 80001ae2 <myproc>
    800024aa:	892a                	mv	s2,a0
  acquire(&p->lock);
    800024ac:	8c2a                	mv	s8,a0
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	762080e7          	jalr	1890(ra) # 80000c10 <acquire>
    havekids = 0;
    800024b6:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800024b8:	4a11                	li	s4,4
    for (np = proc; np < &proc[NPROC]; np++)
    800024ba:	00015997          	auipc	s3,0x15
    800024be:	4ae98993          	addi	s3,s3,1198 # 80017968 <tickslock>
        havekids = 1;
    800024c2:	4a85                	li	s5,1
    havekids = 0;
    800024c4:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800024c6:	00010497          	auipc	s1,0x10
    800024ca:	8a248493          	addi	s1,s1,-1886 # 80011d68 <proc>
    800024ce:	a08d                	j	80002530 <wait+0xa8>
          pid = np->pid;
    800024d0:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024d4:	000b0e63          	beqz	s6,800024f0 <wait+0x68>
    800024d8:	4691                	li	a3,4
    800024da:	03448613          	addi	a2,s1,52
    800024de:	85da                	mv	a1,s6
    800024e0:	05093503          	ld	a0,80(s2)
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	46a080e7          	jalr	1130(ra) # 8000194e <copyout>
    800024ec:	02054263          	bltz	a0,80002510 <wait+0x88>
          freeproc(np);
    800024f0:	8526                	mv	a0,s1
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	7a2080e7          	jalr	1954(ra) # 80001c94 <freeproc>
          release(&np->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	7c8080e7          	jalr	1992(ra) # 80000cc4 <release>
          release(&p->lock);
    80002504:	854a                	mv	a0,s2
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	7be080e7          	jalr	1982(ra) # 80000cc4 <release>
          return pid;
    8000250e:	a8a9                	j	80002568 <wait+0xe0>
            release(&np->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	7b2080e7          	jalr	1970(ra) # 80000cc4 <release>
            release(&p->lock);
    8000251a:	854a                	mv	a0,s2
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	7a8080e7          	jalr	1960(ra) # 80000cc4 <release>
            return -1;
    80002524:	59fd                	li	s3,-1
    80002526:	a089                	j	80002568 <wait+0xe0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002528:	17048493          	addi	s1,s1,368
    8000252c:	03348463          	beq	s1,s3,80002554 <wait+0xcc>
      if (np->parent == p)
    80002530:	709c                	ld	a5,32(s1)
    80002532:	ff279be3          	bne	a5,s2,80002528 <wait+0xa0>
        acquire(&np->lock);
    80002536:	8526                	mv	a0,s1
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	6d8080e7          	jalr	1752(ra) # 80000c10 <acquire>
        if (np->state == ZOMBIE)
    80002540:	4c9c                	lw	a5,24(s1)
    80002542:	f94787e3          	beq	a5,s4,800024d0 <wait+0x48>
        release(&np->lock);
    80002546:	8526                	mv	a0,s1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	77c080e7          	jalr	1916(ra) # 80000cc4 <release>
        havekids = 1;
    80002550:	8756                	mv	a4,s5
    80002552:	bfd9                	j	80002528 <wait+0xa0>
    if (!havekids || p->killed)
    80002554:	c701                	beqz	a4,8000255c <wait+0xd4>
    80002556:	03092783          	lw	a5,48(s2)
    8000255a:	c785                	beqz	a5,80002582 <wait+0xfa>
      release(&p->lock);
    8000255c:	854a                	mv	a0,s2
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	766080e7          	jalr	1894(ra) # 80000cc4 <release>
      return -1;
    80002566:	59fd                	li	s3,-1
}
    80002568:	854e                	mv	a0,s3
    8000256a:	60a6                	ld	ra,72(sp)
    8000256c:	6406                	ld	s0,64(sp)
    8000256e:	74e2                	ld	s1,56(sp)
    80002570:	7942                	ld	s2,48(sp)
    80002572:	79a2                	ld	s3,40(sp)
    80002574:	7a02                	ld	s4,32(sp)
    80002576:	6ae2                	ld	s5,24(sp)
    80002578:	6b42                	ld	s6,16(sp)
    8000257a:	6ba2                	ld	s7,8(sp)
    8000257c:	6c02                	ld	s8,0(sp)
    8000257e:	6161                	addi	sp,sp,80
    80002580:	8082                	ret
    sleep(p, &p->lock); // DOC: wait-sleep
    80002582:	85e2                	mv	a1,s8
    80002584:	854a                	mv	a0,s2
    80002586:	00000097          	auipc	ra,0x0
    8000258a:	e84080e7          	jalr	-380(ra) # 8000240a <sleep>
    havekids = 0;
    8000258e:	bf1d                	j	800024c4 <wait+0x3c>

0000000080002590 <wakeup>:
{
    80002590:	7139                	addi	sp,sp,-64
    80002592:	fc06                	sd	ra,56(sp)
    80002594:	f822                	sd	s0,48(sp)
    80002596:	f426                	sd	s1,40(sp)
    80002598:	f04a                	sd	s2,32(sp)
    8000259a:	ec4e                	sd	s3,24(sp)
    8000259c:	e852                	sd	s4,16(sp)
    8000259e:	e456                	sd	s5,8(sp)
    800025a0:	0080                	addi	s0,sp,64
    800025a2:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800025a4:	0000f497          	auipc	s1,0xf
    800025a8:	7c448493          	addi	s1,s1,1988 # 80011d68 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800025ac:	4985                	li	s3,1
      p->state = RUNNABLE;
    800025ae:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    800025b0:	00015917          	auipc	s2,0x15
    800025b4:	3b890913          	addi	s2,s2,952 # 80017968 <tickslock>
    800025b8:	a821                	j	800025d0 <wakeup+0x40>
      p->state = RUNNABLE;
    800025ba:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	704080e7          	jalr	1796(ra) # 80000cc4 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025c8:	17048493          	addi	s1,s1,368
    800025cc:	01248e63          	beq	s1,s2,800025e8 <wakeup+0x58>
    acquire(&p->lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	63e080e7          	jalr	1598(ra) # 80000c10 <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    800025da:	4c9c                	lw	a5,24(s1)
    800025dc:	ff3791e3          	bne	a5,s3,800025be <wakeup+0x2e>
    800025e0:	749c                	ld	a5,40(s1)
    800025e2:	fd479ee3          	bne	a5,s4,800025be <wakeup+0x2e>
    800025e6:	bfd1                	j	800025ba <wakeup+0x2a>
}
    800025e8:	70e2                	ld	ra,56(sp)
    800025ea:	7442                	ld	s0,48(sp)
    800025ec:	74a2                	ld	s1,40(sp)
    800025ee:	7902                	ld	s2,32(sp)
    800025f0:	69e2                	ld	s3,24(sp)
    800025f2:	6a42                	ld	s4,16(sp)
    800025f4:	6aa2                	ld	s5,8(sp)
    800025f6:	6121                	addi	sp,sp,64
    800025f8:	8082                	ret

00000000800025fa <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025fa:	7179                	addi	sp,sp,-48
    800025fc:	f406                	sd	ra,40(sp)
    800025fe:	f022                	sd	s0,32(sp)
    80002600:	ec26                	sd	s1,24(sp)
    80002602:	e84a                	sd	s2,16(sp)
    80002604:	e44e                	sd	s3,8(sp)
    80002606:	1800                	addi	s0,sp,48
    80002608:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000260a:	0000f497          	auipc	s1,0xf
    8000260e:	75e48493          	addi	s1,s1,1886 # 80011d68 <proc>
    80002612:	00015997          	auipc	s3,0x15
    80002616:	35698993          	addi	s3,s3,854 # 80017968 <tickslock>
  {
    acquire(&p->lock);
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	5f4080e7          	jalr	1524(ra) # 80000c10 <acquire>
    if (p->pid == pid)
    80002624:	5c9c                	lw	a5,56(s1)
    80002626:	01278d63          	beq	a5,s2,80002640 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000262a:	8526                	mv	a0,s1
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	698080e7          	jalr	1688(ra) # 80000cc4 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002634:	17048493          	addi	s1,s1,368
    80002638:	ff3491e3          	bne	s1,s3,8000261a <kill+0x20>
  }
  return -1;
    8000263c:	557d                	li	a0,-1
    8000263e:	a829                	j	80002658 <kill+0x5e>
      p->killed = 1;
    80002640:	4785                	li	a5,1
    80002642:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    80002644:	4c98                	lw	a4,24(s1)
    80002646:	4785                	li	a5,1
    80002648:	00f70f63          	beq	a4,a5,80002666 <kill+0x6c>
      release(&p->lock);
    8000264c:	8526                	mv	a0,s1
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	676080e7          	jalr	1654(ra) # 80000cc4 <release>
      return 0;
    80002656:	4501                	li	a0,0
}
    80002658:	70a2                	ld	ra,40(sp)
    8000265a:	7402                	ld	s0,32(sp)
    8000265c:	64e2                	ld	s1,24(sp)
    8000265e:	6942                	ld	s2,16(sp)
    80002660:	69a2                	ld	s3,8(sp)
    80002662:	6145                	addi	sp,sp,48
    80002664:	8082                	ret
        p->state = RUNNABLE;
    80002666:	4789                	li	a5,2
    80002668:	cc9c                	sw	a5,24(s1)
    8000266a:	b7cd                	j	8000264c <kill+0x52>

000000008000266c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000266c:	7179                	addi	sp,sp,-48
    8000266e:	f406                	sd	ra,40(sp)
    80002670:	f022                	sd	s0,32(sp)
    80002672:	ec26                	sd	s1,24(sp)
    80002674:	e84a                	sd	s2,16(sp)
    80002676:	e44e                	sd	s3,8(sp)
    80002678:	e052                	sd	s4,0(sp)
    8000267a:	1800                	addi	s0,sp,48
    8000267c:	84aa                	mv	s1,a0
    8000267e:	892e                	mv	s2,a1
    80002680:	89b2                	mv	s3,a2
    80002682:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	45e080e7          	jalr	1118(ra) # 80001ae2 <myproc>
  if (user_dst)
    8000268c:	c08d                	beqz	s1,800026ae <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000268e:	86d2                	mv	a3,s4
    80002690:	864e                	mv	a2,s3
    80002692:	85ca                	mv	a1,s2
    80002694:	6928                	ld	a0,80(a0)
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	2b8080e7          	jalr	696(ra) # 8000194e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000269e:	70a2                	ld	ra,40(sp)
    800026a0:	7402                	ld	s0,32(sp)
    800026a2:	64e2                	ld	s1,24(sp)
    800026a4:	6942                	ld	s2,16(sp)
    800026a6:	69a2                	ld	s3,8(sp)
    800026a8:	6a02                	ld	s4,0(sp)
    800026aa:	6145                	addi	sp,sp,48
    800026ac:	8082                	ret
    memmove((char *)dst, src, len);
    800026ae:	000a061b          	sext.w	a2,s4
    800026b2:	85ce                	mv	a1,s3
    800026b4:	854a                	mv	a0,s2
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	6b6080e7          	jalr	1718(ra) # 80000d6c <memmove>
    return 0;
    800026be:	8526                	mv	a0,s1
    800026c0:	bff9                	j	8000269e <either_copyout+0x32>

00000000800026c2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026c2:	7179                	addi	sp,sp,-48
    800026c4:	f406                	sd	ra,40(sp)
    800026c6:	f022                	sd	s0,32(sp)
    800026c8:	ec26                	sd	s1,24(sp)
    800026ca:	e84a                	sd	s2,16(sp)
    800026cc:	e44e                	sd	s3,8(sp)
    800026ce:	e052                	sd	s4,0(sp)
    800026d0:	1800                	addi	s0,sp,48
    800026d2:	892a                	mv	s2,a0
    800026d4:	84ae                	mv	s1,a1
    800026d6:	89b2                	mv	s3,a2
    800026d8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	408080e7          	jalr	1032(ra) # 80001ae2 <myproc>
  if (user_src)
    800026e2:	c08d                	beqz	s1,80002704 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026e4:	86d2                	mv	a3,s4
    800026e6:	864e                	mv	a2,s3
    800026e8:	85ca                	mv	a1,s2
    800026ea:	6928                	ld	a0,80(a0)
    800026ec:	fffff097          	auipc	ra,0xfffff
    800026f0:	2ee080e7          	jalr	750(ra) # 800019da <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026f4:	70a2                	ld	ra,40(sp)
    800026f6:	7402                	ld	s0,32(sp)
    800026f8:	64e2                	ld	s1,24(sp)
    800026fa:	6942                	ld	s2,16(sp)
    800026fc:	69a2                	ld	s3,8(sp)
    800026fe:	6a02                	ld	s4,0(sp)
    80002700:	6145                	addi	sp,sp,48
    80002702:	8082                	ret
    memmove(dst, (char *)src, len);
    80002704:	000a061b          	sext.w	a2,s4
    80002708:	85ce                	mv	a1,s3
    8000270a:	854a                	mv	a0,s2
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	660080e7          	jalr	1632(ra) # 80000d6c <memmove>
    return 0;
    80002714:	8526                	mv	a0,s1
    80002716:	bff9                	j	800026f4 <either_copyin+0x32>

0000000080002718 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002718:	715d                	addi	sp,sp,-80
    8000271a:	e486                	sd	ra,72(sp)
    8000271c:	e0a2                	sd	s0,64(sp)
    8000271e:	fc26                	sd	s1,56(sp)
    80002720:	f84a                	sd	s2,48(sp)
    80002722:	f44e                	sd	s3,40(sp)
    80002724:	f052                	sd	s4,32(sp)
    80002726:	ec56                	sd	s5,24(sp)
    80002728:	e85a                	sd	s6,16(sp)
    8000272a:	e45e                	sd	s7,8(sp)
    8000272c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000272e:	00006517          	auipc	a0,0x6
    80002732:	98a50513          	addi	a0,a0,-1654 # 800080b8 <digits+0x88>
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	e5c080e7          	jalr	-420(ra) # 80000592 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000273e:	0000f497          	auipc	s1,0xf
    80002742:	78248493          	addi	s1,s1,1922 # 80011ec0 <proc+0x158>
    80002746:	00015917          	auipc	s2,0x15
    8000274a:	37a90913          	addi	s2,s2,890 # 80017ac0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000274e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002750:	00006997          	auipc	s3,0x6
    80002754:	b8098993          	addi	s3,s3,-1152 # 800082d0 <digits+0x2a0>
    printf("%d %s %s", p->pid, state, p->name);
    80002758:	00006a97          	auipc	s5,0x6
    8000275c:	b80a8a93          	addi	s5,s5,-1152 # 800082d8 <digits+0x2a8>
    printf("\n");
    80002760:	00006a17          	auipc	s4,0x6
    80002764:	958a0a13          	addi	s4,s4,-1704 # 800080b8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002768:	00006b97          	auipc	s7,0x6
    8000276c:	ba8b8b93          	addi	s7,s7,-1112 # 80008310 <states.1739>
    80002770:	a00d                	j	80002792 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002772:	ee06a583          	lw	a1,-288(a3)
    80002776:	8556                	mv	a0,s5
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	e1a080e7          	jalr	-486(ra) # 80000592 <printf>
    printf("\n");
    80002780:	8552                	mv	a0,s4
    80002782:	ffffe097          	auipc	ra,0xffffe
    80002786:	e10080e7          	jalr	-496(ra) # 80000592 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000278a:	17048493          	addi	s1,s1,368
    8000278e:	03248163          	beq	s1,s2,800027b0 <procdump+0x98>
    if (p->state == UNUSED)
    80002792:	86a6                	mv	a3,s1
    80002794:	ec04a783          	lw	a5,-320(s1)
    80002798:	dbed                	beqz	a5,8000278a <procdump+0x72>
      state = "???";
    8000279a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279c:	fcfb6be3          	bltu	s6,a5,80002772 <procdump+0x5a>
    800027a0:	1782                	slli	a5,a5,0x20
    800027a2:	9381                	srli	a5,a5,0x20
    800027a4:	078e                	slli	a5,a5,0x3
    800027a6:	97de                	add	a5,a5,s7
    800027a8:	6390                	ld	a2,0(a5)
    800027aa:	f661                	bnez	a2,80002772 <procdump+0x5a>
      state = "???";
    800027ac:	864e                	mv	a2,s3
    800027ae:	b7d1                	j	80002772 <procdump+0x5a>
  }
}
    800027b0:	60a6                	ld	ra,72(sp)
    800027b2:	6406                	ld	s0,64(sp)
    800027b4:	74e2                	ld	s1,56(sp)
    800027b6:	7942                	ld	s2,48(sp)
    800027b8:	79a2                	ld	s3,40(sp)
    800027ba:	7a02                	ld	s4,32(sp)
    800027bc:	6ae2                	ld	s5,24(sp)
    800027be:	6b42                	ld	s6,16(sp)
    800027c0:	6ba2                	ld	s7,8(sp)
    800027c2:	6161                	addi	sp,sp,80
    800027c4:	8082                	ret

00000000800027c6 <swtch>:
    800027c6:	00153023          	sd	ra,0(a0)
    800027ca:	00253423          	sd	sp,8(a0)
    800027ce:	e900                	sd	s0,16(a0)
    800027d0:	ed04                	sd	s1,24(a0)
    800027d2:	03253023          	sd	s2,32(a0)
    800027d6:	03353423          	sd	s3,40(a0)
    800027da:	03453823          	sd	s4,48(a0)
    800027de:	03553c23          	sd	s5,56(a0)
    800027e2:	05653023          	sd	s6,64(a0)
    800027e6:	05753423          	sd	s7,72(a0)
    800027ea:	05853823          	sd	s8,80(a0)
    800027ee:	05953c23          	sd	s9,88(a0)
    800027f2:	07a53023          	sd	s10,96(a0)
    800027f6:	07b53423          	sd	s11,104(a0)
    800027fa:	0005b083          	ld	ra,0(a1)
    800027fe:	0085b103          	ld	sp,8(a1)
    80002802:	6980                	ld	s0,16(a1)
    80002804:	6d84                	ld	s1,24(a1)
    80002806:	0205b903          	ld	s2,32(a1)
    8000280a:	0285b983          	ld	s3,40(a1)
    8000280e:	0305ba03          	ld	s4,48(a1)
    80002812:	0385ba83          	ld	s5,56(a1)
    80002816:	0405bb03          	ld	s6,64(a1)
    8000281a:	0485bb83          	ld	s7,72(a1)
    8000281e:	0505bc03          	ld	s8,80(a1)
    80002822:	0585bc83          	ld	s9,88(a1)
    80002826:	0605bd03          	ld	s10,96(a1)
    8000282a:	0685bd83          	ld	s11,104(a1)
    8000282e:	8082                	ret

0000000080002830 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002830:	1141                	addi	sp,sp,-16
    80002832:	e406                	sd	ra,8(sp)
    80002834:	e022                	sd	s0,0(sp)
    80002836:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002838:	00006597          	auipc	a1,0x6
    8000283c:	b0058593          	addi	a1,a1,-1280 # 80008338 <states.1739+0x28>
    80002840:	00015517          	auipc	a0,0x15
    80002844:	12850513          	addi	a0,a0,296 # 80017968 <tickslock>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	338080e7          	jalr	824(ra) # 80000b80 <initlock>
}
    80002850:	60a2                	ld	ra,8(sp)
    80002852:	6402                	ld	s0,0(sp)
    80002854:	0141                	addi	sp,sp,16
    80002856:	8082                	ret

0000000080002858 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002858:	1141                	addi	sp,sp,-16
    8000285a:	e422                	sd	s0,8(sp)
    8000285c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000285e:	00003797          	auipc	a5,0x3
    80002862:	53278793          	addi	a5,a5,1330 # 80005d90 <kernelvec>
    80002866:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000286a:	6422                	ld	s0,8(sp)
    8000286c:	0141                	addi	sp,sp,16
    8000286e:	8082                	ret

0000000080002870 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002870:	1141                	addi	sp,sp,-16
    80002872:	e406                	sd	ra,8(sp)
    80002874:	e022                	sd	s0,0(sp)
    80002876:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002878:	fffff097          	auipc	ra,0xfffff
    8000287c:	26a080e7          	jalr	618(ra) # 80001ae2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002880:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002884:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002886:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000288a:	00004617          	auipc	a2,0x4
    8000288e:	77660613          	addi	a2,a2,1910 # 80007000 <_trampoline>
    80002892:	00004697          	auipc	a3,0x4
    80002896:	76e68693          	addi	a3,a3,1902 # 80007000 <_trampoline>
    8000289a:	8e91                	sub	a3,a3,a2
    8000289c:	040007b7          	lui	a5,0x4000
    800028a0:	17fd                	addi	a5,a5,-1
    800028a2:	07b2                	slli	a5,a5,0xc
    800028a4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028ac:	180026f3          	csrr	a3,satp
    800028b0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028b2:	6d38                	ld	a4,88(a0)
    800028b4:	6134                	ld	a3,64(a0)
    800028b6:	6585                	lui	a1,0x1
    800028b8:	96ae                	add	a3,a3,a1
    800028ba:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028bc:	6d38                	ld	a4,88(a0)
    800028be:	00000697          	auipc	a3,0x0
    800028c2:	13868693          	addi	a3,a3,312 # 800029f6 <usertrap>
    800028c6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028c8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ca:	8692                	mv	a3,tp
    800028cc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ce:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028d2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028d6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028da:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028de:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028e0:	6f18                	ld	a4,24(a4)
    800028e2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028e6:	692c                	ld	a1,80(a0)
    800028e8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028ea:	00004717          	auipc	a4,0x4
    800028ee:	7a670713          	addi	a4,a4,1958 # 80007090 <userret>
    800028f2:	8f11                	sub	a4,a4,a2
    800028f4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028f6:	577d                	li	a4,-1
    800028f8:	177e                	slli	a4,a4,0x3f
    800028fa:	8dd9                	or	a1,a1,a4
    800028fc:	02000537          	lui	a0,0x2000
    80002900:	157d                	addi	a0,a0,-1
    80002902:	0536                	slli	a0,a0,0xd
    80002904:	9782                	jalr	a5
}
    80002906:	60a2                	ld	ra,8(sp)
    80002908:	6402                	ld	s0,0(sp)
    8000290a:	0141                	addi	sp,sp,16
    8000290c:	8082                	ret

000000008000290e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000290e:	1101                	addi	sp,sp,-32
    80002910:	ec06                	sd	ra,24(sp)
    80002912:	e822                	sd	s0,16(sp)
    80002914:	e426                	sd	s1,8(sp)
    80002916:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002918:	00015497          	auipc	s1,0x15
    8000291c:	05048493          	addi	s1,s1,80 # 80017968 <tickslock>
    80002920:	8526                	mv	a0,s1
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	2ee080e7          	jalr	750(ra) # 80000c10 <acquire>
  ticks++;
    8000292a:	00006517          	auipc	a0,0x6
    8000292e:	6f650513          	addi	a0,a0,1782 # 80009020 <ticks>
    80002932:	411c                	lw	a5,0(a0)
    80002934:	2785                	addiw	a5,a5,1
    80002936:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	c58080e7          	jalr	-936(ra) # 80002590 <wakeup>
  release(&tickslock);
    80002940:	8526                	mv	a0,s1
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	382080e7          	jalr	898(ra) # 80000cc4 <release>
}
    8000294a:	60e2                	ld	ra,24(sp)
    8000294c:	6442                	ld	s0,16(sp)
    8000294e:	64a2                	ld	s1,8(sp)
    80002950:	6105                	addi	sp,sp,32
    80002952:	8082                	ret

0000000080002954 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002954:	1101                	addi	sp,sp,-32
    80002956:	ec06                	sd	ra,24(sp)
    80002958:	e822                	sd	s0,16(sp)
    8000295a:	e426                	sd	s1,8(sp)
    8000295c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002962:	00074d63          	bltz	a4,8000297c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002966:	57fd                	li	a5,-1
    80002968:	17fe                	slli	a5,a5,0x3f
    8000296a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000296c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000296e:	06f70363          	beq	a4,a5,800029d4 <devintr+0x80>
  }
}
    80002972:	60e2                	ld	ra,24(sp)
    80002974:	6442                	ld	s0,16(sp)
    80002976:	64a2                	ld	s1,8(sp)
    80002978:	6105                	addi	sp,sp,32
    8000297a:	8082                	ret
     (scause & 0xff) == 9){
    8000297c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002980:	46a5                	li	a3,9
    80002982:	fed792e3          	bne	a5,a3,80002966 <devintr+0x12>
    int irq = plic_claim();
    80002986:	00003097          	auipc	ra,0x3
    8000298a:	512080e7          	jalr	1298(ra) # 80005e98 <plic_claim>
    8000298e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002990:	47a9                	li	a5,10
    80002992:	02f50763          	beq	a0,a5,800029c0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002996:	4785                	li	a5,1
    80002998:	02f50963          	beq	a0,a5,800029ca <devintr+0x76>
    return 1;
    8000299c:	4505                	li	a0,1
    } else if(irq){
    8000299e:	d8f1                	beqz	s1,80002972 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029a0:	85a6                	mv	a1,s1
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	99e50513          	addi	a0,a0,-1634 # 80008340 <states.1739+0x30>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	be8080e7          	jalr	-1048(ra) # 80000592 <printf>
      plic_complete(irq);
    800029b2:	8526                	mv	a0,s1
    800029b4:	00003097          	auipc	ra,0x3
    800029b8:	508080e7          	jalr	1288(ra) # 80005ebc <plic_complete>
    return 1;
    800029bc:	4505                	li	a0,1
    800029be:	bf55                	j	80002972 <devintr+0x1e>
      uartintr();
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	014080e7          	jalr	20(ra) # 800009d4 <uartintr>
    800029c8:	b7ed                	j	800029b2 <devintr+0x5e>
      virtio_disk_intr();
    800029ca:	00004097          	auipc	ra,0x4
    800029ce:	998080e7          	jalr	-1640(ra) # 80006362 <virtio_disk_intr>
    800029d2:	b7c5                	j	800029b2 <devintr+0x5e>
    if(cpuid() == 0){
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	0e2080e7          	jalr	226(ra) # 80001ab6 <cpuid>
    800029dc:	c901                	beqz	a0,800029ec <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029de:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029e2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029e4:	14479073          	csrw	sip,a5
    return 2;
    800029e8:	4509                	li	a0,2
    800029ea:	b761                	j	80002972 <devintr+0x1e>
      clockintr();
    800029ec:	00000097          	auipc	ra,0x0
    800029f0:	f22080e7          	jalr	-222(ra) # 8000290e <clockintr>
    800029f4:	b7ed                	j	800029de <devintr+0x8a>

00000000800029f6 <usertrap>:
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	e04a                	sd	s2,0(sp)
    80002a00:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a06:	1007f793          	andi	a5,a5,256
    80002a0a:	e3ad                	bnez	a5,80002a6c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a0c:	00003797          	auipc	a5,0x3
    80002a10:	38478793          	addi	a5,a5,900 # 80005d90 <kernelvec>
    80002a14:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	0ca080e7          	jalr	202(ra) # 80001ae2 <myproc>
    80002a20:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a22:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a24:	14102773          	csrr	a4,sepc
    80002a28:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a2e:	47a1                	li	a5,8
    80002a30:	04f71c63          	bne	a4,a5,80002a88 <usertrap+0x92>
    if(p->killed)
    80002a34:	591c                	lw	a5,48(a0)
    80002a36:	e3b9                	bnez	a5,80002a7c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a38:	6cb8                	ld	a4,88(s1)
    80002a3a:	6f1c                	ld	a5,24(a4)
    80002a3c:	0791                	addi	a5,a5,4
    80002a3e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a44:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a48:	10079073          	csrw	sstatus,a5
    syscall();
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	2e0080e7          	jalr	736(ra) # 80002d2c <syscall>
  if(p->killed)
    80002a54:	589c                	lw	a5,48(s1)
    80002a56:	ebc1                	bnez	a5,80002ae6 <usertrap+0xf0>
  usertrapret();
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	e18080e7          	jalr	-488(ra) # 80002870 <usertrapret>
}
    80002a60:	60e2                	ld	ra,24(sp)
    80002a62:	6442                	ld	s0,16(sp)
    80002a64:	64a2                	ld	s1,8(sp)
    80002a66:	6902                	ld	s2,0(sp)
    80002a68:	6105                	addi	sp,sp,32
    80002a6a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	8f450513          	addi	a0,a0,-1804 # 80008360 <states.1739+0x50>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	ad4080e7          	jalr	-1324(ra) # 80000548 <panic>
      exit(-1);
    80002a7c:	557d                	li	a0,-1
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	846080e7          	jalr	-1978(ra) # 800022c4 <exit>
    80002a86:	bf4d                	j	80002a38 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	ecc080e7          	jalr	-308(ra) # 80002954 <devintr>
    80002a90:	892a                	mv	s2,a0
    80002a92:	c501                	beqz	a0,80002a9a <usertrap+0xa4>
  if(p->killed)
    80002a94:	589c                	lw	a5,48(s1)
    80002a96:	c3a1                	beqz	a5,80002ad6 <usertrap+0xe0>
    80002a98:	a815                	j	80002acc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a9a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a9e:	5c90                	lw	a2,56(s1)
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	8e050513          	addi	a0,a0,-1824 # 80008380 <states.1739+0x70>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	aea080e7          	jalr	-1302(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	8f850513          	addi	a0,a0,-1800 # 800083b0 <states.1739+0xa0>
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	ad2080e7          	jalr	-1326(ra) # 80000592 <printf>
    p->killed = 1;
    80002ac8:	4785                	li	a5,1
    80002aca:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002acc:	557d                	li	a0,-1
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	7f6080e7          	jalr	2038(ra) # 800022c4 <exit>
  if(which_dev == 2)
    80002ad6:	4789                	li	a5,2
    80002ad8:	f8f910e3          	bne	s2,a5,80002a58 <usertrap+0x62>
    yield();
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	8f2080e7          	jalr	-1806(ra) # 800023ce <yield>
    80002ae4:	bf95                	j	80002a58 <usertrap+0x62>
  int which_dev = 0;
    80002ae6:	4901                	li	s2,0
    80002ae8:	b7d5                	j	80002acc <usertrap+0xd6>

0000000080002aea <kerneltrap>:
{
    80002aea:	7179                	addi	sp,sp,-48
    80002aec:	f406                	sd	ra,40(sp)
    80002aee:	f022                	sd	s0,32(sp)
    80002af0:	ec26                	sd	s1,24(sp)
    80002af2:	e84a                	sd	s2,16(sp)
    80002af4:	e44e                	sd	s3,8(sp)
    80002af6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b00:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b04:	1004f793          	andi	a5,s1,256
    80002b08:	cb85                	beqz	a5,80002b38 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b0e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b10:	ef85                	bnez	a5,80002b48 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	e42080e7          	jalr	-446(ra) # 80002954 <devintr>
    80002b1a:	cd1d                	beqz	a0,80002b58 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b1c:	4789                	li	a5,2
    80002b1e:	06f50a63          	beq	a0,a5,80002b92 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b22:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b26:	10049073          	csrw	sstatus,s1
}
    80002b2a:	70a2                	ld	ra,40(sp)
    80002b2c:	7402                	ld	s0,32(sp)
    80002b2e:	64e2                	ld	s1,24(sp)
    80002b30:	6942                	ld	s2,16(sp)
    80002b32:	69a2                	ld	s3,8(sp)
    80002b34:	6145                	addi	sp,sp,48
    80002b36:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	89850513          	addi	a0,a0,-1896 # 800083d0 <states.1739+0xc0>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	a08080e7          	jalr	-1528(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	8b050513          	addi	a0,a0,-1872 # 800083f8 <states.1739+0xe8>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	9f8080e7          	jalr	-1544(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002b58:	85ce                	mv	a1,s3
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	8be50513          	addi	a0,a0,-1858 # 80008418 <states.1739+0x108>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a30080e7          	jalr	-1488(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	8b650513          	addi	a0,a0,-1866 # 80008428 <states.1739+0x118>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	a18080e7          	jalr	-1512(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	8be50513          	addi	a0,a0,-1858 # 80008440 <states.1739+0x130>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9be080e7          	jalr	-1602(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	f50080e7          	jalr	-176(ra) # 80001ae2 <myproc>
    80002b9a:	d541                	beqz	a0,80002b22 <kerneltrap+0x38>
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	f46080e7          	jalr	-186(ra) # 80001ae2 <myproc>
    80002ba4:	4d18                	lw	a4,24(a0)
    80002ba6:	478d                	li	a5,3
    80002ba8:	f6f71de3          	bne	a4,a5,80002b22 <kerneltrap+0x38>
    yield();
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	822080e7          	jalr	-2014(ra) # 800023ce <yield>
    80002bb4:	b7bd                	j	80002b22 <kerneltrap+0x38>

0000000080002bb6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	1000                	addi	s0,sp,32
    80002bc0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	f20080e7          	jalr	-224(ra) # 80001ae2 <myproc>
  switch (n) {
    80002bca:	4795                	li	a5,5
    80002bcc:	0497e163          	bltu	a5,s1,80002c0e <argraw+0x58>
    80002bd0:	048a                	slli	s1,s1,0x2
    80002bd2:	00006717          	auipc	a4,0x6
    80002bd6:	8a670713          	addi	a4,a4,-1882 # 80008478 <states.1739+0x168>
    80002bda:	94ba                	add	s1,s1,a4
    80002bdc:	409c                	lw	a5,0(s1)
    80002bde:	97ba                	add	a5,a5,a4
    80002be0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002be2:	6d3c                	ld	a5,88(a0)
    80002be4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret
    return p->trapframe->a1;
    80002bf0:	6d3c                	ld	a5,88(a0)
    80002bf2:	7fa8                	ld	a0,120(a5)
    80002bf4:	bfcd                	j	80002be6 <argraw+0x30>
    return p->trapframe->a2;
    80002bf6:	6d3c                	ld	a5,88(a0)
    80002bf8:	63c8                	ld	a0,128(a5)
    80002bfa:	b7f5                	j	80002be6 <argraw+0x30>
    return p->trapframe->a3;
    80002bfc:	6d3c                	ld	a5,88(a0)
    80002bfe:	67c8                	ld	a0,136(a5)
    80002c00:	b7dd                	j	80002be6 <argraw+0x30>
    return p->trapframe->a4;
    80002c02:	6d3c                	ld	a5,88(a0)
    80002c04:	6bc8                	ld	a0,144(a5)
    80002c06:	b7c5                	j	80002be6 <argraw+0x30>
    return p->trapframe->a5;
    80002c08:	6d3c                	ld	a5,88(a0)
    80002c0a:	6fc8                	ld	a0,152(a5)
    80002c0c:	bfe9                	j	80002be6 <argraw+0x30>
  panic("argraw");
    80002c0e:	00006517          	auipc	a0,0x6
    80002c12:	84250513          	addi	a0,a0,-1982 # 80008450 <states.1739+0x140>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	932080e7          	jalr	-1742(ra) # 80000548 <panic>

0000000080002c1e <fetchaddr>:
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	e426                	sd	s1,8(sp)
    80002c26:	e04a                	sd	s2,0(sp)
    80002c28:	1000                	addi	s0,sp,32
    80002c2a:	84aa                	mv	s1,a0
    80002c2c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	eb4080e7          	jalr	-332(ra) # 80001ae2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c36:	653c                	ld	a5,72(a0)
    80002c38:	02f4f863          	bgeu	s1,a5,80002c68 <fetchaddr+0x4a>
    80002c3c:	00848713          	addi	a4,s1,8
    80002c40:	02e7e663          	bltu	a5,a4,80002c6c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c44:	46a1                	li	a3,8
    80002c46:	8626                	mv	a2,s1
    80002c48:	85ca                	mv	a1,s2
    80002c4a:	6928                	ld	a0,80(a0)
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	d8e080e7          	jalr	-626(ra) # 800019da <copyin>
    80002c54:	00a03533          	snez	a0,a0
    80002c58:	40a00533          	neg	a0,a0
}
    80002c5c:	60e2                	ld	ra,24(sp)
    80002c5e:	6442                	ld	s0,16(sp)
    80002c60:	64a2                	ld	s1,8(sp)
    80002c62:	6902                	ld	s2,0(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret
    return -1;
    80002c68:	557d                	li	a0,-1
    80002c6a:	bfcd                	j	80002c5c <fetchaddr+0x3e>
    80002c6c:	557d                	li	a0,-1
    80002c6e:	b7fd                	j	80002c5c <fetchaddr+0x3e>

0000000080002c70 <fetchstr>:
{
    80002c70:	7179                	addi	sp,sp,-48
    80002c72:	f406                	sd	ra,40(sp)
    80002c74:	f022                	sd	s0,32(sp)
    80002c76:	ec26                	sd	s1,24(sp)
    80002c78:	e84a                	sd	s2,16(sp)
    80002c7a:	e44e                	sd	s3,8(sp)
    80002c7c:	1800                	addi	s0,sp,48
    80002c7e:	892a                	mv	s2,a0
    80002c80:	84ae                	mv	s1,a1
    80002c82:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	e5e080e7          	jalr	-418(ra) # 80001ae2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c8c:	86ce                	mv	a3,s3
    80002c8e:	864a                	mv	a2,s2
    80002c90:	85a6                	mv	a1,s1
    80002c92:	6928                	ld	a0,80(a0)
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	d5e080e7          	jalr	-674(ra) # 800019f2 <copyinstr>
  if(err < 0)
    80002c9c:	00054763          	bltz	a0,80002caa <fetchstr+0x3a>
  return strlen(buf);
    80002ca0:	8526                	mv	a0,s1
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	1f2080e7          	jalr	498(ra) # 80000e94 <strlen>
}
    80002caa:	70a2                	ld	ra,40(sp)
    80002cac:	7402                	ld	s0,32(sp)
    80002cae:	64e2                	ld	s1,24(sp)
    80002cb0:	6942                	ld	s2,16(sp)
    80002cb2:	69a2                	ld	s3,8(sp)
    80002cb4:	6145                	addi	sp,sp,48
    80002cb6:	8082                	ret

0000000080002cb8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	ef2080e7          	jalr	-270(ra) # 80002bb6 <argraw>
    80002ccc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cce:	4501                	li	a0,0
    80002cd0:	60e2                	ld	ra,24(sp)
    80002cd2:	6442                	ld	s0,16(sp)
    80002cd4:	64a2                	ld	s1,8(sp)
    80002cd6:	6105                	addi	sp,sp,32
    80002cd8:	8082                	ret

0000000080002cda <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	e426                	sd	s1,8(sp)
    80002ce2:	1000                	addi	s0,sp,32
    80002ce4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	ed0080e7          	jalr	-304(ra) # 80002bb6 <argraw>
    80002cee:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cf0:	4501                	li	a0,0
    80002cf2:	60e2                	ld	ra,24(sp)
    80002cf4:	6442                	ld	s0,16(sp)
    80002cf6:	64a2                	ld	s1,8(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	e04a                	sd	s2,0(sp)
    80002d06:	1000                	addi	s0,sp,32
    80002d08:	84ae                	mv	s1,a1
    80002d0a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	eaa080e7          	jalr	-342(ra) # 80002bb6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d14:	864a                	mv	a2,s2
    80002d16:	85a6                	mv	a1,s1
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	f58080e7          	jalr	-168(ra) # 80002c70 <fetchstr>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	64a2                	ld	s1,8(sp)
    80002d26:	6902                	ld	s2,0(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	e426                	sd	s1,8(sp)
    80002d34:	e04a                	sd	s2,0(sp)
    80002d36:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	daa080e7          	jalr	-598(ra) # 80001ae2 <myproc>
    80002d40:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d42:	05853903          	ld	s2,88(a0)
    80002d46:	0a893783          	ld	a5,168(s2)
    80002d4a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d4e:	37fd                	addiw	a5,a5,-1
    80002d50:	4751                	li	a4,20
    80002d52:	00f76f63          	bltu	a4,a5,80002d70 <syscall+0x44>
    80002d56:	00369713          	slli	a4,a3,0x3
    80002d5a:	00005797          	auipc	a5,0x5
    80002d5e:	73678793          	addi	a5,a5,1846 # 80008490 <syscalls>
    80002d62:	97ba                	add	a5,a5,a4
    80002d64:	639c                	ld	a5,0(a5)
    80002d66:	c789                	beqz	a5,80002d70 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d68:	9782                	jalr	a5
    80002d6a:	06a93823          	sd	a0,112(s2)
    80002d6e:	a839                	j	80002d8c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d70:	15848613          	addi	a2,s1,344
    80002d74:	5c8c                	lw	a1,56(s1)
    80002d76:	00005517          	auipc	a0,0x5
    80002d7a:	6e250513          	addi	a0,a0,1762 # 80008458 <states.1739+0x148>
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	814080e7          	jalr	-2028(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d86:	6cbc                	ld	a5,88(s1)
    80002d88:	577d                	li	a4,-1
    80002d8a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d8c:	60e2                	ld	ra,24(sp)
    80002d8e:	6442                	ld	s0,16(sp)
    80002d90:	64a2                	ld	s1,8(sp)
    80002d92:	6902                	ld	s2,0(sp)
    80002d94:	6105                	addi	sp,sp,32
    80002d96:	8082                	ret

0000000080002d98 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002da0:	fec40593          	addi	a1,s0,-20
    80002da4:	4501                	li	a0,0
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	f12080e7          	jalr	-238(ra) # 80002cb8 <argint>
    return -1;
    80002dae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002db0:	00054963          	bltz	a0,80002dc2 <sys_exit+0x2a>
  exit(n);
    80002db4:	fec42503          	lw	a0,-20(s0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	50c080e7          	jalr	1292(ra) # 800022c4 <exit>
  return 0;  // not reached
    80002dc0:	4781                	li	a5,0
}
    80002dc2:	853e                	mv	a0,a5
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dcc:	1141                	addi	sp,sp,-16
    80002dce:	e406                	sd	ra,8(sp)
    80002dd0:	e022                	sd	s0,0(sp)
    80002dd2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	d0e080e7          	jalr	-754(ra) # 80001ae2 <myproc>
}
    80002ddc:	5d08                	lw	a0,56(a0)
    80002dde:	60a2                	ld	ra,8(sp)
    80002de0:	6402                	ld	s0,0(sp)
    80002de2:	0141                	addi	sp,sp,16
    80002de4:	8082                	ret

0000000080002de6 <sys_fork>:

uint64
sys_fork(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e406                	sd	ra,8(sp)
    80002dea:	e022                	sd	s0,0(sp)
    80002dec:	0800                	addi	s0,sp,16
  return fork();
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	198080e7          	jalr	408(ra) # 80001f86 <fork>
}
    80002df6:	60a2                	ld	ra,8(sp)
    80002df8:	6402                	ld	s0,0(sp)
    80002dfa:	0141                	addi	sp,sp,16
    80002dfc:	8082                	ret

0000000080002dfe <sys_wait>:

uint64
sys_wait(void)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e06:	fe840593          	addi	a1,s0,-24
    80002e0a:	4501                	li	a0,0
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	ece080e7          	jalr	-306(ra) # 80002cda <argaddr>
    80002e14:	87aa                	mv	a5,a0
    return -1;
    80002e16:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e18:	0007c863          	bltz	a5,80002e28 <sys_wait+0x2a>
  return wait(p);
    80002e1c:	fe843503          	ld	a0,-24(s0)
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	668080e7          	jalr	1640(ra) # 80002488 <wait>
}
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e30:	7179                	addi	sp,sp,-48
    80002e32:	f406                	sd	ra,40(sp)
    80002e34:	f022                	sd	s0,32(sp)
    80002e36:	ec26                	sd	s1,24(sp)
    80002e38:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e3a:	fdc40593          	addi	a1,s0,-36
    80002e3e:	4501                	li	a0,0
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	e78080e7          	jalr	-392(ra) # 80002cb8 <argint>
    80002e48:	87aa                	mv	a5,a0
    return -1;
    80002e4a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e4c:	0207c063          	bltz	a5,80002e6c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	c92080e7          	jalr	-878(ra) # 80001ae2 <myproc>
    80002e58:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e5a:	fdc42503          	lw	a0,-36(s0)
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	05c080e7          	jalr	92(ra) # 80001eba <growproc>
    80002e66:	00054863          	bltz	a0,80002e76 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e6a:	8526                	mv	a0,s1
}
    80002e6c:	70a2                	ld	ra,40(sp)
    80002e6e:	7402                	ld	s0,32(sp)
    80002e70:	64e2                	ld	s1,24(sp)
    80002e72:	6145                	addi	sp,sp,48
    80002e74:	8082                	ret
    return -1;
    80002e76:	557d                	li	a0,-1
    80002e78:	bfd5                	j	80002e6c <sys_sbrk+0x3c>

0000000080002e7a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e7a:	7139                	addi	sp,sp,-64
    80002e7c:	fc06                	sd	ra,56(sp)
    80002e7e:	f822                	sd	s0,48(sp)
    80002e80:	f426                	sd	s1,40(sp)
    80002e82:	f04a                	sd	s2,32(sp)
    80002e84:	ec4e                	sd	s3,24(sp)
    80002e86:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e88:	fcc40593          	addi	a1,s0,-52
    80002e8c:	4501                	li	a0,0
    80002e8e:	00000097          	auipc	ra,0x0
    80002e92:	e2a080e7          	jalr	-470(ra) # 80002cb8 <argint>
    return -1;
    80002e96:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e98:	06054563          	bltz	a0,80002f02 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e9c:	00015517          	auipc	a0,0x15
    80002ea0:	acc50513          	addi	a0,a0,-1332 # 80017968 <tickslock>
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	d6c080e7          	jalr	-660(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002eac:	00006917          	auipc	s2,0x6
    80002eb0:	17492903          	lw	s2,372(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002eb4:	fcc42783          	lw	a5,-52(s0)
    80002eb8:	cf85                	beqz	a5,80002ef0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eba:	00015997          	auipc	s3,0x15
    80002ebe:	aae98993          	addi	s3,s3,-1362 # 80017968 <tickslock>
    80002ec2:	00006497          	auipc	s1,0x6
    80002ec6:	15e48493          	addi	s1,s1,350 # 80009020 <ticks>
    if(myproc()->killed){
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	c18080e7          	jalr	-1000(ra) # 80001ae2 <myproc>
    80002ed2:	591c                	lw	a5,48(a0)
    80002ed4:	ef9d                	bnez	a5,80002f12 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ed6:	85ce                	mv	a1,s3
    80002ed8:	8526                	mv	a0,s1
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	530080e7          	jalr	1328(ra) # 8000240a <sleep>
  while(ticks - ticks0 < n){
    80002ee2:	409c                	lw	a5,0(s1)
    80002ee4:	412787bb          	subw	a5,a5,s2
    80002ee8:	fcc42703          	lw	a4,-52(s0)
    80002eec:	fce7efe3          	bltu	a5,a4,80002eca <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ef0:	00015517          	auipc	a0,0x15
    80002ef4:	a7850513          	addi	a0,a0,-1416 # 80017968 <tickslock>
    80002ef8:	ffffe097          	auipc	ra,0xffffe
    80002efc:	dcc080e7          	jalr	-564(ra) # 80000cc4 <release>
  return 0;
    80002f00:	4781                	li	a5,0
}
    80002f02:	853e                	mv	a0,a5
    80002f04:	70e2                	ld	ra,56(sp)
    80002f06:	7442                	ld	s0,48(sp)
    80002f08:	74a2                	ld	s1,40(sp)
    80002f0a:	7902                	ld	s2,32(sp)
    80002f0c:	69e2                	ld	s3,24(sp)
    80002f0e:	6121                	addi	sp,sp,64
    80002f10:	8082                	ret
      release(&tickslock);
    80002f12:	00015517          	auipc	a0,0x15
    80002f16:	a5650513          	addi	a0,a0,-1450 # 80017968 <tickslock>
    80002f1a:	ffffe097          	auipc	ra,0xffffe
    80002f1e:	daa080e7          	jalr	-598(ra) # 80000cc4 <release>
      return -1;
    80002f22:	57fd                	li	a5,-1
    80002f24:	bff9                	j	80002f02 <sys_sleep+0x88>

0000000080002f26 <sys_kill>:

uint64
sys_kill(void)
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f2e:	fec40593          	addi	a1,s0,-20
    80002f32:	4501                	li	a0,0
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	d84080e7          	jalr	-636(ra) # 80002cb8 <argint>
    80002f3c:	87aa                	mv	a5,a0
    return -1;
    80002f3e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f40:	0007c863          	bltz	a5,80002f50 <sys_kill+0x2a>
  return kill(pid);
    80002f44:	fec42503          	lw	a0,-20(s0)
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	6b2080e7          	jalr	1714(ra) # 800025fa <kill>
}
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	6105                	addi	sp,sp,32
    80002f56:	8082                	ret

0000000080002f58 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	e426                	sd	s1,8(sp)
    80002f60:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f62:	00015517          	auipc	a0,0x15
    80002f66:	a0650513          	addi	a0,a0,-1530 # 80017968 <tickslock>
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	ca6080e7          	jalr	-858(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002f72:	00006497          	auipc	s1,0x6
    80002f76:	0ae4a483          	lw	s1,174(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f7a:	00015517          	auipc	a0,0x15
    80002f7e:	9ee50513          	addi	a0,a0,-1554 # 80017968 <tickslock>
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	d42080e7          	jalr	-702(ra) # 80000cc4 <release>
  return xticks;
}
    80002f8a:	02049513          	slli	a0,s1,0x20
    80002f8e:	9101                	srli	a0,a0,0x20
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	64a2                	ld	s1,8(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret

0000000080002f9a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	e84a                	sd	s2,16(sp)
    80002fa4:	e44e                	sd	s3,8(sp)
    80002fa6:	e052                	sd	s4,0(sp)
    80002fa8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002faa:	00005597          	auipc	a1,0x5
    80002fae:	59658593          	addi	a1,a1,1430 # 80008540 <syscalls+0xb0>
    80002fb2:	00015517          	auipc	a0,0x15
    80002fb6:	9ce50513          	addi	a0,a0,-1586 # 80017980 <bcache>
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	bc6080e7          	jalr	-1082(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fc2:	0001d797          	auipc	a5,0x1d
    80002fc6:	9be78793          	addi	a5,a5,-1602 # 8001f980 <bcache+0x8000>
    80002fca:	0001d717          	auipc	a4,0x1d
    80002fce:	c1e70713          	addi	a4,a4,-994 # 8001fbe8 <bcache+0x8268>
    80002fd2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fd6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fda:	00015497          	auipc	s1,0x15
    80002fde:	9be48493          	addi	s1,s1,-1602 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002fe2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fe4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fe6:	00005a17          	auipc	s4,0x5
    80002fea:	562a0a13          	addi	s4,s4,1378 # 80008548 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002fee:	2b893783          	ld	a5,696(s2)
    80002ff2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ff4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ff8:	85d2                	mv	a1,s4
    80002ffa:	01048513          	addi	a0,s1,16
    80002ffe:	00001097          	auipc	ra,0x1
    80003002:	4ac080e7          	jalr	1196(ra) # 800044aa <initsleeplock>
    bcache.head.next->prev = b;
    80003006:	2b893783          	ld	a5,696(s2)
    8000300a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000300c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003010:	45848493          	addi	s1,s1,1112
    80003014:	fd349de3          	bne	s1,s3,80002fee <binit+0x54>
  }
}
    80003018:	70a2                	ld	ra,40(sp)
    8000301a:	7402                	ld	s0,32(sp)
    8000301c:	64e2                	ld	s1,24(sp)
    8000301e:	6942                	ld	s2,16(sp)
    80003020:	69a2                	ld	s3,8(sp)
    80003022:	6a02                	ld	s4,0(sp)
    80003024:	6145                	addi	sp,sp,48
    80003026:	8082                	ret

0000000080003028 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003028:	7179                	addi	sp,sp,-48
    8000302a:	f406                	sd	ra,40(sp)
    8000302c:	f022                	sd	s0,32(sp)
    8000302e:	ec26                	sd	s1,24(sp)
    80003030:	e84a                	sd	s2,16(sp)
    80003032:	e44e                	sd	s3,8(sp)
    80003034:	1800                	addi	s0,sp,48
    80003036:	89aa                	mv	s3,a0
    80003038:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000303a:	00015517          	auipc	a0,0x15
    8000303e:	94650513          	addi	a0,a0,-1722 # 80017980 <bcache>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	bce080e7          	jalr	-1074(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000304a:	0001d497          	auipc	s1,0x1d
    8000304e:	bee4b483          	ld	s1,-1042(s1) # 8001fc38 <bcache+0x82b8>
    80003052:	0001d797          	auipc	a5,0x1d
    80003056:	b9678793          	addi	a5,a5,-1130 # 8001fbe8 <bcache+0x8268>
    8000305a:	02f48f63          	beq	s1,a5,80003098 <bread+0x70>
    8000305e:	873e                	mv	a4,a5
    80003060:	a021                	j	80003068 <bread+0x40>
    80003062:	68a4                	ld	s1,80(s1)
    80003064:	02e48a63          	beq	s1,a4,80003098 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003068:	449c                	lw	a5,8(s1)
    8000306a:	ff379ce3          	bne	a5,s3,80003062 <bread+0x3a>
    8000306e:	44dc                	lw	a5,12(s1)
    80003070:	ff2799e3          	bne	a5,s2,80003062 <bread+0x3a>
      b->refcnt++;
    80003074:	40bc                	lw	a5,64(s1)
    80003076:	2785                	addiw	a5,a5,1
    80003078:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000307a:	00015517          	auipc	a0,0x15
    8000307e:	90650513          	addi	a0,a0,-1786 # 80017980 <bcache>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	c42080e7          	jalr	-958(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000308a:	01048513          	addi	a0,s1,16
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	456080e7          	jalr	1110(ra) # 800044e4 <acquiresleep>
      return b;
    80003096:	a8b9                	j	800030f4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003098:	0001d497          	auipc	s1,0x1d
    8000309c:	b984b483          	ld	s1,-1128(s1) # 8001fc30 <bcache+0x82b0>
    800030a0:	0001d797          	auipc	a5,0x1d
    800030a4:	b4878793          	addi	a5,a5,-1208 # 8001fbe8 <bcache+0x8268>
    800030a8:	00f48863          	beq	s1,a5,800030b8 <bread+0x90>
    800030ac:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030ae:	40bc                	lw	a5,64(s1)
    800030b0:	cf81                	beqz	a5,800030c8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030b2:	64a4                	ld	s1,72(s1)
    800030b4:	fee49de3          	bne	s1,a4,800030ae <bread+0x86>
  panic("bget: no buffers");
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	49850513          	addi	a0,a0,1176 # 80008550 <syscalls+0xc0>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	488080e7          	jalr	1160(ra) # 80000548 <panic>
      b->dev = dev;
    800030c8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030cc:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030d0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030d4:	4785                	li	a5,1
    800030d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d8:	00015517          	auipc	a0,0x15
    800030dc:	8a850513          	addi	a0,a0,-1880 # 80017980 <bcache>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	be4080e7          	jalr	-1052(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800030e8:	01048513          	addi	a0,s1,16
    800030ec:	00001097          	auipc	ra,0x1
    800030f0:	3f8080e7          	jalr	1016(ra) # 800044e4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030f4:	409c                	lw	a5,0(s1)
    800030f6:	cb89                	beqz	a5,80003108 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030f8:	8526                	mv	a0,s1
    800030fa:	70a2                	ld	ra,40(sp)
    800030fc:	7402                	ld	s0,32(sp)
    800030fe:	64e2                	ld	s1,24(sp)
    80003100:	6942                	ld	s2,16(sp)
    80003102:	69a2                	ld	s3,8(sp)
    80003104:	6145                	addi	sp,sp,48
    80003106:	8082                	ret
    virtio_disk_rw(b, 0);
    80003108:	4581                	li	a1,0
    8000310a:	8526                	mv	a0,s1
    8000310c:	00003097          	auipc	ra,0x3
    80003110:	fa0080e7          	jalr	-96(ra) # 800060ac <virtio_disk_rw>
    b->valid = 1;
    80003114:	4785                	li	a5,1
    80003116:	c09c                	sw	a5,0(s1)
  return b;
    80003118:	b7c5                	j	800030f8 <bread+0xd0>

000000008000311a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	e426                	sd	s1,8(sp)
    80003122:	1000                	addi	s0,sp,32
    80003124:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003126:	0541                	addi	a0,a0,16
    80003128:	00001097          	auipc	ra,0x1
    8000312c:	456080e7          	jalr	1110(ra) # 8000457e <holdingsleep>
    80003130:	cd01                	beqz	a0,80003148 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003132:	4585                	li	a1,1
    80003134:	8526                	mv	a0,s1
    80003136:	00003097          	auipc	ra,0x3
    8000313a:	f76080e7          	jalr	-138(ra) # 800060ac <virtio_disk_rw>
}
    8000313e:	60e2                	ld	ra,24(sp)
    80003140:	6442                	ld	s0,16(sp)
    80003142:	64a2                	ld	s1,8(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret
    panic("bwrite");
    80003148:	00005517          	auipc	a0,0x5
    8000314c:	42050513          	addi	a0,a0,1056 # 80008568 <syscalls+0xd8>
    80003150:	ffffd097          	auipc	ra,0xffffd
    80003154:	3f8080e7          	jalr	1016(ra) # 80000548 <panic>

0000000080003158 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	e426                	sd	s1,8(sp)
    80003160:	e04a                	sd	s2,0(sp)
    80003162:	1000                	addi	s0,sp,32
    80003164:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003166:	01050913          	addi	s2,a0,16
    8000316a:	854a                	mv	a0,s2
    8000316c:	00001097          	auipc	ra,0x1
    80003170:	412080e7          	jalr	1042(ra) # 8000457e <holdingsleep>
    80003174:	c92d                	beqz	a0,800031e6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003176:	854a                	mv	a0,s2
    80003178:	00001097          	auipc	ra,0x1
    8000317c:	3c2080e7          	jalr	962(ra) # 8000453a <releasesleep>

  acquire(&bcache.lock);
    80003180:	00015517          	auipc	a0,0x15
    80003184:	80050513          	addi	a0,a0,-2048 # 80017980 <bcache>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	a88080e7          	jalr	-1400(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003190:	40bc                	lw	a5,64(s1)
    80003192:	37fd                	addiw	a5,a5,-1
    80003194:	0007871b          	sext.w	a4,a5
    80003198:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000319a:	eb05                	bnez	a4,800031ca <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000319c:	68bc                	ld	a5,80(s1)
    8000319e:	64b8                	ld	a4,72(s1)
    800031a0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031a2:	64bc                	ld	a5,72(s1)
    800031a4:	68b8                	ld	a4,80(s1)
    800031a6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031a8:	0001c797          	auipc	a5,0x1c
    800031ac:	7d878793          	addi	a5,a5,2008 # 8001f980 <bcache+0x8000>
    800031b0:	2b87b703          	ld	a4,696(a5)
    800031b4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031b6:	0001d717          	auipc	a4,0x1d
    800031ba:	a3270713          	addi	a4,a4,-1486 # 8001fbe8 <bcache+0x8268>
    800031be:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031c0:	2b87b703          	ld	a4,696(a5)
    800031c4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031c6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031ca:	00014517          	auipc	a0,0x14
    800031ce:	7b650513          	addi	a0,a0,1974 # 80017980 <bcache>
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	af2080e7          	jalr	-1294(ra) # 80000cc4 <release>
}
    800031da:	60e2                	ld	ra,24(sp)
    800031dc:	6442                	ld	s0,16(sp)
    800031de:	64a2                	ld	s1,8(sp)
    800031e0:	6902                	ld	s2,0(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret
    panic("brelse");
    800031e6:	00005517          	auipc	a0,0x5
    800031ea:	38a50513          	addi	a0,a0,906 # 80008570 <syscalls+0xe0>
    800031ee:	ffffd097          	auipc	ra,0xffffd
    800031f2:	35a080e7          	jalr	858(ra) # 80000548 <panic>

00000000800031f6 <bpin>:

void
bpin(struct buf *b) {
    800031f6:	1101                	addi	sp,sp,-32
    800031f8:	ec06                	sd	ra,24(sp)
    800031fa:	e822                	sd	s0,16(sp)
    800031fc:	e426                	sd	s1,8(sp)
    800031fe:	1000                	addi	s0,sp,32
    80003200:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003202:	00014517          	auipc	a0,0x14
    80003206:	77e50513          	addi	a0,a0,1918 # 80017980 <bcache>
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	a06080e7          	jalr	-1530(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003212:	40bc                	lw	a5,64(s1)
    80003214:	2785                	addiw	a5,a5,1
    80003216:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	76850513          	addi	a0,a0,1896 # 80017980 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	aa4080e7          	jalr	-1372(ra) # 80000cc4 <release>
}
    80003228:	60e2                	ld	ra,24(sp)
    8000322a:	6442                	ld	s0,16(sp)
    8000322c:	64a2                	ld	s1,8(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret

0000000080003232 <bunpin>:

void
bunpin(struct buf *b) {
    80003232:	1101                	addi	sp,sp,-32
    80003234:	ec06                	sd	ra,24(sp)
    80003236:	e822                	sd	s0,16(sp)
    80003238:	e426                	sd	s1,8(sp)
    8000323a:	1000                	addi	s0,sp,32
    8000323c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000323e:	00014517          	auipc	a0,0x14
    80003242:	74250513          	addi	a0,a0,1858 # 80017980 <bcache>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	9ca080e7          	jalr	-1590(ra) # 80000c10 <acquire>
  b->refcnt--;
    8000324e:	40bc                	lw	a5,64(s1)
    80003250:	37fd                	addiw	a5,a5,-1
    80003252:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003254:	00014517          	auipc	a0,0x14
    80003258:	72c50513          	addi	a0,a0,1836 # 80017980 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	a68080e7          	jalr	-1432(ra) # 80000cc4 <release>
}
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	64a2                	ld	s1,8(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret

000000008000326e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	e426                	sd	s1,8(sp)
    80003276:	e04a                	sd	s2,0(sp)
    80003278:	1000                	addi	s0,sp,32
    8000327a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000327c:	00d5d59b          	srliw	a1,a1,0xd
    80003280:	0001d797          	auipc	a5,0x1d
    80003284:	ddc7a783          	lw	a5,-548(a5) # 8002005c <sb+0x1c>
    80003288:	9dbd                	addw	a1,a1,a5
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	d9e080e7          	jalr	-610(ra) # 80003028 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003292:	0074f713          	andi	a4,s1,7
    80003296:	4785                	li	a5,1
    80003298:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000329c:	14ce                	slli	s1,s1,0x33
    8000329e:	90d9                	srli	s1,s1,0x36
    800032a0:	00950733          	add	a4,a0,s1
    800032a4:	05874703          	lbu	a4,88(a4)
    800032a8:	00e7f6b3          	and	a3,a5,a4
    800032ac:	c69d                	beqz	a3,800032da <bfree+0x6c>
    800032ae:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032b0:	94aa                	add	s1,s1,a0
    800032b2:	fff7c793          	not	a5,a5
    800032b6:	8ff9                	and	a5,a5,a4
    800032b8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	100080e7          	jalr	256(ra) # 800043bc <log_write>
  brelse(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	e92080e7          	jalr	-366(ra) # 80003158 <brelse>
}
    800032ce:	60e2                	ld	ra,24(sp)
    800032d0:	6442                	ld	s0,16(sp)
    800032d2:	64a2                	ld	s1,8(sp)
    800032d4:	6902                	ld	s2,0(sp)
    800032d6:	6105                	addi	sp,sp,32
    800032d8:	8082                	ret
    panic("freeing free block");
    800032da:	00005517          	auipc	a0,0x5
    800032de:	29e50513          	addi	a0,a0,670 # 80008578 <syscalls+0xe8>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	266080e7          	jalr	614(ra) # 80000548 <panic>

00000000800032ea <balloc>:
{
    800032ea:	711d                	addi	sp,sp,-96
    800032ec:	ec86                	sd	ra,88(sp)
    800032ee:	e8a2                	sd	s0,80(sp)
    800032f0:	e4a6                	sd	s1,72(sp)
    800032f2:	e0ca                	sd	s2,64(sp)
    800032f4:	fc4e                	sd	s3,56(sp)
    800032f6:	f852                	sd	s4,48(sp)
    800032f8:	f456                	sd	s5,40(sp)
    800032fa:	f05a                	sd	s6,32(sp)
    800032fc:	ec5e                	sd	s7,24(sp)
    800032fe:	e862                	sd	s8,16(sp)
    80003300:	e466                	sd	s9,8(sp)
    80003302:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003304:	0001d797          	auipc	a5,0x1d
    80003308:	d407a783          	lw	a5,-704(a5) # 80020044 <sb+0x4>
    8000330c:	cbd1                	beqz	a5,800033a0 <balloc+0xb6>
    8000330e:	8baa                	mv	s7,a0
    80003310:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003312:	0001db17          	auipc	s6,0x1d
    80003316:	d2eb0b13          	addi	s6,s6,-722 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000331a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000331c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000331e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003320:	6c89                	lui	s9,0x2
    80003322:	a831                	j	8000333e <balloc+0x54>
    brelse(bp);
    80003324:	854a                	mv	a0,s2
    80003326:	00000097          	auipc	ra,0x0
    8000332a:	e32080e7          	jalr	-462(ra) # 80003158 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000332e:	015c87bb          	addw	a5,s9,s5
    80003332:	00078a9b          	sext.w	s5,a5
    80003336:	004b2703          	lw	a4,4(s6)
    8000333a:	06eaf363          	bgeu	s5,a4,800033a0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000333e:	41fad79b          	sraiw	a5,s5,0x1f
    80003342:	0137d79b          	srliw	a5,a5,0x13
    80003346:	015787bb          	addw	a5,a5,s5
    8000334a:	40d7d79b          	sraiw	a5,a5,0xd
    8000334e:	01cb2583          	lw	a1,28(s6)
    80003352:	9dbd                	addw	a1,a1,a5
    80003354:	855e                	mv	a0,s7
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	cd2080e7          	jalr	-814(ra) # 80003028 <bread>
    8000335e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003360:	004b2503          	lw	a0,4(s6)
    80003364:	000a849b          	sext.w	s1,s5
    80003368:	8662                	mv	a2,s8
    8000336a:	faa4fde3          	bgeu	s1,a0,80003324 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000336e:	41f6579b          	sraiw	a5,a2,0x1f
    80003372:	01d7d69b          	srliw	a3,a5,0x1d
    80003376:	00c6873b          	addw	a4,a3,a2
    8000337a:	00777793          	andi	a5,a4,7
    8000337e:	9f95                	subw	a5,a5,a3
    80003380:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003384:	4037571b          	sraiw	a4,a4,0x3
    80003388:	00e906b3          	add	a3,s2,a4
    8000338c:	0586c683          	lbu	a3,88(a3)
    80003390:	00d7f5b3          	and	a1,a5,a3
    80003394:	cd91                	beqz	a1,800033b0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003396:	2605                	addiw	a2,a2,1
    80003398:	2485                	addiw	s1,s1,1
    8000339a:	fd4618e3          	bne	a2,s4,8000336a <balloc+0x80>
    8000339e:	b759                	j	80003324 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033a0:	00005517          	auipc	a0,0x5
    800033a4:	1f050513          	addi	a0,a0,496 # 80008590 <syscalls+0x100>
    800033a8:	ffffd097          	auipc	ra,0xffffd
    800033ac:	1a0080e7          	jalr	416(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033b0:	974a                	add	a4,a4,s2
    800033b2:	8fd5                	or	a5,a5,a3
    800033b4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033b8:	854a                	mv	a0,s2
    800033ba:	00001097          	auipc	ra,0x1
    800033be:	002080e7          	jalr	2(ra) # 800043bc <log_write>
        brelse(bp);
    800033c2:	854a                	mv	a0,s2
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	d94080e7          	jalr	-620(ra) # 80003158 <brelse>
  bp = bread(dev, bno);
    800033cc:	85a6                	mv	a1,s1
    800033ce:	855e                	mv	a0,s7
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	c58080e7          	jalr	-936(ra) # 80003028 <bread>
    800033d8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033da:	40000613          	li	a2,1024
    800033de:	4581                	li	a1,0
    800033e0:	05850513          	addi	a0,a0,88
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	928080e7          	jalr	-1752(ra) # 80000d0c <memset>
  log_write(bp);
    800033ec:	854a                	mv	a0,s2
    800033ee:	00001097          	auipc	ra,0x1
    800033f2:	fce080e7          	jalr	-50(ra) # 800043bc <log_write>
  brelse(bp);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	d60080e7          	jalr	-672(ra) # 80003158 <brelse>
}
    80003400:	8526                	mv	a0,s1
    80003402:	60e6                	ld	ra,88(sp)
    80003404:	6446                	ld	s0,80(sp)
    80003406:	64a6                	ld	s1,72(sp)
    80003408:	6906                	ld	s2,64(sp)
    8000340a:	79e2                	ld	s3,56(sp)
    8000340c:	7a42                	ld	s4,48(sp)
    8000340e:	7aa2                	ld	s5,40(sp)
    80003410:	7b02                	ld	s6,32(sp)
    80003412:	6be2                	ld	s7,24(sp)
    80003414:	6c42                	ld	s8,16(sp)
    80003416:	6ca2                	ld	s9,8(sp)
    80003418:	6125                	addi	sp,sp,96
    8000341a:	8082                	ret

000000008000341c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000341c:	7179                	addi	sp,sp,-48
    8000341e:	f406                	sd	ra,40(sp)
    80003420:	f022                	sd	s0,32(sp)
    80003422:	ec26                	sd	s1,24(sp)
    80003424:	e84a                	sd	s2,16(sp)
    80003426:	e44e                	sd	s3,8(sp)
    80003428:	e052                	sd	s4,0(sp)
    8000342a:	1800                	addi	s0,sp,48
    8000342c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000342e:	47ad                	li	a5,11
    80003430:	04b7fe63          	bgeu	a5,a1,8000348c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003434:	ff45849b          	addiw	s1,a1,-12
    80003438:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000343c:	0ff00793          	li	a5,255
    80003440:	0ae7e363          	bltu	a5,a4,800034e6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003444:	08052583          	lw	a1,128(a0)
    80003448:	c5ad                	beqz	a1,800034b2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000344a:	00092503          	lw	a0,0(s2)
    8000344e:	00000097          	auipc	ra,0x0
    80003452:	bda080e7          	jalr	-1062(ra) # 80003028 <bread>
    80003456:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003458:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000345c:	02049593          	slli	a1,s1,0x20
    80003460:	9181                	srli	a1,a1,0x20
    80003462:	058a                	slli	a1,a1,0x2
    80003464:	00b784b3          	add	s1,a5,a1
    80003468:	0004a983          	lw	s3,0(s1)
    8000346c:	04098d63          	beqz	s3,800034c6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003470:	8552                	mv	a0,s4
    80003472:	00000097          	auipc	ra,0x0
    80003476:	ce6080e7          	jalr	-794(ra) # 80003158 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000347a:	854e                	mv	a0,s3
    8000347c:	70a2                	ld	ra,40(sp)
    8000347e:	7402                	ld	s0,32(sp)
    80003480:	64e2                	ld	s1,24(sp)
    80003482:	6942                	ld	s2,16(sp)
    80003484:	69a2                	ld	s3,8(sp)
    80003486:	6a02                	ld	s4,0(sp)
    80003488:	6145                	addi	sp,sp,48
    8000348a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000348c:	02059493          	slli	s1,a1,0x20
    80003490:	9081                	srli	s1,s1,0x20
    80003492:	048a                	slli	s1,s1,0x2
    80003494:	94aa                	add	s1,s1,a0
    80003496:	0504a983          	lw	s3,80(s1)
    8000349a:	fe0990e3          	bnez	s3,8000347a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000349e:	4108                	lw	a0,0(a0)
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	e4a080e7          	jalr	-438(ra) # 800032ea <balloc>
    800034a8:	0005099b          	sext.w	s3,a0
    800034ac:	0534a823          	sw	s3,80(s1)
    800034b0:	b7e9                	j	8000347a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034b2:	4108                	lw	a0,0(a0)
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	e36080e7          	jalr	-458(ra) # 800032ea <balloc>
    800034bc:	0005059b          	sext.w	a1,a0
    800034c0:	08b92023          	sw	a1,128(s2)
    800034c4:	b759                	j	8000344a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034c6:	00092503          	lw	a0,0(s2)
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	e20080e7          	jalr	-480(ra) # 800032ea <balloc>
    800034d2:	0005099b          	sext.w	s3,a0
    800034d6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034da:	8552                	mv	a0,s4
    800034dc:	00001097          	auipc	ra,0x1
    800034e0:	ee0080e7          	jalr	-288(ra) # 800043bc <log_write>
    800034e4:	b771                	j	80003470 <bmap+0x54>
  panic("bmap: out of range");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	0c250513          	addi	a0,a0,194 # 800085a8 <syscalls+0x118>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	05a080e7          	jalr	90(ra) # 80000548 <panic>

00000000800034f6 <iget>:
{
    800034f6:	7179                	addi	sp,sp,-48
    800034f8:	f406                	sd	ra,40(sp)
    800034fa:	f022                	sd	s0,32(sp)
    800034fc:	ec26                	sd	s1,24(sp)
    800034fe:	e84a                	sd	s2,16(sp)
    80003500:	e44e                	sd	s3,8(sp)
    80003502:	e052                	sd	s4,0(sp)
    80003504:	1800                	addi	s0,sp,48
    80003506:	89aa                	mv	s3,a0
    80003508:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000350a:	0001d517          	auipc	a0,0x1d
    8000350e:	b5650513          	addi	a0,a0,-1194 # 80020060 <icache>
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	6fe080e7          	jalr	1790(ra) # 80000c10 <acquire>
  empty = 0;
    8000351a:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000351c:	0001d497          	auipc	s1,0x1d
    80003520:	b5c48493          	addi	s1,s1,-1188 # 80020078 <icache+0x18>
    80003524:	0001e697          	auipc	a3,0x1e
    80003528:	5e468693          	addi	a3,a3,1508 # 80021b08 <log>
    8000352c:	a039                	j	8000353a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000352e:	02090b63          	beqz	s2,80003564 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003532:	08848493          	addi	s1,s1,136
    80003536:	02d48a63          	beq	s1,a3,8000356a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000353a:	449c                	lw	a5,8(s1)
    8000353c:	fef059e3          	blez	a5,8000352e <iget+0x38>
    80003540:	4098                	lw	a4,0(s1)
    80003542:	ff3716e3          	bne	a4,s3,8000352e <iget+0x38>
    80003546:	40d8                	lw	a4,4(s1)
    80003548:	ff4713e3          	bne	a4,s4,8000352e <iget+0x38>
      ip->ref++;
    8000354c:	2785                	addiw	a5,a5,1
    8000354e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003550:	0001d517          	auipc	a0,0x1d
    80003554:	b1050513          	addi	a0,a0,-1264 # 80020060 <icache>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	76c080e7          	jalr	1900(ra) # 80000cc4 <release>
      return ip;
    80003560:	8926                	mv	s2,s1
    80003562:	a03d                	j	80003590 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003564:	f7f9                	bnez	a5,80003532 <iget+0x3c>
    80003566:	8926                	mv	s2,s1
    80003568:	b7e9                	j	80003532 <iget+0x3c>
  if(empty == 0)
    8000356a:	02090c63          	beqz	s2,800035a2 <iget+0xac>
  ip->dev = dev;
    8000356e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003572:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003576:	4785                	li	a5,1
    80003578:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000357c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003580:	0001d517          	auipc	a0,0x1d
    80003584:	ae050513          	addi	a0,a0,-1312 # 80020060 <icache>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	73c080e7          	jalr	1852(ra) # 80000cc4 <release>
}
    80003590:	854a                	mv	a0,s2
    80003592:	70a2                	ld	ra,40(sp)
    80003594:	7402                	ld	s0,32(sp)
    80003596:	64e2                	ld	s1,24(sp)
    80003598:	6942                	ld	s2,16(sp)
    8000359a:	69a2                	ld	s3,8(sp)
    8000359c:	6a02                	ld	s4,0(sp)
    8000359e:	6145                	addi	sp,sp,48
    800035a0:	8082                	ret
    panic("iget: no inodes");
    800035a2:	00005517          	auipc	a0,0x5
    800035a6:	01e50513          	addi	a0,a0,30 # 800085c0 <syscalls+0x130>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	f9e080e7          	jalr	-98(ra) # 80000548 <panic>

00000000800035b2 <fsinit>:
fsinit(int dev) {
    800035b2:	7179                	addi	sp,sp,-48
    800035b4:	f406                	sd	ra,40(sp)
    800035b6:	f022                	sd	s0,32(sp)
    800035b8:	ec26                	sd	s1,24(sp)
    800035ba:	e84a                	sd	s2,16(sp)
    800035bc:	e44e                	sd	s3,8(sp)
    800035be:	1800                	addi	s0,sp,48
    800035c0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035c2:	4585                	li	a1,1
    800035c4:	00000097          	auipc	ra,0x0
    800035c8:	a64080e7          	jalr	-1436(ra) # 80003028 <bread>
    800035cc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035ce:	0001d997          	auipc	s3,0x1d
    800035d2:	a7298993          	addi	s3,s3,-1422 # 80020040 <sb>
    800035d6:	02000613          	li	a2,32
    800035da:	05850593          	addi	a1,a0,88
    800035de:	854e                	mv	a0,s3
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	78c080e7          	jalr	1932(ra) # 80000d6c <memmove>
  brelse(bp);
    800035e8:	8526                	mv	a0,s1
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	b6e080e7          	jalr	-1170(ra) # 80003158 <brelse>
  if(sb.magic != FSMAGIC)
    800035f2:	0009a703          	lw	a4,0(s3)
    800035f6:	102037b7          	lui	a5,0x10203
    800035fa:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035fe:	02f71263          	bne	a4,a5,80003622 <fsinit+0x70>
  initlog(dev, &sb);
    80003602:	0001d597          	auipc	a1,0x1d
    80003606:	a3e58593          	addi	a1,a1,-1474 # 80020040 <sb>
    8000360a:	854a                	mv	a0,s2
    8000360c:	00001097          	auipc	ra,0x1
    80003610:	b38080e7          	jalr	-1224(ra) # 80004144 <initlog>
}
    80003614:	70a2                	ld	ra,40(sp)
    80003616:	7402                	ld	s0,32(sp)
    80003618:	64e2                	ld	s1,24(sp)
    8000361a:	6942                	ld	s2,16(sp)
    8000361c:	69a2                	ld	s3,8(sp)
    8000361e:	6145                	addi	sp,sp,48
    80003620:	8082                	ret
    panic("invalid file system");
    80003622:	00005517          	auipc	a0,0x5
    80003626:	fae50513          	addi	a0,a0,-82 # 800085d0 <syscalls+0x140>
    8000362a:	ffffd097          	auipc	ra,0xffffd
    8000362e:	f1e080e7          	jalr	-226(ra) # 80000548 <panic>

0000000080003632 <iinit>:
{
    80003632:	7179                	addi	sp,sp,-48
    80003634:	f406                	sd	ra,40(sp)
    80003636:	f022                	sd	s0,32(sp)
    80003638:	ec26                	sd	s1,24(sp)
    8000363a:	e84a                	sd	s2,16(sp)
    8000363c:	e44e                	sd	s3,8(sp)
    8000363e:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003640:	00005597          	auipc	a1,0x5
    80003644:	fa858593          	addi	a1,a1,-88 # 800085e8 <syscalls+0x158>
    80003648:	0001d517          	auipc	a0,0x1d
    8000364c:	a1850513          	addi	a0,a0,-1512 # 80020060 <icache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	530080e7          	jalr	1328(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003658:	0001d497          	auipc	s1,0x1d
    8000365c:	a3048493          	addi	s1,s1,-1488 # 80020088 <icache+0x28>
    80003660:	0001e997          	auipc	s3,0x1e
    80003664:	4b898993          	addi	s3,s3,1208 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003668:	00005917          	auipc	s2,0x5
    8000366c:	f8890913          	addi	s2,s2,-120 # 800085f0 <syscalls+0x160>
    80003670:	85ca                	mv	a1,s2
    80003672:	8526                	mv	a0,s1
    80003674:	00001097          	auipc	ra,0x1
    80003678:	e36080e7          	jalr	-458(ra) # 800044aa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000367c:	08848493          	addi	s1,s1,136
    80003680:	ff3498e3          	bne	s1,s3,80003670 <iinit+0x3e>
}
    80003684:	70a2                	ld	ra,40(sp)
    80003686:	7402                	ld	s0,32(sp)
    80003688:	64e2                	ld	s1,24(sp)
    8000368a:	6942                	ld	s2,16(sp)
    8000368c:	69a2                	ld	s3,8(sp)
    8000368e:	6145                	addi	sp,sp,48
    80003690:	8082                	ret

0000000080003692 <ialloc>:
{
    80003692:	715d                	addi	sp,sp,-80
    80003694:	e486                	sd	ra,72(sp)
    80003696:	e0a2                	sd	s0,64(sp)
    80003698:	fc26                	sd	s1,56(sp)
    8000369a:	f84a                	sd	s2,48(sp)
    8000369c:	f44e                	sd	s3,40(sp)
    8000369e:	f052                	sd	s4,32(sp)
    800036a0:	ec56                	sd	s5,24(sp)
    800036a2:	e85a                	sd	s6,16(sp)
    800036a4:	e45e                	sd	s7,8(sp)
    800036a6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036a8:	0001d717          	auipc	a4,0x1d
    800036ac:	9a472703          	lw	a4,-1628(a4) # 8002004c <sb+0xc>
    800036b0:	4785                	li	a5,1
    800036b2:	04e7fa63          	bgeu	a5,a4,80003706 <ialloc+0x74>
    800036b6:	8aaa                	mv	s5,a0
    800036b8:	8bae                	mv	s7,a1
    800036ba:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036bc:	0001da17          	auipc	s4,0x1d
    800036c0:	984a0a13          	addi	s4,s4,-1660 # 80020040 <sb>
    800036c4:	00048b1b          	sext.w	s6,s1
    800036c8:	0044d593          	srli	a1,s1,0x4
    800036cc:	018a2783          	lw	a5,24(s4)
    800036d0:	9dbd                	addw	a1,a1,a5
    800036d2:	8556                	mv	a0,s5
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	954080e7          	jalr	-1708(ra) # 80003028 <bread>
    800036dc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036de:	05850993          	addi	s3,a0,88
    800036e2:	00f4f793          	andi	a5,s1,15
    800036e6:	079a                	slli	a5,a5,0x6
    800036e8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036ea:	00099783          	lh	a5,0(s3)
    800036ee:	c785                	beqz	a5,80003716 <ialloc+0x84>
    brelse(bp);
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	a68080e7          	jalr	-1432(ra) # 80003158 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036f8:	0485                	addi	s1,s1,1
    800036fa:	00ca2703          	lw	a4,12(s4)
    800036fe:	0004879b          	sext.w	a5,s1
    80003702:	fce7e1e3          	bltu	a5,a4,800036c4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003706:	00005517          	auipc	a0,0x5
    8000370a:	ef250513          	addi	a0,a0,-270 # 800085f8 <syscalls+0x168>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e3a080e7          	jalr	-454(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003716:	04000613          	li	a2,64
    8000371a:	4581                	li	a1,0
    8000371c:	854e                	mv	a0,s3
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	5ee080e7          	jalr	1518(ra) # 80000d0c <memset>
      dip->type = type;
    80003726:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000372a:	854a                	mv	a0,s2
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	c90080e7          	jalr	-880(ra) # 800043bc <log_write>
      brelse(bp);
    80003734:	854a                	mv	a0,s2
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	a22080e7          	jalr	-1502(ra) # 80003158 <brelse>
      return iget(dev, inum);
    8000373e:	85da                	mv	a1,s6
    80003740:	8556                	mv	a0,s5
    80003742:	00000097          	auipc	ra,0x0
    80003746:	db4080e7          	jalr	-588(ra) # 800034f6 <iget>
}
    8000374a:	60a6                	ld	ra,72(sp)
    8000374c:	6406                	ld	s0,64(sp)
    8000374e:	74e2                	ld	s1,56(sp)
    80003750:	7942                	ld	s2,48(sp)
    80003752:	79a2                	ld	s3,40(sp)
    80003754:	7a02                	ld	s4,32(sp)
    80003756:	6ae2                	ld	s5,24(sp)
    80003758:	6b42                	ld	s6,16(sp)
    8000375a:	6ba2                	ld	s7,8(sp)
    8000375c:	6161                	addi	sp,sp,80
    8000375e:	8082                	ret

0000000080003760 <iupdate>:
{
    80003760:	1101                	addi	sp,sp,-32
    80003762:	ec06                	sd	ra,24(sp)
    80003764:	e822                	sd	s0,16(sp)
    80003766:	e426                	sd	s1,8(sp)
    80003768:	e04a                	sd	s2,0(sp)
    8000376a:	1000                	addi	s0,sp,32
    8000376c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000376e:	415c                	lw	a5,4(a0)
    80003770:	0047d79b          	srliw	a5,a5,0x4
    80003774:	0001d597          	auipc	a1,0x1d
    80003778:	8e45a583          	lw	a1,-1820(a1) # 80020058 <sb+0x18>
    8000377c:	9dbd                	addw	a1,a1,a5
    8000377e:	4108                	lw	a0,0(a0)
    80003780:	00000097          	auipc	ra,0x0
    80003784:	8a8080e7          	jalr	-1880(ra) # 80003028 <bread>
    80003788:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000378a:	05850793          	addi	a5,a0,88
    8000378e:	40c8                	lw	a0,4(s1)
    80003790:	893d                	andi	a0,a0,15
    80003792:	051a                	slli	a0,a0,0x6
    80003794:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003796:	04449703          	lh	a4,68(s1)
    8000379a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000379e:	04649703          	lh	a4,70(s1)
    800037a2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037a6:	04849703          	lh	a4,72(s1)
    800037aa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037ae:	04a49703          	lh	a4,74(s1)
    800037b2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037b6:	44f8                	lw	a4,76(s1)
    800037b8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037ba:	03400613          	li	a2,52
    800037be:	05048593          	addi	a1,s1,80
    800037c2:	0531                	addi	a0,a0,12
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	5a8080e7          	jalr	1448(ra) # 80000d6c <memmove>
  log_write(bp);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	bee080e7          	jalr	-1042(ra) # 800043bc <log_write>
  brelse(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	980080e7          	jalr	-1664(ra) # 80003158 <brelse>
}
    800037e0:	60e2                	ld	ra,24(sp)
    800037e2:	6442                	ld	s0,16(sp)
    800037e4:	64a2                	ld	s1,8(sp)
    800037e6:	6902                	ld	s2,0(sp)
    800037e8:	6105                	addi	sp,sp,32
    800037ea:	8082                	ret

00000000800037ec <idup>:
{
    800037ec:	1101                	addi	sp,sp,-32
    800037ee:	ec06                	sd	ra,24(sp)
    800037f0:	e822                	sd	s0,16(sp)
    800037f2:	e426                	sd	s1,8(sp)
    800037f4:	1000                	addi	s0,sp,32
    800037f6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037f8:	0001d517          	auipc	a0,0x1d
    800037fc:	86850513          	addi	a0,a0,-1944 # 80020060 <icache>
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	410080e7          	jalr	1040(ra) # 80000c10 <acquire>
  ip->ref++;
    80003808:	449c                	lw	a5,8(s1)
    8000380a:	2785                	addiw	a5,a5,1
    8000380c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000380e:	0001d517          	auipc	a0,0x1d
    80003812:	85250513          	addi	a0,a0,-1966 # 80020060 <icache>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	4ae080e7          	jalr	1198(ra) # 80000cc4 <release>
}
    8000381e:	8526                	mv	a0,s1
    80003820:	60e2                	ld	ra,24(sp)
    80003822:	6442                	ld	s0,16(sp)
    80003824:	64a2                	ld	s1,8(sp)
    80003826:	6105                	addi	sp,sp,32
    80003828:	8082                	ret

000000008000382a <ilock>:
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	e426                	sd	s1,8(sp)
    80003832:	e04a                	sd	s2,0(sp)
    80003834:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003836:	c115                	beqz	a0,8000385a <ilock+0x30>
    80003838:	84aa                	mv	s1,a0
    8000383a:	451c                	lw	a5,8(a0)
    8000383c:	00f05f63          	blez	a5,8000385a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003840:	0541                	addi	a0,a0,16
    80003842:	00001097          	auipc	ra,0x1
    80003846:	ca2080e7          	jalr	-862(ra) # 800044e4 <acquiresleep>
  if(ip->valid == 0){
    8000384a:	40bc                	lw	a5,64(s1)
    8000384c:	cf99                	beqz	a5,8000386a <ilock+0x40>
}
    8000384e:	60e2                	ld	ra,24(sp)
    80003850:	6442                	ld	s0,16(sp)
    80003852:	64a2                	ld	s1,8(sp)
    80003854:	6902                	ld	s2,0(sp)
    80003856:	6105                	addi	sp,sp,32
    80003858:	8082                	ret
    panic("ilock");
    8000385a:	00005517          	auipc	a0,0x5
    8000385e:	db650513          	addi	a0,a0,-586 # 80008610 <syscalls+0x180>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	ce6080e7          	jalr	-794(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000386a:	40dc                	lw	a5,4(s1)
    8000386c:	0047d79b          	srliw	a5,a5,0x4
    80003870:	0001c597          	auipc	a1,0x1c
    80003874:	7e85a583          	lw	a1,2024(a1) # 80020058 <sb+0x18>
    80003878:	9dbd                	addw	a1,a1,a5
    8000387a:	4088                	lw	a0,0(s1)
    8000387c:	fffff097          	auipc	ra,0xfffff
    80003880:	7ac080e7          	jalr	1964(ra) # 80003028 <bread>
    80003884:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003886:	05850593          	addi	a1,a0,88
    8000388a:	40dc                	lw	a5,4(s1)
    8000388c:	8bbd                	andi	a5,a5,15
    8000388e:	079a                	slli	a5,a5,0x6
    80003890:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003892:	00059783          	lh	a5,0(a1)
    80003896:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000389a:	00259783          	lh	a5,2(a1)
    8000389e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038a2:	00459783          	lh	a5,4(a1)
    800038a6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038aa:	00659783          	lh	a5,6(a1)
    800038ae:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038b2:	459c                	lw	a5,8(a1)
    800038b4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038b6:	03400613          	li	a2,52
    800038ba:	05b1                	addi	a1,a1,12
    800038bc:	05048513          	addi	a0,s1,80
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	4ac080e7          	jalr	1196(ra) # 80000d6c <memmove>
    brelse(bp);
    800038c8:	854a                	mv	a0,s2
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	88e080e7          	jalr	-1906(ra) # 80003158 <brelse>
    ip->valid = 1;
    800038d2:	4785                	li	a5,1
    800038d4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038d6:	04449783          	lh	a5,68(s1)
    800038da:	fbb5                	bnez	a5,8000384e <ilock+0x24>
      panic("ilock: no type");
    800038dc:	00005517          	auipc	a0,0x5
    800038e0:	d3c50513          	addi	a0,a0,-708 # 80008618 <syscalls+0x188>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	c64080e7          	jalr	-924(ra) # 80000548 <panic>

00000000800038ec <iunlock>:
{
    800038ec:	1101                	addi	sp,sp,-32
    800038ee:	ec06                	sd	ra,24(sp)
    800038f0:	e822                	sd	s0,16(sp)
    800038f2:	e426                	sd	s1,8(sp)
    800038f4:	e04a                	sd	s2,0(sp)
    800038f6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038f8:	c905                	beqz	a0,80003928 <iunlock+0x3c>
    800038fa:	84aa                	mv	s1,a0
    800038fc:	01050913          	addi	s2,a0,16
    80003900:	854a                	mv	a0,s2
    80003902:	00001097          	auipc	ra,0x1
    80003906:	c7c080e7          	jalr	-900(ra) # 8000457e <holdingsleep>
    8000390a:	cd19                	beqz	a0,80003928 <iunlock+0x3c>
    8000390c:	449c                	lw	a5,8(s1)
    8000390e:	00f05d63          	blez	a5,80003928 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003912:	854a                	mv	a0,s2
    80003914:	00001097          	auipc	ra,0x1
    80003918:	c26080e7          	jalr	-986(ra) # 8000453a <releasesleep>
}
    8000391c:	60e2                	ld	ra,24(sp)
    8000391e:	6442                	ld	s0,16(sp)
    80003920:	64a2                	ld	s1,8(sp)
    80003922:	6902                	ld	s2,0(sp)
    80003924:	6105                	addi	sp,sp,32
    80003926:	8082                	ret
    panic("iunlock");
    80003928:	00005517          	auipc	a0,0x5
    8000392c:	d0050513          	addi	a0,a0,-768 # 80008628 <syscalls+0x198>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	c18080e7          	jalr	-1000(ra) # 80000548 <panic>

0000000080003938 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003938:	7179                	addi	sp,sp,-48
    8000393a:	f406                	sd	ra,40(sp)
    8000393c:	f022                	sd	s0,32(sp)
    8000393e:	ec26                	sd	s1,24(sp)
    80003940:	e84a                	sd	s2,16(sp)
    80003942:	e44e                	sd	s3,8(sp)
    80003944:	e052                	sd	s4,0(sp)
    80003946:	1800                	addi	s0,sp,48
    80003948:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000394a:	05050493          	addi	s1,a0,80
    8000394e:	08050913          	addi	s2,a0,128
    80003952:	a021                	j	8000395a <itrunc+0x22>
    80003954:	0491                	addi	s1,s1,4
    80003956:	01248d63          	beq	s1,s2,80003970 <itrunc+0x38>
    if(ip->addrs[i]){
    8000395a:	408c                	lw	a1,0(s1)
    8000395c:	dde5                	beqz	a1,80003954 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000395e:	0009a503          	lw	a0,0(s3)
    80003962:	00000097          	auipc	ra,0x0
    80003966:	90c080e7          	jalr	-1780(ra) # 8000326e <bfree>
      ip->addrs[i] = 0;
    8000396a:	0004a023          	sw	zero,0(s1)
    8000396e:	b7dd                	j	80003954 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003970:	0809a583          	lw	a1,128(s3)
    80003974:	e185                	bnez	a1,80003994 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003976:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000397a:	854e                	mv	a0,s3
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	de4080e7          	jalr	-540(ra) # 80003760 <iupdate>
}
    80003984:	70a2                	ld	ra,40(sp)
    80003986:	7402                	ld	s0,32(sp)
    80003988:	64e2                	ld	s1,24(sp)
    8000398a:	6942                	ld	s2,16(sp)
    8000398c:	69a2                	ld	s3,8(sp)
    8000398e:	6a02                	ld	s4,0(sp)
    80003990:	6145                	addi	sp,sp,48
    80003992:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003994:	0009a503          	lw	a0,0(s3)
    80003998:	fffff097          	auipc	ra,0xfffff
    8000399c:	690080e7          	jalr	1680(ra) # 80003028 <bread>
    800039a0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039a2:	05850493          	addi	s1,a0,88
    800039a6:	45850913          	addi	s2,a0,1112
    800039aa:	a811                	j	800039be <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039ac:	0009a503          	lw	a0,0(s3)
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	8be080e7          	jalr	-1858(ra) # 8000326e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039b8:	0491                	addi	s1,s1,4
    800039ba:	01248563          	beq	s1,s2,800039c4 <itrunc+0x8c>
      if(a[j])
    800039be:	408c                	lw	a1,0(s1)
    800039c0:	dde5                	beqz	a1,800039b8 <itrunc+0x80>
    800039c2:	b7ed                	j	800039ac <itrunc+0x74>
    brelse(bp);
    800039c4:	8552                	mv	a0,s4
    800039c6:	fffff097          	auipc	ra,0xfffff
    800039ca:	792080e7          	jalr	1938(ra) # 80003158 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039ce:	0809a583          	lw	a1,128(s3)
    800039d2:	0009a503          	lw	a0,0(s3)
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	898080e7          	jalr	-1896(ra) # 8000326e <bfree>
    ip->addrs[NDIRECT] = 0;
    800039de:	0809a023          	sw	zero,128(s3)
    800039e2:	bf51                	j	80003976 <itrunc+0x3e>

00000000800039e4 <iput>:
{
    800039e4:	1101                	addi	sp,sp,-32
    800039e6:	ec06                	sd	ra,24(sp)
    800039e8:	e822                	sd	s0,16(sp)
    800039ea:	e426                	sd	s1,8(sp)
    800039ec:	e04a                	sd	s2,0(sp)
    800039ee:	1000                	addi	s0,sp,32
    800039f0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039f2:	0001c517          	auipc	a0,0x1c
    800039f6:	66e50513          	addi	a0,a0,1646 # 80020060 <icache>
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	216080e7          	jalr	534(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a02:	4498                	lw	a4,8(s1)
    80003a04:	4785                	li	a5,1
    80003a06:	02f70363          	beq	a4,a5,80003a2c <iput+0x48>
  ip->ref--;
    80003a0a:	449c                	lw	a5,8(s1)
    80003a0c:	37fd                	addiw	a5,a5,-1
    80003a0e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a10:	0001c517          	auipc	a0,0x1c
    80003a14:	65050513          	addi	a0,a0,1616 # 80020060 <icache>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	2ac080e7          	jalr	684(ra) # 80000cc4 <release>
}
    80003a20:	60e2                	ld	ra,24(sp)
    80003a22:	6442                	ld	s0,16(sp)
    80003a24:	64a2                	ld	s1,8(sp)
    80003a26:	6902                	ld	s2,0(sp)
    80003a28:	6105                	addi	sp,sp,32
    80003a2a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a2c:	40bc                	lw	a5,64(s1)
    80003a2e:	dff1                	beqz	a5,80003a0a <iput+0x26>
    80003a30:	04a49783          	lh	a5,74(s1)
    80003a34:	fbf9                	bnez	a5,80003a0a <iput+0x26>
    acquiresleep(&ip->lock);
    80003a36:	01048913          	addi	s2,s1,16
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	00001097          	auipc	ra,0x1
    80003a40:	aa8080e7          	jalr	-1368(ra) # 800044e4 <acquiresleep>
    release(&icache.lock);
    80003a44:	0001c517          	auipc	a0,0x1c
    80003a48:	61c50513          	addi	a0,a0,1564 # 80020060 <icache>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	278080e7          	jalr	632(ra) # 80000cc4 <release>
    itrunc(ip);
    80003a54:	8526                	mv	a0,s1
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	ee2080e7          	jalr	-286(ra) # 80003938 <itrunc>
    ip->type = 0;
    80003a5e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a62:	8526                	mv	a0,s1
    80003a64:	00000097          	auipc	ra,0x0
    80003a68:	cfc080e7          	jalr	-772(ra) # 80003760 <iupdate>
    ip->valid = 0;
    80003a6c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a70:	854a                	mv	a0,s2
    80003a72:	00001097          	auipc	ra,0x1
    80003a76:	ac8080e7          	jalr	-1336(ra) # 8000453a <releasesleep>
    acquire(&icache.lock);
    80003a7a:	0001c517          	auipc	a0,0x1c
    80003a7e:	5e650513          	addi	a0,a0,1510 # 80020060 <icache>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	18e080e7          	jalr	398(ra) # 80000c10 <acquire>
    80003a8a:	b741                	j	80003a0a <iput+0x26>

0000000080003a8c <iunlockput>:
{
    80003a8c:	1101                	addi	sp,sp,-32
    80003a8e:	ec06                	sd	ra,24(sp)
    80003a90:	e822                	sd	s0,16(sp)
    80003a92:	e426                	sd	s1,8(sp)
    80003a94:	1000                	addi	s0,sp,32
    80003a96:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	e54080e7          	jalr	-428(ra) # 800038ec <iunlock>
  iput(ip);
    80003aa0:	8526                	mv	a0,s1
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	f42080e7          	jalr	-190(ra) # 800039e4 <iput>
}
    80003aaa:	60e2                	ld	ra,24(sp)
    80003aac:	6442                	ld	s0,16(sp)
    80003aae:	64a2                	ld	s1,8(sp)
    80003ab0:	6105                	addi	sp,sp,32
    80003ab2:	8082                	ret

0000000080003ab4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ab4:	1141                	addi	sp,sp,-16
    80003ab6:	e422                	sd	s0,8(sp)
    80003ab8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003aba:	411c                	lw	a5,0(a0)
    80003abc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003abe:	415c                	lw	a5,4(a0)
    80003ac0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ac2:	04451783          	lh	a5,68(a0)
    80003ac6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003aca:	04a51783          	lh	a5,74(a0)
    80003ace:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ad2:	04c56783          	lwu	a5,76(a0)
    80003ad6:	e99c                	sd	a5,16(a1)
}
    80003ad8:	6422                	ld	s0,8(sp)
    80003ada:	0141                	addi	sp,sp,16
    80003adc:	8082                	ret

0000000080003ade <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ade:	457c                	lw	a5,76(a0)
    80003ae0:	0ed7e863          	bltu	a5,a3,80003bd0 <readi+0xf2>
{
    80003ae4:	7159                	addi	sp,sp,-112
    80003ae6:	f486                	sd	ra,104(sp)
    80003ae8:	f0a2                	sd	s0,96(sp)
    80003aea:	eca6                	sd	s1,88(sp)
    80003aec:	e8ca                	sd	s2,80(sp)
    80003aee:	e4ce                	sd	s3,72(sp)
    80003af0:	e0d2                	sd	s4,64(sp)
    80003af2:	fc56                	sd	s5,56(sp)
    80003af4:	f85a                	sd	s6,48(sp)
    80003af6:	f45e                	sd	s7,40(sp)
    80003af8:	f062                	sd	s8,32(sp)
    80003afa:	ec66                	sd	s9,24(sp)
    80003afc:	e86a                	sd	s10,16(sp)
    80003afe:	e46e                	sd	s11,8(sp)
    80003b00:	1880                	addi	s0,sp,112
    80003b02:	8baa                	mv	s7,a0
    80003b04:	8c2e                	mv	s8,a1
    80003b06:	8ab2                	mv	s5,a2
    80003b08:	84b6                	mv	s1,a3
    80003b0a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b0c:	9f35                	addw	a4,a4,a3
    return 0;
    80003b0e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b10:	08d76f63          	bltu	a4,a3,80003bae <readi+0xd0>
  if(off + n > ip->size)
    80003b14:	00e7f463          	bgeu	a5,a4,80003b1c <readi+0x3e>
    n = ip->size - off;
    80003b18:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b1c:	0a0b0863          	beqz	s6,80003bcc <readi+0xee>
    80003b20:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b22:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b26:	5cfd                	li	s9,-1
    80003b28:	a82d                	j	80003b62 <readi+0x84>
    80003b2a:	020a1d93          	slli	s11,s4,0x20
    80003b2e:	020ddd93          	srli	s11,s11,0x20
    80003b32:	05890613          	addi	a2,s2,88
    80003b36:	86ee                	mv	a3,s11
    80003b38:	963a                	add	a2,a2,a4
    80003b3a:	85d6                	mv	a1,s5
    80003b3c:	8562                	mv	a0,s8
    80003b3e:	fffff097          	auipc	ra,0xfffff
    80003b42:	b2e080e7          	jalr	-1234(ra) # 8000266c <either_copyout>
    80003b46:	05950d63          	beq	a0,s9,80003ba0 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b4a:	854a                	mv	a0,s2
    80003b4c:	fffff097          	auipc	ra,0xfffff
    80003b50:	60c080e7          	jalr	1548(ra) # 80003158 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b54:	013a09bb          	addw	s3,s4,s3
    80003b58:	009a04bb          	addw	s1,s4,s1
    80003b5c:	9aee                	add	s5,s5,s11
    80003b5e:	0569f663          	bgeu	s3,s6,80003baa <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b62:	000ba903          	lw	s2,0(s7)
    80003b66:	00a4d59b          	srliw	a1,s1,0xa
    80003b6a:	855e                	mv	a0,s7
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	8b0080e7          	jalr	-1872(ra) # 8000341c <bmap>
    80003b74:	0005059b          	sext.w	a1,a0
    80003b78:	854a                	mv	a0,s2
    80003b7a:	fffff097          	auipc	ra,0xfffff
    80003b7e:	4ae080e7          	jalr	1198(ra) # 80003028 <bread>
    80003b82:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b84:	3ff4f713          	andi	a4,s1,1023
    80003b88:	40ed07bb          	subw	a5,s10,a4
    80003b8c:	413b06bb          	subw	a3,s6,s3
    80003b90:	8a3e                	mv	s4,a5
    80003b92:	2781                	sext.w	a5,a5
    80003b94:	0006861b          	sext.w	a2,a3
    80003b98:	f8f679e3          	bgeu	a2,a5,80003b2a <readi+0x4c>
    80003b9c:	8a36                	mv	s4,a3
    80003b9e:	b771                	j	80003b2a <readi+0x4c>
      brelse(bp);
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	5b6080e7          	jalr	1462(ra) # 80003158 <brelse>
  }
  return tot;
    80003baa:	0009851b          	sext.w	a0,s3
}
    80003bae:	70a6                	ld	ra,104(sp)
    80003bb0:	7406                	ld	s0,96(sp)
    80003bb2:	64e6                	ld	s1,88(sp)
    80003bb4:	6946                	ld	s2,80(sp)
    80003bb6:	69a6                	ld	s3,72(sp)
    80003bb8:	6a06                	ld	s4,64(sp)
    80003bba:	7ae2                	ld	s5,56(sp)
    80003bbc:	7b42                	ld	s6,48(sp)
    80003bbe:	7ba2                	ld	s7,40(sp)
    80003bc0:	7c02                	ld	s8,32(sp)
    80003bc2:	6ce2                	ld	s9,24(sp)
    80003bc4:	6d42                	ld	s10,16(sp)
    80003bc6:	6da2                	ld	s11,8(sp)
    80003bc8:	6165                	addi	sp,sp,112
    80003bca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bcc:	89da                	mv	s3,s6
    80003bce:	bff1                	j	80003baa <readi+0xcc>
    return 0;
    80003bd0:	4501                	li	a0,0
}
    80003bd2:	8082                	ret

0000000080003bd4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bd4:	457c                	lw	a5,76(a0)
    80003bd6:	10d7e663          	bltu	a5,a3,80003ce2 <writei+0x10e>
{
    80003bda:	7159                	addi	sp,sp,-112
    80003bdc:	f486                	sd	ra,104(sp)
    80003bde:	f0a2                	sd	s0,96(sp)
    80003be0:	eca6                	sd	s1,88(sp)
    80003be2:	e8ca                	sd	s2,80(sp)
    80003be4:	e4ce                	sd	s3,72(sp)
    80003be6:	e0d2                	sd	s4,64(sp)
    80003be8:	fc56                	sd	s5,56(sp)
    80003bea:	f85a                	sd	s6,48(sp)
    80003bec:	f45e                	sd	s7,40(sp)
    80003bee:	f062                	sd	s8,32(sp)
    80003bf0:	ec66                	sd	s9,24(sp)
    80003bf2:	e86a                	sd	s10,16(sp)
    80003bf4:	e46e                	sd	s11,8(sp)
    80003bf6:	1880                	addi	s0,sp,112
    80003bf8:	8baa                	mv	s7,a0
    80003bfa:	8c2e                	mv	s8,a1
    80003bfc:	8ab2                	mv	s5,a2
    80003bfe:	8936                	mv	s2,a3
    80003c00:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c02:	00e687bb          	addw	a5,a3,a4
    80003c06:	0ed7e063          	bltu	a5,a3,80003ce6 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c0a:	00043737          	lui	a4,0x43
    80003c0e:	0cf76e63          	bltu	a4,a5,80003cea <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c12:	0a0b0763          	beqz	s6,80003cc0 <writei+0xec>
    80003c16:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c18:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c1c:	5cfd                	li	s9,-1
    80003c1e:	a091                	j	80003c62 <writei+0x8e>
    80003c20:	02099d93          	slli	s11,s3,0x20
    80003c24:	020ddd93          	srli	s11,s11,0x20
    80003c28:	05848513          	addi	a0,s1,88
    80003c2c:	86ee                	mv	a3,s11
    80003c2e:	8656                	mv	a2,s5
    80003c30:	85e2                	mv	a1,s8
    80003c32:	953a                	add	a0,a0,a4
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	a8e080e7          	jalr	-1394(ra) # 800026c2 <either_copyin>
    80003c3c:	07950263          	beq	a0,s9,80003ca0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c40:	8526                	mv	a0,s1
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	77a080e7          	jalr	1914(ra) # 800043bc <log_write>
    brelse(bp);
    80003c4a:	8526                	mv	a0,s1
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	50c080e7          	jalr	1292(ra) # 80003158 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c54:	01498a3b          	addw	s4,s3,s4
    80003c58:	0129893b          	addw	s2,s3,s2
    80003c5c:	9aee                	add	s5,s5,s11
    80003c5e:	056a7663          	bgeu	s4,s6,80003caa <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c62:	000ba483          	lw	s1,0(s7)
    80003c66:	00a9559b          	srliw	a1,s2,0xa
    80003c6a:	855e                	mv	a0,s7
    80003c6c:	fffff097          	auipc	ra,0xfffff
    80003c70:	7b0080e7          	jalr	1968(ra) # 8000341c <bmap>
    80003c74:	0005059b          	sext.w	a1,a0
    80003c78:	8526                	mv	a0,s1
    80003c7a:	fffff097          	auipc	ra,0xfffff
    80003c7e:	3ae080e7          	jalr	942(ra) # 80003028 <bread>
    80003c82:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c84:	3ff97713          	andi	a4,s2,1023
    80003c88:	40ed07bb          	subw	a5,s10,a4
    80003c8c:	414b06bb          	subw	a3,s6,s4
    80003c90:	89be                	mv	s3,a5
    80003c92:	2781                	sext.w	a5,a5
    80003c94:	0006861b          	sext.w	a2,a3
    80003c98:	f8f674e3          	bgeu	a2,a5,80003c20 <writei+0x4c>
    80003c9c:	89b6                	mv	s3,a3
    80003c9e:	b749                	j	80003c20 <writei+0x4c>
      brelse(bp);
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	4b6080e7          	jalr	1206(ra) # 80003158 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003caa:	04cba783          	lw	a5,76(s7)
    80003cae:	0127f463          	bgeu	a5,s2,80003cb6 <writei+0xe2>
      ip->size = off;
    80003cb2:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003cb6:	855e                	mv	a0,s7
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	aa8080e7          	jalr	-1368(ra) # 80003760 <iupdate>
  }

  return n;
    80003cc0:	000b051b          	sext.w	a0,s6
}
    80003cc4:	70a6                	ld	ra,104(sp)
    80003cc6:	7406                	ld	s0,96(sp)
    80003cc8:	64e6                	ld	s1,88(sp)
    80003cca:	6946                	ld	s2,80(sp)
    80003ccc:	69a6                	ld	s3,72(sp)
    80003cce:	6a06                	ld	s4,64(sp)
    80003cd0:	7ae2                	ld	s5,56(sp)
    80003cd2:	7b42                	ld	s6,48(sp)
    80003cd4:	7ba2                	ld	s7,40(sp)
    80003cd6:	7c02                	ld	s8,32(sp)
    80003cd8:	6ce2                	ld	s9,24(sp)
    80003cda:	6d42                	ld	s10,16(sp)
    80003cdc:	6da2                	ld	s11,8(sp)
    80003cde:	6165                	addi	sp,sp,112
    80003ce0:	8082                	ret
    return -1;
    80003ce2:	557d                	li	a0,-1
}
    80003ce4:	8082                	ret
    return -1;
    80003ce6:	557d                	li	a0,-1
    80003ce8:	bff1                	j	80003cc4 <writei+0xf0>
    return -1;
    80003cea:	557d                	li	a0,-1
    80003cec:	bfe1                	j	80003cc4 <writei+0xf0>

0000000080003cee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cee:	1141                	addi	sp,sp,-16
    80003cf0:	e406                	sd	ra,8(sp)
    80003cf2:	e022                	sd	s0,0(sp)
    80003cf4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cf6:	4639                	li	a2,14
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	0f0080e7          	jalr	240(ra) # 80000de8 <strncmp>
}
    80003d00:	60a2                	ld	ra,8(sp)
    80003d02:	6402                	ld	s0,0(sp)
    80003d04:	0141                	addi	sp,sp,16
    80003d06:	8082                	ret

0000000080003d08 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d08:	7139                	addi	sp,sp,-64
    80003d0a:	fc06                	sd	ra,56(sp)
    80003d0c:	f822                	sd	s0,48(sp)
    80003d0e:	f426                	sd	s1,40(sp)
    80003d10:	f04a                	sd	s2,32(sp)
    80003d12:	ec4e                	sd	s3,24(sp)
    80003d14:	e852                	sd	s4,16(sp)
    80003d16:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d18:	04451703          	lh	a4,68(a0)
    80003d1c:	4785                	li	a5,1
    80003d1e:	00f71a63          	bne	a4,a5,80003d32 <dirlookup+0x2a>
    80003d22:	892a                	mv	s2,a0
    80003d24:	89ae                	mv	s3,a1
    80003d26:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d28:	457c                	lw	a5,76(a0)
    80003d2a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d2c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d2e:	e79d                	bnez	a5,80003d5c <dirlookup+0x54>
    80003d30:	a8a5                	j	80003da8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d32:	00005517          	auipc	a0,0x5
    80003d36:	8fe50513          	addi	a0,a0,-1794 # 80008630 <syscalls+0x1a0>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	80e080e7          	jalr	-2034(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003d42:	00005517          	auipc	a0,0x5
    80003d46:	90650513          	addi	a0,a0,-1786 # 80008648 <syscalls+0x1b8>
    80003d4a:	ffffc097          	auipc	ra,0xffffc
    80003d4e:	7fe080e7          	jalr	2046(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d52:	24c1                	addiw	s1,s1,16
    80003d54:	04c92783          	lw	a5,76(s2)
    80003d58:	04f4f763          	bgeu	s1,a5,80003da6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d5c:	4741                	li	a4,16
    80003d5e:	86a6                	mv	a3,s1
    80003d60:	fc040613          	addi	a2,s0,-64
    80003d64:	4581                	li	a1,0
    80003d66:	854a                	mv	a0,s2
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	d76080e7          	jalr	-650(ra) # 80003ade <readi>
    80003d70:	47c1                	li	a5,16
    80003d72:	fcf518e3          	bne	a0,a5,80003d42 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d76:	fc045783          	lhu	a5,-64(s0)
    80003d7a:	dfe1                	beqz	a5,80003d52 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d7c:	fc240593          	addi	a1,s0,-62
    80003d80:	854e                	mv	a0,s3
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	f6c080e7          	jalr	-148(ra) # 80003cee <namecmp>
    80003d8a:	f561                	bnez	a0,80003d52 <dirlookup+0x4a>
      if(poff)
    80003d8c:	000a0463          	beqz	s4,80003d94 <dirlookup+0x8c>
        *poff = off;
    80003d90:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d94:	fc045583          	lhu	a1,-64(s0)
    80003d98:	00092503          	lw	a0,0(s2)
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	75a080e7          	jalr	1882(ra) # 800034f6 <iget>
    80003da4:	a011                	j	80003da8 <dirlookup+0xa0>
  return 0;
    80003da6:	4501                	li	a0,0
}
    80003da8:	70e2                	ld	ra,56(sp)
    80003daa:	7442                	ld	s0,48(sp)
    80003dac:	74a2                	ld	s1,40(sp)
    80003dae:	7902                	ld	s2,32(sp)
    80003db0:	69e2                	ld	s3,24(sp)
    80003db2:	6a42                	ld	s4,16(sp)
    80003db4:	6121                	addi	sp,sp,64
    80003db6:	8082                	ret

0000000080003db8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003db8:	711d                	addi	sp,sp,-96
    80003dba:	ec86                	sd	ra,88(sp)
    80003dbc:	e8a2                	sd	s0,80(sp)
    80003dbe:	e4a6                	sd	s1,72(sp)
    80003dc0:	e0ca                	sd	s2,64(sp)
    80003dc2:	fc4e                	sd	s3,56(sp)
    80003dc4:	f852                	sd	s4,48(sp)
    80003dc6:	f456                	sd	s5,40(sp)
    80003dc8:	f05a                	sd	s6,32(sp)
    80003dca:	ec5e                	sd	s7,24(sp)
    80003dcc:	e862                	sd	s8,16(sp)
    80003dce:	e466                	sd	s9,8(sp)
    80003dd0:	1080                	addi	s0,sp,96
    80003dd2:	84aa                	mv	s1,a0
    80003dd4:	8b2e                	mv	s6,a1
    80003dd6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dd8:	00054703          	lbu	a4,0(a0)
    80003ddc:	02f00793          	li	a5,47
    80003de0:	02f70363          	beq	a4,a5,80003e06 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003de4:	ffffe097          	auipc	ra,0xffffe
    80003de8:	cfe080e7          	jalr	-770(ra) # 80001ae2 <myproc>
    80003dec:	15053503          	ld	a0,336(a0)
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	9fc080e7          	jalr	-1540(ra) # 800037ec <idup>
    80003df8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dfa:	02f00913          	li	s2,47
  len = path - s;
    80003dfe:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e00:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e02:	4c05                	li	s8,1
    80003e04:	a865                	j	80003ebc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e06:	4585                	li	a1,1
    80003e08:	4505                	li	a0,1
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	6ec080e7          	jalr	1772(ra) # 800034f6 <iget>
    80003e12:	89aa                	mv	s3,a0
    80003e14:	b7dd                	j	80003dfa <namex+0x42>
      iunlockput(ip);
    80003e16:	854e                	mv	a0,s3
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	c74080e7          	jalr	-908(ra) # 80003a8c <iunlockput>
      return 0;
    80003e20:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e22:	854e                	mv	a0,s3
    80003e24:	60e6                	ld	ra,88(sp)
    80003e26:	6446                	ld	s0,80(sp)
    80003e28:	64a6                	ld	s1,72(sp)
    80003e2a:	6906                	ld	s2,64(sp)
    80003e2c:	79e2                	ld	s3,56(sp)
    80003e2e:	7a42                	ld	s4,48(sp)
    80003e30:	7aa2                	ld	s5,40(sp)
    80003e32:	7b02                	ld	s6,32(sp)
    80003e34:	6be2                	ld	s7,24(sp)
    80003e36:	6c42                	ld	s8,16(sp)
    80003e38:	6ca2                	ld	s9,8(sp)
    80003e3a:	6125                	addi	sp,sp,96
    80003e3c:	8082                	ret
      iunlock(ip);
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	aac080e7          	jalr	-1364(ra) # 800038ec <iunlock>
      return ip;
    80003e48:	bfe9                	j	80003e22 <namex+0x6a>
      iunlockput(ip);
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	c40080e7          	jalr	-960(ra) # 80003a8c <iunlockput>
      return 0;
    80003e54:	89d2                	mv	s3,s4
    80003e56:	b7f1                	j	80003e22 <namex+0x6a>
  len = path - s;
    80003e58:	40b48633          	sub	a2,s1,a1
    80003e5c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e60:	094cd463          	bge	s9,s4,80003ee8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e64:	4639                	li	a2,14
    80003e66:	8556                	mv	a0,s5
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	f04080e7          	jalr	-252(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	01279763          	bne	a5,s2,80003e82 <namex+0xca>
    path++;
    80003e78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e7a:	0004c783          	lbu	a5,0(s1)
    80003e7e:	ff278de3          	beq	a5,s2,80003e78 <namex+0xc0>
    ilock(ip);
    80003e82:	854e                	mv	a0,s3
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	9a6080e7          	jalr	-1626(ra) # 8000382a <ilock>
    if(ip->type != T_DIR){
    80003e8c:	04499783          	lh	a5,68(s3)
    80003e90:	f98793e3          	bne	a5,s8,80003e16 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e94:	000b0563          	beqz	s6,80003e9e <namex+0xe6>
    80003e98:	0004c783          	lbu	a5,0(s1)
    80003e9c:	d3cd                	beqz	a5,80003e3e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e9e:	865e                	mv	a2,s7
    80003ea0:	85d6                	mv	a1,s5
    80003ea2:	854e                	mv	a0,s3
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	e64080e7          	jalr	-412(ra) # 80003d08 <dirlookup>
    80003eac:	8a2a                	mv	s4,a0
    80003eae:	dd51                	beqz	a0,80003e4a <namex+0x92>
    iunlockput(ip);
    80003eb0:	854e                	mv	a0,s3
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	bda080e7          	jalr	-1062(ra) # 80003a8c <iunlockput>
    ip = next;
    80003eba:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	05279763          	bne	a5,s2,80003f0e <namex+0x156>
    path++;
    80003ec4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ec6:	0004c783          	lbu	a5,0(s1)
    80003eca:	ff278de3          	beq	a5,s2,80003ec4 <namex+0x10c>
  if(*path == 0)
    80003ece:	c79d                	beqz	a5,80003efc <namex+0x144>
    path++;
    80003ed0:	85a6                	mv	a1,s1
  len = path - s;
    80003ed2:	8a5e                	mv	s4,s7
    80003ed4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ed6:	01278963          	beq	a5,s2,80003ee8 <namex+0x130>
    80003eda:	dfbd                	beqz	a5,80003e58 <namex+0xa0>
    path++;
    80003edc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ede:	0004c783          	lbu	a5,0(s1)
    80003ee2:	ff279ce3          	bne	a5,s2,80003eda <namex+0x122>
    80003ee6:	bf8d                	j	80003e58 <namex+0xa0>
    memmove(name, s, len);
    80003ee8:	2601                	sext.w	a2,a2
    80003eea:	8556                	mv	a0,s5
    80003eec:	ffffd097          	auipc	ra,0xffffd
    80003ef0:	e80080e7          	jalr	-384(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003ef4:	9a56                	add	s4,s4,s5
    80003ef6:	000a0023          	sb	zero,0(s4)
    80003efa:	bf9d                	j	80003e70 <namex+0xb8>
  if(nameiparent){
    80003efc:	f20b03e3          	beqz	s6,80003e22 <namex+0x6a>
    iput(ip);
    80003f00:	854e                	mv	a0,s3
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	ae2080e7          	jalr	-1310(ra) # 800039e4 <iput>
    return 0;
    80003f0a:	4981                	li	s3,0
    80003f0c:	bf19                	j	80003e22 <namex+0x6a>
  if(*path == 0)
    80003f0e:	d7fd                	beqz	a5,80003efc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f10:	0004c783          	lbu	a5,0(s1)
    80003f14:	85a6                	mv	a1,s1
    80003f16:	b7d1                	j	80003eda <namex+0x122>

0000000080003f18 <dirlink>:
{
    80003f18:	7139                	addi	sp,sp,-64
    80003f1a:	fc06                	sd	ra,56(sp)
    80003f1c:	f822                	sd	s0,48(sp)
    80003f1e:	f426                	sd	s1,40(sp)
    80003f20:	f04a                	sd	s2,32(sp)
    80003f22:	ec4e                	sd	s3,24(sp)
    80003f24:	e852                	sd	s4,16(sp)
    80003f26:	0080                	addi	s0,sp,64
    80003f28:	892a                	mv	s2,a0
    80003f2a:	8a2e                	mv	s4,a1
    80003f2c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f2e:	4601                	li	a2,0
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	dd8080e7          	jalr	-552(ra) # 80003d08 <dirlookup>
    80003f38:	e93d                	bnez	a0,80003fae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3a:	04c92483          	lw	s1,76(s2)
    80003f3e:	c49d                	beqz	s1,80003f6c <dirlink+0x54>
    80003f40:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f42:	4741                	li	a4,16
    80003f44:	86a6                	mv	a3,s1
    80003f46:	fc040613          	addi	a2,s0,-64
    80003f4a:	4581                	li	a1,0
    80003f4c:	854a                	mv	a0,s2
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	b90080e7          	jalr	-1136(ra) # 80003ade <readi>
    80003f56:	47c1                	li	a5,16
    80003f58:	06f51163          	bne	a0,a5,80003fba <dirlink+0xa2>
    if(de.inum == 0)
    80003f5c:	fc045783          	lhu	a5,-64(s0)
    80003f60:	c791                	beqz	a5,80003f6c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f62:	24c1                	addiw	s1,s1,16
    80003f64:	04c92783          	lw	a5,76(s2)
    80003f68:	fcf4ede3          	bltu	s1,a5,80003f42 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f6c:	4639                	li	a2,14
    80003f6e:	85d2                	mv	a1,s4
    80003f70:	fc240513          	addi	a0,s0,-62
    80003f74:	ffffd097          	auipc	ra,0xffffd
    80003f78:	eb0080e7          	jalr	-336(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003f7c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f80:	4741                	li	a4,16
    80003f82:	86a6                	mv	a3,s1
    80003f84:	fc040613          	addi	a2,s0,-64
    80003f88:	4581                	li	a1,0
    80003f8a:	854a                	mv	a0,s2
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	c48080e7          	jalr	-952(ra) # 80003bd4 <writei>
    80003f94:	872a                	mv	a4,a0
    80003f96:	47c1                	li	a5,16
  return 0;
    80003f98:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f9a:	02f71863          	bne	a4,a5,80003fca <dirlink+0xb2>
}
    80003f9e:	70e2                	ld	ra,56(sp)
    80003fa0:	7442                	ld	s0,48(sp)
    80003fa2:	74a2                	ld	s1,40(sp)
    80003fa4:	7902                	ld	s2,32(sp)
    80003fa6:	69e2                	ld	s3,24(sp)
    80003fa8:	6a42                	ld	s4,16(sp)
    80003faa:	6121                	addi	sp,sp,64
    80003fac:	8082                	ret
    iput(ip);
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	a36080e7          	jalr	-1482(ra) # 800039e4 <iput>
    return -1;
    80003fb6:	557d                	li	a0,-1
    80003fb8:	b7dd                	j	80003f9e <dirlink+0x86>
      panic("dirlink read");
    80003fba:	00004517          	auipc	a0,0x4
    80003fbe:	69e50513          	addi	a0,a0,1694 # 80008658 <syscalls+0x1c8>
    80003fc2:	ffffc097          	auipc	ra,0xffffc
    80003fc6:	586080e7          	jalr	1414(ra) # 80000548 <panic>
    panic("dirlink");
    80003fca:	00004517          	auipc	a0,0x4
    80003fce:	7a650513          	addi	a0,a0,1958 # 80008770 <syscalls+0x2e0>
    80003fd2:	ffffc097          	auipc	ra,0xffffc
    80003fd6:	576080e7          	jalr	1398(ra) # 80000548 <panic>

0000000080003fda <namei>:

struct inode*
namei(char *path)
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fe2:	fe040613          	addi	a2,s0,-32
    80003fe6:	4581                	li	a1,0
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	dd0080e7          	jalr	-560(ra) # 80003db8 <namex>
}
    80003ff0:	60e2                	ld	ra,24(sp)
    80003ff2:	6442                	ld	s0,16(sp)
    80003ff4:	6105                	addi	sp,sp,32
    80003ff6:	8082                	ret

0000000080003ff8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ff8:	1141                	addi	sp,sp,-16
    80003ffa:	e406                	sd	ra,8(sp)
    80003ffc:	e022                	sd	s0,0(sp)
    80003ffe:	0800                	addi	s0,sp,16
    80004000:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004002:	4585                	li	a1,1
    80004004:	00000097          	auipc	ra,0x0
    80004008:	db4080e7          	jalr	-588(ra) # 80003db8 <namex>
}
    8000400c:	60a2                	ld	ra,8(sp)
    8000400e:	6402                	ld	s0,0(sp)
    80004010:	0141                	addi	sp,sp,16
    80004012:	8082                	ret

0000000080004014 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004014:	1101                	addi	sp,sp,-32
    80004016:	ec06                	sd	ra,24(sp)
    80004018:	e822                	sd	s0,16(sp)
    8000401a:	e426                	sd	s1,8(sp)
    8000401c:	e04a                	sd	s2,0(sp)
    8000401e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004020:	0001e917          	auipc	s2,0x1e
    80004024:	ae890913          	addi	s2,s2,-1304 # 80021b08 <log>
    80004028:	01892583          	lw	a1,24(s2)
    8000402c:	02892503          	lw	a0,40(s2)
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	ff8080e7          	jalr	-8(ra) # 80003028 <bread>
    80004038:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000403a:	02c92683          	lw	a3,44(s2)
    8000403e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004040:	02d05763          	blez	a3,8000406e <write_head+0x5a>
    80004044:	0001e797          	auipc	a5,0x1e
    80004048:	af478793          	addi	a5,a5,-1292 # 80021b38 <log+0x30>
    8000404c:	05c50713          	addi	a4,a0,92
    80004050:	36fd                	addiw	a3,a3,-1
    80004052:	1682                	slli	a3,a3,0x20
    80004054:	9281                	srli	a3,a3,0x20
    80004056:	068a                	slli	a3,a3,0x2
    80004058:	0001e617          	auipc	a2,0x1e
    8000405c:	ae460613          	addi	a2,a2,-1308 # 80021b3c <log+0x34>
    80004060:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004062:	4390                	lw	a2,0(a5)
    80004064:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004066:	0791                	addi	a5,a5,4
    80004068:	0711                	addi	a4,a4,4
    8000406a:	fed79ce3          	bne	a5,a3,80004062 <write_head+0x4e>
  }
  bwrite(buf);
    8000406e:	8526                	mv	a0,s1
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	0aa080e7          	jalr	170(ra) # 8000311a <bwrite>
  brelse(buf);
    80004078:	8526                	mv	a0,s1
    8000407a:	fffff097          	auipc	ra,0xfffff
    8000407e:	0de080e7          	jalr	222(ra) # 80003158 <brelse>
}
    80004082:	60e2                	ld	ra,24(sp)
    80004084:	6442                	ld	s0,16(sp)
    80004086:	64a2                	ld	s1,8(sp)
    80004088:	6902                	ld	s2,0(sp)
    8000408a:	6105                	addi	sp,sp,32
    8000408c:	8082                	ret

000000008000408e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408e:	0001e797          	auipc	a5,0x1e
    80004092:	aa67a783          	lw	a5,-1370(a5) # 80021b34 <log+0x2c>
    80004096:	0af05663          	blez	a5,80004142 <install_trans+0xb4>
{
    8000409a:	7139                	addi	sp,sp,-64
    8000409c:	fc06                	sd	ra,56(sp)
    8000409e:	f822                	sd	s0,48(sp)
    800040a0:	f426                	sd	s1,40(sp)
    800040a2:	f04a                	sd	s2,32(sp)
    800040a4:	ec4e                	sd	s3,24(sp)
    800040a6:	e852                	sd	s4,16(sp)
    800040a8:	e456                	sd	s5,8(sp)
    800040aa:	0080                	addi	s0,sp,64
    800040ac:	0001ea97          	auipc	s5,0x1e
    800040b0:	a8ca8a93          	addi	s5,s5,-1396 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040b6:	0001e997          	auipc	s3,0x1e
    800040ba:	a5298993          	addi	s3,s3,-1454 # 80021b08 <log>
    800040be:	0189a583          	lw	a1,24(s3)
    800040c2:	014585bb          	addw	a1,a1,s4
    800040c6:	2585                	addiw	a1,a1,1
    800040c8:	0289a503          	lw	a0,40(s3)
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	f5c080e7          	jalr	-164(ra) # 80003028 <bread>
    800040d4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040d6:	000aa583          	lw	a1,0(s5)
    800040da:	0289a503          	lw	a0,40(s3)
    800040de:	fffff097          	auipc	ra,0xfffff
    800040e2:	f4a080e7          	jalr	-182(ra) # 80003028 <bread>
    800040e6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040e8:	40000613          	li	a2,1024
    800040ec:	05890593          	addi	a1,s2,88
    800040f0:	05850513          	addi	a0,a0,88
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	c78080e7          	jalr	-904(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    800040fc:	8526                	mv	a0,s1
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	01c080e7          	jalr	28(ra) # 8000311a <bwrite>
    bunpin(dbuf);
    80004106:	8526                	mv	a0,s1
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	12a080e7          	jalr	298(ra) # 80003232 <bunpin>
    brelse(lbuf);
    80004110:	854a                	mv	a0,s2
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	046080e7          	jalr	70(ra) # 80003158 <brelse>
    brelse(dbuf);
    8000411a:	8526                	mv	a0,s1
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	03c080e7          	jalr	60(ra) # 80003158 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004124:	2a05                	addiw	s4,s4,1
    80004126:	0a91                	addi	s5,s5,4
    80004128:	02c9a783          	lw	a5,44(s3)
    8000412c:	f8fa49e3          	blt	s4,a5,800040be <install_trans+0x30>
}
    80004130:	70e2                	ld	ra,56(sp)
    80004132:	7442                	ld	s0,48(sp)
    80004134:	74a2                	ld	s1,40(sp)
    80004136:	7902                	ld	s2,32(sp)
    80004138:	69e2                	ld	s3,24(sp)
    8000413a:	6a42                	ld	s4,16(sp)
    8000413c:	6aa2                	ld	s5,8(sp)
    8000413e:	6121                	addi	sp,sp,64
    80004140:	8082                	ret
    80004142:	8082                	ret

0000000080004144 <initlog>:
{
    80004144:	7179                	addi	sp,sp,-48
    80004146:	f406                	sd	ra,40(sp)
    80004148:	f022                	sd	s0,32(sp)
    8000414a:	ec26                	sd	s1,24(sp)
    8000414c:	e84a                	sd	s2,16(sp)
    8000414e:	e44e                	sd	s3,8(sp)
    80004150:	1800                	addi	s0,sp,48
    80004152:	892a                	mv	s2,a0
    80004154:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004156:	0001e497          	auipc	s1,0x1e
    8000415a:	9b248493          	addi	s1,s1,-1614 # 80021b08 <log>
    8000415e:	00004597          	auipc	a1,0x4
    80004162:	50a58593          	addi	a1,a1,1290 # 80008668 <syscalls+0x1d8>
    80004166:	8526                	mv	a0,s1
    80004168:	ffffd097          	auipc	ra,0xffffd
    8000416c:	a18080e7          	jalr	-1512(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004170:	0149a583          	lw	a1,20(s3)
    80004174:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004176:	0109a783          	lw	a5,16(s3)
    8000417a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000417c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004180:	854a                	mv	a0,s2
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	ea6080e7          	jalr	-346(ra) # 80003028 <bread>
  log.lh.n = lh->n;
    8000418a:	4d3c                	lw	a5,88(a0)
    8000418c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000418e:	02f05563          	blez	a5,800041b8 <initlog+0x74>
    80004192:	05c50713          	addi	a4,a0,92
    80004196:	0001e697          	auipc	a3,0x1e
    8000419a:	9a268693          	addi	a3,a3,-1630 # 80021b38 <log+0x30>
    8000419e:	37fd                	addiw	a5,a5,-1
    800041a0:	1782                	slli	a5,a5,0x20
    800041a2:	9381                	srli	a5,a5,0x20
    800041a4:	078a                	slli	a5,a5,0x2
    800041a6:	06050613          	addi	a2,a0,96
    800041aa:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041ac:	4310                	lw	a2,0(a4)
    800041ae:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041b0:	0711                	addi	a4,a4,4
    800041b2:	0691                	addi	a3,a3,4
    800041b4:	fef71ce3          	bne	a4,a5,800041ac <initlog+0x68>
  brelse(buf);
    800041b8:	fffff097          	auipc	ra,0xfffff
    800041bc:	fa0080e7          	jalr	-96(ra) # 80003158 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	ece080e7          	jalr	-306(ra) # 8000408e <install_trans>
  log.lh.n = 0;
    800041c8:	0001e797          	auipc	a5,0x1e
    800041cc:	9607a623          	sw	zero,-1684(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	e44080e7          	jalr	-444(ra) # 80004014 <write_head>
}
    800041d8:	70a2                	ld	ra,40(sp)
    800041da:	7402                	ld	s0,32(sp)
    800041dc:	64e2                	ld	s1,24(sp)
    800041de:	6942                	ld	s2,16(sp)
    800041e0:	69a2                	ld	s3,8(sp)
    800041e2:	6145                	addi	sp,sp,48
    800041e4:	8082                	ret

00000000800041e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041e6:	1101                	addi	sp,sp,-32
    800041e8:	ec06                	sd	ra,24(sp)
    800041ea:	e822                	sd	s0,16(sp)
    800041ec:	e426                	sd	s1,8(sp)
    800041ee:	e04a                	sd	s2,0(sp)
    800041f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041f2:	0001e517          	auipc	a0,0x1e
    800041f6:	91650513          	addi	a0,a0,-1770 # 80021b08 <log>
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	a16080e7          	jalr	-1514(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004202:	0001e497          	auipc	s1,0x1e
    80004206:	90648493          	addi	s1,s1,-1786 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000420a:	4979                	li	s2,30
    8000420c:	a039                	j	8000421a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000420e:	85a6                	mv	a1,s1
    80004210:	8526                	mv	a0,s1
    80004212:	ffffe097          	auipc	ra,0xffffe
    80004216:	1f8080e7          	jalr	504(ra) # 8000240a <sleep>
    if(log.committing){
    8000421a:	50dc                	lw	a5,36(s1)
    8000421c:	fbed                	bnez	a5,8000420e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000421e:	509c                	lw	a5,32(s1)
    80004220:	0017871b          	addiw	a4,a5,1
    80004224:	0007069b          	sext.w	a3,a4
    80004228:	0027179b          	slliw	a5,a4,0x2
    8000422c:	9fb9                	addw	a5,a5,a4
    8000422e:	0017979b          	slliw	a5,a5,0x1
    80004232:	54d8                	lw	a4,44(s1)
    80004234:	9fb9                	addw	a5,a5,a4
    80004236:	00f95963          	bge	s2,a5,80004248 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000423a:	85a6                	mv	a1,s1
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffe097          	auipc	ra,0xffffe
    80004242:	1cc080e7          	jalr	460(ra) # 8000240a <sleep>
    80004246:	bfd1                	j	8000421a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004248:	0001e517          	auipc	a0,0x1e
    8000424c:	8c050513          	addi	a0,a0,-1856 # 80021b08 <log>
    80004250:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	a72080e7          	jalr	-1422(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000425a:	60e2                	ld	ra,24(sp)
    8000425c:	6442                	ld	s0,16(sp)
    8000425e:	64a2                	ld	s1,8(sp)
    80004260:	6902                	ld	s2,0(sp)
    80004262:	6105                	addi	sp,sp,32
    80004264:	8082                	ret

0000000080004266 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004266:	7139                	addi	sp,sp,-64
    80004268:	fc06                	sd	ra,56(sp)
    8000426a:	f822                	sd	s0,48(sp)
    8000426c:	f426                	sd	s1,40(sp)
    8000426e:	f04a                	sd	s2,32(sp)
    80004270:	ec4e                	sd	s3,24(sp)
    80004272:	e852                	sd	s4,16(sp)
    80004274:	e456                	sd	s5,8(sp)
    80004276:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004278:	0001e497          	auipc	s1,0x1e
    8000427c:	89048493          	addi	s1,s1,-1904 # 80021b08 <log>
    80004280:	8526                	mv	a0,s1
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	98e080e7          	jalr	-1650(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    8000428a:	509c                	lw	a5,32(s1)
    8000428c:	37fd                	addiw	a5,a5,-1
    8000428e:	0007891b          	sext.w	s2,a5
    80004292:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004294:	50dc                	lw	a5,36(s1)
    80004296:	efb9                	bnez	a5,800042f4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004298:	06091663          	bnez	s2,80004304 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000429c:	0001e497          	auipc	s1,0x1e
    800042a0:	86c48493          	addi	s1,s1,-1940 # 80021b08 <log>
    800042a4:	4785                	li	a5,1
    800042a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a8:	8526                	mv	a0,s1
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	a1a080e7          	jalr	-1510(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042b2:	54dc                	lw	a5,44(s1)
    800042b4:	06f04763          	bgtz	a5,80004322 <end_op+0xbc>
    acquire(&log.lock);
    800042b8:	0001e497          	auipc	s1,0x1e
    800042bc:	85048493          	addi	s1,s1,-1968 # 80021b08 <log>
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	94e080e7          	jalr	-1714(ra) # 80000c10 <acquire>
    log.committing = 0;
    800042ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	2c0080e7          	jalr	704(ra) # 80002590 <wakeup>
    release(&log.lock);
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	9ea080e7          	jalr	-1558(ra) # 80000cc4 <release>
}
    800042e2:	70e2                	ld	ra,56(sp)
    800042e4:	7442                	ld	s0,48(sp)
    800042e6:	74a2                	ld	s1,40(sp)
    800042e8:	7902                	ld	s2,32(sp)
    800042ea:	69e2                	ld	s3,24(sp)
    800042ec:	6a42                	ld	s4,16(sp)
    800042ee:	6aa2                	ld	s5,8(sp)
    800042f0:	6121                	addi	sp,sp,64
    800042f2:	8082                	ret
    panic("log.committing");
    800042f4:	00004517          	auipc	a0,0x4
    800042f8:	37c50513          	addi	a0,a0,892 # 80008670 <syscalls+0x1e0>
    800042fc:	ffffc097          	auipc	ra,0xffffc
    80004300:	24c080e7          	jalr	588(ra) # 80000548 <panic>
    wakeup(&log);
    80004304:	0001e497          	auipc	s1,0x1e
    80004308:	80448493          	addi	s1,s1,-2044 # 80021b08 <log>
    8000430c:	8526                	mv	a0,s1
    8000430e:	ffffe097          	auipc	ra,0xffffe
    80004312:	282080e7          	jalr	642(ra) # 80002590 <wakeup>
  release(&log.lock);
    80004316:	8526                	mv	a0,s1
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	9ac080e7          	jalr	-1620(ra) # 80000cc4 <release>
  if(do_commit){
    80004320:	b7c9                	j	800042e2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004322:	0001ea97          	auipc	s5,0x1e
    80004326:	816a8a93          	addi	s5,s5,-2026 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000432a:	0001da17          	auipc	s4,0x1d
    8000432e:	7dea0a13          	addi	s4,s4,2014 # 80021b08 <log>
    80004332:	018a2583          	lw	a1,24(s4)
    80004336:	012585bb          	addw	a1,a1,s2
    8000433a:	2585                	addiw	a1,a1,1
    8000433c:	028a2503          	lw	a0,40(s4)
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	ce8080e7          	jalr	-792(ra) # 80003028 <bread>
    80004348:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000434a:	000aa583          	lw	a1,0(s5)
    8000434e:	028a2503          	lw	a0,40(s4)
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	cd6080e7          	jalr	-810(ra) # 80003028 <bread>
    8000435a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000435c:	40000613          	li	a2,1024
    80004360:	05850593          	addi	a1,a0,88
    80004364:	05848513          	addi	a0,s1,88
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	a04080e7          	jalr	-1532(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004370:	8526                	mv	a0,s1
    80004372:	fffff097          	auipc	ra,0xfffff
    80004376:	da8080e7          	jalr	-600(ra) # 8000311a <bwrite>
    brelse(from);
    8000437a:	854e                	mv	a0,s3
    8000437c:	fffff097          	auipc	ra,0xfffff
    80004380:	ddc080e7          	jalr	-548(ra) # 80003158 <brelse>
    brelse(to);
    80004384:	8526                	mv	a0,s1
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	dd2080e7          	jalr	-558(ra) # 80003158 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438e:	2905                	addiw	s2,s2,1
    80004390:	0a91                	addi	s5,s5,4
    80004392:	02ca2783          	lw	a5,44(s4)
    80004396:	f8f94ee3          	blt	s2,a5,80004332 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	c7a080e7          	jalr	-902(ra) # 80004014 <write_head>
    install_trans(); // Now install writes to home locations
    800043a2:	00000097          	auipc	ra,0x0
    800043a6:	cec080e7          	jalr	-788(ra) # 8000408e <install_trans>
    log.lh.n = 0;
    800043aa:	0001d797          	auipc	a5,0x1d
    800043ae:	7807a523          	sw	zero,1930(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	c62080e7          	jalr	-926(ra) # 80004014 <write_head>
    800043ba:	bdfd                	j	800042b8 <end_op+0x52>

00000000800043bc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043bc:	1101                	addi	sp,sp,-32
    800043be:	ec06                	sd	ra,24(sp)
    800043c0:	e822                	sd	s0,16(sp)
    800043c2:	e426                	sd	s1,8(sp)
    800043c4:	e04a                	sd	s2,0(sp)
    800043c6:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043c8:	0001d717          	auipc	a4,0x1d
    800043cc:	76c72703          	lw	a4,1900(a4) # 80021b34 <log+0x2c>
    800043d0:	47f5                	li	a5,29
    800043d2:	08e7c063          	blt	a5,a4,80004452 <log_write+0x96>
    800043d6:	84aa                	mv	s1,a0
    800043d8:	0001d797          	auipc	a5,0x1d
    800043dc:	74c7a783          	lw	a5,1868(a5) # 80021b24 <log+0x1c>
    800043e0:	37fd                	addiw	a5,a5,-1
    800043e2:	06f75863          	bge	a4,a5,80004452 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043e6:	0001d797          	auipc	a5,0x1d
    800043ea:	7427a783          	lw	a5,1858(a5) # 80021b28 <log+0x20>
    800043ee:	06f05a63          	blez	a5,80004462 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043f2:	0001d917          	auipc	s2,0x1d
    800043f6:	71690913          	addi	s2,s2,1814 # 80021b08 <log>
    800043fa:	854a                	mv	a0,s2
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	814080e7          	jalr	-2028(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004404:	02c92603          	lw	a2,44(s2)
    80004408:	06c05563          	blez	a2,80004472 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000440c:	44cc                	lw	a1,12(s1)
    8000440e:	0001d717          	auipc	a4,0x1d
    80004412:	72a70713          	addi	a4,a4,1834 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004416:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004418:	4314                	lw	a3,0(a4)
    8000441a:	04b68d63          	beq	a3,a1,80004474 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000441e:	2785                	addiw	a5,a5,1
    80004420:	0711                	addi	a4,a4,4
    80004422:	fec79be3          	bne	a5,a2,80004418 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004426:	0621                	addi	a2,a2,8
    80004428:	060a                	slli	a2,a2,0x2
    8000442a:	0001d797          	auipc	a5,0x1d
    8000442e:	6de78793          	addi	a5,a5,1758 # 80021b08 <log>
    80004432:	963e                	add	a2,a2,a5
    80004434:	44dc                	lw	a5,12(s1)
    80004436:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004438:	8526                	mv	a0,s1
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	dbc080e7          	jalr	-580(ra) # 800031f6 <bpin>
    log.lh.n++;
    80004442:	0001d717          	auipc	a4,0x1d
    80004446:	6c670713          	addi	a4,a4,1734 # 80021b08 <log>
    8000444a:	575c                	lw	a5,44(a4)
    8000444c:	2785                	addiw	a5,a5,1
    8000444e:	d75c                	sw	a5,44(a4)
    80004450:	a83d                	j	8000448e <log_write+0xd2>
    panic("too big a transaction");
    80004452:	00004517          	auipc	a0,0x4
    80004456:	22e50513          	addi	a0,a0,558 # 80008680 <syscalls+0x1f0>
    8000445a:	ffffc097          	auipc	ra,0xffffc
    8000445e:	0ee080e7          	jalr	238(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004462:	00004517          	auipc	a0,0x4
    80004466:	23650513          	addi	a0,a0,566 # 80008698 <syscalls+0x208>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	0de080e7          	jalr	222(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004472:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004474:	00878713          	addi	a4,a5,8
    80004478:	00271693          	slli	a3,a4,0x2
    8000447c:	0001d717          	auipc	a4,0x1d
    80004480:	68c70713          	addi	a4,a4,1676 # 80021b08 <log>
    80004484:	9736                	add	a4,a4,a3
    80004486:	44d4                	lw	a3,12(s1)
    80004488:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000448a:	faf607e3          	beq	a2,a5,80004438 <log_write+0x7c>
  }
  release(&log.lock);
    8000448e:	0001d517          	auipc	a0,0x1d
    80004492:	67a50513          	addi	a0,a0,1658 # 80021b08 <log>
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	82e080e7          	jalr	-2002(ra) # 80000cc4 <release>
}
    8000449e:	60e2                	ld	ra,24(sp)
    800044a0:	6442                	ld	s0,16(sp)
    800044a2:	64a2                	ld	s1,8(sp)
    800044a4:	6902                	ld	s2,0(sp)
    800044a6:	6105                	addi	sp,sp,32
    800044a8:	8082                	ret

00000000800044aa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044aa:	1101                	addi	sp,sp,-32
    800044ac:	ec06                	sd	ra,24(sp)
    800044ae:	e822                	sd	s0,16(sp)
    800044b0:	e426                	sd	s1,8(sp)
    800044b2:	e04a                	sd	s2,0(sp)
    800044b4:	1000                	addi	s0,sp,32
    800044b6:	84aa                	mv	s1,a0
    800044b8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044ba:	00004597          	auipc	a1,0x4
    800044be:	1fe58593          	addi	a1,a1,510 # 800086b8 <syscalls+0x228>
    800044c2:	0521                	addi	a0,a0,8
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	6bc080e7          	jalr	1724(ra) # 80000b80 <initlock>
  lk->name = name;
    800044cc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d4:	0204a423          	sw	zero,40(s1)
}
    800044d8:	60e2                	ld	ra,24(sp)
    800044da:	6442                	ld	s0,16(sp)
    800044dc:	64a2                	ld	s1,8(sp)
    800044de:	6902                	ld	s2,0(sp)
    800044e0:	6105                	addi	sp,sp,32
    800044e2:	8082                	ret

00000000800044e4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044e4:	1101                	addi	sp,sp,-32
    800044e6:	ec06                	sd	ra,24(sp)
    800044e8:	e822                	sd	s0,16(sp)
    800044ea:	e426                	sd	s1,8(sp)
    800044ec:	e04a                	sd	s2,0(sp)
    800044ee:	1000                	addi	s0,sp,32
    800044f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044f2:	00850913          	addi	s2,a0,8
    800044f6:	854a                	mv	a0,s2
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	718080e7          	jalr	1816(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004500:	409c                	lw	a5,0(s1)
    80004502:	cb89                	beqz	a5,80004514 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004504:	85ca                	mv	a1,s2
    80004506:	8526                	mv	a0,s1
    80004508:	ffffe097          	auipc	ra,0xffffe
    8000450c:	f02080e7          	jalr	-254(ra) # 8000240a <sleep>
  while (lk->locked) {
    80004510:	409c                	lw	a5,0(s1)
    80004512:	fbed                	bnez	a5,80004504 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004514:	4785                	li	a5,1
    80004516:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	5ca080e7          	jalr	1482(ra) # 80001ae2 <myproc>
    80004520:	5d1c                	lw	a5,56(a0)
    80004522:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004524:	854a                	mv	a0,s2
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	79e080e7          	jalr	1950(ra) # 80000cc4 <release>
}
    8000452e:	60e2                	ld	ra,24(sp)
    80004530:	6442                	ld	s0,16(sp)
    80004532:	64a2                	ld	s1,8(sp)
    80004534:	6902                	ld	s2,0(sp)
    80004536:	6105                	addi	sp,sp,32
    80004538:	8082                	ret

000000008000453a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000453a:	1101                	addi	sp,sp,-32
    8000453c:	ec06                	sd	ra,24(sp)
    8000453e:	e822                	sd	s0,16(sp)
    80004540:	e426                	sd	s1,8(sp)
    80004542:	e04a                	sd	s2,0(sp)
    80004544:	1000                	addi	s0,sp,32
    80004546:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004548:	00850913          	addi	s2,a0,8
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	6c2080e7          	jalr	1730(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004556:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000455a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000455e:	8526                	mv	a0,s1
    80004560:	ffffe097          	auipc	ra,0xffffe
    80004564:	030080e7          	jalr	48(ra) # 80002590 <wakeup>
  release(&lk->lk);
    80004568:	854a                	mv	a0,s2
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	75a080e7          	jalr	1882(ra) # 80000cc4 <release>
}
    80004572:	60e2                	ld	ra,24(sp)
    80004574:	6442                	ld	s0,16(sp)
    80004576:	64a2                	ld	s1,8(sp)
    80004578:	6902                	ld	s2,0(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret

000000008000457e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000457e:	7179                	addi	sp,sp,-48
    80004580:	f406                	sd	ra,40(sp)
    80004582:	f022                	sd	s0,32(sp)
    80004584:	ec26                	sd	s1,24(sp)
    80004586:	e84a                	sd	s2,16(sp)
    80004588:	e44e                	sd	s3,8(sp)
    8000458a:	1800                	addi	s0,sp,48
    8000458c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000458e:	00850913          	addi	s2,a0,8
    80004592:	854a                	mv	a0,s2
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	67c080e7          	jalr	1660(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000459c:	409c                	lw	a5,0(s1)
    8000459e:	ef99                	bnez	a5,800045bc <holdingsleep+0x3e>
    800045a0:	4481                	li	s1,0
  release(&lk->lk);
    800045a2:	854a                	mv	a0,s2
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	720080e7          	jalr	1824(ra) # 80000cc4 <release>
  return r;
}
    800045ac:	8526                	mv	a0,s1
    800045ae:	70a2                	ld	ra,40(sp)
    800045b0:	7402                	ld	s0,32(sp)
    800045b2:	64e2                	ld	s1,24(sp)
    800045b4:	6942                	ld	s2,16(sp)
    800045b6:	69a2                	ld	s3,8(sp)
    800045b8:	6145                	addi	sp,sp,48
    800045ba:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045bc:	0284a983          	lw	s3,40(s1)
    800045c0:	ffffd097          	auipc	ra,0xffffd
    800045c4:	522080e7          	jalr	1314(ra) # 80001ae2 <myproc>
    800045c8:	5d04                	lw	s1,56(a0)
    800045ca:	413484b3          	sub	s1,s1,s3
    800045ce:	0014b493          	seqz	s1,s1
    800045d2:	bfc1                	j	800045a2 <holdingsleep+0x24>

00000000800045d4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045d4:	1141                	addi	sp,sp,-16
    800045d6:	e406                	sd	ra,8(sp)
    800045d8:	e022                	sd	s0,0(sp)
    800045da:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045dc:	00004597          	auipc	a1,0x4
    800045e0:	0ec58593          	addi	a1,a1,236 # 800086c8 <syscalls+0x238>
    800045e4:	0001d517          	auipc	a0,0x1d
    800045e8:	66c50513          	addi	a0,a0,1644 # 80021c50 <ftable>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	594080e7          	jalr	1428(ra) # 80000b80 <initlock>
}
    800045f4:	60a2                	ld	ra,8(sp)
    800045f6:	6402                	ld	s0,0(sp)
    800045f8:	0141                	addi	sp,sp,16
    800045fa:	8082                	ret

00000000800045fc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045fc:	1101                	addi	sp,sp,-32
    800045fe:	ec06                	sd	ra,24(sp)
    80004600:	e822                	sd	s0,16(sp)
    80004602:	e426                	sd	s1,8(sp)
    80004604:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004606:	0001d517          	auipc	a0,0x1d
    8000460a:	64a50513          	addi	a0,a0,1610 # 80021c50 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	602080e7          	jalr	1538(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004616:	0001d497          	auipc	s1,0x1d
    8000461a:	65248493          	addi	s1,s1,1618 # 80021c68 <ftable+0x18>
    8000461e:	0001e717          	auipc	a4,0x1e
    80004622:	5ea70713          	addi	a4,a4,1514 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    80004626:	40dc                	lw	a5,4(s1)
    80004628:	cf99                	beqz	a5,80004646 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000462a:	02848493          	addi	s1,s1,40
    8000462e:	fee49ce3          	bne	s1,a4,80004626 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004632:	0001d517          	auipc	a0,0x1d
    80004636:	61e50513          	addi	a0,a0,1566 # 80021c50 <ftable>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	68a080e7          	jalr	1674(ra) # 80000cc4 <release>
  return 0;
    80004642:	4481                	li	s1,0
    80004644:	a819                	j	8000465a <filealloc+0x5e>
      f->ref = 1;
    80004646:	4785                	li	a5,1
    80004648:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000464a:	0001d517          	auipc	a0,0x1d
    8000464e:	60650513          	addi	a0,a0,1542 # 80021c50 <ftable>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	672080e7          	jalr	1650(ra) # 80000cc4 <release>
}
    8000465a:	8526                	mv	a0,s1
    8000465c:	60e2                	ld	ra,24(sp)
    8000465e:	6442                	ld	s0,16(sp)
    80004660:	64a2                	ld	s1,8(sp)
    80004662:	6105                	addi	sp,sp,32
    80004664:	8082                	ret

0000000080004666 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004666:	1101                	addi	sp,sp,-32
    80004668:	ec06                	sd	ra,24(sp)
    8000466a:	e822                	sd	s0,16(sp)
    8000466c:	e426                	sd	s1,8(sp)
    8000466e:	1000                	addi	s0,sp,32
    80004670:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	5de50513          	addi	a0,a0,1502 # 80021c50 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	596080e7          	jalr	1430(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004682:	40dc                	lw	a5,4(s1)
    80004684:	02f05263          	blez	a5,800046a8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004688:	2785                	addiw	a5,a5,1
    8000468a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000468c:	0001d517          	auipc	a0,0x1d
    80004690:	5c450513          	addi	a0,a0,1476 # 80021c50 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	630080e7          	jalr	1584(ra) # 80000cc4 <release>
  return f;
}
    8000469c:	8526                	mv	a0,s1
    8000469e:	60e2                	ld	ra,24(sp)
    800046a0:	6442                	ld	s0,16(sp)
    800046a2:	64a2                	ld	s1,8(sp)
    800046a4:	6105                	addi	sp,sp,32
    800046a6:	8082                	ret
    panic("filedup");
    800046a8:	00004517          	auipc	a0,0x4
    800046ac:	02850513          	addi	a0,a0,40 # 800086d0 <syscalls+0x240>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	e98080e7          	jalr	-360(ra) # 80000548 <panic>

00000000800046b8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046b8:	7139                	addi	sp,sp,-64
    800046ba:	fc06                	sd	ra,56(sp)
    800046bc:	f822                	sd	s0,48(sp)
    800046be:	f426                	sd	s1,40(sp)
    800046c0:	f04a                	sd	s2,32(sp)
    800046c2:	ec4e                	sd	s3,24(sp)
    800046c4:	e852                	sd	s4,16(sp)
    800046c6:	e456                	sd	s5,8(sp)
    800046c8:	0080                	addi	s0,sp,64
    800046ca:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046cc:	0001d517          	auipc	a0,0x1d
    800046d0:	58450513          	addi	a0,a0,1412 # 80021c50 <ftable>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	53c080e7          	jalr	1340(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800046dc:	40dc                	lw	a5,4(s1)
    800046de:	06f05163          	blez	a5,80004740 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046e2:	37fd                	addiw	a5,a5,-1
    800046e4:	0007871b          	sext.w	a4,a5
    800046e8:	c0dc                	sw	a5,4(s1)
    800046ea:	06e04363          	bgtz	a4,80004750 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046ee:	0004a903          	lw	s2,0(s1)
    800046f2:	0094ca83          	lbu	s5,9(s1)
    800046f6:	0104ba03          	ld	s4,16(s1)
    800046fa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046fe:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004702:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004706:	0001d517          	auipc	a0,0x1d
    8000470a:	54a50513          	addi	a0,a0,1354 # 80021c50 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	5b6080e7          	jalr	1462(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    80004716:	4785                	li	a5,1
    80004718:	04f90d63          	beq	s2,a5,80004772 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000471c:	3979                	addiw	s2,s2,-2
    8000471e:	4785                	li	a5,1
    80004720:	0527e063          	bltu	a5,s2,80004760 <fileclose+0xa8>
    begin_op();
    80004724:	00000097          	auipc	ra,0x0
    80004728:	ac2080e7          	jalr	-1342(ra) # 800041e6 <begin_op>
    iput(ff.ip);
    8000472c:	854e                	mv	a0,s3
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	2b6080e7          	jalr	694(ra) # 800039e4 <iput>
    end_op();
    80004736:	00000097          	auipc	ra,0x0
    8000473a:	b30080e7          	jalr	-1232(ra) # 80004266 <end_op>
    8000473e:	a00d                	j	80004760 <fileclose+0xa8>
    panic("fileclose");
    80004740:	00004517          	auipc	a0,0x4
    80004744:	f9850513          	addi	a0,a0,-104 # 800086d8 <syscalls+0x248>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	e00080e7          	jalr	-512(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004750:	0001d517          	auipc	a0,0x1d
    80004754:	50050513          	addi	a0,a0,1280 # 80021c50 <ftable>
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	56c080e7          	jalr	1388(ra) # 80000cc4 <release>
  }
}
    80004760:	70e2                	ld	ra,56(sp)
    80004762:	7442                	ld	s0,48(sp)
    80004764:	74a2                	ld	s1,40(sp)
    80004766:	7902                	ld	s2,32(sp)
    80004768:	69e2                	ld	s3,24(sp)
    8000476a:	6a42                	ld	s4,16(sp)
    8000476c:	6aa2                	ld	s5,8(sp)
    8000476e:	6121                	addi	sp,sp,64
    80004770:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004772:	85d6                	mv	a1,s5
    80004774:	8552                	mv	a0,s4
    80004776:	00000097          	auipc	ra,0x0
    8000477a:	372080e7          	jalr	882(ra) # 80004ae8 <pipeclose>
    8000477e:	b7cd                	j	80004760 <fileclose+0xa8>

0000000080004780 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004780:	715d                	addi	sp,sp,-80
    80004782:	e486                	sd	ra,72(sp)
    80004784:	e0a2                	sd	s0,64(sp)
    80004786:	fc26                	sd	s1,56(sp)
    80004788:	f84a                	sd	s2,48(sp)
    8000478a:	f44e                	sd	s3,40(sp)
    8000478c:	0880                	addi	s0,sp,80
    8000478e:	84aa                	mv	s1,a0
    80004790:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004792:	ffffd097          	auipc	ra,0xffffd
    80004796:	350080e7          	jalr	848(ra) # 80001ae2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000479a:	409c                	lw	a5,0(s1)
    8000479c:	37f9                	addiw	a5,a5,-2
    8000479e:	4705                	li	a4,1
    800047a0:	04f76763          	bltu	a4,a5,800047ee <filestat+0x6e>
    800047a4:	892a                	mv	s2,a0
    ilock(f->ip);
    800047a6:	6c88                	ld	a0,24(s1)
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	082080e7          	jalr	130(ra) # 8000382a <ilock>
    stati(f->ip, &st);
    800047b0:	fb840593          	addi	a1,s0,-72
    800047b4:	6c88                	ld	a0,24(s1)
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	2fe080e7          	jalr	766(ra) # 80003ab4 <stati>
    iunlock(f->ip);
    800047be:	6c88                	ld	a0,24(s1)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	12c080e7          	jalr	300(ra) # 800038ec <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047c8:	46e1                	li	a3,24
    800047ca:	fb840613          	addi	a2,s0,-72
    800047ce:	85ce                	mv	a1,s3
    800047d0:	05093503          	ld	a0,80(s2)
    800047d4:	ffffd097          	auipc	ra,0xffffd
    800047d8:	17a080e7          	jalr	378(ra) # 8000194e <copyout>
    800047dc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047e0:	60a6                	ld	ra,72(sp)
    800047e2:	6406                	ld	s0,64(sp)
    800047e4:	74e2                	ld	s1,56(sp)
    800047e6:	7942                	ld	s2,48(sp)
    800047e8:	79a2                	ld	s3,40(sp)
    800047ea:	6161                	addi	sp,sp,80
    800047ec:	8082                	ret
  return -1;
    800047ee:	557d                	li	a0,-1
    800047f0:	bfc5                	j	800047e0 <filestat+0x60>

00000000800047f2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047f2:	7179                	addi	sp,sp,-48
    800047f4:	f406                	sd	ra,40(sp)
    800047f6:	f022                	sd	s0,32(sp)
    800047f8:	ec26                	sd	s1,24(sp)
    800047fa:	e84a                	sd	s2,16(sp)
    800047fc:	e44e                	sd	s3,8(sp)
    800047fe:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004800:	00854783          	lbu	a5,8(a0)
    80004804:	c3d5                	beqz	a5,800048a8 <fileread+0xb6>
    80004806:	84aa                	mv	s1,a0
    80004808:	89ae                	mv	s3,a1
    8000480a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000480c:	411c                	lw	a5,0(a0)
    8000480e:	4705                	li	a4,1
    80004810:	04e78963          	beq	a5,a4,80004862 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004814:	470d                	li	a4,3
    80004816:	04e78d63          	beq	a5,a4,80004870 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000481a:	4709                	li	a4,2
    8000481c:	06e79e63          	bne	a5,a4,80004898 <fileread+0xa6>
    ilock(f->ip);
    80004820:	6d08                	ld	a0,24(a0)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	008080e7          	jalr	8(ra) # 8000382a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000482a:	874a                	mv	a4,s2
    8000482c:	5094                	lw	a3,32(s1)
    8000482e:	864e                	mv	a2,s3
    80004830:	4585                	li	a1,1
    80004832:	6c88                	ld	a0,24(s1)
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	2aa080e7          	jalr	682(ra) # 80003ade <readi>
    8000483c:	892a                	mv	s2,a0
    8000483e:	00a05563          	blez	a0,80004848 <fileread+0x56>
      f->off += r;
    80004842:	509c                	lw	a5,32(s1)
    80004844:	9fa9                	addw	a5,a5,a0
    80004846:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004848:	6c88                	ld	a0,24(s1)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	0a2080e7          	jalr	162(ra) # 800038ec <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004852:	854a                	mv	a0,s2
    80004854:	70a2                	ld	ra,40(sp)
    80004856:	7402                	ld	s0,32(sp)
    80004858:	64e2                	ld	s1,24(sp)
    8000485a:	6942                	ld	s2,16(sp)
    8000485c:	69a2                	ld	s3,8(sp)
    8000485e:	6145                	addi	sp,sp,48
    80004860:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004862:	6908                	ld	a0,16(a0)
    80004864:	00000097          	auipc	ra,0x0
    80004868:	418080e7          	jalr	1048(ra) # 80004c7c <piperead>
    8000486c:	892a                	mv	s2,a0
    8000486e:	b7d5                	j	80004852 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004870:	02451783          	lh	a5,36(a0)
    80004874:	03079693          	slli	a3,a5,0x30
    80004878:	92c1                	srli	a3,a3,0x30
    8000487a:	4725                	li	a4,9
    8000487c:	02d76863          	bltu	a4,a3,800048ac <fileread+0xba>
    80004880:	0792                	slli	a5,a5,0x4
    80004882:	0001d717          	auipc	a4,0x1d
    80004886:	32e70713          	addi	a4,a4,814 # 80021bb0 <devsw>
    8000488a:	97ba                	add	a5,a5,a4
    8000488c:	639c                	ld	a5,0(a5)
    8000488e:	c38d                	beqz	a5,800048b0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004890:	4505                	li	a0,1
    80004892:	9782                	jalr	a5
    80004894:	892a                	mv	s2,a0
    80004896:	bf75                	j	80004852 <fileread+0x60>
    panic("fileread");
    80004898:	00004517          	auipc	a0,0x4
    8000489c:	e5050513          	addi	a0,a0,-432 # 800086e8 <syscalls+0x258>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	ca8080e7          	jalr	-856(ra) # 80000548 <panic>
    return -1;
    800048a8:	597d                	li	s2,-1
    800048aa:	b765                	j	80004852 <fileread+0x60>
      return -1;
    800048ac:	597d                	li	s2,-1
    800048ae:	b755                	j	80004852 <fileread+0x60>
    800048b0:	597d                	li	s2,-1
    800048b2:	b745                	j	80004852 <fileread+0x60>

00000000800048b4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048b4:	00954783          	lbu	a5,9(a0)
    800048b8:	14078563          	beqz	a5,80004a02 <filewrite+0x14e>
{
    800048bc:	715d                	addi	sp,sp,-80
    800048be:	e486                	sd	ra,72(sp)
    800048c0:	e0a2                	sd	s0,64(sp)
    800048c2:	fc26                	sd	s1,56(sp)
    800048c4:	f84a                	sd	s2,48(sp)
    800048c6:	f44e                	sd	s3,40(sp)
    800048c8:	f052                	sd	s4,32(sp)
    800048ca:	ec56                	sd	s5,24(sp)
    800048cc:	e85a                	sd	s6,16(sp)
    800048ce:	e45e                	sd	s7,8(sp)
    800048d0:	e062                	sd	s8,0(sp)
    800048d2:	0880                	addi	s0,sp,80
    800048d4:	892a                	mv	s2,a0
    800048d6:	8aae                	mv	s5,a1
    800048d8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048da:	411c                	lw	a5,0(a0)
    800048dc:	4705                	li	a4,1
    800048de:	02e78263          	beq	a5,a4,80004902 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048e2:	470d                	li	a4,3
    800048e4:	02e78563          	beq	a5,a4,8000490e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048e8:	4709                	li	a4,2
    800048ea:	10e79463          	bne	a5,a4,800049f2 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048ee:	0ec05e63          	blez	a2,800049ea <filewrite+0x136>
    int i = 0;
    800048f2:	4981                	li	s3,0
    800048f4:	6b05                	lui	s6,0x1
    800048f6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048fa:	6b85                	lui	s7,0x1
    800048fc:	c00b8b9b          	addiw	s7,s7,-1024
    80004900:	a851                	j	80004994 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004902:	6908                	ld	a0,16(a0)
    80004904:	00000097          	auipc	ra,0x0
    80004908:	254080e7          	jalr	596(ra) # 80004b58 <pipewrite>
    8000490c:	a85d                	j	800049c2 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000490e:	02451783          	lh	a5,36(a0)
    80004912:	03079693          	slli	a3,a5,0x30
    80004916:	92c1                	srli	a3,a3,0x30
    80004918:	4725                	li	a4,9
    8000491a:	0ed76663          	bltu	a4,a3,80004a06 <filewrite+0x152>
    8000491e:	0792                	slli	a5,a5,0x4
    80004920:	0001d717          	auipc	a4,0x1d
    80004924:	29070713          	addi	a4,a4,656 # 80021bb0 <devsw>
    80004928:	97ba                	add	a5,a5,a4
    8000492a:	679c                	ld	a5,8(a5)
    8000492c:	cff9                	beqz	a5,80004a0a <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000492e:	4505                	li	a0,1
    80004930:	9782                	jalr	a5
    80004932:	a841                	j	800049c2 <filewrite+0x10e>
    80004934:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004938:	00000097          	auipc	ra,0x0
    8000493c:	8ae080e7          	jalr	-1874(ra) # 800041e6 <begin_op>
      ilock(f->ip);
    80004940:	01893503          	ld	a0,24(s2)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	ee6080e7          	jalr	-282(ra) # 8000382a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000494c:	8762                	mv	a4,s8
    8000494e:	02092683          	lw	a3,32(s2)
    80004952:	01598633          	add	a2,s3,s5
    80004956:	4585                	li	a1,1
    80004958:	01893503          	ld	a0,24(s2)
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	278080e7          	jalr	632(ra) # 80003bd4 <writei>
    80004964:	84aa                	mv	s1,a0
    80004966:	02a05f63          	blez	a0,800049a4 <filewrite+0xf0>
        f->off += r;
    8000496a:	02092783          	lw	a5,32(s2)
    8000496e:	9fa9                	addw	a5,a5,a0
    80004970:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004974:	01893503          	ld	a0,24(s2)
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	f74080e7          	jalr	-140(ra) # 800038ec <iunlock>
      end_op();
    80004980:	00000097          	auipc	ra,0x0
    80004984:	8e6080e7          	jalr	-1818(ra) # 80004266 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004988:	049c1963          	bne	s8,s1,800049da <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000498c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004990:	0349d663          	bge	s3,s4,800049bc <filewrite+0x108>
      int n1 = n - i;
    80004994:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004998:	84be                	mv	s1,a5
    8000499a:	2781                	sext.w	a5,a5
    8000499c:	f8fb5ce3          	bge	s6,a5,80004934 <filewrite+0x80>
    800049a0:	84de                	mv	s1,s7
    800049a2:	bf49                	j	80004934 <filewrite+0x80>
      iunlock(f->ip);
    800049a4:	01893503          	ld	a0,24(s2)
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	f44080e7          	jalr	-188(ra) # 800038ec <iunlock>
      end_op();
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	8b6080e7          	jalr	-1866(ra) # 80004266 <end_op>
      if(r < 0)
    800049b8:	fc04d8e3          	bgez	s1,80004988 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049bc:	8552                	mv	a0,s4
    800049be:	033a1863          	bne	s4,s3,800049ee <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049c2:	60a6                	ld	ra,72(sp)
    800049c4:	6406                	ld	s0,64(sp)
    800049c6:	74e2                	ld	s1,56(sp)
    800049c8:	7942                	ld	s2,48(sp)
    800049ca:	79a2                	ld	s3,40(sp)
    800049cc:	7a02                	ld	s4,32(sp)
    800049ce:	6ae2                	ld	s5,24(sp)
    800049d0:	6b42                	ld	s6,16(sp)
    800049d2:	6ba2                	ld	s7,8(sp)
    800049d4:	6c02                	ld	s8,0(sp)
    800049d6:	6161                	addi	sp,sp,80
    800049d8:	8082                	ret
        panic("short filewrite");
    800049da:	00004517          	auipc	a0,0x4
    800049de:	d1e50513          	addi	a0,a0,-738 # 800086f8 <syscalls+0x268>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	b66080e7          	jalr	-1178(ra) # 80000548 <panic>
    int i = 0;
    800049ea:	4981                	li	s3,0
    800049ec:	bfc1                	j	800049bc <filewrite+0x108>
    ret = (i == n ? n : -1);
    800049ee:	557d                	li	a0,-1
    800049f0:	bfc9                	j	800049c2 <filewrite+0x10e>
    panic("filewrite");
    800049f2:	00004517          	auipc	a0,0x4
    800049f6:	d1650513          	addi	a0,a0,-746 # 80008708 <syscalls+0x278>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b4e080e7          	jalr	-1202(ra) # 80000548 <panic>
    return -1;
    80004a02:	557d                	li	a0,-1
}
    80004a04:	8082                	ret
      return -1;
    80004a06:	557d                	li	a0,-1
    80004a08:	bf6d                	j	800049c2 <filewrite+0x10e>
    80004a0a:	557d                	li	a0,-1
    80004a0c:	bf5d                	j	800049c2 <filewrite+0x10e>

0000000080004a0e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a0e:	7179                	addi	sp,sp,-48
    80004a10:	f406                	sd	ra,40(sp)
    80004a12:	f022                	sd	s0,32(sp)
    80004a14:	ec26                	sd	s1,24(sp)
    80004a16:	e84a                	sd	s2,16(sp)
    80004a18:	e44e                	sd	s3,8(sp)
    80004a1a:	e052                	sd	s4,0(sp)
    80004a1c:	1800                	addi	s0,sp,48
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a22:	0005b023          	sd	zero,0(a1)
    80004a26:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	bd2080e7          	jalr	-1070(ra) # 800045fc <filealloc>
    80004a32:	e088                	sd	a0,0(s1)
    80004a34:	c551                	beqz	a0,80004ac0 <pipealloc+0xb2>
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	bc6080e7          	jalr	-1082(ra) # 800045fc <filealloc>
    80004a3e:	00aa3023          	sd	a0,0(s4)
    80004a42:	c92d                	beqz	a0,80004ab4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	0dc080e7          	jalr	220(ra) # 80000b20 <kalloc>
    80004a4c:	892a                	mv	s2,a0
    80004a4e:	c125                	beqz	a0,80004aae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a50:	4985                	li	s3,1
    80004a52:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a56:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a5a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a5e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a62:	00004597          	auipc	a1,0x4
    80004a66:	cb658593          	addi	a1,a1,-842 # 80008718 <syscalls+0x288>
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	116080e7          	jalr	278(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004a72:	609c                	ld	a5,0(s1)
    80004a74:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a78:	609c                	ld	a5,0(s1)
    80004a7a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a7e:	609c                	ld	a5,0(s1)
    80004a80:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a84:	609c                	ld	a5,0(s1)
    80004a86:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a8a:	000a3783          	ld	a5,0(s4)
    80004a8e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a92:	000a3783          	ld	a5,0(s4)
    80004a96:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a9a:	000a3783          	ld	a5,0(s4)
    80004a9e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aa2:	000a3783          	ld	a5,0(s4)
    80004aa6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aaa:	4501                	li	a0,0
    80004aac:	a025                	j	80004ad4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aae:	6088                	ld	a0,0(s1)
    80004ab0:	e501                	bnez	a0,80004ab8 <pipealloc+0xaa>
    80004ab2:	a039                	j	80004ac0 <pipealloc+0xb2>
    80004ab4:	6088                	ld	a0,0(s1)
    80004ab6:	c51d                	beqz	a0,80004ae4 <pipealloc+0xd6>
    fileclose(*f0);
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	c00080e7          	jalr	-1024(ra) # 800046b8 <fileclose>
  if(*f1)
    80004ac0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ac4:	557d                	li	a0,-1
  if(*f1)
    80004ac6:	c799                	beqz	a5,80004ad4 <pipealloc+0xc6>
    fileclose(*f1);
    80004ac8:	853e                	mv	a0,a5
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	bee080e7          	jalr	-1042(ra) # 800046b8 <fileclose>
  return -1;
    80004ad2:	557d                	li	a0,-1
}
    80004ad4:	70a2                	ld	ra,40(sp)
    80004ad6:	7402                	ld	s0,32(sp)
    80004ad8:	64e2                	ld	s1,24(sp)
    80004ada:	6942                	ld	s2,16(sp)
    80004adc:	69a2                	ld	s3,8(sp)
    80004ade:	6a02                	ld	s4,0(sp)
    80004ae0:	6145                	addi	sp,sp,48
    80004ae2:	8082                	ret
  return -1;
    80004ae4:	557d                	li	a0,-1
    80004ae6:	b7fd                	j	80004ad4 <pipealloc+0xc6>

0000000080004ae8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ae8:	1101                	addi	sp,sp,-32
    80004aea:	ec06                	sd	ra,24(sp)
    80004aec:	e822                	sd	s0,16(sp)
    80004aee:	e426                	sd	s1,8(sp)
    80004af0:	e04a                	sd	s2,0(sp)
    80004af2:	1000                	addi	s0,sp,32
    80004af4:	84aa                	mv	s1,a0
    80004af6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	118080e7          	jalr	280(ra) # 80000c10 <acquire>
  if(writable){
    80004b00:	02090d63          	beqz	s2,80004b3a <pipeclose+0x52>
    pi->writeopen = 0;
    80004b04:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b08:	21848513          	addi	a0,s1,536
    80004b0c:	ffffe097          	auipc	ra,0xffffe
    80004b10:	a84080e7          	jalr	-1404(ra) # 80002590 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b14:	2204b783          	ld	a5,544(s1)
    80004b18:	eb95                	bnez	a5,80004b4c <pipeclose+0x64>
    release(&pi->lock);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	1a8080e7          	jalr	424(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	efe080e7          	jalr	-258(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004b2e:	60e2                	ld	ra,24(sp)
    80004b30:	6442                	ld	s0,16(sp)
    80004b32:	64a2                	ld	s1,8(sp)
    80004b34:	6902                	ld	s2,0(sp)
    80004b36:	6105                	addi	sp,sp,32
    80004b38:	8082                	ret
    pi->readopen = 0;
    80004b3a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b3e:	21c48513          	addi	a0,s1,540
    80004b42:	ffffe097          	auipc	ra,0xffffe
    80004b46:	a4e080e7          	jalr	-1458(ra) # 80002590 <wakeup>
    80004b4a:	b7e9                	j	80004b14 <pipeclose+0x2c>
    release(&pi->lock);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	176080e7          	jalr	374(ra) # 80000cc4 <release>
}
    80004b56:	bfe1                	j	80004b2e <pipeclose+0x46>

0000000080004b58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b58:	7119                	addi	sp,sp,-128
    80004b5a:	fc86                	sd	ra,120(sp)
    80004b5c:	f8a2                	sd	s0,112(sp)
    80004b5e:	f4a6                	sd	s1,104(sp)
    80004b60:	f0ca                	sd	s2,96(sp)
    80004b62:	ecce                	sd	s3,88(sp)
    80004b64:	e8d2                	sd	s4,80(sp)
    80004b66:	e4d6                	sd	s5,72(sp)
    80004b68:	e0da                	sd	s6,64(sp)
    80004b6a:	fc5e                	sd	s7,56(sp)
    80004b6c:	f862                	sd	s8,48(sp)
    80004b6e:	f466                	sd	s9,40(sp)
    80004b70:	f06a                	sd	s10,32(sp)
    80004b72:	ec6e                	sd	s11,24(sp)
    80004b74:	0100                	addi	s0,sp,128
    80004b76:	84aa                	mv	s1,a0
    80004b78:	8cae                	mv	s9,a1
    80004b7a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	f66080e7          	jalr	-154(ra) # 80001ae2 <myproc>
    80004b84:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b86:	8526                	mv	a0,s1
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	088080e7          	jalr	136(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004b90:	0d605963          	blez	s6,80004c62 <pipewrite+0x10a>
    80004b94:	89a6                	mv	s3,s1
    80004b96:	3b7d                	addiw	s6,s6,-1
    80004b98:	1b02                	slli	s6,s6,0x20
    80004b9a:	020b5b13          	srli	s6,s6,0x20
    80004b9e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ba0:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ba4:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba8:	5dfd                	li	s11,-1
    80004baa:	000b8d1b          	sext.w	s10,s7
    80004bae:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bb0:	2184a783          	lw	a5,536(s1)
    80004bb4:	21c4a703          	lw	a4,540(s1)
    80004bb8:	2007879b          	addiw	a5,a5,512
    80004bbc:	02f71b63          	bne	a4,a5,80004bf2 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004bc0:	2204a783          	lw	a5,544(s1)
    80004bc4:	cbad                	beqz	a5,80004c36 <pipewrite+0xde>
    80004bc6:	03092783          	lw	a5,48(s2)
    80004bca:	e7b5                	bnez	a5,80004c36 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004bcc:	8556                	mv	a0,s5
    80004bce:	ffffe097          	auipc	ra,0xffffe
    80004bd2:	9c2080e7          	jalr	-1598(ra) # 80002590 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bd6:	85ce                	mv	a1,s3
    80004bd8:	8552                	mv	a0,s4
    80004bda:	ffffe097          	auipc	ra,0xffffe
    80004bde:	830080e7          	jalr	-2000(ra) # 8000240a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004be2:	2184a783          	lw	a5,536(s1)
    80004be6:	21c4a703          	lw	a4,540(s1)
    80004bea:	2007879b          	addiw	a5,a5,512
    80004bee:	fcf709e3          	beq	a4,a5,80004bc0 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf2:	4685                	li	a3,1
    80004bf4:	019b8633          	add	a2,s7,s9
    80004bf8:	f8f40593          	addi	a1,s0,-113
    80004bfc:	05093503          	ld	a0,80(s2)
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	dda080e7          	jalr	-550(ra) # 800019da <copyin>
    80004c08:	05b50e63          	beq	a0,s11,80004c64 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c0c:	21c4a783          	lw	a5,540(s1)
    80004c10:	0017871b          	addiw	a4,a5,1
    80004c14:	20e4ae23          	sw	a4,540(s1)
    80004c18:	1ff7f793          	andi	a5,a5,511
    80004c1c:	97a6                	add	a5,a5,s1
    80004c1e:	f8f44703          	lbu	a4,-113(s0)
    80004c22:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c26:	001d0c1b          	addiw	s8,s10,1
    80004c2a:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004c2e:	036b8b63          	beq	s7,s6,80004c64 <pipewrite+0x10c>
    80004c32:	8bbe                	mv	s7,a5
    80004c34:	bf9d                	j	80004baa <pipewrite+0x52>
        release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	08c080e7          	jalr	140(ra) # 80000cc4 <release>
        return -1;
    80004c40:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c42:	8562                	mv	a0,s8
    80004c44:	70e6                	ld	ra,120(sp)
    80004c46:	7446                	ld	s0,112(sp)
    80004c48:	74a6                	ld	s1,104(sp)
    80004c4a:	7906                	ld	s2,96(sp)
    80004c4c:	69e6                	ld	s3,88(sp)
    80004c4e:	6a46                	ld	s4,80(sp)
    80004c50:	6aa6                	ld	s5,72(sp)
    80004c52:	6b06                	ld	s6,64(sp)
    80004c54:	7be2                	ld	s7,56(sp)
    80004c56:	7c42                	ld	s8,48(sp)
    80004c58:	7ca2                	ld	s9,40(sp)
    80004c5a:	7d02                	ld	s10,32(sp)
    80004c5c:	6de2                	ld	s11,24(sp)
    80004c5e:	6109                	addi	sp,sp,128
    80004c60:	8082                	ret
  for(i = 0; i < n; i++){
    80004c62:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c64:	21848513          	addi	a0,s1,536
    80004c68:	ffffe097          	auipc	ra,0xffffe
    80004c6c:	928080e7          	jalr	-1752(ra) # 80002590 <wakeup>
  release(&pi->lock);
    80004c70:	8526                	mv	a0,s1
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	052080e7          	jalr	82(ra) # 80000cc4 <release>
  return i;
    80004c7a:	b7e1                	j	80004c42 <pipewrite+0xea>

0000000080004c7c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c7c:	715d                	addi	sp,sp,-80
    80004c7e:	e486                	sd	ra,72(sp)
    80004c80:	e0a2                	sd	s0,64(sp)
    80004c82:	fc26                	sd	s1,56(sp)
    80004c84:	f84a                	sd	s2,48(sp)
    80004c86:	f44e                	sd	s3,40(sp)
    80004c88:	f052                	sd	s4,32(sp)
    80004c8a:	ec56                	sd	s5,24(sp)
    80004c8c:	e85a                	sd	s6,16(sp)
    80004c8e:	0880                	addi	s0,sp,80
    80004c90:	84aa                	mv	s1,a0
    80004c92:	892e                	mv	s2,a1
    80004c94:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c96:	ffffd097          	auipc	ra,0xffffd
    80004c9a:	e4c080e7          	jalr	-436(ra) # 80001ae2 <myproc>
    80004c9e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ca0:	8b26                	mv	s6,s1
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	f6c080e7          	jalr	-148(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cac:	2184a703          	lw	a4,536(s1)
    80004cb0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cb4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb8:	02f71463          	bne	a4,a5,80004ce0 <piperead+0x64>
    80004cbc:	2244a783          	lw	a5,548(s1)
    80004cc0:	c385                	beqz	a5,80004ce0 <piperead+0x64>
    if(pr->killed){
    80004cc2:	030a2783          	lw	a5,48(s4)
    80004cc6:	ebc1                	bnez	a5,80004d56 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cc8:	85da                	mv	a1,s6
    80004cca:	854e                	mv	a0,s3
    80004ccc:	ffffd097          	auipc	ra,0xffffd
    80004cd0:	73e080e7          	jalr	1854(ra) # 8000240a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd4:	2184a703          	lw	a4,536(s1)
    80004cd8:	21c4a783          	lw	a5,540(s1)
    80004cdc:	fef700e3          	beq	a4,a5,80004cbc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ce0:	09505263          	blez	s5,80004d64 <piperead+0xe8>
    80004ce4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ce8:	2184a783          	lw	a5,536(s1)
    80004cec:	21c4a703          	lw	a4,540(s1)
    80004cf0:	02f70d63          	beq	a4,a5,80004d2a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cf4:	0017871b          	addiw	a4,a5,1
    80004cf8:	20e4ac23          	sw	a4,536(s1)
    80004cfc:	1ff7f793          	andi	a5,a5,511
    80004d00:	97a6                	add	a5,a5,s1
    80004d02:	0187c783          	lbu	a5,24(a5)
    80004d06:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d0a:	4685                	li	a3,1
    80004d0c:	fbf40613          	addi	a2,s0,-65
    80004d10:	85ca                	mv	a1,s2
    80004d12:	050a3503          	ld	a0,80(s4)
    80004d16:	ffffd097          	auipc	ra,0xffffd
    80004d1a:	c38080e7          	jalr	-968(ra) # 8000194e <copyout>
    80004d1e:	01650663          	beq	a0,s6,80004d2a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d22:	2985                	addiw	s3,s3,1
    80004d24:	0905                	addi	s2,s2,1
    80004d26:	fd3a91e3          	bne	s5,s3,80004ce8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d2a:	21c48513          	addi	a0,s1,540
    80004d2e:	ffffe097          	auipc	ra,0xffffe
    80004d32:	862080e7          	jalr	-1950(ra) # 80002590 <wakeup>
  release(&pi->lock);
    80004d36:	8526                	mv	a0,s1
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	f8c080e7          	jalr	-116(ra) # 80000cc4 <release>
  return i;
}
    80004d40:	854e                	mv	a0,s3
    80004d42:	60a6                	ld	ra,72(sp)
    80004d44:	6406                	ld	s0,64(sp)
    80004d46:	74e2                	ld	s1,56(sp)
    80004d48:	7942                	ld	s2,48(sp)
    80004d4a:	79a2                	ld	s3,40(sp)
    80004d4c:	7a02                	ld	s4,32(sp)
    80004d4e:	6ae2                	ld	s5,24(sp)
    80004d50:	6b42                	ld	s6,16(sp)
    80004d52:	6161                	addi	sp,sp,80
    80004d54:	8082                	ret
      release(&pi->lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	f6c080e7          	jalr	-148(ra) # 80000cc4 <release>
      return -1;
    80004d60:	59fd                	li	s3,-1
    80004d62:	bff9                	j	80004d40 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d64:	4981                	li	s3,0
    80004d66:	b7d1                	j	80004d2a <piperead+0xae>

0000000080004d68 <exec>:
#include "elf.h"

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int exec(char *path, char **argv)
{
    80004d68:	de010113          	addi	sp,sp,-544
    80004d6c:	20113c23          	sd	ra,536(sp)
    80004d70:	20813823          	sd	s0,528(sp)
    80004d74:	20913423          	sd	s1,520(sp)
    80004d78:	21213023          	sd	s2,512(sp)
    80004d7c:	ffce                	sd	s3,504(sp)
    80004d7e:	fbd2                	sd	s4,496(sp)
    80004d80:	f7d6                	sd	s5,488(sp)
    80004d82:	f3da                	sd	s6,480(sp)
    80004d84:	efde                	sd	s7,472(sp)
    80004d86:	ebe2                	sd	s8,464(sp)
    80004d88:	e7e6                	sd	s9,456(sp)
    80004d8a:	e3ea                	sd	s10,448(sp)
    80004d8c:	ff6e                	sd	s11,440(sp)
    80004d8e:	1400                	addi	s0,sp,544
    80004d90:	84aa                	mv	s1,a0
    80004d92:	dea43823          	sd	a0,-528(s0)
    80004d96:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG + 1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	d48080e7          	jalr	-696(ra) # 80001ae2 <myproc>
    80004da2:	892a                	mv	s2,a0

  begin_op();
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	442080e7          	jalr	1090(ra) # 800041e6 <begin_op>

  if ((ip = namei(path)) == 0)
    80004dac:	8526                	mv	a0,s1
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	22c080e7          	jalr	556(ra) # 80003fda <namei>
    80004db6:	c93d                	beqz	a0,80004e2c <exec+0xc4>
    80004db8:	84aa                	mv	s1,a0
  {
    end_op();
    return -1;
  }
  ilock(ip);
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	a70080e7          	jalr	-1424(ra) # 8000382a <ilock>

  // Check ELF header
  if (readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dc2:	04000713          	li	a4,64
    80004dc6:	4681                	li	a3,0
    80004dc8:	e4840613          	addi	a2,s0,-440
    80004dcc:	4581                	li	a1,0
    80004dce:	8526                	mv	a0,s1
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	d0e080e7          	jalr	-754(ra) # 80003ade <readi>
    80004dd8:	04000793          	li	a5,64
    80004ddc:	00f51a63          	bne	a0,a5,80004df0 <exec+0x88>
    goto bad;
  if (elf.magic != ELF_MAGIC)
    80004de0:	e4842703          	lw	a4,-440(s0)
    80004de4:	464c47b7          	lui	a5,0x464c4
    80004de8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dec:	04f70663          	beq	a4,a5,80004e38 <exec+0xd0>
bad:
  if (pagetable)
    proc_freepagetable(pagetable, sz);
  if (ip)
  {
    iunlockput(ip);
    80004df0:	8526                	mv	a0,s1
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	c9a080e7          	jalr	-870(ra) # 80003a8c <iunlockput>
    end_op();
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	46c080e7          	jalr	1132(ra) # 80004266 <end_op>
  }
  return -1;
    80004e02:	557d                	li	a0,-1
}
    80004e04:	21813083          	ld	ra,536(sp)
    80004e08:	21013403          	ld	s0,528(sp)
    80004e0c:	20813483          	ld	s1,520(sp)
    80004e10:	20013903          	ld	s2,512(sp)
    80004e14:	79fe                	ld	s3,504(sp)
    80004e16:	7a5e                	ld	s4,496(sp)
    80004e18:	7abe                	ld	s5,488(sp)
    80004e1a:	7b1e                	ld	s6,480(sp)
    80004e1c:	6bfe                	ld	s7,472(sp)
    80004e1e:	6c5e                	ld	s8,464(sp)
    80004e20:	6cbe                	ld	s9,456(sp)
    80004e22:	6d1e                	ld	s10,448(sp)
    80004e24:	7dfa                	ld	s11,440(sp)
    80004e26:	22010113          	addi	sp,sp,544
    80004e2a:	8082                	ret
    end_op();
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	43a080e7          	jalr	1082(ra) # 80004266 <end_op>
    return -1;
    80004e34:	557d                	li	a0,-1
    80004e36:	b7f9                	j	80004e04 <exec+0x9c>
  if ((pagetable = proc_pagetable(p)) == 0)
    80004e38:	854a                	mv	a0,s2
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	d6c080e7          	jalr	-660(ra) # 80001ba6 <proc_pagetable>
    80004e42:	e0a43423          	sd	a0,-504(s0)
    80004e46:	d54d                	beqz	a0,80004df0 <exec+0x88>
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    80004e48:	e6842983          	lw	s3,-408(s0)
    80004e4c:	e8045783          	lhu	a5,-384(s0)
    80004e50:	cbb5                	beqz	a5,80004ec4 <exec+0x15c>
  uint64 argc, sz = 0, sp, ustack[MAXARG + 1], stackbase;
    80004e52:	4901                	li	s2,0
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    80004e54:	4b01                	li	s6,0
    if ((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e56:	0c0007b7          	lui	a5,0xc000
    80004e5a:	17f9                	addi	a5,a5,-2
    80004e5c:	def43423          	sd	a5,-536(s0)
    if (ph.vaddr % PGSIZE != 0)
    80004e60:	6b85                	lui	s7,0x1
    80004e62:	fffb8793          	addi	a5,s7,-1 # fff <_entry-0x7ffff001>
    80004e66:	def43023          	sd	a5,-544(s0)
    80004e6a:	a4bd                	j	800050d8 <exec+0x370>

  for (i = 0; i < sz; i += PGSIZE)
  {
    pa = walkaddr(pagetable, va + i);
    if (pa == 0)
      panic("loadseg: address should exist");
    80004e6c:	00004517          	auipc	a0,0x4
    80004e70:	8b450513          	addi	a0,a0,-1868 # 80008720 <syscalls+0x290>
    80004e74:	ffffb097          	auipc	ra,0xffffb
    80004e78:	6d4080e7          	jalr	1748(ra) # 80000548 <panic>
    if (sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if (readi(ip, 0, (uint64)pa, offset + i, n) != n)
    80004e7c:	8756                	mv	a4,s5
    80004e7e:	012d06bb          	addw	a3,s10,s2
    80004e82:	4581                	li	a1,0
    80004e84:	8526                	mv	a0,s1
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	c58080e7          	jalr	-936(ra) # 80003ade <readi>
    80004e8e:	2501                	sext.w	a0,a0
    80004e90:	1eaa9a63          	bne	s5,a0,80005084 <exec+0x31c>
  for (i = 0; i < sz; i += PGSIZE)
    80004e94:	6785                	lui	a5,0x1
    80004e96:	0127893b          	addw	s2,a5,s2
    80004e9a:	014d8a3b          	addw	s4,s11,s4
    80004e9e:	23897463          	bgeu	s2,s8,800050c6 <exec+0x35e>
    pa = walkaddr(pagetable, va + i);
    80004ea2:	02091593          	slli	a1,s2,0x20
    80004ea6:	9181                	srli	a1,a1,0x20
    80004ea8:	95e6                	add	a1,a1,s9
    80004eaa:	e0843503          	ld	a0,-504(s0)
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	24e080e7          	jalr	590(ra) # 800010fc <walkaddr>
    80004eb6:	862a                	mv	a2,a0
    if (pa == 0)
    80004eb8:	d955                	beqz	a0,80004e6c <exec+0x104>
      n = PGSIZE;
    80004eba:	8ade                	mv	s5,s7
    if (sz - i < PGSIZE)
    80004ebc:	fd7a70e3          	bgeu	s4,s7,80004e7c <exec+0x114>
      n = sz - i;
    80004ec0:	8ad2                	mv	s5,s4
    80004ec2:	bf6d                	j	80004e7c <exec+0x114>
  uint64 argc, sz = 0, sp, ustack[MAXARG + 1], stackbase;
    80004ec4:	4901                	li	s2,0
  iunlockput(ip);
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	bc4080e7          	jalr	-1084(ra) # 80003a8c <iunlockput>
  end_op();
    80004ed0:	fffff097          	auipc	ra,0xfffff
    80004ed4:	396080e7          	jalr	918(ra) # 80004266 <end_op>
  p = myproc();
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	c0a080e7          	jalr	-1014(ra) # 80001ae2 <myproc>
    80004ee0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ee2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ee6:	6785                	lui	a5,0x1
    80004ee8:	17fd                	addi	a5,a5,-1
    80004eea:	993e                	add	s2,s2,a5
    80004eec:	757d                	lui	a0,0xfffff
    80004eee:	00a977b3          	and	a5,s2,a0
    80004ef2:	e0f43023          	sd	a5,-512(s0)
  if ((sz1 = uvmalloc(pagetable, sz, sz + 2 * PGSIZE)) == 0)
    80004ef6:	6609                	lui	a2,0x2
    80004ef8:	963e                	add	a2,a2,a5
    80004efa:	85be                	mv	a1,a5
    80004efc:	e0843903          	ld	s2,-504(s0)
    80004f00:	854a                	mv	a0,s2
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	6a2080e7          	jalr	1698(ra) # 800015a4 <uvmalloc>
    80004f0a:	8b2a                	mv	s6,a0
  ip = 0;
    80004f0c:	4481                	li	s1,0
  if ((sz1 = uvmalloc(pagetable, sz, sz + 2 * PGSIZE)) == 0)
    80004f0e:	16050b63          	beqz	a0,80005084 <exec+0x31c>
  uvmclear(pagetable, sz - 2 * PGSIZE);
    80004f12:	75f9                	lui	a1,0xffffe
    80004f14:	95aa                	add	a1,a1,a0
    80004f16:	854a                	mv	a0,s2
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	a04080e7          	jalr	-1532(ra) # 8000191c <uvmclear>
  stackbase = sp - PGSIZE;
    80004f20:	7c7d                	lui	s8,0xfffff
    80004f22:	9c5a                	add	s8,s8,s6
  for (argc = 0; argv[argc]; argc++)
    80004f24:	df843783          	ld	a5,-520(s0)
    80004f28:	6388                	ld	a0,0(a5)
    80004f2a:	c53d                	beqz	a0,80004f98 <exec+0x230>
    80004f2c:	e8840993          	addi	s3,s0,-376
    80004f30:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f34:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	f5e080e7          	jalr	-162(ra) # 80000e94 <strlen>
    80004f3e:	2505                	addiw	a0,a0,1
    80004f40:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f44:	ff097913          	andi	s2,s2,-16
    if (sp < stackbase)
    80004f48:	17896363          	bltu	s2,s8,800050ae <exec+0x346>
    if (copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f4c:	df843b83          	ld	s7,-520(s0)
    80004f50:	000bba03          	ld	s4,0(s7)
    80004f54:	8552                	mv	a0,s4
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	f3e080e7          	jalr	-194(ra) # 80000e94 <strlen>
    80004f5e:	0015069b          	addiw	a3,a0,1
    80004f62:	8652                	mv	a2,s4
    80004f64:	85ca                	mv	a1,s2
    80004f66:	e0843503          	ld	a0,-504(s0)
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	9e4080e7          	jalr	-1564(ra) # 8000194e <copyout>
    80004f72:	14054263          	bltz	a0,800050b6 <exec+0x34e>
    ustack[argc] = sp;
    80004f76:	0129b023          	sd	s2,0(s3)
  for (argc = 0; argv[argc]; argc++)
    80004f7a:	0485                	addi	s1,s1,1
    80004f7c:	008b8793          	addi	a5,s7,8
    80004f80:	def43c23          	sd	a5,-520(s0)
    80004f84:	008bb503          	ld	a0,8(s7)
    80004f88:	c911                	beqz	a0,80004f9c <exec+0x234>
    if (argc >= MAXARG)
    80004f8a:	09a1                	addi	s3,s3,8
    80004f8c:	fb3c95e3          	bne	s9,s3,80004f36 <exec+0x1ce>
  sz = sz1;
    80004f90:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004f94:	4481                	li	s1,0
    80004f96:	a0fd                	j	80005084 <exec+0x31c>
  sp = sz;
    80004f98:	895a                	mv	s2,s6
  for (argc = 0; argv[argc]; argc++)
    80004f9a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f9c:	00349793          	slli	a5,s1,0x3
    80004fa0:	f9040713          	addi	a4,s0,-112
    80004fa4:	97ba                	add	a5,a5,a4
    80004fa6:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc + 1) * sizeof(uint64);
    80004faa:	00148693          	addi	a3,s1,1
    80004fae:	068e                	slli	a3,a3,0x3
    80004fb0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fb4:	ff097913          	andi	s2,s2,-16
  if (sp < stackbase)
    80004fb8:	01897663          	bgeu	s2,s8,80004fc4 <exec+0x25c>
  sz = sz1;
    80004fbc:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004fc0:	4481                	li	s1,0
    80004fc2:	a0c9                	j	80005084 <exec+0x31c>
  if (copyout(pagetable, sp, (char *)ustack, (argc + 1) * sizeof(uint64)) < 0)
    80004fc4:	e8840613          	addi	a2,s0,-376
    80004fc8:	85ca                	mv	a1,s2
    80004fca:	e0843503          	ld	a0,-504(s0)
    80004fce:	ffffd097          	auipc	ra,0xffffd
    80004fd2:	980080e7          	jalr	-1664(ra) # 8000194e <copyout>
    80004fd6:	0e054463          	bltz	a0,800050be <exec+0x356>
  p->trapframe->a1 = sp;
    80004fda:	058ab783          	ld	a5,88(s5)
    80004fde:	0727bc23          	sd	s2,120(a5)
  for (last = s = path; *s; s++)
    80004fe2:	df043783          	ld	a5,-528(s0)
    80004fe6:	0007c703          	lbu	a4,0(a5)
    80004fea:	cf11                	beqz	a4,80005006 <exec+0x29e>
    80004fec:	0785                	addi	a5,a5,1
    if (*s == '/')
    80004fee:	02f00693          	li	a3,47
    80004ff2:	a039                	j	80005000 <exec+0x298>
      last = s + 1;
    80004ff4:	def43823          	sd	a5,-528(s0)
  for (last = s = path; *s; s++)
    80004ff8:	0785                	addi	a5,a5,1
    80004ffa:	fff7c703          	lbu	a4,-1(a5)
    80004ffe:	c701                	beqz	a4,80005006 <exec+0x29e>
    if (*s == '/')
    80005000:	fed71ce3          	bne	a4,a3,80004ff8 <exec+0x290>
    80005004:	bfc5                	j	80004ff4 <exec+0x28c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005006:	4641                	li	a2,16
    80005008:	df043583          	ld	a1,-528(s0)
    8000500c:	158a8513          	addi	a0,s5,344
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	e52080e7          	jalr	-430(ra) # 80000e62 <safestrcpy>
  uvmunmap(p->kernelpgt, 0, PGROUNDUP(oldsz)/PGSIZE, 0);
    80005018:	6605                	lui	a2,0x1
    8000501a:	167d                	addi	a2,a2,-1
    8000501c:	966a                	add	a2,a2,s10
    8000501e:	4681                	li	a3,0
    80005020:	8231                	srli	a2,a2,0xc
    80005022:	4581                	li	a1,0
    80005024:	168ab503          	ld	a0,360(s5)
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	2d4080e7          	jalr	724(ra) # 800012fc <uvmunmap>
  kvmcopy(pagetable, p->kernelpgt, 0, sz);
    80005030:	86da                	mv	a3,s6
    80005032:	4601                	li	a2,0
    80005034:	168ab583          	ld	a1,360(s5)
    80005038:	e0843983          	ld	s3,-504(s0)
    8000503c:	854e                	mv	a0,s3
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	382080e7          	jalr	898(ra) # 800013c0 <kvmcopy>
  oldpagetable = p->pagetable;
    80005046:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000504a:	053ab823          	sd	s3,80(s5)
  p->sz = sz;
    8000504e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry; // initial program counter = main
    80005052:	058ab783          	ld	a5,88(s5)
    80005056:	e6043703          	ld	a4,-416(s0)
    8000505a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp;         // initial stack pointer
    8000505c:	058ab783          	ld	a5,88(s5)
    80005060:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005064:	85ea                	mv	a1,s10
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	bdc080e7          	jalr	-1060(ra) # 80001c42 <proc_freepagetable>
  vmprint(p->pagetable);
    8000506e:	050ab503          	ld	a0,80(s5)
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	6a2080e7          	jalr	1698(ra) # 80001714 <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000507a:	0004851b          	sext.w	a0,s1
    8000507e:	b359                	j	80004e04 <exec+0x9c>
    80005080:	e1243023          	sd	s2,-512(s0)
    proc_freepagetable(pagetable, sz);
    80005084:	e0043583          	ld	a1,-512(s0)
    80005088:	e0843503          	ld	a0,-504(s0)
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	bb6080e7          	jalr	-1098(ra) # 80001c42 <proc_freepagetable>
  if (ip)
    80005094:	d4049ee3          	bnez	s1,80004df0 <exec+0x88>
  return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	b3ad                	j	80004e04 <exec+0x9c>
    8000509c:	e1243023          	sd	s2,-512(s0)
    800050a0:	b7d5                	j	80005084 <exec+0x31c>
    800050a2:	e1243023          	sd	s2,-512(s0)
    800050a6:	bff9                	j	80005084 <exec+0x31c>
    800050a8:	e1243023          	sd	s2,-512(s0)
    800050ac:	bfe1                	j	80005084 <exec+0x31c>
  sz = sz1;
    800050ae:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800050b2:	4481                	li	s1,0
    800050b4:	bfc1                	j	80005084 <exec+0x31c>
  sz = sz1;
    800050b6:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800050ba:	4481                	li	s1,0
    800050bc:	b7e1                	j	80005084 <exec+0x31c>
  sz = sz1;
    800050be:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800050c2:	4481                	li	s1,0
    800050c4:	b7c1                	j	80005084 <exec+0x31c>
    if ((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050c6:	e0043903          	ld	s2,-512(s0)
  for (i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph))
    800050ca:	2b05                	addiw	s6,s6,1
    800050cc:	0389899b          	addiw	s3,s3,56
    800050d0:	e8045783          	lhu	a5,-384(s0)
    800050d4:	defb59e3          	bge	s6,a5,80004ec6 <exec+0x15e>
    if (readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050d8:	2981                	sext.w	s3,s3
    800050da:	03800713          	li	a4,56
    800050de:	86ce                	mv	a3,s3
    800050e0:	e1040613          	addi	a2,s0,-496
    800050e4:	4581                	li	a1,0
    800050e6:	8526                	mv	a0,s1
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	9f6080e7          	jalr	-1546(ra) # 80003ade <readi>
    800050f0:	03800793          	li	a5,56
    800050f4:	f8f516e3          	bne	a0,a5,80005080 <exec+0x318>
    if (ph.type != ELF_PROG_LOAD)
    800050f8:	e1042783          	lw	a5,-496(s0)
    800050fc:	4705                	li	a4,1
    800050fe:	fce796e3          	bne	a5,a4,800050ca <exec+0x362>
    if (ph.memsz < ph.filesz)
    80005102:	e3843603          	ld	a2,-456(s0)
    80005106:	e3043783          	ld	a5,-464(s0)
    8000510a:	f8f669e3          	bltu	a2,a5,8000509c <exec+0x334>
    if (ph.vaddr + ph.memsz < ph.vaddr)
    8000510e:	e2043783          	ld	a5,-480(s0)
    80005112:	963e                	add	a2,a2,a5
    80005114:	f8f667e3          	bltu	a2,a5,800050a2 <exec+0x33a>
    if ((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005118:	85ca                	mv	a1,s2
    8000511a:	e0843503          	ld	a0,-504(s0)
    8000511e:	ffffc097          	auipc	ra,0xffffc
    80005122:	486080e7          	jalr	1158(ra) # 800015a4 <uvmalloc>
    80005126:	e0a43023          	sd	a0,-512(s0)
    8000512a:	fff50793          	addi	a5,a0,-1 # ffffffffffffefff <end+0xffffffff7ffd7fdf>
    8000512e:	de843703          	ld	a4,-536(s0)
    80005132:	f6f76be3          	bltu	a4,a5,800050a8 <exec+0x340>
    if (ph.vaddr % PGSIZE != 0)
    80005136:	e2043c83          	ld	s9,-480(s0)
    8000513a:	de043783          	ld	a5,-544(s0)
    8000513e:	00fcf7b3          	and	a5,s9,a5
    80005142:	f3a9                	bnez	a5,80005084 <exec+0x31c>
    if (loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005144:	e1842d03          	lw	s10,-488(s0)
    80005148:	e3042c03          	lw	s8,-464(s0)
  for (i = 0; i < sz; i += PGSIZE)
    8000514c:	f60c0de3          	beqz	s8,800050c6 <exec+0x35e>
    80005150:	8a62                	mv	s4,s8
    80005152:	4901                	li	s2,0
    80005154:	7dfd                	lui	s11,0xfffff
    80005156:	b3b1                	j	80004ea2 <exec+0x13a>

0000000080005158 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005158:	7179                	addi	sp,sp,-48
    8000515a:	f406                	sd	ra,40(sp)
    8000515c:	f022                	sd	s0,32(sp)
    8000515e:	ec26                	sd	s1,24(sp)
    80005160:	e84a                	sd	s2,16(sp)
    80005162:	1800                	addi	s0,sp,48
    80005164:	892e                	mv	s2,a1
    80005166:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005168:	fdc40593          	addi	a1,s0,-36
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	b4c080e7          	jalr	-1204(ra) # 80002cb8 <argint>
    80005174:	04054063          	bltz	a0,800051b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005178:	fdc42703          	lw	a4,-36(s0)
    8000517c:	47bd                	li	a5,15
    8000517e:	02e7ed63          	bltu	a5,a4,800051b8 <argfd+0x60>
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	960080e7          	jalr	-1696(ra) # 80001ae2 <myproc>
    8000518a:	fdc42703          	lw	a4,-36(s0)
    8000518e:	01a70793          	addi	a5,a4,26
    80005192:	078e                	slli	a5,a5,0x3
    80005194:	953e                	add	a0,a0,a5
    80005196:	611c                	ld	a5,0(a0)
    80005198:	c395                	beqz	a5,800051bc <argfd+0x64>
    return -1;
  if(pfd)
    8000519a:	00090463          	beqz	s2,800051a2 <argfd+0x4a>
    *pfd = fd;
    8000519e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a2:	4501                	li	a0,0
  if(pf)
    800051a4:	c091                	beqz	s1,800051a8 <argfd+0x50>
    *pf = f;
    800051a6:	e09c                	sd	a5,0(s1)
}
    800051a8:	70a2                	ld	ra,40(sp)
    800051aa:	7402                	ld	s0,32(sp)
    800051ac:	64e2                	ld	s1,24(sp)
    800051ae:	6942                	ld	s2,16(sp)
    800051b0:	6145                	addi	sp,sp,48
    800051b2:	8082                	ret
    return -1;
    800051b4:	557d                	li	a0,-1
    800051b6:	bfcd                	j	800051a8 <argfd+0x50>
    return -1;
    800051b8:	557d                	li	a0,-1
    800051ba:	b7fd                	j	800051a8 <argfd+0x50>
    800051bc:	557d                	li	a0,-1
    800051be:	b7ed                	j	800051a8 <argfd+0x50>

00000000800051c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c0:	1101                	addi	sp,sp,-32
    800051c2:	ec06                	sd	ra,24(sp)
    800051c4:	e822                	sd	s0,16(sp)
    800051c6:	e426                	sd	s1,8(sp)
    800051c8:	1000                	addi	s0,sp,32
    800051ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	916080e7          	jalr	-1770(ra) # 80001ae2 <myproc>
    800051d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051d6:	0d050793          	addi	a5,a0,208
    800051da:	4501                	li	a0,0
    800051dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051de:	6398                	ld	a4,0(a5)
    800051e0:	cb19                	beqz	a4,800051f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e2:	2505                	addiw	a0,a0,1
    800051e4:	07a1                	addi	a5,a5,8
    800051e6:	fed51ce3          	bne	a0,a3,800051de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ea:	557d                	li	a0,-1
}
    800051ec:	60e2                	ld	ra,24(sp)
    800051ee:	6442                	ld	s0,16(sp)
    800051f0:	64a2                	ld	s1,8(sp)
    800051f2:	6105                	addi	sp,sp,32
    800051f4:	8082                	ret
      p->ofile[fd] = f;
    800051f6:	01a50793          	addi	a5,a0,26
    800051fa:	078e                	slli	a5,a5,0x3
    800051fc:	963e                	add	a2,a2,a5
    800051fe:	e204                	sd	s1,0(a2)
      return fd;
    80005200:	b7f5                	j	800051ec <fdalloc+0x2c>

0000000080005202 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005202:	715d                	addi	sp,sp,-80
    80005204:	e486                	sd	ra,72(sp)
    80005206:	e0a2                	sd	s0,64(sp)
    80005208:	fc26                	sd	s1,56(sp)
    8000520a:	f84a                	sd	s2,48(sp)
    8000520c:	f44e                	sd	s3,40(sp)
    8000520e:	f052                	sd	s4,32(sp)
    80005210:	ec56                	sd	s5,24(sp)
    80005212:	0880                	addi	s0,sp,80
    80005214:	89ae                	mv	s3,a1
    80005216:	8ab2                	mv	s5,a2
    80005218:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000521a:	fb040593          	addi	a1,s0,-80
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	dda080e7          	jalr	-550(ra) # 80003ff8 <nameiparent>
    80005226:	892a                	mv	s2,a0
    80005228:	12050f63          	beqz	a0,80005366 <create+0x164>
    return 0;

  ilock(dp);
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	5fe080e7          	jalr	1534(ra) # 8000382a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005234:	4601                	li	a2,0
    80005236:	fb040593          	addi	a1,s0,-80
    8000523a:	854a                	mv	a0,s2
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	acc080e7          	jalr	-1332(ra) # 80003d08 <dirlookup>
    80005244:	84aa                	mv	s1,a0
    80005246:	c921                	beqz	a0,80005296 <create+0x94>
    iunlockput(dp);
    80005248:	854a                	mv	a0,s2
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	842080e7          	jalr	-1982(ra) # 80003a8c <iunlockput>
    ilock(ip);
    80005252:	8526                	mv	a0,s1
    80005254:	ffffe097          	auipc	ra,0xffffe
    80005258:	5d6080e7          	jalr	1494(ra) # 8000382a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000525c:	2981                	sext.w	s3,s3
    8000525e:	4789                	li	a5,2
    80005260:	02f99463          	bne	s3,a5,80005288 <create+0x86>
    80005264:	0444d783          	lhu	a5,68(s1)
    80005268:	37f9                	addiw	a5,a5,-2
    8000526a:	17c2                	slli	a5,a5,0x30
    8000526c:	93c1                	srli	a5,a5,0x30
    8000526e:	4705                	li	a4,1
    80005270:	00f76c63          	bltu	a4,a5,80005288 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005274:	8526                	mv	a0,s1
    80005276:	60a6                	ld	ra,72(sp)
    80005278:	6406                	ld	s0,64(sp)
    8000527a:	74e2                	ld	s1,56(sp)
    8000527c:	7942                	ld	s2,48(sp)
    8000527e:	79a2                	ld	s3,40(sp)
    80005280:	7a02                	ld	s4,32(sp)
    80005282:	6ae2                	ld	s5,24(sp)
    80005284:	6161                	addi	sp,sp,80
    80005286:	8082                	ret
    iunlockput(ip);
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	802080e7          	jalr	-2046(ra) # 80003a8c <iunlockput>
    return 0;
    80005292:	4481                	li	s1,0
    80005294:	b7c5                	j	80005274 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005296:	85ce                	mv	a1,s3
    80005298:	00092503          	lw	a0,0(s2)
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	3f6080e7          	jalr	1014(ra) # 80003692 <ialloc>
    800052a4:	84aa                	mv	s1,a0
    800052a6:	c529                	beqz	a0,800052f0 <create+0xee>
  ilock(ip);
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	582080e7          	jalr	1410(ra) # 8000382a <ilock>
  ip->major = major;
    800052b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052b8:	4785                	li	a5,1
    800052ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052be:	8526                	mv	a0,s1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	4a0080e7          	jalr	1184(ra) # 80003760 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052c8:	2981                	sext.w	s3,s3
    800052ca:	4785                	li	a5,1
    800052cc:	02f98a63          	beq	s3,a5,80005300 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052d0:	40d0                	lw	a2,4(s1)
    800052d2:	fb040593          	addi	a1,s0,-80
    800052d6:	854a                	mv	a0,s2
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	c40080e7          	jalr	-960(ra) # 80003f18 <dirlink>
    800052e0:	06054b63          	bltz	a0,80005356 <create+0x154>
  iunlockput(dp);
    800052e4:	854a                	mv	a0,s2
    800052e6:	ffffe097          	auipc	ra,0xffffe
    800052ea:	7a6080e7          	jalr	1958(ra) # 80003a8c <iunlockput>
  return ip;
    800052ee:	b759                	j	80005274 <create+0x72>
    panic("create: ialloc");
    800052f0:	00003517          	auipc	a0,0x3
    800052f4:	45050513          	addi	a0,a0,1104 # 80008740 <syscalls+0x2b0>
    800052f8:	ffffb097          	auipc	ra,0xffffb
    800052fc:	250080e7          	jalr	592(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005300:	04a95783          	lhu	a5,74(s2)
    80005304:	2785                	addiw	a5,a5,1
    80005306:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000530a:	854a                	mv	a0,s2
    8000530c:	ffffe097          	auipc	ra,0xffffe
    80005310:	454080e7          	jalr	1108(ra) # 80003760 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005314:	40d0                	lw	a2,4(s1)
    80005316:	00003597          	auipc	a1,0x3
    8000531a:	43a58593          	addi	a1,a1,1082 # 80008750 <syscalls+0x2c0>
    8000531e:	8526                	mv	a0,s1
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	bf8080e7          	jalr	-1032(ra) # 80003f18 <dirlink>
    80005328:	00054f63          	bltz	a0,80005346 <create+0x144>
    8000532c:	00492603          	lw	a2,4(s2)
    80005330:	00003597          	auipc	a1,0x3
    80005334:	e6858593          	addi	a1,a1,-408 # 80008198 <digits+0x168>
    80005338:	8526                	mv	a0,s1
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	bde080e7          	jalr	-1058(ra) # 80003f18 <dirlink>
    80005342:	f80557e3          	bgez	a0,800052d0 <create+0xce>
      panic("create dots");
    80005346:	00003517          	auipc	a0,0x3
    8000534a:	41250513          	addi	a0,a0,1042 # 80008758 <syscalls+0x2c8>
    8000534e:	ffffb097          	auipc	ra,0xffffb
    80005352:	1fa080e7          	jalr	506(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005356:	00003517          	auipc	a0,0x3
    8000535a:	41250513          	addi	a0,a0,1042 # 80008768 <syscalls+0x2d8>
    8000535e:	ffffb097          	auipc	ra,0xffffb
    80005362:	1ea080e7          	jalr	490(ra) # 80000548 <panic>
    return 0;
    80005366:	84aa                	mv	s1,a0
    80005368:	b731                	j	80005274 <create+0x72>

000000008000536a <sys_dup>:
{
    8000536a:	7179                	addi	sp,sp,-48
    8000536c:	f406                	sd	ra,40(sp)
    8000536e:	f022                	sd	s0,32(sp)
    80005370:	ec26                	sd	s1,24(sp)
    80005372:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005374:	fd840613          	addi	a2,s0,-40
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	ddc080e7          	jalr	-548(ra) # 80005158 <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005386:	02054363          	bltz	a0,800053ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000538a:	fd843503          	ld	a0,-40(s0)
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	e32080e7          	jalr	-462(ra) # 800051c0 <fdalloc>
    80005396:	84aa                	mv	s1,a0
    return -1;
    80005398:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000539a:	00054963          	bltz	a0,800053ac <sys_dup+0x42>
  filedup(f);
    8000539e:	fd843503          	ld	a0,-40(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	2c4080e7          	jalr	708(ra) # 80004666 <filedup>
  return fd;
    800053aa:	87a6                	mv	a5,s1
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	70a2                	ld	ra,40(sp)
    800053b0:	7402                	ld	s0,32(sp)
    800053b2:	64e2                	ld	s1,24(sp)
    800053b4:	6145                	addi	sp,sp,48
    800053b6:	8082                	ret

00000000800053b8 <sys_read>:
{
    800053b8:	7179                	addi	sp,sp,-48
    800053ba:	f406                	sd	ra,40(sp)
    800053bc:	f022                	sd	s0,32(sp)
    800053be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c0:	fe840613          	addi	a2,s0,-24
    800053c4:	4581                	li	a1,0
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	d90080e7          	jalr	-624(ra) # 80005158 <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d2:	04054163          	bltz	a0,80005414 <sys_read+0x5c>
    800053d6:	fe440593          	addi	a1,s0,-28
    800053da:	4509                	li	a0,2
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	8dc080e7          	jalr	-1828(ra) # 80002cb8 <argint>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e6:	02054763          	bltz	a0,80005414 <sys_read+0x5c>
    800053ea:	fd840593          	addi	a1,s0,-40
    800053ee:	4505                	li	a0,1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	8ea080e7          	jalr	-1814(ra) # 80002cda <argaddr>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fa:	00054d63          	bltz	a0,80005414 <sys_read+0x5c>
  return fileread(f, p, n);
    800053fe:	fe442603          	lw	a2,-28(s0)
    80005402:	fd843583          	ld	a1,-40(s0)
    80005406:	fe843503          	ld	a0,-24(s0)
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	3e8080e7          	jalr	1000(ra) # 800047f2 <fileread>
    80005412:	87aa                	mv	a5,a0
}
    80005414:	853e                	mv	a0,a5
    80005416:	70a2                	ld	ra,40(sp)
    80005418:	7402                	ld	s0,32(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret

000000008000541e <sys_write>:
{
    8000541e:	7179                	addi	sp,sp,-48
    80005420:	f406                	sd	ra,40(sp)
    80005422:	f022                	sd	s0,32(sp)
    80005424:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005426:	fe840613          	addi	a2,s0,-24
    8000542a:	4581                	li	a1,0
    8000542c:	4501                	li	a0,0
    8000542e:	00000097          	auipc	ra,0x0
    80005432:	d2a080e7          	jalr	-726(ra) # 80005158 <argfd>
    return -1;
    80005436:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005438:	04054163          	bltz	a0,8000547a <sys_write+0x5c>
    8000543c:	fe440593          	addi	a1,s0,-28
    80005440:	4509                	li	a0,2
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	876080e7          	jalr	-1930(ra) # 80002cb8 <argint>
    return -1;
    8000544a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544c:	02054763          	bltz	a0,8000547a <sys_write+0x5c>
    80005450:	fd840593          	addi	a1,s0,-40
    80005454:	4505                	li	a0,1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	884080e7          	jalr	-1916(ra) # 80002cda <argaddr>
    return -1;
    8000545e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005460:	00054d63          	bltz	a0,8000547a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005464:	fe442603          	lw	a2,-28(s0)
    80005468:	fd843583          	ld	a1,-40(s0)
    8000546c:	fe843503          	ld	a0,-24(s0)
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	444080e7          	jalr	1092(ra) # 800048b4 <filewrite>
    80005478:	87aa                	mv	a5,a0
}
    8000547a:	853e                	mv	a0,a5
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	6145                	addi	sp,sp,48
    80005482:	8082                	ret

0000000080005484 <sys_close>:
{
    80005484:	1101                	addi	sp,sp,-32
    80005486:	ec06                	sd	ra,24(sp)
    80005488:	e822                	sd	s0,16(sp)
    8000548a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000548c:	fe040613          	addi	a2,s0,-32
    80005490:	fec40593          	addi	a1,s0,-20
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	cc2080e7          	jalr	-830(ra) # 80005158 <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054a0:	02054463          	bltz	a0,800054c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	63e080e7          	jalr	1598(ra) # 80001ae2 <myproc>
    800054ac:	fec42783          	lw	a5,-20(s0)
    800054b0:	07e9                	addi	a5,a5,26
    800054b2:	078e                	slli	a5,a5,0x3
    800054b4:	97aa                	add	a5,a5,a0
    800054b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054ba:	fe043503          	ld	a0,-32(s0)
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	1fa080e7          	jalr	506(ra) # 800046b8 <fileclose>
  return 0;
    800054c6:	4781                	li	a5,0
}
    800054c8:	853e                	mv	a0,a5
    800054ca:	60e2                	ld	ra,24(sp)
    800054cc:	6442                	ld	s0,16(sp)
    800054ce:	6105                	addi	sp,sp,32
    800054d0:	8082                	ret

00000000800054d2 <sys_fstat>:
{
    800054d2:	1101                	addi	sp,sp,-32
    800054d4:	ec06                	sd	ra,24(sp)
    800054d6:	e822                	sd	s0,16(sp)
    800054d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054da:	fe840613          	addi	a2,s0,-24
    800054de:	4581                	li	a1,0
    800054e0:	4501                	li	a0,0
    800054e2:	00000097          	auipc	ra,0x0
    800054e6:	c76080e7          	jalr	-906(ra) # 80005158 <argfd>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ec:	02054563          	bltz	a0,80005516 <sys_fstat+0x44>
    800054f0:	fe040593          	addi	a1,s0,-32
    800054f4:	4505                	li	a0,1
    800054f6:	ffffd097          	auipc	ra,0xffffd
    800054fa:	7e4080e7          	jalr	2020(ra) # 80002cda <argaddr>
    return -1;
    800054fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005500:	00054b63          	bltz	a0,80005516 <sys_fstat+0x44>
  return filestat(f, st);
    80005504:	fe043583          	ld	a1,-32(s0)
    80005508:	fe843503          	ld	a0,-24(s0)
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	274080e7          	jalr	628(ra) # 80004780 <filestat>
    80005514:	87aa                	mv	a5,a0
}
    80005516:	853e                	mv	a0,a5
    80005518:	60e2                	ld	ra,24(sp)
    8000551a:	6442                	ld	s0,16(sp)
    8000551c:	6105                	addi	sp,sp,32
    8000551e:	8082                	ret

0000000080005520 <sys_link>:
{
    80005520:	7169                	addi	sp,sp,-304
    80005522:	f606                	sd	ra,296(sp)
    80005524:	f222                	sd	s0,288(sp)
    80005526:	ee26                	sd	s1,280(sp)
    80005528:	ea4a                	sd	s2,272(sp)
    8000552a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552c:	08000613          	li	a2,128
    80005530:	ed040593          	addi	a1,s0,-304
    80005534:	4501                	li	a0,0
    80005536:	ffffd097          	auipc	ra,0xffffd
    8000553a:	7c6080e7          	jalr	1990(ra) # 80002cfc <argstr>
    return -1;
    8000553e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005540:	10054e63          	bltz	a0,8000565c <sys_link+0x13c>
    80005544:	08000613          	li	a2,128
    80005548:	f5040593          	addi	a1,s0,-176
    8000554c:	4505                	li	a0,1
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	7ae080e7          	jalr	1966(ra) # 80002cfc <argstr>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005558:	10054263          	bltz	a0,8000565c <sys_link+0x13c>
  begin_op();
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	c8a080e7          	jalr	-886(ra) # 800041e6 <begin_op>
  if((ip = namei(old)) == 0){
    80005564:	ed040513          	addi	a0,s0,-304
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	a72080e7          	jalr	-1422(ra) # 80003fda <namei>
    80005570:	84aa                	mv	s1,a0
    80005572:	c551                	beqz	a0,800055fe <sys_link+0xde>
  ilock(ip);
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	2b6080e7          	jalr	694(ra) # 8000382a <ilock>
  if(ip->type == T_DIR){
    8000557c:	04449703          	lh	a4,68(s1)
    80005580:	4785                	li	a5,1
    80005582:	08f70463          	beq	a4,a5,8000560a <sys_link+0xea>
  ip->nlink++;
    80005586:	04a4d783          	lhu	a5,74(s1)
    8000558a:	2785                	addiw	a5,a5,1
    8000558c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005590:	8526                	mv	a0,s1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	1ce080e7          	jalr	462(ra) # 80003760 <iupdate>
  iunlock(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	350080e7          	jalr	848(ra) # 800038ec <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a4:	fd040593          	addi	a1,s0,-48
    800055a8:	f5040513          	addi	a0,s0,-176
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	a4c080e7          	jalr	-1460(ra) # 80003ff8 <nameiparent>
    800055b4:	892a                	mv	s2,a0
    800055b6:	c935                	beqz	a0,8000562a <sys_link+0x10a>
  ilock(dp);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	272080e7          	jalr	626(ra) # 8000382a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055c0:	00092703          	lw	a4,0(s2)
    800055c4:	409c                	lw	a5,0(s1)
    800055c6:	04f71d63          	bne	a4,a5,80005620 <sys_link+0x100>
    800055ca:	40d0                	lw	a2,4(s1)
    800055cc:	fd040593          	addi	a1,s0,-48
    800055d0:	854a                	mv	a0,s2
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	946080e7          	jalr	-1722(ra) # 80003f18 <dirlink>
    800055da:	04054363          	bltz	a0,80005620 <sys_link+0x100>
  iunlockput(dp);
    800055de:	854a                	mv	a0,s2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	4ac080e7          	jalr	1196(ra) # 80003a8c <iunlockput>
  iput(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	3fa080e7          	jalr	1018(ra) # 800039e4 <iput>
  end_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	c74080e7          	jalr	-908(ra) # 80004266 <end_op>
  return 0;
    800055fa:	4781                	li	a5,0
    800055fc:	a085                	j	8000565c <sys_link+0x13c>
    end_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	c68080e7          	jalr	-920(ra) # 80004266 <end_op>
    return -1;
    80005606:	57fd                	li	a5,-1
    80005608:	a891                	j	8000565c <sys_link+0x13c>
    iunlockput(ip);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	480080e7          	jalr	1152(ra) # 80003a8c <iunlockput>
    end_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	c52080e7          	jalr	-942(ra) # 80004266 <end_op>
    return -1;
    8000561c:	57fd                	li	a5,-1
    8000561e:	a83d                	j	8000565c <sys_link+0x13c>
    iunlockput(dp);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	46a080e7          	jalr	1130(ra) # 80003a8c <iunlockput>
  ilock(ip);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	1fe080e7          	jalr	510(ra) # 8000382a <ilock>
  ip->nlink--;
    80005634:	04a4d783          	lhu	a5,74(s1)
    80005638:	37fd                	addiw	a5,a5,-1
    8000563a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563e:	8526                	mv	a0,s1
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	120080e7          	jalr	288(ra) # 80003760 <iupdate>
  iunlockput(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	442080e7          	jalr	1090(ra) # 80003a8c <iunlockput>
  end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	c14080e7          	jalr	-1004(ra) # 80004266 <end_op>
  return -1;
    8000565a:	57fd                	li	a5,-1
}
    8000565c:	853e                	mv	a0,a5
    8000565e:	70b2                	ld	ra,296(sp)
    80005660:	7412                	ld	s0,288(sp)
    80005662:	64f2                	ld	s1,280(sp)
    80005664:	6952                	ld	s2,272(sp)
    80005666:	6155                	addi	sp,sp,304
    80005668:	8082                	ret

000000008000566a <sys_unlink>:
{
    8000566a:	7151                	addi	sp,sp,-240
    8000566c:	f586                	sd	ra,232(sp)
    8000566e:	f1a2                	sd	s0,224(sp)
    80005670:	eda6                	sd	s1,216(sp)
    80005672:	e9ca                	sd	s2,208(sp)
    80005674:	e5ce                	sd	s3,200(sp)
    80005676:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005678:	08000613          	li	a2,128
    8000567c:	f3040593          	addi	a1,s0,-208
    80005680:	4501                	li	a0,0
    80005682:	ffffd097          	auipc	ra,0xffffd
    80005686:	67a080e7          	jalr	1658(ra) # 80002cfc <argstr>
    8000568a:	18054163          	bltz	a0,8000580c <sys_unlink+0x1a2>
  begin_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	b58080e7          	jalr	-1192(ra) # 800041e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005696:	fb040593          	addi	a1,s0,-80
    8000569a:	f3040513          	addi	a0,s0,-208
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	95a080e7          	jalr	-1702(ra) # 80003ff8 <nameiparent>
    800056a6:	84aa                	mv	s1,a0
    800056a8:	c979                	beqz	a0,8000577e <sys_unlink+0x114>
  ilock(dp);
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	180080e7          	jalr	384(ra) # 8000382a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b2:	00003597          	auipc	a1,0x3
    800056b6:	09e58593          	addi	a1,a1,158 # 80008750 <syscalls+0x2c0>
    800056ba:	fb040513          	addi	a0,s0,-80
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	630080e7          	jalr	1584(ra) # 80003cee <namecmp>
    800056c6:	14050a63          	beqz	a0,8000581a <sys_unlink+0x1b0>
    800056ca:	00003597          	auipc	a1,0x3
    800056ce:	ace58593          	addi	a1,a1,-1330 # 80008198 <digits+0x168>
    800056d2:	fb040513          	addi	a0,s0,-80
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	618080e7          	jalr	1560(ra) # 80003cee <namecmp>
    800056de:	12050e63          	beqz	a0,8000581a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e2:	f2c40613          	addi	a2,s0,-212
    800056e6:	fb040593          	addi	a1,s0,-80
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	61c080e7          	jalr	1564(ra) # 80003d08 <dirlookup>
    800056f4:	892a                	mv	s2,a0
    800056f6:	12050263          	beqz	a0,8000581a <sys_unlink+0x1b0>
  ilock(ip);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	130080e7          	jalr	304(ra) # 8000382a <ilock>
  if(ip->nlink < 1)
    80005702:	04a91783          	lh	a5,74(s2)
    80005706:	08f05263          	blez	a5,8000578a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000570a:	04491703          	lh	a4,68(s2)
    8000570e:	4785                	li	a5,1
    80005710:	08f70563          	beq	a4,a5,8000579a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005714:	4641                	li	a2,16
    80005716:	4581                	li	a1,0
    80005718:	fc040513          	addi	a0,s0,-64
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	5f0080e7          	jalr	1520(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005724:	4741                	li	a4,16
    80005726:	f2c42683          	lw	a3,-212(s0)
    8000572a:	fc040613          	addi	a2,s0,-64
    8000572e:	4581                	li	a1,0
    80005730:	8526                	mv	a0,s1
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	4a2080e7          	jalr	1186(ra) # 80003bd4 <writei>
    8000573a:	47c1                	li	a5,16
    8000573c:	0af51563          	bne	a0,a5,800057e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005740:	04491703          	lh	a4,68(s2)
    80005744:	4785                	li	a5,1
    80005746:	0af70863          	beq	a4,a5,800057f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	340080e7          	jalr	832(ra) # 80003a8c <iunlockput>
  ip->nlink--;
    80005754:	04a95783          	lhu	a5,74(s2)
    80005758:	37fd                	addiw	a5,a5,-1
    8000575a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	000080e7          	jalr	ra # 80003760 <iupdate>
  iunlockput(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	322080e7          	jalr	802(ra) # 80003a8c <iunlockput>
  end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	af4080e7          	jalr	-1292(ra) # 80004266 <end_op>
  return 0;
    8000577a:	4501                	li	a0,0
    8000577c:	a84d                	j	8000582e <sys_unlink+0x1c4>
    end_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	ae8080e7          	jalr	-1304(ra) # 80004266 <end_op>
    return -1;
    80005786:	557d                	li	a0,-1
    80005788:	a05d                	j	8000582e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000578a:	00003517          	auipc	a0,0x3
    8000578e:	fee50513          	addi	a0,a0,-18 # 80008778 <syscalls+0x2e8>
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	db6080e7          	jalr	-586(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000579a:	04c92703          	lw	a4,76(s2)
    8000579e:	02000793          	li	a5,32
    800057a2:	f6e7f9e3          	bgeu	a5,a4,80005714 <sys_unlink+0xaa>
    800057a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057aa:	4741                	li	a4,16
    800057ac:	86ce                	mv	a3,s3
    800057ae:	f1840613          	addi	a2,s0,-232
    800057b2:	4581                	li	a1,0
    800057b4:	854a                	mv	a0,s2
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	328080e7          	jalr	808(ra) # 80003ade <readi>
    800057be:	47c1                	li	a5,16
    800057c0:	00f51b63          	bne	a0,a5,800057d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c4:	f1845783          	lhu	a5,-232(s0)
    800057c8:	e7a1                	bnez	a5,80005810 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ca:	29c1                	addiw	s3,s3,16
    800057cc:	04c92783          	lw	a5,76(s2)
    800057d0:	fcf9ede3          	bltu	s3,a5,800057aa <sys_unlink+0x140>
    800057d4:	b781                	j	80005714 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057d6:	00003517          	auipc	a0,0x3
    800057da:	fba50513          	addi	a0,a0,-70 # 80008790 <syscalls+0x300>
    800057de:	ffffb097          	auipc	ra,0xffffb
    800057e2:	d6a080e7          	jalr	-662(ra) # 80000548 <panic>
    panic("unlink: writei");
    800057e6:	00003517          	auipc	a0,0x3
    800057ea:	fc250513          	addi	a0,a0,-62 # 800087a8 <syscalls+0x318>
    800057ee:	ffffb097          	auipc	ra,0xffffb
    800057f2:	d5a080e7          	jalr	-678(ra) # 80000548 <panic>
    dp->nlink--;
    800057f6:	04a4d783          	lhu	a5,74(s1)
    800057fa:	37fd                	addiw	a5,a5,-1
    800057fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	f5e080e7          	jalr	-162(ra) # 80003760 <iupdate>
    8000580a:	b781                	j	8000574a <sys_unlink+0xe0>
    return -1;
    8000580c:	557d                	li	a0,-1
    8000580e:	a005                	j	8000582e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005810:	854a                	mv	a0,s2
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	27a080e7          	jalr	634(ra) # 80003a8c <iunlockput>
  iunlockput(dp);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	270080e7          	jalr	624(ra) # 80003a8c <iunlockput>
  end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	a42080e7          	jalr	-1470(ra) # 80004266 <end_op>
  return -1;
    8000582c:	557d                	li	a0,-1
}
    8000582e:	70ae                	ld	ra,232(sp)
    80005830:	740e                	ld	s0,224(sp)
    80005832:	64ee                	ld	s1,216(sp)
    80005834:	694e                	ld	s2,208(sp)
    80005836:	69ae                	ld	s3,200(sp)
    80005838:	616d                	addi	sp,sp,240
    8000583a:	8082                	ret

000000008000583c <sys_open>:

uint64
sys_open(void)
{
    8000583c:	7131                	addi	sp,sp,-192
    8000583e:	fd06                	sd	ra,184(sp)
    80005840:	f922                	sd	s0,176(sp)
    80005842:	f526                	sd	s1,168(sp)
    80005844:	f14a                	sd	s2,160(sp)
    80005846:	ed4e                	sd	s3,152(sp)
    80005848:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000584a:	08000613          	li	a2,128
    8000584e:	f5040593          	addi	a1,s0,-176
    80005852:	4501                	li	a0,0
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	4a8080e7          	jalr	1192(ra) # 80002cfc <argstr>
    return -1;
    8000585c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000585e:	0c054163          	bltz	a0,80005920 <sys_open+0xe4>
    80005862:	f4c40593          	addi	a1,s0,-180
    80005866:	4505                	li	a0,1
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	450080e7          	jalr	1104(ra) # 80002cb8 <argint>
    80005870:	0a054863          	bltz	a0,80005920 <sys_open+0xe4>

  begin_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	972080e7          	jalr	-1678(ra) # 800041e6 <begin_op>

  if(omode & O_CREATE){
    8000587c:	f4c42783          	lw	a5,-180(s0)
    80005880:	2007f793          	andi	a5,a5,512
    80005884:	cbdd                	beqz	a5,8000593a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005886:	4681                	li	a3,0
    80005888:	4601                	li	a2,0
    8000588a:	4589                	li	a1,2
    8000588c:	f5040513          	addi	a0,s0,-176
    80005890:	00000097          	auipc	ra,0x0
    80005894:	972080e7          	jalr	-1678(ra) # 80005202 <create>
    80005898:	892a                	mv	s2,a0
    if(ip == 0){
    8000589a:	c959                	beqz	a0,80005930 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000589c:	04491703          	lh	a4,68(s2)
    800058a0:	478d                	li	a5,3
    800058a2:	00f71763          	bne	a4,a5,800058b0 <sys_open+0x74>
    800058a6:	04695703          	lhu	a4,70(s2)
    800058aa:	47a5                	li	a5,9
    800058ac:	0ce7ec63          	bltu	a5,a4,80005984 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	d4c080e7          	jalr	-692(ra) # 800045fc <filealloc>
    800058b8:	89aa                	mv	s3,a0
    800058ba:	10050263          	beqz	a0,800059be <sys_open+0x182>
    800058be:	00000097          	auipc	ra,0x0
    800058c2:	902080e7          	jalr	-1790(ra) # 800051c0 <fdalloc>
    800058c6:	84aa                	mv	s1,a0
    800058c8:	0e054663          	bltz	a0,800059b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058cc:	04491703          	lh	a4,68(s2)
    800058d0:	478d                	li	a5,3
    800058d2:	0cf70463          	beq	a4,a5,8000599a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058d6:	4789                	li	a5,2
    800058d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e4:	f4c42783          	lw	a5,-180(s0)
    800058e8:	0017c713          	xori	a4,a5,1
    800058ec:	8b05                	andi	a4,a4,1
    800058ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f2:	0037f713          	andi	a4,a5,3
    800058f6:	00e03733          	snez	a4,a4
    800058fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058fe:	4007f793          	andi	a5,a5,1024
    80005902:	c791                	beqz	a5,8000590e <sys_open+0xd2>
    80005904:	04491703          	lh	a4,68(s2)
    80005908:	4789                	li	a5,2
    8000590a:	08f70f63          	beq	a4,a5,800059a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	fdc080e7          	jalr	-36(ra) # 800038ec <iunlock>
  end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	94e080e7          	jalr	-1714(ra) # 80004266 <end_op>

  return fd;
}
    80005920:	8526                	mv	a0,s1
    80005922:	70ea                	ld	ra,184(sp)
    80005924:	744a                	ld	s0,176(sp)
    80005926:	74aa                	ld	s1,168(sp)
    80005928:	790a                	ld	s2,160(sp)
    8000592a:	69ea                	ld	s3,152(sp)
    8000592c:	6129                	addi	sp,sp,192
    8000592e:	8082                	ret
      end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	936080e7          	jalr	-1738(ra) # 80004266 <end_op>
      return -1;
    80005938:	b7e5                	j	80005920 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000593a:	f5040513          	addi	a0,s0,-176
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	69c080e7          	jalr	1692(ra) # 80003fda <namei>
    80005946:	892a                	mv	s2,a0
    80005948:	c905                	beqz	a0,80005978 <sys_open+0x13c>
    ilock(ip);
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	ee0080e7          	jalr	-288(ra) # 8000382a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005952:	04491703          	lh	a4,68(s2)
    80005956:	4785                	li	a5,1
    80005958:	f4f712e3          	bne	a4,a5,8000589c <sys_open+0x60>
    8000595c:	f4c42783          	lw	a5,-180(s0)
    80005960:	dba1                	beqz	a5,800058b0 <sys_open+0x74>
      iunlockput(ip);
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	128080e7          	jalr	296(ra) # 80003a8c <iunlockput>
      end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	8fa080e7          	jalr	-1798(ra) # 80004266 <end_op>
      return -1;
    80005974:	54fd                	li	s1,-1
    80005976:	b76d                	j	80005920 <sys_open+0xe4>
      end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	8ee080e7          	jalr	-1810(ra) # 80004266 <end_op>
      return -1;
    80005980:	54fd                	li	s1,-1
    80005982:	bf79                	j	80005920 <sys_open+0xe4>
    iunlockput(ip);
    80005984:	854a                	mv	a0,s2
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	106080e7          	jalr	262(ra) # 80003a8c <iunlockput>
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	8d8080e7          	jalr	-1832(ra) # 80004266 <end_op>
    return -1;
    80005996:	54fd                	li	s1,-1
    80005998:	b761                	j	80005920 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000599a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000599e:	04691783          	lh	a5,70(s2)
    800059a2:	02f99223          	sh	a5,36(s3)
    800059a6:	bf2d                	j	800058e0 <sys_open+0xa4>
    itrunc(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	f8e080e7          	jalr	-114(ra) # 80003938 <itrunc>
    800059b2:	bfb1                	j	8000590e <sys_open+0xd2>
      fileclose(f);
    800059b4:	854e                	mv	a0,s3
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	d02080e7          	jalr	-766(ra) # 800046b8 <fileclose>
    iunlockput(ip);
    800059be:	854a                	mv	a0,s2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	0cc080e7          	jalr	204(ra) # 80003a8c <iunlockput>
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	89e080e7          	jalr	-1890(ra) # 80004266 <end_op>
    return -1;
    800059d0:	54fd                	li	s1,-1
    800059d2:	b7b9                	j	80005920 <sys_open+0xe4>

00000000800059d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d4:	7175                	addi	sp,sp,-144
    800059d6:	e506                	sd	ra,136(sp)
    800059d8:	e122                	sd	s0,128(sp)
    800059da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	80a080e7          	jalr	-2038(ra) # 800041e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e4:	08000613          	li	a2,128
    800059e8:	f7040593          	addi	a1,s0,-144
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	30e080e7          	jalr	782(ra) # 80002cfc <argstr>
    800059f6:	02054963          	bltz	a0,80005a28 <sys_mkdir+0x54>
    800059fa:	4681                	li	a3,0
    800059fc:	4601                	li	a2,0
    800059fe:	4585                	li	a1,1
    80005a00:	f7040513          	addi	a0,s0,-144
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	7fe080e7          	jalr	2046(ra) # 80005202 <create>
    80005a0c:	cd11                	beqz	a0,80005a28 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	07e080e7          	jalr	126(ra) # 80003a8c <iunlockput>
  end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	850080e7          	jalr	-1968(ra) # 80004266 <end_op>
  return 0;
    80005a1e:	4501                	li	a0,0
}
    80005a20:	60aa                	ld	ra,136(sp)
    80005a22:	640a                	ld	s0,128(sp)
    80005a24:	6149                	addi	sp,sp,144
    80005a26:	8082                	ret
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	83e080e7          	jalr	-1986(ra) # 80004266 <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	b7fd                	j	80005a20 <sys_mkdir+0x4c>

0000000080005a34 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a34:	7135                	addi	sp,sp,-160
    80005a36:	ed06                	sd	ra,152(sp)
    80005a38:	e922                	sd	s0,144(sp)
    80005a3a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7aa080e7          	jalr	1962(ra) # 800041e6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a44:	08000613          	li	a2,128
    80005a48:	f7040593          	addi	a1,s0,-144
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	2ae080e7          	jalr	686(ra) # 80002cfc <argstr>
    80005a56:	04054a63          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a5a:	f6c40593          	addi	a1,s0,-148
    80005a5e:	4505                	li	a0,1
    80005a60:	ffffd097          	auipc	ra,0xffffd
    80005a64:	258080e7          	jalr	600(ra) # 80002cb8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a68:	04054163          	bltz	a0,80005aaa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a6c:	f6840593          	addi	a1,s0,-152
    80005a70:	4509                	li	a0,2
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	246080e7          	jalr	582(ra) # 80002cb8 <argint>
     argint(1, &major) < 0 ||
    80005a7a:	02054863          	bltz	a0,80005aaa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a7e:	f6841683          	lh	a3,-152(s0)
    80005a82:	f6c41603          	lh	a2,-148(s0)
    80005a86:	458d                	li	a1,3
    80005a88:	f7040513          	addi	a0,s0,-144
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	776080e7          	jalr	1910(ra) # 80005202 <create>
     argint(2, &minor) < 0 ||
    80005a94:	c919                	beqz	a0,80005aaa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	ff6080e7          	jalr	-10(ra) # 80003a8c <iunlockput>
  end_op();
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	7c8080e7          	jalr	1992(ra) # 80004266 <end_op>
  return 0;
    80005aa6:	4501                	li	a0,0
    80005aa8:	a031                	j	80005ab4 <sys_mknod+0x80>
    end_op();
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	7bc080e7          	jalr	1980(ra) # 80004266 <end_op>
    return -1;
    80005ab2:	557d                	li	a0,-1
}
    80005ab4:	60ea                	ld	ra,152(sp)
    80005ab6:	644a                	ld	s0,144(sp)
    80005ab8:	610d                	addi	sp,sp,160
    80005aba:	8082                	ret

0000000080005abc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005abc:	7135                	addi	sp,sp,-160
    80005abe:	ed06                	sd	ra,152(sp)
    80005ac0:	e922                	sd	s0,144(sp)
    80005ac2:	e526                	sd	s1,136(sp)
    80005ac4:	e14a                	sd	s2,128(sp)
    80005ac6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ac8:	ffffc097          	auipc	ra,0xffffc
    80005acc:	01a080e7          	jalr	26(ra) # 80001ae2 <myproc>
    80005ad0:	892a                	mv	s2,a0
  
  begin_op();
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	714080e7          	jalr	1812(ra) # 800041e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ada:	08000613          	li	a2,128
    80005ade:	f6040593          	addi	a1,s0,-160
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	218080e7          	jalr	536(ra) # 80002cfc <argstr>
    80005aec:	04054b63          	bltz	a0,80005b42 <sys_chdir+0x86>
    80005af0:	f6040513          	addi	a0,s0,-160
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	4e6080e7          	jalr	1254(ra) # 80003fda <namei>
    80005afc:	84aa                	mv	s1,a0
    80005afe:	c131                	beqz	a0,80005b42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	d2a080e7          	jalr	-726(ra) # 8000382a <ilock>
  if(ip->type != T_DIR){
    80005b08:	04449703          	lh	a4,68(s1)
    80005b0c:	4785                	li	a5,1
    80005b0e:	04f71063          	bne	a4,a5,80005b4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	dd8080e7          	jalr	-552(ra) # 800038ec <iunlock>
  iput(p->cwd);
    80005b1c:	15093503          	ld	a0,336(s2)
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	ec4080e7          	jalr	-316(ra) # 800039e4 <iput>
  end_op();
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	73e080e7          	jalr	1854(ra) # 80004266 <end_op>
  p->cwd = ip;
    80005b30:	14993823          	sd	s1,336(s2)
  return 0;
    80005b34:	4501                	li	a0,0
}
    80005b36:	60ea                	ld	ra,152(sp)
    80005b38:	644a                	ld	s0,144(sp)
    80005b3a:	64aa                	ld	s1,136(sp)
    80005b3c:	690a                	ld	s2,128(sp)
    80005b3e:	610d                	addi	sp,sp,160
    80005b40:	8082                	ret
    end_op();
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	724080e7          	jalr	1828(ra) # 80004266 <end_op>
    return -1;
    80005b4a:	557d                	li	a0,-1
    80005b4c:	b7ed                	j	80005b36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b4e:	8526                	mv	a0,s1
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	f3c080e7          	jalr	-196(ra) # 80003a8c <iunlockput>
    end_op();
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	70e080e7          	jalr	1806(ra) # 80004266 <end_op>
    return -1;
    80005b60:	557d                	li	a0,-1
    80005b62:	bfd1                	j	80005b36 <sys_chdir+0x7a>

0000000080005b64 <sys_exec>:

uint64
sys_exec(void)
{
    80005b64:	7145                	addi	sp,sp,-464
    80005b66:	e786                	sd	ra,456(sp)
    80005b68:	e3a2                	sd	s0,448(sp)
    80005b6a:	ff26                	sd	s1,440(sp)
    80005b6c:	fb4a                	sd	s2,432(sp)
    80005b6e:	f74e                	sd	s3,424(sp)
    80005b70:	f352                	sd	s4,416(sp)
    80005b72:	ef56                	sd	s5,408(sp)
    80005b74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b76:	08000613          	li	a2,128
    80005b7a:	f4040593          	addi	a1,s0,-192
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	17c080e7          	jalr	380(ra) # 80002cfc <argstr>
    return -1;
    80005b88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b8a:	0c054a63          	bltz	a0,80005c5e <sys_exec+0xfa>
    80005b8e:	e3840593          	addi	a1,s0,-456
    80005b92:	4505                	li	a0,1
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	146080e7          	jalr	326(ra) # 80002cda <argaddr>
    80005b9c:	0c054163          	bltz	a0,80005c5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ba0:	10000613          	li	a2,256
    80005ba4:	4581                	li	a1,0
    80005ba6:	e4040513          	addi	a0,s0,-448
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	162080e7          	jalr	354(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb6:	89a6                	mv	s3,s1
    80005bb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bba:	02000a13          	li	s4,32
    80005bbe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc2:	00391513          	slli	a0,s2,0x3
    80005bc6:	e3040593          	addi	a1,s0,-464
    80005bca:	e3843783          	ld	a5,-456(s0)
    80005bce:	953e                	add	a0,a0,a5
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	04e080e7          	jalr	78(ra) # 80002c1e <fetchaddr>
    80005bd8:	02054a63          	bltz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bdc:	e3043783          	ld	a5,-464(s0)
    80005be0:	c3b9                	beqz	a5,80005c26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	f3e080e7          	jalr	-194(ra) # 80000b20 <kalloc>
    80005bea:	85aa                	mv	a1,a0
    80005bec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf0:	cd11                	beqz	a0,80005c0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf2:	6605                	lui	a2,0x1
    80005bf4:	e3043503          	ld	a0,-464(s0)
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	078080e7          	jalr	120(ra) # 80002c70 <fetchstr>
    80005c00:	00054663          	bltz	a0,80005c0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c04:	0905                	addi	s2,s2,1
    80005c06:	09a1                	addi	s3,s3,8
    80005c08:	fb491be3          	bne	s2,s4,80005bbe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0c:	10048913          	addi	s2,s1,256
    80005c10:	6088                	ld	a0,0(s1)
    80005c12:	c529                	beqz	a0,80005c5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	e10080e7          	jalr	-496(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1c:	04a1                	addi	s1,s1,8
    80005c1e:	ff2499e3          	bne	s1,s2,80005c10 <sys_exec+0xac>
  return -1;
    80005c22:	597d                	li	s2,-1
    80005c24:	a82d                	j	80005c5e <sys_exec+0xfa>
      argv[i] = 0;
    80005c26:	0a8e                	slli	s5,s5,0x3
    80005c28:	fc040793          	addi	a5,s0,-64
    80005c2c:	9abe                	add	s5,s5,a5
    80005c2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c32:	e4040593          	addi	a1,s0,-448
    80005c36:	f4040513          	addi	a0,s0,-192
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	12e080e7          	jalr	302(ra) # 80004d68 <exec>
    80005c42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	10048993          	addi	s3,s1,256
    80005c48:	6088                	ld	a0,0(s1)
    80005c4a:	c911                	beqz	a0,80005c5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	dd8080e7          	jalr	-552(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	04a1                	addi	s1,s1,8
    80005c56:	ff3499e3          	bne	s1,s3,80005c48 <sys_exec+0xe4>
    80005c5a:	a011                	j	80005c5e <sys_exec+0xfa>
  return -1;
    80005c5c:	597d                	li	s2,-1
}
    80005c5e:	854a                	mv	a0,s2
    80005c60:	60be                	ld	ra,456(sp)
    80005c62:	641e                	ld	s0,448(sp)
    80005c64:	74fa                	ld	s1,440(sp)
    80005c66:	795a                	ld	s2,432(sp)
    80005c68:	79ba                	ld	s3,424(sp)
    80005c6a:	7a1a                	ld	s4,416(sp)
    80005c6c:	6afa                	ld	s5,408(sp)
    80005c6e:	6179                	addi	sp,sp,464
    80005c70:	8082                	ret

0000000080005c72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c72:	7139                	addi	sp,sp,-64
    80005c74:	fc06                	sd	ra,56(sp)
    80005c76:	f822                	sd	s0,48(sp)
    80005c78:	f426                	sd	s1,40(sp)
    80005c7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7c:	ffffc097          	auipc	ra,0xffffc
    80005c80:	e66080e7          	jalr	-410(ra) # 80001ae2 <myproc>
    80005c84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c86:	fd840593          	addi	a1,s0,-40
    80005c8a:	4501                	li	a0,0
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	04e080e7          	jalr	78(ra) # 80002cda <argaddr>
    return -1;
    80005c94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c96:	0e054063          	bltz	a0,80005d76 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c9a:	fc840593          	addi	a1,s0,-56
    80005c9e:	fd040513          	addi	a0,s0,-48
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	d6c080e7          	jalr	-660(ra) # 80004a0e <pipealloc>
    return -1;
    80005caa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cac:	0c054563          	bltz	a0,80005d76 <sys_pipe+0x104>
  fd0 = -1;
    80005cb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb4:	fd043503          	ld	a0,-48(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	508080e7          	jalr	1288(ra) # 800051c0 <fdalloc>
    80005cc0:	fca42223          	sw	a0,-60(s0)
    80005cc4:	08054c63          	bltz	a0,80005d5c <sys_pipe+0xea>
    80005cc8:	fc843503          	ld	a0,-56(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	4f4080e7          	jalr	1268(ra) # 800051c0 <fdalloc>
    80005cd4:	fca42023          	sw	a0,-64(s0)
    80005cd8:	06054863          	bltz	a0,80005d48 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cdc:	4691                	li	a3,4
    80005cde:	fc440613          	addi	a2,s0,-60
    80005ce2:	fd843583          	ld	a1,-40(s0)
    80005ce6:	68a8                	ld	a0,80(s1)
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	c66080e7          	jalr	-922(ra) # 8000194e <copyout>
    80005cf0:	02054063          	bltz	a0,80005d10 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf4:	4691                	li	a3,4
    80005cf6:	fc040613          	addi	a2,s0,-64
    80005cfa:	fd843583          	ld	a1,-40(s0)
    80005cfe:	0591                	addi	a1,a1,4
    80005d00:	68a8                	ld	a0,80(s1)
    80005d02:	ffffc097          	auipc	ra,0xffffc
    80005d06:	c4c080e7          	jalr	-948(ra) # 8000194e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d0c:	06055563          	bgez	a0,80005d76 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d10:	fc442783          	lw	a5,-60(s0)
    80005d14:	07e9                	addi	a5,a5,26
    80005d16:	078e                	slli	a5,a5,0x3
    80005d18:	97a6                	add	a5,a5,s1
    80005d1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d1e:	fc042503          	lw	a0,-64(s0)
    80005d22:	0569                	addi	a0,a0,26
    80005d24:	050e                	slli	a0,a0,0x3
    80005d26:	9526                	add	a0,a0,s1
    80005d28:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d2c:	fd043503          	ld	a0,-48(s0)
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	988080e7          	jalr	-1656(ra) # 800046b8 <fileclose>
    fileclose(wf);
    80005d38:	fc843503          	ld	a0,-56(s0)
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	97c080e7          	jalr	-1668(ra) # 800046b8 <fileclose>
    return -1;
    80005d44:	57fd                	li	a5,-1
    80005d46:	a805                	j	80005d76 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d48:	fc442783          	lw	a5,-60(s0)
    80005d4c:	0007c863          	bltz	a5,80005d5c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d50:	01a78513          	addi	a0,a5,26
    80005d54:	050e                	slli	a0,a0,0x3
    80005d56:	9526                	add	a0,a0,s1
    80005d58:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d5c:	fd043503          	ld	a0,-48(s0)
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	958080e7          	jalr	-1704(ra) # 800046b8 <fileclose>
    fileclose(wf);
    80005d68:	fc843503          	ld	a0,-56(s0)
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	94c080e7          	jalr	-1716(ra) # 800046b8 <fileclose>
    return -1;
    80005d74:	57fd                	li	a5,-1
}
    80005d76:	853e                	mv	a0,a5
    80005d78:	70e2                	ld	ra,56(sp)
    80005d7a:	7442                	ld	s0,48(sp)
    80005d7c:	74a2                	ld	s1,40(sp)
    80005d7e:	6121                	addi	sp,sp,64
    80005d80:	8082                	ret
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	d1bfc0ef          	jal	ra,80002aea <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	710c                	ld	a1,32(a0)
    80005e2c:	7510                	ld	a2,40(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	c4e080e7          	jalr	-946(ra) # 80001ab6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	c16080e7          	jalr	-1002(ra) # 80001ab6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	bee080e7          	jalr	-1042(ra) # 80001ab6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	04a7cc63          	blt	a5,a0,80005f48 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	10c78793          	addi	a5,a5,268 # 80023000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	eba1                	bnez	a5,80005f58 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451713          	slli	a4,a0,0x4
    80005f0e:	0001f797          	auipc	a5,0x1f
    80005f12:	0f27b783          	ld	a5,242(a5) # 80025000 <disk+0x2000>
    80005f16:	97ba                	add	a5,a5,a4
    80005f18:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f1c:	0001d797          	auipc	a5,0x1d
    80005f20:	0e478793          	addi	a5,a5,228 # 80023000 <disk>
    80005f24:	97aa                	add	a5,a5,a0
    80005f26:	6509                	lui	a0,0x2
    80005f28:	953e                	add	a0,a0,a5
    80005f2a:	4785                	li	a5,1
    80005f2c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f30:	0001f517          	auipc	a0,0x1f
    80005f34:	0e850513          	addi	a0,a0,232 # 80025018 <disk+0x2018>
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	658080e7          	jalr	1624(ra) # 80002590 <wakeup>
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	87050513          	addi	a0,a0,-1936 # 800087b8 <syscalls+0x328>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5f8080e7          	jalr	1528(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005f58:	00003517          	auipc	a0,0x3
    80005f5c:	87850513          	addi	a0,a0,-1928 # 800087d0 <syscalls+0x340>
    80005f60:	ffffa097          	auipc	ra,0xffffa
    80005f64:	5e8080e7          	jalr	1512(ra) # 80000548 <panic>

0000000080005f68 <virtio_disk_init>:
{
    80005f68:	1101                	addi	sp,sp,-32
    80005f6a:	ec06                	sd	ra,24(sp)
    80005f6c:	e822                	sd	s0,16(sp)
    80005f6e:	e426                	sd	s1,8(sp)
    80005f70:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f72:	00003597          	auipc	a1,0x3
    80005f76:	87658593          	addi	a1,a1,-1930 # 800087e8 <syscalls+0x358>
    80005f7a:	0001f517          	auipc	a0,0x1f
    80005f7e:	12e50513          	addi	a0,a0,302 # 800250a8 <disk+0x20a8>
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	bfe080e7          	jalr	-1026(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f8a:	100017b7          	lui	a5,0x10001
    80005f8e:	4398                	lw	a4,0(a5)
    80005f90:	2701                	sext.w	a4,a4
    80005f92:	747277b7          	lui	a5,0x74727
    80005f96:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f9a:	0ef71163          	bne	a4,a5,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	43dc                	lw	a5,4(a5)
    80005fa4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa6:	4705                	li	a4,1
    80005fa8:	0ce79a63          	bne	a5,a4,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fac:	100017b7          	lui	a5,0x10001
    80005fb0:	479c                	lw	a5,8(a5)
    80005fb2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb4:	4709                	li	a4,2
    80005fb6:	0ce79363          	bne	a5,a4,8000607c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fba:	100017b7          	lui	a5,0x10001
    80005fbe:	47d8                	lw	a4,12(a5)
    80005fc0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc2:	554d47b7          	lui	a5,0x554d4
    80005fc6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fca:	0af71963          	bne	a4,a5,8000607c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	4705                	li	a4,1
    80005fd4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fd6:	470d                	li	a4,3
    80005fd8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fda:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fdc:	c7ffe737          	lui	a4,0xc7ffe
    80005fe0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80005fe4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fe6:	2701                	sext.w	a4,a4
    80005fe8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fea:	472d                	li	a4,11
    80005fec:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	473d                	li	a4,15
    80005ff0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ff2:	6705                	lui	a4,0x1
    80005ff4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ff6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ffa:	5bdc                	lw	a5,52(a5)
    80005ffc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ffe:	c7d9                	beqz	a5,8000608c <virtio_disk_init+0x124>
  if(max < NUM)
    80006000:	471d                	li	a4,7
    80006002:	08f77d63          	bgeu	a4,a5,8000609c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006006:	100014b7          	lui	s1,0x10001
    8000600a:	47a1                	li	a5,8
    8000600c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000600e:	6609                	lui	a2,0x2
    80006010:	4581                	li	a1,0
    80006012:	0001d517          	auipc	a0,0x1d
    80006016:	fee50513          	addi	a0,a0,-18 # 80023000 <disk>
    8000601a:	ffffb097          	auipc	ra,0xffffb
    8000601e:	cf2080e7          	jalr	-782(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006022:	0001d717          	auipc	a4,0x1d
    80006026:	fde70713          	addi	a4,a4,-34 # 80023000 <disk>
    8000602a:	00c75793          	srli	a5,a4,0xc
    8000602e:	2781                	sext.w	a5,a5
    80006030:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006032:	0001f797          	auipc	a5,0x1f
    80006036:	fce78793          	addi	a5,a5,-50 # 80025000 <disk+0x2000>
    8000603a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000603c:	0001d717          	auipc	a4,0x1d
    80006040:	04470713          	addi	a4,a4,68 # 80023080 <disk+0x80>
    80006044:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006046:	0001e717          	auipc	a4,0x1e
    8000604a:	fba70713          	addi	a4,a4,-70 # 80024000 <disk+0x1000>
    8000604e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006050:	4705                	li	a4,1
    80006052:	00e78c23          	sb	a4,24(a5)
    80006056:	00e78ca3          	sb	a4,25(a5)
    8000605a:	00e78d23          	sb	a4,26(a5)
    8000605e:	00e78da3          	sb	a4,27(a5)
    80006062:	00e78e23          	sb	a4,28(a5)
    80006066:	00e78ea3          	sb	a4,29(a5)
    8000606a:	00e78f23          	sb	a4,30(a5)
    8000606e:	00e78fa3          	sb	a4,31(a5)
}
    80006072:	60e2                	ld	ra,24(sp)
    80006074:	6442                	ld	s0,16(sp)
    80006076:	64a2                	ld	s1,8(sp)
    80006078:	6105                	addi	sp,sp,32
    8000607a:	8082                	ret
    panic("could not find virtio disk");
    8000607c:	00002517          	auipc	a0,0x2
    80006080:	77c50513          	addi	a0,a0,1916 # 800087f8 <syscalls+0x368>
    80006084:	ffffa097          	auipc	ra,0xffffa
    80006088:	4c4080e7          	jalr	1220(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000608c:	00002517          	auipc	a0,0x2
    80006090:	78c50513          	addi	a0,a0,1932 # 80008818 <syscalls+0x388>
    80006094:	ffffa097          	auipc	ra,0xffffa
    80006098:	4b4080e7          	jalr	1204(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000609c:	00002517          	auipc	a0,0x2
    800060a0:	79c50513          	addi	a0,a0,1948 # 80008838 <syscalls+0x3a8>
    800060a4:	ffffa097          	auipc	ra,0xffffa
    800060a8:	4a4080e7          	jalr	1188(ra) # 80000548 <panic>

00000000800060ac <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060ac:	7119                	addi	sp,sp,-128
    800060ae:	fc86                	sd	ra,120(sp)
    800060b0:	f8a2                	sd	s0,112(sp)
    800060b2:	f4a6                	sd	s1,104(sp)
    800060b4:	f0ca                	sd	s2,96(sp)
    800060b6:	ecce                	sd	s3,88(sp)
    800060b8:	e8d2                	sd	s4,80(sp)
    800060ba:	e4d6                	sd	s5,72(sp)
    800060bc:	e0da                	sd	s6,64(sp)
    800060be:	fc5e                	sd	s7,56(sp)
    800060c0:	f862                	sd	s8,48(sp)
    800060c2:	f466                	sd	s9,40(sp)
    800060c4:	f06a                	sd	s10,32(sp)
    800060c6:	0100                	addi	s0,sp,128
    800060c8:	892a                	mv	s2,a0
    800060ca:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060cc:	00c52c83          	lw	s9,12(a0)
    800060d0:	001c9c9b          	slliw	s9,s9,0x1
    800060d4:	1c82                	slli	s9,s9,0x20
    800060d6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060da:	0001f517          	auipc	a0,0x1f
    800060de:	fce50513          	addi	a0,a0,-50 # 800250a8 <disk+0x20a8>
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	b2e080e7          	jalr	-1234(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    800060ea:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060ec:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060ee:	0001db97          	auipc	s7,0x1d
    800060f2:	f12b8b93          	addi	s7,s7,-238 # 80023000 <disk>
    800060f6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060f8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060fa:	8a4e                	mv	s4,s3
    800060fc:	a051                	j	80006180 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060fe:	00fb86b3          	add	a3,s7,a5
    80006102:	96da                	add	a3,a3,s6
    80006104:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006108:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000610a:	0207c563          	bltz	a5,80006134 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000610e:	2485                	addiw	s1,s1,1
    80006110:	0711                	addi	a4,a4,4
    80006112:	25548363          	beq	s1,s5,80006358 <virtio_disk_rw+0x2ac>
    idx[i] = alloc_desc();
    80006116:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006118:	0001f697          	auipc	a3,0x1f
    8000611c:	f0068693          	addi	a3,a3,-256 # 80025018 <disk+0x2018>
    80006120:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006122:	0006c583          	lbu	a1,0(a3)
    80006126:	fde1                	bnez	a1,800060fe <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006128:	2785                	addiw	a5,a5,1
    8000612a:	0685                	addi	a3,a3,1
    8000612c:	ff879be3          	bne	a5,s8,80006122 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006130:	57fd                	li	a5,-1
    80006132:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006134:	02905a63          	blez	s1,80006168 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006138:	f9042503          	lw	a0,-112(s0)
    8000613c:	00000097          	auipc	ra,0x0
    80006140:	daa080e7          	jalr	-598(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006144:	4785                	li	a5,1
    80006146:	0297d163          	bge	a5,s1,80006168 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000614a:	f9442503          	lw	a0,-108(s0)
    8000614e:	00000097          	auipc	ra,0x0
    80006152:	d98080e7          	jalr	-616(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006156:	4789                	li	a5,2
    80006158:	0097d863          	bge	a5,s1,80006168 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000615c:	f9842503          	lw	a0,-104(s0)
    80006160:	00000097          	auipc	ra,0x0
    80006164:	d86080e7          	jalr	-634(ra) # 80005ee6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006168:	0001f597          	auipc	a1,0x1f
    8000616c:	f4058593          	addi	a1,a1,-192 # 800250a8 <disk+0x20a8>
    80006170:	0001f517          	auipc	a0,0x1f
    80006174:	ea850513          	addi	a0,a0,-344 # 80025018 <disk+0x2018>
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	292080e7          	jalr	658(ra) # 8000240a <sleep>
  for(int i = 0; i < 3; i++){
    80006180:	f9040713          	addi	a4,s0,-112
    80006184:	84ce                	mv	s1,s3
    80006186:	bf41                	j	80006116 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006188:	4785                	li	a5,1
    8000618a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000618e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006192:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa(myproc()->kernelpgt,(uint64) &buf0);
    80006196:	ffffc097          	auipc	ra,0xffffc
    8000619a:	94c080e7          	jalr	-1716(ra) # 80001ae2 <myproc>
    8000619e:	f9042983          	lw	s3,-112(s0)
    800061a2:	00499493          	slli	s1,s3,0x4
    800061a6:	0001fa17          	auipc	s4,0x1f
    800061aa:	e5aa0a13          	addi	s4,s4,-422 # 80025000 <disk+0x2000>
    800061ae:	000a3a83          	ld	s5,0(s4)
    800061b2:	9aa6                	add	s5,s5,s1
    800061b4:	f8040593          	addi	a1,s0,-128
    800061b8:	16853503          	ld	a0,360(a0)
    800061bc:	ffffb097          	auipc	ra,0xffffb
    800061c0:	eea080e7          	jalr	-278(ra) # 800010a6 <kvmpa>
    800061c4:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800061c8:	000a3783          	ld	a5,0(s4)
    800061cc:	97a6                	add	a5,a5,s1
    800061ce:	4741                	li	a4,16
    800061d0:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061d2:	000a3783          	ld	a5,0(s4)
    800061d6:	97a6                	add	a5,a5,s1
    800061d8:	4705                	li	a4,1
    800061da:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800061de:	f9442703          	lw	a4,-108(s0)
    800061e2:	000a3783          	ld	a5,0(s4)
    800061e6:	97a6                	add	a5,a5,s1
    800061e8:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061ec:	0712                	slli	a4,a4,0x4
    800061ee:	000a3783          	ld	a5,0(s4)
    800061f2:	97ba                	add	a5,a5,a4
    800061f4:	05890693          	addi	a3,s2,88
    800061f8:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800061fa:	000a3783          	ld	a5,0(s4)
    800061fe:	97ba                	add	a5,a5,a4
    80006200:	40000693          	li	a3,1024
    80006204:	c794                	sw	a3,8(a5)
  if(write)
    80006206:	100d0a63          	beqz	s10,8000631a <virtio_disk_rw+0x26e>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000620a:	0001f797          	auipc	a5,0x1f
    8000620e:	df67b783          	ld	a5,-522(a5) # 80025000 <disk+0x2000>
    80006212:	97ba                	add	a5,a5,a4
    80006214:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006218:	0001d517          	auipc	a0,0x1d
    8000621c:	de850513          	addi	a0,a0,-536 # 80023000 <disk>
    80006220:	0001f797          	auipc	a5,0x1f
    80006224:	de078793          	addi	a5,a5,-544 # 80025000 <disk+0x2000>
    80006228:	6394                	ld	a3,0(a5)
    8000622a:	96ba                	add	a3,a3,a4
    8000622c:	00c6d603          	lhu	a2,12(a3)
    80006230:	00166613          	ori	a2,a2,1
    80006234:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006238:	f9842683          	lw	a3,-104(s0)
    8000623c:	6390                	ld	a2,0(a5)
    8000623e:	9732                	add	a4,a4,a2
    80006240:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006244:	20098613          	addi	a2,s3,512
    80006248:	0612                	slli	a2,a2,0x4
    8000624a:	962a                	add	a2,a2,a0
    8000624c:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006250:	00469713          	slli	a4,a3,0x4
    80006254:	6394                	ld	a3,0(a5)
    80006256:	96ba                	add	a3,a3,a4
    80006258:	6589                	lui	a1,0x2
    8000625a:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    8000625e:	94ae                	add	s1,s1,a1
    80006260:	94aa                	add	s1,s1,a0
    80006262:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006264:	6394                	ld	a3,0(a5)
    80006266:	96ba                	add	a3,a3,a4
    80006268:	4585                	li	a1,1
    8000626a:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000626c:	6394                	ld	a3,0(a5)
    8000626e:	96ba                	add	a3,a3,a4
    80006270:	4509                	li	a0,2
    80006272:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006276:	6394                	ld	a3,0(a5)
    80006278:	9736                	add	a4,a4,a3
    8000627a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000627e:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006282:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006286:	6794                	ld	a3,8(a5)
    80006288:	0026d703          	lhu	a4,2(a3)
    8000628c:	8b1d                	andi	a4,a4,7
    8000628e:	2709                	addiw	a4,a4,2
    80006290:	0706                	slli	a4,a4,0x1
    80006292:	9736                	add	a4,a4,a3
    80006294:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    80006298:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000629c:	6798                	ld	a4,8(a5)
    8000629e:	00275783          	lhu	a5,2(a4)
    800062a2:	2785                	addiw	a5,a5,1
    800062a4:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062a8:	100017b7          	lui	a5,0x10001
    800062ac:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062b0:	00492703          	lw	a4,4(s2)
    800062b4:	4785                	li	a5,1
    800062b6:	02f71163          	bne	a4,a5,800062d8 <virtio_disk_rw+0x22c>
    sleep(b, &disk.vdisk_lock);
    800062ba:	0001f997          	auipc	s3,0x1f
    800062be:	dee98993          	addi	s3,s3,-530 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062c2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062c4:	85ce                	mv	a1,s3
    800062c6:	854a                	mv	a0,s2
    800062c8:	ffffc097          	auipc	ra,0xffffc
    800062cc:	142080e7          	jalr	322(ra) # 8000240a <sleep>
  while(b->disk == 1) {
    800062d0:	00492783          	lw	a5,4(s2)
    800062d4:	fe9788e3          	beq	a5,s1,800062c4 <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    800062d8:	f9042483          	lw	s1,-112(s0)
    800062dc:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800062e0:	00479713          	slli	a4,a5,0x4
    800062e4:	0001d797          	auipc	a5,0x1d
    800062e8:	d1c78793          	addi	a5,a5,-740 # 80023000 <disk>
    800062ec:	97ba                	add	a5,a5,a4
    800062ee:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062f2:	0001f917          	auipc	s2,0x1f
    800062f6:	d0e90913          	addi	s2,s2,-754 # 80025000 <disk+0x2000>
    free_desc(i);
    800062fa:	8526                	mv	a0,s1
    800062fc:	00000097          	auipc	ra,0x0
    80006300:	bea080e7          	jalr	-1046(ra) # 80005ee6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006304:	0492                	slli	s1,s1,0x4
    80006306:	00093783          	ld	a5,0(s2)
    8000630a:	94be                	add	s1,s1,a5
    8000630c:	00c4d783          	lhu	a5,12(s1)
    80006310:	8b85                	andi	a5,a5,1
    80006312:	cf89                	beqz	a5,8000632c <virtio_disk_rw+0x280>
      i = disk.desc[i].next;
    80006314:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006318:	b7cd                	j	800062fa <virtio_disk_rw+0x24e>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000631a:	0001f797          	auipc	a5,0x1f
    8000631e:	ce67b783          	ld	a5,-794(a5) # 80025000 <disk+0x2000>
    80006322:	97ba                	add	a5,a5,a4
    80006324:	4689                	li	a3,2
    80006326:	00d79623          	sh	a3,12(a5)
    8000632a:	b5fd                	j	80006218 <virtio_disk_rw+0x16c>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000632c:	0001f517          	auipc	a0,0x1f
    80006330:	d7c50513          	addi	a0,a0,-644 # 800250a8 <disk+0x20a8>
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	990080e7          	jalr	-1648(ra) # 80000cc4 <release>
}
    8000633c:	70e6                	ld	ra,120(sp)
    8000633e:	7446                	ld	s0,112(sp)
    80006340:	74a6                	ld	s1,104(sp)
    80006342:	7906                	ld	s2,96(sp)
    80006344:	69e6                	ld	s3,88(sp)
    80006346:	6a46                	ld	s4,80(sp)
    80006348:	6aa6                	ld	s5,72(sp)
    8000634a:	6b06                	ld	s6,64(sp)
    8000634c:	7be2                	ld	s7,56(sp)
    8000634e:	7c42                	ld	s8,48(sp)
    80006350:	7ca2                	ld	s9,40(sp)
    80006352:	7d02                	ld	s10,32(sp)
    80006354:	6109                	addi	sp,sp,128
    80006356:	8082                	ret
  if(write)
    80006358:	e20d18e3          	bnez	s10,80006188 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    8000635c:	f8042023          	sw	zero,-128(s0)
    80006360:	b53d                	j	8000618e <virtio_disk_rw+0xe2>

0000000080006362 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006362:	1101                	addi	sp,sp,-32
    80006364:	ec06                	sd	ra,24(sp)
    80006366:	e822                	sd	s0,16(sp)
    80006368:	e426                	sd	s1,8(sp)
    8000636a:	e04a                	sd	s2,0(sp)
    8000636c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000636e:	0001f517          	auipc	a0,0x1f
    80006372:	d3a50513          	addi	a0,a0,-710 # 800250a8 <disk+0x20a8>
    80006376:	ffffb097          	auipc	ra,0xffffb
    8000637a:	89a080e7          	jalr	-1894(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000637e:	0001f717          	auipc	a4,0x1f
    80006382:	c8270713          	addi	a4,a4,-894 # 80025000 <disk+0x2000>
    80006386:	02075783          	lhu	a5,32(a4)
    8000638a:	6b18                	ld	a4,16(a4)
    8000638c:	00275683          	lhu	a3,2(a4)
    80006390:	8ebd                	xor	a3,a3,a5
    80006392:	8a9d                	andi	a3,a3,7
    80006394:	cab9                	beqz	a3,800063ea <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006396:	0001d917          	auipc	s2,0x1d
    8000639a:	c6a90913          	addi	s2,s2,-918 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000639e:	0001f497          	auipc	s1,0x1f
    800063a2:	c6248493          	addi	s1,s1,-926 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063a6:	078e                	slli	a5,a5,0x3
    800063a8:	97ba                	add	a5,a5,a4
    800063aa:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800063ac:	20078713          	addi	a4,a5,512
    800063b0:	0712                	slli	a4,a4,0x4
    800063b2:	974a                	add	a4,a4,s2
    800063b4:	03074703          	lbu	a4,48(a4)
    800063b8:	ef21                	bnez	a4,80006410 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063ba:	20078793          	addi	a5,a5,512
    800063be:	0792                	slli	a5,a5,0x4
    800063c0:	97ca                	add	a5,a5,s2
    800063c2:	7798                	ld	a4,40(a5)
    800063c4:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063c8:	7788                	ld	a0,40(a5)
    800063ca:	ffffc097          	auipc	ra,0xffffc
    800063ce:	1c6080e7          	jalr	454(ra) # 80002590 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063d2:	0204d783          	lhu	a5,32(s1)
    800063d6:	2785                	addiw	a5,a5,1
    800063d8:	8b9d                	andi	a5,a5,7
    800063da:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063de:	6898                	ld	a4,16(s1)
    800063e0:	00275683          	lhu	a3,2(a4)
    800063e4:	8a9d                	andi	a3,a3,7
    800063e6:	fcf690e3          	bne	a3,a5,800063a6 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063ea:	10001737          	lui	a4,0x10001
    800063ee:	533c                	lw	a5,96(a4)
    800063f0:	8b8d                	andi	a5,a5,3
    800063f2:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063f4:	0001f517          	auipc	a0,0x1f
    800063f8:	cb450513          	addi	a0,a0,-844 # 800250a8 <disk+0x20a8>
    800063fc:	ffffb097          	auipc	ra,0xffffb
    80006400:	8c8080e7          	jalr	-1848(ra) # 80000cc4 <release>
}
    80006404:	60e2                	ld	ra,24(sp)
    80006406:	6442                	ld	s0,16(sp)
    80006408:	64a2                	ld	s1,8(sp)
    8000640a:	6902                	ld	s2,0(sp)
    8000640c:	6105                	addi	sp,sp,32
    8000640e:	8082                	ret
      panic("virtio_disk_intr status");
    80006410:	00002517          	auipc	a0,0x2
    80006414:	44850513          	addi	a0,a0,1096 # 80008858 <syscalls+0x3c8>
    80006418:	ffffa097          	auipc	ra,0xffffa
    8000641c:	130080e7          	jalr	304(ra) # 80000548 <panic>

0000000080006420 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006420:	7179                	addi	sp,sp,-48
    80006422:	f406                	sd	ra,40(sp)
    80006424:	f022                	sd	s0,32(sp)
    80006426:	ec26                	sd	s1,24(sp)
    80006428:	e84a                	sd	s2,16(sp)
    8000642a:	e44e                	sd	s3,8(sp)
    8000642c:	e052                	sd	s4,0(sp)
    8000642e:	1800                	addi	s0,sp,48
    80006430:	892a                	mv	s2,a0
    80006432:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006434:	00003a17          	auipc	s4,0x3
    80006438:	bf4a0a13          	addi	s4,s4,-1036 # 80009028 <stats>
    8000643c:	000a2683          	lw	a3,0(s4)
    80006440:	00002617          	auipc	a2,0x2
    80006444:	43060613          	addi	a2,a2,1072 # 80008870 <syscalls+0x3e0>
    80006448:	00000097          	auipc	ra,0x0
    8000644c:	2c2080e7          	jalr	706(ra) # 8000670a <snprintf>
    80006450:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006452:	004a2683          	lw	a3,4(s4)
    80006456:	00002617          	auipc	a2,0x2
    8000645a:	42a60613          	addi	a2,a2,1066 # 80008880 <syscalls+0x3f0>
    8000645e:	85ce                	mv	a1,s3
    80006460:	954a                	add	a0,a0,s2
    80006462:	00000097          	auipc	ra,0x0
    80006466:	2a8080e7          	jalr	680(ra) # 8000670a <snprintf>
  return n;
}
    8000646a:	9d25                	addw	a0,a0,s1
    8000646c:	70a2                	ld	ra,40(sp)
    8000646e:	7402                	ld	s0,32(sp)
    80006470:	64e2                	ld	s1,24(sp)
    80006472:	6942                	ld	s2,16(sp)
    80006474:	69a2                	ld	s3,8(sp)
    80006476:	6a02                	ld	s4,0(sp)
    80006478:	6145                	addi	sp,sp,48
    8000647a:	8082                	ret

000000008000647c <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    8000647c:	7179                	addi	sp,sp,-48
    8000647e:	f406                	sd	ra,40(sp)
    80006480:	f022                	sd	s0,32(sp)
    80006482:	ec26                	sd	s1,24(sp)
    80006484:	e84a                	sd	s2,16(sp)
    80006486:	e44e                	sd	s3,8(sp)
    80006488:	1800                	addi	s0,sp,48
    8000648a:	89ae                	mv	s3,a1
    8000648c:	84b2                	mv	s1,a2
    8000648e:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006490:	ffffb097          	auipc	ra,0xffffb
    80006494:	652080e7          	jalr	1618(ra) # 80001ae2 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    80006498:	653c                	ld	a5,72(a0)
    8000649a:	02f4ff63          	bgeu	s1,a5,800064d8 <copyin_new+0x5c>
    8000649e:	01248733          	add	a4,s1,s2
    800064a2:	02f77d63          	bgeu	a4,a5,800064dc <copyin_new+0x60>
    800064a6:	02976d63          	bltu	a4,s1,800064e0 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800064aa:	0009061b          	sext.w	a2,s2
    800064ae:	85a6                	mv	a1,s1
    800064b0:	854e                	mv	a0,s3
    800064b2:	ffffb097          	auipc	ra,0xffffb
    800064b6:	8ba080e7          	jalr	-1862(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    800064ba:	00003717          	auipc	a4,0x3
    800064be:	b6e70713          	addi	a4,a4,-1170 # 80009028 <stats>
    800064c2:	431c                	lw	a5,0(a4)
    800064c4:	2785                	addiw	a5,a5,1
    800064c6:	c31c                	sw	a5,0(a4)
  return 0;
    800064c8:	4501                	li	a0,0
}
    800064ca:	70a2                	ld	ra,40(sp)
    800064cc:	7402                	ld	s0,32(sp)
    800064ce:	64e2                	ld	s1,24(sp)
    800064d0:	6942                	ld	s2,16(sp)
    800064d2:	69a2                	ld	s3,8(sp)
    800064d4:	6145                	addi	sp,sp,48
    800064d6:	8082                	ret
    return -1;
    800064d8:	557d                	li	a0,-1
    800064da:	bfc5                	j	800064ca <copyin_new+0x4e>
    800064dc:	557d                	li	a0,-1
    800064de:	b7f5                	j	800064ca <copyin_new+0x4e>
    800064e0:	557d                	li	a0,-1
    800064e2:	b7e5                	j	800064ca <copyin_new+0x4e>

00000000800064e4 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800064e4:	7179                	addi	sp,sp,-48
    800064e6:	f406                	sd	ra,40(sp)
    800064e8:	f022                	sd	s0,32(sp)
    800064ea:	ec26                	sd	s1,24(sp)
    800064ec:	e84a                	sd	s2,16(sp)
    800064ee:	e44e                	sd	s3,8(sp)
    800064f0:	1800                	addi	s0,sp,48
    800064f2:	89ae                	mv	s3,a1
    800064f4:	8932                	mv	s2,a2
    800064f6:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    800064f8:	ffffb097          	auipc	ra,0xffffb
    800064fc:	5ea080e7          	jalr	1514(ra) # 80001ae2 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006500:	00003717          	auipc	a4,0x3
    80006504:	b2870713          	addi	a4,a4,-1240 # 80009028 <stats>
    80006508:	435c                	lw	a5,4(a4)
    8000650a:	2785                	addiw	a5,a5,1
    8000650c:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000650e:	cc85                	beqz	s1,80006546 <copyinstr_new+0x62>
    80006510:	00990833          	add	a6,s2,s1
    80006514:	87ca                	mv	a5,s2
    80006516:	6538                	ld	a4,72(a0)
    80006518:	00e7ff63          	bgeu	a5,a4,80006536 <copyinstr_new+0x52>
    dst[i] = s[i];
    8000651c:	0007c683          	lbu	a3,0(a5)
    80006520:	41278733          	sub	a4,a5,s2
    80006524:	974e                	add	a4,a4,s3
    80006526:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000652a:	c285                	beqz	a3,8000654a <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000652c:	0785                	addi	a5,a5,1
    8000652e:	ff0794e3          	bne	a5,a6,80006516 <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006532:	557d                	li	a0,-1
    80006534:	a011                	j	80006538 <copyinstr_new+0x54>
    80006536:	557d                	li	a0,-1
}
    80006538:	70a2                	ld	ra,40(sp)
    8000653a:	7402                	ld	s0,32(sp)
    8000653c:	64e2                	ld	s1,24(sp)
    8000653e:	6942                	ld	s2,16(sp)
    80006540:	69a2                	ld	s3,8(sp)
    80006542:	6145                	addi	sp,sp,48
    80006544:	8082                	ret
  return -1;
    80006546:	557d                	li	a0,-1
    80006548:	bfc5                	j	80006538 <copyinstr_new+0x54>
      return 0;
    8000654a:	4501                	li	a0,0
    8000654c:	b7f5                	j	80006538 <copyinstr_new+0x54>

000000008000654e <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    8000654e:	1141                	addi	sp,sp,-16
    80006550:	e422                	sd	s0,8(sp)
    80006552:	0800                	addi	s0,sp,16
  return -1;
}
    80006554:	557d                	li	a0,-1
    80006556:	6422                	ld	s0,8(sp)
    80006558:	0141                	addi	sp,sp,16
    8000655a:	8082                	ret

000000008000655c <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    8000655c:	7179                	addi	sp,sp,-48
    8000655e:	f406                	sd	ra,40(sp)
    80006560:	f022                	sd	s0,32(sp)
    80006562:	ec26                	sd	s1,24(sp)
    80006564:	e84a                	sd	s2,16(sp)
    80006566:	e44e                	sd	s3,8(sp)
    80006568:	e052                	sd	s4,0(sp)
    8000656a:	1800                	addi	s0,sp,48
    8000656c:	892a                	mv	s2,a0
    8000656e:	89ae                	mv	s3,a1
    80006570:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006572:	00020517          	auipc	a0,0x20
    80006576:	a8e50513          	addi	a0,a0,-1394 # 80026000 <stats>
    8000657a:	ffffa097          	auipc	ra,0xffffa
    8000657e:	696080e7          	jalr	1686(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006582:	00021797          	auipc	a5,0x21
    80006586:	a967a783          	lw	a5,-1386(a5) # 80027018 <stats+0x1018>
    8000658a:	cbb5                	beqz	a5,800065fe <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    8000658c:	00021797          	auipc	a5,0x21
    80006590:	a7478793          	addi	a5,a5,-1420 # 80027000 <stats+0x1000>
    80006594:	4fd8                	lw	a4,28(a5)
    80006596:	4f9c                	lw	a5,24(a5)
    80006598:	9f99                	subw	a5,a5,a4
    8000659a:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    8000659e:	06d05e63          	blez	a3,8000661a <statsread+0xbe>
    if(m > n)
    800065a2:	8a3e                	mv	s4,a5
    800065a4:	00d4d363          	bge	s1,a3,800065aa <statsread+0x4e>
    800065a8:	8a26                	mv	s4,s1
    800065aa:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800065ae:	86a6                	mv	a3,s1
    800065b0:	00020617          	auipc	a2,0x20
    800065b4:	a6860613          	addi	a2,a2,-1432 # 80026018 <stats+0x18>
    800065b8:	963a                	add	a2,a2,a4
    800065ba:	85ce                	mv	a1,s3
    800065bc:	854a                	mv	a0,s2
    800065be:	ffffc097          	auipc	ra,0xffffc
    800065c2:	0ae080e7          	jalr	174(ra) # 8000266c <either_copyout>
    800065c6:	57fd                	li	a5,-1
    800065c8:	00f50a63          	beq	a0,a5,800065dc <statsread+0x80>
      stats.off += m;
    800065cc:	00021717          	auipc	a4,0x21
    800065d0:	a3470713          	addi	a4,a4,-1484 # 80027000 <stats+0x1000>
    800065d4:	4f5c                	lw	a5,28(a4)
    800065d6:	014787bb          	addw	a5,a5,s4
    800065da:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800065dc:	00020517          	auipc	a0,0x20
    800065e0:	a2450513          	addi	a0,a0,-1500 # 80026000 <stats>
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	6e0080e7          	jalr	1760(ra) # 80000cc4 <release>
  return m;
}
    800065ec:	8526                	mv	a0,s1
    800065ee:	70a2                	ld	ra,40(sp)
    800065f0:	7402                	ld	s0,32(sp)
    800065f2:	64e2                	ld	s1,24(sp)
    800065f4:	6942                	ld	s2,16(sp)
    800065f6:	69a2                	ld	s3,8(sp)
    800065f8:	6a02                	ld	s4,0(sp)
    800065fa:	6145                	addi	sp,sp,48
    800065fc:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    800065fe:	6585                	lui	a1,0x1
    80006600:	00020517          	auipc	a0,0x20
    80006604:	a1850513          	addi	a0,a0,-1512 # 80026018 <stats+0x18>
    80006608:	00000097          	auipc	ra,0x0
    8000660c:	e18080e7          	jalr	-488(ra) # 80006420 <statscopyin>
    80006610:	00021797          	auipc	a5,0x21
    80006614:	a0a7a423          	sw	a0,-1528(a5) # 80027018 <stats+0x1018>
    80006618:	bf95                	j	8000658c <statsread+0x30>
    stats.sz = 0;
    8000661a:	00021797          	auipc	a5,0x21
    8000661e:	9e678793          	addi	a5,a5,-1562 # 80027000 <stats+0x1000>
    80006622:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006626:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000662a:	54fd                	li	s1,-1
    8000662c:	bf45                	j	800065dc <statsread+0x80>

000000008000662e <statsinit>:

void
statsinit(void)
{
    8000662e:	1141                	addi	sp,sp,-16
    80006630:	e406                	sd	ra,8(sp)
    80006632:	e022                	sd	s0,0(sp)
    80006634:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006636:	00002597          	auipc	a1,0x2
    8000663a:	25a58593          	addi	a1,a1,602 # 80008890 <syscalls+0x400>
    8000663e:	00020517          	auipc	a0,0x20
    80006642:	9c250513          	addi	a0,a0,-1598 # 80026000 <stats>
    80006646:	ffffa097          	auipc	ra,0xffffa
    8000664a:	53a080e7          	jalr	1338(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    8000664e:	0001b797          	auipc	a5,0x1b
    80006652:	56278793          	addi	a5,a5,1378 # 80021bb0 <devsw>
    80006656:	00000717          	auipc	a4,0x0
    8000665a:	f0670713          	addi	a4,a4,-250 # 8000655c <statsread>
    8000665e:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006660:	00000717          	auipc	a4,0x0
    80006664:	eee70713          	addi	a4,a4,-274 # 8000654e <statswrite>
    80006668:	f798                	sd	a4,40(a5)
}
    8000666a:	60a2                	ld	ra,8(sp)
    8000666c:	6402                	ld	s0,0(sp)
    8000666e:	0141                	addi	sp,sp,16
    80006670:	8082                	ret

0000000080006672 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006672:	1101                	addi	sp,sp,-32
    80006674:	ec22                	sd	s0,24(sp)
    80006676:	1000                	addi	s0,sp,32
    80006678:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000667a:	c299                	beqz	a3,80006680 <sprintint+0xe>
    8000667c:	0805c163          	bltz	a1,800066fe <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006680:	2581                	sext.w	a1,a1
    80006682:	4301                	li	t1,0

  i = 0;
    80006684:	fe040713          	addi	a4,s0,-32
    80006688:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000668a:	2601                	sext.w	a2,a2
    8000668c:	00002697          	auipc	a3,0x2
    80006690:	20c68693          	addi	a3,a3,524 # 80008898 <digits>
    80006694:	88aa                	mv	a7,a0
    80006696:	2505                	addiw	a0,a0,1
    80006698:	02c5f7bb          	remuw	a5,a1,a2
    8000669c:	1782                	slli	a5,a5,0x20
    8000669e:	9381                	srli	a5,a5,0x20
    800066a0:	97b6                	add	a5,a5,a3
    800066a2:	0007c783          	lbu	a5,0(a5)
    800066a6:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800066aa:	0005879b          	sext.w	a5,a1
    800066ae:	02c5d5bb          	divuw	a1,a1,a2
    800066b2:	0705                	addi	a4,a4,1
    800066b4:	fec7f0e3          	bgeu	a5,a2,80006694 <sprintint+0x22>

  if(sign)
    800066b8:	00030b63          	beqz	t1,800066ce <sprintint+0x5c>
    buf[i++] = '-';
    800066bc:	ff040793          	addi	a5,s0,-16
    800066c0:	97aa                	add	a5,a5,a0
    800066c2:	02d00713          	li	a4,45
    800066c6:	fee78823          	sb	a4,-16(a5)
    800066ca:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800066ce:	02a05c63          	blez	a0,80006706 <sprintint+0x94>
    800066d2:	fe040793          	addi	a5,s0,-32
    800066d6:	00a78733          	add	a4,a5,a0
    800066da:	87c2                	mv	a5,a6
    800066dc:	0805                	addi	a6,a6,1
    800066de:	fff5061b          	addiw	a2,a0,-1
    800066e2:	1602                	slli	a2,a2,0x20
    800066e4:	9201                	srli	a2,a2,0x20
    800066e6:	9642                	add	a2,a2,a6
  *s = c;
    800066e8:	fff74683          	lbu	a3,-1(a4)
    800066ec:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800066f0:	177d                	addi	a4,a4,-1
    800066f2:	0785                	addi	a5,a5,1
    800066f4:	fec79ae3          	bne	a5,a2,800066e8 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    800066f8:	6462                	ld	s0,24(sp)
    800066fa:	6105                	addi	sp,sp,32
    800066fc:	8082                	ret
    x = -xx;
    800066fe:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006702:	4305                	li	t1,1
    x = -xx;
    80006704:	b741                	j	80006684 <sprintint+0x12>
  while(--i >= 0)
    80006706:	4501                	li	a0,0
    80006708:	bfc5                	j	800066f8 <sprintint+0x86>

000000008000670a <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000670a:	7171                	addi	sp,sp,-176
    8000670c:	fc86                	sd	ra,120(sp)
    8000670e:	f8a2                	sd	s0,112(sp)
    80006710:	f4a6                	sd	s1,104(sp)
    80006712:	f0ca                	sd	s2,96(sp)
    80006714:	ecce                	sd	s3,88(sp)
    80006716:	e8d2                	sd	s4,80(sp)
    80006718:	e4d6                	sd	s5,72(sp)
    8000671a:	e0da                	sd	s6,64(sp)
    8000671c:	fc5e                	sd	s7,56(sp)
    8000671e:	f862                	sd	s8,48(sp)
    80006720:	f466                	sd	s9,40(sp)
    80006722:	f06a                	sd	s10,32(sp)
    80006724:	ec6e                	sd	s11,24(sp)
    80006726:	0100                	addi	s0,sp,128
    80006728:	e414                	sd	a3,8(s0)
    8000672a:	e818                	sd	a4,16(s0)
    8000672c:	ec1c                	sd	a5,24(s0)
    8000672e:	03043023          	sd	a6,32(s0)
    80006732:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006736:	ca0d                	beqz	a2,80006768 <snprintf+0x5e>
    80006738:	8baa                	mv	s7,a0
    8000673a:	89ae                	mv	s3,a1
    8000673c:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    8000673e:	00840793          	addi	a5,s0,8
    80006742:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    80006746:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006748:	4901                	li	s2,0
    8000674a:	02b05763          	blez	a1,80006778 <snprintf+0x6e>
    if(c != '%'){
    8000674e:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006752:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006756:	02800d93          	li	s11,40
  *s = c;
    8000675a:	02500d13          	li	s10,37
    switch(c){
    8000675e:	07800c93          	li	s9,120
    80006762:	06400c13          	li	s8,100
    80006766:	a01d                	j	8000678c <snprintf+0x82>
    panic("null fmt");
    80006768:	00002517          	auipc	a0,0x2
    8000676c:	8b050513          	addi	a0,a0,-1872 # 80008018 <etext+0x18>
    80006770:	ffffa097          	auipc	ra,0xffffa
    80006774:	dd8080e7          	jalr	-552(ra) # 80000548 <panic>
  int off = 0;
    80006778:	4481                	li	s1,0
    8000677a:	a86d                	j	80006834 <snprintf+0x12a>
  *s = c;
    8000677c:	009b8733          	add	a4,s7,s1
    80006780:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006784:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006786:	2905                	addiw	s2,s2,1
    80006788:	0b34d663          	bge	s1,s3,80006834 <snprintf+0x12a>
    8000678c:	012a07b3          	add	a5,s4,s2
    80006790:	0007c783          	lbu	a5,0(a5)
    80006794:	0007871b          	sext.w	a4,a5
    80006798:	cfd1                	beqz	a5,80006834 <snprintf+0x12a>
    if(c != '%'){
    8000679a:	ff5711e3          	bne	a4,s5,8000677c <snprintf+0x72>
    c = fmt[++i] & 0xff;
    8000679e:	2905                	addiw	s2,s2,1
    800067a0:	012a07b3          	add	a5,s4,s2
    800067a4:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800067a8:	c7d1                	beqz	a5,80006834 <snprintf+0x12a>
    switch(c){
    800067aa:	05678c63          	beq	a5,s6,80006802 <snprintf+0xf8>
    800067ae:	02fb6763          	bltu	s6,a5,800067dc <snprintf+0xd2>
    800067b2:	0b578763          	beq	a5,s5,80006860 <snprintf+0x156>
    800067b6:	0b879b63          	bne	a5,s8,8000686c <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800067ba:	f8843783          	ld	a5,-120(s0)
    800067be:	00878713          	addi	a4,a5,8
    800067c2:	f8e43423          	sd	a4,-120(s0)
    800067c6:	4685                	li	a3,1
    800067c8:	4629                	li	a2,10
    800067ca:	438c                	lw	a1,0(a5)
    800067cc:	009b8533          	add	a0,s7,s1
    800067d0:	00000097          	auipc	ra,0x0
    800067d4:	ea2080e7          	jalr	-350(ra) # 80006672 <sprintint>
    800067d8:	9ca9                	addw	s1,s1,a0
      break;
    800067da:	b775                	j	80006786 <snprintf+0x7c>
    switch(c){
    800067dc:	09979863          	bne	a5,s9,8000686c <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800067e0:	f8843783          	ld	a5,-120(s0)
    800067e4:	00878713          	addi	a4,a5,8
    800067e8:	f8e43423          	sd	a4,-120(s0)
    800067ec:	4685                	li	a3,1
    800067ee:	4641                	li	a2,16
    800067f0:	438c                	lw	a1,0(a5)
    800067f2:	009b8533          	add	a0,s7,s1
    800067f6:	00000097          	auipc	ra,0x0
    800067fa:	e7c080e7          	jalr	-388(ra) # 80006672 <sprintint>
    800067fe:	9ca9                	addw	s1,s1,a0
      break;
    80006800:	b759                	j	80006786 <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006802:	f8843783          	ld	a5,-120(s0)
    80006806:	00878713          	addi	a4,a5,8
    8000680a:	f8e43423          	sd	a4,-120(s0)
    8000680e:	639c                	ld	a5,0(a5)
    80006810:	c3b1                	beqz	a5,80006854 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006812:	0007c703          	lbu	a4,0(a5)
    80006816:	db25                	beqz	a4,80006786 <snprintf+0x7c>
    80006818:	0134de63          	bge	s1,s3,80006834 <snprintf+0x12a>
    8000681c:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006820:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006824:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006826:	0785                	addi	a5,a5,1
    80006828:	0007c703          	lbu	a4,0(a5)
    8000682c:	df29                	beqz	a4,80006786 <snprintf+0x7c>
    8000682e:	0685                	addi	a3,a3,1
    80006830:	fe9998e3          	bne	s3,s1,80006820 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006834:	8526                	mv	a0,s1
    80006836:	70e6                	ld	ra,120(sp)
    80006838:	7446                	ld	s0,112(sp)
    8000683a:	74a6                	ld	s1,104(sp)
    8000683c:	7906                	ld	s2,96(sp)
    8000683e:	69e6                	ld	s3,88(sp)
    80006840:	6a46                	ld	s4,80(sp)
    80006842:	6aa6                	ld	s5,72(sp)
    80006844:	6b06                	ld	s6,64(sp)
    80006846:	7be2                	ld	s7,56(sp)
    80006848:	7c42                	ld	s8,48(sp)
    8000684a:	7ca2                	ld	s9,40(sp)
    8000684c:	7d02                	ld	s10,32(sp)
    8000684e:	6de2                	ld	s11,24(sp)
    80006850:	614d                	addi	sp,sp,176
    80006852:	8082                	ret
        s = "(null)";
    80006854:	00001797          	auipc	a5,0x1
    80006858:	7bc78793          	addi	a5,a5,1980 # 80008010 <etext+0x10>
      for(; *s && off < sz; s++)
    8000685c:	876e                	mv	a4,s11
    8000685e:	bf6d                	j	80006818 <snprintf+0x10e>
  *s = c;
    80006860:	009b87b3          	add	a5,s7,s1
    80006864:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006868:	2485                	addiw	s1,s1,1
      break;
    8000686a:	bf31                	j	80006786 <snprintf+0x7c>
  *s = c;
    8000686c:	009b8733          	add	a4,s7,s1
    80006870:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006874:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006878:	975e                	add	a4,a4,s7
    8000687a:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000687e:	2489                	addiw	s1,s1,2
      break;
    80006880:	b719                	j	80006786 <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
