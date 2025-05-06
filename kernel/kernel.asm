
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	00c78793          	addi	a5,a5,12 # 80006070 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	410080e7          	jalr	1040(ra) # 8000252e <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00001097          	auipc	ra,0x1
    800001ba:	7f0080e7          	jalr	2032(ra) # 800019a6 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	0b0080e7          	jalr	176(ra) # 80002276 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	2d6080e7          	jalr	726(ra) # 800024d8 <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	2a0080e7          	jalr	672(ra) # 80002584 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	fc4080e7          	jalr	-60(ra) # 800023fc <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	0002d797          	auipc	a5,0x2d
    8000046e:	e9678793          	addi	a5,a5,-362 # 8002d300 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	b6a080e7          	jalr	-1174(ra) # 800023fc <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	958080e7          	jalr	-1704(ra) # 80002276 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00031797          	auipc	a5,0x31
    80000a02:	60278793          	addi	a5,a5,1538 # 80032000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00031517          	auipc	a0,0x31
    80000ad2:	53250513          	addi	a0,a0,1330 # 80032000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e1a080e7          	jalr	-486(ra) # 8000198a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	de8080e7          	jalr	-536(ra) # 8000198a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	ddc080e7          	jalr	-548(ra) # 8000198a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dc4080e7          	jalr	-572(ra) # 8000198a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d84080e7          	jalr	-636(ra) # 8000198a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d58080e7          	jalr	-680(ra) # 8000198a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	aee080e7          	jalr	-1298(ra) # 8000197a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	ad2080e7          	jalr	-1326(ra) # 8000197a <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	7fa080e7          	jalr	2042(ra) # 800026c4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	1de080e7          	jalr	478(ra) # 800060b0 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	04e080e7          	jalr	78(ra) # 80001f28 <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	9a8080e7          	jalr	-1624(ra) # 800018e2 <procinit>
    trapinit();      // trap vectors
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	75a080e7          	jalr	1882(ra) # 8000269c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	77a080e7          	jalr	1914(ra) # 800026c4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	148080e7          	jalr	328(ra) # 8000609a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	156080e7          	jalr	342(ra) # 800060b0 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	06c080e7          	jalr	108(ra) # 80002fce <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	6fc080e7          	jalr	1788(ra) # 80003666 <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	6ae080e7          	jalr	1710(ra) # 80004620 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	258080e7          	jalr	600(ra) # 800061d2 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	d00080e7          	jalr	-768(ra) # 80001c82 <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	628080e7          	jalr	1576(ra) # 8000184c <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6a85                	lui	s5,0x1
    80001286:	0735e163          	bltu	a1,s3,800012e8 <uvmunmap+0x8e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e5050513          	addi	a0,a0,-432 # 80008110 <digits+0xd0>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	268080e7          	jalr	616(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012d0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012d2:	00c79513          	slli	a0,a5,0xc
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	714080e7          	jalr	1812(ra) # 800009ea <kfree>
    *pte = 0;
    800012de:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e2:	9956                	add	s2,s2,s5
    800012e4:	fb3973e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012e8:	4601                	li	a2,0
    800012ea:	85ca                	mv	a1,s2
    800012ec:	8552                	mv	a0,s4
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	cd0080e7          	jalr	-816(ra) # 80000fbe <walk>
    800012f6:	84aa                	mv	s1,a0
    800012f8:	dd45                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fa:	611c                	ld	a5,0(a0)
    800012fc:	0017f713          	andi	a4,a5,1
    80001300:	d36d                	beqz	a4,800012e2 <uvmunmap+0x88>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001302:	3ff7f713          	andi	a4,a5,1023
    80001306:	fb770de3          	beq	a4,s7,800012c0 <uvmunmap+0x66>
    if(do_free){
    8000130a:	fc0b0ae3          	beqz	s6,800012de <uvmunmap+0x84>
    8000130e:	b7c9                	j	800012d0 <uvmunmap+0x76>

0000000080001310 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001310:	1101                	addi	sp,sp,-32
    80001312:	ec06                	sd	ra,24(sp)
    80001314:	e822                	sd	s0,16(sp)
    80001316:	e426                	sd	s1,8(sp)
    80001318:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	7cc080e7          	jalr	1996(ra) # 80000ae6 <kalloc>
    80001322:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001324:	c519                	beqz	a0,80001332 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001326:	6605                	lui	a2,0x1
    80001328:	4581                	li	a1,0
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	9a8080e7          	jalr	-1624(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001332:	8526                	mv	a0,s1
    80001334:	60e2                	ld	ra,24(sp)
    80001336:	6442                	ld	s0,16(sp)
    80001338:	64a2                	ld	s1,8(sp)
    8000133a:	6105                	addi	sp,sp,32
    8000133c:	8082                	ret

000000008000133e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000133e:	7179                	addi	sp,sp,-48
    80001340:	f406                	sd	ra,40(sp)
    80001342:	f022                	sd	s0,32(sp)
    80001344:	ec26                	sd	s1,24(sp)
    80001346:	e84a                	sd	s2,16(sp)
    80001348:	e44e                	sd	s3,8(sp)
    8000134a:	e052                	sd	s4,0(sp)
    8000134c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000134e:	6785                	lui	a5,0x1
    80001350:	04f67863          	bgeu	a2,a5,800013a0 <uvminit+0x62>
    80001354:	8a2a                	mv	s4,a0
    80001356:	89ae                	mv	s3,a1
    80001358:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	78c080e7          	jalr	1932(ra) # 80000ae6 <kalloc>
    80001362:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	96a080e7          	jalr	-1686(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001370:	4779                	li	a4,30
    80001372:	86ca                	mv	a3,s2
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	8552                	mv	a0,s4
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	d2c080e7          	jalr	-724(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001382:	8626                	mv	a2,s1
    80001384:	85ce                	mv	a1,s3
    80001386:	854a                	mv	a0,s2
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	9aa080e7          	jalr	-1622(ra) # 80000d32 <memmove>
}
    80001390:	70a2                	ld	ra,40(sp)
    80001392:	7402                	ld	s0,32(sp)
    80001394:	64e2                	ld	s1,24(sp)
    80001396:	6942                	ld	s2,16(sp)
    80001398:	69a2                	ld	s3,8(sp)
    8000139a:	6a02                	ld	s4,0(sp)
    8000139c:	6145                	addi	sp,sp,48
    8000139e:	8082                	ret
    panic("inituvm: more than a page");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d8850513          	addi	a0,a0,-632 # 80008128 <digits+0xe8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	188080e7          	jalr	392(ra) # 80000530 <panic>

00000000800013b0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013b0:	1101                	addi	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ba:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013bc:	00b67d63          	bgeu	a2,a1,800013d6 <uvmdealloc+0x26>
    800013c0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c2:	6785                	lui	a5,0x1
    800013c4:	17fd                	addi	a5,a5,-1
    800013c6:	00f60733          	add	a4,a2,a5
    800013ca:	767d                	lui	a2,0xfffff
    800013cc:	8f71                	and	a4,a4,a2
    800013ce:	97ae                	add	a5,a5,a1
    800013d0:	8ff1                	and	a5,a5,a2
    800013d2:	00f76863          	bltu	a4,a5,800013e2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d6:	8526                	mv	a0,s1
    800013d8:	60e2                	ld	ra,24(sp)
    800013da:	6442                	ld	s0,16(sp)
    800013dc:	64a2                	ld	s1,8(sp)
    800013de:	6105                	addi	sp,sp,32
    800013e0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e2:	8f99                	sub	a5,a5,a4
    800013e4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e6:	4685                	li	a3,1
    800013e8:	0007861b          	sext.w	a2,a5
    800013ec:	85ba                	mv	a1,a4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	e6c080e7          	jalr	-404(ra) # 8000125a <uvmunmap>
    800013f6:	b7c5                	j	800013d6 <uvmdealloc+0x26>

00000000800013f8 <uvmalloc>:
  if(newsz < oldsz)
    800013f8:	0ab66163          	bltu	a2,a1,8000149a <uvmalloc+0xa2>
{
    800013fc:	7139                	addi	sp,sp,-64
    800013fe:	fc06                	sd	ra,56(sp)
    80001400:	f822                	sd	s0,48(sp)
    80001402:	f426                	sd	s1,40(sp)
    80001404:	f04a                	sd	s2,32(sp)
    80001406:	ec4e                	sd	s3,24(sp)
    80001408:	e852                	sd	s4,16(sp)
    8000140a:	e456                	sd	s5,8(sp)
    8000140c:	0080                	addi	s0,sp,64
    8000140e:	8aaa                	mv	s5,a0
    80001410:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001412:	6985                	lui	s3,0x1
    80001414:	19fd                	addi	s3,s3,-1
    80001416:	95ce                	add	a1,a1,s3
    80001418:	79fd                	lui	s3,0xfffff
    8000141a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000141e:	08c9f063          	bgeu	s3,a2,8000149e <uvmalloc+0xa6>
    80001422:	894e                	mv	s2,s3
    mem = kalloc();
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	6c2080e7          	jalr	1730(ra) # 80000ae6 <kalloc>
    8000142c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000142e:	c51d                	beqz	a0,8000145c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001430:	6605                	lui	a2,0x1
    80001432:	4581                	li	a1,0
    80001434:	00000097          	auipc	ra,0x0
    80001438:	89e080e7          	jalr	-1890(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000143c:	4779                	li	a4,30
    8000143e:	86a6                	mv	a3,s1
    80001440:	6605                	lui	a2,0x1
    80001442:	85ca                	mv	a1,s2
    80001444:	8556                	mv	a0,s5
    80001446:	00000097          	auipc	ra,0x0
    8000144a:	c60080e7          	jalr	-928(ra) # 800010a6 <mappages>
    8000144e:	e905                	bnez	a0,8000147e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	6785                	lui	a5,0x1
    80001452:	993e                	add	s2,s2,a5
    80001454:	fd4968e3          	bltu	s2,s4,80001424 <uvmalloc+0x2c>
  return newsz;
    80001458:	8552                	mv	a0,s4
    8000145a:	a809                	j	8000146c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000145c:	864e                	mv	a2,s3
    8000145e:	85ca                	mv	a1,s2
    80001460:	8556                	mv	a0,s5
    80001462:	00000097          	auipc	ra,0x0
    80001466:	f4e080e7          	jalr	-178(ra) # 800013b0 <uvmdealloc>
      return 0;
    8000146a:	4501                	li	a0,0
}
    8000146c:	70e2                	ld	ra,56(sp)
    8000146e:	7442                	ld	s0,48(sp)
    80001470:	74a2                	ld	s1,40(sp)
    80001472:	7902                	ld	s2,32(sp)
    80001474:	69e2                	ld	s3,24(sp)
    80001476:	6a42                	ld	s4,16(sp)
    80001478:	6aa2                	ld	s5,8(sp)
    8000147a:	6121                	addi	sp,sp,64
    8000147c:	8082                	ret
      kfree(mem);
    8000147e:	8526                	mv	a0,s1
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	56a080e7          	jalr	1386(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001488:	864e                	mv	a2,s3
    8000148a:	85ca                	mv	a1,s2
    8000148c:	8556                	mv	a0,s5
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	f22080e7          	jalr	-222(ra) # 800013b0 <uvmdealloc>
      return 0;
    80001496:	4501                	li	a0,0
    80001498:	bfd1                	j	8000146c <uvmalloc+0x74>
    return oldsz;
    8000149a:	852e                	mv	a0,a1
}
    8000149c:	8082                	ret
  return newsz;
    8000149e:	8532                	mv	a0,a2
    800014a0:	b7f1                	j	8000146c <uvmalloc+0x74>

00000000800014a2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014a2:	7179                	addi	sp,sp,-48
    800014a4:	f406                	sd	ra,40(sp)
    800014a6:	f022                	sd	s0,32(sp)
    800014a8:	ec26                	sd	s1,24(sp)
    800014aa:	e84a                	sd	s2,16(sp)
    800014ac:	e44e                	sd	s3,8(sp)
    800014ae:	e052                	sd	s4,0(sp)
    800014b0:	1800                	addi	s0,sp,48
    800014b2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014b4:	84aa                	mv	s1,a0
    800014b6:	6905                	lui	s2,0x1
    800014b8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ba:	4985                	li	s3,1
    800014bc:	a821                	j	800014d4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014be:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014c0:	0532                	slli	a0,a0,0xc
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	fe0080e7          	jalr	-32(ra) # 800014a2 <freewalk>
      pagetable[i] = 0;
    800014ca:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ce:	04a1                	addi	s1,s1,8
    800014d0:	03248163          	beq	s1,s2,800014f2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014d4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d6:	00f57793          	andi	a5,a0,15
    800014da:	ff3782e3          	beq	a5,s3,800014be <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014de:	8905                	andi	a0,a0,1
    800014e0:	d57d                	beqz	a0,800014ce <freewalk+0x2c>
      panic("freewalk: leaf");
    800014e2:	00007517          	auipc	a0,0x7
    800014e6:	c6650513          	addi	a0,a0,-922 # 80008148 <digits+0x108>
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	046080e7          	jalr	70(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    800014f2:	8552                	mv	a0,s4
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	4f6080e7          	jalr	1270(ra) # 800009ea <kfree>
}
    800014fc:	70a2                	ld	ra,40(sp)
    800014fe:	7402                	ld	s0,32(sp)
    80001500:	64e2                	ld	s1,24(sp)
    80001502:	6942                	ld	s2,16(sp)
    80001504:	69a2                	ld	s3,8(sp)
    80001506:	6a02                	ld	s4,0(sp)
    80001508:	6145                	addi	sp,sp,48
    8000150a:	8082                	ret

000000008000150c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000150c:	1101                	addi	sp,sp,-32
    8000150e:	ec06                	sd	ra,24(sp)
    80001510:	e822                	sd	s0,16(sp)
    80001512:	e426                	sd	s1,8(sp)
    80001514:	1000                	addi	s0,sp,32
    80001516:	84aa                	mv	s1,a0
  if(sz > 0)
    80001518:	e999                	bnez	a1,8000152e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000151a:	8526                	mv	a0,s1
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	f86080e7          	jalr	-122(ra) # 800014a2 <freewalk>
}
    80001524:	60e2                	ld	ra,24(sp)
    80001526:	6442                	ld	s0,16(sp)
    80001528:	64a2                	ld	s1,8(sp)
    8000152a:	6105                	addi	sp,sp,32
    8000152c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000152e:	6605                	lui	a2,0x1
    80001530:	167d                	addi	a2,a2,-1
    80001532:	962e                	add	a2,a2,a1
    80001534:	4685                	li	a3,1
    80001536:	8231                	srli	a2,a2,0xc
    80001538:	4581                	li	a1,0
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	d20080e7          	jalr	-736(ra) # 8000125a <uvmunmap>
    80001542:	bfe1                	j	8000151a <uvmfree+0xe>

0000000080001544 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001544:	c269                	beqz	a2,80001606 <uvmcopy+0xc2>
{
    80001546:	715d                	addi	sp,sp,-80
    80001548:	e486                	sd	ra,72(sp)
    8000154a:	e0a2                	sd	s0,64(sp)
    8000154c:	fc26                	sd	s1,56(sp)
    8000154e:	f84a                	sd	s2,48(sp)
    80001550:	f44e                	sd	s3,40(sp)
    80001552:	f052                	sd	s4,32(sp)
    80001554:	ec56                	sd	s5,24(sp)
    80001556:	e85a                	sd	s6,16(sp)
    80001558:	e45e                	sd	s7,8(sp)
    8000155a:	0880                	addi	s0,sp,80
    8000155c:	8aaa                	mv	s5,a0
    8000155e:	8b2e                	mv	s6,a1
    80001560:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001562:	4481                	li	s1,0
    80001564:	a829                	j	8000157e <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    80001566:	00007517          	auipc	a0,0x7
    8000156a:	bf250513          	addi	a0,a0,-1038 # 80008158 <digits+0x118>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	fc2080e7          	jalr	-62(ra) # 80000530 <panic>
  for(i = 0; i < sz; i += PGSIZE){
    80001576:	6785                	lui	a5,0x1
    80001578:	94be                	add	s1,s1,a5
    8000157a:	0944f463          	bgeu	s1,s4,80001602 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    8000157e:	4601                	li	a2,0
    80001580:	85a6                	mv	a1,s1
    80001582:	8556                	mv	a0,s5
    80001584:	00000097          	auipc	ra,0x0
    80001588:	a3a080e7          	jalr	-1478(ra) # 80000fbe <walk>
    8000158c:	dd69                	beqz	a0,80001566 <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    8000158e:	6118                	ld	a4,0(a0)
    80001590:	00177793          	andi	a5,a4,1
    80001594:	d3ed                	beqz	a5,80001576 <uvmcopy+0x32>
      continue;
    pa = PTE2PA(*pte);
    80001596:	00a75593          	srli	a1,a4,0xa
    8000159a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000159e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	544080e7          	jalr	1348(ra) # 80000ae6 <kalloc>
    800015aa:	89aa                	mv	s3,a0
    800015ac:	c515                	beqz	a0,800015d8 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	85de                	mv	a1,s7
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	780080e7          	jalr	1920(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ba:	874a                	mv	a4,s2
    800015bc:	86ce                	mv	a3,s3
    800015be:	6605                	lui	a2,0x1
    800015c0:	85a6                	mv	a1,s1
    800015c2:	855a                	mv	a0,s6
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	ae2080e7          	jalr	-1310(ra) # 800010a6 <mappages>
    800015cc:	d54d                	beqz	a0,80001576 <uvmcopy+0x32>
      kfree(mem);
    800015ce:	854e                	mv	a0,s3
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	41a080e7          	jalr	1050(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015d8:	4685                	li	a3,1
    800015da:	00c4d613          	srli	a2,s1,0xc
    800015de:	4581                	li	a1,0
    800015e0:	855a                	mv	a0,s6
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	c78080e7          	jalr	-904(ra) # 8000125a <uvmunmap>
  return -1;
    800015ea:	557d                	li	a0,-1
}
    800015ec:	60a6                	ld	ra,72(sp)
    800015ee:	6406                	ld	s0,64(sp)
    800015f0:	74e2                	ld	s1,56(sp)
    800015f2:	7942                	ld	s2,48(sp)
    800015f4:	79a2                	ld	s3,40(sp)
    800015f6:	7a02                	ld	s4,32(sp)
    800015f8:	6ae2                	ld	s5,24(sp)
    800015fa:	6b42                	ld	s6,16(sp)
    800015fc:	6ba2                	ld	s7,8(sp)
    800015fe:	6161                	addi	sp,sp,80
    80001600:	8082                	ret
  return 0;
    80001602:	4501                	li	a0,0
    80001604:	b7e5                	j	800015ec <uvmcopy+0xa8>
    80001606:	4501                	li	a0,0
}
    80001608:	8082                	ret

000000008000160a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160a:	1141                	addi	sp,sp,-16
    8000160c:	e406                	sd	ra,8(sp)
    8000160e:	e022                	sd	s0,0(sp)
    80001610:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001612:	4601                	li	a2,0
    80001614:	00000097          	auipc	ra,0x0
    80001618:	9aa080e7          	jalr	-1622(ra) # 80000fbe <walk>
  if(pte == 0)
    8000161c:	c901                	beqz	a0,8000162c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000161e:	611c                	ld	a5,0(a0)
    80001620:	9bbd                	andi	a5,a5,-17
    80001622:	e11c                	sd	a5,0(a0)
}
    80001624:	60a2                	ld	ra,8(sp)
    80001626:	6402                	ld	s0,0(sp)
    80001628:	0141                	addi	sp,sp,16
    8000162a:	8082                	ret
    panic("uvmclear");
    8000162c:	00007517          	auipc	a0,0x7
    80001630:	b4c50513          	addi	a0,a0,-1204 # 80008178 <digits+0x138>
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	efc080e7          	jalr	-260(ra) # 80000530 <panic>

000000008000163c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163c:	c6bd                	beqz	a3,800016aa <copyout+0x6e>
{
    8000163e:	715d                	addi	sp,sp,-80
    80001640:	e486                	sd	ra,72(sp)
    80001642:	e0a2                	sd	s0,64(sp)
    80001644:	fc26                	sd	s1,56(sp)
    80001646:	f84a                	sd	s2,48(sp)
    80001648:	f44e                	sd	s3,40(sp)
    8000164a:	f052                	sd	s4,32(sp)
    8000164c:	ec56                	sd	s5,24(sp)
    8000164e:	e85a                	sd	s6,16(sp)
    80001650:	e45e                	sd	s7,8(sp)
    80001652:	e062                	sd	s8,0(sp)
    80001654:	0880                	addi	s0,sp,80
    80001656:	8b2a                	mv	s6,a0
    80001658:	8c2e                	mv	s8,a1
    8000165a:	8a32                	mv	s4,a2
    8000165c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000165e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001660:	6a85                	lui	s5,0x1
    80001662:	a015                	j	80001686 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001664:	9562                	add	a0,a0,s8
    80001666:	0004861b          	sext.w	a2,s1
    8000166a:	85d2                	mv	a1,s4
    8000166c:	41250533          	sub	a0,a0,s2
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	6c2080e7          	jalr	1730(ra) # 80000d32 <memmove>

    len -= n;
    80001678:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000167e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001682:	02098263          	beqz	s3,800016a6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001686:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168a:	85ca                	mv	a1,s2
    8000168c:	855a                	mv	a0,s6
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	9d6080e7          	jalr	-1578(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001696:	cd01                	beqz	a0,800016ae <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001698:	418904b3          	sub	s1,s2,s8
    8000169c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000169e:	fc99f3e3          	bgeu	s3,s1,80001664 <copyout+0x28>
    800016a2:	84ce                	mv	s1,s3
    800016a4:	b7c1                	j	80001664 <copyout+0x28>
  }
  return 0;
    800016a6:	4501                	li	a0,0
    800016a8:	a021                	j	800016b0 <copyout+0x74>
    800016aa:	4501                	li	a0,0
}
    800016ac:	8082                	ret
      return -1;
    800016ae:	557d                	li	a0,-1
}
    800016b0:	60a6                	ld	ra,72(sp)
    800016b2:	6406                	ld	s0,64(sp)
    800016b4:	74e2                	ld	s1,56(sp)
    800016b6:	7942                	ld	s2,48(sp)
    800016b8:	79a2                	ld	s3,40(sp)
    800016ba:	7a02                	ld	s4,32(sp)
    800016bc:	6ae2                	ld	s5,24(sp)
    800016be:	6b42                	ld	s6,16(sp)
    800016c0:	6ba2                	ld	s7,8(sp)
    800016c2:	6c02                	ld	s8,0(sp)
    800016c4:	6161                	addi	sp,sp,80
    800016c6:	8082                	ret

00000000800016c8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c8:	c6bd                	beqz	a3,80001736 <copyin+0x6e>
{
    800016ca:	715d                	addi	sp,sp,-80
    800016cc:	e486                	sd	ra,72(sp)
    800016ce:	e0a2                	sd	s0,64(sp)
    800016d0:	fc26                	sd	s1,56(sp)
    800016d2:	f84a                	sd	s2,48(sp)
    800016d4:	f44e                	sd	s3,40(sp)
    800016d6:	f052                	sd	s4,32(sp)
    800016d8:	ec56                	sd	s5,24(sp)
    800016da:	e85a                	sd	s6,16(sp)
    800016dc:	e45e                	sd	s7,8(sp)
    800016de:	e062                	sd	s8,0(sp)
    800016e0:	0880                	addi	s0,sp,80
    800016e2:	8b2a                	mv	s6,a0
    800016e4:	8a2e                	mv	s4,a1
    800016e6:	8c32                	mv	s8,a2
    800016e8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ea:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ec:	6a85                	lui	s5,0x1
    800016ee:	a015                	j	80001712 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f0:	9562                	add	a0,a0,s8
    800016f2:	0004861b          	sext.w	a2,s1
    800016f6:	412505b3          	sub	a1,a0,s2
    800016fa:	8552                	mv	a0,s4
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	636080e7          	jalr	1590(ra) # 80000d32 <memmove>

    len -= n;
    80001704:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001708:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170e:	02098263          	beqz	s3,80001732 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001712:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001716:	85ca                	mv	a1,s2
    80001718:	855a                	mv	a0,s6
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	94a080e7          	jalr	-1718(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001722:	cd01                	beqz	a0,8000173a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001724:	418904b3          	sub	s1,s2,s8
    80001728:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172a:	fc99f3e3          	bgeu	s3,s1,800016f0 <copyin+0x28>
    8000172e:	84ce                	mv	s1,s3
    80001730:	b7c1                	j	800016f0 <copyin+0x28>
  }
  return 0;
    80001732:	4501                	li	a0,0
    80001734:	a021                	j	8000173c <copyin+0x74>
    80001736:	4501                	li	a0,0
}
    80001738:	8082                	ret
      return -1;
    8000173a:	557d                	li	a0,-1
}
    8000173c:	60a6                	ld	ra,72(sp)
    8000173e:	6406                	ld	s0,64(sp)
    80001740:	74e2                	ld	s1,56(sp)
    80001742:	7942                	ld	s2,48(sp)
    80001744:	79a2                	ld	s3,40(sp)
    80001746:	7a02                	ld	s4,32(sp)
    80001748:	6ae2                	ld	s5,24(sp)
    8000174a:	6b42                	ld	s6,16(sp)
    8000174c:	6ba2                	ld	s7,8(sp)
    8000174e:	6c02                	ld	s8,0(sp)
    80001750:	6161                	addi	sp,sp,80
    80001752:	8082                	ret

0000000080001754 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001754:	c6c5                	beqz	a3,800017fc <copyinstr+0xa8>
{
    80001756:	715d                	addi	sp,sp,-80
    80001758:	e486                	sd	ra,72(sp)
    8000175a:	e0a2                	sd	s0,64(sp)
    8000175c:	fc26                	sd	s1,56(sp)
    8000175e:	f84a                	sd	s2,48(sp)
    80001760:	f44e                	sd	s3,40(sp)
    80001762:	f052                	sd	s4,32(sp)
    80001764:	ec56                	sd	s5,24(sp)
    80001766:	e85a                	sd	s6,16(sp)
    80001768:	e45e                	sd	s7,8(sp)
    8000176a:	0880                	addi	s0,sp,80
    8000176c:	8a2a                	mv	s4,a0
    8000176e:	8b2e                	mv	s6,a1
    80001770:	8bb2                	mv	s7,a2
    80001772:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001774:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001776:	6985                	lui	s3,0x1
    80001778:	a035                	j	800017a4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000177e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001780:	0017b793          	seqz	a5,a5
    80001784:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001788:	60a6                	ld	ra,72(sp)
    8000178a:	6406                	ld	s0,64(sp)
    8000178c:	74e2                	ld	s1,56(sp)
    8000178e:	7942                	ld	s2,48(sp)
    80001790:	79a2                	ld	s3,40(sp)
    80001792:	7a02                	ld	s4,32(sp)
    80001794:	6ae2                	ld	s5,24(sp)
    80001796:	6b42                	ld	s6,16(sp)
    80001798:	6ba2                	ld	s7,8(sp)
    8000179a:	6161                	addi	sp,sp,80
    8000179c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000179e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a2:	c8a9                	beqz	s1,800017f4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017a8:	85ca                	mv	a1,s2
    800017aa:	8552                	mv	a0,s4
    800017ac:	00000097          	auipc	ra,0x0
    800017b0:	8b8080e7          	jalr	-1864(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017b4:	c131                	beqz	a0,800017f8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017b6:	41790833          	sub	a6,s2,s7
    800017ba:	984e                	add	a6,a6,s3
    if(n > max)
    800017bc:	0104f363          	bgeu	s1,a6,800017c2 <copyinstr+0x6e>
    800017c0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c2:	955e                	add	a0,a0,s7
    800017c4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017c8:	fc080be3          	beqz	a6,8000179e <copyinstr+0x4a>
    800017cc:	985a                	add	a6,a6,s6
    800017ce:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d0:	41650633          	sub	a2,a0,s6
    800017d4:	14fd                	addi	s1,s1,-1
    800017d6:	9b26                	add	s6,s6,s1
    800017d8:	00f60733          	add	a4,a2,a5
    800017dc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffcd000>
    800017e0:	df49                	beqz	a4,8000177a <copyinstr+0x26>
        *dst = *p;
    800017e2:	00e78023          	sb	a4,0(a5)
      --max;
    800017e6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ea:	0785                	addi	a5,a5,1
    while(n > 0){
    800017ec:	ff0796e3          	bne	a5,a6,800017d8 <copyinstr+0x84>
      dst++;
    800017f0:	8b42                	mv	s6,a6
    800017f2:	b775                	j	8000179e <copyinstr+0x4a>
    800017f4:	4781                	li	a5,0
    800017f6:	b769                	j	80001780 <copyinstr+0x2c>
      return -1;
    800017f8:	557d                	li	a0,-1
    800017fa:	b779                	j	80001788 <copyinstr+0x34>
  int got_null = 0;
    800017fc:	4781                	li	a5,0
  if(got_null){
    800017fe:	0017b793          	seqz	a5,a5
    80001802:	40f00533          	neg	a0,a5
}
    80001806:	8082                	ret

0000000080001808 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001808:	1101                	addi	sp,sp,-32
    8000180a:	ec06                	sd	ra,24(sp)
    8000180c:	e822                	sd	s0,16(sp)
    8000180e:	e426                	sd	s1,8(sp)
    80001810:	1000                	addi	s0,sp,32
    80001812:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001814:	fffff097          	auipc	ra,0xfffff
    80001818:	348080e7          	jalr	840(ra) # 80000b5c <holding>
    8000181c:	c909                	beqz	a0,8000182e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000181e:	749c                	ld	a5,40(s1)
    80001820:	00978f63          	beq	a5,s1,8000183e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001824:	60e2                	ld	ra,24(sp)
    80001826:	6442                	ld	s0,16(sp)
    80001828:	64a2                	ld	s1,8(sp)
    8000182a:	6105                	addi	sp,sp,32
    8000182c:	8082                	ret
    panic("wakeup1");
    8000182e:	00007517          	auipc	a0,0x7
    80001832:	95a50513          	addi	a0,a0,-1702 # 80008188 <digits+0x148>
    80001836:	fffff097          	auipc	ra,0xfffff
    8000183a:	cfa080e7          	jalr	-774(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000183e:	4c98                	lw	a4,24(s1)
    80001840:	4785                	li	a5,1
    80001842:	fef711e3          	bne	a4,a5,80001824 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001846:	4789                	li	a5,2
    80001848:	cc9c                	sw	a5,24(s1)
}
    8000184a:	bfe9                	j	80001824 <wakeup1+0x1c>

000000008000184c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000184c:	7139                	addi	sp,sp,-64
    8000184e:	fc06                	sd	ra,56(sp)
    80001850:	f822                	sd	s0,48(sp)
    80001852:	f426                	sd	s1,40(sp)
    80001854:	f04a                	sd	s2,32(sp)
    80001856:	ec4e                	sd	s3,24(sp)
    80001858:	e852                	sd	s4,16(sp)
    8000185a:	e456                	sd	s5,8(sp)
    8000185c:	e05a                	sd	s6,0(sp)
    8000185e:	0080                	addi	s0,sp,64
    80001860:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001862:	00010497          	auipc	s1,0x10
    80001866:	e5648493          	addi	s1,s1,-426 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000186a:	8b26                	mv	s6,s1
    8000186c:	00006a97          	auipc	s5,0x6
    80001870:	794a8a93          	addi	s5,s5,1940 # 80008000 <etext>
    80001874:	04000937          	lui	s2,0x4000
    80001878:	197d                	addi	s2,s2,-1
    8000187a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187c:	00022a17          	auipc	s4,0x22
    80001880:	83ca0a13          	addi	s4,s4,-1988 # 800230b8 <tickslock>
    char *pa = kalloc();
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	262080e7          	jalr	610(ra) # 80000ae6 <kalloc>
    8000188c:	862a                	mv	a2,a0
    if(pa == 0)
    8000188e:	c131                	beqz	a0,800018d2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001890:	416485b3          	sub	a1,s1,s6
    80001894:	858d                	srai	a1,a1,0x3
    80001896:	000ab783          	ld	a5,0(s5)
    8000189a:	02f585b3          	mul	a1,a1,a5
    8000189e:	2585                	addiw	a1,a1,1
    800018a0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a4:	4719                	li	a4,6
    800018a6:	6685                	lui	a3,0x1
    800018a8:	40b905b3          	sub	a1,s2,a1
    800018ac:	854e                	mv	a0,s3
    800018ae:	00000097          	auipc	ra,0x0
    800018b2:	886080e7          	jalr	-1914(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b6:	46848493          	addi	s1,s1,1128
    800018ba:	fd4495e3          	bne	s1,s4,80001884 <proc_mapstacks+0x38>
}
    800018be:	70e2                	ld	ra,56(sp)
    800018c0:	7442                	ld	s0,48(sp)
    800018c2:	74a2                	ld	s1,40(sp)
    800018c4:	7902                	ld	s2,32(sp)
    800018c6:	69e2                	ld	s3,24(sp)
    800018c8:	6a42                	ld	s4,16(sp)
    800018ca:	6aa2                	ld	s5,8(sp)
    800018cc:	6b02                	ld	s6,0(sp)
    800018ce:	6121                	addi	sp,sp,64
    800018d0:	8082                	ret
      panic("kalloc");
    800018d2:	00007517          	auipc	a0,0x7
    800018d6:	8be50513          	addi	a0,a0,-1858 # 80008190 <digits+0x150>
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	c56080e7          	jalr	-938(ra) # 80000530 <panic>

00000000800018e2 <procinit>:
{
    800018e2:	7139                	addi	sp,sp,-64
    800018e4:	fc06                	sd	ra,56(sp)
    800018e6:	f822                	sd	s0,48(sp)
    800018e8:	f426                	sd	s1,40(sp)
    800018ea:	f04a                	sd	s2,32(sp)
    800018ec:	ec4e                	sd	s3,24(sp)
    800018ee:	e852                	sd	s4,16(sp)
    800018f0:	e456                	sd	s5,8(sp)
    800018f2:	e05a                	sd	s6,0(sp)
    800018f4:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    800018f6:	00007597          	auipc	a1,0x7
    800018fa:	8a258593          	addi	a1,a1,-1886 # 80008198 <digits+0x158>
    800018fe:	00010517          	auipc	a0,0x10
    80001902:	9a250513          	addi	a0,a0,-1630 # 800112a0 <pid_lock>
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	240080e7          	jalr	576(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190e:	00010497          	auipc	s1,0x10
    80001912:	daa48493          	addi	s1,s1,-598 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    80001916:	00007b17          	auipc	s6,0x7
    8000191a:	88ab0b13          	addi	s6,s6,-1910 # 800081a0 <digits+0x160>
      p->kstack = KSTACK((int) (p - proc));
    8000191e:	8aa6                	mv	s5,s1
    80001920:	00006a17          	auipc	s4,0x6
    80001924:	6e0a0a13          	addi	s4,s4,1760 # 80008000 <etext>
    80001928:	04000937          	lui	s2,0x4000
    8000192c:	197d                	addi	s2,s2,-1
    8000192e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	00021997          	auipc	s3,0x21
    80001934:	78898993          	addi	s3,s3,1928 # 800230b8 <tickslock>
      initlock(&p->lock, "proc");
    80001938:	85da                	mv	a1,s6
    8000193a:	8526                	mv	a0,s1
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	20a080e7          	jalr	522(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	srai	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addiw	a5,a5,1
    80001954:	00d7979b          	slliw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195e:	46848493          	addi	s1,s1,1128
    80001962:	fd349be3          	bne	s1,s3,80001938 <procinit+0x56>
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	addi	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:
mycpu(void) {
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
    80001990:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
}
    80001996:	00010517          	auipc	a0,0x10
    8000199a:	92250513          	addi	a0,a0,-1758 # 800112b8 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	addi	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:
myproc(void) {
    800019a6:	1101                	addi	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	addi	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1da080e7          	jalr	474(ra) # 80000b8a <push_off>
    800019b8:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
    800019be:	00010717          	auipc	a4,0x10
    800019c2:	8e270713          	addi	a4,a4,-1822 # 800112a0 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	6f84                	ld	s1,24(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	260080e7          	jalr	608(ra) # 80000c2a <pop_off>
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	addi	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:
{
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	29c080e7          	jalr	668(ra) # 80000c8a <release>
  if (first) {
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	dca7a783          	lw	a5,-566(a5) # 800087c0 <first.1687>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	e50080e7          	jalr	-432(ra) # 80002850 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	da07a823          	sw	zero,-592(a5) # 800087c0 <first.1687>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	bcc080e7          	jalr	-1076(ra) # 800035e6 <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
allocpid() {
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a30:	00010917          	auipc	s2,0x10
    80001a34:	87090913          	addi	s2,s2,-1936 # 800112a0 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	19c080e7          	jalr	412(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	d8278793          	addi	a5,a5,-638 # 800087c4 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addiw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	236080e7          	jalr	566(ra) # 80000c8a <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	addi	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <proc_pagetable>:
{
    80001a6a:	1101                	addi	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	e426                	sd	s1,8(sp)
    80001a72:	e04a                	sd	s2,0(sp)
    80001a74:	1000                	addi	s0,sp,32
    80001a76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	898080e7          	jalr	-1896(ra) # 80001310 <uvmcreate>
    80001a80:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a82:	c121                	beqz	a0,80001ac2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a84:	4729                	li	a4,10
    80001a86:	00005697          	auipc	a3,0x5
    80001a8a:	57a68693          	addi	a3,a3,1402 # 80007000 <_trampoline>
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	040005b7          	lui	a1,0x4000
    80001a94:	15fd                	addi	a1,a1,-1
    80001a96:	05b2                	slli	a1,a1,0xc
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	60e080e7          	jalr	1550(ra) # 800010a6 <mappages>
    80001aa0:	02054863          	bltz	a0,80001ad0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa4:	4719                	li	a4,6
    80001aa6:	05893683          	ld	a3,88(s2)
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	020005b7          	lui	a1,0x2000
    80001ab0:	15fd                	addi	a1,a1,-1
    80001ab2:	05b6                	slli	a1,a1,0xd
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	5f0080e7          	jalr	1520(ra) # 800010a6 <mappages>
    80001abe:	02054163          	bltz	a0,80001ae0 <proc_pagetable+0x76>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	addi	sp,sp,32
    80001ace:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a38080e7          	jalr	-1480(ra) # 8000150c <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	b7d5                	j	80001ac2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	addi	a1,a1,-1
    80001aea:	05b2                	slli	a1,a1,0xc
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	76c080e7          	jalr	1900(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a12080e7          	jalr	-1518(ra) # 8000150c <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	bf7d                	j	80001ac2 <proc_pagetable+0x58>

0000000080001b06 <proc_freepagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
    80001b14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	738080e7          	jalr	1848(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	722080e7          	jalr	1826(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b40:	85ca                	mv	a1,s2
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9c8080e7          	jalr	-1592(ra) # 8000150c <uvmfree>
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <freeproc>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b64:	6d28                	ld	a0,88(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e82080e7          	jalr	-382(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b70:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b74:	68a8                	ld	a0,80(s1)
    80001b76:	c511                	beqz	a0,80001b82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b78:	64ac                	ld	a1,72(s1)
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	f8c080e7          	jalr	-116(ra) # 80001b06 <proc_freepagetable>
  p->pagetable = 0;
    80001b82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b8a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001b8e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001b92:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b96:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001b9a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001b9e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001ba2:	0004ac23          	sw	zero,24(s1)
}
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <allocproc>:
{
    80001bb0:	1101                	addi	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbc:	00010497          	auipc	s1,0x10
    80001bc0:	afc48493          	addi	s1,s1,-1284 # 800116b8 <proc>
    80001bc4:	00021917          	auipc	s2,0x21
    80001bc8:	4f490913          	addi	s2,s2,1268 # 800230b8 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	008080e7          	jalr	8(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0ae080e7          	jalr	174(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	46848493          	addi	s1,s1,1128
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	a085                	j	80001c4e <allocproc+0x9e>
  p->pid = allocpid();
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	eec080e7          	jalr	-276(ra) # 80000ae6 <kalloc>
    80001c02:	892a                	mv	s2,a0
    80001c04:	eca8                	sd	a0,88(s1)
    80001c06:	c939                	beqz	a0,80001c5c <allocproc+0xac>
  p->pagetable = proc_pagetable(p);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e60080e7          	jalr	-416(ra) # 80001a6a <proc_pagetable>
    80001c12:	892a                	mv	s2,a0
    80001c14:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c16:	c931                	beqz	a0,80001c6a <allocproc+0xba>
  memset(&p->context, 0, sizeof(p->context));
    80001c18:	07000613          	li	a2,112
    80001c1c:	4581                	li	a1,0
    80001c1e:	06048513          	addi	a0,s1,96
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	0b0080e7          	jalr	176(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c2a:	00000797          	auipc	a5,0x0
    80001c2e:	db478793          	addi	a5,a5,-588 # 800019de <forkret>
    80001c32:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c34:	60bc                	ld	a5,64(s1)
    80001c36:	6705                	lui	a4,0x1
    80001c38:	97ba                	add	a5,a5,a4
    80001c3a:	f4bc                	sd	a5,104(s1)
  memset(&p->vma, 0, sizeof(p->vma));
    80001c3c:	30000613          	li	a2,768
    80001c40:	4581                	li	a1,0
    80001c42:	16848513          	addi	a0,s1,360
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	08c080e7          	jalr	140(ra) # 80000cd2 <memset>
}
    80001c4e:	8526                	mv	a0,s1
    80001c50:	60e2                	ld	ra,24(sp)
    80001c52:	6442                	ld	s0,16(sp)
    80001c54:	64a2                	ld	s1,8(sp)
    80001c56:	6902                	ld	s2,0(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret
    release(&p->lock);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	02c080e7          	jalr	44(ra) # 80000c8a <release>
    return 0;
    80001c66:	84ca                	mv	s1,s2
    80001c68:	b7dd                	j	80001c4e <allocproc+0x9e>
    freeproc(p);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	eec080e7          	jalr	-276(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c74:	8526                	mv	a0,s1
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	014080e7          	jalr	20(ra) # 80000c8a <release>
    return 0;
    80001c7e:	84ca                	mv	s1,s2
    80001c80:	b7f9                	j	80001c4e <allocproc+0x9e>

0000000080001c82 <userinit>:
{
    80001c82:	1101                	addi	sp,sp,-32
    80001c84:	ec06                	sd	ra,24(sp)
    80001c86:	e822                	sd	s0,16(sp)
    80001c88:	e426                	sd	s1,8(sp)
    80001c8a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	f24080e7          	jalr	-220(ra) # 80001bb0 <allocproc>
    80001c94:	84aa                	mv	s1,a0
  initproc = p;
    80001c96:	00007797          	auipc	a5,0x7
    80001c9a:	38a7b923          	sd	a0,914(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c9e:	03400613          	li	a2,52
    80001ca2:	00007597          	auipc	a1,0x7
    80001ca6:	b2e58593          	addi	a1,a1,-1234 # 800087d0 <initcode>
    80001caa:	6928                	ld	a0,80(a0)
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	692080e7          	jalr	1682(ra) # 8000133e <uvminit>
  p->sz = PGSIZE;
    80001cb4:	6785                	lui	a5,0x1
    80001cb6:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cb8:	6cb8                	ld	a4,88(s1)
    80001cba:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cbe:	6cb8                	ld	a4,88(s1)
    80001cc0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc2:	4641                	li	a2,16
    80001cc4:	00006597          	auipc	a1,0x6
    80001cc8:	4e458593          	addi	a1,a1,1252 # 800081a8 <digits+0x168>
    80001ccc:	15848513          	addi	a0,s1,344
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	158080e7          	jalr	344(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001cd8:	00006517          	auipc	a0,0x6
    80001cdc:	4e050513          	addi	a0,a0,1248 # 800081b8 <digits+0x178>
    80001ce0:	00002097          	auipc	ra,0x2
    80001ce4:	334080e7          	jalr	820(ra) # 80004014 <namei>
    80001ce8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cec:	4789                	li	a5,2
    80001cee:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	f98080e7          	jalr	-104(ra) # 80000c8a <release>
}
    80001cfa:	60e2                	ld	ra,24(sp)
    80001cfc:	6442                	ld	s0,16(sp)
    80001cfe:	64a2                	ld	s1,8(sp)
    80001d00:	6105                	addi	sp,sp,32
    80001d02:	8082                	ret

0000000080001d04 <growproc>:
{
    80001d04:	1101                	addi	sp,sp,-32
    80001d06:	ec06                	sd	ra,24(sp)
    80001d08:	e822                	sd	s0,16(sp)
    80001d0a:	e426                	sd	s1,8(sp)
    80001d0c:	e04a                	sd	s2,0(sp)
    80001d0e:	1000                	addi	s0,sp,32
    80001d10:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	c94080e7          	jalr	-876(ra) # 800019a6 <myproc>
    80001d1a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d1c:	652c                	ld	a1,72(a0)
    80001d1e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d22:	00904f63          	bgtz	s1,80001d40 <growproc+0x3c>
  } else if(n < 0){
    80001d26:	0204cc63          	bltz	s1,80001d5e <growproc+0x5a>
  p->sz = sz;
    80001d2a:	1602                	slli	a2,a2,0x20
    80001d2c:	9201                	srli	a2,a2,0x20
    80001d2e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d32:	4501                	li	a0,0
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6902                	ld	s2,0(sp)
    80001d3c:	6105                	addi	sp,sp,32
    80001d3e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d40:	9e25                	addw	a2,a2,s1
    80001d42:	1602                	slli	a2,a2,0x20
    80001d44:	9201                	srli	a2,a2,0x20
    80001d46:	1582                	slli	a1,a1,0x20
    80001d48:	9181                	srli	a1,a1,0x20
    80001d4a:	6928                	ld	a0,80(a0)
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	6ac080e7          	jalr	1708(ra) # 800013f8 <uvmalloc>
    80001d54:	0005061b          	sext.w	a2,a0
    80001d58:	fa69                	bnez	a2,80001d2a <growproc+0x26>
      return -1;
    80001d5a:	557d                	li	a0,-1
    80001d5c:	bfe1                	j	80001d34 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d5e:	9e25                	addw	a2,a2,s1
    80001d60:	1602                	slli	a2,a2,0x20
    80001d62:	9201                	srli	a2,a2,0x20
    80001d64:	1582                	slli	a1,a1,0x20
    80001d66:	9181                	srli	a1,a1,0x20
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	646080e7          	jalr	1606(ra) # 800013b0 <uvmdealloc>
    80001d72:	0005061b          	sext.w	a2,a0
    80001d76:	bf55                	j	80001d2a <growproc+0x26>

0000000080001d78 <fork>:
{
    80001d78:	7139                	addi	sp,sp,-64
    80001d7a:	fc06                	sd	ra,56(sp)
    80001d7c:	f822                	sd	s0,48(sp)
    80001d7e:	f426                	sd	s1,40(sp)
    80001d80:	f04a                	sd	s2,32(sp)
    80001d82:	ec4e                	sd	s3,24(sp)
    80001d84:	e852                	sd	s4,16(sp)
    80001d86:	e456                	sd	s5,8(sp)
    80001d88:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	c1c080e7          	jalr	-996(ra) # 800019a6 <myproc>
    80001d92:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	e1c080e7          	jalr	-484(ra) # 80001bb0 <allocproc>
    80001d9c:	12050163          	beqz	a0,80001ebe <fork+0x146>
    80001da0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da2:	0489b603          	ld	a2,72(s3)
    80001da6:	692c                	ld	a1,80(a0)
    80001da8:	0509b503          	ld	a0,80(s3)
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	798080e7          	jalr	1944(ra) # 80001544 <uvmcopy>
    80001db4:	04054863          	bltz	a0,80001e04 <fork+0x8c>
  np->sz = p->sz;
    80001db8:	0489b783          	ld	a5,72(s3)
    80001dbc:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001dc0:	033a3023          	sd	s3,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	0589b683          	ld	a3,88(s3)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	058a3703          	ld	a4,88(s4)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001df2:	058a3783          	ld	a5,88(s4)
    80001df6:	0607b823          	sd	zero,112(a5)
    80001dfa:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfe:	15000913          	li	s2,336
    80001e02:	a03d                	j	80001e30 <fork+0xb8>
    freeproc(np);
    80001e04:	8552                	mv	a0,s4
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	d52080e7          	jalr	-686(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001e0e:	8552                	mv	a0,s4
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	e7a080e7          	jalr	-390(ra) # 80000c8a <release>
    return -1;
    80001e18:	54fd                	li	s1,-1
    80001e1a:	a841                	j	80001eaa <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1c:	00003097          	auipc	ra,0x3
    80001e20:	896080e7          	jalr	-1898(ra) # 800046b2 <filedup>
    80001e24:	009a07b3          	add	a5,s4,s1
    80001e28:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	01248763          	beq	s1,s2,80001e3a <fork+0xc2>
    if(p->ofile[i])
    80001e30:	009987b3          	add	a5,s3,s1
    80001e34:	6388                	ld	a0,0(a5)
    80001e36:	f17d                	bnez	a0,80001e1c <fork+0xa4>
    80001e38:	bfcd                	j	80001e2a <fork+0xb2>
  np->cwd = idup(p->cwd);
    80001e3a:	1509b503          	ld	a0,336(s3)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	9e2080e7          	jalr	-1566(ra) # 80003820 <idup>
    80001e46:	14aa3823          	sd	a0,336(s4)
   for(i = 0; i < NVMA; ++i) {
    80001e4a:	16898493          	addi	s1,s3,360
    80001e4e:	168a0913          	addi	s2,s4,360
    80001e52:	46898a93          	addi	s5,s3,1128
    80001e56:	a025                	j	80001e7e <fork+0x106>
      memmove(&np->vma[i], &p->vma[i], sizeof(p->vma[i]));
    80001e58:	03000613          	li	a2,48
    80001e5c:	85a6                	mv	a1,s1
    80001e5e:	854a                	mv	a0,s2
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	ed2080e7          	jalr	-302(ra) # 80000d32 <memmove>
      filedup(p->vma[i].vfile);
    80001e68:	7088                	ld	a0,32(s1)
    80001e6a:	00003097          	auipc	ra,0x3
    80001e6e:	848080e7          	jalr	-1976(ra) # 800046b2 <filedup>
   for(i = 0; i < NVMA; ++i) {
    80001e72:	03048493          	addi	s1,s1,48
    80001e76:	03090913          	addi	s2,s2,48
    80001e7a:	01548563          	beq	s1,s5,80001e84 <fork+0x10c>
    if(p->vma[i].used) {
    80001e7e:	409c                	lw	a5,0(s1)
    80001e80:	dbed                	beqz	a5,80001e72 <fork+0xfa>
    80001e82:	bfd9                	j	80001e58 <fork+0xe0>
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e84:	4641                	li	a2,16
    80001e86:	15898593          	addi	a1,s3,344
    80001e8a:	158a0513          	addi	a0,s4,344
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	f9a080e7          	jalr	-102(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e96:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001e9a:	4789                	li	a5,2
    80001e9c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea0:	8552                	mv	a0,s4
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	de8080e7          	jalr	-536(ra) # 80000c8a <release>
}
    80001eaa:	8526                	mv	a0,s1
    80001eac:	70e2                	ld	ra,56(sp)
    80001eae:	7442                	ld	s0,48(sp)
    80001eb0:	74a2                	ld	s1,40(sp)
    80001eb2:	7902                	ld	s2,32(sp)
    80001eb4:	69e2                	ld	s3,24(sp)
    80001eb6:	6a42                	ld	s4,16(sp)
    80001eb8:	6aa2                	ld	s5,8(sp)
    80001eba:	6121                	addi	sp,sp,64
    80001ebc:	8082                	ret
    return -1;
    80001ebe:	54fd                	li	s1,-1
    80001ec0:	b7ed                	j	80001eaa <fork+0x132>

0000000080001ec2 <reparent>:
{
    80001ec2:	7179                	addi	sp,sp,-48
    80001ec4:	f406                	sd	ra,40(sp)
    80001ec6:	f022                	sd	s0,32(sp)
    80001ec8:	ec26                	sd	s1,24(sp)
    80001eca:	e84a                	sd	s2,16(sp)
    80001ecc:	e44e                	sd	s3,8(sp)
    80001ece:	e052                	sd	s4,0(sp)
    80001ed0:	1800                	addi	s0,sp,48
    80001ed2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed4:	0000f497          	auipc	s1,0xf
    80001ed8:	7e448493          	addi	s1,s1,2020 # 800116b8 <proc>
      pp->parent = initproc;
    80001edc:	00007a17          	auipc	s4,0x7
    80001ee0:	14ca0a13          	addi	s4,s4,332 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ee4:	00021997          	auipc	s3,0x21
    80001ee8:	1d498993          	addi	s3,s3,468 # 800230b8 <tickslock>
    80001eec:	a029                	j	80001ef6 <reparent+0x34>
    80001eee:	46848493          	addi	s1,s1,1128
    80001ef2:	03348363          	beq	s1,s3,80001f18 <reparent+0x56>
    if(pp->parent == p){
    80001ef6:	709c                	ld	a5,32(s1)
    80001ef8:	ff279be3          	bne	a5,s2,80001eee <reparent+0x2c>
      acquire(&pp->lock);
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	cd8080e7          	jalr	-808(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    80001f06:	000a3783          	ld	a5,0(s4)
    80001f0a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	d7c080e7          	jalr	-644(ra) # 80000c8a <release>
    80001f16:	bfe1                	j	80001eee <reparent+0x2c>
}
    80001f18:	70a2                	ld	ra,40(sp)
    80001f1a:	7402                	ld	s0,32(sp)
    80001f1c:	64e2                	ld	s1,24(sp)
    80001f1e:	6942                	ld	s2,16(sp)
    80001f20:	69a2                	ld	s3,8(sp)
    80001f22:	6a02                	ld	s4,0(sp)
    80001f24:	6145                	addi	sp,sp,48
    80001f26:	8082                	ret

0000000080001f28 <scheduler>:
{
    80001f28:	711d                	addi	sp,sp,-96
    80001f2a:	ec86                	sd	ra,88(sp)
    80001f2c:	e8a2                	sd	s0,80(sp)
    80001f2e:	e4a6                	sd	s1,72(sp)
    80001f30:	e0ca                	sd	s2,64(sp)
    80001f32:	fc4e                	sd	s3,56(sp)
    80001f34:	f852                	sd	s4,48(sp)
    80001f36:	f456                	sd	s5,40(sp)
    80001f38:	f05a                	sd	s6,32(sp)
    80001f3a:	ec5e                	sd	s7,24(sp)
    80001f3c:	e862                	sd	s8,16(sp)
    80001f3e:	e466                	sd	s9,8(sp)
    80001f40:	1080                	addi	s0,sp,96
    80001f42:	8792                	mv	a5,tp
  int id = r_tp();
    80001f44:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f46:	00779c13          	slli	s8,a5,0x7
    80001f4a:	0000f717          	auipc	a4,0xf
    80001f4e:	35670713          	addi	a4,a4,854 # 800112a0 <pid_lock>
    80001f52:	9762                	add	a4,a4,s8
    80001f54:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f58:	0000f717          	auipc	a4,0xf
    80001f5c:	36870713          	addi	a4,a4,872 # 800112c0 <cpus+0x8>
    80001f60:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001f62:	4a89                	li	s5,2
        c->proc = p;
    80001f64:	079e                	slli	a5,a5,0x7
    80001f66:	0000fb17          	auipc	s6,0xf
    80001f6a:	33ab0b13          	addi	s6,s6,826 # 800112a0 <pid_lock>
    80001f6e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f70:	00021a17          	auipc	s4,0x21
    80001f74:	148a0a13          	addi	s4,s4,328 # 800230b8 <tickslock>
    int nproc = 0;
    80001f78:	4c81                	li	s9,0
    80001f7a:	a8a1                	j	80001fd2 <scheduler+0xaa>
        p->state = RUNNING;
    80001f7c:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f80:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001f84:	06048593          	addi	a1,s1,96
    80001f88:	8562                	mv	a0,s8
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	6a8080e7          	jalr	1704(ra) # 80002632 <swtch>
        c->proc = 0;
    80001f92:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	cf2080e7          	jalr	-782(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa0:	46848493          	addi	s1,s1,1128
    80001fa4:	01448d63          	beq	s1,s4,80001fbe <scheduler+0x96>
      acquire(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	c2c080e7          	jalr	-980(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80001fb2:	4c9c                	lw	a5,24(s1)
    80001fb4:	d3ed                	beqz	a5,80001f96 <scheduler+0x6e>
        nproc++;
    80001fb6:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001fb8:	fd579fe3          	bne	a5,s5,80001f96 <scheduler+0x6e>
    80001fbc:	b7c1                	j	80001f7c <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001fbe:	013aca63          	blt	s5,s3,80001fd2 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fca:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fce:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fd6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fda:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80001fde:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe0:	0000f497          	auipc	s1,0xf
    80001fe4:	6d848493          	addi	s1,s1,1752 # 800116b8 <proc>
        p->state = RUNNING;
    80001fe8:	4b8d                	li	s7,3
    80001fea:	bf7d                	j	80001fa8 <scheduler+0x80>

0000000080001fec <sched>:
{
    80001fec:	7179                	addi	sp,sp,-48
    80001fee:	f406                	sd	ra,40(sp)
    80001ff0:	f022                	sd	s0,32(sp)
    80001ff2:	ec26                	sd	s1,24(sp)
    80001ff4:	e84a                	sd	s2,16(sp)
    80001ff6:	e44e                	sd	s3,8(sp)
    80001ff8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	9ac080e7          	jalr	-1620(ra) # 800019a6 <myproc>
    80002002:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	b58080e7          	jalr	-1192(ra) # 80000b5c <holding>
    8000200c:	c93d                	beqz	a0,80002082 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002010:	2781                	sext.w	a5,a5
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	0000f717          	auipc	a4,0xf
    80002018:	28c70713          	addi	a4,a4,652 # 800112a0 <pid_lock>
    8000201c:	97ba                	add	a5,a5,a4
    8000201e:	0907a703          	lw	a4,144(a5)
    80002022:	4785                	li	a5,1
    80002024:	06f71763          	bne	a4,a5,80002092 <sched+0xa6>
  if(p->state == RUNNING)
    80002028:	4c98                	lw	a4,24(s1)
    8000202a:	478d                	li	a5,3
    8000202c:	06f70b63          	beq	a4,a5,800020a2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002030:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002034:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002036:	efb5                	bnez	a5,800020b2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002038:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000203a:	0000f917          	auipc	s2,0xf
    8000203e:	26690913          	addi	s2,s2,614 # 800112a0 <pid_lock>
    80002042:	2781                	sext.w	a5,a5
    80002044:	079e                	slli	a5,a5,0x7
    80002046:	97ca                	add	a5,a5,s2
    80002048:	0947a983          	lw	s3,148(a5)
    8000204c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204e:	2781                	sext.w	a5,a5
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	0000f597          	auipc	a1,0xf
    80002056:	26e58593          	addi	a1,a1,622 # 800112c0 <cpus+0x8>
    8000205a:	95be                	add	a1,a1,a5
    8000205c:	06048513          	addi	a0,s1,96
    80002060:	00000097          	auipc	ra,0x0
    80002064:	5d2080e7          	jalr	1490(ra) # 80002632 <swtch>
    80002068:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000206a:	2781                	sext.w	a5,a5
    8000206c:	079e                	slli	a5,a5,0x7
    8000206e:	97ca                	add	a5,a5,s2
    80002070:	0937aa23          	sw	s3,148(a5)
}
    80002074:	70a2                	ld	ra,40(sp)
    80002076:	7402                	ld	s0,32(sp)
    80002078:	64e2                	ld	s1,24(sp)
    8000207a:	6942                	ld	s2,16(sp)
    8000207c:	69a2                	ld	s3,8(sp)
    8000207e:	6145                	addi	sp,sp,48
    80002080:	8082                	ret
    panic("sched p->lock");
    80002082:	00006517          	auipc	a0,0x6
    80002086:	13e50513          	addi	a0,a0,318 # 800081c0 <digits+0x180>
    8000208a:	ffffe097          	auipc	ra,0xffffe
    8000208e:	4a6080e7          	jalr	1190(ra) # 80000530 <panic>
    panic("sched locks");
    80002092:	00006517          	auipc	a0,0x6
    80002096:	13e50513          	addi	a0,a0,318 # 800081d0 <digits+0x190>
    8000209a:	ffffe097          	auipc	ra,0xffffe
    8000209e:	496080e7          	jalr	1174(ra) # 80000530 <panic>
    panic("sched running");
    800020a2:	00006517          	auipc	a0,0x6
    800020a6:	13e50513          	addi	a0,a0,318 # 800081e0 <digits+0x1a0>
    800020aa:	ffffe097          	auipc	ra,0xffffe
    800020ae:	486080e7          	jalr	1158(ra) # 80000530 <panic>
    panic("sched interruptible");
    800020b2:	00006517          	auipc	a0,0x6
    800020b6:	13e50513          	addi	a0,a0,318 # 800081f0 <digits+0x1b0>
    800020ba:	ffffe097          	auipc	ra,0xffffe
    800020be:	476080e7          	jalr	1142(ra) # 80000530 <panic>

00000000800020c2 <exit>:
{
    800020c2:	7139                	addi	sp,sp,-64
    800020c4:	fc06                	sd	ra,56(sp)
    800020c6:	f822                	sd	s0,48(sp)
    800020c8:	f426                	sd	s1,40(sp)
    800020ca:	f04a                	sd	s2,32(sp)
    800020cc:	ec4e                	sd	s3,24(sp)
    800020ce:	e852                	sd	s4,16(sp)
    800020d0:	e456                	sd	s5,8(sp)
    800020d2:	e05a                	sd	s6,0(sp)
    800020d4:	0080                	addi	s0,sp,64
    800020d6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	8ce080e7          	jalr	-1842(ra) # 800019a6 <myproc>
    800020e0:	89aa                	mv	s3,a0
  if(p == initproc)
    800020e2:	00007797          	auipc	a5,0x7
    800020e6:	f467b783          	ld	a5,-186(a5) # 80009028 <initproc>
    800020ea:	0d050493          	addi	s1,a0,208
    800020ee:	15050913          	addi	s2,a0,336
    800020f2:	02a79363          	bne	a5,a0,80002118 <exit+0x56>
    panic("init exiting");
    800020f6:	00006517          	auipc	a0,0x6
    800020fa:	11250513          	addi	a0,a0,274 # 80008208 <digits+0x1c8>
    800020fe:	ffffe097          	auipc	ra,0xffffe
    80002102:	432080e7          	jalr	1074(ra) # 80000530 <panic>
      fileclose(f);
    80002106:	00002097          	auipc	ra,0x2
    8000210a:	5fe080e7          	jalr	1534(ra) # 80004704 <fileclose>
      p->ofile[fd] = 0;
    8000210e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002112:	04a1                	addi	s1,s1,8
    80002114:	01248563          	beq	s1,s2,8000211e <exit+0x5c>
    if(p->ofile[fd]){
    80002118:	6088                	ld	a0,0(s1)
    8000211a:	f575                	bnez	a0,80002106 <exit+0x44>
    8000211c:	bfdd                	j	80002112 <exit+0x50>
    8000211e:	16898493          	addi	s1,s3,360
    80002122:	46898a93          	addi	s5,s3,1128
    if(p->vma[i].flags == MAP_SHARED && (p->vma[i].prot & PROT_WRITE) != 0) {
    80002126:	4b05                	li	s6,1
    80002128:	a83d                	j	80002166 <exit+0xa4>
    fileclose(p->vma[i].vfile);
    8000212a:	02093503          	ld	a0,32(s2)
    8000212e:	00002097          	auipc	ra,0x2
    80002132:	5d6080e7          	jalr	1494(ra) # 80004704 <fileclose>
    uvmunmap(p->pagetable, p->vma[i].addr, p->vma[i].len / PGSIZE, 1);
    80002136:	01092783          	lw	a5,16(s2)
    8000213a:	41f7d61b          	sraiw	a2,a5,0x1f
    8000213e:	0146561b          	srliw	a2,a2,0x14
    80002142:	9e3d                	addw	a2,a2,a5
    80002144:	86da                	mv	a3,s6
    80002146:	40c6561b          	sraiw	a2,a2,0xc
    8000214a:	00893583          	ld	a1,8(s2)
    8000214e:	0509b503          	ld	a0,80(s3)
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	108080e7          	jalr	264(ra) # 8000125a <uvmunmap>
    p->vma[i].used = 0;
    8000215a:	00092023          	sw	zero,0(s2)
for(int i = 0; i < NVMA; ++i) {
    8000215e:	03048493          	addi	s1,s1,48
    80002162:	03548363          	beq	s1,s5,80002188 <exit+0xc6>
  if(p->vma[i].used) {
    80002166:	8926                	mv	s2,s1
    80002168:	409c                	lw	a5,0(s1)
    8000216a:	dbf5                	beqz	a5,8000215e <exit+0x9c>
    if(p->vma[i].flags == MAP_SHARED && (p->vma[i].prot & PROT_WRITE) != 0) {
    8000216c:	4c9c                	lw	a5,24(s1)
    8000216e:	fb679ee3          	bne	a5,s6,8000212a <exit+0x68>
    80002172:	48dc                	lw	a5,20(s1)
    80002174:	8b89                	andi	a5,a5,2
    80002176:	dbd5                	beqz	a5,8000212a <exit+0x68>
      filewrite(p->vma[i].vfile, p->vma[i].addr, p->vma[i].len);
    80002178:	4890                	lw	a2,16(s1)
    8000217a:	648c                	ld	a1,8(s1)
    8000217c:	7088                	ld	a0,32(s1)
    8000217e:	00002097          	auipc	ra,0x2
    80002182:	782080e7          	jalr	1922(ra) # 80004900 <filewrite>
    80002186:	b755                	j	8000212a <exit+0x68>
  begin_op();
    80002188:	00002097          	auipc	ra,0x2
    8000218c:	0a8080e7          	jalr	168(ra) # 80004230 <begin_op>
  iput(p->cwd);
    80002190:	1509b503          	ld	a0,336(s3)
    80002194:	00002097          	auipc	ra,0x2
    80002198:	884080e7          	jalr	-1916(ra) # 80003a18 <iput>
  end_op();
    8000219c:	00002097          	auipc	ra,0x2
    800021a0:	114080e7          	jalr	276(ra) # 800042b0 <end_op>
  p->cwd = 0;
    800021a4:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021a8:	00007497          	auipc	s1,0x7
    800021ac:	e8048493          	addi	s1,s1,-384 # 80009028 <initproc>
    800021b0:	6088                	ld	a0,0(s1)
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a24080e7          	jalr	-1500(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    800021ba:	6088                	ld	a0,0(s1)
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	64c080e7          	jalr	1612(ra) # 80001808 <wakeup1>
  release(&initproc->lock);
    800021c4:	6088                	ld	a0,0(s1)
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	ac4080e7          	jalr	-1340(ra) # 80000c8a <release>
  acquire(&p->lock);
    800021ce:	854e                	mv	a0,s3
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	a06080e7          	jalr	-1530(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    800021d8:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021dc:	854e                	mv	a0,s3
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	aac080e7          	jalr	-1364(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	9ee080e7          	jalr	-1554(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    800021f0:	854e                	mv	a0,s3
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	9e4080e7          	jalr	-1564(ra) # 80000bd6 <acquire>
  reparent(p);
    800021fa:	854e                	mv	a0,s3
    800021fc:	00000097          	auipc	ra,0x0
    80002200:	cc6080e7          	jalr	-826(ra) # 80001ec2 <reparent>
  wakeup1(original_parent);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	602080e7          	jalr	1538(ra) # 80001808 <wakeup1>
  p->xstate = status;
    8000220e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002212:	4791                	li	a5,4
    80002214:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a70080e7          	jalr	-1424(ra) # 80000c8a <release>
  sched();
    80002222:	00000097          	auipc	ra,0x0
    80002226:	dca080e7          	jalr	-566(ra) # 80001fec <sched>
  panic("zombie exit");
    8000222a:	00006517          	auipc	a0,0x6
    8000222e:	fee50513          	addi	a0,a0,-18 # 80008218 <digits+0x1d8>
    80002232:	ffffe097          	auipc	ra,0xffffe
    80002236:	2fe080e7          	jalr	766(ra) # 80000530 <panic>

000000008000223a <yield>:
{
    8000223a:	1101                	addi	sp,sp,-32
    8000223c:	ec06                	sd	ra,24(sp)
    8000223e:	e822                	sd	s0,16(sp)
    80002240:	e426                	sd	s1,8(sp)
    80002242:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	762080e7          	jalr	1890(ra) # 800019a6 <myproc>
    8000224c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	988080e7          	jalr	-1656(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002256:	4789                	li	a5,2
    80002258:	cc9c                	sw	a5,24(s1)
  sched();
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	d92080e7          	jalr	-622(ra) # 80001fec <sched>
  release(&p->lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a26080e7          	jalr	-1498(ra) # 80000c8a <release>
}
    8000226c:	60e2                	ld	ra,24(sp)
    8000226e:	6442                	ld	s0,16(sp)
    80002270:	64a2                	ld	s1,8(sp)
    80002272:	6105                	addi	sp,sp,32
    80002274:	8082                	ret

0000000080002276 <sleep>:
{
    80002276:	7179                	addi	sp,sp,-48
    80002278:	f406                	sd	ra,40(sp)
    8000227a:	f022                	sd	s0,32(sp)
    8000227c:	ec26                	sd	s1,24(sp)
    8000227e:	e84a                	sd	s2,16(sp)
    80002280:	e44e                	sd	s3,8(sp)
    80002282:	1800                	addi	s0,sp,48
    80002284:	89aa                	mv	s3,a0
    80002286:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	71e080e7          	jalr	1822(ra) # 800019a6 <myproc>
    80002290:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002292:	05250663          	beq	a0,s2,800022de <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	940080e7          	jalr	-1728(ra) # 80000bd6 <acquire>
    release(lk);
    8000229e:	854a                	mv	a0,s2
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9ea080e7          	jalr	-1558(ra) # 80000c8a <release>
  p->chan = chan;
    800022a8:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022ac:	4785                	li	a5,1
    800022ae:	cc9c                	sw	a5,24(s1)
  sched();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	d3c080e7          	jalr	-708(ra) # 80001fec <sched>
  p->chan = 0;
    800022b8:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9cc080e7          	jalr	-1588(ra) # 80000c8a <release>
    acquire(lk);
    800022c6:	854a                	mv	a0,s2
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	90e080e7          	jalr	-1778(ra) # 80000bd6 <acquire>
}
    800022d0:	70a2                	ld	ra,40(sp)
    800022d2:	7402                	ld	s0,32(sp)
    800022d4:	64e2                	ld	s1,24(sp)
    800022d6:	6942                	ld	s2,16(sp)
    800022d8:	69a2                	ld	s3,8(sp)
    800022da:	6145                	addi	sp,sp,48
    800022dc:	8082                	ret
  p->chan = chan;
    800022de:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022e2:	4785                	li	a5,1
    800022e4:	cd1c                	sw	a5,24(a0)
  sched();
    800022e6:	00000097          	auipc	ra,0x0
    800022ea:	d06080e7          	jalr	-762(ra) # 80001fec <sched>
  p->chan = 0;
    800022ee:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022f2:	bff9                	j	800022d0 <sleep+0x5a>

00000000800022f4 <wait>:
{
    800022f4:	715d                	addi	sp,sp,-80
    800022f6:	e486                	sd	ra,72(sp)
    800022f8:	e0a2                	sd	s0,64(sp)
    800022fa:	fc26                	sd	s1,56(sp)
    800022fc:	f84a                	sd	s2,48(sp)
    800022fe:	f44e                	sd	s3,40(sp)
    80002300:	f052                	sd	s4,32(sp)
    80002302:	ec56                	sd	s5,24(sp)
    80002304:	e85a                	sd	s6,16(sp)
    80002306:	e45e                	sd	s7,8(sp)
    80002308:	e062                	sd	s8,0(sp)
    8000230a:	0880                	addi	s0,sp,80
    8000230c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	698080e7          	jalr	1688(ra) # 800019a6 <myproc>
    80002316:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002318:	8c2a                	mv	s8,a0
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	8bc080e7          	jalr	-1860(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002322:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002324:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002326:	00021997          	auipc	s3,0x21
    8000232a:	d9298993          	addi	s3,s3,-622 # 800230b8 <tickslock>
        havekids = 1;
    8000232e:	4a85                	li	s5,1
    havekids = 0;
    80002330:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002332:	0000f497          	auipc	s1,0xf
    80002336:	38648493          	addi	s1,s1,902 # 800116b8 <proc>
    8000233a:	a08d                	j	8000239c <wait+0xa8>
          pid = np->pid;
    8000233c:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002340:	000b0e63          	beqz	s6,8000235c <wait+0x68>
    80002344:	4691                	li	a3,4
    80002346:	03448613          	addi	a2,s1,52
    8000234a:	85da                	mv	a1,s6
    8000234c:	05093503          	ld	a0,80(s2)
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	2ec080e7          	jalr	748(ra) # 8000163c <copyout>
    80002358:	02054263          	bltz	a0,8000237c <wait+0x88>
          freeproc(np);
    8000235c:	8526                	mv	a0,s1
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	7fa080e7          	jalr	2042(ra) # 80001b58 <freeproc>
          release(&np->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	922080e7          	jalr	-1758(ra) # 80000c8a <release>
          release(&p->lock);
    80002370:	854a                	mv	a0,s2
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	918080e7          	jalr	-1768(ra) # 80000c8a <release>
          return pid;
    8000237a:	a8a9                	j	800023d4 <wait+0xe0>
            release(&np->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	90c080e7          	jalr	-1780(ra) # 80000c8a <release>
            release(&p->lock);
    80002386:	854a                	mv	a0,s2
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	902080e7          	jalr	-1790(ra) # 80000c8a <release>
            return -1;
    80002390:	59fd                	li	s3,-1
    80002392:	a089                	j	800023d4 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002394:	46848493          	addi	s1,s1,1128
    80002398:	03348463          	beq	s1,s3,800023c0 <wait+0xcc>
      if(np->parent == p){
    8000239c:	709c                	ld	a5,32(s1)
    8000239e:	ff279be3          	bne	a5,s2,80002394 <wait+0xa0>
        acquire(&np->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	832080e7          	jalr	-1998(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    800023ac:	4c9c                	lw	a5,24(s1)
    800023ae:	f94787e3          	beq	a5,s4,8000233c <wait+0x48>
        release(&np->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
        havekids = 1;
    800023bc:	8756                	mv	a4,s5
    800023be:	bfd9                	j	80002394 <wait+0xa0>
    if(!havekids || p->killed){
    800023c0:	c701                	beqz	a4,800023c8 <wait+0xd4>
    800023c2:	03092783          	lw	a5,48(s2)
    800023c6:	c785                	beqz	a5,800023ee <wait+0xfa>
      release(&p->lock);
    800023c8:	854a                	mv	a0,s2
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	8c0080e7          	jalr	-1856(ra) # 80000c8a <release>
      return -1;
    800023d2:	59fd                	li	s3,-1
}
    800023d4:	854e                	mv	a0,s3
    800023d6:	60a6                	ld	ra,72(sp)
    800023d8:	6406                	ld	s0,64(sp)
    800023da:	74e2                	ld	s1,56(sp)
    800023dc:	7942                	ld	s2,48(sp)
    800023de:	79a2                	ld	s3,40(sp)
    800023e0:	7a02                	ld	s4,32(sp)
    800023e2:	6ae2                	ld	s5,24(sp)
    800023e4:	6b42                	ld	s6,16(sp)
    800023e6:	6ba2                	ld	s7,8(sp)
    800023e8:	6c02                	ld	s8,0(sp)
    800023ea:	6161                	addi	sp,sp,80
    800023ec:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023ee:	85e2                	mv	a1,s8
    800023f0:	854a                	mv	a0,s2
    800023f2:	00000097          	auipc	ra,0x0
    800023f6:	e84080e7          	jalr	-380(ra) # 80002276 <sleep>
    havekids = 0;
    800023fa:	bf1d                	j	80002330 <wait+0x3c>

00000000800023fc <wakeup>:
{
    800023fc:	7139                	addi	sp,sp,-64
    800023fe:	fc06                	sd	ra,56(sp)
    80002400:	f822                	sd	s0,48(sp)
    80002402:	f426                	sd	s1,40(sp)
    80002404:	f04a                	sd	s2,32(sp)
    80002406:	ec4e                	sd	s3,24(sp)
    80002408:	e852                	sd	s4,16(sp)
    8000240a:	e456                	sd	s5,8(sp)
    8000240c:	0080                	addi	s0,sp,64
    8000240e:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002410:	0000f497          	auipc	s1,0xf
    80002414:	2a848493          	addi	s1,s1,680 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002418:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000241a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000241c:	00021917          	auipc	s2,0x21
    80002420:	c9c90913          	addi	s2,s2,-868 # 800230b8 <tickslock>
    80002424:	a821                	j	8000243c <wakeup+0x40>
      p->state = RUNNABLE;
    80002426:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	85e080e7          	jalr	-1954(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002434:	46848493          	addi	s1,s1,1128
    80002438:	01248e63          	beq	s1,s2,80002454 <wakeup+0x58>
    acquire(&p->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	ffffe097          	auipc	ra,0xffffe
    80002442:	798080e7          	jalr	1944(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002446:	4c9c                	lw	a5,24(s1)
    80002448:	ff3791e3          	bne	a5,s3,8000242a <wakeup+0x2e>
    8000244c:	749c                	ld	a5,40(s1)
    8000244e:	fd479ee3          	bne	a5,s4,8000242a <wakeup+0x2e>
    80002452:	bfd1                	j	80002426 <wakeup+0x2a>
}
    80002454:	70e2                	ld	ra,56(sp)
    80002456:	7442                	ld	s0,48(sp)
    80002458:	74a2                	ld	s1,40(sp)
    8000245a:	7902                	ld	s2,32(sp)
    8000245c:	69e2                	ld	s3,24(sp)
    8000245e:	6a42                	ld	s4,16(sp)
    80002460:	6aa2                	ld	s5,8(sp)
    80002462:	6121                	addi	sp,sp,64
    80002464:	8082                	ret

0000000080002466 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	1800                	addi	s0,sp,48
    80002474:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002476:	0000f497          	auipc	s1,0xf
    8000247a:	24248493          	addi	s1,s1,578 # 800116b8 <proc>
    8000247e:	00021997          	auipc	s3,0x21
    80002482:	c3a98993          	addi	s3,s3,-966 # 800230b8 <tickslock>
    acquire(&p->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	ffffe097          	auipc	ra,0xffffe
    8000248c:	74e080e7          	jalr	1870(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002490:	5c9c                	lw	a5,56(s1)
    80002492:	01278d63          	beq	a5,s2,800024ac <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	7f2080e7          	jalr	2034(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024a0:	46848493          	addi	s1,s1,1128
    800024a4:	ff3491e3          	bne	s1,s3,80002486 <kill+0x20>
  }
  return -1;
    800024a8:	557d                	li	a0,-1
    800024aa:	a829                	j	800024c4 <kill+0x5e>
      p->killed = 1;
    800024ac:	4785                	li	a5,1
    800024ae:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024b0:	4c98                	lw	a4,24(s1)
    800024b2:	4785                	li	a5,1
    800024b4:	00f70f63          	beq	a4,a5,800024d2 <kill+0x6c>
      release(&p->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	7d0080e7          	jalr	2000(ra) # 80000c8a <release>
      return 0;
    800024c2:	4501                	li	a0,0
}
    800024c4:	70a2                	ld	ra,40(sp)
    800024c6:	7402                	ld	s0,32(sp)
    800024c8:	64e2                	ld	s1,24(sp)
    800024ca:	6942                	ld	s2,16(sp)
    800024cc:	69a2                	ld	s3,8(sp)
    800024ce:	6145                	addi	sp,sp,48
    800024d0:	8082                	ret
        p->state = RUNNABLE;
    800024d2:	4789                	li	a5,2
    800024d4:	cc9c                	sw	a5,24(s1)
    800024d6:	b7cd                	j	800024b8 <kill+0x52>

00000000800024d8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024d8:	7179                	addi	sp,sp,-48
    800024da:	f406                	sd	ra,40(sp)
    800024dc:	f022                	sd	s0,32(sp)
    800024de:	ec26                	sd	s1,24(sp)
    800024e0:	e84a                	sd	s2,16(sp)
    800024e2:	e44e                	sd	s3,8(sp)
    800024e4:	e052                	sd	s4,0(sp)
    800024e6:	1800                	addi	s0,sp,48
    800024e8:	84aa                	mv	s1,a0
    800024ea:	892e                	mv	s2,a1
    800024ec:	89b2                	mv	s3,a2
    800024ee:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	4b6080e7          	jalr	1206(ra) # 800019a6 <myproc>
  if(user_dst){
    800024f8:	c08d                	beqz	s1,8000251a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024fa:	86d2                	mv	a3,s4
    800024fc:	864e                	mv	a2,s3
    800024fe:	85ca                	mv	a1,s2
    80002500:	6928                	ld	a0,80(a0)
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	13a080e7          	jalr	314(ra) # 8000163c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000250a:	70a2                	ld	ra,40(sp)
    8000250c:	7402                	ld	s0,32(sp)
    8000250e:	64e2                	ld	s1,24(sp)
    80002510:	6942                	ld	s2,16(sp)
    80002512:	69a2                	ld	s3,8(sp)
    80002514:	6a02                	ld	s4,0(sp)
    80002516:	6145                	addi	sp,sp,48
    80002518:	8082                	ret
    memmove((char *)dst, src, len);
    8000251a:	000a061b          	sext.w	a2,s4
    8000251e:	85ce                	mv	a1,s3
    80002520:	854a                	mv	a0,s2
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	810080e7          	jalr	-2032(ra) # 80000d32 <memmove>
    return 0;
    8000252a:	8526                	mv	a0,s1
    8000252c:	bff9                	j	8000250a <either_copyout+0x32>

000000008000252e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000252e:	7179                	addi	sp,sp,-48
    80002530:	f406                	sd	ra,40(sp)
    80002532:	f022                	sd	s0,32(sp)
    80002534:	ec26                	sd	s1,24(sp)
    80002536:	e84a                	sd	s2,16(sp)
    80002538:	e44e                	sd	s3,8(sp)
    8000253a:	e052                	sd	s4,0(sp)
    8000253c:	1800                	addi	s0,sp,48
    8000253e:	892a                	mv	s2,a0
    80002540:	84ae                	mv	s1,a1
    80002542:	89b2                	mv	s3,a2
    80002544:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002546:	fffff097          	auipc	ra,0xfffff
    8000254a:	460080e7          	jalr	1120(ra) # 800019a6 <myproc>
  if(user_src){
    8000254e:	c08d                	beqz	s1,80002570 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002550:	86d2                	mv	a3,s4
    80002552:	864e                	mv	a2,s3
    80002554:	85ca                	mv	a1,s2
    80002556:	6928                	ld	a0,80(a0)
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	170080e7          	jalr	368(ra) # 800016c8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002560:	70a2                	ld	ra,40(sp)
    80002562:	7402                	ld	s0,32(sp)
    80002564:	64e2                	ld	s1,24(sp)
    80002566:	6942                	ld	s2,16(sp)
    80002568:	69a2                	ld	s3,8(sp)
    8000256a:	6a02                	ld	s4,0(sp)
    8000256c:	6145                	addi	sp,sp,48
    8000256e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002570:	000a061b          	sext.w	a2,s4
    80002574:	85ce                	mv	a1,s3
    80002576:	854a                	mv	a0,s2
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	7ba080e7          	jalr	1978(ra) # 80000d32 <memmove>
    return 0;
    80002580:	8526                	mv	a0,s1
    80002582:	bff9                	j	80002560 <either_copyin+0x32>

0000000080002584 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002584:	715d                	addi	sp,sp,-80
    80002586:	e486                	sd	ra,72(sp)
    80002588:	e0a2                	sd	s0,64(sp)
    8000258a:	fc26                	sd	s1,56(sp)
    8000258c:	f84a                	sd	s2,48(sp)
    8000258e:	f44e                	sd	s3,40(sp)
    80002590:	f052                	sd	s4,32(sp)
    80002592:	ec56                	sd	s5,24(sp)
    80002594:	e85a                	sd	s6,16(sp)
    80002596:	e45e                	sd	s7,8(sp)
    80002598:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000259a:	00006517          	auipc	a0,0x6
    8000259e:	b2e50513          	addi	a0,a0,-1234 # 800080c8 <digits+0x88>
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	fd8080e7          	jalr	-40(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025aa:	0000f497          	auipc	s1,0xf
    800025ae:	26648493          	addi	s1,s1,614 # 80011810 <proc+0x158>
    800025b2:	00021917          	auipc	s2,0x21
    800025b6:	c5e90913          	addi	s2,s2,-930 # 80023210 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ba:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025bc:	00006997          	auipc	s3,0x6
    800025c0:	c6c98993          	addi	s3,s3,-916 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    800025c4:	00006a97          	auipc	s5,0x6
    800025c8:	c6ca8a93          	addi	s5,s5,-916 # 80008230 <digits+0x1f0>
    printf("\n");
    800025cc:	00006a17          	auipc	s4,0x6
    800025d0:	afca0a13          	addi	s4,s4,-1284 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d4:	00006b97          	auipc	s7,0x6
    800025d8:	c94b8b93          	addi	s7,s7,-876 # 80008268 <states.1727>
    800025dc:	a00d                	j	800025fe <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025de:	ee06a583          	lw	a1,-288(a3)
    800025e2:	8556                	mv	a0,s5
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	f96080e7          	jalr	-106(ra) # 8000057a <printf>
    printf("\n");
    800025ec:	8552                	mv	a0,s4
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	f8c080e7          	jalr	-116(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f6:	46848493          	addi	s1,s1,1128
    800025fa:	03248163          	beq	s1,s2,8000261c <procdump+0x98>
    if(p->state == UNUSED)
    800025fe:	86a6                	mv	a3,s1
    80002600:	ec04a783          	lw	a5,-320(s1)
    80002604:	dbed                	beqz	a5,800025f6 <procdump+0x72>
      state = "???";
    80002606:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	fcfb6be3          	bltu	s6,a5,800025de <procdump+0x5a>
    8000260c:	1782                	slli	a5,a5,0x20
    8000260e:	9381                	srli	a5,a5,0x20
    80002610:	078e                	slli	a5,a5,0x3
    80002612:	97de                	add	a5,a5,s7
    80002614:	6390                	ld	a2,0(a5)
    80002616:	f661                	bnez	a2,800025de <procdump+0x5a>
      state = "???";
    80002618:	864e                	mv	a2,s3
    8000261a:	b7d1                	j	800025de <procdump+0x5a>
  }
}
    8000261c:	60a6                	ld	ra,72(sp)
    8000261e:	6406                	ld	s0,64(sp)
    80002620:	74e2                	ld	s1,56(sp)
    80002622:	7942                	ld	s2,48(sp)
    80002624:	79a2                	ld	s3,40(sp)
    80002626:	7a02                	ld	s4,32(sp)
    80002628:	6ae2                	ld	s5,24(sp)
    8000262a:	6b42                	ld	s6,16(sp)
    8000262c:	6ba2                	ld	s7,8(sp)
    8000262e:	6161                	addi	sp,sp,80
    80002630:	8082                	ret

0000000080002632 <swtch>:
    80002632:	00153023          	sd	ra,0(a0)
    80002636:	00253423          	sd	sp,8(a0)
    8000263a:	e900                	sd	s0,16(a0)
    8000263c:	ed04                	sd	s1,24(a0)
    8000263e:	03253023          	sd	s2,32(a0)
    80002642:	03353423          	sd	s3,40(a0)
    80002646:	03453823          	sd	s4,48(a0)
    8000264a:	03553c23          	sd	s5,56(a0)
    8000264e:	05653023          	sd	s6,64(a0)
    80002652:	05753423          	sd	s7,72(a0)
    80002656:	05853823          	sd	s8,80(a0)
    8000265a:	05953c23          	sd	s9,88(a0)
    8000265e:	07a53023          	sd	s10,96(a0)
    80002662:	07b53423          	sd	s11,104(a0)
    80002666:	0005b083          	ld	ra,0(a1)
    8000266a:	0085b103          	ld	sp,8(a1)
    8000266e:	6980                	ld	s0,16(a1)
    80002670:	6d84                	ld	s1,24(a1)
    80002672:	0205b903          	ld	s2,32(a1)
    80002676:	0285b983          	ld	s3,40(a1)
    8000267a:	0305ba03          	ld	s4,48(a1)
    8000267e:	0385ba83          	ld	s5,56(a1)
    80002682:	0405bb03          	ld	s6,64(a1)
    80002686:	0485bb83          	ld	s7,72(a1)
    8000268a:	0505bc03          	ld	s8,80(a1)
    8000268e:	0585bc83          	ld	s9,88(a1)
    80002692:	0605bd03          	ld	s10,96(a1)
    80002696:	0685bd83          	ld	s11,104(a1)
    8000269a:	8082                	ret

000000008000269c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000269c:	1141                	addi	sp,sp,-16
    8000269e:	e406                	sd	ra,8(sp)
    800026a0:	e022                	sd	s0,0(sp)
    800026a2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026a4:	00006597          	auipc	a1,0x6
    800026a8:	bec58593          	addi	a1,a1,-1044 # 80008290 <states.1727+0x28>
    800026ac:	00021517          	auipc	a0,0x21
    800026b0:	a0c50513          	addi	a0,a0,-1524 # 800230b8 <tickslock>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	492080e7          	jalr	1170(ra) # 80000b46 <initlock>
}
    800026bc:	60a2                	ld	ra,8(sp)
    800026be:	6402                	ld	s0,0(sp)
    800026c0:	0141                	addi	sp,sp,16
    800026c2:	8082                	ret

00000000800026c4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026c4:	1141                	addi	sp,sp,-16
    800026c6:	e422                	sd	s0,8(sp)
    800026c8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ca:	00004797          	auipc	a5,0x4
    800026ce:	91678793          	addi	a5,a5,-1770 # 80005fe0 <kernelvec>
    800026d2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026d6:	6422                	ld	s0,8(sp)
    800026d8:	0141                	addi	sp,sp,16
    800026da:	8082                	ret

00000000800026dc <mmap_handler>:

  usertrapret();
}


int mmap_handler(int va, int cause) {
    800026dc:	7139                	addi	sp,sp,-64
    800026de:	fc06                	sd	ra,56(sp)
    800026e0:	f822                	sd	s0,48(sp)
    800026e2:	f426                	sd	s1,40(sp)
    800026e4:	f04a                	sd	s2,32(sp)
    800026e6:	ec4e                	sd	s3,24(sp)
    800026e8:	e852                	sd	s4,16(sp)
    800026ea:	e456                	sd	s5,8(sp)
    800026ec:	e05a                	sd	s6,0(sp)
    800026ee:	0080                	addi	s0,sp,64
    800026f0:	892a                	mv	s2,a0
    800026f2:	8a2e                	mv	s4,a1
  int i;
  struct proc* p = myproc();
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	2b2080e7          	jalr	690(ra) # 800019a6 <myproc>
    800026fc:	89aa                	mv	s3,a0
  // 根据地址查找属于哪一个VMA
  for(i = 0; i < NVMA; ++i) {
    800026fe:	16850793          	addi	a5,a0,360
    80002702:	4481                	li	s1,0
    if(p->vma[i].used && p->vma[i].addr <= va && va <= p->vma[i].addr + p->vma[i].len - 1) {
    80002704:	85ca                	mv	a1,s2
  for(i = 0; i < NVMA; ++i) {
    80002706:	4641                	li	a2,16
    80002708:	a031                	j	80002714 <mmap_handler+0x38>
    8000270a:	2485                	addiw	s1,s1,1
    8000270c:	03078793          	addi	a5,a5,48
    80002710:	0ec48f63          	beq	s1,a2,8000280e <mmap_handler+0x132>
    if(p->vma[i].used && p->vma[i].addr <= va && va <= p->vma[i].addr + p->vma[i].len - 1) {
    80002714:	4398                	lw	a4,0(a5)
    80002716:	db75                	beqz	a4,8000270a <mmap_handler+0x2e>
    80002718:	6798                	ld	a4,8(a5)
    8000271a:	fee968e3          	bltu	s2,a4,8000270a <mmap_handler+0x2e>
    8000271e:	4b94                	lw	a3,16(a5)
    80002720:	177d                	addi	a4,a4,-1
    80002722:	9736                	add	a4,a4,a3
    80002724:	feb763e3          	bltu	a4,a1,8000270a <mmap_handler+0x2e>
      break;
    }
  }
  if(i == NVMA)
    80002728:	47c1                	li	a5,16
    8000272a:	10f48d63          	beq	s1,a5,80002844 <mmap_handler+0x168>
    return -1;

  int pte_flags = PTE_U;
  if(p->vma[i].prot & PROT_READ) pte_flags |= PTE_R;
    8000272e:	00149793          	slli	a5,s1,0x1
    80002732:	97a6                	add	a5,a5,s1
    80002734:	0792                	slli	a5,a5,0x4
    80002736:	97ce                	add	a5,a5,s3
    80002738:	17c7a783          	lw	a5,380(a5)
    8000273c:	0017f713          	andi	a4,a5,1
  int pte_flags = PTE_U;
    80002740:	4ac1                	li	s5,16
  if(p->vma[i].prot & PROT_READ) pte_flags |= PTE_R;
    80002742:	c311                	beqz	a4,80002746 <mmap_handler+0x6a>
    80002744:	4ac9                	li	s5,18
  if(p->vma[i].prot & PROT_WRITE) pte_flags |= PTE_W;
    80002746:	0027f713          	andi	a4,a5,2
    8000274a:	c319                	beqz	a4,80002750 <mmap_handler+0x74>
    8000274c:	004aea93          	ori	s5,s5,4
  if(p->vma[i].prot & PROT_EXEC) pte_flags |= PTE_X;
    80002750:	8b91                	andi	a5,a5,4
    80002752:	c399                	beqz	a5,80002758 <mmap_handler+0x7c>
    80002754:	008aea93          	ori	s5,s5,8


  struct file* vf = p->vma[i].vfile;
    80002758:	00149793          	slli	a5,s1,0x1
    8000275c:	97a6                	add	a5,a5,s1
    8000275e:	0792                	slli	a5,a5,0x4
    80002760:	97ce                	add	a5,a5,s3
    80002762:	1887bb03          	ld	s6,392(a5)
  // 读导致的页面错误
  if(cause == 13 && vf->readable == 0) return -1;
    80002766:	47b5                	li	a5,13
    80002768:	0afa0563          	beq	s4,a5,80002812 <mmap_handler+0x136>
  // 写导致的页面错误
  if(cause == 15 && vf->writable == 0) return -1;
    8000276c:	47bd                	li	a5,15
    8000276e:	00fa1563          	bne	s4,a5,80002778 <mmap_handler+0x9c>
    80002772:	009b4783          	lbu	a5,9(s6)
    80002776:	cbe9                	beqz	a5,80002848 <mmap_handler+0x16c>

  void* pa = kalloc();
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	36e080e7          	jalr	878(ra) # 80000ae6 <kalloc>
    80002780:	8a2a                	mv	s4,a0
  if(pa == 0)
    80002782:	c569                	beqz	a0,8000284c <mmap_handler+0x170>
    return -1;
  memset(pa, 0, PGSIZE);
    80002784:	6605                	lui	a2,0x1
    80002786:	4581                	li	a1,0
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	54a080e7          	jalr	1354(ra) # 80000cd2 <memset>

  // 读取文件内容
  ilock(vf->ip);
    80002790:	018b3503          	ld	a0,24(s6)
    80002794:	00001097          	auipc	ra,0x1
    80002798:	0ca080e7          	jalr	202(ra) # 8000385e <ilock>
  // 计算当前页面读取文件的偏移量，实验中p->vma[i].offset总是0
  // 要按顺序读读取，例如内存页面A,B和文件块a,b
  // 则A读取a，B读取b，而不能A读取b，B读取a
  int offset = p->vma[i].offset + PGROUNDDOWN(va - p->vma[i].addr);
    8000279c:	00149793          	slli	a5,s1,0x1
    800027a0:	00978733          	add	a4,a5,s1
    800027a4:	0712                	slli	a4,a4,0x4
    800027a6:	974e                	add	a4,a4,s3
    800027a8:	17073683          	ld	a3,368(a4)
    800027ac:	40d906bb          	subw	a3,s2,a3
    800027b0:	777d                	lui	a4,0xfffff
    800027b2:	8ef9                	and	a3,a3,a4
    800027b4:	97a6                	add	a5,a5,s1
    800027b6:	0792                	slli	a5,a5,0x4
    800027b8:	97ce                	add	a5,a5,s3
    800027ba:	1907a783          	lw	a5,400(a5)
  int readbytes = readi(vf->ip, 0, (uint64)pa, offset, PGSIZE);
    800027be:	6705                	lui	a4,0x1
    800027c0:	9ebd                	addw	a3,a3,a5
    800027c2:	8652                	mv	a2,s4
    800027c4:	4581                	li	a1,0
    800027c6:	018b3503          	ld	a0,24(s6)
    800027ca:	00001097          	auipc	ra,0x1
    800027ce:	348080e7          	jalr	840(ra) # 80003b12 <readi>
  // 什么都没有读到
  if(readbytes == 0) {
    800027d2:	c529                	beqz	a0,8000281c <mmap_handler+0x140>
    iunlock(vf->ip);
    kfree(pa);
    return -1;
  }
  iunlock(vf->ip);
    800027d4:	018b3503          	ld	a0,24(s6)
    800027d8:	00001097          	auipc	ra,0x1
    800027dc:	148080e7          	jalr	328(ra) # 80003920 <iunlock>

  // 添加页面映射
  if(mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)pa, pte_flags) != 0) {
    800027e0:	8756                	mv	a4,s5
    800027e2:	86d2                	mv	a3,s4
    800027e4:	6605                	lui	a2,0x1
    800027e6:	75fd                	lui	a1,0xfffff
    800027e8:	00b975b3          	and	a1,s2,a1
    800027ec:	0509b503          	ld	a0,80(s3)
    800027f0:	fffff097          	auipc	ra,0xfffff
    800027f4:	8b6080e7          	jalr	-1866(ra) # 800010a6 <mappages>
    800027f8:	ed1d                	bnez	a0,80002836 <mmap_handler+0x15a>
    kfree(pa);
    return -1;
  }

  return 0;
}
    800027fa:	70e2                	ld	ra,56(sp)
    800027fc:	7442                	ld	s0,48(sp)
    800027fe:	74a2                	ld	s1,40(sp)
    80002800:	7902                	ld	s2,32(sp)
    80002802:	69e2                	ld	s3,24(sp)
    80002804:	6a42                	ld	s4,16(sp)
    80002806:	6aa2                	ld	s5,8(sp)
    80002808:	6b02                	ld	s6,0(sp)
    8000280a:	6121                	addi	sp,sp,64
    8000280c:	8082                	ret
    return -1;
    8000280e:	557d                	li	a0,-1
    80002810:	b7ed                	j	800027fa <mmap_handler+0x11e>
  if(cause == 13 && vf->readable == 0) return -1;
    80002812:	008b4783          	lbu	a5,8(s6)
    80002816:	f3ad                	bnez	a5,80002778 <mmap_handler+0x9c>
    80002818:	557d                	li	a0,-1
    8000281a:	b7c5                	j	800027fa <mmap_handler+0x11e>
    iunlock(vf->ip);
    8000281c:	018b3503          	ld	a0,24(s6)
    80002820:	00001097          	auipc	ra,0x1
    80002824:	100080e7          	jalr	256(ra) # 80003920 <iunlock>
    kfree(pa);
    80002828:	8552                	mv	a0,s4
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	1c0080e7          	jalr	448(ra) # 800009ea <kfree>
    return -1;
    80002832:	557d                	li	a0,-1
    80002834:	b7d9                	j	800027fa <mmap_handler+0x11e>
    kfree(pa);
    80002836:	8552                	mv	a0,s4
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	1b2080e7          	jalr	434(ra) # 800009ea <kfree>
    return -1;
    80002840:	557d                	li	a0,-1
    80002842:	bf65                	j	800027fa <mmap_handler+0x11e>
    return -1;
    80002844:	557d                	li	a0,-1
    80002846:	bf55                	j	800027fa <mmap_handler+0x11e>
  if(cause == 15 && vf->writable == 0) return -1;
    80002848:	557d                	li	a0,-1
    8000284a:	bf45                	j	800027fa <mmap_handler+0x11e>
    return -1;
    8000284c:	557d                	li	a0,-1
    8000284e:	b775                	j	800027fa <mmap_handler+0x11e>

0000000080002850 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002850:	1141                	addi	sp,sp,-16
    80002852:	e406                	sd	ra,8(sp)
    80002854:	e022                	sd	s0,0(sp)
    80002856:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002858:	fffff097          	auipc	ra,0xfffff
    8000285c:	14e080e7          	jalr	334(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002860:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002864:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002866:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000286a:	00004617          	auipc	a2,0x4
    8000286e:	79660613          	addi	a2,a2,1942 # 80007000 <_trampoline>
    80002872:	00004697          	auipc	a3,0x4
    80002876:	78e68693          	addi	a3,a3,1934 # 80007000 <_trampoline>
    8000287a:	8e91                	sub	a3,a3,a2
    8000287c:	040007b7          	lui	a5,0x4000
    80002880:	17fd                	addi	a5,a5,-1
    80002882:	07b2                	slli	a5,a5,0xc
    80002884:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002886:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000288a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000288c:	180026f3          	csrr	a3,satp
    80002890:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002892:	6d38                	ld	a4,88(a0)
    80002894:	6134                	ld	a3,64(a0)
    80002896:	6585                	lui	a1,0x1
    80002898:	96ae                	add	a3,a3,a1
    8000289a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000289c:	6d38                	ld	a4,88(a0)
    8000289e:	00000697          	auipc	a3,0x0
    800028a2:	13868693          	addi	a3,a3,312 # 800029d6 <usertrap>
    800028a6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028a8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028aa:	8692                	mv	a3,tp
    800028ac:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ae:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028b2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028b6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ba:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028be:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028c0:	6f18                	ld	a4,24(a4)
    800028c2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028c6:	692c                	ld	a1,80(a0)
    800028c8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028ca:	00004717          	auipc	a4,0x4
    800028ce:	7c670713          	addi	a4,a4,1990 # 80007090 <userret>
    800028d2:	8f11                	sub	a4,a4,a2
    800028d4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028d6:	577d                	li	a4,-1
    800028d8:	177e                	slli	a4,a4,0x3f
    800028da:	8dd9                	or	a1,a1,a4
    800028dc:	02000537          	lui	a0,0x2000
    800028e0:	157d                	addi	a0,a0,-1
    800028e2:	0536                	slli	a0,a0,0xd
    800028e4:	9782                	jalr	a5
}
    800028e6:	60a2                	ld	ra,8(sp)
    800028e8:	6402                	ld	s0,0(sp)
    800028ea:	0141                	addi	sp,sp,16
    800028ec:	8082                	ret

00000000800028ee <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028ee:	1101                	addi	sp,sp,-32
    800028f0:	ec06                	sd	ra,24(sp)
    800028f2:	e822                	sd	s0,16(sp)
    800028f4:	e426                	sd	s1,8(sp)
    800028f6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028f8:	00020497          	auipc	s1,0x20
    800028fc:	7c048493          	addi	s1,s1,1984 # 800230b8 <tickslock>
    80002900:	8526                	mv	a0,s1
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	2d4080e7          	jalr	724(ra) # 80000bd6 <acquire>
  ticks++;
    8000290a:	00006517          	auipc	a0,0x6
    8000290e:	72650513          	addi	a0,a0,1830 # 80009030 <ticks>
    80002912:	411c                	lw	a5,0(a0)
    80002914:	2785                	addiw	a5,a5,1
    80002916:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	ae4080e7          	jalr	-1308(ra) # 800023fc <wakeup>
  release(&tickslock);
    80002920:	8526                	mv	a0,s1
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	368080e7          	jalr	872(ra) # 80000c8a <release>
}
    8000292a:	60e2                	ld	ra,24(sp)
    8000292c:	6442                	ld	s0,16(sp)
    8000292e:	64a2                	ld	s1,8(sp)
    80002930:	6105                	addi	sp,sp,32
    80002932:	8082                	ret

0000000080002934 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002934:	1101                	addi	sp,sp,-32
    80002936:	ec06                	sd	ra,24(sp)
    80002938:	e822                	sd	s0,16(sp)
    8000293a:	e426                	sd	s1,8(sp)
    8000293c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002942:	00074d63          	bltz	a4,8000295c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002946:	57fd                	li	a5,-1
    80002948:	17fe                	slli	a5,a5,0x3f
    8000294a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000294c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000294e:	06f70363          	beq	a4,a5,800029b4 <devintr+0x80>
  }
}
    80002952:	60e2                	ld	ra,24(sp)
    80002954:	6442                	ld	s0,16(sp)
    80002956:	64a2                	ld	s1,8(sp)
    80002958:	6105                	addi	sp,sp,32
    8000295a:	8082                	ret
     (scause & 0xff) == 9){
    8000295c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002960:	46a5                	li	a3,9
    80002962:	fed792e3          	bne	a5,a3,80002946 <devintr+0x12>
    int irq = plic_claim();
    80002966:	00003097          	auipc	ra,0x3
    8000296a:	782080e7          	jalr	1922(ra) # 800060e8 <plic_claim>
    8000296e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002970:	47a9                	li	a5,10
    80002972:	02f50763          	beq	a0,a5,800029a0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002976:	4785                	li	a5,1
    80002978:	02f50963          	beq	a0,a5,800029aa <devintr+0x76>
    return 1;
    8000297c:	4505                	li	a0,1
    } else if(irq){
    8000297e:	d8f1                	beqz	s1,80002952 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002980:	85a6                	mv	a1,s1
    80002982:	00006517          	auipc	a0,0x6
    80002986:	91650513          	addi	a0,a0,-1770 # 80008298 <states.1727+0x30>
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	bf0080e7          	jalr	-1040(ra) # 8000057a <printf>
      plic_complete(irq);
    80002992:	8526                	mv	a0,s1
    80002994:	00003097          	auipc	ra,0x3
    80002998:	778080e7          	jalr	1912(ra) # 8000610c <plic_complete>
    return 1;
    8000299c:	4505                	li	a0,1
    8000299e:	bf55                	j	80002952 <devintr+0x1e>
      uartintr();
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	ffa080e7          	jalr	-6(ra) # 8000099a <uartintr>
    800029a8:	b7ed                	j	80002992 <devintr+0x5e>
      virtio_disk_intr();
    800029aa:	00004097          	auipc	ra,0x4
    800029ae:	c42080e7          	jalr	-958(ra) # 800065ec <virtio_disk_intr>
    800029b2:	b7c5                	j	80002992 <devintr+0x5e>
    if(cpuid() == 0){
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	fc6080e7          	jalr	-58(ra) # 8000197a <cpuid>
    800029bc:	c901                	beqz	a0,800029cc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029be:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029c2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029c4:	14479073          	csrw	sip,a5
    return 2;
    800029c8:	4509                	li	a0,2
    800029ca:	b761                	j	80002952 <devintr+0x1e>
      clockintr();
    800029cc:	00000097          	auipc	ra,0x0
    800029d0:	f22080e7          	jalr	-222(ra) # 800028ee <clockintr>
    800029d4:	b7ed                	j	800029be <devintr+0x8a>

00000000800029d6 <usertrap>:
{
    800029d6:	1101                	addi	sp,sp,-32
    800029d8:	ec06                	sd	ra,24(sp)
    800029da:	e822                	sd	s0,16(sp)
    800029dc:	e426                	sd	s1,8(sp)
    800029de:	e04a                	sd	s2,0(sp)
    800029e0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029e6:	1007f793          	andi	a5,a5,256
    800029ea:	e3ad                	bnez	a5,80002a4c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ec:	00003797          	auipc	a5,0x3
    800029f0:	5f478793          	addi	a5,a5,1524 # 80005fe0 <kernelvec>
    800029f4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029f8:	fffff097          	auipc	ra,0xfffff
    800029fc:	fae080e7          	jalr	-82(ra) # 800019a6 <myproc>
    80002a00:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a02:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a04:	14102773          	csrr	a4,sepc
    80002a08:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a0e:	47a1                	li	a5,8
    80002a10:	04f71c63          	bne	a4,a5,80002a68 <usertrap+0x92>
    if(p->killed)
    80002a14:	591c                	lw	a5,48(a0)
    80002a16:	e3b9                	bnez	a5,80002a5c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a18:	6cb8                	ld	a4,88(s1)
    80002a1a:	6f1c                	ld	a5,24(a4)
    80002a1c:	0791                	addi	a5,a5,4
    80002a1e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a20:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a24:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a28:	10079073          	csrw	sstatus,a5
    syscall();
    80002a2c:	00000097          	auipc	ra,0x0
    80002a30:	334080e7          	jalr	820(ra) # 80002d60 <syscall>
  if(p->killed)
    80002a34:	589c                	lw	a5,48(s1)
    80002a36:	e3f5                	bnez	a5,80002b1a <usertrap+0x144>
  usertrapret();
    80002a38:	00000097          	auipc	ra,0x0
    80002a3c:	e18080e7          	jalr	-488(ra) # 80002850 <usertrapret>
}
    80002a40:	60e2                	ld	ra,24(sp)
    80002a42:	6442                	ld	s0,16(sp)
    80002a44:	64a2                	ld	s1,8(sp)
    80002a46:	6902                	ld	s2,0(sp)
    80002a48:	6105                	addi	sp,sp,32
    80002a4a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a4c:	00006517          	auipc	a0,0x6
    80002a50:	86c50513          	addi	a0,a0,-1940 # 800082b8 <states.1727+0x50>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	adc080e7          	jalr	-1316(ra) # 80000530 <panic>
      exit(-1);
    80002a5c:	557d                	li	a0,-1
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	664080e7          	jalr	1636(ra) # 800020c2 <exit>
    80002a66:	bf4d                	j	80002a18 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	ecc080e7          	jalr	-308(ra) # 80002934 <devintr>
    80002a70:	892a                	mv	s2,a0
    80002a72:	e14d                	bnez	a0,80002b14 <usertrap+0x13e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a74:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15) {
    80002a78:	47b5                	li	a5,13
    80002a7a:	00f70763          	beq	a4,a5,80002a88 <usertrap+0xb2>
    80002a7e:	14202773          	csrr	a4,scause
    80002a82:	47bd                	li	a5,15
    80002a84:	04f71e63          	bne	a4,a5,80002ae0 <usertrap+0x10a>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a88:	143026f3          	csrr	a3,stval
        if(PGROUNDUP(p->trapframe->sp) - 1 < fault_va && fault_va < p->sz) {
    80002a8c:	6cbc                	ld	a5,88(s1)
    80002a8e:	7b9c                	ld	a5,48(a5)
    80002a90:	6705                	lui	a4,0x1
    80002a92:	177d                	addi	a4,a4,-1
    80002a94:	97ba                	add	a5,a5,a4
    80002a96:	777d                	lui	a4,0xfffff
    80002a98:	8ff9                	and	a5,a5,a4
    80002a9a:	17fd                	addi	a5,a5,-1
    80002a9c:	00d7f563          	bgeu	a5,a3,80002aa6 <usertrap+0xd0>
    80002aa0:	64bc                	ld	a5,72(s1)
    80002aa2:	02f6e163          	bltu	a3,a5,80002ac4 <usertrap+0xee>
          p->killed = 1;
    80002aa6:	4785                	li	a5,1
    80002aa8:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002aaa:	557d                	li	a0,-1
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	616080e7          	jalr	1558(ra) # 800020c2 <exit>
  if(which_dev == 2)
    80002ab4:	4789                	li	a5,2
    80002ab6:	f8f911e3          	bne	s2,a5,80002a38 <usertrap+0x62>
    yield();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	780080e7          	jalr	1920(ra) # 8000223a <yield>
    80002ac2:	bf9d                	j	80002a38 <usertrap+0x62>
    80002ac4:	14302573          	csrr	a0,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac8:	142025f3          	csrr	a1,scause
          if(mmap_handler(r_stval(), r_scause()) != 0) p->killed = 1;
    80002acc:	2581                	sext.w	a1,a1
    80002ace:	2501                	sext.w	a0,a0
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	c0c080e7          	jalr	-1012(ra) # 800026dc <mmap_handler>
    80002ad8:	dd31                	beqz	a0,80002a34 <usertrap+0x5e>
    80002ada:	4785                	li	a5,1
    80002adc:	d89c                	sw	a5,48(s1)
    80002ade:	b7f1                	j	80002aaa <usertrap+0xd4>
    80002ae0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ae4:	5c90                	lw	a2,56(s1)
    80002ae6:	00005517          	auipc	a0,0x5
    80002aea:	7f250513          	addi	a0,a0,2034 # 800082d8 <states.1727+0x70>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a8c080e7          	jalr	-1396(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002afa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	80a50513          	addi	a0,a0,-2038 # 80008308 <states.1727+0xa0>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a74080e7          	jalr	-1420(ra) # 8000057a <printf>
    p->killed = 1;
    80002b0e:	4785                	li	a5,1
    80002b10:	d89c                	sw	a5,48(s1)
    80002b12:	bf61                	j	80002aaa <usertrap+0xd4>
  if(p->killed)
    80002b14:	589c                	lw	a5,48(s1)
    80002b16:	dfd9                	beqz	a5,80002ab4 <usertrap+0xde>
    80002b18:	bf49                	j	80002aaa <usertrap+0xd4>
    80002b1a:	4901                	li	s2,0
    80002b1c:	b779                	j	80002aaa <usertrap+0xd4>

0000000080002b1e <kerneltrap>:
{
    80002b1e:	7179                	addi	sp,sp,-48
    80002b20:	f406                	sd	ra,40(sp)
    80002b22:	f022                	sd	s0,32(sp)
    80002b24:	ec26                	sd	s1,24(sp)
    80002b26:	e84a                	sd	s2,16(sp)
    80002b28:	e44e                	sd	s3,8(sp)
    80002b2a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b2c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b30:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b34:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b38:	1004f793          	andi	a5,s1,256
    80002b3c:	cb85                	beqz	a5,80002b6c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b42:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b44:	ef85                	bnez	a5,80002b7c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b46:	00000097          	auipc	ra,0x0
    80002b4a:	dee080e7          	jalr	-530(ra) # 80002934 <devintr>
    80002b4e:	cd1d                	beqz	a0,80002b8c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b50:	4789                	li	a5,2
    80002b52:	06f50a63          	beq	a0,a5,80002bc6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b56:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b5a:	10049073          	csrw	sstatus,s1
}
    80002b5e:	70a2                	ld	ra,40(sp)
    80002b60:	7402                	ld	s0,32(sp)
    80002b62:	64e2                	ld	s1,24(sp)
    80002b64:	6942                	ld	s2,16(sp)
    80002b66:	69a2                	ld	s3,8(sp)
    80002b68:	6145                	addi	sp,sp,48
    80002b6a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b6c:	00005517          	auipc	a0,0x5
    80002b70:	7bc50513          	addi	a0,a0,1980 # 80008328 <states.1727+0xc0>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	9bc080e7          	jalr	-1604(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b7c:	00005517          	auipc	a0,0x5
    80002b80:	7d450513          	addi	a0,a0,2004 # 80008350 <states.1727+0xe8>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	9ac080e7          	jalr	-1620(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002b8c:	85ce                	mv	a1,s3
    80002b8e:	00005517          	auipc	a0,0x5
    80002b92:	7e250513          	addi	a0,a0,2018 # 80008370 <states.1727+0x108>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	9e4080e7          	jalr	-1564(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b9e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ba2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ba6:	00005517          	auipc	a0,0x5
    80002baa:	7da50513          	addi	a0,a0,2010 # 80008380 <states.1727+0x118>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	9cc080e7          	jalr	-1588(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002bb6:	00005517          	auipc	a0,0x5
    80002bba:	7e250513          	addi	a0,a0,2018 # 80008398 <states.1727+0x130>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	972080e7          	jalr	-1678(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	de0080e7          	jalr	-544(ra) # 800019a6 <myproc>
    80002bce:	d541                	beqz	a0,80002b56 <kerneltrap+0x38>
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	dd6080e7          	jalr	-554(ra) # 800019a6 <myproc>
    80002bd8:	4d18                	lw	a4,24(a0)
    80002bda:	478d                	li	a5,3
    80002bdc:	f6f71de3          	bne	a4,a5,80002b56 <kerneltrap+0x38>
    yield();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	65a080e7          	jalr	1626(ra) # 8000223a <yield>
    80002be8:	b7bd                	j	80002b56 <kerneltrap+0x38>

0000000080002bea <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bea:	1101                	addi	sp,sp,-32
    80002bec:	ec06                	sd	ra,24(sp)
    80002bee:	e822                	sd	s0,16(sp)
    80002bf0:	e426                	sd	s1,8(sp)
    80002bf2:	1000                	addi	s0,sp,32
    80002bf4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	db0080e7          	jalr	-592(ra) # 800019a6 <myproc>
  switch (n) {
    80002bfe:	4795                	li	a5,5
    80002c00:	0497e163          	bltu	a5,s1,80002c42 <argraw+0x58>
    80002c04:	048a                	slli	s1,s1,0x2
    80002c06:	00005717          	auipc	a4,0x5
    80002c0a:	7ca70713          	addi	a4,a4,1994 # 800083d0 <states.1727+0x168>
    80002c0e:	94ba                	add	s1,s1,a4
    80002c10:	409c                	lw	a5,0(s1)
    80002c12:	97ba                	add	a5,a5,a4
    80002c14:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c16:	6d3c                	ld	a5,88(a0)
    80002c18:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret
    return p->trapframe->a1;
    80002c24:	6d3c                	ld	a5,88(a0)
    80002c26:	7fa8                	ld	a0,120(a5)
    80002c28:	bfcd                	j	80002c1a <argraw+0x30>
    return p->trapframe->a2;
    80002c2a:	6d3c                	ld	a5,88(a0)
    80002c2c:	63c8                	ld	a0,128(a5)
    80002c2e:	b7f5                	j	80002c1a <argraw+0x30>
    return p->trapframe->a3;
    80002c30:	6d3c                	ld	a5,88(a0)
    80002c32:	67c8                	ld	a0,136(a5)
    80002c34:	b7dd                	j	80002c1a <argraw+0x30>
    return p->trapframe->a4;
    80002c36:	6d3c                	ld	a5,88(a0)
    80002c38:	6bc8                	ld	a0,144(a5)
    80002c3a:	b7c5                	j	80002c1a <argraw+0x30>
    return p->trapframe->a5;
    80002c3c:	6d3c                	ld	a5,88(a0)
    80002c3e:	6fc8                	ld	a0,152(a5)
    80002c40:	bfe9                	j	80002c1a <argraw+0x30>
  panic("argraw");
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	76650513          	addi	a0,a0,1894 # 800083a8 <states.1727+0x140>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	8e6080e7          	jalr	-1818(ra) # 80000530 <panic>

0000000080002c52 <fetchaddr>:
{
    80002c52:	1101                	addi	sp,sp,-32
    80002c54:	ec06                	sd	ra,24(sp)
    80002c56:	e822                	sd	s0,16(sp)
    80002c58:	e426                	sd	s1,8(sp)
    80002c5a:	e04a                	sd	s2,0(sp)
    80002c5c:	1000                	addi	s0,sp,32
    80002c5e:	84aa                	mv	s1,a0
    80002c60:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	d44080e7          	jalr	-700(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c6a:	653c                	ld	a5,72(a0)
    80002c6c:	02f4f863          	bgeu	s1,a5,80002c9c <fetchaddr+0x4a>
    80002c70:	00848713          	addi	a4,s1,8
    80002c74:	02e7e663          	bltu	a5,a4,80002ca0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c78:	46a1                	li	a3,8
    80002c7a:	8626                	mv	a2,s1
    80002c7c:	85ca                	mv	a1,s2
    80002c7e:	6928                	ld	a0,80(a0)
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	a48080e7          	jalr	-1464(ra) # 800016c8 <copyin>
    80002c88:	00a03533          	snez	a0,a0
    80002c8c:	40a00533          	neg	a0,a0
}
    80002c90:	60e2                	ld	ra,24(sp)
    80002c92:	6442                	ld	s0,16(sp)
    80002c94:	64a2                	ld	s1,8(sp)
    80002c96:	6902                	ld	s2,0(sp)
    80002c98:	6105                	addi	sp,sp,32
    80002c9a:	8082                	ret
    return -1;
    80002c9c:	557d                	li	a0,-1
    80002c9e:	bfcd                	j	80002c90 <fetchaddr+0x3e>
    80002ca0:	557d                	li	a0,-1
    80002ca2:	b7fd                	j	80002c90 <fetchaddr+0x3e>

0000000080002ca4 <fetchstr>:
{
    80002ca4:	7179                	addi	sp,sp,-48
    80002ca6:	f406                	sd	ra,40(sp)
    80002ca8:	f022                	sd	s0,32(sp)
    80002caa:	ec26                	sd	s1,24(sp)
    80002cac:	e84a                	sd	s2,16(sp)
    80002cae:	e44e                	sd	s3,8(sp)
    80002cb0:	1800                	addi	s0,sp,48
    80002cb2:	892a                	mv	s2,a0
    80002cb4:	84ae                	mv	s1,a1
    80002cb6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	cee080e7          	jalr	-786(ra) # 800019a6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cc0:	86ce                	mv	a3,s3
    80002cc2:	864a                	mv	a2,s2
    80002cc4:	85a6                	mv	a1,s1
    80002cc6:	6928                	ld	a0,80(a0)
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	a8c080e7          	jalr	-1396(ra) # 80001754 <copyinstr>
  if(err < 0)
    80002cd0:	00054763          	bltz	a0,80002cde <fetchstr+0x3a>
  return strlen(buf);
    80002cd4:	8526                	mv	a0,s1
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	184080e7          	jalr	388(ra) # 80000e5a <strlen>
}
    80002cde:	70a2                	ld	ra,40(sp)
    80002ce0:	7402                	ld	s0,32(sp)
    80002ce2:	64e2                	ld	s1,24(sp)
    80002ce4:	6942                	ld	s2,16(sp)
    80002ce6:	69a2                	ld	s3,8(sp)
    80002ce8:	6145                	addi	sp,sp,48
    80002cea:	8082                	ret

0000000080002cec <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	e426                	sd	s1,8(sp)
    80002cf4:	1000                	addi	s0,sp,32
    80002cf6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cf8:	00000097          	auipc	ra,0x0
    80002cfc:	ef2080e7          	jalr	-270(ra) # 80002bea <argraw>
    80002d00:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d02:	4501                	li	a0,0
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	64a2                	ld	s1,8(sp)
    80002d0a:	6105                	addi	sp,sp,32
    80002d0c:	8082                	ret

0000000080002d0e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	e426                	sd	s1,8(sp)
    80002d16:	1000                	addi	s0,sp,32
    80002d18:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d1a:	00000097          	auipc	ra,0x0
    80002d1e:	ed0080e7          	jalr	-304(ra) # 80002bea <argraw>
    80002d22:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d24:	4501                	li	a0,0
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	64a2                	ld	s1,8(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret

0000000080002d30 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	e426                	sd	s1,8(sp)
    80002d38:	e04a                	sd	s2,0(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84ae                	mv	s1,a1
    80002d3e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d40:	00000097          	auipc	ra,0x0
    80002d44:	eaa080e7          	jalr	-342(ra) # 80002bea <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d48:	864a                	mv	a2,s2
    80002d4a:	85a6                	mv	a1,s1
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	f58080e7          	jalr	-168(ra) # 80002ca4 <fetchstr>
}
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6902                	ld	s2,0(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <syscall>:
[SYS_munmap]   sys_munmap,
};

void
syscall(void)
{
    80002d60:	1101                	addi	sp,sp,-32
    80002d62:	ec06                	sd	ra,24(sp)
    80002d64:	e822                	sd	s0,16(sp)
    80002d66:	e426                	sd	s1,8(sp)
    80002d68:	e04a                	sd	s2,0(sp)
    80002d6a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	c3a080e7          	jalr	-966(ra) # 800019a6 <myproc>
    80002d74:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d76:	05853903          	ld	s2,88(a0)
    80002d7a:	0a893783          	ld	a5,168(s2)
    80002d7e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d82:	37fd                	addiw	a5,a5,-1
    80002d84:	4759                	li	a4,22
    80002d86:	00f76f63          	bltu	a4,a5,80002da4 <syscall+0x44>
    80002d8a:	00369713          	slli	a4,a3,0x3
    80002d8e:	00005797          	auipc	a5,0x5
    80002d92:	65a78793          	addi	a5,a5,1626 # 800083e8 <syscalls>
    80002d96:	97ba                	add	a5,a5,a4
    80002d98:	639c                	ld	a5,0(a5)
    80002d9a:	c789                	beqz	a5,80002da4 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d9c:	9782                	jalr	a5
    80002d9e:	06a93823          	sd	a0,112(s2)
    80002da2:	a839                	j	80002dc0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002da4:	15848613          	addi	a2,s1,344
    80002da8:	5c8c                	lw	a1,56(s1)
    80002daa:	00005517          	auipc	a0,0x5
    80002dae:	60650513          	addi	a0,a0,1542 # 800083b0 <states.1727+0x148>
    80002db2:	ffffd097          	auipc	ra,0xffffd
    80002db6:	7c8080e7          	jalr	1992(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dba:	6cbc                	ld	a5,88(s1)
    80002dbc:	577d                	li	a4,-1
    80002dbe:	fbb8                	sd	a4,112(a5)
  }
}
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	64a2                	ld	s1,8(sp)
    80002dc6:	6902                	ld	s2,0(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dd4:	fec40593          	addi	a1,s0,-20
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	f12080e7          	jalr	-238(ra) # 80002cec <argint>
    return -1;
    80002de2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002de4:	00054963          	bltz	a0,80002df6 <sys_exit+0x2a>
  exit(n);
    80002de8:	fec42503          	lw	a0,-20(s0)
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	2d6080e7          	jalr	726(ra) # 800020c2 <exit>
  return 0;  // not reached
    80002df4:	4781                	li	a5,0
}
    80002df6:	853e                	mv	a0,a5
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	6105                	addi	sp,sp,32
    80002dfe:	8082                	ret

0000000080002e00 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e00:	1141                	addi	sp,sp,-16
    80002e02:	e406                	sd	ra,8(sp)
    80002e04:	e022                	sd	s0,0(sp)
    80002e06:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	b9e080e7          	jalr	-1122(ra) # 800019a6 <myproc>
}
    80002e10:	5d08                	lw	a0,56(a0)
    80002e12:	60a2                	ld	ra,8(sp)
    80002e14:	6402                	ld	s0,0(sp)
    80002e16:	0141                	addi	sp,sp,16
    80002e18:	8082                	ret

0000000080002e1a <sys_fork>:

uint64
sys_fork(void)
{
    80002e1a:	1141                	addi	sp,sp,-16
    80002e1c:	e406                	sd	ra,8(sp)
    80002e1e:	e022                	sd	s0,0(sp)
    80002e20:	0800                	addi	s0,sp,16
  return fork();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	f56080e7          	jalr	-170(ra) # 80001d78 <fork>
}
    80002e2a:	60a2                	ld	ra,8(sp)
    80002e2c:	6402                	ld	s0,0(sp)
    80002e2e:	0141                	addi	sp,sp,16
    80002e30:	8082                	ret

0000000080002e32 <sys_wait>:

uint64
sys_wait(void)
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e3a:	fe840593          	addi	a1,s0,-24
    80002e3e:	4501                	li	a0,0
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	ece080e7          	jalr	-306(ra) # 80002d0e <argaddr>
    80002e48:	87aa                	mv	a5,a0
    return -1;
    80002e4a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e4c:	0007c863          	bltz	a5,80002e5c <sys_wait+0x2a>
  return wait(p);
    80002e50:	fe843503          	ld	a0,-24(s0)
    80002e54:	fffff097          	auipc	ra,0xfffff
    80002e58:	4a0080e7          	jalr	1184(ra) # 800022f4 <wait>
}
    80002e5c:	60e2                	ld	ra,24(sp)
    80002e5e:	6442                	ld	s0,16(sp)
    80002e60:	6105                	addi	sp,sp,32
    80002e62:	8082                	ret

0000000080002e64 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e64:	7179                	addi	sp,sp,-48
    80002e66:	f406                	sd	ra,40(sp)
    80002e68:	f022                	sd	s0,32(sp)
    80002e6a:	ec26                	sd	s1,24(sp)
    80002e6c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e6e:	fdc40593          	addi	a1,s0,-36
    80002e72:	4501                	li	a0,0
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	e78080e7          	jalr	-392(ra) # 80002cec <argint>
    80002e7c:	87aa                	mv	a5,a0
    return -1;
    80002e7e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e80:	0207c063          	bltz	a5,80002ea0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	b22080e7          	jalr	-1246(ra) # 800019a6 <myproc>
    80002e8c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e8e:	fdc42503          	lw	a0,-36(s0)
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	e72080e7          	jalr	-398(ra) # 80001d04 <growproc>
    80002e9a:	00054863          	bltz	a0,80002eaa <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e9e:	8526                	mv	a0,s1
}
    80002ea0:	70a2                	ld	ra,40(sp)
    80002ea2:	7402                	ld	s0,32(sp)
    80002ea4:	64e2                	ld	s1,24(sp)
    80002ea6:	6145                	addi	sp,sp,48
    80002ea8:	8082                	ret
    return -1;
    80002eaa:	557d                	li	a0,-1
    80002eac:	bfd5                	j	80002ea0 <sys_sbrk+0x3c>

0000000080002eae <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eae:	7139                	addi	sp,sp,-64
    80002eb0:	fc06                	sd	ra,56(sp)
    80002eb2:	f822                	sd	s0,48(sp)
    80002eb4:	f426                	sd	s1,40(sp)
    80002eb6:	f04a                	sd	s2,32(sp)
    80002eb8:	ec4e                	sd	s3,24(sp)
    80002eba:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ebc:	fcc40593          	addi	a1,s0,-52
    80002ec0:	4501                	li	a0,0
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	e2a080e7          	jalr	-470(ra) # 80002cec <argint>
    return -1;
    80002eca:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ecc:	06054563          	bltz	a0,80002f36 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ed0:	00020517          	auipc	a0,0x20
    80002ed4:	1e850513          	addi	a0,a0,488 # 800230b8 <tickslock>
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	cfe080e7          	jalr	-770(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002ee0:	00006917          	auipc	s2,0x6
    80002ee4:	15092903          	lw	s2,336(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002ee8:	fcc42783          	lw	a5,-52(s0)
    80002eec:	cf85                	beqz	a5,80002f24 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eee:	00020997          	auipc	s3,0x20
    80002ef2:	1ca98993          	addi	s3,s3,458 # 800230b8 <tickslock>
    80002ef6:	00006497          	auipc	s1,0x6
    80002efa:	13a48493          	addi	s1,s1,314 # 80009030 <ticks>
    if(myproc()->killed){
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	aa8080e7          	jalr	-1368(ra) # 800019a6 <myproc>
    80002f06:	591c                	lw	a5,48(a0)
    80002f08:	ef9d                	bnez	a5,80002f46 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f0a:	85ce                	mv	a1,s3
    80002f0c:	8526                	mv	a0,s1
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	368080e7          	jalr	872(ra) # 80002276 <sleep>
  while(ticks - ticks0 < n){
    80002f16:	409c                	lw	a5,0(s1)
    80002f18:	412787bb          	subw	a5,a5,s2
    80002f1c:	fcc42703          	lw	a4,-52(s0)
    80002f20:	fce7efe3          	bltu	a5,a4,80002efe <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f24:	00020517          	auipc	a0,0x20
    80002f28:	19450513          	addi	a0,a0,404 # 800230b8 <tickslock>
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	d5e080e7          	jalr	-674(ra) # 80000c8a <release>
  return 0;
    80002f34:	4781                	li	a5,0
}
    80002f36:	853e                	mv	a0,a5
    80002f38:	70e2                	ld	ra,56(sp)
    80002f3a:	7442                	ld	s0,48(sp)
    80002f3c:	74a2                	ld	s1,40(sp)
    80002f3e:	7902                	ld	s2,32(sp)
    80002f40:	69e2                	ld	s3,24(sp)
    80002f42:	6121                	addi	sp,sp,64
    80002f44:	8082                	ret
      release(&tickslock);
    80002f46:	00020517          	auipc	a0,0x20
    80002f4a:	17250513          	addi	a0,a0,370 # 800230b8 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	d3c080e7          	jalr	-708(ra) # 80000c8a <release>
      return -1;
    80002f56:	57fd                	li	a5,-1
    80002f58:	bff9                	j	80002f36 <sys_sleep+0x88>

0000000080002f5a <sys_kill>:

uint64
sys_kill(void)
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f62:	fec40593          	addi	a1,s0,-20
    80002f66:	4501                	li	a0,0
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	d84080e7          	jalr	-636(ra) # 80002cec <argint>
    80002f70:	87aa                	mv	a5,a0
    return -1;
    80002f72:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f74:	0007c863          	bltz	a5,80002f84 <sys_kill+0x2a>
  return kill(pid);
    80002f78:	fec42503          	lw	a0,-20(s0)
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	4ea080e7          	jalr	1258(ra) # 80002466 <kill>
}
    80002f84:	60e2                	ld	ra,24(sp)
    80002f86:	6442                	ld	s0,16(sp)
    80002f88:	6105                	addi	sp,sp,32
    80002f8a:	8082                	ret

0000000080002f8c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f8c:	1101                	addi	sp,sp,-32
    80002f8e:	ec06                	sd	ra,24(sp)
    80002f90:	e822                	sd	s0,16(sp)
    80002f92:	e426                	sd	s1,8(sp)
    80002f94:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f96:	00020517          	auipc	a0,0x20
    80002f9a:	12250513          	addi	a0,a0,290 # 800230b8 <tickslock>
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	c38080e7          	jalr	-968(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fa6:	00006497          	auipc	s1,0x6
    80002faa:	08a4a483          	lw	s1,138(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fae:	00020517          	auipc	a0,0x20
    80002fb2:	10a50513          	addi	a0,a0,266 # 800230b8 <tickslock>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	cd4080e7          	jalr	-812(ra) # 80000c8a <release>
  return xticks;
}
    80002fbe:	02049513          	slli	a0,s1,0x20
    80002fc2:	9101                	srli	a0,a0,0x20
    80002fc4:	60e2                	ld	ra,24(sp)
    80002fc6:	6442                	ld	s0,16(sp)
    80002fc8:	64a2                	ld	s1,8(sp)
    80002fca:	6105                	addi	sp,sp,32
    80002fcc:	8082                	ret

0000000080002fce <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fce:	7179                	addi	sp,sp,-48
    80002fd0:	f406                	sd	ra,40(sp)
    80002fd2:	f022                	sd	s0,32(sp)
    80002fd4:	ec26                	sd	s1,24(sp)
    80002fd6:	e84a                	sd	s2,16(sp)
    80002fd8:	e44e                	sd	s3,8(sp)
    80002fda:	e052                	sd	s4,0(sp)
    80002fdc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fde:	00005597          	auipc	a1,0x5
    80002fe2:	4ca58593          	addi	a1,a1,1226 # 800084a8 <syscalls+0xc0>
    80002fe6:	00020517          	auipc	a0,0x20
    80002fea:	0ea50513          	addi	a0,a0,234 # 800230d0 <bcache>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	b58080e7          	jalr	-1192(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ff6:	00028797          	auipc	a5,0x28
    80002ffa:	0da78793          	addi	a5,a5,218 # 8002b0d0 <bcache+0x8000>
    80002ffe:	00028717          	auipc	a4,0x28
    80003002:	33a70713          	addi	a4,a4,826 # 8002b338 <bcache+0x8268>
    80003006:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000300a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000300e:	00020497          	auipc	s1,0x20
    80003012:	0da48493          	addi	s1,s1,218 # 800230e8 <bcache+0x18>
    b->next = bcache.head.next;
    80003016:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003018:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000301a:	00005a17          	auipc	s4,0x5
    8000301e:	496a0a13          	addi	s4,s4,1174 # 800084b0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003022:	2b893783          	ld	a5,696(s2)
    80003026:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003028:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000302c:	85d2                	mv	a1,s4
    8000302e:	01048513          	addi	a0,s1,16
    80003032:	00001097          	auipc	ra,0x1
    80003036:	4c4080e7          	jalr	1220(ra) # 800044f6 <initsleeplock>
    bcache.head.next->prev = b;
    8000303a:	2b893783          	ld	a5,696(s2)
    8000303e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003040:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003044:	45848493          	addi	s1,s1,1112
    80003048:	fd349de3          	bne	s1,s3,80003022 <binit+0x54>
  }
}
    8000304c:	70a2                	ld	ra,40(sp)
    8000304e:	7402                	ld	s0,32(sp)
    80003050:	64e2                	ld	s1,24(sp)
    80003052:	6942                	ld	s2,16(sp)
    80003054:	69a2                	ld	s3,8(sp)
    80003056:	6a02                	ld	s4,0(sp)
    80003058:	6145                	addi	sp,sp,48
    8000305a:	8082                	ret

000000008000305c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000305c:	7179                	addi	sp,sp,-48
    8000305e:	f406                	sd	ra,40(sp)
    80003060:	f022                	sd	s0,32(sp)
    80003062:	ec26                	sd	s1,24(sp)
    80003064:	e84a                	sd	s2,16(sp)
    80003066:	e44e                	sd	s3,8(sp)
    80003068:	1800                	addi	s0,sp,48
    8000306a:	89aa                	mv	s3,a0
    8000306c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000306e:	00020517          	auipc	a0,0x20
    80003072:	06250513          	addi	a0,a0,98 # 800230d0 <bcache>
    80003076:	ffffe097          	auipc	ra,0xffffe
    8000307a:	b60080e7          	jalr	-1184(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000307e:	00028497          	auipc	s1,0x28
    80003082:	30a4b483          	ld	s1,778(s1) # 8002b388 <bcache+0x82b8>
    80003086:	00028797          	auipc	a5,0x28
    8000308a:	2b278793          	addi	a5,a5,690 # 8002b338 <bcache+0x8268>
    8000308e:	02f48f63          	beq	s1,a5,800030cc <bread+0x70>
    80003092:	873e                	mv	a4,a5
    80003094:	a021                	j	8000309c <bread+0x40>
    80003096:	68a4                	ld	s1,80(s1)
    80003098:	02e48a63          	beq	s1,a4,800030cc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000309c:	449c                	lw	a5,8(s1)
    8000309e:	ff379ce3          	bne	a5,s3,80003096 <bread+0x3a>
    800030a2:	44dc                	lw	a5,12(s1)
    800030a4:	ff2799e3          	bne	a5,s2,80003096 <bread+0x3a>
      b->refcnt++;
    800030a8:	40bc                	lw	a5,64(s1)
    800030aa:	2785                	addiw	a5,a5,1
    800030ac:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ae:	00020517          	auipc	a0,0x20
    800030b2:	02250513          	addi	a0,a0,34 # 800230d0 <bcache>
    800030b6:	ffffe097          	auipc	ra,0xffffe
    800030ba:	bd4080e7          	jalr	-1068(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030be:	01048513          	addi	a0,s1,16
    800030c2:	00001097          	auipc	ra,0x1
    800030c6:	46e080e7          	jalr	1134(ra) # 80004530 <acquiresleep>
      return b;
    800030ca:	a8b9                	j	80003128 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030cc:	00028497          	auipc	s1,0x28
    800030d0:	2b44b483          	ld	s1,692(s1) # 8002b380 <bcache+0x82b0>
    800030d4:	00028797          	auipc	a5,0x28
    800030d8:	26478793          	addi	a5,a5,612 # 8002b338 <bcache+0x8268>
    800030dc:	00f48863          	beq	s1,a5,800030ec <bread+0x90>
    800030e0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030e2:	40bc                	lw	a5,64(s1)
    800030e4:	cf81                	beqz	a5,800030fc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030e6:	64a4                	ld	s1,72(s1)
    800030e8:	fee49de3          	bne	s1,a4,800030e2 <bread+0x86>
  panic("bget: no buffers");
    800030ec:	00005517          	auipc	a0,0x5
    800030f0:	3cc50513          	addi	a0,a0,972 # 800084b8 <syscalls+0xd0>
    800030f4:	ffffd097          	auipc	ra,0xffffd
    800030f8:	43c080e7          	jalr	1084(ra) # 80000530 <panic>
      b->dev = dev;
    800030fc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003100:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003104:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003108:	4785                	li	a5,1
    8000310a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000310c:	00020517          	auipc	a0,0x20
    80003110:	fc450513          	addi	a0,a0,-60 # 800230d0 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	b76080e7          	jalr	-1162(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000311c:	01048513          	addi	a0,s1,16
    80003120:	00001097          	auipc	ra,0x1
    80003124:	410080e7          	jalr	1040(ra) # 80004530 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003128:	409c                	lw	a5,0(s1)
    8000312a:	cb89                	beqz	a5,8000313c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000312c:	8526                	mv	a0,s1
    8000312e:	70a2                	ld	ra,40(sp)
    80003130:	7402                	ld	s0,32(sp)
    80003132:	64e2                	ld	s1,24(sp)
    80003134:	6942                	ld	s2,16(sp)
    80003136:	69a2                	ld	s3,8(sp)
    80003138:	6145                	addi	sp,sp,48
    8000313a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000313c:	4581                	li	a1,0
    8000313e:	8526                	mv	a0,s1
    80003140:	00003097          	auipc	ra,0x3
    80003144:	1d6080e7          	jalr	470(ra) # 80006316 <virtio_disk_rw>
    b->valid = 1;
    80003148:	4785                	li	a5,1
    8000314a:	c09c                	sw	a5,0(s1)
  return b;
    8000314c:	b7c5                	j	8000312c <bread+0xd0>

000000008000314e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	e426                	sd	s1,8(sp)
    80003156:	1000                	addi	s0,sp,32
    80003158:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000315a:	0541                	addi	a0,a0,16
    8000315c:	00001097          	auipc	ra,0x1
    80003160:	46e080e7          	jalr	1134(ra) # 800045ca <holdingsleep>
    80003164:	cd01                	beqz	a0,8000317c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003166:	4585                	li	a1,1
    80003168:	8526                	mv	a0,s1
    8000316a:	00003097          	auipc	ra,0x3
    8000316e:	1ac080e7          	jalr	428(ra) # 80006316 <virtio_disk_rw>
}
    80003172:	60e2                	ld	ra,24(sp)
    80003174:	6442                	ld	s0,16(sp)
    80003176:	64a2                	ld	s1,8(sp)
    80003178:	6105                	addi	sp,sp,32
    8000317a:	8082                	ret
    panic("bwrite");
    8000317c:	00005517          	auipc	a0,0x5
    80003180:	35450513          	addi	a0,a0,852 # 800084d0 <syscalls+0xe8>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	3ac080e7          	jalr	940(ra) # 80000530 <panic>

000000008000318c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000318c:	1101                	addi	sp,sp,-32
    8000318e:	ec06                	sd	ra,24(sp)
    80003190:	e822                	sd	s0,16(sp)
    80003192:	e426                	sd	s1,8(sp)
    80003194:	e04a                	sd	s2,0(sp)
    80003196:	1000                	addi	s0,sp,32
    80003198:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000319a:	01050913          	addi	s2,a0,16
    8000319e:	854a                	mv	a0,s2
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	42a080e7          	jalr	1066(ra) # 800045ca <holdingsleep>
    800031a8:	c92d                	beqz	a0,8000321a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031aa:	854a                	mv	a0,s2
    800031ac:	00001097          	auipc	ra,0x1
    800031b0:	3da080e7          	jalr	986(ra) # 80004586 <releasesleep>

  acquire(&bcache.lock);
    800031b4:	00020517          	auipc	a0,0x20
    800031b8:	f1c50513          	addi	a0,a0,-228 # 800230d0 <bcache>
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	a1a080e7          	jalr	-1510(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031c4:	40bc                	lw	a5,64(s1)
    800031c6:	37fd                	addiw	a5,a5,-1
    800031c8:	0007871b          	sext.w	a4,a5
    800031cc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031ce:	eb05                	bnez	a4,800031fe <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031d0:	68bc                	ld	a5,80(s1)
    800031d2:	64b8                	ld	a4,72(s1)
    800031d4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031d6:	64bc                	ld	a5,72(s1)
    800031d8:	68b8                	ld	a4,80(s1)
    800031da:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031dc:	00028797          	auipc	a5,0x28
    800031e0:	ef478793          	addi	a5,a5,-268 # 8002b0d0 <bcache+0x8000>
    800031e4:	2b87b703          	ld	a4,696(a5)
    800031e8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031ea:	00028717          	auipc	a4,0x28
    800031ee:	14e70713          	addi	a4,a4,334 # 8002b338 <bcache+0x8268>
    800031f2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031f4:	2b87b703          	ld	a4,696(a5)
    800031f8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031fa:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031fe:	00020517          	auipc	a0,0x20
    80003202:	ed250513          	addi	a0,a0,-302 # 800230d0 <bcache>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	a84080e7          	jalr	-1404(ra) # 80000c8a <release>
}
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	64a2                	ld	s1,8(sp)
    80003214:	6902                	ld	s2,0(sp)
    80003216:	6105                	addi	sp,sp,32
    80003218:	8082                	ret
    panic("brelse");
    8000321a:	00005517          	auipc	a0,0x5
    8000321e:	2be50513          	addi	a0,a0,702 # 800084d8 <syscalls+0xf0>
    80003222:	ffffd097          	auipc	ra,0xffffd
    80003226:	30e080e7          	jalr	782(ra) # 80000530 <panic>

000000008000322a <bpin>:

void
bpin(struct buf *b) {
    8000322a:	1101                	addi	sp,sp,-32
    8000322c:	ec06                	sd	ra,24(sp)
    8000322e:	e822                	sd	s0,16(sp)
    80003230:	e426                	sd	s1,8(sp)
    80003232:	1000                	addi	s0,sp,32
    80003234:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003236:	00020517          	auipc	a0,0x20
    8000323a:	e9a50513          	addi	a0,a0,-358 # 800230d0 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	998080e7          	jalr	-1640(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003246:	40bc                	lw	a5,64(s1)
    80003248:	2785                	addiw	a5,a5,1
    8000324a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000324c:	00020517          	auipc	a0,0x20
    80003250:	e8450513          	addi	a0,a0,-380 # 800230d0 <bcache>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	a36080e7          	jalr	-1482(ra) # 80000c8a <release>
}
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	64a2                	ld	s1,8(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret

0000000080003266 <bunpin>:

void
bunpin(struct buf *b) {
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	1000                	addi	s0,sp,32
    80003270:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003272:	00020517          	auipc	a0,0x20
    80003276:	e5e50513          	addi	a0,a0,-418 # 800230d0 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	95c080e7          	jalr	-1700(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003282:	40bc                	lw	a5,64(s1)
    80003284:	37fd                	addiw	a5,a5,-1
    80003286:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003288:	00020517          	auipc	a0,0x20
    8000328c:	e4850513          	addi	a0,a0,-440 # 800230d0 <bcache>
    80003290:	ffffe097          	auipc	ra,0xffffe
    80003294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
}
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	64a2                	ld	s1,8(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	e426                	sd	s1,8(sp)
    800032aa:	e04a                	sd	s2,0(sp)
    800032ac:	1000                	addi	s0,sp,32
    800032ae:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032b0:	00d5d59b          	srliw	a1,a1,0xd
    800032b4:	00028797          	auipc	a5,0x28
    800032b8:	4f87a783          	lw	a5,1272(a5) # 8002b7ac <sb+0x1c>
    800032bc:	9dbd                	addw	a1,a1,a5
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	d9e080e7          	jalr	-610(ra) # 8000305c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032c6:	0074f713          	andi	a4,s1,7
    800032ca:	4785                	li	a5,1
    800032cc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032d0:	14ce                	slli	s1,s1,0x33
    800032d2:	90d9                	srli	s1,s1,0x36
    800032d4:	00950733          	add	a4,a0,s1
    800032d8:	05874703          	lbu	a4,88(a4)
    800032dc:	00e7f6b3          	and	a3,a5,a4
    800032e0:	c69d                	beqz	a3,8000330e <bfree+0x6c>
    800032e2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032e4:	94aa                	add	s1,s1,a0
    800032e6:	fff7c793          	not	a5,a5
    800032ea:	8ff9                	and	a5,a5,a4
    800032ec:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032f0:	00001097          	auipc	ra,0x1
    800032f4:	118080e7          	jalr	280(ra) # 80004408 <log_write>
  brelse(bp);
    800032f8:	854a                	mv	a0,s2
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	e92080e7          	jalr	-366(ra) # 8000318c <brelse>
}
    80003302:	60e2                	ld	ra,24(sp)
    80003304:	6442                	ld	s0,16(sp)
    80003306:	64a2                	ld	s1,8(sp)
    80003308:	6902                	ld	s2,0(sp)
    8000330a:	6105                	addi	sp,sp,32
    8000330c:	8082                	ret
    panic("freeing free block");
    8000330e:	00005517          	auipc	a0,0x5
    80003312:	1d250513          	addi	a0,a0,466 # 800084e0 <syscalls+0xf8>
    80003316:	ffffd097          	auipc	ra,0xffffd
    8000331a:	21a080e7          	jalr	538(ra) # 80000530 <panic>

000000008000331e <balloc>:
{
    8000331e:	711d                	addi	sp,sp,-96
    80003320:	ec86                	sd	ra,88(sp)
    80003322:	e8a2                	sd	s0,80(sp)
    80003324:	e4a6                	sd	s1,72(sp)
    80003326:	e0ca                	sd	s2,64(sp)
    80003328:	fc4e                	sd	s3,56(sp)
    8000332a:	f852                	sd	s4,48(sp)
    8000332c:	f456                	sd	s5,40(sp)
    8000332e:	f05a                	sd	s6,32(sp)
    80003330:	ec5e                	sd	s7,24(sp)
    80003332:	e862                	sd	s8,16(sp)
    80003334:	e466                	sd	s9,8(sp)
    80003336:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003338:	00028797          	auipc	a5,0x28
    8000333c:	45c7a783          	lw	a5,1116(a5) # 8002b794 <sb+0x4>
    80003340:	cbd1                	beqz	a5,800033d4 <balloc+0xb6>
    80003342:	8baa                	mv	s7,a0
    80003344:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003346:	00028b17          	auipc	s6,0x28
    8000334a:	44ab0b13          	addi	s6,s6,1098 # 8002b790 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000334e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003350:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003352:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003354:	6c89                	lui	s9,0x2
    80003356:	a831                	j	80003372 <balloc+0x54>
    brelse(bp);
    80003358:	854a                	mv	a0,s2
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	e32080e7          	jalr	-462(ra) # 8000318c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003362:	015c87bb          	addw	a5,s9,s5
    80003366:	00078a9b          	sext.w	s5,a5
    8000336a:	004b2703          	lw	a4,4(s6)
    8000336e:	06eaf363          	bgeu	s5,a4,800033d4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003372:	41fad79b          	sraiw	a5,s5,0x1f
    80003376:	0137d79b          	srliw	a5,a5,0x13
    8000337a:	015787bb          	addw	a5,a5,s5
    8000337e:	40d7d79b          	sraiw	a5,a5,0xd
    80003382:	01cb2583          	lw	a1,28(s6)
    80003386:	9dbd                	addw	a1,a1,a5
    80003388:	855e                	mv	a0,s7
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	cd2080e7          	jalr	-814(ra) # 8000305c <bread>
    80003392:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003394:	004b2503          	lw	a0,4(s6)
    80003398:	000a849b          	sext.w	s1,s5
    8000339c:	8662                	mv	a2,s8
    8000339e:	faa4fde3          	bgeu	s1,a0,80003358 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033a2:	41f6579b          	sraiw	a5,a2,0x1f
    800033a6:	01d7d69b          	srliw	a3,a5,0x1d
    800033aa:	00c6873b          	addw	a4,a3,a2
    800033ae:	00777793          	andi	a5,a4,7
    800033b2:	9f95                	subw	a5,a5,a3
    800033b4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033b8:	4037571b          	sraiw	a4,a4,0x3
    800033bc:	00e906b3          	add	a3,s2,a4
    800033c0:	0586c683          	lbu	a3,88(a3)
    800033c4:	00d7f5b3          	and	a1,a5,a3
    800033c8:	cd91                	beqz	a1,800033e4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ca:	2605                	addiw	a2,a2,1
    800033cc:	2485                	addiw	s1,s1,1
    800033ce:	fd4618e3          	bne	a2,s4,8000339e <balloc+0x80>
    800033d2:	b759                	j	80003358 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033d4:	00005517          	auipc	a0,0x5
    800033d8:	12450513          	addi	a0,a0,292 # 800084f8 <syscalls+0x110>
    800033dc:	ffffd097          	auipc	ra,0xffffd
    800033e0:	154080e7          	jalr	340(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033e4:	974a                	add	a4,a4,s2
    800033e6:	8fd5                	or	a5,a5,a3
    800033e8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033ec:	854a                	mv	a0,s2
    800033ee:	00001097          	auipc	ra,0x1
    800033f2:	01a080e7          	jalr	26(ra) # 80004408 <log_write>
        brelse(bp);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	d94080e7          	jalr	-620(ra) # 8000318c <brelse>
  bp = bread(dev, bno);
    80003400:	85a6                	mv	a1,s1
    80003402:	855e                	mv	a0,s7
    80003404:	00000097          	auipc	ra,0x0
    80003408:	c58080e7          	jalr	-936(ra) # 8000305c <bread>
    8000340c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000340e:	40000613          	li	a2,1024
    80003412:	4581                	li	a1,0
    80003414:	05850513          	addi	a0,a0,88
    80003418:	ffffe097          	auipc	ra,0xffffe
    8000341c:	8ba080e7          	jalr	-1862(ra) # 80000cd2 <memset>
  log_write(bp);
    80003420:	854a                	mv	a0,s2
    80003422:	00001097          	auipc	ra,0x1
    80003426:	fe6080e7          	jalr	-26(ra) # 80004408 <log_write>
  brelse(bp);
    8000342a:	854a                	mv	a0,s2
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	d60080e7          	jalr	-672(ra) # 8000318c <brelse>
}
    80003434:	8526                	mv	a0,s1
    80003436:	60e6                	ld	ra,88(sp)
    80003438:	6446                	ld	s0,80(sp)
    8000343a:	64a6                	ld	s1,72(sp)
    8000343c:	6906                	ld	s2,64(sp)
    8000343e:	79e2                	ld	s3,56(sp)
    80003440:	7a42                	ld	s4,48(sp)
    80003442:	7aa2                	ld	s5,40(sp)
    80003444:	7b02                	ld	s6,32(sp)
    80003446:	6be2                	ld	s7,24(sp)
    80003448:	6c42                	ld	s8,16(sp)
    8000344a:	6ca2                	ld	s9,8(sp)
    8000344c:	6125                	addi	sp,sp,96
    8000344e:	8082                	ret

0000000080003450 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003450:	7179                	addi	sp,sp,-48
    80003452:	f406                	sd	ra,40(sp)
    80003454:	f022                	sd	s0,32(sp)
    80003456:	ec26                	sd	s1,24(sp)
    80003458:	e84a                	sd	s2,16(sp)
    8000345a:	e44e                	sd	s3,8(sp)
    8000345c:	e052                	sd	s4,0(sp)
    8000345e:	1800                	addi	s0,sp,48
    80003460:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003462:	47ad                	li	a5,11
    80003464:	04b7fe63          	bgeu	a5,a1,800034c0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003468:	ff45849b          	addiw	s1,a1,-12
    8000346c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003470:	0ff00793          	li	a5,255
    80003474:	0ae7e363          	bltu	a5,a4,8000351a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003478:	08052583          	lw	a1,128(a0)
    8000347c:	c5ad                	beqz	a1,800034e6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000347e:	00092503          	lw	a0,0(s2)
    80003482:	00000097          	auipc	ra,0x0
    80003486:	bda080e7          	jalr	-1062(ra) # 8000305c <bread>
    8000348a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000348c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003490:	02049593          	slli	a1,s1,0x20
    80003494:	9181                	srli	a1,a1,0x20
    80003496:	058a                	slli	a1,a1,0x2
    80003498:	00b784b3          	add	s1,a5,a1
    8000349c:	0004a983          	lw	s3,0(s1)
    800034a0:	04098d63          	beqz	s3,800034fa <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034a4:	8552                	mv	a0,s4
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	ce6080e7          	jalr	-794(ra) # 8000318c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034ae:	854e                	mv	a0,s3
    800034b0:	70a2                	ld	ra,40(sp)
    800034b2:	7402                	ld	s0,32(sp)
    800034b4:	64e2                	ld	s1,24(sp)
    800034b6:	6942                	ld	s2,16(sp)
    800034b8:	69a2                	ld	s3,8(sp)
    800034ba:	6a02                	ld	s4,0(sp)
    800034bc:	6145                	addi	sp,sp,48
    800034be:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034c0:	02059493          	slli	s1,a1,0x20
    800034c4:	9081                	srli	s1,s1,0x20
    800034c6:	048a                	slli	s1,s1,0x2
    800034c8:	94aa                	add	s1,s1,a0
    800034ca:	0504a983          	lw	s3,80(s1)
    800034ce:	fe0990e3          	bnez	s3,800034ae <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034d2:	4108                	lw	a0,0(a0)
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	e4a080e7          	jalr	-438(ra) # 8000331e <balloc>
    800034dc:	0005099b          	sext.w	s3,a0
    800034e0:	0534a823          	sw	s3,80(s1)
    800034e4:	b7e9                	j	800034ae <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034e6:	4108                	lw	a0,0(a0)
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	e36080e7          	jalr	-458(ra) # 8000331e <balloc>
    800034f0:	0005059b          	sext.w	a1,a0
    800034f4:	08b92023          	sw	a1,128(s2)
    800034f8:	b759                	j	8000347e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034fa:	00092503          	lw	a0,0(s2)
    800034fe:	00000097          	auipc	ra,0x0
    80003502:	e20080e7          	jalr	-480(ra) # 8000331e <balloc>
    80003506:	0005099b          	sext.w	s3,a0
    8000350a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000350e:	8552                	mv	a0,s4
    80003510:	00001097          	auipc	ra,0x1
    80003514:	ef8080e7          	jalr	-264(ra) # 80004408 <log_write>
    80003518:	b771                	j	800034a4 <bmap+0x54>
  panic("bmap: out of range");
    8000351a:	00005517          	auipc	a0,0x5
    8000351e:	ff650513          	addi	a0,a0,-10 # 80008510 <syscalls+0x128>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	00e080e7          	jalr	14(ra) # 80000530 <panic>

000000008000352a <iget>:
{
    8000352a:	7179                	addi	sp,sp,-48
    8000352c:	f406                	sd	ra,40(sp)
    8000352e:	f022                	sd	s0,32(sp)
    80003530:	ec26                	sd	s1,24(sp)
    80003532:	e84a                	sd	s2,16(sp)
    80003534:	e44e                	sd	s3,8(sp)
    80003536:	e052                	sd	s4,0(sp)
    80003538:	1800                	addi	s0,sp,48
    8000353a:	89aa                	mv	s3,a0
    8000353c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000353e:	00028517          	auipc	a0,0x28
    80003542:	27250513          	addi	a0,a0,626 # 8002b7b0 <icache>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	690080e7          	jalr	1680(ra) # 80000bd6 <acquire>
  empty = 0;
    8000354e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003550:	00028497          	auipc	s1,0x28
    80003554:	27848493          	addi	s1,s1,632 # 8002b7c8 <icache+0x18>
    80003558:	0002a697          	auipc	a3,0x2a
    8000355c:	d0068693          	addi	a3,a3,-768 # 8002d258 <log>
    80003560:	a039                	j	8000356e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003562:	02090b63          	beqz	s2,80003598 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003566:	08848493          	addi	s1,s1,136
    8000356a:	02d48a63          	beq	s1,a3,8000359e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000356e:	449c                	lw	a5,8(s1)
    80003570:	fef059e3          	blez	a5,80003562 <iget+0x38>
    80003574:	4098                	lw	a4,0(s1)
    80003576:	ff3716e3          	bne	a4,s3,80003562 <iget+0x38>
    8000357a:	40d8                	lw	a4,4(s1)
    8000357c:	ff4713e3          	bne	a4,s4,80003562 <iget+0x38>
      ip->ref++;
    80003580:	2785                	addiw	a5,a5,1
    80003582:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003584:	00028517          	auipc	a0,0x28
    80003588:	22c50513          	addi	a0,a0,556 # 8002b7b0 <icache>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	6fe080e7          	jalr	1790(ra) # 80000c8a <release>
      return ip;
    80003594:	8926                	mv	s2,s1
    80003596:	a03d                	j	800035c4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003598:	f7f9                	bnez	a5,80003566 <iget+0x3c>
    8000359a:	8926                	mv	s2,s1
    8000359c:	b7e9                	j	80003566 <iget+0x3c>
  if(empty == 0)
    8000359e:	02090c63          	beqz	s2,800035d6 <iget+0xac>
  ip->dev = dev;
    800035a2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035a6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035aa:	4785                	li	a5,1
    800035ac:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035b0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035b4:	00028517          	auipc	a0,0x28
    800035b8:	1fc50513          	addi	a0,a0,508 # 8002b7b0 <icache>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	6ce080e7          	jalr	1742(ra) # 80000c8a <release>
}
    800035c4:	854a                	mv	a0,s2
    800035c6:	70a2                	ld	ra,40(sp)
    800035c8:	7402                	ld	s0,32(sp)
    800035ca:	64e2                	ld	s1,24(sp)
    800035cc:	6942                	ld	s2,16(sp)
    800035ce:	69a2                	ld	s3,8(sp)
    800035d0:	6a02                	ld	s4,0(sp)
    800035d2:	6145                	addi	sp,sp,48
    800035d4:	8082                	ret
    panic("iget: no inodes");
    800035d6:	00005517          	auipc	a0,0x5
    800035da:	f5250513          	addi	a0,a0,-174 # 80008528 <syscalls+0x140>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	f52080e7          	jalr	-174(ra) # 80000530 <panic>

00000000800035e6 <fsinit>:
fsinit(int dev) {
    800035e6:	7179                	addi	sp,sp,-48
    800035e8:	f406                	sd	ra,40(sp)
    800035ea:	f022                	sd	s0,32(sp)
    800035ec:	ec26                	sd	s1,24(sp)
    800035ee:	e84a                	sd	s2,16(sp)
    800035f0:	e44e                	sd	s3,8(sp)
    800035f2:	1800                	addi	s0,sp,48
    800035f4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035f6:	4585                	li	a1,1
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	a64080e7          	jalr	-1436(ra) # 8000305c <bread>
    80003600:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003602:	00028997          	auipc	s3,0x28
    80003606:	18e98993          	addi	s3,s3,398 # 8002b790 <sb>
    8000360a:	02000613          	li	a2,32
    8000360e:	05850593          	addi	a1,a0,88
    80003612:	854e                	mv	a0,s3
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	71e080e7          	jalr	1822(ra) # 80000d32 <memmove>
  brelse(bp);
    8000361c:	8526                	mv	a0,s1
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	b6e080e7          	jalr	-1170(ra) # 8000318c <brelse>
  if(sb.magic != FSMAGIC)
    80003626:	0009a703          	lw	a4,0(s3)
    8000362a:	102037b7          	lui	a5,0x10203
    8000362e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003632:	02f71263          	bne	a4,a5,80003656 <fsinit+0x70>
  initlog(dev, &sb);
    80003636:	00028597          	auipc	a1,0x28
    8000363a:	15a58593          	addi	a1,a1,346 # 8002b790 <sb>
    8000363e:	854a                	mv	a0,s2
    80003640:	00001097          	auipc	ra,0x1
    80003644:	b4c080e7          	jalr	-1204(ra) # 8000418c <initlog>
}
    80003648:	70a2                	ld	ra,40(sp)
    8000364a:	7402                	ld	s0,32(sp)
    8000364c:	64e2                	ld	s1,24(sp)
    8000364e:	6942                	ld	s2,16(sp)
    80003650:	69a2                	ld	s3,8(sp)
    80003652:	6145                	addi	sp,sp,48
    80003654:	8082                	ret
    panic("invalid file system");
    80003656:	00005517          	auipc	a0,0x5
    8000365a:	ee250513          	addi	a0,a0,-286 # 80008538 <syscalls+0x150>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	ed2080e7          	jalr	-302(ra) # 80000530 <panic>

0000000080003666 <iinit>:
{
    80003666:	7179                	addi	sp,sp,-48
    80003668:	f406                	sd	ra,40(sp)
    8000366a:	f022                	sd	s0,32(sp)
    8000366c:	ec26                	sd	s1,24(sp)
    8000366e:	e84a                	sd	s2,16(sp)
    80003670:	e44e                	sd	s3,8(sp)
    80003672:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003674:	00005597          	auipc	a1,0x5
    80003678:	edc58593          	addi	a1,a1,-292 # 80008550 <syscalls+0x168>
    8000367c:	00028517          	auipc	a0,0x28
    80003680:	13450513          	addi	a0,a0,308 # 8002b7b0 <icache>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	4c2080e7          	jalr	1218(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000368c:	00028497          	auipc	s1,0x28
    80003690:	14c48493          	addi	s1,s1,332 # 8002b7d8 <icache+0x28>
    80003694:	0002a997          	auipc	s3,0x2a
    80003698:	bd498993          	addi	s3,s3,-1068 # 8002d268 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000369c:	00005917          	auipc	s2,0x5
    800036a0:	ebc90913          	addi	s2,s2,-324 # 80008558 <syscalls+0x170>
    800036a4:	85ca                	mv	a1,s2
    800036a6:	8526                	mv	a0,s1
    800036a8:	00001097          	auipc	ra,0x1
    800036ac:	e4e080e7          	jalr	-434(ra) # 800044f6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036b0:	08848493          	addi	s1,s1,136
    800036b4:	ff3498e3          	bne	s1,s3,800036a4 <iinit+0x3e>
}
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6942                	ld	s2,16(sp)
    800036c0:	69a2                	ld	s3,8(sp)
    800036c2:	6145                	addi	sp,sp,48
    800036c4:	8082                	ret

00000000800036c6 <ialloc>:
{
    800036c6:	715d                	addi	sp,sp,-80
    800036c8:	e486                	sd	ra,72(sp)
    800036ca:	e0a2                	sd	s0,64(sp)
    800036cc:	fc26                	sd	s1,56(sp)
    800036ce:	f84a                	sd	s2,48(sp)
    800036d0:	f44e                	sd	s3,40(sp)
    800036d2:	f052                	sd	s4,32(sp)
    800036d4:	ec56                	sd	s5,24(sp)
    800036d6:	e85a                	sd	s6,16(sp)
    800036d8:	e45e                	sd	s7,8(sp)
    800036da:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036dc:	00028717          	auipc	a4,0x28
    800036e0:	0c072703          	lw	a4,192(a4) # 8002b79c <sb+0xc>
    800036e4:	4785                	li	a5,1
    800036e6:	04e7fa63          	bgeu	a5,a4,8000373a <ialloc+0x74>
    800036ea:	8aaa                	mv	s5,a0
    800036ec:	8bae                	mv	s7,a1
    800036ee:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036f0:	00028a17          	auipc	s4,0x28
    800036f4:	0a0a0a13          	addi	s4,s4,160 # 8002b790 <sb>
    800036f8:	00048b1b          	sext.w	s6,s1
    800036fc:	0044d593          	srli	a1,s1,0x4
    80003700:	018a2783          	lw	a5,24(s4)
    80003704:	9dbd                	addw	a1,a1,a5
    80003706:	8556                	mv	a0,s5
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	954080e7          	jalr	-1708(ra) # 8000305c <bread>
    80003710:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003712:	05850993          	addi	s3,a0,88
    80003716:	00f4f793          	andi	a5,s1,15
    8000371a:	079a                	slli	a5,a5,0x6
    8000371c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000371e:	00099783          	lh	a5,0(s3)
    80003722:	c785                	beqz	a5,8000374a <ialloc+0x84>
    brelse(bp);
    80003724:	00000097          	auipc	ra,0x0
    80003728:	a68080e7          	jalr	-1432(ra) # 8000318c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000372c:	0485                	addi	s1,s1,1
    8000372e:	00ca2703          	lw	a4,12(s4)
    80003732:	0004879b          	sext.w	a5,s1
    80003736:	fce7e1e3          	bltu	a5,a4,800036f8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000373a:	00005517          	auipc	a0,0x5
    8000373e:	e2650513          	addi	a0,a0,-474 # 80008560 <syscalls+0x178>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	dee080e7          	jalr	-530(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    8000374a:	04000613          	li	a2,64
    8000374e:	4581                	li	a1,0
    80003750:	854e                	mv	a0,s3
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	580080e7          	jalr	1408(ra) # 80000cd2 <memset>
      dip->type = type;
    8000375a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	ca8080e7          	jalr	-856(ra) # 80004408 <log_write>
      brelse(bp);
    80003768:	854a                	mv	a0,s2
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	a22080e7          	jalr	-1502(ra) # 8000318c <brelse>
      return iget(dev, inum);
    80003772:	85da                	mv	a1,s6
    80003774:	8556                	mv	a0,s5
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	db4080e7          	jalr	-588(ra) # 8000352a <iget>
}
    8000377e:	60a6                	ld	ra,72(sp)
    80003780:	6406                	ld	s0,64(sp)
    80003782:	74e2                	ld	s1,56(sp)
    80003784:	7942                	ld	s2,48(sp)
    80003786:	79a2                	ld	s3,40(sp)
    80003788:	7a02                	ld	s4,32(sp)
    8000378a:	6ae2                	ld	s5,24(sp)
    8000378c:	6b42                	ld	s6,16(sp)
    8000378e:	6ba2                	ld	s7,8(sp)
    80003790:	6161                	addi	sp,sp,80
    80003792:	8082                	ret

0000000080003794 <iupdate>:
{
    80003794:	1101                	addi	sp,sp,-32
    80003796:	ec06                	sd	ra,24(sp)
    80003798:	e822                	sd	s0,16(sp)
    8000379a:	e426                	sd	s1,8(sp)
    8000379c:	e04a                	sd	s2,0(sp)
    8000379e:	1000                	addi	s0,sp,32
    800037a0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037a2:	415c                	lw	a5,4(a0)
    800037a4:	0047d79b          	srliw	a5,a5,0x4
    800037a8:	00028597          	auipc	a1,0x28
    800037ac:	0005a583          	lw	a1,0(a1) # 8002b7a8 <sb+0x18>
    800037b0:	9dbd                	addw	a1,a1,a5
    800037b2:	4108                	lw	a0,0(a0)
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	8a8080e7          	jalr	-1880(ra) # 8000305c <bread>
    800037bc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037be:	05850793          	addi	a5,a0,88
    800037c2:	40c8                	lw	a0,4(s1)
    800037c4:	893d                	andi	a0,a0,15
    800037c6:	051a                	slli	a0,a0,0x6
    800037c8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037ca:	04449703          	lh	a4,68(s1)
    800037ce:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037d2:	04649703          	lh	a4,70(s1)
    800037d6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037da:	04849703          	lh	a4,72(s1)
    800037de:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037e2:	04a49703          	lh	a4,74(s1)
    800037e6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037ea:	44f8                	lw	a4,76(s1)
    800037ec:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037ee:	03400613          	li	a2,52
    800037f2:	05048593          	addi	a1,s1,80
    800037f6:	0531                	addi	a0,a0,12
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	53a080e7          	jalr	1338(ra) # 80000d32 <memmove>
  log_write(bp);
    80003800:	854a                	mv	a0,s2
    80003802:	00001097          	auipc	ra,0x1
    80003806:	c06080e7          	jalr	-1018(ra) # 80004408 <log_write>
  brelse(bp);
    8000380a:	854a                	mv	a0,s2
    8000380c:	00000097          	auipc	ra,0x0
    80003810:	980080e7          	jalr	-1664(ra) # 8000318c <brelse>
}
    80003814:	60e2                	ld	ra,24(sp)
    80003816:	6442                	ld	s0,16(sp)
    80003818:	64a2                	ld	s1,8(sp)
    8000381a:	6902                	ld	s2,0(sp)
    8000381c:	6105                	addi	sp,sp,32
    8000381e:	8082                	ret

0000000080003820 <idup>:
{
    80003820:	1101                	addi	sp,sp,-32
    80003822:	ec06                	sd	ra,24(sp)
    80003824:	e822                	sd	s0,16(sp)
    80003826:	e426                	sd	s1,8(sp)
    80003828:	1000                	addi	s0,sp,32
    8000382a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000382c:	00028517          	auipc	a0,0x28
    80003830:	f8450513          	addi	a0,a0,-124 # 8002b7b0 <icache>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	3a2080e7          	jalr	930(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000383c:	449c                	lw	a5,8(s1)
    8000383e:	2785                	addiw	a5,a5,1
    80003840:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003842:	00028517          	auipc	a0,0x28
    80003846:	f6e50513          	addi	a0,a0,-146 # 8002b7b0 <icache>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	440080e7          	jalr	1088(ra) # 80000c8a <release>
}
    80003852:	8526                	mv	a0,s1
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	64a2                	ld	s1,8(sp)
    8000385a:	6105                	addi	sp,sp,32
    8000385c:	8082                	ret

000000008000385e <ilock>:
{
    8000385e:	1101                	addi	sp,sp,-32
    80003860:	ec06                	sd	ra,24(sp)
    80003862:	e822                	sd	s0,16(sp)
    80003864:	e426                	sd	s1,8(sp)
    80003866:	e04a                	sd	s2,0(sp)
    80003868:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000386a:	c115                	beqz	a0,8000388e <ilock+0x30>
    8000386c:	84aa                	mv	s1,a0
    8000386e:	451c                	lw	a5,8(a0)
    80003870:	00f05f63          	blez	a5,8000388e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003874:	0541                	addi	a0,a0,16
    80003876:	00001097          	auipc	ra,0x1
    8000387a:	cba080e7          	jalr	-838(ra) # 80004530 <acquiresleep>
  if(ip->valid == 0){
    8000387e:	40bc                	lw	a5,64(s1)
    80003880:	cf99                	beqz	a5,8000389e <ilock+0x40>
}
    80003882:	60e2                	ld	ra,24(sp)
    80003884:	6442                	ld	s0,16(sp)
    80003886:	64a2                	ld	s1,8(sp)
    80003888:	6902                	ld	s2,0(sp)
    8000388a:	6105                	addi	sp,sp,32
    8000388c:	8082                	ret
    panic("ilock");
    8000388e:	00005517          	auipc	a0,0x5
    80003892:	cea50513          	addi	a0,a0,-790 # 80008578 <syscalls+0x190>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	c9a080e7          	jalr	-870(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000389e:	40dc                	lw	a5,4(s1)
    800038a0:	0047d79b          	srliw	a5,a5,0x4
    800038a4:	00028597          	auipc	a1,0x28
    800038a8:	f045a583          	lw	a1,-252(a1) # 8002b7a8 <sb+0x18>
    800038ac:	9dbd                	addw	a1,a1,a5
    800038ae:	4088                	lw	a0,0(s1)
    800038b0:	fffff097          	auipc	ra,0xfffff
    800038b4:	7ac080e7          	jalr	1964(ra) # 8000305c <bread>
    800038b8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038ba:	05850593          	addi	a1,a0,88
    800038be:	40dc                	lw	a5,4(s1)
    800038c0:	8bbd                	andi	a5,a5,15
    800038c2:	079a                	slli	a5,a5,0x6
    800038c4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038c6:	00059783          	lh	a5,0(a1)
    800038ca:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038ce:	00259783          	lh	a5,2(a1)
    800038d2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038d6:	00459783          	lh	a5,4(a1)
    800038da:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038de:	00659783          	lh	a5,6(a1)
    800038e2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038e6:	459c                	lw	a5,8(a1)
    800038e8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038ea:	03400613          	li	a2,52
    800038ee:	05b1                	addi	a1,a1,12
    800038f0:	05048513          	addi	a0,s1,80
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	43e080e7          	jalr	1086(ra) # 80000d32 <memmove>
    brelse(bp);
    800038fc:	854a                	mv	a0,s2
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	88e080e7          	jalr	-1906(ra) # 8000318c <brelse>
    ip->valid = 1;
    80003906:	4785                	li	a5,1
    80003908:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000390a:	04449783          	lh	a5,68(s1)
    8000390e:	fbb5                	bnez	a5,80003882 <ilock+0x24>
      panic("ilock: no type");
    80003910:	00005517          	auipc	a0,0x5
    80003914:	c7050513          	addi	a0,a0,-912 # 80008580 <syscalls+0x198>
    80003918:	ffffd097          	auipc	ra,0xffffd
    8000391c:	c18080e7          	jalr	-1000(ra) # 80000530 <panic>

0000000080003920 <iunlock>:
{
    80003920:	1101                	addi	sp,sp,-32
    80003922:	ec06                	sd	ra,24(sp)
    80003924:	e822                	sd	s0,16(sp)
    80003926:	e426                	sd	s1,8(sp)
    80003928:	e04a                	sd	s2,0(sp)
    8000392a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000392c:	c905                	beqz	a0,8000395c <iunlock+0x3c>
    8000392e:	84aa                	mv	s1,a0
    80003930:	01050913          	addi	s2,a0,16
    80003934:	854a                	mv	a0,s2
    80003936:	00001097          	auipc	ra,0x1
    8000393a:	c94080e7          	jalr	-876(ra) # 800045ca <holdingsleep>
    8000393e:	cd19                	beqz	a0,8000395c <iunlock+0x3c>
    80003940:	449c                	lw	a5,8(s1)
    80003942:	00f05d63          	blez	a5,8000395c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003946:	854a                	mv	a0,s2
    80003948:	00001097          	auipc	ra,0x1
    8000394c:	c3e080e7          	jalr	-962(ra) # 80004586 <releasesleep>
}
    80003950:	60e2                	ld	ra,24(sp)
    80003952:	6442                	ld	s0,16(sp)
    80003954:	64a2                	ld	s1,8(sp)
    80003956:	6902                	ld	s2,0(sp)
    80003958:	6105                	addi	sp,sp,32
    8000395a:	8082                	ret
    panic("iunlock");
    8000395c:	00005517          	auipc	a0,0x5
    80003960:	c3450513          	addi	a0,a0,-972 # 80008590 <syscalls+0x1a8>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	bcc080e7          	jalr	-1076(ra) # 80000530 <panic>

000000008000396c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000396c:	7179                	addi	sp,sp,-48
    8000396e:	f406                	sd	ra,40(sp)
    80003970:	f022                	sd	s0,32(sp)
    80003972:	ec26                	sd	s1,24(sp)
    80003974:	e84a                	sd	s2,16(sp)
    80003976:	e44e                	sd	s3,8(sp)
    80003978:	e052                	sd	s4,0(sp)
    8000397a:	1800                	addi	s0,sp,48
    8000397c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000397e:	05050493          	addi	s1,a0,80
    80003982:	08050913          	addi	s2,a0,128
    80003986:	a021                	j	8000398e <itrunc+0x22>
    80003988:	0491                	addi	s1,s1,4
    8000398a:	01248d63          	beq	s1,s2,800039a4 <itrunc+0x38>
    if(ip->addrs[i]){
    8000398e:	408c                	lw	a1,0(s1)
    80003990:	dde5                	beqz	a1,80003988 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003992:	0009a503          	lw	a0,0(s3)
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	90c080e7          	jalr	-1780(ra) # 800032a2 <bfree>
      ip->addrs[i] = 0;
    8000399e:	0004a023          	sw	zero,0(s1)
    800039a2:	b7dd                	j	80003988 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039a4:	0809a583          	lw	a1,128(s3)
    800039a8:	e185                	bnez	a1,800039c8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039aa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039ae:	854e                	mv	a0,s3
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	de4080e7          	jalr	-540(ra) # 80003794 <iupdate>
}
    800039b8:	70a2                	ld	ra,40(sp)
    800039ba:	7402                	ld	s0,32(sp)
    800039bc:	64e2                	ld	s1,24(sp)
    800039be:	6942                	ld	s2,16(sp)
    800039c0:	69a2                	ld	s3,8(sp)
    800039c2:	6a02                	ld	s4,0(sp)
    800039c4:	6145                	addi	sp,sp,48
    800039c6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039c8:	0009a503          	lw	a0,0(s3)
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	690080e7          	jalr	1680(ra) # 8000305c <bread>
    800039d4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039d6:	05850493          	addi	s1,a0,88
    800039da:	45850913          	addi	s2,a0,1112
    800039de:	a811                	j	800039f2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039e0:	0009a503          	lw	a0,0(s3)
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	8be080e7          	jalr	-1858(ra) # 800032a2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039ec:	0491                	addi	s1,s1,4
    800039ee:	01248563          	beq	s1,s2,800039f8 <itrunc+0x8c>
      if(a[j])
    800039f2:	408c                	lw	a1,0(s1)
    800039f4:	dde5                	beqz	a1,800039ec <itrunc+0x80>
    800039f6:	b7ed                	j	800039e0 <itrunc+0x74>
    brelse(bp);
    800039f8:	8552                	mv	a0,s4
    800039fa:	fffff097          	auipc	ra,0xfffff
    800039fe:	792080e7          	jalr	1938(ra) # 8000318c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a02:	0809a583          	lw	a1,128(s3)
    80003a06:	0009a503          	lw	a0,0(s3)
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	898080e7          	jalr	-1896(ra) # 800032a2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a12:	0809a023          	sw	zero,128(s3)
    80003a16:	bf51                	j	800039aa <itrunc+0x3e>

0000000080003a18 <iput>:
{
    80003a18:	1101                	addi	sp,sp,-32
    80003a1a:	ec06                	sd	ra,24(sp)
    80003a1c:	e822                	sd	s0,16(sp)
    80003a1e:	e426                	sd	s1,8(sp)
    80003a20:	e04a                	sd	s2,0(sp)
    80003a22:	1000                	addi	s0,sp,32
    80003a24:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a26:	00028517          	auipc	a0,0x28
    80003a2a:	d8a50513          	addi	a0,a0,-630 # 8002b7b0 <icache>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	1a8080e7          	jalr	424(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a36:	4498                	lw	a4,8(s1)
    80003a38:	4785                	li	a5,1
    80003a3a:	02f70363          	beq	a4,a5,80003a60 <iput+0x48>
  ip->ref--;
    80003a3e:	449c                	lw	a5,8(s1)
    80003a40:	37fd                	addiw	a5,a5,-1
    80003a42:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a44:	00028517          	auipc	a0,0x28
    80003a48:	d6c50513          	addi	a0,a0,-660 # 8002b7b0 <icache>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	23e080e7          	jalr	574(ra) # 80000c8a <release>
}
    80003a54:	60e2                	ld	ra,24(sp)
    80003a56:	6442                	ld	s0,16(sp)
    80003a58:	64a2                	ld	s1,8(sp)
    80003a5a:	6902                	ld	s2,0(sp)
    80003a5c:	6105                	addi	sp,sp,32
    80003a5e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a60:	40bc                	lw	a5,64(s1)
    80003a62:	dff1                	beqz	a5,80003a3e <iput+0x26>
    80003a64:	04a49783          	lh	a5,74(s1)
    80003a68:	fbf9                	bnez	a5,80003a3e <iput+0x26>
    acquiresleep(&ip->lock);
    80003a6a:	01048913          	addi	s2,s1,16
    80003a6e:	854a                	mv	a0,s2
    80003a70:	00001097          	auipc	ra,0x1
    80003a74:	ac0080e7          	jalr	-1344(ra) # 80004530 <acquiresleep>
    release(&icache.lock);
    80003a78:	00028517          	auipc	a0,0x28
    80003a7c:	d3850513          	addi	a0,a0,-712 # 8002b7b0 <icache>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	20a080e7          	jalr	522(ra) # 80000c8a <release>
    itrunc(ip);
    80003a88:	8526                	mv	a0,s1
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	ee2080e7          	jalr	-286(ra) # 8000396c <itrunc>
    ip->type = 0;
    80003a92:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a96:	8526                	mv	a0,s1
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	cfc080e7          	jalr	-772(ra) # 80003794 <iupdate>
    ip->valid = 0;
    80003aa0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003aa4:	854a                	mv	a0,s2
    80003aa6:	00001097          	auipc	ra,0x1
    80003aaa:	ae0080e7          	jalr	-1312(ra) # 80004586 <releasesleep>
    acquire(&icache.lock);
    80003aae:	00028517          	auipc	a0,0x28
    80003ab2:	d0250513          	addi	a0,a0,-766 # 8002b7b0 <icache>
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	120080e7          	jalr	288(ra) # 80000bd6 <acquire>
    80003abe:	b741                	j	80003a3e <iput+0x26>

0000000080003ac0 <iunlockput>:
{
    80003ac0:	1101                	addi	sp,sp,-32
    80003ac2:	ec06                	sd	ra,24(sp)
    80003ac4:	e822                	sd	s0,16(sp)
    80003ac6:	e426                	sd	s1,8(sp)
    80003ac8:	1000                	addi	s0,sp,32
    80003aca:	84aa                	mv	s1,a0
  iunlock(ip);
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	e54080e7          	jalr	-428(ra) # 80003920 <iunlock>
  iput(ip);
    80003ad4:	8526                	mv	a0,s1
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	f42080e7          	jalr	-190(ra) # 80003a18 <iput>
}
    80003ade:	60e2                	ld	ra,24(sp)
    80003ae0:	6442                	ld	s0,16(sp)
    80003ae2:	64a2                	ld	s1,8(sp)
    80003ae4:	6105                	addi	sp,sp,32
    80003ae6:	8082                	ret

0000000080003ae8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ae8:	1141                	addi	sp,sp,-16
    80003aea:	e422                	sd	s0,8(sp)
    80003aec:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003aee:	411c                	lw	a5,0(a0)
    80003af0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003af2:	415c                	lw	a5,4(a0)
    80003af4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003af6:	04451783          	lh	a5,68(a0)
    80003afa:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003afe:	04a51783          	lh	a5,74(a0)
    80003b02:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b06:	04c56783          	lwu	a5,76(a0)
    80003b0a:	e99c                	sd	a5,16(a1)
}
    80003b0c:	6422                	ld	s0,8(sp)
    80003b0e:	0141                	addi	sp,sp,16
    80003b10:	8082                	ret

0000000080003b12 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b12:	457c                	lw	a5,76(a0)
    80003b14:	0ed7e963          	bltu	a5,a3,80003c06 <readi+0xf4>
{
    80003b18:	7159                	addi	sp,sp,-112
    80003b1a:	f486                	sd	ra,104(sp)
    80003b1c:	f0a2                	sd	s0,96(sp)
    80003b1e:	eca6                	sd	s1,88(sp)
    80003b20:	e8ca                	sd	s2,80(sp)
    80003b22:	e4ce                	sd	s3,72(sp)
    80003b24:	e0d2                	sd	s4,64(sp)
    80003b26:	fc56                	sd	s5,56(sp)
    80003b28:	f85a                	sd	s6,48(sp)
    80003b2a:	f45e                	sd	s7,40(sp)
    80003b2c:	f062                	sd	s8,32(sp)
    80003b2e:	ec66                	sd	s9,24(sp)
    80003b30:	e86a                	sd	s10,16(sp)
    80003b32:	e46e                	sd	s11,8(sp)
    80003b34:	1880                	addi	s0,sp,112
    80003b36:	8baa                	mv	s7,a0
    80003b38:	8c2e                	mv	s8,a1
    80003b3a:	8ab2                	mv	s5,a2
    80003b3c:	84b6                	mv	s1,a3
    80003b3e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b40:	9f35                	addw	a4,a4,a3
    return 0;
    80003b42:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b44:	0ad76063          	bltu	a4,a3,80003be4 <readi+0xd2>
  if(off + n > ip->size)
    80003b48:	00e7f463          	bgeu	a5,a4,80003b50 <readi+0x3e>
    n = ip->size - off;
    80003b4c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b50:	0a0b0963          	beqz	s6,80003c02 <readi+0xf0>
    80003b54:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b56:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b5a:	5cfd                	li	s9,-1
    80003b5c:	a82d                	j	80003b96 <readi+0x84>
    80003b5e:	020a1d93          	slli	s11,s4,0x20
    80003b62:	020ddd93          	srli	s11,s11,0x20
    80003b66:	05890613          	addi	a2,s2,88
    80003b6a:	86ee                	mv	a3,s11
    80003b6c:	963a                	add	a2,a2,a4
    80003b6e:	85d6                	mv	a1,s5
    80003b70:	8562                	mv	a0,s8
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	966080e7          	jalr	-1690(ra) # 800024d8 <either_copyout>
    80003b7a:	05950d63          	beq	a0,s9,80003bd4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b7e:	854a                	mv	a0,s2
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	60c080e7          	jalr	1548(ra) # 8000318c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b88:	013a09bb          	addw	s3,s4,s3
    80003b8c:	009a04bb          	addw	s1,s4,s1
    80003b90:	9aee                	add	s5,s5,s11
    80003b92:	0569f763          	bgeu	s3,s6,80003be0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b96:	000ba903          	lw	s2,0(s7)
    80003b9a:	00a4d59b          	srliw	a1,s1,0xa
    80003b9e:	855e                	mv	a0,s7
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	8b0080e7          	jalr	-1872(ra) # 80003450 <bmap>
    80003ba8:	0005059b          	sext.w	a1,a0
    80003bac:	854a                	mv	a0,s2
    80003bae:	fffff097          	auipc	ra,0xfffff
    80003bb2:	4ae080e7          	jalr	1198(ra) # 8000305c <bread>
    80003bb6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb8:	3ff4f713          	andi	a4,s1,1023
    80003bbc:	40ed07bb          	subw	a5,s10,a4
    80003bc0:	413b06bb          	subw	a3,s6,s3
    80003bc4:	8a3e                	mv	s4,a5
    80003bc6:	2781                	sext.w	a5,a5
    80003bc8:	0006861b          	sext.w	a2,a3
    80003bcc:	f8f679e3          	bgeu	a2,a5,80003b5e <readi+0x4c>
    80003bd0:	8a36                	mv	s4,a3
    80003bd2:	b771                	j	80003b5e <readi+0x4c>
      brelse(bp);
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	5b6080e7          	jalr	1462(ra) # 8000318c <brelse>
      tot = -1;
    80003bde:	59fd                	li	s3,-1
  }
  return tot;
    80003be0:	0009851b          	sext.w	a0,s3
}
    80003be4:	70a6                	ld	ra,104(sp)
    80003be6:	7406                	ld	s0,96(sp)
    80003be8:	64e6                	ld	s1,88(sp)
    80003bea:	6946                	ld	s2,80(sp)
    80003bec:	69a6                	ld	s3,72(sp)
    80003bee:	6a06                	ld	s4,64(sp)
    80003bf0:	7ae2                	ld	s5,56(sp)
    80003bf2:	7b42                	ld	s6,48(sp)
    80003bf4:	7ba2                	ld	s7,40(sp)
    80003bf6:	7c02                	ld	s8,32(sp)
    80003bf8:	6ce2                	ld	s9,24(sp)
    80003bfa:	6d42                	ld	s10,16(sp)
    80003bfc:	6da2                	ld	s11,8(sp)
    80003bfe:	6165                	addi	sp,sp,112
    80003c00:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c02:	89da                	mv	s3,s6
    80003c04:	bff1                	j	80003be0 <readi+0xce>
    return 0;
    80003c06:	4501                	li	a0,0
}
    80003c08:	8082                	ret

0000000080003c0a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c0a:	457c                	lw	a5,76(a0)
    80003c0c:	10d7e863          	bltu	a5,a3,80003d1c <writei+0x112>
{
    80003c10:	7159                	addi	sp,sp,-112
    80003c12:	f486                	sd	ra,104(sp)
    80003c14:	f0a2                	sd	s0,96(sp)
    80003c16:	eca6                	sd	s1,88(sp)
    80003c18:	e8ca                	sd	s2,80(sp)
    80003c1a:	e4ce                	sd	s3,72(sp)
    80003c1c:	e0d2                	sd	s4,64(sp)
    80003c1e:	fc56                	sd	s5,56(sp)
    80003c20:	f85a                	sd	s6,48(sp)
    80003c22:	f45e                	sd	s7,40(sp)
    80003c24:	f062                	sd	s8,32(sp)
    80003c26:	ec66                	sd	s9,24(sp)
    80003c28:	e86a                	sd	s10,16(sp)
    80003c2a:	e46e                	sd	s11,8(sp)
    80003c2c:	1880                	addi	s0,sp,112
    80003c2e:	8b2a                	mv	s6,a0
    80003c30:	8c2e                	mv	s8,a1
    80003c32:	8ab2                	mv	s5,a2
    80003c34:	8936                	mv	s2,a3
    80003c36:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c38:	00e687bb          	addw	a5,a3,a4
    80003c3c:	0ed7e263          	bltu	a5,a3,80003d20 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c40:	00043737          	lui	a4,0x43
    80003c44:	0ef76063          	bltu	a4,a5,80003d24 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c48:	0c0b8863          	beqz	s7,80003d18 <writei+0x10e>
    80003c4c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c4e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c52:	5cfd                	li	s9,-1
    80003c54:	a091                	j	80003c98 <writei+0x8e>
    80003c56:	02099d93          	slli	s11,s3,0x20
    80003c5a:	020ddd93          	srli	s11,s11,0x20
    80003c5e:	05848513          	addi	a0,s1,88
    80003c62:	86ee                	mv	a3,s11
    80003c64:	8656                	mv	a2,s5
    80003c66:	85e2                	mv	a1,s8
    80003c68:	953a                	add	a0,a0,a4
    80003c6a:	fffff097          	auipc	ra,0xfffff
    80003c6e:	8c4080e7          	jalr	-1852(ra) # 8000252e <either_copyin>
    80003c72:	07950263          	beq	a0,s9,80003cd6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c76:	8526                	mv	a0,s1
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	790080e7          	jalr	1936(ra) # 80004408 <log_write>
    brelse(bp);
    80003c80:	8526                	mv	a0,s1
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	50a080e7          	jalr	1290(ra) # 8000318c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c8a:	01498a3b          	addw	s4,s3,s4
    80003c8e:	0129893b          	addw	s2,s3,s2
    80003c92:	9aee                	add	s5,s5,s11
    80003c94:	057a7663          	bgeu	s4,s7,80003ce0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c98:	000b2483          	lw	s1,0(s6)
    80003c9c:	00a9559b          	srliw	a1,s2,0xa
    80003ca0:	855a                	mv	a0,s6
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	7ae080e7          	jalr	1966(ra) # 80003450 <bmap>
    80003caa:	0005059b          	sext.w	a1,a0
    80003cae:	8526                	mv	a0,s1
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	3ac080e7          	jalr	940(ra) # 8000305c <bread>
    80003cb8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cba:	3ff97713          	andi	a4,s2,1023
    80003cbe:	40ed07bb          	subw	a5,s10,a4
    80003cc2:	414b86bb          	subw	a3,s7,s4
    80003cc6:	89be                	mv	s3,a5
    80003cc8:	2781                	sext.w	a5,a5
    80003cca:	0006861b          	sext.w	a2,a3
    80003cce:	f8f674e3          	bgeu	a2,a5,80003c56 <writei+0x4c>
    80003cd2:	89b6                	mv	s3,a3
    80003cd4:	b749                	j	80003c56 <writei+0x4c>
      brelse(bp);
    80003cd6:	8526                	mv	a0,s1
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	4b4080e7          	jalr	1204(ra) # 8000318c <brelse>
  }

  if(off > ip->size)
    80003ce0:	04cb2783          	lw	a5,76(s6)
    80003ce4:	0127f463          	bgeu	a5,s2,80003cec <writei+0xe2>
    ip->size = off;
    80003ce8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cec:	855a                	mv	a0,s6
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	aa6080e7          	jalr	-1370(ra) # 80003794 <iupdate>

  return tot;
    80003cf6:	000a051b          	sext.w	a0,s4
}
    80003cfa:	70a6                	ld	ra,104(sp)
    80003cfc:	7406                	ld	s0,96(sp)
    80003cfe:	64e6                	ld	s1,88(sp)
    80003d00:	6946                	ld	s2,80(sp)
    80003d02:	69a6                	ld	s3,72(sp)
    80003d04:	6a06                	ld	s4,64(sp)
    80003d06:	7ae2                	ld	s5,56(sp)
    80003d08:	7b42                	ld	s6,48(sp)
    80003d0a:	7ba2                	ld	s7,40(sp)
    80003d0c:	7c02                	ld	s8,32(sp)
    80003d0e:	6ce2                	ld	s9,24(sp)
    80003d10:	6d42                	ld	s10,16(sp)
    80003d12:	6da2                	ld	s11,8(sp)
    80003d14:	6165                	addi	sp,sp,112
    80003d16:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d18:	8a5e                	mv	s4,s7
    80003d1a:	bfc9                	j	80003cec <writei+0xe2>
    return -1;
    80003d1c:	557d                	li	a0,-1
}
    80003d1e:	8082                	ret
    return -1;
    80003d20:	557d                	li	a0,-1
    80003d22:	bfe1                	j	80003cfa <writei+0xf0>
    return -1;
    80003d24:	557d                	li	a0,-1
    80003d26:	bfd1                	j	80003cfa <writei+0xf0>

0000000080003d28 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d28:	1141                	addi	sp,sp,-16
    80003d2a:	e406                	sd	ra,8(sp)
    80003d2c:	e022                	sd	s0,0(sp)
    80003d2e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d30:	4639                	li	a2,14
    80003d32:	ffffd097          	auipc	ra,0xffffd
    80003d36:	07c080e7          	jalr	124(ra) # 80000dae <strncmp>
}
    80003d3a:	60a2                	ld	ra,8(sp)
    80003d3c:	6402                	ld	s0,0(sp)
    80003d3e:	0141                	addi	sp,sp,16
    80003d40:	8082                	ret

0000000080003d42 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d42:	7139                	addi	sp,sp,-64
    80003d44:	fc06                	sd	ra,56(sp)
    80003d46:	f822                	sd	s0,48(sp)
    80003d48:	f426                	sd	s1,40(sp)
    80003d4a:	f04a                	sd	s2,32(sp)
    80003d4c:	ec4e                	sd	s3,24(sp)
    80003d4e:	e852                	sd	s4,16(sp)
    80003d50:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d52:	04451703          	lh	a4,68(a0)
    80003d56:	4785                	li	a5,1
    80003d58:	00f71a63          	bne	a4,a5,80003d6c <dirlookup+0x2a>
    80003d5c:	892a                	mv	s2,a0
    80003d5e:	89ae                	mv	s3,a1
    80003d60:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d62:	457c                	lw	a5,76(a0)
    80003d64:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d66:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d68:	e79d                	bnez	a5,80003d96 <dirlookup+0x54>
    80003d6a:	a8a5                	j	80003de2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d6c:	00005517          	auipc	a0,0x5
    80003d70:	82c50513          	addi	a0,a0,-2004 # 80008598 <syscalls+0x1b0>
    80003d74:	ffffc097          	auipc	ra,0xffffc
    80003d78:	7bc080e7          	jalr	1980(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003d7c:	00005517          	auipc	a0,0x5
    80003d80:	83450513          	addi	a0,a0,-1996 # 800085b0 <syscalls+0x1c8>
    80003d84:	ffffc097          	auipc	ra,0xffffc
    80003d88:	7ac080e7          	jalr	1964(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8c:	24c1                	addiw	s1,s1,16
    80003d8e:	04c92783          	lw	a5,76(s2)
    80003d92:	04f4f763          	bgeu	s1,a5,80003de0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d96:	4741                	li	a4,16
    80003d98:	86a6                	mv	a3,s1
    80003d9a:	fc040613          	addi	a2,s0,-64
    80003d9e:	4581                	li	a1,0
    80003da0:	854a                	mv	a0,s2
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	d70080e7          	jalr	-656(ra) # 80003b12 <readi>
    80003daa:	47c1                	li	a5,16
    80003dac:	fcf518e3          	bne	a0,a5,80003d7c <dirlookup+0x3a>
    if(de.inum == 0)
    80003db0:	fc045783          	lhu	a5,-64(s0)
    80003db4:	dfe1                	beqz	a5,80003d8c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003db6:	fc240593          	addi	a1,s0,-62
    80003dba:	854e                	mv	a0,s3
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	f6c080e7          	jalr	-148(ra) # 80003d28 <namecmp>
    80003dc4:	f561                	bnez	a0,80003d8c <dirlookup+0x4a>
      if(poff)
    80003dc6:	000a0463          	beqz	s4,80003dce <dirlookup+0x8c>
        *poff = off;
    80003dca:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dce:	fc045583          	lhu	a1,-64(s0)
    80003dd2:	00092503          	lw	a0,0(s2)
    80003dd6:	fffff097          	auipc	ra,0xfffff
    80003dda:	754080e7          	jalr	1876(ra) # 8000352a <iget>
    80003dde:	a011                	j	80003de2 <dirlookup+0xa0>
  return 0;
    80003de0:	4501                	li	a0,0
}
    80003de2:	70e2                	ld	ra,56(sp)
    80003de4:	7442                	ld	s0,48(sp)
    80003de6:	74a2                	ld	s1,40(sp)
    80003de8:	7902                	ld	s2,32(sp)
    80003dea:	69e2                	ld	s3,24(sp)
    80003dec:	6a42                	ld	s4,16(sp)
    80003dee:	6121                	addi	sp,sp,64
    80003df0:	8082                	ret

0000000080003df2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003df2:	711d                	addi	sp,sp,-96
    80003df4:	ec86                	sd	ra,88(sp)
    80003df6:	e8a2                	sd	s0,80(sp)
    80003df8:	e4a6                	sd	s1,72(sp)
    80003dfa:	e0ca                	sd	s2,64(sp)
    80003dfc:	fc4e                	sd	s3,56(sp)
    80003dfe:	f852                	sd	s4,48(sp)
    80003e00:	f456                	sd	s5,40(sp)
    80003e02:	f05a                	sd	s6,32(sp)
    80003e04:	ec5e                	sd	s7,24(sp)
    80003e06:	e862                	sd	s8,16(sp)
    80003e08:	e466                	sd	s9,8(sp)
    80003e0a:	1080                	addi	s0,sp,96
    80003e0c:	84aa                	mv	s1,a0
    80003e0e:	8b2e                	mv	s6,a1
    80003e10:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e12:	00054703          	lbu	a4,0(a0)
    80003e16:	02f00793          	li	a5,47
    80003e1a:	02f70363          	beq	a4,a5,80003e40 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e1e:	ffffe097          	auipc	ra,0xffffe
    80003e22:	b88080e7          	jalr	-1144(ra) # 800019a6 <myproc>
    80003e26:	15053503          	ld	a0,336(a0)
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	9f6080e7          	jalr	-1546(ra) # 80003820 <idup>
    80003e32:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e34:	02f00913          	li	s2,47
  len = path - s;
    80003e38:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e3a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e3c:	4c05                	li	s8,1
    80003e3e:	a865                	j	80003ef6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e40:	4585                	li	a1,1
    80003e42:	4505                	li	a0,1
    80003e44:	fffff097          	auipc	ra,0xfffff
    80003e48:	6e6080e7          	jalr	1766(ra) # 8000352a <iget>
    80003e4c:	89aa                	mv	s3,a0
    80003e4e:	b7dd                	j	80003e34 <namex+0x42>
      iunlockput(ip);
    80003e50:	854e                	mv	a0,s3
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	c6e080e7          	jalr	-914(ra) # 80003ac0 <iunlockput>
      return 0;
    80003e5a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	60e6                	ld	ra,88(sp)
    80003e60:	6446                	ld	s0,80(sp)
    80003e62:	64a6                	ld	s1,72(sp)
    80003e64:	6906                	ld	s2,64(sp)
    80003e66:	79e2                	ld	s3,56(sp)
    80003e68:	7a42                	ld	s4,48(sp)
    80003e6a:	7aa2                	ld	s5,40(sp)
    80003e6c:	7b02                	ld	s6,32(sp)
    80003e6e:	6be2                	ld	s7,24(sp)
    80003e70:	6c42                	ld	s8,16(sp)
    80003e72:	6ca2                	ld	s9,8(sp)
    80003e74:	6125                	addi	sp,sp,96
    80003e76:	8082                	ret
      iunlock(ip);
    80003e78:	854e                	mv	a0,s3
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	aa6080e7          	jalr	-1370(ra) # 80003920 <iunlock>
      return ip;
    80003e82:	bfe9                	j	80003e5c <namex+0x6a>
      iunlockput(ip);
    80003e84:	854e                	mv	a0,s3
    80003e86:	00000097          	auipc	ra,0x0
    80003e8a:	c3a080e7          	jalr	-966(ra) # 80003ac0 <iunlockput>
      return 0;
    80003e8e:	89d2                	mv	s3,s4
    80003e90:	b7f1                	j	80003e5c <namex+0x6a>
  len = path - s;
    80003e92:	40b48633          	sub	a2,s1,a1
    80003e96:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e9a:	094cd463          	bge	s9,s4,80003f22 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e9e:	4639                	li	a2,14
    80003ea0:	8556                	mv	a0,s5
    80003ea2:	ffffd097          	auipc	ra,0xffffd
    80003ea6:	e90080e7          	jalr	-368(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003eaa:	0004c783          	lbu	a5,0(s1)
    80003eae:	01279763          	bne	a5,s2,80003ebc <namex+0xca>
    path++;
    80003eb2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	ff278de3          	beq	a5,s2,80003eb2 <namex+0xc0>
    ilock(ip);
    80003ebc:	854e                	mv	a0,s3
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	9a0080e7          	jalr	-1632(ra) # 8000385e <ilock>
    if(ip->type != T_DIR){
    80003ec6:	04499783          	lh	a5,68(s3)
    80003eca:	f98793e3          	bne	a5,s8,80003e50 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ece:	000b0563          	beqz	s6,80003ed8 <namex+0xe6>
    80003ed2:	0004c783          	lbu	a5,0(s1)
    80003ed6:	d3cd                	beqz	a5,80003e78 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ed8:	865e                	mv	a2,s7
    80003eda:	85d6                	mv	a1,s5
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	e64080e7          	jalr	-412(ra) # 80003d42 <dirlookup>
    80003ee6:	8a2a                	mv	s4,a0
    80003ee8:	dd51                	beqz	a0,80003e84 <namex+0x92>
    iunlockput(ip);
    80003eea:	854e                	mv	a0,s3
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	bd4080e7          	jalr	-1068(ra) # 80003ac0 <iunlockput>
    ip = next;
    80003ef4:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ef6:	0004c783          	lbu	a5,0(s1)
    80003efa:	05279763          	bne	a5,s2,80003f48 <namex+0x156>
    path++;
    80003efe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f00:	0004c783          	lbu	a5,0(s1)
    80003f04:	ff278de3          	beq	a5,s2,80003efe <namex+0x10c>
  if(*path == 0)
    80003f08:	c79d                	beqz	a5,80003f36 <namex+0x144>
    path++;
    80003f0a:	85a6                	mv	a1,s1
  len = path - s;
    80003f0c:	8a5e                	mv	s4,s7
    80003f0e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f10:	01278963          	beq	a5,s2,80003f22 <namex+0x130>
    80003f14:	dfbd                	beqz	a5,80003e92 <namex+0xa0>
    path++;
    80003f16:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f18:	0004c783          	lbu	a5,0(s1)
    80003f1c:	ff279ce3          	bne	a5,s2,80003f14 <namex+0x122>
    80003f20:	bf8d                	j	80003e92 <namex+0xa0>
    memmove(name, s, len);
    80003f22:	2601                	sext.w	a2,a2
    80003f24:	8556                	mv	a0,s5
    80003f26:	ffffd097          	auipc	ra,0xffffd
    80003f2a:	e0c080e7          	jalr	-500(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003f2e:	9a56                	add	s4,s4,s5
    80003f30:	000a0023          	sb	zero,0(s4)
    80003f34:	bf9d                	j	80003eaa <namex+0xb8>
  if(nameiparent){
    80003f36:	f20b03e3          	beqz	s6,80003e5c <namex+0x6a>
    iput(ip);
    80003f3a:	854e                	mv	a0,s3
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	adc080e7          	jalr	-1316(ra) # 80003a18 <iput>
    return 0;
    80003f44:	4981                	li	s3,0
    80003f46:	bf19                	j	80003e5c <namex+0x6a>
  if(*path == 0)
    80003f48:	d7fd                	beqz	a5,80003f36 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f4a:	0004c783          	lbu	a5,0(s1)
    80003f4e:	85a6                	mv	a1,s1
    80003f50:	b7d1                	j	80003f14 <namex+0x122>

0000000080003f52 <dirlink>:
{
    80003f52:	7139                	addi	sp,sp,-64
    80003f54:	fc06                	sd	ra,56(sp)
    80003f56:	f822                	sd	s0,48(sp)
    80003f58:	f426                	sd	s1,40(sp)
    80003f5a:	f04a                	sd	s2,32(sp)
    80003f5c:	ec4e                	sd	s3,24(sp)
    80003f5e:	e852                	sd	s4,16(sp)
    80003f60:	0080                	addi	s0,sp,64
    80003f62:	892a                	mv	s2,a0
    80003f64:	8a2e                	mv	s4,a1
    80003f66:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f68:	4601                	li	a2,0
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	dd8080e7          	jalr	-552(ra) # 80003d42 <dirlookup>
    80003f72:	e93d                	bnez	a0,80003fe8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f74:	04c92483          	lw	s1,76(s2)
    80003f78:	c49d                	beqz	s1,80003fa6 <dirlink+0x54>
    80003f7a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7c:	4741                	li	a4,16
    80003f7e:	86a6                	mv	a3,s1
    80003f80:	fc040613          	addi	a2,s0,-64
    80003f84:	4581                	li	a1,0
    80003f86:	854a                	mv	a0,s2
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	b8a080e7          	jalr	-1142(ra) # 80003b12 <readi>
    80003f90:	47c1                	li	a5,16
    80003f92:	06f51163          	bne	a0,a5,80003ff4 <dirlink+0xa2>
    if(de.inum == 0)
    80003f96:	fc045783          	lhu	a5,-64(s0)
    80003f9a:	c791                	beqz	a5,80003fa6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f9c:	24c1                	addiw	s1,s1,16
    80003f9e:	04c92783          	lw	a5,76(s2)
    80003fa2:	fcf4ede3          	bltu	s1,a5,80003f7c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fa6:	4639                	li	a2,14
    80003fa8:	85d2                	mv	a1,s4
    80003faa:	fc240513          	addi	a0,s0,-62
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	e3c080e7          	jalr	-452(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003fb6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fba:	4741                	li	a4,16
    80003fbc:	86a6                	mv	a3,s1
    80003fbe:	fc040613          	addi	a2,s0,-64
    80003fc2:	4581                	li	a1,0
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	c44080e7          	jalr	-956(ra) # 80003c0a <writei>
    80003fce:	872a                	mv	a4,a0
    80003fd0:	47c1                	li	a5,16
  return 0;
    80003fd2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fd4:	02f71863          	bne	a4,a5,80004004 <dirlink+0xb2>
}
    80003fd8:	70e2                	ld	ra,56(sp)
    80003fda:	7442                	ld	s0,48(sp)
    80003fdc:	74a2                	ld	s1,40(sp)
    80003fde:	7902                	ld	s2,32(sp)
    80003fe0:	69e2                	ld	s3,24(sp)
    80003fe2:	6a42                	ld	s4,16(sp)
    80003fe4:	6121                	addi	sp,sp,64
    80003fe6:	8082                	ret
    iput(ip);
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	a30080e7          	jalr	-1488(ra) # 80003a18 <iput>
    return -1;
    80003ff0:	557d                	li	a0,-1
    80003ff2:	b7dd                	j	80003fd8 <dirlink+0x86>
      panic("dirlink read");
    80003ff4:	00004517          	auipc	a0,0x4
    80003ff8:	5cc50513          	addi	a0,a0,1484 # 800085c0 <syscalls+0x1d8>
    80003ffc:	ffffc097          	auipc	ra,0xffffc
    80004000:	534080e7          	jalr	1332(ra) # 80000530 <panic>
    panic("dirlink");
    80004004:	00004517          	auipc	a0,0x4
    80004008:	6cc50513          	addi	a0,a0,1740 # 800086d0 <syscalls+0x2e8>
    8000400c:	ffffc097          	auipc	ra,0xffffc
    80004010:	524080e7          	jalr	1316(ra) # 80000530 <panic>

0000000080004014 <namei>:

struct inode*
namei(char *path)
{
    80004014:	1101                	addi	sp,sp,-32
    80004016:	ec06                	sd	ra,24(sp)
    80004018:	e822                	sd	s0,16(sp)
    8000401a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000401c:	fe040613          	addi	a2,s0,-32
    80004020:	4581                	li	a1,0
    80004022:	00000097          	auipc	ra,0x0
    80004026:	dd0080e7          	jalr	-560(ra) # 80003df2 <namex>
}
    8000402a:	60e2                	ld	ra,24(sp)
    8000402c:	6442                	ld	s0,16(sp)
    8000402e:	6105                	addi	sp,sp,32
    80004030:	8082                	ret

0000000080004032 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004032:	1141                	addi	sp,sp,-16
    80004034:	e406                	sd	ra,8(sp)
    80004036:	e022                	sd	s0,0(sp)
    80004038:	0800                	addi	s0,sp,16
    8000403a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000403c:	4585                	li	a1,1
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	db4080e7          	jalr	-588(ra) # 80003df2 <namex>
}
    80004046:	60a2                	ld	ra,8(sp)
    80004048:	6402                	ld	s0,0(sp)
    8000404a:	0141                	addi	sp,sp,16
    8000404c:	8082                	ret

000000008000404e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000404e:	1101                	addi	sp,sp,-32
    80004050:	ec06                	sd	ra,24(sp)
    80004052:	e822                	sd	s0,16(sp)
    80004054:	e426                	sd	s1,8(sp)
    80004056:	e04a                	sd	s2,0(sp)
    80004058:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000405a:	00029917          	auipc	s2,0x29
    8000405e:	1fe90913          	addi	s2,s2,510 # 8002d258 <log>
    80004062:	01892583          	lw	a1,24(s2)
    80004066:	02892503          	lw	a0,40(s2)
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	ff2080e7          	jalr	-14(ra) # 8000305c <bread>
    80004072:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004074:	02c92683          	lw	a3,44(s2)
    80004078:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000407a:	02d05763          	blez	a3,800040a8 <write_head+0x5a>
    8000407e:	00029797          	auipc	a5,0x29
    80004082:	20a78793          	addi	a5,a5,522 # 8002d288 <log+0x30>
    80004086:	05c50713          	addi	a4,a0,92
    8000408a:	36fd                	addiw	a3,a3,-1
    8000408c:	1682                	slli	a3,a3,0x20
    8000408e:	9281                	srli	a3,a3,0x20
    80004090:	068a                	slli	a3,a3,0x2
    80004092:	00029617          	auipc	a2,0x29
    80004096:	1fa60613          	addi	a2,a2,506 # 8002d28c <log+0x34>
    8000409a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000409c:	4390                	lw	a2,0(a5)
    8000409e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040a0:	0791                	addi	a5,a5,4
    800040a2:	0711                	addi	a4,a4,4
    800040a4:	fed79ce3          	bne	a5,a3,8000409c <write_head+0x4e>
  }
  bwrite(buf);
    800040a8:	8526                	mv	a0,s1
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	0a4080e7          	jalr	164(ra) # 8000314e <bwrite>
  brelse(buf);
    800040b2:	8526                	mv	a0,s1
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	0d8080e7          	jalr	216(ra) # 8000318c <brelse>
}
    800040bc:	60e2                	ld	ra,24(sp)
    800040be:	6442                	ld	s0,16(sp)
    800040c0:	64a2                	ld	s1,8(sp)
    800040c2:	6902                	ld	s2,0(sp)
    800040c4:	6105                	addi	sp,sp,32
    800040c6:	8082                	ret

00000000800040c8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040c8:	00029797          	auipc	a5,0x29
    800040cc:	1bc7a783          	lw	a5,444(a5) # 8002d284 <log+0x2c>
    800040d0:	0af05d63          	blez	a5,8000418a <install_trans+0xc2>
{
    800040d4:	7139                	addi	sp,sp,-64
    800040d6:	fc06                	sd	ra,56(sp)
    800040d8:	f822                	sd	s0,48(sp)
    800040da:	f426                	sd	s1,40(sp)
    800040dc:	f04a                	sd	s2,32(sp)
    800040de:	ec4e                	sd	s3,24(sp)
    800040e0:	e852                	sd	s4,16(sp)
    800040e2:	e456                	sd	s5,8(sp)
    800040e4:	e05a                	sd	s6,0(sp)
    800040e6:	0080                	addi	s0,sp,64
    800040e8:	8b2a                	mv	s6,a0
    800040ea:	00029a97          	auipc	s5,0x29
    800040ee:	19ea8a93          	addi	s5,s5,414 # 8002d288 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040f4:	00029997          	auipc	s3,0x29
    800040f8:	16498993          	addi	s3,s3,356 # 8002d258 <log>
    800040fc:	a035                	j	80004128 <install_trans+0x60>
      bunpin(dbuf);
    800040fe:	8526                	mv	a0,s1
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	166080e7          	jalr	358(ra) # 80003266 <bunpin>
    brelse(lbuf);
    80004108:	854a                	mv	a0,s2
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	082080e7          	jalr	130(ra) # 8000318c <brelse>
    brelse(dbuf);
    80004112:	8526                	mv	a0,s1
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	078080e7          	jalr	120(ra) # 8000318c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411c:	2a05                	addiw	s4,s4,1
    8000411e:	0a91                	addi	s5,s5,4
    80004120:	02c9a783          	lw	a5,44(s3)
    80004124:	04fa5963          	bge	s4,a5,80004176 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004128:	0189a583          	lw	a1,24(s3)
    8000412c:	014585bb          	addw	a1,a1,s4
    80004130:	2585                	addiw	a1,a1,1
    80004132:	0289a503          	lw	a0,40(s3)
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	f26080e7          	jalr	-218(ra) # 8000305c <bread>
    8000413e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004140:	000aa583          	lw	a1,0(s5)
    80004144:	0289a503          	lw	a0,40(s3)
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	f14080e7          	jalr	-236(ra) # 8000305c <bread>
    80004150:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004152:	40000613          	li	a2,1024
    80004156:	05890593          	addi	a1,s2,88
    8000415a:	05850513          	addi	a0,a0,88
    8000415e:	ffffd097          	auipc	ra,0xffffd
    80004162:	bd4080e7          	jalr	-1068(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004166:	8526                	mv	a0,s1
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	fe6080e7          	jalr	-26(ra) # 8000314e <bwrite>
    if(recovering == 0)
    80004170:	f80b1ce3          	bnez	s6,80004108 <install_trans+0x40>
    80004174:	b769                	j	800040fe <install_trans+0x36>
}
    80004176:	70e2                	ld	ra,56(sp)
    80004178:	7442                	ld	s0,48(sp)
    8000417a:	74a2                	ld	s1,40(sp)
    8000417c:	7902                	ld	s2,32(sp)
    8000417e:	69e2                	ld	s3,24(sp)
    80004180:	6a42                	ld	s4,16(sp)
    80004182:	6aa2                	ld	s5,8(sp)
    80004184:	6b02                	ld	s6,0(sp)
    80004186:	6121                	addi	sp,sp,64
    80004188:	8082                	ret
    8000418a:	8082                	ret

000000008000418c <initlog>:
{
    8000418c:	7179                	addi	sp,sp,-48
    8000418e:	f406                	sd	ra,40(sp)
    80004190:	f022                	sd	s0,32(sp)
    80004192:	ec26                	sd	s1,24(sp)
    80004194:	e84a                	sd	s2,16(sp)
    80004196:	e44e                	sd	s3,8(sp)
    80004198:	1800                	addi	s0,sp,48
    8000419a:	892a                	mv	s2,a0
    8000419c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000419e:	00029497          	auipc	s1,0x29
    800041a2:	0ba48493          	addi	s1,s1,186 # 8002d258 <log>
    800041a6:	00004597          	auipc	a1,0x4
    800041aa:	42a58593          	addi	a1,a1,1066 # 800085d0 <syscalls+0x1e8>
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	996080e7          	jalr	-1642(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800041b8:	0149a583          	lw	a1,20(s3)
    800041bc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041be:	0109a783          	lw	a5,16(s3)
    800041c2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041c4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041c8:	854a                	mv	a0,s2
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	e92080e7          	jalr	-366(ra) # 8000305c <bread>
  log.lh.n = lh->n;
    800041d2:	4d3c                	lw	a5,88(a0)
    800041d4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041d6:	02f05563          	blez	a5,80004200 <initlog+0x74>
    800041da:	05c50713          	addi	a4,a0,92
    800041de:	00029697          	auipc	a3,0x29
    800041e2:	0aa68693          	addi	a3,a3,170 # 8002d288 <log+0x30>
    800041e6:	37fd                	addiw	a5,a5,-1
    800041e8:	1782                	slli	a5,a5,0x20
    800041ea:	9381                	srli	a5,a5,0x20
    800041ec:	078a                	slli	a5,a5,0x2
    800041ee:	06050613          	addi	a2,a0,96
    800041f2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041f4:	4310                	lw	a2,0(a4)
    800041f6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041f8:	0711                	addi	a4,a4,4
    800041fa:	0691                	addi	a3,a3,4
    800041fc:	fef71ce3          	bne	a4,a5,800041f4 <initlog+0x68>
  brelse(buf);
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	f8c080e7          	jalr	-116(ra) # 8000318c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004208:	4505                	li	a0,1
    8000420a:	00000097          	auipc	ra,0x0
    8000420e:	ebe080e7          	jalr	-322(ra) # 800040c8 <install_trans>
  log.lh.n = 0;
    80004212:	00029797          	auipc	a5,0x29
    80004216:	0607a923          	sw	zero,114(a5) # 8002d284 <log+0x2c>
  write_head(); // clear the log
    8000421a:	00000097          	auipc	ra,0x0
    8000421e:	e34080e7          	jalr	-460(ra) # 8000404e <write_head>
}
    80004222:	70a2                	ld	ra,40(sp)
    80004224:	7402                	ld	s0,32(sp)
    80004226:	64e2                	ld	s1,24(sp)
    80004228:	6942                	ld	s2,16(sp)
    8000422a:	69a2                	ld	s3,8(sp)
    8000422c:	6145                	addi	sp,sp,48
    8000422e:	8082                	ret

0000000080004230 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004230:	1101                	addi	sp,sp,-32
    80004232:	ec06                	sd	ra,24(sp)
    80004234:	e822                	sd	s0,16(sp)
    80004236:	e426                	sd	s1,8(sp)
    80004238:	e04a                	sd	s2,0(sp)
    8000423a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000423c:	00029517          	auipc	a0,0x29
    80004240:	01c50513          	addi	a0,a0,28 # 8002d258 <log>
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	992080e7          	jalr	-1646(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000424c:	00029497          	auipc	s1,0x29
    80004250:	00c48493          	addi	s1,s1,12 # 8002d258 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004254:	4979                	li	s2,30
    80004256:	a039                	j	80004264 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004258:	85a6                	mv	a1,s1
    8000425a:	8526                	mv	a0,s1
    8000425c:	ffffe097          	auipc	ra,0xffffe
    80004260:	01a080e7          	jalr	26(ra) # 80002276 <sleep>
    if(log.committing){
    80004264:	50dc                	lw	a5,36(s1)
    80004266:	fbed                	bnez	a5,80004258 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004268:	509c                	lw	a5,32(s1)
    8000426a:	0017871b          	addiw	a4,a5,1
    8000426e:	0007069b          	sext.w	a3,a4
    80004272:	0027179b          	slliw	a5,a4,0x2
    80004276:	9fb9                	addw	a5,a5,a4
    80004278:	0017979b          	slliw	a5,a5,0x1
    8000427c:	54d8                	lw	a4,44(s1)
    8000427e:	9fb9                	addw	a5,a5,a4
    80004280:	00f95963          	bge	s2,a5,80004292 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004284:	85a6                	mv	a1,s1
    80004286:	8526                	mv	a0,s1
    80004288:	ffffe097          	auipc	ra,0xffffe
    8000428c:	fee080e7          	jalr	-18(ra) # 80002276 <sleep>
    80004290:	bfd1                	j	80004264 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004292:	00029517          	auipc	a0,0x29
    80004296:	fc650513          	addi	a0,a0,-58 # 8002d258 <log>
    8000429a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	9ee080e7          	jalr	-1554(ra) # 80000c8a <release>
      break;
    }
  }
}
    800042a4:	60e2                	ld	ra,24(sp)
    800042a6:	6442                	ld	s0,16(sp)
    800042a8:	64a2                	ld	s1,8(sp)
    800042aa:	6902                	ld	s2,0(sp)
    800042ac:	6105                	addi	sp,sp,32
    800042ae:	8082                	ret

00000000800042b0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042b0:	7139                	addi	sp,sp,-64
    800042b2:	fc06                	sd	ra,56(sp)
    800042b4:	f822                	sd	s0,48(sp)
    800042b6:	f426                	sd	s1,40(sp)
    800042b8:	f04a                	sd	s2,32(sp)
    800042ba:	ec4e                	sd	s3,24(sp)
    800042bc:	e852                	sd	s4,16(sp)
    800042be:	e456                	sd	s5,8(sp)
    800042c0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042c2:	00029497          	auipc	s1,0x29
    800042c6:	f9648493          	addi	s1,s1,-106 # 8002d258 <log>
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	90a080e7          	jalr	-1782(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800042d4:	509c                	lw	a5,32(s1)
    800042d6:	37fd                	addiw	a5,a5,-1
    800042d8:	0007891b          	sext.w	s2,a5
    800042dc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042de:	50dc                	lw	a5,36(s1)
    800042e0:	efb9                	bnez	a5,8000433e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042e2:	06091663          	bnez	s2,8000434e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042e6:	00029497          	auipc	s1,0x29
    800042ea:	f7248493          	addi	s1,s1,-142 # 8002d258 <log>
    800042ee:	4785                	li	a5,1
    800042f0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042f2:	8526                	mv	a0,s1
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042fc:	54dc                	lw	a5,44(s1)
    800042fe:	06f04763          	bgtz	a5,8000436c <end_op+0xbc>
    acquire(&log.lock);
    80004302:	00029497          	auipc	s1,0x29
    80004306:	f5648493          	addi	s1,s1,-170 # 8002d258 <log>
    8000430a:	8526                	mv	a0,s1
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	8ca080e7          	jalr	-1846(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004314:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004318:	8526                	mv	a0,s1
    8000431a:	ffffe097          	auipc	ra,0xffffe
    8000431e:	0e2080e7          	jalr	226(ra) # 800023fc <wakeup>
    release(&log.lock);
    80004322:	8526                	mv	a0,s1
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	966080e7          	jalr	-1690(ra) # 80000c8a <release>
}
    8000432c:	70e2                	ld	ra,56(sp)
    8000432e:	7442                	ld	s0,48(sp)
    80004330:	74a2                	ld	s1,40(sp)
    80004332:	7902                	ld	s2,32(sp)
    80004334:	69e2                	ld	s3,24(sp)
    80004336:	6a42                	ld	s4,16(sp)
    80004338:	6aa2                	ld	s5,8(sp)
    8000433a:	6121                	addi	sp,sp,64
    8000433c:	8082                	ret
    panic("log.committing");
    8000433e:	00004517          	auipc	a0,0x4
    80004342:	29a50513          	addi	a0,a0,666 # 800085d8 <syscalls+0x1f0>
    80004346:	ffffc097          	auipc	ra,0xffffc
    8000434a:	1ea080e7          	jalr	490(ra) # 80000530 <panic>
    wakeup(&log);
    8000434e:	00029497          	auipc	s1,0x29
    80004352:	f0a48493          	addi	s1,s1,-246 # 8002d258 <log>
    80004356:	8526                	mv	a0,s1
    80004358:	ffffe097          	auipc	ra,0xffffe
    8000435c:	0a4080e7          	jalr	164(ra) # 800023fc <wakeup>
  release(&log.lock);
    80004360:	8526                	mv	a0,s1
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
  if(do_commit){
    8000436a:	b7c9                	j	8000432c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000436c:	00029a97          	auipc	s5,0x29
    80004370:	f1ca8a93          	addi	s5,s5,-228 # 8002d288 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004374:	00029a17          	auipc	s4,0x29
    80004378:	ee4a0a13          	addi	s4,s4,-284 # 8002d258 <log>
    8000437c:	018a2583          	lw	a1,24(s4)
    80004380:	012585bb          	addw	a1,a1,s2
    80004384:	2585                	addiw	a1,a1,1
    80004386:	028a2503          	lw	a0,40(s4)
    8000438a:	fffff097          	auipc	ra,0xfffff
    8000438e:	cd2080e7          	jalr	-814(ra) # 8000305c <bread>
    80004392:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004394:	000aa583          	lw	a1,0(s5)
    80004398:	028a2503          	lw	a0,40(s4)
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	cc0080e7          	jalr	-832(ra) # 8000305c <bread>
    800043a4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043a6:	40000613          	li	a2,1024
    800043aa:	05850593          	addi	a1,a0,88
    800043ae:	05848513          	addi	a0,s1,88
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	980080e7          	jalr	-1664(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    800043ba:	8526                	mv	a0,s1
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	d92080e7          	jalr	-622(ra) # 8000314e <bwrite>
    brelse(from);
    800043c4:	854e                	mv	a0,s3
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	dc6080e7          	jalr	-570(ra) # 8000318c <brelse>
    brelse(to);
    800043ce:	8526                	mv	a0,s1
    800043d0:	fffff097          	auipc	ra,0xfffff
    800043d4:	dbc080e7          	jalr	-580(ra) # 8000318c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d8:	2905                	addiw	s2,s2,1
    800043da:	0a91                	addi	s5,s5,4
    800043dc:	02ca2783          	lw	a5,44(s4)
    800043e0:	f8f94ee3          	blt	s2,a5,8000437c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	c6a080e7          	jalr	-918(ra) # 8000404e <write_head>
    install_trans(0); // Now install writes to home locations
    800043ec:	4501                	li	a0,0
    800043ee:	00000097          	auipc	ra,0x0
    800043f2:	cda080e7          	jalr	-806(ra) # 800040c8 <install_trans>
    log.lh.n = 0;
    800043f6:	00029797          	auipc	a5,0x29
    800043fa:	e807a723          	sw	zero,-370(a5) # 8002d284 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	c50080e7          	jalr	-944(ra) # 8000404e <write_head>
    80004406:	bdf5                	j	80004302 <end_op+0x52>

0000000080004408 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004408:	1101                	addi	sp,sp,-32
    8000440a:	ec06                	sd	ra,24(sp)
    8000440c:	e822                	sd	s0,16(sp)
    8000440e:	e426                	sd	s1,8(sp)
    80004410:	e04a                	sd	s2,0(sp)
    80004412:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004414:	00029717          	auipc	a4,0x29
    80004418:	e7072703          	lw	a4,-400(a4) # 8002d284 <log+0x2c>
    8000441c:	47f5                	li	a5,29
    8000441e:	08e7c063          	blt	a5,a4,8000449e <log_write+0x96>
    80004422:	84aa                	mv	s1,a0
    80004424:	00029797          	auipc	a5,0x29
    80004428:	e507a783          	lw	a5,-432(a5) # 8002d274 <log+0x1c>
    8000442c:	37fd                	addiw	a5,a5,-1
    8000442e:	06f75863          	bge	a4,a5,8000449e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004432:	00029797          	auipc	a5,0x29
    80004436:	e467a783          	lw	a5,-442(a5) # 8002d278 <log+0x20>
    8000443a:	06f05a63          	blez	a5,800044ae <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000443e:	00029917          	auipc	s2,0x29
    80004442:	e1a90913          	addi	s2,s2,-486 # 8002d258 <log>
    80004446:	854a                	mv	a0,s2
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	78e080e7          	jalr	1934(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004450:	02c92603          	lw	a2,44(s2)
    80004454:	06c05563          	blez	a2,800044be <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004458:	44cc                	lw	a1,12(s1)
    8000445a:	00029717          	auipc	a4,0x29
    8000445e:	e2e70713          	addi	a4,a4,-466 # 8002d288 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004462:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004464:	4314                	lw	a3,0(a4)
    80004466:	04b68d63          	beq	a3,a1,800044c0 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000446a:	2785                	addiw	a5,a5,1
    8000446c:	0711                	addi	a4,a4,4
    8000446e:	fec79be3          	bne	a5,a2,80004464 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004472:	0621                	addi	a2,a2,8
    80004474:	060a                	slli	a2,a2,0x2
    80004476:	00029797          	auipc	a5,0x29
    8000447a:	de278793          	addi	a5,a5,-542 # 8002d258 <log>
    8000447e:	963e                	add	a2,a2,a5
    80004480:	44dc                	lw	a5,12(s1)
    80004482:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004484:	8526                	mv	a0,s1
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	da4080e7          	jalr	-604(ra) # 8000322a <bpin>
    log.lh.n++;
    8000448e:	00029717          	auipc	a4,0x29
    80004492:	dca70713          	addi	a4,a4,-566 # 8002d258 <log>
    80004496:	575c                	lw	a5,44(a4)
    80004498:	2785                	addiw	a5,a5,1
    8000449a:	d75c                	sw	a5,44(a4)
    8000449c:	a83d                	j	800044da <log_write+0xd2>
    panic("too big a transaction");
    8000449e:	00004517          	auipc	a0,0x4
    800044a2:	14a50513          	addi	a0,a0,330 # 800085e8 <syscalls+0x200>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	08a080e7          	jalr	138(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    800044ae:	00004517          	auipc	a0,0x4
    800044b2:	15250513          	addi	a0,a0,338 # 80008600 <syscalls+0x218>
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	07a080e7          	jalr	122(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800044be:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800044c0:	00878713          	addi	a4,a5,8
    800044c4:	00271693          	slli	a3,a4,0x2
    800044c8:	00029717          	auipc	a4,0x29
    800044cc:	d9070713          	addi	a4,a4,-624 # 8002d258 <log>
    800044d0:	9736                	add	a4,a4,a3
    800044d2:	44d4                	lw	a3,12(s1)
    800044d4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044d6:	faf607e3          	beq	a2,a5,80004484 <log_write+0x7c>
  }
  release(&log.lock);
    800044da:	00029517          	auipc	a0,0x29
    800044de:	d7e50513          	addi	a0,a0,-642 # 8002d258 <log>
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	7a8080e7          	jalr	1960(ra) # 80000c8a <release>
}
    800044ea:	60e2                	ld	ra,24(sp)
    800044ec:	6442                	ld	s0,16(sp)
    800044ee:	64a2                	ld	s1,8(sp)
    800044f0:	6902                	ld	s2,0(sp)
    800044f2:	6105                	addi	sp,sp,32
    800044f4:	8082                	ret

00000000800044f6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044f6:	1101                	addi	sp,sp,-32
    800044f8:	ec06                	sd	ra,24(sp)
    800044fa:	e822                	sd	s0,16(sp)
    800044fc:	e426                	sd	s1,8(sp)
    800044fe:	e04a                	sd	s2,0(sp)
    80004500:	1000                	addi	s0,sp,32
    80004502:	84aa                	mv	s1,a0
    80004504:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004506:	00004597          	auipc	a1,0x4
    8000450a:	11a58593          	addi	a1,a1,282 # 80008620 <syscalls+0x238>
    8000450e:	0521                	addi	a0,a0,8
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	636080e7          	jalr	1590(ra) # 80000b46 <initlock>
  lk->name = name;
    80004518:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000451c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004520:	0204a423          	sw	zero,40(s1)
}
    80004524:	60e2                	ld	ra,24(sp)
    80004526:	6442                	ld	s0,16(sp)
    80004528:	64a2                	ld	s1,8(sp)
    8000452a:	6902                	ld	s2,0(sp)
    8000452c:	6105                	addi	sp,sp,32
    8000452e:	8082                	ret

0000000080004530 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004530:	1101                	addi	sp,sp,-32
    80004532:	ec06                	sd	ra,24(sp)
    80004534:	e822                	sd	s0,16(sp)
    80004536:	e426                	sd	s1,8(sp)
    80004538:	e04a                	sd	s2,0(sp)
    8000453a:	1000                	addi	s0,sp,32
    8000453c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000453e:	00850913          	addi	s2,a0,8
    80004542:	854a                	mv	a0,s2
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	692080e7          	jalr	1682(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000454c:	409c                	lw	a5,0(s1)
    8000454e:	cb89                	beqz	a5,80004560 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004550:	85ca                	mv	a1,s2
    80004552:	8526                	mv	a0,s1
    80004554:	ffffe097          	auipc	ra,0xffffe
    80004558:	d22080e7          	jalr	-734(ra) # 80002276 <sleep>
  while (lk->locked) {
    8000455c:	409c                	lw	a5,0(s1)
    8000455e:	fbed                	bnez	a5,80004550 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004560:	4785                	li	a5,1
    80004562:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004564:	ffffd097          	auipc	ra,0xffffd
    80004568:	442080e7          	jalr	1090(ra) # 800019a6 <myproc>
    8000456c:	5d1c                	lw	a5,56(a0)
    8000456e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004570:	854a                	mv	a0,s2
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	718080e7          	jalr	1816(ra) # 80000c8a <release>
}
    8000457a:	60e2                	ld	ra,24(sp)
    8000457c:	6442                	ld	s0,16(sp)
    8000457e:	64a2                	ld	s1,8(sp)
    80004580:	6902                	ld	s2,0(sp)
    80004582:	6105                	addi	sp,sp,32
    80004584:	8082                	ret

0000000080004586 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004586:	1101                	addi	sp,sp,-32
    80004588:	ec06                	sd	ra,24(sp)
    8000458a:	e822                	sd	s0,16(sp)
    8000458c:	e426                	sd	s1,8(sp)
    8000458e:	e04a                	sd	s2,0(sp)
    80004590:	1000                	addi	s0,sp,32
    80004592:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004594:	00850913          	addi	s2,a0,8
    80004598:	854a                	mv	a0,s2
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	63c080e7          	jalr	1596(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800045a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045a6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffe097          	auipc	ra,0xffffe
    800045b0:	e50080e7          	jalr	-432(ra) # 800023fc <wakeup>
  release(&lk->lk);
    800045b4:	854a                	mv	a0,s2
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	6d4080e7          	jalr	1748(ra) # 80000c8a <release>
}
    800045be:	60e2                	ld	ra,24(sp)
    800045c0:	6442                	ld	s0,16(sp)
    800045c2:	64a2                	ld	s1,8(sp)
    800045c4:	6902                	ld	s2,0(sp)
    800045c6:	6105                	addi	sp,sp,32
    800045c8:	8082                	ret

00000000800045ca <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045ca:	7179                	addi	sp,sp,-48
    800045cc:	f406                	sd	ra,40(sp)
    800045ce:	f022                	sd	s0,32(sp)
    800045d0:	ec26                	sd	s1,24(sp)
    800045d2:	e84a                	sd	s2,16(sp)
    800045d4:	e44e                	sd	s3,8(sp)
    800045d6:	1800                	addi	s0,sp,48
    800045d8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045da:	00850913          	addi	s2,a0,8
    800045de:	854a                	mv	a0,s2
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	5f6080e7          	jalr	1526(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e8:	409c                	lw	a5,0(s1)
    800045ea:	ef99                	bnez	a5,80004608 <holdingsleep+0x3e>
    800045ec:	4481                	li	s1,0
  release(&lk->lk);
    800045ee:	854a                	mv	a0,s2
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	69a080e7          	jalr	1690(ra) # 80000c8a <release>
  return r;
}
    800045f8:	8526                	mv	a0,s1
    800045fa:	70a2                	ld	ra,40(sp)
    800045fc:	7402                	ld	s0,32(sp)
    800045fe:	64e2                	ld	s1,24(sp)
    80004600:	6942                	ld	s2,16(sp)
    80004602:	69a2                	ld	s3,8(sp)
    80004604:	6145                	addi	sp,sp,48
    80004606:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004608:	0284a983          	lw	s3,40(s1)
    8000460c:	ffffd097          	auipc	ra,0xffffd
    80004610:	39a080e7          	jalr	922(ra) # 800019a6 <myproc>
    80004614:	5d04                	lw	s1,56(a0)
    80004616:	413484b3          	sub	s1,s1,s3
    8000461a:	0014b493          	seqz	s1,s1
    8000461e:	bfc1                	j	800045ee <holdingsleep+0x24>

0000000080004620 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004620:	1141                	addi	sp,sp,-16
    80004622:	e406                	sd	ra,8(sp)
    80004624:	e022                	sd	s0,0(sp)
    80004626:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004628:	00004597          	auipc	a1,0x4
    8000462c:	00858593          	addi	a1,a1,8 # 80008630 <syscalls+0x248>
    80004630:	00029517          	auipc	a0,0x29
    80004634:	d7050513          	addi	a0,a0,-656 # 8002d3a0 <ftable>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	50e080e7          	jalr	1294(ra) # 80000b46 <initlock>
}
    80004640:	60a2                	ld	ra,8(sp)
    80004642:	6402                	ld	s0,0(sp)
    80004644:	0141                	addi	sp,sp,16
    80004646:	8082                	ret

0000000080004648 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004648:	1101                	addi	sp,sp,-32
    8000464a:	ec06                	sd	ra,24(sp)
    8000464c:	e822                	sd	s0,16(sp)
    8000464e:	e426                	sd	s1,8(sp)
    80004650:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004652:	00029517          	auipc	a0,0x29
    80004656:	d4e50513          	addi	a0,a0,-690 # 8002d3a0 <ftable>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	57c080e7          	jalr	1404(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004662:	00029497          	auipc	s1,0x29
    80004666:	d5648493          	addi	s1,s1,-682 # 8002d3b8 <ftable+0x18>
    8000466a:	0002a717          	auipc	a4,0x2a
    8000466e:	cee70713          	addi	a4,a4,-786 # 8002e358 <ftable+0xfb8>
    if(f->ref == 0){
    80004672:	40dc                	lw	a5,4(s1)
    80004674:	cf99                	beqz	a5,80004692 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004676:	02848493          	addi	s1,s1,40
    8000467a:	fee49ce3          	bne	s1,a4,80004672 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000467e:	00029517          	auipc	a0,0x29
    80004682:	d2250513          	addi	a0,a0,-734 # 8002d3a0 <ftable>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	604080e7          	jalr	1540(ra) # 80000c8a <release>
  return 0;
    8000468e:	4481                	li	s1,0
    80004690:	a819                	j	800046a6 <filealloc+0x5e>
      f->ref = 1;
    80004692:	4785                	li	a5,1
    80004694:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004696:	00029517          	auipc	a0,0x29
    8000469a:	d0a50513          	addi	a0,a0,-758 # 8002d3a0 <ftable>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	5ec080e7          	jalr	1516(ra) # 80000c8a <release>
}
    800046a6:	8526                	mv	a0,s1
    800046a8:	60e2                	ld	ra,24(sp)
    800046aa:	6442                	ld	s0,16(sp)
    800046ac:	64a2                	ld	s1,8(sp)
    800046ae:	6105                	addi	sp,sp,32
    800046b0:	8082                	ret

00000000800046b2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046b2:	1101                	addi	sp,sp,-32
    800046b4:	ec06                	sd	ra,24(sp)
    800046b6:	e822                	sd	s0,16(sp)
    800046b8:	e426                	sd	s1,8(sp)
    800046ba:	1000                	addi	s0,sp,32
    800046bc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046be:	00029517          	auipc	a0,0x29
    800046c2:	ce250513          	addi	a0,a0,-798 # 8002d3a0 <ftable>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	510080e7          	jalr	1296(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046ce:	40dc                	lw	a5,4(s1)
    800046d0:	02f05263          	blez	a5,800046f4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046d4:	2785                	addiw	a5,a5,1
    800046d6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046d8:	00029517          	auipc	a0,0x29
    800046dc:	cc850513          	addi	a0,a0,-824 # 8002d3a0 <ftable>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	5aa080e7          	jalr	1450(ra) # 80000c8a <release>
  return f;
}
    800046e8:	8526                	mv	a0,s1
    800046ea:	60e2                	ld	ra,24(sp)
    800046ec:	6442                	ld	s0,16(sp)
    800046ee:	64a2                	ld	s1,8(sp)
    800046f0:	6105                	addi	sp,sp,32
    800046f2:	8082                	ret
    panic("filedup");
    800046f4:	00004517          	auipc	a0,0x4
    800046f8:	f4450513          	addi	a0,a0,-188 # 80008638 <syscalls+0x250>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	e34080e7          	jalr	-460(ra) # 80000530 <panic>

0000000080004704 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004704:	7139                	addi	sp,sp,-64
    80004706:	fc06                	sd	ra,56(sp)
    80004708:	f822                	sd	s0,48(sp)
    8000470a:	f426                	sd	s1,40(sp)
    8000470c:	f04a                	sd	s2,32(sp)
    8000470e:	ec4e                	sd	s3,24(sp)
    80004710:	e852                	sd	s4,16(sp)
    80004712:	e456                	sd	s5,8(sp)
    80004714:	0080                	addi	s0,sp,64
    80004716:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004718:	00029517          	auipc	a0,0x29
    8000471c:	c8850513          	addi	a0,a0,-888 # 8002d3a0 <ftable>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	4b6080e7          	jalr	1206(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004728:	40dc                	lw	a5,4(s1)
    8000472a:	06f05163          	blez	a5,8000478c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000472e:	37fd                	addiw	a5,a5,-1
    80004730:	0007871b          	sext.w	a4,a5
    80004734:	c0dc                	sw	a5,4(s1)
    80004736:	06e04363          	bgtz	a4,8000479c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000473a:	0004a903          	lw	s2,0(s1)
    8000473e:	0094ca83          	lbu	s5,9(s1)
    80004742:	0104ba03          	ld	s4,16(s1)
    80004746:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000474a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000474e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004752:	00029517          	auipc	a0,0x29
    80004756:	c4e50513          	addi	a0,a0,-946 # 8002d3a0 <ftable>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	530080e7          	jalr	1328(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004762:	4785                	li	a5,1
    80004764:	04f90d63          	beq	s2,a5,800047be <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004768:	3979                	addiw	s2,s2,-2
    8000476a:	4785                	li	a5,1
    8000476c:	0527e063          	bltu	a5,s2,800047ac <fileclose+0xa8>
    begin_op();
    80004770:	00000097          	auipc	ra,0x0
    80004774:	ac0080e7          	jalr	-1344(ra) # 80004230 <begin_op>
    iput(ff.ip);
    80004778:	854e                	mv	a0,s3
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	29e080e7          	jalr	670(ra) # 80003a18 <iput>
    end_op();
    80004782:	00000097          	auipc	ra,0x0
    80004786:	b2e080e7          	jalr	-1234(ra) # 800042b0 <end_op>
    8000478a:	a00d                	j	800047ac <fileclose+0xa8>
    panic("fileclose");
    8000478c:	00004517          	auipc	a0,0x4
    80004790:	eb450513          	addi	a0,a0,-332 # 80008640 <syscalls+0x258>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	d9c080e7          	jalr	-612(ra) # 80000530 <panic>
    release(&ftable.lock);
    8000479c:	00029517          	auipc	a0,0x29
    800047a0:	c0450513          	addi	a0,a0,-1020 # 8002d3a0 <ftable>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	4e6080e7          	jalr	1254(ra) # 80000c8a <release>
  }
}
    800047ac:	70e2                	ld	ra,56(sp)
    800047ae:	7442                	ld	s0,48(sp)
    800047b0:	74a2                	ld	s1,40(sp)
    800047b2:	7902                	ld	s2,32(sp)
    800047b4:	69e2                	ld	s3,24(sp)
    800047b6:	6a42                	ld	s4,16(sp)
    800047b8:	6aa2                	ld	s5,8(sp)
    800047ba:	6121                	addi	sp,sp,64
    800047bc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047be:	85d6                	mv	a1,s5
    800047c0:	8552                	mv	a0,s4
    800047c2:	00000097          	auipc	ra,0x0
    800047c6:	34c080e7          	jalr	844(ra) # 80004b0e <pipeclose>
    800047ca:	b7cd                	j	800047ac <fileclose+0xa8>

00000000800047cc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047cc:	715d                	addi	sp,sp,-80
    800047ce:	e486                	sd	ra,72(sp)
    800047d0:	e0a2                	sd	s0,64(sp)
    800047d2:	fc26                	sd	s1,56(sp)
    800047d4:	f84a                	sd	s2,48(sp)
    800047d6:	f44e                	sd	s3,40(sp)
    800047d8:	0880                	addi	s0,sp,80
    800047da:	84aa                	mv	s1,a0
    800047dc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047de:	ffffd097          	auipc	ra,0xffffd
    800047e2:	1c8080e7          	jalr	456(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047e6:	409c                	lw	a5,0(s1)
    800047e8:	37f9                	addiw	a5,a5,-2
    800047ea:	4705                	li	a4,1
    800047ec:	04f76763          	bltu	a4,a5,8000483a <filestat+0x6e>
    800047f0:	892a                	mv	s2,a0
    ilock(f->ip);
    800047f2:	6c88                	ld	a0,24(s1)
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	06a080e7          	jalr	106(ra) # 8000385e <ilock>
    stati(f->ip, &st);
    800047fc:	fb840593          	addi	a1,s0,-72
    80004800:	6c88                	ld	a0,24(s1)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	2e6080e7          	jalr	742(ra) # 80003ae8 <stati>
    iunlock(f->ip);
    8000480a:	6c88                	ld	a0,24(s1)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	114080e7          	jalr	276(ra) # 80003920 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004814:	46e1                	li	a3,24
    80004816:	fb840613          	addi	a2,s0,-72
    8000481a:	85ce                	mv	a1,s3
    8000481c:	05093503          	ld	a0,80(s2)
    80004820:	ffffd097          	auipc	ra,0xffffd
    80004824:	e1c080e7          	jalr	-484(ra) # 8000163c <copyout>
    80004828:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000482c:	60a6                	ld	ra,72(sp)
    8000482e:	6406                	ld	s0,64(sp)
    80004830:	74e2                	ld	s1,56(sp)
    80004832:	7942                	ld	s2,48(sp)
    80004834:	79a2                	ld	s3,40(sp)
    80004836:	6161                	addi	sp,sp,80
    80004838:	8082                	ret
  return -1;
    8000483a:	557d                	li	a0,-1
    8000483c:	bfc5                	j	8000482c <filestat+0x60>

000000008000483e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000483e:	7179                	addi	sp,sp,-48
    80004840:	f406                	sd	ra,40(sp)
    80004842:	f022                	sd	s0,32(sp)
    80004844:	ec26                	sd	s1,24(sp)
    80004846:	e84a                	sd	s2,16(sp)
    80004848:	e44e                	sd	s3,8(sp)
    8000484a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000484c:	00854783          	lbu	a5,8(a0)
    80004850:	c3d5                	beqz	a5,800048f4 <fileread+0xb6>
    80004852:	84aa                	mv	s1,a0
    80004854:	89ae                	mv	s3,a1
    80004856:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004858:	411c                	lw	a5,0(a0)
    8000485a:	4705                	li	a4,1
    8000485c:	04e78963          	beq	a5,a4,800048ae <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004860:	470d                	li	a4,3
    80004862:	04e78d63          	beq	a5,a4,800048bc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004866:	4709                	li	a4,2
    80004868:	06e79e63          	bne	a5,a4,800048e4 <fileread+0xa6>
    ilock(f->ip);
    8000486c:	6d08                	ld	a0,24(a0)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	ff0080e7          	jalr	-16(ra) # 8000385e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004876:	874a                	mv	a4,s2
    80004878:	5094                	lw	a3,32(s1)
    8000487a:	864e                	mv	a2,s3
    8000487c:	4585                	li	a1,1
    8000487e:	6c88                	ld	a0,24(s1)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	292080e7          	jalr	658(ra) # 80003b12 <readi>
    80004888:	892a                	mv	s2,a0
    8000488a:	00a05563          	blez	a0,80004894 <fileread+0x56>
      f->off += r;
    8000488e:	509c                	lw	a5,32(s1)
    80004890:	9fa9                	addw	a5,a5,a0
    80004892:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004894:	6c88                	ld	a0,24(s1)
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	08a080e7          	jalr	138(ra) # 80003920 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000489e:	854a                	mv	a0,s2
    800048a0:	70a2                	ld	ra,40(sp)
    800048a2:	7402                	ld	s0,32(sp)
    800048a4:	64e2                	ld	s1,24(sp)
    800048a6:	6942                	ld	s2,16(sp)
    800048a8:	69a2                	ld	s3,8(sp)
    800048aa:	6145                	addi	sp,sp,48
    800048ac:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048ae:	6908                	ld	a0,16(a0)
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	3c8080e7          	jalr	968(ra) # 80004c78 <piperead>
    800048b8:	892a                	mv	s2,a0
    800048ba:	b7d5                	j	8000489e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048bc:	02451783          	lh	a5,36(a0)
    800048c0:	03079693          	slli	a3,a5,0x30
    800048c4:	92c1                	srli	a3,a3,0x30
    800048c6:	4725                	li	a4,9
    800048c8:	02d76863          	bltu	a4,a3,800048f8 <fileread+0xba>
    800048cc:	0792                	slli	a5,a5,0x4
    800048ce:	00029717          	auipc	a4,0x29
    800048d2:	a3270713          	addi	a4,a4,-1486 # 8002d300 <devsw>
    800048d6:	97ba                	add	a5,a5,a4
    800048d8:	639c                	ld	a5,0(a5)
    800048da:	c38d                	beqz	a5,800048fc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048dc:	4505                	li	a0,1
    800048de:	9782                	jalr	a5
    800048e0:	892a                	mv	s2,a0
    800048e2:	bf75                	j	8000489e <fileread+0x60>
    panic("fileread");
    800048e4:	00004517          	auipc	a0,0x4
    800048e8:	d6c50513          	addi	a0,a0,-660 # 80008650 <syscalls+0x268>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	c44080e7          	jalr	-956(ra) # 80000530 <panic>
    return -1;
    800048f4:	597d                	li	s2,-1
    800048f6:	b765                	j	8000489e <fileread+0x60>
      return -1;
    800048f8:	597d                	li	s2,-1
    800048fa:	b755                	j	8000489e <fileread+0x60>
    800048fc:	597d                	li	s2,-1
    800048fe:	b745                	j	8000489e <fileread+0x60>

0000000080004900 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004900:	715d                	addi	sp,sp,-80
    80004902:	e486                	sd	ra,72(sp)
    80004904:	e0a2                	sd	s0,64(sp)
    80004906:	fc26                	sd	s1,56(sp)
    80004908:	f84a                	sd	s2,48(sp)
    8000490a:	f44e                	sd	s3,40(sp)
    8000490c:	f052                	sd	s4,32(sp)
    8000490e:	ec56                	sd	s5,24(sp)
    80004910:	e85a                	sd	s6,16(sp)
    80004912:	e45e                	sd	s7,8(sp)
    80004914:	e062                	sd	s8,0(sp)
    80004916:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004918:	00954783          	lbu	a5,9(a0)
    8000491c:	10078663          	beqz	a5,80004a28 <filewrite+0x128>
    80004920:	892a                	mv	s2,a0
    80004922:	8aae                	mv	s5,a1
    80004924:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004926:	411c                	lw	a5,0(a0)
    80004928:	4705                	li	a4,1
    8000492a:	02e78263          	beq	a5,a4,8000494e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000492e:	470d                	li	a4,3
    80004930:	02e78663          	beq	a5,a4,8000495c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004934:	4709                	li	a4,2
    80004936:	0ee79163          	bne	a5,a4,80004a18 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000493a:	0ac05d63          	blez	a2,800049f4 <filewrite+0xf4>
    int i = 0;
    8000493e:	4981                	li	s3,0
    80004940:	6b05                	lui	s6,0x1
    80004942:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004946:	6b85                	lui	s7,0x1
    80004948:	c00b8b9b          	addiw	s7,s7,-1024
    8000494c:	a861                	j	800049e4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000494e:	6908                	ld	a0,16(a0)
    80004950:	00000097          	auipc	ra,0x0
    80004954:	22e080e7          	jalr	558(ra) # 80004b7e <pipewrite>
    80004958:	8a2a                	mv	s4,a0
    8000495a:	a045                	j	800049fa <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000495c:	02451783          	lh	a5,36(a0)
    80004960:	03079693          	slli	a3,a5,0x30
    80004964:	92c1                	srli	a3,a3,0x30
    80004966:	4725                	li	a4,9
    80004968:	0cd76263          	bltu	a4,a3,80004a2c <filewrite+0x12c>
    8000496c:	0792                	slli	a5,a5,0x4
    8000496e:	00029717          	auipc	a4,0x29
    80004972:	99270713          	addi	a4,a4,-1646 # 8002d300 <devsw>
    80004976:	97ba                	add	a5,a5,a4
    80004978:	679c                	ld	a5,8(a5)
    8000497a:	cbdd                	beqz	a5,80004a30 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000497c:	4505                	li	a0,1
    8000497e:	9782                	jalr	a5
    80004980:	8a2a                	mv	s4,a0
    80004982:	a8a5                	j	800049fa <filewrite+0xfa>
    80004984:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	8a8080e7          	jalr	-1880(ra) # 80004230 <begin_op>
      ilock(f->ip);
    80004990:	01893503          	ld	a0,24(s2)
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	eca080e7          	jalr	-310(ra) # 8000385e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000499c:	8762                	mv	a4,s8
    8000499e:	02092683          	lw	a3,32(s2)
    800049a2:	01598633          	add	a2,s3,s5
    800049a6:	4585                	li	a1,1
    800049a8:	01893503          	ld	a0,24(s2)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	25e080e7          	jalr	606(ra) # 80003c0a <writei>
    800049b4:	84aa                	mv	s1,a0
    800049b6:	00a05763          	blez	a0,800049c4 <filewrite+0xc4>
        f->off += r;
    800049ba:	02092783          	lw	a5,32(s2)
    800049be:	9fa9                	addw	a5,a5,a0
    800049c0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049c4:	01893503          	ld	a0,24(s2)
    800049c8:	fffff097          	auipc	ra,0xfffff
    800049cc:	f58080e7          	jalr	-168(ra) # 80003920 <iunlock>
      end_op();
    800049d0:	00000097          	auipc	ra,0x0
    800049d4:	8e0080e7          	jalr	-1824(ra) # 800042b0 <end_op>

      if(r != n1){
    800049d8:	009c1f63          	bne	s8,s1,800049f6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049dc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049e0:	0149db63          	bge	s3,s4,800049f6 <filewrite+0xf6>
      int n1 = n - i;
    800049e4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049e8:	84be                	mv	s1,a5
    800049ea:	2781                	sext.w	a5,a5
    800049ec:	f8fb5ce3          	bge	s6,a5,80004984 <filewrite+0x84>
    800049f0:	84de                	mv	s1,s7
    800049f2:	bf49                	j	80004984 <filewrite+0x84>
    int i = 0;
    800049f4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049f6:	013a1f63          	bne	s4,s3,80004a14 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049fa:	8552                	mv	a0,s4
    800049fc:	60a6                	ld	ra,72(sp)
    800049fe:	6406                	ld	s0,64(sp)
    80004a00:	74e2                	ld	s1,56(sp)
    80004a02:	7942                	ld	s2,48(sp)
    80004a04:	79a2                	ld	s3,40(sp)
    80004a06:	7a02                	ld	s4,32(sp)
    80004a08:	6ae2                	ld	s5,24(sp)
    80004a0a:	6b42                	ld	s6,16(sp)
    80004a0c:	6ba2                	ld	s7,8(sp)
    80004a0e:	6c02                	ld	s8,0(sp)
    80004a10:	6161                	addi	sp,sp,80
    80004a12:	8082                	ret
    ret = (i == n ? n : -1);
    80004a14:	5a7d                	li	s4,-1
    80004a16:	b7d5                	j	800049fa <filewrite+0xfa>
    panic("filewrite");
    80004a18:	00004517          	auipc	a0,0x4
    80004a1c:	c4850513          	addi	a0,a0,-952 # 80008660 <syscalls+0x278>
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	b10080e7          	jalr	-1264(ra) # 80000530 <panic>
    return -1;
    80004a28:	5a7d                	li	s4,-1
    80004a2a:	bfc1                	j	800049fa <filewrite+0xfa>
      return -1;
    80004a2c:	5a7d                	li	s4,-1
    80004a2e:	b7f1                	j	800049fa <filewrite+0xfa>
    80004a30:	5a7d                	li	s4,-1
    80004a32:	b7e1                	j	800049fa <filewrite+0xfa>

0000000080004a34 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a34:	7179                	addi	sp,sp,-48
    80004a36:	f406                	sd	ra,40(sp)
    80004a38:	f022                	sd	s0,32(sp)
    80004a3a:	ec26                	sd	s1,24(sp)
    80004a3c:	e84a                	sd	s2,16(sp)
    80004a3e:	e44e                	sd	s3,8(sp)
    80004a40:	e052                	sd	s4,0(sp)
    80004a42:	1800                	addi	s0,sp,48
    80004a44:	84aa                	mv	s1,a0
    80004a46:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a48:	0005b023          	sd	zero,0(a1)
    80004a4c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	bf8080e7          	jalr	-1032(ra) # 80004648 <filealloc>
    80004a58:	e088                	sd	a0,0(s1)
    80004a5a:	c551                	beqz	a0,80004ae6 <pipealloc+0xb2>
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	bec080e7          	jalr	-1044(ra) # 80004648 <filealloc>
    80004a64:	00aa3023          	sd	a0,0(s4)
    80004a68:	c92d                	beqz	a0,80004ada <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	07c080e7          	jalr	124(ra) # 80000ae6 <kalloc>
    80004a72:	892a                	mv	s2,a0
    80004a74:	c125                	beqz	a0,80004ad4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a76:	4985                	li	s3,1
    80004a78:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a7c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a80:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a84:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a88:	00004597          	auipc	a1,0x4
    80004a8c:	be858593          	addi	a1,a1,-1048 # 80008670 <syscalls+0x288>
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	0b6080e7          	jalr	182(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004a98:	609c                	ld	a5,0(s1)
    80004a9a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a9e:	609c                	ld	a5,0(s1)
    80004aa0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004aa4:	609c                	ld	a5,0(s1)
    80004aa6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aaa:	609c                	ld	a5,0(s1)
    80004aac:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ab0:	000a3783          	ld	a5,0(s4)
    80004ab4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ab8:	000a3783          	ld	a5,0(s4)
    80004abc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ac0:	000a3783          	ld	a5,0(s4)
    80004ac4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ac8:	000a3783          	ld	a5,0(s4)
    80004acc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ad0:	4501                	li	a0,0
    80004ad2:	a025                	j	80004afa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ad4:	6088                	ld	a0,0(s1)
    80004ad6:	e501                	bnez	a0,80004ade <pipealloc+0xaa>
    80004ad8:	a039                	j	80004ae6 <pipealloc+0xb2>
    80004ada:	6088                	ld	a0,0(s1)
    80004adc:	c51d                	beqz	a0,80004b0a <pipealloc+0xd6>
    fileclose(*f0);
    80004ade:	00000097          	auipc	ra,0x0
    80004ae2:	c26080e7          	jalr	-986(ra) # 80004704 <fileclose>
  if(*f1)
    80004ae6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aea:	557d                	li	a0,-1
  if(*f1)
    80004aec:	c799                	beqz	a5,80004afa <pipealloc+0xc6>
    fileclose(*f1);
    80004aee:	853e                	mv	a0,a5
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	c14080e7          	jalr	-1004(ra) # 80004704 <fileclose>
  return -1;
    80004af8:	557d                	li	a0,-1
}
    80004afa:	70a2                	ld	ra,40(sp)
    80004afc:	7402                	ld	s0,32(sp)
    80004afe:	64e2                	ld	s1,24(sp)
    80004b00:	6942                	ld	s2,16(sp)
    80004b02:	69a2                	ld	s3,8(sp)
    80004b04:	6a02                	ld	s4,0(sp)
    80004b06:	6145                	addi	sp,sp,48
    80004b08:	8082                	ret
  return -1;
    80004b0a:	557d                	li	a0,-1
    80004b0c:	b7fd                	j	80004afa <pipealloc+0xc6>

0000000080004b0e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b0e:	1101                	addi	sp,sp,-32
    80004b10:	ec06                	sd	ra,24(sp)
    80004b12:	e822                	sd	s0,16(sp)
    80004b14:	e426                	sd	s1,8(sp)
    80004b16:	e04a                	sd	s2,0(sp)
    80004b18:	1000                	addi	s0,sp,32
    80004b1a:	84aa                	mv	s1,a0
    80004b1c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	0b8080e7          	jalr	184(ra) # 80000bd6 <acquire>
  if(writable){
    80004b26:	02090d63          	beqz	s2,80004b60 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b2a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b2e:	21848513          	addi	a0,s1,536
    80004b32:	ffffe097          	auipc	ra,0xffffe
    80004b36:	8ca080e7          	jalr	-1846(ra) # 800023fc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b3a:	2204b783          	ld	a5,544(s1)
    80004b3e:	eb95                	bnez	a5,80004b72 <pipeclose+0x64>
    release(&pi->lock);
    80004b40:	8526                	mv	a0,s1
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	148080e7          	jalr	328(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	e9e080e7          	jalr	-354(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004b54:	60e2                	ld	ra,24(sp)
    80004b56:	6442                	ld	s0,16(sp)
    80004b58:	64a2                	ld	s1,8(sp)
    80004b5a:	6902                	ld	s2,0(sp)
    80004b5c:	6105                	addi	sp,sp,32
    80004b5e:	8082                	ret
    pi->readopen = 0;
    80004b60:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b64:	21c48513          	addi	a0,s1,540
    80004b68:	ffffe097          	auipc	ra,0xffffe
    80004b6c:	894080e7          	jalr	-1900(ra) # 800023fc <wakeup>
    80004b70:	b7e9                	j	80004b3a <pipeclose+0x2c>
    release(&pi->lock);
    80004b72:	8526                	mv	a0,s1
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	116080e7          	jalr	278(ra) # 80000c8a <release>
}
    80004b7c:	bfe1                	j	80004b54 <pipeclose+0x46>

0000000080004b7e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b7e:	7159                	addi	sp,sp,-112
    80004b80:	f486                	sd	ra,104(sp)
    80004b82:	f0a2                	sd	s0,96(sp)
    80004b84:	eca6                	sd	s1,88(sp)
    80004b86:	e8ca                	sd	s2,80(sp)
    80004b88:	e4ce                	sd	s3,72(sp)
    80004b8a:	e0d2                	sd	s4,64(sp)
    80004b8c:	fc56                	sd	s5,56(sp)
    80004b8e:	f85a                	sd	s6,48(sp)
    80004b90:	f45e                	sd	s7,40(sp)
    80004b92:	f062                	sd	s8,32(sp)
    80004b94:	ec66                	sd	s9,24(sp)
    80004b96:	1880                	addi	s0,sp,112
    80004b98:	84aa                	mv	s1,a0
    80004b9a:	8aae                	mv	s5,a1
    80004b9c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b9e:	ffffd097          	auipc	ra,0xffffd
    80004ba2:	e08080e7          	jalr	-504(ra) # 800019a6 <myproc>
    80004ba6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	02c080e7          	jalr	44(ra) # 80000bd6 <acquire>
  while(i < n){
    80004bb2:	0d405163          	blez	s4,80004c74 <pipewrite+0xf6>
    80004bb6:	8ba6                	mv	s7,s1
  int i = 0;
    80004bb8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bba:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bbc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bc0:	21c48c13          	addi	s8,s1,540
    80004bc4:	a08d                	j	80004c26 <pipewrite+0xa8>
      release(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	0c2080e7          	jalr	194(ra) # 80000c8a <release>
      return -1;
    80004bd0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bd2:	854a                	mv	a0,s2
    80004bd4:	70a6                	ld	ra,104(sp)
    80004bd6:	7406                	ld	s0,96(sp)
    80004bd8:	64e6                	ld	s1,88(sp)
    80004bda:	6946                	ld	s2,80(sp)
    80004bdc:	69a6                	ld	s3,72(sp)
    80004bde:	6a06                	ld	s4,64(sp)
    80004be0:	7ae2                	ld	s5,56(sp)
    80004be2:	7b42                	ld	s6,48(sp)
    80004be4:	7ba2                	ld	s7,40(sp)
    80004be6:	7c02                	ld	s8,32(sp)
    80004be8:	6ce2                	ld	s9,24(sp)
    80004bea:	6165                	addi	sp,sp,112
    80004bec:	8082                	ret
      wakeup(&pi->nread);
    80004bee:	8566                	mv	a0,s9
    80004bf0:	ffffe097          	auipc	ra,0xffffe
    80004bf4:	80c080e7          	jalr	-2036(ra) # 800023fc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bf8:	85de                	mv	a1,s7
    80004bfa:	8562                	mv	a0,s8
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	67a080e7          	jalr	1658(ra) # 80002276 <sleep>
    80004c04:	a839                	j	80004c22 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c06:	21c4a783          	lw	a5,540(s1)
    80004c0a:	0017871b          	addiw	a4,a5,1
    80004c0e:	20e4ae23          	sw	a4,540(s1)
    80004c12:	1ff7f793          	andi	a5,a5,511
    80004c16:	97a6                	add	a5,a5,s1
    80004c18:	f9f44703          	lbu	a4,-97(s0)
    80004c1c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c20:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c22:	03495d63          	bge	s2,s4,80004c5c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c26:	2204a783          	lw	a5,544(s1)
    80004c2a:	dfd1                	beqz	a5,80004bc6 <pipewrite+0x48>
    80004c2c:	0309a783          	lw	a5,48(s3)
    80004c30:	fbd9                	bnez	a5,80004bc6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c32:	2184a783          	lw	a5,536(s1)
    80004c36:	21c4a703          	lw	a4,540(s1)
    80004c3a:	2007879b          	addiw	a5,a5,512
    80004c3e:	faf708e3          	beq	a4,a5,80004bee <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c42:	4685                	li	a3,1
    80004c44:	01590633          	add	a2,s2,s5
    80004c48:	f9f40593          	addi	a1,s0,-97
    80004c4c:	0509b503          	ld	a0,80(s3)
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	a78080e7          	jalr	-1416(ra) # 800016c8 <copyin>
    80004c58:	fb6517e3          	bne	a0,s6,80004c06 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c5c:	21848513          	addi	a0,s1,536
    80004c60:	ffffd097          	auipc	ra,0xffffd
    80004c64:	79c080e7          	jalr	1948(ra) # 800023fc <wakeup>
  release(&pi->lock);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	020080e7          	jalr	32(ra) # 80000c8a <release>
  return i;
    80004c72:	b785                	j	80004bd2 <pipewrite+0x54>
  int i = 0;
    80004c74:	4901                	li	s2,0
    80004c76:	b7dd                	j	80004c5c <pipewrite+0xde>

0000000080004c78 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c78:	715d                	addi	sp,sp,-80
    80004c7a:	e486                	sd	ra,72(sp)
    80004c7c:	e0a2                	sd	s0,64(sp)
    80004c7e:	fc26                	sd	s1,56(sp)
    80004c80:	f84a                	sd	s2,48(sp)
    80004c82:	f44e                	sd	s3,40(sp)
    80004c84:	f052                	sd	s4,32(sp)
    80004c86:	ec56                	sd	s5,24(sp)
    80004c88:	e85a                	sd	s6,16(sp)
    80004c8a:	0880                	addi	s0,sp,80
    80004c8c:	84aa                	mv	s1,a0
    80004c8e:	892e                	mv	s2,a1
    80004c90:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	d14080e7          	jalr	-748(ra) # 800019a6 <myproc>
    80004c9a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c9c:	8b26                	mv	s6,s1
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	f36080e7          	jalr	-202(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca8:	2184a703          	lw	a4,536(s1)
    80004cac:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cb0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb4:	02f71463          	bne	a4,a5,80004cdc <piperead+0x64>
    80004cb8:	2244a783          	lw	a5,548(s1)
    80004cbc:	c385                	beqz	a5,80004cdc <piperead+0x64>
    if(pr->killed){
    80004cbe:	030a2783          	lw	a5,48(s4)
    80004cc2:	ebc1                	bnez	a5,80004d52 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cc4:	85da                	mv	a1,s6
    80004cc6:	854e                	mv	a0,s3
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	5ae080e7          	jalr	1454(ra) # 80002276 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd0:	2184a703          	lw	a4,536(s1)
    80004cd4:	21c4a783          	lw	a5,540(s1)
    80004cd8:	fef700e3          	beq	a4,a5,80004cb8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cdc:	09505263          	blez	s5,80004d60 <piperead+0xe8>
    80004ce0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ce4:	2184a783          	lw	a5,536(s1)
    80004ce8:	21c4a703          	lw	a4,540(s1)
    80004cec:	02f70d63          	beq	a4,a5,80004d26 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cf0:	0017871b          	addiw	a4,a5,1
    80004cf4:	20e4ac23          	sw	a4,536(s1)
    80004cf8:	1ff7f793          	andi	a5,a5,511
    80004cfc:	97a6                	add	a5,a5,s1
    80004cfe:	0187c783          	lbu	a5,24(a5)
    80004d02:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d06:	4685                	li	a3,1
    80004d08:	fbf40613          	addi	a2,s0,-65
    80004d0c:	85ca                	mv	a1,s2
    80004d0e:	050a3503          	ld	a0,80(s4)
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	92a080e7          	jalr	-1750(ra) # 8000163c <copyout>
    80004d1a:	01650663          	beq	a0,s6,80004d26 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d1e:	2985                	addiw	s3,s3,1
    80004d20:	0905                	addi	s2,s2,1
    80004d22:	fd3a91e3          	bne	s5,s3,80004ce4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d26:	21c48513          	addi	a0,s1,540
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	6d2080e7          	jalr	1746(ra) # 800023fc <wakeup>
  release(&pi->lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	f56080e7          	jalr	-170(ra) # 80000c8a <release>
  return i;
}
    80004d3c:	854e                	mv	a0,s3
    80004d3e:	60a6                	ld	ra,72(sp)
    80004d40:	6406                	ld	s0,64(sp)
    80004d42:	74e2                	ld	s1,56(sp)
    80004d44:	7942                	ld	s2,48(sp)
    80004d46:	79a2                	ld	s3,40(sp)
    80004d48:	7a02                	ld	s4,32(sp)
    80004d4a:	6ae2                	ld	s5,24(sp)
    80004d4c:	6b42                	ld	s6,16(sp)
    80004d4e:	6161                	addi	sp,sp,80
    80004d50:	8082                	ret
      release(&pi->lock);
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	f36080e7          	jalr	-202(ra) # 80000c8a <release>
      return -1;
    80004d5c:	59fd                	li	s3,-1
    80004d5e:	bff9                	j	80004d3c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d60:	4981                	li	s3,0
    80004d62:	b7d1                	j	80004d26 <piperead+0xae>

0000000080004d64 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d64:	df010113          	addi	sp,sp,-528
    80004d68:	20113423          	sd	ra,520(sp)
    80004d6c:	20813023          	sd	s0,512(sp)
    80004d70:	ffa6                	sd	s1,504(sp)
    80004d72:	fbca                	sd	s2,496(sp)
    80004d74:	f7ce                	sd	s3,488(sp)
    80004d76:	f3d2                	sd	s4,480(sp)
    80004d78:	efd6                	sd	s5,472(sp)
    80004d7a:	ebda                	sd	s6,464(sp)
    80004d7c:	e7de                	sd	s7,456(sp)
    80004d7e:	e3e2                	sd	s8,448(sp)
    80004d80:	ff66                	sd	s9,440(sp)
    80004d82:	fb6a                	sd	s10,432(sp)
    80004d84:	f76e                	sd	s11,424(sp)
    80004d86:	0c00                	addi	s0,sp,528
    80004d88:	84aa                	mv	s1,a0
    80004d8a:	dea43c23          	sd	a0,-520(s0)
    80004d8e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	c14080e7          	jalr	-1004(ra) # 800019a6 <myproc>
    80004d9a:	892a                	mv	s2,a0

  begin_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	494080e7          	jalr	1172(ra) # 80004230 <begin_op>

  if((ip = namei(path)) == 0){
    80004da4:	8526                	mv	a0,s1
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	26e080e7          	jalr	622(ra) # 80004014 <namei>
    80004dae:	c92d                	beqz	a0,80004e20 <exec+0xbc>
    80004db0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	aac080e7          	jalr	-1364(ra) # 8000385e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dba:	04000713          	li	a4,64
    80004dbe:	4681                	li	a3,0
    80004dc0:	e4840613          	addi	a2,s0,-440
    80004dc4:	4581                	li	a1,0
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	d4a080e7          	jalr	-694(ra) # 80003b12 <readi>
    80004dd0:	04000793          	li	a5,64
    80004dd4:	00f51a63          	bne	a0,a5,80004de8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dd8:	e4842703          	lw	a4,-440(s0)
    80004ddc:	464c47b7          	lui	a5,0x464c4
    80004de0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004de4:	04f70463          	beq	a4,a5,80004e2c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004de8:	8526                	mv	a0,s1
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	cd6080e7          	jalr	-810(ra) # 80003ac0 <iunlockput>
    end_op();
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	4be080e7          	jalr	1214(ra) # 800042b0 <end_op>
  }
  return -1;
    80004dfa:	557d                	li	a0,-1
}
    80004dfc:	20813083          	ld	ra,520(sp)
    80004e00:	20013403          	ld	s0,512(sp)
    80004e04:	74fe                	ld	s1,504(sp)
    80004e06:	795e                	ld	s2,496(sp)
    80004e08:	79be                	ld	s3,488(sp)
    80004e0a:	7a1e                	ld	s4,480(sp)
    80004e0c:	6afe                	ld	s5,472(sp)
    80004e0e:	6b5e                	ld	s6,464(sp)
    80004e10:	6bbe                	ld	s7,456(sp)
    80004e12:	6c1e                	ld	s8,448(sp)
    80004e14:	7cfa                	ld	s9,440(sp)
    80004e16:	7d5a                	ld	s10,432(sp)
    80004e18:	7dba                	ld	s11,424(sp)
    80004e1a:	21010113          	addi	sp,sp,528
    80004e1e:	8082                	ret
    end_op();
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	490080e7          	jalr	1168(ra) # 800042b0 <end_op>
    return -1;
    80004e28:	557d                	li	a0,-1
    80004e2a:	bfc9                	j	80004dfc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e2c:	854a                	mv	a0,s2
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	c3c080e7          	jalr	-964(ra) # 80001a6a <proc_pagetable>
    80004e36:	8baa                	mv	s7,a0
    80004e38:	d945                	beqz	a0,80004de8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e3a:	e6842983          	lw	s3,-408(s0)
    80004e3e:	e8045783          	lhu	a5,-384(s0)
    80004e42:	c7ad                	beqz	a5,80004eac <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e44:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e46:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e48:	6c85                	lui	s9,0x1
    80004e4a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e4e:	def43823          	sd	a5,-528(s0)
    80004e52:	a42d                	j	8000507c <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e54:	00004517          	auipc	a0,0x4
    80004e58:	82450513          	addi	a0,a0,-2012 # 80008678 <syscalls+0x290>
    80004e5c:	ffffb097          	auipc	ra,0xffffb
    80004e60:	6d4080e7          	jalr	1748(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e64:	8756                	mv	a4,s5
    80004e66:	012d86bb          	addw	a3,s11,s2
    80004e6a:	4581                	li	a1,0
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	ca4080e7          	jalr	-860(ra) # 80003b12 <readi>
    80004e76:	2501                	sext.w	a0,a0
    80004e78:	1aaa9963          	bne	s5,a0,8000502a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e7c:	6785                	lui	a5,0x1
    80004e7e:	0127893b          	addw	s2,a5,s2
    80004e82:	77fd                	lui	a5,0xfffff
    80004e84:	01478a3b          	addw	s4,a5,s4
    80004e88:	1f897163          	bgeu	s2,s8,8000506a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e8c:	02091593          	slli	a1,s2,0x20
    80004e90:	9181                	srli	a1,a1,0x20
    80004e92:	95ea                	add	a1,a1,s10
    80004e94:	855e                	mv	a0,s7
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	1ce080e7          	jalr	462(ra) # 80001064 <walkaddr>
    80004e9e:	862a                	mv	a2,a0
    if(pa == 0)
    80004ea0:	d955                	beqz	a0,80004e54 <exec+0xf0>
      n = PGSIZE;
    80004ea2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ea4:	fd9a70e3          	bgeu	s4,s9,80004e64 <exec+0x100>
      n = sz - i;
    80004ea8:	8ad2                	mv	s5,s4
    80004eaa:	bf6d                	j	80004e64 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004eac:	4901                	li	s2,0
  iunlockput(ip);
    80004eae:	8526                	mv	a0,s1
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	c10080e7          	jalr	-1008(ra) # 80003ac0 <iunlockput>
  end_op();
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	3f8080e7          	jalr	1016(ra) # 800042b0 <end_op>
  p = myproc();
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	ae6080e7          	jalr	-1306(ra) # 800019a6 <myproc>
    80004ec8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eca:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ece:	6785                	lui	a5,0x1
    80004ed0:	17fd                	addi	a5,a5,-1
    80004ed2:	993e                	add	s2,s2,a5
    80004ed4:	757d                	lui	a0,0xfffff
    80004ed6:	00a977b3          	and	a5,s2,a0
    80004eda:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ede:	6609                	lui	a2,0x2
    80004ee0:	963e                	add	a2,a2,a5
    80004ee2:	85be                	mv	a1,a5
    80004ee4:	855e                	mv	a0,s7
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	512080e7          	jalr	1298(ra) # 800013f8 <uvmalloc>
    80004eee:	8b2a                	mv	s6,a0
  ip = 0;
    80004ef0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ef2:	12050c63          	beqz	a0,8000502a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ef6:	75f9                	lui	a1,0xffffe
    80004ef8:	95aa                	add	a1,a1,a0
    80004efa:	855e                	mv	a0,s7
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	70e080e7          	jalr	1806(ra) # 8000160a <uvmclear>
  stackbase = sp - PGSIZE;
    80004f04:	7c7d                	lui	s8,0xfffff
    80004f06:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f08:	e0043783          	ld	a5,-512(s0)
    80004f0c:	6388                	ld	a0,0(a5)
    80004f0e:	c535                	beqz	a0,80004f7a <exec+0x216>
    80004f10:	e8840993          	addi	s3,s0,-376
    80004f14:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f18:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	f40080e7          	jalr	-192(ra) # 80000e5a <strlen>
    80004f22:	2505                	addiw	a0,a0,1
    80004f24:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f28:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f2c:	13896363          	bltu	s2,s8,80005052 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f30:	e0043d83          	ld	s11,-512(s0)
    80004f34:	000dba03          	ld	s4,0(s11)
    80004f38:	8552                	mv	a0,s4
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	f20080e7          	jalr	-224(ra) # 80000e5a <strlen>
    80004f42:	0015069b          	addiw	a3,a0,1
    80004f46:	8652                	mv	a2,s4
    80004f48:	85ca                	mv	a1,s2
    80004f4a:	855e                	mv	a0,s7
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	6f0080e7          	jalr	1776(ra) # 8000163c <copyout>
    80004f54:	10054363          	bltz	a0,8000505a <exec+0x2f6>
    ustack[argc] = sp;
    80004f58:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f5c:	0485                	addi	s1,s1,1
    80004f5e:	008d8793          	addi	a5,s11,8
    80004f62:	e0f43023          	sd	a5,-512(s0)
    80004f66:	008db503          	ld	a0,8(s11)
    80004f6a:	c911                	beqz	a0,80004f7e <exec+0x21a>
    if(argc >= MAXARG)
    80004f6c:	09a1                	addi	s3,s3,8
    80004f6e:	fb3c96e3          	bne	s9,s3,80004f1a <exec+0x1b6>
  sz = sz1;
    80004f72:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f76:	4481                	li	s1,0
    80004f78:	a84d                	j	8000502a <exec+0x2c6>
  sp = sz;
    80004f7a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f7c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f7e:	00349793          	slli	a5,s1,0x3
    80004f82:	f9040713          	addi	a4,s0,-112
    80004f86:	97ba                	add	a5,a5,a4
    80004f88:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f8c:	00148693          	addi	a3,s1,1
    80004f90:	068e                	slli	a3,a3,0x3
    80004f92:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f96:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f9a:	01897663          	bgeu	s2,s8,80004fa6 <exec+0x242>
  sz = sz1;
    80004f9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa2:	4481                	li	s1,0
    80004fa4:	a059                	j	8000502a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fa6:	e8840613          	addi	a2,s0,-376
    80004faa:	85ca                	mv	a1,s2
    80004fac:	855e                	mv	a0,s7
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	68e080e7          	jalr	1678(ra) # 8000163c <copyout>
    80004fb6:	0a054663          	bltz	a0,80005062 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fba:	058ab783          	ld	a5,88(s5)
    80004fbe:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fc2:	df843783          	ld	a5,-520(s0)
    80004fc6:	0007c703          	lbu	a4,0(a5)
    80004fca:	cf11                	beqz	a4,80004fe6 <exec+0x282>
    80004fcc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fce:	02f00693          	li	a3,47
    80004fd2:	a029                	j	80004fdc <exec+0x278>
  for(last=s=path; *s; s++)
    80004fd4:	0785                	addi	a5,a5,1
    80004fd6:	fff7c703          	lbu	a4,-1(a5)
    80004fda:	c711                	beqz	a4,80004fe6 <exec+0x282>
    if(*s == '/')
    80004fdc:	fed71ce3          	bne	a4,a3,80004fd4 <exec+0x270>
      last = s+1;
    80004fe0:	def43c23          	sd	a5,-520(s0)
    80004fe4:	bfc5                	j	80004fd4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fe6:	4641                	li	a2,16
    80004fe8:	df843583          	ld	a1,-520(s0)
    80004fec:	158a8513          	addi	a0,s5,344
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	e38080e7          	jalr	-456(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ff8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ffc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005000:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005004:	058ab783          	ld	a5,88(s5)
    80005008:	e6043703          	ld	a4,-416(s0)
    8000500c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000500e:	058ab783          	ld	a5,88(s5)
    80005012:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005016:	85ea                	mv	a1,s10
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	aee080e7          	jalr	-1298(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005020:	0004851b          	sext.w	a0,s1
    80005024:	bbe1                	j	80004dfc <exec+0x98>
    80005026:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000502a:	e0843583          	ld	a1,-504(s0)
    8000502e:	855e                	mv	a0,s7
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	ad6080e7          	jalr	-1322(ra) # 80001b06 <proc_freepagetable>
  if(ip){
    80005038:	da0498e3          	bnez	s1,80004de8 <exec+0x84>
  return -1;
    8000503c:	557d                	li	a0,-1
    8000503e:	bb7d                	j	80004dfc <exec+0x98>
    80005040:	e1243423          	sd	s2,-504(s0)
    80005044:	b7dd                	j	8000502a <exec+0x2c6>
    80005046:	e1243423          	sd	s2,-504(s0)
    8000504a:	b7c5                	j	8000502a <exec+0x2c6>
    8000504c:	e1243423          	sd	s2,-504(s0)
    80005050:	bfe9                	j	8000502a <exec+0x2c6>
  sz = sz1;
    80005052:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005056:	4481                	li	s1,0
    80005058:	bfc9                	j	8000502a <exec+0x2c6>
  sz = sz1;
    8000505a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000505e:	4481                	li	s1,0
    80005060:	b7e9                	j	8000502a <exec+0x2c6>
  sz = sz1;
    80005062:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005066:	4481                	li	s1,0
    80005068:	b7c9                	j	8000502a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000506a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000506e:	2b05                	addiw	s6,s6,1
    80005070:	0389899b          	addiw	s3,s3,56
    80005074:	e8045783          	lhu	a5,-384(s0)
    80005078:	e2fb5be3          	bge	s6,a5,80004eae <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000507c:	2981                	sext.w	s3,s3
    8000507e:	03800713          	li	a4,56
    80005082:	86ce                	mv	a3,s3
    80005084:	e1040613          	addi	a2,s0,-496
    80005088:	4581                	li	a1,0
    8000508a:	8526                	mv	a0,s1
    8000508c:	fffff097          	auipc	ra,0xfffff
    80005090:	a86080e7          	jalr	-1402(ra) # 80003b12 <readi>
    80005094:	03800793          	li	a5,56
    80005098:	f8f517e3          	bne	a0,a5,80005026 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000509c:	e1042783          	lw	a5,-496(s0)
    800050a0:	4705                	li	a4,1
    800050a2:	fce796e3          	bne	a5,a4,8000506e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050a6:	e3843603          	ld	a2,-456(s0)
    800050aa:	e3043783          	ld	a5,-464(s0)
    800050ae:	f8f669e3          	bltu	a2,a5,80005040 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050b2:	e2043783          	ld	a5,-480(s0)
    800050b6:	963e                	add	a2,a2,a5
    800050b8:	f8f667e3          	bltu	a2,a5,80005046 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050bc:	85ca                	mv	a1,s2
    800050be:	855e                	mv	a0,s7
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	338080e7          	jalr	824(ra) # 800013f8 <uvmalloc>
    800050c8:	e0a43423          	sd	a0,-504(s0)
    800050cc:	d141                	beqz	a0,8000504c <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800050ce:	e2043d03          	ld	s10,-480(s0)
    800050d2:	df043783          	ld	a5,-528(s0)
    800050d6:	00fd77b3          	and	a5,s10,a5
    800050da:	fba1                	bnez	a5,8000502a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050dc:	e1842d83          	lw	s11,-488(s0)
    800050e0:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050e4:	f80c03e3          	beqz	s8,8000506a <exec+0x306>
    800050e8:	8a62                	mv	s4,s8
    800050ea:	4901                	li	s2,0
    800050ec:	b345                	j	80004e8c <exec+0x128>

00000000800050ee <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050ee:	7179                	addi	sp,sp,-48
    800050f0:	f406                	sd	ra,40(sp)
    800050f2:	f022                	sd	s0,32(sp)
    800050f4:	ec26                	sd	s1,24(sp)
    800050f6:	e84a                	sd	s2,16(sp)
    800050f8:	1800                	addi	s0,sp,48
    800050fa:	892e                	mv	s2,a1
    800050fc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050fe:	fdc40593          	addi	a1,s0,-36
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	bea080e7          	jalr	-1046(ra) # 80002cec <argint>
    8000510a:	04054063          	bltz	a0,8000514a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000510e:	fdc42703          	lw	a4,-36(s0)
    80005112:	47bd                	li	a5,15
    80005114:	02e7ed63          	bltu	a5,a4,8000514e <argfd+0x60>
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	88e080e7          	jalr	-1906(ra) # 800019a6 <myproc>
    80005120:	fdc42703          	lw	a4,-36(s0)
    80005124:	01a70793          	addi	a5,a4,26
    80005128:	078e                	slli	a5,a5,0x3
    8000512a:	953e                	add	a0,a0,a5
    8000512c:	611c                	ld	a5,0(a0)
    8000512e:	c395                	beqz	a5,80005152 <argfd+0x64>
    return -1;
  if(pfd)
    80005130:	00090463          	beqz	s2,80005138 <argfd+0x4a>
    *pfd = fd;
    80005134:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005138:	4501                	li	a0,0
  if(pf)
    8000513a:	c091                	beqz	s1,8000513e <argfd+0x50>
    *pf = f;
    8000513c:	e09c                	sd	a5,0(s1)
}
    8000513e:	70a2                	ld	ra,40(sp)
    80005140:	7402                	ld	s0,32(sp)
    80005142:	64e2                	ld	s1,24(sp)
    80005144:	6942                	ld	s2,16(sp)
    80005146:	6145                	addi	sp,sp,48
    80005148:	8082                	ret
    return -1;
    8000514a:	557d                	li	a0,-1
    8000514c:	bfcd                	j	8000513e <argfd+0x50>
    return -1;
    8000514e:	557d                	li	a0,-1
    80005150:	b7fd                	j	8000513e <argfd+0x50>
    80005152:	557d                	li	a0,-1
    80005154:	b7ed                	j	8000513e <argfd+0x50>

0000000080005156 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005156:	1101                	addi	sp,sp,-32
    80005158:	ec06                	sd	ra,24(sp)
    8000515a:	e822                	sd	s0,16(sp)
    8000515c:	e426                	sd	s1,8(sp)
    8000515e:	1000                	addi	s0,sp,32
    80005160:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005162:	ffffd097          	auipc	ra,0xffffd
    80005166:	844080e7          	jalr	-1980(ra) # 800019a6 <myproc>
    8000516a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000516c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffcd0d0>
    80005170:	4501                	li	a0,0
    80005172:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005174:	6398                	ld	a4,0(a5)
    80005176:	cb19                	beqz	a4,8000518c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005178:	2505                	addiw	a0,a0,1
    8000517a:	07a1                	addi	a5,a5,8
    8000517c:	fed51ce3          	bne	a0,a3,80005174 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005180:	557d                	li	a0,-1
}
    80005182:	60e2                	ld	ra,24(sp)
    80005184:	6442                	ld	s0,16(sp)
    80005186:	64a2                	ld	s1,8(sp)
    80005188:	6105                	addi	sp,sp,32
    8000518a:	8082                	ret
      p->ofile[fd] = f;
    8000518c:	01a50793          	addi	a5,a0,26
    80005190:	078e                	slli	a5,a5,0x3
    80005192:	963e                	add	a2,a2,a5
    80005194:	e204                	sd	s1,0(a2)
      return fd;
    80005196:	b7f5                	j	80005182 <fdalloc+0x2c>

0000000080005198 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005198:	715d                	addi	sp,sp,-80
    8000519a:	e486                	sd	ra,72(sp)
    8000519c:	e0a2                	sd	s0,64(sp)
    8000519e:	fc26                	sd	s1,56(sp)
    800051a0:	f84a                	sd	s2,48(sp)
    800051a2:	f44e                	sd	s3,40(sp)
    800051a4:	f052                	sd	s4,32(sp)
    800051a6:	ec56                	sd	s5,24(sp)
    800051a8:	0880                	addi	s0,sp,80
    800051aa:	89ae                	mv	s3,a1
    800051ac:	8ab2                	mv	s5,a2
    800051ae:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051b0:	fb040593          	addi	a1,s0,-80
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	e7e080e7          	jalr	-386(ra) # 80004032 <nameiparent>
    800051bc:	892a                	mv	s2,a0
    800051be:	12050f63          	beqz	a0,800052fc <create+0x164>
    return 0;

  ilock(dp);
    800051c2:	ffffe097          	auipc	ra,0xffffe
    800051c6:	69c080e7          	jalr	1692(ra) # 8000385e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ca:	4601                	li	a2,0
    800051cc:	fb040593          	addi	a1,s0,-80
    800051d0:	854a                	mv	a0,s2
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	b70080e7          	jalr	-1168(ra) # 80003d42 <dirlookup>
    800051da:	84aa                	mv	s1,a0
    800051dc:	c921                	beqz	a0,8000522c <create+0x94>
    iunlockput(dp);
    800051de:	854a                	mv	a0,s2
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	8e0080e7          	jalr	-1824(ra) # 80003ac0 <iunlockput>
    ilock(ip);
    800051e8:	8526                	mv	a0,s1
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	674080e7          	jalr	1652(ra) # 8000385e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051f2:	2981                	sext.w	s3,s3
    800051f4:	4789                	li	a5,2
    800051f6:	02f99463          	bne	s3,a5,8000521e <create+0x86>
    800051fa:	0444d783          	lhu	a5,68(s1)
    800051fe:	37f9                	addiw	a5,a5,-2
    80005200:	17c2                	slli	a5,a5,0x30
    80005202:	93c1                	srli	a5,a5,0x30
    80005204:	4705                	li	a4,1
    80005206:	00f76c63          	bltu	a4,a5,8000521e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000520a:	8526                	mv	a0,s1
    8000520c:	60a6                	ld	ra,72(sp)
    8000520e:	6406                	ld	s0,64(sp)
    80005210:	74e2                	ld	s1,56(sp)
    80005212:	7942                	ld	s2,48(sp)
    80005214:	79a2                	ld	s3,40(sp)
    80005216:	7a02                	ld	s4,32(sp)
    80005218:	6ae2                	ld	s5,24(sp)
    8000521a:	6161                	addi	sp,sp,80
    8000521c:	8082                	ret
    iunlockput(ip);
    8000521e:	8526                	mv	a0,s1
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	8a0080e7          	jalr	-1888(ra) # 80003ac0 <iunlockput>
    return 0;
    80005228:	4481                	li	s1,0
    8000522a:	b7c5                	j	8000520a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000522c:	85ce                	mv	a1,s3
    8000522e:	00092503          	lw	a0,0(s2)
    80005232:	ffffe097          	auipc	ra,0xffffe
    80005236:	494080e7          	jalr	1172(ra) # 800036c6 <ialloc>
    8000523a:	84aa                	mv	s1,a0
    8000523c:	c529                	beqz	a0,80005286 <create+0xee>
  ilock(ip);
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	620080e7          	jalr	1568(ra) # 8000385e <ilock>
  ip->major = major;
    80005246:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000524a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000524e:	4785                	li	a5,1
    80005250:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005254:	8526                	mv	a0,s1
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	53e080e7          	jalr	1342(ra) # 80003794 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000525e:	2981                	sext.w	s3,s3
    80005260:	4785                	li	a5,1
    80005262:	02f98a63          	beq	s3,a5,80005296 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005266:	40d0                	lw	a2,4(s1)
    80005268:	fb040593          	addi	a1,s0,-80
    8000526c:	854a                	mv	a0,s2
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	ce4080e7          	jalr	-796(ra) # 80003f52 <dirlink>
    80005276:	06054b63          	bltz	a0,800052ec <create+0x154>
  iunlockput(dp);
    8000527a:	854a                	mv	a0,s2
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	844080e7          	jalr	-1980(ra) # 80003ac0 <iunlockput>
  return ip;
    80005284:	b759                	j	8000520a <create+0x72>
    panic("create: ialloc");
    80005286:	00003517          	auipc	a0,0x3
    8000528a:	41250513          	addi	a0,a0,1042 # 80008698 <syscalls+0x2b0>
    8000528e:	ffffb097          	auipc	ra,0xffffb
    80005292:	2a2080e7          	jalr	674(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005296:	04a95783          	lhu	a5,74(s2)
    8000529a:	2785                	addiw	a5,a5,1
    8000529c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052a0:	854a                	mv	a0,s2
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	4f2080e7          	jalr	1266(ra) # 80003794 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052aa:	40d0                	lw	a2,4(s1)
    800052ac:	00003597          	auipc	a1,0x3
    800052b0:	3fc58593          	addi	a1,a1,1020 # 800086a8 <syscalls+0x2c0>
    800052b4:	8526                	mv	a0,s1
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	c9c080e7          	jalr	-868(ra) # 80003f52 <dirlink>
    800052be:	00054f63          	bltz	a0,800052dc <create+0x144>
    800052c2:	00492603          	lw	a2,4(s2)
    800052c6:	00003597          	auipc	a1,0x3
    800052ca:	3ea58593          	addi	a1,a1,1002 # 800086b0 <syscalls+0x2c8>
    800052ce:	8526                	mv	a0,s1
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	c82080e7          	jalr	-894(ra) # 80003f52 <dirlink>
    800052d8:	f80557e3          	bgez	a0,80005266 <create+0xce>
      panic("create dots");
    800052dc:	00003517          	auipc	a0,0x3
    800052e0:	3dc50513          	addi	a0,a0,988 # 800086b8 <syscalls+0x2d0>
    800052e4:	ffffb097          	auipc	ra,0xffffb
    800052e8:	24c080e7          	jalr	588(ra) # 80000530 <panic>
    panic("create: dirlink");
    800052ec:	00003517          	auipc	a0,0x3
    800052f0:	3dc50513          	addi	a0,a0,988 # 800086c8 <syscalls+0x2e0>
    800052f4:	ffffb097          	auipc	ra,0xffffb
    800052f8:	23c080e7          	jalr	572(ra) # 80000530 <panic>
    return 0;
    800052fc:	84aa                	mv	s1,a0
    800052fe:	b731                	j	8000520a <create+0x72>

0000000080005300 <sys_dup>:
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	ec26                	sd	s1,24(sp)
    80005308:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000530a:	fd840613          	addi	a2,s0,-40
    8000530e:	4581                	li	a1,0
    80005310:	4501                	li	a0,0
    80005312:	00000097          	auipc	ra,0x0
    80005316:	ddc080e7          	jalr	-548(ra) # 800050ee <argfd>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000531c:	02054363          	bltz	a0,80005342 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005320:	fd843503          	ld	a0,-40(s0)
    80005324:	00000097          	auipc	ra,0x0
    80005328:	e32080e7          	jalr	-462(ra) # 80005156 <fdalloc>
    8000532c:	84aa                	mv	s1,a0
    return -1;
    8000532e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005330:	00054963          	bltz	a0,80005342 <sys_dup+0x42>
  filedup(f);
    80005334:	fd843503          	ld	a0,-40(s0)
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	37a080e7          	jalr	890(ra) # 800046b2 <filedup>
  return fd;
    80005340:	87a6                	mv	a5,s1
}
    80005342:	853e                	mv	a0,a5
    80005344:	70a2                	ld	ra,40(sp)
    80005346:	7402                	ld	s0,32(sp)
    80005348:	64e2                	ld	s1,24(sp)
    8000534a:	6145                	addi	sp,sp,48
    8000534c:	8082                	ret

000000008000534e <sys_read>:
{
    8000534e:	7179                	addi	sp,sp,-48
    80005350:	f406                	sd	ra,40(sp)
    80005352:	f022                	sd	s0,32(sp)
    80005354:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	fe840613          	addi	a2,s0,-24
    8000535a:	4581                	li	a1,0
    8000535c:	4501                	li	a0,0
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	d90080e7          	jalr	-624(ra) # 800050ee <argfd>
    return -1;
    80005366:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005368:	04054163          	bltz	a0,800053aa <sys_read+0x5c>
    8000536c:	fe440593          	addi	a1,s0,-28
    80005370:	4509                	li	a0,2
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	97a080e7          	jalr	-1670(ra) # 80002cec <argint>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537c:	02054763          	bltz	a0,800053aa <sys_read+0x5c>
    80005380:	fd840593          	addi	a1,s0,-40
    80005384:	4505                	li	a0,1
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	988080e7          	jalr	-1656(ra) # 80002d0e <argaddr>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005390:	00054d63          	bltz	a0,800053aa <sys_read+0x5c>
  return fileread(f, p, n);
    80005394:	fe442603          	lw	a2,-28(s0)
    80005398:	fd843583          	ld	a1,-40(s0)
    8000539c:	fe843503          	ld	a0,-24(s0)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	49e080e7          	jalr	1182(ra) # 8000483e <fileread>
    800053a8:	87aa                	mv	a5,a0
}
    800053aa:	853e                	mv	a0,a5
    800053ac:	70a2                	ld	ra,40(sp)
    800053ae:	7402                	ld	s0,32(sp)
    800053b0:	6145                	addi	sp,sp,48
    800053b2:	8082                	ret

00000000800053b4 <sys_write>:
{
    800053b4:	7179                	addi	sp,sp,-48
    800053b6:	f406                	sd	ra,40(sp)
    800053b8:	f022                	sd	s0,32(sp)
    800053ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	fe840613          	addi	a2,s0,-24
    800053c0:	4581                	li	a1,0
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	d2a080e7          	jalr	-726(ra) # 800050ee <argfd>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ce:	04054163          	bltz	a0,80005410 <sys_write+0x5c>
    800053d2:	fe440593          	addi	a1,s0,-28
    800053d6:	4509                	li	a0,2
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	914080e7          	jalr	-1772(ra) # 80002cec <argint>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	02054763          	bltz	a0,80005410 <sys_write+0x5c>
    800053e6:	fd840593          	addi	a1,s0,-40
    800053ea:	4505                	li	a0,1
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	922080e7          	jalr	-1758(ra) # 80002d0e <argaddr>
    return -1;
    800053f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f6:	00054d63          	bltz	a0,80005410 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053fa:	fe442603          	lw	a2,-28(s0)
    800053fe:	fd843583          	ld	a1,-40(s0)
    80005402:	fe843503          	ld	a0,-24(s0)
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	4fa080e7          	jalr	1274(ra) # 80004900 <filewrite>
    8000540e:	87aa                	mv	a5,a0
}
    80005410:	853e                	mv	a0,a5
    80005412:	70a2                	ld	ra,40(sp)
    80005414:	7402                	ld	s0,32(sp)
    80005416:	6145                	addi	sp,sp,48
    80005418:	8082                	ret

000000008000541a <sys_close>:
{
    8000541a:	1101                	addi	sp,sp,-32
    8000541c:	ec06                	sd	ra,24(sp)
    8000541e:	e822                	sd	s0,16(sp)
    80005420:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005422:	fe040613          	addi	a2,s0,-32
    80005426:	fec40593          	addi	a1,s0,-20
    8000542a:	4501                	li	a0,0
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	cc2080e7          	jalr	-830(ra) # 800050ee <argfd>
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005436:	02054463          	bltz	a0,8000545e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000543a:	ffffc097          	auipc	ra,0xffffc
    8000543e:	56c080e7          	jalr	1388(ra) # 800019a6 <myproc>
    80005442:	fec42783          	lw	a5,-20(s0)
    80005446:	07e9                	addi	a5,a5,26
    80005448:	078e                	slli	a5,a5,0x3
    8000544a:	97aa                	add	a5,a5,a0
    8000544c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005450:	fe043503          	ld	a0,-32(s0)
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	2b0080e7          	jalr	688(ra) # 80004704 <fileclose>
  return 0;
    8000545c:	4781                	li	a5,0
}
    8000545e:	853e                	mv	a0,a5
    80005460:	60e2                	ld	ra,24(sp)
    80005462:	6442                	ld	s0,16(sp)
    80005464:	6105                	addi	sp,sp,32
    80005466:	8082                	ret

0000000080005468 <sys_fstat>:
{
    80005468:	1101                	addi	sp,sp,-32
    8000546a:	ec06                	sd	ra,24(sp)
    8000546c:	e822                	sd	s0,16(sp)
    8000546e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005470:	fe840613          	addi	a2,s0,-24
    80005474:	4581                	li	a1,0
    80005476:	4501                	li	a0,0
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	c76080e7          	jalr	-906(ra) # 800050ee <argfd>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005482:	02054563          	bltz	a0,800054ac <sys_fstat+0x44>
    80005486:	fe040593          	addi	a1,s0,-32
    8000548a:	4505                	li	a0,1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	882080e7          	jalr	-1918(ra) # 80002d0e <argaddr>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005496:	00054b63          	bltz	a0,800054ac <sys_fstat+0x44>
  return filestat(f, st);
    8000549a:	fe043583          	ld	a1,-32(s0)
    8000549e:	fe843503          	ld	a0,-24(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	32a080e7          	jalr	810(ra) # 800047cc <filestat>
    800054aa:	87aa                	mv	a5,a0
}
    800054ac:	853e                	mv	a0,a5
    800054ae:	60e2                	ld	ra,24(sp)
    800054b0:	6442                	ld	s0,16(sp)
    800054b2:	6105                	addi	sp,sp,32
    800054b4:	8082                	ret

00000000800054b6 <sys_link>:
{
    800054b6:	7169                	addi	sp,sp,-304
    800054b8:	f606                	sd	ra,296(sp)
    800054ba:	f222                	sd	s0,288(sp)
    800054bc:	ee26                	sd	s1,280(sp)
    800054be:	ea4a                	sd	s2,272(sp)
    800054c0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c2:	08000613          	li	a2,128
    800054c6:	ed040593          	addi	a1,s0,-304
    800054ca:	4501                	li	a0,0
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	864080e7          	jalr	-1948(ra) # 80002d30 <argstr>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d6:	10054e63          	bltz	a0,800055f2 <sys_link+0x13c>
    800054da:	08000613          	li	a2,128
    800054de:	f5040593          	addi	a1,s0,-176
    800054e2:	4505                	li	a0,1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	84c080e7          	jalr	-1972(ra) # 80002d30 <argstr>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ee:	10054263          	bltz	a0,800055f2 <sys_link+0x13c>
  begin_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	d3e080e7          	jalr	-706(ra) # 80004230 <begin_op>
  if((ip = namei(old)) == 0){
    800054fa:	ed040513          	addi	a0,s0,-304
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	b16080e7          	jalr	-1258(ra) # 80004014 <namei>
    80005506:	84aa                	mv	s1,a0
    80005508:	c551                	beqz	a0,80005594 <sys_link+0xde>
  ilock(ip);
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	354080e7          	jalr	852(ra) # 8000385e <ilock>
  if(ip->type == T_DIR){
    80005512:	04449703          	lh	a4,68(s1)
    80005516:	4785                	li	a5,1
    80005518:	08f70463          	beq	a4,a5,800055a0 <sys_link+0xea>
  ip->nlink++;
    8000551c:	04a4d783          	lhu	a5,74(s1)
    80005520:	2785                	addiw	a5,a5,1
    80005522:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	26c080e7          	jalr	620(ra) # 80003794 <iupdate>
  iunlock(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	3ee080e7          	jalr	1006(ra) # 80003920 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000553a:	fd040593          	addi	a1,s0,-48
    8000553e:	f5040513          	addi	a0,s0,-176
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	af0080e7          	jalr	-1296(ra) # 80004032 <nameiparent>
    8000554a:	892a                	mv	s2,a0
    8000554c:	c935                	beqz	a0,800055c0 <sys_link+0x10a>
  ilock(dp);
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	310080e7          	jalr	784(ra) # 8000385e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005556:	00092703          	lw	a4,0(s2)
    8000555a:	409c                	lw	a5,0(s1)
    8000555c:	04f71d63          	bne	a4,a5,800055b6 <sys_link+0x100>
    80005560:	40d0                	lw	a2,4(s1)
    80005562:	fd040593          	addi	a1,s0,-48
    80005566:	854a                	mv	a0,s2
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	9ea080e7          	jalr	-1558(ra) # 80003f52 <dirlink>
    80005570:	04054363          	bltz	a0,800055b6 <sys_link+0x100>
  iunlockput(dp);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	54a080e7          	jalr	1354(ra) # 80003ac0 <iunlockput>
  iput(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	498080e7          	jalr	1176(ra) # 80003a18 <iput>
  end_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	d28080e7          	jalr	-728(ra) # 800042b0 <end_op>
  return 0;
    80005590:	4781                	li	a5,0
    80005592:	a085                	j	800055f2 <sys_link+0x13c>
    end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	d1c080e7          	jalr	-740(ra) # 800042b0 <end_op>
    return -1;
    8000559c:	57fd                	li	a5,-1
    8000559e:	a891                	j	800055f2 <sys_link+0x13c>
    iunlockput(ip);
    800055a0:	8526                	mv	a0,s1
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	51e080e7          	jalr	1310(ra) # 80003ac0 <iunlockput>
    end_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	d06080e7          	jalr	-762(ra) # 800042b0 <end_op>
    return -1;
    800055b2:	57fd                	li	a5,-1
    800055b4:	a83d                	j	800055f2 <sys_link+0x13c>
    iunlockput(dp);
    800055b6:	854a                	mv	a0,s2
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	508080e7          	jalr	1288(ra) # 80003ac0 <iunlockput>
  ilock(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	29c080e7          	jalr	668(ra) # 8000385e <ilock>
  ip->nlink--;
    800055ca:	04a4d783          	lhu	a5,74(s1)
    800055ce:	37fd                	addiw	a5,a5,-1
    800055d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	1be080e7          	jalr	446(ra) # 80003794 <iupdate>
  iunlockput(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	4e0080e7          	jalr	1248(ra) # 80003ac0 <iunlockput>
  end_op();
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	cc8080e7          	jalr	-824(ra) # 800042b0 <end_op>
  return -1;
    800055f0:	57fd                	li	a5,-1
}
    800055f2:	853e                	mv	a0,a5
    800055f4:	70b2                	ld	ra,296(sp)
    800055f6:	7412                	ld	s0,288(sp)
    800055f8:	64f2                	ld	s1,280(sp)
    800055fa:	6952                	ld	s2,272(sp)
    800055fc:	6155                	addi	sp,sp,304
    800055fe:	8082                	ret

0000000080005600 <sys_unlink>:
{
    80005600:	7151                	addi	sp,sp,-240
    80005602:	f586                	sd	ra,232(sp)
    80005604:	f1a2                	sd	s0,224(sp)
    80005606:	eda6                	sd	s1,216(sp)
    80005608:	e9ca                	sd	s2,208(sp)
    8000560a:	e5ce                	sd	s3,200(sp)
    8000560c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000560e:	08000613          	li	a2,128
    80005612:	f3040593          	addi	a1,s0,-208
    80005616:	4501                	li	a0,0
    80005618:	ffffd097          	auipc	ra,0xffffd
    8000561c:	718080e7          	jalr	1816(ra) # 80002d30 <argstr>
    80005620:	18054163          	bltz	a0,800057a2 <sys_unlink+0x1a2>
  begin_op();
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	c0c080e7          	jalr	-1012(ra) # 80004230 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000562c:	fb040593          	addi	a1,s0,-80
    80005630:	f3040513          	addi	a0,s0,-208
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	9fe080e7          	jalr	-1538(ra) # 80004032 <nameiparent>
    8000563c:	84aa                	mv	s1,a0
    8000563e:	c979                	beqz	a0,80005714 <sys_unlink+0x114>
  ilock(dp);
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	21e080e7          	jalr	542(ra) # 8000385e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005648:	00003597          	auipc	a1,0x3
    8000564c:	06058593          	addi	a1,a1,96 # 800086a8 <syscalls+0x2c0>
    80005650:	fb040513          	addi	a0,s0,-80
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	6d4080e7          	jalr	1748(ra) # 80003d28 <namecmp>
    8000565c:	14050a63          	beqz	a0,800057b0 <sys_unlink+0x1b0>
    80005660:	00003597          	auipc	a1,0x3
    80005664:	05058593          	addi	a1,a1,80 # 800086b0 <syscalls+0x2c8>
    80005668:	fb040513          	addi	a0,s0,-80
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	6bc080e7          	jalr	1724(ra) # 80003d28 <namecmp>
    80005674:	12050e63          	beqz	a0,800057b0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005678:	f2c40613          	addi	a2,s0,-212
    8000567c:	fb040593          	addi	a1,s0,-80
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	6c0080e7          	jalr	1728(ra) # 80003d42 <dirlookup>
    8000568a:	892a                	mv	s2,a0
    8000568c:	12050263          	beqz	a0,800057b0 <sys_unlink+0x1b0>
  ilock(ip);
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	1ce080e7          	jalr	462(ra) # 8000385e <ilock>
  if(ip->nlink < 1)
    80005698:	04a91783          	lh	a5,74(s2)
    8000569c:	08f05263          	blez	a5,80005720 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056a0:	04491703          	lh	a4,68(s2)
    800056a4:	4785                	li	a5,1
    800056a6:	08f70563          	beq	a4,a5,80005730 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056aa:	4641                	li	a2,16
    800056ac:	4581                	li	a1,0
    800056ae:	fc040513          	addi	a0,s0,-64
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	620080e7          	jalr	1568(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ba:	4741                	li	a4,16
    800056bc:	f2c42683          	lw	a3,-212(s0)
    800056c0:	fc040613          	addi	a2,s0,-64
    800056c4:	4581                	li	a1,0
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	542080e7          	jalr	1346(ra) # 80003c0a <writei>
    800056d0:	47c1                	li	a5,16
    800056d2:	0af51563          	bne	a0,a5,8000577c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056d6:	04491703          	lh	a4,68(s2)
    800056da:	4785                	li	a5,1
    800056dc:	0af70863          	beq	a4,a5,8000578c <sys_unlink+0x18c>
  iunlockput(dp);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	3de080e7          	jalr	990(ra) # 80003ac0 <iunlockput>
  ip->nlink--;
    800056ea:	04a95783          	lhu	a5,74(s2)
    800056ee:	37fd                	addiw	a5,a5,-1
    800056f0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	09e080e7          	jalr	158(ra) # 80003794 <iupdate>
  iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	3c0080e7          	jalr	960(ra) # 80003ac0 <iunlockput>
  end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	ba8080e7          	jalr	-1112(ra) # 800042b0 <end_op>
  return 0;
    80005710:	4501                	li	a0,0
    80005712:	a84d                	j	800057c4 <sys_unlink+0x1c4>
    end_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	b9c080e7          	jalr	-1124(ra) # 800042b0 <end_op>
    return -1;
    8000571c:	557d                	li	a0,-1
    8000571e:	a05d                	j	800057c4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005720:	00003517          	auipc	a0,0x3
    80005724:	fb850513          	addi	a0,a0,-72 # 800086d8 <syscalls+0x2f0>
    80005728:	ffffb097          	auipc	ra,0xffffb
    8000572c:	e08080e7          	jalr	-504(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005730:	04c92703          	lw	a4,76(s2)
    80005734:	02000793          	li	a5,32
    80005738:	f6e7f9e3          	bgeu	a5,a4,800056aa <sys_unlink+0xaa>
    8000573c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005740:	4741                	li	a4,16
    80005742:	86ce                	mv	a3,s3
    80005744:	f1840613          	addi	a2,s0,-232
    80005748:	4581                	li	a1,0
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	3c6080e7          	jalr	966(ra) # 80003b12 <readi>
    80005754:	47c1                	li	a5,16
    80005756:	00f51b63          	bne	a0,a5,8000576c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000575a:	f1845783          	lhu	a5,-232(s0)
    8000575e:	e7a1                	bnez	a5,800057a6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005760:	29c1                	addiw	s3,s3,16
    80005762:	04c92783          	lw	a5,76(s2)
    80005766:	fcf9ede3          	bltu	s3,a5,80005740 <sys_unlink+0x140>
    8000576a:	b781                	j	800056aa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000576c:	00003517          	auipc	a0,0x3
    80005770:	f8450513          	addi	a0,a0,-124 # 800086f0 <syscalls+0x308>
    80005774:	ffffb097          	auipc	ra,0xffffb
    80005778:	dbc080e7          	jalr	-580(ra) # 80000530 <panic>
    panic("unlink: writei");
    8000577c:	00003517          	auipc	a0,0x3
    80005780:	f8c50513          	addi	a0,a0,-116 # 80008708 <syscalls+0x320>
    80005784:	ffffb097          	auipc	ra,0xffffb
    80005788:	dac080e7          	jalr	-596(ra) # 80000530 <panic>
    dp->nlink--;
    8000578c:	04a4d783          	lhu	a5,74(s1)
    80005790:	37fd                	addiw	a5,a5,-1
    80005792:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	ffc080e7          	jalr	-4(ra) # 80003794 <iupdate>
    800057a0:	b781                	j	800056e0 <sys_unlink+0xe0>
    return -1;
    800057a2:	557d                	li	a0,-1
    800057a4:	a005                	j	800057c4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057a6:	854a                	mv	a0,s2
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	318080e7          	jalr	792(ra) # 80003ac0 <iunlockput>
  iunlockput(dp);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	30e080e7          	jalr	782(ra) # 80003ac0 <iunlockput>
  end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	af6080e7          	jalr	-1290(ra) # 800042b0 <end_op>
  return -1;
    800057c2:	557d                	li	a0,-1
}
    800057c4:	70ae                	ld	ra,232(sp)
    800057c6:	740e                	ld	s0,224(sp)
    800057c8:	64ee                	ld	s1,216(sp)
    800057ca:	694e                	ld	s2,208(sp)
    800057cc:	69ae                	ld	s3,200(sp)
    800057ce:	616d                	addi	sp,sp,240
    800057d0:	8082                	ret

00000000800057d2 <sys_open>:

uint64
sys_open(void)
{
    800057d2:	7131                	addi	sp,sp,-192
    800057d4:	fd06                	sd	ra,184(sp)
    800057d6:	f922                	sd	s0,176(sp)
    800057d8:	f526                	sd	s1,168(sp)
    800057da:	f14a                	sd	s2,160(sp)
    800057dc:	ed4e                	sd	s3,152(sp)
    800057de:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	f5040593          	addi	a1,s0,-176
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	546080e7          	jalr	1350(ra) # 80002d30 <argstr>
    return -1;
    800057f2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057f4:	0c054163          	bltz	a0,800058b6 <sys_open+0xe4>
    800057f8:	f4c40593          	addi	a1,s0,-180
    800057fc:	4505                	li	a0,1
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	4ee080e7          	jalr	1262(ra) # 80002cec <argint>
    80005806:	0a054863          	bltz	a0,800058b6 <sys_open+0xe4>

  begin_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	a26080e7          	jalr	-1498(ra) # 80004230 <begin_op>

  if(omode & O_CREATE){
    80005812:	f4c42783          	lw	a5,-180(s0)
    80005816:	2007f793          	andi	a5,a5,512
    8000581a:	cbdd                	beqz	a5,800058d0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000581c:	4681                	li	a3,0
    8000581e:	4601                	li	a2,0
    80005820:	4589                	li	a1,2
    80005822:	f5040513          	addi	a0,s0,-176
    80005826:	00000097          	auipc	ra,0x0
    8000582a:	972080e7          	jalr	-1678(ra) # 80005198 <create>
    8000582e:	892a                	mv	s2,a0
    if(ip == 0){
    80005830:	c959                	beqz	a0,800058c6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005832:	04491703          	lh	a4,68(s2)
    80005836:	478d                	li	a5,3
    80005838:	00f71763          	bne	a4,a5,80005846 <sys_open+0x74>
    8000583c:	04695703          	lhu	a4,70(s2)
    80005840:	47a5                	li	a5,9
    80005842:	0ce7ec63          	bltu	a5,a4,8000591a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	e02080e7          	jalr	-510(ra) # 80004648 <filealloc>
    8000584e:	89aa                	mv	s3,a0
    80005850:	10050263          	beqz	a0,80005954 <sys_open+0x182>
    80005854:	00000097          	auipc	ra,0x0
    80005858:	902080e7          	jalr	-1790(ra) # 80005156 <fdalloc>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	0e054663          	bltz	a0,8000594a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005862:	04491703          	lh	a4,68(s2)
    80005866:	478d                	li	a5,3
    80005868:	0cf70463          	beq	a4,a5,80005930 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000586c:	4789                	li	a5,2
    8000586e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005872:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005876:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000587a:	f4c42783          	lw	a5,-180(s0)
    8000587e:	0017c713          	xori	a4,a5,1
    80005882:	8b05                	andi	a4,a4,1
    80005884:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005888:	0037f713          	andi	a4,a5,3
    8000588c:	00e03733          	snez	a4,a4
    80005890:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005894:	4007f793          	andi	a5,a5,1024
    80005898:	c791                	beqz	a5,800058a4 <sys_open+0xd2>
    8000589a:	04491703          	lh	a4,68(s2)
    8000589e:	4789                	li	a5,2
    800058a0:	08f70f63          	beq	a4,a5,8000593e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	07a080e7          	jalr	122(ra) # 80003920 <iunlock>
  end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	a02080e7          	jalr	-1534(ra) # 800042b0 <end_op>

  return fd;
}
    800058b6:	8526                	mv	a0,s1
    800058b8:	70ea                	ld	ra,184(sp)
    800058ba:	744a                	ld	s0,176(sp)
    800058bc:	74aa                	ld	s1,168(sp)
    800058be:	790a                	ld	s2,160(sp)
    800058c0:	69ea                	ld	s3,152(sp)
    800058c2:	6129                	addi	sp,sp,192
    800058c4:	8082                	ret
      end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	9ea080e7          	jalr	-1558(ra) # 800042b0 <end_op>
      return -1;
    800058ce:	b7e5                	j	800058b6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058d0:	f5040513          	addi	a0,s0,-176
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	740080e7          	jalr	1856(ra) # 80004014 <namei>
    800058dc:	892a                	mv	s2,a0
    800058de:	c905                	beqz	a0,8000590e <sys_open+0x13c>
    ilock(ip);
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	f7e080e7          	jalr	-130(ra) # 8000385e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058e8:	04491703          	lh	a4,68(s2)
    800058ec:	4785                	li	a5,1
    800058ee:	f4f712e3          	bne	a4,a5,80005832 <sys_open+0x60>
    800058f2:	f4c42783          	lw	a5,-180(s0)
    800058f6:	dba1                	beqz	a5,80005846 <sys_open+0x74>
      iunlockput(ip);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	1c6080e7          	jalr	454(ra) # 80003ac0 <iunlockput>
      end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	9ae080e7          	jalr	-1618(ra) # 800042b0 <end_op>
      return -1;
    8000590a:	54fd                	li	s1,-1
    8000590c:	b76d                	j	800058b6 <sys_open+0xe4>
      end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	9a2080e7          	jalr	-1630(ra) # 800042b0 <end_op>
      return -1;
    80005916:	54fd                	li	s1,-1
    80005918:	bf79                	j	800058b6 <sys_open+0xe4>
    iunlockput(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	1a4080e7          	jalr	420(ra) # 80003ac0 <iunlockput>
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	98c080e7          	jalr	-1652(ra) # 800042b0 <end_op>
    return -1;
    8000592c:	54fd                	li	s1,-1
    8000592e:	b761                	j	800058b6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005930:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005934:	04691783          	lh	a5,70(s2)
    80005938:	02f99223          	sh	a5,36(s3)
    8000593c:	bf2d                	j	80005876 <sys_open+0xa4>
    itrunc(ip);
    8000593e:	854a                	mv	a0,s2
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	02c080e7          	jalr	44(ra) # 8000396c <itrunc>
    80005948:	bfb1                	j	800058a4 <sys_open+0xd2>
      fileclose(f);
    8000594a:	854e                	mv	a0,s3
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	db8080e7          	jalr	-584(ra) # 80004704 <fileclose>
    iunlockput(ip);
    80005954:	854a                	mv	a0,s2
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	16a080e7          	jalr	362(ra) # 80003ac0 <iunlockput>
    end_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	952080e7          	jalr	-1710(ra) # 800042b0 <end_op>
    return -1;
    80005966:	54fd                	li	s1,-1
    80005968:	b7b9                	j	800058b6 <sys_open+0xe4>

000000008000596a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000596a:	7175                	addi	sp,sp,-144
    8000596c:	e506                	sd	ra,136(sp)
    8000596e:	e122                	sd	s0,128(sp)
    80005970:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	8be080e7          	jalr	-1858(ra) # 80004230 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000597a:	08000613          	li	a2,128
    8000597e:	f7040593          	addi	a1,s0,-144
    80005982:	4501                	li	a0,0
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	3ac080e7          	jalr	940(ra) # 80002d30 <argstr>
    8000598c:	02054963          	bltz	a0,800059be <sys_mkdir+0x54>
    80005990:	4681                	li	a3,0
    80005992:	4601                	li	a2,0
    80005994:	4585                	li	a1,1
    80005996:	f7040513          	addi	a0,s0,-144
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	7fe080e7          	jalr	2046(ra) # 80005198 <create>
    800059a2:	cd11                	beqz	a0,800059be <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	11c080e7          	jalr	284(ra) # 80003ac0 <iunlockput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	904080e7          	jalr	-1788(ra) # 800042b0 <end_op>
  return 0;
    800059b4:	4501                	li	a0,0
}
    800059b6:	60aa                	ld	ra,136(sp)
    800059b8:	640a                	ld	s0,128(sp)
    800059ba:	6149                	addi	sp,sp,144
    800059bc:	8082                	ret
    end_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	8f2080e7          	jalr	-1806(ra) # 800042b0 <end_op>
    return -1;
    800059c6:	557d                	li	a0,-1
    800059c8:	b7fd                	j	800059b6 <sys_mkdir+0x4c>

00000000800059ca <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ca:	7135                	addi	sp,sp,-160
    800059cc:	ed06                	sd	ra,152(sp)
    800059ce:	e922                	sd	s0,144(sp)
    800059d0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	85e080e7          	jalr	-1954(ra) # 80004230 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059da:	08000613          	li	a2,128
    800059de:	f7040593          	addi	a1,s0,-144
    800059e2:	4501                	li	a0,0
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	34c080e7          	jalr	844(ra) # 80002d30 <argstr>
    800059ec:	04054a63          	bltz	a0,80005a40 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059f0:	f6c40593          	addi	a1,s0,-148
    800059f4:	4505                	li	a0,1
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	2f6080e7          	jalr	758(ra) # 80002cec <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059fe:	04054163          	bltz	a0,80005a40 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a02:	f6840593          	addi	a1,s0,-152
    80005a06:	4509                	li	a0,2
    80005a08:	ffffd097          	auipc	ra,0xffffd
    80005a0c:	2e4080e7          	jalr	740(ra) # 80002cec <argint>
     argint(1, &major) < 0 ||
    80005a10:	02054863          	bltz	a0,80005a40 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a14:	f6841683          	lh	a3,-152(s0)
    80005a18:	f6c41603          	lh	a2,-148(s0)
    80005a1c:	458d                	li	a1,3
    80005a1e:	f7040513          	addi	a0,s0,-144
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	776080e7          	jalr	1910(ra) # 80005198 <create>
     argint(2, &minor) < 0 ||
    80005a2a:	c919                	beqz	a0,80005a40 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	094080e7          	jalr	148(ra) # 80003ac0 <iunlockput>
  end_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	87c080e7          	jalr	-1924(ra) # 800042b0 <end_op>
  return 0;
    80005a3c:	4501                	li	a0,0
    80005a3e:	a031                	j	80005a4a <sys_mknod+0x80>
    end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	870080e7          	jalr	-1936(ra) # 800042b0 <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
}
    80005a4a:	60ea                	ld	ra,152(sp)
    80005a4c:	644a                	ld	s0,144(sp)
    80005a4e:	610d                	addi	sp,sp,160
    80005a50:	8082                	ret

0000000080005a52 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a52:	7135                	addi	sp,sp,-160
    80005a54:	ed06                	sd	ra,152(sp)
    80005a56:	e922                	sd	s0,144(sp)
    80005a58:	e526                	sd	s1,136(sp)
    80005a5a:	e14a                	sd	s2,128(sp)
    80005a5c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a5e:	ffffc097          	auipc	ra,0xffffc
    80005a62:	f48080e7          	jalr	-184(ra) # 800019a6 <myproc>
    80005a66:	892a                	mv	s2,a0
  
  begin_op();
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	7c8080e7          	jalr	1992(ra) # 80004230 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a70:	08000613          	li	a2,128
    80005a74:	f6040593          	addi	a1,s0,-160
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	2b6080e7          	jalr	694(ra) # 80002d30 <argstr>
    80005a82:	04054b63          	bltz	a0,80005ad8 <sys_chdir+0x86>
    80005a86:	f6040513          	addi	a0,s0,-160
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	58a080e7          	jalr	1418(ra) # 80004014 <namei>
    80005a92:	84aa                	mv	s1,a0
    80005a94:	c131                	beqz	a0,80005ad8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	dc8080e7          	jalr	-568(ra) # 8000385e <ilock>
  if(ip->type != T_DIR){
    80005a9e:	04449703          	lh	a4,68(s1)
    80005aa2:	4785                	li	a5,1
    80005aa4:	04f71063          	bne	a4,a5,80005ae4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	e76080e7          	jalr	-394(ra) # 80003920 <iunlock>
  iput(p->cwd);
    80005ab2:	15093503          	ld	a0,336(s2)
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	f62080e7          	jalr	-158(ra) # 80003a18 <iput>
  end_op();
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	7f2080e7          	jalr	2034(ra) # 800042b0 <end_op>
  p->cwd = ip;
    80005ac6:	14993823          	sd	s1,336(s2)
  return 0;
    80005aca:	4501                	li	a0,0
}
    80005acc:	60ea                	ld	ra,152(sp)
    80005ace:	644a                	ld	s0,144(sp)
    80005ad0:	64aa                	ld	s1,136(sp)
    80005ad2:	690a                	ld	s2,128(sp)
    80005ad4:	610d                	addi	sp,sp,160
    80005ad6:	8082                	ret
    end_op();
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	7d8080e7          	jalr	2008(ra) # 800042b0 <end_op>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	b7ed                	j	80005acc <sys_chdir+0x7a>
    iunlockput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	fda080e7          	jalr	-38(ra) # 80003ac0 <iunlockput>
    end_op();
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	7c2080e7          	jalr	1986(ra) # 800042b0 <end_op>
    return -1;
    80005af6:	557d                	li	a0,-1
    80005af8:	bfd1                	j	80005acc <sys_chdir+0x7a>

0000000080005afa <sys_exec>:

uint64
sys_exec(void)
{
    80005afa:	7145                	addi	sp,sp,-464
    80005afc:	e786                	sd	ra,456(sp)
    80005afe:	e3a2                	sd	s0,448(sp)
    80005b00:	ff26                	sd	s1,440(sp)
    80005b02:	fb4a                	sd	s2,432(sp)
    80005b04:	f74e                	sd	s3,424(sp)
    80005b06:	f352                	sd	s4,416(sp)
    80005b08:	ef56                	sd	s5,408(sp)
    80005b0a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b0c:	08000613          	li	a2,128
    80005b10:	f4040593          	addi	a1,s0,-192
    80005b14:	4501                	li	a0,0
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	21a080e7          	jalr	538(ra) # 80002d30 <argstr>
    return -1;
    80005b1e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b20:	0c054a63          	bltz	a0,80005bf4 <sys_exec+0xfa>
    80005b24:	e3840593          	addi	a1,s0,-456
    80005b28:	4505                	li	a0,1
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	1e4080e7          	jalr	484(ra) # 80002d0e <argaddr>
    80005b32:	0c054163          	bltz	a0,80005bf4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b36:	10000613          	li	a2,256
    80005b3a:	4581                	li	a1,0
    80005b3c:	e4040513          	addi	a0,s0,-448
    80005b40:	ffffb097          	auipc	ra,0xffffb
    80005b44:	192080e7          	jalr	402(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b48:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b4c:	89a6                	mv	s3,s1
    80005b4e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b50:	02000a13          	li	s4,32
    80005b54:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b58:	00391513          	slli	a0,s2,0x3
    80005b5c:	e3040593          	addi	a1,s0,-464
    80005b60:	e3843783          	ld	a5,-456(s0)
    80005b64:	953e                	add	a0,a0,a5
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	0ec080e7          	jalr	236(ra) # 80002c52 <fetchaddr>
    80005b6e:	02054a63          	bltz	a0,80005ba2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b72:	e3043783          	ld	a5,-464(s0)
    80005b76:	c3b9                	beqz	a5,80005bbc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	f6e080e7          	jalr	-146(ra) # 80000ae6 <kalloc>
    80005b80:	85aa                	mv	a1,a0
    80005b82:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b86:	cd11                	beqz	a0,80005ba2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b88:	6605                	lui	a2,0x1
    80005b8a:	e3043503          	ld	a0,-464(s0)
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	116080e7          	jalr	278(ra) # 80002ca4 <fetchstr>
    80005b96:	00054663          	bltz	a0,80005ba2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b9a:	0905                	addi	s2,s2,1
    80005b9c:	09a1                	addi	s3,s3,8
    80005b9e:	fb491be3          	bne	s2,s4,80005b54 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba2:	10048913          	addi	s2,s1,256
    80005ba6:	6088                	ld	a0,0(s1)
    80005ba8:	c529                	beqz	a0,80005bf2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	e40080e7          	jalr	-448(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb2:	04a1                	addi	s1,s1,8
    80005bb4:	ff2499e3          	bne	s1,s2,80005ba6 <sys_exec+0xac>
  return -1;
    80005bb8:	597d                	li	s2,-1
    80005bba:	a82d                	j	80005bf4 <sys_exec+0xfa>
      argv[i] = 0;
    80005bbc:	0a8e                	slli	s5,s5,0x3
    80005bbe:	fc040793          	addi	a5,s0,-64
    80005bc2:	9abe                	add	s5,s5,a5
    80005bc4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bc8:	e4040593          	addi	a1,s0,-448
    80005bcc:	f4040513          	addi	a0,s0,-192
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	194080e7          	jalr	404(ra) # 80004d64 <exec>
    80005bd8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bda:	10048993          	addi	s3,s1,256
    80005bde:	6088                	ld	a0,0(s1)
    80005be0:	c911                	beqz	a0,80005bf4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	e08080e7          	jalr	-504(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bea:	04a1                	addi	s1,s1,8
    80005bec:	ff3499e3          	bne	s1,s3,80005bde <sys_exec+0xe4>
    80005bf0:	a011                	j	80005bf4 <sys_exec+0xfa>
  return -1;
    80005bf2:	597d                	li	s2,-1
}
    80005bf4:	854a                	mv	a0,s2
    80005bf6:	60be                	ld	ra,456(sp)
    80005bf8:	641e                	ld	s0,448(sp)
    80005bfa:	74fa                	ld	s1,440(sp)
    80005bfc:	795a                	ld	s2,432(sp)
    80005bfe:	79ba                	ld	s3,424(sp)
    80005c00:	7a1a                	ld	s4,416(sp)
    80005c02:	6afa                	ld	s5,408(sp)
    80005c04:	6179                	addi	sp,sp,464
    80005c06:	8082                	ret

0000000080005c08 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c08:	7139                	addi	sp,sp,-64
    80005c0a:	fc06                	sd	ra,56(sp)
    80005c0c:	f822                	sd	s0,48(sp)
    80005c0e:	f426                	sd	s1,40(sp)
    80005c10:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c12:	ffffc097          	auipc	ra,0xffffc
    80005c16:	d94080e7          	jalr	-620(ra) # 800019a6 <myproc>
    80005c1a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c1c:	fd840593          	addi	a1,s0,-40
    80005c20:	4501                	li	a0,0
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	0ec080e7          	jalr	236(ra) # 80002d0e <argaddr>
    return -1;
    80005c2a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c2c:	0e054063          	bltz	a0,80005d0c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c30:	fc840593          	addi	a1,s0,-56
    80005c34:	fd040513          	addi	a0,s0,-48
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	dfc080e7          	jalr	-516(ra) # 80004a34 <pipealloc>
    return -1;
    80005c40:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c42:	0c054563          	bltz	a0,80005d0c <sys_pipe+0x104>
  fd0 = -1;
    80005c46:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c4a:	fd043503          	ld	a0,-48(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	508080e7          	jalr	1288(ra) # 80005156 <fdalloc>
    80005c56:	fca42223          	sw	a0,-60(s0)
    80005c5a:	08054c63          	bltz	a0,80005cf2 <sys_pipe+0xea>
    80005c5e:	fc843503          	ld	a0,-56(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	4f4080e7          	jalr	1268(ra) # 80005156 <fdalloc>
    80005c6a:	fca42023          	sw	a0,-64(s0)
    80005c6e:	06054863          	bltz	a0,80005cde <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c72:	4691                	li	a3,4
    80005c74:	fc440613          	addi	a2,s0,-60
    80005c78:	fd843583          	ld	a1,-40(s0)
    80005c7c:	68a8                	ld	a0,80(s1)
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	9be080e7          	jalr	-1602(ra) # 8000163c <copyout>
    80005c86:	02054063          	bltz	a0,80005ca6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c8a:	4691                	li	a3,4
    80005c8c:	fc040613          	addi	a2,s0,-64
    80005c90:	fd843583          	ld	a1,-40(s0)
    80005c94:	0591                	addi	a1,a1,4
    80005c96:	68a8                	ld	a0,80(s1)
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	9a4080e7          	jalr	-1628(ra) # 8000163c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ca0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca2:	06055563          	bgez	a0,80005d0c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ca6:	fc442783          	lw	a5,-60(s0)
    80005caa:	07e9                	addi	a5,a5,26
    80005cac:	078e                	slli	a5,a5,0x3
    80005cae:	97a6                	add	a5,a5,s1
    80005cb0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cb4:	fc042503          	lw	a0,-64(s0)
    80005cb8:	0569                	addi	a0,a0,26
    80005cba:	050e                	slli	a0,a0,0x3
    80005cbc:	9526                	add	a0,a0,s1
    80005cbe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cc2:	fd043503          	ld	a0,-48(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	a3e080e7          	jalr	-1474(ra) # 80004704 <fileclose>
    fileclose(wf);
    80005cce:	fc843503          	ld	a0,-56(s0)
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	a32080e7          	jalr	-1486(ra) # 80004704 <fileclose>
    return -1;
    80005cda:	57fd                	li	a5,-1
    80005cdc:	a805                	j	80005d0c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cde:	fc442783          	lw	a5,-60(s0)
    80005ce2:	0007c863          	bltz	a5,80005cf2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ce6:	01a78513          	addi	a0,a5,26
    80005cea:	050e                	slli	a0,a0,0x3
    80005cec:	9526                	add	a0,a0,s1
    80005cee:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cf2:	fd043503          	ld	a0,-48(s0)
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	a0e080e7          	jalr	-1522(ra) # 80004704 <fileclose>
    fileclose(wf);
    80005cfe:	fc843503          	ld	a0,-56(s0)
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	a02080e7          	jalr	-1534(ra) # 80004704 <fileclose>
    return -1;
    80005d0a:	57fd                	li	a5,-1
}
    80005d0c:	853e                	mv	a0,a5
    80005d0e:	70e2                	ld	ra,56(sp)
    80005d10:	7442                	ld	s0,48(sp)
    80005d12:	74a2                	ld	s1,40(sp)
    80005d14:	6121                	addi	sp,sp,64
    80005d16:	8082                	ret

0000000080005d18 <sys_mmap>:
uint64
sys_mmap(void) {
    80005d18:	711d                	addi	sp,sp,-96
    80005d1a:	ec86                	sd	ra,88(sp)
    80005d1c:	e8a2                	sd	s0,80(sp)
    80005d1e:	e4a6                	sd	s1,72(sp)
    80005d20:	e0ca                	sd	s2,64(sp)
    80005d22:	fc4e                	sd	s3,56(sp)
    80005d24:	1080                	addi	s0,sp,96
  struct file* vfile;
  int offset;
  uint64 err = 0xffffffffffffffff;

  // 获取系统调用参数
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 ||
    80005d26:	fc840593          	addi	a1,s0,-56
    80005d2a:	4501                	li	a0,0
    80005d2c:	ffffd097          	auipc	ra,0xffffd
    80005d30:	fe2080e7          	jalr	-30(ra) # 80002d0e <argaddr>
    argint(3, &flags) < 0 || argfd(4, &vfd, &vfile) < 0 || argint(5, &offset) < 0)
    return err;
    80005d34:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 ||
    80005d36:	12054c63          	bltz	a0,80005e6e <sys_mmap+0x156>
    80005d3a:	fc440593          	addi	a1,s0,-60
    80005d3e:	4505                	li	a0,1
    80005d40:	ffffd097          	auipc	ra,0xffffd
    80005d44:	fac080e7          	jalr	-84(ra) # 80002cec <argint>
    return err;
    80005d48:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 ||
    80005d4a:	12054263          	bltz	a0,80005e6e <sys_mmap+0x156>
    80005d4e:	fc040593          	addi	a1,s0,-64
    80005d52:	4509                	li	a0,2
    80005d54:	ffffd097          	auipc	ra,0xffffd
    80005d58:	f98080e7          	jalr	-104(ra) # 80002cec <argint>
    return err;
    80005d5c:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 ||
    80005d5e:	10054863          	bltz	a0,80005e6e <sys_mmap+0x156>
    argint(3, &flags) < 0 || argfd(4, &vfd, &vfile) < 0 || argint(5, &offset) < 0)
    80005d62:	fbc40593          	addi	a1,s0,-68
    80005d66:	450d                	li	a0,3
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	f84080e7          	jalr	-124(ra) # 80002cec <argint>
    return err;
    80005d70:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 ||
    80005d72:	0e054e63          	bltz	a0,80005e6e <sys_mmap+0x156>
    argint(3, &flags) < 0 || argfd(4, &vfd, &vfile) < 0 || argint(5, &offset) < 0)
    80005d76:	fb040613          	addi	a2,s0,-80
    80005d7a:	fb840593          	addi	a1,s0,-72
    80005d7e:	4511                	li	a0,4
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	36e080e7          	jalr	878(ra) # 800050ee <argfd>
    return err;
    80005d88:	57fd                	li	a5,-1
    argint(3, &flags) < 0 || argfd(4, &vfd, &vfile) < 0 || argint(5, &offset) < 0)
    80005d8a:	0e054263          	bltz	a0,80005e6e <sys_mmap+0x156>
    80005d8e:	fac40593          	addi	a1,s0,-84
    80005d92:	4515                	li	a0,5
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	f58080e7          	jalr	-168(ra) # 80002cec <argint>
    80005d9c:	0c054863          	bltz	a0,80005e6c <sys_mmap+0x154>

  // 实验提示中假定addr和offset为0，简化程序可能发生的情况
  if(addr != 0 || offset != 0 || length < 0)
    80005da0:	fc843703          	ld	a4,-56(s0)
    return err;
    80005da4:	57fd                	li	a5,-1
  if(addr != 0 || offset != 0 || length < 0)
    80005da6:	e761                	bnez	a4,80005e6e <sys_mmap+0x156>
    80005da8:	fac42483          	lw	s1,-84(s0)
    80005dac:	e0e9                	bnez	s1,80005e6e <sys_mmap+0x156>
    80005dae:	fc442783          	lw	a5,-60(s0)
    80005db2:	0c07c663          	bltz	a5,80005e7e <sys_mmap+0x166>

  // 文件不可写则不允许拥有PROT_WRITE权限时映射为MAP_SHARED
  if(vfile->writable == 0 && (prot & PROT_WRITE) != 0 && flags == MAP_SHARED)
    80005db6:	fb043783          	ld	a5,-80(s0)
    80005dba:	0097c783          	lbu	a5,9(a5)
    80005dbe:	eb91                	bnez	a5,80005dd2 <sys_mmap+0xba>
    80005dc0:	fc042783          	lw	a5,-64(s0)
    80005dc4:	8b89                	andi	a5,a5,2
    80005dc6:	c791                	beqz	a5,80005dd2 <sys_mmap+0xba>
    80005dc8:	fbc42703          	lw	a4,-68(s0)
    80005dcc:	4785                	li	a5,1
    80005dce:	0af70a63          	beq	a4,a5,80005e82 <sys_mmap+0x16a>
    return err;

  struct proc* p = myproc();
    80005dd2:	ffffc097          	auipc	ra,0xffffc
    80005dd6:	bd4080e7          	jalr	-1068(ra) # 800019a6 <myproc>
    80005dda:	892a                	mv	s2,a0
  // 没有足够的虚拟地址空间
  if(p->sz + length > MAXVA)
    80005ddc:	652c                	ld	a1,72(a0)
    80005dde:	fc442603          	lw	a2,-60(s0)
    80005de2:	00b606b3          	add	a3,a2,a1
    80005de6:	4705                	li	a4,1
    80005de8:	171a                	slli	a4,a4,0x26
    return err;
    80005dea:	57fd                	li	a5,-1
  if(p->sz + length > MAXVA)
    80005dec:	08d76163          	bltu	a4,a3,80005e6e <sys_mmap+0x156>
    80005df0:	16850793          	addi	a5,a0,360

  // 遍历查找未使用的VMA结构体
  for(int i = 0; i < NVMA; ++i) {
    80005df4:	46c1                	li	a3,16
    if(p->vma[i].used == 0) {
    80005df6:	4398                	lw	a4,0(a5)
    80005df8:	cb01                	beqz	a4,80005e08 <sys_mmap+0xf0>
  for(int i = 0; i < NVMA; ++i) {
    80005dfa:	2485                	addiw	s1,s1,1
    80005dfc:	03078793          	addi	a5,a5,48
    80005e00:	fed49be3          	bne	s1,a3,80005df6 <sys_mmap+0xde>
      p->sz += length;
      return p->vma[i].addr;
    }
  }

  return err;
    80005e04:	57fd                	li	a5,-1
    80005e06:	a0a5                	j	80005e6e <sys_mmap+0x156>
      p->vma[i].used = 1;
    80005e08:	00149993          	slli	s3,s1,0x1
    80005e0c:	009987b3          	add	a5,s3,s1
    80005e10:	0792                	slli	a5,a5,0x4
    80005e12:	97ca                	add	a5,a5,s2
    80005e14:	4705                	li	a4,1
    80005e16:	16e7a423          	sw	a4,360(a5)
      p->vma[i].addr = p->sz;
    80005e1a:	16b7b823          	sd	a1,368(a5)
      p->vma[i].len = length;
    80005e1e:	16c7ac23          	sw	a2,376(a5)
      p->vma[i].flags = flags;
    80005e22:	fbc42703          	lw	a4,-68(s0)
    80005e26:	18e7a023          	sw	a4,384(a5)
      p->vma[i].prot = prot;
    80005e2a:	fc042703          	lw	a4,-64(s0)
    80005e2e:	16e7ae23          	sw	a4,380(a5)
      p->vma[i].vfile = vfile;
    80005e32:	fb043503          	ld	a0,-80(s0)
    80005e36:	18a7b423          	sd	a0,392(a5)
      p->vma[i].vfd = vfd;
    80005e3a:	fb842703          	lw	a4,-72(s0)
    80005e3e:	18e7a223          	sw	a4,388(a5)
      p->vma[i].offset = offset;
    80005e42:	fac42703          	lw	a4,-84(s0)
    80005e46:	18e7a823          	sw	a4,400(a5)
      filedup(vfile);
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	868080e7          	jalr	-1944(ra) # 800046b2 <filedup>
      p->sz += length;
    80005e52:	fc442703          	lw	a4,-60(s0)
    80005e56:	04893783          	ld	a5,72(s2)
    80005e5a:	97ba                	add	a5,a5,a4
    80005e5c:	04f93423          	sd	a5,72(s2)
      return p->vma[i].addr;
    80005e60:	94ce                	add	s1,s1,s3
    80005e62:	0492                	slli	s1,s1,0x4
    80005e64:	9926                	add	s2,s2,s1
    80005e66:	17093783          	ld	a5,368(s2)
    80005e6a:	a011                	j	80005e6e <sys_mmap+0x156>
    return err;
    80005e6c:	57fd                	li	a5,-1
}
    80005e6e:	853e                	mv	a0,a5
    80005e70:	60e6                	ld	ra,88(sp)
    80005e72:	6446                	ld	s0,80(sp)
    80005e74:	64a6                	ld	s1,72(sp)
    80005e76:	6906                	ld	s2,64(sp)
    80005e78:	79e2                	ld	s3,56(sp)
    80005e7a:	6125                	addi	sp,sp,96
    80005e7c:	8082                	ret
    return err;
    80005e7e:	57fd                	li	a5,-1
    80005e80:	b7fd                	j	80005e6e <sys_mmap+0x156>
    return err;
    80005e82:	57fd                	li	a5,-1
    80005e84:	b7ed                	j	80005e6e <sys_mmap+0x156>

0000000080005e86 <sys_munmap>:

uint64
sys_munmap(void) {
    80005e86:	7139                	addi	sp,sp,-64
    80005e88:	fc06                	sd	ra,56(sp)
    80005e8a:	f822                	sd	s0,48(sp)
    80005e8c:	f426                	sd	s1,40(sp)
    80005e8e:	f04a                	sd	s2,32(sp)
    80005e90:	ec4e                	sd	s3,24(sp)
    80005e92:	0080                	addi	s0,sp,64
  uint64 addr;
  int length;
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0)
    80005e94:	fc840593          	addi	a1,s0,-56
    80005e98:	4501                	li	a0,0
    80005e9a:	ffffd097          	auipc	ra,0xffffd
    80005e9e:	e74080e7          	jalr	-396(ra) # 80002d0e <argaddr>
    return -1;
    80005ea2:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0)
    80005ea4:	0e054d63          	bltz	a0,80005f9e <sys_munmap+0x118>
    80005ea8:	fc440593          	addi	a1,s0,-60
    80005eac:	4505                	li	a0,1
    80005eae:	ffffd097          	auipc	ra,0xffffd
    80005eb2:	e3e080e7          	jalr	-450(ra) # 80002cec <argint>
    return -1;
    80005eb6:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0 || argint(1, &length) < 0)
    80005eb8:	0e054363          	bltz	a0,80005f9e <sys_munmap+0x118>

  int i;
  struct proc* p = myproc();
    80005ebc:	ffffc097          	auipc	ra,0xffffc
    80005ec0:	aea080e7          	jalr	-1302(ra) # 800019a6 <myproc>
    80005ec4:	892a                	mv	s2,a0
  for(i = 0; i < NVMA; ++i) {
    if(p->vma[i].used && p->vma[i].len >= length) {
    80005ec6:	fc442603          	lw	a2,-60(s0)
      // 根据提示，munmap的地址范围只能是
      // 1. 起始位置
      if(p->vma[i].addr == addr) {
    80005eca:	fc843583          	ld	a1,-56(s0)
        p->vma[i].addr += length;
        p->vma[i].len -= length;
        break;
      }
      // 2. 结束位置
      if(addr + length == p->vma[i].addr + p->vma[i].len) {
    80005ece:	00b60533          	add	a0,a2,a1
    80005ed2:	16890793          	addi	a5,s2,360
  for(i = 0; i < NVMA; ++i) {
    80005ed6:	4481                	li	s1,0
    80005ed8:	4841                	li	a6,16
    80005eda:	a869                	j	80005f74 <sys_munmap+0xee>
        p->vma[i].addr += length;
    80005edc:	00149793          	slli	a5,s1,0x1
    80005ee0:	97a6                	add	a5,a5,s1
    80005ee2:	0792                	slli	a5,a5,0x4
    80005ee4:	97ca                	add	a5,a5,s2
    80005ee6:	16a7b823          	sd	a0,368(a5)
        p->vma[i].len -= length;
    80005eea:	1787a703          	lw	a4,376(a5)
    80005eee:	9f11                	subw	a4,a4,a2
    80005ef0:	16e7ac23          	sw	a4,376(a5)
        p->vma[i].len -= length;
        break;
      }
    }
  }
  if(i == NVMA)
    80005ef4:	47c1                	li	a5,16
    80005ef6:	0ef48163          	beq	s1,a5,80005fd8 <sys_munmap+0x152>
    return -1;

  // 将MAP_SHARED页面写回文件系统
  if(p->vma[i].flags == MAP_SHARED && (p->vma[i].prot & PROT_WRITE) != 0) {
    80005efa:	00149793          	slli	a5,s1,0x1
    80005efe:	97a6                	add	a5,a5,s1
    80005f00:	0792                	slli	a5,a5,0x4
    80005f02:	97ca                	add	a5,a5,s2
    80005f04:	1807a703          	lw	a4,384(a5)
    80005f08:	4785                	li	a5,1
    80005f0a:	0af70263          	beq	a4,a5,80005fae <sys_munmap+0x128>
    filewrite(p->vma[i].vfile, addr, length);
  }

  // 判断此页面是否存在映射
  uvmunmap(p->pagetable, addr, length / PGSIZE, 1);
    80005f0e:	fc442783          	lw	a5,-60(s0)
    80005f12:	41f7d61b          	sraiw	a2,a5,0x1f
    80005f16:	0146561b          	srliw	a2,a2,0x14
    80005f1a:	9e3d                	addw	a2,a2,a5
    80005f1c:	4685                	li	a3,1
    80005f1e:	40c6561b          	sraiw	a2,a2,0xc
    80005f22:	fc843583          	ld	a1,-56(s0)
    80005f26:	05093503          	ld	a0,80(s2)
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	330080e7          	jalr	816(ra) # 8000125a <uvmunmap>


  // 当前VMA中全部映射都被取消
  if(p->vma[i].len == 0) {
    80005f32:	00149793          	slli	a5,s1,0x1
    80005f36:	97a6                	add	a5,a5,s1
    80005f38:	0792                	slli	a5,a5,0x4
    80005f3a:	97ca                	add	a5,a5,s2
    80005f3c:	1787a703          	lw	a4,376(a5)
    fileclose(p->vma[i].vfile);
    p->vma[i].used = 0;
  }

  return 0;
    80005f40:	4781                	li	a5,0
  if(p->vma[i].len == 0) {
    80005f42:	ef31                	bnez	a4,80005f9e <sys_munmap+0x118>
    fileclose(p->vma[i].vfile);
    80005f44:	00149993          	slli	s3,s1,0x1
    80005f48:	009987b3          	add	a5,s3,s1
    80005f4c:	0792                	slli	a5,a5,0x4
    80005f4e:	97ca                	add	a5,a5,s2
    80005f50:	1887b503          	ld	a0,392(a5)
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	7b0080e7          	jalr	1968(ra) # 80004704 <fileclose>
    p->vma[i].used = 0;
    80005f5c:	94ce                	add	s1,s1,s3
    80005f5e:	0492                	slli	s1,s1,0x4
    80005f60:	9926                	add	s2,s2,s1
    80005f62:	16092423          	sw	zero,360(s2)
  return 0;
    80005f66:	4781                	li	a5,0
    80005f68:	a81d                	j	80005f9e <sys_munmap+0x118>
  for(i = 0; i < NVMA; ++i) {
    80005f6a:	2485                	addiw	s1,s1,1
    80005f6c:	03078793          	addi	a5,a5,48
    80005f70:	03048663          	beq	s1,a6,80005f9c <sys_munmap+0x116>
    if(p->vma[i].used && p->vma[i].len >= length) {
    80005f74:	4398                	lw	a4,0(a5)
    80005f76:	db75                	beqz	a4,80005f6a <sys_munmap+0xe4>
    80005f78:	4b98                	lw	a4,16(a5)
    80005f7a:	fec748e3          	blt	a4,a2,80005f6a <sys_munmap+0xe4>
      if(p->vma[i].addr == addr) {
    80005f7e:	6794                	ld	a3,8(a5)
    80005f80:	f4b68ee3          	beq	a3,a1,80005edc <sys_munmap+0x56>
      if(addr + length == p->vma[i].addr + p->vma[i].len) {
    80005f84:	96ba                	add	a3,a3,a4
    80005f86:	fed512e3          	bne	a0,a3,80005f6a <sys_munmap+0xe4>
        p->vma[i].len -= length;
    80005f8a:	00149793          	slli	a5,s1,0x1
    80005f8e:	97a6                	add	a5,a5,s1
    80005f90:	0792                	slli	a5,a5,0x4
    80005f92:	97ca                	add	a5,a5,s2
    80005f94:	9f11                	subw	a4,a4,a2
    80005f96:	16e7ac23          	sw	a4,376(a5)
        break;
    80005f9a:	bfa9                	j	80005ef4 <sys_munmap+0x6e>
    return -1;
    80005f9c:	57fd                	li	a5,-1
}
    80005f9e:	853e                	mv	a0,a5
    80005fa0:	70e2                	ld	ra,56(sp)
    80005fa2:	7442                	ld	s0,48(sp)
    80005fa4:	74a2                	ld	s1,40(sp)
    80005fa6:	7902                	ld	s2,32(sp)
    80005fa8:	69e2                	ld	s3,24(sp)
    80005faa:	6121                	addi	sp,sp,64
    80005fac:	8082                	ret
  if(p->vma[i].flags == MAP_SHARED && (p->vma[i].prot & PROT_WRITE) != 0) {
    80005fae:	00149793          	slli	a5,s1,0x1
    80005fb2:	97a6                	add	a5,a5,s1
    80005fb4:	0792                	slli	a5,a5,0x4
    80005fb6:	97ca                	add	a5,a5,s2
    80005fb8:	17c7a783          	lw	a5,380(a5)
    80005fbc:	8b89                	andi	a5,a5,2
    80005fbe:	dba1                	beqz	a5,80005f0e <sys_munmap+0x88>
    filewrite(p->vma[i].vfile, addr, length);
    80005fc0:	00149793          	slli	a5,s1,0x1
    80005fc4:	97a6                	add	a5,a5,s1
    80005fc6:	0792                	slli	a5,a5,0x4
    80005fc8:	97ca                	add	a5,a5,s2
    80005fca:	1887b503          	ld	a0,392(a5)
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	932080e7          	jalr	-1742(ra) # 80004900 <filewrite>
    80005fd6:	bf25                	j	80005f0e <sys_munmap+0x88>
    return -1;
    80005fd8:	57fd                	li	a5,-1
    80005fda:	b7d1                	j	80005f9e <sys_munmap+0x118>
    80005fdc:	0000                	unimp
	...

0000000080005fe0 <kernelvec>:
    80005fe0:	7111                	addi	sp,sp,-256
    80005fe2:	e006                	sd	ra,0(sp)
    80005fe4:	e40a                	sd	sp,8(sp)
    80005fe6:	e80e                	sd	gp,16(sp)
    80005fe8:	ec12                	sd	tp,24(sp)
    80005fea:	f016                	sd	t0,32(sp)
    80005fec:	f41a                	sd	t1,40(sp)
    80005fee:	f81e                	sd	t2,48(sp)
    80005ff0:	fc22                	sd	s0,56(sp)
    80005ff2:	e0a6                	sd	s1,64(sp)
    80005ff4:	e4aa                	sd	a0,72(sp)
    80005ff6:	e8ae                	sd	a1,80(sp)
    80005ff8:	ecb2                	sd	a2,88(sp)
    80005ffa:	f0b6                	sd	a3,96(sp)
    80005ffc:	f4ba                	sd	a4,104(sp)
    80005ffe:	f8be                	sd	a5,112(sp)
    80006000:	fcc2                	sd	a6,120(sp)
    80006002:	e146                	sd	a7,128(sp)
    80006004:	e54a                	sd	s2,136(sp)
    80006006:	e94e                	sd	s3,144(sp)
    80006008:	ed52                	sd	s4,152(sp)
    8000600a:	f156                	sd	s5,160(sp)
    8000600c:	f55a                	sd	s6,168(sp)
    8000600e:	f95e                	sd	s7,176(sp)
    80006010:	fd62                	sd	s8,184(sp)
    80006012:	e1e6                	sd	s9,192(sp)
    80006014:	e5ea                	sd	s10,200(sp)
    80006016:	e9ee                	sd	s11,208(sp)
    80006018:	edf2                	sd	t3,216(sp)
    8000601a:	f1f6                	sd	t4,224(sp)
    8000601c:	f5fa                	sd	t5,232(sp)
    8000601e:	f9fe                	sd	t6,240(sp)
    80006020:	afffc0ef          	jal	ra,80002b1e <kerneltrap>
    80006024:	6082                	ld	ra,0(sp)
    80006026:	6122                	ld	sp,8(sp)
    80006028:	61c2                	ld	gp,16(sp)
    8000602a:	7282                	ld	t0,32(sp)
    8000602c:	7322                	ld	t1,40(sp)
    8000602e:	73c2                	ld	t2,48(sp)
    80006030:	7462                	ld	s0,56(sp)
    80006032:	6486                	ld	s1,64(sp)
    80006034:	6526                	ld	a0,72(sp)
    80006036:	65c6                	ld	a1,80(sp)
    80006038:	6666                	ld	a2,88(sp)
    8000603a:	7686                	ld	a3,96(sp)
    8000603c:	7726                	ld	a4,104(sp)
    8000603e:	77c6                	ld	a5,112(sp)
    80006040:	7866                	ld	a6,120(sp)
    80006042:	688a                	ld	a7,128(sp)
    80006044:	692a                	ld	s2,136(sp)
    80006046:	69ca                	ld	s3,144(sp)
    80006048:	6a6a                	ld	s4,152(sp)
    8000604a:	7a8a                	ld	s5,160(sp)
    8000604c:	7b2a                	ld	s6,168(sp)
    8000604e:	7bca                	ld	s7,176(sp)
    80006050:	7c6a                	ld	s8,184(sp)
    80006052:	6c8e                	ld	s9,192(sp)
    80006054:	6d2e                	ld	s10,200(sp)
    80006056:	6dce                	ld	s11,208(sp)
    80006058:	6e6e                	ld	t3,216(sp)
    8000605a:	7e8e                	ld	t4,224(sp)
    8000605c:	7f2e                	ld	t5,232(sp)
    8000605e:	7fce                	ld	t6,240(sp)
    80006060:	6111                	addi	sp,sp,256
    80006062:	10200073          	sret
    80006066:	00000013          	nop
    8000606a:	00000013          	nop
    8000606e:	0001                	nop

0000000080006070 <timervec>:
    80006070:	34051573          	csrrw	a0,mscratch,a0
    80006074:	e10c                	sd	a1,0(a0)
    80006076:	e510                	sd	a2,8(a0)
    80006078:	e914                	sd	a3,16(a0)
    8000607a:	6d0c                	ld	a1,24(a0)
    8000607c:	7110                	ld	a2,32(a0)
    8000607e:	6194                	ld	a3,0(a1)
    80006080:	96b2                	add	a3,a3,a2
    80006082:	e194                	sd	a3,0(a1)
    80006084:	4589                	li	a1,2
    80006086:	14459073          	csrw	sip,a1
    8000608a:	6914                	ld	a3,16(a0)
    8000608c:	6510                	ld	a2,8(a0)
    8000608e:	610c                	ld	a1,0(a0)
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	30200073          	mret
	...

000000008000609a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000609a:	1141                	addi	sp,sp,-16
    8000609c:	e422                	sd	s0,8(sp)
    8000609e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060a0:	0c0007b7          	lui	a5,0xc000
    800060a4:	4705                	li	a4,1
    800060a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060a8:	c3d8                	sw	a4,4(a5)
}
    800060aa:	6422                	ld	s0,8(sp)
    800060ac:	0141                	addi	sp,sp,16
    800060ae:	8082                	ret

00000000800060b0 <plicinithart>:

void
plicinithart(void)
{
    800060b0:	1141                	addi	sp,sp,-16
    800060b2:	e406                	sd	ra,8(sp)
    800060b4:	e022                	sd	s0,0(sp)
    800060b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	8c2080e7          	jalr	-1854(ra) # 8000197a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060c0:	0085171b          	slliw	a4,a0,0x8
    800060c4:	0c0027b7          	lui	a5,0xc002
    800060c8:	97ba                	add	a5,a5,a4
    800060ca:	40200713          	li	a4,1026
    800060ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060d2:	00d5151b          	slliw	a0,a0,0xd
    800060d6:	0c2017b7          	lui	a5,0xc201
    800060da:	953e                	add	a0,a0,a5
    800060dc:	00052023          	sw	zero,0(a0)
}
    800060e0:	60a2                	ld	ra,8(sp)
    800060e2:	6402                	ld	s0,0(sp)
    800060e4:	0141                	addi	sp,sp,16
    800060e6:	8082                	ret

00000000800060e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060e8:	1141                	addi	sp,sp,-16
    800060ea:	e406                	sd	ra,8(sp)
    800060ec:	e022                	sd	s0,0(sp)
    800060ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f0:	ffffc097          	auipc	ra,0xffffc
    800060f4:	88a080e7          	jalr	-1910(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060f8:	00d5179b          	slliw	a5,a0,0xd
    800060fc:	0c201537          	lui	a0,0xc201
    80006100:	953e                	add	a0,a0,a5
  return irq;
}
    80006102:	4148                	lw	a0,4(a0)
    80006104:	60a2                	ld	ra,8(sp)
    80006106:	6402                	ld	s0,0(sp)
    80006108:	0141                	addi	sp,sp,16
    8000610a:	8082                	ret

000000008000610c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000610c:	1101                	addi	sp,sp,-32
    8000610e:	ec06                	sd	ra,24(sp)
    80006110:	e822                	sd	s0,16(sp)
    80006112:	e426                	sd	s1,8(sp)
    80006114:	1000                	addi	s0,sp,32
    80006116:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	862080e7          	jalr	-1950(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006120:	00d5151b          	slliw	a0,a0,0xd
    80006124:	0c2017b7          	lui	a5,0xc201
    80006128:	97aa                	add	a5,a5,a0
    8000612a:	c3c4                	sw	s1,4(a5)
}
    8000612c:	60e2                	ld	ra,24(sp)
    8000612e:	6442                	ld	s0,16(sp)
    80006130:	64a2                	ld	s1,8(sp)
    80006132:	6105                	addi	sp,sp,32
    80006134:	8082                	ret

0000000080006136 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006136:	1141                	addi	sp,sp,-16
    80006138:	e406                	sd	ra,8(sp)
    8000613a:	e022                	sd	s0,0(sp)
    8000613c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000613e:	479d                	li	a5,7
    80006140:	06a7c963          	blt	a5,a0,800061b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006144:	00029797          	auipc	a5,0x29
    80006148:	ebc78793          	addi	a5,a5,-324 # 8002f000 <disk>
    8000614c:	00a78733          	add	a4,a5,a0
    80006150:	6789                	lui	a5,0x2
    80006152:	97ba                	add	a5,a5,a4
    80006154:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006158:	e7ad                	bnez	a5,800061c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000615a:	00451793          	slli	a5,a0,0x4
    8000615e:	0002b717          	auipc	a4,0x2b
    80006162:	ea270713          	addi	a4,a4,-350 # 80031000 <disk+0x2000>
    80006166:	6314                	ld	a3,0(a4)
    80006168:	96be                	add	a3,a3,a5
    8000616a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000616e:	6314                	ld	a3,0(a4)
    80006170:	96be                	add	a3,a3,a5
    80006172:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006176:	6314                	ld	a3,0(a4)
    80006178:	96be                	add	a3,a3,a5
    8000617a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000617e:	6318                	ld	a4,0(a4)
    80006180:	97ba                	add	a5,a5,a4
    80006182:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006186:	00029797          	auipc	a5,0x29
    8000618a:	e7a78793          	addi	a5,a5,-390 # 8002f000 <disk>
    8000618e:	97aa                	add	a5,a5,a0
    80006190:	6509                	lui	a0,0x2
    80006192:	953e                	add	a0,a0,a5
    80006194:	4785                	li	a5,1
    80006196:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000619a:	0002b517          	auipc	a0,0x2b
    8000619e:	e7e50513          	addi	a0,a0,-386 # 80031018 <disk+0x2018>
    800061a2:	ffffc097          	auipc	ra,0xffffc
    800061a6:	25a080e7          	jalr	602(ra) # 800023fc <wakeup>
}
    800061aa:	60a2                	ld	ra,8(sp)
    800061ac:	6402                	ld	s0,0(sp)
    800061ae:	0141                	addi	sp,sp,16
    800061b0:	8082                	ret
    panic("free_desc 1");
    800061b2:	00002517          	auipc	a0,0x2
    800061b6:	56650513          	addi	a0,a0,1382 # 80008718 <syscalls+0x330>
    800061ba:	ffffa097          	auipc	ra,0xffffa
    800061be:	376080e7          	jalr	886(ra) # 80000530 <panic>
    panic("free_desc 2");
    800061c2:	00002517          	auipc	a0,0x2
    800061c6:	56650513          	addi	a0,a0,1382 # 80008728 <syscalls+0x340>
    800061ca:	ffffa097          	auipc	ra,0xffffa
    800061ce:	366080e7          	jalr	870(ra) # 80000530 <panic>

00000000800061d2 <virtio_disk_init>:
{
    800061d2:	1101                	addi	sp,sp,-32
    800061d4:	ec06                	sd	ra,24(sp)
    800061d6:	e822                	sd	s0,16(sp)
    800061d8:	e426                	sd	s1,8(sp)
    800061da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061dc:	00002597          	auipc	a1,0x2
    800061e0:	55c58593          	addi	a1,a1,1372 # 80008738 <syscalls+0x350>
    800061e4:	0002b517          	auipc	a0,0x2b
    800061e8:	f4450513          	addi	a0,a0,-188 # 80031128 <disk+0x2128>
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	95a080e7          	jalr	-1702(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061f4:	100017b7          	lui	a5,0x10001
    800061f8:	4398                	lw	a4,0(a5)
    800061fa:	2701                	sext.w	a4,a4
    800061fc:	747277b7          	lui	a5,0x74727
    80006200:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006204:	0ef71163          	bne	a4,a5,800062e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006208:	100017b7          	lui	a5,0x10001
    8000620c:	43dc                	lw	a5,4(a5)
    8000620e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006210:	4705                	li	a4,1
    80006212:	0ce79a63          	bne	a5,a4,800062e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006216:	100017b7          	lui	a5,0x10001
    8000621a:	479c                	lw	a5,8(a5)
    8000621c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000621e:	4709                	li	a4,2
    80006220:	0ce79363          	bne	a5,a4,800062e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006224:	100017b7          	lui	a5,0x10001
    80006228:	47d8                	lw	a4,12(a5)
    8000622a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000622c:	554d47b7          	lui	a5,0x554d4
    80006230:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006234:	0af71963          	bne	a4,a5,800062e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006238:	100017b7          	lui	a5,0x10001
    8000623c:	4705                	li	a4,1
    8000623e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006240:	470d                	li	a4,3
    80006242:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006244:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006246:	c7ffe737          	lui	a4,0xc7ffe
    8000624a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc75f>
    8000624e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006250:	2701                	sext.w	a4,a4
    80006252:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006254:	472d                	li	a4,11
    80006256:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006258:	473d                	li	a4,15
    8000625a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000625c:	6705                	lui	a4,0x1
    8000625e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006260:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006264:	5bdc                	lw	a5,52(a5)
    80006266:	2781                	sext.w	a5,a5
  if(max == 0)
    80006268:	c7d9                	beqz	a5,800062f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000626a:	471d                	li	a4,7
    8000626c:	08f77d63          	bgeu	a4,a5,80006306 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006270:	100014b7          	lui	s1,0x10001
    80006274:	47a1                	li	a5,8
    80006276:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006278:	6609                	lui	a2,0x2
    8000627a:	4581                	li	a1,0
    8000627c:	00029517          	auipc	a0,0x29
    80006280:	d8450513          	addi	a0,a0,-636 # 8002f000 <disk>
    80006284:	ffffb097          	auipc	ra,0xffffb
    80006288:	a4e080e7          	jalr	-1458(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000628c:	00029717          	auipc	a4,0x29
    80006290:	d7470713          	addi	a4,a4,-652 # 8002f000 <disk>
    80006294:	00c75793          	srli	a5,a4,0xc
    80006298:	2781                	sext.w	a5,a5
    8000629a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000629c:	0002b797          	auipc	a5,0x2b
    800062a0:	d6478793          	addi	a5,a5,-668 # 80031000 <disk+0x2000>
    800062a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062a6:	00029717          	auipc	a4,0x29
    800062aa:	dda70713          	addi	a4,a4,-550 # 8002f080 <disk+0x80>
    800062ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062b0:	0002a717          	auipc	a4,0x2a
    800062b4:	d5070713          	addi	a4,a4,-688 # 80030000 <disk+0x1000>
    800062b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062ba:	4705                	li	a4,1
    800062bc:	00e78c23          	sb	a4,24(a5)
    800062c0:	00e78ca3          	sb	a4,25(a5)
    800062c4:	00e78d23          	sb	a4,26(a5)
    800062c8:	00e78da3          	sb	a4,27(a5)
    800062cc:	00e78e23          	sb	a4,28(a5)
    800062d0:	00e78ea3          	sb	a4,29(a5)
    800062d4:	00e78f23          	sb	a4,30(a5)
    800062d8:	00e78fa3          	sb	a4,31(a5)
}
    800062dc:	60e2                	ld	ra,24(sp)
    800062de:	6442                	ld	s0,16(sp)
    800062e0:	64a2                	ld	s1,8(sp)
    800062e2:	6105                	addi	sp,sp,32
    800062e4:	8082                	ret
    panic("could not find virtio disk");
    800062e6:	00002517          	auipc	a0,0x2
    800062ea:	46250513          	addi	a0,a0,1122 # 80008748 <syscalls+0x360>
    800062ee:	ffffa097          	auipc	ra,0xffffa
    800062f2:	242080e7          	jalr	578(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    800062f6:	00002517          	auipc	a0,0x2
    800062fa:	47250513          	addi	a0,a0,1138 # 80008768 <syscalls+0x380>
    800062fe:	ffffa097          	auipc	ra,0xffffa
    80006302:	232080e7          	jalr	562(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80006306:	00002517          	auipc	a0,0x2
    8000630a:	48250513          	addi	a0,a0,1154 # 80008788 <syscalls+0x3a0>
    8000630e:	ffffa097          	auipc	ra,0xffffa
    80006312:	222080e7          	jalr	546(ra) # 80000530 <panic>

0000000080006316 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006316:	7159                	addi	sp,sp,-112
    80006318:	f486                	sd	ra,104(sp)
    8000631a:	f0a2                	sd	s0,96(sp)
    8000631c:	eca6                	sd	s1,88(sp)
    8000631e:	e8ca                	sd	s2,80(sp)
    80006320:	e4ce                	sd	s3,72(sp)
    80006322:	e0d2                	sd	s4,64(sp)
    80006324:	fc56                	sd	s5,56(sp)
    80006326:	f85a                	sd	s6,48(sp)
    80006328:	f45e                	sd	s7,40(sp)
    8000632a:	f062                	sd	s8,32(sp)
    8000632c:	ec66                	sd	s9,24(sp)
    8000632e:	e86a                	sd	s10,16(sp)
    80006330:	1880                	addi	s0,sp,112
    80006332:	892a                	mv	s2,a0
    80006334:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006336:	00c52c83          	lw	s9,12(a0)
    8000633a:	001c9c9b          	slliw	s9,s9,0x1
    8000633e:	1c82                	slli	s9,s9,0x20
    80006340:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006344:	0002b517          	auipc	a0,0x2b
    80006348:	de450513          	addi	a0,a0,-540 # 80031128 <disk+0x2128>
    8000634c:	ffffb097          	auipc	ra,0xffffb
    80006350:	88a080e7          	jalr	-1910(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006354:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006356:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006358:	00029b97          	auipc	s7,0x29
    8000635c:	ca8b8b93          	addi	s7,s7,-856 # 8002f000 <disk>
    80006360:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006362:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006364:	8a4e                	mv	s4,s3
    80006366:	a051                	j	800063ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006368:	00fb86b3          	add	a3,s7,a5
    8000636c:	96da                	add	a3,a3,s6
    8000636e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006372:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006374:	0207c563          	bltz	a5,8000639e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006378:	2485                	addiw	s1,s1,1
    8000637a:	0711                	addi	a4,a4,4
    8000637c:	25548063          	beq	s1,s5,800065bc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006380:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006382:	0002b697          	auipc	a3,0x2b
    80006386:	c9668693          	addi	a3,a3,-874 # 80031018 <disk+0x2018>
    8000638a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000638c:	0006c583          	lbu	a1,0(a3)
    80006390:	fde1                	bnez	a1,80006368 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006392:	2785                	addiw	a5,a5,1
    80006394:	0685                	addi	a3,a3,1
    80006396:	ff879be3          	bne	a5,s8,8000638c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000639a:	57fd                	li	a5,-1
    8000639c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000639e:	02905a63          	blez	s1,800063d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063a2:	f9042503          	lw	a0,-112(s0)
    800063a6:	00000097          	auipc	ra,0x0
    800063aa:	d90080e7          	jalr	-624(ra) # 80006136 <free_desc>
      for(int j = 0; j < i; j++)
    800063ae:	4785                	li	a5,1
    800063b0:	0297d163          	bge	a5,s1,800063d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063b4:	f9442503          	lw	a0,-108(s0)
    800063b8:	00000097          	auipc	ra,0x0
    800063bc:	d7e080e7          	jalr	-642(ra) # 80006136 <free_desc>
      for(int j = 0; j < i; j++)
    800063c0:	4789                	li	a5,2
    800063c2:	0097d863          	bge	a5,s1,800063d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063c6:	f9842503          	lw	a0,-104(s0)
    800063ca:	00000097          	auipc	ra,0x0
    800063ce:	d6c080e7          	jalr	-660(ra) # 80006136 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063d2:	0002b597          	auipc	a1,0x2b
    800063d6:	d5658593          	addi	a1,a1,-682 # 80031128 <disk+0x2128>
    800063da:	0002b517          	auipc	a0,0x2b
    800063de:	c3e50513          	addi	a0,a0,-962 # 80031018 <disk+0x2018>
    800063e2:	ffffc097          	auipc	ra,0xffffc
    800063e6:	e94080e7          	jalr	-364(ra) # 80002276 <sleep>
  for(int i = 0; i < 3; i++){
    800063ea:	f9040713          	addi	a4,s0,-112
    800063ee:	84ce                	mv	s1,s3
    800063f0:	bf41                	j	80006380 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063f2:	20058713          	addi	a4,a1,512
    800063f6:	00471693          	slli	a3,a4,0x4
    800063fa:	00029717          	auipc	a4,0x29
    800063fe:	c0670713          	addi	a4,a4,-1018 # 8002f000 <disk>
    80006402:	9736                	add	a4,a4,a3
    80006404:	4685                	li	a3,1
    80006406:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000640a:	20058713          	addi	a4,a1,512
    8000640e:	00471693          	slli	a3,a4,0x4
    80006412:	00029717          	auipc	a4,0x29
    80006416:	bee70713          	addi	a4,a4,-1042 # 8002f000 <disk>
    8000641a:	9736                	add	a4,a4,a3
    8000641c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006420:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006424:	7679                	lui	a2,0xffffe
    80006426:	963e                	add	a2,a2,a5
    80006428:	0002b697          	auipc	a3,0x2b
    8000642c:	bd868693          	addi	a3,a3,-1064 # 80031000 <disk+0x2000>
    80006430:	6298                	ld	a4,0(a3)
    80006432:	9732                	add	a4,a4,a2
    80006434:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006436:	6298                	ld	a4,0(a3)
    80006438:	9732                	add	a4,a4,a2
    8000643a:	4541                	li	a0,16
    8000643c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000643e:	6298                	ld	a4,0(a3)
    80006440:	9732                	add	a4,a4,a2
    80006442:	4505                	li	a0,1
    80006444:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006448:	f9442703          	lw	a4,-108(s0)
    8000644c:	6288                	ld	a0,0(a3)
    8000644e:	962a                	add	a2,a2,a0
    80006450:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcc00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006454:	0712                	slli	a4,a4,0x4
    80006456:	6290                	ld	a2,0(a3)
    80006458:	963a                	add	a2,a2,a4
    8000645a:	05890513          	addi	a0,s2,88
    8000645e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006460:	6294                	ld	a3,0(a3)
    80006462:	96ba                	add	a3,a3,a4
    80006464:	40000613          	li	a2,1024
    80006468:	c690                	sw	a2,8(a3)
  if(write)
    8000646a:	140d0063          	beqz	s10,800065aa <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000646e:	0002b697          	auipc	a3,0x2b
    80006472:	b926b683          	ld	a3,-1134(a3) # 80031000 <disk+0x2000>
    80006476:	96ba                	add	a3,a3,a4
    80006478:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000647c:	00029817          	auipc	a6,0x29
    80006480:	b8480813          	addi	a6,a6,-1148 # 8002f000 <disk>
    80006484:	0002b517          	auipc	a0,0x2b
    80006488:	b7c50513          	addi	a0,a0,-1156 # 80031000 <disk+0x2000>
    8000648c:	6114                	ld	a3,0(a0)
    8000648e:	96ba                	add	a3,a3,a4
    80006490:	00c6d603          	lhu	a2,12(a3)
    80006494:	00166613          	ori	a2,a2,1
    80006498:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000649c:	f9842683          	lw	a3,-104(s0)
    800064a0:	6110                	ld	a2,0(a0)
    800064a2:	9732                	add	a4,a4,a2
    800064a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064a8:	20058613          	addi	a2,a1,512
    800064ac:	0612                	slli	a2,a2,0x4
    800064ae:	9642                	add	a2,a2,a6
    800064b0:	577d                	li	a4,-1
    800064b2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064b6:	00469713          	slli	a4,a3,0x4
    800064ba:	6114                	ld	a3,0(a0)
    800064bc:	96ba                	add	a3,a3,a4
    800064be:	03078793          	addi	a5,a5,48
    800064c2:	97c2                	add	a5,a5,a6
    800064c4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800064c6:	611c                	ld	a5,0(a0)
    800064c8:	97ba                	add	a5,a5,a4
    800064ca:	4685                	li	a3,1
    800064cc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064ce:	611c                	ld	a5,0(a0)
    800064d0:	97ba                	add	a5,a5,a4
    800064d2:	4809                	li	a6,2
    800064d4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800064d8:	611c                	ld	a5,0(a0)
    800064da:	973e                	add	a4,a4,a5
    800064dc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064e0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800064e4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064e8:	6518                	ld	a4,8(a0)
    800064ea:	00275783          	lhu	a5,2(a4)
    800064ee:	8b9d                	andi	a5,a5,7
    800064f0:	0786                	slli	a5,a5,0x1
    800064f2:	97ba                	add	a5,a5,a4
    800064f4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064f8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064fc:	6518                	ld	a4,8(a0)
    800064fe:	00275783          	lhu	a5,2(a4)
    80006502:	2785                	addiw	a5,a5,1
    80006504:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006508:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000650c:	100017b7          	lui	a5,0x10001
    80006510:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006514:	00492703          	lw	a4,4(s2)
    80006518:	4785                	li	a5,1
    8000651a:	02f71163          	bne	a4,a5,8000653c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000651e:	0002b997          	auipc	s3,0x2b
    80006522:	c0a98993          	addi	s3,s3,-1014 # 80031128 <disk+0x2128>
  while(b->disk == 1) {
    80006526:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006528:	85ce                	mv	a1,s3
    8000652a:	854a                	mv	a0,s2
    8000652c:	ffffc097          	auipc	ra,0xffffc
    80006530:	d4a080e7          	jalr	-694(ra) # 80002276 <sleep>
  while(b->disk == 1) {
    80006534:	00492783          	lw	a5,4(s2)
    80006538:	fe9788e3          	beq	a5,s1,80006528 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000653c:	f9042903          	lw	s2,-112(s0)
    80006540:	20090793          	addi	a5,s2,512
    80006544:	00479713          	slli	a4,a5,0x4
    80006548:	00029797          	auipc	a5,0x29
    8000654c:	ab878793          	addi	a5,a5,-1352 # 8002f000 <disk>
    80006550:	97ba                	add	a5,a5,a4
    80006552:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006556:	0002b997          	auipc	s3,0x2b
    8000655a:	aaa98993          	addi	s3,s3,-1366 # 80031000 <disk+0x2000>
    8000655e:	00491713          	slli	a4,s2,0x4
    80006562:	0009b783          	ld	a5,0(s3)
    80006566:	97ba                	add	a5,a5,a4
    80006568:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000656c:	854a                	mv	a0,s2
    8000656e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006572:	00000097          	auipc	ra,0x0
    80006576:	bc4080e7          	jalr	-1084(ra) # 80006136 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000657a:	8885                	andi	s1,s1,1
    8000657c:	f0ed                	bnez	s1,8000655e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000657e:	0002b517          	auipc	a0,0x2b
    80006582:	baa50513          	addi	a0,a0,-1110 # 80031128 <disk+0x2128>
    80006586:	ffffa097          	auipc	ra,0xffffa
    8000658a:	704080e7          	jalr	1796(ra) # 80000c8a <release>
}
    8000658e:	70a6                	ld	ra,104(sp)
    80006590:	7406                	ld	s0,96(sp)
    80006592:	64e6                	ld	s1,88(sp)
    80006594:	6946                	ld	s2,80(sp)
    80006596:	69a6                	ld	s3,72(sp)
    80006598:	6a06                	ld	s4,64(sp)
    8000659a:	7ae2                	ld	s5,56(sp)
    8000659c:	7b42                	ld	s6,48(sp)
    8000659e:	7ba2                	ld	s7,40(sp)
    800065a0:	7c02                	ld	s8,32(sp)
    800065a2:	6ce2                	ld	s9,24(sp)
    800065a4:	6d42                	ld	s10,16(sp)
    800065a6:	6165                	addi	sp,sp,112
    800065a8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065aa:	0002b697          	auipc	a3,0x2b
    800065ae:	a566b683          	ld	a3,-1450(a3) # 80031000 <disk+0x2000>
    800065b2:	96ba                	add	a3,a3,a4
    800065b4:	4609                	li	a2,2
    800065b6:	00c69623          	sh	a2,12(a3)
    800065ba:	b5c9                	j	8000647c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065bc:	f9042583          	lw	a1,-112(s0)
    800065c0:	20058793          	addi	a5,a1,512
    800065c4:	0792                	slli	a5,a5,0x4
    800065c6:	00029517          	auipc	a0,0x29
    800065ca:	ae250513          	addi	a0,a0,-1310 # 8002f0a8 <disk+0xa8>
    800065ce:	953e                	add	a0,a0,a5
  if(write)
    800065d0:	e20d11e3          	bnez	s10,800063f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800065d4:	20058713          	addi	a4,a1,512
    800065d8:	00471693          	slli	a3,a4,0x4
    800065dc:	00029717          	auipc	a4,0x29
    800065e0:	a2470713          	addi	a4,a4,-1500 # 8002f000 <disk>
    800065e4:	9736                	add	a4,a4,a3
    800065e6:	0a072423          	sw	zero,168(a4)
    800065ea:	b505                	j	8000640a <virtio_disk_rw+0xf4>

00000000800065ec <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065ec:	1101                	addi	sp,sp,-32
    800065ee:	ec06                	sd	ra,24(sp)
    800065f0:	e822                	sd	s0,16(sp)
    800065f2:	e426                	sd	s1,8(sp)
    800065f4:	e04a                	sd	s2,0(sp)
    800065f6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065f8:	0002b517          	auipc	a0,0x2b
    800065fc:	b3050513          	addi	a0,a0,-1232 # 80031128 <disk+0x2128>
    80006600:	ffffa097          	auipc	ra,0xffffa
    80006604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006608:	10001737          	lui	a4,0x10001
    8000660c:	533c                	lw	a5,96(a4)
    8000660e:	8b8d                	andi	a5,a5,3
    80006610:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006612:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006616:	0002b797          	auipc	a5,0x2b
    8000661a:	9ea78793          	addi	a5,a5,-1558 # 80031000 <disk+0x2000>
    8000661e:	6b94                	ld	a3,16(a5)
    80006620:	0207d703          	lhu	a4,32(a5)
    80006624:	0026d783          	lhu	a5,2(a3)
    80006628:	06f70163          	beq	a4,a5,8000668a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000662c:	00029917          	auipc	s2,0x29
    80006630:	9d490913          	addi	s2,s2,-1580 # 8002f000 <disk>
    80006634:	0002b497          	auipc	s1,0x2b
    80006638:	9cc48493          	addi	s1,s1,-1588 # 80031000 <disk+0x2000>
    __sync_synchronize();
    8000663c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006640:	6898                	ld	a4,16(s1)
    80006642:	0204d783          	lhu	a5,32(s1)
    80006646:	8b9d                	andi	a5,a5,7
    80006648:	078e                	slli	a5,a5,0x3
    8000664a:	97ba                	add	a5,a5,a4
    8000664c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000664e:	20078713          	addi	a4,a5,512
    80006652:	0712                	slli	a4,a4,0x4
    80006654:	974a                	add	a4,a4,s2
    80006656:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000665a:	e731                	bnez	a4,800066a6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000665c:	20078793          	addi	a5,a5,512
    80006660:	0792                	slli	a5,a5,0x4
    80006662:	97ca                	add	a5,a5,s2
    80006664:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006666:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000666a:	ffffc097          	auipc	ra,0xffffc
    8000666e:	d92080e7          	jalr	-622(ra) # 800023fc <wakeup>

    disk.used_idx += 1;
    80006672:	0204d783          	lhu	a5,32(s1)
    80006676:	2785                	addiw	a5,a5,1
    80006678:	17c2                	slli	a5,a5,0x30
    8000667a:	93c1                	srli	a5,a5,0x30
    8000667c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006680:	6898                	ld	a4,16(s1)
    80006682:	00275703          	lhu	a4,2(a4)
    80006686:	faf71be3          	bne	a4,a5,8000663c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000668a:	0002b517          	auipc	a0,0x2b
    8000668e:	a9e50513          	addi	a0,a0,-1378 # 80031128 <disk+0x2128>
    80006692:	ffffa097          	auipc	ra,0xffffa
    80006696:	5f8080e7          	jalr	1528(ra) # 80000c8a <release>
}
    8000669a:	60e2                	ld	ra,24(sp)
    8000669c:	6442                	ld	s0,16(sp)
    8000669e:	64a2                	ld	s1,8(sp)
    800066a0:	6902                	ld	s2,0(sp)
    800066a2:	6105                	addi	sp,sp,32
    800066a4:	8082                	ret
      panic("virtio_disk_intr status");
    800066a6:	00002517          	auipc	a0,0x2
    800066aa:	10250513          	addi	a0,a0,258 # 800087a8 <syscalls+0x3c0>
    800066ae:	ffffa097          	auipc	ra,0xffffa
    800066b2:	e82080e7          	jalr	-382(ra) # 80000530 <panic>
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
