
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000056:	89e70713          	addi	a4,a4,-1890 # 800088f0 <timer_scratch>
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
    80000068:	ddc78793          	addi	a5,a5,-548 # 80005e40 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc69f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
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
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	3a6080e7          	jalr	934(ra) # 800024d2 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8a650513          	addi	a0,a0,-1882 # 80010a30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	89648493          	addi	s1,s1,-1898 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	92690913          	addi	s2,s2,-1754 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	154080e7          	jalr	340(ra) # 8000231c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e92080e7          	jalr	-366(ra) # 80002068 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	26a080e7          	jalr	618(ra) # 8000247c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72b23          	sw	a5,-1962(a4) # 80010ac8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	76450513          	addi	a0,a0,1892 # 80010a30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	236080e7          	jalr	566(ra) # 80002528 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	73650513          	addi	a0,a0,1846 # 80010a30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	71270713          	addi	a4,a4,1810 # 80010a30 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6e878793          	addi	a5,a5,1768 # 80010a30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7527a783          	lw	a5,1874(a5) # 80010ac8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6a670713          	addi	a4,a4,1702 # 80010a30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	69648493          	addi	s1,s1,1686 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	65a70713          	addi	a4,a4,1626 # 80010a30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72223          	sw	a5,1764(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	61e78793          	addi	a5,a5,1566 # 80010a30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7ab23          	sw	a2,1686(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	68a50513          	addi	a0,a0,1674 # 80010ac8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c86080e7          	jalr	-890(ra) # 800020cc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5d050513          	addi	a0,a0,1488 # 80010a30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	b5078793          	addi	a5,a5,-1200 # 80020fc8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5a07a323          	sw	zero,1446(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	32f72923          	sw	a5,818(a4) # 800088b0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	536dad83          	lw	s11,1334(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4e050513          	addi	a0,a0,1248 # 80010ad8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	38250513          	addi	a0,a0,898 # 80010ad8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	36648493          	addi	s1,s1,870 # 80010ad8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	32650513          	addi	a0,a0,806 # 80010af8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0b27a783          	lw	a5,178(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0827b783          	ld	a5,130(a5) # 800088b8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	08273703          	ld	a4,130(a4) # 800088c0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	298a0a13          	addi	s4,s4,664 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	05048493          	addi	s1,s1,80 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	05098993          	addi	s3,s3,80 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	83a080e7          	jalr	-1990(ra) # 800020cc <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
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
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	22a50513          	addi	a0,a0,554 # 80010af8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fd27a783          	lw	a5,-46(a5) # 800088b0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fd873703          	ld	a4,-40(a4) # 800088c0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fc87b783          	ld	a5,-56(a5) # 800088b8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	1fc98993          	addi	s3,s3,508 # 80010af8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fb448493          	addi	s1,s1,-76 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fb490913          	addi	s2,s2,-76 # 800088c0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	74c080e7          	jalr	1868(ra) # 80002068 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1c648493          	addi	s1,s1,454 # 80010af8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f6e7bd23          	sd	a4,-134(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

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
// both. called from devintr().
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
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	13c48493          	addi	s1,s1,316 # 80010af8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
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
    800009fe:	00021797          	auipc	a5,0x21
    80000a02:	76278793          	addi	a5,a5,1890 # 80022160 <end>
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
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	11290913          	addi	s2,s2,274 # 80010b30 <kmem>
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
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

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
    80000abe:	07650513          	addi	a0,a0,118 # 80010b30 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	69250513          	addi	a0,a0,1682 # 80022160 <end>
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
    80000af4:	04048493          	addi	s1,s1,64 # 80010b30 <kmem>
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
    80000b0c:	02850513          	addi	a0,a0,40 # 80010b30 <kmem>
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
    80000b38:	ffc50513          	addi	a0,a0,-4 # 80010b30 <kmem>
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
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
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
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
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
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
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
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
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
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

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
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
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
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

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
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

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
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a4070713          	addi	a4,a4,-1472 # 800088c8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	954080e7          	jalr	-1708(ra) # 80002812 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	fba080e7          	jalr	-70(ra) # 80005e80 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe8080e7          	jalr	-24(ra) # 80001eb6 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	8b4080e7          	jalr	-1868(ra) # 800027ea <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	8d4080e7          	jalr	-1836(ra) # 80002812 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	f24080e7          	jalr	-220(ra) # 80005e6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	f32080e7          	jalr	-206(ra) # 80005e80 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	0a2080e7          	jalr	162(ra) # 80002ff8 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	746080e7          	jalr	1862(ra) # 800036a4 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	6e4080e7          	jalr	1764(ra) # 8000464a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	01a080e7          	jalr	26(ra) # 80005f88 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d22080e7          	jalr	-734(ra) # 80001c98 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	94f72223          	sw	a5,-1724(a4) # 800088c8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9387b783          	ld	a5,-1736(a5) # 800088d0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	66a7be23          	sd	a0,1660(a5) # 800088d0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	73448493          	addi	s1,s1,1844 # 80010f80 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	51aa0a13          	addi	s4,s4,1306 # 80016d80 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	17848493          	addi	s1,s1,376
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	26850513          	addi	a0,a0,616 # 80010b50 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	26850513          	addi	a0,a0,616 # 80010b68 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	67048493          	addi	s1,s1,1648 # 80010f80 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00015997          	auipc	s3,0x15
    80001936:	44e98993          	addi	s3,s3,1102 # 80016d80 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	17848493          	addi	s1,s1,376
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	1e450513          	addi	a0,a0,484 # 80010b80 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	18c70713          	addi	a4,a4,396 # 80010b50 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	e24080e7          	jalr	-476(ra) # 8000282a <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	c04080e7          	jalr	-1020(ra) # 80003624 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	11a90913          	addi	s2,s2,282 # 80010b50 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3be48493          	addi	s1,s1,958 # 80010f80 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	1b690913          	addi	s2,s2,438 # 80016d80 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	17848493          	addi	s1,s1,376
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a09d                	j	80001c5a <allocproc+0xa4>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd21                	beqz	a0,80001c68 <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c125                	beqz	a0,80001c80 <allocproc+0xca>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	c927a783          	lw	a5,-878(a5) # 800088e0 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
    freeproc(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	ef4080e7          	jalr	-268(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	016080e7          	jalr	22(ra) # 80000c8a <release>
    return 0;
    80001c7c:	84ca                	mv	s1,s2
    80001c7e:	bff1                	j	80001c5a <allocproc+0xa4>
    freeproc(p);
    80001c80:	8526                	mv	a0,s1
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	edc080e7          	jalr	-292(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
    return 0;
    80001c94:	84ca                	mv	s1,s2
    80001c96:	b7d1                	j	80001c5a <allocproc+0xa4>

0000000080001c98 <userinit>:
{
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	f14080e7          	jalr	-236(ra) # 80001bb6 <allocproc>
    80001caa:	84aa                	mv	s1,a0
  initproc = p;
    80001cac:	00007797          	auipc	a5,0x7
    80001cb0:	c2a7b623          	sd	a0,-980(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cb4:	03400613          	li	a2,52
    80001cb8:	00007597          	auipc	a1,0x7
    80001cbc:	bb858593          	addi	a1,a1,-1096 # 80008870 <initcode>
    80001cc0:	6928                	ld	a0,80(a0)
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	694080e7          	jalr	1684(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cca:	6785                	lui	a5,0x1
    80001ccc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cce:	6cb8                	ld	a4,88(s1)
    80001cd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd8:	4641                	li	a2,16
    80001cda:	00006597          	auipc	a1,0x6
    80001cde:	52658593          	addi	a1,a1,1318 # 80008200 <digits+0x1c0>
    80001ce2:	15848513          	addi	a0,s1,344
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	136080e7          	jalr	310(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cee:	00006517          	auipc	a0,0x6
    80001cf2:	52250513          	addi	a0,a0,1314 # 80008210 <digits+0x1d0>
    80001cf6:	00002097          	auipc	ra,0x2
    80001cfa:	350080e7          	jalr	848(ra) # 80004046 <namei>
    80001cfe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d02:	478d                	li	a5,3
    80001d04:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	f82080e7          	jalr	-126(ra) # 80000c8a <release>
}
    80001d10:	60e2                	ld	ra,24(sp)
    80001d12:	6442                	ld	s0,16(sp)
    80001d14:	64a2                	ld	s1,8(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret

0000000080001d1a <growproc>:
{
    80001d1a:	1101                	addi	sp,sp,-32
    80001d1c:	ec06                	sd	ra,24(sp)
    80001d1e:	e822                	sd	s0,16(sp)
    80001d20:	e426                	sd	s1,8(sp)
    80001d22:	e04a                	sd	s2,0(sp)
    80001d24:	1000                	addi	s0,sp,32
    80001d26:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80001d30:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d32:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d34:	01204c63          	bgtz	s2,80001d4c <growproc+0x32>
  else if (n < 0)
    80001d38:	02094663          	bltz	s2,80001d64 <growproc+0x4a>
  p->sz = sz;
    80001d3c:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d3e:	4501                	li	a0,0
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6902                	ld	s2,0(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d4c:	4691                	li	a3,4
    80001d4e:	00b90633          	add	a2,s2,a1
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	6bc080e7          	jalr	1724(ra) # 80001410 <uvmalloc>
    80001d5c:	85aa                	mv	a1,a0
    80001d5e:	fd79                	bnez	a0,80001d3c <growproc+0x22>
      return -1;
    80001d60:	557d                	li	a0,-1
    80001d62:	bff9                	j	80001d40 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	00b90633          	add	a2,s2,a1
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	65e080e7          	jalr	1630(ra) # 800013c8 <uvmdealloc>
    80001d72:	85aa                	mv	a1,a0
    80001d74:	b7e1                	j	80001d3c <growproc+0x22>

0000000080001d76 <fork>:
{
    80001d76:	7139                	addi	sp,sp,-64
    80001d78:	fc06                	sd	ra,56(sp)
    80001d7a:	f822                	sd	s0,48(sp)
    80001d7c:	f426                	sd	s1,40(sp)
    80001d7e:	f04a                	sd	s2,32(sp)
    80001d80:	ec4e                	sd	s3,24(sp)
    80001d82:	e852                	sd	s4,16(sp)
    80001d84:	e456                	sd	s5,8(sp)
    80001d86:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
    80001d90:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	e24080e7          	jalr	-476(ra) # 80001bb6 <allocproc>
    80001d9a:	10050c63          	beqz	a0,80001eb2 <fork+0x13c>
    80001d9e:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001da0:	048ab603          	ld	a2,72(s5)
    80001da4:	692c                	ld	a1,80(a0)
    80001da6:	050ab503          	ld	a0,80(s5)
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	7ba080e7          	jalr	1978(ra) # 80001564 <uvmcopy>
    80001db2:	04054863          	bltz	a0,80001e02 <fork+0x8c>
  np->sz = p->sz;
    80001db6:	048ab783          	ld	a5,72(s5)
    80001dba:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dbe:	058ab683          	ld	a3,88(s5)
    80001dc2:	87b6                	mv	a5,a3
    80001dc4:	058a3703          	ld	a4,88(s4)
    80001dc8:	12068693          	addi	a3,a3,288
    80001dcc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd0:	6788                	ld	a0,8(a5)
    80001dd2:	6b8c                	ld	a1,16(a5)
    80001dd4:	6f90                	ld	a2,24(a5)
    80001dd6:	01073023          	sd	a6,0(a4)
    80001dda:	e708                	sd	a0,8(a4)
    80001ddc:	eb0c                	sd	a1,16(a4)
    80001dde:	ef10                	sd	a2,24(a4)
    80001de0:	02078793          	addi	a5,a5,32
    80001de4:	02070713          	addi	a4,a4,32
    80001de8:	fed792e3          	bne	a5,a3,80001dcc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dec:	058a3783          	ld	a5,88(s4)
    80001df0:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001df4:	0d0a8493          	addi	s1,s5,208
    80001df8:	0d0a0913          	addi	s2,s4,208
    80001dfc:	150a8993          	addi	s3,s5,336
    80001e00:	a00d                	j	80001e22 <fork+0xac>
    freeproc(np);
    80001e02:	8552                	mv	a0,s4
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d5a080e7          	jalr	-678(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e0c:	8552                	mv	a0,s4
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e7c080e7          	jalr	-388(ra) # 80000c8a <release>
    return -1;
    80001e16:	597d                	li	s2,-1
    80001e18:	a059                	j	80001e9e <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e1a:	04a1                	addi	s1,s1,8
    80001e1c:	0921                	addi	s2,s2,8
    80001e1e:	01348b63          	beq	s1,s3,80001e34 <fork+0xbe>
    if (p->ofile[i])
    80001e22:	6088                	ld	a0,0(s1)
    80001e24:	d97d                	beqz	a0,80001e1a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e26:	00003097          	auipc	ra,0x3
    80001e2a:	8b6080e7          	jalr	-1866(ra) # 800046dc <filedup>
    80001e2e:	00a93023          	sd	a0,0(s2)
    80001e32:	b7e5                	j	80001e1a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e34:	150ab503          	ld	a0,336(s5)
    80001e38:	00002097          	auipc	ra,0x2
    80001e3c:	a2a080e7          	jalr	-1494(ra) # 80003862 <idup>
    80001e40:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e44:	4641                	li	a2,16
    80001e46:	158a8593          	addi	a1,s5,344
    80001e4a:	158a0513          	addi	a0,s4,344
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	fce080e7          	jalr	-50(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e56:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e64:	0000f497          	auipc	s1,0xf
    80001e68:	d0448493          	addi	s1,s1,-764 # 80010b68 <wait_lock>
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	d68080e7          	jalr	-664(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e76:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	e0e080e7          	jalr	-498(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	d50080e7          	jalr	-688(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e8e:	478d                	li	a5,3
    80001e90:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
}
    80001e9e:	854a                	mv	a0,s2
    80001ea0:	70e2                	ld	ra,56(sp)
    80001ea2:	7442                	ld	s0,48(sp)
    80001ea4:	74a2                	ld	s1,40(sp)
    80001ea6:	7902                	ld	s2,32(sp)
    80001ea8:	69e2                	ld	s3,24(sp)
    80001eaa:	6a42                	ld	s4,16(sp)
    80001eac:	6aa2                	ld	s5,8(sp)
    80001eae:	6121                	addi	sp,sp,64
    80001eb0:	8082                	ret
    return -1;
    80001eb2:	597d                	li	s2,-1
    80001eb4:	b7ed                	j	80001e9e <fork+0x128>

0000000080001eb6 <scheduler>:
{
    80001eb6:	7139                	addi	sp,sp,-64
    80001eb8:	fc06                	sd	ra,56(sp)
    80001eba:	f822                	sd	s0,48(sp)
    80001ebc:	f426                	sd	s1,40(sp)
    80001ebe:	f04a                	sd	s2,32(sp)
    80001ec0:	ec4e                	sd	s3,24(sp)
    80001ec2:	e852                	sd	s4,16(sp)
    80001ec4:	e456                	sd	s5,8(sp)
    80001ec6:	e05a                	sd	s6,0(sp)
    80001ec8:	0080                	addi	s0,sp,64
    80001eca:	8792                	mv	a5,tp
  int id = r_tp();
    80001ecc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ece:	00779a93          	slli	s5,a5,0x7
    80001ed2:	0000f717          	auipc	a4,0xf
    80001ed6:	c7e70713          	addi	a4,a4,-898 # 80010b50 <pid_lock>
    80001eda:	9756                	add	a4,a4,s5
    80001edc:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee0:	0000f717          	auipc	a4,0xf
    80001ee4:	ca870713          	addi	a4,a4,-856 # 80010b88 <cpus+0x8>
    80001ee8:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001eea:	498d                	li	s3,3
        p->state = RUNNING;
    80001eec:	4b11                	li	s6,4
        c->proc = p;
    80001eee:	079e                	slli	a5,a5,0x7
    80001ef0:	0000fa17          	auipc	s4,0xf
    80001ef4:	c60a0a13          	addi	s4,s4,-928 # 80010b50 <pid_lock>
    80001ef8:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001efa:	00015917          	auipc	s2,0x15
    80001efe:	e8690913          	addi	s2,s2,-378 # 80016d80 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f02:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f06:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0a:	10079073          	csrw	sstatus,a5
    80001f0e:	0000f497          	auipc	s1,0xf
    80001f12:	07248493          	addi	s1,s1,114 # 80010f80 <proc>
    80001f16:	a811                	j	80001f2a <scheduler+0x74>
      release(&p->lock);
    80001f18:	8526                	mv	a0,s1
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f22:	17848493          	addi	s1,s1,376
    80001f26:	fd248ee3          	beq	s1,s2,80001f02 <scheduler+0x4c>
      acquire(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	caa080e7          	jalr	-854(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f34:	4c9c                	lw	a5,24(s1)
    80001f36:	ff3791e3          	bne	a5,s3,80001f18 <scheduler+0x62>
        p->state = RUNNING;
    80001f3a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f3e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f42:	06048593          	addi	a1,s1,96
    80001f46:	8556                	mv	a0,s5
    80001f48:	00001097          	auipc	ra,0x1
    80001f4c:	838080e7          	jalr	-1992(ra) # 80002780 <swtch>
        c->proc = 0;
    80001f50:	020a3823          	sd	zero,48(s4)
    80001f54:	b7d1                	j	80001f18 <scheduler+0x62>

0000000080001f56 <sched>:
{
    80001f56:	7179                	addi	sp,sp,-48
    80001f58:	f406                	sd	ra,40(sp)
    80001f5a:	f022                	sd	s0,32(sp)
    80001f5c:	ec26                	sd	s1,24(sp)
    80001f5e:	e84a                	sd	s2,16(sp)
    80001f60:	e44e                	sd	s3,8(sp)
    80001f62:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	a48080e7          	jalr	-1464(ra) # 800019ac <myproc>
    80001f6c:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	bee080e7          	jalr	-1042(ra) # 80000b5c <holding>
    80001f76:	c93d                	beqz	a0,80001fec <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f78:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f7a:	2781                	sext.w	a5,a5
    80001f7c:	079e                	slli	a5,a5,0x7
    80001f7e:	0000f717          	auipc	a4,0xf
    80001f82:	bd270713          	addi	a4,a4,-1070 # 80010b50 <pid_lock>
    80001f86:	97ba                	add	a5,a5,a4
    80001f88:	0a87a703          	lw	a4,168(a5)
    80001f8c:	4785                	li	a5,1
    80001f8e:	06f71763          	bne	a4,a5,80001ffc <sched+0xa6>
  if (p->state == RUNNING)
    80001f92:	4c98                	lw	a4,24(s1)
    80001f94:	4791                	li	a5,4
    80001f96:	06f70b63          	beq	a4,a5,8000200c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f9e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fa0:	efb5                	bnez	a5,8000201c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa4:	0000f917          	auipc	s2,0xf
    80001fa8:	bac90913          	addi	s2,s2,-1108 # 80010b50 <pid_lock>
    80001fac:	2781                	sext.w	a5,a5
    80001fae:	079e                	slli	a5,a5,0x7
    80001fb0:	97ca                	add	a5,a5,s2
    80001fb2:	0ac7a983          	lw	s3,172(a5)
    80001fb6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fb8:	2781                	sext.w	a5,a5
    80001fba:	079e                	slli	a5,a5,0x7
    80001fbc:	0000f597          	auipc	a1,0xf
    80001fc0:	bcc58593          	addi	a1,a1,-1076 # 80010b88 <cpus+0x8>
    80001fc4:	95be                	add	a1,a1,a5
    80001fc6:	06048513          	addi	a0,s1,96
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	7b6080e7          	jalr	1974(ra) # 80002780 <swtch>
    80001fd2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd4:	2781                	sext.w	a5,a5
    80001fd6:	079e                	slli	a5,a5,0x7
    80001fd8:	97ca                	add	a5,a5,s2
    80001fda:	0b37a623          	sw	s3,172(a5)
}
    80001fde:	70a2                	ld	ra,40(sp)
    80001fe0:	7402                	ld	s0,32(sp)
    80001fe2:	64e2                	ld	s1,24(sp)
    80001fe4:	6942                	ld	s2,16(sp)
    80001fe6:	69a2                	ld	s3,8(sp)
    80001fe8:	6145                	addi	sp,sp,48
    80001fea:	8082                	ret
    panic("sched p->lock");
    80001fec:	00006517          	auipc	a0,0x6
    80001ff0:	22c50513          	addi	a0,a0,556 # 80008218 <digits+0x1d8>
    80001ff4:	ffffe097          	auipc	ra,0xffffe
    80001ff8:	54a080e7          	jalr	1354(ra) # 8000053e <panic>
    panic("sched locks");
    80001ffc:	00006517          	auipc	a0,0x6
    80002000:	22c50513          	addi	a0,a0,556 # 80008228 <digits+0x1e8>
    80002004:	ffffe097          	auipc	ra,0xffffe
    80002008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>
    panic("sched running");
    8000200c:	00006517          	auipc	a0,0x6
    80002010:	22c50513          	addi	a0,a0,556 # 80008238 <digits+0x1f8>
    80002014:	ffffe097          	auipc	ra,0xffffe
    80002018:	52a080e7          	jalr	1322(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000201c:	00006517          	auipc	a0,0x6
    80002020:	22c50513          	addi	a0,a0,556 # 80008248 <digits+0x208>
    80002024:	ffffe097          	auipc	ra,0xffffe
    80002028:	51a080e7          	jalr	1306(ra) # 8000053e <panic>

000000008000202c <yield>:
{
    8000202c:	1101                	addi	sp,sp,-32
    8000202e:	ec06                	sd	ra,24(sp)
    80002030:	e822                	sd	s0,16(sp)
    80002032:	e426                	sd	s1,8(sp)
    80002034:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	976080e7          	jalr	-1674(ra) # 800019ac <myproc>
    8000203e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	b96080e7          	jalr	-1130(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002048:	478d                	li	a5,3
    8000204a:	cc9c                	sw	a5,24(s1)
  sched();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	f0a080e7          	jalr	-246(ra) # 80001f56 <sched>
  release(&p->lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c34080e7          	jalr	-972(ra) # 80000c8a <release>
}
    8000205e:	60e2                	ld	ra,24(sp)
    80002060:	6442                	ld	s0,16(sp)
    80002062:	64a2                	ld	s1,8(sp)
    80002064:	6105                	addi	sp,sp,32
    80002066:	8082                	ret

0000000080002068 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002068:	7179                	addi	sp,sp,-48
    8000206a:	f406                	sd	ra,40(sp)
    8000206c:	f022                	sd	s0,32(sp)
    8000206e:	ec26                	sd	s1,24(sp)
    80002070:	e84a                	sd	s2,16(sp)
    80002072:	e44e                	sd	s3,8(sp)
    80002074:	1800                	addi	s0,sp,48
    80002076:	89aa                	mv	s3,a0
    80002078:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	932080e7          	jalr	-1742(ra) # 800019ac <myproc>
    80002082:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b52080e7          	jalr	-1198(ra) # 80000bd6 <acquire>
  release(lk);
    8000208c:	854a                	mv	a0,s2
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	bfc080e7          	jalr	-1028(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002096:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209a:	4789                	li	a5,2
    8000209c:	cc9c                	sw	a5,24(s1)

  sched();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	eb8080e7          	jalr	-328(ra) # 80001f56 <sched>

  // Tidy up.
  p->chan = 0;
    800020a6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	bde080e7          	jalr	-1058(ra) # 80000c8a <release>
  acquire(lk);
    800020b4:	854a                	mv	a0,s2
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b20080e7          	jalr	-1248(ra) # 80000bd6 <acquire>
}
    800020be:	70a2                	ld	ra,40(sp)
    800020c0:	7402                	ld	s0,32(sp)
    800020c2:	64e2                	ld	s1,24(sp)
    800020c4:	6942                	ld	s2,16(sp)
    800020c6:	69a2                	ld	s3,8(sp)
    800020c8:	6145                	addi	sp,sp,48
    800020ca:	8082                	ret

00000000800020cc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020cc:	7139                	addi	sp,sp,-64
    800020ce:	fc06                	sd	ra,56(sp)
    800020d0:	f822                	sd	s0,48(sp)
    800020d2:	f426                	sd	s1,40(sp)
    800020d4:	f04a                	sd	s2,32(sp)
    800020d6:	ec4e                	sd	s3,24(sp)
    800020d8:	e852                	sd	s4,16(sp)
    800020da:	e456                	sd	s5,8(sp)
    800020dc:	0080                	addi	s0,sp,64
    800020de:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020e0:	0000f497          	auipc	s1,0xf
    800020e4:	ea048493          	addi	s1,s1,-352 # 80010f80 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020e8:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020ea:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020ec:	00015917          	auipc	s2,0x15
    800020f0:	c9490913          	addi	s2,s2,-876 # 80016d80 <tickslock>
    800020f4:	a811                	j	80002108 <wakeup+0x3c>
      }
      release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	b92080e7          	jalr	-1134(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002100:	17848493          	addi	s1,s1,376
    80002104:	03248663          	beq	s1,s2,80002130 <wakeup+0x64>
    if (p != myproc())
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	8a4080e7          	jalr	-1884(ra) # 800019ac <myproc>
    80002110:	fea488e3          	beq	s1,a0,80002100 <wakeup+0x34>
      acquire(&p->lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	ac0080e7          	jalr	-1344(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000211e:	4c9c                	lw	a5,24(s1)
    80002120:	fd379be3          	bne	a5,s3,800020f6 <wakeup+0x2a>
    80002124:	709c                	ld	a5,32(s1)
    80002126:	fd4798e3          	bne	a5,s4,800020f6 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000212a:	0154ac23          	sw	s5,24(s1)
    8000212e:	b7e1                	j	800020f6 <wakeup+0x2a>
    }
  }
}
    80002130:	70e2                	ld	ra,56(sp)
    80002132:	7442                	ld	s0,48(sp)
    80002134:	74a2                	ld	s1,40(sp)
    80002136:	7902                	ld	s2,32(sp)
    80002138:	69e2                	ld	s3,24(sp)
    8000213a:	6a42                	ld	s4,16(sp)
    8000213c:	6aa2                	ld	s5,8(sp)
    8000213e:	6121                	addi	sp,sp,64
    80002140:	8082                	ret

0000000080002142 <reparent>:
{
    80002142:	7179                	addi	sp,sp,-48
    80002144:	f406                	sd	ra,40(sp)
    80002146:	f022                	sd	s0,32(sp)
    80002148:	ec26                	sd	s1,24(sp)
    8000214a:	e84a                	sd	s2,16(sp)
    8000214c:	e44e                	sd	s3,8(sp)
    8000214e:	e052                	sd	s4,0(sp)
    80002150:	1800                	addi	s0,sp,48
    80002152:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002154:	0000f497          	auipc	s1,0xf
    80002158:	e2c48493          	addi	s1,s1,-468 # 80010f80 <proc>
      pp->parent = initproc;
    8000215c:	00006a17          	auipc	s4,0x6
    80002160:	77ca0a13          	addi	s4,s4,1916 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002164:	00015997          	auipc	s3,0x15
    80002168:	c1c98993          	addi	s3,s3,-996 # 80016d80 <tickslock>
    8000216c:	a029                	j	80002176 <reparent+0x34>
    8000216e:	17848493          	addi	s1,s1,376
    80002172:	01348d63          	beq	s1,s3,8000218c <reparent+0x4a>
    if (pp->parent == p)
    80002176:	7c9c                	ld	a5,56(s1)
    80002178:	ff279be3          	bne	a5,s2,8000216e <reparent+0x2c>
      pp->parent = initproc;
    8000217c:	000a3503          	ld	a0,0(s4)
    80002180:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002182:	00000097          	auipc	ra,0x0
    80002186:	f4a080e7          	jalr	-182(ra) # 800020cc <wakeup>
    8000218a:	b7d5                	j	8000216e <reparent+0x2c>
}
    8000218c:	70a2                	ld	ra,40(sp)
    8000218e:	7402                	ld	s0,32(sp)
    80002190:	64e2                	ld	s1,24(sp)
    80002192:	6942                	ld	s2,16(sp)
    80002194:	69a2                	ld	s3,8(sp)
    80002196:	6a02                	ld	s4,0(sp)
    80002198:	6145                	addi	sp,sp,48
    8000219a:	8082                	ret

000000008000219c <exit>:
{
    8000219c:	7179                	addi	sp,sp,-48
    8000219e:	f406                	sd	ra,40(sp)
    800021a0:	f022                	sd	s0,32(sp)
    800021a2:	ec26                	sd	s1,24(sp)
    800021a4:	e84a                	sd	s2,16(sp)
    800021a6:	e44e                	sd	s3,8(sp)
    800021a8:	e052                	sd	s4,0(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	7fe080e7          	jalr	2046(ra) # 800019ac <myproc>
    800021b6:	89aa                	mv	s3,a0
  if (p == initproc)
    800021b8:	00006797          	auipc	a5,0x6
    800021bc:	7207b783          	ld	a5,1824(a5) # 800088d8 <initproc>
    800021c0:	0d050493          	addi	s1,a0,208
    800021c4:	15050913          	addi	s2,a0,336
    800021c8:	02a79363          	bne	a5,a0,800021ee <exit+0x52>
    panic("init exiting");
    800021cc:	00006517          	auipc	a0,0x6
    800021d0:	09450513          	addi	a0,a0,148 # 80008260 <digits+0x220>
    800021d4:	ffffe097          	auipc	ra,0xffffe
    800021d8:	36a080e7          	jalr	874(ra) # 8000053e <panic>
      fileclose(f);
    800021dc:	00002097          	auipc	ra,0x2
    800021e0:	552080e7          	jalr	1362(ra) # 8000472e <fileclose>
      p->ofile[fd] = 0;
    800021e4:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021e8:	04a1                	addi	s1,s1,8
    800021ea:	01248563          	beq	s1,s2,800021f4 <exit+0x58>
    if (p->ofile[fd])
    800021ee:	6088                	ld	a0,0(s1)
    800021f0:	f575                	bnez	a0,800021dc <exit+0x40>
    800021f2:	bfdd                	j	800021e8 <exit+0x4c>
  begin_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	06e080e7          	jalr	110(ra) # 80004262 <begin_op>
  iput(p->cwd);
    800021fc:	1509b503          	ld	a0,336(s3)
    80002200:	00002097          	auipc	ra,0x2
    80002204:	85a080e7          	jalr	-1958(ra) # 80003a5a <iput>
  end_op();
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	0da080e7          	jalr	218(ra) # 800042e2 <end_op>
  p->cwd = 0;
    80002210:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002214:	0000f497          	auipc	s1,0xf
    80002218:	95448493          	addi	s1,s1,-1708 # 80010b68 <wait_lock>
    8000221c:	8526                	mv	a0,s1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9b8080e7          	jalr	-1608(ra) # 80000bd6 <acquire>
  reparent(p);
    80002226:	854e                	mv	a0,s3
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	f1a080e7          	jalr	-230(ra) # 80002142 <reparent>
  wakeup(p->parent);
    80002230:	0389b503          	ld	a0,56(s3)
    80002234:	00000097          	auipc	ra,0x0
    80002238:	e98080e7          	jalr	-360(ra) # 800020cc <wakeup>
  acquire(&p->lock);
    8000223c:	854e                	mv	a0,s3
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	998080e7          	jalr	-1640(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002246:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000224a:	4795                	li	a5,5
    8000224c:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002250:	00006797          	auipc	a5,0x6
    80002254:	6907a783          	lw	a5,1680(a5) # 800088e0 <ticks>
    80002258:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a2c080e7          	jalr	-1492(ra) # 80000c8a <release>
  sched();
    80002266:	00000097          	auipc	ra,0x0
    8000226a:	cf0080e7          	jalr	-784(ra) # 80001f56 <sched>
  panic("zombie exit");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	00250513          	addi	a0,a0,2 # 80008270 <digits+0x230>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>

000000008000227e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	cf248493          	addi	s1,s1,-782 # 80010f80 <proc>
    80002296:	00015997          	auipc	s3,0x15
    8000229a:	aea98993          	addi	s3,s3,-1302 # 80016d80 <tickslock>
  {
    acquire(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	936080e7          	jalr	-1738(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800022a8:	589c                	lw	a5,48(s1)
    800022aa:	01278d63          	beq	a5,s2,800022c4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9da080e7          	jalr	-1574(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022b8:	17848493          	addi	s1,s1,376
    800022bc:	ff3491e3          	bne	s1,s3,8000229e <kill+0x20>
  }
  return -1;
    800022c0:	557d                	li	a0,-1
    800022c2:	a829                	j	800022dc <kill+0x5e>
      p->killed = 1;
    800022c4:	4785                	li	a5,1
    800022c6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022c8:	4c98                	lw	a4,24(s1)
    800022ca:	4789                	li	a5,2
    800022cc:	00f70f63          	beq	a4,a5,800022ea <kill+0x6c>
      release(&p->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9b8080e7          	jalr	-1608(ra) # 80000c8a <release>
      return 0;
    800022da:	4501                	li	a0,0
}
    800022dc:	70a2                	ld	ra,40(sp)
    800022de:	7402                	ld	s0,32(sp)
    800022e0:	64e2                	ld	s1,24(sp)
    800022e2:	6942                	ld	s2,16(sp)
    800022e4:	69a2                	ld	s3,8(sp)
    800022e6:	6145                	addi	sp,sp,48
    800022e8:	8082                	ret
        p->state = RUNNABLE;
    800022ea:	478d                	li	a5,3
    800022ec:	cc9c                	sw	a5,24(s1)
    800022ee:	b7cd                	j	800022d0 <kill+0x52>

00000000800022f0 <setkilled>:

void setkilled(struct proc *p)
{
    800022f0:	1101                	addi	sp,sp,-32
    800022f2:	ec06                	sd	ra,24(sp)
    800022f4:	e822                	sd	s0,16(sp)
    800022f6:	e426                	sd	s1,8(sp)
    800022f8:	1000                	addi	s0,sp,32
    800022fa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002304:	4785                	li	a5,1
    80002306:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	980080e7          	jalr	-1664(ra) # 80000c8a <release>
}
    80002312:	60e2                	ld	ra,24(sp)
    80002314:	6442                	ld	s0,16(sp)
    80002316:	64a2                	ld	s1,8(sp)
    80002318:	6105                	addi	sp,sp,32
    8000231a:	8082                	ret

000000008000231c <killed>:

int killed(struct proc *p)
{
    8000231c:	1101                	addi	sp,sp,-32
    8000231e:	ec06                	sd	ra,24(sp)
    80002320:	e822                	sd	s0,16(sp)
    80002322:	e426                	sd	s1,8(sp)
    80002324:	e04a                	sd	s2,0(sp)
    80002326:	1000                	addi	s0,sp,32
    80002328:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8ac080e7          	jalr	-1876(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002332:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
  return k;
}
    80002340:	854a                	mv	a0,s2
    80002342:	60e2                	ld	ra,24(sp)
    80002344:	6442                	ld	s0,16(sp)
    80002346:	64a2                	ld	s1,8(sp)
    80002348:	6902                	ld	s2,0(sp)
    8000234a:	6105                	addi	sp,sp,32
    8000234c:	8082                	ret

000000008000234e <wait>:
{
    8000234e:	715d                	addi	sp,sp,-80
    80002350:	e486                	sd	ra,72(sp)
    80002352:	e0a2                	sd	s0,64(sp)
    80002354:	fc26                	sd	s1,56(sp)
    80002356:	f84a                	sd	s2,48(sp)
    80002358:	f44e                	sd	s3,40(sp)
    8000235a:	f052                	sd	s4,32(sp)
    8000235c:	ec56                	sd	s5,24(sp)
    8000235e:	e85a                	sd	s6,16(sp)
    80002360:	e45e                	sd	s7,8(sp)
    80002362:	e062                	sd	s8,0(sp)
    80002364:	0880                	addi	s0,sp,80
    80002366:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	644080e7          	jalr	1604(ra) # 800019ac <myproc>
    80002370:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002372:	0000e517          	auipc	a0,0xe
    80002376:	7f650513          	addi	a0,a0,2038 # 80010b68 <wait_lock>
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	85c080e7          	jalr	-1956(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002382:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002384:	4a15                	li	s4,5
        havekids = 1;
    80002386:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002388:	00015997          	auipc	s3,0x15
    8000238c:	9f898993          	addi	s3,s3,-1544 # 80016d80 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002390:	0000ec17          	auipc	s8,0xe
    80002394:	7d8c0c13          	addi	s8,s8,2008 # 80010b68 <wait_lock>
    havekids = 0;
    80002398:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	be648493          	addi	s1,s1,-1050 # 80010f80 <proc>
    800023a2:	a0bd                	j	80002410 <wait+0xc2>
          pid = pp->pid;
    800023a4:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023a8:	000b0e63          	beqz	s6,800023c4 <wait+0x76>
    800023ac:	4691                	li	a3,4
    800023ae:	02c48613          	addi	a2,s1,44
    800023b2:	85da                	mv	a1,s6
    800023b4:	05093503          	ld	a0,80(s2)
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	2b0080e7          	jalr	688(ra) # 80001668 <copyout>
    800023c0:	02054563          	bltz	a0,800023ea <wait+0x9c>
          freeproc(pp);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	798080e7          	jalr	1944(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8ba080e7          	jalr	-1862(ra) # 80000c8a <release>
          release(&wait_lock);
    800023d8:	0000e517          	auipc	a0,0xe
    800023dc:	79050513          	addi	a0,a0,1936 # 80010b68 <wait_lock>
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
          return pid;
    800023e8:	a0b5                	j	80002454 <wait+0x106>
            release(&pp->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	89e080e7          	jalr	-1890(ra) # 80000c8a <release>
            release(&wait_lock);
    800023f4:	0000e517          	auipc	a0,0xe
    800023f8:	77450513          	addi	a0,a0,1908 # 80010b68 <wait_lock>
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	88e080e7          	jalr	-1906(ra) # 80000c8a <release>
            return -1;
    80002404:	59fd                	li	s3,-1
    80002406:	a0b9                	j	80002454 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002408:	17848493          	addi	s1,s1,376
    8000240c:	03348463          	beq	s1,s3,80002434 <wait+0xe6>
      if (pp->parent == p)
    80002410:	7c9c                	ld	a5,56(s1)
    80002412:	ff279be3          	bne	a5,s2,80002408 <wait+0xba>
        acquire(&pp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7be080e7          	jalr	1982(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002420:	4c9c                	lw	a5,24(s1)
    80002422:	f94781e3          	beq	a5,s4,800023a4 <wait+0x56>
        release(&pp->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
        havekids = 1;
    80002430:	8756                	mv	a4,s5
    80002432:	bfd9                	j	80002408 <wait+0xba>
    if (!havekids || killed(p))
    80002434:	c719                	beqz	a4,80002442 <wait+0xf4>
    80002436:	854a                	mv	a0,s2
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	ee4080e7          	jalr	-284(ra) # 8000231c <killed>
    80002440:	c51d                	beqz	a0,8000246e <wait+0x120>
      release(&wait_lock);
    80002442:	0000e517          	auipc	a0,0xe
    80002446:	72650513          	addi	a0,a0,1830 # 80010b68 <wait_lock>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	840080e7          	jalr	-1984(ra) # 80000c8a <release>
      return -1;
    80002452:	59fd                	li	s3,-1
}
    80002454:	854e                	mv	a0,s3
    80002456:	60a6                	ld	ra,72(sp)
    80002458:	6406                	ld	s0,64(sp)
    8000245a:	74e2                	ld	s1,56(sp)
    8000245c:	7942                	ld	s2,48(sp)
    8000245e:	79a2                	ld	s3,40(sp)
    80002460:	7a02                	ld	s4,32(sp)
    80002462:	6ae2                	ld	s5,24(sp)
    80002464:	6b42                	ld	s6,16(sp)
    80002466:	6ba2                	ld	s7,8(sp)
    80002468:	6c02                	ld	s8,0(sp)
    8000246a:	6161                	addi	sp,sp,80
    8000246c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000246e:	85e2                	mv	a1,s8
    80002470:	854a                	mv	a0,s2
    80002472:	00000097          	auipc	ra,0x0
    80002476:	bf6080e7          	jalr	-1034(ra) # 80002068 <sleep>
    havekids = 0;
    8000247a:	bf39                	j	80002398 <wait+0x4a>

000000008000247c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000247c:	7179                	addi	sp,sp,-48
    8000247e:	f406                	sd	ra,40(sp)
    80002480:	f022                	sd	s0,32(sp)
    80002482:	ec26                	sd	s1,24(sp)
    80002484:	e84a                	sd	s2,16(sp)
    80002486:	e44e                	sd	s3,8(sp)
    80002488:	e052                	sd	s4,0(sp)
    8000248a:	1800                	addi	s0,sp,48
    8000248c:	84aa                	mv	s1,a0
    8000248e:	892e                	mv	s2,a1
    80002490:	89b2                	mv	s3,a2
    80002492:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	518080e7          	jalr	1304(ra) # 800019ac <myproc>
  if (user_dst)
    8000249c:	c08d                	beqz	s1,800024be <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000249e:	86d2                	mv	a3,s4
    800024a0:	864e                	mv	a2,s3
    800024a2:	85ca                	mv	a1,s2
    800024a4:	6928                	ld	a0,80(a0)
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	1c2080e7          	jalr	450(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ae:	70a2                	ld	ra,40(sp)
    800024b0:	7402                	ld	s0,32(sp)
    800024b2:	64e2                	ld	s1,24(sp)
    800024b4:	6942                	ld	s2,16(sp)
    800024b6:	69a2                	ld	s3,8(sp)
    800024b8:	6a02                	ld	s4,0(sp)
    800024ba:	6145                	addi	sp,sp,48
    800024bc:	8082                	ret
    memmove((char *)dst, src, len);
    800024be:	000a061b          	sext.w	a2,s4
    800024c2:	85ce                	mv	a1,s3
    800024c4:	854a                	mv	a0,s2
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	868080e7          	jalr	-1944(ra) # 80000d2e <memmove>
    return 0;
    800024ce:	8526                	mv	a0,s1
    800024d0:	bff9                	j	800024ae <either_copyout+0x32>

00000000800024d2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d2:	7179                	addi	sp,sp,-48
    800024d4:	f406                	sd	ra,40(sp)
    800024d6:	f022                	sd	s0,32(sp)
    800024d8:	ec26                	sd	s1,24(sp)
    800024da:	e84a                	sd	s2,16(sp)
    800024dc:	e44e                	sd	s3,8(sp)
    800024de:	e052                	sd	s4,0(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	892a                	mv	s2,a0
    800024e4:	84ae                	mv	s1,a1
    800024e6:	89b2                	mv	s3,a2
    800024e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	4c2080e7          	jalr	1218(ra) # 800019ac <myproc>
  if (user_src)
    800024f2:	c08d                	beqz	s1,80002514 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024f4:	86d2                	mv	a3,s4
    800024f6:	864e                	mv	a2,s3
    800024f8:	85ca                	mv	a1,s2
    800024fa:	6928                	ld	a0,80(a0)
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	1f8080e7          	jalr	504(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002504:	70a2                	ld	ra,40(sp)
    80002506:	7402                	ld	s0,32(sp)
    80002508:	64e2                	ld	s1,24(sp)
    8000250a:	6942                	ld	s2,16(sp)
    8000250c:	69a2                	ld	s3,8(sp)
    8000250e:	6a02                	ld	s4,0(sp)
    80002510:	6145                	addi	sp,sp,48
    80002512:	8082                	ret
    memmove(dst, (char *)src, len);
    80002514:	000a061b          	sext.w	a2,s4
    80002518:	85ce                	mv	a1,s3
    8000251a:	854a                	mv	a0,s2
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	812080e7          	jalr	-2030(ra) # 80000d2e <memmove>
    return 0;
    80002524:	8526                	mv	a0,s1
    80002526:	bff9                	j	80002504 <either_copyin+0x32>

0000000080002528 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002528:	715d                	addi	sp,sp,-80
    8000252a:	e486                	sd	ra,72(sp)
    8000252c:	e0a2                	sd	s0,64(sp)
    8000252e:	fc26                	sd	s1,56(sp)
    80002530:	f84a                	sd	s2,48(sp)
    80002532:	f44e                	sd	s3,40(sp)
    80002534:	f052                	sd	s4,32(sp)
    80002536:	ec56                	sd	s5,24(sp)
    80002538:	e85a                	sd	s6,16(sp)
    8000253a:	e45e                	sd	s7,8(sp)
    8000253c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000253e:	00006517          	auipc	a0,0x6
    80002542:	b8a50513          	addi	a0,a0,-1142 # 800080c8 <digits+0x88>
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	042080e7          	jalr	66(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000254e:	0000f497          	auipc	s1,0xf
    80002552:	b8a48493          	addi	s1,s1,-1142 # 800110d8 <proc+0x158>
    80002556:	00015917          	auipc	s2,0x15
    8000255a:	98290913          	addi	s2,s2,-1662 # 80016ed8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002560:	00006997          	auipc	s3,0x6
    80002564:	d2098993          	addi	s3,s3,-736 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002568:	00006a97          	auipc	s5,0x6
    8000256c:	d20a8a93          	addi	s5,s5,-736 # 80008288 <digits+0x248>
    printf("\n");
    80002570:	00006a17          	auipc	s4,0x6
    80002574:	b58a0a13          	addi	s4,s4,-1192 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002578:	00006b97          	auipc	s7,0x6
    8000257c:	d50b8b93          	addi	s7,s7,-688 # 800082c8 <states.0>
    80002580:	a00d                	j	800025a2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002582:	ed86a583          	lw	a1,-296(a3)
    80002586:	8556                	mv	a0,s5
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	000080e7          	jalr	ra # 80000588 <printf>
    printf("\n");
    80002590:	8552                	mv	a0,s4
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	ff6080e7          	jalr	-10(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000259a:	17848493          	addi	s1,s1,376
    8000259e:	03248163          	beq	s1,s2,800025c0 <procdump+0x98>
    if (p->state == UNUSED)
    800025a2:	86a6                	mv	a3,s1
    800025a4:	ec04a783          	lw	a5,-320(s1)
    800025a8:	dbed                	beqz	a5,8000259a <procdump+0x72>
      state = "???";
    800025aa:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ac:	fcfb6be3          	bltu	s6,a5,80002582 <procdump+0x5a>
    800025b0:	1782                	slli	a5,a5,0x20
    800025b2:	9381                	srli	a5,a5,0x20
    800025b4:	078e                	slli	a5,a5,0x3
    800025b6:	97de                	add	a5,a5,s7
    800025b8:	6390                	ld	a2,0(a5)
    800025ba:	f661                	bnez	a2,80002582 <procdump+0x5a>
      state = "???";
    800025bc:	864e                	mv	a2,s3
    800025be:	b7d1                	j	80002582 <procdump+0x5a>
  }
}
    800025c0:	60a6                	ld	ra,72(sp)
    800025c2:	6406                	ld	s0,64(sp)
    800025c4:	74e2                	ld	s1,56(sp)
    800025c6:	7942                	ld	s2,48(sp)
    800025c8:	79a2                	ld	s3,40(sp)
    800025ca:	7a02                	ld	s4,32(sp)
    800025cc:	6ae2                	ld	s5,24(sp)
    800025ce:	6b42                	ld	s6,16(sp)
    800025d0:	6ba2                	ld	s7,8(sp)
    800025d2:	6161                	addi	sp,sp,80
    800025d4:	8082                	ret

00000000800025d6 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800025d6:	711d                	addi	sp,sp,-96
    800025d8:	ec86                	sd	ra,88(sp)
    800025da:	e8a2                	sd	s0,80(sp)
    800025dc:	e4a6                	sd	s1,72(sp)
    800025de:	e0ca                	sd	s2,64(sp)
    800025e0:	fc4e                	sd	s3,56(sp)
    800025e2:	f852                	sd	s4,48(sp)
    800025e4:	f456                	sd	s5,40(sp)
    800025e6:	f05a                	sd	s6,32(sp)
    800025e8:	ec5e                	sd	s7,24(sp)
    800025ea:	e862                	sd	s8,16(sp)
    800025ec:	e466                	sd	s9,8(sp)
    800025ee:	e06a                	sd	s10,0(sp)
    800025f0:	1080                	addi	s0,sp,96
    800025f2:	8b2a                	mv	s6,a0
    800025f4:	8bae                	mv	s7,a1
    800025f6:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	3b4080e7          	jalr	948(ra) # 800019ac <myproc>
    80002600:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002602:	0000e517          	auipc	a0,0xe
    80002606:	56650513          	addi	a0,a0,1382 # 80010b68 <wait_lock>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	5cc080e7          	jalr	1484(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002612:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002614:	4a15                	li	s4,5
        havekids = 1;
    80002616:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002618:	00014997          	auipc	s3,0x14
    8000261c:	76898993          	addi	s3,s3,1896 # 80016d80 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002620:	0000ed17          	auipc	s10,0xe
    80002624:	548d0d13          	addi	s10,s10,1352 # 80010b68 <wait_lock>
    havekids = 0;
    80002628:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000262a:	0000f497          	auipc	s1,0xf
    8000262e:	95648493          	addi	s1,s1,-1706 # 80010f80 <proc>
    80002632:	a059                	j	800026b8 <waitx+0xe2>
          pid = np->pid;
    80002634:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002638:	1684a703          	lw	a4,360(s1)
    8000263c:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002640:	16c4a783          	lw	a5,364(s1)
    80002644:	9f3d                	addw	a4,a4,a5
    80002646:	1704a783          	lw	a5,368(s1)
    8000264a:	9f99                	subw	a5,a5,a4
    8000264c:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002650:	000b0e63          	beqz	s6,8000266c <waitx+0x96>
    80002654:	4691                	li	a3,4
    80002656:	02c48613          	addi	a2,s1,44
    8000265a:	85da                	mv	a1,s6
    8000265c:	05093503          	ld	a0,80(s2)
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	008080e7          	jalr	8(ra) # 80001668 <copyout>
    80002668:	02054563          	bltz	a0,80002692 <waitx+0xbc>
          freeproc(np);
    8000266c:	8526                	mv	a0,s1
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	4f0080e7          	jalr	1264(ra) # 80001b5e <freeproc>
          release(&np->lock);
    80002676:	8526                	mv	a0,s1
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	612080e7          	jalr	1554(ra) # 80000c8a <release>
          release(&wait_lock);
    80002680:	0000e517          	auipc	a0,0xe
    80002684:	4e850513          	addi	a0,a0,1256 # 80010b68 <wait_lock>
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	602080e7          	jalr	1538(ra) # 80000c8a <release>
          return pid;
    80002690:	a09d                	j	800026f6 <waitx+0x120>
            release(&np->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	5f6080e7          	jalr	1526(ra) # 80000c8a <release>
            release(&wait_lock);
    8000269c:	0000e517          	auipc	a0,0xe
    800026a0:	4cc50513          	addi	a0,a0,1228 # 80010b68 <wait_lock>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5e6080e7          	jalr	1510(ra) # 80000c8a <release>
            return -1;
    800026ac:	59fd                	li	s3,-1
    800026ae:	a0a1                	j	800026f6 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800026b0:	17848493          	addi	s1,s1,376
    800026b4:	03348463          	beq	s1,s3,800026dc <waitx+0x106>
      if (np->parent == p)
    800026b8:	7c9c                	ld	a5,56(s1)
    800026ba:	ff279be3          	bne	a5,s2,800026b0 <waitx+0xda>
        acquire(&np->lock);
    800026be:	8526                	mv	a0,s1
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	516080e7          	jalr	1302(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800026c8:	4c9c                	lw	a5,24(s1)
    800026ca:	f74785e3          	beq	a5,s4,80002634 <waitx+0x5e>
        release(&np->lock);
    800026ce:	8526                	mv	a0,s1
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	5ba080e7          	jalr	1466(ra) # 80000c8a <release>
        havekids = 1;
    800026d8:	8756                	mv	a4,s5
    800026da:	bfd9                	j	800026b0 <waitx+0xda>
    if (!havekids || p->killed)
    800026dc:	c701                	beqz	a4,800026e4 <waitx+0x10e>
    800026de:	02892783          	lw	a5,40(s2)
    800026e2:	cb8d                	beqz	a5,80002714 <waitx+0x13e>
      release(&wait_lock);
    800026e4:	0000e517          	auipc	a0,0xe
    800026e8:	48450513          	addi	a0,a0,1156 # 80010b68 <wait_lock>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	59e080e7          	jalr	1438(ra) # 80000c8a <release>
      return -1;
    800026f4:	59fd                	li	s3,-1
  }
}
    800026f6:	854e                	mv	a0,s3
    800026f8:	60e6                	ld	ra,88(sp)
    800026fa:	6446                	ld	s0,80(sp)
    800026fc:	64a6                	ld	s1,72(sp)
    800026fe:	6906                	ld	s2,64(sp)
    80002700:	79e2                	ld	s3,56(sp)
    80002702:	7a42                	ld	s4,48(sp)
    80002704:	7aa2                	ld	s5,40(sp)
    80002706:	7b02                	ld	s6,32(sp)
    80002708:	6be2                	ld	s7,24(sp)
    8000270a:	6c42                	ld	s8,16(sp)
    8000270c:	6ca2                	ld	s9,8(sp)
    8000270e:	6d02                	ld	s10,0(sp)
    80002710:	6125                	addi	sp,sp,96
    80002712:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002714:	85ea                	mv	a1,s10
    80002716:	854a                	mv	a0,s2
    80002718:	00000097          	auipc	ra,0x0
    8000271c:	950080e7          	jalr	-1712(ra) # 80002068 <sleep>
    havekids = 0;
    80002720:	b721                	j	80002628 <waitx+0x52>

0000000080002722 <update_time>:

void update_time()
{
    80002722:	7179                	addi	sp,sp,-48
    80002724:	f406                	sd	ra,40(sp)
    80002726:	f022                	sd	s0,32(sp)
    80002728:	ec26                	sd	s1,24(sp)
    8000272a:	e84a                	sd	s2,16(sp)
    8000272c:	e44e                	sd	s3,8(sp)
    8000272e:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002730:	0000f497          	auipc	s1,0xf
    80002734:	85048493          	addi	s1,s1,-1968 # 80010f80 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002738:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000273a:	00014917          	auipc	s2,0x14
    8000273e:	64690913          	addi	s2,s2,1606 # 80016d80 <tickslock>
    80002742:	a811                	j	80002756 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000274e:	17848493          	addi	s1,s1,376
    80002752:	03248063          	beq	s1,s2,80002772 <update_time+0x50>
    acquire(&p->lock);
    80002756:	8526                	mv	a0,s1
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	47e080e7          	jalr	1150(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002760:	4c9c                	lw	a5,24(s1)
    80002762:	ff3791e3          	bne	a5,s3,80002744 <update_time+0x22>
      p->rtime++;
    80002766:	1684a783          	lw	a5,360(s1)
    8000276a:	2785                	addiw	a5,a5,1
    8000276c:	16f4a423          	sw	a5,360(s1)
    80002770:	bfd1                	j	80002744 <update_time+0x22>
  }
    80002772:	70a2                	ld	ra,40(sp)
    80002774:	7402                	ld	s0,32(sp)
    80002776:	64e2                	ld	s1,24(sp)
    80002778:	6942                	ld	s2,16(sp)
    8000277a:	69a2                	ld	s3,8(sp)
    8000277c:	6145                	addi	sp,sp,48
    8000277e:	8082                	ret

0000000080002780 <swtch>:
    80002780:	00153023          	sd	ra,0(a0)
    80002784:	00253423          	sd	sp,8(a0)
    80002788:	e900                	sd	s0,16(a0)
    8000278a:	ed04                	sd	s1,24(a0)
    8000278c:	03253023          	sd	s2,32(a0)
    80002790:	03353423          	sd	s3,40(a0)
    80002794:	03453823          	sd	s4,48(a0)
    80002798:	03553c23          	sd	s5,56(a0)
    8000279c:	05653023          	sd	s6,64(a0)
    800027a0:	05753423          	sd	s7,72(a0)
    800027a4:	05853823          	sd	s8,80(a0)
    800027a8:	05953c23          	sd	s9,88(a0)
    800027ac:	07a53023          	sd	s10,96(a0)
    800027b0:	07b53423          	sd	s11,104(a0)
    800027b4:	0005b083          	ld	ra,0(a1)
    800027b8:	0085b103          	ld	sp,8(a1)
    800027bc:	6980                	ld	s0,16(a1)
    800027be:	6d84                	ld	s1,24(a1)
    800027c0:	0205b903          	ld	s2,32(a1)
    800027c4:	0285b983          	ld	s3,40(a1)
    800027c8:	0305ba03          	ld	s4,48(a1)
    800027cc:	0385ba83          	ld	s5,56(a1)
    800027d0:	0405bb03          	ld	s6,64(a1)
    800027d4:	0485bb83          	ld	s7,72(a1)
    800027d8:	0505bc03          	ld	s8,80(a1)
    800027dc:	0585bc83          	ld	s9,88(a1)
    800027e0:	0605bd03          	ld	s10,96(a1)
    800027e4:	0685bd83          	ld	s11,104(a1)
    800027e8:	8082                	ret

00000000800027ea <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800027ea:	1141                	addi	sp,sp,-16
    800027ec:	e406                	sd	ra,8(sp)
    800027ee:	e022                	sd	s0,0(sp)
    800027f0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027f2:	00006597          	auipc	a1,0x6
    800027f6:	b0658593          	addi	a1,a1,-1274 # 800082f8 <states.0+0x30>
    800027fa:	00014517          	auipc	a0,0x14
    800027fe:	58650513          	addi	a0,a0,1414 # 80016d80 <tickslock>
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	344080e7          	jalr	836(ra) # 80000b46 <initlock>
}
    8000280a:	60a2                	ld	ra,8(sp)
    8000280c:	6402                	ld	s0,0(sp)
    8000280e:	0141                	addi	sp,sp,16
    80002810:	8082                	ret

0000000080002812 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002812:	1141                	addi	sp,sp,-16
    80002814:	e422                	sd	s0,8(sp)
    80002816:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002818:	00003797          	auipc	a5,0x3
    8000281c:	59878793          	addi	a5,a5,1432 # 80005db0 <kernelvec>
    80002820:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002824:	6422                	ld	s0,8(sp)
    80002826:	0141                	addi	sp,sp,16
    80002828:	8082                	ret

000000008000282a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000282a:	1141                	addi	sp,sp,-16
    8000282c:	e406                	sd	ra,8(sp)
    8000282e:	e022                	sd	s0,0(sp)
    80002830:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	17a080e7          	jalr	378(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000283e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002840:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002844:	00004617          	auipc	a2,0x4
    80002848:	7bc60613          	addi	a2,a2,1980 # 80007000 <_trampoline>
    8000284c:	00004697          	auipc	a3,0x4
    80002850:	7b468693          	addi	a3,a3,1972 # 80007000 <_trampoline>
    80002854:	8e91                	sub	a3,a3,a2
    80002856:	040007b7          	lui	a5,0x4000
    8000285a:	17fd                	addi	a5,a5,-1
    8000285c:	07b2                	slli	a5,a5,0xc
    8000285e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002860:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002864:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002866:	180026f3          	csrr	a3,satp
    8000286a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000286c:	6d38                	ld	a4,88(a0)
    8000286e:	6134                	ld	a3,64(a0)
    80002870:	6585                	lui	a1,0x1
    80002872:	96ae                	add	a3,a3,a1
    80002874:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002876:	6d38                	ld	a4,88(a0)
    80002878:	00000697          	auipc	a3,0x0
    8000287c:	13e68693          	addi	a3,a3,318 # 800029b6 <usertrap>
    80002880:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002882:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002884:	8692                	mv	a3,tp
    80002886:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000288c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002890:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002894:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002898:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000289a:	6f18                	ld	a4,24(a4)
    8000289c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028a0:	6928                	ld	a0,80(a0)
    800028a2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028a4:	00004717          	auipc	a4,0x4
    800028a8:	7f870713          	addi	a4,a4,2040 # 8000709c <userret>
    800028ac:	8f11                	sub	a4,a4,a2
    800028ae:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028b0:	577d                	li	a4,-1
    800028b2:	177e                	slli	a4,a4,0x3f
    800028b4:	8d59                	or	a0,a0,a4
    800028b6:	9782                	jalr	a5
}
    800028b8:	60a2                	ld	ra,8(sp)
    800028ba:	6402                	ld	s0,0(sp)
    800028bc:	0141                	addi	sp,sp,16
    800028be:	8082                	ret

00000000800028c0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800028c0:	1101                	addi	sp,sp,-32
    800028c2:	ec06                	sd	ra,24(sp)
    800028c4:	e822                	sd	s0,16(sp)
    800028c6:	e426                	sd	s1,8(sp)
    800028c8:	e04a                	sd	s2,0(sp)
    800028ca:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028cc:	00014917          	auipc	s2,0x14
    800028d0:	4b490913          	addi	s2,s2,1204 # 80016d80 <tickslock>
    800028d4:	854a                	mv	a0,s2
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  ticks++;
    800028de:	00006497          	auipc	s1,0x6
    800028e2:	00248493          	addi	s1,s1,2 # 800088e0 <ticks>
    800028e6:	409c                	lw	a5,0(s1)
    800028e8:	2785                	addiw	a5,a5,1
    800028ea:	c09c                	sw	a5,0(s1)
  update_time();
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	e36080e7          	jalr	-458(ra) # 80002722 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    800028f4:	8526                	mv	a0,s1
    800028f6:	fffff097          	auipc	ra,0xfffff
    800028fa:	7d6080e7          	jalr	2006(ra) # 800020cc <wakeup>
  release(&tickslock);
    800028fe:	854a                	mv	a0,s2
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	38a080e7          	jalr	906(ra) # 80000c8a <release>
}
    80002908:	60e2                	ld	ra,24(sp)
    8000290a:	6442                	ld	s0,16(sp)
    8000290c:	64a2                	ld	s1,8(sp)
    8000290e:	6902                	ld	s2,0(sp)
    80002910:	6105                	addi	sp,sp,32
    80002912:	8082                	ret

0000000080002914 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002914:	1101                	addi	sp,sp,-32
    80002916:	ec06                	sd	ra,24(sp)
    80002918:	e822                	sd	s0,16(sp)
    8000291a:	e426                	sd	s1,8(sp)
    8000291c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002922:	00074d63          	bltz	a4,8000293c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002926:	57fd                	li	a5,-1
    80002928:	17fe                	slli	a5,a5,0x3f
    8000292a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    8000292c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    8000292e:	06f70363          	beq	a4,a5,80002994 <devintr+0x80>
  }
}
    80002932:	60e2                	ld	ra,24(sp)
    80002934:	6442                	ld	s0,16(sp)
    80002936:	64a2                	ld	s1,8(sp)
    80002938:	6105                	addi	sp,sp,32
    8000293a:	8082                	ret
      (scause & 0xff) == 9)
    8000293c:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002940:	46a5                	li	a3,9
    80002942:	fed792e3          	bne	a5,a3,80002926 <devintr+0x12>
    int irq = plic_claim();
    80002946:	00003097          	auipc	ra,0x3
    8000294a:	572080e7          	jalr	1394(ra) # 80005eb8 <plic_claim>
    8000294e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002950:	47a9                	li	a5,10
    80002952:	02f50763          	beq	a0,a5,80002980 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002956:	4785                	li	a5,1
    80002958:	02f50963          	beq	a0,a5,8000298a <devintr+0x76>
    return 1;
    8000295c:	4505                	li	a0,1
    else if (irq)
    8000295e:	d8f1                	beqz	s1,80002932 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002960:	85a6                	mv	a1,s1
    80002962:	00006517          	auipc	a0,0x6
    80002966:	99e50513          	addi	a0,a0,-1634 # 80008300 <states.0+0x38>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	c1e080e7          	jalr	-994(ra) # 80000588 <printf>
      plic_complete(irq);
    80002972:	8526                	mv	a0,s1
    80002974:	00003097          	auipc	ra,0x3
    80002978:	568080e7          	jalr	1384(ra) # 80005edc <plic_complete>
    return 1;
    8000297c:	4505                	li	a0,1
    8000297e:	bf55                	j	80002932 <devintr+0x1e>
      uartintr();
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	01a080e7          	jalr	26(ra) # 8000099a <uartintr>
    80002988:	b7ed                	j	80002972 <devintr+0x5e>
      virtio_disk_intr();
    8000298a:	00004097          	auipc	ra,0x4
    8000298e:	a1e080e7          	jalr	-1506(ra) # 800063a8 <virtio_disk_intr>
    80002992:	b7c5                	j	80002972 <devintr+0x5e>
    if (cpuid() == 0)
    80002994:	fffff097          	auipc	ra,0xfffff
    80002998:	fec080e7          	jalr	-20(ra) # 80001980 <cpuid>
    8000299c:	c901                	beqz	a0,800029ac <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000299e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029a2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029a4:	14479073          	csrw	sip,a5
    return 2;
    800029a8:	4509                	li	a0,2
    800029aa:	b761                	j	80002932 <devintr+0x1e>
      clockintr();
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	f14080e7          	jalr	-236(ra) # 800028c0 <clockintr>
    800029b4:	b7ed                	j	8000299e <devintr+0x8a>

00000000800029b6 <usertrap>:
{
    800029b6:	1101                	addi	sp,sp,-32
    800029b8:	ec06                	sd	ra,24(sp)
    800029ba:	e822                	sd	s0,16(sp)
    800029bc:	e426                	sd	s1,8(sp)
    800029be:	e04a                	sd	s2,0(sp)
    800029c0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800029c6:	1007f793          	andi	a5,a5,256
    800029ca:	e3b1                	bnez	a5,80002a0e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029cc:	00003797          	auipc	a5,0x3
    800029d0:	3e478793          	addi	a5,a5,996 # 80005db0 <kernelvec>
    800029d4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	fd4080e7          	jalr	-44(ra) # 800019ac <myproc>
    800029e0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029e2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e4:	14102773          	csrr	a4,sepc
    800029e8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ea:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    800029ee:	47a1                	li	a5,8
    800029f0:	02f70763          	beq	a4,a5,80002a1e <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    800029f4:	00000097          	auipc	ra,0x0
    800029f8:	f20080e7          	jalr	-224(ra) # 80002914 <devintr>
    800029fc:	892a                	mv	s2,a0
    800029fe:	c151                	beqz	a0,80002a82 <usertrap+0xcc>
  if (killed(p))
    80002a00:	8526                	mv	a0,s1
    80002a02:	00000097          	auipc	ra,0x0
    80002a06:	91a080e7          	jalr	-1766(ra) # 8000231c <killed>
    80002a0a:	c929                	beqz	a0,80002a5c <usertrap+0xa6>
    80002a0c:	a099                	j	80002a52 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	91250513          	addi	a0,a0,-1774 # 80008320 <states.0+0x58>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>
    if (killed(p))
    80002a1e:	00000097          	auipc	ra,0x0
    80002a22:	8fe080e7          	jalr	-1794(ra) # 8000231c <killed>
    80002a26:	e921                	bnez	a0,80002a76 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a28:	6cb8                	ld	a4,88(s1)
    80002a2a:	6f1c                	ld	a5,24(a4)
    80002a2c:	0791                	addi	a5,a5,4
    80002a2e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a34:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a38:	10079073          	csrw	sstatus,a5
    syscall();
    80002a3c:	00000097          	auipc	ra,0x0
    80002a40:	2d4080e7          	jalr	724(ra) # 80002d10 <syscall>
  if (killed(p))
    80002a44:	8526                	mv	a0,s1
    80002a46:	00000097          	auipc	ra,0x0
    80002a4a:	8d6080e7          	jalr	-1834(ra) # 8000231c <killed>
    80002a4e:	c911                	beqz	a0,80002a62 <usertrap+0xac>
    80002a50:	4901                	li	s2,0
    exit(-1);
    80002a52:	557d                	li	a0,-1
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	748080e7          	jalr	1864(ra) # 8000219c <exit>
  if (which_dev == 2)
    80002a5c:	4789                	li	a5,2
    80002a5e:	04f90f63          	beq	s2,a5,80002abc <usertrap+0x106>
  usertrapret();
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	dc8080e7          	jalr	-568(ra) # 8000282a <usertrapret>
}
    80002a6a:	60e2                	ld	ra,24(sp)
    80002a6c:	6442                	ld	s0,16(sp)
    80002a6e:	64a2                	ld	s1,8(sp)
    80002a70:	6902                	ld	s2,0(sp)
    80002a72:	6105                	addi	sp,sp,32
    80002a74:	8082                	ret
      exit(-1);
    80002a76:	557d                	li	a0,-1
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	724080e7          	jalr	1828(ra) # 8000219c <exit>
    80002a80:	b765                	j	80002a28 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a82:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a86:	5890                	lw	a2,48(s1)
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	8b850513          	addi	a0,a0,-1864 # 80008340 <states.0+0x78>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	af8080e7          	jalr	-1288(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a98:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a9c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aa0:	00006517          	auipc	a0,0x6
    80002aa4:	8d050513          	addi	a0,a0,-1840 # 80008370 <states.0+0xa8>
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	ae0080e7          	jalr	-1312(ra) # 80000588 <printf>
    setkilled(p);
    80002ab0:	8526                	mv	a0,s1
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	83e080e7          	jalr	-1986(ra) # 800022f0 <setkilled>
    80002aba:	b769                	j	80002a44 <usertrap+0x8e>
    yield();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	570080e7          	jalr	1392(ra) # 8000202c <yield>
    80002ac4:	bf79                	j	80002a62 <usertrap+0xac>

0000000080002ac6 <kerneltrap>:
{
    80002ac6:	7179                	addi	sp,sp,-48
    80002ac8:	f406                	sd	ra,40(sp)
    80002aca:	f022                	sd	s0,32(sp)
    80002acc:	ec26                	sd	s1,24(sp)
    80002ace:	e84a                	sd	s2,16(sp)
    80002ad0:	e44e                	sd	s3,8(sp)
    80002ad2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002adc:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002ae0:	1004f793          	andi	a5,s1,256
    80002ae4:	cb85                	beqz	a5,80002b14 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aea:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002aec:	ef85                	bnez	a5,80002b24 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	e26080e7          	jalr	-474(ra) # 80002914 <devintr>
    80002af6:	cd1d                	beqz	a0,80002b34 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002af8:	4789                	li	a5,2
    80002afa:	06f50a63          	beq	a0,a5,80002b6e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002afe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b02:	10049073          	csrw	sstatus,s1
}
    80002b06:	70a2                	ld	ra,40(sp)
    80002b08:	7402                	ld	s0,32(sp)
    80002b0a:	64e2                	ld	s1,24(sp)
    80002b0c:	6942                	ld	s2,16(sp)
    80002b0e:	69a2                	ld	s3,8(sp)
    80002b10:	6145                	addi	sp,sp,48
    80002b12:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	87c50513          	addi	a0,a0,-1924 # 80008390 <states.0+0xc8>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a22080e7          	jalr	-1502(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	89450513          	addi	a0,a0,-1900 # 800083b8 <states.0+0xf0>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b34:	85ce                	mv	a1,s3
    80002b36:	00006517          	auipc	a0,0x6
    80002b3a:	8a250513          	addi	a0,a0,-1886 # 800083d8 <states.0+0x110>
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	a4a080e7          	jalr	-1462(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b46:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b4a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b4e:	00006517          	auipc	a0,0x6
    80002b52:	89a50513          	addi	a0,a0,-1894 # 800083e8 <states.0+0x120>
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	a32080e7          	jalr	-1486(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b5e:	00006517          	auipc	a0,0x6
    80002b62:	8a250513          	addi	a0,a0,-1886 # 80008400 <states.0+0x138>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	9d8080e7          	jalr	-1576(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	e3e080e7          	jalr	-450(ra) # 800019ac <myproc>
    80002b76:	d541                	beqz	a0,80002afe <kerneltrap+0x38>
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	e34080e7          	jalr	-460(ra) # 800019ac <myproc>
    80002b80:	4d18                	lw	a4,24(a0)
    80002b82:	4791                	li	a5,4
    80002b84:	f6f71de3          	bne	a4,a5,80002afe <kerneltrap+0x38>
    yield();
    80002b88:	fffff097          	auipc	ra,0xfffff
    80002b8c:	4a4080e7          	jalr	1188(ra) # 8000202c <yield>
    80002b90:	b7bd                	j	80002afe <kerneltrap+0x38>

0000000080002b92 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b92:	1101                	addi	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	e426                	sd	s1,8(sp)
    80002b9a:	1000                	addi	s0,sp,32
    80002b9c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	e0e080e7          	jalr	-498(ra) # 800019ac <myproc>
  switch (n) {
    80002ba6:	4795                	li	a5,5
    80002ba8:	0497e163          	bltu	a5,s1,80002bea <argraw+0x58>
    80002bac:	048a                	slli	s1,s1,0x2
    80002bae:	00006717          	auipc	a4,0x6
    80002bb2:	88a70713          	addi	a4,a4,-1910 # 80008438 <states.0+0x170>
    80002bb6:	94ba                	add	s1,s1,a4
    80002bb8:	409c                	lw	a5,0(s1)
    80002bba:	97ba                	add	a5,a5,a4
    80002bbc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bbe:	6d3c                	ld	a5,88(a0)
    80002bc0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6105                	addi	sp,sp,32
    80002bca:	8082                	ret
    return p->trapframe->a1;
    80002bcc:	6d3c                	ld	a5,88(a0)
    80002bce:	7fa8                	ld	a0,120(a5)
    80002bd0:	bfcd                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a2;
    80002bd2:	6d3c                	ld	a5,88(a0)
    80002bd4:	63c8                	ld	a0,128(a5)
    80002bd6:	b7f5                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a3;
    80002bd8:	6d3c                	ld	a5,88(a0)
    80002bda:	67c8                	ld	a0,136(a5)
    80002bdc:	b7dd                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a4;
    80002bde:	6d3c                	ld	a5,88(a0)
    80002be0:	6bc8                	ld	a0,144(a5)
    80002be2:	b7c5                	j	80002bc2 <argraw+0x30>
    return p->trapframe->a5;
    80002be4:	6d3c                	ld	a5,88(a0)
    80002be6:	6fc8                	ld	a0,152(a5)
    80002be8:	bfe9                	j	80002bc2 <argraw+0x30>
  panic("argraw");
    80002bea:	00006517          	auipc	a0,0x6
    80002bee:	82650513          	addi	a0,a0,-2010 # 80008410 <states.0+0x148>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	94c080e7          	jalr	-1716(ra) # 8000053e <panic>

0000000080002bfa <fetchaddr>:
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	e04a                	sd	s2,0(sp)
    80002c04:	1000                	addi	s0,sp,32
    80002c06:	84aa                	mv	s1,a0
    80002c08:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c0a:	fffff097          	auipc	ra,0xfffff
    80002c0e:	da2080e7          	jalr	-606(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c12:	653c                	ld	a5,72(a0)
    80002c14:	02f4f863          	bgeu	s1,a5,80002c44 <fetchaddr+0x4a>
    80002c18:	00848713          	addi	a4,s1,8
    80002c1c:	02e7e663          	bltu	a5,a4,80002c48 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c20:	46a1                	li	a3,8
    80002c22:	8626                	mv	a2,s1
    80002c24:	85ca                	mv	a1,s2
    80002c26:	6928                	ld	a0,80(a0)
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	acc080e7          	jalr	-1332(ra) # 800016f4 <copyin>
    80002c30:	00a03533          	snez	a0,a0
    80002c34:	40a00533          	neg	a0,a0
}
    80002c38:	60e2                	ld	ra,24(sp)
    80002c3a:	6442                	ld	s0,16(sp)
    80002c3c:	64a2                	ld	s1,8(sp)
    80002c3e:	6902                	ld	s2,0(sp)
    80002c40:	6105                	addi	sp,sp,32
    80002c42:	8082                	ret
    return -1;
    80002c44:	557d                	li	a0,-1
    80002c46:	bfcd                	j	80002c38 <fetchaddr+0x3e>
    80002c48:	557d                	li	a0,-1
    80002c4a:	b7fd                	j	80002c38 <fetchaddr+0x3e>

0000000080002c4c <fetchstr>:
{
    80002c4c:	7179                	addi	sp,sp,-48
    80002c4e:	f406                	sd	ra,40(sp)
    80002c50:	f022                	sd	s0,32(sp)
    80002c52:	ec26                	sd	s1,24(sp)
    80002c54:	e84a                	sd	s2,16(sp)
    80002c56:	e44e                	sd	s3,8(sp)
    80002c58:	1800                	addi	s0,sp,48
    80002c5a:	892a                	mv	s2,a0
    80002c5c:	84ae                	mv	s1,a1
    80002c5e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	d4c080e7          	jalr	-692(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c68:	86ce                	mv	a3,s3
    80002c6a:	864a                	mv	a2,s2
    80002c6c:	85a6                	mv	a1,s1
    80002c6e:	6928                	ld	a0,80(a0)
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	b12080e7          	jalr	-1262(ra) # 80001782 <copyinstr>
    80002c78:	00054e63          	bltz	a0,80002c94 <fetchstr+0x48>
  return strlen(buf);
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	1d0080e7          	jalr	464(ra) # 80000e4e <strlen>
}
    80002c86:	70a2                	ld	ra,40(sp)
    80002c88:	7402                	ld	s0,32(sp)
    80002c8a:	64e2                	ld	s1,24(sp)
    80002c8c:	6942                	ld	s2,16(sp)
    80002c8e:	69a2                	ld	s3,8(sp)
    80002c90:	6145                	addi	sp,sp,48
    80002c92:	8082                	ret
    return -1;
    80002c94:	557d                	li	a0,-1
    80002c96:	bfc5                	j	80002c86 <fetchstr+0x3a>

0000000080002c98 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	e426                	sd	s1,8(sp)
    80002ca0:	1000                	addi	s0,sp,32
    80002ca2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	eee080e7          	jalr	-274(ra) # 80002b92 <argraw>
    80002cac:	c088                	sw	a0,0(s1)
}
    80002cae:	60e2                	ld	ra,24(sp)
    80002cb0:	6442                	ld	s0,16(sp)
    80002cb2:	64a2                	ld	s1,8(sp)
    80002cb4:	6105                	addi	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	ece080e7          	jalr	-306(ra) # 80002b92 <argraw>
    80002ccc:	e088                	sd	a0,0(s1)
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	64a2                	ld	s1,8(sp)
    80002cd4:	6105                	addi	sp,sp,32
    80002cd6:	8082                	ret

0000000080002cd8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cd8:	7179                	addi	sp,sp,-48
    80002cda:	f406                	sd	ra,40(sp)
    80002cdc:	f022                	sd	s0,32(sp)
    80002cde:	ec26                	sd	s1,24(sp)
    80002ce0:	e84a                	sd	s2,16(sp)
    80002ce2:	1800                	addi	s0,sp,48
    80002ce4:	84ae                	mv	s1,a1
    80002ce6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ce8:	fd840593          	addi	a1,s0,-40
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	fcc080e7          	jalr	-52(ra) # 80002cb8 <argaddr>
  return fetchstr(addr, buf, max);
    80002cf4:	864a                	mv	a2,s2
    80002cf6:	85a6                	mv	a1,s1
    80002cf8:	fd843503          	ld	a0,-40(s0)
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	f50080e7          	jalr	-176(ra) # 80002c4c <fetchstr>
}
    80002d04:	70a2                	ld	ra,40(sp)
    80002d06:	7402                	ld	s0,32(sp)
    80002d08:	64e2                	ld	s1,24(sp)
    80002d0a:	6942                	ld	s2,16(sp)
    80002d0c:	6145                	addi	sp,sp,48
    80002d0e:	8082                	ret

0000000080002d10 <syscall>:
[SYS_getreadcount]   getreadcount,
};

void
syscall(void)
{
    80002d10:	1101                	addi	sp,sp,-32
    80002d12:	ec06                	sd	ra,24(sp)
    80002d14:	e822                	sd	s0,16(sp)
    80002d16:	e426                	sd	s1,8(sp)
    80002d18:	e04a                	sd	s2,0(sp)
    80002d1a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	c90080e7          	jalr	-880(ra) # 800019ac <myproc>
    80002d24:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d26:	05853903          	ld	s2,88(a0)
    80002d2a:	0a893783          	ld	a5,168(s2)
    80002d2e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d32:	37fd                	addiw	a5,a5,-1
    80002d34:	4759                	li	a4,22
    80002d36:	00f76f63          	bltu	a4,a5,80002d54 <syscall+0x44>
    80002d3a:	00369713          	slli	a4,a3,0x3
    80002d3e:	00005797          	auipc	a5,0x5
    80002d42:	71278793          	addi	a5,a5,1810 # 80008450 <syscalls>
    80002d46:	97ba                	add	a5,a5,a4
    80002d48:	639c                	ld	a5,0(a5)
    80002d4a:	c789                	beqz	a5,80002d54 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d4c:	9782                	jalr	a5
    80002d4e:	06a93823          	sd	a0,112(s2)
    80002d52:	a839                	j	80002d70 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d54:	15848613          	addi	a2,s1,344
    80002d58:	588c                	lw	a1,48(s1)
    80002d5a:	00005517          	auipc	a0,0x5
    80002d5e:	6be50513          	addi	a0,a0,1726 # 80008418 <states.0+0x150>
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	826080e7          	jalr	-2010(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d6a:	6cbc                	ld	a5,88(s1)
    80002d6c:	577d                	li	a4,-1
    80002d6e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d70:	60e2                	ld	ra,24(sp)
    80002d72:	6442                	ld	s0,16(sp)
    80002d74:	64a2                	ld	s1,8(sp)
    80002d76:	6902                	ld	s2,0(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret

0000000080002d7c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d7c:	1101                	addi	sp,sp,-32
    80002d7e:	ec06                	sd	ra,24(sp)
    80002d80:	e822                	sd	s0,16(sp)
    80002d82:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d84:	fec40593          	addi	a1,s0,-20
    80002d88:	4501                	li	a0,0
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	f0e080e7          	jalr	-242(ra) # 80002c98 <argint>
  exit(n);
    80002d92:	fec42503          	lw	a0,-20(s0)
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	406080e7          	jalr	1030(ra) # 8000219c <exit>
  return 0; // not reached
}
    80002d9e:	4501                	li	a0,0
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002da8:	1141                	addi	sp,sp,-16
    80002daa:	e406                	sd	ra,8(sp)
    80002dac:	e022                	sd	s0,0(sp)
    80002dae:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	bfc080e7          	jalr	-1028(ra) # 800019ac <myproc>
}
    80002db8:	5908                	lw	a0,48(a0)
    80002dba:	60a2                	ld	ra,8(sp)
    80002dbc:	6402                	ld	s0,0(sp)
    80002dbe:	0141                	addi	sp,sp,16
    80002dc0:	8082                	ret

0000000080002dc2 <sys_fork>:

uint64
sys_fork(void)
{
    80002dc2:	1141                	addi	sp,sp,-16
    80002dc4:	e406                	sd	ra,8(sp)
    80002dc6:	e022                	sd	s0,0(sp)
    80002dc8:	0800                	addi	s0,sp,16
  return fork();
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	fac080e7          	jalr	-84(ra) # 80001d76 <fork>
}
    80002dd2:	60a2                	ld	ra,8(sp)
    80002dd4:	6402                	ld	s0,0(sp)
    80002dd6:	0141                	addi	sp,sp,16
    80002dd8:	8082                	ret

0000000080002dda <sys_wait>:

uint64
sys_wait(void)
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002de2:	fe840593          	addi	a1,s0,-24
    80002de6:	4501                	li	a0,0
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	ed0080e7          	jalr	-304(ra) # 80002cb8 <argaddr>
  return wait(p);
    80002df0:	fe843503          	ld	a0,-24(s0)
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	55a080e7          	jalr	1370(ra) # 8000234e <wait>
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e04:	7179                	addi	sp,sp,-48
    80002e06:	f406                	sd	ra,40(sp)
    80002e08:	f022                	sd	s0,32(sp)
    80002e0a:	ec26                	sd	s1,24(sp)
    80002e0c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e0e:	fdc40593          	addi	a1,s0,-36
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	e84080e7          	jalr	-380(ra) # 80002c98 <argint>
  addr = myproc()->sz;
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	b90080e7          	jalr	-1136(ra) # 800019ac <myproc>
    80002e24:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002e26:	fdc42503          	lw	a0,-36(s0)
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	ef0080e7          	jalr	-272(ra) # 80001d1a <growproc>
    80002e32:	00054863          	bltz	a0,80002e42 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e36:	8526                	mv	a0,s1
    80002e38:	70a2                	ld	ra,40(sp)
    80002e3a:	7402                	ld	s0,32(sp)
    80002e3c:	64e2                	ld	s1,24(sp)
    80002e3e:	6145                	addi	sp,sp,48
    80002e40:	8082                	ret
    return -1;
    80002e42:	54fd                	li	s1,-1
    80002e44:	bfcd                	j	80002e36 <sys_sbrk+0x32>

0000000080002e46 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e46:	7139                	addi	sp,sp,-64
    80002e48:	fc06                	sd	ra,56(sp)
    80002e4a:	f822                	sd	s0,48(sp)
    80002e4c:	f426                	sd	s1,40(sp)
    80002e4e:	f04a                	sd	s2,32(sp)
    80002e50:	ec4e                	sd	s3,24(sp)
    80002e52:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e54:	fcc40593          	addi	a1,s0,-52
    80002e58:	4501                	li	a0,0
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	e3e080e7          	jalr	-450(ra) # 80002c98 <argint>
  acquire(&tickslock);
    80002e62:	00014517          	auipc	a0,0x14
    80002e66:	f1e50513          	addi	a0,a0,-226 # 80016d80 <tickslock>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	d6c080e7          	jalr	-660(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e72:	00006917          	auipc	s2,0x6
    80002e76:	a6e92903          	lw	s2,-1426(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    80002e7a:	fcc42783          	lw	a5,-52(s0)
    80002e7e:	cf9d                	beqz	a5,80002ebc <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e80:	00014997          	auipc	s3,0x14
    80002e84:	f0098993          	addi	s3,s3,-256 # 80016d80 <tickslock>
    80002e88:	00006497          	auipc	s1,0x6
    80002e8c:	a5848493          	addi	s1,s1,-1448 # 800088e0 <ticks>
    if (killed(myproc()))
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	b1c080e7          	jalr	-1252(ra) # 800019ac <myproc>
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	484080e7          	jalr	1156(ra) # 8000231c <killed>
    80002ea0:	ed15                	bnez	a0,80002edc <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ea2:	85ce                	mv	a1,s3
    80002ea4:	8526                	mv	a0,s1
    80002ea6:	fffff097          	auipc	ra,0xfffff
    80002eaa:	1c2080e7          	jalr	450(ra) # 80002068 <sleep>
  while (ticks - ticks0 < n)
    80002eae:	409c                	lw	a5,0(s1)
    80002eb0:	412787bb          	subw	a5,a5,s2
    80002eb4:	fcc42703          	lw	a4,-52(s0)
    80002eb8:	fce7ece3          	bltu	a5,a4,80002e90 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ebc:	00014517          	auipc	a0,0x14
    80002ec0:	ec450513          	addi	a0,a0,-316 # 80016d80 <tickslock>
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	dc6080e7          	jalr	-570(ra) # 80000c8a <release>
  return 0;
    80002ecc:	4501                	li	a0,0
}
    80002ece:	70e2                	ld	ra,56(sp)
    80002ed0:	7442                	ld	s0,48(sp)
    80002ed2:	74a2                	ld	s1,40(sp)
    80002ed4:	7902                	ld	s2,32(sp)
    80002ed6:	69e2                	ld	s3,24(sp)
    80002ed8:	6121                	addi	sp,sp,64
    80002eda:	8082                	ret
      release(&tickslock);
    80002edc:	00014517          	auipc	a0,0x14
    80002ee0:	ea450513          	addi	a0,a0,-348 # 80016d80 <tickslock>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	da6080e7          	jalr	-602(ra) # 80000c8a <release>
      return -1;
    80002eec:	557d                	li	a0,-1
    80002eee:	b7c5                	j	80002ece <sys_sleep+0x88>

0000000080002ef0 <sys_kill>:

uint64
sys_kill(void)
{
    80002ef0:	1101                	addi	sp,sp,-32
    80002ef2:	ec06                	sd	ra,24(sp)
    80002ef4:	e822                	sd	s0,16(sp)
    80002ef6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ef8:	fec40593          	addi	a1,s0,-20
    80002efc:	4501                	li	a0,0
    80002efe:	00000097          	auipc	ra,0x0
    80002f02:	d9a080e7          	jalr	-614(ra) # 80002c98 <argint>
  return kill(pid);
    80002f06:	fec42503          	lw	a0,-20(s0)
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	374080e7          	jalr	884(ra) # 8000227e <kill>
}
    80002f12:	60e2                	ld	ra,24(sp)
    80002f14:	6442                	ld	s0,16(sp)
    80002f16:	6105                	addi	sp,sp,32
    80002f18:	8082                	ret

0000000080002f1a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f24:	00014517          	auipc	a0,0x14
    80002f28:	e5c50513          	addi	a0,a0,-420 # 80016d80 <tickslock>
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	caa080e7          	jalr	-854(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f34:	00006497          	auipc	s1,0x6
    80002f38:	9ac4a483          	lw	s1,-1620(s1) # 800088e0 <ticks>
  release(&tickslock);
    80002f3c:	00014517          	auipc	a0,0x14
    80002f40:	e4450513          	addi	a0,a0,-444 # 80016d80 <tickslock>
    80002f44:	ffffe097          	auipc	ra,0xffffe
    80002f48:	d46080e7          	jalr	-698(ra) # 80000c8a <release>
  return xticks;
}
    80002f4c:	02049513          	slli	a0,s1,0x20
    80002f50:	9101                	srli	a0,a0,0x20
    80002f52:	60e2                	ld	ra,24(sp)
    80002f54:	6442                	ld	s0,16(sp)
    80002f56:	64a2                	ld	s1,8(sp)
    80002f58:	6105                	addi	sp,sp,32
    80002f5a:	8082                	ret

0000000080002f5c <sys_waitx>:

uint64
sys_waitx(void)
{
    80002f5c:	7139                	addi	sp,sp,-64
    80002f5e:	fc06                	sd	ra,56(sp)
    80002f60:	f822                	sd	s0,48(sp)
    80002f62:	f426                	sd	s1,40(sp)
    80002f64:	f04a                	sd	s2,32(sp)
    80002f66:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002f68:	fd840593          	addi	a1,s0,-40
    80002f6c:	4501                	li	a0,0
    80002f6e:	00000097          	auipc	ra,0x0
    80002f72:	d4a080e7          	jalr	-694(ra) # 80002cb8 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002f76:	fd040593          	addi	a1,s0,-48
    80002f7a:	4505                	li	a0,1
    80002f7c:	00000097          	auipc	ra,0x0
    80002f80:	d3c080e7          	jalr	-708(ra) # 80002cb8 <argaddr>
  argaddr(2, &addr2);
    80002f84:	fc840593          	addi	a1,s0,-56
    80002f88:	4509                	li	a0,2
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	d2e080e7          	jalr	-722(ra) # 80002cb8 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80002f92:	fc040613          	addi	a2,s0,-64
    80002f96:	fc440593          	addi	a1,s0,-60
    80002f9a:	fd843503          	ld	a0,-40(s0)
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	638080e7          	jalr	1592(ra) # 800025d6 <waitx>
    80002fa6:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	a04080e7          	jalr	-1532(ra) # 800019ac <myproc>
    80002fb0:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fb2:	4691                	li	a3,4
    80002fb4:	fc440613          	addi	a2,s0,-60
    80002fb8:	fd043583          	ld	a1,-48(s0)
    80002fbc:	6928                	ld	a0,80(a0)
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	6aa080e7          	jalr	1706(ra) # 80001668 <copyout>
    return -1;
    80002fc6:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80002fc8:	00054f63          	bltz	a0,80002fe6 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80002fcc:	4691                	li	a3,4
    80002fce:	fc040613          	addi	a2,s0,-64
    80002fd2:	fc843583          	ld	a1,-56(s0)
    80002fd6:	68a8                	ld	a0,80(s1)
    80002fd8:	ffffe097          	auipc	ra,0xffffe
    80002fdc:	690080e7          	jalr	1680(ra) # 80001668 <copyout>
    80002fe0:	00054a63          	bltz	a0,80002ff4 <sys_waitx+0x98>
    return -1;
  return ret;
    80002fe4:	87ca                	mv	a5,s2
    80002fe6:	853e                	mv	a0,a5
    80002fe8:	70e2                	ld	ra,56(sp)
    80002fea:	7442                	ld	s0,48(sp)
    80002fec:	74a2                	ld	s1,40(sp)
    80002fee:	7902                	ld	s2,32(sp)
    80002ff0:	6121                	addi	sp,sp,64
    80002ff2:	8082                	ret
    return -1;
    80002ff4:	57fd                	li	a5,-1
    80002ff6:	bfc5                	j	80002fe6 <sys_waitx+0x8a>

0000000080002ff8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ff8:	7179                	addi	sp,sp,-48
    80002ffa:	f406                	sd	ra,40(sp)
    80002ffc:	f022                	sd	s0,32(sp)
    80002ffe:	ec26                	sd	s1,24(sp)
    80003000:	e84a                	sd	s2,16(sp)
    80003002:	e44e                	sd	s3,8(sp)
    80003004:	e052                	sd	s4,0(sp)
    80003006:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003008:	00005597          	auipc	a1,0x5
    8000300c:	50858593          	addi	a1,a1,1288 # 80008510 <syscalls+0xc0>
    80003010:	00014517          	auipc	a0,0x14
    80003014:	d8850513          	addi	a0,a0,-632 # 80016d98 <bcache>
    80003018:	ffffe097          	auipc	ra,0xffffe
    8000301c:	b2e080e7          	jalr	-1234(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003020:	0001c797          	auipc	a5,0x1c
    80003024:	d7878793          	addi	a5,a5,-648 # 8001ed98 <bcache+0x8000>
    80003028:	0001c717          	auipc	a4,0x1c
    8000302c:	fd870713          	addi	a4,a4,-40 # 8001f000 <bcache+0x8268>
    80003030:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003034:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003038:	00014497          	auipc	s1,0x14
    8000303c:	d7848493          	addi	s1,s1,-648 # 80016db0 <bcache+0x18>
    b->next = bcache.head.next;
    80003040:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003042:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003044:	00005a17          	auipc	s4,0x5
    80003048:	4d4a0a13          	addi	s4,s4,1236 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000304c:	2b893783          	ld	a5,696(s2)
    80003050:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003052:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003056:	85d2                	mv	a1,s4
    80003058:	01048513          	addi	a0,s1,16
    8000305c:	00001097          	auipc	ra,0x1
    80003060:	4c4080e7          	jalr	1220(ra) # 80004520 <initsleeplock>
    bcache.head.next->prev = b;
    80003064:	2b893783          	ld	a5,696(s2)
    80003068:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000306a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000306e:	45848493          	addi	s1,s1,1112
    80003072:	fd349de3          	bne	s1,s3,8000304c <binit+0x54>
  }
}
    80003076:	70a2                	ld	ra,40(sp)
    80003078:	7402                	ld	s0,32(sp)
    8000307a:	64e2                	ld	s1,24(sp)
    8000307c:	6942                	ld	s2,16(sp)
    8000307e:	69a2                	ld	s3,8(sp)
    80003080:	6a02                	ld	s4,0(sp)
    80003082:	6145                	addi	sp,sp,48
    80003084:	8082                	ret

0000000080003086 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003086:	7179                	addi	sp,sp,-48
    80003088:	f406                	sd	ra,40(sp)
    8000308a:	f022                	sd	s0,32(sp)
    8000308c:	ec26                	sd	s1,24(sp)
    8000308e:	e84a                	sd	s2,16(sp)
    80003090:	e44e                	sd	s3,8(sp)
    80003092:	1800                	addi	s0,sp,48
    80003094:	892a                	mv	s2,a0
    80003096:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003098:	00014517          	auipc	a0,0x14
    8000309c:	d0050513          	addi	a0,a0,-768 # 80016d98 <bcache>
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	b36080e7          	jalr	-1226(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030a8:	0001c497          	auipc	s1,0x1c
    800030ac:	fa84b483          	ld	s1,-88(s1) # 8001f050 <bcache+0x82b8>
    800030b0:	0001c797          	auipc	a5,0x1c
    800030b4:	f5078793          	addi	a5,a5,-176 # 8001f000 <bcache+0x8268>
    800030b8:	02f48f63          	beq	s1,a5,800030f6 <bread+0x70>
    800030bc:	873e                	mv	a4,a5
    800030be:	a021                	j	800030c6 <bread+0x40>
    800030c0:	68a4                	ld	s1,80(s1)
    800030c2:	02e48a63          	beq	s1,a4,800030f6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030c6:	449c                	lw	a5,8(s1)
    800030c8:	ff279ce3          	bne	a5,s2,800030c0 <bread+0x3a>
    800030cc:	44dc                	lw	a5,12(s1)
    800030ce:	ff3799e3          	bne	a5,s3,800030c0 <bread+0x3a>
      b->refcnt++;
    800030d2:	40bc                	lw	a5,64(s1)
    800030d4:	2785                	addiw	a5,a5,1
    800030d6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d8:	00014517          	auipc	a0,0x14
    800030dc:	cc050513          	addi	a0,a0,-832 # 80016d98 <bcache>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	baa080e7          	jalr	-1110(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030e8:	01048513          	addi	a0,s1,16
    800030ec:	00001097          	auipc	ra,0x1
    800030f0:	46e080e7          	jalr	1134(ra) # 8000455a <acquiresleep>
      return b;
    800030f4:	a8b9                	j	80003152 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f6:	0001c497          	auipc	s1,0x1c
    800030fa:	f524b483          	ld	s1,-174(s1) # 8001f048 <bcache+0x82b0>
    800030fe:	0001c797          	auipc	a5,0x1c
    80003102:	f0278793          	addi	a5,a5,-254 # 8001f000 <bcache+0x8268>
    80003106:	00f48863          	beq	s1,a5,80003116 <bread+0x90>
    8000310a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000310c:	40bc                	lw	a5,64(s1)
    8000310e:	cf81                	beqz	a5,80003126 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003110:	64a4                	ld	s1,72(s1)
    80003112:	fee49de3          	bne	s1,a4,8000310c <bread+0x86>
  panic("bget: no buffers");
    80003116:	00005517          	auipc	a0,0x5
    8000311a:	40a50513          	addi	a0,a0,1034 # 80008520 <syscalls+0xd0>
    8000311e:	ffffd097          	auipc	ra,0xffffd
    80003122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
      b->dev = dev;
    80003126:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000312a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000312e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003132:	4785                	li	a5,1
    80003134:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	c6250513          	addi	a0,a0,-926 # 80016d98 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	b4c080e7          	jalr	-1204(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003146:	01048513          	addi	a0,s1,16
    8000314a:	00001097          	auipc	ra,0x1
    8000314e:	410080e7          	jalr	1040(ra) # 8000455a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003152:	409c                	lw	a5,0(s1)
    80003154:	cb89                	beqz	a5,80003166 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003156:	8526                	mv	a0,s1
    80003158:	70a2                	ld	ra,40(sp)
    8000315a:	7402                	ld	s0,32(sp)
    8000315c:	64e2                	ld	s1,24(sp)
    8000315e:	6942                	ld	s2,16(sp)
    80003160:	69a2                	ld	s3,8(sp)
    80003162:	6145                	addi	sp,sp,48
    80003164:	8082                	ret
    virtio_disk_rw(b, 0);
    80003166:	4581                	li	a1,0
    80003168:	8526                	mv	a0,s1
    8000316a:	00003097          	auipc	ra,0x3
    8000316e:	00a080e7          	jalr	10(ra) # 80006174 <virtio_disk_rw>
    b->valid = 1;
    80003172:	4785                	li	a5,1
    80003174:	c09c                	sw	a5,0(s1)
  return b;
    80003176:	b7c5                	j	80003156 <bread+0xd0>

0000000080003178 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003184:	0541                	addi	a0,a0,16
    80003186:	00001097          	auipc	ra,0x1
    8000318a:	46e080e7          	jalr	1134(ra) # 800045f4 <holdingsleep>
    8000318e:	cd01                	beqz	a0,800031a6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003190:	4585                	li	a1,1
    80003192:	8526                	mv	a0,s1
    80003194:	00003097          	auipc	ra,0x3
    80003198:	fe0080e7          	jalr	-32(ra) # 80006174 <virtio_disk_rw>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6105                	addi	sp,sp,32
    800031a4:	8082                	ret
    panic("bwrite");
    800031a6:	00005517          	auipc	a0,0x5
    800031aa:	39250513          	addi	a0,a0,914 # 80008538 <syscalls+0xe8>
    800031ae:	ffffd097          	auipc	ra,0xffffd
    800031b2:	390080e7          	jalr	912(ra) # 8000053e <panic>

00000000800031b6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031b6:	1101                	addi	sp,sp,-32
    800031b8:	ec06                	sd	ra,24(sp)
    800031ba:	e822                	sd	s0,16(sp)
    800031bc:	e426                	sd	s1,8(sp)
    800031be:	e04a                	sd	s2,0(sp)
    800031c0:	1000                	addi	s0,sp,32
    800031c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031c4:	01050913          	addi	s2,a0,16
    800031c8:	854a                	mv	a0,s2
    800031ca:	00001097          	auipc	ra,0x1
    800031ce:	42a080e7          	jalr	1066(ra) # 800045f4 <holdingsleep>
    800031d2:	c92d                	beqz	a0,80003244 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00001097          	auipc	ra,0x1
    800031da:	3da080e7          	jalr	986(ra) # 800045b0 <releasesleep>

  acquire(&bcache.lock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	bba50513          	addi	a0,a0,-1094 # 80016d98 <bcache>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	9f0080e7          	jalr	-1552(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031ee:	40bc                	lw	a5,64(s1)
    800031f0:	37fd                	addiw	a5,a5,-1
    800031f2:	0007871b          	sext.w	a4,a5
    800031f6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031f8:	eb05                	bnez	a4,80003228 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031fa:	68bc                	ld	a5,80(s1)
    800031fc:	64b8                	ld	a4,72(s1)
    800031fe:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003200:	64bc                	ld	a5,72(s1)
    80003202:	68b8                	ld	a4,80(s1)
    80003204:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003206:	0001c797          	auipc	a5,0x1c
    8000320a:	b9278793          	addi	a5,a5,-1134 # 8001ed98 <bcache+0x8000>
    8000320e:	2b87b703          	ld	a4,696(a5)
    80003212:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003214:	0001c717          	auipc	a4,0x1c
    80003218:	dec70713          	addi	a4,a4,-532 # 8001f000 <bcache+0x8268>
    8000321c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000321e:	2b87b703          	ld	a4,696(a5)
    80003222:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003224:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003228:	00014517          	auipc	a0,0x14
    8000322c:	b7050513          	addi	a0,a0,-1168 # 80016d98 <bcache>
    80003230:	ffffe097          	auipc	ra,0xffffe
    80003234:	a5a080e7          	jalr	-1446(ra) # 80000c8a <release>
}
    80003238:	60e2                	ld	ra,24(sp)
    8000323a:	6442                	ld	s0,16(sp)
    8000323c:	64a2                	ld	s1,8(sp)
    8000323e:	6902                	ld	s2,0(sp)
    80003240:	6105                	addi	sp,sp,32
    80003242:	8082                	ret
    panic("brelse");
    80003244:	00005517          	auipc	a0,0x5
    80003248:	2fc50513          	addi	a0,a0,764 # 80008540 <syscalls+0xf0>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>

0000000080003254 <bpin>:

void
bpin(struct buf *b) {
    80003254:	1101                	addi	sp,sp,-32
    80003256:	ec06                	sd	ra,24(sp)
    80003258:	e822                	sd	s0,16(sp)
    8000325a:	e426                	sd	s1,8(sp)
    8000325c:	1000                	addi	s0,sp,32
    8000325e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003260:	00014517          	auipc	a0,0x14
    80003264:	b3850513          	addi	a0,a0,-1224 # 80016d98 <bcache>
    80003268:	ffffe097          	auipc	ra,0xffffe
    8000326c:	96e080e7          	jalr	-1682(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003270:	40bc                	lw	a5,64(s1)
    80003272:	2785                	addiw	a5,a5,1
    80003274:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003276:	00014517          	auipc	a0,0x14
    8000327a:	b2250513          	addi	a0,a0,-1246 # 80016d98 <bcache>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	a0c080e7          	jalr	-1524(ra) # 80000c8a <release>
}
    80003286:	60e2                	ld	ra,24(sp)
    80003288:	6442                	ld	s0,16(sp)
    8000328a:	64a2                	ld	s1,8(sp)
    8000328c:	6105                	addi	sp,sp,32
    8000328e:	8082                	ret

0000000080003290 <bunpin>:

void
bunpin(struct buf *b) {
    80003290:	1101                	addi	sp,sp,-32
    80003292:	ec06                	sd	ra,24(sp)
    80003294:	e822                	sd	s0,16(sp)
    80003296:	e426                	sd	s1,8(sp)
    80003298:	1000                	addi	s0,sp,32
    8000329a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000329c:	00014517          	auipc	a0,0x14
    800032a0:	afc50513          	addi	a0,a0,-1284 # 80016d98 <bcache>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	932080e7          	jalr	-1742(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032ac:	40bc                	lw	a5,64(s1)
    800032ae:	37fd                	addiw	a5,a5,-1
    800032b0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032b2:	00014517          	auipc	a0,0x14
    800032b6:	ae650513          	addi	a0,a0,-1306 # 80016d98 <bcache>
    800032ba:	ffffe097          	auipc	ra,0xffffe
    800032be:	9d0080e7          	jalr	-1584(ra) # 80000c8a <release>
}
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	64a2                	ld	s1,8(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret

00000000800032cc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032cc:	1101                	addi	sp,sp,-32
    800032ce:	ec06                	sd	ra,24(sp)
    800032d0:	e822                	sd	s0,16(sp)
    800032d2:	e426                	sd	s1,8(sp)
    800032d4:	e04a                	sd	s2,0(sp)
    800032d6:	1000                	addi	s0,sp,32
    800032d8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032da:	00d5d59b          	srliw	a1,a1,0xd
    800032de:	0001c797          	auipc	a5,0x1c
    800032e2:	1967a783          	lw	a5,406(a5) # 8001f474 <sb+0x1c>
    800032e6:	9dbd                	addw	a1,a1,a5
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	d9e080e7          	jalr	-610(ra) # 80003086 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032f0:	0074f713          	andi	a4,s1,7
    800032f4:	4785                	li	a5,1
    800032f6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032fa:	14ce                	slli	s1,s1,0x33
    800032fc:	90d9                	srli	s1,s1,0x36
    800032fe:	00950733          	add	a4,a0,s1
    80003302:	05874703          	lbu	a4,88(a4)
    80003306:	00e7f6b3          	and	a3,a5,a4
    8000330a:	c69d                	beqz	a3,80003338 <bfree+0x6c>
    8000330c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000330e:	94aa                	add	s1,s1,a0
    80003310:	fff7c793          	not	a5,a5
    80003314:	8ff9                	and	a5,a5,a4
    80003316:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000331a:	00001097          	auipc	ra,0x1
    8000331e:	120080e7          	jalr	288(ra) # 8000443a <log_write>
  brelse(bp);
    80003322:	854a                	mv	a0,s2
    80003324:	00000097          	auipc	ra,0x0
    80003328:	e92080e7          	jalr	-366(ra) # 800031b6 <brelse>
}
    8000332c:	60e2                	ld	ra,24(sp)
    8000332e:	6442                	ld	s0,16(sp)
    80003330:	64a2                	ld	s1,8(sp)
    80003332:	6902                	ld	s2,0(sp)
    80003334:	6105                	addi	sp,sp,32
    80003336:	8082                	ret
    panic("freeing free block");
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	21050513          	addi	a0,a0,528 # 80008548 <syscalls+0xf8>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	1fe080e7          	jalr	510(ra) # 8000053e <panic>

0000000080003348 <balloc>:
{
    80003348:	711d                	addi	sp,sp,-96
    8000334a:	ec86                	sd	ra,88(sp)
    8000334c:	e8a2                	sd	s0,80(sp)
    8000334e:	e4a6                	sd	s1,72(sp)
    80003350:	e0ca                	sd	s2,64(sp)
    80003352:	fc4e                	sd	s3,56(sp)
    80003354:	f852                	sd	s4,48(sp)
    80003356:	f456                	sd	s5,40(sp)
    80003358:	f05a                	sd	s6,32(sp)
    8000335a:	ec5e                	sd	s7,24(sp)
    8000335c:	e862                	sd	s8,16(sp)
    8000335e:	e466                	sd	s9,8(sp)
    80003360:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003362:	0001c797          	auipc	a5,0x1c
    80003366:	0fa7a783          	lw	a5,250(a5) # 8001f45c <sb+0x4>
    8000336a:	10078163          	beqz	a5,8000346c <balloc+0x124>
    8000336e:	8baa                	mv	s7,a0
    80003370:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003372:	0001cb17          	auipc	s6,0x1c
    80003376:	0e6b0b13          	addi	s6,s6,230 # 8001f458 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000337a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000337c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000337e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003380:	6c89                	lui	s9,0x2
    80003382:	a061                	j	8000340a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003384:	974a                	add	a4,a4,s2
    80003386:	8fd5                	or	a5,a5,a3
    80003388:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000338c:	854a                	mv	a0,s2
    8000338e:	00001097          	auipc	ra,0x1
    80003392:	0ac080e7          	jalr	172(ra) # 8000443a <log_write>
        brelse(bp);
    80003396:	854a                	mv	a0,s2
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	e1e080e7          	jalr	-482(ra) # 800031b6 <brelse>
  bp = bread(dev, bno);
    800033a0:	85a6                	mv	a1,s1
    800033a2:	855e                	mv	a0,s7
    800033a4:	00000097          	auipc	ra,0x0
    800033a8:	ce2080e7          	jalr	-798(ra) # 80003086 <bread>
    800033ac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033ae:	40000613          	li	a2,1024
    800033b2:	4581                	li	a1,0
    800033b4:	05850513          	addi	a0,a0,88
    800033b8:	ffffe097          	auipc	ra,0xffffe
    800033bc:	91a080e7          	jalr	-1766(ra) # 80000cd2 <memset>
  log_write(bp);
    800033c0:	854a                	mv	a0,s2
    800033c2:	00001097          	auipc	ra,0x1
    800033c6:	078080e7          	jalr	120(ra) # 8000443a <log_write>
  brelse(bp);
    800033ca:	854a                	mv	a0,s2
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	dea080e7          	jalr	-534(ra) # 800031b6 <brelse>
}
    800033d4:	8526                	mv	a0,s1
    800033d6:	60e6                	ld	ra,88(sp)
    800033d8:	6446                	ld	s0,80(sp)
    800033da:	64a6                	ld	s1,72(sp)
    800033dc:	6906                	ld	s2,64(sp)
    800033de:	79e2                	ld	s3,56(sp)
    800033e0:	7a42                	ld	s4,48(sp)
    800033e2:	7aa2                	ld	s5,40(sp)
    800033e4:	7b02                	ld	s6,32(sp)
    800033e6:	6be2                	ld	s7,24(sp)
    800033e8:	6c42                	ld	s8,16(sp)
    800033ea:	6ca2                	ld	s9,8(sp)
    800033ec:	6125                	addi	sp,sp,96
    800033ee:	8082                	ret
    brelse(bp);
    800033f0:	854a                	mv	a0,s2
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	dc4080e7          	jalr	-572(ra) # 800031b6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033fa:	015c87bb          	addw	a5,s9,s5
    800033fe:	00078a9b          	sext.w	s5,a5
    80003402:	004b2703          	lw	a4,4(s6)
    80003406:	06eaf363          	bgeu	s5,a4,8000346c <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000340a:	41fad79b          	sraiw	a5,s5,0x1f
    8000340e:	0137d79b          	srliw	a5,a5,0x13
    80003412:	015787bb          	addw	a5,a5,s5
    80003416:	40d7d79b          	sraiw	a5,a5,0xd
    8000341a:	01cb2583          	lw	a1,28(s6)
    8000341e:	9dbd                	addw	a1,a1,a5
    80003420:	855e                	mv	a0,s7
    80003422:	00000097          	auipc	ra,0x0
    80003426:	c64080e7          	jalr	-924(ra) # 80003086 <bread>
    8000342a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000342c:	004b2503          	lw	a0,4(s6)
    80003430:	000a849b          	sext.w	s1,s5
    80003434:	8662                	mv	a2,s8
    80003436:	faa4fde3          	bgeu	s1,a0,800033f0 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000343a:	41f6579b          	sraiw	a5,a2,0x1f
    8000343e:	01d7d69b          	srliw	a3,a5,0x1d
    80003442:	00c6873b          	addw	a4,a3,a2
    80003446:	00777793          	andi	a5,a4,7
    8000344a:	9f95                	subw	a5,a5,a3
    8000344c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003450:	4037571b          	sraiw	a4,a4,0x3
    80003454:	00e906b3          	add	a3,s2,a4
    80003458:	0586c683          	lbu	a3,88(a3)
    8000345c:	00d7f5b3          	and	a1,a5,a3
    80003460:	d195                	beqz	a1,80003384 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003462:	2605                	addiw	a2,a2,1
    80003464:	2485                	addiw	s1,s1,1
    80003466:	fd4618e3          	bne	a2,s4,80003436 <balloc+0xee>
    8000346a:	b759                	j	800033f0 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000346c:	00005517          	auipc	a0,0x5
    80003470:	0f450513          	addi	a0,a0,244 # 80008560 <syscalls+0x110>
    80003474:	ffffd097          	auipc	ra,0xffffd
    80003478:	114080e7          	jalr	276(ra) # 80000588 <printf>
  return 0;
    8000347c:	4481                	li	s1,0
    8000347e:	bf99                	j	800033d4 <balloc+0x8c>

0000000080003480 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003480:	7179                	addi	sp,sp,-48
    80003482:	f406                	sd	ra,40(sp)
    80003484:	f022                	sd	s0,32(sp)
    80003486:	ec26                	sd	s1,24(sp)
    80003488:	e84a                	sd	s2,16(sp)
    8000348a:	e44e                	sd	s3,8(sp)
    8000348c:	e052                	sd	s4,0(sp)
    8000348e:	1800                	addi	s0,sp,48
    80003490:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003492:	47ad                	li	a5,11
    80003494:	02b7e763          	bltu	a5,a1,800034c2 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003498:	02059493          	slli	s1,a1,0x20
    8000349c:	9081                	srli	s1,s1,0x20
    8000349e:	048a                	slli	s1,s1,0x2
    800034a0:	94aa                	add	s1,s1,a0
    800034a2:	0504a903          	lw	s2,80(s1)
    800034a6:	06091e63          	bnez	s2,80003522 <bmap+0xa2>
      addr = balloc(ip->dev);
    800034aa:	4108                	lw	a0,0(a0)
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	e9c080e7          	jalr	-356(ra) # 80003348 <balloc>
    800034b4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034b8:	06090563          	beqz	s2,80003522 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800034bc:	0524a823          	sw	s2,80(s1)
    800034c0:	a08d                	j	80003522 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034c2:	ff45849b          	addiw	s1,a1,-12
    800034c6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034ca:	0ff00793          	li	a5,255
    800034ce:	08e7e563          	bltu	a5,a4,80003558 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034d2:	08052903          	lw	s2,128(a0)
    800034d6:	00091d63          	bnez	s2,800034f0 <bmap+0x70>
      addr = balloc(ip->dev);
    800034da:	4108                	lw	a0,0(a0)
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	e6c080e7          	jalr	-404(ra) # 80003348 <balloc>
    800034e4:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034e8:	02090d63          	beqz	s2,80003522 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034ec:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800034f0:	85ca                	mv	a1,s2
    800034f2:	0009a503          	lw	a0,0(s3)
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	b90080e7          	jalr	-1136(ra) # 80003086 <bread>
    800034fe:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003500:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003504:	02049593          	slli	a1,s1,0x20
    80003508:	9181                	srli	a1,a1,0x20
    8000350a:	058a                	slli	a1,a1,0x2
    8000350c:	00b784b3          	add	s1,a5,a1
    80003510:	0004a903          	lw	s2,0(s1)
    80003514:	02090063          	beqz	s2,80003534 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003518:	8552                	mv	a0,s4
    8000351a:	00000097          	auipc	ra,0x0
    8000351e:	c9c080e7          	jalr	-868(ra) # 800031b6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003522:	854a                	mv	a0,s2
    80003524:	70a2                	ld	ra,40(sp)
    80003526:	7402                	ld	s0,32(sp)
    80003528:	64e2                	ld	s1,24(sp)
    8000352a:	6942                	ld	s2,16(sp)
    8000352c:	69a2                	ld	s3,8(sp)
    8000352e:	6a02                	ld	s4,0(sp)
    80003530:	6145                	addi	sp,sp,48
    80003532:	8082                	ret
      addr = balloc(ip->dev);
    80003534:	0009a503          	lw	a0,0(s3)
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	e10080e7          	jalr	-496(ra) # 80003348 <balloc>
    80003540:	0005091b          	sext.w	s2,a0
      if(addr){
    80003544:	fc090ae3          	beqz	s2,80003518 <bmap+0x98>
        a[bn] = addr;
    80003548:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000354c:	8552                	mv	a0,s4
    8000354e:	00001097          	auipc	ra,0x1
    80003552:	eec080e7          	jalr	-276(ra) # 8000443a <log_write>
    80003556:	b7c9                	j	80003518 <bmap+0x98>
  panic("bmap: out of range");
    80003558:	00005517          	auipc	a0,0x5
    8000355c:	02050513          	addi	a0,a0,32 # 80008578 <syscalls+0x128>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	fde080e7          	jalr	-34(ra) # 8000053e <panic>

0000000080003568 <iget>:
{
    80003568:	7179                	addi	sp,sp,-48
    8000356a:	f406                	sd	ra,40(sp)
    8000356c:	f022                	sd	s0,32(sp)
    8000356e:	ec26                	sd	s1,24(sp)
    80003570:	e84a                	sd	s2,16(sp)
    80003572:	e44e                	sd	s3,8(sp)
    80003574:	e052                	sd	s4,0(sp)
    80003576:	1800                	addi	s0,sp,48
    80003578:	89aa                	mv	s3,a0
    8000357a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000357c:	0001c517          	auipc	a0,0x1c
    80003580:	efc50513          	addi	a0,a0,-260 # 8001f478 <itable>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	652080e7          	jalr	1618(ra) # 80000bd6 <acquire>
  empty = 0;
    8000358c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000358e:	0001c497          	auipc	s1,0x1c
    80003592:	f0248493          	addi	s1,s1,-254 # 8001f490 <itable+0x18>
    80003596:	0001e697          	auipc	a3,0x1e
    8000359a:	98a68693          	addi	a3,a3,-1654 # 80020f20 <log>
    8000359e:	a039                	j	800035ac <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035a0:	02090b63          	beqz	s2,800035d6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035a4:	08848493          	addi	s1,s1,136
    800035a8:	02d48a63          	beq	s1,a3,800035dc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035ac:	449c                	lw	a5,8(s1)
    800035ae:	fef059e3          	blez	a5,800035a0 <iget+0x38>
    800035b2:	4098                	lw	a4,0(s1)
    800035b4:	ff3716e3          	bne	a4,s3,800035a0 <iget+0x38>
    800035b8:	40d8                	lw	a4,4(s1)
    800035ba:	ff4713e3          	bne	a4,s4,800035a0 <iget+0x38>
      ip->ref++;
    800035be:	2785                	addiw	a5,a5,1
    800035c0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035c2:	0001c517          	auipc	a0,0x1c
    800035c6:	eb650513          	addi	a0,a0,-330 # 8001f478 <itable>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	6c0080e7          	jalr	1728(ra) # 80000c8a <release>
      return ip;
    800035d2:	8926                	mv	s2,s1
    800035d4:	a03d                	j	80003602 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035d6:	f7f9                	bnez	a5,800035a4 <iget+0x3c>
    800035d8:	8926                	mv	s2,s1
    800035da:	b7e9                	j	800035a4 <iget+0x3c>
  if(empty == 0)
    800035dc:	02090c63          	beqz	s2,80003614 <iget+0xac>
  ip->dev = dev;
    800035e0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035e4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035e8:	4785                	li	a5,1
    800035ea:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035ee:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035f2:	0001c517          	auipc	a0,0x1c
    800035f6:	e8650513          	addi	a0,a0,-378 # 8001f478 <itable>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	690080e7          	jalr	1680(ra) # 80000c8a <release>
}
    80003602:	854a                	mv	a0,s2
    80003604:	70a2                	ld	ra,40(sp)
    80003606:	7402                	ld	s0,32(sp)
    80003608:	64e2                	ld	s1,24(sp)
    8000360a:	6942                	ld	s2,16(sp)
    8000360c:	69a2                	ld	s3,8(sp)
    8000360e:	6a02                	ld	s4,0(sp)
    80003610:	6145                	addi	sp,sp,48
    80003612:	8082                	ret
    panic("iget: no inodes");
    80003614:	00005517          	auipc	a0,0x5
    80003618:	f7c50513          	addi	a0,a0,-132 # 80008590 <syscalls+0x140>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>

0000000080003624 <fsinit>:
fsinit(int dev) {
    80003624:	7179                	addi	sp,sp,-48
    80003626:	f406                	sd	ra,40(sp)
    80003628:	f022                	sd	s0,32(sp)
    8000362a:	ec26                	sd	s1,24(sp)
    8000362c:	e84a                	sd	s2,16(sp)
    8000362e:	e44e                	sd	s3,8(sp)
    80003630:	1800                	addi	s0,sp,48
    80003632:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003634:	4585                	li	a1,1
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	a50080e7          	jalr	-1456(ra) # 80003086 <bread>
    8000363e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003640:	0001c997          	auipc	s3,0x1c
    80003644:	e1898993          	addi	s3,s3,-488 # 8001f458 <sb>
    80003648:	02000613          	li	a2,32
    8000364c:	05850593          	addi	a1,a0,88
    80003650:	854e                	mv	a0,s3
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	6dc080e7          	jalr	1756(ra) # 80000d2e <memmove>
  brelse(bp);
    8000365a:	8526                	mv	a0,s1
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	b5a080e7          	jalr	-1190(ra) # 800031b6 <brelse>
  if(sb.magic != FSMAGIC)
    80003664:	0009a703          	lw	a4,0(s3)
    80003668:	102037b7          	lui	a5,0x10203
    8000366c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003670:	02f71263          	bne	a4,a5,80003694 <fsinit+0x70>
  initlog(dev, &sb);
    80003674:	0001c597          	auipc	a1,0x1c
    80003678:	de458593          	addi	a1,a1,-540 # 8001f458 <sb>
    8000367c:	854a                	mv	a0,s2
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	b40080e7          	jalr	-1216(ra) # 800041be <initlog>
}
    80003686:	70a2                	ld	ra,40(sp)
    80003688:	7402                	ld	s0,32(sp)
    8000368a:	64e2                	ld	s1,24(sp)
    8000368c:	6942                	ld	s2,16(sp)
    8000368e:	69a2                	ld	s3,8(sp)
    80003690:	6145                	addi	sp,sp,48
    80003692:	8082                	ret
    panic("invalid file system");
    80003694:	00005517          	auipc	a0,0x5
    80003698:	f0c50513          	addi	a0,a0,-244 # 800085a0 <syscalls+0x150>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	ea2080e7          	jalr	-350(ra) # 8000053e <panic>

00000000800036a4 <iinit>:
{
    800036a4:	7179                	addi	sp,sp,-48
    800036a6:	f406                	sd	ra,40(sp)
    800036a8:	f022                	sd	s0,32(sp)
    800036aa:	ec26                	sd	s1,24(sp)
    800036ac:	e84a                	sd	s2,16(sp)
    800036ae:	e44e                	sd	s3,8(sp)
    800036b0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036b2:	00005597          	auipc	a1,0x5
    800036b6:	f0658593          	addi	a1,a1,-250 # 800085b8 <syscalls+0x168>
    800036ba:	0001c517          	auipc	a0,0x1c
    800036be:	dbe50513          	addi	a0,a0,-578 # 8001f478 <itable>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	484080e7          	jalr	1156(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036ca:	0001c497          	auipc	s1,0x1c
    800036ce:	dd648493          	addi	s1,s1,-554 # 8001f4a0 <itable+0x28>
    800036d2:	0001e997          	auipc	s3,0x1e
    800036d6:	85e98993          	addi	s3,s3,-1954 # 80020f30 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036da:	00005917          	auipc	s2,0x5
    800036de:	ee690913          	addi	s2,s2,-282 # 800085c0 <syscalls+0x170>
    800036e2:	85ca                	mv	a1,s2
    800036e4:	8526                	mv	a0,s1
    800036e6:	00001097          	auipc	ra,0x1
    800036ea:	e3a080e7          	jalr	-454(ra) # 80004520 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036ee:	08848493          	addi	s1,s1,136
    800036f2:	ff3498e3          	bne	s1,s3,800036e2 <iinit+0x3e>
}
    800036f6:	70a2                	ld	ra,40(sp)
    800036f8:	7402                	ld	s0,32(sp)
    800036fa:	64e2                	ld	s1,24(sp)
    800036fc:	6942                	ld	s2,16(sp)
    800036fe:	69a2                	ld	s3,8(sp)
    80003700:	6145                	addi	sp,sp,48
    80003702:	8082                	ret

0000000080003704 <ialloc>:
{
    80003704:	715d                	addi	sp,sp,-80
    80003706:	e486                	sd	ra,72(sp)
    80003708:	e0a2                	sd	s0,64(sp)
    8000370a:	fc26                	sd	s1,56(sp)
    8000370c:	f84a                	sd	s2,48(sp)
    8000370e:	f44e                	sd	s3,40(sp)
    80003710:	f052                	sd	s4,32(sp)
    80003712:	ec56                	sd	s5,24(sp)
    80003714:	e85a                	sd	s6,16(sp)
    80003716:	e45e                	sd	s7,8(sp)
    80003718:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000371a:	0001c717          	auipc	a4,0x1c
    8000371e:	d4a72703          	lw	a4,-694(a4) # 8001f464 <sb+0xc>
    80003722:	4785                	li	a5,1
    80003724:	04e7fa63          	bgeu	a5,a4,80003778 <ialloc+0x74>
    80003728:	8aaa                	mv	s5,a0
    8000372a:	8bae                	mv	s7,a1
    8000372c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000372e:	0001ca17          	auipc	s4,0x1c
    80003732:	d2aa0a13          	addi	s4,s4,-726 # 8001f458 <sb>
    80003736:	00048b1b          	sext.w	s6,s1
    8000373a:	0044d793          	srli	a5,s1,0x4
    8000373e:	018a2583          	lw	a1,24(s4)
    80003742:	9dbd                	addw	a1,a1,a5
    80003744:	8556                	mv	a0,s5
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	940080e7          	jalr	-1728(ra) # 80003086 <bread>
    8000374e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003750:	05850993          	addi	s3,a0,88
    80003754:	00f4f793          	andi	a5,s1,15
    80003758:	079a                	slli	a5,a5,0x6
    8000375a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000375c:	00099783          	lh	a5,0(s3)
    80003760:	c3a1                	beqz	a5,800037a0 <ialloc+0x9c>
    brelse(bp);
    80003762:	00000097          	auipc	ra,0x0
    80003766:	a54080e7          	jalr	-1452(ra) # 800031b6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000376a:	0485                	addi	s1,s1,1
    8000376c:	00ca2703          	lw	a4,12(s4)
    80003770:	0004879b          	sext.w	a5,s1
    80003774:	fce7e1e3          	bltu	a5,a4,80003736 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	e5050513          	addi	a0,a0,-432 # 800085c8 <syscalls+0x178>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	e08080e7          	jalr	-504(ra) # 80000588 <printf>
  return 0;
    80003788:	4501                	li	a0,0
}
    8000378a:	60a6                	ld	ra,72(sp)
    8000378c:	6406                	ld	s0,64(sp)
    8000378e:	74e2                	ld	s1,56(sp)
    80003790:	7942                	ld	s2,48(sp)
    80003792:	79a2                	ld	s3,40(sp)
    80003794:	7a02                	ld	s4,32(sp)
    80003796:	6ae2                	ld	s5,24(sp)
    80003798:	6b42                	ld	s6,16(sp)
    8000379a:	6ba2                	ld	s7,8(sp)
    8000379c:	6161                	addi	sp,sp,80
    8000379e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037a0:	04000613          	li	a2,64
    800037a4:	4581                	li	a1,0
    800037a6:	854e                	mv	a0,s3
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	52a080e7          	jalr	1322(ra) # 80000cd2 <memset>
      dip->type = type;
    800037b0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037b4:	854a                	mv	a0,s2
    800037b6:	00001097          	auipc	ra,0x1
    800037ba:	c84080e7          	jalr	-892(ra) # 8000443a <log_write>
      brelse(bp);
    800037be:	854a                	mv	a0,s2
    800037c0:	00000097          	auipc	ra,0x0
    800037c4:	9f6080e7          	jalr	-1546(ra) # 800031b6 <brelse>
      return iget(dev, inum);
    800037c8:	85da                	mv	a1,s6
    800037ca:	8556                	mv	a0,s5
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	d9c080e7          	jalr	-612(ra) # 80003568 <iget>
    800037d4:	bf5d                	j	8000378a <ialloc+0x86>

00000000800037d6 <iupdate>:
{
    800037d6:	1101                	addi	sp,sp,-32
    800037d8:	ec06                	sd	ra,24(sp)
    800037da:	e822                	sd	s0,16(sp)
    800037dc:	e426                	sd	s1,8(sp)
    800037de:	e04a                	sd	s2,0(sp)
    800037e0:	1000                	addi	s0,sp,32
    800037e2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037e4:	415c                	lw	a5,4(a0)
    800037e6:	0047d79b          	srliw	a5,a5,0x4
    800037ea:	0001c597          	auipc	a1,0x1c
    800037ee:	c865a583          	lw	a1,-890(a1) # 8001f470 <sb+0x18>
    800037f2:	9dbd                	addw	a1,a1,a5
    800037f4:	4108                	lw	a0,0(a0)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	890080e7          	jalr	-1904(ra) # 80003086 <bread>
    800037fe:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003800:	05850793          	addi	a5,a0,88
    80003804:	40c8                	lw	a0,4(s1)
    80003806:	893d                	andi	a0,a0,15
    80003808:	051a                	slli	a0,a0,0x6
    8000380a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000380c:	04449703          	lh	a4,68(s1)
    80003810:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003814:	04649703          	lh	a4,70(s1)
    80003818:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000381c:	04849703          	lh	a4,72(s1)
    80003820:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003824:	04a49703          	lh	a4,74(s1)
    80003828:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000382c:	44f8                	lw	a4,76(s1)
    8000382e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003830:	03400613          	li	a2,52
    80003834:	05048593          	addi	a1,s1,80
    80003838:	0531                	addi	a0,a0,12
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	4f4080e7          	jalr	1268(ra) # 80000d2e <memmove>
  log_write(bp);
    80003842:	854a                	mv	a0,s2
    80003844:	00001097          	auipc	ra,0x1
    80003848:	bf6080e7          	jalr	-1034(ra) # 8000443a <log_write>
  brelse(bp);
    8000384c:	854a                	mv	a0,s2
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	968080e7          	jalr	-1688(ra) # 800031b6 <brelse>
}
    80003856:	60e2                	ld	ra,24(sp)
    80003858:	6442                	ld	s0,16(sp)
    8000385a:	64a2                	ld	s1,8(sp)
    8000385c:	6902                	ld	s2,0(sp)
    8000385e:	6105                	addi	sp,sp,32
    80003860:	8082                	ret

0000000080003862 <idup>:
{
    80003862:	1101                	addi	sp,sp,-32
    80003864:	ec06                	sd	ra,24(sp)
    80003866:	e822                	sd	s0,16(sp)
    80003868:	e426                	sd	s1,8(sp)
    8000386a:	1000                	addi	s0,sp,32
    8000386c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000386e:	0001c517          	auipc	a0,0x1c
    80003872:	c0a50513          	addi	a0,a0,-1014 # 8001f478 <itable>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	360080e7          	jalr	864(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000387e:	449c                	lw	a5,8(s1)
    80003880:	2785                	addiw	a5,a5,1
    80003882:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003884:	0001c517          	auipc	a0,0x1c
    80003888:	bf450513          	addi	a0,a0,-1036 # 8001f478 <itable>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	3fe080e7          	jalr	1022(ra) # 80000c8a <release>
}
    80003894:	8526                	mv	a0,s1
    80003896:	60e2                	ld	ra,24(sp)
    80003898:	6442                	ld	s0,16(sp)
    8000389a:	64a2                	ld	s1,8(sp)
    8000389c:	6105                	addi	sp,sp,32
    8000389e:	8082                	ret

00000000800038a0 <ilock>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	e04a                	sd	s2,0(sp)
    800038aa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ac:	c115                	beqz	a0,800038d0 <ilock+0x30>
    800038ae:	84aa                	mv	s1,a0
    800038b0:	451c                	lw	a5,8(a0)
    800038b2:	00f05f63          	blez	a5,800038d0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038b6:	0541                	addi	a0,a0,16
    800038b8:	00001097          	auipc	ra,0x1
    800038bc:	ca2080e7          	jalr	-862(ra) # 8000455a <acquiresleep>
  if(ip->valid == 0){
    800038c0:	40bc                	lw	a5,64(s1)
    800038c2:	cf99                	beqz	a5,800038e0 <ilock+0x40>
}
    800038c4:	60e2                	ld	ra,24(sp)
    800038c6:	6442                	ld	s0,16(sp)
    800038c8:	64a2                	ld	s1,8(sp)
    800038ca:	6902                	ld	s2,0(sp)
    800038cc:	6105                	addi	sp,sp,32
    800038ce:	8082                	ret
    panic("ilock");
    800038d0:	00005517          	auipc	a0,0x5
    800038d4:	d1050513          	addi	a0,a0,-752 # 800085e0 <syscalls+0x190>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038e0:	40dc                	lw	a5,4(s1)
    800038e2:	0047d79b          	srliw	a5,a5,0x4
    800038e6:	0001c597          	auipc	a1,0x1c
    800038ea:	b8a5a583          	lw	a1,-1142(a1) # 8001f470 <sb+0x18>
    800038ee:	9dbd                	addw	a1,a1,a5
    800038f0:	4088                	lw	a0,0(s1)
    800038f2:	fffff097          	auipc	ra,0xfffff
    800038f6:	794080e7          	jalr	1940(ra) # 80003086 <bread>
    800038fa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038fc:	05850593          	addi	a1,a0,88
    80003900:	40dc                	lw	a5,4(s1)
    80003902:	8bbd                	andi	a5,a5,15
    80003904:	079a                	slli	a5,a5,0x6
    80003906:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003908:	00059783          	lh	a5,0(a1)
    8000390c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003910:	00259783          	lh	a5,2(a1)
    80003914:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003918:	00459783          	lh	a5,4(a1)
    8000391c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003920:	00659783          	lh	a5,6(a1)
    80003924:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003928:	459c                	lw	a5,8(a1)
    8000392a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000392c:	03400613          	li	a2,52
    80003930:	05b1                	addi	a1,a1,12
    80003932:	05048513          	addi	a0,s1,80
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	3f8080e7          	jalr	1016(ra) # 80000d2e <memmove>
    brelse(bp);
    8000393e:	854a                	mv	a0,s2
    80003940:	00000097          	auipc	ra,0x0
    80003944:	876080e7          	jalr	-1930(ra) # 800031b6 <brelse>
    ip->valid = 1;
    80003948:	4785                	li	a5,1
    8000394a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000394c:	04449783          	lh	a5,68(s1)
    80003950:	fbb5                	bnez	a5,800038c4 <ilock+0x24>
      panic("ilock: no type");
    80003952:	00005517          	auipc	a0,0x5
    80003956:	c9650513          	addi	a0,a0,-874 # 800085e8 <syscalls+0x198>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>

0000000080003962 <iunlock>:
{
    80003962:	1101                	addi	sp,sp,-32
    80003964:	ec06                	sd	ra,24(sp)
    80003966:	e822                	sd	s0,16(sp)
    80003968:	e426                	sd	s1,8(sp)
    8000396a:	e04a                	sd	s2,0(sp)
    8000396c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000396e:	c905                	beqz	a0,8000399e <iunlock+0x3c>
    80003970:	84aa                	mv	s1,a0
    80003972:	01050913          	addi	s2,a0,16
    80003976:	854a                	mv	a0,s2
    80003978:	00001097          	auipc	ra,0x1
    8000397c:	c7c080e7          	jalr	-900(ra) # 800045f4 <holdingsleep>
    80003980:	cd19                	beqz	a0,8000399e <iunlock+0x3c>
    80003982:	449c                	lw	a5,8(s1)
    80003984:	00f05d63          	blez	a5,8000399e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003988:	854a                	mv	a0,s2
    8000398a:	00001097          	auipc	ra,0x1
    8000398e:	c26080e7          	jalr	-986(ra) # 800045b0 <releasesleep>
}
    80003992:	60e2                	ld	ra,24(sp)
    80003994:	6442                	ld	s0,16(sp)
    80003996:	64a2                	ld	s1,8(sp)
    80003998:	6902                	ld	s2,0(sp)
    8000399a:	6105                	addi	sp,sp,32
    8000399c:	8082                	ret
    panic("iunlock");
    8000399e:	00005517          	auipc	a0,0x5
    800039a2:	c5a50513          	addi	a0,a0,-934 # 800085f8 <syscalls+0x1a8>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	b98080e7          	jalr	-1128(ra) # 8000053e <panic>

00000000800039ae <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039ae:	7179                	addi	sp,sp,-48
    800039b0:	f406                	sd	ra,40(sp)
    800039b2:	f022                	sd	s0,32(sp)
    800039b4:	ec26                	sd	s1,24(sp)
    800039b6:	e84a                	sd	s2,16(sp)
    800039b8:	e44e                	sd	s3,8(sp)
    800039ba:	e052                	sd	s4,0(sp)
    800039bc:	1800                	addi	s0,sp,48
    800039be:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039c0:	05050493          	addi	s1,a0,80
    800039c4:	08050913          	addi	s2,a0,128
    800039c8:	a021                	j	800039d0 <itrunc+0x22>
    800039ca:	0491                	addi	s1,s1,4
    800039cc:	01248d63          	beq	s1,s2,800039e6 <itrunc+0x38>
    if(ip->addrs[i]){
    800039d0:	408c                	lw	a1,0(s1)
    800039d2:	dde5                	beqz	a1,800039ca <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039d4:	0009a503          	lw	a0,0(s3)
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	8f4080e7          	jalr	-1804(ra) # 800032cc <bfree>
      ip->addrs[i] = 0;
    800039e0:	0004a023          	sw	zero,0(s1)
    800039e4:	b7dd                	j	800039ca <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039e6:	0809a583          	lw	a1,128(s3)
    800039ea:	e185                	bnez	a1,80003a0a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039ec:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039f0:	854e                	mv	a0,s3
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	de4080e7          	jalr	-540(ra) # 800037d6 <iupdate>
}
    800039fa:	70a2                	ld	ra,40(sp)
    800039fc:	7402                	ld	s0,32(sp)
    800039fe:	64e2                	ld	s1,24(sp)
    80003a00:	6942                	ld	s2,16(sp)
    80003a02:	69a2                	ld	s3,8(sp)
    80003a04:	6a02                	ld	s4,0(sp)
    80003a06:	6145                	addi	sp,sp,48
    80003a08:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a0a:	0009a503          	lw	a0,0(s3)
    80003a0e:	fffff097          	auipc	ra,0xfffff
    80003a12:	678080e7          	jalr	1656(ra) # 80003086 <bread>
    80003a16:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a18:	05850493          	addi	s1,a0,88
    80003a1c:	45850913          	addi	s2,a0,1112
    80003a20:	a021                	j	80003a28 <itrunc+0x7a>
    80003a22:	0491                	addi	s1,s1,4
    80003a24:	01248b63          	beq	s1,s2,80003a3a <itrunc+0x8c>
      if(a[j])
    80003a28:	408c                	lw	a1,0(s1)
    80003a2a:	dde5                	beqz	a1,80003a22 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a2c:	0009a503          	lw	a0,0(s3)
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	89c080e7          	jalr	-1892(ra) # 800032cc <bfree>
    80003a38:	b7ed                	j	80003a22 <itrunc+0x74>
    brelse(bp);
    80003a3a:	8552                	mv	a0,s4
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	77a080e7          	jalr	1914(ra) # 800031b6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a44:	0809a583          	lw	a1,128(s3)
    80003a48:	0009a503          	lw	a0,0(s3)
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	880080e7          	jalr	-1920(ra) # 800032cc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a54:	0809a023          	sw	zero,128(s3)
    80003a58:	bf51                	j	800039ec <itrunc+0x3e>

0000000080003a5a <iput>:
{
    80003a5a:	1101                	addi	sp,sp,-32
    80003a5c:	ec06                	sd	ra,24(sp)
    80003a5e:	e822                	sd	s0,16(sp)
    80003a60:	e426                	sd	s1,8(sp)
    80003a62:	e04a                	sd	s2,0(sp)
    80003a64:	1000                	addi	s0,sp,32
    80003a66:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a68:	0001c517          	auipc	a0,0x1c
    80003a6c:	a1050513          	addi	a0,a0,-1520 # 8001f478 <itable>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	166080e7          	jalr	358(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a78:	4498                	lw	a4,8(s1)
    80003a7a:	4785                	li	a5,1
    80003a7c:	02f70363          	beq	a4,a5,80003aa2 <iput+0x48>
  ip->ref--;
    80003a80:	449c                	lw	a5,8(s1)
    80003a82:	37fd                	addiw	a5,a5,-1
    80003a84:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a86:	0001c517          	auipc	a0,0x1c
    80003a8a:	9f250513          	addi	a0,a0,-1550 # 8001f478 <itable>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	1fc080e7          	jalr	508(ra) # 80000c8a <release>
}
    80003a96:	60e2                	ld	ra,24(sp)
    80003a98:	6442                	ld	s0,16(sp)
    80003a9a:	64a2                	ld	s1,8(sp)
    80003a9c:	6902                	ld	s2,0(sp)
    80003a9e:	6105                	addi	sp,sp,32
    80003aa0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa2:	40bc                	lw	a5,64(s1)
    80003aa4:	dff1                	beqz	a5,80003a80 <iput+0x26>
    80003aa6:	04a49783          	lh	a5,74(s1)
    80003aaa:	fbf9                	bnez	a5,80003a80 <iput+0x26>
    acquiresleep(&ip->lock);
    80003aac:	01048913          	addi	s2,s1,16
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	00001097          	auipc	ra,0x1
    80003ab6:	aa8080e7          	jalr	-1368(ra) # 8000455a <acquiresleep>
    release(&itable.lock);
    80003aba:	0001c517          	auipc	a0,0x1c
    80003abe:	9be50513          	addi	a0,a0,-1602 # 8001f478 <itable>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	1c8080e7          	jalr	456(ra) # 80000c8a <release>
    itrunc(ip);
    80003aca:	8526                	mv	a0,s1
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	ee2080e7          	jalr	-286(ra) # 800039ae <itrunc>
    ip->type = 0;
    80003ad4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ad8:	8526                	mv	a0,s1
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	cfc080e7          	jalr	-772(ra) # 800037d6 <iupdate>
    ip->valid = 0;
    80003ae2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	00001097          	auipc	ra,0x1
    80003aec:	ac8080e7          	jalr	-1336(ra) # 800045b0 <releasesleep>
    acquire(&itable.lock);
    80003af0:	0001c517          	auipc	a0,0x1c
    80003af4:	98850513          	addi	a0,a0,-1656 # 8001f478 <itable>
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	0de080e7          	jalr	222(ra) # 80000bd6 <acquire>
    80003b00:	b741                	j	80003a80 <iput+0x26>

0000000080003b02 <iunlockput>:
{
    80003b02:	1101                	addi	sp,sp,-32
    80003b04:	ec06                	sd	ra,24(sp)
    80003b06:	e822                	sd	s0,16(sp)
    80003b08:	e426                	sd	s1,8(sp)
    80003b0a:	1000                	addi	s0,sp,32
    80003b0c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b0e:	00000097          	auipc	ra,0x0
    80003b12:	e54080e7          	jalr	-428(ra) # 80003962 <iunlock>
  iput(ip);
    80003b16:	8526                	mv	a0,s1
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	f42080e7          	jalr	-190(ra) # 80003a5a <iput>
}
    80003b20:	60e2                	ld	ra,24(sp)
    80003b22:	6442                	ld	s0,16(sp)
    80003b24:	64a2                	ld	s1,8(sp)
    80003b26:	6105                	addi	sp,sp,32
    80003b28:	8082                	ret

0000000080003b2a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b2a:	1141                	addi	sp,sp,-16
    80003b2c:	e422                	sd	s0,8(sp)
    80003b2e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b30:	411c                	lw	a5,0(a0)
    80003b32:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b34:	415c                	lw	a5,4(a0)
    80003b36:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b38:	04451783          	lh	a5,68(a0)
    80003b3c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b40:	04a51783          	lh	a5,74(a0)
    80003b44:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b48:	04c56783          	lwu	a5,76(a0)
    80003b4c:	e99c                	sd	a5,16(a1)
}
    80003b4e:	6422                	ld	s0,8(sp)
    80003b50:	0141                	addi	sp,sp,16
    80003b52:	8082                	ret

0000000080003b54 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b54:	457c                	lw	a5,76(a0)
    80003b56:	0ed7e963          	bltu	a5,a3,80003c48 <readi+0xf4>
{
    80003b5a:	7159                	addi	sp,sp,-112
    80003b5c:	f486                	sd	ra,104(sp)
    80003b5e:	f0a2                	sd	s0,96(sp)
    80003b60:	eca6                	sd	s1,88(sp)
    80003b62:	e8ca                	sd	s2,80(sp)
    80003b64:	e4ce                	sd	s3,72(sp)
    80003b66:	e0d2                	sd	s4,64(sp)
    80003b68:	fc56                	sd	s5,56(sp)
    80003b6a:	f85a                	sd	s6,48(sp)
    80003b6c:	f45e                	sd	s7,40(sp)
    80003b6e:	f062                	sd	s8,32(sp)
    80003b70:	ec66                	sd	s9,24(sp)
    80003b72:	e86a                	sd	s10,16(sp)
    80003b74:	e46e                	sd	s11,8(sp)
    80003b76:	1880                	addi	s0,sp,112
    80003b78:	8b2a                	mv	s6,a0
    80003b7a:	8bae                	mv	s7,a1
    80003b7c:	8a32                	mv	s4,a2
    80003b7e:	84b6                	mv	s1,a3
    80003b80:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b82:	9f35                	addw	a4,a4,a3
    return 0;
    80003b84:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b86:	0ad76063          	bltu	a4,a3,80003c26 <readi+0xd2>
  if(off + n > ip->size)
    80003b8a:	00e7f463          	bgeu	a5,a4,80003b92 <readi+0x3e>
    n = ip->size - off;
    80003b8e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b92:	0a0a8963          	beqz	s5,80003c44 <readi+0xf0>
    80003b96:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b98:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b9c:	5c7d                	li	s8,-1
    80003b9e:	a82d                	j	80003bd8 <readi+0x84>
    80003ba0:	020d1d93          	slli	s11,s10,0x20
    80003ba4:	020ddd93          	srli	s11,s11,0x20
    80003ba8:	05890793          	addi	a5,s2,88
    80003bac:	86ee                	mv	a3,s11
    80003bae:	963e                	add	a2,a2,a5
    80003bb0:	85d2                	mv	a1,s4
    80003bb2:	855e                	mv	a0,s7
    80003bb4:	fffff097          	auipc	ra,0xfffff
    80003bb8:	8c8080e7          	jalr	-1848(ra) # 8000247c <either_copyout>
    80003bbc:	05850d63          	beq	a0,s8,80003c16 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	5f4080e7          	jalr	1524(ra) # 800031b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bca:	013d09bb          	addw	s3,s10,s3
    80003bce:	009d04bb          	addw	s1,s10,s1
    80003bd2:	9a6e                	add	s4,s4,s11
    80003bd4:	0559f763          	bgeu	s3,s5,80003c22 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bd8:	00a4d59b          	srliw	a1,s1,0xa
    80003bdc:	855a                	mv	a0,s6
    80003bde:	00000097          	auipc	ra,0x0
    80003be2:	8a2080e7          	jalr	-1886(ra) # 80003480 <bmap>
    80003be6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bea:	cd85                	beqz	a1,80003c22 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003bec:	000b2503          	lw	a0,0(s6)
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	496080e7          	jalr	1174(ra) # 80003086 <bread>
    80003bf8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bfa:	3ff4f613          	andi	a2,s1,1023
    80003bfe:	40cc87bb          	subw	a5,s9,a2
    80003c02:	413a873b          	subw	a4,s5,s3
    80003c06:	8d3e                	mv	s10,a5
    80003c08:	2781                	sext.w	a5,a5
    80003c0a:	0007069b          	sext.w	a3,a4
    80003c0e:	f8f6f9e3          	bgeu	a3,a5,80003ba0 <readi+0x4c>
    80003c12:	8d3a                	mv	s10,a4
    80003c14:	b771                	j	80003ba0 <readi+0x4c>
      brelse(bp);
    80003c16:	854a                	mv	a0,s2
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	59e080e7          	jalr	1438(ra) # 800031b6 <brelse>
      tot = -1;
    80003c20:	59fd                	li	s3,-1
  }
  return tot;
    80003c22:	0009851b          	sext.w	a0,s3
}
    80003c26:	70a6                	ld	ra,104(sp)
    80003c28:	7406                	ld	s0,96(sp)
    80003c2a:	64e6                	ld	s1,88(sp)
    80003c2c:	6946                	ld	s2,80(sp)
    80003c2e:	69a6                	ld	s3,72(sp)
    80003c30:	6a06                	ld	s4,64(sp)
    80003c32:	7ae2                	ld	s5,56(sp)
    80003c34:	7b42                	ld	s6,48(sp)
    80003c36:	7ba2                	ld	s7,40(sp)
    80003c38:	7c02                	ld	s8,32(sp)
    80003c3a:	6ce2                	ld	s9,24(sp)
    80003c3c:	6d42                	ld	s10,16(sp)
    80003c3e:	6da2                	ld	s11,8(sp)
    80003c40:	6165                	addi	sp,sp,112
    80003c42:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c44:	89d6                	mv	s3,s5
    80003c46:	bff1                	j	80003c22 <readi+0xce>
    return 0;
    80003c48:	4501                	li	a0,0
}
    80003c4a:	8082                	ret

0000000080003c4c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c4c:	457c                	lw	a5,76(a0)
    80003c4e:	10d7e863          	bltu	a5,a3,80003d5e <writei+0x112>
{
    80003c52:	7159                	addi	sp,sp,-112
    80003c54:	f486                	sd	ra,104(sp)
    80003c56:	f0a2                	sd	s0,96(sp)
    80003c58:	eca6                	sd	s1,88(sp)
    80003c5a:	e8ca                	sd	s2,80(sp)
    80003c5c:	e4ce                	sd	s3,72(sp)
    80003c5e:	e0d2                	sd	s4,64(sp)
    80003c60:	fc56                	sd	s5,56(sp)
    80003c62:	f85a                	sd	s6,48(sp)
    80003c64:	f45e                	sd	s7,40(sp)
    80003c66:	f062                	sd	s8,32(sp)
    80003c68:	ec66                	sd	s9,24(sp)
    80003c6a:	e86a                	sd	s10,16(sp)
    80003c6c:	e46e                	sd	s11,8(sp)
    80003c6e:	1880                	addi	s0,sp,112
    80003c70:	8aaa                	mv	s5,a0
    80003c72:	8bae                	mv	s7,a1
    80003c74:	8a32                	mv	s4,a2
    80003c76:	8936                	mv	s2,a3
    80003c78:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c7a:	00e687bb          	addw	a5,a3,a4
    80003c7e:	0ed7e263          	bltu	a5,a3,80003d62 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c82:	00043737          	lui	a4,0x43
    80003c86:	0ef76063          	bltu	a4,a5,80003d66 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c8a:	0c0b0863          	beqz	s6,80003d5a <writei+0x10e>
    80003c8e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c90:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c94:	5c7d                	li	s8,-1
    80003c96:	a091                	j	80003cda <writei+0x8e>
    80003c98:	020d1d93          	slli	s11,s10,0x20
    80003c9c:	020ddd93          	srli	s11,s11,0x20
    80003ca0:	05848793          	addi	a5,s1,88
    80003ca4:	86ee                	mv	a3,s11
    80003ca6:	8652                	mv	a2,s4
    80003ca8:	85de                	mv	a1,s7
    80003caa:	953e                	add	a0,a0,a5
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	826080e7          	jalr	-2010(ra) # 800024d2 <either_copyin>
    80003cb4:	07850263          	beq	a0,s8,80003d18 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	780080e7          	jalr	1920(ra) # 8000443a <log_write>
    brelse(bp);
    80003cc2:	8526                	mv	a0,s1
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	4f2080e7          	jalr	1266(ra) # 800031b6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ccc:	013d09bb          	addw	s3,s10,s3
    80003cd0:	012d093b          	addw	s2,s10,s2
    80003cd4:	9a6e                	add	s4,s4,s11
    80003cd6:	0569f663          	bgeu	s3,s6,80003d22 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003cda:	00a9559b          	srliw	a1,s2,0xa
    80003cde:	8556                	mv	a0,s5
    80003ce0:	fffff097          	auipc	ra,0xfffff
    80003ce4:	7a0080e7          	jalr	1952(ra) # 80003480 <bmap>
    80003ce8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cec:	c99d                	beqz	a1,80003d22 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003cee:	000aa503          	lw	a0,0(s5)
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	394080e7          	jalr	916(ra) # 80003086 <bread>
    80003cfa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cfc:	3ff97513          	andi	a0,s2,1023
    80003d00:	40ac87bb          	subw	a5,s9,a0
    80003d04:	413b073b          	subw	a4,s6,s3
    80003d08:	8d3e                	mv	s10,a5
    80003d0a:	2781                	sext.w	a5,a5
    80003d0c:	0007069b          	sext.w	a3,a4
    80003d10:	f8f6f4e3          	bgeu	a3,a5,80003c98 <writei+0x4c>
    80003d14:	8d3a                	mv	s10,a4
    80003d16:	b749                	j	80003c98 <writei+0x4c>
      brelse(bp);
    80003d18:	8526                	mv	a0,s1
    80003d1a:	fffff097          	auipc	ra,0xfffff
    80003d1e:	49c080e7          	jalr	1180(ra) # 800031b6 <brelse>
  }

  if(off > ip->size)
    80003d22:	04caa783          	lw	a5,76(s5)
    80003d26:	0127f463          	bgeu	a5,s2,80003d2e <writei+0xe2>
    ip->size = off;
    80003d2a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d2e:	8556                	mv	a0,s5
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	aa6080e7          	jalr	-1370(ra) # 800037d6 <iupdate>

  return tot;
    80003d38:	0009851b          	sext.w	a0,s3
}
    80003d3c:	70a6                	ld	ra,104(sp)
    80003d3e:	7406                	ld	s0,96(sp)
    80003d40:	64e6                	ld	s1,88(sp)
    80003d42:	6946                	ld	s2,80(sp)
    80003d44:	69a6                	ld	s3,72(sp)
    80003d46:	6a06                	ld	s4,64(sp)
    80003d48:	7ae2                	ld	s5,56(sp)
    80003d4a:	7b42                	ld	s6,48(sp)
    80003d4c:	7ba2                	ld	s7,40(sp)
    80003d4e:	7c02                	ld	s8,32(sp)
    80003d50:	6ce2                	ld	s9,24(sp)
    80003d52:	6d42                	ld	s10,16(sp)
    80003d54:	6da2                	ld	s11,8(sp)
    80003d56:	6165                	addi	sp,sp,112
    80003d58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d5a:	89da                	mv	s3,s6
    80003d5c:	bfc9                	j	80003d2e <writei+0xe2>
    return -1;
    80003d5e:	557d                	li	a0,-1
}
    80003d60:	8082                	ret
    return -1;
    80003d62:	557d                	li	a0,-1
    80003d64:	bfe1                	j	80003d3c <writei+0xf0>
    return -1;
    80003d66:	557d                	li	a0,-1
    80003d68:	bfd1                	j	80003d3c <writei+0xf0>

0000000080003d6a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d6a:	1141                	addi	sp,sp,-16
    80003d6c:	e406                	sd	ra,8(sp)
    80003d6e:	e022                	sd	s0,0(sp)
    80003d70:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d72:	4639                	li	a2,14
    80003d74:	ffffd097          	auipc	ra,0xffffd
    80003d78:	02e080e7          	jalr	46(ra) # 80000da2 <strncmp>
}
    80003d7c:	60a2                	ld	ra,8(sp)
    80003d7e:	6402                	ld	s0,0(sp)
    80003d80:	0141                	addi	sp,sp,16
    80003d82:	8082                	ret

0000000080003d84 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d84:	7139                	addi	sp,sp,-64
    80003d86:	fc06                	sd	ra,56(sp)
    80003d88:	f822                	sd	s0,48(sp)
    80003d8a:	f426                	sd	s1,40(sp)
    80003d8c:	f04a                	sd	s2,32(sp)
    80003d8e:	ec4e                	sd	s3,24(sp)
    80003d90:	e852                	sd	s4,16(sp)
    80003d92:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d94:	04451703          	lh	a4,68(a0)
    80003d98:	4785                	li	a5,1
    80003d9a:	00f71a63          	bne	a4,a5,80003dae <dirlookup+0x2a>
    80003d9e:	892a                	mv	s2,a0
    80003da0:	89ae                	mv	s3,a1
    80003da2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003da4:	457c                	lw	a5,76(a0)
    80003da6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003da8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003daa:	e79d                	bnez	a5,80003dd8 <dirlookup+0x54>
    80003dac:	a8a5                	j	80003e24 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dae:	00005517          	auipc	a0,0x5
    80003db2:	85250513          	addi	a0,a0,-1966 # 80008600 <syscalls+0x1b0>
    80003db6:	ffffc097          	auipc	ra,0xffffc
    80003dba:	788080e7          	jalr	1928(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003dbe:	00005517          	auipc	a0,0x5
    80003dc2:	85a50513          	addi	a0,a0,-1958 # 80008618 <syscalls+0x1c8>
    80003dc6:	ffffc097          	auipc	ra,0xffffc
    80003dca:	778080e7          	jalr	1912(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dce:	24c1                	addiw	s1,s1,16
    80003dd0:	04c92783          	lw	a5,76(s2)
    80003dd4:	04f4f763          	bgeu	s1,a5,80003e22 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dd8:	4741                	li	a4,16
    80003dda:	86a6                	mv	a3,s1
    80003ddc:	fc040613          	addi	a2,s0,-64
    80003de0:	4581                	li	a1,0
    80003de2:	854a                	mv	a0,s2
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	d70080e7          	jalr	-656(ra) # 80003b54 <readi>
    80003dec:	47c1                	li	a5,16
    80003dee:	fcf518e3          	bne	a0,a5,80003dbe <dirlookup+0x3a>
    if(de.inum == 0)
    80003df2:	fc045783          	lhu	a5,-64(s0)
    80003df6:	dfe1                	beqz	a5,80003dce <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003df8:	fc240593          	addi	a1,s0,-62
    80003dfc:	854e                	mv	a0,s3
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	f6c080e7          	jalr	-148(ra) # 80003d6a <namecmp>
    80003e06:	f561                	bnez	a0,80003dce <dirlookup+0x4a>
      if(poff)
    80003e08:	000a0463          	beqz	s4,80003e10 <dirlookup+0x8c>
        *poff = off;
    80003e0c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e10:	fc045583          	lhu	a1,-64(s0)
    80003e14:	00092503          	lw	a0,0(s2)
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	750080e7          	jalr	1872(ra) # 80003568 <iget>
    80003e20:	a011                	j	80003e24 <dirlookup+0xa0>
  return 0;
    80003e22:	4501                	li	a0,0
}
    80003e24:	70e2                	ld	ra,56(sp)
    80003e26:	7442                	ld	s0,48(sp)
    80003e28:	74a2                	ld	s1,40(sp)
    80003e2a:	7902                	ld	s2,32(sp)
    80003e2c:	69e2                	ld	s3,24(sp)
    80003e2e:	6a42                	ld	s4,16(sp)
    80003e30:	6121                	addi	sp,sp,64
    80003e32:	8082                	ret

0000000080003e34 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e34:	711d                	addi	sp,sp,-96
    80003e36:	ec86                	sd	ra,88(sp)
    80003e38:	e8a2                	sd	s0,80(sp)
    80003e3a:	e4a6                	sd	s1,72(sp)
    80003e3c:	e0ca                	sd	s2,64(sp)
    80003e3e:	fc4e                	sd	s3,56(sp)
    80003e40:	f852                	sd	s4,48(sp)
    80003e42:	f456                	sd	s5,40(sp)
    80003e44:	f05a                	sd	s6,32(sp)
    80003e46:	ec5e                	sd	s7,24(sp)
    80003e48:	e862                	sd	s8,16(sp)
    80003e4a:	e466                	sd	s9,8(sp)
    80003e4c:	1080                	addi	s0,sp,96
    80003e4e:	84aa                	mv	s1,a0
    80003e50:	8aae                	mv	s5,a1
    80003e52:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e54:	00054703          	lbu	a4,0(a0)
    80003e58:	02f00793          	li	a5,47
    80003e5c:	02f70363          	beq	a4,a5,80003e82 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e60:	ffffe097          	auipc	ra,0xffffe
    80003e64:	b4c080e7          	jalr	-1204(ra) # 800019ac <myproc>
    80003e68:	15053503          	ld	a0,336(a0)
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	9f6080e7          	jalr	-1546(ra) # 80003862 <idup>
    80003e74:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e76:	02f00913          	li	s2,47
  len = path - s;
    80003e7a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e7c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e7e:	4b85                	li	s7,1
    80003e80:	a865                	j	80003f38 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e82:	4585                	li	a1,1
    80003e84:	4505                	li	a0,1
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	6e2080e7          	jalr	1762(ra) # 80003568 <iget>
    80003e8e:	89aa                	mv	s3,a0
    80003e90:	b7dd                	j	80003e76 <namex+0x42>
      iunlockput(ip);
    80003e92:	854e                	mv	a0,s3
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	c6e080e7          	jalr	-914(ra) # 80003b02 <iunlockput>
      return 0;
    80003e9c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	60e6                	ld	ra,88(sp)
    80003ea2:	6446                	ld	s0,80(sp)
    80003ea4:	64a6                	ld	s1,72(sp)
    80003ea6:	6906                	ld	s2,64(sp)
    80003ea8:	79e2                	ld	s3,56(sp)
    80003eaa:	7a42                	ld	s4,48(sp)
    80003eac:	7aa2                	ld	s5,40(sp)
    80003eae:	7b02                	ld	s6,32(sp)
    80003eb0:	6be2                	ld	s7,24(sp)
    80003eb2:	6c42                	ld	s8,16(sp)
    80003eb4:	6ca2                	ld	s9,8(sp)
    80003eb6:	6125                	addi	sp,sp,96
    80003eb8:	8082                	ret
      iunlock(ip);
    80003eba:	854e                	mv	a0,s3
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	aa6080e7          	jalr	-1370(ra) # 80003962 <iunlock>
      return ip;
    80003ec4:	bfe9                	j	80003e9e <namex+0x6a>
      iunlockput(ip);
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	c3a080e7          	jalr	-966(ra) # 80003b02 <iunlockput>
      return 0;
    80003ed0:	89e6                	mv	s3,s9
    80003ed2:	b7f1                	j	80003e9e <namex+0x6a>
  len = path - s;
    80003ed4:	40b48633          	sub	a2,s1,a1
    80003ed8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003edc:	099c5463          	bge	s8,s9,80003f64 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ee0:	4639                	li	a2,14
    80003ee2:	8552                	mv	a0,s4
    80003ee4:	ffffd097          	auipc	ra,0xffffd
    80003ee8:	e4a080e7          	jalr	-438(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003eec:	0004c783          	lbu	a5,0(s1)
    80003ef0:	01279763          	bne	a5,s2,80003efe <namex+0xca>
    path++;
    80003ef4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef6:	0004c783          	lbu	a5,0(s1)
    80003efa:	ff278de3          	beq	a5,s2,80003ef4 <namex+0xc0>
    ilock(ip);
    80003efe:	854e                	mv	a0,s3
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	9a0080e7          	jalr	-1632(ra) # 800038a0 <ilock>
    if(ip->type != T_DIR){
    80003f08:	04499783          	lh	a5,68(s3)
    80003f0c:	f97793e3          	bne	a5,s7,80003e92 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f10:	000a8563          	beqz	s5,80003f1a <namex+0xe6>
    80003f14:	0004c783          	lbu	a5,0(s1)
    80003f18:	d3cd                	beqz	a5,80003eba <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f1a:	865a                	mv	a2,s6
    80003f1c:	85d2                	mv	a1,s4
    80003f1e:	854e                	mv	a0,s3
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	e64080e7          	jalr	-412(ra) # 80003d84 <dirlookup>
    80003f28:	8caa                	mv	s9,a0
    80003f2a:	dd51                	beqz	a0,80003ec6 <namex+0x92>
    iunlockput(ip);
    80003f2c:	854e                	mv	a0,s3
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	bd4080e7          	jalr	-1068(ra) # 80003b02 <iunlockput>
    ip = next;
    80003f36:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f38:	0004c783          	lbu	a5,0(s1)
    80003f3c:	05279763          	bne	a5,s2,80003f8a <namex+0x156>
    path++;
    80003f40:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f42:	0004c783          	lbu	a5,0(s1)
    80003f46:	ff278de3          	beq	a5,s2,80003f40 <namex+0x10c>
  if(*path == 0)
    80003f4a:	c79d                	beqz	a5,80003f78 <namex+0x144>
    path++;
    80003f4c:	85a6                	mv	a1,s1
  len = path - s;
    80003f4e:	8cda                	mv	s9,s6
    80003f50:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f52:	01278963          	beq	a5,s2,80003f64 <namex+0x130>
    80003f56:	dfbd                	beqz	a5,80003ed4 <namex+0xa0>
    path++;
    80003f58:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	ff279ce3          	bne	a5,s2,80003f56 <namex+0x122>
    80003f62:	bf8d                	j	80003ed4 <namex+0xa0>
    memmove(name, s, len);
    80003f64:	2601                	sext.w	a2,a2
    80003f66:	8552                	mv	a0,s4
    80003f68:	ffffd097          	auipc	ra,0xffffd
    80003f6c:	dc6080e7          	jalr	-570(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003f70:	9cd2                	add	s9,s9,s4
    80003f72:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f76:	bf9d                	j	80003eec <namex+0xb8>
  if(nameiparent){
    80003f78:	f20a83e3          	beqz	s5,80003e9e <namex+0x6a>
    iput(ip);
    80003f7c:	854e                	mv	a0,s3
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	adc080e7          	jalr	-1316(ra) # 80003a5a <iput>
    return 0;
    80003f86:	4981                	li	s3,0
    80003f88:	bf19                	j	80003e9e <namex+0x6a>
  if(*path == 0)
    80003f8a:	d7fd                	beqz	a5,80003f78 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f8c:	0004c783          	lbu	a5,0(s1)
    80003f90:	85a6                	mv	a1,s1
    80003f92:	b7d1                	j	80003f56 <namex+0x122>

0000000080003f94 <dirlink>:
{
    80003f94:	7139                	addi	sp,sp,-64
    80003f96:	fc06                	sd	ra,56(sp)
    80003f98:	f822                	sd	s0,48(sp)
    80003f9a:	f426                	sd	s1,40(sp)
    80003f9c:	f04a                	sd	s2,32(sp)
    80003f9e:	ec4e                	sd	s3,24(sp)
    80003fa0:	e852                	sd	s4,16(sp)
    80003fa2:	0080                	addi	s0,sp,64
    80003fa4:	892a                	mv	s2,a0
    80003fa6:	8a2e                	mv	s4,a1
    80003fa8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003faa:	4601                	li	a2,0
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	dd8080e7          	jalr	-552(ra) # 80003d84 <dirlookup>
    80003fb4:	e93d                	bnez	a0,8000402a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb6:	04c92483          	lw	s1,76(s2)
    80003fba:	c49d                	beqz	s1,80003fe8 <dirlink+0x54>
    80003fbc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fbe:	4741                	li	a4,16
    80003fc0:	86a6                	mv	a3,s1
    80003fc2:	fc040613          	addi	a2,s0,-64
    80003fc6:	4581                	li	a1,0
    80003fc8:	854a                	mv	a0,s2
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	b8a080e7          	jalr	-1142(ra) # 80003b54 <readi>
    80003fd2:	47c1                	li	a5,16
    80003fd4:	06f51163          	bne	a0,a5,80004036 <dirlink+0xa2>
    if(de.inum == 0)
    80003fd8:	fc045783          	lhu	a5,-64(s0)
    80003fdc:	c791                	beqz	a5,80003fe8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fde:	24c1                	addiw	s1,s1,16
    80003fe0:	04c92783          	lw	a5,76(s2)
    80003fe4:	fcf4ede3          	bltu	s1,a5,80003fbe <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fe8:	4639                	li	a2,14
    80003fea:	85d2                	mv	a1,s4
    80003fec:	fc240513          	addi	a0,s0,-62
    80003ff0:	ffffd097          	auipc	ra,0xffffd
    80003ff4:	dee080e7          	jalr	-530(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003ff8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffc:	4741                	li	a4,16
    80003ffe:	86a6                	mv	a3,s1
    80004000:	fc040613          	addi	a2,s0,-64
    80004004:	4581                	li	a1,0
    80004006:	854a                	mv	a0,s2
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	c44080e7          	jalr	-956(ra) # 80003c4c <writei>
    80004010:	1541                	addi	a0,a0,-16
    80004012:	00a03533          	snez	a0,a0
    80004016:	40a00533          	neg	a0,a0
}
    8000401a:	70e2                	ld	ra,56(sp)
    8000401c:	7442                	ld	s0,48(sp)
    8000401e:	74a2                	ld	s1,40(sp)
    80004020:	7902                	ld	s2,32(sp)
    80004022:	69e2                	ld	s3,24(sp)
    80004024:	6a42                	ld	s4,16(sp)
    80004026:	6121                	addi	sp,sp,64
    80004028:	8082                	ret
    iput(ip);
    8000402a:	00000097          	auipc	ra,0x0
    8000402e:	a30080e7          	jalr	-1488(ra) # 80003a5a <iput>
    return -1;
    80004032:	557d                	li	a0,-1
    80004034:	b7dd                	j	8000401a <dirlink+0x86>
      panic("dirlink read");
    80004036:	00004517          	auipc	a0,0x4
    8000403a:	5f250513          	addi	a0,a0,1522 # 80008628 <syscalls+0x1d8>
    8000403e:	ffffc097          	auipc	ra,0xffffc
    80004042:	500080e7          	jalr	1280(ra) # 8000053e <panic>

0000000080004046 <namei>:

struct inode*
namei(char *path)
{
    80004046:	1101                	addi	sp,sp,-32
    80004048:	ec06                	sd	ra,24(sp)
    8000404a:	e822                	sd	s0,16(sp)
    8000404c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000404e:	fe040613          	addi	a2,s0,-32
    80004052:	4581                	li	a1,0
    80004054:	00000097          	auipc	ra,0x0
    80004058:	de0080e7          	jalr	-544(ra) # 80003e34 <namex>
}
    8000405c:	60e2                	ld	ra,24(sp)
    8000405e:	6442                	ld	s0,16(sp)
    80004060:	6105                	addi	sp,sp,32
    80004062:	8082                	ret

0000000080004064 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004064:	1141                	addi	sp,sp,-16
    80004066:	e406                	sd	ra,8(sp)
    80004068:	e022                	sd	s0,0(sp)
    8000406a:	0800                	addi	s0,sp,16
    8000406c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000406e:	4585                	li	a1,1
    80004070:	00000097          	auipc	ra,0x0
    80004074:	dc4080e7          	jalr	-572(ra) # 80003e34 <namex>
}
    80004078:	60a2                	ld	ra,8(sp)
    8000407a:	6402                	ld	s0,0(sp)
    8000407c:	0141                	addi	sp,sp,16
    8000407e:	8082                	ret

0000000080004080 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004080:	1101                	addi	sp,sp,-32
    80004082:	ec06                	sd	ra,24(sp)
    80004084:	e822                	sd	s0,16(sp)
    80004086:	e426                	sd	s1,8(sp)
    80004088:	e04a                	sd	s2,0(sp)
    8000408a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000408c:	0001d917          	auipc	s2,0x1d
    80004090:	e9490913          	addi	s2,s2,-364 # 80020f20 <log>
    80004094:	01892583          	lw	a1,24(s2)
    80004098:	02892503          	lw	a0,40(s2)
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	fea080e7          	jalr	-22(ra) # 80003086 <bread>
    800040a4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040a6:	02c92683          	lw	a3,44(s2)
    800040aa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040ac:	02d05763          	blez	a3,800040da <write_head+0x5a>
    800040b0:	0001d797          	auipc	a5,0x1d
    800040b4:	ea078793          	addi	a5,a5,-352 # 80020f50 <log+0x30>
    800040b8:	05c50713          	addi	a4,a0,92
    800040bc:	36fd                	addiw	a3,a3,-1
    800040be:	1682                	slli	a3,a3,0x20
    800040c0:	9281                	srli	a3,a3,0x20
    800040c2:	068a                	slli	a3,a3,0x2
    800040c4:	0001d617          	auipc	a2,0x1d
    800040c8:	e9060613          	addi	a2,a2,-368 # 80020f54 <log+0x34>
    800040cc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040ce:	4390                	lw	a2,0(a5)
    800040d0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040d2:	0791                	addi	a5,a5,4
    800040d4:	0711                	addi	a4,a4,4
    800040d6:	fed79ce3          	bne	a5,a3,800040ce <write_head+0x4e>
  }
  bwrite(buf);
    800040da:	8526                	mv	a0,s1
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	09c080e7          	jalr	156(ra) # 80003178 <bwrite>
  brelse(buf);
    800040e4:	8526                	mv	a0,s1
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	0d0080e7          	jalr	208(ra) # 800031b6 <brelse>
}
    800040ee:	60e2                	ld	ra,24(sp)
    800040f0:	6442                	ld	s0,16(sp)
    800040f2:	64a2                	ld	s1,8(sp)
    800040f4:	6902                	ld	s2,0(sp)
    800040f6:	6105                	addi	sp,sp,32
    800040f8:	8082                	ret

00000000800040fa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fa:	0001d797          	auipc	a5,0x1d
    800040fe:	e527a783          	lw	a5,-430(a5) # 80020f4c <log+0x2c>
    80004102:	0af05d63          	blez	a5,800041bc <install_trans+0xc2>
{
    80004106:	7139                	addi	sp,sp,-64
    80004108:	fc06                	sd	ra,56(sp)
    8000410a:	f822                	sd	s0,48(sp)
    8000410c:	f426                	sd	s1,40(sp)
    8000410e:	f04a                	sd	s2,32(sp)
    80004110:	ec4e                	sd	s3,24(sp)
    80004112:	e852                	sd	s4,16(sp)
    80004114:	e456                	sd	s5,8(sp)
    80004116:	e05a                	sd	s6,0(sp)
    80004118:	0080                	addi	s0,sp,64
    8000411a:	8b2a                	mv	s6,a0
    8000411c:	0001da97          	auipc	s5,0x1d
    80004120:	e34a8a93          	addi	s5,s5,-460 # 80020f50 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004124:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004126:	0001d997          	auipc	s3,0x1d
    8000412a:	dfa98993          	addi	s3,s3,-518 # 80020f20 <log>
    8000412e:	a00d                	j	80004150 <install_trans+0x56>
    brelse(lbuf);
    80004130:	854a                	mv	a0,s2
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	084080e7          	jalr	132(ra) # 800031b6 <brelse>
    brelse(dbuf);
    8000413a:	8526                	mv	a0,s1
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	07a080e7          	jalr	122(ra) # 800031b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004144:	2a05                	addiw	s4,s4,1
    80004146:	0a91                	addi	s5,s5,4
    80004148:	02c9a783          	lw	a5,44(s3)
    8000414c:	04fa5e63          	bge	s4,a5,800041a8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004150:	0189a583          	lw	a1,24(s3)
    80004154:	014585bb          	addw	a1,a1,s4
    80004158:	2585                	addiw	a1,a1,1
    8000415a:	0289a503          	lw	a0,40(s3)
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	f28080e7          	jalr	-216(ra) # 80003086 <bread>
    80004166:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004168:	000aa583          	lw	a1,0(s5)
    8000416c:	0289a503          	lw	a0,40(s3)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	f16080e7          	jalr	-234(ra) # 80003086 <bread>
    80004178:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000417a:	40000613          	li	a2,1024
    8000417e:	05890593          	addi	a1,s2,88
    80004182:	05850513          	addi	a0,a0,88
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	ba8080e7          	jalr	-1112(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000418e:	8526                	mv	a0,s1
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	fe8080e7          	jalr	-24(ra) # 80003178 <bwrite>
    if(recovering == 0)
    80004198:	f80b1ce3          	bnez	s6,80004130 <install_trans+0x36>
      bunpin(dbuf);
    8000419c:	8526                	mv	a0,s1
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	0f2080e7          	jalr	242(ra) # 80003290 <bunpin>
    800041a6:	b769                	j	80004130 <install_trans+0x36>
}
    800041a8:	70e2                	ld	ra,56(sp)
    800041aa:	7442                	ld	s0,48(sp)
    800041ac:	74a2                	ld	s1,40(sp)
    800041ae:	7902                	ld	s2,32(sp)
    800041b0:	69e2                	ld	s3,24(sp)
    800041b2:	6a42                	ld	s4,16(sp)
    800041b4:	6aa2                	ld	s5,8(sp)
    800041b6:	6b02                	ld	s6,0(sp)
    800041b8:	6121                	addi	sp,sp,64
    800041ba:	8082                	ret
    800041bc:	8082                	ret

00000000800041be <initlog>:
{
    800041be:	7179                	addi	sp,sp,-48
    800041c0:	f406                	sd	ra,40(sp)
    800041c2:	f022                	sd	s0,32(sp)
    800041c4:	ec26                	sd	s1,24(sp)
    800041c6:	e84a                	sd	s2,16(sp)
    800041c8:	e44e                	sd	s3,8(sp)
    800041ca:	1800                	addi	s0,sp,48
    800041cc:	892a                	mv	s2,a0
    800041ce:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041d0:	0001d497          	auipc	s1,0x1d
    800041d4:	d5048493          	addi	s1,s1,-688 # 80020f20 <log>
    800041d8:	00004597          	auipc	a1,0x4
    800041dc:	46058593          	addi	a1,a1,1120 # 80008638 <syscalls+0x1e8>
    800041e0:	8526                	mv	a0,s1
    800041e2:	ffffd097          	auipc	ra,0xffffd
    800041e6:	964080e7          	jalr	-1692(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800041ea:	0149a583          	lw	a1,20(s3)
    800041ee:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041f0:	0109a783          	lw	a5,16(s3)
    800041f4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041f6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041fa:	854a                	mv	a0,s2
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	e8a080e7          	jalr	-374(ra) # 80003086 <bread>
  log.lh.n = lh->n;
    80004204:	4d34                	lw	a3,88(a0)
    80004206:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004208:	02d05563          	blez	a3,80004232 <initlog+0x74>
    8000420c:	05c50793          	addi	a5,a0,92
    80004210:	0001d717          	auipc	a4,0x1d
    80004214:	d4070713          	addi	a4,a4,-704 # 80020f50 <log+0x30>
    80004218:	36fd                	addiw	a3,a3,-1
    8000421a:	1682                	slli	a3,a3,0x20
    8000421c:	9281                	srli	a3,a3,0x20
    8000421e:	068a                	slli	a3,a3,0x2
    80004220:	06050613          	addi	a2,a0,96
    80004224:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004226:	4390                	lw	a2,0(a5)
    80004228:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000422a:	0791                	addi	a5,a5,4
    8000422c:	0711                	addi	a4,a4,4
    8000422e:	fed79ce3          	bne	a5,a3,80004226 <initlog+0x68>
  brelse(buf);
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	f84080e7          	jalr	-124(ra) # 800031b6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000423a:	4505                	li	a0,1
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	ebe080e7          	jalr	-322(ra) # 800040fa <install_trans>
  log.lh.n = 0;
    80004244:	0001d797          	auipc	a5,0x1d
    80004248:	d007a423          	sw	zero,-760(a5) # 80020f4c <log+0x2c>
  write_head(); // clear the log
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	e34080e7          	jalr	-460(ra) # 80004080 <write_head>
}
    80004254:	70a2                	ld	ra,40(sp)
    80004256:	7402                	ld	s0,32(sp)
    80004258:	64e2                	ld	s1,24(sp)
    8000425a:	6942                	ld	s2,16(sp)
    8000425c:	69a2                	ld	s3,8(sp)
    8000425e:	6145                	addi	sp,sp,48
    80004260:	8082                	ret

0000000080004262 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004262:	1101                	addi	sp,sp,-32
    80004264:	ec06                	sd	ra,24(sp)
    80004266:	e822                	sd	s0,16(sp)
    80004268:	e426                	sd	s1,8(sp)
    8000426a:	e04a                	sd	s2,0(sp)
    8000426c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000426e:	0001d517          	auipc	a0,0x1d
    80004272:	cb250513          	addi	a0,a0,-846 # 80020f20 <log>
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	960080e7          	jalr	-1696(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000427e:	0001d497          	auipc	s1,0x1d
    80004282:	ca248493          	addi	s1,s1,-862 # 80020f20 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004286:	4979                	li	s2,30
    80004288:	a039                	j	80004296 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000428a:	85a6                	mv	a1,s1
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffe097          	auipc	ra,0xffffe
    80004292:	dda080e7          	jalr	-550(ra) # 80002068 <sleep>
    if(log.committing){
    80004296:	50dc                	lw	a5,36(s1)
    80004298:	fbed                	bnez	a5,8000428a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429a:	509c                	lw	a5,32(s1)
    8000429c:	0017871b          	addiw	a4,a5,1
    800042a0:	0007069b          	sext.w	a3,a4
    800042a4:	0027179b          	slliw	a5,a4,0x2
    800042a8:	9fb9                	addw	a5,a5,a4
    800042aa:	0017979b          	slliw	a5,a5,0x1
    800042ae:	54d8                	lw	a4,44(s1)
    800042b0:	9fb9                	addw	a5,a5,a4
    800042b2:	00f95963          	bge	s2,a5,800042c4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042b6:	85a6                	mv	a1,s1
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffe097          	auipc	ra,0xffffe
    800042be:	dae080e7          	jalr	-594(ra) # 80002068 <sleep>
    800042c2:	bfd1                	j	80004296 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042c4:	0001d517          	auipc	a0,0x1d
    800042c8:	c5c50513          	addi	a0,a0,-932 # 80020f20 <log>
    800042cc:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	9bc080e7          	jalr	-1604(ra) # 80000c8a <release>
      break;
    }
  }
}
    800042d6:	60e2                	ld	ra,24(sp)
    800042d8:	6442                	ld	s0,16(sp)
    800042da:	64a2                	ld	s1,8(sp)
    800042dc:	6902                	ld	s2,0(sp)
    800042de:	6105                	addi	sp,sp,32
    800042e0:	8082                	ret

00000000800042e2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042e2:	7139                	addi	sp,sp,-64
    800042e4:	fc06                	sd	ra,56(sp)
    800042e6:	f822                	sd	s0,48(sp)
    800042e8:	f426                	sd	s1,40(sp)
    800042ea:	f04a                	sd	s2,32(sp)
    800042ec:	ec4e                	sd	s3,24(sp)
    800042ee:	e852                	sd	s4,16(sp)
    800042f0:	e456                	sd	s5,8(sp)
    800042f2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042f4:	0001d497          	auipc	s1,0x1d
    800042f8:	c2c48493          	addi	s1,s1,-980 # 80020f20 <log>
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	8d8080e7          	jalr	-1832(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004306:	509c                	lw	a5,32(s1)
    80004308:	37fd                	addiw	a5,a5,-1
    8000430a:	0007891b          	sext.w	s2,a5
    8000430e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004310:	50dc                	lw	a5,36(s1)
    80004312:	e7b9                	bnez	a5,80004360 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004314:	04091e63          	bnez	s2,80004370 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004318:	0001d497          	auipc	s1,0x1d
    8000431c:	c0848493          	addi	s1,s1,-1016 # 80020f20 <log>
    80004320:	4785                	li	a5,1
    80004322:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004324:	8526                	mv	a0,s1
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	964080e7          	jalr	-1692(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000432e:	54dc                	lw	a5,44(s1)
    80004330:	06f04763          	bgtz	a5,8000439e <end_op+0xbc>
    acquire(&log.lock);
    80004334:	0001d497          	auipc	s1,0x1d
    80004338:	bec48493          	addi	s1,s1,-1044 # 80020f20 <log>
    8000433c:	8526                	mv	a0,s1
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	898080e7          	jalr	-1896(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004346:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffe097          	auipc	ra,0xffffe
    80004350:	d80080e7          	jalr	-640(ra) # 800020cc <wakeup>
    release(&log.lock);
    80004354:	8526                	mv	a0,s1
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	934080e7          	jalr	-1740(ra) # 80000c8a <release>
}
    8000435e:	a03d                	j	8000438c <end_op+0xaa>
    panic("log.committing");
    80004360:	00004517          	auipc	a0,0x4
    80004364:	2e050513          	addi	a0,a0,736 # 80008640 <syscalls+0x1f0>
    80004368:	ffffc097          	auipc	ra,0xffffc
    8000436c:	1d6080e7          	jalr	470(ra) # 8000053e <panic>
    wakeup(&log);
    80004370:	0001d497          	auipc	s1,0x1d
    80004374:	bb048493          	addi	s1,s1,-1104 # 80020f20 <log>
    80004378:	8526                	mv	a0,s1
    8000437a:	ffffe097          	auipc	ra,0xffffe
    8000437e:	d52080e7          	jalr	-686(ra) # 800020cc <wakeup>
  release(&log.lock);
    80004382:	8526                	mv	a0,s1
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	906080e7          	jalr	-1786(ra) # 80000c8a <release>
}
    8000438c:	70e2                	ld	ra,56(sp)
    8000438e:	7442                	ld	s0,48(sp)
    80004390:	74a2                	ld	s1,40(sp)
    80004392:	7902                	ld	s2,32(sp)
    80004394:	69e2                	ld	s3,24(sp)
    80004396:	6a42                	ld	s4,16(sp)
    80004398:	6aa2                	ld	s5,8(sp)
    8000439a:	6121                	addi	sp,sp,64
    8000439c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000439e:	0001da97          	auipc	s5,0x1d
    800043a2:	bb2a8a93          	addi	s5,s5,-1102 # 80020f50 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043a6:	0001da17          	auipc	s4,0x1d
    800043aa:	b7aa0a13          	addi	s4,s4,-1158 # 80020f20 <log>
    800043ae:	018a2583          	lw	a1,24(s4)
    800043b2:	012585bb          	addw	a1,a1,s2
    800043b6:	2585                	addiw	a1,a1,1
    800043b8:	028a2503          	lw	a0,40(s4)
    800043bc:	fffff097          	auipc	ra,0xfffff
    800043c0:	cca080e7          	jalr	-822(ra) # 80003086 <bread>
    800043c4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043c6:	000aa583          	lw	a1,0(s5)
    800043ca:	028a2503          	lw	a0,40(s4)
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	cb8080e7          	jalr	-840(ra) # 80003086 <bread>
    800043d6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043d8:	40000613          	li	a2,1024
    800043dc:	05850593          	addi	a1,a0,88
    800043e0:	05848513          	addi	a0,s1,88
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	94a080e7          	jalr	-1718(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800043ec:	8526                	mv	a0,s1
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	d8a080e7          	jalr	-630(ra) # 80003178 <bwrite>
    brelse(from);
    800043f6:	854e                	mv	a0,s3
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	dbe080e7          	jalr	-578(ra) # 800031b6 <brelse>
    brelse(to);
    80004400:	8526                	mv	a0,s1
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	db4080e7          	jalr	-588(ra) # 800031b6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440a:	2905                	addiw	s2,s2,1
    8000440c:	0a91                	addi	s5,s5,4
    8000440e:	02ca2783          	lw	a5,44(s4)
    80004412:	f8f94ee3          	blt	s2,a5,800043ae <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	c6a080e7          	jalr	-918(ra) # 80004080 <write_head>
    install_trans(0); // Now install writes to home locations
    8000441e:	4501                	li	a0,0
    80004420:	00000097          	auipc	ra,0x0
    80004424:	cda080e7          	jalr	-806(ra) # 800040fa <install_trans>
    log.lh.n = 0;
    80004428:	0001d797          	auipc	a5,0x1d
    8000442c:	b207a223          	sw	zero,-1244(a5) # 80020f4c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004430:	00000097          	auipc	ra,0x0
    80004434:	c50080e7          	jalr	-944(ra) # 80004080 <write_head>
    80004438:	bdf5                	j	80004334 <end_op+0x52>

000000008000443a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000443a:	1101                	addi	sp,sp,-32
    8000443c:	ec06                	sd	ra,24(sp)
    8000443e:	e822                	sd	s0,16(sp)
    80004440:	e426                	sd	s1,8(sp)
    80004442:	e04a                	sd	s2,0(sp)
    80004444:	1000                	addi	s0,sp,32
    80004446:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004448:	0001d917          	auipc	s2,0x1d
    8000444c:	ad890913          	addi	s2,s2,-1320 # 80020f20 <log>
    80004450:	854a                	mv	a0,s2
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	784080e7          	jalr	1924(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000445a:	02c92603          	lw	a2,44(s2)
    8000445e:	47f5                	li	a5,29
    80004460:	06c7c563          	blt	a5,a2,800044ca <log_write+0x90>
    80004464:	0001d797          	auipc	a5,0x1d
    80004468:	ad87a783          	lw	a5,-1320(a5) # 80020f3c <log+0x1c>
    8000446c:	37fd                	addiw	a5,a5,-1
    8000446e:	04f65e63          	bge	a2,a5,800044ca <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004472:	0001d797          	auipc	a5,0x1d
    80004476:	ace7a783          	lw	a5,-1330(a5) # 80020f40 <log+0x20>
    8000447a:	06f05063          	blez	a5,800044da <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000447e:	4781                	li	a5,0
    80004480:	06c05563          	blez	a2,800044ea <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004484:	44cc                	lw	a1,12(s1)
    80004486:	0001d717          	auipc	a4,0x1d
    8000448a:	aca70713          	addi	a4,a4,-1334 # 80020f50 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000448e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004490:	4314                	lw	a3,0(a4)
    80004492:	04b68c63          	beq	a3,a1,800044ea <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004496:	2785                	addiw	a5,a5,1
    80004498:	0711                	addi	a4,a4,4
    8000449a:	fef61be3          	bne	a2,a5,80004490 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000449e:	0621                	addi	a2,a2,8
    800044a0:	060a                	slli	a2,a2,0x2
    800044a2:	0001d797          	auipc	a5,0x1d
    800044a6:	a7e78793          	addi	a5,a5,-1410 # 80020f20 <log>
    800044aa:	963e                	add	a2,a2,a5
    800044ac:	44dc                	lw	a5,12(s1)
    800044ae:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044b0:	8526                	mv	a0,s1
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	da2080e7          	jalr	-606(ra) # 80003254 <bpin>
    log.lh.n++;
    800044ba:	0001d717          	auipc	a4,0x1d
    800044be:	a6670713          	addi	a4,a4,-1434 # 80020f20 <log>
    800044c2:	575c                	lw	a5,44(a4)
    800044c4:	2785                	addiw	a5,a5,1
    800044c6:	d75c                	sw	a5,44(a4)
    800044c8:	a835                	j	80004504 <log_write+0xca>
    panic("too big a transaction");
    800044ca:	00004517          	auipc	a0,0x4
    800044ce:	18650513          	addi	a0,a0,390 # 80008650 <syscalls+0x200>
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	06c080e7          	jalr	108(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044da:	00004517          	auipc	a0,0x4
    800044de:	18e50513          	addi	a0,a0,398 # 80008668 <syscalls+0x218>
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	05c080e7          	jalr	92(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044ea:	00878713          	addi	a4,a5,8
    800044ee:	00271693          	slli	a3,a4,0x2
    800044f2:	0001d717          	auipc	a4,0x1d
    800044f6:	a2e70713          	addi	a4,a4,-1490 # 80020f20 <log>
    800044fa:	9736                	add	a4,a4,a3
    800044fc:	44d4                	lw	a3,12(s1)
    800044fe:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004500:	faf608e3          	beq	a2,a5,800044b0 <log_write+0x76>
  }
  release(&log.lock);
    80004504:	0001d517          	auipc	a0,0x1d
    80004508:	a1c50513          	addi	a0,a0,-1508 # 80020f20 <log>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	77e080e7          	jalr	1918(ra) # 80000c8a <release>
}
    80004514:	60e2                	ld	ra,24(sp)
    80004516:	6442                	ld	s0,16(sp)
    80004518:	64a2                	ld	s1,8(sp)
    8000451a:	6902                	ld	s2,0(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret

0000000080004520 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004520:	1101                	addi	sp,sp,-32
    80004522:	ec06                	sd	ra,24(sp)
    80004524:	e822                	sd	s0,16(sp)
    80004526:	e426                	sd	s1,8(sp)
    80004528:	e04a                	sd	s2,0(sp)
    8000452a:	1000                	addi	s0,sp,32
    8000452c:	84aa                	mv	s1,a0
    8000452e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004530:	00004597          	auipc	a1,0x4
    80004534:	15858593          	addi	a1,a1,344 # 80008688 <syscalls+0x238>
    80004538:	0521                	addi	a0,a0,8
    8000453a:	ffffc097          	auipc	ra,0xffffc
    8000453e:	60c080e7          	jalr	1548(ra) # 80000b46 <initlock>
  lk->name = name;
    80004542:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004546:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000454a:	0204a423          	sw	zero,40(s1)
}
    8000454e:	60e2                	ld	ra,24(sp)
    80004550:	6442                	ld	s0,16(sp)
    80004552:	64a2                	ld	s1,8(sp)
    80004554:	6902                	ld	s2,0(sp)
    80004556:	6105                	addi	sp,sp,32
    80004558:	8082                	ret

000000008000455a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000455a:	1101                	addi	sp,sp,-32
    8000455c:	ec06                	sd	ra,24(sp)
    8000455e:	e822                	sd	s0,16(sp)
    80004560:	e426                	sd	s1,8(sp)
    80004562:	e04a                	sd	s2,0(sp)
    80004564:	1000                	addi	s0,sp,32
    80004566:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004568:	00850913          	addi	s2,a0,8
    8000456c:	854a                	mv	a0,s2
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	668080e7          	jalr	1640(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004576:	409c                	lw	a5,0(s1)
    80004578:	cb89                	beqz	a5,8000458a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000457a:	85ca                	mv	a1,s2
    8000457c:	8526                	mv	a0,s1
    8000457e:	ffffe097          	auipc	ra,0xffffe
    80004582:	aea080e7          	jalr	-1302(ra) # 80002068 <sleep>
  while (lk->locked) {
    80004586:	409c                	lw	a5,0(s1)
    80004588:	fbed                	bnez	a5,8000457a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000458a:	4785                	li	a5,1
    8000458c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000458e:	ffffd097          	auipc	ra,0xffffd
    80004592:	41e080e7          	jalr	1054(ra) # 800019ac <myproc>
    80004596:	591c                	lw	a5,48(a0)
    80004598:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000459a:	854a                	mv	a0,s2
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	6ee080e7          	jalr	1774(ra) # 80000c8a <release>
}
    800045a4:	60e2                	ld	ra,24(sp)
    800045a6:	6442                	ld	s0,16(sp)
    800045a8:	64a2                	ld	s1,8(sp)
    800045aa:	6902                	ld	s2,0(sp)
    800045ac:	6105                	addi	sp,sp,32
    800045ae:	8082                	ret

00000000800045b0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045b0:	1101                	addi	sp,sp,-32
    800045b2:	ec06                	sd	ra,24(sp)
    800045b4:	e822                	sd	s0,16(sp)
    800045b6:	e426                	sd	s1,8(sp)
    800045b8:	e04a                	sd	s2,0(sp)
    800045ba:	1000                	addi	s0,sp,32
    800045bc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045be:	00850913          	addi	s2,a0,8
    800045c2:	854a                	mv	a0,s2
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	612080e7          	jalr	1554(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800045cc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d0:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffe097          	auipc	ra,0xffffe
    800045da:	af6080e7          	jalr	-1290(ra) # 800020cc <wakeup>
  release(&lk->lk);
    800045de:	854a                	mv	a0,s2
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6aa080e7          	jalr	1706(ra) # 80000c8a <release>
}
    800045e8:	60e2                	ld	ra,24(sp)
    800045ea:	6442                	ld	s0,16(sp)
    800045ec:	64a2                	ld	s1,8(sp)
    800045ee:	6902                	ld	s2,0(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045f4:	7179                	addi	sp,sp,-48
    800045f6:	f406                	sd	ra,40(sp)
    800045f8:	f022                	sd	s0,32(sp)
    800045fa:	ec26                	sd	s1,24(sp)
    800045fc:	e84a                	sd	s2,16(sp)
    800045fe:	e44e                	sd	s3,8(sp)
    80004600:	1800                	addi	s0,sp,48
    80004602:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004604:	00850913          	addi	s2,a0,8
    80004608:	854a                	mv	a0,s2
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	5cc080e7          	jalr	1484(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004612:	409c                	lw	a5,0(s1)
    80004614:	ef99                	bnez	a5,80004632 <holdingsleep+0x3e>
    80004616:	4481                	li	s1,0
  release(&lk->lk);
    80004618:	854a                	mv	a0,s2
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	670080e7          	jalr	1648(ra) # 80000c8a <release>
  return r;
}
    80004622:	8526                	mv	a0,s1
    80004624:	70a2                	ld	ra,40(sp)
    80004626:	7402                	ld	s0,32(sp)
    80004628:	64e2                	ld	s1,24(sp)
    8000462a:	6942                	ld	s2,16(sp)
    8000462c:	69a2                	ld	s3,8(sp)
    8000462e:	6145                	addi	sp,sp,48
    80004630:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004632:	0284a983          	lw	s3,40(s1)
    80004636:	ffffd097          	auipc	ra,0xffffd
    8000463a:	376080e7          	jalr	886(ra) # 800019ac <myproc>
    8000463e:	5904                	lw	s1,48(a0)
    80004640:	413484b3          	sub	s1,s1,s3
    80004644:	0014b493          	seqz	s1,s1
    80004648:	bfc1                	j	80004618 <holdingsleep+0x24>

000000008000464a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000464a:	1141                	addi	sp,sp,-16
    8000464c:	e406                	sd	ra,8(sp)
    8000464e:	e022                	sd	s0,0(sp)
    80004650:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004652:	00004597          	auipc	a1,0x4
    80004656:	04658593          	addi	a1,a1,70 # 80008698 <syscalls+0x248>
    8000465a:	0001d517          	auipc	a0,0x1d
    8000465e:	a0e50513          	addi	a0,a0,-1522 # 80021068 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	4e4080e7          	jalr	1252(ra) # 80000b46 <initlock>
}
    8000466a:	60a2                	ld	ra,8(sp)
    8000466c:	6402                	ld	s0,0(sp)
    8000466e:	0141                	addi	sp,sp,16
    80004670:	8082                	ret

0000000080004672 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004672:	1101                	addi	sp,sp,-32
    80004674:	ec06                	sd	ra,24(sp)
    80004676:	e822                	sd	s0,16(sp)
    80004678:	e426                	sd	s1,8(sp)
    8000467a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000467c:	0001d517          	auipc	a0,0x1d
    80004680:	9ec50513          	addi	a0,a0,-1556 # 80021068 <ftable>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	552080e7          	jalr	1362(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000468c:	0001d497          	auipc	s1,0x1d
    80004690:	9f448493          	addi	s1,s1,-1548 # 80021080 <ftable+0x18>
    80004694:	0001e717          	auipc	a4,0x1e
    80004698:	98c70713          	addi	a4,a4,-1652 # 80022020 <disk>
    if(f->ref == 0){
    8000469c:	40dc                	lw	a5,4(s1)
    8000469e:	cf99                	beqz	a5,800046bc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a0:	02848493          	addi	s1,s1,40
    800046a4:	fee49ce3          	bne	s1,a4,8000469c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046a8:	0001d517          	auipc	a0,0x1d
    800046ac:	9c050513          	addi	a0,a0,-1600 # 80021068 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5da080e7          	jalr	1498(ra) # 80000c8a <release>
  return 0;
    800046b8:	4481                	li	s1,0
    800046ba:	a819                	j	800046d0 <filealloc+0x5e>
      f->ref = 1;
    800046bc:	4785                	li	a5,1
    800046be:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046c0:	0001d517          	auipc	a0,0x1d
    800046c4:	9a850513          	addi	a0,a0,-1624 # 80021068 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5c2080e7          	jalr	1474(ra) # 80000c8a <release>
}
    800046d0:	8526                	mv	a0,s1
    800046d2:	60e2                	ld	ra,24(sp)
    800046d4:	6442                	ld	s0,16(sp)
    800046d6:	64a2                	ld	s1,8(sp)
    800046d8:	6105                	addi	sp,sp,32
    800046da:	8082                	ret

00000000800046dc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046dc:	1101                	addi	sp,sp,-32
    800046de:	ec06                	sd	ra,24(sp)
    800046e0:	e822                	sd	s0,16(sp)
    800046e2:	e426                	sd	s1,8(sp)
    800046e4:	1000                	addi	s0,sp,32
    800046e6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	98050513          	addi	a0,a0,-1664 # 80021068 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	4e6080e7          	jalr	1254(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046f8:	40dc                	lw	a5,4(s1)
    800046fa:	02f05263          	blez	a5,8000471e <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046fe:	2785                	addiw	a5,a5,1
    80004700:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004702:	0001d517          	auipc	a0,0x1d
    80004706:	96650513          	addi	a0,a0,-1690 # 80021068 <ftable>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	580080e7          	jalr	1408(ra) # 80000c8a <release>
  return f;
}
    80004712:	8526                	mv	a0,s1
    80004714:	60e2                	ld	ra,24(sp)
    80004716:	6442                	ld	s0,16(sp)
    80004718:	64a2                	ld	s1,8(sp)
    8000471a:	6105                	addi	sp,sp,32
    8000471c:	8082                	ret
    panic("filedup");
    8000471e:	00004517          	auipc	a0,0x4
    80004722:	f8250513          	addi	a0,a0,-126 # 800086a0 <syscalls+0x250>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>

000000008000472e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000472e:	7139                	addi	sp,sp,-64
    80004730:	fc06                	sd	ra,56(sp)
    80004732:	f822                	sd	s0,48(sp)
    80004734:	f426                	sd	s1,40(sp)
    80004736:	f04a                	sd	s2,32(sp)
    80004738:	ec4e                	sd	s3,24(sp)
    8000473a:	e852                	sd	s4,16(sp)
    8000473c:	e456                	sd	s5,8(sp)
    8000473e:	0080                	addi	s0,sp,64
    80004740:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004742:	0001d517          	auipc	a0,0x1d
    80004746:	92650513          	addi	a0,a0,-1754 # 80021068 <ftable>
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	48c080e7          	jalr	1164(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004752:	40dc                	lw	a5,4(s1)
    80004754:	06f05163          	blez	a5,800047b6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004758:	37fd                	addiw	a5,a5,-1
    8000475a:	0007871b          	sext.w	a4,a5
    8000475e:	c0dc                	sw	a5,4(s1)
    80004760:	06e04363          	bgtz	a4,800047c6 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004764:	0004a903          	lw	s2,0(s1)
    80004768:	0094ca83          	lbu	s5,9(s1)
    8000476c:	0104ba03          	ld	s4,16(s1)
    80004770:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004774:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004778:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000477c:	0001d517          	auipc	a0,0x1d
    80004780:	8ec50513          	addi	a0,a0,-1812 # 80021068 <ftable>
    80004784:	ffffc097          	auipc	ra,0xffffc
    80004788:	506080e7          	jalr	1286(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    8000478c:	4785                	li	a5,1
    8000478e:	04f90d63          	beq	s2,a5,800047e8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004792:	3979                	addiw	s2,s2,-2
    80004794:	4785                	li	a5,1
    80004796:	0527e063          	bltu	a5,s2,800047d6 <fileclose+0xa8>
    begin_op();
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	ac8080e7          	jalr	-1336(ra) # 80004262 <begin_op>
    iput(ff.ip);
    800047a2:	854e                	mv	a0,s3
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	2b6080e7          	jalr	694(ra) # 80003a5a <iput>
    end_op();
    800047ac:	00000097          	auipc	ra,0x0
    800047b0:	b36080e7          	jalr	-1226(ra) # 800042e2 <end_op>
    800047b4:	a00d                	j	800047d6 <fileclose+0xa8>
    panic("fileclose");
    800047b6:	00004517          	auipc	a0,0x4
    800047ba:	ef250513          	addi	a0,a0,-270 # 800086a8 <syscalls+0x258>
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	d80080e7          	jalr	-640(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	8a250513          	addi	a0,a0,-1886 # 80021068 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	4bc080e7          	jalr	1212(ra) # 80000c8a <release>
  }
}
    800047d6:	70e2                	ld	ra,56(sp)
    800047d8:	7442                	ld	s0,48(sp)
    800047da:	74a2                	ld	s1,40(sp)
    800047dc:	7902                	ld	s2,32(sp)
    800047de:	69e2                	ld	s3,24(sp)
    800047e0:	6a42                	ld	s4,16(sp)
    800047e2:	6aa2                	ld	s5,8(sp)
    800047e4:	6121                	addi	sp,sp,64
    800047e6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047e8:	85d6                	mv	a1,s5
    800047ea:	8552                	mv	a0,s4
    800047ec:	00000097          	auipc	ra,0x0
    800047f0:	34c080e7          	jalr	844(ra) # 80004b38 <pipeclose>
    800047f4:	b7cd                	j	800047d6 <fileclose+0xa8>

00000000800047f6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047f6:	715d                	addi	sp,sp,-80
    800047f8:	e486                	sd	ra,72(sp)
    800047fa:	e0a2                	sd	s0,64(sp)
    800047fc:	fc26                	sd	s1,56(sp)
    800047fe:	f84a                	sd	s2,48(sp)
    80004800:	f44e                	sd	s3,40(sp)
    80004802:	0880                	addi	s0,sp,80
    80004804:	84aa                	mv	s1,a0
    80004806:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004808:	ffffd097          	auipc	ra,0xffffd
    8000480c:	1a4080e7          	jalr	420(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004810:	409c                	lw	a5,0(s1)
    80004812:	37f9                	addiw	a5,a5,-2
    80004814:	4705                	li	a4,1
    80004816:	04f76763          	bltu	a4,a5,80004864 <filestat+0x6e>
    8000481a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000481c:	6c88                	ld	a0,24(s1)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	082080e7          	jalr	130(ra) # 800038a0 <ilock>
    stati(f->ip, &st);
    80004826:	fb840593          	addi	a1,s0,-72
    8000482a:	6c88                	ld	a0,24(s1)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	2fe080e7          	jalr	766(ra) # 80003b2a <stati>
    iunlock(f->ip);
    80004834:	6c88                	ld	a0,24(s1)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	12c080e7          	jalr	300(ra) # 80003962 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000483e:	46e1                	li	a3,24
    80004840:	fb840613          	addi	a2,s0,-72
    80004844:	85ce                	mv	a1,s3
    80004846:	05093503          	ld	a0,80(s2)
    8000484a:	ffffd097          	auipc	ra,0xffffd
    8000484e:	e1e080e7          	jalr	-482(ra) # 80001668 <copyout>
    80004852:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004856:	60a6                	ld	ra,72(sp)
    80004858:	6406                	ld	s0,64(sp)
    8000485a:	74e2                	ld	s1,56(sp)
    8000485c:	7942                	ld	s2,48(sp)
    8000485e:	79a2                	ld	s3,40(sp)
    80004860:	6161                	addi	sp,sp,80
    80004862:	8082                	ret
  return -1;
    80004864:	557d                	li	a0,-1
    80004866:	bfc5                	j	80004856 <filestat+0x60>

0000000080004868 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004868:	7179                	addi	sp,sp,-48
    8000486a:	f406                	sd	ra,40(sp)
    8000486c:	f022                	sd	s0,32(sp)
    8000486e:	ec26                	sd	s1,24(sp)
    80004870:	e84a                	sd	s2,16(sp)
    80004872:	e44e                	sd	s3,8(sp)
    80004874:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004876:	00854783          	lbu	a5,8(a0)
    8000487a:	c3d5                	beqz	a5,8000491e <fileread+0xb6>
    8000487c:	84aa                	mv	s1,a0
    8000487e:	89ae                	mv	s3,a1
    80004880:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004882:	411c                	lw	a5,0(a0)
    80004884:	4705                	li	a4,1
    80004886:	04e78963          	beq	a5,a4,800048d8 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000488a:	470d                	li	a4,3
    8000488c:	04e78d63          	beq	a5,a4,800048e6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004890:	4709                	li	a4,2
    80004892:	06e79e63          	bne	a5,a4,8000490e <fileread+0xa6>
    ilock(f->ip);
    80004896:	6d08                	ld	a0,24(a0)
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	008080e7          	jalr	8(ra) # 800038a0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048a0:	874a                	mv	a4,s2
    800048a2:	5094                	lw	a3,32(s1)
    800048a4:	864e                	mv	a2,s3
    800048a6:	4585                	li	a1,1
    800048a8:	6c88                	ld	a0,24(s1)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	2aa080e7          	jalr	682(ra) # 80003b54 <readi>
    800048b2:	892a                	mv	s2,a0
    800048b4:	00a05563          	blez	a0,800048be <fileread+0x56>
      f->off += r;
    800048b8:	509c                	lw	a5,32(s1)
    800048ba:	9fa9                	addw	a5,a5,a0
    800048bc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048be:	6c88                	ld	a0,24(s1)
    800048c0:	fffff097          	auipc	ra,0xfffff
    800048c4:	0a2080e7          	jalr	162(ra) # 80003962 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048c8:	854a                	mv	a0,s2
    800048ca:	70a2                	ld	ra,40(sp)
    800048cc:	7402                	ld	s0,32(sp)
    800048ce:	64e2                	ld	s1,24(sp)
    800048d0:	6942                	ld	s2,16(sp)
    800048d2:	69a2                	ld	s3,8(sp)
    800048d4:	6145                	addi	sp,sp,48
    800048d6:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048d8:	6908                	ld	a0,16(a0)
    800048da:	00000097          	auipc	ra,0x0
    800048de:	3c6080e7          	jalr	966(ra) # 80004ca0 <piperead>
    800048e2:	892a                	mv	s2,a0
    800048e4:	b7d5                	j	800048c8 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048e6:	02451783          	lh	a5,36(a0)
    800048ea:	03079693          	slli	a3,a5,0x30
    800048ee:	92c1                	srli	a3,a3,0x30
    800048f0:	4725                	li	a4,9
    800048f2:	02d76863          	bltu	a4,a3,80004922 <fileread+0xba>
    800048f6:	0792                	slli	a5,a5,0x4
    800048f8:	0001c717          	auipc	a4,0x1c
    800048fc:	6d070713          	addi	a4,a4,1744 # 80020fc8 <devsw>
    80004900:	97ba                	add	a5,a5,a4
    80004902:	639c                	ld	a5,0(a5)
    80004904:	c38d                	beqz	a5,80004926 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004906:	4505                	li	a0,1
    80004908:	9782                	jalr	a5
    8000490a:	892a                	mv	s2,a0
    8000490c:	bf75                	j	800048c8 <fileread+0x60>
    panic("fileread");
    8000490e:	00004517          	auipc	a0,0x4
    80004912:	daa50513          	addi	a0,a0,-598 # 800086b8 <syscalls+0x268>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	c28080e7          	jalr	-984(ra) # 8000053e <panic>
    return -1;
    8000491e:	597d                	li	s2,-1
    80004920:	b765                	j	800048c8 <fileread+0x60>
      return -1;
    80004922:	597d                	li	s2,-1
    80004924:	b755                	j	800048c8 <fileread+0x60>
    80004926:	597d                	li	s2,-1
    80004928:	b745                	j	800048c8 <fileread+0x60>

000000008000492a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000492a:	715d                	addi	sp,sp,-80
    8000492c:	e486                	sd	ra,72(sp)
    8000492e:	e0a2                	sd	s0,64(sp)
    80004930:	fc26                	sd	s1,56(sp)
    80004932:	f84a                	sd	s2,48(sp)
    80004934:	f44e                	sd	s3,40(sp)
    80004936:	f052                	sd	s4,32(sp)
    80004938:	ec56                	sd	s5,24(sp)
    8000493a:	e85a                	sd	s6,16(sp)
    8000493c:	e45e                	sd	s7,8(sp)
    8000493e:	e062                	sd	s8,0(sp)
    80004940:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004942:	00954783          	lbu	a5,9(a0)
    80004946:	10078663          	beqz	a5,80004a52 <filewrite+0x128>
    8000494a:	892a                	mv	s2,a0
    8000494c:	8aae                	mv	s5,a1
    8000494e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004950:	411c                	lw	a5,0(a0)
    80004952:	4705                	li	a4,1
    80004954:	02e78263          	beq	a5,a4,80004978 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004958:	470d                	li	a4,3
    8000495a:	02e78663          	beq	a5,a4,80004986 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000495e:	4709                	li	a4,2
    80004960:	0ee79163          	bne	a5,a4,80004a42 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004964:	0ac05d63          	blez	a2,80004a1e <filewrite+0xf4>
    int i = 0;
    80004968:	4981                	li	s3,0
    8000496a:	6b05                	lui	s6,0x1
    8000496c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004970:	6b85                	lui	s7,0x1
    80004972:	c00b8b9b          	addiw	s7,s7,-1024
    80004976:	a861                	j	80004a0e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004978:	6908                	ld	a0,16(a0)
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	22e080e7          	jalr	558(ra) # 80004ba8 <pipewrite>
    80004982:	8a2a                	mv	s4,a0
    80004984:	a045                	j	80004a24 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004986:	02451783          	lh	a5,36(a0)
    8000498a:	03079693          	slli	a3,a5,0x30
    8000498e:	92c1                	srli	a3,a3,0x30
    80004990:	4725                	li	a4,9
    80004992:	0cd76263          	bltu	a4,a3,80004a56 <filewrite+0x12c>
    80004996:	0792                	slli	a5,a5,0x4
    80004998:	0001c717          	auipc	a4,0x1c
    8000499c:	63070713          	addi	a4,a4,1584 # 80020fc8 <devsw>
    800049a0:	97ba                	add	a5,a5,a4
    800049a2:	679c                	ld	a5,8(a5)
    800049a4:	cbdd                	beqz	a5,80004a5a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049a6:	4505                	li	a0,1
    800049a8:	9782                	jalr	a5
    800049aa:	8a2a                	mv	s4,a0
    800049ac:	a8a5                	j	80004a24 <filewrite+0xfa>
    800049ae:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	8b0080e7          	jalr	-1872(ra) # 80004262 <begin_op>
      ilock(f->ip);
    800049ba:	01893503          	ld	a0,24(s2)
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	ee2080e7          	jalr	-286(ra) # 800038a0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049c6:	8762                	mv	a4,s8
    800049c8:	02092683          	lw	a3,32(s2)
    800049cc:	01598633          	add	a2,s3,s5
    800049d0:	4585                	li	a1,1
    800049d2:	01893503          	ld	a0,24(s2)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	276080e7          	jalr	630(ra) # 80003c4c <writei>
    800049de:	84aa                	mv	s1,a0
    800049e0:	00a05763          	blez	a0,800049ee <filewrite+0xc4>
        f->off += r;
    800049e4:	02092783          	lw	a5,32(s2)
    800049e8:	9fa9                	addw	a5,a5,a0
    800049ea:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049ee:	01893503          	ld	a0,24(s2)
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	f70080e7          	jalr	-144(ra) # 80003962 <iunlock>
      end_op();
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	8e8080e7          	jalr	-1816(ra) # 800042e2 <end_op>

      if(r != n1){
    80004a02:	009c1f63          	bne	s8,s1,80004a20 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a06:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a0a:	0149db63          	bge	s3,s4,80004a20 <filewrite+0xf6>
      int n1 = n - i;
    80004a0e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a12:	84be                	mv	s1,a5
    80004a14:	2781                	sext.w	a5,a5
    80004a16:	f8fb5ce3          	bge	s6,a5,800049ae <filewrite+0x84>
    80004a1a:	84de                	mv	s1,s7
    80004a1c:	bf49                	j	800049ae <filewrite+0x84>
    int i = 0;
    80004a1e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a20:	013a1f63          	bne	s4,s3,80004a3e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a24:	8552                	mv	a0,s4
    80004a26:	60a6                	ld	ra,72(sp)
    80004a28:	6406                	ld	s0,64(sp)
    80004a2a:	74e2                	ld	s1,56(sp)
    80004a2c:	7942                	ld	s2,48(sp)
    80004a2e:	79a2                	ld	s3,40(sp)
    80004a30:	7a02                	ld	s4,32(sp)
    80004a32:	6ae2                	ld	s5,24(sp)
    80004a34:	6b42                	ld	s6,16(sp)
    80004a36:	6ba2                	ld	s7,8(sp)
    80004a38:	6c02                	ld	s8,0(sp)
    80004a3a:	6161                	addi	sp,sp,80
    80004a3c:	8082                	ret
    ret = (i == n ? n : -1);
    80004a3e:	5a7d                	li	s4,-1
    80004a40:	b7d5                	j	80004a24 <filewrite+0xfa>
    panic("filewrite");
    80004a42:	00004517          	auipc	a0,0x4
    80004a46:	c8650513          	addi	a0,a0,-890 # 800086c8 <syscalls+0x278>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	af4080e7          	jalr	-1292(ra) # 8000053e <panic>
    return -1;
    80004a52:	5a7d                	li	s4,-1
    80004a54:	bfc1                	j	80004a24 <filewrite+0xfa>
      return -1;
    80004a56:	5a7d                	li	s4,-1
    80004a58:	b7f1                	j	80004a24 <filewrite+0xfa>
    80004a5a:	5a7d                	li	s4,-1
    80004a5c:	b7e1                	j	80004a24 <filewrite+0xfa>

0000000080004a5e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a5e:	7179                	addi	sp,sp,-48
    80004a60:	f406                	sd	ra,40(sp)
    80004a62:	f022                	sd	s0,32(sp)
    80004a64:	ec26                	sd	s1,24(sp)
    80004a66:	e84a                	sd	s2,16(sp)
    80004a68:	e44e                	sd	s3,8(sp)
    80004a6a:	e052                	sd	s4,0(sp)
    80004a6c:	1800                	addi	s0,sp,48
    80004a6e:	84aa                	mv	s1,a0
    80004a70:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a72:	0005b023          	sd	zero,0(a1)
    80004a76:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	bf8080e7          	jalr	-1032(ra) # 80004672 <filealloc>
    80004a82:	e088                	sd	a0,0(s1)
    80004a84:	c551                	beqz	a0,80004b10 <pipealloc+0xb2>
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	bec080e7          	jalr	-1044(ra) # 80004672 <filealloc>
    80004a8e:	00aa3023          	sd	a0,0(s4)
    80004a92:	c92d                	beqz	a0,80004b04 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	052080e7          	jalr	82(ra) # 80000ae6 <kalloc>
    80004a9c:	892a                	mv	s2,a0
    80004a9e:	c125                	beqz	a0,80004afe <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004aa0:	4985                	li	s3,1
    80004aa2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aa6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aaa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aae:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ab2:	00004597          	auipc	a1,0x4
    80004ab6:	c2658593          	addi	a1,a1,-986 # 800086d8 <syscalls+0x288>
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	08c080e7          	jalr	140(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004ac2:	609c                	ld	a5,0(s1)
    80004ac4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ac8:	609c                	ld	a5,0(s1)
    80004aca:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ace:	609c                	ld	a5,0(s1)
    80004ad0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ad4:	609c                	ld	a5,0(s1)
    80004ad6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ada:	000a3783          	ld	a5,0(s4)
    80004ade:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ae2:	000a3783          	ld	a5,0(s4)
    80004ae6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004aea:	000a3783          	ld	a5,0(s4)
    80004aee:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004af2:	000a3783          	ld	a5,0(s4)
    80004af6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004afa:	4501                	li	a0,0
    80004afc:	a025                	j	80004b24 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004afe:	6088                	ld	a0,0(s1)
    80004b00:	e501                	bnez	a0,80004b08 <pipealloc+0xaa>
    80004b02:	a039                	j	80004b10 <pipealloc+0xb2>
    80004b04:	6088                	ld	a0,0(s1)
    80004b06:	c51d                	beqz	a0,80004b34 <pipealloc+0xd6>
    fileclose(*f0);
    80004b08:	00000097          	auipc	ra,0x0
    80004b0c:	c26080e7          	jalr	-986(ra) # 8000472e <fileclose>
  if(*f1)
    80004b10:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b14:	557d                	li	a0,-1
  if(*f1)
    80004b16:	c799                	beqz	a5,80004b24 <pipealloc+0xc6>
    fileclose(*f1);
    80004b18:	853e                	mv	a0,a5
    80004b1a:	00000097          	auipc	ra,0x0
    80004b1e:	c14080e7          	jalr	-1004(ra) # 8000472e <fileclose>
  return -1;
    80004b22:	557d                	li	a0,-1
}
    80004b24:	70a2                	ld	ra,40(sp)
    80004b26:	7402                	ld	s0,32(sp)
    80004b28:	64e2                	ld	s1,24(sp)
    80004b2a:	6942                	ld	s2,16(sp)
    80004b2c:	69a2                	ld	s3,8(sp)
    80004b2e:	6a02                	ld	s4,0(sp)
    80004b30:	6145                	addi	sp,sp,48
    80004b32:	8082                	ret
  return -1;
    80004b34:	557d                	li	a0,-1
    80004b36:	b7fd                	j	80004b24 <pipealloc+0xc6>

0000000080004b38 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b38:	1101                	addi	sp,sp,-32
    80004b3a:	ec06                	sd	ra,24(sp)
    80004b3c:	e822                	sd	s0,16(sp)
    80004b3e:	e426                	sd	s1,8(sp)
    80004b40:	e04a                	sd	s2,0(sp)
    80004b42:	1000                	addi	s0,sp,32
    80004b44:	84aa                	mv	s1,a0
    80004b46:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	08e080e7          	jalr	142(ra) # 80000bd6 <acquire>
  if(writable){
    80004b50:	02090d63          	beqz	s2,80004b8a <pipeclose+0x52>
    pi->writeopen = 0;
    80004b54:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b58:	21848513          	addi	a0,s1,536
    80004b5c:	ffffd097          	auipc	ra,0xffffd
    80004b60:	570080e7          	jalr	1392(ra) # 800020cc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b64:	2204b783          	ld	a5,544(s1)
    80004b68:	eb95                	bnez	a5,80004b9c <pipeclose+0x64>
    release(&pi->lock);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	11e080e7          	jalr	286(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004b74:	8526                	mv	a0,s1
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	e74080e7          	jalr	-396(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004b7e:	60e2                	ld	ra,24(sp)
    80004b80:	6442                	ld	s0,16(sp)
    80004b82:	64a2                	ld	s1,8(sp)
    80004b84:	6902                	ld	s2,0(sp)
    80004b86:	6105                	addi	sp,sp,32
    80004b88:	8082                	ret
    pi->readopen = 0;
    80004b8a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b8e:	21c48513          	addi	a0,s1,540
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	53a080e7          	jalr	1338(ra) # 800020cc <wakeup>
    80004b9a:	b7e9                	j	80004b64 <pipeclose+0x2c>
    release(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	0ec080e7          	jalr	236(ra) # 80000c8a <release>
}
    80004ba6:	bfe1                	j	80004b7e <pipeclose+0x46>

0000000080004ba8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ba8:	711d                	addi	sp,sp,-96
    80004baa:	ec86                	sd	ra,88(sp)
    80004bac:	e8a2                	sd	s0,80(sp)
    80004bae:	e4a6                	sd	s1,72(sp)
    80004bb0:	e0ca                	sd	s2,64(sp)
    80004bb2:	fc4e                	sd	s3,56(sp)
    80004bb4:	f852                	sd	s4,48(sp)
    80004bb6:	f456                	sd	s5,40(sp)
    80004bb8:	f05a                	sd	s6,32(sp)
    80004bba:	ec5e                	sd	s7,24(sp)
    80004bbc:	e862                	sd	s8,16(sp)
    80004bbe:	1080                	addi	s0,sp,96
    80004bc0:	84aa                	mv	s1,a0
    80004bc2:	8aae                	mv	s5,a1
    80004bc4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	de6080e7          	jalr	-538(ra) # 800019ac <myproc>
    80004bce:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bd0:	8526                	mv	a0,s1
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	004080e7          	jalr	4(ra) # 80000bd6 <acquire>
  while(i < n){
    80004bda:	0b405663          	blez	s4,80004c86 <pipewrite+0xde>
  int i = 0;
    80004bde:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004be0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004be2:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004be6:	21c48b93          	addi	s7,s1,540
    80004bea:	a089                	j	80004c2c <pipewrite+0x84>
      release(&pi->lock);
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	09c080e7          	jalr	156(ra) # 80000c8a <release>
      return -1;
    80004bf6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bf8:	854a                	mv	a0,s2
    80004bfa:	60e6                	ld	ra,88(sp)
    80004bfc:	6446                	ld	s0,80(sp)
    80004bfe:	64a6                	ld	s1,72(sp)
    80004c00:	6906                	ld	s2,64(sp)
    80004c02:	79e2                	ld	s3,56(sp)
    80004c04:	7a42                	ld	s4,48(sp)
    80004c06:	7aa2                	ld	s5,40(sp)
    80004c08:	7b02                	ld	s6,32(sp)
    80004c0a:	6be2                	ld	s7,24(sp)
    80004c0c:	6c42                	ld	s8,16(sp)
    80004c0e:	6125                	addi	sp,sp,96
    80004c10:	8082                	ret
      wakeup(&pi->nread);
    80004c12:	8562                	mv	a0,s8
    80004c14:	ffffd097          	auipc	ra,0xffffd
    80004c18:	4b8080e7          	jalr	1208(ra) # 800020cc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c1c:	85a6                	mv	a1,s1
    80004c1e:	855e                	mv	a0,s7
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	448080e7          	jalr	1096(ra) # 80002068 <sleep>
  while(i < n){
    80004c28:	07495063          	bge	s2,s4,80004c88 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c2c:	2204a783          	lw	a5,544(s1)
    80004c30:	dfd5                	beqz	a5,80004bec <pipewrite+0x44>
    80004c32:	854e                	mv	a0,s3
    80004c34:	ffffd097          	auipc	ra,0xffffd
    80004c38:	6e8080e7          	jalr	1768(ra) # 8000231c <killed>
    80004c3c:	f945                	bnez	a0,80004bec <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c3e:	2184a783          	lw	a5,536(s1)
    80004c42:	21c4a703          	lw	a4,540(s1)
    80004c46:	2007879b          	addiw	a5,a5,512
    80004c4a:	fcf704e3          	beq	a4,a5,80004c12 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c4e:	4685                	li	a3,1
    80004c50:	01590633          	add	a2,s2,s5
    80004c54:	faf40593          	addi	a1,s0,-81
    80004c58:	0509b503          	ld	a0,80(s3)
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	a98080e7          	jalr	-1384(ra) # 800016f4 <copyin>
    80004c64:	03650263          	beq	a0,s6,80004c88 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c68:	21c4a783          	lw	a5,540(s1)
    80004c6c:	0017871b          	addiw	a4,a5,1
    80004c70:	20e4ae23          	sw	a4,540(s1)
    80004c74:	1ff7f793          	andi	a5,a5,511
    80004c78:	97a6                	add	a5,a5,s1
    80004c7a:	faf44703          	lbu	a4,-81(s0)
    80004c7e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c82:	2905                	addiw	s2,s2,1
    80004c84:	b755                	j	80004c28 <pipewrite+0x80>
  int i = 0;
    80004c86:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c88:	21848513          	addi	a0,s1,536
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	440080e7          	jalr	1088(ra) # 800020cc <wakeup>
  release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	ff4080e7          	jalr	-12(ra) # 80000c8a <release>
  return i;
    80004c9e:	bfa9                	j	80004bf8 <pipewrite+0x50>

0000000080004ca0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ca0:	715d                	addi	sp,sp,-80
    80004ca2:	e486                	sd	ra,72(sp)
    80004ca4:	e0a2                	sd	s0,64(sp)
    80004ca6:	fc26                	sd	s1,56(sp)
    80004ca8:	f84a                	sd	s2,48(sp)
    80004caa:	f44e                	sd	s3,40(sp)
    80004cac:	f052                	sd	s4,32(sp)
    80004cae:	ec56                	sd	s5,24(sp)
    80004cb0:	e85a                	sd	s6,16(sp)
    80004cb2:	0880                	addi	s0,sp,80
    80004cb4:	84aa                	mv	s1,a0
    80004cb6:	892e                	mv	s2,a1
    80004cb8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	cf2080e7          	jalr	-782(ra) # 800019ac <myproc>
    80004cc2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	f10080e7          	jalr	-240(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cce:	2184a703          	lw	a4,536(s1)
    80004cd2:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cd6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cda:	02f71763          	bne	a4,a5,80004d08 <piperead+0x68>
    80004cde:	2244a783          	lw	a5,548(s1)
    80004ce2:	c39d                	beqz	a5,80004d08 <piperead+0x68>
    if(killed(pr)){
    80004ce4:	8552                	mv	a0,s4
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	636080e7          	jalr	1590(ra) # 8000231c <killed>
    80004cee:	e941                	bnez	a0,80004d7e <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf0:	85a6                	mv	a1,s1
    80004cf2:	854e                	mv	a0,s3
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	374080e7          	jalr	884(ra) # 80002068 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfc:	2184a703          	lw	a4,536(s1)
    80004d00:	21c4a783          	lw	a5,540(s1)
    80004d04:	fcf70de3          	beq	a4,a5,80004cde <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d08:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d0a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d0c:	05505363          	blez	s5,80004d52 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004d10:	2184a783          	lw	a5,536(s1)
    80004d14:	21c4a703          	lw	a4,540(s1)
    80004d18:	02f70d63          	beq	a4,a5,80004d52 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d1c:	0017871b          	addiw	a4,a5,1
    80004d20:	20e4ac23          	sw	a4,536(s1)
    80004d24:	1ff7f793          	andi	a5,a5,511
    80004d28:	97a6                	add	a5,a5,s1
    80004d2a:	0187c783          	lbu	a5,24(a5)
    80004d2e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d32:	4685                	li	a3,1
    80004d34:	fbf40613          	addi	a2,s0,-65
    80004d38:	85ca                	mv	a1,s2
    80004d3a:	050a3503          	ld	a0,80(s4)
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	92a080e7          	jalr	-1750(ra) # 80001668 <copyout>
    80004d46:	01650663          	beq	a0,s6,80004d52 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d4a:	2985                	addiw	s3,s3,1
    80004d4c:	0905                	addi	s2,s2,1
    80004d4e:	fd3a91e3          	bne	s5,s3,80004d10 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d52:	21c48513          	addi	a0,s1,540
    80004d56:	ffffd097          	auipc	ra,0xffffd
    80004d5a:	376080e7          	jalr	886(ra) # 800020cc <wakeup>
  release(&pi->lock);
    80004d5e:	8526                	mv	a0,s1
    80004d60:	ffffc097          	auipc	ra,0xffffc
    80004d64:	f2a080e7          	jalr	-214(ra) # 80000c8a <release>
  return i;
}
    80004d68:	854e                	mv	a0,s3
    80004d6a:	60a6                	ld	ra,72(sp)
    80004d6c:	6406                	ld	s0,64(sp)
    80004d6e:	74e2                	ld	s1,56(sp)
    80004d70:	7942                	ld	s2,48(sp)
    80004d72:	79a2                	ld	s3,40(sp)
    80004d74:	7a02                	ld	s4,32(sp)
    80004d76:	6ae2                	ld	s5,24(sp)
    80004d78:	6b42                	ld	s6,16(sp)
    80004d7a:	6161                	addi	sp,sp,80
    80004d7c:	8082                	ret
      release(&pi->lock);
    80004d7e:	8526                	mv	a0,s1
    80004d80:	ffffc097          	auipc	ra,0xffffc
    80004d84:	f0a080e7          	jalr	-246(ra) # 80000c8a <release>
      return -1;
    80004d88:	59fd                	li	s3,-1
    80004d8a:	bff9                	j	80004d68 <piperead+0xc8>

0000000080004d8c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d8c:	1141                	addi	sp,sp,-16
    80004d8e:	e422                	sd	s0,8(sp)
    80004d90:	0800                	addi	s0,sp,16
    80004d92:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d94:	8905                	andi	a0,a0,1
    80004d96:	c111                	beqz	a0,80004d9a <flags2perm+0xe>
      perm = PTE_X;
    80004d98:	4521                	li	a0,8
    if(flags & 0x2)
    80004d9a:	8b89                	andi	a5,a5,2
    80004d9c:	c399                	beqz	a5,80004da2 <flags2perm+0x16>
      perm |= PTE_W;
    80004d9e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004da2:	6422                	ld	s0,8(sp)
    80004da4:	0141                	addi	sp,sp,16
    80004da6:	8082                	ret

0000000080004da8 <exec>:

int
exec(char *path, char **argv)
{
    80004da8:	de010113          	addi	sp,sp,-544
    80004dac:	20113c23          	sd	ra,536(sp)
    80004db0:	20813823          	sd	s0,528(sp)
    80004db4:	20913423          	sd	s1,520(sp)
    80004db8:	21213023          	sd	s2,512(sp)
    80004dbc:	ffce                	sd	s3,504(sp)
    80004dbe:	fbd2                	sd	s4,496(sp)
    80004dc0:	f7d6                	sd	s5,488(sp)
    80004dc2:	f3da                	sd	s6,480(sp)
    80004dc4:	efde                	sd	s7,472(sp)
    80004dc6:	ebe2                	sd	s8,464(sp)
    80004dc8:	e7e6                	sd	s9,456(sp)
    80004dca:	e3ea                	sd	s10,448(sp)
    80004dcc:	ff6e                	sd	s11,440(sp)
    80004dce:	1400                	addi	s0,sp,544
    80004dd0:	892a                	mv	s2,a0
    80004dd2:	dea43423          	sd	a0,-536(s0)
    80004dd6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	bd2080e7          	jalr	-1070(ra) # 800019ac <myproc>
    80004de2:	84aa                	mv	s1,a0

  begin_op();
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	47e080e7          	jalr	1150(ra) # 80004262 <begin_op>

  if((ip = namei(path)) == 0){
    80004dec:	854a                	mv	a0,s2
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	258080e7          	jalr	600(ra) # 80004046 <namei>
    80004df6:	c93d                	beqz	a0,80004e6c <exec+0xc4>
    80004df8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	aa6080e7          	jalr	-1370(ra) # 800038a0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e02:	04000713          	li	a4,64
    80004e06:	4681                	li	a3,0
    80004e08:	e5040613          	addi	a2,s0,-432
    80004e0c:	4581                	li	a1,0
    80004e0e:	8556                	mv	a0,s5
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	d44080e7          	jalr	-700(ra) # 80003b54 <readi>
    80004e18:	04000793          	li	a5,64
    80004e1c:	00f51a63          	bne	a0,a5,80004e30 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e20:	e5042703          	lw	a4,-432(s0)
    80004e24:	464c47b7          	lui	a5,0x464c4
    80004e28:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e2c:	04f70663          	beq	a4,a5,80004e78 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e30:	8556                	mv	a0,s5
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	cd0080e7          	jalr	-816(ra) # 80003b02 <iunlockput>
    end_op();
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	4a8080e7          	jalr	1192(ra) # 800042e2 <end_op>
  }
  return -1;
    80004e42:	557d                	li	a0,-1
}
    80004e44:	21813083          	ld	ra,536(sp)
    80004e48:	21013403          	ld	s0,528(sp)
    80004e4c:	20813483          	ld	s1,520(sp)
    80004e50:	20013903          	ld	s2,512(sp)
    80004e54:	79fe                	ld	s3,504(sp)
    80004e56:	7a5e                	ld	s4,496(sp)
    80004e58:	7abe                	ld	s5,488(sp)
    80004e5a:	7b1e                	ld	s6,480(sp)
    80004e5c:	6bfe                	ld	s7,472(sp)
    80004e5e:	6c5e                	ld	s8,464(sp)
    80004e60:	6cbe                	ld	s9,456(sp)
    80004e62:	6d1e                	ld	s10,448(sp)
    80004e64:	7dfa                	ld	s11,440(sp)
    80004e66:	22010113          	addi	sp,sp,544
    80004e6a:	8082                	ret
    end_op();
    80004e6c:	fffff097          	auipc	ra,0xfffff
    80004e70:	476080e7          	jalr	1142(ra) # 800042e2 <end_op>
    return -1;
    80004e74:	557d                	li	a0,-1
    80004e76:	b7f9                	j	80004e44 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e78:	8526                	mv	a0,s1
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	bf6080e7          	jalr	-1034(ra) # 80001a70 <proc_pagetable>
    80004e82:	8b2a                	mv	s6,a0
    80004e84:	d555                	beqz	a0,80004e30 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e86:	e7042783          	lw	a5,-400(s0)
    80004e8a:	e8845703          	lhu	a4,-376(s0)
    80004e8e:	c735                	beqz	a4,80004efa <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e90:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e92:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e96:	6a05                	lui	s4,0x1
    80004e98:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e9c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004ea0:	6d85                	lui	s11,0x1
    80004ea2:	7d7d                	lui	s10,0xfffff
    80004ea4:	a481                	j	800050e4 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ea6:	00004517          	auipc	a0,0x4
    80004eaa:	83a50513          	addi	a0,a0,-1990 # 800086e0 <syscalls+0x290>
    80004eae:	ffffb097          	auipc	ra,0xffffb
    80004eb2:	690080e7          	jalr	1680(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eb6:	874a                	mv	a4,s2
    80004eb8:	009c86bb          	addw	a3,s9,s1
    80004ebc:	4581                	li	a1,0
    80004ebe:	8556                	mv	a0,s5
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	c94080e7          	jalr	-876(ra) # 80003b54 <readi>
    80004ec8:	2501                	sext.w	a0,a0
    80004eca:	1aa91a63          	bne	s2,a0,8000507e <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004ece:	009d84bb          	addw	s1,s11,s1
    80004ed2:	013d09bb          	addw	s3,s10,s3
    80004ed6:	1f74f763          	bgeu	s1,s7,800050c4 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004eda:	02049593          	slli	a1,s1,0x20
    80004ede:	9181                	srli	a1,a1,0x20
    80004ee0:	95e2                	add	a1,a1,s8
    80004ee2:	855a                	mv	a0,s6
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	178080e7          	jalr	376(ra) # 8000105c <walkaddr>
    80004eec:	862a                	mv	a2,a0
    if(pa == 0)
    80004eee:	dd45                	beqz	a0,80004ea6 <exec+0xfe>
      n = PGSIZE;
    80004ef0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ef2:	fd49f2e3          	bgeu	s3,s4,80004eb6 <exec+0x10e>
      n = sz - i;
    80004ef6:	894e                	mv	s2,s3
    80004ef8:	bf7d                	j	80004eb6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004efa:	4901                	li	s2,0
  iunlockput(ip);
    80004efc:	8556                	mv	a0,s5
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	c04080e7          	jalr	-1020(ra) # 80003b02 <iunlockput>
  end_op();
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	3dc080e7          	jalr	988(ra) # 800042e2 <end_op>
  p = myproc();
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	a9e080e7          	jalr	-1378(ra) # 800019ac <myproc>
    80004f16:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f18:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f1c:	6785                	lui	a5,0x1
    80004f1e:	17fd                	addi	a5,a5,-1
    80004f20:	993e                	add	s2,s2,a5
    80004f22:	77fd                	lui	a5,0xfffff
    80004f24:	00f977b3          	and	a5,s2,a5
    80004f28:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f2c:	4691                	li	a3,4
    80004f2e:	6609                	lui	a2,0x2
    80004f30:	963e                	add	a2,a2,a5
    80004f32:	85be                	mv	a1,a5
    80004f34:	855a                	mv	a0,s6
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	4da080e7          	jalr	1242(ra) # 80001410 <uvmalloc>
    80004f3e:	8c2a                	mv	s8,a0
  ip = 0;
    80004f40:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f42:	12050e63          	beqz	a0,8000507e <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f46:	75f9                	lui	a1,0xffffe
    80004f48:	95aa                	add	a1,a1,a0
    80004f4a:	855a                	mv	a0,s6
    80004f4c:	ffffc097          	auipc	ra,0xffffc
    80004f50:	6ea080e7          	jalr	1770(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f54:	7afd                	lui	s5,0xfffff
    80004f56:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f58:	df043783          	ld	a5,-528(s0)
    80004f5c:	6388                	ld	a0,0(a5)
    80004f5e:	c925                	beqz	a0,80004fce <exec+0x226>
    80004f60:	e9040993          	addi	s3,s0,-368
    80004f64:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f68:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f6a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	ee2080e7          	jalr	-286(ra) # 80000e4e <strlen>
    80004f74:	0015079b          	addiw	a5,a0,1
    80004f78:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f7c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f80:	13596663          	bltu	s2,s5,800050ac <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f84:	df043d83          	ld	s11,-528(s0)
    80004f88:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f8c:	8552                	mv	a0,s4
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	ec0080e7          	jalr	-320(ra) # 80000e4e <strlen>
    80004f96:	0015069b          	addiw	a3,a0,1
    80004f9a:	8652                	mv	a2,s4
    80004f9c:	85ca                	mv	a1,s2
    80004f9e:	855a                	mv	a0,s6
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	6c8080e7          	jalr	1736(ra) # 80001668 <copyout>
    80004fa8:	10054663          	bltz	a0,800050b4 <exec+0x30c>
    ustack[argc] = sp;
    80004fac:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fb0:	0485                	addi	s1,s1,1
    80004fb2:	008d8793          	addi	a5,s11,8
    80004fb6:	def43823          	sd	a5,-528(s0)
    80004fba:	008db503          	ld	a0,8(s11)
    80004fbe:	c911                	beqz	a0,80004fd2 <exec+0x22a>
    if(argc >= MAXARG)
    80004fc0:	09a1                	addi	s3,s3,8
    80004fc2:	fb3c95e3          	bne	s9,s3,80004f6c <exec+0x1c4>
  sz = sz1;
    80004fc6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fca:	4a81                	li	s5,0
    80004fcc:	a84d                	j	8000507e <exec+0x2d6>
  sp = sz;
    80004fce:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fd0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fd2:	00349793          	slli	a5,s1,0x3
    80004fd6:	f9040713          	addi	a4,s0,-112
    80004fda:	97ba                	add	a5,a5,a4
    80004fdc:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdcda0>
  sp -= (argc+1) * sizeof(uint64);
    80004fe0:	00148693          	addi	a3,s1,1
    80004fe4:	068e                	slli	a3,a3,0x3
    80004fe6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fea:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fee:	01597663          	bgeu	s2,s5,80004ffa <exec+0x252>
  sz = sz1;
    80004ff2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ff6:	4a81                	li	s5,0
    80004ff8:	a059                	j	8000507e <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ffa:	e9040613          	addi	a2,s0,-368
    80004ffe:	85ca                	mv	a1,s2
    80005000:	855a                	mv	a0,s6
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	666080e7          	jalr	1638(ra) # 80001668 <copyout>
    8000500a:	0a054963          	bltz	a0,800050bc <exec+0x314>
  p->trapframe->a1 = sp;
    8000500e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005012:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005016:	de843783          	ld	a5,-536(s0)
    8000501a:	0007c703          	lbu	a4,0(a5)
    8000501e:	cf11                	beqz	a4,8000503a <exec+0x292>
    80005020:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005022:	02f00693          	li	a3,47
    80005026:	a039                	j	80005034 <exec+0x28c>
      last = s+1;
    80005028:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000502c:	0785                	addi	a5,a5,1
    8000502e:	fff7c703          	lbu	a4,-1(a5)
    80005032:	c701                	beqz	a4,8000503a <exec+0x292>
    if(*s == '/')
    80005034:	fed71ce3          	bne	a4,a3,8000502c <exec+0x284>
    80005038:	bfc5                	j	80005028 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000503a:	4641                	li	a2,16
    8000503c:	de843583          	ld	a1,-536(s0)
    80005040:	158b8513          	addi	a0,s7,344
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	dd8080e7          	jalr	-552(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000504c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005050:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005054:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005058:	058bb783          	ld	a5,88(s7)
    8000505c:	e6843703          	ld	a4,-408(s0)
    80005060:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005062:	058bb783          	ld	a5,88(s7)
    80005066:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000506a:	85ea                	mv	a1,s10
    8000506c:	ffffd097          	auipc	ra,0xffffd
    80005070:	aa0080e7          	jalr	-1376(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005074:	0004851b          	sext.w	a0,s1
    80005078:	b3f1                	j	80004e44 <exec+0x9c>
    8000507a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000507e:	df843583          	ld	a1,-520(s0)
    80005082:	855a                	mv	a0,s6
    80005084:	ffffd097          	auipc	ra,0xffffd
    80005088:	a88080e7          	jalr	-1400(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000508c:	da0a92e3          	bnez	s5,80004e30 <exec+0x88>
  return -1;
    80005090:	557d                	li	a0,-1
    80005092:	bb4d                	j	80004e44 <exec+0x9c>
    80005094:	df243c23          	sd	s2,-520(s0)
    80005098:	b7dd                	j	8000507e <exec+0x2d6>
    8000509a:	df243c23          	sd	s2,-520(s0)
    8000509e:	b7c5                	j	8000507e <exec+0x2d6>
    800050a0:	df243c23          	sd	s2,-520(s0)
    800050a4:	bfe9                	j	8000507e <exec+0x2d6>
    800050a6:	df243c23          	sd	s2,-520(s0)
    800050aa:	bfd1                	j	8000507e <exec+0x2d6>
  sz = sz1;
    800050ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b0:	4a81                	li	s5,0
    800050b2:	b7f1                	j	8000507e <exec+0x2d6>
  sz = sz1;
    800050b4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b8:	4a81                	li	s5,0
    800050ba:	b7d1                	j	8000507e <exec+0x2d6>
  sz = sz1;
    800050bc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c0:	4a81                	li	s5,0
    800050c2:	bf75                	j	8000507e <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050c4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c8:	e0843783          	ld	a5,-504(s0)
    800050cc:	0017869b          	addiw	a3,a5,1
    800050d0:	e0d43423          	sd	a3,-504(s0)
    800050d4:	e0043783          	ld	a5,-512(s0)
    800050d8:	0387879b          	addiw	a5,a5,56
    800050dc:	e8845703          	lhu	a4,-376(s0)
    800050e0:	e0e6dee3          	bge	a3,a4,80004efc <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050e4:	2781                	sext.w	a5,a5
    800050e6:	e0f43023          	sd	a5,-512(s0)
    800050ea:	03800713          	li	a4,56
    800050ee:	86be                	mv	a3,a5
    800050f0:	e1840613          	addi	a2,s0,-488
    800050f4:	4581                	li	a1,0
    800050f6:	8556                	mv	a0,s5
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	a5c080e7          	jalr	-1444(ra) # 80003b54 <readi>
    80005100:	03800793          	li	a5,56
    80005104:	f6f51be3          	bne	a0,a5,8000507a <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005108:	e1842783          	lw	a5,-488(s0)
    8000510c:	4705                	li	a4,1
    8000510e:	fae79de3          	bne	a5,a4,800050c8 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005112:	e4043483          	ld	s1,-448(s0)
    80005116:	e3843783          	ld	a5,-456(s0)
    8000511a:	f6f4ede3          	bltu	s1,a5,80005094 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000511e:	e2843783          	ld	a5,-472(s0)
    80005122:	94be                	add	s1,s1,a5
    80005124:	f6f4ebe3          	bltu	s1,a5,8000509a <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005128:	de043703          	ld	a4,-544(s0)
    8000512c:	8ff9                	and	a5,a5,a4
    8000512e:	fbad                	bnez	a5,800050a0 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005130:	e1c42503          	lw	a0,-484(s0)
    80005134:	00000097          	auipc	ra,0x0
    80005138:	c58080e7          	jalr	-936(ra) # 80004d8c <flags2perm>
    8000513c:	86aa                	mv	a3,a0
    8000513e:	8626                	mv	a2,s1
    80005140:	85ca                	mv	a1,s2
    80005142:	855a                	mv	a0,s6
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	2cc080e7          	jalr	716(ra) # 80001410 <uvmalloc>
    8000514c:	dea43c23          	sd	a0,-520(s0)
    80005150:	d939                	beqz	a0,800050a6 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005152:	e2843c03          	ld	s8,-472(s0)
    80005156:	e2042c83          	lw	s9,-480(s0)
    8000515a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000515e:	f60b83e3          	beqz	s7,800050c4 <exec+0x31c>
    80005162:	89de                	mv	s3,s7
    80005164:	4481                	li	s1,0
    80005166:	bb95                	j	80004eda <exec+0x132>

0000000080005168 <argfd>:
int readcount=0;
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005168:	7179                	addi	sp,sp,-48
    8000516a:	f406                	sd	ra,40(sp)
    8000516c:	f022                	sd	s0,32(sp)
    8000516e:	ec26                	sd	s1,24(sp)
    80005170:	e84a                	sd	s2,16(sp)
    80005172:	1800                	addi	s0,sp,48
    80005174:	892e                	mv	s2,a1
    80005176:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005178:	fdc40593          	addi	a1,s0,-36
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	b1c080e7          	jalr	-1252(ra) # 80002c98 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005184:	fdc42703          	lw	a4,-36(s0)
    80005188:	47bd                	li	a5,15
    8000518a:	02e7eb63          	bltu	a5,a4,800051c0 <argfd+0x58>
    8000518e:	ffffd097          	auipc	ra,0xffffd
    80005192:	81e080e7          	jalr	-2018(ra) # 800019ac <myproc>
    80005196:	fdc42703          	lw	a4,-36(s0)
    8000519a:	01a70793          	addi	a5,a4,26
    8000519e:	078e                	slli	a5,a5,0x3
    800051a0:	953e                	add	a0,a0,a5
    800051a2:	611c                	ld	a5,0(a0)
    800051a4:	c385                	beqz	a5,800051c4 <argfd+0x5c>
    return -1;
  if(pfd)
    800051a6:	00090463          	beqz	s2,800051ae <argfd+0x46>
    *pfd = fd;
    800051aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051ae:	4501                	li	a0,0
  if(pf)
    800051b0:	c091                	beqz	s1,800051b4 <argfd+0x4c>
    *pf = f;
    800051b2:	e09c                	sd	a5,0(s1)
}
    800051b4:	70a2                	ld	ra,40(sp)
    800051b6:	7402                	ld	s0,32(sp)
    800051b8:	64e2                	ld	s1,24(sp)
    800051ba:	6942                	ld	s2,16(sp)
    800051bc:	6145                	addi	sp,sp,48
    800051be:	8082                	ret
    return -1;
    800051c0:	557d                	li	a0,-1
    800051c2:	bfcd                	j	800051b4 <argfd+0x4c>
    800051c4:	557d                	li	a0,-1
    800051c6:	b7fd                	j	800051b4 <argfd+0x4c>

00000000800051c8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c8:	1101                	addi	sp,sp,-32
    800051ca:	ec06                	sd	ra,24(sp)
    800051cc:	e822                	sd	s0,16(sp)
    800051ce:	e426                	sd	s1,8(sp)
    800051d0:	1000                	addi	s0,sp,32
    800051d2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	7d8080e7          	jalr	2008(ra) # 800019ac <myproc>
    800051dc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051de:	0d050793          	addi	a5,a0,208
    800051e2:	4501                	li	a0,0
    800051e4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051e6:	6398                	ld	a4,0(a5)
    800051e8:	cb19                	beqz	a4,800051fe <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051ea:	2505                	addiw	a0,a0,1
    800051ec:	07a1                	addi	a5,a5,8
    800051ee:	fed51ce3          	bne	a0,a3,800051e6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051f2:	557d                	li	a0,-1
}
    800051f4:	60e2                	ld	ra,24(sp)
    800051f6:	6442                	ld	s0,16(sp)
    800051f8:	64a2                	ld	s1,8(sp)
    800051fa:	6105                	addi	sp,sp,32
    800051fc:	8082                	ret
      p->ofile[fd] = f;
    800051fe:	01a50793          	addi	a5,a0,26
    80005202:	078e                	slli	a5,a5,0x3
    80005204:	963e                	add	a2,a2,a5
    80005206:	e204                	sd	s1,0(a2)
      return fd;
    80005208:	b7f5                	j	800051f4 <fdalloc+0x2c>

000000008000520a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000520a:	715d                	addi	sp,sp,-80
    8000520c:	e486                	sd	ra,72(sp)
    8000520e:	e0a2                	sd	s0,64(sp)
    80005210:	fc26                	sd	s1,56(sp)
    80005212:	f84a                	sd	s2,48(sp)
    80005214:	f44e                	sd	s3,40(sp)
    80005216:	f052                	sd	s4,32(sp)
    80005218:	ec56                	sd	s5,24(sp)
    8000521a:	e85a                	sd	s6,16(sp)
    8000521c:	0880                	addi	s0,sp,80
    8000521e:	8b2e                	mv	s6,a1
    80005220:	89b2                	mv	s3,a2
    80005222:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005224:	fb040593          	addi	a1,s0,-80
    80005228:	fffff097          	auipc	ra,0xfffff
    8000522c:	e3c080e7          	jalr	-452(ra) # 80004064 <nameiparent>
    80005230:	84aa                	mv	s1,a0
    80005232:	14050f63          	beqz	a0,80005390 <create+0x186>
    return 0;

  ilock(dp);
    80005236:	ffffe097          	auipc	ra,0xffffe
    8000523a:	66a080e7          	jalr	1642(ra) # 800038a0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000523e:	4601                	li	a2,0
    80005240:	fb040593          	addi	a1,s0,-80
    80005244:	8526                	mv	a0,s1
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	b3e080e7          	jalr	-1218(ra) # 80003d84 <dirlookup>
    8000524e:	8aaa                	mv	s5,a0
    80005250:	c931                	beqz	a0,800052a4 <create+0x9a>
    iunlockput(dp);
    80005252:	8526                	mv	a0,s1
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	8ae080e7          	jalr	-1874(ra) # 80003b02 <iunlockput>
    ilock(ip);
    8000525c:	8556                	mv	a0,s5
    8000525e:	ffffe097          	auipc	ra,0xffffe
    80005262:	642080e7          	jalr	1602(ra) # 800038a0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005266:	000b059b          	sext.w	a1,s6
    8000526a:	4789                	li	a5,2
    8000526c:	02f59563          	bne	a1,a5,80005296 <create+0x8c>
    80005270:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcee4>
    80005274:	37f9                	addiw	a5,a5,-2
    80005276:	17c2                	slli	a5,a5,0x30
    80005278:	93c1                	srli	a5,a5,0x30
    8000527a:	4705                	li	a4,1
    8000527c:	00f76d63          	bltu	a4,a5,80005296 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005280:	8556                	mv	a0,s5
    80005282:	60a6                	ld	ra,72(sp)
    80005284:	6406                	ld	s0,64(sp)
    80005286:	74e2                	ld	s1,56(sp)
    80005288:	7942                	ld	s2,48(sp)
    8000528a:	79a2                	ld	s3,40(sp)
    8000528c:	7a02                	ld	s4,32(sp)
    8000528e:	6ae2                	ld	s5,24(sp)
    80005290:	6b42                	ld	s6,16(sp)
    80005292:	6161                	addi	sp,sp,80
    80005294:	8082                	ret
    iunlockput(ip);
    80005296:	8556                	mv	a0,s5
    80005298:	fffff097          	auipc	ra,0xfffff
    8000529c:	86a080e7          	jalr	-1942(ra) # 80003b02 <iunlockput>
    return 0;
    800052a0:	4a81                	li	s5,0
    800052a2:	bff9                	j	80005280 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052a4:	85da                	mv	a1,s6
    800052a6:	4088                	lw	a0,0(s1)
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	45c080e7          	jalr	1116(ra) # 80003704 <ialloc>
    800052b0:	8a2a                	mv	s4,a0
    800052b2:	c539                	beqz	a0,80005300 <create+0xf6>
  ilock(ip);
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	5ec080e7          	jalr	1516(ra) # 800038a0 <ilock>
  ip->major = major;
    800052bc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052c0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052c4:	4905                	li	s2,1
    800052c6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800052ca:	8552                	mv	a0,s4
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	50a080e7          	jalr	1290(ra) # 800037d6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052d4:	000b059b          	sext.w	a1,s6
    800052d8:	03258b63          	beq	a1,s2,8000530e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800052dc:	004a2603          	lw	a2,4(s4)
    800052e0:	fb040593          	addi	a1,s0,-80
    800052e4:	8526                	mv	a0,s1
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	cae080e7          	jalr	-850(ra) # 80003f94 <dirlink>
    800052ee:	06054f63          	bltz	a0,8000536c <create+0x162>
  iunlockput(dp);
    800052f2:	8526                	mv	a0,s1
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	80e080e7          	jalr	-2034(ra) # 80003b02 <iunlockput>
  return ip;
    800052fc:	8ad2                	mv	s5,s4
    800052fe:	b749                	j	80005280 <create+0x76>
    iunlockput(dp);
    80005300:	8526                	mv	a0,s1
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	800080e7          	jalr	-2048(ra) # 80003b02 <iunlockput>
    return 0;
    8000530a:	8ad2                	mv	s5,s4
    8000530c:	bf95                	j	80005280 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000530e:	004a2603          	lw	a2,4(s4)
    80005312:	00003597          	auipc	a1,0x3
    80005316:	3ee58593          	addi	a1,a1,1006 # 80008700 <syscalls+0x2b0>
    8000531a:	8552                	mv	a0,s4
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	c78080e7          	jalr	-904(ra) # 80003f94 <dirlink>
    80005324:	04054463          	bltz	a0,8000536c <create+0x162>
    80005328:	40d0                	lw	a2,4(s1)
    8000532a:	00003597          	auipc	a1,0x3
    8000532e:	3de58593          	addi	a1,a1,990 # 80008708 <syscalls+0x2b8>
    80005332:	8552                	mv	a0,s4
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	c60080e7          	jalr	-928(ra) # 80003f94 <dirlink>
    8000533c:	02054863          	bltz	a0,8000536c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005340:	004a2603          	lw	a2,4(s4)
    80005344:	fb040593          	addi	a1,s0,-80
    80005348:	8526                	mv	a0,s1
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	c4a080e7          	jalr	-950(ra) # 80003f94 <dirlink>
    80005352:	00054d63          	bltz	a0,8000536c <create+0x162>
    dp->nlink++;  // for ".."
    80005356:	04a4d783          	lhu	a5,74(s1)
    8000535a:	2785                	addiw	a5,a5,1
    8000535c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005360:	8526                	mv	a0,s1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	474080e7          	jalr	1140(ra) # 800037d6 <iupdate>
    8000536a:	b761                	j	800052f2 <create+0xe8>
  ip->nlink = 0;
    8000536c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005370:	8552                	mv	a0,s4
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	464080e7          	jalr	1124(ra) # 800037d6 <iupdate>
  iunlockput(ip);
    8000537a:	8552                	mv	a0,s4
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	786080e7          	jalr	1926(ra) # 80003b02 <iunlockput>
  iunlockput(dp);
    80005384:	8526                	mv	a0,s1
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	77c080e7          	jalr	1916(ra) # 80003b02 <iunlockput>
  return 0;
    8000538e:	bdcd                	j	80005280 <create+0x76>
    return 0;
    80005390:	8aaa                	mv	s5,a0
    80005392:	b5fd                	j	80005280 <create+0x76>

0000000080005394 <sys_dup>:
{
    80005394:	7179                	addi	sp,sp,-48
    80005396:	f406                	sd	ra,40(sp)
    80005398:	f022                	sd	s0,32(sp)
    8000539a:	ec26                	sd	s1,24(sp)
    8000539c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000539e:	fd840613          	addi	a2,s0,-40
    800053a2:	4581                	li	a1,0
    800053a4:	4501                	li	a0,0
    800053a6:	00000097          	auipc	ra,0x0
    800053aa:	dc2080e7          	jalr	-574(ra) # 80005168 <argfd>
    return -1;
    800053ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053b0:	02054363          	bltz	a0,800053d6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053b4:	fd843503          	ld	a0,-40(s0)
    800053b8:	00000097          	auipc	ra,0x0
    800053bc:	e10080e7          	jalr	-496(ra) # 800051c8 <fdalloc>
    800053c0:	84aa                	mv	s1,a0
    return -1;
    800053c2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053c4:	00054963          	bltz	a0,800053d6 <sys_dup+0x42>
  filedup(f);
    800053c8:	fd843503          	ld	a0,-40(s0)
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	310080e7          	jalr	784(ra) # 800046dc <filedup>
  return fd;
    800053d4:	87a6                	mv	a5,s1
}
    800053d6:	853e                	mv	a0,a5
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	64e2                	ld	s1,24(sp)
    800053de:	6145                	addi	sp,sp,48
    800053e0:	8082                	ret

00000000800053e2 <sys_read>:
{
    800053e2:	7179                	addi	sp,sp,-48
    800053e4:	f406                	sd	ra,40(sp)
    800053e6:	f022                	sd	s0,32(sp)
    800053e8:	1800                	addi	s0,sp,48
  printf("wth\n");
    800053ea:	00003517          	auipc	a0,0x3
    800053ee:	32650513          	addi	a0,a0,806 # 80008710 <syscalls+0x2c0>
    800053f2:	ffffb097          	auipc	ra,0xffffb
    800053f6:	196080e7          	jalr	406(ra) # 80000588 <printf>
  readcount++;
    800053fa:	00003717          	auipc	a4,0x3
    800053fe:	4ea70713          	addi	a4,a4,1258 # 800088e4 <readcount>
    80005402:	431c                	lw	a5,0(a4)
    80005404:	2785                	addiw	a5,a5,1
    80005406:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005408:	fd840593          	addi	a1,s0,-40
    8000540c:	4505                	li	a0,1
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	8aa080e7          	jalr	-1878(ra) # 80002cb8 <argaddr>
  argint(2, &n);
    80005416:	fe440593          	addi	a1,s0,-28
    8000541a:	4509                	li	a0,2
    8000541c:	ffffe097          	auipc	ra,0xffffe
    80005420:	87c080e7          	jalr	-1924(ra) # 80002c98 <argint>
  if(argfd(0, 0, &f) < 0)
    80005424:	fe840613          	addi	a2,s0,-24
    80005428:	4581                	li	a1,0
    8000542a:	4501                	li	a0,0
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	d3c080e7          	jalr	-708(ra) # 80005168 <argfd>
    80005434:	87aa                	mv	a5,a0
    return -1;
    80005436:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005438:	0007cc63          	bltz	a5,80005450 <sys_read+0x6e>
  return fileread(f, p, n);
    8000543c:	fe442603          	lw	a2,-28(s0)
    80005440:	fd843583          	ld	a1,-40(s0)
    80005444:	fe843503          	ld	a0,-24(s0)
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	420080e7          	jalr	1056(ra) # 80004868 <fileread>
}
    80005450:	70a2                	ld	ra,40(sp)
    80005452:	7402                	ld	s0,32(sp)
    80005454:	6145                	addi	sp,sp,48
    80005456:	8082                	ret

0000000080005458 <sys_write>:
{
    80005458:	7179                	addi	sp,sp,-48
    8000545a:	f406                	sd	ra,40(sp)
    8000545c:	f022                	sd	s0,32(sp)
    8000545e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005460:	fd840593          	addi	a1,s0,-40
    80005464:	4505                	li	a0,1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	852080e7          	jalr	-1966(ra) # 80002cb8 <argaddr>
  argint(2, &n);
    8000546e:	fe440593          	addi	a1,s0,-28
    80005472:	4509                	li	a0,2
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	824080e7          	jalr	-2012(ra) # 80002c98 <argint>
  if(argfd(0, 0, &f) < 0)
    8000547c:	fe840613          	addi	a2,s0,-24
    80005480:	4581                	li	a1,0
    80005482:	4501                	li	a0,0
    80005484:	00000097          	auipc	ra,0x0
    80005488:	ce4080e7          	jalr	-796(ra) # 80005168 <argfd>
    8000548c:	87aa                	mv	a5,a0
    return -1;
    8000548e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005490:	0007cc63          	bltz	a5,800054a8 <sys_write+0x50>
  return filewrite(f, p, n);
    80005494:	fe442603          	lw	a2,-28(s0)
    80005498:	fd843583          	ld	a1,-40(s0)
    8000549c:	fe843503          	ld	a0,-24(s0)
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	48a080e7          	jalr	1162(ra) # 8000492a <filewrite>
}
    800054a8:	70a2                	ld	ra,40(sp)
    800054aa:	7402                	ld	s0,32(sp)
    800054ac:	6145                	addi	sp,sp,48
    800054ae:	8082                	ret

00000000800054b0 <sys_close>:
{
    800054b0:	1101                	addi	sp,sp,-32
    800054b2:	ec06                	sd	ra,24(sp)
    800054b4:	e822                	sd	s0,16(sp)
    800054b6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054b8:	fe040613          	addi	a2,s0,-32
    800054bc:	fec40593          	addi	a1,s0,-20
    800054c0:	4501                	li	a0,0
    800054c2:	00000097          	auipc	ra,0x0
    800054c6:	ca6080e7          	jalr	-858(ra) # 80005168 <argfd>
    return -1;
    800054ca:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054cc:	02054463          	bltz	a0,800054f4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054d0:	ffffc097          	auipc	ra,0xffffc
    800054d4:	4dc080e7          	jalr	1244(ra) # 800019ac <myproc>
    800054d8:	fec42783          	lw	a5,-20(s0)
    800054dc:	07e9                	addi	a5,a5,26
    800054de:	078e                	slli	a5,a5,0x3
    800054e0:	97aa                	add	a5,a5,a0
    800054e2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054e6:	fe043503          	ld	a0,-32(s0)
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	244080e7          	jalr	580(ra) # 8000472e <fileclose>
  return 0;
    800054f2:	4781                	li	a5,0
}
    800054f4:	853e                	mv	a0,a5
    800054f6:	60e2                	ld	ra,24(sp)
    800054f8:	6442                	ld	s0,16(sp)
    800054fa:	6105                	addi	sp,sp,32
    800054fc:	8082                	ret

00000000800054fe <sys_fstat>:
{
    800054fe:	1101                	addi	sp,sp,-32
    80005500:	ec06                	sd	ra,24(sp)
    80005502:	e822                	sd	s0,16(sp)
    80005504:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005506:	fe040593          	addi	a1,s0,-32
    8000550a:	4505                	li	a0,1
    8000550c:	ffffd097          	auipc	ra,0xffffd
    80005510:	7ac080e7          	jalr	1964(ra) # 80002cb8 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005514:	fe840613          	addi	a2,s0,-24
    80005518:	4581                	li	a1,0
    8000551a:	4501                	li	a0,0
    8000551c:	00000097          	auipc	ra,0x0
    80005520:	c4c080e7          	jalr	-948(ra) # 80005168 <argfd>
    80005524:	87aa                	mv	a5,a0
    return -1;
    80005526:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005528:	0007ca63          	bltz	a5,8000553c <sys_fstat+0x3e>
  return filestat(f, st);
    8000552c:	fe043583          	ld	a1,-32(s0)
    80005530:	fe843503          	ld	a0,-24(s0)
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	2c2080e7          	jalr	706(ra) # 800047f6 <filestat>
}
    8000553c:	60e2                	ld	ra,24(sp)
    8000553e:	6442                	ld	s0,16(sp)
    80005540:	6105                	addi	sp,sp,32
    80005542:	8082                	ret

0000000080005544 <sys_link>:
{
    80005544:	7169                	addi	sp,sp,-304
    80005546:	f606                	sd	ra,296(sp)
    80005548:	f222                	sd	s0,288(sp)
    8000554a:	ee26                	sd	s1,280(sp)
    8000554c:	ea4a                	sd	s2,272(sp)
    8000554e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005550:	08000613          	li	a2,128
    80005554:	ed040593          	addi	a1,s0,-304
    80005558:	4501                	li	a0,0
    8000555a:	ffffd097          	auipc	ra,0xffffd
    8000555e:	77e080e7          	jalr	1918(ra) # 80002cd8 <argstr>
    return -1;
    80005562:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005564:	10054e63          	bltz	a0,80005680 <sys_link+0x13c>
    80005568:	08000613          	li	a2,128
    8000556c:	f5040593          	addi	a1,s0,-176
    80005570:	4505                	li	a0,1
    80005572:	ffffd097          	auipc	ra,0xffffd
    80005576:	766080e7          	jalr	1894(ra) # 80002cd8 <argstr>
    return -1;
    8000557a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000557c:	10054263          	bltz	a0,80005680 <sys_link+0x13c>
  begin_op();
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	ce2080e7          	jalr	-798(ra) # 80004262 <begin_op>
  if((ip = namei(old)) == 0){
    80005588:	ed040513          	addi	a0,s0,-304
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	aba080e7          	jalr	-1350(ra) # 80004046 <namei>
    80005594:	84aa                	mv	s1,a0
    80005596:	c551                	beqz	a0,80005622 <sys_link+0xde>
  ilock(ip);
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	308080e7          	jalr	776(ra) # 800038a0 <ilock>
  if(ip->type == T_DIR){
    800055a0:	04449703          	lh	a4,68(s1)
    800055a4:	4785                	li	a5,1
    800055a6:	08f70463          	beq	a4,a5,8000562e <sys_link+0xea>
  ip->nlink++;
    800055aa:	04a4d783          	lhu	a5,74(s1)
    800055ae:	2785                	addiw	a5,a5,1
    800055b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	220080e7          	jalr	544(ra) # 800037d6 <iupdate>
  iunlock(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	3a2080e7          	jalr	930(ra) # 80003962 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055c8:	fd040593          	addi	a1,s0,-48
    800055cc:	f5040513          	addi	a0,s0,-176
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	a94080e7          	jalr	-1388(ra) # 80004064 <nameiparent>
    800055d8:	892a                	mv	s2,a0
    800055da:	c935                	beqz	a0,8000564e <sys_link+0x10a>
  ilock(dp);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	2c4080e7          	jalr	708(ra) # 800038a0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055e4:	00092703          	lw	a4,0(s2)
    800055e8:	409c                	lw	a5,0(s1)
    800055ea:	04f71d63          	bne	a4,a5,80005644 <sys_link+0x100>
    800055ee:	40d0                	lw	a2,4(s1)
    800055f0:	fd040593          	addi	a1,s0,-48
    800055f4:	854a                	mv	a0,s2
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	99e080e7          	jalr	-1634(ra) # 80003f94 <dirlink>
    800055fe:	04054363          	bltz	a0,80005644 <sys_link+0x100>
  iunlockput(dp);
    80005602:	854a                	mv	a0,s2
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	4fe080e7          	jalr	1278(ra) # 80003b02 <iunlockput>
  iput(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	44c080e7          	jalr	1100(ra) # 80003a5a <iput>
  end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	ccc080e7          	jalr	-820(ra) # 800042e2 <end_op>
  return 0;
    8000561e:	4781                	li	a5,0
    80005620:	a085                	j	80005680 <sys_link+0x13c>
    end_op();
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	cc0080e7          	jalr	-832(ra) # 800042e2 <end_op>
    return -1;
    8000562a:	57fd                	li	a5,-1
    8000562c:	a891                	j	80005680 <sys_link+0x13c>
    iunlockput(ip);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	4d2080e7          	jalr	1234(ra) # 80003b02 <iunlockput>
    end_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	caa080e7          	jalr	-854(ra) # 800042e2 <end_op>
    return -1;
    80005640:	57fd                	li	a5,-1
    80005642:	a83d                	j	80005680 <sys_link+0x13c>
    iunlockput(dp);
    80005644:	854a                	mv	a0,s2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	4bc080e7          	jalr	1212(ra) # 80003b02 <iunlockput>
  ilock(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	250080e7          	jalr	592(ra) # 800038a0 <ilock>
  ip->nlink--;
    80005658:	04a4d783          	lhu	a5,74(s1)
    8000565c:	37fd                	addiw	a5,a5,-1
    8000565e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	172080e7          	jalr	370(ra) # 800037d6 <iupdate>
  iunlockput(ip);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	494080e7          	jalr	1172(ra) # 80003b02 <iunlockput>
  end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	c6c080e7          	jalr	-916(ra) # 800042e2 <end_op>
  return -1;
    8000567e:	57fd                	li	a5,-1
}
    80005680:	853e                	mv	a0,a5
    80005682:	70b2                	ld	ra,296(sp)
    80005684:	7412                	ld	s0,288(sp)
    80005686:	64f2                	ld	s1,280(sp)
    80005688:	6952                	ld	s2,272(sp)
    8000568a:	6155                	addi	sp,sp,304
    8000568c:	8082                	ret

000000008000568e <sys_unlink>:
{
    8000568e:	7151                	addi	sp,sp,-240
    80005690:	f586                	sd	ra,232(sp)
    80005692:	f1a2                	sd	s0,224(sp)
    80005694:	eda6                	sd	s1,216(sp)
    80005696:	e9ca                	sd	s2,208(sp)
    80005698:	e5ce                	sd	s3,200(sp)
    8000569a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000569c:	08000613          	li	a2,128
    800056a0:	f3040593          	addi	a1,s0,-208
    800056a4:	4501                	li	a0,0
    800056a6:	ffffd097          	auipc	ra,0xffffd
    800056aa:	632080e7          	jalr	1586(ra) # 80002cd8 <argstr>
    800056ae:	18054163          	bltz	a0,80005830 <sys_unlink+0x1a2>
  begin_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	bb0080e7          	jalr	-1104(ra) # 80004262 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ba:	fb040593          	addi	a1,s0,-80
    800056be:	f3040513          	addi	a0,s0,-208
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	9a2080e7          	jalr	-1630(ra) # 80004064 <nameiparent>
    800056ca:	84aa                	mv	s1,a0
    800056cc:	c979                	beqz	a0,800057a2 <sys_unlink+0x114>
  ilock(dp);
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	1d2080e7          	jalr	466(ra) # 800038a0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056d6:	00003597          	auipc	a1,0x3
    800056da:	02a58593          	addi	a1,a1,42 # 80008700 <syscalls+0x2b0>
    800056de:	fb040513          	addi	a0,s0,-80
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	688080e7          	jalr	1672(ra) # 80003d6a <namecmp>
    800056ea:	14050a63          	beqz	a0,8000583e <sys_unlink+0x1b0>
    800056ee:	00003597          	auipc	a1,0x3
    800056f2:	01a58593          	addi	a1,a1,26 # 80008708 <syscalls+0x2b8>
    800056f6:	fb040513          	addi	a0,s0,-80
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	670080e7          	jalr	1648(ra) # 80003d6a <namecmp>
    80005702:	12050e63          	beqz	a0,8000583e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005706:	f2c40613          	addi	a2,s0,-212
    8000570a:	fb040593          	addi	a1,s0,-80
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	674080e7          	jalr	1652(ra) # 80003d84 <dirlookup>
    80005718:	892a                	mv	s2,a0
    8000571a:	12050263          	beqz	a0,8000583e <sys_unlink+0x1b0>
  ilock(ip);
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	182080e7          	jalr	386(ra) # 800038a0 <ilock>
  if(ip->nlink < 1)
    80005726:	04a91783          	lh	a5,74(s2)
    8000572a:	08f05263          	blez	a5,800057ae <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000572e:	04491703          	lh	a4,68(s2)
    80005732:	4785                	li	a5,1
    80005734:	08f70563          	beq	a4,a5,800057be <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005738:	4641                	li	a2,16
    8000573a:	4581                	li	a1,0
    8000573c:	fc040513          	addi	a0,s0,-64
    80005740:	ffffb097          	auipc	ra,0xffffb
    80005744:	592080e7          	jalr	1426(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005748:	4741                	li	a4,16
    8000574a:	f2c42683          	lw	a3,-212(s0)
    8000574e:	fc040613          	addi	a2,s0,-64
    80005752:	4581                	li	a1,0
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	4f6080e7          	jalr	1270(ra) # 80003c4c <writei>
    8000575e:	47c1                	li	a5,16
    80005760:	0af51563          	bne	a0,a5,8000580a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005764:	04491703          	lh	a4,68(s2)
    80005768:	4785                	li	a5,1
    8000576a:	0af70863          	beq	a4,a5,8000581a <sys_unlink+0x18c>
  iunlockput(dp);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	392080e7          	jalr	914(ra) # 80003b02 <iunlockput>
  ip->nlink--;
    80005778:	04a95783          	lhu	a5,74(s2)
    8000577c:	37fd                	addiw	a5,a5,-1
    8000577e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005782:	854a                	mv	a0,s2
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	052080e7          	jalr	82(ra) # 800037d6 <iupdate>
  iunlockput(ip);
    8000578c:	854a                	mv	a0,s2
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	374080e7          	jalr	884(ra) # 80003b02 <iunlockput>
  end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	b4c080e7          	jalr	-1204(ra) # 800042e2 <end_op>
  return 0;
    8000579e:	4501                	li	a0,0
    800057a0:	a84d                	j	80005852 <sys_unlink+0x1c4>
    end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	b40080e7          	jalr	-1216(ra) # 800042e2 <end_op>
    return -1;
    800057aa:	557d                	li	a0,-1
    800057ac:	a05d                	j	80005852 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057ae:	00003517          	auipc	a0,0x3
    800057b2:	f6a50513          	addi	a0,a0,-150 # 80008718 <syscalls+0x2c8>
    800057b6:	ffffb097          	auipc	ra,0xffffb
    800057ba:	d88080e7          	jalr	-632(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057be:	04c92703          	lw	a4,76(s2)
    800057c2:	02000793          	li	a5,32
    800057c6:	f6e7f9e3          	bgeu	a5,a4,80005738 <sys_unlink+0xaa>
    800057ca:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ce:	4741                	li	a4,16
    800057d0:	86ce                	mv	a3,s3
    800057d2:	f1840613          	addi	a2,s0,-232
    800057d6:	4581                	li	a1,0
    800057d8:	854a                	mv	a0,s2
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	37a080e7          	jalr	890(ra) # 80003b54 <readi>
    800057e2:	47c1                	li	a5,16
    800057e4:	00f51b63          	bne	a0,a5,800057fa <sys_unlink+0x16c>
    if(de.inum != 0)
    800057e8:	f1845783          	lhu	a5,-232(s0)
    800057ec:	e7a1                	bnez	a5,80005834 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ee:	29c1                	addiw	s3,s3,16
    800057f0:	04c92783          	lw	a5,76(s2)
    800057f4:	fcf9ede3          	bltu	s3,a5,800057ce <sys_unlink+0x140>
    800057f8:	b781                	j	80005738 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057fa:	00003517          	auipc	a0,0x3
    800057fe:	f3650513          	addi	a0,a0,-202 # 80008730 <syscalls+0x2e0>
    80005802:	ffffb097          	auipc	ra,0xffffb
    80005806:	d3c080e7          	jalr	-708(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000580a:	00003517          	auipc	a0,0x3
    8000580e:	f3e50513          	addi	a0,a0,-194 # 80008748 <syscalls+0x2f8>
    80005812:	ffffb097          	auipc	ra,0xffffb
    80005816:	d2c080e7          	jalr	-724(ra) # 8000053e <panic>
    dp->nlink--;
    8000581a:	04a4d783          	lhu	a5,74(s1)
    8000581e:	37fd                	addiw	a5,a5,-1
    80005820:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	fb0080e7          	jalr	-80(ra) # 800037d6 <iupdate>
    8000582e:	b781                	j	8000576e <sys_unlink+0xe0>
    return -1;
    80005830:	557d                	li	a0,-1
    80005832:	a005                	j	80005852 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005834:	854a                	mv	a0,s2
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	2cc080e7          	jalr	716(ra) # 80003b02 <iunlockput>
  iunlockput(dp);
    8000583e:	8526                	mv	a0,s1
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	2c2080e7          	jalr	706(ra) # 80003b02 <iunlockput>
  end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	a9a080e7          	jalr	-1382(ra) # 800042e2 <end_op>
  return -1;
    80005850:	557d                	li	a0,-1
}
    80005852:	70ae                	ld	ra,232(sp)
    80005854:	740e                	ld	s0,224(sp)
    80005856:	64ee                	ld	s1,216(sp)
    80005858:	694e                	ld	s2,208(sp)
    8000585a:	69ae                	ld	s3,200(sp)
    8000585c:	616d                	addi	sp,sp,240
    8000585e:	8082                	ret

0000000080005860 <sys_open>:

uint64
sys_open(void)
{
    80005860:	7131                	addi	sp,sp,-192
    80005862:	fd06                	sd	ra,184(sp)
    80005864:	f922                	sd	s0,176(sp)
    80005866:	f526                	sd	s1,168(sp)
    80005868:	f14a                	sd	s2,160(sp)
    8000586a:	ed4e                	sd	s3,152(sp)
    8000586c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000586e:	f4c40593          	addi	a1,s0,-180
    80005872:	4505                	li	a0,1
    80005874:	ffffd097          	auipc	ra,0xffffd
    80005878:	424080e7          	jalr	1060(ra) # 80002c98 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000587c:	08000613          	li	a2,128
    80005880:	f5040593          	addi	a1,s0,-176
    80005884:	4501                	li	a0,0
    80005886:	ffffd097          	auipc	ra,0xffffd
    8000588a:	452080e7          	jalr	1106(ra) # 80002cd8 <argstr>
    8000588e:	87aa                	mv	a5,a0
    return -1;
    80005890:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005892:	0a07c963          	bltz	a5,80005944 <sys_open+0xe4>

  begin_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	9cc080e7          	jalr	-1588(ra) # 80004262 <begin_op>

  if(omode & O_CREATE){
    8000589e:	f4c42783          	lw	a5,-180(s0)
    800058a2:	2007f793          	andi	a5,a5,512
    800058a6:	cfc5                	beqz	a5,8000595e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058a8:	4681                	li	a3,0
    800058aa:	4601                	li	a2,0
    800058ac:	4589                	li	a1,2
    800058ae:	f5040513          	addi	a0,s0,-176
    800058b2:	00000097          	auipc	ra,0x0
    800058b6:	958080e7          	jalr	-1704(ra) # 8000520a <create>
    800058ba:	84aa                	mv	s1,a0
    if(ip == 0){
    800058bc:	c959                	beqz	a0,80005952 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058be:	04449703          	lh	a4,68(s1)
    800058c2:	478d                	li	a5,3
    800058c4:	00f71763          	bne	a4,a5,800058d2 <sys_open+0x72>
    800058c8:	0464d703          	lhu	a4,70(s1)
    800058cc:	47a5                	li	a5,9
    800058ce:	0ce7ed63          	bltu	a5,a4,800059a8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	da0080e7          	jalr	-608(ra) # 80004672 <filealloc>
    800058da:	89aa                	mv	s3,a0
    800058dc:	10050363          	beqz	a0,800059e2 <sys_open+0x182>
    800058e0:	00000097          	auipc	ra,0x0
    800058e4:	8e8080e7          	jalr	-1816(ra) # 800051c8 <fdalloc>
    800058e8:	892a                	mv	s2,a0
    800058ea:	0e054763          	bltz	a0,800059d8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058ee:	04449703          	lh	a4,68(s1)
    800058f2:	478d                	li	a5,3
    800058f4:	0cf70563          	beq	a4,a5,800059be <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058f8:	4789                	li	a5,2
    800058fa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058fe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005902:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005906:	f4c42783          	lw	a5,-180(s0)
    8000590a:	0017c713          	xori	a4,a5,1
    8000590e:	8b05                	andi	a4,a4,1
    80005910:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005914:	0037f713          	andi	a4,a5,3
    80005918:	00e03733          	snez	a4,a4
    8000591c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005920:	4007f793          	andi	a5,a5,1024
    80005924:	c791                	beqz	a5,80005930 <sys_open+0xd0>
    80005926:	04449703          	lh	a4,68(s1)
    8000592a:	4789                	li	a5,2
    8000592c:	0af70063          	beq	a4,a5,800059cc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005930:	8526                	mv	a0,s1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	030080e7          	jalr	48(ra) # 80003962 <iunlock>
  end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	9a8080e7          	jalr	-1624(ra) # 800042e2 <end_op>

  return fd;
    80005942:	854a                	mv	a0,s2
}
    80005944:	70ea                	ld	ra,184(sp)
    80005946:	744a                	ld	s0,176(sp)
    80005948:	74aa                	ld	s1,168(sp)
    8000594a:	790a                	ld	s2,160(sp)
    8000594c:	69ea                	ld	s3,152(sp)
    8000594e:	6129                	addi	sp,sp,192
    80005950:	8082                	ret
      end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	990080e7          	jalr	-1648(ra) # 800042e2 <end_op>
      return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	b7e5                	j	80005944 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000595e:	f5040513          	addi	a0,s0,-176
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	6e4080e7          	jalr	1764(ra) # 80004046 <namei>
    8000596a:	84aa                	mv	s1,a0
    8000596c:	c905                	beqz	a0,8000599c <sys_open+0x13c>
    ilock(ip);
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	f32080e7          	jalr	-206(ra) # 800038a0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005976:	04449703          	lh	a4,68(s1)
    8000597a:	4785                	li	a5,1
    8000597c:	f4f711e3          	bne	a4,a5,800058be <sys_open+0x5e>
    80005980:	f4c42783          	lw	a5,-180(s0)
    80005984:	d7b9                	beqz	a5,800058d2 <sys_open+0x72>
      iunlockput(ip);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	17a080e7          	jalr	378(ra) # 80003b02 <iunlockput>
      end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	952080e7          	jalr	-1710(ra) # 800042e2 <end_op>
      return -1;
    80005998:	557d                	li	a0,-1
    8000599a:	b76d                	j	80005944 <sys_open+0xe4>
      end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	946080e7          	jalr	-1722(ra) # 800042e2 <end_op>
      return -1;
    800059a4:	557d                	li	a0,-1
    800059a6:	bf79                	j	80005944 <sys_open+0xe4>
    iunlockput(ip);
    800059a8:	8526                	mv	a0,s1
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	158080e7          	jalr	344(ra) # 80003b02 <iunlockput>
    end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	930080e7          	jalr	-1744(ra) # 800042e2 <end_op>
    return -1;
    800059ba:	557d                	li	a0,-1
    800059bc:	b761                	j	80005944 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059be:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059c2:	04649783          	lh	a5,70(s1)
    800059c6:	02f99223          	sh	a5,36(s3)
    800059ca:	bf25                	j	80005902 <sys_open+0xa2>
    itrunc(ip);
    800059cc:	8526                	mv	a0,s1
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	fe0080e7          	jalr	-32(ra) # 800039ae <itrunc>
    800059d6:	bfa9                	j	80005930 <sys_open+0xd0>
      fileclose(f);
    800059d8:	854e                	mv	a0,s3
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	d54080e7          	jalr	-684(ra) # 8000472e <fileclose>
    iunlockput(ip);
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	11e080e7          	jalr	286(ra) # 80003b02 <iunlockput>
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	8f6080e7          	jalr	-1802(ra) # 800042e2 <end_op>
    return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	b7b9                	j	80005944 <sys_open+0xe4>

00000000800059f8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059f8:	7175                	addi	sp,sp,-144
    800059fa:	e506                	sd	ra,136(sp)
    800059fc:	e122                	sd	s0,128(sp)
    800059fe:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	862080e7          	jalr	-1950(ra) # 80004262 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a08:	08000613          	li	a2,128
    80005a0c:	f7040593          	addi	a1,s0,-144
    80005a10:	4501                	li	a0,0
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	2c6080e7          	jalr	710(ra) # 80002cd8 <argstr>
    80005a1a:	02054963          	bltz	a0,80005a4c <sys_mkdir+0x54>
    80005a1e:	4681                	li	a3,0
    80005a20:	4601                	li	a2,0
    80005a22:	4585                	li	a1,1
    80005a24:	f7040513          	addi	a0,s0,-144
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	7e2080e7          	jalr	2018(ra) # 8000520a <create>
    80005a30:	cd11                	beqz	a0,80005a4c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	0d0080e7          	jalr	208(ra) # 80003b02 <iunlockput>
  end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	8a8080e7          	jalr	-1880(ra) # 800042e2 <end_op>
  return 0;
    80005a42:	4501                	li	a0,0
}
    80005a44:	60aa                	ld	ra,136(sp)
    80005a46:	640a                	ld	s0,128(sp)
    80005a48:	6149                	addi	sp,sp,144
    80005a4a:	8082                	ret
    end_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	896080e7          	jalr	-1898(ra) # 800042e2 <end_op>
    return -1;
    80005a54:	557d                	li	a0,-1
    80005a56:	b7fd                	j	80005a44 <sys_mkdir+0x4c>

0000000080005a58 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a58:	7135                	addi	sp,sp,-160
    80005a5a:	ed06                	sd	ra,152(sp)
    80005a5c:	e922                	sd	s0,144(sp)
    80005a5e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	802080e7          	jalr	-2046(ra) # 80004262 <begin_op>
  argint(1, &major);
    80005a68:	f6c40593          	addi	a1,s0,-148
    80005a6c:	4505                	li	a0,1
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	22a080e7          	jalr	554(ra) # 80002c98 <argint>
  argint(2, &minor);
    80005a76:	f6840593          	addi	a1,s0,-152
    80005a7a:	4509                	li	a0,2
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	21c080e7          	jalr	540(ra) # 80002c98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a84:	08000613          	li	a2,128
    80005a88:	f7040593          	addi	a1,s0,-144
    80005a8c:	4501                	li	a0,0
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	24a080e7          	jalr	586(ra) # 80002cd8 <argstr>
    80005a96:	02054b63          	bltz	a0,80005acc <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a9a:	f6841683          	lh	a3,-152(s0)
    80005a9e:	f6c41603          	lh	a2,-148(s0)
    80005aa2:	458d                	li	a1,3
    80005aa4:	f7040513          	addi	a0,s0,-144
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	762080e7          	jalr	1890(ra) # 8000520a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ab0:	cd11                	beqz	a0,80005acc <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	050080e7          	jalr	80(ra) # 80003b02 <iunlockput>
  end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	828080e7          	jalr	-2008(ra) # 800042e2 <end_op>
  return 0;
    80005ac2:	4501                	li	a0,0
}
    80005ac4:	60ea                	ld	ra,152(sp)
    80005ac6:	644a                	ld	s0,144(sp)
    80005ac8:	610d                	addi	sp,sp,160
    80005aca:	8082                	ret
    end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	816080e7          	jalr	-2026(ra) # 800042e2 <end_op>
    return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	b7fd                	j	80005ac4 <sys_mknod+0x6c>

0000000080005ad8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ad8:	7135                	addi	sp,sp,-160
    80005ada:	ed06                	sd	ra,152(sp)
    80005adc:	e922                	sd	s0,144(sp)
    80005ade:	e526                	sd	s1,136(sp)
    80005ae0:	e14a                	sd	s2,128(sp)
    80005ae2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ae4:	ffffc097          	auipc	ra,0xffffc
    80005ae8:	ec8080e7          	jalr	-312(ra) # 800019ac <myproc>
    80005aec:	892a                	mv	s2,a0
  
  begin_op();
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	774080e7          	jalr	1908(ra) # 80004262 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005af6:	08000613          	li	a2,128
    80005afa:	f6040593          	addi	a1,s0,-160
    80005afe:	4501                	li	a0,0
    80005b00:	ffffd097          	auipc	ra,0xffffd
    80005b04:	1d8080e7          	jalr	472(ra) # 80002cd8 <argstr>
    80005b08:	04054b63          	bltz	a0,80005b5e <sys_chdir+0x86>
    80005b0c:	f6040513          	addi	a0,s0,-160
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	536080e7          	jalr	1334(ra) # 80004046 <namei>
    80005b18:	84aa                	mv	s1,a0
    80005b1a:	c131                	beqz	a0,80005b5e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	d84080e7          	jalr	-636(ra) # 800038a0 <ilock>
  if(ip->type != T_DIR){
    80005b24:	04449703          	lh	a4,68(s1)
    80005b28:	4785                	li	a5,1
    80005b2a:	04f71063          	bne	a4,a5,80005b6a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	e32080e7          	jalr	-462(ra) # 80003962 <iunlock>
  iput(p->cwd);
    80005b38:	15093503          	ld	a0,336(s2)
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	f1e080e7          	jalr	-226(ra) # 80003a5a <iput>
  end_op();
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	79e080e7          	jalr	1950(ra) # 800042e2 <end_op>
  p->cwd = ip;
    80005b4c:	14993823          	sd	s1,336(s2)
  return 0;
    80005b50:	4501                	li	a0,0
}
    80005b52:	60ea                	ld	ra,152(sp)
    80005b54:	644a                	ld	s0,144(sp)
    80005b56:	64aa                	ld	s1,136(sp)
    80005b58:	690a                	ld	s2,128(sp)
    80005b5a:	610d                	addi	sp,sp,160
    80005b5c:	8082                	ret
    end_op();
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	784080e7          	jalr	1924(ra) # 800042e2 <end_op>
    return -1;
    80005b66:	557d                	li	a0,-1
    80005b68:	b7ed                	j	80005b52 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b6a:	8526                	mv	a0,s1
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	f96080e7          	jalr	-106(ra) # 80003b02 <iunlockput>
    end_op();
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	76e080e7          	jalr	1902(ra) # 800042e2 <end_op>
    return -1;
    80005b7c:	557d                	li	a0,-1
    80005b7e:	bfd1                	j	80005b52 <sys_chdir+0x7a>

0000000080005b80 <sys_exec>:

uint64
sys_exec(void)
{
    80005b80:	7145                	addi	sp,sp,-464
    80005b82:	e786                	sd	ra,456(sp)
    80005b84:	e3a2                	sd	s0,448(sp)
    80005b86:	ff26                	sd	s1,440(sp)
    80005b88:	fb4a                	sd	s2,432(sp)
    80005b8a:	f74e                	sd	s3,424(sp)
    80005b8c:	f352                	sd	s4,416(sp)
    80005b8e:	ef56                	sd	s5,408(sp)
    80005b90:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b92:	e3840593          	addi	a1,s0,-456
    80005b96:	4505                	li	a0,1
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	120080e7          	jalr	288(ra) # 80002cb8 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ba0:	08000613          	li	a2,128
    80005ba4:	f4040593          	addi	a1,s0,-192
    80005ba8:	4501                	li	a0,0
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	12e080e7          	jalr	302(ra) # 80002cd8 <argstr>
    80005bb2:	87aa                	mv	a5,a0
    return -1;
    80005bb4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005bb6:	0c07c263          	bltz	a5,80005c7a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bba:	10000613          	li	a2,256
    80005bbe:	4581                	li	a1,0
    80005bc0:	e4040513          	addi	a0,s0,-448
    80005bc4:	ffffb097          	auipc	ra,0xffffb
    80005bc8:	10e080e7          	jalr	270(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bcc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bd0:	89a6                	mv	s3,s1
    80005bd2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bd4:	02000a13          	li	s4,32
    80005bd8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bdc:	00391793          	slli	a5,s2,0x3
    80005be0:	e3040593          	addi	a1,s0,-464
    80005be4:	e3843503          	ld	a0,-456(s0)
    80005be8:	953e                	add	a0,a0,a5
    80005bea:	ffffd097          	auipc	ra,0xffffd
    80005bee:	010080e7          	jalr	16(ra) # 80002bfa <fetchaddr>
    80005bf2:	02054a63          	bltz	a0,80005c26 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005bf6:	e3043783          	ld	a5,-464(s0)
    80005bfa:	c3b9                	beqz	a5,80005c40 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bfc:	ffffb097          	auipc	ra,0xffffb
    80005c00:	eea080e7          	jalr	-278(ra) # 80000ae6 <kalloc>
    80005c04:	85aa                	mv	a1,a0
    80005c06:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c0a:	cd11                	beqz	a0,80005c26 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c0c:	6605                	lui	a2,0x1
    80005c0e:	e3043503          	ld	a0,-464(s0)
    80005c12:	ffffd097          	auipc	ra,0xffffd
    80005c16:	03a080e7          	jalr	58(ra) # 80002c4c <fetchstr>
    80005c1a:	00054663          	bltz	a0,80005c26 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c1e:	0905                	addi	s2,s2,1
    80005c20:	09a1                	addi	s3,s3,8
    80005c22:	fb491be3          	bne	s2,s4,80005bd8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c26:	10048913          	addi	s2,s1,256
    80005c2a:	6088                	ld	a0,0(s1)
    80005c2c:	c531                	beqz	a0,80005c78 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c2e:	ffffb097          	auipc	ra,0xffffb
    80005c32:	dbc080e7          	jalr	-580(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c36:	04a1                	addi	s1,s1,8
    80005c38:	ff2499e3          	bne	s1,s2,80005c2a <sys_exec+0xaa>
  return -1;
    80005c3c:	557d                	li	a0,-1
    80005c3e:	a835                	j	80005c7a <sys_exec+0xfa>
      argv[i] = 0;
    80005c40:	0a8e                	slli	s5,s5,0x3
    80005c42:	fc040793          	addi	a5,s0,-64
    80005c46:	9abe                	add	s5,s5,a5
    80005c48:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c4c:	e4040593          	addi	a1,s0,-448
    80005c50:	f4040513          	addi	a0,s0,-192
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	154080e7          	jalr	340(ra) # 80004da8 <exec>
    80005c5c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c5e:	10048993          	addi	s3,s1,256
    80005c62:	6088                	ld	a0,0(s1)
    80005c64:	c901                	beqz	a0,80005c74 <sys_exec+0xf4>
    kfree(argv[i]);
    80005c66:	ffffb097          	auipc	ra,0xffffb
    80005c6a:	d84080e7          	jalr	-636(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c6e:	04a1                	addi	s1,s1,8
    80005c70:	ff3499e3          	bne	s1,s3,80005c62 <sys_exec+0xe2>
  return ret;
    80005c74:	854a                	mv	a0,s2
    80005c76:	a011                	j	80005c7a <sys_exec+0xfa>
  return -1;
    80005c78:	557d                	li	a0,-1
}
    80005c7a:	60be                	ld	ra,456(sp)
    80005c7c:	641e                	ld	s0,448(sp)
    80005c7e:	74fa                	ld	s1,440(sp)
    80005c80:	795a                	ld	s2,432(sp)
    80005c82:	79ba                	ld	s3,424(sp)
    80005c84:	7a1a                	ld	s4,416(sp)
    80005c86:	6afa                	ld	s5,408(sp)
    80005c88:	6179                	addi	sp,sp,464
    80005c8a:	8082                	ret

0000000080005c8c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c8c:	7139                	addi	sp,sp,-64
    80005c8e:	fc06                	sd	ra,56(sp)
    80005c90:	f822                	sd	s0,48(sp)
    80005c92:	f426                	sd	s1,40(sp)
    80005c94:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c96:	ffffc097          	auipc	ra,0xffffc
    80005c9a:	d16080e7          	jalr	-746(ra) # 800019ac <myproc>
    80005c9e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ca0:	fd840593          	addi	a1,s0,-40
    80005ca4:	4501                	li	a0,0
    80005ca6:	ffffd097          	auipc	ra,0xffffd
    80005caa:	012080e7          	jalr	18(ra) # 80002cb8 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005cae:	fc840593          	addi	a1,s0,-56
    80005cb2:	fd040513          	addi	a0,s0,-48
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	da8080e7          	jalr	-600(ra) # 80004a5e <pipealloc>
    return -1;
    80005cbe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cc0:	0c054463          	bltz	a0,80005d88 <sys_pipe+0xfc>
  fd0 = -1;
    80005cc4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cc8:	fd043503          	ld	a0,-48(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	4fc080e7          	jalr	1276(ra) # 800051c8 <fdalloc>
    80005cd4:	fca42223          	sw	a0,-60(s0)
    80005cd8:	08054b63          	bltz	a0,80005d6e <sys_pipe+0xe2>
    80005cdc:	fc843503          	ld	a0,-56(s0)
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	4e8080e7          	jalr	1256(ra) # 800051c8 <fdalloc>
    80005ce8:	fca42023          	sw	a0,-64(s0)
    80005cec:	06054863          	bltz	a0,80005d5c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cf0:	4691                	li	a3,4
    80005cf2:	fc440613          	addi	a2,s0,-60
    80005cf6:	fd843583          	ld	a1,-40(s0)
    80005cfa:	68a8                	ld	a0,80(s1)
    80005cfc:	ffffc097          	auipc	ra,0xffffc
    80005d00:	96c080e7          	jalr	-1684(ra) # 80001668 <copyout>
    80005d04:	02054063          	bltz	a0,80005d24 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d08:	4691                	li	a3,4
    80005d0a:	fc040613          	addi	a2,s0,-64
    80005d0e:	fd843583          	ld	a1,-40(s0)
    80005d12:	0591                	addi	a1,a1,4
    80005d14:	68a8                	ld	a0,80(s1)
    80005d16:	ffffc097          	auipc	ra,0xffffc
    80005d1a:	952080e7          	jalr	-1710(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d1e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d20:	06055463          	bgez	a0,80005d88 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d24:	fc442783          	lw	a5,-60(s0)
    80005d28:	07e9                	addi	a5,a5,26
    80005d2a:	078e                	slli	a5,a5,0x3
    80005d2c:	97a6                	add	a5,a5,s1
    80005d2e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d32:	fc042503          	lw	a0,-64(s0)
    80005d36:	0569                	addi	a0,a0,26
    80005d38:	050e                	slli	a0,a0,0x3
    80005d3a:	94aa                	add	s1,s1,a0
    80005d3c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d40:	fd043503          	ld	a0,-48(s0)
    80005d44:	fffff097          	auipc	ra,0xfffff
    80005d48:	9ea080e7          	jalr	-1558(ra) # 8000472e <fileclose>
    fileclose(wf);
    80005d4c:	fc843503          	ld	a0,-56(s0)
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	9de080e7          	jalr	-1570(ra) # 8000472e <fileclose>
    return -1;
    80005d58:	57fd                	li	a5,-1
    80005d5a:	a03d                	j	80005d88 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d5c:	fc442783          	lw	a5,-60(s0)
    80005d60:	0007c763          	bltz	a5,80005d6e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d64:	07e9                	addi	a5,a5,26
    80005d66:	078e                	slli	a5,a5,0x3
    80005d68:	94be                	add	s1,s1,a5
    80005d6a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d6e:	fd043503          	ld	a0,-48(s0)
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	9bc080e7          	jalr	-1604(ra) # 8000472e <fileclose>
    fileclose(wf);
    80005d7a:	fc843503          	ld	a0,-56(s0)
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	9b0080e7          	jalr	-1616(ra) # 8000472e <fileclose>
    return -1;
    80005d86:	57fd                	li	a5,-1
}
    80005d88:	853e                	mv	a0,a5
    80005d8a:	70e2                	ld	ra,56(sp)
    80005d8c:	7442                	ld	s0,48(sp)
    80005d8e:	74a2                	ld	s1,40(sp)
    80005d90:	6121                	addi	sp,sp,64
    80005d92:	8082                	ret

0000000080005d94 <getreadcount>:

uint64 getreadcount(void)
{
    80005d94:	1141                	addi	sp,sp,-16
    80005d96:	e422                	sd	s0,8(sp)
    80005d98:	0800                	addi	s0,sp,16
  // printf("Hi\n");
  // // readcount++;
  // printf("%d\n",readcount);
  return readcount;
    80005d9a:	00003517          	auipc	a0,0x3
    80005d9e:	b4a52503          	lw	a0,-1206(a0) # 800088e4 <readcount>
    80005da2:	6422                	ld	s0,8(sp)
    80005da4:	0141                	addi	sp,sp,16
    80005da6:	8082                	ret
	...

0000000080005db0 <kernelvec>:
    80005db0:	7111                	addi	sp,sp,-256
    80005db2:	e006                	sd	ra,0(sp)
    80005db4:	e40a                	sd	sp,8(sp)
    80005db6:	e80e                	sd	gp,16(sp)
    80005db8:	ec12                	sd	tp,24(sp)
    80005dba:	f016                	sd	t0,32(sp)
    80005dbc:	f41a                	sd	t1,40(sp)
    80005dbe:	f81e                	sd	t2,48(sp)
    80005dc0:	fc22                	sd	s0,56(sp)
    80005dc2:	e0a6                	sd	s1,64(sp)
    80005dc4:	e4aa                	sd	a0,72(sp)
    80005dc6:	e8ae                	sd	a1,80(sp)
    80005dc8:	ecb2                	sd	a2,88(sp)
    80005dca:	f0b6                	sd	a3,96(sp)
    80005dcc:	f4ba                	sd	a4,104(sp)
    80005dce:	f8be                	sd	a5,112(sp)
    80005dd0:	fcc2                	sd	a6,120(sp)
    80005dd2:	e146                	sd	a7,128(sp)
    80005dd4:	e54a                	sd	s2,136(sp)
    80005dd6:	e94e                	sd	s3,144(sp)
    80005dd8:	ed52                	sd	s4,152(sp)
    80005dda:	f156                	sd	s5,160(sp)
    80005ddc:	f55a                	sd	s6,168(sp)
    80005dde:	f95e                	sd	s7,176(sp)
    80005de0:	fd62                	sd	s8,184(sp)
    80005de2:	e1e6                	sd	s9,192(sp)
    80005de4:	e5ea                	sd	s10,200(sp)
    80005de6:	e9ee                	sd	s11,208(sp)
    80005de8:	edf2                	sd	t3,216(sp)
    80005dea:	f1f6                	sd	t4,224(sp)
    80005dec:	f5fa                	sd	t5,232(sp)
    80005dee:	f9fe                	sd	t6,240(sp)
    80005df0:	cd7fc0ef          	jal	ra,80002ac6 <kerneltrap>
    80005df4:	6082                	ld	ra,0(sp)
    80005df6:	6122                	ld	sp,8(sp)
    80005df8:	61c2                	ld	gp,16(sp)
    80005dfa:	7282                	ld	t0,32(sp)
    80005dfc:	7322                	ld	t1,40(sp)
    80005dfe:	73c2                	ld	t2,48(sp)
    80005e00:	7462                	ld	s0,56(sp)
    80005e02:	6486                	ld	s1,64(sp)
    80005e04:	6526                	ld	a0,72(sp)
    80005e06:	65c6                	ld	a1,80(sp)
    80005e08:	6666                	ld	a2,88(sp)
    80005e0a:	7686                	ld	a3,96(sp)
    80005e0c:	7726                	ld	a4,104(sp)
    80005e0e:	77c6                	ld	a5,112(sp)
    80005e10:	7866                	ld	a6,120(sp)
    80005e12:	688a                	ld	a7,128(sp)
    80005e14:	692a                	ld	s2,136(sp)
    80005e16:	69ca                	ld	s3,144(sp)
    80005e18:	6a6a                	ld	s4,152(sp)
    80005e1a:	7a8a                	ld	s5,160(sp)
    80005e1c:	7b2a                	ld	s6,168(sp)
    80005e1e:	7bca                	ld	s7,176(sp)
    80005e20:	7c6a                	ld	s8,184(sp)
    80005e22:	6c8e                	ld	s9,192(sp)
    80005e24:	6d2e                	ld	s10,200(sp)
    80005e26:	6dce                	ld	s11,208(sp)
    80005e28:	6e6e                	ld	t3,216(sp)
    80005e2a:	7e8e                	ld	t4,224(sp)
    80005e2c:	7f2e                	ld	t5,232(sp)
    80005e2e:	7fce                	ld	t6,240(sp)
    80005e30:	6111                	addi	sp,sp,256
    80005e32:	10200073          	sret
    80005e36:	00000013          	nop
    80005e3a:	00000013          	nop
    80005e3e:	0001                	nop

0000000080005e40 <timervec>:
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	e10c                	sd	a1,0(a0)
    80005e46:	e510                	sd	a2,8(a0)
    80005e48:	e914                	sd	a3,16(a0)
    80005e4a:	6d0c                	ld	a1,24(a0)
    80005e4c:	7110                	ld	a2,32(a0)
    80005e4e:	6194                	ld	a3,0(a1)
    80005e50:	96b2                	add	a3,a3,a2
    80005e52:	e194                	sd	a3,0(a1)
    80005e54:	4589                	li	a1,2
    80005e56:	14459073          	csrw	sip,a1
    80005e5a:	6914                	ld	a3,16(a0)
    80005e5c:	6510                	ld	a2,8(a0)
    80005e5e:	610c                	ld	a1,0(a0)
    80005e60:	34051573          	csrrw	a0,mscratch,a0
    80005e64:	30200073          	mret
	...

0000000080005e6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e6a:	1141                	addi	sp,sp,-16
    80005e6c:	e422                	sd	s0,8(sp)
    80005e6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e70:	0c0007b7          	lui	a5,0xc000
    80005e74:	4705                	li	a4,1
    80005e76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e78:	c3d8                	sw	a4,4(a5)
}
    80005e7a:	6422                	ld	s0,8(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret

0000000080005e80 <plicinithart>:

void
plicinithart(void)
{
    80005e80:	1141                	addi	sp,sp,-16
    80005e82:	e406                	sd	ra,8(sp)
    80005e84:	e022                	sd	s0,0(sp)
    80005e86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	af8080e7          	jalr	-1288(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e90:	0085171b          	slliw	a4,a0,0x8
    80005e94:	0c0027b7          	lui	a5,0xc002
    80005e98:	97ba                	add	a5,a5,a4
    80005e9a:	40200713          	li	a4,1026
    80005e9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ea2:	00d5151b          	slliw	a0,a0,0xd
    80005ea6:	0c2017b7          	lui	a5,0xc201
    80005eaa:	953e                	add	a0,a0,a5
    80005eac:	00052023          	sw	zero,0(a0)
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret

0000000080005eb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005eb8:	1141                	addi	sp,sp,-16
    80005eba:	e406                	sd	ra,8(sp)
    80005ebc:	e022                	sd	s0,0(sp)
    80005ebe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	ac0080e7          	jalr	-1344(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ec8:	00d5179b          	slliw	a5,a0,0xd
    80005ecc:	0c201537          	lui	a0,0xc201
    80005ed0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ed2:	4148                	lw	a0,4(a0)
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret

0000000080005edc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	e426                	sd	s1,8(sp)
    80005ee4:	1000                	addi	s0,sp,32
    80005ee6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	a98080e7          	jalr	-1384(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ef0:	00d5151b          	slliw	a0,a0,0xd
    80005ef4:	0c2017b7          	lui	a5,0xc201
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	c3c4                	sw	s1,4(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret

0000000080005f06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f06:	1141                	addi	sp,sp,-16
    80005f08:	e406                	sd	ra,8(sp)
    80005f0a:	e022                	sd	s0,0(sp)
    80005f0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f0e:	479d                	li	a5,7
    80005f10:	04a7cc63          	blt	a5,a0,80005f68 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f14:	0001c797          	auipc	a5,0x1c
    80005f18:	10c78793          	addi	a5,a5,268 # 80022020 <disk>
    80005f1c:	97aa                	add	a5,a5,a0
    80005f1e:	0187c783          	lbu	a5,24(a5)
    80005f22:	ebb9                	bnez	a5,80005f78 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f24:	00451613          	slli	a2,a0,0x4
    80005f28:	0001c797          	auipc	a5,0x1c
    80005f2c:	0f878793          	addi	a5,a5,248 # 80022020 <disk>
    80005f30:	6394                	ld	a3,0(a5)
    80005f32:	96b2                	add	a3,a3,a2
    80005f34:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f38:	6398                	ld	a4,0(a5)
    80005f3a:	9732                	add	a4,a4,a2
    80005f3c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f40:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f44:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f48:	953e                	add	a0,a0,a5
    80005f4a:	4785                	li	a5,1
    80005f4c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f50:	0001c517          	auipc	a0,0x1c
    80005f54:	0e850513          	addi	a0,a0,232 # 80022038 <disk+0x18>
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	174080e7          	jalr	372(ra) # 800020cc <wakeup>
}
    80005f60:	60a2                	ld	ra,8(sp)
    80005f62:	6402                	ld	s0,0(sp)
    80005f64:	0141                	addi	sp,sp,16
    80005f66:	8082                	ret
    panic("free_desc 1");
    80005f68:	00002517          	auipc	a0,0x2
    80005f6c:	7f050513          	addi	a0,a0,2032 # 80008758 <syscalls+0x308>
    80005f70:	ffffa097          	auipc	ra,0xffffa
    80005f74:	5ce080e7          	jalr	1486(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f78:	00002517          	auipc	a0,0x2
    80005f7c:	7f050513          	addi	a0,a0,2032 # 80008768 <syscalls+0x318>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	5be080e7          	jalr	1470(ra) # 8000053e <panic>

0000000080005f88 <virtio_disk_init>:
{
    80005f88:	1101                	addi	sp,sp,-32
    80005f8a:	ec06                	sd	ra,24(sp)
    80005f8c:	e822                	sd	s0,16(sp)
    80005f8e:	e426                	sd	s1,8(sp)
    80005f90:	e04a                	sd	s2,0(sp)
    80005f92:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f94:	00002597          	auipc	a1,0x2
    80005f98:	7e458593          	addi	a1,a1,2020 # 80008778 <syscalls+0x328>
    80005f9c:	0001c517          	auipc	a0,0x1c
    80005fa0:	1ac50513          	addi	a0,a0,428 # 80022148 <disk+0x128>
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	ba2080e7          	jalr	-1118(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fac:	100017b7          	lui	a5,0x10001
    80005fb0:	4398                	lw	a4,0(a5)
    80005fb2:	2701                	sext.w	a4,a4
    80005fb4:	747277b7          	lui	a5,0x74727
    80005fb8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fbc:	14f71c63          	bne	a4,a5,80006114 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fc0:	100017b7          	lui	a5,0x10001
    80005fc4:	43dc                	lw	a5,4(a5)
    80005fc6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc8:	4709                	li	a4,2
    80005fca:	14e79563          	bne	a5,a4,80006114 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	479c                	lw	a5,8(a5)
    80005fd4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fd6:	12e79f63          	bne	a5,a4,80006114 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fda:	100017b7          	lui	a5,0x10001
    80005fde:	47d8                	lw	a4,12(a5)
    80005fe0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fe2:	554d47b7          	lui	a5,0x554d4
    80005fe6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fea:	12f71563          	bne	a4,a5,80006114 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	100017b7          	lui	a5,0x10001
    80005ff2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff6:	4705                	li	a4,1
    80005ff8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffa:	470d                	li	a4,3
    80005ffc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ffe:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006000:	c7ffe737          	lui	a4,0xc7ffe
    80006004:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc5ff>
    80006008:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000600a:	2701                	sext.w	a4,a4
    8000600c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600e:	472d                	li	a4,11
    80006010:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006012:	5bbc                	lw	a5,112(a5)
    80006014:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006018:	8ba1                	andi	a5,a5,8
    8000601a:	10078563          	beqz	a5,80006124 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000601e:	100017b7          	lui	a5,0x10001
    80006022:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006026:	43fc                	lw	a5,68(a5)
    80006028:	2781                	sext.w	a5,a5
    8000602a:	10079563          	bnez	a5,80006134 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	5bdc                	lw	a5,52(a5)
    80006034:	2781                	sext.w	a5,a5
  if(max == 0)
    80006036:	10078763          	beqz	a5,80006144 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000603a:	471d                	li	a4,7
    8000603c:	10f77c63          	bgeu	a4,a5,80006154 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	aa6080e7          	jalr	-1370(ra) # 80000ae6 <kalloc>
    80006048:	0001c497          	auipc	s1,0x1c
    8000604c:	fd848493          	addi	s1,s1,-40 # 80022020 <disk>
    80006050:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006052:	ffffb097          	auipc	ra,0xffffb
    80006056:	a94080e7          	jalr	-1388(ra) # 80000ae6 <kalloc>
    8000605a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000605c:	ffffb097          	auipc	ra,0xffffb
    80006060:	a8a080e7          	jalr	-1398(ra) # 80000ae6 <kalloc>
    80006064:	87aa                	mv	a5,a0
    80006066:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006068:	6088                	ld	a0,0(s1)
    8000606a:	cd6d                	beqz	a0,80006164 <virtio_disk_init+0x1dc>
    8000606c:	0001c717          	auipc	a4,0x1c
    80006070:	fbc73703          	ld	a4,-68(a4) # 80022028 <disk+0x8>
    80006074:	cb65                	beqz	a4,80006164 <virtio_disk_init+0x1dc>
    80006076:	c7fd                	beqz	a5,80006164 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006078:	6605                	lui	a2,0x1
    8000607a:	4581                	li	a1,0
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	c56080e7          	jalr	-938(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006084:	0001c497          	auipc	s1,0x1c
    80006088:	f9c48493          	addi	s1,s1,-100 # 80022020 <disk>
    8000608c:	6605                	lui	a2,0x1
    8000608e:	4581                	li	a1,0
    80006090:	6488                	ld	a0,8(s1)
    80006092:	ffffb097          	auipc	ra,0xffffb
    80006096:	c40080e7          	jalr	-960(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000609a:	6605                	lui	a2,0x1
    8000609c:	4581                	li	a1,0
    8000609e:	6888                	ld	a0,16(s1)
    800060a0:	ffffb097          	auipc	ra,0xffffb
    800060a4:	c32080e7          	jalr	-974(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060a8:	100017b7          	lui	a5,0x10001
    800060ac:	4721                	li	a4,8
    800060ae:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060b0:	4098                	lw	a4,0(s1)
    800060b2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060b6:	40d8                	lw	a4,4(s1)
    800060b8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060bc:	6498                	ld	a4,8(s1)
    800060be:	0007069b          	sext.w	a3,a4
    800060c2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060c6:	9701                	srai	a4,a4,0x20
    800060c8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060cc:	6898                	ld	a4,16(s1)
    800060ce:	0007069b          	sext.w	a3,a4
    800060d2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060d6:	9701                	srai	a4,a4,0x20
    800060d8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060dc:	4705                	li	a4,1
    800060de:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800060e0:	00e48c23          	sb	a4,24(s1)
    800060e4:	00e48ca3          	sb	a4,25(s1)
    800060e8:	00e48d23          	sb	a4,26(s1)
    800060ec:	00e48da3          	sb	a4,27(s1)
    800060f0:	00e48e23          	sb	a4,28(s1)
    800060f4:	00e48ea3          	sb	a4,29(s1)
    800060f8:	00e48f23          	sb	a4,30(s1)
    800060fc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006100:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006104:	0727a823          	sw	s2,112(a5)
}
    80006108:	60e2                	ld	ra,24(sp)
    8000610a:	6442                	ld	s0,16(sp)
    8000610c:	64a2                	ld	s1,8(sp)
    8000610e:	6902                	ld	s2,0(sp)
    80006110:	6105                	addi	sp,sp,32
    80006112:	8082                	ret
    panic("could not find virtio disk");
    80006114:	00002517          	auipc	a0,0x2
    80006118:	67450513          	addi	a0,a0,1652 # 80008788 <syscalls+0x338>
    8000611c:	ffffa097          	auipc	ra,0xffffa
    80006120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006124:	00002517          	auipc	a0,0x2
    80006128:	68450513          	addi	a0,a0,1668 # 800087a8 <syscalls+0x358>
    8000612c:	ffffa097          	auipc	ra,0xffffa
    80006130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006134:	00002517          	auipc	a0,0x2
    80006138:	69450513          	addi	a0,a0,1684 # 800087c8 <syscalls+0x378>
    8000613c:	ffffa097          	auipc	ra,0xffffa
    80006140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	6a450513          	addi	a0,a0,1700 # 800087e8 <syscalls+0x398>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006154:	00002517          	auipc	a0,0x2
    80006158:	6b450513          	addi	a0,a0,1716 # 80008808 <syscalls+0x3b8>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e2080e7          	jalr	994(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	6c450513          	addi	a0,a0,1732 # 80008828 <syscalls+0x3d8>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>

0000000080006174 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006174:	7119                	addi	sp,sp,-128
    80006176:	fc86                	sd	ra,120(sp)
    80006178:	f8a2                	sd	s0,112(sp)
    8000617a:	f4a6                	sd	s1,104(sp)
    8000617c:	f0ca                	sd	s2,96(sp)
    8000617e:	ecce                	sd	s3,88(sp)
    80006180:	e8d2                	sd	s4,80(sp)
    80006182:	e4d6                	sd	s5,72(sp)
    80006184:	e0da                	sd	s6,64(sp)
    80006186:	fc5e                	sd	s7,56(sp)
    80006188:	f862                	sd	s8,48(sp)
    8000618a:	f466                	sd	s9,40(sp)
    8000618c:	f06a                	sd	s10,32(sp)
    8000618e:	ec6e                	sd	s11,24(sp)
    80006190:	0100                	addi	s0,sp,128
    80006192:	8aaa                	mv	s5,a0
    80006194:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006196:	00c52d03          	lw	s10,12(a0)
    8000619a:	001d1d1b          	slliw	s10,s10,0x1
    8000619e:	1d02                	slli	s10,s10,0x20
    800061a0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800061a4:	0001c517          	auipc	a0,0x1c
    800061a8:	fa450513          	addi	a0,a0,-92 # 80022148 <disk+0x128>
    800061ac:	ffffb097          	auipc	ra,0xffffb
    800061b0:	a2a080e7          	jalr	-1494(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800061b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061b6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061b8:	0001cb97          	auipc	s7,0x1c
    800061bc:	e68b8b93          	addi	s7,s7,-408 # 80022020 <disk>
  for(int i = 0; i < 3; i++){
    800061c0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061c2:	0001cc97          	auipc	s9,0x1c
    800061c6:	f86c8c93          	addi	s9,s9,-122 # 80022148 <disk+0x128>
    800061ca:	a08d                	j	8000622c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061cc:	00fb8733          	add	a4,s7,a5
    800061d0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061d4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061d6:	0207c563          	bltz	a5,80006200 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061da:	2905                	addiw	s2,s2,1
    800061dc:	0611                	addi	a2,a2,4
    800061de:	05690c63          	beq	s2,s6,80006236 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800061e2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061e4:	0001c717          	auipc	a4,0x1c
    800061e8:	e3c70713          	addi	a4,a4,-452 # 80022020 <disk>
    800061ec:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061ee:	01874683          	lbu	a3,24(a4)
    800061f2:	fee9                	bnez	a3,800061cc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061f4:	2785                	addiw	a5,a5,1
    800061f6:	0705                	addi	a4,a4,1
    800061f8:	fe979be3          	bne	a5,s1,800061ee <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061fc:	57fd                	li	a5,-1
    800061fe:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006200:	01205d63          	blez	s2,8000621a <virtio_disk_rw+0xa6>
    80006204:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006206:	000a2503          	lw	a0,0(s4)
    8000620a:	00000097          	auipc	ra,0x0
    8000620e:	cfc080e7          	jalr	-772(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006212:	2d85                	addiw	s11,s11,1
    80006214:	0a11                	addi	s4,s4,4
    80006216:	ffb918e3          	bne	s2,s11,80006206 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000621a:	85e6                	mv	a1,s9
    8000621c:	0001c517          	auipc	a0,0x1c
    80006220:	e1c50513          	addi	a0,a0,-484 # 80022038 <disk+0x18>
    80006224:	ffffc097          	auipc	ra,0xffffc
    80006228:	e44080e7          	jalr	-444(ra) # 80002068 <sleep>
  for(int i = 0; i < 3; i++){
    8000622c:	f8040a13          	addi	s4,s0,-128
{
    80006230:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006232:	894e                	mv	s2,s3
    80006234:	b77d                	j	800061e2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006236:	f8042583          	lw	a1,-128(s0)
    8000623a:	00a58793          	addi	a5,a1,10
    8000623e:	0792                	slli	a5,a5,0x4

  if(write)
    80006240:	0001c617          	auipc	a2,0x1c
    80006244:	de060613          	addi	a2,a2,-544 # 80022020 <disk>
    80006248:	00f60733          	add	a4,a2,a5
    8000624c:	018036b3          	snez	a3,s8
    80006250:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006252:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006256:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000625a:	f6078693          	addi	a3,a5,-160
    8000625e:	6218                	ld	a4,0(a2)
    80006260:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006262:	00878513          	addi	a0,a5,8
    80006266:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006268:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000626a:	6208                	ld	a0,0(a2)
    8000626c:	96aa                	add	a3,a3,a0
    8000626e:	4741                	li	a4,16
    80006270:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006272:	4705                	li	a4,1
    80006274:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006278:	f8442703          	lw	a4,-124(s0)
    8000627c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006280:	0712                	slli	a4,a4,0x4
    80006282:	953a                	add	a0,a0,a4
    80006284:	058a8693          	addi	a3,s5,88
    80006288:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000628a:	6208                	ld	a0,0(a2)
    8000628c:	972a                	add	a4,a4,a0
    8000628e:	40000693          	li	a3,1024
    80006292:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006294:	001c3c13          	seqz	s8,s8
    80006298:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000629a:	001c6c13          	ori	s8,s8,1
    8000629e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800062a2:	f8842603          	lw	a2,-120(s0)
    800062a6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062aa:	0001c697          	auipc	a3,0x1c
    800062ae:	d7668693          	addi	a3,a3,-650 # 80022020 <disk>
    800062b2:	00258713          	addi	a4,a1,2
    800062b6:	0712                	slli	a4,a4,0x4
    800062b8:	9736                	add	a4,a4,a3
    800062ba:	587d                	li	a6,-1
    800062bc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062c0:	0612                	slli	a2,a2,0x4
    800062c2:	9532                	add	a0,a0,a2
    800062c4:	f9078793          	addi	a5,a5,-112
    800062c8:	97b6                	add	a5,a5,a3
    800062ca:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800062cc:	629c                	ld	a5,0(a3)
    800062ce:	97b2                	add	a5,a5,a2
    800062d0:	4605                	li	a2,1
    800062d2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062d4:	4509                	li	a0,2
    800062d6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800062da:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062de:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062e2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062e6:	6698                	ld	a4,8(a3)
    800062e8:	00275783          	lhu	a5,2(a4)
    800062ec:	8b9d                	andi	a5,a5,7
    800062ee:	0786                	slli	a5,a5,0x1
    800062f0:	97ba                	add	a5,a5,a4
    800062f2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800062f6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062fa:	6698                	ld	a4,8(a3)
    800062fc:	00275783          	lhu	a5,2(a4)
    80006300:	2785                	addiw	a5,a5,1
    80006302:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006306:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000630a:	100017b7          	lui	a5,0x10001
    8000630e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006312:	004aa783          	lw	a5,4(s5)
    80006316:	02c79163          	bne	a5,a2,80006338 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000631a:	0001c917          	auipc	s2,0x1c
    8000631e:	e2e90913          	addi	s2,s2,-466 # 80022148 <disk+0x128>
  while(b->disk == 1) {
    80006322:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006324:	85ca                	mv	a1,s2
    80006326:	8556                	mv	a0,s5
    80006328:	ffffc097          	auipc	ra,0xffffc
    8000632c:	d40080e7          	jalr	-704(ra) # 80002068 <sleep>
  while(b->disk == 1) {
    80006330:	004aa783          	lw	a5,4(s5)
    80006334:	fe9788e3          	beq	a5,s1,80006324 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006338:	f8042903          	lw	s2,-128(s0)
    8000633c:	00290793          	addi	a5,s2,2
    80006340:	00479713          	slli	a4,a5,0x4
    80006344:	0001c797          	auipc	a5,0x1c
    80006348:	cdc78793          	addi	a5,a5,-804 # 80022020 <disk>
    8000634c:	97ba                	add	a5,a5,a4
    8000634e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006352:	0001c997          	auipc	s3,0x1c
    80006356:	cce98993          	addi	s3,s3,-818 # 80022020 <disk>
    8000635a:	00491713          	slli	a4,s2,0x4
    8000635e:	0009b783          	ld	a5,0(s3)
    80006362:	97ba                	add	a5,a5,a4
    80006364:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006368:	854a                	mv	a0,s2
    8000636a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000636e:	00000097          	auipc	ra,0x0
    80006372:	b98080e7          	jalr	-1128(ra) # 80005f06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006376:	8885                	andi	s1,s1,1
    80006378:	f0ed                	bnez	s1,8000635a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000637a:	0001c517          	auipc	a0,0x1c
    8000637e:	dce50513          	addi	a0,a0,-562 # 80022148 <disk+0x128>
    80006382:	ffffb097          	auipc	ra,0xffffb
    80006386:	908080e7          	jalr	-1784(ra) # 80000c8a <release>
}
    8000638a:	70e6                	ld	ra,120(sp)
    8000638c:	7446                	ld	s0,112(sp)
    8000638e:	74a6                	ld	s1,104(sp)
    80006390:	7906                	ld	s2,96(sp)
    80006392:	69e6                	ld	s3,88(sp)
    80006394:	6a46                	ld	s4,80(sp)
    80006396:	6aa6                	ld	s5,72(sp)
    80006398:	6b06                	ld	s6,64(sp)
    8000639a:	7be2                	ld	s7,56(sp)
    8000639c:	7c42                	ld	s8,48(sp)
    8000639e:	7ca2                	ld	s9,40(sp)
    800063a0:	7d02                	ld	s10,32(sp)
    800063a2:	6de2                	ld	s11,24(sp)
    800063a4:	6109                	addi	sp,sp,128
    800063a6:	8082                	ret

00000000800063a8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063a8:	1101                	addi	sp,sp,-32
    800063aa:	ec06                	sd	ra,24(sp)
    800063ac:	e822                	sd	s0,16(sp)
    800063ae:	e426                	sd	s1,8(sp)
    800063b0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063b2:	0001c497          	auipc	s1,0x1c
    800063b6:	c6e48493          	addi	s1,s1,-914 # 80022020 <disk>
    800063ba:	0001c517          	auipc	a0,0x1c
    800063be:	d8e50513          	addi	a0,a0,-626 # 80022148 <disk+0x128>
    800063c2:	ffffb097          	auipc	ra,0xffffb
    800063c6:	814080e7          	jalr	-2028(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063ca:	10001737          	lui	a4,0x10001
    800063ce:	533c                	lw	a5,96(a4)
    800063d0:	8b8d                	andi	a5,a5,3
    800063d2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063d4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063d8:	689c                	ld	a5,16(s1)
    800063da:	0204d703          	lhu	a4,32(s1)
    800063de:	0027d783          	lhu	a5,2(a5)
    800063e2:	04f70863          	beq	a4,a5,80006432 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063e6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063ea:	6898                	ld	a4,16(s1)
    800063ec:	0204d783          	lhu	a5,32(s1)
    800063f0:	8b9d                	andi	a5,a5,7
    800063f2:	078e                	slli	a5,a5,0x3
    800063f4:	97ba                	add	a5,a5,a4
    800063f6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063f8:	00278713          	addi	a4,a5,2
    800063fc:	0712                	slli	a4,a4,0x4
    800063fe:	9726                	add	a4,a4,s1
    80006400:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006404:	e721                	bnez	a4,8000644c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006406:	0789                	addi	a5,a5,2
    80006408:	0792                	slli	a5,a5,0x4
    8000640a:	97a6                	add	a5,a5,s1
    8000640c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000640e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006412:	ffffc097          	auipc	ra,0xffffc
    80006416:	cba080e7          	jalr	-838(ra) # 800020cc <wakeup>

    disk.used_idx += 1;
    8000641a:	0204d783          	lhu	a5,32(s1)
    8000641e:	2785                	addiw	a5,a5,1
    80006420:	17c2                	slli	a5,a5,0x30
    80006422:	93c1                	srli	a5,a5,0x30
    80006424:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006428:	6898                	ld	a4,16(s1)
    8000642a:	00275703          	lhu	a4,2(a4)
    8000642e:	faf71ce3          	bne	a4,a5,800063e6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006432:	0001c517          	auipc	a0,0x1c
    80006436:	d1650513          	addi	a0,a0,-746 # 80022148 <disk+0x128>
    8000643a:	ffffb097          	auipc	ra,0xffffb
    8000643e:	850080e7          	jalr	-1968(ra) # 80000c8a <release>
}
    80006442:	60e2                	ld	ra,24(sp)
    80006444:	6442                	ld	s0,16(sp)
    80006446:	64a2                	ld	s1,8(sp)
    80006448:	6105                	addi	sp,sp,32
    8000644a:	8082                	ret
      panic("virtio_disk_intr status");
    8000644c:	00002517          	auipc	a0,0x2
    80006450:	3f450513          	addi	a0,a0,1012 # 80008840 <syscalls+0x3f0>
    80006454:	ffffa097          	auipc	ra,0xffffa
    80006458:	0ea080e7          	jalr	234(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
